/*
 * Awards. The coin, its mail and the audit rows are written in one
 * transaction; the receiver's mailbox in memory changes only after the
 * transaction reported success. The unique keys in grootcoin_award are the
 * duplicate guards: (issue, account) for in-game awards and (source,
 * source_ref) for external ones, so two requests for the same thing still pay
 * once. A queued award also marks its groot_coin_award_queue row done inside
 * that transaction.
 */

#include "GrootCoin.h"
#include "GrootCoinInternal.h"

#include "DatabaseEnv.h"
#include "Item.h"
#include "Log.h"
#include "Mail.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "QueryCallback.h"

#include <memory>

namespace GrootCoin
{
    namespace
    {
        std::size_t inFlight = 0;

        struct Delivery
        {
            AwardRequest request;
            uint32 recipientAccountId = 0;
            std::string awardId;
            std::unique_ptr<MailDraft> draft;
            Optional<StagedMail> staged;
            ObjectGuid::LowType coinGuid = 0;
        };

        using DeliveryPtr = std::shared_ptr<Delivery>;
        using Kind = AwardOutcome::Kind;

        bool ByReference(AwardRequest const& request)
        {
            return !request.sourceRef.empty();
        }

        // "issue #12" or "website bug:1234", for messages and logs.
        std::string Subject(AwardRequest const& request)
        {
            if (request.issueNumber)
                return Acore::StringFormat("issue #{}", request.issueNumber);
            return Acore::StringFormat("{} {}", request.source, request.sourceRef);
        }

        void Reply(Delivery const& delivery, std::string const& text)
        {
            Internal::Notify(delivery.request.actor, text);
        }

        // Every path ends here exactly once.
        void Finish(Delivery& delivery, Kind kind, std::string error = {})
        {
            if (delivery.draft)
                delivery.draft->DiscardItems();
            --inFlight;

            if (!error.empty())
                Reply(delivery, "Groot Coin: " + error);

            if (delivery.request.onDone)
            {
                AwardOutcome outcome;
                outcome.kind = kind;
                outcome.awardId = delivery.awardId;
                outcome.error = std::move(error);
                delivery.request.onDone(outcome);
            }
        }

        CharacterDatabasePreparedStatement* KeyLookup(Delivery const& delivery)
        {
            AwardRequest const& request = delivery.request;
            if (ByReference(request))
            {
                CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_AWARD_BY_REF);
                stmt->SetData(0, request.source);
                stmt->SetData(1, request.sourceRef);
                return stmt;
            }

            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_AWARD_BY_KEY);
            stmt->SetData(0, request.issueNumber);
            stmt->SetData(1, delivery.recipientAccountId);
            return stmt;
        }

        // An award already exists under the request's key: the same request
        // paid before, or a conflicting one.
        void ReportExisting(Delivery& delivery, Field const* fields)
        {
            std::string const existingId = fields[1].Get<std::string>();
            uint32 const existingCharacter = fields[2].Get<uint32>();
            uint32 const existingAmount = fields[3].Get<uint32>();
            ExistingAward const existing = ClassifyExisting(true, existingCharacter, existingAmount,
                delivery.request.recipient.GetCounter(), delivery.request.amount);

            delivery.awardId = existingId;
            if (existing == ExistingAward::SameRequest)
            {
                Reply(delivery, Acore::StringFormat("Groot Coin: already awarded for {} as {}; nothing sent.",
                    Subject(delivery.request), existingId));
                Finish(delivery, Kind::AlreadyDelivered);
                return;
            }

            Finish(delivery, Kind::Rejected, Acore::StringFormat("conflict. Award {} for {} already paid {} coin(s) to "
                "character {}; nothing sent.", existingId, Subject(delivery.request), existingAmount, existingCharacter));
        }

        void Publish(Delivery& delivery)
        {
            AwardRequest const& request = delivery.request;
            Player* recipient = ObjectAccessor::FindPlayer(request.recipient);
            delivery.draft->PublishStagedMail(*delivery.staged, recipient);
            delivery.draft.reset();

            LOG_INFO("module.bazaar", "Groot Coin: award {} delivered {} coin(s) for {} to character {} (account {}) "
                "by account {}, mail {}.", delivery.awardId, request.amount, Subject(request),
                request.recipient.GetCounter(), delivery.recipientAccountId, request.actorAccountId,
                delivery.staged->mailId);

            Reply(delivery, Acore::StringFormat("Groot Coin: award {} sent, {} coin(s) for {}.", delivery.awardId,
                request.amount, Subject(request)));
            if (recipient)
                Internal::Notify(request.recipient, request.issueNumber
                    ? Acore::StringFormat("You have been sent {} Groot Coin(s) by mail for helping with issue #{}. "
                        "Thank you!", request.amount, request.issueNumber)
                    : Acore::StringFormat("You have been sent {} Groot Coin(s) by mail: {}. Thank you!", request.amount,
                        request.reason));
        }

        // The commit reported failure. Read the duplicate key before deciding:
        // a concurrent award, our own award after a lost acknowledgement, or a
        // genuine rollback are all possible.
        void ResolveFailedCommit(DeliveryPtr delivery)
        {
            Internal::AddQueryCallback(CharacterDatabase.AsyncQuery(KeyLookup(*delivery)).WithPreparedCallback(
                [delivery](PreparedQueryResult result)
                {
                    if (!result)
                    {
                        Internal::RecordReconciliation(Acore::StringFormat("award {} ({}, account {}): commit outcome "
                            "unknown.", delivery->awardId, Subject(delivery->request), delivery->recipientAccountId));
                        Finish(*delivery, Kind::Unknown, Acore::StringFormat("the database did not confirm award {}. "
                            "Check `.groot inspect {}` before trying again.", delivery->awardId, delivery->awardId));
                        return;
                    }

                    Field const* fields = result->Fetch();
                    if (fields[0].Get<uint64>() && fields[1].Get<std::string>() == delivery->awardId)
                    {
                        Publish(*delivery);
                        Finish(*delivery, Kind::Delivered);
                        return;
                    }

                    if (fields[0].Get<uint64>())
                        ReportExisting(*delivery, fields);
                    else
                        Finish(*delivery, Kind::Unknown, Acore::StringFormat("award {} was rolled back; nothing sent.",
                            delivery->awardId));
                }));
        }

        void Deliver(DeliveryPtr delivery)
        {
            AwardRequest const& request = delivery->request;
            delivery->awardId = NewOperationId();

            Item* coin = Item::CreateItem(COIN_ITEM, request.amount);
            if (!coin)
            {
                Finish(*delivery, Kind::Unknown, "the coin item could not be created; nothing sent.");
                return;
            }

            coin->SetOwnerGUID(request.recipient);
            coin->SetBinding(true);
            delivery->coinGuid = coin->GetGUID().GetCounter();

            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            coin->SaveToDB(trans);

            std::string const body = request.issueNumber
                ? Acore::StringFormat("Thank you for your report on issue #{}. Exchange these coins with Tiraxis for "
                    "Bazaar Tokens. This mail is kept for {} days.", request.issueNumber, MAIL_RETENTION_DAYS)
                : Acore::StringFormat("Thank you: {}. Exchange these coins with Tiraxis for Bazaar Tokens. This mail is "
                    "kept for {} days.", request.reason, MAIL_RETENTION_DAYS);
            delivery->draft = std::make_unique<MailDraft>("Groot Coins", body);
            delivery->draft->AddItem(coin);
            delivery->staged = delivery->draft->StageMailTo(trans, request.recipient.GetCounter(),
                MailSender(MAIL_NORMAL, request.actor.GetCounter(), MAIL_STATIONERY_GM), MAIL_CHECK_MASK_COPIED,
                MAIL_RETENTION_DAYS);
            if (!delivery->staged)
            {
                Finish(*delivery, Kind::Rejected, "a mail script suppressed the delivery; nothing sent.");
                return;
            }

            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_AWARD);
            stmt->SetData(0, delivery->awardId);
            if (request.issueNumber)
                stmt->SetData(1, request.issueNumber);
            else
                stmt->SetData(1, nullptr);
            stmt->SetData(2, delivery->recipientAccountId);
            stmt->SetData(3, request.recipient.GetCounter());
            stmt->SetData(4, request.actorAccountId);
            stmt->SetData(5, request.actor.GetCounter());
            stmt->SetData(6, request.amount);
            stmt->SetData(7, request.reason);
            stmt->SetData(8, request.attributionRef);
            stmt->SetData(9, request.source);
            if (ByReference(request))
                stmt->SetData(10, request.sourceRef);
            else
                stmt->SetData(10, nullptr);
            trans->Append(stmt);

            stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_AWARD_MAIL);
            stmt->SetData(0, delivery->awardId);
            stmt->SetData(1, delivery->staged->mailId);
            stmt->SetData(2, delivery->coinGuid);
            stmt->SetData(3, request.amount);
            trans->Append(stmt);

            if (request.queueId)
            {
                stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_GROOTCOIN_QUEUE_DONE);
                stmt->SetData(0, delivery->awardId);
                stmt->SetData(1, request.queueId);
                trans->Append(stmt);
            }

            TransactionCallback callback = CharacterDatabase.AsyncCommitTransaction(trans);
            callback.AfterComplete([delivery](bool committed)
            {
                if (!committed)
                {
                    ResolveFailedCommit(delivery);
                    return;
                }

                Publish(*delivery);
                Finish(*delivery, Kind::Delivered);
            });
            Internal::AddTransactionCallback(std::move(callback));
        }

        void CheckDuplicate(DeliveryPtr delivery)
        {
            Internal::AddQueryCallback(CharacterDatabase.AsyncQuery(KeyLookup(*delivery)).WithPreparedCallback(
                [delivery](PreparedQueryResult result)
                {
                    if (!result)
                    {
                        Finish(*delivery, Kind::Unknown, "the award lookup failed; nothing sent.");
                        return;
                    }

                    Field const* fields = result->Fetch();
                    if (fields[0].Get<uint64>())
                    {
                        ReportExisting(*delivery, fields);
                        return;
                    }

                    Deliver(delivery);
                }));
        }
    }

    void IssueAward(AwardRequest request)
    {
        auto delivery = std::make_shared<Delivery>();
        delivery->request = std::move(request);
        ++inFlight;

        AwardRequest const& checked = delivery->request;
        if (!AwardsAvailable())
        {
            Finish(*delivery, Kind::Unknown, "awards are disabled; nothing sent.");
            return;
        }
        if (!checked.amount || checked.amount > GetSettings().maxAward || checked.amount > COIN_STACK_SIZE
            || !IsValidAuditText(checked.reason, REASON_MAX) || !IsValidAuditText(checked.attributionRef, ATTRIBUTION_MAX)
            || !IsValidSource(checked.source) || (!checked.issueNumber && !ByReference(checked))
            || (ByReference(checked) && (!IsValidExternalSource(checked.source) || !IsValidSourceRef(checked.sourceRef))))
        {
            Finish(*delivery, Kind::Rejected, "the award request is invalid; nothing sent.");
            return;
        }

        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_RECIPIENT);
        stmt->SetData(0, delivery->request.recipient.GetCounter());
        Internal::AddQueryCallback(CharacterDatabase.AsyncQuery(stmt).WithPreparedCallback(
            [delivery](PreparedQueryResult result)
            {
                if (!result)
                {
                    Finish(*delivery, Kind::Rejected, "that character does not exist or was deleted; nothing sent.");
                    return;
                }

                // Staff may award their own characters; the audit row records the awarding account either way.
                delivery->recipientAccountId = result->Fetch()[0].Get<uint32>();

                CheckDuplicate(delivery);
            }));
    }

    namespace Internal
    {
        std::size_t PendingAwards()
        {
            return inFlight;
        }
    }
}
