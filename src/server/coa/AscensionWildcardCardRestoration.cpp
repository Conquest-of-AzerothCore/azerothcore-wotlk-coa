/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "GameTime.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include "UnitScript.h"
#include <algorithm>
#include <limits>
#include <string_view>

namespace
{
std::string_view CardName(SpellInfo const* info)
{
    return info && info->SpellName[LOCALE_enUS] ? info->SpellName[LOCALE_enUS] : "";
}
Aura* CardAura(Unit* owner, std::string_view name, ObjectGuid caster = ObjectGuid::Empty)
{
    if (!owner)
        return nullptr;
    for (auto const& [id, application] : owner->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        if (CardName(aura->GetSpellInfo()) == name && (!caster || aura->GetCasterGUID() == caster))
            return aura;
    }
    return nullptr;
}
Unit* CardTarget(ProcEventInfo& event)
{
    if (Unit* target = event.GetActionTarget())
        return target;
    Spell const* spell = event.GetProcSpell();
    return spell ? spell->m_targets.GetUnitTarget() : nullptr;
}
void CardCast(Unit* owner, Unit* target, uint32 spell, AuraEffect const* effect)
{
    if (owner && target && target->IsInWorld())
        owner->CastSpell(target, spell, true, nullptr, effect);
}
class aura_wildcard_card_restoration : public AuraScript
{
    PrepareAuraScript(aura_wildcard_card_restoration);
    uint8 _marks = 0;
    bool Validate(SpellInfo const* info) override
    {
        for (SpellEffectInfo const& effect : info->Effects)
            if (effect.IsAura(SPELL_AURA_PROC_TRIGGER_SPELL) && effect.TriggerSpell &&
                !ValidateSpellInfo({effect.TriggerSpell}))
                return false;
        return true;
    }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* target = CardTarget(event);
        if (!owner || !owner->IsPlayer())
            return false;
        SpellInfo const* info = event.GetSpellInfo();
        std::string_view const name = CardName(info);
        DamageInfo* damage = event.GetDamageInfo();
        bool const dealt = damage && damage->GetDamage();
        bool const periodic = event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC);
        Spell const* spell = event.GetProcSpell();
        bool const cast = spell && !spell->IsTriggered() && (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH);
        switch (GetId())
        {
            case 284374:
                return event.GetActor() == owner && info && (event.GetHitMask() & PROC_HIT_MISS) &&
                    !(event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_RANGED_AUTO_ATTACK));
            case 271746:
                return event.GetActor() == owner && dealt && !periodic && name == "Steady Shot" &&
                    CardAura(owner, "Wild Quiver") && CardAura(target, "Serpent Sting", owner->GetGUID());
            case 281701: return event.GetActor() == owner && cast && target && name == "Fear";
            case 277160: return event.GetActor() == owner && cast && (name == "Incinerate" || name == "Chaos Bolt");
            case 278135:
                return event.GetActor() == owner && cast && !owner->HasAura(278139) &&
                    (name == "Sinister Strike" || name == "Wrath" || name == "Starfire" || name == "Starsurge") &&
                    CardAura(target, "Insect Swarm", owner->GetGUID());
            default: return false;
        }
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* target = CardTarget(event);
        switch (GetId())
        {
            case 284374: CardCast(owner, owner, 284375, effect); break;
            case 271746: CardCast(owner, target, 53254, effect); break;
            case 281701: CardCast(owner, target, 281705, effect); break;
            case 277160:
            {
                Aura* counter = owner->GetAura(277161);
                if (counter && counter->GetStackAmount() >= counter->GetSpellInfo()->StackAmount)
                {
                    counter->Remove();
                    bool decimation = false;
                    for (auto const& [id, application] : owner->GetAppliedAuras())
                        if (CardName(application->GetBase()->GetSpellInfo()) == "Decimation")
                            for (SpellEffectInfo const& part : application->GetBase()->GetSpellInfo()->Effects)
                                if (part.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) && part.MiscValue == SPELLMOD_CASTING_TIME)
                                    decimation = true;
                    if (!decimation)
                        CardCast(owner, owner, 277142, effect);
                }
                else
                    CardCast(owner, owner, 277161, effect);
                break;
            }
            case 278135:
                if (Aura* swarm = CardAura(target, "Insect Swarm", owner->GetGUID()))
                {
                    int32 extension = sSpellMgr->GetSpellInfo(278136)->Effects[EFFECT_0].CalcValue(owner);
                    if (swarm->GetDuration() > 0 && extension > 0)
                    {
                        swarm->SetDuration(int32(std::min<int64>(int64(swarm->GetDuration()) + extension,
                            std::numeric_limits<int32>::max())));
                        if (++_marks >= sSpellMgr->GetSpellInfo(278139)->StackAmount)
                        {
                            _marks = 0;
                            CardCast(owner, owner, 278139, effect);
                        }
                    }
                }
                break;
            default: break;
        }
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_card_restoration::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_card_restoration::Proc,
            EFFECT_ALL, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class aura_wildcard_shaken_spread : public AuraScript
{
    PrepareAuraScript(aura_wildcard_shaken_spread);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({281706}); }
    void Spread(AuraEffect const* effect)
    {
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (caster && target && target->IsAlive())
            caster->CastSpell(target->GetPositionX(), target->GetPositionY(), target->GetPositionZ(),
                281706, true, nullptr, effect);
    }
    void Apply(AuraEffect const* effect, AuraEffectHandleModes) { Spread(effect); }
    void Tick(AuraEffect const* effect) { PreventDefaultAction(); Spread(effect); }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_wildcard_shaken_spread::Apply,
            EFFECT_2, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_wildcard_shaken_spread::Tick,
            EFFECT_2, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
    }
};
class card_decimation_exclusion : public UnitScript
{
public:
    card_decimation_exclusion() : UnitScript("card_decimation_exclusion", true, {UNITHOOK_ON_AURA_APPLY}) { }
    void OnAuraApply(Unit* owner, Aura* aura) override
    {
        if (owner && aura && owner->IsPlayer() && CardName(aura->GetSpellInfo()) == "Decimation")
            for (SpellEffectInfo const& effect : aura->GetSpellInfo()->Effects)
                if (effect.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) && effect.MiscValue == SPELLMOD_CASTING_TIME)
                {
                    owner->RemoveAurasDueToSpell(277142);
                    break;
                }
    }
};
class card_restoration_casts : public AllSpellScript
{
public:
    card_restoration_casts() : AllSpellScript("card_restoration_casts",
        {ALLSPELLHOOK_ON_GLOBAL_COOLDOWN}) { }
    void OnSpellGlobalCooldown(Spell* spell, int32& duration) override
    {
        Unit* owner = spell->GetCaster();
        if (!owner || !owner->IsPlayer())
            return;
        if (CardName(spell->GetSpellInfo()) == "Soul Fire")
            if (AuraEffect const* ready = owner->GetAuraEffect(277142, EFFECT_2))
                duration = std::min(duration, CalculatePct(int32(spell->GetSpellInfo()->StartRecoveryTime),
                    100 + ready->GetAmount()));
    }
};
class card_restoration_contracts : public GlobalScript
{
public:
    card_restoration_contracts() : GlobalScript("card_restoration_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }
    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == 277161 && info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_FLAT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_DURATION)
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        if (info->Id == 278135 && info->Effects[EFFECT_1].IsAura(SPELL_AURA_PERIODIC_HASTE))
            if (SpellInfo const* swarm = sSpellMgr->GetSpellInfo(5570))
            {
                info->SpellFamilyName = swarm->SpellFamilyName;
                info->Effects[EFFECT_1].SpellClassMask = swarm->SpellFamilyFlags;
            }
    }

};
}
void AddSC_AscensionWildcardCardRestoration()
{
    RegisterSpellScript(aura_wildcard_card_restoration);
    RegisterSpellScript(aura_wildcard_shaken_spread);
    new card_decimation_exclusion();
    new card_restoration_casts();
    new card_restoration_contracts();
}
