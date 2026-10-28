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

constexpr std::array<std::pair<uint32, uint32>, 5> DEEP_FREEZE_DAMAGE = { { { 44572, 71757 }, { 44665, 71790 },
    { 44666, 71791 }, { 44667, 71792 }, { 44668, 71793 } } };

constexpr std::array<std::pair<uint32, uint32>, 4> WARD_REFLECT = { { { SPELL_SCHOOL_MASK_FIRE, 949389 },
    { SPELL_SCHOOL_MASK_FROST, 949392 }, { SPELL_SCHOOL_MASK_SHADOW, 949399 }, { SPELL_SCHOOL_MASK_ARCANE, 949400 } } };

constexpr int32 PLAYING_WITH_FIRE_CAP_MS = 15000;
constexpr int32 PLAYING_WITH_FIRE_EXPLOSIVE_SHOT_CAP_MS = 5000;
constexpr uint32 EXPLOSIVE_SHOT_FLAG1 = 0x80000000;
}

class spell_hero_mage_deep_freeze : public SpellScript
{
    PrepareSpellScript(spell_hero_mage_deep_freeze);

    void HandleDummy(SpellEffIndex)
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

class aura_hero_mage_empowering_frostbolt : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_empowering_frostbolt);

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo&)
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

class aura_hero_mage_spell_power : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_spell_power);

    bool CheckProc(ProcEventInfo&)
    {
        Unit* target = GetTarget();
        return target->GetMaxPower(POWER_MANA) && target->GetPower(POWER_MANA) * 2 < target->GetMaxPower(POWER_MANA);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_hero_mage_spell_power::CheckProc);
    }
};

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

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
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

class aura_hero_mage_power_surge_mana_shield : public AuraScript
{
    PrepareAuraScript(aura_hero_mage_power_surge_mana_shield);

    void AfterApply(AuraEffect const* aurEff, AuraEffectHandleModes)
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
