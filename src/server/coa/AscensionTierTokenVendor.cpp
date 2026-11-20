/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "GossipDef.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"
#include <array>

namespace
{
constexpr uint32 TierVendorEntryCount = 13;

constexpr std::array<uint32, TierVendorEntryCount> TierVendorEntries = {
    91000001, 91000002, 91000003, 91000004,
    91000005, 91000006, 91000007, 91000008,
    91000009, 91000010, 91000011, 91000012, 91000013,
};

constexpr std::array<char const*, TierVendorEntryCount> TierVendorLabels = {
    "Tokens T1 Normal", "Tokens T1 Heroic", "Tokens T1 Mythic", "Tokens T1 Ascended",
    "Tokens T2 Normal", "Tokens T2 Heroic", "Tokens T2 Mythic", "Tokens T2 Ascended",
    "Tokens T3 Normal", "Tokens T3 Heroic", "Tokens T3 Mythic", "Tokens T3 Ascended", "Tokens T3 Rings",
};

constexpr std::array<uint32, 4> TierFourVendorEntries = { 91000014, 91000015, 91000016, 91000017 };
constexpr std::array<char const*, TierFourVendorEntries.size()> TierFourVendorLabels = {
    "Tokens T4 Normal", "Tokens T4 Heroic", "Tokens T4 Mythic", "Tokens T4 Ascended",
};

class npc_coa_tier_token_vendor : public CreatureScript
{
public:
    npc_coa_tier_token_vendor() : CreatureScript("npc_coa_tier_token_vendor") { }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        for (uint32 i = 0; i < TierVendorEntryCount; ++i)
            AddGossipItemFor(player, GOSSIP_ICON_VENDOR, TierVendorLabels[i], GOSSIP_SENDER_MAIN, i + 1);
        for (uint32 i = 0; i < TierFourVendorEntries.size(); ++i)
            AddGossipItemFor(player, GOSSIP_ICON_VENDOR, TierFourVendorLabels[i],
                GOSSIP_SENDER_MAIN, TierVendorEntryCount + i + 1);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature* creature, uint32, uint32 action) override
    {
        ClearGossipMenuFor(player);
        CloseGossipMenuFor(player);
        if (action >= 1 && action <= TierVendorEntryCount)
            player->GetSession()->SendListInventory(creature->GetGUID(), TierVendorEntries[action - 1]);
        else if (action > TierVendorEntryCount && action <= TierVendorEntryCount + TierFourVendorEntries.size())
            player->GetSession()->SendListInventory(creature->GetGUID(),
                TierFourVendorEntries[action - TierVendorEntryCount - 1]);
        return true;
    }
};
}

void AddSC_AscensionTierTokenVendor()
{
    new npc_coa_tier_token_vendor();
}
