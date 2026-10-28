/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionFlightMasters.h"
#include "DBCStores.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"

namespace
{
TaxiNodesEntry const* NearestFlightMaster(Player const* player)
{
    uint32 node = AscensionFlightMasters::NearestNode(player->GetPositionX(), player->GetPositionY(),
        player->GetPositionZ(), player->GetMapId(), player->GetTeamId());
    return node ? sTaxiNodesStore.LookupEntry(node) : nullptr;
}

class spell_ascension_flight_masters_whistle : public SpellScript
{
    PrepareSpellScript(spell_ascension_flight_masters_whistle);

    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->GetMap()->Instanceable() || !NearestFlightMaster(player))
            return SPELL_FAILED_NOT_HERE;
        return SPELL_CAST_OK;
    }

    void Retreat(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        if (TaxiNodesEntry const* node = player ? NearestFlightMaster(player) : nullptr)
            player->TeleportTo(node->map_id, node->x, node->y, node->z, player->GetOrientation());
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_flight_masters_whistle::Check);
        OnEffectHit += SpellEffectFn(spell_ascension_flight_masters_whistle::Retreat, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionConvenienceItems()
{
    RegisterSpellScript(spell_ascension_flight_masters_whistle);
}
