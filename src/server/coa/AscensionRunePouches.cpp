/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Item.h"
#include "ItemScript.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include <array>

namespace
{
enum RuneOfAscension : uint32
{
    RuneOfAscensionItem = 375250
};

struct RunePouch
{
    uint32 itemId;
    uint32 amount;
};

constexpr std::array<RunePouch, 17> RunePouches{ {
    { 1235070,   1000 },
    {  509872,  12500 },
    {  509873,  15000 },
    {  509886,  17500 },
    {  509874,  20000 },
    {  509875,  25000 },
    {  509876,  30000 },
    {  509893,  32500 },
    {  518448,  35000 },
    {  509894,  39000 },
    {  518449,  40000 },
    {  509895,  45500 },
    {  518450,  50000 },
    {  509896,  52000 },
    {  509897,  65000 },
    {  800902, 200000 },
    { 2509893, 500000 }
} };

uint32 RunePouchAmount(uint32 itemId)
{
    for (RunePouch const& pouch : RunePouches)
        if (pouch.itemId == itemId)
            return pouch.amount;
    return 0;
}

bool PayRunePouch(Player* player, Item* item)
{
    uint32 const amount = RunePouchAmount(item->GetEntry());
    if (!amount)
        return false;

    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    ItemPosCountVec dest;
    InventoryResult space = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, RuneOfAscensionItem, int32(amount));
    if (space != EQUIP_ERR_OK)
    {
        player->SendEquipError(space, nullptr, nullptr, RuneOfAscensionItem);
        return true;
    }

    uint32 const held = player->GetItemCount(RuneOfAscensionItem, false);
    Item* runes = player->StoreNewItem(dest, RuneOfAscensionItem, true);
    if (!runes || player->GetItemCount(RuneOfAscensionItem, false) <= held)
        return true;

    uint32 count = 1;
    player->DestroyItemCount(item, count, true);
    player->SendNewItem(runes, amount, false, false, true);
    return true;
}

class item_ascension_rune_pouch : public ItemScript
{
public:
    item_ascension_rune_pouch() : ItemScript("item_ascension_rune_pouch") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        return PayRunePouch(player, item);
    }
};

class ascension_rune_pouch_open : public PlayerScript
{
public:
    ascension_rune_pouch_open() : PlayerScript("ascension_rune_pouch_open", {PLAYERHOOK_ON_BEFORE_OPEN_ITEM}) { }

    bool OnPlayerBeforeOpenItem(Player* player, Item* item) override
    {
        if (!item || !PayRunePouch(player, item))
            return true;
        return false;
    }
};
}

void AddSC_AscensionRunePouches()
{
    new item_ascension_rune_pouch();
    new ascension_rune_pouch_open();
}
