/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Config.h"
#include "Creature.h"
#include "Item.h"
#include "GossipDef.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "StringFormat.h"
#include "World.h"
#include <algorithm>
#include <limits>
#include <string>

namespace
{
constexpr uint32 TEXT_LEVEL_BOOST = 9990500;
constexpr uint32 TEXT_LEVEL_BOOST_UNAVAILABLE = 9990501;
constexpr uint32 ACTION_BOOST = 1;
constexpr uint32 RUNE_OF_DESCENSION = 375250;

bool BoostEnabled()
{
    return sConfigMgr->GetOption<bool>("CoA.LevelBoostNpc.Enable", false);
}

uint8 BoostLevel()
{
    uint32 const wanted = sConfigMgr->GetOption<uint32>("CoA.LevelBoostNpc.Level", 60);
    uint32 const cap = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
    return uint8(std::clamp<uint32>(wanted, 1, cap));
}

uint32 BoostGoldReward()
{
    return std::min<uint32>(sConfigMgr->GetOption<uint32>("CoA.LevelBoostNpc.GoldReward", 5000), 200000);
}

uint32 BoostRuneReward()
{
    return std::min<uint32>(sConfigMgr->GetOption<uint32>("CoA.LevelBoostNpc.RuneOfDescensionReward", 2000000),
        uint32(std::numeric_limits<int32>::max()));
}

std::string BoostPrompt(uint8 level)
{
    std::string rewards;
    if (uint32 const gold = BoostGoldReward())
        rewards = Acore::StringFormat("{} gold", gold);
    if (uint32 const runes = BoostRuneReward())
        rewards += Acore::StringFormat("{}{} Runes of Descension", rewards.empty() ? "" : " and ", runes);
    if (rewards.empty())
        return Acore::StringFormat("Raise this character to level {}? This cannot be undone.", level);
    return Acore::StringFormat("Raise this character to level {} and receive {}? This cannot be undone.", level, rewards);
}

void PayRunes(Player* player, uint32 amount)
{
    ItemPosCountVec dest;
    InventoryResult const space = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, dest, RUNE_OF_DESCENSION, amount);
    if (space != EQUIP_ERR_OK)
    {
        player->SendEquipError(space, nullptr, nullptr, RUNE_OF_DESCENSION);
        return;
    }
    if (Item* runes = player->StoreNewItem(dest, RUNE_OF_DESCENSION, true))
        player->SendNewItem(runes, amount, true, false, true);
}

class npc_coa_level_boost : public CreatureScript
{
public:
    npc_coa_level_boost() : CreatureScript("npc_coa_level_boost") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        if (!BoostEnabled())
        {
            SendGossipMenuFor(player, TEXT_LEVEL_BOOST_UNAVAILABLE, creature->GetGUID());
            return true;
        }

        uint8 const level = BoostLevel();
        if (player->GetLevel() < level)
            AddGossipItemFor(player, GOSSIP_ICON_TRAINER, Acore::StringFormat("Raise me to level {}", level),
                GOSSIP_SENDER_MAIN, ACTION_BOOST,
                BoostPrompt(level), 0, false);
        SendGossipMenuFor(player, TEXT_LEVEL_BOOST, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature*, uint32, uint32 action) override
    {
        CloseGossipMenuFor(player);
        if (action != ACTION_BOOST || !BoostEnabled())
            return true;

        uint8 const level = BoostLevel();
        if (player->GetLevel() >= level)
            return true;

        player->GiveLevel(level);
        if (player->GetLevel() != level)
            return true;

        player->SetUInt32Value(PLAYER_XP, 0);
        if (uint32 const gold = BoostGoldReward())
            player->ModifyMoney(int32(gold * GOLD));
        if (uint32 const runes = BoostRuneReward())
            PayRunes(player, runes);
        return true;
    }
};
}

void AddSC_CoALevelBoostNpc()
{
    new npc_coa_level_boost();
}
