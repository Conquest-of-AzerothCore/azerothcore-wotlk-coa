/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchHunterCompletion.h"
#include "Map.h"
#include "MovementTypedefs.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>
#include <utility>

namespace
{
using namespace AscensionWitchHunter;

enum WitchHunterCastSpells
{
    SPELL_WITCHBANE_SHOT = 704342,
    SPELL_ARBALEST_MASTERY = 706240,
    SPELL_ARBALEST_MASTERY_PROGRESS = 706241,
    SPELL_SIXFOLD_SHOT = 807364,
    SPELL_SIXFOLD_SHOT_DAMAGE = 807527,
    SPELL_SIXFOLD_SHOT_ENERGIZE = 521228,
    SPELL_SIXFOLD_SHOT_PASSIVE = 500567,
    SPELL_SIXFOLD_SHOT_STACKS = 500569,
    SPELL_SIXFOLD_SHOT_TRANSFORM = 500604,
    SPELL_SHADOW_RAGE_TALENT = 705455,
    SPELL_SHADOW_RAGE_PET = 804192,
    SPELL_SHADOW_RAGE_DAMAGE = 567570,
    SPELL_SHARPSHOOTER = 705456,
    SPELL_SHARPSHOOTER_ENERGIZE = 704385,
    SPELL_DEAL_WITH_THE_DEVIL = 680255,
    SPELL_SHADOWSTORM = 520277,
    SPELL_SHADOWSTORM_DAMAGE = 520278,
    SPELL_SHADOWSTORM_HEAL = 520793,
    SPELL_SHADOWSTORM_LEECH = 520794,
    SPELL_SMITE_EVIL_WICKEDNESS = 802844,
    SPELL_COLLECT_BOUNTY = 504687,
    SPELL_PAVISE_EFFECT = 1108180
};

enum WitchHunterHounds
{
    NPC_SHADOWHOUND = 50124,
    NPC_LESSER_SHADOWHOUND = 50224
};

bool CarriesAttackerBonus(SpellEffectInfo const& effect)
{
    return effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE || effect.Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG;
}

template <typename Bonus>
int32 MarginalShare(Bonus bonus, int32 amount)
{
    return amount > 0 ? std::max(0, bonus(uint32(2 * amount)) - bonus(uint32(amount))) : 0;
}

std::pair<int32, int32> RangedWeaponShares(Unit* caster, Unit* target, SpellInfo const* info, uint32 raw)
{
    SpellSchoolMask const school = info->GetSchoolMask();
    int32 const scaled = int32(raw * caster->GetPctModifierValue(UNIT_MOD_DAMAGE_RANGED, TOTAL_PCT));
    int32 const done = MarginalShare([&](uint32 amount)
        { return int32(caster->MeleeDamageBonusDone(target, amount, RANGED_ATTACK, info, school)); }, scaled);
    int32 const taken = MarginalShare([&](uint32 amount)
        { return int32(target->MeleeDamageBonusTaken(caster, amount, RANGED_ATTACK, info, school)); }, done);
    return {done, taken};
}

std::pair<int32, int32> SpellShares(Unit* caster, Unit* target, SpellInfo const* info, uint32 raw, uint8 effIndex)
{
    int32 const done = std::max(0, SpellDoneShare(caster, target, info, raw, SPELL_DIRECT_DAMAGE, effIndex, 0.0f));
    int32 const taken = int32(target->SpellDamageBonusTaken(caster, info, uint32(done), SPELL_DIRECT_DAMAGE)) -
                        int32(target->SpellDamageBonusTaken(caster, info, 0, SPELL_DIRECT_DAMAGE));
    return {done, taken};
}

int32 AreaShare(Spell* spell, Unit* target, uint8 effIndex, int32 taken)
{
    SpellInfo const* info = spell->GetSpellInfo();
    SpellEffectInfo const& effect = info->Effects[effIndex];
    if (taken <= 0 || !(effect.IsAreaAuraEffect() || effect.IsTargetingArea() ||
                        (effect.ChainTarget > 1 && info->DmgClass != SPELL_DAMAGE_CLASS_MAGIC)))
        return taken;
    Unit* caster = spell->GetCaster();
    bool const npcCaster = !caster->IsControlledByPlayer() || info->HasAttribute(SPELL_ATTR7_TREAT_AS_NPC_AOE);
    taken = target->CalculateAOEDamageReduction(taken, info->SchoolMask, npcCaster);
    int32 const targets = int32(spell->GetUniqueTargetInfo()->size());
    if (caster->IsPlayer() && targets > 10)
        taken = taken * 10 / targets;
    return taken;
}

void AddVictimAttackerBonus(Spell* spell, Unit* target, TargetInfo& hit)
{
    SpellInfo const* info = spell->GetSpellInfo();
    uint32 raw = 0;
    uint8 effIndex = EFFECT_0;
    for (uint8 i = EFFECT_0; i < MAX_SPELL_EFFECTS && !raw; ++i)
        if ((hit.effectMask & (1 << i)) && CarriesAttackerBonus(info->Effects[i]))
        {
            raw = VictimAttackerBonus(target, info->Id, i);
            effIndex = i;
        }
    SpellInfo const* aura = spell->GetTriggeredByAuraSpellInfo();
    if (!raw && aura && aura->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE &&
        aura->Effects[EFFECT_0].TriggerSpell == info->Id)
    {
        raw = VictimAttackerBonus(target, aura->Id, EFFECT_0);
        effIndex = EFFECT_0;
    }
    if (!raw)
        return;
    Unit* caster = spell->GetCaster();
    auto const [done, taken] = info->Effects[effIndex].Effect == SPELL_EFFECT_NORMALIZED_WEAPON_DMG ?
        RangedWeaponShares(caster, target, info, raw) : SpellShares(caster, target, info, raw, effIndex);
    hit.damageBeforeTakenMods += done;
    hit.damage += AreaShare(spell, target, effIndex, taken);
}

void GrantShadowRageToHounds(Player* player)
{
    float const range = sSpellMgr->AssertSpellInfo(SPELL_SHADOW_RAGE_PET)->Effects[EFFECT_1].CalcRadius(player);
    for (Unit* hound : Nearby(player, range))
        if ((hound->GetEntry() == NPC_SHADOWHOUND || hound->GetEntry() == NPC_LESSER_SHADOWHOUND) &&
            hound->GetOwnerGUID() == player->GetGUID())
            Cast(player, hound, SPELL_SHADOW_RAGE_PET);
}

void ApplyShadowblastTalents(Player* player)
{
    if (player->HasAura(SPELL_SHADOW_RAGE_TALENT))
        GrantShadowRageToHounds(player);
    if (player->HasAura(SPELL_SHARPSHOOTER))
        Cast(player, player, SPELL_SHARPSHOOTER_ENERGIZE);
}

bool SubmittedByPlayer(Spell const* spell)
{
    return !spell->HasTriggeredCastFlag(TRIGGERED_IGNORE_GCD);
}

bool SixfoldShotReady(Player* player)
{
    Aura const* stacks = player->GetAura(SPELL_SIXFOLD_SHOT_STACKS);
    return player->HasAura(SPELL_SIXFOLD_SHOT_PASSIVE) && stacks && stacks->GetStackAmount() >= 5;
}

void LeapVault(Player* player, float distance, float angle)
{
    Position end = player->GetPosition();
    player->MovePositionToFirstCollision(end, distance, angle);
    sScriptMgr->AnticheatSetUnderACKmount(player);
    player->GetMotionMaster()->MoveCharge(end.GetPositionX(), end.GetPositionY(), end.GetPositionZ(),
                                          12.0f * player->GetSpeed(MOVE_RUN));
}

float SilverBulletsCreatureTypeShare(Player* player, Unit* target, SpellInfo const* info)
{
    for (uint32 id : {SPELL_SILVER_BULLETS_R2, SPELL_SILVER_BULLETS_R1})
    {
        AuraEffect const* damage = player->GetAuraEffect(id, EFFECT_0);
        AuraEffect const* creatureType = player->GetAuraEffect(id, EFFECT_1);
        if (!damage || !creatureType)
            continue;
        if (!creatureType->IsAffectedOnSpell(info) ||
            !(target->GetCreatureTypeMask() & uint32(creatureType->GetMiscValueB())))
            return 1.0f;
        return float(100 + damage->GetAmount() + creatureType->GetAmount()) / float(100 + damage->GetAmount());
    }
    return 1.0f;
}

float SilverBoltsDoubledShare(Player* player, Unit* target, SpellInfo const* info)
{
    AuraEffect const* doubled = player->GetAuraEffect(SPELL_SILVER_BOLTS, EFFECT_0);
    AuraEffect const* base = player->GetAuraEffect(SPELL_SILVER_BOLTS, EFFECT_2);
    if (!doubled || !base || !doubled->IsAffectedOnSpell(info))
        return 1.0f;
    if (!(target->GetCreatureTypeMask() & uint32(doubled->GetMiscValueB())) && !target->HasAura(SPELL_SHADOW_TRAPPED))
        return 1.0f;
    return float(100 + base->GetAmount() + doubled->GetAmount()) / float(100 + base->GetAmount());
}

bool PeriodicDamageAura(uint32 aura)
{
    return aura == SPELL_AURA_PERIODIC_DAMAGE || aura == SPELL_AURA_PERIODIC_LEECH ||
           aura == SPELL_AURA_PERIODIC_DAMAGE_PERCENT;
}

bool WitchblightDamaging(SpellInfo const* info)
{
    return std::any_of(std::begin(info->Effects), std::end(info->Effects), [](SpellEffectInfo const& effect)
    {
        switch (effect.Effect)
        {
            case SPELL_EFFECT_SCHOOL_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
            case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
            case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
            case SPELL_EFFECT_HEALTH_LEECH:
            case SPELL_EFFECT_POWER_BURN:
            case SPELL_EFFECT_ENVIRONMENTAL_DAMAGE:
                return true;
            default:
                return effect.IsAura() && PeriodicDamageAura(effect.ApplyAuraName);
        }
    });
}

bool PersistentAreaDamage(SpellInfo const* info)
{
    return std::any_of(std::begin(info->Effects), std::end(info->Effects), [](SpellEffectInfo const& effect)
    {
        return effect.Effect == SPELL_EFFECT_PERSISTENT_AREA_AURA && PeriodicDamageAura(effect.ApplyAuraName);
    });
}

void WitchblightMiss(Spell* spell, Unit* caster, SpellInfo const* info)
{
    Unit* attacker = spell->GetOriginalCaster() ? spell->GetOriginalCaster() : caster;
    if (!attacker || !CarriesWitchblight(attacker) || !WitchblightDamaging(info) ||
        PulseOfEffectNotLaunchedUnderWitchblight(spell, info, attacker))
        return;
    bool attempted = PersistentAreaDamage(info);
    if (attempted)
        spell->SetSpellValue(SPELLVALUE_AURA_DURATION, 1);
    for (TargetInfo& target : *spell->GetUniqueTargetInfo())
    {
        Unit* victim = target.targetGUID == attacker->GetGUID() ? nullptr :
                       ObjectAccessor::GetUnit(*attacker, target.targetGUID);
        if (!victim || attacker->IsFriendlyTo(victim))
            continue;
        attempted = true;
        if (target.missCondition == SPELL_MISS_NONE)
            target.missCondition = SPELL_MISS_MISS;
    }
    if (attempted)
        for (uint32 rank : WitchblightRanks)
            attacker->RemoveAurasDueToSpell(rank);
}

bool MagicDeflectRolled(Unit* attacker, Unit* victim, SpellInfo const* info)
{
    return (victim->IsAlive() || victim->IsPlayer()) && !attacker->IsVehicle() &&
           !info->HasAttribute(SPELL_ATTR7_NO_ATTACK_MISS);
}

bool DeflectRolledFromFront(Unit* attacker, Unit* victim, SpellInfo const* info)
{
    if (info->HasAttribute(SPELL_ATTR3_ALWAYS_HIT) ||
        ((info->IsPositive() || info->HasEffect(SPELL_EFFECT_DISPEL)) && !attacker->IsHostileTo(victim)))
        return false;
    switch (info->DmgClass)
    {
        case SPELL_DAMAGE_CLASS_RANGED:
            return !info->HasAttribute(SPELL_ATTR0_NO_ACTIVE_DEFENSE);
        case SPELL_DAMAGE_CLASS_NONE:
            return !info->SpellFamilyName &&
                   std::none_of(std::begin(info->Effects), std::end(info->Effects), [](SpellEffectInfo const& effect)
                   {
                       return effect.Effect && effect.Effect != SPELL_EFFECT_SCHOOL_DAMAGE &&
                              effect.ApplyAuraName != SPELL_AURA_PERIODIC_DAMAGE;
                   }) && MagicDeflectRolled(attacker, victim, info);
        case SPELL_DAMAGE_CLASS_MAGIC:
            return MagicDeflectRolled(attacker, victim, info);
        default:
            return false;
    }
}

int32 PaviseDeflectChance(Unit* victim)
{
    int32 chance = 0;
    for (AuraEffect const* effect : victim->GetAuraEffectsByType(SPELL_AURA_DEFLECT_SPELLS))
        if (effect->GetId() == SPELL_PAVISE_EFFECT)
            chance += effect->GetAmount();
    return chance;
}

void PaviseDeflectFromBehind(Spell* spell, SpellInfo const* info)
{
    Unit* attacker = spell->GetOriginalCaster();
    if (!attacker)
        return;
    for (TargetInfo& target : *spell->GetUniqueTargetInfo())
    {
        if (target.missCondition != SPELL_MISS_NONE || target.targetGUID == attacker->GetGUID())
            continue;
        Unit* victim = ObjectAccessor::GetUnit(*attacker, target.targetGUID);
        if (!victim || victim->HasInArc(M_PI, attacker) || victim->HasIgnoreHitDirectionAura() ||
            victim->HasUnitState(UNIT_STATE_STUNNED))
            continue;
        int32 const chance = PaviseDeflectChance(victim);
        if (chance > 0 && DeflectRolledFromFront(attacker, victim, info) && roll_chance_i(chance))
            target.missCondition = SPELL_MISS_DEFLECT;
    }
}

class witch_hunter_casts : public AllSpellScript
{
  public:
    witch_hunter_casts() : AllSpellScript("witch_hunter_casts") {}

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Unit* striker = spell->GetCaster();
        Player* player = striker ? Owner(striker->GetCharmerOrOwnerPlayerOrPlayerItself()) : nullptr;
        if (player && striker == player && Quickdraw(spell->GetSpellInfo()) &&
            player->HasAura(SPELL_DEAL_WITH_THE_DEVIL, player->GetGUID()))
            chance = 100.0f;
        if (player && spell->GetSpellInfo()->Id == SPELL_SHADOW_RAGE_DAMAGE)
        {
            float const ranged = player->GetFloatValue(PLAYER_RANGED_CRIT_PERCENTAGE);
            chance = striker == player ? ranged :
                     striker->GetUnitCriticalChance(BASE_ATTACK, target) + std::max(0.0f, ranged - 5.0f);
        }
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Unit* launcher = spell->GetOriginalCaster() ? spell->GetOriginalCaster() : caster;
        if (launcher && CarriesWitchblight(launcher))
            StampWitchblightLaunch(launcher, info->Id);
        Player* player = Owner(caster);
        if (!player)
            return;
        if (!spell->IsTriggered() && Desecrate(info) && player->HasAura(SPELL_SHADOWSTORM))
            Cast(player, player, SPELL_SHADOWSTORM_DAMAGE);
        if (!spell->IsTriggered())
            return;
        SpellInfo const* channel = spell->GetTriggeredByAuraSpellInfo();
        if (!channel)
            return;

        if (info->Id == SPELL_WITCHBANE_SHOT && Family(channel, 1, 4194304) &&
            player->HasAura(SPELL_ARBALEST_MASTERY))
            Cast(player, player, SPELL_ARBALEST_MASTERY_PROGRESS);
        if (info->Id == SPELL_SIXFOLD_SHOT_DAMAGE && channel->Id == SPELL_SIXFOLD_SHOT)
            Cast(player, player, SPELL_SIXFOLD_SHOT_ENERGIZE);
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        PaviseDeflectFromBehind(spell, info);
        WitchblightMiss(spell, caster, info);
        Player* player = Owner(caster);
        if (!player || spell->IsTriggered())
            return;
        if (Family(info, 0, 65536))
        {
            uint32 extra = player->GetPower(POWER_RAGE);
            spell->SetScriptExtraPowerSpent(extra);
            player->ModifyPower(POWER_RAGE, -int32(extra));
            spell->SetSpellValue(SPELLVALUE_BASE_POINT1, info->Effects[EFFECT_1].BasePoints + 1 +
                                                             int32((extra / 10) * player->GetLevel() * 0.5f));
        }
    }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || !target || target == player || hit.damage <= 0)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        AddVictimAttackerBonus(spell, target, hit);
        float multiplier = 1.0f;
        if (info->Id == SPELL_BRAND_OF_THE_DAMNED_DAMAGE && info->SpellFamilyName == 21 &&
            hit.missCondition == SPELL_MISS_NONE && (target->GetCreatureTypeMask() & CREATURE_TYPEMASK_DEMON_OR_UNDEAD))
            multiplier *= 2.0f;
        bool brand = target->HasAura(680517, player->GetGUID());
        if (brand && Noctis(info) && player->HasAura(681098))
            multiplier *= 1.2f;
        if (info->Id == SPELL_WITCHBANE_SHOT && player->HasAura(SPELL_ARBALEST_MASTERY))
            if (Aura* mastery = player->GetAura(SPELL_ARBALEST_MASTERY_PROGRESS))
                multiplier *= 1.0f + mastery->GetStackAmount() * 0.15f;
        multiplier *= SilverBulletsCreatureTypeShare(player, target, info);
        hit.damage = int32(hit.damage * multiplier);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * multiplier);
        float bolts = SilverBoltsDoubledShare(player, target, info);
        hit.damage = int32(hit.damage * bolts);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * bolts);
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (result != SPELL_CAST_OK)
            return;
        Unit* caster = spell->GetCaster();
        Unit* target = spell->m_targets.GetUnitTarget();
        if (!spell->IsTriggered() && spell->GetSpellInfo()->HasAura(SPELL_AURA_MOD_STEALTH) && caster->HasAura(804068))
        {
            result = SPELL_FAILED_CASTER_AURASTATE;
            return;
        }
        Player* player = Owner(caster);
        if (!player)
            return;
        uint32 id = spell->GetSpellInfo()->Id;
        if (id == SPELL_SIXFOLD_SHOT && SubmittedByPlayer(spell) && !SixfoldShotReady(player))
        {
            result = SPELL_FAILED_CASTER_AURASTATE;
            return;
        }
        if (id == 500085 && SubmittedByPlayer(spell) && player->HasUnitState(UNIT_STATE_ROOT))
        {
            result = SPELL_FAILED_ROOTED;
            return;
        }
        if (spell->IsTriggered())
            return;
        if (id == 802281 &&
            (!player->FindMap() || player->GetMap()->IsDungeon() || player->GetMap()->IsBattlegroundOrArena() ||
             !target || target->IsControlledByPlayer() || !(target->GetCreatureTypeMask() & 36)))
            result = SPELL_FAILED_BAD_TARGETS;
        if (id == 501380 && (!target || !(target->GetCreatureTypeMask() & (36 | 64))))
            result = SPELL_FAILED_BAD_TARGETS;
        if (id == 805770 && !player->HasAura(805771))
            result = SPELL_FAILED_CASTER_AURASTATE;
        if (Quickdraw(spell->GetSpellInfo()) && !player->HasAura(680244))
            result = SPELL_FAILED_CASTER_AURASTATE;
        if ((id == 681788 || id == 684330 || id == 685020 || id == 686020) &&
            (!player->HasAura(680513) || !player->HasAura(681499)))
            result = SPELL_FAILED_CASTER_AURASTATE;
    }
};

class spell_ascension_witch_hunter_ability : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_ability);
    bool _boltDash = false;
    bool _lightbringer = false;
    bool _dawnKnight = false;
    bool _slinging = false;
    bool _darkhunter = false;
    bool _anguish = false;
    bool _oath = false;
    bool _bounty = false;
    int32 _bountyAmount = 0;
    bool _bountyPending = false;
    uint32 _hits = 0;
    std::vector<ObjectGuid> _flock;

    void Before()
    {
        Unit* caster = GetCaster();
        _boltDash = caster->HasAura(520670);
        _lightbringer = caster->HasAura(680539);
        _dawnKnight = caster->HasAura(681390);
        _slinging = caster->HasAura(500161);
        _darkhunter = caster->HasAura(680237);
        _anguish = caster->HasAura(500566);
        _oath = caster->HasAura(680498);
        _bounty = caster->HasAura(504478);
        if (Heartseeking(GetSpellInfo()) && !GetSpell()->IsTriggered())
            if (Player* player = Owner(caster))
                if (AuraEffect* bounty = player->GetAuraEffect(504478, EFFECT_0))
                {
                    _bountyAmount = std::max(
                        0, bounty->GetAmount() +
                               int32((player->GetTotalAttackPowerValue(RANGED_ATTACK) * 0.3f +
                                      player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY) * 0.45f) *
                                     bounty->GetBase()->GetStackAmount()));
                    _bountyPending = true;
                }
    }

    void BeforeHitTarget(SpellMissInfo missInfo)
    {
        if (!_bountyPending || missInfo != SPELL_MISS_NONE)
            return;
        Player* player = Owner(GetCaster());
        Unit* target = GetHitUnit();
        if (!player || !target || target == player || !target->IsAlive())
            return;
        _bountyPending = false;
        player->CastCustomSpell(SPELL_COLLECT_BOUNTY, SPELLVALUE_BASE_POINT0, _bountyAmount, target,
                                TRIGGERED_FULL_MASK);
    }

    void Hit()
    {
        Player* player = Owner(GetCaster());
        Unit* target = GetHitUnit();
        if (player && target == player && _anguish && Family(GetSpellInfo(), 0, 2))
            player->RemoveAurasDueToSpell(500566);
        if (!player || !target || target == player)
            return;
        uint32 id = GetSpellInfo()->Id;
        uint32 dealt = GetSpell()->GetScriptHealthLeechDamage();
        if (GetHitDamage() > 0)
            ++_hits;
        if (Dusk(GetSpellInfo()) || id == 803502 || Noctis(GetSpellInfo()))
        {
            SpellInfo const* passive = sSpellMgr->GetSpellInfo(Noctis(GetSpellInfo()) ? 574336 : 574334);
            uint32 percent = passive ? std::max(passive->Effects[EFFECT_0].CalcValue(), 0) :
                                       (Noctis(GetSpellInfo()) ? 100 : 25);
            if (dealt)
                player->CastCustomSpell(Noctis(GetSpellInfo()) ? 574337 : 574335, SPELLVALUE_BASE_POINT0,
                                        int32(dealt * uint64(percent) / 100), player, TRIGGERED_FULL_MASK);
            if (Noctis(GetSpellInfo()) && dealt && player->HasAura(707067))
                target->RemoveAurasDueToSpell(680517, player->GetGUID());
        }
        if (Heartseeking(GetSpellInfo()) && dealt)
            player->RewardRage(dealt, 0, true);
        if (id == 680230 && dealt)
            Cast(player, player, 500179);
        if (Desecrate(GetSpellInfo()) && dealt && player->HasAura(560208) &&
            target->HasAura(680517, player->GetGUID()))
            player->CastCustomSpell(574335, SPELLVALUE_BASE_POINT0, int32(player->CountPctFromMaxHealth(1)), player,
                                    TRIGGERED_FULL_MASK);
        if (id == SPELL_SHADOWSTORM_DAMAGE && dealt)
            player->CastCustomSpell(
                SPELL_SHADOWSTORM_HEAL, SPELLVALUE_BASE_POINT0,
                int32(CalculatePct(uint64(dealt),
                                   sSpellMgr->AssertSpellInfo(SPELL_SHADOWSTORM_LEECH)->Effects[EFFECT_0].CalcValue())),
                player, TRIGGERED_FULL_MASK);
        if (id == 503662 && dealt && player->HasAura(680544) &&
            (target->HasAura(681413, player->GetGUID()) || target->HasAura(681523, player->GetGUID())))
        {
            uint32 child = roll_chance_i(50) ? 681415 : 681524;
            SpellInfo const* helper = sSpellMgr->GetSpellInfo(child);
            float value = helper->Effects[EFFECT_0].BasePoints + 1 +
                          player->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_HOLY) * 0.25f +
                          player->GetTotalAttackPowerValue(BASE_ATTACK) * 0.45f;
            player->CastCustomSpell(child, SPELLVALUE_BASE_POINT0, int32(value), target, TRIGGERED_FULL_MASK);
            target->RemoveAurasDueToSpell(681413, player->GetGUID());
            target->RemoveAurasDueToSpell(681523, player->GetGUID());
        }
        if (id == 520271 && dealt && player->HasAura(500056))
        {
            _flock.push_back(target->GetGUID());
            if (_flock.size() >= 5)
                for (size_t i = _flock.size() == 5 ? 0 : _flock.size() - 1; i < _flock.size(); ++i)
                    if (Unit* center = ObjectAccessor::GetUnit(*player, _flock[i]))
                        for (Unit* enemy : Nearby(center, 6.0f))
                            if (player->IsValidAttackTarget(enemy))
                                Cast(player, enemy, 500564);
        }
        if ((id == 680236 || (id >= 680270 && id <= 680273)) && dealt)
            target->KnockbackFrom(player->GetPositionX(), player->GetPositionY(), 10.0f, 5.0f);
        if (id == 802139 && !target->IsControlledByPlayer())
            Cast(player, target, 32747);
        if (Family(GetSpellInfo(), 1, 16384) && dealt && player->HasAura(680503))
            Brand(player, target);
        if (id == 684330)
            Cast(player, target, 504472);
    }

    void After()
    {
        Player* player = Owner(GetCaster());
        if (!player)
            return;
        SpellInfo const* info = GetSpellInfo();
        uint32 id = info->Id;
        Unit* target = GetExplTargetUnit();
        bool const castWhileCasting = (id == 500085 || id == SPELL_SIXFOLD_SHOT) && SubmittedByPlayer(GetSpell());
        if (GetSpell()->IsTriggered() && !castWhileCasting)
            return;
        auto talent = [&](uint32 passive, uint32 helper, Unit* recipient = nullptr)
        {
            if (player->HasAura(passive))
                Cast(player, recipient ? recipient : player, helper);
        };
        if (Family(info, 2, 32) || Family(info, 1, 4194304))
            talent(805773, 504478);
        if (Family(info, 2, 16))
            ApplyShadowblastTalents(player);
        if (Bolt(info) && player->HasAura(SPELL_SIXFOLD_SHOT_PASSIVE))
        {
            Cast(player, player, SPELL_SIXFOLD_SHOT_STACKS);
            if (SixfoldShotReady(player))
            {
                Cast(player, player, SPELL_SIXFOLD_SHOT_TRANSFORM);
                if (!player->HasSpell(SPELL_SIXFOLD_SHOT))
                    player->learnSpellWithoutAnnouncement(SPELL_SIXFOLD_SHOT);
                Replacement(player, 0, 64, SPELL_SIXFOLD_SHOT);
            }
        }
        if (id == SPELL_SIXFOLD_SHOT)
        {
            ClearReplacement(player, 0, 64);
            player->RemoveAurasDueToSpell(SPELL_SIXFOLD_SHOT_STACKS);
            player->RemoveAurasDueToSpell(SPELL_SIXFOLD_SHOT_TRANSFORM);
        }
        if (id == 500085)
        {
            float x = 0.0f, y = 0.0f;
            if (player->HasUnitMovementFlag(MOVEMENTFLAG_FORWARD))
                x += 1.0f;
            if (player->HasUnitMovementFlag(MOVEMENTFLAG_BACKWARD))
                x -= 1.0f;
            if (player->HasUnitMovementFlag(MOVEMENTFLAG_STRAFE_LEFT))
                y += 1.0f;
            if (player->HasUnitMovementFlag(MOVEMENTFLAG_STRAFE_RIGHT))
                y -= 1.0f;
            float angle = x || y ? std::atan2(y, x) : 0.0f;
            float distance = 15.0f * player->GetSpeedRate(MOVE_RUN);
            if (AuraEffect* extra = player->GetAuraEffect(789256, EFFECT_0))
                distance += extra->GetAmount();
            LeapVault(player, distance, angle);
            talent(524812, 525054);
            talent(681156, 681155);
            player->RemoveAurasDueToSpell(500102);
        }
        if (id == 802006)
        {
            talent(560219, 560218);
            if (player->HasAura(807797))
                talent(681156, 681155);
        }
        if ((id == 680236 || (id >= 680270 && id <= 680273)) && player->HasAura(500101))
        {
            Reset(player, 500085);
            Cast(player, player, 500102);
        }
        if (id == 500086 && player->HasAura(705490))
        {
            Reset(player, 500085);
            Cast(player, player, 500160);
        }
        if (Noctis(info))
        {
            talent(681100, 681099);
            player->RemoveAurasDueToSpell(680495);
        }
        if (Heartseeking(info))
        {
            talent(500055, 520130);
            talent(582310, 804304);
            if (_bounty)
                player->RemoveAurasDueToSpell(504478);
            Aura const* boltDash = player->GetAura(520670);
            if (_boltDash && (!boltDash || !boltDash->IsUsingCharges()))
            {
                player->RemoveAurasDueToSpell(520670);
                Cast(player, player, 524602);
            }
        }
        if (Quickdraw(info))
        {
            player->RemoveAurasDueToSpell(680244);
            talent(503669, 680237);
        }
        if (_darkhunter && Family(info, 2, 32))
            player->RemoveAurasDueToSpell(680237);
        if (_slinging && Family(info, 0, 65536))
            player->RemoveAurasDueToSpell(500161);
        if (_dawnKnight && Family(info, 0, 1024))
            player->RemoveAurasDueToSpell(681390);
        if (Family(info, 1, 134217728))
        {
            talent(705480, 806191);
            if (_lightbringer && !roll_chance_i(25))
                player->RemoveAurasDueToSpell(680539);
        }
        if (Desecrate(info))
        {
            talent(560208, 680519);
            player->RemoveAurasDueToSpell(803166);
            if (player->HasAura(504645) && roll_chance_i(15))
                for (auto const& [known, state] : player->GetSpellMap())
                    if (state->State != PLAYERSPELL_REMOVED && Noctis(sSpellMgr->GetSpellInfo(known)))
                        Reset(player, known);
            if (_oath)
            {
                Cast(player, player, 680511);
                player->RemoveAurasDueToSpell(680498);
            }
        }
        if (id == 805738)
        {
            flag96 const traps = info->Effects[EFFECT_1].SpellClassMask;
            for (auto const& [known, state] : player->GetSpellMap())
                if (state->State != PLAYERSPELL_REMOVED)
                    if (SpellInfo const* trap = sSpellMgr->GetSpellInfo(known))
                        if (trap->SpellFamilyName == 21 && (trap->SpellFamilyFlags & traps))
                        {
                            Reset(player, known);
                            if (uint32 category = trap->GetCategory())
                                player->RemoveCategoryCooldown(category);
                        }
        }
        if (id == 680498)
            Cast(player, player, 680505);
        if (Family(info, 1, 16384))
            Cast(player, player, 681339);
        if (id == 802273)
        {
            if (player->HasAura(705450))
                SummonHounds(player, 1, sSpellMgr->GetSpellInfo(803886)->GetDuration(), 803886, target);
            CallHounds(player, target);
        }
        if (Family(info, 2, 8))
        {
            talent(705463, 680275);
            uint32 chance = player->HasAura(707891) ? 50 : player->HasAura(706365) ? 25 : 0;
            if (chance && roll_chance_i(chance))
                SummonHounds(player, 1, sSpellMgr->GetSpellInfo(707890)->GetDuration(), 707890, target);
        }
        if (Family(info, 2, 512) && id != 802826 && player->HasAura(680513))
        {
            uint32 child = id == 802276 ? 686020 : id == 802278 ? 684330 : Family(info, 1, 67108864) ? 685020 : 681788;
            Cast(player, player, 681499);
            Replacement(player, 0, 1024, child);
        }
        if (id == 805770)
            player->RemoveAurasDueToSpell(805771);
        if (id == 802281 && target)
            player->SetDisplayId(target->GetDisplayId());
    }

    void Launch(SpellEffIndex index)
    {
        SpellEffectInfo const& effect = GetSpellInfo()->Effects[index];
        if (effect.Effect != SPELL_EFFECT_TRIGGER_SPELL_WITH_VALUE ||
            effect.TriggerSpell != SPELL_SMITE_EVIL_WICKEDNESS)
            return;
        SpellInfo const* strike = sSpellMgr->GetSpellInfo(effect.TriggerSpell);
        if (strike && strike->CasterAuraSpell && !GetCaster()->HasAura(strike->CasterAuraSpell))
            PreventHitDefaultEffect(index);
    }

    void LeechMark(SpellEffIndex index)
    {
        SpellInfo const* info = GetSpellInfo();
        if (info->Effects[index].Effect != SPELL_EFFECT_HEALTH_LEECH)
            return;
        Unit* caster = GetCaster();
        Player* player = caster->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!player || player->getClass() != CLASS_WITCH_HUNTER)
            return;
        int32 const raw = int32(VictimAttackerBonus(GetHitUnit(), info->Id, index));
        SetEffectValue(GetEffectValue() + MarginalShare([&](uint32 amount)
            { return int32(caster->ApplyEffectModifiers(info, index, float(amount))); }, raw));
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_witch_hunter_ability::Before);
        OnEffectLaunch += SpellEffectFn(spell_ascension_witch_hunter_ability::Launch, EFFECT_ALL, SPELL_EFFECT_ANY);
        OnEffectLaunchTarget +=
            SpellEffectFn(spell_ascension_witch_hunter_ability::Launch, EFFECT_ALL, SPELL_EFFECT_ANY);
        BeforeHit += BeforeSpellHitFn(spell_ascension_witch_hunter_ability::BeforeHitTarget);
        AfterHit += SpellHitFn(spell_ascension_witch_hunter_ability::Hit);
        OnEffectHitTarget +=
            SpellEffectFn(spell_ascension_witch_hunter_ability::LeechMark, EFFECT_ALL, SPELL_EFFECT_ANY);
        AfterCast += SpellCastFn(spell_ascension_witch_hunter_ability::After);
    }
};

class spell_ascension_witch_hunter_greater_knights_edict : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_hunter_greater_knights_edict);

    void FilterPlayers(std::list<WorldObject*>& targets)
    {
        targets.remove_if([](WorldObject* object) { return !object->ToPlayer(); });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(
            spell_ascension_witch_hunter_greater_knights_edict::FilterPlayers, EFFECT_ALL,
            TARGET_UNIT_CASTER_AREA_RAID);
    }
};
}

void AddAscensionWitchHunterAbilityScripts()
{
    new witch_hunter_casts();
    RegisterSpellScript(spell_ascension_witch_hunter_ability);
    RegisterSpellScript(spell_ascension_witch_hunter_greater_knights_edict);
}
