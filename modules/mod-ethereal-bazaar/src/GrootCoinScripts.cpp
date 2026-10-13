/*
 * Groot Coin commands, the Tiraxis submenu and the world hooks.
 */

#include "GrootCoin.h"

#include "AscensionClientSpellPatches.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "Creature.h"
#include "Player.h"
#include "RBAC.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"

#include <limits>

namespace GrootCoin::TiraxisMenu
{
    namespace
    {
        enum GrootGossip : uint32
        {
            GOSSIP_GROOT_FIRST = 9100,
            GOSSIP_GROOT_MENU = 9100,
            GOSSIP_GROOT_BALANCE = 9101,
            GOSSIP_GROOT_BUNDLE_1 = 9111,
            GOSSIP_GROOT_BUNDLE_5 = 9115,
            GOSSIP_GROOT_BUNDLE_10 = 9120,
            GOSSIP_GROOT_ALL = 9130,
            GOSSIP_GROOT_CONFIRM = 9150,
            GOSSIP_GROOT_CANCEL = 9151,
            GOSSIP_GROOT_BACK = 9152,
            GOSSIP_GROOT_LAST = 9199
        };

        constexpr uint32 GOSSIP_SENDER_GROOT = 0;
        constexpr uint32 TIRAXIS_TEXT_ID = 900007;
        constexpr std::string_view SOURCE = "tiraxis";

        uint32 BundleCoins(uint32 action)
        {
            switch (action)
            {
                case GOSSIP_GROOT_BUNDLE_1: return 1;
                case GOSSIP_GROOT_BUNDLE_5: return 5;
                case GOSSIP_GROOT_BUNDLE_10: return 10;
                default: return 0;
            }
        }

        uint32 BundleAction(uint32 coins)
        {
            switch (coins)
            {
                case 1: return GOSSIP_GROOT_BUNDLE_1;
                case 5: return GOSSIP_GROOT_BUNDLE_5;
                default: return GOSSIP_GROOT_BUNDLE_10;
            }
        }

        std::string Coins(uint32 coins)
        {
            return Acore::StringFormat("{} Groot Coin{}", coins, coins == 1 ? "" : "s");
        }

        // One option per amount. The client's own pop-up is the only confirmation;
        // the sender carries the token payout the pop-up named, re-checked on OK.
        void AddOffer(Player* player, std::string const& label, uint32 coins, uint32 rate, uint32 action)
        {
            uint64 const tokens = uint64(coins) * rate;
            if (tokens > std::numeric_limits<uint32>::max())
                return;
            AddGossipItemFor(player, GOSSIP_ICON_VENDOR, label, uint32(tokens), action,
                Acore::StringFormat("Exchange {} for {} Bazaar Tokens?", Coins(coins), tokens), 0, false);
        }

        void ShowExchange(Player* player, Creature* creature)
        {
            uint32 const carried = CarriedCoins(player);
            uint32 const rate = GetSettings().tokensPerCoin;

            ClearGossipMenuFor(player);
            for (uint32 const coins : EXCHANGE_BUNDLES)
                if (carried >= coins)
                    AddOffer(player, Acore::StringFormat("Exchange {} for {} Bazaar Tokens.", Coins(coins),
                        uint64(coins) * rate), coins, rate, BundleAction(coins));
            if (carried >= 1)
                AddOffer(player, Acore::StringFormat("Exchange all {} for {} Bazaar Tokens.", Coins(carried),
                    uint64(carried) * rate), carried, rate, GOSSIP_GROOT_ALL);
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Back.", GOSSIP_SENDER_GROOT, GOSSIP_GROOT_BACK);
            player->PlayerTalkClass->SendDynamicGossipMenu(Acore::StringFormat("You carry {} Groot Coin(s). One coin "
                "is worth {} Bazaar Tokens.", carried, rate), creature->GetGUID());
        }

        void Tell(Player* player, std::string_view text)
        {
            ChatHandler(player->GetSession()).SendSysMessage(std::string(text));
        }
    }

    bool IsAction(uint32 action)
    {
        return action >= GOSSIP_GROOT_FIRST && action <= GOSSIP_GROOT_LAST;
    }

    void AddEntry(Player* player)
    {
        if (ExchangeAvailable())
            AddGossipItemFor(player, GOSSIP_ICON_MONEY_BAG, "I want to exchange Groot Coins.", GOSSIP_SENDER_GROOT,
                GOSSIP_GROOT_MENU);
    }

    void OnSelect(Player* player, Creature* creature, uint32 sender, uint32 action)
    {
        Vendor const vendor{ creature, SOURCE };
        switch (action)
        {
            case GOSSIP_GROOT_MENU:
            case GOSSIP_GROOT_BALANCE:
                ShowExchange(player, creature);
                return;
            case GOSSIP_GROOT_CANCEL:
                CancelQuote(player);
                ShowExchange(player, creature);
                return;
            case GOSSIP_GROOT_BACK:
                CancelQuote(player);
                sScriptMgr->OnGossipHello(player, creature);
                return;
            default:
                break;
        }

        CloseGossipMenuFor(player);
        uint32 const coins = action == GOSSIP_GROOT_ALL ? CarriedCoins(player) : BundleCoins(action);
        if (!coins)
            return;

        // The player already accepted the pop-up. Coins carried, rate and payout
        // must still match what it showed; TryExchange re-validates and rolls back.
        ExchangeResult const result = MatchesOffer(coins, GetSettings().tokensPerCoin, sender)
            ? TryExchange(player, vendor, coins) : ExchangeResult::InvalidQuote;
        if (result != ExchangeResult::Ok)
            Tell(player, Describe(result));
    }
}

namespace
{
    using namespace GrootCoin;
    using namespace Acore::ChatCommands;

    constexpr char const* AWARD_USAGE =
        "Usage: .groot award <character> <amount> <issue-number> \"<reason>\" \"<attribution-ref>\"";

    class groot_coin_commands : public CommandScript
    {
    public:
        groot_coin_commands() : CommandScript("groot_coin_commands") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable grootTable =
            {
                { "award",   HandleAward,   rbac::RBAC_PERM_COMMAND_GROOT_AWARD, Console::No },
                { "history", HandleHistory, rbac::RBAC_PERM_COMMAND_GROOT_AUDIT, Console::Yes },
                { "inspect", HandleInspect, rbac::RBAC_PERM_COMMAND_GROOT_AUDIT, Console::Yes },
                { "status",  HandleStatus,  rbac::RBAC_PERM_COMMAND_GROOT_AUDIT, Console::Yes },
            };
            static ChatCommandTable root =
            {
                { "groot", grootTable },
            };
            return root;
        }

        static bool HandleAward(ChatHandler* handler, Optional<PlayerIdentifier> target, Optional<std::string> amountText,
            Optional<std::string> issueText, Optional<QuotedString> reason, Optional<QuotedString> attribution)
        {
            WorldSession* session = handler->GetSession();
            if (!session || !session->GetPlayer())
            {
                handler->SendSysMessage("Groot Coin awards need an in-game staff character.");
                return true;
            }
            if (!AwardsAvailable())
            {
                handler->SendSysMessage("Groot Coin awards are disabled. See .groot status.");
                return true;
            }
            if (session->GetSecurity() < SEC_GAMEMASTER)
            {
                handler->SendSysMessage("Groot Coin awards need Game Master security.");
                return true;
            }
            if (!target || !amountText || !issueText || !reason || !attribution)
            {
                handler->SendSysMessage(AWARD_USAGE);
                return true;
            }

            Optional<uint32> const amount = ParseAwardAmount(*amountText, GetSettings().maxAward);
            Optional<uint32> const issue = ParseIssueNumber(*issueText);
            if (!amount || !issue)
            {
                handler->PSendSysMessage("Amount must be a whole number from 1 to {}, and the issue the plain number of "
                    "a jealous-sound/azerothcore-wotlk-coa issue.", GetSettings().maxAward);
                handler->SendSysMessage(AWARD_USAGE);
                return true;
            }
            if (!IsValidAuditText(*reason, REASON_MAX) || !IsValidAuditText(*attribution, ATTRIBUTION_MAX))
            {
                handler->PSendSysMessage("Reason (up to {} characters) and attribution reference (up to {}) are "
                    "required.", REASON_MAX, ATTRIBUTION_MAX);
                handler->SendSysMessage(AWARD_USAGE);
                return true;
            }

            ObjectGuid const recipient = target->GetGUID();

            AwardRequest request;
            request.recipient = recipient;
            request.amount = *amount;
            request.issueNumber = *issue;
            request.reason = *reason;
            request.attributionRef = *attribution;
            request.actorAccountId = session->GetAccountId();
            request.actor = session->GetPlayer()->GetGUID();
            IssueAward(std::move(request));

            handler->PSendSysMessage("Groot Coin: awarding {} coin(s) to {} for issue #{}...", *amount,
                target->GetName(), *issue);
            return true;
        }

        static bool HandleHistory(ChatHandler* handler, Optional<PlayerIdentifier> target, Optional<std::string> count)
        {
            if (!target)
            {
                handler->PSendSysMessage("Usage: .groot history <character> [count up to {}]", HISTORY_MAX);
                return true;
            }

            Optional<uint32> const limit = ParseHistoryCount(count ? std::string_view(*count) : std::string_view());
            if (!limit)
            {
                handler->PSendSysMessage("Usage: .groot history <character> [count up to {}]", HISTORY_MAX);
                return true;
            }

            ShowHistory(handler, target->GetGUID(), target->GetName(), *limit);
            return true;
        }

        static bool HandleInspect(ChatHandler* handler, Optional<std::string> id)
        {
            if (!id || !IsUuid(*id))
            {
                handler->SendSysMessage("Usage: .groot inspect <award-id or exchange-id>");
                return true;
            }

            ShowRecord(handler, *id);
            return true;
        }

        static bool HandleStatus(ChatHandler* handler)
        {
            ShowStatus(handler);
            return true;
        }
    };

    class groot_coin_world : public WorldScript
    {
    public:
        groot_coin_world() : WorldScript("groot_coin_world") { }

        void OnAfterConfigLoad(bool reload) override
        {
            if (!reload)
                LoadSettings();
        }

        void OnStartup() override
        {
            Validate();
        }

        void OnUpdate(uint32 /*diff*/) override
        {
            Update();
        }
    };
}

void AddGrootCoinScripts()
{
    Ascension::ClientItemPatches::Instance().Register(COIN_ITEM);
    new groot_coin_commands();
    new groot_coin_world();
}
