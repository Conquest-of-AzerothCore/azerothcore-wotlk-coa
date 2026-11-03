/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionFlightMasters.h"
#include "DBCStores.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"

namespace
{
enum SchmorgusBoard
{
    SPELL_WELL_FED_SPELL_POWER  = 966453,
    SPELL_WELL_FED_ATTACK_POWER = 966454,
};

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

class spell_ascension_schmorgus_well_fed : public SpellScript
{
    PrepareSpellScript(spell_ascension_schmorgus_well_fed);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ SPELL_WELL_FED_SPELL_POWER, SPELL_WELL_FED_ATTACK_POWER });
    }

    void Feed(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        float attackPower = std::max(target->GetTotalAttackPowerValue(BASE_ATTACK),
            target->GetTotalAttackPowerValue(RANGED_ATTACK));
        float spellPower = float(std::max(target->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SPELL),
            target->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_SPELL)));
        target->CastSpell(target, spellPower > attackPower ? SPELL_WELL_FED_SPELL_POWER : SPELL_WELL_FED_ATTACK_POWER,
            true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_schmorgus_well_fed::Feed, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionConvenienceItems()
{
    RegisterSpellScript(spell_ascension_flight_masters_whistle);
    RegisterSpellScript(spell_ascension_schmorgus_well_fed);
}
