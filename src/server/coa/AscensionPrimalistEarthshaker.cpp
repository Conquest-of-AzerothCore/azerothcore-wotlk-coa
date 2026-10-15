/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <algorithm>

namespace
{
constexpr uint32 Earthshaker = 300698;

class aura_ascension_earthshaker_periodic : public AuraScript
{
    PrepareAuraScript(aura_ascension_earthshaker_periodic);

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_WILDWALKER &&
            GetSpellInfo()->SpellFamilyName == 37 && GetSpellInfo()->GetSchoolMask() == SPELL_SCHOOL_MASK_NORMAL;
    }

    void Snapshot(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(Earthshaker))
            return;

        SpellInfo const* info = GetSpellInfo();
        float chance = caster->SpellDoneCritChance(GetTarget(), info, SPELL_SCHOOL_MASK_NATURE, BASE_ATTACK, true);
        chance = GetTarget()->SpellTakenCritChance(caster, info, info->GetSchoolMask(), chance, BASE_ATTACK, true);
        GetEffect(effect->GetEffIndex())->SetCritChance(std::max(0.0f, chance));
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_earthshaker_periodic::Snapshot,
            EFFECT_ALL, SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
    }
};

class primalist_earthshaker_metadata : public GlobalScript
{
public:
    primalist_earthshaker_metadata() : GlobalScript("primalist_earthshaker_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != Earthshaker || info->SpellFamilyName != 37)
            return;

        if (info->Effects[EFFECT_0].IsAura(SPELL_AURA_ABILITY_PERIODIC_CRIT))
            info->Effects[EFFECT_0].SpellClassMask[0] |= 64;
        for (SpellEffIndex index : {EFFECT_1, EFFECT_2})
            if (info->Effects[index].IsAura(SPELL_AURA_ADD_PCT_MODIFIER))
            {
                info->Effects[index].SpellClassMask[0] |= 64;
                info->Effects[index].SpellClassMask[1] |= 256;
                info->Effects[index].SpellClassMask[2] |= 263168;
            }
    }
};
}

void AddSC_AscensionPrimalistEarthshaker()
{
    new primalist_earthshaker_metadata();
    RegisterSpellScript(aura_ascension_earthshaker_periodic);
}
