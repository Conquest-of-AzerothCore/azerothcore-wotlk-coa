/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

namespace
{
enum CrushingEarthSpells : uint32
{
    CrushingEarth = 300697,
    CrushingEarthPower = 301353
};

class aura_ascension_crushing_earth : public AuraScript
{
    PrepareAuraScript(aura_ascension_crushing_earth);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == CrushingEarth && ValidateSpellInfo({CrushingEarthPower});
    }

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == GetUnitOwner()->GetGUID();
    }

    void Update(AuraEffect const* effect)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player->IsInWorld() || !player->IsAlive())
            return;
        int32 amount = int32(player->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + CR_ARMOR_PENETRATION) / 2);
        player->CastCustomSpell(CrushingEarthPower, SPELLVALUE_BASE_POINT0, amount, player,
            TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Update(effect);
    }

    void Tick(AuraEffect const* effect)
    {
        PreventDefaultAction();
        Update(effect);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(CrushingEarthPower, GetTarget()->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_crushing_earth::Apply,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_crushing_earth::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_crushing_earth::Remove,
            EFFECT_0, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class primalist_crushing_earth_metadata : public GlobalScript
{
public:
    primalist_crushing_earth_metadata() : GlobalScript("primalist_crushing_earth_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == CrushingEarthPower && info->SpellFamilyName == 37)
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
    }
};
}

void AddSC_AscensionPrimalistCrushingEarth()
{
    new primalist_crushing_earth_metadata();
    RegisterSpellScript(aura_ascension_crushing_earth);
}
