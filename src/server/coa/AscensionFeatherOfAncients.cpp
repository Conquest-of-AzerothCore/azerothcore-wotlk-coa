/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionFlightMasters.h"
#include "Chat.h"
#include "CreatureData.h"
#include "DBCStores.h"
#include "Item.h"
#include "ItemScript.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <array>
#include <vector>

namespace
{
enum FeatherOfAncients : uint32
{
    FeatherAzerothLegacy = 134989,
    FeatherAzeroth = 977025
};

class item_ascension_feather_of_ancients : public ItemScript
{
public:
    item_ascension_feather_of_ancients() : ItemScript("item_ascension_feather_of_ancients") { }

    bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
    {
        if (item->GetEntry() != FeatherAzerothLegacy && item->GetEntry() != FeatherAzeroth)
            return false;

        player->SendEquipError(EQUIP_ERR_NONE, item, nullptr);

        TeamId team = player->GetTeamId();
        if (team != TEAM_ALLIANCE && team != TEAM_HORDE)
            return true;

        uint32 learned = 0;
        for (uint32 node : AscensionFlightMasters::Nodes(team))
        {
            if (!AscensionFlightMasters::InMask(sOldContinentsNodesMask, node) || !player->m_taxi.SetTaximaskNode(node))
                continue;
            sScriptMgr->OnPlayerLearnTaxiNode(player, node);
            ++learned;
        }

        if (!learned)
        {
            ChatHandler(player->GetSession()).SendNotification("You already know every flight path of Azeroth.");
            return true;
        }

        uint32 count = 1;
        player->DestroyItemCount(item, count, true);

        WorldPacket discovered(SMSG_NEW_TAXI_PATH, 0);
        player->SendDirectMessage(&discovered);
        return true;
    }
};
}

void AddSC_AscensionFeatherOfAncients()
{
    new item_ascension_feather_of_ancients();
}
