/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"

namespace
{
enum MountainSpells : uint32
{
    EarthsRage = 806068,
    CallOfTheMountain = 680406,
    MountainBuff = 680472
};

class aura_ascension_blessed_by_earth : public AuraScript
{
    PrepareAuraScript(aura_ascension_blessed_by_earth);

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* info = damage ? damage->GetSpellInfo() : nullptr;
        return owner->IsPlayer() && owner->getClass() == CLASS_WILDWALKER && owner->IsAlive() &&
            event.GetActor() == owner && damage && damage->GetDamage() && info && info->SpellFamilyName == 37 &&
            ((info->SpellFamilyFlags[0] & 16384) || (info->SpellFamilyFlags[2] & 256)) &&
            event.GetActionTarget() && !owner->IsFriendlyTo(event.GetActionTarget());
    }

    void Gain(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (CheckProc(event))
            GetTarget()->CastSpell(GetTarget(), EarthsRage, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_blessed_by_earth::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_blessed_by_earth::Gain,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_ascension_mountain_threshold : public AuraScript
{
    PrepareAuraScript(aura_ascension_mountain_threshold);
    uint8 _previous = 0;

    void Changed(AuraEffect const*, AuraEffectHandleModes mode)
    {
        uint8 current = GetStackAmount();
        uint8 previous = _previous;
        bool crossedUp = previous < 5 && current >= 5;
        bool crossedDown = previous >= 5 && current < 5;
        _previous = current;
        Unit* owner = GetTarget();
        if (mode == AURA_EFFECT_HANDLE_REAL || !owner->IsPlayer() ||
            owner->getClass() != CLASS_WILDWALKER || GetCasterGUID() != owner->GetGUID())
            return;
        if (crossedDown)
            owner->RemoveAurasDueToSpell(MountainBuff, owner->GetGUID());
        else if (crossedUp && owner->IsAlive() && owner->GetLevel() >= 40 && owner->HasAura(CallOfTheMountain))
            owner->CastSpell(owner, MountainBuff, true);
    }

    void Cleared(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* owner = GetTarget();
        owner->RemoveAurasDueToSpell(MountainBuff, owner->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_mountain_threshold::Changed,
            EFFECT_0, SPELL_AURA_MOD_INCREASE_SPEED, AURA_EFFECT_HANDLE_CHANGE_AMOUNT_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_mountain_threshold::Cleared,
            EFFECT_0, SPELL_AURA_MOD_INCREASE_SPEED, AURA_EFFECT_HANDLE_REAL);
    }
};

class mountain_talent_metadata : public GlobalScript
{
public:
    mountain_talent_metadata() : GlobalScript("mountain_talent_metadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == EarthsRage && info->SpellFamilyName == 37)
            info->Effects[EFFECT_2].Effect = 0;
    }
};
}

void AddSC_AscensionPrimalistMountain()
{
    RegisterSpellScript(aura_ascension_blessed_by_earth);
    RegisterSpellScript(aura_ascension_mountain_threshold);
    new mountain_talent_metadata();
}
