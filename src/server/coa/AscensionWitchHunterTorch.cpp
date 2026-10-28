/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
constexpr uint32 SPELL_TORCH_THE_WICKED = 560226;
constexpr uint32 SPELL_TORCH_ATTACK_SPEED = 560227;
constexpr uint32 SPELL_FLAMES_OF_SIN_DAMAGE = 802850;
constexpr uint32 SPELL_PYRO_TONIC = 802277;
constexpr uint32 SPELL_TORCHLIGHT = 503662;
constexpr uint32 WITCH_HUNTER_FAMILY = uint32(CLASS_WITCH_HUNTER) + 6;

class spell_ascension_witch_hunter_torch_stacks : public AuraScript
{
    PrepareAuraScript(spell_ascension_witch_hunter_torch_stacks);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* buff = sSpellMgr->GetSpellInfo(SPELL_TORCH_ATTACK_SPEED);
        return spellInfo && spellInfo->Id == SPELL_TORCH_THE_WICKED && spellInfo->SpellFamilyName == WITCH_HUNTER_FAMILY &&
            spellInfo->Effects[EFFECT_0].IsAura(SPELL_AURA_PROC_TRIGGER_SPELL) &&
            spellInfo->Effects[EFFECT_0].TriggerSpell == SPELL_TORCH_ATTACK_SPEED &&
            buff && buff->SpellFamilyName == WITCH_HUNTER_FAMILY && buff->StackAmount &&
            buff->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_MELEE_HASTE) &&
            buff->Effects[EFFECT_0].TargetA.GetTarget() == TARGET_UNIT_CASTER;
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_WITCH_HUNTER && caster == GetUnitOwner();
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* caster = GetCaster();
        DamageInfo const* damage = eventInfo.GetDamageInfo();
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return caster && caster->IsAlive() && eventInfo.GetActor() == caster &&
            spellInfo && spellInfo->Id == SPELL_FLAMES_OF_SIN_DAMAGE &&
            damage && damage->GetDamage() && damage->GetAttacker() == caster && damage->GetVictim() != caster &&
            damage->GetSpellInfo() && damage->GetSpellInfo()->Id == SPELL_FLAMES_OF_SIN_DAMAGE;
    }

    void AddAttackSpeed(AuraEffect const* effect, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (!CheckProc(eventInfo))
            return;

        Unit* caster = GetCaster();
        if (Aura* buff = caster->GetAura(SPELL_TORCH_ATTACK_SPEED, caster->GetGUID()))
        {
            uint8 maximum = buff->GetSpellInfo()->CalcMaxAuraStacks(caster);
            if (buff->GetStackAmount() < maximum)
                buff->SetStackAmount(uint8(buff->GetStackAmount() + 1));
        }
        else
            caster->CastSpell(caster, SPELL_TORCH_ATTACK_SPEED, TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_witch_hunter_torch_stacks::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_witch_hunter_torch_stacks::AddAttackSpeed, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_witch_hunter_pyro_torchlight : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_pyro_torchlight);

    bool Validate(SpellInfo const* spellInfo) override
    {
        SpellInfo const* torchlight = sSpellMgr->GetSpellInfo(SPELL_TORCHLIGHT);
        return spellInfo && spellInfo->Id == SPELL_PYRO_TONIC && spellInfo->SpellFamilyName == WITCH_HUNTER_FAMILY &&
            torchlight && torchlight->SpellFamilyName == WITCH_HUNTER_FAMILY &&
            ValidateSpellInfo({SPELL_TORCH_THE_WICKED});
    }

    bool Load() override
    {
        Unit* caster = GetCaster();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_WITCH_HUNTER && !GetSpell()->IsTriggered();
    }

    void ResetTorchlight()
    {
        Player* player = GetCaster()->ToPlayer();
        if (player->HasAura(SPELL_TORCH_THE_WICKED) && player->GetSpellCooldownDelay(SPELL_TORCHLIGHT))
            player->RemoveSpellCooldown(SPELL_TORCHLIGHT, true);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_witch_hunter_pyro_torchlight::ResetTorchlight);
    }
};
}

void AddAscensionWitchHunterTorchScripts()
{
    RegisterSpellScript(spell_ascension_witch_hunter_torch_stacks);
    RegisterSpellScript(spell_ascension_witch_hunter_pyro_torchlight);
}
