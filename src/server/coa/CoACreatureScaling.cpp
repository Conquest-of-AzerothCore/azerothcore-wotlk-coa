/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CoACreatureScaling.h"
#include "CoACreatureScalingPolicy.h"
#include "AllCreatureScript.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "QueryResult.h"
#include "UnitScript.h"
#include "WorldScript.h"
#include <atomic>
#include <memory>
#include <mutex>
#include <unordered_set>

namespace
{
    std::mutex SettingsMutex;
    std::shared_ptr<CreatureScaling::Settings const> Configured = std::make_shared<CreatureScaling::Settings>();
    std::shared_ptr<CreatureScaling::Settings const> Override;
    std::atomic<bool> Enabled = false;
    std::unordered_set<uint32> FlexHealthEntries;

    std::shared_ptr<CreatureScaling::Settings const> Active()
    {
        std::lock_guard<std::mutex> lock(SettingsMutex);
        return Override ? Override : Configured;
    }

    void Publish()
    {
        Enabled = (Override ? Override : Configured)->enabled;
    }

    bool HasFlexHealth(Creature const* creature)
    {
        return FlexHealthEntries.count(creature->GetEntry()) || FlexHealthEntries.count(creature->GetEntry() % 100000);
    }

    bool IsDummy(Creature const* creature)
    {
        std::string const& script = creature->GetScriptName();
        return script == "npc_training_dummy" || script == "npc_target_dummy";
    }

    bool IsEligible(Creature const* creature)
    {
        return creature && !creature->IsPet() && !creature->IsSummon() && !creature->IsTotem() && !creature->IsTrigger()
            && !creature->IsCritter() && !creature->GetCharmerOrOwnerGUID() && !IsDummy(creature);
    }

    CreatureScaling::Context ContextOf(Creature const* creature)
    {
        Map const* map = creature->FindMap();
        if (!map)
            return CreatureScaling::Context::None;
        return CreatureScaling::ContextOf(map->IsBattlegroundOrArena(), map->IsScriptedPrivateInstance(),
            map->IsRegularDifficulty(), map->IsRaid(), map->IsDungeon());
    }

    float DamageMultiplier(Unit const* target, Unit const* attacker)
    {
        if (!Enabled || !target || !attacker || !target->GetCharmerOrOwnerPlayerOrPlayerItself())
            return 1.0f;
        Creature const* creature = attacker->ToCreature();
        if (!IsEligible(creature) || !creature->IsHostileTo(target))
            return 1.0f;
        CreatureScaling::Context const context = ContextOf(creature);
        if (context == CreatureScaling::Context::None)
            return 1.0f;
        return CreatureScaling::Multiplier(Active()->damage, context, creature->GetMapId());
    }

    template <typename T>
    void ScaleDamage(T& damage, Unit const* target, Unit const* attacker)
    {
        if (damage <= 0)
            return;
        if (float const multiplier = DamageMultiplier(target, attacker); multiplier != 1.0f)
            damage = T(CreatureScaling::Scaled(uint32(damage), multiplier));
    }

    CreatureScaling::Multipliers ReadMultipliers(std::string const& kind, CreatureScaling::Multipliers const& defaults)
    {
        CreatureScaling::Multipliers result;
        result.world = sConfigMgr->GetOption<float>("CoA.CreatureScaling.World." + kind, defaults.world);
        result.dungeon = sConfigMgr->GetOption<float>("CoA.CreatureScaling.Dungeon." + kind, defaults.dungeon);
        result.raid = sConfigMgr->GetOption<float>("CoA.CreatureScaling.Raid." + kind, defaults.raid);
        result.maps = CreatureScaling::ParseMapMultipliers(sConfigMgr->GetOption<std::string>(
            "CoA.CreatureScaling.Map" + kind, CreatureScaling::FormatMapMultipliers(defaults.maps), false));
        return result;
    }
}

CreatureScaling::TestOverride::TestOverride()
{
    auto settings = std::make_shared<CreatureScaling::Settings>();
    settings->enabled = true;
    std::lock_guard<std::mutex> lock(SettingsMutex);
    Override = std::move(settings);
    Publish();
}

CreatureScaling::TestOverride::~TestOverride()
{
    std::lock_guard<std::mutex> lock(SettingsMutex);
    Override.reset();
    Publish();
}

class CoACreatureScalingWorld final : public WorldScript
{
public:
    CoACreatureScalingWorld() : WorldScript("CoACreatureScalingWorld",
        { WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnAfterConfigLoad(bool) override
    {
        CreatureScaling::Settings const defaults;
        auto settings = std::make_shared<CreatureScaling::Settings>();
        settings->enabled = sConfigMgr->GetOption<bool>("CoA.CreatureScaling.Enable", false);
        settings->health = ReadMultipliers("Health", defaults.health);
        settings->damage = ReadMultipliers("Damage", defaults.damage);
        std::lock_guard<std::mutex> lock(SettingsMutex);
        Configured = std::move(settings);
        Publish();
    }

    void OnStartup() override
    {
        OnAfterConfigLoad(false);
        FlexHealthEntries.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT entry FROM coa_boss_flex"))
        {
            do
            {
                FlexHealthEntries.insert(result->Fetch()[0].Get<uint32>());
            } while (result->NextRow());
        }
        auto settings = Active();
        LOG_INFO("server.loading",
            ">> CoA creature scaling {}: health {}/{}/{}, damage {}/{}/{} (world/dungeon/raid), "
            "{} map health overrides, {} flex health entries kept",
            settings->enabled ? "enabled" : "disabled", settings->health.world, settings->health.dungeon,
            settings->health.raid, settings->damage.world, settings->damage.dungeon, settings->damage.raid,
            settings->health.maps.size(), FlexHealthEntries.size());
    }
};

class CoACreatureScalingHealth final : public AllCreatureScript
{
public:
    CoACreatureScalingHealth() : AllCreatureScript("CoACreatureScalingHealth") { }

    void OnCreatureSelectLevel(CreatureTemplate const*, Creature* creature) override
    {
        if (!Enabled || !IsEligible(creature) || HasFlexHealth(creature))
            return;
        CreatureScaling::Context const context = ContextOf(creature);
        if (context == CreatureScaling::Context::None)
            return;
        float const multiplier = CreatureScaling::Multiplier(Active()->health, context, creature->GetMapId());
        if (multiplier == 1.0f)
            return;
        uint32 const health = CreatureScaling::Scaled(creature->GetCreateHealth(), multiplier);
        creature->SetCreateHealth(health);
        creature->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        creature->SetMaxHealth(health);
        creature->SetHealth(health);
        creature->ResetPlayerDamageReq();
    }
};

class CoACreatureScalingDamage final : public UnitScript
{
public:
    CoACreatureScalingDamage() : UnitScript("CoACreatureScalingDamage", true, { UNITHOOK_MODIFY_MELEE_DAMAGE,
        UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK })
    { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        ScaleDamage(damage, target, attacker);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const*) override
    {
        ScaleDamage(damage, target, attacker);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const*) override
    {
        ScaleDamage(damage, target, attacker);
    }
};

void AddSC_CoACreatureScaling()
{
    new CoACreatureScalingWorld();
    new CoACreatureScalingHealth();
    new CoACreatureScalingDamage();
}
