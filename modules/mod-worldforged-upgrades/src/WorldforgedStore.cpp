/*
 * The custom-store protocol, server side.
 *
 * Six opcodes are involved and all six names are the client's own, read out of
 * the handler table in Extensions.dll:
 *
 *   SMSG_OPEN_CUSTOM_STORE   0x073E  uint32 storeID
 *   CMSG_QUERY_CUSTOM_STORE  0x06B9  uint32 storeID
 *   SMSG_QUERY_..._RESULT    0x06BA  cstring result, uint32 count, count * 64
 *   CMSG_PURCHASE_..._ITEM   0x06BB  uint32 recordKey, uint32 quantity
 *   SMSG_PURCHASE_..._RESULT 0x06BC  cstring result
 *
 * The answer carries no store id. It does not need one: the client asked, and
 * it remembers what it asked for. `CustomVendorMixin:QUERY_CUSTOM_STORE_RESULT`
 * takes exactly one argument, the result string.
 */

#include "WorldforgedUpgrades.h"

#include "AscensionCompatOpcodes.h"
#include "AscensionItemScaling.h"

#include "Config.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <string>
#include <unordered_set>

namespace
{
    std::unordered_map<uint32, Worldforged::Recipe> g_recipes;
    std::unordered_map<uint32, std::vector<Worldforged::Recipe const*>> g_byStore;
    std::vector<Worldforged::Recipe const*> const g_empty;
    std::unordered_set<uint32> g_unlockCreatures;

    /// Multiplies every stored cost. The stored numbers are computed rather
    /// than recovered, so a server wants one knob to move them all at once
    /// without regenerating the table.
    float CostFactor()
    {
        return sConfigMgr->GetOption<float>("Worldforged.CostFactor", 1.0f);
    }

    uint32 CostOf(Worldforged::Recipe const& recipe)
    {
        float const scaled = float(recipe.cost) * CostFactor();
        return scaled < 1.0f ? 1u : uint32(scaled + 0.5f);
    }

    /// One 64-byte store record.
    ///
    /// The field order is not guessed. `CustomVendorItemMixin:Update` unpacks
    /// C_CustomStore.GetCustomStoreItemInfo as
    ///
    ///     itemID, moneyCost, requiredItems, requiredItemCosts,
    ///     requiredGameEvent, requiredAchievement
    ///
    /// and the handler reads them at these offsets:
    ///
    ///     0x00  record key, sent back on purchase
    ///     0x04  store/group value, meaning not fully proven - kept at the
    ///           store id, which is what makes the client's own grouping work
    ///     0x08  the item handed out
    ///     0x0C  money cost, unused here
    ///     0x10  five required item ids
    ///     0x24  five required amounts
    ///     0x38  required game event
    ///     0x3C  required achievement
    void BuildStoreRecord(ByteBuffer& out, Worldforged::Recipe const& recipe)
    {
        std::size_t const start = out.wpos();

        out << uint32(recipe.key);
        out << uint32(recipe.store);
        out << uint32(recipe.targetItem);
        out << uint32(0);                       // money cost

        uint32 items[5] = { recipe.baseItem, Worldforged::CURRENCY_ITEM, 0, 0, 0 };
        uint32 counts[5] = { 1, CostOf(recipe), 0, 0, 0 };
        for (uint32 id : items)
            out << id;
        for (uint32 n : counts)
            out << n;

        out << uint32(0);                       // required game event
        out << uint32(0);                       // required achievement

        // A short record would slide every following entry along by the
        // difference, and the client would read nonsense without complaining.
        ASSERT(out.wpos() - start == Worldforged::RECORD_SIZE);
    }

    void SendQueryResult(WorldSession* session, char const* result,
                         std::vector<Worldforged::Recipe const*> const& recipes)
    {
        WorldPacket packet(Worldforged::SMSG_QUERY_CUSTOM_STORE_RESULT,
                           32 + recipes.size() * Worldforged::RECORD_SIZE);
        packet << result;
        packet << uint32(recipes.size());
        for (Worldforged::Recipe const* recipe : recipes)
            BuildStoreRecord(packet, *recipe);

        session->SendPacket(&packet);
    }

    void SendPurchaseResult(WorldSession* session, char const* result)
    {
        WorldPacket packet(Worldforged::SMSG_PURCHASE_CUSTOM_STORE_ITEM_RESULT, 32);
        packet << result;
        session->SendPacket(&packet);
    }

    bool HandleQuery(WorldSession* session, WorldPacket const& packet)
    {
        Player* player = session->GetPlayer();
        if (!player)
            return false;

        WorldPacket read(packet);
        uint32 store = 0;
        read >> store;

        if (store != Worldforged::STORE_WEAPONS && store != Worldforged::STORE_ARMOUR)
            return false;   // not ours; let the generic consumer log it

        // Only what the player can actually act on. The full list is 651 or
        // 1087 rows, and a player who owns three of them should not have to
        // search a thousand entries for the three that mean anything.
        std::vector<Worldforged::Recipe const*> offer;
        for (Worldforged::Recipe const* recipe : Worldforged::RecipesOfStore(store))
            if (player->HasItemCount(recipe->baseItem, 1, true))
                offer.push_back(recipe);

        SendQueryResult(session, Worldforged::RESULT_QUERY_OK, offer);

        LOG_DEBUG("module.worldforged", "Worldforged: sent store {} to {} with {} of {} rows.",
                  store, player->GetName(), offer.size(),
                  Worldforged::RecipesOfStore(store).size());
        return true;
    }

    bool HandlePurchase(WorldSession* session, WorldPacket const& packet)
    {
        Player* player = session->GetPlayer();
        if (!player)
            return false;

        WorldPacket read(packet);
        uint32 key = 0;
        uint32 quantity = 0;
        read >> key >> quantity;

        auto const it = Worldforged::Recipes().find(key);
        if (it == Worldforged::Recipes().end())
            return false;

        Worldforged::Recipe const& recipe = it->second;
        uint32 const cost = CostOf(recipe);

        if (!player->HasItemCount(recipe.baseItem, 1, true))
        {
            SendPurchaseResult(session, "You no longer carry the item to upgrade.");
            return true;
        }

        if (!Worldforged::IsUnlocked(session->GetAccountId(), recipe.unlockCreature))
        {
            CreatureTemplate const* boss = sObjectMgr->GetCreatureTemplate(recipe.unlockCreature);
            std::string const message = Acore::StringFormat("Defeat {} to unlock this upgrade for your account.",
                                                            boss ? boss->Name : "the raid's last boss");
            SendPurchaseResult(session, message.c_str());
            return true;
        }

        if (!player->HasItemCount(Worldforged::CURRENCY_ITEM, cost, true))
        {
            SendPurchaseResult(session, "You do not have enough Runes of Ascension.");
            return true;
        }

        // The base item frees its slot only after it is destroyed, so the check
        // has to happen before anything is taken away.
        ItemPosCountVec destination;
        InventoryResult const fits =
            player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, recipe.targetItem, 1);
        if (fits != EQUIP_ERR_OK)
        {
            player->SendEquipError(fits, nullptr, nullptr, recipe.targetItem);
            SendPurchaseResult(session, "You have no room for the upgraded item.");
            return true;
        }

        player->DestroyItemCount(recipe.baseItem, 1, true);
        player->DestroyItemCount(Worldforged::CURRENCY_ITEM, cost, true);

        if (Item* given = player->StoreNewItem(destination, recipe.targetItem, true,
                                               Item::GenerateItemRandomPropertyId(recipe.targetItem)))
            player->SendNewItem(given, 1, true, false);

        SendPurchaseResult(session, Worldforged::RESULT_PURCHASE_OK);

        LOG_INFO("module.worldforged",
                 "Worldforged: {} upgraded item {} to {} for {} runes.",
                 player->GetName(), recipe.baseItem, recipe.targetItem, cost);

        (void)quantity;   // one upgrade per purchase; the client never sends more
        return true;
    }
}

namespace Worldforged
{
    std::unordered_map<uint32, Recipe> const& Recipes()
    {
        return g_recipes;
    }

    std::vector<Recipe const*> const& RecipesOfStore(uint32 store)
    {
        auto const it = g_byStore.find(store);
        return it == g_byStore.end() ? g_empty : it->second;
    }

    void LoadRecipes()
    {
        g_recipes.clear();
        g_byStore.clear();
        g_unlockCreatures.clear();

        QueryResult result = WorldDatabase.Query(
            "SELECT id, store, base_item, target_item, cost, unlock_creature FROM worldforged_upgrade ORDER BY id");
        if (!result)
        {
            LOG_WARN("module.worldforged", "Worldforged: no upgrade recipes defined.");
            return;
        }

        uint32 skipped = 0;
        do
        {
            Field* field = result->Fetch();
            Recipe recipe;
            recipe.key = field[0].Get<uint32>();
            recipe.store = field[1].Get<uint8>();
            recipe.baseItem = field[2].Get<uint32>();
            recipe.targetItem = field[3].Get<uint32>();
            recipe.cost = field[4].Get<uint32>();
            recipe.unlockCreature = field[5].Get<uint32>();

            if (!sObjectMgr->GetItemTemplate(recipe.baseItem) ||
                !sObjectMgr->GetItemTemplate(recipe.targetItem))
            {
                ++skipped;
                continue;
            }

            auto const& stored = g_recipes.emplace(recipe.key, recipe).first->second;
            g_byStore[recipe.store].push_back(&stored);
        } while (result->NextRow());

        std::unordered_set<uint32> upgradeItems;
        for (auto const& [key, recipe] : g_recipes)
        {
            upgradeItems.insert(recipe.baseItem);
            upgradeItems.insert(recipe.targetItem);
            if (recipe.unlockCreature)
                g_unlockCreatures.insert(recipe.unlockCreature);
        }
        ItemScaling::SetUnliftableEntries(std::move(upgradeItems));

        LOG_INFO("module.worldforged",
                 "Worldforged: {} upgrades loaded, {} weapons and {} armour{}.",
                 g_recipes.size(), RecipesOfStore(STORE_WEAPONS).size(),
                 RecipesOfStore(STORE_ARMOUR).size(),
                 skipped ? Acore::StringFormat(", {} skipped as unknown", skipped) : "");
    }

    bool IsUnlockCreature(uint32 creature)
    {
        return g_unlockCreatures.contains(creature);
    }

    void OpenStore(Player* player, uint32 store)
    {
        WorldPacket packet(SMSG_OPEN_CUSTOM_STORE, 4);
        packet << uint32(store);
        player->GetSession()->SendPacket(&packet);
    }
}

class worldforged_world : public WorldScript
{
public:
    worldforged_world() : WorldScript("worldforged_world") { }

    void OnStartup() override { Worldforged::LoadRecipes(); }
};

void AddWorldforgedStoreScripts()
{
    // These opcodes belong to this module; the compat consumer hands over
    // anything claimed here instead of swallowing it.
    AscensionCompatOpcodes::Claim(Worldforged::CMSG_QUERY_CUSTOM_STORE, &HandleQuery);
    AscensionCompatOpcodes::Claim(Worldforged::CMSG_PURCHASE_CUSTOM_STORE_ITEM, &HandlePurchase);

    new worldforged_world();
}
