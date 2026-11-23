/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Item.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include <array>

namespace
{
struct GoldSatchel
{
    uint32 itemId;
    uint32 gold;
};

constexpr std::array<GoldSatchel, 1> GoldSatchels{ {
    { 800901, 500 }
} };

uint32 GoldSatchelCopper(uint32 itemId)
{
    for (GoldSatchel const& satchel : GoldSatchels)
        if (satchel.itemId == itemId)
            return satchel.gold * GOLD;
    return 0;
}

bool PayGoldSatchel(Player* player, Item* item)
{
    uint32 const copper = GoldSatchelCopper(item->GetEntry());
    if (!copper)
        return false;

    player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

    if (!player->ModifyMoney(int32(copper)))
        return true;

    uint32 count = 1;
    player->DestroyItemCount(item, count, true);

    WorldPacket notice(SMSG_LOOT_MONEY_NOTIFY, 4 + 1);
    notice << copper << uint8(1);
    player->SendDirectMessage(&notice);
    return true;
}

class ascension_gold_satchel_open : public PlayerScript
{
public:
    ascension_gold_satchel_open() : PlayerScript("ascension_gold_satchel_open", {PLAYERHOOK_ON_BEFORE_OPEN_ITEM}) { }

    bool OnPlayerBeforeOpenItem(Player* player, Item* item) override
    {
        return !item || !PayGoldSatchel(player, item);
    }
};
}

void AddSC_AscensionGoldSatchels()
{
    new ascension_gold_satchel_open();
}
