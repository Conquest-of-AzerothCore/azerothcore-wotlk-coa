/*
 * Awards. The coin, its mail and the audit rows are written in one
 * transaction; the receiver's mailbox in memory changes only after the
 * transaction reported success. The unique (issue, account) key in
 * grootcoin_award is the duplicate guard, so two staff members awarding the
 * same issue at once still pay once.
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

        void Reply(Delivery const& delivery, std::string const& text)
        {
            Internal::Notify(delivery.request.actor, text);
        }

        void Finish(Delivery& delivery)
        {
            if (delivery.draft)
                delivery.draft->DiscardItems();
            --inFlight;
        }

        CharacterDatabasePreparedStatement* KeyLookup(Delivery const& delivery)
        {
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_AWARD_BY_KEY);
            stmt->SetData(0, delivery.request.issueNumber);
            stmt->SetData(1, delivery.recipientAccountId);
            return stmt;
        }

        // An award already exists for this issue and account: report it, or
        // the conflict when its intent differs from the request.
        void ReportExisting(Delivery const& delivery, Field const* fields)
        {
            std::string const existingId = fields[1].Get<std::string>();
            uint32 const existingCharacter = fields[2].Get<uint32>();
            uint32 const existingAmount = fields[3].Get<uint32>();
            if (existingCharacter == delivery.request.recipient.GetCounter() && existingAmount == delivery.request.amount)
                Reply(delivery, Acore::StringFormat("Groot Coin: already awarded for issue #{} as {}; nothing sent.",
                    delivery.request.issueNumber, existingId));
            else
                Reply(delivery, Acore::StringFormat("Groot Coin: conflict. Award {} for issue #{} already paid this "
                    "account {} coin(s) on character {}; nothing sent.", existingId, delivery.request.issueNumber,
                    existingAmount, existingCharacter));
        }

        void Publish(Delivery& delivery)
        {
            Player* recipient = ObjectAccessor::FindPlayer(delivery.request.recipient);
            delivery.draft->PublishStagedMail(*delivery.staged, recipient);
            delivery.draft.reset();

            LOG_INFO("module.bazaar", "Groot Coin: award {} delivered {} coin(s) for issue #{} to character {} "
                "(account {}) by account {}, mail {}.", delivery.awardId, delivery.request.amount,
                delivery.request.issueNumber, delivery.request.recipient.GetCounter(), delivery.recipientAccountId,
                delivery.request.actorAccountId, delivery.staged->mailId);

            Reply(delivery, Acore::StringFormat("Groot Coin: award {} sent, {} coin(s) for issue #{}.",
                delivery.awardId, delivery.request.amount, delivery.request.issueNumber));
            if (recipient)
                Internal::Notify(delivery.request.recipient, Acore::StringFormat(
                    "You have been sent {} Groot Coin(s) by mail for helping with issue #{}. Thank you!",
                    delivery.request.amount, delivery.request.issueNumber));
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
                        Internal::RecordReconciliation(Acore::StringFormat("award {} (issue #{}, account {}): commit "
                            "outcome unknown.", delivery->awardId, delivery->request.issueNumber,
                            delivery->recipientAccountId));
                        Reply(*delivery, Acore::StringFormat("Groot Coin: the database did not confirm award {}. "
                            "Check `.groot inspect {}` before trying again.", delivery->awardId, delivery->awardId));
                        Finish(*delivery);
                        return;
                    }

                    Field const* fields = result->Fetch();
                    if (fields[0].Get<uint64>() && fields[1].Get<std::string>() == delivery->awardId)
                    {
                        Publish(*delivery);
                        Finish(*delivery);
                        return;
                    }

                    if (fields[0].Get<uint64>())
                        ReportExisting(*delivery, fields);
                    else
                        Reply(*delivery, Acore::StringFormat("Groot Coin: award {} was rolled back; nothing sent.",
                            delivery->awardId));
                    Finish(*delivery);
                }));
        }

        void Deliver(DeliveryPtr delivery)
        {
            AwardRequest const& request = delivery->request;
            delivery->awardId = NewOperationId();

            Item* coin = Item::CreateItem(COIN_ITEM, request.amount);
            if (!coin)
            {
                Reply(*delivery, "Groot Coin: the coin item could not be created; nothing sent.");
                Finish(*delivery);
                return;
            }

            coin->SetOwnerGUID(request.recipient);
            coin->SetBinding(true);
            delivery->coinGuid = coin->GetGUID().GetCounter();

            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            coin->SaveToDB(trans);

            delivery->draft = std::make_unique<MailDraft>("Groot Coins",
                Acore::StringFormat("Thank you for your report on issue #{}. Exchange these coins with Tiraxis for "
                    "Bazaar Tokens. This mail is kept for {} days.", request.issueNumber, MAIL_RETENTION_DAYS));
            delivery->draft->AddItem(coin);
            delivery->staged = delivery->draft->StageMailTo(trans, request.recipient.GetCounter(),
                MailSender(MAIL_NORMAL, request.actor.GetCounter(), MAIL_STATIONERY_GM), MAIL_CHECK_MASK_COPIED,
                MAIL_RETENTION_DAYS);
            if (!delivery->staged)
            {
                Reply(*delivery, "Groot Coin: a mail script suppressed the delivery; nothing sent.");
                Finish(*delivery);
                return;
            }

            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_AWARD);
            stmt->SetData(0, delivery->awardId);
            stmt->SetData(1, request.issueNumber);
            stmt->SetData(2, delivery->recipientAccountId);
            stmt->SetData(3, request.recipient.GetCounter());
            stmt->SetData(4, request.actorAccountId);
            stmt->SetData(5, request.actor.GetCounter());
            stmt->SetData(6, request.amount);
            stmt->SetData(7, request.reason);
            stmt->SetData(8, request.attributionRef);
            trans->Append(stmt);

            stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_AWARD_MAIL);
            stmt->SetData(0, delivery->awardId);
            stmt->SetData(1, delivery->staged->mailId);
            stmt->SetData(2, delivery->coinGuid);
            stmt->SetData(3, request.amount);
            trans->Append(stmt);

            TransactionCallback callback = CharacterDatabase.AsyncCommitTransaction(trans);
            callback.AfterComplete([delivery](bool committed)
            {
                if (!committed)
                {
                    ResolveFailedCommit(delivery);
                    return;
                }

                Publish(*delivery);
                Finish(*delivery);
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
                        Reply(*delivery, "Groot Coin: the award lookup failed; nothing sent.");
                        Finish(*delivery);
                        return;
                    }

                    Field const* fields = result->Fetch();
                    if (fields[0].Get<uint64>())
                    {
                        ReportExisting(*delivery, fields);
                        Finish(*delivery);
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

        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_RECIPIENT);
        stmt->SetData(0, delivery->request.recipient.GetCounter());
        Internal::AddQueryCallback(CharacterDatabase.AsyncQuery(stmt).WithPreparedCallback(
            [delivery](PreparedQueryResult result)
            {
                if (!result)
                {
                    Reply(*delivery, "Groot Coin: that character does not exist or was deleted; nothing sent.");
                    Finish(*delivery);
                    return;
                }

                delivery->recipientAccountId = result->Fetch()[0].Get<uint32>();
                if (delivery->recipientAccountId == delivery->request.actorAccountId)
                {
                    Reply(*delivery, "Groot Coin: you cannot award your own account; nothing sent.");
                    Finish(*delivery);
                    return;
                }

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
