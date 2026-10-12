/*
 * Groot Coins.
 *
 * Staff mail a soulbound coin to a player whose bug report helped; the
 * player trades carried coins for Bazaar Tokens. Awards and exchanges are
 * written in one character-database transaction each, together with an
 * immutable audit row, and nothing becomes visible or spendable before that
 * transaction is known to have committed.
 *
 * The exchange is a service, not a part of Tiraxis: any NPC entry point
 * (Tiraxis today, a vanity store later) quotes and confirms through the
 * functions below and receives plain Bazaar Tokens (item 975001) in bags.
 */

#ifndef MOD_ETHEREAL_BAZAAR_GROOT_COIN_H
#define MOD_ETHEREAL_BAZAAR_GROOT_COIN_H

#include "GrootCoinRules.h"
#include "ObjectGuid.h"

#include <string>
#include <vector>

class ChatHandler;
class Creature;
class Player;

namespace GrootCoin
{
    struct Settings
    {
        bool enable = false;
        bool exchangeEnable = false;
        uint32 tokensPerCoin = DEFAULT_TOKENS_PER_COIN;
        uint32 maxAward = DEFAULT_MAX_AWARD;
    };

    Settings const& GetSettings();
    void LoadSettings();

    // Startup validation. A failure turns the feature off with the reasons
    // kept for `.groot status`; existing coins keep their item and display.
    void Validate();
    std::vector<std::string> const& StartupFailures();
    bool AwardsAvailable();
    bool ExchangeAvailable();

    // Processes database callbacks on the world thread.
    void Update();

    // ---- awards ---------------------------------------------------------

    struct AwardRequest
    {
        ObjectGuid recipient;
        uint32 amount = 0;
        uint32 issueNumber = 0;
        std::string reason;
        std::string attributionRef;
        uint32 actorAccountId = 0;
        ObjectGuid actor;
    };

    // Validates the recipient against the database, rejects self-awards and
    // duplicates, then delivers by mail. Replies go to the actor's session
    // if it is still online.
    void IssueAward(AwardRequest request);

    // ---- exchange -------------------------------------------------------

    enum class ExchangeResult : uint8
    {
        Ok,
        Disabled,
        Busy,
        InvalidAmount,
        NotEnoughCoins,
        NoSpace,
        InvalidQuote,
        NotAtVendor,
        PlayerState,
        StorageChanged,
        Failed,
        Pending
    };

    std::string_view Describe(ExchangeResult result);

    struct Quote
    {
        uint32 nonce = 0;
        uint32 coins = 0;
        uint32 tokens = 0;
        uint32 tokensPerCoin = 0;
    };

    // The vendor an exchange happens at. `source` is stored in the audit row.
    struct Vendor
    {
        Creature* npc = nullptr;
        std::string_view source;
    };

    // Coins in the backpack and equipped bags only.
    uint32 CarriedCoins(Player* player);

    // Server-side quote bound to the player, the NPC, the amount and the rate.
    ExchangeResult CreateQuote(Player* player, Vendor const& vendor, uint32 coins, Quote& quote);
    ExchangeResult ConfirmQuote(Player* player, Vendor const& vendor, uint32 nonce);
    void CancelQuote(Player* player);

    // Quote and confirm in one call, for an entry point that already asked
    // the player to confirm in its own UI.
    ExchangeResult TryExchange(Player* player, Vendor const& vendor, uint32 coins);

    // ---- audit ----------------------------------------------------------

    void ShowStatus(ChatHandler* handler);
    void ShowHistory(ChatHandler* handler, ObjectGuid character, std::string const& name, uint32 count);
    void ShowRecord(ChatHandler* handler, std::string const& id);

    std::string NewOperationId();

    // Tiraxis' "Exchange Groot Coins" submenu; gossip actions 9100-9199.
    namespace TiraxisMenu
    {
        bool IsAction(uint32 action);
        void AddEntry(Player* player);
        void OnSelect(Player* player, Creature* creature, uint32 sender, uint32 action);
    }
}

#endif
