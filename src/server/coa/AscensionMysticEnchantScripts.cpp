/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

// Warcraft Reborn Mystic Enchants whose effect is a dummy, has no trigger spell, or lives outside the proc system.
//
// Where an enchant procs, spell_ascension_mystic_enchant_proc (AscensionMysticEnchantProcs.cpp) still decides WHEN
// from coa_mystic_enchant_proc; the AuraScripts here, registered on the same enchant, only supply WHAT happens
// (PreventDefaultAction, then the action the tooltip names). The rest hook what is not a proc: healing received,
// an aura arriving on the pet, a shield breaking, the dummy Evocation fires every tick.

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
    // Dread Communion
    SPELL_DREAD_COMMUNION                  = 1180473,
    // Renewed Through Absolution
    SPELL_RENEWED_THROUGH_ABSOLUTION_HEAL  = 1571424,
    SPELL_WEAKENED_SOUL                    = 1106788,
    // Atonement
    SPELL_ATONEMENT_SINGLE_HEAL            = 1567779,
    SPELL_ATONEMENT_PENANCE_HEAL           = 1567780,
    SPELL_ATONEMENT_BUFF                   = 1567778,
    // Fury of the Wind
    SPELL_FURY_OF_THE_WIND_JUMP            = 1590418,
    SPELL_FURY_OF_THE_WIND_SELF            = 1590421,
    // Elune's Fury
    SPELL_ELUNES_FURY_CRIT                 = 1583365,
    // Shadow Funnel
    SPELL_SHADOW_FUNNEL                    = 1180900,
    SPELL_SHADOW_FUNNEL_PET                = 1180901,
    // Lightning Fangs
    SPELL_LIGHTNING_CHARGED                = 1180161,
    NPC_FERAL_SPIRIT_WOLF                  = 1129264,
    // Demonic Whirl
    SPELL_DEMONIC_WHIRL_WHIRLWIND          = 1180111,
    // Vampiric Death
    SPELL_VAMPIRIC_DEATH                   = 1180080,
    SPELL_VAMPIRIC_DEATH_DAMAGE            = 1180081,
    SPELL_SHADOW_WORD_DEATH_BACKLASH       = 1132409,
    // Arcane Conduit
    SPELL_ARCANE_CONDUIT                   = 1181430,
    SPELL_ARCANE_SURGE                     = 1181431,
    SPELL_ARCANE_CONDUIT_TRIGGER           = 1181434,
    // Shattered Renewal
    SPELL_SHATTERED_RENEWAL                = 1181000,
    SPELL_SHATTERED_RENEWAL_MANA           = 1181001,
    SPELL_SHATTERED_RENEWAL_WEAKENED_SOUL  = 1181002,
    // Savage Frenzy
    SPELL_SAVAGE_ROAR                      = 1152610,
    // Purity of Light
    SPELL_PURITY_OF_LIGHT                  = 1581027,
    SPELL_SURGE_OF_LIGHT                   = 1133151,
    SPELL_SURGE_OF_LIGHT_PURE              = 1333151,
    // Hydromancer: Water Nova
    SPELL_WATER_NOVA_POOL                  = 1569715,
    SPELL_WATER_NOVA_ELECTRIFIED           = 1569735,
    // Feeding the Abyss
    SPELL_FEEDING_THE_ABYSS                = 1154364,
    SPELL_FEEDING_THE_ABYSS_VISUAL         = 1154362,
    SPELL_FEEDING_THE_ABYSS_STORED         = 1154365,
    SPELL_ABYSSAL_ERUPTION_READY           = 1154366,
    SPELL_ABYSSAL_ERUPTION                 = 1154367,
    // Blessing of the Divines
    SPELL_BLESSING_DIVINES                 = 1571467,
    SPELL_BLESSING_RADIANCE                = 1571470,
    SPELL_BLESSING_MENDING                 = 1571471,
    // Cauterize
    SPELL_CAUTERIZE_BURN                   = 1181411,
    SPELL_CAUTERIZE_SLOW_CLEAR             = 1181413,
    // Heavy Thunder
    SPELL_HEAVY_THUNDER                    = 1181080,
    SPELL_HEAVY_THUNDER_COUNTER            = 1181081,
    SPELL_HEAVY_THUNDER_EMPOWERED          = 1181082,
};

constexpr uint32 PRIEST_RENEW_FLAG0 = 0x40;
constexpr uint32 PRIEST_PENANCE_FLAG1 = 0x8000;
constexpr uint32 PRIEST_SHIELD_FLAG0 = 0x1;
constexpr uint32 PRIEST_VAMPIRIC_TOUCH_FLAG1 = 0x400;
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

bool IsPriestSpell(SpellInfo const* spell, uint32 flag0, uint32 flag1)
{
    return spell && spell->SpellFamilyName == SPELLFAMILY_PRIEST &&
        ((flag0 && (spell->SpellFamilyFlags[0] & flag0)) || (flag1 && (spell->SpellFamilyFlags[1] & flag1)));
}

// Dread Communion: "Your demon is healed for 25% of the healing you receive." The Demonic Empowerment
// half is a proc rule; this is the share, which no proc event carries (healing received).
class AscensionMysticEnchantHealShare final : public UnitScript
{
public:
    AscensionMysticEnchantHealShare() : UnitScript("AscensionMysticEnchantHealShare", true,
        { UNITHOOK_MODIFY_HEAL_RECEIVED, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_AURA_APPLY,
          UNITHOOK_ON_AURA_REMOVE, UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN }) { }

    void ModifyHealReceived(Unit* target, Unit* /*healer*/, uint32& heal, SpellInfo const* /*spellInfo*/) override
    {
        if (!heal || !target || !target->IsPlayer())
            return;
        AuraEffect const* share = target->GetAuraEffect(SPELL_DREAD_COMMUNION, EFFECT_0);
        Pet* pet = share ? target->ToPlayer()->GetPet() : nullptr;
        if (!pet || !pet->IsAlive() || pet->IsFullHealth())
            return;
        SpellInfo const* spellInfo = share->GetSpellInfo();
        // the share is the tooltip's 25%: no effect of the enchant carries it
        HealInfo healInfo(target, pet, CalculatePct(heal, 25), spellInfo, spellInfo->GetSchoolMask());
        target->HealBySpell(healInfo);
    }

    // Vampiric Death: "the damage you take from your Shadow Word: Death is reduced by 40%" (effect 1, a dummy).
    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (!spellInfo || spellInfo->Id != SPELL_SHADOW_WORD_DEATH_BACKLASH || target != attacker)
            return;
        if (AuraEffect const* reduction = target->GetAuraEffect(SPELL_VAMPIRIC_DEATH, EFFECT_1))
            damage = uint32(uint64(damage) * uint32(std::max(0, 100 + reduction->GetAmount())) / 100);
    }

    // Shadow Funnel: "While channeling Health Funnel on your Voidwalker, its auto-attacks trigger a Void Nova".
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
        // Feeding the Abyss: "After 10 seconds the stored damage is fed to the abyss, causing your next Life Tap to..."
        if (aura->GetId() == SPELL_FEEDING_THE_ABYSS_STORED && mode == AURA_REMOVE_BY_EXPIRE &&
            AbyssStored.contains(unit->GetGUID()))
        {
            unit->CastSpell(unit, SPELL_ABYSSAL_ERUPTION_READY, true);
            return;
        }
        if (IsHealthFunnel(aura->GetSpellInfo()) && IsVoidwalker(unit))
            unit->RemoveAurasDueToSpell(SPELL_SHADOW_FUNNEL_PET);

        // Shattered Renewal: "When your Power Word: Shield breaks from damage, it restores 5% base mana to you. This can
        // only occur once per second."
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

    // Feeding the Abyss: "Your ability to Dodge is replaced with a dark hunger. You have a chance to fully absorb
    // incoming physical damage, storing it for later use." Chance: 10% plus your spell critical strike chance.
    void ModifyMeleeDamage(Unit* target, Unit* /*attacker*/, uint32& damage) override
    {
        Hunger(target, damage);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        HeavyThunder(attacker, damage, spellInfo);
        if (!spellInfo || !(spellInfo->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL) || damage <= 0)
            return;
        uint32 amount = uint32(damage);
        Hunger(target, amount);
        damage = int32(amount);
    }

    static std::unordered_map<ObjectGuid, uint32> AbyssStored;

private:
    // Heavy Thunder: "Your Thunder Clap deals 20% more damage when using single Two-Handed Weapon" (effect 0, a dummy).
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
        // the 10 second window starts with the first absorb; later absorbs add to the same store
        if (!player->HasAura(SPELL_FEEDING_THE_ABYSS_STORED))
            player->CastSpell(player, SPELL_FEEDING_THE_ABYSS_STORED, true);
    }

    // Purity of Light: "Surge of Light no longer prevents a critical strike from Flash Heal or Smite and allows it to
    // be stacked up to 2 times. However, Surge of Light only reduces the mana cost by 60%." Reborn's 1333151 is that
    // buff; it is spent by charge, one per Flash Heal or Smite.
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

// Feeding the Abyss: the next Life Tap after the store is fed releases it as Abyssal Eruption, damaging nearby
// enemies and healing you and your pet. The tooltip gives no ratio; the data does: the store aura's second effect is
// 30 and the ready buff reads "your next Life Tap will do $w2 additional damage and healing", so the eruption is its
// own base plus 30% of the stored damage. Nothing in the data bounds the store, and a soaked killing blow would come
// back out at full size (the uncapped Reckoning of 2005), so the bonus is capped at the caster's maximum health.
class AscensionMysticEnchantLifeTap final : public PlayerScript
{
public:
    AscensionMysticEnchantLifeTap() : PlayerScript("AscensionMysticEnchantLifeTap", { PLAYERHOOK_ON_SPELL_CAST }) { }

    void OnPlayerSpellCast(Player* player, Spell* spell, bool /*skipCheck*/) override
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

// Hydromancer: Water Nova: "Casting Frost Shock on an enemy leaves behind a pool of splashing water for 6 sec ...
// Dealing damage with Lightning Bolt or Chain Lightning, electrifies the water". Rules: hit of Frost Shock, damage of
// Lightning Bolt / Chain Lightning.
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
            // the pool's first effect needs a unit target; the core takes the area's position from it
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

// Renewed Through Absolution: "Penance consumes your Renew to heal your target and nearby allies for an additional
// N Holy healing. Consuming Renew this way also reduces the duration of your active Weakened Soul by 3 sec."
// Rule: heal of Penance on a target with your Renew.
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

// Atonement: "Dealing damage with Smite or Holy Fire heals a nearby ally ... Dealing damage with Penance heals three
// nearby allies ... Casting any of these spells grants Atonement." The heals' targets are chosen by
// spell_ascension_mystic_atonement_heal. Rules: direct damage of Smite / Holy Fire, damage of Penance.
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

// Atonement's heals go to the lowest-health allies, like the Cataclysm / Mists of Pandaria talent the enchant copies
// ("heal a nearby low health friendly target"): one for Smite and Holy Fire, three for Penance, among the caster's
// party or raid and their pets within the spell's radius of the caster. The heal spells' own area targeting cannot
// express that (Penance's uses an entry-checked area that finds no one without conditions), so the list is replaced.
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

// Fury of the Wind: "Your Windfury Weapon can jump to 2 nearby enemies but each jump reduces its damage by 25%. If no
// other enemies are nearby the wind jumps to you instead, increasing your physical damage by 20% ... and attack speed
// by 20% for 20 sec." Rule: damage of Windfury Attack.
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

// Elune's Fury: "dealing damage with Starfall increases your critical strike chance by 15%, lasting for 1 second per
// target hit" (trigger 1583364: 1 sec per hit, 60 sec at most). Rule: damage of Starfall.
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

// Lightning Fangs: "Using Stormstrike charges your Spirit Wolves with lightning, causing their auto attacks to deal
// extra Nature damage for 6 seconds." Rule: cast of Stormstrike.
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

// Demonic Whirl: "Dealing damage with Shadow Bolt or Incinerate causes your Felguard to cast a Whirlwind ... This can
// only occur once every 3 sec." Rule: damage of Shadow Bolt / Incinerate, cooldown 3 sec.
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

// Vampiric Death: "Shadow Word: Death consumes your Vampiric Touch on the target to deal damage based on 60% of the
// total damage of your Vampiric Touch." Rule: hit of Shadow Word: Death on a target with your Vampiric Touch.
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
        int32 const damage = CalculatePct(total, aurEff->GetAmount());
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

// Savage Frenzy: "Every time you hit with Feral Frenzy the duration of your Savage Roar is increased by 6 sec."
// Rule: damage of Feral Frenzy.
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

// Shattered Renewal: "After killing an opponent that yields experience or honor your Weakened Soul is removed from
// you." Effect 0 is a dummy aura carrying the trigger, so it is not a proc-trigger effect the rule engine sees.
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

// Blessing of the Divines: "Your Paladin heals have a 33% chance to trigger a random blessing. This can only occur
// once every 5 seconds." The proc effect has no trigger spell; the three blessings are the tooltip's @s: spells.
// Rule: heal of a Paladin ability, cooldown 5 sec.
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

// The two enchants below carry a school absorb of 1 point and no script: the first hit drained it and removed the whole
// enchant aura with it (proc effects included). Their absorbs are conditional, so the amount is unlimited (-1) and the
// script decides each hit.

// Shield Master's Resolve: "damage taken while you are below 50% health is reduced by 10%" (effect 1 carries the 10).
class spell_ascension_mystic_shield_masters_resolve : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_shield_masters_resolve);

    void CalcAmount(AuraEffect const*, int32& amount, bool& /*canBeRecalculated*/)
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

// Cauterize: "An attack which would otherwise kill you will instead bring you to 35% maximum health. When this happens
// all movement speed impairing effects are removed and you gain 50% movement speed for 6 sec, but burn, taking 3% health
// as Fire damage every second. This effect can only occur once every minute." 1181413 clears the slows, 1181411 is the
// speed and the burn.
class spell_ascension_mystic_cauterize : public AuraScript
{
    PrepareAuraScript(spell_ascension_mystic_cauterize);

    TimePoint _ready{};

    void CalcAmount(AuraEffect const*, int32& amount, bool& /*canBeRecalculated*/)
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

// Heavy Thunder: "Hitting single target with Thunder Clap will cause next Thunder Clap gain 40% increase critical strike
// chance" (and costs no rage). Every Thunder Clap hit stacks the 100 ms counter (rule: damage of Thunder Clap); the
// cast's delayed trigger (rule: cast of Thunder Clap) checks it after its delay and empowers the next Thunder Clap
// only at one stack. The empowerment removes the counter itself; otherwise it is dropped here.
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

// Arcane Conduit: "every second you fire an Arcane Surge, dealing Arcane damage to your target and reduces the
// cooldown of Arcane Power, Presence of Mind and Evocation by 10 sec." Reborn Evocation's periodic trigger casts
// the Arcane Conduit trigger (1181434), a dummy, on every tick; with the enchant it fires the surge.
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
}
