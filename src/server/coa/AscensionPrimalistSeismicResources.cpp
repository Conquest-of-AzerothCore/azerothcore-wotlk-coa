/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellInfo.h"

#include <algorithm>

namespace
{
enum SeismicResourceSpells : uint32
{
    SeismicCrash = 803981,
    SeismicSpike = 804433,
    CrashRage = 681355,
    SpikeRage = 681356,
    SeismicSmash = 300693,
    ThanesRage = 804124,
    Aftershock = 301086
};

Player* PrimalistCaster(Spell* spell)
{
    if (!spell || spell->IsTriggered() || spell->GetSpellInfo()->SpellFamilyName != 37)
        return nullptr;
    Player* player = spell->GetCaster()->ToPlayer();
    return player && player->getClass() == CLASS_WILDWALKER && player->IsAlive() ? player : nullptr;
}

class primalist_seismic_resources : public AllSpellScript
{
public:
    primalist_seismic_resources() : AllSpellScript("primalist_seismic_resources",
        {ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellCast(Spell* spell, Unit*, SpellInfo const* info, bool) override
    {
        Player* player = PrimalistCaster(spell);
        if (player && info->GetFirstRankSpell()->Id == SeismicCrash)
            player->CastSpell(player, CrashRage, true);
        else if (player && info->GetFirstRankSpell()->Id == SeismicSmash)
        {
            player->CastSpell(player, ThanesRage, true);
            player->CastSpell(player, Aftershock, true);
        }
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
    {
        Player* player = PrimalistCaster(spell);
        if (!player || !target || target == player || player->IsFriendlyTo(target) || miss != SPELL_MISS_NONE ||
            spell->GetSpellInfo()->GetFirstRankSpell()->Id != SeismicSpike)
            return;
        player->CastSpell(player, SpikeRage, true);
    }
};

class primalist_aftershock_metadata : public GlobalScript
{
public:
    primalist_aftershock_metadata() : GlobalScript("primalist_aftershock_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == Aftershock)
            info->ProcCharges = 1;
    }
};

class primalist_seismic_smash_scaling : public UnitScript
{
public:
    primalist_seismic_smash_scaling() : UnitScript("primalist_seismic_smash_scaling", true,
        {UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        if (!caster || !caster->IsPlayer() || caster->getClass() != CLASS_WILDWALKER ||
            info->SpellFamilyName != 37 || index != EFFECT_0 || info->GetFirstRankSpell()->Id != SeismicSmash ||
            info->Effects[index].Effect != SPELL_EFFECT_SCHOOL_DAMAGE)
            return;
        value += std::max(0.0f, caster->GetTotalAttackPowerValue(BASE_ATTACK)) * 0.22f +
            caster->GetStat(STAT_STAMINA) * 0.5f;
    }
};
}

void AddSC_AscensionPrimalistSeismicResources()
{
    new primalist_seismic_resources();
    new primalist_aftershock_metadata();
    new primalist_seismic_smash_scaling();
}
