/*
 * The exchange. It is an ordinary inventory change, made the way a vendor
 * purchase is made, plus one audit row:
 *
 *   1. Every check runs first: the player, the vendor, the coins carried in the
 *      backpack and equipped bags (bank, mail and the rest never count) and one
 *      slot or stack for the tokens. Nothing is touched if any check fails.
 *   2. The tokens are stored, then the planned coin stacks are destroyed,
 *      through the normal item API on the map thread. Storing comes first
 *      because it is the only step that can fail; it was checked a moment
 *      earlier with the same inventory, and if it still fails no coin is
 *      touched.
 *   3. The player's inventory save and the audit row go into one transaction
 *      on the character database queue. The database therefore holds either
 *      the old inventory without the audit row, or the new inventory with it.
 *
 * Nothing waits for the database and nothing is pending: the memory state is
 * authoritative at once, like any vendor purchase, so moving items, logging
 * out or a later save can only write the new state. That relies on saves for
 * one character committing in the order they were queued, which holds only
 * with CharacterDatabase.WorkerThreads = 1; with more workers the exchange
 * refuses to start (see Validate in GrootCoin.cpp).
 */

#include "GrootCoin.h"
#include "GrootCoinInternal.h"

#include "Bag.h"
#include "Creature.h"
#include "CryptoRandom.h"
#include "DatabaseEnv.h"
#include "EtherealBazaar.h"
#include "GameTime.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "WorldSession.h"

#include <unordered_map>

namespace GrootCoin
{
    namespace
    {
        struct QuoteState
        {
            Quote quote;
            ObjectGuid npc;
            uint64 expiresAt = 0;
        };

        std::unordered_map<ObjectGuid, QuoteState> quotes;

        template<class Fn>
        void ForEachCarried(Player* player, Fn&& fn)
        {
            for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
                if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    fn(item);

            for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
                if (Bag* bag = player->GetBagByPos(bagSlot))
                    for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot)
                        if (Item* item = bag->GetItemByPos(uint8(slot)))
                            fn(item);
        }

        uint32 TokenStackSize()
        {
            ItemTemplate const* token = sObjectMgr->GetItemTemplate(BAZAAR_TOKEN_ITEM);
            return token ? token->GetMaxStackSize() : 0;
        }

        ExchangeResult CheckPlayer(Player* player)
        {
            if (!player || !player->IsInWorld() || !player->IsAlive() || player->IsBeingTeleported()
                || player->GetTradeData() || player->IsInCombat() || player->GetSession()->PlayerLogout())
                return ExchangeResult::PlayerState;
            return ExchangeResult::Ok;
        }

        ExchangeResult CheckVendor(Player* player, Vendor const& vendor)
        {
            if (!vendor.npc || vendor.source.empty() || !vendor.npc->IsInWorld() || !player->InSamePhase(vendor.npc)
                || player->GetNPCIfCanInteractWith(vendor.npc->GetGUID(), UNIT_NPC_FLAG_NONE) != vendor.npc)
                return ExchangeResult::NotAtVendor;
            return ExchangeResult::Ok;
        }

        // The coin stacks to debit (smallest first, see PlanDebits) and how
        // many coins each one gives.
        bool PlanCoins(Player* player, uint32 coins, std::vector<std::pair<Item*, uint32>>& debits)
        {
            std::vector<Item*> stacks;
            ForEachCarried(player, [&](Item* item)
            {
                if (item->GetEntry() == COIN_ITEM)
                    stacks.push_back(item);
            });

            std::vector<uint32_t> counts;
            counts.reserve(stacks.size());
            for (Item* item : stacks)
                counts.push_back(item->GetCount());

            std::vector<uint32_t> const takes = PlanDebits(counts, coins);
            if (takes.empty())
                return false;

            debits.clear();
            for (std::size_t i = 0; i < stacks.size(); ++i)
                if (takes[i])
                    debits.emplace_back(stacks[i], takes[i]);
            return true;
        }

        ExchangeResult Execute(Player* player, Vendor const& vendor, uint32 coins, uint32 tokens, uint32 rate)
        {
            std::vector<std::pair<Item*, uint32>> debits;
            if (!PlanCoins(player, coins, debits))
                return ExchangeResult::NotEnoughCoins;

            ItemPosCountVec dest;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, BAZAAR_TOKEN_ITEM, tokens) != EQUIP_ERR_OK)
                return ExchangeResult::NoSpace;

            Item* stored = player->StoreNewItem(dest, BAZAAR_TOKEN_ITEM, true);
            if (!stored)
                return ExchangeResult::Failed;

            for (auto& [item, take] : debits)
                player->DestroyItemCount(item, take, true);

            std::string const id = NewOperationId();
            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            player->SaveInventoryAndGoldToDB(trans);
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_EXCHANGE);
            stmt->SetData(0, id);
            stmt->SetData(1, player->GetSession()->GetAccountId());
            stmt->SetData(2, player->GetGUID().GetCounter());
            stmt->SetData(3, COIN_ITEM);
            stmt->SetData(4, BAZAAR_TOKEN_ITEM);
            stmt->SetData(5, coins);
            stmt->SetData(6, tokens);
            stmt->SetData(7, rate);
            stmt->SetData(8, std::string(vendor.source));
            trans->Append(stmt);
            CharacterDatabase.CommitTransaction(trans);

            player->SendNewItem(stored, tokens, true, false);
            LOG_INFO("module.bazaar", "Groot Coin: exchange {} at {}: character {} (account {}) spent {} coin(s) for "
                "{} Bazaar Token(s) at {} per coin.", id, vendor.source, player->GetGUID().GetCounter(),
                player->GetSession()->GetAccountId(), coins, tokens, rate);
            return ExchangeResult::Ok;
        }
    }

    std::string_view Describe(ExchangeResult result)
    {
        switch (result)
        {
            case ExchangeResult::Ok: return "Done.";
            case ExchangeResult::Disabled: return "The Groot Coin exchange is closed.";
            case ExchangeResult::InvalidAmount: return "That amount cannot be exchanged.";
            case ExchangeResult::NotEnoughCoins: return "You are not carrying enough Groot Coins.";
            case ExchangeResult::NoSpace: return "You need room in your bags for the Bazaar Tokens.";
            case ExchangeResult::InvalidQuote: return "That offer has expired. Please choose again.";
            case ExchangeResult::NotAtVendor: return "You are too far away.";
            case ExchangeResult::PlayerState: return "You cannot exchange coins right now.";
            case ExchangeResult::Failed: return "The exchange failed; nothing was spent.";
        }
        return "";
    }

    uint32 CarriedCoins(Player* player)
    {
        uint32 total = 0;
        ForEachCarried(player, [&](Item* item)
        {
            if (item->GetEntry() == COIN_ITEM)
                total += item->GetCount();
        });
        return total;
    }

    ExchangeResult CreateQuote(Player* player, Vendor const& vendor, uint32 coins, Quote& quote)
    {
        if (!ExchangeAvailable())
            return ExchangeResult::Disabled;
        if (!IsExchangeAmount(coins, CarriedCoins(player)))
            return ExchangeResult::InvalidAmount;

        ExchangeResult result = CheckPlayer(player);
        if (result == ExchangeResult::Ok)
            result = CheckVendor(player, vendor);
        if (result != ExchangeResult::Ok)
            return result;

        uint32 const rate = GetSettings().tokensPerCoin;
        Optional<uint32> const tokens = TokensFor(coins, rate, TokenStackSize());
        if (!tokens)
            return ExchangeResult::InvalidAmount;
        if (CarriedCoins(player) < coins)
            return ExchangeResult::NotEnoughCoins;

        quote.nonce = 0;
        while (!quote.nonce)
        {
            std::array<uint8, 4> const bytes = Acore::Crypto::GetRandomBytes<4>();
            quote.nonce = uint32(bytes[0]) | uint32(bytes[1]) << 8 | uint32(bytes[2]) << 16 | uint32(bytes[3]) << 24;
        }
        quote.coins = coins;
        quote.tokens = *tokens;
        quote.tokensPerCoin = rate;
        quotes[player->GetGUID()] = { quote, vendor.npc->GetGUID(), uint64(GameTime::GetGameTimeMS().count()) + QUOTE_LIFETIME_MS };
        return ExchangeResult::Ok;
    }

    void CancelQuote(Player* player)
    {
        quotes.erase(player->GetGUID());
    }

    ExchangeResult ConfirmQuote(Player* player, Vendor const& vendor, uint32 nonce)
    {
        auto const found = quotes.find(player->GetGUID());
        if (found == quotes.end())
            return ExchangeResult::InvalidQuote;

        QuoteState const state = found->second;
        quotes.erase(found);

        if (!ExchangeAvailable())
            return ExchangeResult::Disabled;
        if (!nonce || state.quote.nonce != nonce || !vendor.npc || state.npc != vendor.npc->GetGUID()
            || GameTime::GetGameTimeMS().count() > state.expiresAt
            || state.quote.tokensPerCoin != GetSettings().tokensPerCoin)
            return ExchangeResult::InvalidQuote;

        ExchangeResult result = CheckPlayer(player);
        if (result == ExchangeResult::Ok)
            result = CheckVendor(player, vendor);
        if (result != ExchangeResult::Ok)
            return result;

        Optional<uint32> const tokens = TokensFor(state.quote.coins, state.quote.tokensPerCoin, TokenStackSize());
        if (!tokens || *tokens != state.quote.tokens)
            return ExchangeResult::InvalidQuote;

        return Execute(player, vendor, state.quote.coins, *tokens, state.quote.tokensPerCoin);
    }

    ExchangeResult TryExchange(Player* player, Vendor const& vendor, uint32 coins)
    {
        Quote quote;
        ExchangeResult const result = CreateQuote(player, vendor, coins, quote);
        if (result != ExchangeResult::Ok)
            return result;
        return ConfirmQuote(player, vendor, quote.nonce);
    }

    namespace Internal
    {
        void UpdateExchanges()
        {
            uint64 const now = GameTime::GetGameTimeMS().count();
            std::erase_if(quotes, [now](auto const& quote) { return quote.second.expiresAt < now; });
        }
    }
}
