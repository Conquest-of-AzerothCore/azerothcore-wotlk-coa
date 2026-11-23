/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattlegroundBrackets.h"
#include "AscensionBattlegroundBracketsPolicy.h"
#include "AscensionBattlegroundCatchUp.h"
#include "AscensionBattlegroundCombat.h"
#include "Battleground.h"
#include "Config.h"
#include "DataMap.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include <algorithm>
#include <limits>

namespace
{
namespace Policy = AscensionBattlegroundBracketsPolicy;

constexpr char LiftKey[] = "AscensionBattlegroundCatchUp.Lift";
uint32 MaxLiftLevels = 0;

struct AppliedLift final : DataMap::Base
{
    Policy::Lift lift;
    float ratio = 1.0f;
};

void RaiseCreateStat(Unit* unit, Stats stat, float amount)
{
    unit->SetCreateStat(stat, unit->GetCreateStat(stat) + amount);
    unit->UpdateStats(stat);
}

void HandleLiftModifiers(Unit* unit, Policy::Lift const& lift, bool apply)
{
    if (lift.stamina != 0.0f)
    {
        if (unit->IsPet())
            RaiseCreateStat(unit, STAT_STAMINA, apply ? lift.stamina : -lift.stamina);
        else
            unit->HandleStatFlatModifier(UnitMods(int(UNIT_MOD_STAT_START) + int(STAT_STAMINA)), BASE_VALUE,
                lift.stamina, apply);
    }

    if (lift.health != 0.0f)
        unit->HandleStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, lift.health, apply);
}

void DropLift(Unit* unit)
{
    AppliedLift const* applied = unit->CustomData.Get<AppliedLift>(LiftKey);
    if (!applied)
        return;

    Policy::Lift const lift = applied->lift;
    unit->CustomData.Erase(LiftKey);
    HandleLiftModifiers(unit, lift, false);
}

void RemoveLift(Unit* unit)
{
    if (!unit->CustomData.Get<AppliedLift>(LiftKey))
        return;

    uint32 const health = unit->GetHealth();
    uint32 const oldMax = unit->GetMaxHealth();
    DropLift(unit);
    unit->SetHealth(Policy::KeptHealth(health, oldMax, unit->GetMaxHealth()));
}

void ApplyLift(Unit* unit, Policy::Lift const& lift, float ratio)
{
    if (lift.Empty())
    {
        RemoveLift(unit);
        return;
    }

    uint32 const health = unit->GetHealth();
    uint32 const oldMax = unit->GetMaxHealth();
    DropLift(unit);
    HandleLiftModifiers(unit, lift, true);
    auto* applied = new AppliedLift();
    applied->lift = lift;
    applied->ratio = ratio;
    unit->CustomData.Set(LiftKey, applied);

    unit->SetHealth(Policy::KeptHealth(health, oldMax, unit->GetMaxHealth()));
}

float PlayerOutputHealth(Policy::LevelValues const& values)
{
    return static_cast<float>(values.health) + Policy::PlayerStaminaHealth(values.stats[STAT_STAMINA]);
}

uint32 LiftTargetLevel(Player const* player)
{
    Map const* map = player->FindMap();
    if (!map || !map->IsBattleground())
        return 0;

    Battleground const* battleground = player->GetBattleground();
    if (!battleground || battleground->isArena() || battleground->GetMapId() != map->GetId())
        return 0;

    return AscensionBattlegroundBrackets::WidenedMaxLevel(battleground->GetMapId(), battleground->GetBracketId());
}

Policy::LevelValues PlayerLevelValues(Player const* player, uint8 level)
{
    PlayerClassLevelInfo classInfo;
    sObjectMgr->GetPlayerClassLevelInfo(player->getClass(), level, &classInfo);

    PlayerLevelInfo levelInfo;
    sObjectMgr->GetPlayerLevelInfo(player->getRace(true), player->getClass(), level, &levelInfo);

    Policy::LevelValues values{ classInfo.basehealth, classInfo.basemana, {} };
    for (uint8 stat = STAT_STRENGTH; stat < MAX_STATS; ++stat)
        values.stats[stat] = levelInfo.stats[stat];
    return values;
}

void RefreshPlayerLift(Player* player)
{
    uint8 const level = player->GetLevel();
    uint32 const target = Policy::CappedLiftLevel(level, LiftTargetLevel(player), MaxLiftLevels);
    if (target <= level)
    {
        RemoveLift(player);
        return;
    }

    Policy::LevelValues const own = PlayerLevelValues(player, level);
    Policy::LevelValues const lifted = PlayerLevelValues(player, uint8(target));
    ApplyLift(player, Policy::LiftBetween(own, lifted),
        Policy::OutputRatio(PlayerOutputHealth(own), PlayerOutputHealth(lifted)));
}

Policy::LevelValues PetLevelValues(PetLevelInfo const& info, bool hasMana)
{
    Policy::LevelValues values{ info.health, hasMana ? info.mana : 0, {} };
    for (uint8 stat = STAT_STRENGTH; stat < MAX_STATS; ++stat)
        values.stats[stat] = info.stats[stat];
    return values;
}

void RefreshPetLift(Pet* pet)
{
    PetType const type = pet->getPetType();
    Player const* owner = pet->GetOwner();
    bool const combatPet = type == HUNTER_PET || type == SUMMON_PET;
    uint8 const level = pet->GetLevel();
    uint32 const target =
        owner && combatPet ? Policy::CappedLiftLevel(level, LiftTargetLevel(owner), MaxLiftLevels) : 0;
    bool const hunterStats = pet->IsHunterPet();
    uint32 const statsCreatureId = hunterStats ? 1 : pet->GetEntry();
    PetLevelInfo const* own = target > level ? sObjectMgr->GetPetLevelInfo(statsCreatureId, level) : nullptr;
    PetLevelInfo const* top = own ? sObjectMgr->GetPetLevelInfo(statsCreatureId, uint8(target)) : nullptr;
    if (!top)
    {
        RemoveLift(pet);
        return;
    }

    ApplyLift(pet, Policy::LiftBetween(PetLevelValues(*own, !hunterStats), PetLevelValues(*top, !hunterStats)),
        Policy::OutputRatio(static_cast<float>(own->health), static_cast<float>(top->health)));
}

void RefreshOwnerLifts(Player* player)
{
    RefreshPlayerLift(player);
    if (Pet* pet = player->GetPet())
        RefreshPetLift(pet);
}

void RemoveOwnerLifts(Player* player)
{
    RemoveLift(player);
    if (Pet* pet = player->GetPet())
        RemoveLift(pet);
}

class ascension_battleground_wide_brackets_config : public WorldScript
{
public:
    ascension_battleground_wide_brackets_config()
        : WorldScript("ascension_battleground_wide_brackets_config", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool reload) override
    {
        if (reload)
            return;

        AscensionBattlegroundBrackets::Configure(
            sConfigMgr->GetOption<bool>("CoA.Battleground.WideBrackets.Enable", true),
            sConfigMgr->GetOption<std::string>("CoA.Battleground.WideBrackets.Ranges", "10-29,30-49,50-59"));
        MaxLiftLevels = uint32(std::max<int32>(
            sConfigMgr->GetOption<int32>("CoA.Battleground.WideBrackets.MaxLiftLevels", 0), 0));
    }
};

class ascension_battleground_catch_up_battleground : public AllBattlegroundScript
{
public:
    ascension_battleground_catch_up_battleground()
        : AllBattlegroundScript("ascension_battleground_catch_up_battleground",
            {ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_ADD_PLAYER,
                ALLBATTLEGROUNDHOOK_ON_BATTLEGROUND_REMOVE_PLAYER_AT_LEAVE})
    { }

    void OnBattlegroundAddPlayer(Battleground*, Player* player) override
    {
        RefreshOwnerLifts(player);
    }

    void OnBattlegroundRemovePlayerAtLeave(Battleground*, Player* player) override
    {
        RemoveOwnerLifts(player);
    }
};

class ascension_battleground_catch_up_player : public PlayerScript
{
public:
    ascension_battleground_catch_up_player()
        : PlayerScript("ascension_battleground_catch_up_player",
            {PLAYERHOOK_ON_LEVEL_CHANGED, PLAYERHOOK_ON_MAP_CHANGED, PLAYERHOOK_ON_LOGOUT})
    { }

    void OnPlayerLevelChanged(Player* player, uint8) override
    {
        if (player->CustomData.Get<AppliedLift>(LiftKey))
            RefreshPlayerLift(player);
    }

    void OnPlayerMapChanged(Player* player) override
    {
        RefreshOwnerLifts(player);
    }

    void OnPlayerLogout(Player* player) override
    {
        RemoveOwnerLifts(player);
    }
};

class ascension_battleground_catch_up_pet : public PetScript
{
public:
    ascension_battleground_catch_up_pet()
        : PetScript("ascension_battleground_catch_up_pet",
            {PETHOOK_ON_INIT_STATS_FOR_LEVEL, PETHOOK_ON_PET_ADD_TO_WORLD})
    { }

    void OnInitStatsForLevel(Guardian* guardian, uint8) override
    {
        Pet* pet = guardian->ToPet();
        if (!pet)
            return;

        pet->CustomData.Erase(LiftKey);
        if (pet->IsInWorld())
            RefreshPetLift(pet);
    }

    void OnPetAddToWorld(Pet* pet) override
    {
        RefreshPetLift(pet);
    }
};

int32 ScaledSigned(Unit const* source, Unit const* target, int32 amount, SpellInfo const* spell, bool healing)
{
    if (amount <= 0)
        return amount;

    uint32 const scaled = AscensionBattlegroundCatchUp::ScaledOutput(source, target, uint32(amount), spell, healing);
    return int32(std::min<uint32>(scaled, uint32(std::numeric_limits<int32>::max())));
}

class ascension_battleground_catch_up_output : public UnitScript
{
public:
    ascension_battleground_catch_up_output()
        : UnitScript("ascension_battleground_catch_up_output", true,
            {UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_MELEE_DAMAGE,
                UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_ON_BEFORE_HEAL_ABSORB,
                UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT})
    { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& amount, SpellInfo const* spell) override
    {
        amount = ScaledSigned(attacker, target, amount, spell, false);
    }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& amount) override
    {
        amount = AscensionBattlegroundCatchUp::ScaledOutput(attacker, target, amount, nullptr, false);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& amount, SpellInfo const* spell) override
    {
        amount = AscensionBattlegroundCatchUp::ScaledOutput(attacker, target, amount, spell, false);
    }

    void OnBeforeHealAbsorb(HealInfo& healInfo) override
    {
        healInfo.SetHeal(AscensionBattlegroundCatchUp::ScaledOutput(healInfo.GetHealer(), healInfo.GetTarget(),
            healInfo.GetHeal(), healInfo.GetSpellInfo(), true));
    }

    void OnAfterAuraEffectCalculateAmount(AuraEffect const* effect, Unit* caster, int32& amount) override
    {
        AuraType const type = effect->GetAuraType();
        if (type != SPELL_AURA_SCHOOL_ABSORB && type != SPELL_AURA_MANA_SHIELD)
            return;

        WorldObject* const owner = effect->GetBase()->GetOwner();
        amount = ScaledSigned(caster, owner ? owner->ToUnit() : nullptr, amount, effect->GetSpellInfo(), true);
    }
};
}

namespace AscensionBattlegroundCatchUp
{
float OutputRatio(Unit const* unit)
{
    if (!unit)
        return 1.0f;

    if (AppliedLift const* applied = unit->CustomData.Get<AppliedLift>(LiftKey))
        return applied->ratio;

    Unit const* owner = unit->GetCharmerOrOwner();
    AppliedLift const* ownerLift = owner ? owner->CustomData.Get<AppliedLift>(LiftKey) : nullptr;
    return ownerLift ? ownerLift->ratio : 1.0f;
}

uint32 ScaledOutput(Unit const* source, Unit const* target, uint32 amount, SpellInfo const* spell, bool healing)
{
    if (!source || !target || amount == 0 || AscensionBattlegroundCombat::SharedTopLevel(source, target) == 0)
        return amount;

    if (spell && spell->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
        return amount;

    if (spell && spell->AscensionInheritsResolvedAmount)
        return amount;

    if (healing && spell && (spell->HasEffect(SPELL_EFFECT_HEALTH_LEECH) || spell->HasAura(SPELL_AURA_PERIODIC_LEECH)))
        return amount;

    if (healing && spell &&
        (spell->HasEffect(SPELL_EFFECT_HEAL_PCT) || spell->HasEffect(SPELL_EFFECT_HEAL_MAX_HEALTH) ||
            spell->HasAura(SPELL_AURA_OBS_MOD_HEALTH)))
        return amount;

    if (source->IsHostileTo(target) == healing)
        return amount;

    return Policy::ScaleAmount(amount, OutputRatio(source));
}
}

void AddSC_AscensionBattlegroundCatchUp()
{
    new ascension_battleground_catch_up_output();
    new ascension_battleground_wide_brackets_config();
    new ascension_battleground_catch_up_battleground();
    new ascension_battleground_catch_up_player();
    new ascension_battleground_catch_up_pet();
}
