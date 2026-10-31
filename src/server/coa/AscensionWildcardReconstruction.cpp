/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "GameTime.h"
#include "DBCStores.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "Player.h"
#include "Pet.h"
#include "UnitScript.h"
#include <list>
#include <unordered_map>
#include "SpellAuras.h"
#include <algorithm>
#include <array>
#include "Random.h"
#include "Containers.h"
#include <limits>
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellMgr.h"
#include <string_view>
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "Unit.h"

namespace
{
class aura_wildcard_vindication : public AuraScript
{
    PrepareAuraScript(aura_wildcard_vindication);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({67}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        SpellInfo const* info = event.GetSpellInfo();
        DamageInfo* damage = event.GetDamageInfo();
        return owner && owner->IsPlayer() && event.GetActor() == owner && event.GetActionTarget() &&
            info && damage && damage->GetDamage() &&
            ((info->GetSchoolMask() & SPELL_SCHOOL_MASK_HOLY) ||
                (info->SpellFamilyName == SPELLFAMILY_PALADIN && info->DmgClass == SPELL_DAMAGE_CLASS_MELEE));
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_vindication::Check);
    }
};

std::string_view ReconstructionName(SpellInfo const* info)
{
    return info && info->SpellName[LOCALE_enUS] ? info->SpellName[LOCALE_enUS] : "";
}
class aura_wildcard_battlemage : public AuraScript
{
    PrepareAuraScript(aura_wildcard_battlemage);
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({270276, 270277, 270278, 270279, 270280, 270281});
    }
    uint32 Empowerment(SpellInfo const* info) const
    {
        if (!info || info->SpellFamilyName != SPELLFAMILY_MAGE)
            return 0;
        std::string_view const name = ReconstructionName(info);
        if (name == "Arcane Blast") return 270276;
        if (name == "Fireball") return 270277;
        if (name == "Frostbolt") return 270278;
        return 0;
    }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        SpellInfo const* info = event.GetSpellInfo();
        if (!owner || !owner->IsPlayer() || event.GetActor() != owner || !info)
            return false;
        Spell const* spell = event.GetProcSpell();
        if (Empowerment(info))
            return spell && !spell->IsTriggered() && (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH);
        DamageInfo const* damage = event.GetDamageInfo();
        return info->SpellFamilyName == SPELLFAMILY_WARRIOR && event.GetActionTarget() && damage &&
            damage->GetDamage() && (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT) &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) &&
            (owner->HasAura(270276) || owner->HasAura(270277) || owner->HasAura(270278));
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        if (uint32 buff = Empowerment(event.GetSpellInfo()))
        {
            owner->CastSpell(owner, buff, true, nullptr, effect);
            return;
        }
        for (uint32 buff : {270276u, 270277u, 270278u})
            if (owner->HasAura(buff))
                owner->CastSpell(event.GetActionTarget(), buff + 3, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_battlemage::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_battlemage::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class spell_wildcard_holy_supernova : public SpellScript
{
    PrepareSpellScript(spell_wildcard_holy_supernova);
    bool Validate(SpellInfo const* info) override
    {
        return info->Id >= 270182 && info->Id <= 270190 && ValidateSpellInfo({info->Id + 12});
    }
    void HealRaid()
    {
        GetCaster()->CastSpell(GetCaster(), GetSpellInfo()->Id + 12, true);
    }
    void Register() override
    {
        AfterCast += SpellCastFn(spell_wildcard_holy_supernova::HealRaid);
    }
};

class aura_wildcard_burn_restoration : public AuraScript
{
    PrepareAuraScript(aura_wildcard_burn_restoration);
    TimePoint _ready{};
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({348, 11119, 12654, 270425, 270430, 270435});
    }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* info = event.GetSpellInfo();
        if (!owner || !owner->IsPlayer() || event.GetActor() != owner || !event.GetActionTarget() ||
            !info || !damage || !damage->GetDamage())
            return false;
        std::string_view const name = ReconstructionName(info);
        bool const periodic = event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC;
        if (GetId() == 270423)
            return (!periodic && name == "Chaos Bolt") ||
                (periodic && name == "Immolate" && (event.GetHitMask() & PROC_HIT_CRITICAL) &&
                    owner->GetAuraOfRankedSpellOrTwin(11119));
        return periodic ? ((name == "Immolate" || name == "Shadowflame") && GameTime::Now() >= _ready) :
            (name == "Chaos Bolt" || name == "Incinerate" || name == "Searing Pain" || name == "Scorch");
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* target = event.GetActionTarget();
        bool const periodic = event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC;
        if (GetId() == 270426)
        {
            if (periodic)
            {
                _ready = GameTime::Now() + Milliseconds(1000);
                owner->CastSpell(owner, 270435, true, nullptr, effect);
            }
            else
                owner->CastSpell(owner, 270425, true, nullptr, effect);
            return;
        }
        if (!periodic)
        {
            if (Aura* immolate = target->GetAuraOfRankedSpellOrTwin(348, owner->GetGUID()))
                if (immolate->GetDuration() > 0)
                {
                    SpellInfo const* helper = sSpellMgr->GetSpellInfo(270430);
                    int32 const extension = helper->Effects[EFFECT_0].CalcValue(owner);
                    immolate->SetDuration(int32(std::min<int64>(std::numeric_limits<int32>::max(),
                        int64(immolate->GetDuration()) + extension)));
                }
            return;
        }
        Aura* ignite = owner->GetAuraOfRankedSpellOrTwin(11119);
        SpellInfo const* dot = sSpellMgr->GetSpellInfo(12654);
        if (ignite && ignite->GetEffect(EFFECT_0) && dot && dot->GetMaxTicks())
        {
            int32 const amount = int32(CalculatePct(event.GetDamageInfo()->GetDamage(),
                ignite->GetEffect(EFFECT_0)->GetAmount()) / dot->GetMaxTicks());
            target->CastDelayedSpellWithPeriodicAmount(owner, 12654, SPELL_AURA_PERIODIC_DAMAGE, amount);
        }
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_burn_restoration::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_burn_restoration::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_dominant_shield : public AuraScript
{
    PrepareAuraScript(aura_wildcard_dominant_shield);
    TimePoint _penanceReady{};
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({270633, 270634}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        SpellInfo const* info = event.GetSpellInfo();
        DamageInfo const* damage = event.GetDamageInfo();
        if (GetId() == 270632 && owner && owner->IsPlayer() && event.GetActor() == owner &&
            ReconstructionName(info) == "Inner Focus")
            return event.GetProcSpell() && !event.GetProcSpell()->IsTriggered() &&
                (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH);
        if (!owner || !owner->IsPlayer() || event.GetActor() != owner || !info || !damage || !damage->GetDamage() ||
            (event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC))
            return false;
        std::string_view const name = ReconstructionName(info);
        return name == "Smite" || name == "Holy Fire" || (name == "Penance" && GameTime::Now() >= _penanceReady);
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (ReconstructionName(event.GetSpellInfo()) == "Penance")
            _penanceReady = GameTime::Now() + Milliseconds(2000);
        if (GetId() == 270632 && ReconstructionName(event.GetSpellInfo()) != "Inner Focus")
        {
            GetTarget()->CastSpell(GetTarget(), 270633, true, nullptr, effect);
            return;
        }
        GetTarget()->CastSpell(GetTarget(), 270634, true, nullptr, effect);
        if (GetId() == 270632)
            if (Aura* shield = GetTarget()->GetAura(270634))
                shield->SetStackAmount(shield->GetSpellInfo()->StackAmount);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_dominant_shield::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_dominant_shield::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

std::list<Unit*> ReconstructionAllies(Unit* caster, Unit* center, float radius, bool raidOnly)
{
    std::list<Unit*> allies;
    Acore::AnyFriendlyUnitInObjectRangeCheck check(center, caster, radius);
    Acore::UnitListSearcher<Acore::AnyFriendlyUnitInObjectRangeCheck> searcher(center, allies, check);
    Cell::VisitObjects(center, searcher, radius);
    allies.remove_if([caster, raidOnly](Unit* ally)
    {
        return !caster->IsValidAssistTarget(ally) || !caster->IsWithinLOSInMap(ally) ||
            (raidOnly && !caster->IsInRaidWith(ally));
    });
    allies.sort([](Unit* a, Unit* b) { return a->GetHealthPct() < b->GetHealthPct(); });
    return allies;
}
class aura_wildcard_atonement : public AuraScript
{
    PrepareAuraScript(aura_wildcard_atonement);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({270622, 270626}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* info = event.GetSpellInfo();
        std::string_view const name = ReconstructionName(info);
        bool const periodic = event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC;
        return owner && owner->IsPlayer() && event.GetActor() == owner && damage && damage->GetDamage() &&
            (name == "Holy Fire" || (name == "Smite" && !periodic));
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        auto allies = ReconstructionAllies(owner, owner, 30.0f, true);
        if (!allies.empty())
            owner->CastSpell(allies.front(), (event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) ? 270622 : 270626,
                true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_atonement::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_atonement::Proc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
class wildcard_growing_light : public UnitScript
{
public:
    wildcard_growing_light() : UnitScript("wildcard_growing_light", true, {UNITHOOK_ON_BEFORE_HEAL_ABSORB}) { }
    void OnBeforeHealAbsorb(HealInfo& heal) override
    {
        Unit* caster = heal.GetHealer();
        Unit* target = heal.GetTarget();
        SpellInfo const* info = heal.GetSpellInfo();
        if (!caster || !caster->IsPlayer() || !target || !info || info->Id == 270665 || !heal.GetHeal() ||
            !(info->GetSchoolMask() & SPELL_SCHOOL_MASK_HOLY) || !caster->HasAura(270661) ||
            !target->GetAuraOfRankedSpellOrTwin(53563, caster->GetGUID()))
            return;
        auto allies = ReconstructionAllies(caster, target, 8.0f, false);
        allies.remove(target);
        uint8 count = 0;
        int32 const amount = int32(CalculatePct(heal.GetHeal(), 20));
        for (Unit* ally : allies)
        {
            if (count++ == 3)
                break;
            caster->CastCustomSpell(270665, SPELLVALUE_BASE_POINT0, amount, ally, true);
        }
    }
};

class aura_wildcard_crushing_charge : public AuraScript
{
    PrepareAuraScript(aura_wildcard_crushing_charge);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({270698, 270703}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* target = event.GetActionTarget();
        SpellInfo const* info = event.GetSpellInfo();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner && owner->IsPlayer() && event.GetActor() == owner && target && info && damage &&
            damage->GetDamage() && !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) &&
            info->DmgClass == SPELL_DAMAGE_CLASS_MELEE && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) &&
            target->GetAuraOfRankedSpellOrTwin(270698, owner->GetGUID());
    }
    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), 270703, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_crushing_charge::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_crushing_charge::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_flashpoint : public AuraScript
{
    PrepareAuraScript(aura_wildcard_flashpoint);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({271121}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        SpellInfo const* info = event.GetSpellInfo();
        DamageInfo const* damage = event.GetDamageInfo();
        return owner && owner->IsPlayer() && event.GetActor() == owner && info && damage && damage->GetDamage() &&
            info->SpellFamilyName == SPELLFAMILY_HUNTER && ReconstructionName(info) == "Explosive Shot";
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_flashpoint::Check);
    }
};

class aura_wildcard_effective_heal : public AuraScript
{
    PrepareAuraScript(aura_wildcard_effective_heal);
    bool Check(ProcEventInfo& event)
    {
        HealInfo const* heal = event.GetHealInfo();
        return heal && heal->GetEffectiveHeal() > 0;
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_effective_heal::Check);
    }
};
class aura_wildcard_tree_healing : public AuraScript
{
    PrepareAuraScript(aura_wildcard_tree_healing);
    void Amount(AuraEffect const*, int32& amount, bool&)
    {
        if (Unit* owner = GetUnitOwner(); owner && owner->HasAura(271151))
            amount = 0;
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_wildcard_tree_healing::Amount,
            EFFECT_1, SPELL_AURA_ADD_PCT_MODIFIER);
    }
};

class spell_wildcard_cauterizing_heal : public SpellScript
{
    PrepareSpellScript(spell_wildcard_cauterizing_heal);
    void Heal(SpellEffIndex effect)
    {
        if (GetHitUnit()->IsImmunedToDamage(GetCaster(), GetSpellInfo()))
            PreventHitDefaultEffect(effect);
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_wildcard_cauterizing_heal::Heal, EFFECT_0, SPELL_EFFECT_HEAL);
    }
};
class aura_wildcard_cauterizing_hot : public AuraScript
{
    PrepareAuraScript(aura_wildcard_cauterizing_hot);
    void Tick(AuraEffect const*)
    {
        if (GetTarget()->IsImmunedToDamage(GetCaster(), GetSpellInfo()))
            PreventDefaultAction();
    }
    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_wildcard_cauterizing_hot::Tick,
            EFFECT_1, SPELL_AURA_PERIODIC_HEAL);
    }
};

class aura_wildcard_fingers_light_consumption : public AuraScript
{
    PrepareAuraScript(aura_wildcard_fingers_light_consumption);
    void Consume(ProcEventInfo&)
    {
        GetTarget()->RemoveAurasDueToSpell(271318);
    }
    void Register() override
    {
        AfterProc += AuraProcFn(aura_wildcard_fingers_light_consumption::Consume);
    }
};

class aura_wildcard_infused_aegis : public AuraScript
{
    PrepareAuraScript(aura_wildcard_infused_aegis);
    std::unordered_map<ObjectGuid, TimePoint> _ready;
    bool Check(ProcEventInfo& event)
    {
        Unit* enemy = event.GetActor();
        if (!enemy)
            return false;
        auto const itr = _ready.find(enemy->GetGUID());
        return itr == _ready.end() || GameTime::Now() >= itr->second;
    }
    void Mark(ProcEventInfo& event)
    {
        if (Unit* enemy = event.GetActor())
            _ready[enemy->GetGUID()] = GameTime::Now() + Milliseconds(1000);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_infused_aegis::Check);
        AfterProc += AuraProcFn(aura_wildcard_infused_aegis::Mark);
    }
};

class wildcard_vampiric_tonic_cap : public UnitScript
{
public:
    wildcard_vampiric_tonic_cap() : UnitScript("wildcard_vampiric_tonic_cap", true,
        {UNITHOOK_ON_BEFORE_HEAL_ABSORB}) { }
    void OnBeforeHealAbsorb(HealInfo& heal) override
    {
        Unit* owner = heal.GetHealer();
        SpellInfo const* info = heal.GetSpellInfo();
        if (owner && owner->IsPlayer() && owner == heal.GetTarget() && info && info->Id == 289262)
            heal.SetHeal(std::min(heal.GetHeal(), uint32(CalculatePct(owner->GetMaxHealth(), 10))));
    }
};

class aura_wildcard_glacial_pact : public AuraScript
{
    PrepareAuraScript(aura_wildcard_glacial_pact);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({271942}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Spell const* spell = event.GetProcSpell();
        std::string_view const name = ReconstructionName(event.GetSpellInfo());
        return owner && owner->IsPlayer() && event.GetActor() == owner && spell && !spell->IsTriggered() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) &&
            (name == "Ice Barrier" || name == "Summon Water Elemental");
    }
    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Unit* pet = owner->GetGuardianPet();
        if (pet && pet->IsAlive() && pet->IsInWorld() && pet->IsInMap(owner) &&
            pet->GetCharmerOrOwnerGUID() == owner->GetGUID() && (pet->GetEntry() == 510 || pet->GetEntry() == 37994))
            pet->CastSpell(pet, 271942, true, nullptr, effect, owner->GetGUID());
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_glacial_pact::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_glacial_pact::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
Unit* PackTacticsPet(Unit* owner)
{
    if (!owner || !owner->IsPlayer())
        return nullptr;
    Unit* pet = nullptr;
    if (Pet* candidate = owner->ToPlayer()->GetPet())
        if (candidate->getPetType() == HUNTER_PET || candidate->GetCreatureType() == CREATURE_TYPE_DEMON)
            pet = candidate;
    if (!pet)
    {
        pet = owner->GetCharm();
        if (pet)
            switch (pet->GetCreatureType())
            {
                case CREATURE_TYPE_BEAST:
                case CREATURE_TYPE_DEMON:
                case CREATURE_TYPE_UNDEAD:
                case CREATURE_TYPE_DRAGONKIN:
                case CREATURE_TYPE_ELEMENTAL: break;
                default: pet = nullptr; break;
            }
    }
    return pet && pet->IsAlive() && pet->IsInWorld() && pet->IsInMap(owner) &&
        pet->GetCharmerOrOwnerGUID() == owner->GetGUID() ? pet : nullptr;
}
class aura_wildcard_pack_tactics : public AuraScript
{
    PrepareAuraScript(aura_wildcard_pack_tactics);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({275097}); }
    bool Check(ProcEventInfo& event)
    {
        return event.GetActor() == GetTarget() && PackTacticsPet(GetTarget());
    }
    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        if (Unit* pet = PackTacticsPet(GetTarget()))
            GetTarget()->CastSpell(pet, 275097, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_pack_tactics::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_pack_tactics::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_blaze : public AuraScript
{
    PrepareAuraScript(aura_wildcard_blaze);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({281750}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Spell const* spell = event.GetProcSpell();
        return owner && owner->IsPlayer() && event.GetActor() == owner && spell && !spell->IsTriggered() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) &&
            ReconstructionName(event.GetSpellInfo()) == "Fire Blast" && spell->m_targets.GetUnitTarget();
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(event.GetProcSpell()->m_targets.GetUnitTarget(), 281750, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_blaze::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_blaze::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_bloody_business : public AuraScript
{
    PrepareAuraScript(aura_wildcard_bloody_business);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({277163, 277164}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Spell const* spell = event.GetProcSpell();
        SpellInfo const* info = event.GetSpellInfo();
        std::string_view const name = ReconstructionName(info);
        return owner && owner->IsPlayer() && event.GetActor() == owner && info &&
            info->SpellFamilyName == SPELLFAMILY_DRUID && spell && !spell->IsTriggered() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) && spell->m_targets.GetUnitTarget() &&
            (name == "Mangle" || name == "Mangle (Bear)" || name == "Mangle (Cat)");
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        Aura* counter = owner->GetAura(277163, owner->GetGUID());
        if (!counter || counter->GetDuration() == 0)
        {
            owner->CastSpell(owner, 277163, true, nullptr, effect);
            if (Aura* fresh = owner->GetAura(277163, owner->GetGUID()))
                fresh->SetStackAmount(1);
            return;
        }
        if (counter->GetStackAmount() < counter->GetSpellInfo()->StackAmount)
        {
            int32 const remaining = counter->GetDuration();
            counter->ModStackAmount(1);
            counter->SetDuration(remaining);
            return;
        }
        owner->CastSpell(event.GetProcSpell()->m_targets.GetUnitTarget(), 277164, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_bloody_business::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_bloody_business::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class aura_wildcard_virulent_dominion : public AuraScript
{
    PrepareAuraScript(aura_wildcard_virulent_dominion);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({288986, 288988}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        SpellInfo const* info = event.GetSpellInfo();
        if (!owner || !owner->IsPlayer() || event.GetActor() != owner || !info ||
            info->SpellFamilyName != SPELLFAMILY_DEATHKNIGHT)
            return false;
        std::string_view const name = ReconstructionName(info);
        if (name == "Pestilence")
        {
            Spell const* spell = event.GetProcSpell();
            return spell && !spell->IsTriggered() && (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) &&
                spell->m_targets.GetUnitTarget();
        }
        DamageInfo const* damage = event.GetDamageInfo();
        return name == "Scourge Strike" && damage && damage->GetDamage() && event.GetActionTarget() &&
            !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) && (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_HIT);
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        if (ReconstructionName(event.GetSpellInfo()) == "Pestilence")
            GetTarget()->CastSpell(event.GetProcSpell()->m_targets.GetUnitTarget(), 288986, true, nullptr, effect);
        else
            GetTarget()->CastSpell(event.GetActionTarget(), 288988, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_virulent_dominion::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_virulent_dominion::Proc, EFFECT_1, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class wildcard_trauma_care_snapshot : public AllSpellScript
{
public:
    wildcard_trauma_care_snapshot() : AllSpellScript("wildcard_trauma_care_snapshot",
        {ALLSPELLHOOK_ON_BEFORE_EFFECTS}) { }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        if (caster && caster->IsPlayer() && caster->HasAura(274205) && caster->HasAura(84867) &&
            !spell->IsTriggered() && info->NeedsComboPoints())
            spell->SetScriptValue(274205, caster->GetComboPoints());
    }
};
class aura_wildcard_trauma_care : public AuraScript
{
    PrepareAuraScript(aura_wildcard_trauma_care);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({274211}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Spell const* spell = event.GetProcSpell();
        return owner && owner->IsPlayer() && owner->HasAura(84867) && event.GetActor() == owner &&
            spell && !spell->IsTriggered() && spell->GetSpellInfo()->NeedsComboPoints() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) && spell->GetScriptValue(274205);
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Spell const* spell = event.GetProcSpell();
        uint32 const chance = uint32(std::min<uint64>(100,
            spell->GetScriptValue(274205) * GetSpellInfo()->ProcChance));
        if (roll_chance_i(chance))
            GetTarget()->CastSpell(GetTarget(), 274211, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_trauma_care::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_trauma_care::Proc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};
class aura_wildcard_raging_momentum : public AuraScript
{
    PrepareAuraScript(aura_wildcard_raging_momentum);
    static std::array<std::string_view, 6> const& Abilities()
    {
        static std::array<std::string_view, 6> const abilities =
        {
            "Death Wish", "Hunger for Blood", "Bloodrage", "Recklessness", "Berserker Rage", "Bestial Wrath"
        };
        return abilities;
    }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Spell const* spell = event.GetProcSpell();
        std::string_view const name = ReconstructionName(event.GetSpellInfo());
        return owner && owner->IsPlayer() && event.GetActor() == owner && spell && !spell->IsTriggered() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) &&
            std::find(Abilities().begin(), Abilities().end(), name) != Abilities().end();
    }
    void Proc(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        std::array<std::string_view, 5> choices{};
        uint8 index = 0;
        std::string_view const used = ReconstructionName(event.GetSpellInfo());
        for (std::string_view name : Abilities())
            if (name != used)
                choices[index++] = name;
        std::string_view const selected = choices[urand(0, uint32(choices.size() - 1))];
        Player* owner = GetTarget()->ToPlayer();
        for (auto const& [id, cooldown] : owner->GetSpellCooldownMap())
            if (ReconstructionName(sSpellMgr->GetSpellInfo(id)) == selected)
                owner->ModifySpellCooldown(id, -3000);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_raging_momentum::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_raging_momentum::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_arcane_thunder : public AuraScript
{
    PrepareAuraScript(aura_wildcard_arcane_thunder);
    bool Check(ProcEventInfo&) { return false; }
    void Register() override { DoCheckProc += AuraCheckProcFn(aura_wildcard_arcane_thunder::Check); }
};
class wildcard_arcane_thunder_channel : public UnitScript
{
public:
    wildcard_arcane_thunder_channel() : UnitScript("wildcard_arcane_thunder_channel", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }
    void OnAuraApply(Unit*, Aura* aura) override
    {
        if (ReconstructionName(aura->GetSpellInfo()) != "Arcane Missiles" ||
            !aura->GetSpellInfo()->IsChanneled() || aura->GetDuration() <= 0)
            return;
        Unit* caster = aura->GetCaster();
        if (caster && caster->IsPlayer() && caster->HasAura(276693))
        {
            caster->CastSpell(caster, 276695, true);
            if (Aura* replacement = caster->GetAura(276695, caster->GetGUID()))
            {
                replacement->SetMaxDuration(aura->GetDuration());
                replacement->SetDuration(aura->GetDuration());
            }
        }
    }
    void OnAuraRemove(Unit* target, AuraApplication* application, AuraRemoveMode) override
    {
        Aura* aura = application->GetBase();
        if (aura->GetId() == 276693)
            target->RemoveAurasDueToSpell(276695);
        else if (ReconstructionName(aura->GetSpellInfo()) == "Arcane Missiles" &&
            aura->GetSpellInfo()->IsChanneled())
            if (Unit* caster = aura->GetCaster())
                caster->RemoveAurasDueToSpell(276695);
    }
};
class aura_wildcard_flame_ascendance : public AuraScript
{
    PrepareAuraScript(aura_wildcard_flame_ascendance);
    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        Player* owner = GetTarget()->ToPlayer();
        SpellInfo const* shock = sSpellMgr->GetSpellInfo(8050);
        SpellInfo const* known = nullptr;
        if (!owner || !shock)
            return;
        for (SpellInfo const* rank = shock->GetFirstRankSpell(); rank; rank = rank->GetNextRankSpell())
            if (owner->HasActiveSpell(rank->Id))
                known = rank;
        if (!known)
            return;
        std::list<Unit*> targets;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(owner, owner, 10.0f);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(owner, targets, check);
        Cell::VisitObjects(owner, searcher, 10.0f);
        targets.remove_if([owner](Unit* target)
        {
            return !target->IsAlive() || !owner->IsValidAttackTarget(target) || !owner->IsWithinLOSInMap(target);
        });
        Acore::Containers::RandomResize(targets, 10);
        for (Unit* target : targets)
            owner->CastSpell(target, known, TRIGGERED_FULL_MASK, nullptr, effect);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_wildcard_flame_ascendance::Apply,
            EFFECT_0, SPELL_AURA_TRANSFORM, AURA_EFFECT_HANDLE_REAL);
    }
};
class aura_wildcard_grimfire : public AuraScript
{
    PrepareAuraScript(aura_wildcard_grimfire);
    bool Check(ProcEventInfo&) { return false; }
    void Apply(AuraEffect const*, AuraEffectHandleModes) { GetTarget()->CastSpell(GetTarget(), 278018, true); }
    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(278018);
        GetTarget()->RemoveAurasDueToSpell(278017);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_grimfire::Check);
        AfterEffectApply += AuraEffectApplyFn(aura_wildcard_grimfire::Apply,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wildcard_grimfire::Remove,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};
class wildcard_grimfire_casts : public AllSpellScript
{
public:
    wildcard_grimfire_casts() : AllSpellScript("wildcard_grimfire_casts", {ALLSPELLHOOK_ON_BEFORE_EFFECTS}) { }
    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        if (!caster || !caster->IsPlayer() || !caster->HasAura(278016) || spell->IsTriggered())
            return;
        if (ReconstructionName(info) == "Pyroblast")
            caster->CastSpell(caster, 278017, true);
        else if (ReconstructionName(info) == "Soul Fire")
            if (Unit* target = spell->m_targets.GetUnitTarget())
            {
                if (caster->HasAura(278017))
                {
                    caster->RemoveAurasDueToSpell(278017);
                    caster->CastSpell(target, 278015, true);
                }
                if (Aura* bomb = target->GetAuraOfRankedSpellOrTwin(44457, caster->GetGUID()))
                    if (SpellInfo const* extension = sSpellMgr->GetSpellInfo(278014))
                    {
                        int32 const amount = extension->Effects[EFFECT_0].CalcValue(caster);
                        int32 const duration = int32(std::min<int64>(INT32_MAX,
                            int64(bomb->GetDuration()) + amount));
                        bomb->SetMaxDuration(std::max(bomb->GetMaxDuration(), duration));
                        bomb->SetDuration(duration);
                    }
            }
    }
};
class spell_wildcard_grimfire_projectile : public SpellScript
{
    PrepareSpellScript(spell_wildcard_grimfire_projectile);
    void Damage(SpellEffIndex) { SetEffectValue(GetEffectValue() + 18 * GetCaster()->GetLevel()); }
    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_wildcard_grimfire_projectile::Damage,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

class aura_wildcard_opener_proc : public AuraScript
{
    PrepareAuraScript(aura_wildcard_opener_proc);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({284355, 286309, 286310}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        SpellInfo const* info = event.GetSpellInfo();
        if (!owner || !owner->IsPlayer() || event.GetActor() != owner || !damage || !damage->GetDamage() || !info)
            return false;
        std::string_view const name = ReconstructionName(info);
        bool const periodic = (event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) != 0;
        return GetId() == 284354 ? name == "Hemorrhage" && !periodic :
            (name == "Rake" || name == "Rip" || (name == "Shred" && !periodic));
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint32 chance = GetSpellInfo()->ProcChance;
        if (GetId() == 286308 && ReconstructionName(event.GetSpellInfo()) != "Shred")
            chance = sSpellMgr->GetSpellInfo(286310)->ProcChance;
        if (roll_chance_i(chance))
            GetTarget()->CastSpell(GetTarget(), GetId() == 284354 ? 284355 : 286309, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_opener_proc::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_opener_proc::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class spell_wildcard_opener_consume : public SpellScript
{
    PrepareSpellScript(spell_wildcard_opener_consume);
    void Consume()
    {
        if (!GetSpell()->IsTriggered())
            GetCaster()->RemoveAurasDueToSpell(ReconstructionName(GetSpellInfo()) == "Ambush" ? 284355 : 286309);
    }
    void Register() override { AfterCast += SpellCastFn(spell_wildcard_opener_consume::Consume); }
};
class aura_wildcard_sanguine_pressure : public AuraScript
{
    PrepareAuraScript(aura_wildcard_sanguine_pressure);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({288931}); }
    bool Check(ProcEventInfo& event)
    {
        Spell const* spell = event.GetProcSpell();
        return GetTarget()->IsPlayer() && event.GetActor() == GetTarget() && spell && !spell->IsTriggered() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) &&
            ReconstructionName(event.GetSpellInfo()) == "Blood Boil";
    }
    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), 288931, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_sanguine_pressure::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_sanguine_pressure::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class aura_wildcard_flow_of_life : public AuraScript
{
    PrepareAuraScript(aura_wildcard_flow_of_life);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({283965}); }
    bool Check(ProcEventInfo& event)
    {
        HealInfo const* heal = event.GetHealInfo();
        return GetTarget()->IsPlayer() && event.GetActor() == GetTarget() && heal && heal->GetHeal() &&
            event.GetActionTarget() && ReconstructionName(event.GetSpellInfo()) == "Tranquility";
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(event.GetActionTarget(), 283965, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_flow_of_life::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_flow_of_life::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class aura_wildcard_avatar_lightning : public AuraScript
{
    PrepareAuraScript(aura_wildcard_avatar_lightning);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({283692, 16166}); }
    bool Check(ProcEventInfo& event)
    {
        Spell const* spell = event.GetProcSpell();
        return GetTarget()->IsPlayer() && event.GetActor() == GetTarget() && spell && !spell->IsTriggered() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) &&
            ReconstructionName(event.GetSpellInfo()) == "Elemental Mastery";
    }
    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->RemoveAurasDueToSpell(16166);
        GetTarget()->CastSpell(GetTarget(), 283692, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_avatar_lightning::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_avatar_lightning::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class aura_wildcard_elemental_clearcasting : public AuraScript
{
    PrepareAuraScript(aura_wildcard_elemental_clearcasting);
    bool Check(ProcEventInfo& event)
    {
        Spell const* spell = event.GetProcSpell();
        SpellInfo const* info = event.GetSpellInfo();
        return event.GetActor() == GetTarget() && spell && !spell->IsTriggered() && info &&
            (info->GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC) &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH);
    }
    void Register() override { DoCheckProc += AuraCheckProcFn(aura_wildcard_elemental_clearcasting::Check); }
};

class aura_wildcard_divine_circle : public AuraScript
{
    PrepareAuraScript(aura_wildcard_divine_circle);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({271485}); }
    bool Check(ProcEventInfo& event)
    {
        Spell const* spell = event.GetProcSpell();
        std::string_view const name = ReconstructionName(event.GetSpellInfo());
        return GetTarget()->IsPlayer() && event.GetActor() == GetTarget() && spell && !spell->IsTriggered() &&
            (event.GetSpellPhaseMask() & PROC_SPELL_PHASE_FINISH) &&
            (name == "Flash Heal" || name == "Greater Heal");
    }
    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), 271485, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_divine_circle::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_divine_circle::Proc, EFFECT_2, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class spell_wildcard_divine_circle_consume : public SpellScript
{
    PrepareSpellScript(spell_wildcard_divine_circle_consume);
    void Consume()
    {
        if (!GetSpell()->IsTriggered())
            GetCaster()->RemoveAurasDueToSpell(271485);
    }
    void Register() override { AfterCast += SpellCastFn(spell_wildcard_divine_circle_consume::Consume); }
};

class aura_wildcard_pyrolysis : public AuraScript
{
    PrepareAuraScript(aura_wildcard_pyrolysis);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({271546}); }
    bool Check(ProcEventInfo& event)
    {
        DamageInfo const* damage = event.GetDamageInfo();
        return GetTarget()->IsPlayer() && event.GetActor() == GetTarget() && damage && damage->GetDamage() &&
            event.GetActionTarget() && ReconstructionName(event.GetSpellInfo()) == "Pyroblast";
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(event.GetActionTarget(), 271546, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_pyrolysis::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_pyrolysis::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class spell_wildcard_pyrolysis_refresh : public SpellScript
{
    PrepareSpellScript(spell_wildcard_pyrolysis_refresh);
    void Refresh(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Unit* target = GetHitUnit();
        if (!target)
            return;
        for (auto const& [id, application] : target->GetAppliedAuras())
        {
            Aura* aura = application->GetBase();
            SpellInfo const* info = aura->GetSpellInfo();
            if (aura->GetCasterGUID() == GetCaster()->GetGUID() && info->SpellFamilyName == SPELLFAMILY_WARLOCK &&
                (info->SpellFamilyFlags[0] & 2))
                aura->RefreshDuration();
        }
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_wildcard_pyrolysis_refresh::Refresh,
            EFFECT_0, SPELL_EFFECT_ASCENSION_LAST);
    }
};
class wildcard_decimation_pyro : public UnitScript
{
    static bool Decimation(Aura const* aura)
    {
        if (ReconstructionName(aura->GetSpellInfo()) != "Decimation")
            return false;
        for (SpellEffectInfo const& effect : aura->GetSpellInfo()->Effects)
            if (effect.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) && effect.MiscValue == SPELLMOD_CASTING_TIME)
                return true;
        return false;
    }
    static void Synchronize(Unit* target, Aura const* removed = nullptr)
    {
        if (target->HasAura(271547))
            for (auto const& [id, application] : target->GetAppliedAuras())
            {
                Aura* aura = application->GetBase();
                if (aura != removed && !aura->IsRemoved() && Decimation(aura))
                {
                    target->CastSpell(target, 271542, true);
                    if (Aura* modifier = target->GetAura(271542, target->GetGUID()))
                    {
                        modifier->SetMaxDuration(aura->GetMaxDuration());
                        modifier->SetDuration(aura->GetDuration());
                    }
                    return;
                }
            }
        target->RemoveAurasDueToSpell(271542, target->GetGUID());
    }
public:
    wildcard_decimation_pyro() : UnitScript("wildcard_decimation_pyro", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }
    void OnAuraApply(Unit* target, Aura* aura) override
    {
        if (target->IsPlayer() && (aura->GetId() == 271547 || Decimation(aura)))
            Synchronize(target);
    }
    void OnAuraRemove(Unit* target, AuraApplication* application, AuraRemoveMode) override
    {
        Aura* aura = application->GetBase();
        if (aura->GetId() == 271547)
            target->RemoveAurasDueToSpell(271542, target->GetGUID());
        else if (target->IsPlayer() && Decimation(aura))
            Synchronize(target, aura);
    }
};
class aura_wildcard_light_of_life : public AuraScript
{
    PrepareAuraScript(aura_wildcard_light_of_life);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({271490, 271493}); }
    bool Check(ProcEventInfo& event)
    {
        HealInfo const* heal = event.GetHealInfo();
        return GetTarget()->IsPlayer() && event.GetActor() == GetTarget() && heal && heal->GetHeal() &&
            event.GetActionTarget() && !(event.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }
    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        std::string_view const name = ReconstructionName(event.GetSpellInfo());
        if (name == "Halo" || name == "Halo (Circle of Life)" || name == "Halo (Circle of life)")
            GetTarget()->CastSpell(event.GetActionTarget(), 271490, true, nullptr, effect);
        if (event.GetSchoolMask() & SPELL_SCHOOL_MASK_HOLY)
            GetTarget()->CastSpell(GetTarget(), 271493, true, nullptr, effect);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_wildcard_light_of_life::Check);
        OnEffectProc += AuraEffectProcFn(aura_wildcard_light_of_life::Proc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};
class aura_wildcard_light_of_life_hot : public AuraScript
{
    PrepareAuraScript(aura_wildcard_light_of_life_hot);
    void Amount(AuraEffect const*, int32& amount, bool&)
    {
        if (Unit* caster = GetCaster())
            amount += caster->GetLevel();
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_wildcard_light_of_life_hot::Amount,
            EFFECT_0, SPELL_AURA_PERIODIC_HEAL);
    }
};
class spell_wildcard_light_of_life_renew : public SpellScript
{
    PrepareSpellScript(spell_wildcard_light_of_life_renew);
    void Extend(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (Unit* target = GetHitUnit())
            if (Aura* renew = target->GetAuraOfRankedSpellOrTwin(139, GetCaster()->GetGUID()))
                renew->SetDuration(std::min(renew->GetMaxDuration(), renew->GetDuration() + GetEffectValue()));
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_wildcard_light_of_life_renew::Extend,
            EFFECT_1, SPELL_EFFECT_ASCENSION_MODIFY_AURA_DURATION);
    }
};

class wildcard_reconstruction_contracts : public GlobalScript
{
public:
    wildcard_reconstruction_contracts() : GlobalScript("wildcard_reconstruction_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR, GLOBALHOOK_ON_SPELL_MOD_FAMILY_MASK}) { }
    void OnSpellModFamilyMask(SpellInfo const*, SpellInfo const* check, SpellModifier const* mod,
        bool& affected) override
    {
        if (mod && mod->op == SPELLMOD_RANGE && mod->value > 0 &&
            ReconstructionName(check) == "Cauterizing Fire")
            affected = false;
    }
    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == 281750)
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        if (info->Id == 281493)
        {
            info->TargetCreatureType = uint32(-1) & ~(1u << (CREATURE_TYPE_TOTEM - 1));
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.Effect == SPELL_EFFECT_ASCENSION_SPREAD_AURA)
                    effect.RadiusEntry = sSpellRadiusStore.LookupEntry(EFFECT_RADIUS_10_YARDS);
        }
        if (info->Id == 271490)
            info->Effects[EFFECT_0].RealPointsPerLevel = 0.0f;
        if (info->Id == 283965 || info->Id == 760174)
        {
            SpellEffectInfo& effect = info->Effects[EFFECT_0];
            effect.ApplyAuraName = SPELL_AURA_OVERRIDE_CLASS_SCRIPTS;
            effect.MiscValue = info->Id == 283965 ?
                ASCENSION_PERIODIC_HEAL_EXCEPT_CLASSMASK : ASCENSION_PERIODIC_HEAL_FROM_CASTER;
            effect.MiscValueB = info->Id == 283965 ? SPELL_SCHOOL_MASK_MAGIC : SPELL_SCHOOL_MASK_NATURE;
            effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
            if (info->Id == 283965)
                if (SpellInfo const* tranquility = sSpellMgr->GetSpellInfo(740))
                {
                    info->SpellFamilyName = tranquility->SpellFamilyName;
                    effect.SpellClassMask = tranquility->SpellFamilyFlags;
                }
        }
        if (info->Id == 16246)
        {
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_POWER_COST_SCHOOL_PCT;
            info->Effects[EFFECT_0].MiscValue = SPELL_SCHOOL_MASK_MAGIC;
        }
        if (info->Id == 284355 || info->Id == 286309)
        {
            info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_OVERRIDE_CLASS_SCRIPTS;
            info->Effects[EFFECT_2].MiscValue = ASCENSION_IGNORE_BEHIND_REQUIREMENT;
            info->Effects[EFFECT_2].MiscValueB = info->Id == 284355 ?
                ASCENSION_POSITION_SCOPE_MONSTERS : ASCENSION_POSITION_SCOPE_ALL;
        }
        if (info->Id == 288931)
        {
            info->Effects[EFFECT_0].MiscValue = AURA_STATE_BLEEDING;
            info->Effects[EFFECT_0].MiscValueB = ASCENSION_SCHOOLMASK_AURASTATE_DAMAGE;
        }
        if (info->Id == 288985)
            info->Effects[EFFECT_0].SpellClassMask[2] |= 0x40000000;
        if (info->Id == 275097)
            for (SpellEffectInfo& effect : info->Effects)
                if (effect.IsAura())
                    effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
        if (info->Id == 280221)
        {
            info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_DEST_TARGET_ENEMY);
            info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo(TARGET_UNIT_DEST_AREA_ENEMY);
        }
        if (info->Id == 271315 && info->Effects[EFFECT_1].IsAura(SPELL_AURA_MOD_DAMAGE_FROM_CASTER))
            info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_HEALING_RECEIVED;
        if (info->Id == 271329 && info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_DAMAGE_FROM_CASTER))
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_HEALING_RECEIVED;
        switch (info->Id)
        {
            case 271305:
            case 271307:
            case 271308:
            case 271310:
                info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_SRC_AREA_ALLY);
                info->Effects[EFFECT_0].TargetB = SpellImplicitTargetInfo();
                if (info->Id == 271308)
                {
                    info->Effects[EFFECT_1].TargetA = info->Effects[EFFECT_0].TargetA;
                    info->Effects[EFFECT_1].TargetB = info->Effects[EFFECT_0].TargetB;
                    info->Effects[EFFECT_1].RadiusEntry = info->Effects[EFFECT_0].RadiusEntry;
                }
                break;
            case 271303:
                info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
                break;
            default: break;
        }
        if (info->Id == 270391 && info->Effects[EFFECT_0].IsAura(SPELL_AURA_ADD_FLAT_MODIFIER))
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        if (info->Id >= 270194 && info->Id <= 270202 &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL &&
            info->Effects[EFFECT_2].Effect == SPELL_EFFECT_DISPEL)
        {
            info->Effects[EFFECT_2].MiscValue = DISPEL_POISON;
            info->AttributesEx |= SPELL_ATTR1_NO_THREAT;
        }
    }
};
}
void AddSC_AscensionWildcardReconstruction()
{
    RegisterSpellScript(aura_wildcard_vindication);
    RegisterSpellScript(aura_wildcard_battlemage);
    RegisterSpellScript(aura_wildcard_burn_restoration);
    RegisterSpellScript(aura_wildcard_dominant_shield);
    RegisterSpellScript(aura_wildcard_atonement);
    RegisterSpellScript(aura_wildcard_crushing_charge);
    RegisterSpellScript(aura_wildcard_flashpoint);
    RegisterSpellScript(aura_wildcard_effective_heal);
    RegisterSpellScript(aura_wildcard_tree_healing);
    RegisterSpellScript(spell_wildcard_cauterizing_heal);
    RegisterSpellScript(aura_wildcard_cauterizing_hot);
    RegisterSpellScript(aura_wildcard_fingers_light_consumption);
    RegisterSpellScript(aura_wildcard_infused_aegis);
    RegisterSpellScript(aura_wildcard_glacial_pact);
    RegisterSpellScript(aura_wildcard_pack_tactics);
    RegisterSpellScript(aura_wildcard_blaze);
    RegisterSpellScript(aura_wildcard_bloody_business);
    RegisterSpellScript(aura_wildcard_virulent_dominion);
    new wildcard_growing_light();
    new wildcard_vampiric_tonic_cap();
    RegisterSpellScript(spell_wildcard_holy_supernova);
    new wildcard_trauma_care_snapshot();
    RegisterSpellScript(aura_wildcard_trauma_care);
    RegisterSpellScript(aura_wildcard_raging_momentum);
    RegisterSpellScript(aura_wildcard_arcane_thunder);
    new wildcard_arcane_thunder_channel();
    RegisterSpellScript(aura_wildcard_flame_ascendance);
    RegisterSpellScript(aura_wildcard_grimfire);
    new wildcard_grimfire_casts();
    RegisterSpellScript(spell_wildcard_grimfire_projectile);
    RegisterSpellScript(aura_wildcard_opener_proc);
    RegisterSpellScript(spell_wildcard_opener_consume);
    RegisterSpellScript(aura_wildcard_sanguine_pressure);
    RegisterSpellScript(aura_wildcard_flow_of_life);
    RegisterSpellScript(aura_wildcard_avatar_lightning);
    RegisterSpellScript(aura_wildcard_elemental_clearcasting);
    RegisterSpellScript(aura_wildcard_divine_circle);
    RegisterSpellScript(spell_wildcard_divine_circle_consume);
    RegisterSpellScript(aura_wildcard_pyrolysis);
    RegisterSpellScript(spell_wildcard_pyrolysis_refresh);
    new wildcard_decimation_pyro();
    RegisterSpellScript(aura_wildcard_light_of_life);
    RegisterSpellScript(aura_wildcard_light_of_life_hot);
    RegisterSpellScript(spell_wildcard_light_of_life_renew);
    new wildcard_reconstruction_contracts();
}
