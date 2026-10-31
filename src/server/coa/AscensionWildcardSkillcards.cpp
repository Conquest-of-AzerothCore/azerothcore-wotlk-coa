/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionSkillcardProcRules.h"
#include "AllSpellScript.h"
#include "DynamicObject.h"
#include "GameTime.h"
#include "Player.h"
#include "Pet.h"
#include "ObjectAccessor.h"
#include "MoveSpline.h"
#include "UnitScript.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <array>
#include <limits>
#include <string_view>

namespace
{
using AscensionSkillcard::Event;

std::string_view NameOf(SpellInfo const* info)
{
    return info && info->SpellName[LOCALE_enUS] ? info->SpellName[LOCALE_enUS] : "";
}

Aura* NamedAura(Unit* unit, std::string_view name, ObjectGuid caster = ObjectGuid::Empty)
{
    if (!unit)
        return nullptr;
    for (auto const& [id, application] : unit->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        if (NameOf(aura->GetSpellInfo()) == name && (!caster || aura->GetCasterGUID() == caster))
            return aura;
    }
    return nullptr;
}

bool InEarthquake(Unit* caster, Unit* target)
{
    if (!target)
        return false;
    for (uint32 id : {954524u, 954570u, 954571u, 954572u, 954573u, 954574u, 954575u, 983441u})
        if (DynamicObject* area = caster->GetDynObject(id))
            if (area->GetMap() == target->GetMap() && area->IsWithinDistInMap(target, area->GetRadius()))
                return true;
    return false;
}

Event Describe(Unit* owner, ProcEventInfo& event, uint32 talent)
{
    Event result;
    SpellInfo const* info = event.GetSpellInfo();
    result.Name = NameOf(info);
    DamageInfo* damage = event.GetDamageInfo();
    HealInfo* heal = event.GetHealInfo();
    result.Damage = damage && damage->GetDamage();
    result.Heal = heal && heal->GetHeal();
    result.Periodic = (event.GetTypeMask() & (PROC_FLAG_DONE_PERIODIC | PROC_FLAG_TAKEN_PERIODIC)) != 0;
    result.Cast = (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) != 0 &&
        event.GetProcSpell() && !event.GetProcSpell()->IsTriggered();
    result.Critical = (event.GetHitMask() & PROC_HIT_CRITICAL) != 0;
    result.Miss = (event.GetHitMask() & PROC_HIT_MISS) != 0 &&
        (event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_RANGED_AUTO_ATTACK |
            PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS | PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS));
    result.Kill = (event.GetTypeMask() & PROC_FLAG_KILL) != 0;
    result.RangedAuto = (event.GetTypeMask() & PROC_FLAG_DONE_RANGED_AUTO_ATTACK) != 0;
    result.Offhand = damage && damage->GetAttackType() == OFF_ATTACK;
    result.MeleeAbility = info && info->DmgClass == SPELL_DAMAGE_CLASS_MELEE;
    result.Hunter = info && info->SpellFamilyName == SPELLFAMILY_HUNTER;
    result.HunterShot = info && info->SpellFamilyName == SPELLFAMILY_HUNTER &&
        info->DmgClass == SPELL_DAMAGE_CLASS_RANGED && result.Name != "Auto Shot";
    result.GlobalCooldown = info && info->StartRecoveryCategory;
    uint32 const school = event.GetSchoolMask();
    result.Fire = (school & SPELL_SCHOOL_MASK_FIRE) != 0;
    result.Shadow = (school & SPELL_SCHOOL_MASK_SHADOW) != 0;
    result.Holy = (school & SPELL_SCHOOL_MASK_HOLY) != 0;
    result.Frost = (school & SPELL_SCHOOL_MASK_FROST) != 0;
    result.Magic = (school & SPELL_SCHOOL_MASK_MAGIC) != 0;
    Unit* target = event.GetActionTarget();
    switch (talent)
    {
        case 281782:
            result.Qualified = (event.GetTypeMask() &
                (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS)) != 0;
            break;
        case 282279: result.Qualified = info && info->SpellFamilyName == SPELLFAMILY_PALADIN; break;
        case 282105: result.Qualified = NamedAura(owner, "Recklessness"); break;
        case 285537:
            result.Qualified = result.Name == "Wrath" && result.Critical &&
                (owner->HasAura(16886) || owner->HasAura(116886));
            break;
        case 283949: result.Qualified = info && info->Mechanic == MECHANIC_BANDAGE; break;
        case 283175:
            result.Qualified = target == owner && AscensionSkillcard::FullHealthAfterHeal(owner->GetHealth(),
                owner->GetMaxHealth(), heal ? heal->GetEffectiveHeal() : 0);
            break;
        case 285865:
            result.Qualified = result.Damage && (result.Holy || result.Frost) &&
                NamedAura(target, "Holy Fire", owner->GetGUID());
            break;
        case 273595:
            result.Qualified = owner->HasAura(988256) && !owner->HasAura(273600);
            break;
        case 278510: result.Qualified = false; break;
        case 270424:
            result.Qualified = result.Damage && result.Magic &&
                NamedAura(target, "Conflagrate", owner->GetGUID());
            break;
        case 283471:
            result.Qualified = result.Damage && result.Fire && !result.Periodic &&
                event.GetProcSpell() && event.GetProcSpell()->GetCastTime() > 0 &&
                InEarthquake(owner, target);
            break;
        case 277143: result.Qualified = target && !target->HasAura(277145, owner->GetGUID()); break;
        default: break;
    }
    return result;
}

void Cast(Unit* caster, Unit* target, uint32 spell, AuraEffect const* effect)
{
    if (target && target->IsInWorld())
        caster->CastSpell(target, spell, true, nullptr, effect);
}

class aura_wildcard_skillcard_proc : public AuraScript
{
    PrepareAuraScript(aura_wildcard_skillcard_proc);
    TimePoint _fireReady{};
    TimePoint _shadowReady{};

    bool Validate(SpellInfo const* info) override
    {
        if (!AscensionSkillcard::Implemented(info->Id) ||
            !info->Effects[EFFECT_0].IsAura(SPELL_AURA_PROC_TRIGGER_SPELL) ||
            !ValidateSpellInfo({info->Effects[EFFECT_0].TriggerSpell}))
            return false;
        switch (info->Id)
        {
            case 277185: return ValidateSpellInfo({277187});
            case 277505: return ValidateSpellInfo({277513});
            case 277143: return ValidateSpellInfo({277145});
            case 283465: return ValidateSpellInfo({11113, 283466});
            case 285780: return ValidateSpellInfo({285782});
            case 274268: return ValidateSpellInfo({274315});
            case 283949: return ValidateSpellInfo({283951});
            default: return true;
        }
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        if (!owner || !owner->IsPlayer())
            return false;
        bool const stagger = GetId() == 285780 && NameOf(event.GetSpellInfo()) == "Stagger";
        if (!stagger && event.GetActor() != owner)
            return false;
        if (stagger && (event.GetActionTarget() != owner || !(event.GetTypeMask() & PROC_FLAG_TAKEN_PERIODIC)))
            return false;
        SpellInfo const* trigger = event.GetTriggerAuraSpell();
        if (trigger && trigger->Id == GetId())
            return false;
        Event const info = Describe(owner, event, GetId());
        if (!AscensionSkillcard::Allows(GetId(), info))
            return false;
        if (GetId() == 293200)
            return (info.Fire && GameTime::Now() >= _fireReady) ||
                (info.Shadow && GameTime::Now() >= _shadowReady);
        return true;
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* target = event.GetActionTarget();
        uint32 const helper = effect->GetSpellInfo()->Effects[EFFECT_0].TriggerSpell;
        switch (GetId())
        {
            case 284041:
            case 35102:
            case 282029:
            case 283700:
            case 283238:
            case 273595:
            case 283927:
            case 270424:
            case 283471:
            case 273121:
                Cast(owner, target, helper, effect);
                break;
            case 283465:
            {
                Player* player = owner->ToPlayer();
                if (!player || !player->FindMap())
                    break;
                ObjectGuid const guid = player->GetGUID();
                uint32 const map = player->GetMapId();
                uint32 const instance = player->GetInstanceId();
                Milliseconds const delay(std::max<int32>(1, player->movespline->Duration()));
                player->m_Events.AddEventAtOffset([guid, map, instance]()
                {
                    Player* current = ObjectAccessor::FindPlayer(guid);
                    if (!current || !current->IsAlive() || !current->FindMap() ||
                        current->GetMapId() != map || current->GetInstanceId() != instance)
                        return;
                    AuraEffect const* talent = current->GetAuraEffect(283465, EFFECT_0);
                    if (!talent)
                        return;
                    SpellInfo const* wave = sSpellMgr->GetSpellInfo(11113);
                    for (SpellInfo const* next = wave ? wave->GetNextRankSpell() : nullptr;
                        next && next->SpellLevel <= current->GetLevel(); next = next->GetNextRankSpell())
                        wave = next;
                    if (wave)
                        Cast(current, current, wave->Id, talent);
                    Cast(current, current, 283466, talent);
                }, delay);
                break;
            }
            case 277505:
                Cast(owner, owner, helper, effect);
                Cast(owner, owner, 277513, effect);
                break;
            case 277185:
                Cast(owner, owner, helper, effect);
                Cast(owner, owner, 277187, effect);
                break;
            case 277143:
                if (target)
                {
                    Cast(owner, target, helper, effect);
                    Aura* stacks = target->GetAura(helper, owner->GetGUID());
                    if (stacks && stacks->GetStackAmount() >= stacks->GetSpellInfo()->StackAmount)
                    {
                        target->RemoveAurasDueToSpell(helper, owner->GetGUID());
                        Cast(owner, target, 277145, effect);
                    }
                }
                break;
            case 281710:
            {
                Aura* old = owner->GetAura(helper);
                uint8 const charges = AscensionSkillcard::AddCharge(old ? old->GetCharges() : 0, 3);
                Cast(owner, owner, helper, effect);
                if (Aura* buff = owner->GetAura(helper))
                    buff->SetCharges(charges);
                break;
            }
            case 293200:
            {
                Event const info = Describe(owner, event, GetId());
                TimePoint const now = GameTime::Now();
                if (info.Fire && now >= _fireReady)
                {
                    _fireReady = now + Seconds(1);
                    Cast(owner, owner, 293202, effect);
                }
                if (info.Shadow && now >= _shadowReady)
                {
                    _shadowReady = now + Seconds(3);
                    Cast(owner, owner, 293203, effect);
                }
                break;
            }
            case 285780:
                if (NameOf(event.GetSpellInfo()) == "Stagger")
                {
                    Player* player = owner->ToPlayer();
                    SpellInfo const* reduction = sSpellMgr->GetSpellInfo(285782);
                    if (player && reduction)
                    {
                        auto const& cooldowns = player->GetSpellCooldownMap();
                        for (auto itr = cooldowns.begin(); itr != cooldowns.end();)
                        {
                            uint32 const id = itr->first;
                            ++itr;
                            if (NameOf(sSpellMgr->GetSpellInfo(id)) == "Colossus Smash")
                            {
                                int32 const adjustment = reduction->Effects[EFFECT_0].CalcValue(player);
                                if (AscensionSkillcard::ClearsCooldown(player->GetSpellCooldownDelay(id), adjustment))
                                    player->RemoveSpellCooldown(id, true);
                                else
                                    player->ModifySpellCooldown(id, adjustment);
                            }
                        }
                    }
                }
                else
                    Cast(owner, owner, helper, effect);
                break;
            case 274268:
                if (target)
                {
                    std::string_view const name = NameOf(event.GetSpellInfo());
                    if (name == "Javelin" || (name == "Shield Slam" && target->HasAura(274315, owner->GetGUID())))
                        Cast(owner, target, 274315, effect);
                    else if (name == "Siegebreaker" && target->HasAura(274315, owner->GetGUID()))
                    {
                        if (Player* player = owner->ToPlayer())
                        {
                            auto const& cooldowns = player->GetSpellCooldownMap();
                            for (auto itr = cooldowns.begin(); itr != cooldowns.end();)
                            {
                                uint32 const id = itr->first;
                                ++itr;
                                if (NameOf(sSpellMgr->GetSpellInfo(id)) == "Javelin")
                                    player->RemoveSpellCooldown(id, true);
                            }
                        }
                        target->RemoveAurasDueToSpell(274315, owner->GetGUID());
                    }
                }
                break;
            case 283949:
                if (target)
                    owner->AddAura(283951, target);
                break;
            default:
                Cast(owner, owner, helper, effect);
                break;
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_skillcard_proc::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_skillcard_proc::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_dark_arrows : public AuraScript
{
    PrepareAuraScript(aura_wildcard_dark_arrows);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({276843, 979012});
    }

    bool Check(ProcEventInfo& event)
    {
        return event.GetActor() == GetTarget() && event.GetDamageInfo() &&
            event.GetDamageInfo()->GetDamage() && (event.GetTypeMask() & PROC_FLAG_DONE_RANGED_AUTO_ATTACK);
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Cast(GetTarget(), event.GetActionTarget(), 276843, effect);
        Cast(GetTarget(), GetTarget(), 979012, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_dark_arrows::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_dark_arrows::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_celestial_fury : public AuraScript
{
    PrepareAuraScript(aura_wildcard_celestial_fury);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({285541}); }

    bool Check(ProcEventInfo& event)
    {
        DamageInfo* damage = event.GetDamageInfo();
        SpellInfo const* spell = event.GetSpellInfo();
        return event.GetActor() == GetTarget() && damage && damage->GetDamage() && spell &&
            (spell->GetSchoolMask() & SPELL_SCHOOL_MASK_ARCANE) &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) && spell->Id != 285541;
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Cast(owner, event.GetActionTarget(), 285541, effect);
        GetAura()->Remove();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_celestial_fury::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_celestial_fury::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_wildcard_skillcard_damage : public SpellScript
{
    PrepareSpellScript(spell_wildcard_skillcard_damage);

    void Hit()
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->IsPlayer())
            return;
        switch (GetSpellInfo()->Id)
        {
            case 285541:
                if (Aura* buff = caster->GetAura(285539))
                {
                    int32 amount = GetHitDamage();
                    AddPct(amount, buff->GetSpellInfo()->Effects[EFFECT_1].CalcValue(caster) * buff->GetStackAmount());
                    SetHitDamage(amount);
                }
                break;
            case 273123:
                if (Unit* target = GetExplTargetUnit())
                    if (target->IsPlayer())
                    {
                        SetHitDamage(CalculatePct(GetHitDamage(), 80));
                        SetHitHeal(CalculatePct(GetHitHeal(), 80));
                    }
                break;
            default:
                if (NameOf(GetSpellInfo()) == "Blast Wave")
                    if (SpellInfo const* trigger = GetSpell()->GetTriggeredByAuraSpellInfo())
                        if (trigger->Id == 283465)
                        {
                            int32 amount = GetHitDamage();
                            AddPct(amount, 40);
                            SetHitDamage(amount);
                        }
                break;
        }
    }

    void Knockback(SpellEffIndex index)
    {
        Unit* target = GetHitUnit();
        if (!target || !target->IsPlayer())
            PreventHitDefaultEffect(index);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_wildcard_skillcard_damage::Hit);
        if (m_scriptSpellId == 283472)
            OnEffectHitTarget += SpellEffectFn(spell_wildcard_skillcard_damage::Knockback,
                EFFECT_2, SPELL_EFFECT_KNOCK_BACK);
    }
};

class aura_wildcard_critical_serration : public AuraScript
{
    PrepareAuraScript(aura_wildcard_critical_serration);

    bool Validate(SpellInfo const*) override
    {
        SpellInfo const* bleed = sSpellMgr->GetSpellInfo(63468);
        return bleed && bleed->GetMaxTicks() > 0;
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        SpellInfo const* info = event.GetSpellInfo();
        DamageInfo* damage = event.GetDamageInfo();
        return owner && owner->IsPlayer() && event.GetActor() == owner && event.GetActionTarget() &&
            damage && damage->GetDamage() && (event.GetHitMask() & PROC_HIT_CRITICAL) &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) && info &&
            info->SpellFamilyName == SPELLFAMILY_ROGUE &&
            (NameOf(info) == "Shuriken Toss" || NameOf(info) == "Deadly Throw");
    }

    void Proc(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        int32 percent = 0;
        for (auto const& [id, application] : owner->GetAppliedAuras())
        {
            Aura* aura = application->GetBase();
            if (aura->GetSpellInfo()->SpellFamilyName != SPELLFAMILY_HUNTER ||
                NameOf(aura->GetSpellInfo()) != "Piercing Shots")
                continue;
            AuraEffect const* talent = aura->GetEffect(EFFECT_0);
            if (talent && talent->GetAuraType() == SPELL_AURA_PROC_TRIGGER_SPELL)
                percent = std::max(percent, talent->GetAmount());
        }
        if (percent <= 0)
            return;
        SpellInfo const* bleed = sSpellMgr->GetSpellInfo(63468);
        int64 amount = int64(event.GetDamageInfo()->GetDamage()) * percent / 100 / bleed->GetMaxTicks();
        int32 const tick = int32(std::min<int64>(amount, std::numeric_limits<int32>::max()));
        event.GetActionTarget()->CastDelayedSpellWithPeriodicAmount(owner, 63468, SPELL_AURA_PERIODIC_DAMAGE, tick);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_critical_serration::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_critical_serration::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_tribal_rage : public AuraScript
{
    PrepareAuraScript(aura_wildcard_tribal_rage);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({284462, 284463});
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        DamageInfo* damage = event.GetDamageInfo();
        return owner && owner->IsPlayer() && event.GetActor() == owner && damage && damage->GetDamage() &&
            (event.GetHitMask() & PROC_HIT_CRITICAL) && !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (event.GetTypeMask() & (PROC_FLAG_DONE_MELEE_AUTO_ATTACK | PROC_FLAG_DONE_SPELL_MELEE_DMG_CLASS))
            Cast(GetTarget(), GetTarget(), 284462, effect);
        else if (event.GetSpellInfo())
            Cast(GetTarget(), GetTarget(), 284463, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_tribal_rage::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_tribal_rage::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_cast_reaction : public AuraScript
{
    PrepareAuraScript(aura_wildcard_cast_reaction);

    bool Validate(SpellInfo const* info) override
    {
        return ValidateSpellInfo({info->Id == 280055 ? 280056u : 281111u});
    }

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (GetId() != 281110)
            return;
        Unit* caster = GetCaster();
        Unit* target = GetTarget();
        if (!caster || !target)
            return;
        target->RemoveAurasDueToSpell(281111, GetCasterGUID());
        Cast(caster, target, 281111, effect);
        if (Aura* slow = target->GetAura(281111, GetCasterGUID()))
        {
            slow->SetMaxDuration(GetDuration());
            slow->SetDuration(GetDuration());
        }
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetId() == 281110)
            GetTarget()->RemoveAurasDueToSpell(281111, GetCasterGUID());
    }

    bool Check(ProcEventInfo& event)
    {
        Spell const* spell = event.GetProcSpell();
        return event.GetActor() == GetTarget() && spell && !spell->IsTriggered();
    }

    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        if (GetId() == 280055)
            Cast(GetTarget(), GetTarget(), 280056, effect);
        else if (Aura* slow = GetTarget()->GetAura(281111, GetCasterGUID()))
        {
            slow->ModStackAmount(1);
            slow->SetDuration(GetDuration());
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_cast_reaction::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_cast_reaction::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
        AfterEffectApply += AuraEffectApplyFn(aura_wildcard_cast_reaction::Apply,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wildcard_cast_reaction::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_wildcard_clean_pass : public AuraScript
{
    PrepareAuraScript(aura_wildcard_clean_pass);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({63468, 277486});
    }

    bool Check(ProcEventInfo& event)
    {
        DamageInfo* damage = event.GetDamageInfo();
        SpellInfo const* info = event.GetSpellInfo();
        Unit* target = event.GetActionTarget();
        return GetTarget()->IsPlayer() && event.GetActor() == GetTarget() && target && info &&
            NameOf(info).starts_with("Glaive Toss") && damage && damage->GetDamage() &&
            target->GetAuraEffect(63468, EFFECT_0, GetTarget()->GetGUID());
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* target = event.GetActionTarget();
        AuraEffect* bleed = target->GetAuraEffect(63468, EFFECT_0, owner->GetGUID());
        if (!bleed)
            return;
        int64 const ticks = std::max<int64>(0, int64(bleed->GetTotalTicks()) - bleed->GetTickNumber());
        int64 const remaining = std::min<int64>(int64(std::max(bleed->GetAmount(), 0)) * ticks,
            std::numeric_limits<int32>::max());
        int64 const boosted = remaining * (100 + int64(effect->GetAmount())) / 100;
        if (boosted <= 0)
            return;
        bleed->GetBase()->Remove();
        owner->CastCustomSpell(277486, SPELLVALUE_BASE_POINT0,
            int32(std::min<int64>(boosted, std::numeric_limits<int32>::max())), target, true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_clean_pass::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_clean_pass::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

bool LightningCastWindow(Unit* owner)
{
    if (!owner || !owner->HasAura(283317) || !NamedAura(owner, "Lightning Shield"))
        return false;
    Spell* cast = owner->GetCurrentSpell(CURRENT_GENERIC_SPELL);
    return cast && !cast->IsTriggered() && cast->GetCastTime() > 0 &&
        (NameOf(cast->GetSpellInfo()) == "Lightning Bolt" || NameOf(cast->GetSpellInfo()) == "Chain Lightning");
}

class aura_wildcard_revitalize : public AuraScript
{
    PrepareAuraScript(aura_wildcard_revitalize);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({48540, 48541, 48542});
    }

    bool Check(ProcEventInfo& event)
    {
        HealInfo* heal = event.GetHealInfo();
        if (event.GetActor() != GetTarget() || !event.GetActionTarget() || !heal || !heal->GetHeal())
            return false;
        std::string_view const name = NameOf(event.GetSpellInfo());
        if (name == "Healing Touch" || name == "Regrowth")
            return true;
        return (name == "Rejuvenation" || name == "Wild Growth" || name == "Efflorescence") && roll_chance_i(15);
    }

    void Proc(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* target = event.GetActionTarget();
        uint32 helper = 0;
        Powers const power = target->getPowerType();
        if (power == POWER_ENERGY)
            helper = 48540;
        else if (power == POWER_RAGE)
            helper = 48541;
        else if (power == POWER_MANA)
            helper = 48542;
        if (helper)
        {
            int32 amount = sSpellMgr->GetSpellInfo(helper)->Effects[EFFECT_0].CalcValue(owner);
            if (power == POWER_MANA)
                amount = CalculatePct(target->GetMaxPower(POWER_MANA), amount);
            if (amount > 0)
                owner->EnergizeBySpell(target, helper, amount, power);
        }
        HealInfo* heal = event.GetHealInfo();
        Spell const* spell = event.GetProcSpell();
        if (NameOf(event.GetSpellInfo()) == "Healing Touch" && heal->GetEffectiveHeal() &&
            target->GetHealth() == target->GetMaxHealth() && spell && spell->GetPowerCost() > 0)
            owner->EnergizeBySpell(owner, GetId(), CalculatePct(spell->GetPowerCost(), 30), POWER_MANA);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_revitalize::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_revitalize::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_three_hammers : public AuraScript
{
    PrepareAuraScript(aura_wildcard_three_hammers);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({280211, 280212});
    }

    bool Check(ProcEventInfo& event)
    {
        DamageInfo* damage = event.GetDamageInfo();
        SpellInfo const* info = event.GetSpellInfo();
        return event.GetActor() == GetTarget() && damage && damage->GetDamage() &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) && info && info->Id != 280212;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_three_hammers::Check);
    }
};

class aura_wildcard_supercharged : public AuraScript
{
    PrepareAuraScript(aura_wildcard_supercharged);

    bool Check(ProcEventInfo& event)
    {
        DamageInfo* damage = event.GetDamageInfo();
        return event.GetActionTarget() == GetTarget() && damage && damage->GetDamage() &&
            !GetTarget()->HasAura(283320) && LightningCastWindow(GetTarget());
    }

    void Tick(AuraEffect const*)
    {
        if (!LightningCastWindow(GetTarget()) || GetTarget()->HasAura(283320))
            GetAura()->Remove();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_supercharged::Check);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_wildcard_supercharged::Tick, EFFECT_2, SPELL_AURA_PERIODIC_DUMMY);
    }
};

class aura_wildcard_waking_nightmare : public AuraScript
{
    PrepareAuraScript(aura_wildcard_waking_nightmare);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({284043});
    }

    bool Check(ProcEventInfo& event)
    {
        HealInfo* heal = event.GetHealInfo();
        return event.GetActionTarget() == GetTarget() && event.GetActor() && heal && heal->GetHeal();
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (Unit* caster = GetCaster())
            Cast(caster, event.GetActor(), 284043, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_waking_nightmare::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_waking_nightmare::Proc,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class wildcard_aura_lifecycle : public UnitScript
{
public:
    wildcard_aura_lifecycle() : UnitScript("wildcard_aura_lifecycle", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (unit && aura && unit->IsPlayer() && unit->HasAura(277450) && NameOf(aura->GetSpellInfo()) == "Shadow Dance")
            unit->CastSpell(unit, 277451, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        if (!unit || !application || !unit->IsPlayer())
            return;
        Aura* aura = application->GetBase();
        if (aura->GetId() == 277450)
            unit->RemoveAurasDueToSpell(277451);
        if (aura->GetId() == 283317 || NameOf(aura->GetSpellInfo()) == "Lightning Shield")
            unit->RemoveAurasDueToSpell(283318);
        if (!unit->IsAlive() || !unit->IsInWorld() || mode == AURA_REMOVE_BY_DEATH || !unit->HasAura(277450) ||
            !aura->GetSpellInfo()->HasAura(SPELL_AURA_MOD_STEALTH))
            return;
        for (AuraEffect const* stealth : unit->GetAuraEffectsByType(SPELL_AURA_MOD_STEALTH))
            if (stealth->GetBase() != aura)
                return;
        unit->CastSpell(unit, 277451, true);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* caster, int32& damage, SpellInfo const* info) override
    {
        if (!target || !caster || !info || damage <= 0 || !caster->HasAura(277450))
            return;
        Aura* buff = caster->GetAura(277451);
        std::string_view const name = NameOf(info);
        bool const thrown = name.starts_with("Deadly Throw") || name.starts_with("Shuriken Toss");
        if (!buff || (!thrown && !name.starts_with("Glaive Toss")))
            return;
        if (target->IsPlayer() && thrown)
            damage = CalculatePct(damage, 70);
        else if (target->IsCreature() && !target->IsControlledByPlayer())
            damage = int32(std::min<int64>(int64(damage) *
                (100 + int64(buff->GetSpellInfo()->Effects[EFFECT_2].CalcValue(caster))) / 100,
                std::numeric_limits<int32>::max()));
    }
};

class wildcard_card_spell_events : public AllSpellScript
{
public:
    wildcard_card_spell_events() : AllSpellScript("wildcard_card_spell_events",
        {ALLSPELLHOOK_ON_CRIT_CHANCE, ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_SPELL_CHECK_CAST,
            ALLSPELLHOOK_ON_PREPARE, ALLSPELLHOOK_ON_CAST_CANCEL, ALLSPELLHOOK_ON_CALC_MAX_DURATION,
            ALLSPELLHOOK_ON_GLOBAL_COOLDOWN}) { }

    void OnSpellGlobalCooldown(Spell* spell, int32& duration) override
    {
        Unit* caster = spell->GetCaster();
        std::string_view const name = NameOf(spell->GetSpellInfo());
        if (caster && caster->IsPlayer() && caster->HasAura(277450) && caster->HasAura(277451) &&
            (name.starts_with("Glaive Toss") || name.starts_with("Deadly Throw") || name.starts_with("Shuriken Toss")))
            duration = 500;
    }

    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        if (duration <= 0 || aura->GetType() != UNIT_AURA_TYPE ||
            !(aura->GetSpellInfo()->GetAllEffectsMechanicMask() & (uint64(1) << MECHANIC_FEAR)))
            return;
        if (AuraEffect const* nightmare = aura->GetUnitOwner()->GetAuraEffect(284043, EFFECT_0))
            duration = int32(std::min<int64>(int64(duration) * (100 + std::max<int64>(0, int64(nightmare->GetAmount()) - 100)) / 100,
                std::numeric_limits<int32>::max()));
    }

    void OnSpellPrepare(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        if (caster && caster->IsPlayer() && caster->HasAura(283317) && !caster->HasAura(283320) &&
            NamedAura(caster, "Lightning Shield") && !spell->IsTriggered() && spell->GetCastTime() > 0 &&
            (NameOf(info) == "Lightning Bolt" || NameOf(info) == "Chain Lightning"))
            caster->CastSpell(caster, 283318, true);
    }

    void OnSpellCastCancel(Spell*, Unit* caster, SpellInfo const* info, bool) override
    {
        if (caster && (NameOf(info) == "Lightning Bolt" || NameOf(info) == "Chain Lightning"))
            caster->RemoveAurasDueToSpell(283318);
    }

    void OnSpellCheckCast(Spell* spell, bool strict, SpellCastResult&) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        std::string_view const name = NameOf(info);
        if (strict && caster && caster->IsPlayer() && !spell->IsTriggered() && caster->HasAura(281687) &&
            caster->HasStealthAura() && info->SpellFamilyName == SPELLFAMILY_ROGUE &&
            (name == "Garrote" || name == "Cheap Shot" || name == "Ambush"))
            spell->SetScriptValue(281687, 1);
    }

    void OnSpellCritChance(Spell* spell, Unit*, float& chance) override
    {
        Unit* caster = spell->GetCaster();
        SpellInfo const* info = spell->GetSpellInfo();
        if (!caster || !caster->IsPlayer() || !caster->HasAura(270526) || caster->HasAura(270527) ||
            !(info->HasEffect(SPELL_EFFECT_HEAL) || info->HasEffect(SPELL_EFFECT_HEAL_PCT) ||
                info->HasEffect(SPELL_EFFECT_HEAL_MAX_HEALTH)))
            return;
        for (auto const& [id, application] : caster->GetAppliedAuras())
        {
            SpellInfo const* buff = application->GetBase()->GetSpellInfo();
            if (NameOf(buff) == "Borrowed Time" && buff->HasAura(SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK))
            {
                if (SpellInfo const* helper = sSpellMgr->GetSpellInfo(270527))
                    chance += helper->Effects[EFFECT_0].CalcValue(caster);
                return;
            }
        }
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (caster && (NameOf(info) == "Lightning Bolt" || NameOf(info) == "Chain Lightning"))
            caster->RemoveAurasDueToSpell(283318);
        if (caster && caster->IsPlayer() && caster->HasAura(281687) && spell->GetScriptValue(281687))
            caster->CastSpell(caster, 281690, true);
        if (!caster || !caster->IsPlayer() || !caster->HasAura(281542) || spell->IsTriggered() ||
            spell->GetCastTime() <= 0)
            return;
        bool const damaging = info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) ||
            info->HasEffect(SPELL_EFFECT_HEALTH_LEECH) || info->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE) ||
            info->HasEffect(SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL) ||
            info->HasEffect(SPELL_EFFECT_NORMALIZED_WEAPON_DMG) ||
            info->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE) ||
            info->HasAura(SPELL_AURA_PERIODIC_DAMAGE) || info->HasAura(SPELL_AURA_PERIODIC_LEECH);
        if (!damaging)
            return;
        Unit* target = spell->m_targets.GetUnitTarget();
        Aura* moonfire = NamedAura(target, "Moonfire", caster->GetGUID());
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(281546);
        if (!moonfire || moonfire->GetDuration() < 0 || !helper)
            return;
        int32 const extension = helper->Effects[EFFECT_0].CalcValue(caster);
        if (extension > 0)
            moonfire->SetDuration(int32(std::min<int64>(int64(moonfire->GetDuration()) + extension,
                std::numeric_limits<int32>::max())));
    }
};

class skillcard_pet_healing : public UnitScript
{
public:
    skillcard_pet_healing() : UnitScript("skillcard_pet_healing", true,
        {UNITHOOK_MODIFY_HEAL_RECEIVED}) { }

    void ModifyHealReceived(Unit* target, Unit* healer, uint32& heal, SpellInfo const* info) override
    {
        if (!heal || !healer || target != healer || !healer->IsPlayer() || !healer->FindMap() ||
            !healer->HasAura(275965) || !info || info->SpellFamilyName != SPELLFAMILY_WARLOCK ||
            NameOf(info) != "Drain Life" || !info->HasAura(SPELL_AURA_PERIODIC_LEECH))
            return;
        Unit* pet = healer->GetGuardianPet();
        if (!pet)
            pet = healer->GetCharm();
        if (!pet || !pet->IsAlive() || !pet->IsInWorld() || pet->FindMap() != healer->FindMap() ||
            pet->GetCharmerOrOwnerGUID() != healer->GetGUID())
            return;
        switch (pet->GetCreatureType())
        {
            case CREATURE_TYPE_BEAST:
            case CREATURE_TYPE_DRAGONKIN:
            case CREATURE_TYPE_DEMON:
            case CREATURE_TYPE_ELEMENTAL:
            case CREATURE_TYPE_UNDEAD:
                healer->CastCustomSpell(275981, SPELLVALUE_BASE_POINT0,
                    int32(std::min<uint32>(heal, std::numeric_limits<int32>::max())), pet, true);
                break;
            default: break;
        }
    }
};

class skillcard_bandage_healing : public UnitScript
{
public:
    skillcard_bandage_healing() : UnitScript("skillcard_bandage_healing", true,
        {UNITHOOK_MODIFY_HEAL_RECEIVED}) { }

    void ModifyHealReceived(Unit* target, Unit* healer, uint32& heal, SpellInfo const* info) override
    {
        if (!target || !healer || !healer->IsPlayer() || !info || info->Mechanic != MECHANIC_BANDAGE ||
            !healer->HasAura(283949))
            return;
        if (Aura* stack = target->GetAura(283951, healer->GetGUID()))
        {
            int32 const amount = stack->GetSpellInfo()->Effects[EFFECT_1].CalcValue(healer);
            AddPct(heal, amount * stack->GetStackAmount());
        }
    }
};

class skillcard_helper_contracts : public GlobalScript
{
public:
    skillcard_helper_contracts() : GlobalScript("skillcard_helper_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR, GLOBALHOOK_ON_SPELL_MOD_FAMILY_MASK}) { }

    void OnSpellModFamilyMask(SpellInfo const* affect, SpellInfo const* check,
        SpellModifier const*, bool& affected) override
    {
        if (affect->Id == 281547)
            affected = NameOf(check) == "Arcane Blast" || NameOf(check) == "Starfire";
        if (affect->Id == 277589)
            affected = check->Dispel == DISPEL_POISON ||
                (check->GetAllEffectsMechanicMask() & (uint64(1) << MECHANIC_BLEED));
    }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == 277451 && info->Effects[EFFECT_2].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            info->Effects[EFFECT_2].MiscValue == 38)
            for (uint8 index : {EFFECT_0, EFFECT_1, EFFECT_2})
                info->Effects[index].ApplyAuraName = SPELL_AURA_DUMMY;
        if (info->Id == 283319 && info->Effects[EFFECT_2].Effect == SPELL_EFFECT_REMOVE_AURA &&
            info->Effects[EFFECT_2].TriggerSpell == 954036)
            info->Effects[EFFECT_2].TriggerSpell = 283318;
        if (info->Id == 284043 && info->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN))
        {
            info->SpellFamilyName = SPELLFAMILY_GENERIC;
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_DAMAGE_FROM_CASTER;
            for (uint8 index : {EFFECT_0, EFFECT_1})
                info->Effects[index].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
        }
        if (info->Id == 277486 && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE)
            info->AscensionInheritsResolvedAmount = true;
        if (info->Id == 272993 && info->BaseLevel == 30 && info->SpellLevel == 0 &&
            info->Effects[EFFECT_0].RealPointsPerLevel == 12.0f)
            info->BaseLevel = 0;
        if (info->Id == 277589 && info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            info->Effects[EFFECT_0].MiscValue == SPELLMOD_DOT && !info->Effects[EFFECT_1].Effect)
        {
            SpellEffectInfo& direct = info->Effects[EFFECT_1];
            direct.Effect = SPELL_EFFECT_APPLY_AURA;
            direct.ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
            direct.BasePoints = info->Effects[EFFECT_0].BasePoints;
            direct.DieSides = info->Effects[EFFECT_0].DieSides;
            direct.MiscValue = SPELLMOD_DAMAGE;
            direct.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        }
        if (info->Id == 51687 && info->Effects[EFFECT_0].IsAura(SPELL_AURA_PROC_TRIGGER_SPELL))
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
            info->Effects[EFFECT_0].Amplitude = 2000;
            info->Effects[EFFECT_0].TriggerSpell = 0;
        }
        if (info->Id == 964992 && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_ENERGIZE &&
            info->Effects[EFFECT_0].MiscValue == POWER_MANA && info->Effects[EFFECT_0].BasePoints == 19)
            info->Effects[EFFECT_0].Effect = SPELL_EFFECT_ASCENSION_RESTORE_BASE_MANA_PCT;
        if (info->Id == 281353 && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_DUMMY &&
            info->Effects[EFFECT_1].Effect == 197)
            info->Effects[EFFECT_0].Effect = 0;
        if (info->Id == 283951 && info->Effects[EFFECT_1].IsAura(SPELL_AURA_ADD_PCT_MODIFIER))
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
        if (info->Id == 277513 && info->Effects[EFFECT_1].IsAura(SPELL_AURA_ADD_PCT_MODIFIER) &&
            info->Effects[EFFECT_1].MiscValue == SPELLMOD_IGNORE_ARMOR &&
            info->Effects[EFFECT_2].IsAura(SPELL_AURA_ADD_FLAT_MODIFIER) &&
            info->Effects[EFFECT_2].MiscValue == SPELLMOD_COOLDOWN)
            for (uint8 index : {EFFECT_1, EFFECT_2})
            {
                info->Effects[index].Effect = 0;
                info->Effects[index].ApplyAuraName = SPELL_AURA_NONE;
            }
        if (info->Id == 283701 && info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_DAMAGE_FROM_CASTER) &&
            info->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_HEALING_RECEIVED))
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_HEALING_RECEIVED;
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_HEALING_PCT;
        }
    }
};

class spell_wildcard_bandage_reset : public SpellScript
{
    PrepareSpellScript(spell_wildcard_bandage_reset);

    void Reset()
    {
        Unit* caster = GetCaster();
        Unit* target = GetExplTargetUnit();
        if (caster && target && caster->IsPlayer() && caster->HasAura(283949))
            target->RemoveAurasDueToSpell(283951, caster->GetGUID());
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_wildcard_bandage_reset::Reset);
    }
};
}

void AddSC_AscensionWildcardSkillcards()
{
    RegisterSpellScript(aura_wildcard_skillcard_proc);
    RegisterSpellScript(aura_wildcard_dark_arrows);
    RegisterSpellScript(aura_wildcard_celestial_fury);
    RegisterSpellScript(spell_wildcard_skillcard_damage);
    RegisterSpellScript(spell_wildcard_bandage_reset);
    RegisterSpellScript(aura_wildcard_critical_serration);
    RegisterSpellScript(aura_wildcard_tribal_rage);
    RegisterSpellScript(aura_wildcard_cast_reaction);
    RegisterSpellScript(aura_wildcard_clean_pass);
    RegisterSpellScript(aura_wildcard_revitalize);
    RegisterSpellScript(aura_wildcard_three_hammers);
    RegisterSpellScript(aura_wildcard_supercharged);
    RegisterSpellScript(aura_wildcard_waking_nightmare);
    new wildcard_aura_lifecycle();
    new wildcard_card_spell_events();
    new skillcard_pet_healing();
    new skillcard_bandage_healing();
    new skillcard_helper_contracts();
}
