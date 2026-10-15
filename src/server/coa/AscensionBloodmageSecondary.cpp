/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionPooledVitality.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <list>
#include <unordered_map>
#include <vector>

namespace
{
enum BloodmageSecondarySpells : uint32
{
    SPELL_SACRIFICIAL_RITE = 800785,
    SPELL_SACRIFICIAL_RITE_HEALING = 800786,
    SPELL_VEINBURST = 504260,
    SPELL_REAVE = 800490,
    SPELL_REAVE_BLEED = 802883,
    SPELL_REAVE_EXECUTE = 802884,
    SPELL_REAVE_BACK = 805612,
    SPELL_HEMOBURST = 572855,
    SPELL_HEMOTURGY = 572856,
    SPELL_CURSED_FORM = 562720,
    SPELL_ACCURSED_FORM = 562572,
    SPELL_VAMPYRS_KISS = 504275,
    SPELL_VAMPYRS_KISS_COPY = 504785,
    SPELL_BLACK_HEART = 680731,
    SPELL_NIGHT_HUNTER = 704659,
    SPELL_BLOOD_FEAST_RESTORE = 706608,
    SPELL_ROTCLAW = 804197,
    SPELL_ROTCLAW_ENERGIZE = 805352,
    SPELL_LUNGE = 500126,
    SPELL_LUNGE_ENERGIZE = 804864,
    SPELL_BLOOD_THIRST = 706613,
    SPELL_TORTURE = 504071,
    SPELL_TORTURE_DURATION = 561152,
    SPELL_INSATIABLE = 706621,
    SPELL_INSATIABLE_STACK = 706663,
    SPELL_VAMPIRIC_FANG = 804726,
    SPELL_VAMPIRIC_FANG_SCALAR = 680753,
    SPELL_ANEURYSM = 806099,
    SPELL_ANEURYSM_HEAL = 520860,
    SPELL_KILLER_INSTINCT = 704690,
    SPELL_THIRST_FOR_BLOOD = 570023,
    SPELL_SATED = 570024,
    SPELL_RAVENOUS = 570025,
    SPELL_DARK_ESSENCE = 680732,
    SPELL_DARK_ESSENCE_HEAL = 681036,
    SPELL_BLOOD_RITUALS = 706623,
    SPELL_BLOOD_RITUALS_HEAL = 704119,
    SPELL_CURSED_FORM_REQUIREMENT = 525031,
    SPELL_CURSED_FORM_REQUIREMENT_2 = 524861,
    SPELL_VAMPIRIC_FANG_SHARE = 572373,
    SPELL_VAMPIRIC_FANG_HEAL = 572374,
    SPELL_RUNNING_WILD = 800175,
    SPELL_RUNNING_WILD_JOURNEYMAN = 520575,
    SPELL_BITE_WOUND = 706654,
    SPELL_BITE_WOUND_PERCENT = 532612
};

constexpr uint32 TORTURE_MINIMUM_THIRST_STACKS = 9;
constexpr uint32 VampiricFangRanks[] = {804726, 504093, 504094, 504095, 504096, 504097, 553271, 553272};
constexpr std::array<uint32, 10> BLOODMOON_BLAST_RANKS = {
    500125, 501607, 501608, 501609, 501610, 501611, 501612, 501613, 501614, 572332 };

class spell_ascension_bloodmage_bloodfang_bite : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_bloodfang_bite);

    bool Validate(SpellInfo const* info) override
    {
        return info->SpellFamilyName == 26 && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            ValidateSpellInfo({SPELL_BITE_WOUND});
    }

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_SON_OF_ARUGAL;
    }

    void ApplyWound()
    {
        Unit* target = GetHitUnit();
        if (target && target->IsAlive() && GetCaster()->IsValidAttackTarget(target))
            GetCaster()->CastSpell(target, SPELL_BITE_WOUND, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_ascension_bloodmage_bloodfang_bite::ApplyWound);
    }
};

class aura_ascension_bloodmage_bite_wound : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_bite_wound);

    bool Validate(SpellInfo const* info) override
    {
        return info->Id == SPELL_BITE_WOUND && info->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY) &&
            ValidateSpellInfo({SPELL_BITE_WOUND_PERCENT});
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* caster = GetCaster();
        DamageInfo const* damage = event.GetDamageInfo();
        return caster && caster->IsPlayer() && caster->getClass() == CLASS_SON_OF_ARUGAL &&
            caster->IsAlive() && caster->IsInWorld() && event.GetActor() == caster && damage &&
            damage->GetVictim() == GetTarget() && damage->GetDamage() &&
            (event.GetTypeMask() & (PROC_FLAG_TAKEN_MELEE_AUTO_ATTACK | PROC_FLAG_TAKEN_RANGED_AUTO_ATTACK));
    }

    void HealCaster(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* caster = GetCaster();
        SpellInfo const* scalar = sSpellMgr->AssertSpellInfo(SPELL_BITE_WOUND_PERCENT);
        uint32 percent = uint32(std::clamp(scalar->Effects[EFFECT_0].CalcValue(caster), 0, 100));
        uint32 heal = uint32(uint64(event.GetDamageInfo()->GetDamage()) * percent / 100);
        if (heal)
        {
            heal = caster->SpellHealingBonusTaken(caster, GetSpellInfo(), heal, HEAL);
            HealInfo healing(caster, caster, heal, GetSpellInfo(), GetSpellInfo()->GetSchoolMask());
            caster->HealBySpell(healing);
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_bloodmage_bite_wound::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_bloodmage_bite_wound::HealCaster,
            EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class aura_ascension_bloodmage_sacrificial_rite : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_sacrificial_rite);

    bool Validate(SpellInfo const* info) override
    {
        return info && info->Id == SPELL_SACRIFICIAL_RITE &&
            info->Effects[EFFECT_0].IsAura(SPELL_AURA_MOD_MELEE_RANGED_HASTE) &&
            ValidateSpellInfo({SPELL_SACRIFICIAL_RITE_HEALING});
    }

    void GrantHealing(AuraEffect const*, AuraEffectHandleModes)
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;

        Player* player = GetTarget()->ToPlayer();
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !player->IsAlive() || !player->IsInWorld())
            return;

        player->CastSpell(player, SPELL_SACRIFICIAL_RITE_HEALING, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_bloodmage_sacrificial_rite::GrantHealing,
            EFFECT_0, SPELL_AURA_MOD_MELEE_RANGED_HASTE, AURA_EFFECT_HANDLE_REAL);
    }
};

bool IsVampiricFang(uint32 id)
{
    return std::find(std::begin(VampiricFangRanks), std::end(VampiricFangRanks), id) !=
        std::end(VampiricFangRanks);
}

bool IsCursedFormAbility(SpellInfo const* info)
{
    return info->CasterAuraSpell == SPELL_CURSED_FORM_REQUIREMENT ||
        info->CasterAuraSpell == SPELL_CURSED_FORM_REQUIREMENT_2;
}

bool RankOf(uint32 id, uint32 root)
{
    return id == root || sSpellMgr->GetFirstSpellInChain(id) == root;
}

bool IsBloodmoonBlast(uint32 id)
{
    return std::find(BLOODMOON_BLAST_RANKS.begin(), BLOODMOON_BLAST_RANKS.end(), id) !=
        BLOODMOON_BLAST_RANKS.end();
}

Player* Bloodmage(Spell* spell)
{
    Player* player = spell->GetCaster()->ToPlayer();
    return player && player->getClass() == CLASS_SON_OF_ARUGAL &&
        spell->GetSpellInfo()->SpellFamilyName == 26 ? player : nullptr;
}

void CopyDamage(Player* player, Unit* target, uint32 id, uint32 damage)
{
    if (!damage)
        return;
    uint32 maximum = uint32(std::nextafter(float(std::numeric_limits<int32>::max()), 0.0f));
    player->CastCustomSpell(id, SPELLVALUE_BASE_POINT0, int32(std::min(damage, maximum)), target, true);
}

class bloodmage_secondary_casts : public AllSpellScript
{
public:
    bloodmage_secondary_casts() : AllSpellScript("bloodmage_secondary_casts",
        {ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_CALCULATED_TARGET, ALLSPELLHOOK_ON_CRIT_CHANCE,
            ALLSPELLHOOK_ON_HIT_RESULT, ALLSPELLHOOK_ON_SUCCESSFUL_INTERRUPT}) { }

    void OnSpellSuccessfulInterrupt(Spell* spell, Unit*) override
    {
        Player* player = Bloodmage(spell);
        if (!player || spell->GetSpellInfo()->Id != SPELL_ANEURYSM ||
            spell->GetScriptValue(SPELL_ANEURYSM_HEAL))
            return;
        spell->SetScriptValue(SPELL_ANEURYSM_HEAL, 1);
        player->CastSpell(player, SPELL_ANEURYSM_HEAL, true);
    }

    void OnSpellCast(Spell* spell, Unit*, SpellInfo const* info, bool) override
    {
        Player* player = Bloodmage(spell);
        if (!player || spell->IsTriggered())
            return;
        if (player->HasAura(SPELL_DARK_ESSENCE) && (IsCursedFormAbility(info) ||
            AscensionBloodmage::GetEmpowerment(info->Id) == AscensionBloodmage::Bloodbolt))
            player->CastSpell(player, SPELL_DARK_ESSENCE_HEAL, true);
        if (IsBloodmoonBlast(info->Id))
            player->CastSpell(player, SPELL_BLOOD_RITUALS_HEAL, true);
        if (!player->HasAura(SPELL_NIGHT_HUNTER))
            return;
        if (RankOf(info->Id, SPELL_VEINBURST))
        {
            if (roll_chance_i(40))
                player->RemoveSpellCooldown(info->Id, true);
        }
        else if (AscensionBloodmage::GetEmpowerment(info->Id) == AscensionBloodmage::Bloodbolt &&
            info->PowerType == POWER_RAGE && spell->GetPowerCost() > 0 && roll_chance_i(40))
            player->ModifyPower(POWER_RAGE, spell->GetPowerCost() / 2);
    }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Player* player = Bloodmage(spell);
        if (!player)
            return;
        if (target && RankOf(spell->GetSpellInfo()->Id, SPELL_HEMOBURST) &&
            target->HasAuraState(AURA_STATE_BLEEDING))
            chance = 100;
        if (AuraEffect const* instinct = player->GetAuraEffect(SPELL_KILLER_INSTINCT, EFFECT_0))
            if (instinct->IsAffectedOnSpell(spell->GetSpellInfo()))
                chance += std::min(float(player->GetPower(POWER_RAGE)) * instinct->GetAmount() / 10000.0f,
                    float(instinct->GetMiscValueB()));
    }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Bloodmage(spell);
        if (!player || !target || hit.damage <= 0 || hit.missCondition != SPELL_MISS_NONE)
            return;
        uint32 id = spell->GetSpellInfo()->Id;
        if (RankOf(id, SPELL_VEINBURST) && target->HasAuraState(AURA_STATE_BLEEDING))
        {
            hit.damage = uint32(hit.damage * 1.25f);
            hit.damageBeforeTakenMods = uint32(hit.damageBeforeTakenMods * 1.25f);
        }
        if (!spell->IsTriggered() && RankOf(id, SPELL_REAVE))
        {
            uint32 conditions = target->HasAuraState(AURA_STATE_BLEEDING) ? 1 : 0;
            if (target->HealthBelowPct(35))
                conditions |= 2;
            if (!target->HasInArc(float(M_PI), player))
                conditions |= 4;
            spell->SetScriptValue(SPELL_REAVE, conditions);
        }
        if (IsVampiricFang(id))
        {
            int32 pctPerStack = 0;
            if (SpellInfo const* scalar = sSpellMgr->GetSpellInfo(SPELL_VAMPIRIC_FANG_SCALAR))
                pctPerStack = scalar->Effects[EFFECT_2].BasePoints +
                    (scalar->Effects[EFFECT_2].DieSides ? 1 : 0);
            uint32 stacks = 0;
            if (Aura const* thirst = player->GetAura(SPELL_BLOOD_THIRST))
                stacks = thirst->GetStackAmount();
            if (stacks && pctPerStack > 0)
            {
                uint32 maximum =
                    uint32(std::nextafter(float(std::numeric_limits<int32>::max()), 0.0f));
                double mult = 1.0 + double(stacks) * double(pctPerStack) / 100.0;
                hit.damage = uint32(std::min(double(hit.damage) * mult, double(maximum)));
                hit.damageBeforeTakenMods =
                    uint32(std::min(double(hit.damageBeforeTakenMods) * mult, double(maximum)));
            }
        }
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* player = Bloodmage(spell);
        if (!player || spell->IsTriggered() || !target || miss != SPELL_MISS_NONE)
            return;
        uint32 id = spell->GetSpellInfo()->Id;
        if (target == player && (id == SPELL_CURSED_FORM || id == SPELL_ACCURSED_FORM))
            player->RemoveAurasDueToSpell(SPELL_HEMOTURGY);
        if (target == player || player->IsFriendlyTo(target))
            return;
        if (RankOf(id, SPELL_HEMOBURST) && !spell->GetScriptValue(SPELL_HEMOTURGY))
        {
            spell->SetScriptValue(SPELL_HEMOTURGY, 1);
            player->CastSpell(player, SPELL_HEMOTURGY, true);
        }
        if (RankOf(id, SPELL_ROTCLAW) && !spell->GetScriptValue(SPELL_ROTCLAW_ENERGIZE))
        {
            spell->SetScriptValue(SPELL_ROTCLAW_ENERGIZE, 1);
            player->CastSpell(player, SPELL_ROTCLAW_ENERGIZE, true);
        }
        if (RankOf(id, SPELL_LUNGE) && !spell->GetScriptValue(SPELL_LUNGE_ENERGIZE))
        {
            spell->SetScriptValue(SPELL_LUNGE_ENERGIZE, 1);
            player->CastSpell(player, SPELL_LUNGE_ENERGIZE, true);
        }
        if (IsVampiricFang(id) && !spell->GetScriptValue(SPELL_VAMPIRIC_FANG))
        {
            spell->SetScriptValue(SPELL_VAMPIRIC_FANG, 1);
            Aura const* thirst = player->GetAura(SPELL_BLOOD_THIRST);
            bool extendTransgression = player->HasAura(SPELL_TORTURE) && thirst &&
                thirst->GetStackAmount() >= TORTURE_MINIMUM_THIRST_STACKS;
            if (damage)
                Unit::DealHeal(player, player, damage);
            player->RemoveAurasDueToSpell(SPELL_BLOOD_THIRST);
            player->RemoveAurasDueToSpell(SPELL_INSATIABLE);
            player->RemoveAurasDueToSpell(SPELL_INSATIABLE_STACK);
            if (extendTransgression)
                player->CastSpell(player, SPELL_TORTURE_DURATION, true);
        }
        if (!damage)
            return;
        if (RankOf(id, SPELL_REAVE) && !spell->GetScriptValue(SPELL_REAVE_BLEED))
        {
            spell->SetScriptValue(SPELL_REAVE_BLEED, 1);
            uint32 conditions = uint32(spell->GetScriptValue(SPELL_REAVE));
            if (conditions & 1)
                CopyDamage(player, target, SPELL_REAVE_BLEED, damage);
            if (conditions & 2)
                CopyDamage(player, target, SPELL_REAVE_EXECUTE, damage);
            if (conditions & 4)
                CopyDamage(player, target, SPELL_REAVE_BACK, damage);
        }
        if (RankOf(id, SPELL_VAMPIRIC_FANG))
            if (SpellInfo const* share = sSpellMgr->GetSpellInfo(SPELL_VAMPIRIC_FANG_SHARE))
            {
                SpellEffectInfo const& effect = share->Effects[EFFECT_0];
                int32 authored = effect.BasePoints + (effect.DieSides ? 1 : 0);
                if (int32 increase = effect.CalcValue(player) - authored; increase > 0)
                {
                    uint64 heal = uint64(damage) * uint64(increase) / 100;
                    CopyDamage(player, player, SPELL_VAMPIRIC_FANG_HEAL,
                        uint32(std::min<uint64>(heal, std::numeric_limits<uint32>::max())));
                }
            }
    }
};

class bloodmage_kiss_periodic : public UnitScript
{
public:
    bloodmage_kiss_periodic() : UnitScript("bloodmage_kiss_periodic", true,
        {UNITHOOK_ON_PERIODIC_DAMAGE_RESULT}) { }

    void OnPeriodicDamageResult(Unit* target, Unit*, uint32 damage, SpellInfo const*) override
    {
        if (!target || !target->IsAlive() || !damage)
            return;
        std::vector<ObjectGuid> owners;
        for (auto const& pair : target->GetAppliedAuras())
        {
            Aura* aura = pair.second->GetBase();
            if (RankOf(aura->GetId(), SPELL_VAMPYRS_KISS) &&
                std::find(owners.begin(), owners.end(), aura->GetCasterGUID()) == owners.end())
                owners.push_back(aura->GetCasterGUID());
        }
        for (ObjectGuid const& guid : owners)
            if (Unit* unit = ObjectAccessor::GetUnit(*target, guid))
                if (Player* player = unit->ToPlayer(); player && player->getClass() == CLASS_SON_OF_ARUGAL &&
                    player->IsAlive() && player->IsInWorld() && player->InSamePhase(target) && target->IsAlive() &&
                    player->IsValidAttackTarget(target))
                {
                    CopyDamage(player, target, SPELL_VAMPYRS_KISS_COPY, damage / 4);
                    if (player->HasAura(SPELL_BLACK_HEART))
                        player->ModifyPower(POWER_RAGE, int32(player->GetMaxPower(POWER_RAGE)) / 5);
                }
    }
};

class bloodmage_secondary_contracts : public GlobalScript
{
public:
    bloodmage_secondary_contracts() : GlobalScript("bloodmage_secondary_contracts",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!info || info->SpellFamilyName != 26)
            return;
        if (info->Id == SPELL_REAVE_BLEED || info->Id == SPELL_REAVE_EXECUTE || info->Id == SPELL_REAVE_BACK ||
            info->Id == SPELL_VAMPYRS_KISS_COPY)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (info->Id == SPELL_THIRST_FOR_BLOOD &&
            info->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY && info->Effects[EFFECT_0].Amplitude)
            info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
    }
};

class aura_ascension_bloodmage_thirst_for_blood : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_thirst_for_blood);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_SATED, SPELL_RAVENOUS}); }

    void Evaluate(AuraEffect const*)
    {
        Player* player = GetTarget() ? GetTarget()->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SON_OF_ARUGAL || !player->IsAlive())
            return;
        Aura const* thirst = player->GetAura(SPELL_BLOOD_THIRST);
        uint32 stacks = thirst ? thirst->GetStackAmount() : 0;
        uint32 wanted = !stacks ? 0u : stacks <= 5 ? uint32(SPELL_SATED) : uint32(SPELL_RAVENOUS);
        for (uint32 id : {uint32(SPELL_SATED), uint32(SPELL_RAVENOUS)})
            if (id != wanted)
                player->RemoveAurasDueToSpell(id, player->GetGUID());
        if (!wanted)
            return;
        if (Aura* tier = player->GetAura(wanted, player->GetGUID()))
            tier->RefreshDuration();
        else
            player->CastSpell(player, wanted, true);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_bloodmage_thirst_for_blood::Evaluate,
            EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
    }
};

class spell_ascension_dark_essence : public SpellScript
{
    PrepareSpellScript(spell_ascension_dark_essence);

    void Select(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* object)
        {
            Unit* target = object ? object->ToUnit() : nullptr;
            return !target || !target->HasAura(SPELL_BLOOD_RITUALS);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_dark_essence::Select,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
    }
};

class spell_ascension_blood_rituals_heal : public SpellScript
{
    PrepareSpellScript(spell_ascension_blood_rituals_heal);

    void Select(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* object)
        {
            Unit* target = object ? object->ToUnit() : nullptr;
            return !target || !target->HasAura(SPELL_BLOOD_RITUALS);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_blood_rituals_heal::Select,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
    }
};

class spell_ascension_blood_feast_corpses : public SpellScript
{
    PrepareSpellScript(spell_ascension_blood_feast_corpses);

    void Select(std::list<WorldObject*>& targets)
    {
        Unit* caster = GetCaster();
        targets.remove_if([caster](WorldObject* object)
        {
            Unit* target = object ? object->ToUnit() : nullptr;
            return !target || target->IsAlive() || target == caster || caster->IsFriendlyTo(target);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_blood_feast_corpses::Select,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ENTRY);
    }
};

class spell_ascension_blood_feast_drain : public SpellScript
{
    PrepareSpellScript(spell_ascension_blood_feast_drain);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_BLOOD_FEAST_RESTORE}); }

    void Drain(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        Unit* corpse = GetHitUnit();
        if (player && player->getClass() == CLASS_SON_OF_ARUGAL && player->IsAlive() && !player->IsInCombat() &&
            corpse && !corpse->IsAlive() && corpse != player && !player->IsFriendlyTo(corpse))
            player->CastSpell(player, SPELL_BLOOD_FEAST_RESTORE, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_blood_feast_drain::Drain, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_ascension_bloodmage_blood_craving : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_blood_craving);

    void MissingRage(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        int32 misc = GetSpellInfo()->Effects[index].MiscValue;
        if (!caster || !target || !target->IsAlive() || misc < 0 || misc >= int32(MAX_POWERS))
            return;
        Powers power = Powers(misc);
        if (target->IsPlayer() && !target->CanReceivePowerFromSpell(power))
            return;
        uint32 maximum = target->GetMaxPower(power);
        uint32 current = target->GetPower(power);
        if (maximum <= current)
            return;
        if (uint32 gain = CalculatePct(maximum - current, GetEffectValue()))
            caster->EnergizeBySpell(target, GetSpellInfo()->Id, gain, power);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_bloodmage_blood_craving::MissingRage,
            EFFECT_1, SPELL_EFFECT_ENERGIZE_PCT);
    }
};
constexpr uint32 WavesOfBloodHeal = 807652;

class aura_ascension_waves_of_blood : public AuraScript
{
    PrepareAuraScript(aura_ascension_waves_of_blood);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({WavesOfBloodHeal}); }

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        return player->IsPlayer() && player->getClass() == CLASS_SON_OF_ARUGAL && player->IsAlive() &&
            player->IsInWorld() && event.GetActor() == player && damage && damage->GetDamage();
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        if (!amount)
            return;
        GetTarget()->CastCustomSpell(WavesOfBloodHeal, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), GetTarget(), TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_waves_of_blood::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_waves_of_blood::Proc, EFFECT_0, AuraType(354));
    }
};

constexpr uint32 SPELL_HEMAL_EXCISION = 803681;
constexpr uint32 SPELL_EXCISION = 803733;
constexpr uint32 SPELL_HEMAL_EXCISION_WINDOW = 803734;

struct SiphonedCurse
{
    uint32 spellId;
    ObjectGuid caster;
    int32 duration;
    uint8 stacks;
};

std::unordered_map<ObjectGuid, std::vector<SiphonedCurse>> siphonedCurses;

class spell_ascension_bloodmage_hemal_excision : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_hemal_excision);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_HEMAL_EXCISION_WINDOW}); }

    void Capture(SpellMissInfo missInfo)
    {
        _candidates.clear();
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (missInfo != SPELL_MISS_NONE || !caster || !target)
            return;
        DispelChargesList dispellable;
        target->GetDispellableAuraList(caster, SpellInfo::GetDispelMask(DISPEL_CURSE), dispellable,
            GetSpellInfo());
        for (auto const& pair : dispellable)
            if (Aura const* aura = pair.first)
                _candidates.push_back({aura->GetId(), aura->GetCasterGUID(), aura->GetDuration(),
                    aura->GetStackAmount()});
    }

    void Siphon()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Unit* target = GetHitUnit();
        if (!player || !target || _candidates.empty())
            return;
        std::vector<SiphonedCurse> taken;
        for (SiphonedCurse const& curse : _candidates)
            if (!target->GetAura(curse.spellId, curse.caster))
                taken.push_back(curse);
        if (taken.empty())
            return;
        siphonedCurses[player->GetGUID()] = taken;
        player->CastSpell(player, SPELL_HEMAL_EXCISION_WINDOW, true);
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_ascension_bloodmage_hemal_excision::Capture);
        AfterHit += SpellHitFn(spell_ascension_bloodmage_hemal_excision::Siphon);
    }

    std::vector<SiphonedCurse> _candidates;
};

class aura_ascension_bloodmage_hemal_excision : public AuraScript
{
    PrepareAuraScript(aura_ascension_bloodmage_hemal_excision);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_EXCISION}); }

    void Offer(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget() ? GetTarget()->ToPlayer() : nullptr;
        if (!player)
            return;
        if (player->GetSpellMap().find(SPELL_EXCISION) == player->GetSpellMap().end())
            player->learnSpell(SPELL_EXCISION, true);
        player->SetTemporarySpellReplacement(SPELL_HEMAL_EXCISION, SPELL_EXCISION);
    }

    void Withdraw(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = GetTarget() ? GetTarget()->ToPlayer() : nullptr;
        if (!player)
            return;
        player->SetTemporarySpellReplacement(SPELL_HEMAL_EXCISION, 0);
        if (player->GetSpellMap().find(SPELL_EXCISION) != player->GetSpellMap().end())
            player->removeSpell(SPELL_EXCISION, SPEC_MASK_ALL, true);
        siphonedCurses.erase(player->GetGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_bloodmage_hemal_excision::Offer,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_bloodmage_hemal_excision::Withdraw,
            EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_bloodmage_excision : public SpellScript
{
    PrepareSpellScript(spell_ascension_bloodmage_excision);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_HEMAL_EXCISION_WINDOW}); }

    SpellCastResult CheckWindow()
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || !player->HasAura(SPELL_HEMAL_EXCISION_WINDOW, player->GetGUID()))
            return SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
        auto itr = siphonedCurses.find(player->GetGUID());
        return itr != siphonedCurses.end() && !itr->second.empty() ?
            SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void Place(SpellEffIndex)
    {
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        Unit* target = GetHitUnit();
        if (!player || !target)
            return;
        auto itr = siphonedCurses.find(player->GetGUID());
        if (itr == siphonedCurses.end())
            return;
        for (SiphonedCurse const& curse : itr->second)
            if (Aura* aura = player->AddAura(curse.spellId, target))
            {
                if (curse.stacks > 1)
                    aura->SetStackAmount(curse.stacks);
                if (curse.duration > 0)
                    aura->SetDuration(curse.duration);
            }
        siphonedCurses.erase(itr);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_bloodmage_excision::CheckWindow);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_bloodmage_excision::Place,
            EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void SyncRunningWildJourneyman(Player* player)
{
    bool const runningWild = player->HasSpell(SPELL_RUNNING_WILD);
    bool const journeyman = player->HasSpell(SPELL_RUNNING_WILD_JOURNEYMAN);
    if (runningWild && !journeyman)
        player->learnSpell(SPELL_RUNNING_WILD_JOURNEYMAN);
    else if (!runningWild && journeyman)
        player->removeSpell(SPELL_RUNNING_WILD_JOURNEYMAN, SPEC_MASK_ALL, false);
}

class bloodmage_running_wild_journeyman : public PlayerScript
{
public:
    bloodmage_running_wild_journeyman() : PlayerScript("bloodmage_running_wild_journeyman",
        {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEARN_SPELL, PLAYERHOOK_ON_FORGOT_SPELL}) { }

    void OnPlayerLogin(Player* player) override { SyncRunningWildJourneyman(player); }

    void OnPlayerLearnSpell(Player* player, uint32 spell) override
    {
        if (spell == SPELL_RUNNING_WILD)
            SyncRunningWildJourneyman(player);
    }

    void OnPlayerForgotSpell(Player* player, uint32 spell) override
    {
        if (spell == SPELL_RUNNING_WILD)
            SyncRunningWildJourneyman(player);
    }
};
}

void AddSC_AscensionBloodmageSecondary()
{
    RegisterSpellScript(spell_ascension_bloodmage_bloodfang_bite);
    RegisterSpellScript(aura_ascension_bloodmage_bite_wound);
    RegisterSpellScript(aura_ascension_bloodmage_sacrificial_rite);
    new bloodmage_secondary_casts();
    new bloodmage_kiss_periodic();
    new bloodmage_secondary_contracts();
    RegisterSpellScript(spell_ascension_blood_rituals_heal);
    RegisterSpellScript(spell_ascension_blood_feast_corpses);
    RegisterSpellScript(spell_ascension_blood_feast_drain);
    RegisterSpellScript(spell_ascension_bloodmage_blood_craving);
    RegisterSpellScript(aura_ascension_bloodmage_thirst_for_blood);
    RegisterSpellScript(spell_ascension_dark_essence);
    RegisterSpellScript(aura_ascension_waves_of_blood);
    RegisterSpellScript(spell_ascension_bloodmage_hemal_excision);
    RegisterSpellScript(aura_ascension_bloodmage_hemal_excision);
    RegisterSpellScript(spell_ascension_bloodmage_excision);
    new bloodmage_running_wild_journeyman();
}
