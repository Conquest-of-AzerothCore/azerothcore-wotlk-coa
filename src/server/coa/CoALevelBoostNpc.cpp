/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Config.h"
#include "Creature.h"
#include "GossipDef.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "StringFormat.h"
#include "World.h"
#include <algorithm>

// A test-realm helper: one gossip option raises the player to CoA.LevelBoostNpc.Level. Off unless the realm sets
// CoA.LevelBoostNpc.Enable = 1, so the creature does nothing on a realm that has not chosen it.
namespace
{
constexpr uint32 TEXT_LEVEL_BOOST = 9990500;
constexpr uint32 TEXT_LEVEL_BOOST_UNAVAILABLE = 9990501;
constexpr uint32 ACTION_BOOST = 1;

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
                Acore::StringFormat("Raise this character to level {}? This cannot be undone.", level), 0, false);
        SendGossipMenuFor(player, TEXT_LEVEL_BOOST, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* /*creature*/, uint32 /*sender*/, uint32 action) override
    {
        CloseGossipMenuFor(player);
        if (action != ACTION_BOOST || !BoostEnabled())
            return true;

        uint8 const level = BoostLevel();
        if (player->GetLevel() >= level)
            return true;

        player->GiveLevel(level);
        if (player->GetLevel() == level)
            player->SetUInt32Value(PLAYER_XP, 0);
        return true;
    }
};
}

void AddSC_CoALevelBoostNpc()
{
    new npc_coa_level_boost();
}
