/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 SPELL_TORCHLIGHT_MARK = 503662;
constexpr uint32 SPELL_TORCHLIGHT_FLAMES = 504779;
constexpr uint32 SPELL_TORCHLIGHT_FLAMES_DAMAGE = 802850;
constexpr uint32 TORCHLIGHT_ATTACK_FLAGS = PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK |
    PROC_FLAG_TAKEN_SPELL_MELEE_DMG_CLASS | PROC_FLAG_TAKEN_SPELL_RANGED_DMG_CLASS |
    PROC_FLAG_TAKEN_SPELL_NONE_DMG_CLASS_NEG | PROC_FLAG_TAKEN_SPELL_MAGIC_DMG_CLASS_NEG;

class spell_ascension_witch_hunter_torchlight_mark : public AuraScript
{
    PrepareAuraScript(spell_ascension_witch_hunter_torchlight_mark);

    bool Validate(SpellInfo const* spellInfo) override
    {
        return spellInfo && spellInfo->Id == SPELL_TORCHLIGHT_MARK &&
            spellInfo->SpellFamilyName == uint32(CLASS_WITCH_HUNTER) + 6 && spellInfo->ProcCharges == 5 &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_TORCHLIGHT_FLAMES &&
            ValidateSpellInfo({SPELL_TORCHLIGHT_FLAMES});
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_WITCH_HUNTER &&
            GetUnitOwner() && GetUnitOwner() != caster;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* caster = GetCaster();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        if (!caster || !caster->IsAlive() || eventInfo.GetActor() != caster || !damage || !damage->GetDamage() ||
            damage->GetAttacker() != caster || damage->GetVictim() != GetTarget() ||
            eventInfo.GetActionTarget() != GetTarget() || !(eventInfo.GetTypeMask() & TORCHLIGHT_ATTACK_FLAGS) ||
            (eventInfo.GetTypeMask() & PROC_FLAG_TAKEN_PERIODIC))
            return false;

        for (SpellInfo const* source : {eventInfo.GetSpellInfo(), damage->GetSpellInfo()})
            if (source && (source->Id == SPELL_TORCHLIGHT_MARK || source->Id == SPELL_TORCHLIGHT_FLAMES_DAMAGE))
                return false;

        return true;
    }

    void GrantFlames(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (CheckProc(eventInfo))
            GetCaster()->CastSpell(GetCaster(), SPELL_TORCHLIGHT_FLAMES, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_witch_hunter_torchlight_mark::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_witch_hunter_torchlight_mark::GrantFlames, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
}

void AddAscensionWitchHunterTorchlightScripts()
{
    RegisterSpellScript(spell_ascension_witch_hunter_torchlight_mark);
}
