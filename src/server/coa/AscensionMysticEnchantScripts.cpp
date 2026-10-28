/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CellImpl.h"
#include "Containers.h"
#include "GridNotifiers.h"
#include "GameTime.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "Pet.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Spell.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "UnitScript.h"
#include <array>
#include <list>
#include <unordered_map>

namespace
{
enum MysticEnchantScriptSpells : uint32
{
    SPELL_DREAD_COMMUNION                  = 1180473,
    SPELL_RENEWED_THROUGH_ABSOLUTION_HEAL  = 1571424,
    SPELL_WEAKENED_SOUL                    = 1106788,
    SPELL_ATONEMENT_SINGLE_HEAL            = 1567779,
    SPELL_ATONEMENT_PENANCE_HEAL           = 1567780,
    SPELL_ATONEMENT_BUFF                   = 1567778,
    SPELL_FURY_OF_THE_WIND_JUMP            = 1590418,
    SPELL_FURY_OF_THE_WIND_SELF            = 1590421,
    SPELL_ELUNES_FURY_CRIT                 = 1583365,
    SPELL_SHADOW_FUNNEL                    = 1180900,
    SPELL_SHADOW_FUNNEL_PET                = 1180901,
    SPELL_LIGHTNING_CHARGED                = 1180161,
    NPC_FERAL_SPIRIT_WOLF                  = 1129264,
    SPELL_DEMONIC_WHIRL_WHIRLWIND          = 1180111,
    SPELL_VAMPIRIC_DEATH                   = 1180080,
    SPELL_VAMPIRIC_DEATH_HERO              = 278087,
    SPELL_VAMPIRIC_DEATH_HERO_CRIT         = 278086,
    SPELL_VAMPIRIC_DEATH_DAMAGE            = 1180081,
    SPELL_SHADOW_WORD_DEATH_BACKLASH_STOCK = 32409,
    SPELL_CORRUPTION_R1                    = 172,
    SPELL_CORRUPTED_SHIV                   = 285943,
    SPELL_NIGHTMARE_MAULING                = 271401,
    SPELL_GROWING_CORRUPTION               = 283922,
    SPELL_WIDOWMAKER                       = 979019,
    SPELL_WIDOWMAKER_PROC                  = 979041,
    SPELL_WIDOWHAIL                        = 979058,
    SPELL_PHYSICS_IN_PRACTICE              = 277460,
    SPELL_CRYOTHERAPIST                    = 271313,
    SPELL_CRYOTHERAPIST_BOLT               = 271310,
    SPELL_CRYOTHERAPIST_DEEP_FREEZE        = 271308,
    SPELL_CRYOTHERAPIST_ICY_PENANCE        = 271307,
    SPELL_SHADOW_WORD_DEATH_BACKLASH       = 1132409,
    SPELL_ARCANE_CONDUIT                   = 1181430,
    SPELL_ARCANE_SURGE                     = 1181431,
    SPELL_ARCANE_CONDUIT_TRIGGER           = 1181434,
    SPELL_SHATTERED_RENEWAL                = 1181000,
    SPELL_SHATTERED_RENEWAL_MANA           = 1181001,
    SPELL_SHATTERED_RENEWAL_WEAKENED_SOUL  = 1181002,
    SPELL_SAVAGE_ROAR                      = 1152610,
    SPELL_PURITY_OF_LIGHT                  = 1581027,
    SPELL_SURGE_OF_LIGHT                   = 1133151,
    SPELL_SURGE_OF_LIGHT_PURE              = 1333151,
    SPELL_WATER_NOVA_POOL                  = 1569715,
    SPELL_WATER_NOVA_ELECTRIFIED           = 1569735,
    SPELL_FEEDING_THE_ABYSS                = 1154364,
    SPELL_FEEDING_THE_ABYSS_VISUAL         = 1154362,
    SPELL_FEEDING_THE_ABYSS_STORED         = 1154365,
    SPELL_ABYSSAL_ERUPTION_READY           = 1154366,
    SPELL_ABYSSAL_ERUPTION                 = 1154367,
    SPELL_BLESSING_DIVINES                 = 1571467,
    SPELL_BLESSING_RADIANCE                = 1571470,
    SPELL_BLESSING_MENDING                 = 1571471,
    SPELL_CAUTERIZE_BURN                   = 1181411,
    SPELL_CAUTERIZE_SLOW_CLEAR             = 1181413,
    SPELL_HEAVY_THUNDER                    = 1181080,
    SPELL_HEAVY_THUNDER_COUNTER            = 1181081,
    SPELL_HEAVY_THUNDER_EMPOWERED          = 1181082,
};

constexpr uint32 PRIEST_RENEW_FLAG0 = 0x40;
constexpr uint32 PRIEST_PENANCE_FLAG1 = 0x8000;
constexpr uint32 PRIEST_SHIELD_FLAG0 = 0x1;
constexpr uint32 PRIEST_VAMPIRIC_TOUCH_FLAG1 = 0x400;
constexpr uint32 PRIEST_SHADOW_WORD_PAIN_FLAG0 = 0x8000;
constexpr uint32 PRIEST_ICY_PENANCE_FLAG1 = 0x800000;
constexpr uint32 MAGE_DEEP_FREEZE_FLAG1 = 0x100000;
constexpr uint32 ROGUE_DEADLY_THROW_FLAG1 = 0x1;
constexpr uint32 ROGUE_SHURIKEN_TOSS_FLAG2 = 0x40000000;
constexpr uint32 ROGUE_SPRINT_FLAG0 = 0x40;
constexpr int32 PHYSICS_IN_PRACTICE_PVP_PCT = 15;
constexpr uint32 WARLOCK_HEALTH_FUNNEL_FLAG0 = 0x1000000;
constexpr uint32 WARLOCK_LIFE_TAP_FLAG0 = 0x40000;
constexpr uint32 SHAMAN_FROST_SHOCK_FLAG0 = 0x80000000;
constexpr uint32 WARRIOR_THUNDER_CLAP_FLAG0 = 0x80;
constexpr uint8 PURITY_OF_LIGHT_MAX_CHARGES = 2;
constexpr int32 FEEDING_THE_ABYSS_BASE_CHANCE = 10;
constexpr int32 ELUNES_FURY_PER_HIT_MS = 1000;
constexpr int32 ELUNES_FURY_MAX_MS = 60000;
constexpr int32 SAVAGE_FRENZY_EXTENSION_MS = 6000;
constexpr float FURY_OF_THE_WIND_RANGE = 8.0f;
constexpr Milliseconds SHATTERED_RENEWAL_COOLDOWN = 1s;
constexpr Milliseconds CAUTERIZE_COOLDOWN = 1min;
constexpr uint32 CAUTERIZE_HEALTH_PCT = 35;
constexpr uint32 SHIELD_MASTERS_RESOLVE_HEALTH_PCT = 50;

uint32 CorruptionRank(Unit const* caster)
{
    uint32 rank = SPELL_CORRUPTION_R1;
    Player const* player = caster->ToPlayer();
    for (SpellInfo const* spell = sSpellMgr->GetSpellInfo(SPELL_CORRUPTION_R1); player && spell; spell = spell->GetNextRankSpell())
        if (player->HasSpell(spell->Id))
            rank = spell->Id;
    return rank;
}

bool IsPriestSpell(SpellInfo const* spell, uint32 flag0, uint32 flag1)
{
    return spell && spell->SpellFamilyName == SPELLFAMILY_PRIEST &&
        ((flag0 && (spell->SpellFamilyFlags[0] & flag0)) || (flag1 && (spell->SpellFamilyFlags[1] & flag1)));
}

class AscensionMysticEnchantHealShare final : public UnitScript
{
public:
    AscensionMysticEnchantHealShare() : UnitScript("AscensionMysticEnchantHealShare", true,
        { UNITHOOK_MODIFY_HEAL_RECEIVED, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_AURA_APPLY,
          UNITHOOK_ON_AURA_REMOVE, UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN }) { }

    void ModifyHealReceived(Unit* target, Unit*, uint32& heal, SpellInfo const*) override
    {
        if (!heal || !target || !target->IsPlayer())
            return;
        AuraEffect const* share = target->GetAuraEffect(SPELL_DREAD_COMMUNION, EFFECT_0);
        Pet* pet = share ? target->ToPlayer()->GetPet() : nullptr;
        if (!pet || !pet->IsAlive() || pet->IsFullHealth())
            return;
        SpellInfo const* spellInfo = share->GetSpellInfo();
        HealInfo healInfo(target, pet, CalculatePct(heal, 25), spellInfo, spellInfo->GetSchoolMask());
        target->HealBySpell(healInfo);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (!spellInfo || target != attacker || (spellInfo->Id != SPELL_SHADOW_WORD_DEATH_BACKLASH &&
            spellInfo->Id != SPELL_SHADOW_WORD_DEATH_BACKLASH_STOCK))
            return;
        AuraEffect const* reduction = target->GetAuraEffect(SPELL_VAMPIRIC_DEATH, EFFECT_1);
        if (!reduction)
            reduction = target->GetAuraEffect(SPELL_VAMPIRIC_DEATH_HERO, EFFECT_1);
        if (reduction)
            damage = uint32(uint64(damage) * uint32(std::max(0, 100 + reduction->GetAmount())) / 100);
    }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (aura->GetId() == SPELL_SURGE_OF_LIGHT && unit->HasAura(SPELL_PURITY_OF_LIGHT))
        {
            ApplyPureSurge(unit);
            return;
        }
        if (aura->GetId() == SPELL_FEEDING_THE_ABYSS_STORED)
            return;
        if (!IsHealthFunnel(aura->GetSpellInfo()) || !IsVoidwalker(unit))
            return;
        Unit* caster = aura->GetCaster();
        if (caster && caster->HasAura(SPELL_SHADOW_FUNNEL))
            unit->CastSpell(unit, SPELL_SHADOW_FUNNEL_PET, true);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        Aura const* aura = application->GetBase();
        if (aura->GetId() == SPELL_FEEDING_THE_ABYSS_STORED && mode == AURA_REMOVE_BY_EXPIRE &&
            AbyssStored.contains(unit->GetGUID()))
        {
            unit->CastSpell(unit, SPELL_ABYSSAL_ERUPTION_READY, true);
            return;
        }
        if (IsHealthFunnel(aura->GetSpellInfo()) && IsVoidwalker(unit))
            unit->RemoveAurasDueToSpell(SPELL_SHADOW_FUNNEL_PET);

        if (mode != AURA_REMOVE_BY_ENEMY_SPELL || !IsPriestSpell(aura->GetSpellInfo(), PRIEST_SHIELD_FLAG0, 0) ||
            !aura->GetSpellInfo()->HasAura(SPELL_AURA_SCHOOL_ABSORB))
            return;
        Unit* caster = aura->GetCaster();
        if (!caster || !caster->HasAura(SPELL_SHATTERED_RENEWAL))
            return;
        TimePoint const now = GameTime::Now();
        TimePoint& ready = ShieldBreakReady[caster->GetGUID()];
        if (now < ready)
            return;
        ready = now + SHATTERED_RENEWAL_COOLDOWN;
        caster->CastSpell(caster, SPELL_SHATTERED_RENEWAL_MANA, true);
    }

    void ModifyMeleeDamage(Unit* target, Unit*, uint32& damage) override
    {
        Hunger(target, damage);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        HeavyThunder(attacker, damage, spellInfo);
        PhysicsInPractice(target, attacker, damage, spellInfo);
        if (!spellInfo || !(spellInfo->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) || damage <= 0)
            return;
        uint32 amount = uint32(damage);
        Hunger(target, amount);
        damage = int32(amount);
    }

    static std::unordered_map<ObjectGuid, uint32> AbyssStored;

private:
    static void PhysicsInPractice(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo)
    {
        if (!attacker || damage <= 0 || !spellInfo || spellInfo->SpellFamilyName != SPELLFAMILY_ROGUE ||
            !attacker->HasAura(SPELL_PHYSICS_IN_PRACTICE) ||
            !((spellInfo->SpellFamilyFlags[1] & ROGUE_DEADLY_THROW_FLAG1) ||
              (spellInfo->SpellFamilyFlags[2] & ROGUE_SHURIKEN_TOSS_FLAG2)))
            return;
        AuraEffect const* sprint = attacker->GetAuraEffect(SPELL_AURA_MOD_INCREASE_SPEED, SPELLFAMILY_ROGUE,
            ROGUE_SPRINT_FLAG0, 0, 0);
        if (!sprint || sprint->GetAmount() <= 0)
            return;
        int32 pct = sprint->GetAmount();
        if (target && target->IsPlayer())
            pct = CalculatePct(pct, PHYSICS_IN_PRACTICE_PVP_PCT);
        AddPct(damage, pct);
    }

    static void HeavyThunder(Unit* attacker, int32& damage, SpellInfo const* spellInfo)
    {
        Player* player = attacker ? attacker->ToPlayer() : nullptr;
        if (!player || damage <= 0 || !spellInfo || spellInfo->SpellFamilyName != SPELLFAMILY_WARRIOR ||
            !(spellInfo->SpellFamilyFlags[0] & WARRIOR_THUNDER_CLAP_FLAG0))
            return;
        AuraEffect const* heavy = player->GetAuraEffect(SPELL_HEAVY_THUNDER, EFFECT_0);
        Item const* mainHand = heavy ? player->GetWeaponForAttack(BASE_ATTACK, true) : nullptr;
        if (mainHand && mainHand->GetTemplate()->InventoryType == INVTYPE_2HWEAPON &&
            !player->GetWeaponForAttack(OFF_ATTACK, true))
            AddPct(damage, heavy->GetAmount());
    }

    static void Hunger(Unit* target, uint32& damage)
    {
        Player* player = target ? target->ToPlayer() : nullptr;
        if (!damage || !player || !player->HasAura(SPELL_FEEDING_THE_ABYSS))
            return;
        float const chance = FEEDING_THE_ABYSS_BASE_CHANCE +
            player->GetFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + uint32(SPELL_SCHOOL_SHADOW));
        if (!roll_chance_f(chance))
            return;
        AbyssStored[player->GetGUID()] += damage;
        damage = 0;
        player->CastSpell(player, SPELL_FEEDING_THE_ABYSS_VISUAL, true);
        if (!player->HasAura(SPELL_FEEDING_THE_ABYSS_STORED))
            player->CastSpell(player, SPELL_FEEDING_THE_ABYSS_STORED, true);
    }

    static void ApplyPureSurge(Unit* unit)
    {
        unit->RemoveAurasDueToSpell(SPELL_SURGE_OF_LIGHT);
        if (Aura* pure = unit->GetAura(SPELL_SURGE_OF_LIGHT_PURE))
        {
            pure->SetCharges(std::min<uint8>(pure->GetCharges() + 1, PURITY_OF_LIGHT_MAX_CHARGES));
            pure->RefreshDuration();
            return;
        }
        if (Aura* pure = unit->AddAura(SPELL_SURGE_OF_LIGHT_PURE, unit))
            pure->SetCharges(1);
    }

    static bool IsHealthFunnel(SpellInfo const* spell)
    {
        return spell->SpellFamilyName == SPELLFAMILY_WARLOCK && (spell->SpellFamilyFlags[0] & WARLOCK_HEALTH_FUNNEL_FLAG0) &&
            spell->HasAura(SPELL_AURA_PERIODIC_HEAL);
    }

    static bool IsVoidwalker(Unit const* unit)
    {
        Creature const* creature = unit->ToCreature();
        return creature && creature->IsPet() && creature->GetCreatureTemplate()->family == CREATURE_FAMILY_VOIDWALKER;
    }

    std::unordered_map<ObjectGuid, TimePoint> ShieldBreakReady;
};

std::unordered_map<ObjectGuid, uint32> AscensionMysticEnchantHealShare::AbyssStored;

class AscensionMysticEnchantLifeTap final : public PlayerScript
{
public:
    AscensionMysticEnchantLifeTap() : PlayerScript("AscensionMysticEnchantLifeTap", { PLAYERHOOK_ON_SPELL_CAST }) { }

    void OnPlayerSpellCast(Player* player, Spell* spell, bool) override
    {
        SpellInfo const* info = spell->GetSpellInfo();
        if (info->SpellFamilyName != SPELLFAMILY_WARLOCK || !(info->SpellFamilyFlags[0] & WARLOCK_LIFE_TAP_FLAG0) ||
            !player->HasAura(SPELL_ABYSSAL_ERUPTION_READY))
            return;
        auto const itr = AscensionMysticEnchantHealShare::AbyssStored.find(player->GetGUID());
        int32 const stored = itr == AscensionMysticEnchantHealShare::AbyssStored.end() ? 0 : int32(itr->second);
        AscensionMysticEnchantHealShare::AbyssStored.erase(player->GetGUID());
        player->RemoveAurasDueToSpell(SPELL_ABYSSAL_ERUPTION_READY);
        SpellInfo const* store = sSpellMgr->GetSpellInfo(SPELL_FEEDING_THE_ABYSS_STORED);
        SpellInfo const* eruption = sSpellMgr->GetSpellInfo(SPELL_ABYSSAL_ERUPTION);
        if (stored <= 0 || !store || !eruption)
            return;
        int32 const bonus = std::min<int32>(CalculatePct(stored, store->Effects[EFFECT_1].BasePoints),
            int32(player->GetMaxHealth()));
        std::array<int32, MAX_SPELL_EFFECTS> amounts{};
        for (uint8 effect = 0; effect < MAX_SPELL_EFFECTS; ++effect)
            amounts[effect] = eruption->Effects[effect].CalcValue(player) + bonus;
        player->CastCustomSpell(player, SPELL_ABYSSAL_ERUPTION, &amounts[EFFECT_0], &amounts[EFFECT_1],
            &amounts[EFFECT_2], true);
    }
};

class spell_ascension_mystic_water_nova : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_water_nova);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        if (!spell)
            return;
        if (spell->SpellFamilyName == SPELLFAMILY_SHAMAN && (spell->SpellFamilyFlags[0] & SHAMAN_FROST_SHOCK_FLAG0))
        {
            if (Unit* target = eventInfo.GetActionTarget())
                caster->CastSpell(target, SPELL_WATER_NOVA_POOL, true);
            return;
        }
        if (DynamicObject* pool = caster->GetDynObject(SPELL_WATER_NOVA_POOL))
        {
            float const x = pool->GetPositionX(), y = pool->GetPositionY(), z = pool->GetPositionZ();
            caster->RemoveDynObject(SPELL_WATER_NOVA_POOL);
            caster->CastSpell(x, y, z, SPELL_WATER_NOVA_ELECTRIFIED, true);
        }
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_water_nova::HandleProc, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_renewed_through_absolution : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_renewed_through_absolution);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        if (!target)
            return;
        AuraEffect* renew = target->GetAuraEffect(SPELL_AURA_PERIODIC_HEAL, SPELLFAMILY_PRIEST, PRIEST_RENEW_FLAG0, 0, 0,
            caster->GetGUID());
        if (!renew)
            return;
        renew->GetBase()->Remove();
        caster->CastSpell(target, SPELL_RENEWED_THROUGH_ABSOLUTION_HEAL, true);
        if (Aura* weakenedSoul = target->GetAura(SPELL_WEAKENED_SOUL))
        {
            int32 const duration = weakenedSoul->GetDuration() - 3000;
            if (duration <= 0)
                weakenedSoul->Remove();
            else
                weakenedSoul->SetDuration(duration);
        }
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_renewed_through_absolution::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_atonement : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_atonement);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        bool const penance = IsPriestSpell(eventInfo.GetSpellInfo(), 0, PRIEST_PENANCE_FLAG1);
        caster->CastSpell(caster, penance ? SPELL_ATONEMENT_PENANCE_HEAL : SPELL_ATONEMENT_SINGLE_HEAL, true);
        caster->CastSpell(caster, SPELL_ATONEMENT_BUFF, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_atonement::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_atonement_heal : public SpellScript
{
    PrepareSpellScript(spell_ascension_mystic_atonement_heal);

    void SelectLowest(std::list<WorldObject*>& targets)
    {
        targets.clear();
        Player* caster = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!caster)
            return;
        float const radius = GetSpellInfo()->Effects[EFFECT_0].CalcRadius(caster);
        std::list<Unit*> allies;
        auto consider = [&](Unit* unit)
        {
            if (unit && unit->IsAlive() && unit->IsInMap(caster) && caster->IsWithinDistInMap(unit, radius) &&
                caster->IsValidAssistTarget(unit))
                allies.push_back(unit);
        };
        auto considerWithPet = [&](Player* player)
        {
            consider(player);
            consider(player->GetPet());
        };
        if (Group* group = caster->GetGroup())
        {
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
                if (Player* member = ref->GetSource())
                    considerWithPet(member);
        }
        else
            considerWithPet(caster);

        allies.sort(Acore::HealthPctOrderPred());
        uint32 const count = std::max<uint32>(GetSpellInfo()->MaxAffectedTargets, 1);
        for (Unit* ally : allies)
        {
            if (targets.size() >= count)
                break;
            targets.push_back(ally);
        }
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_mystic_atonement_heal::SelectLowest,
            EFFECT_ALL, TARGET_UNIT_DEST_AREA_ALLY);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_ascension_mystic_atonement_heal::SelectLowest,
            EFFECT_ALL, TARGET_UNIT_DEST_AREA_ENTRY);
    }
};

class spell_ascension_mystic_fury_of_the_wind : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_fury_of_the_wind);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* victim = eventInfo.GetActionTarget();
        if (!victim)
            return;
        std::list<Unit*> enemies;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(victim, caster, FURY_OF_THE_WIND_RANGE);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(victim, enemies, check);
        Cell::VisitObjects(victim, searcher, FURY_OF_THE_WIND_RANGE);
        enemies.remove(victim);
        if (enemies.empty())
            caster->CastSpell(caster, SPELL_FURY_OF_THE_WIND_SELF, true);
        else
            caster->CastSpell(victim, SPELL_FURY_OF_THE_WIND_JUMP, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_fury_of_the_wind::HandleProc, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_elunes_fury : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_elunes_fury);

    void HandleProc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Aura* crit = caster->GetAura(SPELL_ELUNES_FURY_CRIT);
        if (!crit)
        {
            crit = caster->AddAura(SPELL_ELUNES_FURY_CRIT, caster);
            if (!crit)
                return;
            crit->SetMaxDuration(ELUNES_FURY_PER_HIT_MS);
            crit->SetDuration(ELUNES_FURY_PER_HIT_MS);
            return;
        }
        int32 const duration = std::min(crit->GetDuration() + ELUNES_FURY_PER_HIT_MS, ELUNES_FURY_MAX_MS);
        crit->SetMaxDuration(std::max(crit->GetMaxDuration(), duration));
        crit->SetDuration(duration);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_elunes_fury::HandleProc, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_lightning_fangs : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_lightning_fangs);

    void HandleProc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        std::list<Creature*> wolves;
        GetTarget()->GetAllMinionsByEntry(wolves, NPC_FERAL_SPIRIT_WOLF);
        for (Creature* wolf : wolves)
            if (wolf->IsAlive())
                GetTarget()->CastSpell(wolf, SPELL_LIGHTNING_CHARGED, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_lightning_fangs::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_demonic_whirl : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_demonic_whirl);

    void HandleProc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        Pet* pet = player ? player->GetPet() : nullptr;
        if (pet && pet->IsAlive() && pet->GetCreatureTemplate()->family == CREATURE_FAMILY_FELGUARD)
            pet->CastSpell(pet, SPELL_DEMONIC_WHIRL_WHIRLWIND, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_demonic_whirl::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_vampiric_death : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_vampiric_death);

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        if (!target)
            return;
        AuraEffect* touch = target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_PRIEST, 0,
            PRIEST_VAMPIRIC_TOUCH_FLAG1, 0, caster->GetGUID());
        if (!touch)
            return;
        int32 const total = touch->GetAmount() * std::max(touch->GetTotalTicks(), 1);
        int32 percent = aurEff->GetAmount();
        if (GetId() == SPELL_VAMPIRIC_DEATH_HERO && (eventInfo.GetHitMask() & PROC_HIT_CRITICAL))
            if (SpellInfo const* crit = sSpellMgr->GetSpellInfo(SPELL_VAMPIRIC_DEATH_HERO_CRIT))
                percent = crit->Effects[EFFECT_0].CalcValue();
        int32 const damage = CalculatePct(total, percent);
        touch->GetBase()->Remove();
        if (damage > 0)
            caster->CastCustomSpell(SPELL_VAMPIRIC_DEATH_DAMAGE, SPELLVALUE_BASE_POINT0, damage, target, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_vampiric_death::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_corrupted_shiv : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_corrupted_shiv);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        if (!target || target == caster)
            return;
        caster->CastSpell(target, CorruptionRank(caster), true);
        if (AuraEffect* pain = target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_PRIEST,
                PRIEST_SHADOW_WORD_PAIN_FLAG0, 0, 0, caster->GetGUID()))
            pain->GetBase()->RefreshDuration();
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_corrupted_shiv::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_apply_corruption : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_apply_corruption);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        if (Unit* target = eventInfo.GetActionTarget(); target && target != caster)
            caster->CastSpell(target, CorruptionRank(caster), true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_apply_corruption::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_widowmaker : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_widowmaker);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        SpellInfo const* proc = sSpellMgr->GetSpellInfo(SPELL_WIDOWMAKER_PROC);
        if (!target || !damage || !proc)
            return;
        int32 const share = int32(CalculatePct(damage->GetDamage() + damage->GetAbsorb(),
            proc->Effects[EFFECT_0].CalcValue()));
        if (share > 0)
            caster->CastCustomSpell(SPELL_WIDOWHAIL, SPELLVALUE_BASE_POINT0, share, target, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_widowmaker::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_cryotherapist : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_cryotherapist);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        SpellInfo const* spell = eventInfo.GetSpellInfo();
        if (!spell)
            return;
        uint32 heal = SPELL_CRYOTHERAPIST_BOLT;
        if (spell->SpellFamilyName == SPELLFAMILY_MAGE && (spell->SpellFamilyFlags[1] & MAGE_DEEP_FREEZE_FLAG1))
            heal = SPELL_CRYOTHERAPIST_DEEP_FREEZE;
        else if (spell->SpellFamilyName == SPELLFAMILY_PRIEST && (spell->SpellFamilyFlags[1] & PRIEST_ICY_PENANCE_FLAG1))
            heal = SPELL_CRYOTHERAPIST_ICY_PENANCE;
        GetTarget()->CastSpell(GetTarget(), heal, true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_cryotherapist::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_savage_frenzy : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_savage_frenzy);

    void HandleProc(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        if (Aura* roar = GetTarget()->GetAura(SPELL_SAVAGE_ROAR))
        {
            int32 const duration = roar->GetDuration() + SAVAGE_FRENZY_EXTENSION_MS;
            roar->SetMaxDuration(std::max(roar->GetMaxDuration(), duration));
            roar->SetDuration(duration);
        }
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_savage_frenzy::HandleProc, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_shattered_renewal : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_shattered_renewal);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Player* player = eventInfo.GetActor() ? eventInfo.GetActor()->ToPlayer() : nullptr;
        return player && eventInfo.GetActionTarget() && player->isHonorOrXPTarget(eventInfo.GetActionTarget());
    }

    void HandleProc(AuraEffect const*, ProcEventInfo&)
    {
        GetTarget()->CastSpell(GetTarget(), SPELL_SHATTERED_RENEWAL_WEAKENED_SOUL, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_mystic_shattered_renewal::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_shattered_renewal::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_ascension_mystic_blessing_of_the_divines : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_blessing_of_the_divines);

    void HandleProc(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        static constexpr std::array<uint32, 3> BLESSINGS = { SPELL_BLESSING_DIVINES, SPELL_BLESSING_RADIANCE,
            SPELL_BLESSING_MENDING };
        Unit* caster = GetTarget();
        Unit* target = eventInfo.GetActionTarget();
        if (!target || !caster->IsFriendlyTo(target))
            target = caster;
        caster->CastSpell(target, Acore::Containers::SelectRandomContainerElement(BLESSINGS), true);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_ascension_mystic_blessing_of_the_divines::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_mystic_shield_masters_resolve : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_shield_masters_resolve);

    void CalcAmount(AuraEffect const*, int32& amount, bool&)
    {
        amount = -1;
    }

    void Absorb(AuraEffect*, DamageInfo& dmgInfo, uint32& absorbAmount)
    {
        AuraEffect const* reduction = GetEffect(EFFECT_1);
        absorbAmount = reduction && GetTarget()->HealthBelowPct(SHIELD_MASTERS_RESOLVE_HEALTH_PCT) ?
            CalculatePct(dmgInfo.GetDamage(), reduction->GetAmount()) : 0;
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_mystic_shield_masters_resolve::CalcAmount, EFFECT_2,
            SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_ascension_mystic_shield_masters_resolve::Absorb, EFFECT_2);
    }
};

class spell_ascension_mystic_cauterize : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_cauterize);

    TimePoint _ready{};

    void CalcAmount(AuraEffect const*, int32& amount, bool&)
    {
        amount = -1;
    }

    void Absorb(AuraEffect*, DamageInfo& dmgInfo, uint32& absorbAmount)
    {
        absorbAmount = 0;
        Unit* target = GetTarget();
        TimePoint const now = GameTime::Now();
        if (dmgInfo.GetDamage() < target->GetHealth() || now < _ready)
            return;
        _ready = now + CAUTERIZE_COOLDOWN;
        absorbAmount = dmgInfo.GetDamage();
        target->SetHealth(std::max<uint32>(1, target->CountPctFromMaxHealth(CAUTERIZE_HEALTH_PCT)));
        target->CastSpell(target, SPELL_CAUTERIZE_SLOW_CLEAR, true);
        target->CastSpell(target, SPELL_CAUTERIZE_BURN, true);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_ascension_mystic_cauterize::CalcAmount, EFFECT_0,
            SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(spell_ascension_mystic_cauterize::Absorb, EFFECT_0);
    }
};

class spell_ascension_mystic_heavy_thunder_check : public SpellScript
{
    PrepareSpellScript(spell_ascension_mystic_heavy_thunder_check);

    void Schedule(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* caster = GetCaster();
        if (!caster)
            return;
        Milliseconds const delay(std::max<int32>(1, GetSpellInfo()->Effects[effIndex].CalcValue(caster)));
        caster->m_Events.AddEventAtOffset([caster]()
        {
            Aura const* counter = caster->GetAura(SPELL_HEAVY_THUNDER_COUNTER);
            if (counter && counter->GetStackAmount() == 1)
                caster->CastSpell(caster, SPELL_HEAVY_THUNDER_EMPOWERED, true);
            else
                caster->RemoveAurasDueToSpell(SPELL_HEAVY_THUNDER_COUNTER);
        }, delay);
    }

    void PreventTarget(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_ascension_mystic_heavy_thunder_check::Schedule, EFFECT_0,
            SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_mystic_heavy_thunder_check::PreventTarget, EFFECT_0,
            SPELL_EFFECT_ASCENSION_TRIGGER_SPELL_DELAYED);
    }
};

class spell_ascension_mystic_arcane_conduit_trigger : public SpellScript
{
    PrepareSpellScript(spell_ascension_mystic_arcane_conduit_trigger);

    void HandleDummy(SpellEffIndex)
    {
        Unit* caster = GetCaster();
        if (!caster || !caster->HasAura(SPELL_ARCANE_CONDUIT))
            return;
        Unit* target = caster->GetVictim();
        if (!target)
            if (Player* player = caster->ToPlayer())
                target = ObjectAccessor::GetUnit(*player, player->GetTarget());
        if (target && caster->IsValidAttackTarget(target))
            caster->CastSpell(target, SPELL_ARCANE_SURGE, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_mystic_arcane_conduit_trigger::HandleDummy, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionMysticEnchantScripts()
{
    new AscensionMysticEnchantHealShare();
    new AscensionMysticEnchantLifeTap();
    RegisterSpellScript(spell_ascension_mystic_water_nova);
    RegisterSpellScript(spell_ascension_mystic_renewed_through_absolution);
    RegisterSpellScript(spell_ascension_mystic_atonement);
    RegisterSpellScript(spell_ascension_mystic_atonement_heal);
    RegisterSpellScript(spell_ascension_mystic_fury_of_the_wind);
    RegisterSpellScript(spell_ascension_mystic_elunes_fury);
    RegisterSpellScript(spell_ascension_mystic_lightning_fangs);
    RegisterSpellScript(spell_ascension_mystic_demonic_whirl);
    RegisterSpellScript(spell_ascension_mystic_vampiric_death);
    RegisterSpellScript(spell_ascension_mystic_savage_frenzy);
    RegisterSpellScript(spell_ascension_mystic_shattered_renewal);
    RegisterSpellScript(spell_ascension_mystic_arcane_conduit_trigger);
    RegisterSpellScript(spell_ascension_mystic_heavy_thunder_check);
    RegisterSpellScript(spell_ascension_mystic_blessing_of_the_divines);
    RegisterSpellScript(spell_ascension_mystic_shield_masters_resolve);
    RegisterSpellScript(spell_ascension_mystic_cauterize);
    RegisterSpellScript(spell_ascension_mystic_corrupted_shiv);
    RegisterSpellScript(spell_ascension_mystic_apply_corruption);
    RegisterSpellScript(spell_ascension_mystic_widowmaker);
    RegisterSpellScript(spell_ascension_mystic_cryotherapist);
}
