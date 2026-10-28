/*
 * External awards. A website or bot inserts a 'pending' row into
 * groot_coin_award_queue; this poller pays it through IssueAward, the same
 * path as `.groot award`.
 *
 * Exactly once: the award's own transaction sets the row to 'done', and the
 * (source, source_ref) key on grootcoin_award refuses a second award for the
 * same request. A row whose outcome is unknown (database error, server
 * stopped mid-award) stays 'pending' and is read again later; the key lookup
 * then finds the earlier award and marks the row done instead of paying again.
 *
 * Trust: anyone who can INSERT into groot_coin_award_queue can mint coins for
 * any character, up to MaxAward per row. The requested_by_account checks
 * (Game Master and RBAC 1001) only stop rows naming an account that could
 * not award in game; they do not authenticate the inserter. Grant INSERT on
 * that table only to the trusted website or bot account.
 */

#include "GrootCoin.h"
#include "GrootCoinInternal.h"

#include "AccountMgr.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "GameTime.h"
#include "Log.h"
#include "QueryCallback.h"
#include "QueryResult.h"
#include "RBAC.h"
#include "Realm.h"
#include "World.h"

#include <unordered_set>

namespace GrootCoin
{
    namespace
    {
        uint64 nextPollMs = 0;
        bool polling = false;
        std::unordered_set<uint64> inFlight;

        void MarkFailed(uint64 id, std::string const& error)
        {
            LOG_WARN("module.bazaar", "Groot Coin: queued award {} failed: {}", id, error);
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_GROOTCOIN_QUEUE_FAILED);
            stmt->SetData(0, error.substr(0, REASON_MAX));
            stmt->SetData(1, id);
            CharacterDatabase.Execute(stmt);
        }

        void MarkDone(uint64 id, std::string const& awardId)
        {
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_GROOTCOIN_QUEUE_DONE);
            stmt->SetData(0, awardId);
            stmt->SetData(1, id);
            CharacterDatabase.Execute(stmt);
        }

        void Process(Field const* fields)
        {
            uint64 const id = fields[0].Get<uint64>();
            if (inFlight.contains(id))
                return;

            std::string const source = fields[1].Get<std::string>();
            std::string const ref = fields[2].Get<std::string>();
            uint32 const character = fields[3].Get<uint32>();
            uint32 const amount = fields[4].Get<uint32>();
            std::string const reason = fields[5].Get<std::string>();
            uint32 const requester = fields[6].Get<uint32>();

            QueuedAwardCheck const check = CheckQueuedAward(source, ref, character, amount, GetSettings().maxAward,
                reason, requester);
            if (check != QueuedAwardCheck::Ok)
            {
                MarkFailed(id, std::string(DescribeQueuedAwardCheck(check)));
                return;
            }

            // The same two gates as `.groot award`: Game Master security and RBAC 1001 (with its denials) on
            // this realm. The queue cannot authenticate the inserter, so this only names who approved the row.
            if (AccountMgr::GetSecurity(requester, realm.Id.Realm) < SEC_GAMEMASTER)
            {
                MarkFailed(id, "requested_by_account is not a Game Master on this realm");
                return;
            }
            if (!AccountMgr::HasPermission(requester, rbac::RBAC_PERM_COMMAND_GROOT_AWARD, realm.Id.Realm))
            {
                MarkFailed(id, "requested_by_account lacks RBAC 1001 (Command: groot award) on this realm");
                return;
            }

            AwardRequest request;
            request.recipient = ObjectGuid::Create<HighGuid::Player>(character);
            request.amount = amount;
            request.reason = reason;
            request.attributionRef = (source + ":" + ref).substr(0, ATTRIBUTION_MAX);
            request.actorAccountId = requester;
            request.source = source;
            request.sourceRef = ref;
            request.queueId = id;
            request.onDone = [id](AwardOutcome const& outcome)
            {
                inFlight.erase(id);
                switch (outcome.kind)
                {
                    case AwardOutcome::Kind::Delivered:
                        break; // the award transaction already set 'done'
                    case AwardOutcome::Kind::AlreadyDelivered:
                        MarkDone(id, outcome.awardId);
                        break;
                    case AwardOutcome::Kind::Rejected:
                        MarkFailed(id, outcome.error);
                        break;
                    case AwardOutcome::Kind::Unknown:
                        LOG_WARN("module.bazaar", "Groot Coin: queued award {} left pending: {}", id, outcome.error);
                        break;
                }
            };

            inFlight.insert(id);
            IssueAward(std::move(request));
        }
    }

    namespace Internal
    {
        void UpdateQueue()
        {
            Settings const& config = GetSettings();
            if (!ShouldPollQueue(AwardsAvailable(), config.externalAwardsEnable) || polling)
                return;

            uint64 const now = GameTime::GetGameTimeMS().count();
            if (now < nextPollMs)
                return;
            nextPollMs = now + uint64(QueuePollSeconds(config.queuePollSeconds)) * IN_MILLISECONDS;

            polling = true;
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_QUEUE_PENDING);
            stmt->SetData(0, QUEUE_BATCH);
            AddQueryCallback(CharacterDatabase.AsyncQuery(stmt).WithPreparedCallback([](PreparedQueryResult result)
            {
                polling = false;
                if (!result)
                    return;
                do
                    Process(result->Fetch());
                while (result->NextRow());
            }));
        }

        std::size_t QueuedInFlight()
        {
            return inFlight.size();
        }
    }
}
