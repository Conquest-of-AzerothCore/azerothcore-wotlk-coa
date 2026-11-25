#include "GrootCoin.h"
#include "GrootCoinInternal.h"

#include "AscensionClientSpellPatches.h"
#include "Chat.h"
#include "Configuration/Config.h"
#include "CryptoRandom.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "EtherealBazaar.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryCallback.h"
#include "AsyncCallbackProcessor.h"

namespace GrootCoin
{
    namespace
    {
        Settings settings;
        std::vector<std::string> failures;
        bool validated = false;
        std::string exchangeBlocked;
        std::vector<std::string> reconciliations;
        QueryCallbackProcessor queryCallbacks;
        AsyncCallbackProcessor<TransactionCallback> transactionCallbacks;

        constexpr char const* TIRAXIS_SCRIPT = "npc_tiraxis";

        void Fail(std::string reason)
        {
            LOG_ERROR("module.bazaar", "Groot Coin: {}", reason);
            failures.push_back(std::move(reason));
        }

        void ValidateCoinTemplate()
        {
            ItemTemplate const* coin = sObjectMgr->GetItemTemplate(COIN_ITEM);
            if (!coin)
            {
                Fail(Acore::StringFormat("item_template {} is missing.", COIN_ITEM));
                return;
            }

            if (coin->Class != ITEM_CLASS_MISC || coin->SubClass != 0)
                Fail(Acore::StringFormat("item {} must be class 15 subclass 0.", COIN_ITEM));
            if (coin->Bonding != BIND_WHEN_PICKED_UP)
                Fail(Acore::StringFormat("item {} must bind on pickup.", COIN_ITEM));
            if (coin->BuyPrice || coin->SellPrice)
                Fail(Acore::StringFormat("item {} must have no buy or sell price.", COIN_ITEM));
            if (coin->GetMaxStackSize() < settings.maxAward)
                Fail(Acore::StringFormat("item {} stacks to {}, below GrootCoin.MaxAward {}.", COIN_ITEM,
                    coin->GetMaxStackSize(), settings.maxAward));
            if (coin->MaxCount || coin->Duration || coin->ItemLimitCategory)
                Fail(Acore::StringFormat("item {} must have no unique limit or duration.", COIN_ITEM));

            ItemEntry const* client = sItemStore.LookupEntry(COIN_ITEM);
            if (!client)
                Fail(Acore::StringFormat("item_dbc has no row for {}; the client cannot show the coin.", COIN_ITEM));
            else if (client->ClassID != coin->Class || client->SubclassID != coin->SubClass
                || client->DisplayInfoID != coin->DisplayInfoID || client->InventoryType != coin->InventoryType)
                Fail(Acore::StringFormat("item_dbc {} does not match item_template.", COIN_ITEM));

            if (!Ascension::ClientItemPatches::Instance().Contains(COIN_ITEM))
                Fail(Acore::StringFormat("item {} is not registered for the client item patch stream.", COIN_ITEM));
        }

        void ValidateTokenTemplate()
        {
            if (BAZAAR_TOKEN_ITEM == COIN_ITEM)
            {
                Fail("the coin and the Bazaar Token share an item id.");
                return;
            }

            ItemTemplate const* token = sObjectMgr->GetItemTemplate(BAZAAR_TOKEN_ITEM);
            if (!token)
            {
                Fail(Acore::StringFormat("Bazaar Token item {} is missing.", BAZAAR_TOKEN_ITEM));
                return;
            }

            if (token->MaxCount)
                Fail(Acore::StringFormat("Bazaar Token {} has a unique limit.", BAZAAR_TOKEN_ITEM));
            if (!IsValidRate(settings.tokensPerCoin, token->GetMaxStackSize()))
                Fail(Acore::StringFormat("GrootCoin.TokensPerCoin {} does not fit a Bazaar Token stack of {}.",
                    settings.tokensPerCoin, token->GetMaxStackSize()));
        }

        void ValidateEnvironment()
        {
            if (!sConfigMgr->GetOption<bool>("EtherealBazaar.Enable", true))
                Fail("EtherealBazaar.Enable is off.");
            if (!sConfigMgr->GetOption<bool>("CoA.SendDisplayPatches", true))
                Fail("CoA.SendDisplayPatches is off, so clients never learn the coin item.");

            CreatureTemplate const* tiraxis = sObjectMgr->GetCreatureTemplate(BAZAAR_NPC_TIRAXIS);
            if (!tiraxis || tiraxis->ScriptID != sObjectMgr->GetScriptId(TIRAXIS_SCRIPT))
                Fail(Acore::StringFormat("creature {} does not use {}.", BAZAAR_NPC_TIRAXIS, TIRAXIS_SCRIPT));

            if (settings.maxAward == 0 || settings.maxAward > COIN_STACK_SIZE)
                Fail(Acore::StringFormat("GrootCoin.MaxAward must be 1 to {}.", COIN_STACK_SIZE));

            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_SCHEMA);
            PreparedQueryResult result = CharacterDatabase.Query(stmt);
            if (!result || result->Fetch()[0].Get<uint64>() != 4)
                Fail("the grootcoin_* audit tables are missing from the characters database.");
        }
    }

    Settings const& GetSettings()
    {
        return settings;
    }

    void LoadSettings()
    {
        settings.enable = sConfigMgr->GetOption<bool>("GrootCoin.Enable", false);
        settings.exchangeEnable = sConfigMgr->GetOption<bool>("GrootCoin.ExchangeEnable", false);
        settings.tokensPerCoin = sConfigMgr->GetOption<uint32>("GrootCoin.TokensPerCoin", DEFAULT_TOKENS_PER_COIN);
        settings.maxAward = sConfigMgr->GetOption<uint32>("GrootCoin.MaxAward", DEFAULT_MAX_AWARD);
        settings.externalAwardsEnable = sConfigMgr->GetOption<bool>("GrootCoin.ExternalAwardsEnable", false);
        settings.queuePollSeconds = QueuePollSeconds(
            sConfigMgr->GetOption<uint32>("GrootCoin.QueuePollInterval", DEFAULT_QUEUE_POLL_SECONDS));
        settings.characterDbWorkers = sConfigMgr->GetOption<uint32>("CharacterDatabase.WorkerThreads",
            REQUIRED_CHARACTER_DB_WORKERS, false);
    }

    void Validate()
    {
        failures.clear();
        exchangeBlocked.clear();
        validated = true;
        if (!settings.enable && !settings.exchangeEnable)
            return;

        ValidateCoinTemplate();
        ValidateTokenTemplate();
        ValidateEnvironment();

        if (settings.exchangeEnable && !ExchangeSafeWithWorkers(settings.characterDbWorkers))
        {
            exchangeBlocked = Acore::StringFormat("CharacterDatabase.WorkerThreads is {}; the exchange needs {}. "
                "GrootCoin.ExchangeEnable is treated as 0.", settings.characterDbWorkers, REQUIRED_CHARACTER_DB_WORKERS);
            LOG_ERROR("module.bazaar", "Groot Coin: {}", exchangeBlocked);
        }

        if (failures.empty())
            LOG_INFO("module.bazaar", "Groot Coin: awards {}, exchange {}, {} tokens per coin, external awards {}.",
                settings.enable ? "on" : "off", ExchangeAvailable() ? "on" : "off", settings.tokensPerCoin,
                ShouldPollQueue(settings.enable, settings.externalAwardsEnable) ? "on" : "off");
        else
            LOG_ERROR("module.bazaar", "Groot Coin: disabled after {} failed startup check(s).", failures.size());
    }

    std::vector<std::string> const& StartupFailures()
    {
        return failures;
    }

    bool AwardsAvailable()
    {
        return validated && settings.enable && failures.empty();
    }

    bool ExchangeAvailable()
    {
        return validated && settings.exchangeEnable && failures.empty() && exchangeBlocked.empty();
    }

    void Update()
    {
        queryCallbacks.ProcessReadyCallbacks();
        transactionCallbacks.ProcessReadyCallbacks();
        Internal::UpdateExchanges();
        Internal::UpdateQueue();
    }

    std::string NewOperationId()
    {
        return FormatUuid(Acore::Crypto::GetRandomBytes<16>());
    }

    void ShowStatus(ChatHandler* handler)
    {
        handler->PSendSysMessage("Groot Coin: awards {}, exchange {}.",
            AwardsAvailable() ? "enabled" : "disabled", ExchangeAvailable() ? "enabled" : "disabled");
        handler->PSendSysMessage("Config: GrootCoin.Enable={} GrootCoin.ExchangeEnable={} TokensPerCoin={} MaxAward={}.",
            settings.enable ? 1 : 0, settings.exchangeEnable ? 1 : 0, settings.tokensPerCoin, settings.maxAward);
        handler->PSendSysMessage("Items: coin {} (display {}), Bazaar Token {}. Client item patch registered: {}.",
            COIN_ITEM, COIN_DISPLAY, BAZAAR_TOKEN_ITEM,
            Ascension::ClientItemPatches::Instance().Contains(COIN_ITEM) ? "yes" : "no");
        handler->PSendSysMessage("External awards (groot_coin_award_queue): {}, polled every {} s.",
            ShouldPollQueue(AwardsAvailable(), settings.externalAwardsEnable) ? "on" : "off", settings.queuePollSeconds);
        handler->PSendSysMessage("Pending: {} award(s) ({} from the queue).", Internal::PendingAwards(),
            Internal::QueuedInFlight());
        if (!exchangeBlocked.empty())
            handler->PSendSysMessage("Exchange blocked: {}", exchangeBlocked);

        for (std::string const& failure : failures)
            handler->PSendSysMessage("Startup check failed: {}", failure);
        for (std::string const& line : reconciliations)
            handler->PSendSysMessage("Needs reconciliation: {}", line);
    }

    void ShowHistory(ChatHandler* handler, ObjectGuid character, std::string const& name, uint32 count)
    {
        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_AWARD_HISTORY);
        stmt->SetData(0, character.GetCounter());
        stmt->SetData(1, count);
        PreparedQueryResult result = CharacterDatabase.Query(stmt);
        if (!result)
        {
            handler->PSendSysMessage("No Groot Coin awards for {}.", name);
            return;
        }

        handler->PSendSysMessage("Groot Coin awards for {} (newest first):", name);
        do
        {
            Field const* fields = result->Fetch();
            std::string const subject = fields[1].IsNull()
                ? Acore::StringFormat("{} {}", fields[5].Get<std::string>(), fields[6].Get<std::string>())
                : Acore::StringFormat("issue #{}", fields[1].Get<uint32>());
            handler->PSendSysMessage("{} | {} | {} coin(s) | {} | by account {}", fields[0].Get<std::string>(), subject,
                fields[2].Get<uint32>(), fields[3].Get<std::string>(), fields[4].Get<uint32>());
        } while (result->NextRow());
    }

    void ShowRecord(ChatHandler* handler, std::string const& id)
    {
        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_AWARD);
        stmt->SetData(0, id);
        if (PreparedQueryResult award = CharacterDatabase.Query(stmt))
        {
            Field const* f = award->Fetch();
            std::string const subject = f[1].IsNull()
                ? Acore::StringFormat("{} {}", f[13].Get<std::string>(), f[14].Get<std::string>())
                : Acore::StringFormat("issue #{}", f[1].Get<uint32>());
            handler->PSendSysMessage("Award {}: {}, {} coin(s), created {}.", f[0].Get<std::string>(), subject,
                f[6].Get<uint32>(), f[9].Get<std::string>());
            handler->PSendSysMessage("Recipient account {} character {}; issued by account {} character {}.",
                f[2].Get<uint32>(), f[3].Get<uint32>(), f[4].Get<uint32>(), f[5].Get<uint32>());
            handler->PSendSysMessage("Reason: {}", f[7].Get<std::string>());
            handler->PSendSysMessage("Attribution: {}", f[8].Get<std::string>());
            if (f[10].IsNull())
                handler->PSendSysMessage("No delivery row.");
            else
                handler->PSendSysMessage("Mail {} carrying coin stack {}: {}.", f[10].Get<uint32>(), f[11].Get<uint32>(),
                    f[12].Get<uint64>() ? "still in the mailbox" : "claimed, returned, deleted or expired");
            return;
        }

        stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_EXCHANGE);
        stmt->SetData(0, id);
        if (PreparedQueryResult exchange = CharacterDatabase.Query(stmt))
        {
            Field const* f = exchange->Fetch();
            handler->PSendSysMessage("Exchange {}: account {} character {} at {}, {} coin(s) -> {} token(s) at {} per coin, {}.",
                f[0].Get<std::string>(), f[1].Get<uint32>(), f[2].Get<uint32>(), f[6].Get<std::string>(),
                f[3].Get<uint32>(), f[4].Get<uint32>(), f[5].Get<uint32>(), f[7].Get<std::string>());
            return;
        }

        handler->PSendSysMessage("No Groot Coin award or exchange {}.", id);
    }

    namespace Internal
    {
        void AddQueryCallback(QueryCallback&& callback)
        {
            queryCallbacks.AddCallback(std::move(callback));
        }

        void AddTransactionCallback(TransactionCallback&& callback)
        {
            transactionCallbacks.AddCallback(std::move(callback));
        }

        void RecordReconciliation(std::string line)
        {
            LOG_ERROR("module.bazaar", "Groot Coin: needs reconciliation: {}", line);
            reconciliations.push_back(std::move(line));
        }

        std::vector<std::string> const& Reconciliations()
        {
            return reconciliations;
        }

        void Notify(ObjectGuid character, std::string const& text)
        {
            if (Player* player = ObjectAccessor::FindPlayer(character))
                ChatHandler(player->GetSession()).SendSysMessage(text);
        }
    }
}
