/*
 * The Ethereal Tool Dispenser: one bag slot that counts as every profession
 * tool at once.
 *
 * It works by item category, not by script. item_template.TotemCategory points
 * at a TotemCategory.dbc row whose mask is the set of tools the item stands in
 * for, and the core asks in Player::HasItemTotemCategory whether some carried
 * item's mask covers the mask the spell requires. The eight tools the
 * description lists are one block of bits; the upgraded variants add rod tiers
 * on top:
 *
 *   195  Ethereal Tool Dispenser        0x1FE000   the 8 tools
 *   196  Ethereal Tool Dispenser I      0x1FE1F0  + Runed Arcanite Rod  0x1F0
 *   197  Ethereal Tool Dispenser II     0x1FEFF0  + Runed Eternium Rod  0xFF0
 *   198  Ethereal Tool Dispenser III    0x1FFFF0  + Runed Titanium Rod  0x1FF0
 *
 * The mask lives in the item row, so a tier cannot be learned in place; that is
 * why Ascension shipped four item ids rather than one item with a growing mask.
 * What all four share is the on-use spell 8263501, "Upgrade your Dispenser!".
 * This script is what reads it: using the Dispenser takes up the trade of the
 * highest Runed Rod the player carries and replaces the item with the variant
 * whose mask covers it. The rod is not consumed - the Dispenser is what has to
 * be kept, and a covered rod can then be sold - which is the point of the item.
 * Nothing ever goes back down a tier.
 *
 * The rod rule is a reconstruction. The client carries no script and no
 * description of the upgrade; what it does carry is the four masks, the four
 * tier names, and that one shared on-use spell, and this is the reading that
 * fits all of them.
 *
 * The crate the Dispenser arrives in is deliberately NOT handled here. It is a
 * cache with exactly one thing in it, so the generic cache script serves it:
 * ScriptName 'item_ethereal_lost_cache' plus one ethereal_bazaar_cache_pool row,
 * both set by data/sql/updates/pending_db_world/rev_20261007_90_ethereal_tool_dispenser_crate.sql.
 */

#include "EtherealBazaar.h"

#include "Bag.h"
#include "Chat.h"
#include "DBCStores.h"
#include "Item.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"

#include <algorithm>
#include <array>
#include <cstddef>
#include <vector>

namespace
{
    // The four Dispensers, weakest first. Their tool categories (195-198) are
    // each the one before plus a rod tier, so the index in this list is also
    // the tier, and "a higher index covers more rods" holds by construction.
    constexpr std::array<uint32, 4> DISPENSER_TIERS = { 8263501, 8263502, 8263503, 8263504 };

    // Every rod in the client's tool categories sits inside this block of bits
    // (Runed Copper Rod 0x10 up to Runed Titanium Rod 0x1FF0), and every one of
    // them carries the Runed Copper Rod bit, because a rod covers the rods
    // below it. So an item is a rod when its own mask stays inside the block
    // and carries that bit - recognised from its category data rather than from
    // a hand-kept list of rod item ids.
    //
    // The two halves are both needed. The shaman totems (0x1 to 0xF) live in
    // the same block but not on the base bit; the tool categories outside the
    // block (Mining Pick 0x40000 and friends) carry no rod bit at all.
    constexpr uint32 ROD_BLOCK = 0x1FF0;
    constexpr uint32 ROD_BASE_BIT = 0x10;

    // The tool categories of everything the player carries that is a rod and
    // nothing else. Equipment and bags, which is where HasItemTotemCategory
    // looks too.
    void CollectCarriedRodCategories(Player* player, std::vector<uint32>& categories)
    {
        auto consider = [&categories](Item* item)
        {
            if (!item)
                return;

            ItemTemplate const* proto = item->GetTemplate();
            if (!proto || !proto->TotemCategory)
                return;

            TotemCategoryEntry const* entry = sTotemCategoryStore.LookupEntry(proto->TotemCategory);
            if (!entry || !entry->categoryMask)
                return;
            if ((entry->categoryMask & ~ROD_BLOCK) != 0)    // stands in for something outside the rods
                return;
            if ((entry->categoryMask & ROD_BASE_BIT) == 0)  // a totem, not a rod
                return;

            categories.push_back(proto->TotemCategory);
        };

        for (uint8 i = EQUIPMENT_SLOT_START; i < INVENTORY_SLOT_ITEM_END; ++i)
            consider(player->GetItemByPos(INVENTORY_SLOT_BAG_0, i));

        for (uint8 i = INVENTORY_SLOT_BAG_START; i < INVENTORY_SLOT_BAG_END; ++i)
            if (Bag* bag = player->GetBagByPos(i))
                for (uint32 j = 0; j < bag->GetBagSize(); ++j)
                    consider(player->GetItemByPos(i, j));
    }

    // The lowest tier that covers one rod, or DISPENSER_TIERS.size() if none
    // does. The core comparison does the work: the Dispenser's own mask has to
    // be a superset of the rod's, and their category types have to match.
    std::size_t LowestTierCovering(Player* player, uint32 rodCategory)
    {
        for (std::size_t tier = 0; tier < DISPENSER_TIERS.size(); ++tier)
            if (ItemTemplate const* proto = sObjectMgr->GetItemTemplate(DISPENSER_TIERS[tier]))
                if (player->IsTotemCategoryCompatiableWith(proto, rodCategory))
                    return tier;

        return DISPENSER_TIERS.size();
    }

    // One line in the middle of the screen as well as in the chat log.
    // SendNotification is the realm's own centered notice (SMSG_NOTIFICATION),
    // which is what the Dispenser's answers use: the player is looking at the
    // middle of the screen when they right-click the item, not at the chat
    // frame. The same sentence goes to both, so the two never disagree.
    void SendNotice(Player* player, std::string const& line)
    {
        if (!player || !player->IsInWorld() || !player->GetSession())
            return;

        std::string const text = std::string("|cffffff00") + line;

        ChatHandler handler(player->GetSession());
        handler.SendNotification(text);
        handler.SendSysMessage(text);
    }
}

class item_ethereal_tool_dispenser : public ItemScript
{
public:
    item_ethereal_tool_dispenser() : ItemScript("item_ethereal_tool_dispenser") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const& /*targets*/) override
    {
        uint32 const current = item->GetEntry();

        auto const held = std::find(DISPENSER_TIERS.begin(), DISPENSER_TIERS.end(), current);
        if (held == DISPENSER_TIERS.end())
            return false;               // not a Dispenser; the core keeps the use

        std::size_t const tier = std::distance(DISPENSER_TIERS.begin(), held);

        std::vector<uint32> rods;
        CollectCarriedRodCategories(player, rods);

        std::size_t target = tier;
        bool coverable = false;
        for (uint32 rodCategory : rods)
            if (std::size_t const covers = LowestTierCovering(player, rodCategory); covers < DISPENSER_TIERS.size())
            {
                coverable = true;
                target = std::max(target, covers);
            }

        if (target == tier)
        {
            // Either the Dispenser already covers what the player carries, or
            // there is nothing among those rods for it to take up. Both answers
            // are said the same way whichever variant was used, so a player who
            // carries the wrong rod is told what the item wants either way.
            if (coverable)
                SendNotice(player, "This Dispenser already covers every Runed Rod you carry.");
            else
                SendNotice(player, "This Dispenser learns the trade of a Runed Rod: carry one and use the Dispenser again.");

            return true;                // handled: the use does not fall through to the spell
        }

        uint32 const upgrade = DISPENSER_TIERS[target];
        ItemTemplate const* upgradeProto = sObjectMgr->GetItemTemplate(upgrade);
        if (!upgradeProto)
            return false;

        // One slot goes and another is taken, but the item has to leave before
        // the replacement can be placed, so ask first and only then destroy.
        ItemPosCountVec dest;
        InventoryResult const check = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, upgrade, 1);
        if (check != EQUIP_ERR_OK)
        {
            player->SendEquipError(check, nullptr, nullptr, upgrade);
            return true;
        }

        player->DestroyItemCount(current, 1, true);
        if (Item* given = player->StoreNewItem(dest, upgrade, true, Item::GenerateItemRandomPropertyId(upgrade)))
            player->SendNewItem(given, 1, true, false);

        SendNotice(player, std::string("The Dispenser takes up the rod's trade and becomes ") +
                           upgradeProto->Name1 + ".");

        LOG_DEBUG("module.bazaar", "Ethereal Bazaar: {} upgraded a tool dispenser from {} to {}.",
                  player->GetName(), current, upgrade);
        return true;
    }
};

void AddEtherealBazaarDispenserScripts()
{
    new item_ethereal_tool_dispenser();
}
