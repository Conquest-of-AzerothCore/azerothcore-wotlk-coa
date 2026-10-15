/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <algorithm>
#include <limits>

namespace
{
enum EarthmotherRoarSpells : uint32
{
    EarthmotherRoar = 301306,
    EarthmotherHeal = 301307
};

class spell_ascension_earthmother_roar : public SpellScript
{
    PrepareSpellScript(spell_ascension_earthmother_roar);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({EarthmotherHeal}); }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_WILDWALKER;
    }

    void Heal()
    {
        Unit* caster = GetCaster();
        if (caster->HasAura(EarthmotherRoar, caster->GetGUID()))
            caster->CastSpell(caster, EarthmotherHeal, TRIGGERED_FULL_MASK);
    }

    void Register() override { AfterCast += SpellCastFn(spell_ascension_earthmother_roar::Heal); }
};

class spell_ascension_earthmother_missing_health : public SpellScript
{
    PrepareSpellScript(spell_ascension_earthmother_missing_health);

    void Amount(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        uint64 missing = target->GetMaxHealth() - std::min(target->GetHealth(), target->GetMaxHealth());
        uint64 amount = missing * std::clamp(GetEffectValue(), 0, 100) / 100;
        SetEffectValue(int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_earthmother_missing_health::Amount,
            EFFECT_0, SPELL_EFFECT_HEAL);
    }
};

class primalist_earthmother_roar_metadata : public GlobalScript
{
public:
    primalist_earthmother_roar_metadata() : GlobalScript("primalist_earthmother_roar_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == EarthmotherHeal && info->SpellFamilyName == 37 &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL_PCT && info->Effects[EFFECT_0].MiscValueB == 1)
        {
            info->Effects[EFFECT_0].Effect = SPELL_EFFECT_HEAL;
        }
    }
};
}

void AddSC_AscensionPrimalistEarthmotherRoar()
{
    new primalist_earthmother_roar_metadata();
    RegisterSpellScript(spell_ascension_earthmother_roar);
    RegisterSpellScript(spell_ascension_earthmother_missing_health);
}
