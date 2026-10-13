/*
 * The exchange. The database is written first and the player's inventory in
 * memory second, so a definite failure needs no undo at all: nothing in
 * memory was touched, and nothing new was handed out.
 *
 *   1. A plan names every coin stack to debit and the one slot or stack the
 *      tokens go to, by GUID and position. Coins outside the backpack and the
 *      equipped bags are never counted.
 *   2. Stacks with unsaved changes are saved through the ordinary inventory
 *      save first, and that save is waited for.
 *   3. One transaction writes guard rows, the stack changes and the audit row.
 *      A guard row fails its CHECK when the database does not hold exactly
 *      what the plan expects, which rolls the whole transaction back.
 *   4. The map thread waits for the acknowledgement, so no other change to
 *      this player can interleave. Only on success is the plan applied in
 *      memory through the normal item API, with the GUIDs the database holds.
 *   5. A missing acknowledgement is resolved by the exchange id, never by
 *      replaying or compensating.
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
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "WorldSession.h"

#include <chrono>
#include <unordered_map>

namespace GrootCoin
{
    namespace
    {
        constexpr std::chrono::milliseconds SAVE_WAIT{ 2000 };
        constexpr std::chrono::milliseconds COMMIT_WAIT{ 5000 };
        constexpr uint64 RECHECK_MS = 5000;

        struct StackDebit
        {
            ObjectGuid guid;
            uint16 pos = 0;
            uint32 dbBag = 0;
            uint8 slot = 0;
            uint32 before = 0;
            uint32 take = 0;
        };

        struct Plan
        {
            std::string id;
            ObjectGuid player;
            uint32 accountId = 0;
            std::string source;
            uint32 coins = 0;
            uint32 tokens = 0;
            uint32 rate = 0;
            std::vector<StackDebit> debits;
            uint16 tokenPos = 0;
            uint32 tokenDbBag = 0;
            uint8 tokenSlot = 0;
            ObjectGuid tokenStack;
            uint32 tokenBefore = 0;
            Item* newTokenItem = nullptr;
            bool needsSave = false;
        };

        struct QuoteState
        {
            Quote quote;
            ObjectGuid npc;
            uint64 expiresAt = 0;
        };

        struct Pending
        {
            Plan plan;
            TransactionCallback callback;
            bool awaitingCommit = true;
            uint64 nextCheck = 0;
        };

        std::unordered_map<ObjectGuid, QuoteState> quotes;
        std::unordered_map<ObjectGuid, Pending> pending;

        template<class Fn>
        void ForEachCarried(Player* player, Fn&& fn)
        {
            for (uint8 slot = INVENTORY_SLOT_ITEM_START; slot < INVENTORY_SLOT_ITEM_END; ++slot)
                if (Item* item = player->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                    fn(item, uint16(INVENTORY_SLOT_BAG_0) << 8 | slot, 0u, slot);

            for (uint8 bagSlot = INVENTORY_SLOT_BAG_START; bagSlot < INVENTORY_SLOT_BAG_END; ++bagSlot)
                if (Bag* bag = player->GetBagByPos(bagSlot))
                    for (uint32 slot = 0; slot < bag->GetBagSize(); ++slot)
                        if (Item* item = bag->GetItemByPos(uint8(slot)))
                            fn(item, uint16(bagSlot) << 8 | slot, uint32(bag->GetGUID().GetCounter()), uint8(slot));
        }

        // The character_inventory `bag` column holds the container's item GUID.
        bool DatabaseLocation(Player* player, uint16 pos, uint32& dbBag, uint8& slot, bool& containerDirty)
        {
            uint8 const bagSlot = pos >> 8;
            slot = pos & 0xFF;
            containerDirty = false;
            if (bagSlot == INVENTORY_SLOT_BAG_0)
            {
                dbBag = 0;
                return true;
            }

            Bag* bag = player->GetBagByPos(bagSlot);
            if (!bag)
                return false;
            dbBag = bag->GetGUID().GetCounter();
            containerDirty = bag->GetState() != ITEM_UNCHANGED;
            return true;
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

        ExchangeResult BuildPlan(Player* player, uint32 coins, uint32 tokens, uint32 rate, std::string_view source,
            Plan& plan)
        {
            plan = Plan{};
            plan.player = player->GetGUID();
            plan.accountId = player->GetSession()->GetAccountId();
            plan.source = std::string(source);
            plan.coins = coins;
            plan.tokens = tokens;
            plan.rate = rate;

            std::vector<StackDebit> stacks;
            ForEachCarried(player, [&](Item* item, uint16 pos, uint32 dbBag, uint8 slot)
            {
                if (item->GetEntry() != COIN_ITEM)
                    return;
                stacks.push_back({ item->GetGUID(), pos, dbBag, slot, item->GetCount(), 0 });
                if (item->GetState() != ITEM_UNCHANGED)
                    plan.needsSave = true;
            });

            std::sort(stacks.begin(), stacks.end(), [](StackDebit const& a, StackDebit const& b)
            {
                return a.before != b.before ? a.before < b.before : a.guid < b.guid;
            });

            uint32 remaining = coins;
            for (StackDebit& stack : stacks)
            {
                if (!remaining)
                    break;
                stack.take = std::min(stack.before, remaining);
                remaining -= stack.take;
                plan.debits.push_back(stack);
            }
            if (remaining)
                return ExchangeResult::NotEnoughCoins;

            ItemPosCountVec dest;
            if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, BAZAAR_TOKEN_ITEM, tokens) != EQUIP_ERR_OK
                || dest.size() != 1 || dest.front().count != tokens)
                return ExchangeResult::NoSpace;

            plan.tokenPos = dest.front().pos;
            bool containerDirty = false;
            if (!DatabaseLocation(player, plan.tokenPos, plan.tokenDbBag, plan.tokenSlot, containerDirty))
                return ExchangeResult::NoSpace;
            if (containerDirty)
                plan.needsSave = true;

            if (Item* stack = player->GetItemByPos(plan.tokenPos))
            {
                if (stack->GetEntry() != BAZAAR_TOKEN_ITEM)
                    return ExchangeResult::NoSpace;
                plan.tokenStack = stack->GetGUID();
                plan.tokenBefore = stack->GetCount();
                if (stack->GetState() != ITEM_UNCHANGED)
                    plan.needsSave = true;
            }
            return ExchangeResult::Ok;
        }

        // The plan still describes the inventory in memory.
        bool PlanMatches(Player* player, Plan const& plan)
        {
            for (StackDebit const& debit : plan.debits)
            {
                Item* item = player->GetItemByPos(debit.pos);
                if (!item || item->GetGUID() != debit.guid || item->GetCount() != debit.before)
                    return false;
            }

            Item* stack = player->GetItemByPos(plan.tokenPos);
            if (plan.tokenStack)
                return stack && stack->GetGUID() == plan.tokenStack && stack->GetCount() == plan.tokenBefore;
            return !stack;
        }

        void AppendStackGuard(CharacterDatabaseTransaction& trans, Plan const& plan, ObjectGuid item, uint32 entry,
            uint32 before, uint32 after, uint32 dbBag, uint8 slot)
        {
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_EXCHANGE_STACK);
            stmt->SetData(0, plan.id);
            stmt->SetData(1, item.GetCounter());
            stmt->SetData(2, entry);
            stmt->SetData(3, int64(before));
            stmt->SetData(4, item.GetCounter());
            stmt->SetData(5, plan.player.GetCounter());
            stmt->SetData(6, entry);
            stmt->SetData(7, after);
            stmt->SetData(8, item.GetCounter());
            stmt->SetData(9, plan.player.GetCounter());
            stmt->SetData(10, dbBag);
            stmt->SetData(11, slot);
            trans->Append(stmt);
        }

        CharacterDatabaseTransaction BuildTransaction(Player* player, Plan& plan)
        {
            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();

            for (StackDebit const& debit : plan.debits)
                AppendStackGuard(trans, plan, debit.guid, COIN_ITEM, debit.before, debit.before - debit.take,
                    debit.dbBag, debit.slot);

            if (plan.tokenStack)
                AppendStackGuard(trans, plan, plan.tokenStack, BAZAAR_TOKEN_ITEM, plan.tokenBefore,
                    plan.tokenBefore + plan.tokens, plan.tokenDbBag, plan.tokenSlot);
            else
            {
                plan.newTokenItem = Item::CreateItem(BAZAAR_TOKEN_ITEM, plan.tokens, player);
                if (!plan.newTokenItem)
                    return nullptr;

                CharacterDatabasePreparedStatement* stmt =
                    CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_EXCHANGE_NEW_STACK);
                stmt->SetData(0, plan.id);
                stmt->SetData(1, plan.newTokenItem->GetGUID().GetCounter());
                stmt->SetData(2, BAZAAR_TOKEN_ITEM);
                stmt->SetData(3, plan.newTokenItem->GetGUID().GetCounter());
                stmt->SetData(4, plan.tokens);
                stmt->SetData(5, plan.player.GetCounter());
                stmt->SetData(6, plan.tokenDbBag);
                stmt->SetData(7, plan.tokenSlot);
                trans->Append(stmt);
            }

            for (StackDebit const& debit : plan.debits)
            {
                if (debit.take == debit.before)
                {
                    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_ITEM_INSTANCE);
                    stmt->SetData(0, debit.guid.GetCounter());
                    trans->Append(stmt);
                    stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_CHAR_INVENTORY_BY_ITEM);
                    stmt->SetData(0, debit.guid.GetCounter());
                    trans->Append(stmt);
                }
                else
                {
                    CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_GROOTCOIN_STACK_COUNT);
                    stmt->SetData(0, debit.before - debit.take);
                    stmt->SetData(1, debit.guid.GetCounter());
                    trans->Append(stmt);
                }
            }

            if (plan.tokenStack)
            {
                CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_UPD_GROOTCOIN_STACK_COUNT);
                stmt->SetData(0, plan.tokenBefore + plan.tokens);
                stmt->SetData(1, plan.tokenStack.GetCounter());
                trans->Append(stmt);
            }
            else
            {
                plan.newTokenItem->SaveToDB(trans);
                CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_REP_INVENTORY_ITEM);
                stmt->SetData(0, plan.player.GetCounter());
                stmt->SetData(1, plan.tokenDbBag);
                stmt->SetData(2, plan.tokenSlot);
                stmt->SetData(3, plan.newTokenItem->GetGUID().GetCounter());
                trans->Append(stmt);
            }

            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_GROOTCOIN_EXCHANGE);
            stmt->SetData(0, plan.id);
            stmt->SetData(1, plan.accountId);
            stmt->SetData(2, plan.player.GetCounter());
            stmt->SetData(3, COIN_ITEM);
            stmt->SetData(4, BAZAAR_TOKEN_ITEM);
            stmt->SetData(5, plan.coins);
            stmt->SetData(6, plan.tokens);
            stmt->SetData(7, plan.rate);
            stmt->SetData(8, plan.source);
            trans->Append(stmt);
            return trans;
        }

        void Discard(Plan& plan)
        {
            delete plan.newTokenItem;
            plan.newTokenItem = nullptr;
        }

        void Apply(Player* player, Plan& plan)
        {
            for (StackDebit const& debit : plan.debits)
            {
                uint32 take = debit.take;
                player->DestroyItemCount(player->GetItemByPos(debit.pos), take, true);
            }

            Item* tokens = plan.newTokenItem ? plan.newTokenItem
                : Item::CreateItem(BAZAAR_TOKEN_ITEM, plan.tokens, player);
            plan.newTokenItem = nullptr;

            ItemPosCountVec dest;
            dest.emplace_back(plan.tokenPos, plan.tokens);
            if (Item* stored = player->StoreItem(dest, tokens, true))
                player->SendNewItem(stored, plan.tokens, true, false);

            LOG_INFO("module.bazaar", "Groot Coin: exchange {} at {}: character {} (account {}) spent {} coin(s) for "
                "{} Bazaar Token(s) at {} per coin.", plan.id, plan.source, plan.player.GetCounter(), plan.accountId,
                plan.coins, plan.tokens, plan.rate);
        }

        // 1 committed, 0 not committed, empty when the database did not answer.
        Optional<bool> IsCommitted(std::string const& id)
        {
            CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_SEL_GROOTCOIN_EXCHANGE_COMMITTED);
            stmt->SetData(0, id);
            PreparedQueryResult result = CharacterDatabase.Query(stmt);
            if (!result)
                return std::nullopt;
            return result->Fetch()[0].Get<uint64>() != 0;
        }

        // Settles a plan whose transaction finished. The player may be null
        // (logged out); the database then already holds the result.
        ExchangeResult Settle(Player* player, Plan& plan, bool committed)
        {
            if (!committed)
            {
                Optional<bool> const known = IsCommitted(plan.id);
                if (!known)
                    return ExchangeResult::Pending;
                committed = *known;
            }

            if (!committed)
            {
                Discard(plan);
                return ExchangeResult::StorageChanged;
            }

            if (!player)
            {
                Discard(plan);
                return ExchangeResult::Ok;
            }

            if (!PlanMatches(player, plan))
            {
                Internal::RecordReconciliation(Acore::StringFormat("exchange {} committed but character {} changed the "
                    "involved items before it was acknowledged.", plan.id, plan.player.GetCounter()));
                Discard(plan);
                return ExchangeResult::Failed;
            }

            Apply(player, plan);
            return ExchangeResult::Ok;
        }

        bool SaveFirst(Player* player)
        {
            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            player->SaveInventoryAndGoldToDB(trans);
            TransactionCallback callback = CharacterDatabase.AsyncCommitTransaction(trans);
            return callback.m_future.wait_for(SAVE_WAIT) == std::future_status::ready && callback.m_future.get();
        }

        ExchangeResult ExecuteOnce(Player* player, Vendor const& vendor, uint32 coins, uint32 tokens, uint32 rate)
        {
            Plan plan;
            ExchangeResult result = BuildPlan(player, coins, tokens, rate, vendor.source, plan);
            if (result != ExchangeResult::Ok)
                return result;

            // An item marked unchanged may still sit in a save that another database worker has not committed, so
            // the involved stacks are always written again and that save is waited for before the guarded exchange.
            for (StackDebit const& debit : plan.debits)
                if (Item* item = player->GetItemByGuid(debit.guid))
                    item->SetState(ITEM_CHANGED, player);
            if (plan.tokenStack)
                if (Item* item = player->GetItemByGuid(plan.tokenStack))
                    item->SetState(ITEM_CHANGED, player);
            {
                if (!SaveFirst(player))
                    return ExchangeResult::StorageChanged;
                result = BuildPlan(player, coins, tokens, rate, vendor.source, plan);
                if (result != ExchangeResult::Ok)
                    return result;
                if (plan.needsSave)
                    return ExchangeResult::StorageChanged;
            }

            plan.id = NewOperationId();
            CharacterDatabaseTransaction trans = BuildTransaction(player, plan);
            if (!trans)
            {
                Discard(plan);
                return ExchangeResult::Failed;
            }

            TransactionCallback callback = CharacterDatabase.AsyncCommitTransaction(trans);
            if (callback.m_future.wait_for(COMMIT_WAIT) != std::future_status::ready)
            {
                LOG_WARN("module.bazaar", "Groot Coin: exchange {} not acknowledged in time; holding it.", plan.id);
                ObjectGuid const guid = plan.player;
                pending.emplace(guid, Pending{ std::move(plan), std::move(callback), true });
                return ExchangeResult::Pending;
            }

            result = Settle(player, plan, callback.m_future.get());
            if (result == ExchangeResult::Pending)
            {
                ObjectGuid const guid = plan.player;
                pending.emplace(guid, Pending{ std::move(plan), std::move(callback), false,
                    GameTime::GetGameTimeMS().count() + RECHECK_MS });
            }
            return result;
        }

        // A guard row that does not match means the database had not yet stored what the server holds (for example a
        // save still in flight on another database worker, or a deadlock retry). Nothing was spent, so it is tried once
        // more after a fresh save.
        ExchangeResult Execute(Player* player, Vendor const& vendor, uint32 coins, uint32 tokens, uint32 rate)
        {
            ExchangeResult result = ExecuteOnce(player, vendor, coins, tokens, rate);
            if (result == ExchangeResult::StorageChanged)
                result = ExecuteOnce(player, vendor, coins, tokens, rate);
            return result;
        }

        std::string Outcome(ExchangeResult result, Plan const& plan)
        {
            if (result == ExchangeResult::Ok)
                return Acore::StringFormat("Exchange complete: {} Groot Coin(s) for {} Bazaar Tokens.", plan.coins,
                    plan.tokens);
            return Acore::StringFormat("Groot Coin exchange {}: {}", plan.id, Describe(result));
        }
    }

    std::string_view Describe(ExchangeResult result)
    {
        switch (result)
        {
            case ExchangeResult::Ok: return "Done.";
            case ExchangeResult::Disabled: return "The Groot Coin exchange is closed.";
            case ExchangeResult::Busy: return "Your previous exchange is still being processed.";
            case ExchangeResult::InvalidAmount: return "That amount cannot be exchanged.";
            case ExchangeResult::NotEnoughCoins: return "You are not carrying enough Groot Coins.";
            case ExchangeResult::NoSpace: return "You need room in your bags for the Bazaar Tokens.";
            case ExchangeResult::InvalidQuote: return "That offer has expired. Please choose again.";
            case ExchangeResult::NotAtVendor: return "You are too far away.";
            case ExchangeResult::PlayerState: return "You cannot exchange coins right now.";
            case ExchangeResult::StorageChanged: return "Your bags changed while exchanging; nothing was spent. "
                "Please try again.";
            case ExchangeResult::Failed: return "The exchange failed; nothing was spent.";
            case ExchangeResult::Pending: return "The exchange is waiting for confirmation from the server. Nothing "
                "else is needed; you will be told the result.";
        }
        return "";
    }

    uint32 CarriedCoins(Player* player)
    {
        uint32 total = 0;
        ForEachCarried(player, [&](Item* item, uint16, uint32, uint8)
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
        if (pending.contains(player->GetGUID()))
            return ExchangeResult::Busy;
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

        Plan plan;
        result = BuildPlan(player, coins, *tokens, rate, vendor.source, plan);
        if (result != ExchangeResult::Ok)
            return result;

        quote.nonce = 0;
        while (!quote.nonce)
        {
            std::array<uint8, 4> const bytes = Acore::Crypto::GetRandomBytes<4>();
            quote.nonce = uint32(bytes[0]) | uint32(bytes[1]) << 8 | uint32(bytes[2]) << 16 | uint32(bytes[3]) << 24;
        }
        quote.coins = coins;
        quote.tokens = *tokens;
        quote.tokensPerCoin = rate;
        quotes[player->GetGUID()] = { quote, vendor.npc->GetGUID(), GameTime::GetGameTimeMS().count() + QUOTE_LIFETIME_MS };
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
        if (pending.contains(player->GetGUID()))
            return ExchangeResult::Busy;
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
            for (auto it = pending.begin(); it != pending.end();)
            {
                Pending& entry = it->second;
                if (!entry.awaitingCommit && now < entry.nextCheck)
                {
                    ++it;
                    continue;
                }

                bool committed = false;
                if (entry.awaitingCommit)
                {
                    if (entry.callback.m_future.wait_for(std::chrono::seconds(0)) != std::future_status::ready)
                    {
                        ++it;
                        continue;
                    }
                    committed = entry.callback.m_future.get();
                    entry.awaitingCommit = false;
                }

                Player* player = ObjectAccessor::FindPlayer(entry.plan.player);
                ExchangeResult const result = Settle(player, entry.plan, committed);
                if (result == ExchangeResult::Pending)
                {
                    entry.nextCheck = now + RECHECK_MS;
                    ++it;
                    continue;
                }

                if (player)
                    Notify(entry.plan.player, Outcome(result, entry.plan));
                it = pending.erase(it);
            }

            std::erase_if(quotes, [now](auto const& quote) { return quote.second.expiresAt < now; });
        }

        std::size_t PendingExchanges()
        {
            return pending.size();
        }
    }
}
