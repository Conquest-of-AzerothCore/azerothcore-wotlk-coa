/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Creature.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Unit.h"
#include <algorithm>
#include <array>
#include <unordered_map>

namespace
{
enum HeroMageSpells : uint32
{
    DeepFreezeStun          = 844572,
    EmpoweringFrostboltBuff = 831682,
    Combustion              = 11129,
    DragonsBreath           = 31661
};

// Deep Freeze ranks and the damage each deals to targets permanently immune to stuns
constexpr std::array<std::pair<uint32, uint32>, 5> DEEP_FREEZE_DAMAGE = { { { 44572, 71757 }, { 44665, 71790 },
    { 44666, 71791 }, { 44667, 71792 }, { 44668, 71793 } } };

// Molten Shields: the reflect for the school each Ward absorbs
constexpr std::array<std::pair<uint32, uint32>, 4> WARD_REFLECT = { { { SPELL_SCHOOL_MASK_FIRE, 949389 },
    { SPELL_SCHOOL_MASK_FROST, 949392 }, { SPELL_SCHOOL_MASK_SHADOW, 949399 }, { SPELL_SCHOOL_MASK_ARCANE, 949400 } } };

constexpr int32 PLAYING_WITH_FIRE_CAP_MS = 15000;
constexpr int32 PLAYING_WITH_FIRE_EXPLOSIVE_SHOT_CAP_MS = 5000;
constexpr uint32 EXPLOSIVE_SHOT_FLAG1 = 0x80000000;
}

// Deep Freeze 44572-44668: "Stuns the target for 5 sec. Only usable on Frozen targets. Deals ... damage to monsters
// permanently immune to stuns." Spell.dbc leaves the rank a dummy effect; the stun is 844572.
class spell_hero_mage_deep_freeze : public SpellScript
{
    PrepareSpellScript(spell_hero_mage_deep_freeze);

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        Creature* creature = target->ToCreature();
        if (creature && creature->HasMechanicTemplateImmunity(1ULL << MECHANIC_STUN))
        {
            uint32 const id = GetSpellInfo()->Id;
            auto const rank = std::find_if(DEEP_FREEZE_DAMAGE.begin(), DEEP_FREEZE_DAMAGE.end(),
                [id](auto const& row) { return row.first == id; });
            if (rank != DEEP_FREEZE_DAMAGE.end())
                GetCaster()->CastSpell(target, rank->second, true);
            return;
        }
        GetCaster()->CastSpell(target, DeepFreezeStun, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_hero_mage_deep_freeze::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// Empowering Frostbolt 31682-31684: "After casting Frostbolt the critical strike damage bonus of your spells is
// increased by $s1% and your total Frost damage is increased by $s2%". The buff 831682 carries no amounts; the
// talent rank's first two effects do.
class aura_hero_mage_empowering_frostbolt : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_empowering_frostbolt);

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& /*eventInfo*/)
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        int32 critDamage = GetSpellInfo()->Effects[EFFECT_0].CalcValue(target);
        int32 frostDamage = GetSpellInfo()->Effects[EFFECT_1].CalcValue(target);
        target->CastCustomSpell(target, EmpoweringFrostboltBuff, &critDamage, &frostDamage, nullptr, true, nullptr,
            aurEff);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_hero_mage_empowering_frostbolt::HandleProc, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

// Firestarter 44442/44443: "Casting direct damaging Fire spells or abilities that have a cooldown". The class mask
// named Dragon's Breath only.
class aura_hero_mage_firestarter : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_firestarter);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return spellInfo && (spellInfo->RecoveryTime || spellInfo->CategoryRecoveryTime);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_mage_firestarter::CheckProc);
    }
};

// Frost Channeling 12519 capstone: "Killing an enemy that yields experience or honor with Frost damage will restore
// 12% of your mana." Kill procs carry no spell, so the Frost damage that left the target dead procs it.
class aura_hero_mage_frost_channeling : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_frost_channeling);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* victim = eventInfo.GetActionTarget();
        Player* player = GetTarget()->ToPlayer();
        return victim && player && !victim->IsAlive() && player->isHonorOrXPTarget(victim);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_mage_frost_channeling::CheckProc);
    }
};

// Spell Power 835583 capstone: "Dealing direct critical damage with a spell while your mana is below 50%"
class aura_hero_mage_spell_power : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_spell_power);

    bool CheckProc(ProcEventInfo& /*eventInfo*/)
    {
        Unit* target = GetTarget();
        return target->GetMaxPower(POWER_MANA) && target->GetPower(POWER_MANA) * 2 < target->GetMaxPower(POWER_MANA);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_mage_spell_power::CheckProc);
    }
};

// Molten Shields 11094/13043: "Your Fire Ward, Frost Ward, Arcane Ward and Shadow Ward spells have a 50%/100% chance
// to reflect spells from the school it wards against for 1 sec". Spell.dbc names the Fire reflect only.
class aura_hero_mage_molten_shields : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_molten_shields);

    static uint32 ReflectFor(SpellInfo const* spellInfo)
    {
        if (!spellInfo || !spellInfo->HasAura(SPELL_AURA_SCHOOL_ABSORB))
            return 0;
        for (SpellEffectInfo const& effect : spellInfo->Effects)
        {
            if (effect.ApplyAuraName != SPELL_AURA_SCHOOL_ABSORB)
                continue;
            for (auto const& [school, reflect] : WARD_REFLECT)
                if (uint32(effect.MiscValue) == school)
                    return reflect;
        }
        return 0;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return ReflectFor(eventInfo.GetSpellInfo()) != 0;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), ReflectFor(eventInfo.GetSpellInfo()), true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_mage_molten_shields::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_hero_mage_molten_shields::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

// Playing with Fire 31638/31639: "Dealing direct magic damage now has a $h% chance to reduce the cooldown of your
// Combustion and Dragon's Breath by 1 second, doubled when dealing critical strikes. Dragon's Breath cannot reduce its
// own cooldown. Up to 15 seconds reduction. Max 5 seconds reduction for Explosive Shot." The proc aura triggers
// nothing in Spell.dbc.
class aura_hero_mage_playing_with_fire : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_playing_with_fire);

    struct Reduced
    {
        int32 Total = 0;
        int32 ExplosiveShot = 0;
    };

    std::unordered_map<uint32, Reduced> _reduced;

    static bool IsDragonsBreath(SpellInfo const* spellInfo)
    {
        return spellInfo->GetFirstRankSpell()->Id == DragonsBreath;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        return spellInfo && !(spellInfo->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) && !IsDragonsBreath(spellInfo) &&
            GetTarget()->IsPlayer();
    }

    void Reduce(Player* player, uint32 spellId, int32 ms, bool explosiveShot)
    {
        if (!player->HasSpellCooldown(spellId))
        {
            _reduced.erase(spellId);
            return;
        }
        Reduced& reduced = _reduced[spellId];
        ms = std::min(ms, PLAYING_WITH_FIRE_CAP_MS - reduced.Total);
        if (explosiveShot)
            ms = std::min(ms, PLAYING_WITH_FIRE_EXPLOSIVE_SHOT_CAP_MS - reduced.ExplosiveShot);
        if (ms <= 0)
            return;
        reduced.Total += ms;
        if (explosiveShot)
            reduced.ExplosiveShot += ms;
        player->ModifySpellCooldown(spellId, -ms);
    }

    void HandleProc(AuraEffect const* /*aurEff*/, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        SpellInfo const* spellInfo = eventInfo.GetSpellInfo();
        bool const crit = eventInfo.GetHitMask() & PROC_EX_CRITICAL_HIT;
        bool const explosiveShot = spellInfo->SpellFamilyName == SPELLFAMILY_HUNTER &&
            (spellInfo->SpellFamilyFlags[1] & EXPLOSIVE_SHOT_FLAG1);
        int32 const ms = crit ? 2000 : 1000;
        Reduce(player, Combustion, ms, explosiveShot);
        for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(DragonsBreath); rank; rank = rank->GetNextRankSpell())
            if (player->HasSpell(rank->Id))
                Reduce(player, rank->Id, ms, explosiveShot);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_mage_playing_with_fire::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_hero_mage_playing_with_fire::HandleProc, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

// Power Surge 828577: "empowering the absorption amount of your next Mana Shield by $828577s2%", per stack
class aura_hero_mage_power_surge_mana_shield : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_power_surge_mana_shield);

    void AfterApply(AuraEffect const* aurEff, AuraEffectHandleModes /*mode*/)
    {
        Unit* caster = GetCaster();
        Aura* surge = caster ? caster->GetAura(828577) : nullptr;
        if (!surge)
            return;
        int32 const pct = surge->GetSpellInfo()->Effects[EFFECT_1].CalcValue(caster) * surge->GetStackAmount();
        const_cast<AuraEffect*>(aurEff)->ChangeAmount(aurEff->GetAmount() * (100 + pct) / 100);
        surge->Remove();
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_hero_mage_power_surge_mana_shield::AfterApply, EFFECT_0,
            SPELL_AURA_MANA_SHIELD, AURA_EFFECT_HANDLE_REAL);
    }
};

void AddSC_AscensionHeroMage()
{
    RegisterSpellScript(spell_hero_mage_deep_freeze);
    RegisterSpellScript(aura_hero_mage_empowering_frostbolt);
    RegisterSpellScript(aura_hero_mage_firestarter);
    RegisterSpellScript(aura_hero_mage_frost_channeling);
    RegisterSpellScript(aura_hero_mage_spell_power);
    RegisterSpellScript(aura_hero_mage_molten_shields);
    RegisterSpellScript(aura_hero_mage_playing_with_fire);
    RegisterSpellScript(aura_hero_mage_power_surge_mana_shield);
}
