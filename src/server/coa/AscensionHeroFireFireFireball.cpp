/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"

namespace
{
enum FireFireFireballSpells : uint32
{
    FireFireFireballStack = 283066,
    CarbonBuildup = 283068,
    FireFireFireballWave = 283069,
    FireFireFireballConsume = 283077
};

constexpr uint8 FireballsBeforePayoff = 2;
constexpr uint8 FireballsPerWave = 3;

class aura_hero_fire_fire_fireball : public AuraScript
{
    PrepareAuraScript(aura_hero_fire_fire_fireball);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({FireFireFireballStack, CarbonBuildup, FireFireFireballWave, FireFireFireballConsume});
    }

    bool CheckFireball(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        Spell const* spell = eventInfo.GetProcSpell();
        return owner && owner->IsInCombat() && eventInfo.GetActor() == owner && spell &&
            spell->GetSpellInfo()->Id != FireFireFireballWave;
    }

    void CountFireball(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        if (owner->HasAura(CarbonBuildup))
        {
            if (Unit* target = eventInfo.GetProcSpell()->m_targets.GetUnitTarget())
                for (uint8 i = 0; i < FireballsPerWave; ++i)
                    owner->CastSpell(target, FireFireFireballWave, true);
            owner->CastSpell(owner, FireFireFireballConsume, true);
            return;
        }

        owner->CastSpell(owner, FireFireFireballStack, true);
        if (Aura const* stacks = owner->GetAura(FireFireFireballStack))
            if (stacks->GetStackAmount() >= FireballsBeforePayoff)
                owner->CastSpell(owner, CarbonBuildup, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_fire_fire_fireball::CheckFireball);
        OnEffectProc += AuraEffectProcFn(aura_hero_fire_fire_fireball::CountFireball, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
}

void AddSC_AscensionHeroFireFireFireball()
{
    RegisterSpellScript(aura_hero_fire_fire_fireball);
}
