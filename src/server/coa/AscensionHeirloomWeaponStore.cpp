/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCompatOpcodes.h"

#include "../../../modules/mod-worldforged-upgrades/src/WorldforgedUpgrades.h"

#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>

namespace
{
constexpr uint32 STORE_HEIRLOOM_WEAPONS = 7;
constexpr uint32 HEIRLOOM_WEAPON_TOKEN = 414010;
constexpr uint32 TOKENS_PER_WEAPON = 1;

constexpr std::array<uint32, 23> HEIRLOOM_WEAPONS = {
    1518202, 1518203, 1542943, 1642846, 1642847, 1642902, 1642943, 1642944, 1642945, 1642946, 1642947,
    1642948, 1642999, 1644091, 1644092, 1644093, 1644094, 1644095, 1644096, 1648716, 1648718, 3142943,
    3148335,
};

bool IsHeirloomWeapon(uint32 entry)
{
    return std::ranges::find(HEIRLOOM_WEAPONS, entry) != HEIRLOOM_WEAPONS.end() &&
        sObjectMgr->GetItemTemplate(entry) != nullptr;
}

void BuildStoreRecord(ByteBuffer& out, uint32 weapon)
{
    std::size_t const start = out.wpos();

    out << uint32(weapon);
    out << uint32(STORE_HEIRLOOM_WEAPONS);
    out << uint32(weapon);
    out << uint32(0);

    uint32 items[5] = { HEIRLOOM_WEAPON_TOKEN, 0, 0, 0, 0 };
    uint32 counts[5] = { TOKENS_PER_WEAPON, 0, 0, 0, 0 };
    for (uint32 id : items)
        out << id;
    for (uint32 n : counts)
        out << n;

    out << uint32(0);
    out << uint32(0);

    ASSERT(out.wpos() - start == Worldforged::RECORD_SIZE);
}

void SendPurchaseResult(WorldSession* session, char const* result)
{
    WorldPacket packet(Worldforged::SMSG_PURCHASE_CUSTOM_STORE_ITEM_RESULT, 48);
    packet << result;
    session->SendPacket(&packet);
}

bool HandleQuery(WorldSession* session, WorldPacket const& packet)
{
    if (!session->GetPlayer() || packet.size() < sizeof(uint32) || packet.read<uint32>(0) != STORE_HEIRLOOM_WEAPONS)
        return false;

    WorldPacket result(Worldforged::SMSG_QUERY_CUSTOM_STORE_RESULT,
        32 + HEIRLOOM_WEAPONS.size() * Worldforged::RECORD_SIZE);
    result << Worldforged::RESULT_QUERY_OK;
    std::size_t const countPosition = result.wpos();
    result << uint32(0);

    uint32 offered = 0;
    for (uint32 weapon : HEIRLOOM_WEAPONS)
        if (IsHeirloomWeapon(weapon))
        {
            BuildStoreRecord(result, weapon);
            ++offered;
        }
    result.put<uint32>(countPosition, offered);

    session->SendPacket(&result);
    return true;
}

bool HandlePurchase(WorldSession* session, WorldPacket const& packet)
{
    Player* player = session->GetPlayer();
    if (!player || packet.size() < sizeof(uint32))
        return false;

    uint32 const weapon = packet.read<uint32>(0);
    if (!IsHeirloomWeapon(weapon))
        return false;

    if (!player->HasItemCount(HEIRLOOM_WEAPON_TOKEN, TOKENS_PER_WEAPON))
    {
        SendPurchaseResult(session, "PURCHASE_CUSTOM_STORE_ITEM_NOT_ENOUGH_ITEMS");
        return true;
    }

    ItemPosCountVec destination;
    InventoryResult const fits = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destination, weapon, 1);
    if (fits != EQUIP_ERR_OK)
    {
        player->SendEquipError(fits, nullptr, nullptr, weapon);
        SendPurchaseResult(session, "PURCHASE_CUSTOM_STORE_ITEM_UNKNOWN");
        return true;
    }

    player->DestroyItemCount(HEIRLOOM_WEAPON_TOKEN, TOKENS_PER_WEAPON, true);
    if (Item* bought = player->StoreNewItem(destination, weapon, true, Item::GenerateItemRandomPropertyId(weapon)))
        player->SendNewItem(bought, 1, true, false);

    SendPurchaseResult(session, Worldforged::RESULT_PURCHASE_OK);
    LOG_INFO("coa", "Heirloom weapon store: {} bought {} for {} x {}", player->GetName(), weapon,
        TOKENS_PER_WEAPON, HEIRLOOM_WEAPON_TOKEN);
    return true;
}

class item_coa_heirloom_weapon_token : public ItemScript
{
public:
    item_coa_heirloom_weapon_token() : ItemScript("item_coa_heirloom_weapon_token") { }

    bool OnUse(Player* player, Item*, SpellCastTargets const&) override
    {
        WorldPacket packet(Worldforged::SMSG_OPEN_CUSTOM_STORE, 4);
        packet << uint32(STORE_HEIRLOOM_WEAPONS);
        player->GetSession()->SendPacket(&packet);
        return true;
    }
};
}

void AddSC_AscensionHeirloomWeaponStore()
{
    AscensionCompatOpcodes::Claim(Worldforged::CMSG_QUERY_CUSTOM_STORE, &HandleQuery);
    AscensionCompatOpcodes::Claim(Worldforged::CMSG_PURCHASE_CUSTOM_STORE_ITEM, &HandlePurchase);

    new item_coa_heirloom_weapon_token();
}
