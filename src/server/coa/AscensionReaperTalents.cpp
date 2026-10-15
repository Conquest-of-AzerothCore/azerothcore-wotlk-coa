/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionReaperTalents.h"
#include "CellImpl.h"
#include "GridNotifiersImpl.h"
#include "ObjectAccessor.h"
#include "Random.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>
#include <list>

namespace
{
enum ReaperTalentSpells : uint32
{
    SPELL_HARVESTER_AMOUNT = 500283,
    SPELL_BLOOD_HARVEST = 504565,
    SPELL_UNDERWALK = 800797,
    SPELL_BEYOND_THE_VEIL = 804053,
    SPELL_BEYOND_THE_VEIL_BUFF = 560591,
    SPELL_FROM_THE_SHADOWS = 561099,
    SPELL_FROM_THE_SHADOWS_CRIT = 561128,
    SPELL_REAPED_SOUL = 500363,
    SPELL_SOUL_CAPTURED = 572887,
    SPELL_SPECTRAL_WARDEN = 805716,
    SPELL_SOUL_SPLINTERS = 805719,
    SPELL_SOUL_SPLINTER = 805720,
    SPELL_PAINBRINGER = 680995,
    SPELL_PAINBRINGER_APPLY = 520533,
    SPELL_PAINBRINGER_EXTEND = 520877,
    SPELL_MASOCHISTIC_RAGE = 570097,
    SPELL_BLOOD_FRENZY_TALENT = 707899,
    SPELL_BLOOD_FRENZY = 803039,
    SPELL_HARVEST_TIME_LOW = 704188,
    SPELL_HARVEST_TIME = 803995,
    SPELL_SOUL_HARVEST_TALENT = 504012,
    SPELL_SOUL_HARVEST = 573050,
    SPELL_SPIRIT_CULLING = 301986,
    SPELL_SPECTRAL_SCYTHE = 500576,
    SPELL_FATESEALER = 705442,
    SPELL_FATESEALER_PROTECTION = 705443,
    SPELL_EATER_OF_SOULS = 805181,
    SPELL_EATER_OF_SOULS_PROTECTION = 805182,
    SPELL_DAMNED = 706786,
    SPELL_DAMNED_HASTE = 560420,
    SPELL_PURGATORY = 504046,
    SPELL_PURGATORY_DAMAGE = 504047,
    SPELL_ESSENCE_INVIGORATION = 805186,
    SPELL_ESSENCE_INVIGORATION_HEAL = 805187,
    SPELL_WEAKENED_SOULS = 92146,
    SPELL_WEAKENED_SOUL = 803433,
    SPELL_LIFE_TAP = 706788,
    SPELL_DOMINION = 803999,
    SPELL_DOMINION_ARMOR = 804000,
    SPELL_DARK_SOUL_STAMINA = 707091
};

Unit* HostileTargetInRange(Player* player, uint32 spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    Unit* target = player->GetSelectedUnit();
    if (!target)
        target = player->GetVictim();
    if (!info || !target || target == player || !target->IsAlive() ||
        !player->IsValidAttackTarget(target) ||
        !player->IsWithinDistInMap(target, info->GetMaxRange(false)))
        return nullptr;
    return target;
}

bool RollTalent(Player* player, uint32 talentId)
{
    SpellInfo const* talent = sSpellMgr->GetSpellInfo(talentId);
    return talent && player->HasAura(talentId) && roll_chance_i(int32(talent->ProcChance));
}

int32 PainbringerMilliseconds(uint32 spellId)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spellId);
    return info ? info->Effects[EFFECT_0].CalcValue() : 0;
}

void ApplyPainbringer(Player* player)
{
    if (!RollTalent(player, SPELL_PAINBRINGER))
        return;

    if (Aura* rage = player->GetAura(SPELL_MASOCHISTIC_RAGE, player->GetGUID()))
    {
        int32 const extension = PainbringerMilliseconds(SPELL_PAINBRINGER_EXTEND);
        if (extension <= 0)
            return;

        rage->SetMaxDuration(rage->GetMaxDuration() + extension);
        rage->SetDuration(rage->GetDuration() + extension);
        return;
    }

    player->CastSpell(player, SPELL_MASOCHISTIC_RAGE, true);
    int32 const duration = PainbringerMilliseconds(SPELL_PAINBRINGER_APPLY);
    if (duration <= 0)
        return;

    if (Aura* rage = player->GetAura(SPELL_MASOCHISTIC_RAGE, player->GetGUID()))
    {
        rage->SetMaxDuration(duration);
        rage->SetDuration(duration);
    }
}

void ApplySoulHarvest(Player* player)
{
    if (!RollTalent(player, SPELL_SOUL_HARVEST_TALENT))
        return;

    if (Unit* target = HostileTargetInRange(player, SPELL_SOUL_HARVEST))
        player->CastSpell(target, SPELL_SOUL_HARVEST, true);
}

void ApplySpiritCulling(Player* player)
{
    if (!RollTalent(player, SPELL_SPIRIT_CULLING))
        return;

    player->CastSpell(player, SPELL_SPECTRAL_SCYTHE, true);
}

void ApplyFatesealer(Player* player, uint8 gainedSouls)
{
    if (!player->HasAura(SPELL_FATESEALER))
        return;

    for (uint8 soul = 0; soul < gainedSouls; ++soul)
        player->CastSpell(player, SPELL_FATESEALER_PROTECTION, true);
}

void ApplyEaterOfSouls(Player* player, uint8 soulStacks)
{
    if (soulStacks == 3 && player->HasAura(SPELL_EATER_OF_SOULS) &&
        !player->HasAura(SPELL_EATER_OF_SOULS_PROTECTION))
        player->CastSpell(player, SPELL_EATER_OF_SOULS_PROTECTION, true);
}

void ApplyHarvestedSoulTalents(Player* player, uint8 soulStacks, uint8 gainedSouls)
{
    ApplyPainbringer(player);
    ApplySoulHarvest(player);
    ApplySpiritCulling(player);
    ApplyFatesealer(player, gainedSouls);
    ApplyEaterOfSouls(player, soulStacks);
}

void CastTalentTrigger(Player* player, uint32 talentId, uint32 triggerId)
{
    if (RollTalent(player, talentId))
        player->CastSpell(player, triggerId, true);
}

class aura_ascension_reaper_dark_soul : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_dark_soul);

    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({SPELL_DARK_SOUL_STAMINA}); }

    bool Load() override
    {
        Player* player = GetUnitOwner() ? GetUnitOwner()->ToPlayer() : nullptr;
        return player && player->getClass() == CLASS_REAPER && GetCasterGUID() == player->GetGUID();
    }

    void UpdateStamina()
    {
        Player* player = GetTarget()->ToPlayer();
        uint32 const rating = player->GetUInt32Value(uint32(PLAYER_FIELD_COMBAT_RATING_1) + CR_ARMOR_PENETRATION);
        if (!rating)
            player->RemoveAurasDueToSpell(SPELL_DARK_SOUL_STAMINA, player->GetGUID());
        else if (player->IsAlive() && player->IsInWorld())
            player->CastCustomSpell(SPELL_DARK_SOUL_STAMINA, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint32>(rating, std::numeric_limits<int32>::max())), player, TRIGGERED_FULL_MASK);
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        UpdateStamina();
    }

    void Tick(AuraEffect const*)
    {
        PreventDefaultAction();
        UpdateStamina();
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(SPELL_DARK_SOUL_STAMINA, GetCasterGUID());
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_reaper_dark_soul::Apply,
            EFFECT_1, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_reaper_dark_soul::Tick,
            EFFECT_1, SPELL_AURA_PERIODIC_TRIGGER_SPELL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_reaper_dark_soul::Remove,
            EFFECT_1, SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_reaper_essence_invigoration_heal : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_essence_invigoration_heal);

    void Heal(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;

        uint64 missing = target->GetMaxHealth() - std::min(target->GetHealth(), target->GetMaxHealth());
        uint64 amount = missing * std::clamp(GetEffectValue(), 0, 100) / 100;
        SetEffectValue(int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_reaper_essence_invigoration_heal::Heal,
            EFFECT_0, SPELL_EFFECT_HEAL);
    }
};

class reaper_essence_invigoration_metadata : public GlobalScript
{
public:
    reaper_essence_invigoration_metadata() : GlobalScript("reaper_essence_invigoration_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == SPELL_ESSENCE_INVIGORATION_HEAL && info->SpellFamilyName == 36 &&
            info->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL_PCT && info->Effects[EFFECT_0].MiscValueB == 1)
            info->Effects[EFFECT_0].Effect = SPELL_EFFECT_HEAL;
    }
};

class spell_ascension_soul_capture : public SpellScript
{
    PrepareSpellScript(spell_ascension_soul_capture);
    ObjectGuid _corpse;

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_SOUL_CAPTURED, SPELL_REAPED_SOUL});
    }

    bool Eligible(Unit* unit)
    {
        Unit* caster = GetCaster();
        return unit && unit != caster && !unit->IsAlive() && !caster->IsFriendlyTo(unit) &&
            !unit->HasAura(SPELL_SOUL_CAPTURED) && caster->IsInMap(unit) && caster->InSamePhase(unit) &&
            caster->IsWithinDistInMap(unit, GetSpellInfo()->Effects[EFFECT_0].CalcRadius(caster)) &&
            caster->IsWithinLOSInMap(unit);
    }

    SpellCastResult CheckCorpse()
    {
        _corpse.Clear();
        Unit* caster = GetCaster();
        std::list<Unit*> corpses;
        Acore::AnyDeadUnitCheck check;
        Acore::UnitListSearcher<Acore::AnyDeadUnitCheck> searcher(caster, corpses, check);
        Cell::VisitObjects(caster, searcher, GetSpellInfo()->Effects[EFFECT_0].CalcRadius(caster));
        for (Unit* corpse : corpses)
            if (Eligible(corpse))
            {
                _corpse = corpse->GetGUID();
                return SPELL_CAST_OK;
            }
        return SPELL_FAILED_NO_EDIBLE_CORPSES;
    }

    void SuppressTrigger(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }

    void Capture(SpellEffIndex index)
    {
        Unit* caster = GetCaster();
        Unit* corpse = ObjectAccessor::GetUnit(*caster, _corpse);
        if (!Eligible(corpse) || !caster->AddAura(SPELL_SOUL_CAPTURED, corpse))
        {
            PreventHitDefaultEffect(index);
            return;
        }
        caster->CastSpell(caster, SPELL_REAPED_SOUL, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_soul_capture::CheckCorpse);
        OnEffectLaunch += SpellEffectFn(spell_ascension_soul_capture::SuppressTrigger,
            EFFECT_ALL, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_soul_capture::SuppressTrigger,
            EFFECT_ALL, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_soul_capture::Capture, EFFECT_2, SPELL_EFFECT_HEAL_PCT);
    }
};

class aura_ascension_harvester : public AuraScript
{
    PrepareAuraScript(aura_ascension_harvester);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_HARVESTER_AMOUNT, SPELL_BLOOD_HARVEST});
    }

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* owner = GetTarget();
        Unit* victim = event.GetActionTarget();
        return owner->IsPlayer() && owner->getClass() == CLASS_REAPER && owner->IsAlive() &&
            event.GetActor() == owner && victim && victim != owner && !owner->IsFriendlyTo(victim) &&
            event.GetDamageInfo() && event.GetDamageInfo()->GetDamage();
    }

    void Heal(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        int32 percent = sSpellMgr->GetSpellInfo(SPELL_HARVESTER_AMOUNT)->Effects[EFFECT_0].CalcValue(owner);
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(percent, 0, 100) / 100;
        if (amount)
            owner->CastCustomSpell(SPELL_BLOOD_HARVEST, SPELLVALUE_BASE_POINT0,
                int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), owner, TRIGGERED_FULL_MASK);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_harvester::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_harvester::Heal, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class aura_ascension_reaper_ghastly_form : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_ghastly_form);

    static constexpr float AttackPowerCoefficient = 0.2f;

    bool Load() override { return GetUnitOwner() && GetUnitOwner()->IsPlayer(); }

    void CalculateAmount(AuraEffect const*, int32& amount, bool& canBeRecalculated)
    {
        if (Unit* owner = GetUnitOwner())
            amount += int32(owner->GetTotalAttackPowerValue(BASE_ATTACK) * AttackPowerCoefficient);

        canBeRecalculated = false;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(
            aura_ascension_reaper_ghastly_form::CalculateAmount, EFFECT_0,
            SPELL_AURA_SCHOOL_ABSORB);
    }
};

class aura_ascension_jailers_call : public AuraScript
{
    PrepareAuraScript(aura_ascension_jailers_call);

    bool CheckProc(ProcEventInfo& event)
    {
        Unit* victim = event.GetActionTarget();
        return victim && victim != GetTarget() && victim->IsAlive() && victim->HealthBelowPct(20);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_jailers_call::CheckProc);
    }
};

class aura_ascension_reaper_blood_frenzy : public AuraScript
{
    PrepareAuraScript(aura_ascension_reaper_blood_frenzy);

    Unit* FrenzyTarget() const
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !player->IsAlive())
            return nullptr;
        return HostileTargetInRange(player, SPELL_BLOOD_FRENZY);
    }

    bool CheckProc(ProcEventInfo& event)
    {
        SpellInfo const* spell = event.GetSpellInfo();
        return spell && (spell->Id == SPELL_HARVEST_TIME || spell->Id == SPELL_HARVEST_TIME_LOW) &&
            event.GetActor() == GetTarget() && FrenzyTarget() != nullptr;
    }

    void Proc(AuraEffect const* effect, ProcEventInfo&)
    {
        PreventDefaultAction();
        if (Unit* target = FrenzyTarget())
            GetTarget()->CastSpell(target, SPELL_BLOOD_FRENZY, true, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_reaper_blood_frenzy::CheckProc);
        OnEffectProc += AuraEffectProcFn(aura_ascension_reaper_blood_frenzy::Proc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_reaper_weakened_souls : public SpellScript
{
    PrepareSpellScript(spell_ascension_reaper_weakened_souls);

    bool Validate(SpellInfo const* info) override
    {
        return info && info->Effects[EFFECT_0].Effect == SPELL_EFFECT_SCHOOL_DAMAGE &&
            ValidateSpellInfo({SPELL_WEAKENED_SOUL});
    }

    void ApplyWeakenedSoul(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        if (Unit* target = GetHitUnit(); target && caster->HasAura(SPELL_WEAKENED_SOULS))
            caster->CastSpell(target, SPELL_WEAKENED_SOUL, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_reaper_weakened_souls::ApplyWeakenedSoul,
            EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

struct npc_ascension_reaper_spectral_warden : public ScriptedAI
{
    explicit npc_ascension_reaper_spectral_warden(Creature* creature) : ScriptedAI(creature) { }

    void DamageDealt(Unit*, uint32& damage, DamageEffectType, SpellSchoolMask) override
    {
        if (!damage)
            return;

        Player* owner = ObjectAccessor::GetPlayer(*me, me->GetOwnerGUID());
        if (!owner || !owner->IsAlive() || owner->getClass() != CLASS_REAPER || !owner->HasAura(SPELL_LIFE_TAP))
            return;

        SpellInfo const* lifeTap = sSpellMgr->GetSpellInfo(SPELL_LIFE_TAP);
        if (!lifeTap)
            return;

        float const healPct = lifeTap->Effects[EFFECT_0].CalcValue() / 100.0f;
        if (healPct <= 0.0f)
            return;

        Unit::DealHeal(owner, owner, uint32(float(damage) * healPct));
    }
};

class reaper_talent_events : public UnitScript
{
public:
    reaper_talent_events() : UnitScript("reaper_talent_events", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE, UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_REAPER || !aura ||
            aura->GetCasterGUID() != player->GetGUID() ||
            (aura->GetId() != SPELL_UNDERWALK && aura->GetId() != SPELL_BEYOND_THE_VEIL))
            return;

        if (player->HasAura(SPELL_UNDERWALK, player->GetGUID()) &&
            player->HasAura(SPELL_BEYOND_THE_VEIL, player->GetGUID()) &&
            !player->HasAura(SPELL_BEYOND_THE_VEIL_BUFF, player->GetGUID()))
            player->CastSpell(player, SPELL_BEYOND_THE_VEIL_BUFF, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_REAPER || !application)
            return;
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() != player->GetGUID())
            return;

        if (aura->GetId() == SPELL_UNDERWALK || aura->GetId() == SPELL_BEYOND_THE_VEIL)
            player->RemoveAurasDueToSpell(SPELL_BEYOND_THE_VEIL_BUFF, player->GetGUID());

        if (!player->IsAlive() || !player->IsInWorld() || mode == AURA_REMOVE_BY_DEATH)
            return;
        if (aura->GetId() == SPELL_UNDERWALK &&
            player->HasAura(SPELL_FROM_THE_SHADOWS))
            player->CastSpell(player, SPELL_FROM_THE_SHADOWS_CRIT, true);
    }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        if (caster && caster->IsPlayer() && caster->getClass() == CLASS_REAPER && info->Id == SPELL_SPECTRAL_WARDEN &&
            info->SpellFamilyName == 36 && index == EFFECT_1 && info->Effects[index].IsAura(SPELL_AURA_SCHOOL_ABSORB))
            value += caster->GetStat(STAT_STAMINA) * 1.5f;

        if (caster && caster->IsPlayer() && caster->getClass() == CLASS_REAPER && info->Id == SPELL_SOUL_SPLINTER &&
            info->SpellFamilyName == 36 && index == EFFECT_0 && info->Effects[index].IsAura(SPELL_AURA_PERIODIC_DAMAGE))
            value += std::max(0.0f, caster->GetStat(STAT_STAMINA)) * 0.035f;
    }
};
}

bool HandleAscensionReaperResource(Player* player, uint32 spellId, int32 amount)
{
    if (player->getClass() != CLASS_REAPER || spellId != SPELL_REAPED_SOUL)
        return false;
    Aura* aura = player->GetAura(spellId, player->GetGUID());
    uint8 previous = aura ? aura->GetStackAmount() : 0;
    if (aura)
        aura->ModStackAmount(amount);
    else if (amount > 0)
        if (Aura* created = player->AddAura(spellId, player); created && amount > 1)
            created->ModStackAmount(amount - 1);
    aura = player->GetAura(spellId, player->GetGUID());
    if (aura && aura->GetStackAmount() > previous && player->IsAlive())
    {
        uint8 const soulStacks = aura->GetStackAmount();
        if (player->HasAura(SPELL_SOUL_SPLINTERS))
            player->CastSpell(player, SPELL_SOUL_SPLINTER, true);
        ApplyHarvestedSoulTalents(player, soulStacks, soulStacks - previous);
    }
    return true;
}

void ApplyAscensionReaperSoulInfusionGained(Player* player)
{
    if (!player || player->getClass() != CLASS_REAPER || !player->IsAlive())
        return;

    CastTalentTrigger(player, SPELL_DAMNED, SPELL_DAMNED_HASTE);
    CastTalentTrigger(player, SPELL_PURGATORY, SPELL_PURGATORY_DAMAGE);
    CastTalentTrigger(player, SPELL_DOMINION, SPELL_DOMINION_ARMOR);
}

void ApplyAscensionReaperSoulInfusionSpent(Player* player)
{
    if (!player || player->getClass() != CLASS_REAPER || !player->IsAlive())
        return;

    CastTalentTrigger(player, SPELL_ESSENCE_INVIGORATION, SPELL_ESSENCE_INVIGORATION_HEAL);
}

void AddSC_AscensionReaperTalents()
{
    new reaper_essence_invigoration_metadata();
    RegisterSpellScript(spell_ascension_reaper_essence_invigoration_heal);
    RegisterSpellScript(aura_ascension_reaper_dark_soul);
    RegisterSpellScript(spell_ascension_soul_capture);
    RegisterSpellScript(aura_ascension_harvester);
    RegisterSpellScript(aura_ascension_jailers_call);
    RegisterSpellScript(aura_ascension_reaper_blood_frenzy);
    RegisterSpellScript(aura_ascension_reaper_ghastly_form);
    RegisterSpellScript(spell_ascension_reaper_weakened_souls);
    RegisterCreatureAI(npc_ascension_reaper_spectral_warden);
    new reaper_talent_events();
}
