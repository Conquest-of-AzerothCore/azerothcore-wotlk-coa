/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CoACreatureScaling.h"
#include "CoACreatureScalingPolicy.h"
#include "CoAZoneScaling.h"
#include "CoADungeonRescale.h"
#include "CoAProfessionRescale.h"
#include "CoADungeonNormal.h"
#include "AllCreatureScript.h"
#include "AscensionRaidReleasePolicy.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "QueryResult.h"
#include "SpellInfo.h"
#include "TemporarySummon.h"
#include "UnitScript.h"
#include "WorldScript.h"
#include <atomic>
#include <memory>
#include <mutex>
#include <optional>
#include <unordered_set>

namespace
{
    constexpr float KarazhanEnemyHealthMultiplier = 1400000.0f / 422837.0f;

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

    bool SummonedByPlayer(Creature const* creature)
    {
        TempSummon const* summon = creature->ToTempSummon();
        if (!summon)
            return false;
        if (summon->GetSummonerGUID().IsPlayer())
            return true;
        Unit const* summoner = summon->GetSummonerUnit();
        return summoner && (summoner->IsControlledByPlayer() || summoner->GetCharmerOrOwnerPlayerOrPlayerItself());
    }

    bool IsEligible(Creature const* creature)
    {
        return creature && !creature->IsPet() && !SummonedByPlayer(creature) && !creature->IsTotem() && !creature->IsTrigger()
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

    Creature const* ScaledAttacker(Unit const* target, Unit const* attacker, CreatureScaling::Context& context)
    {
        if (!Enabled || !target || !attacker || !target->GetCharmerOrOwnerPlayerOrPlayerItself())
            return nullptr;
        Creature const* creature = attacker->ToCreature();
        if (!IsEligible(creature) || creature->IsFriendlyTo(target))
            return nullptr;
        context = DungeonRescale::Owns(creature) ? CreatureScaling::Context::Dungeon : ContextOf(creature);
        return context == CreatureScaling::Context::None ? nullptr : creature;
    }

    float DamageValue(Unit const* target, Unit const* attacker,
        CreatureScaling::Multipliers CreatureScaling::Settings::* values)
    {
        CreatureScaling::Context context;
        Creature const* creature = ScaledAttacker(target, attacker, context);
        if (!creature)
            return 1.0f;
        return CreatureScaling::Multiplier((*Active()).*values, context, creature->GetMapId(), creature->GetLevel());
    }

    float DamageMultiplier(Unit const* target, Unit const* attacker)
    {
        return DamageValue(target, attacker, &CreatureScaling::Settings::damage) *
            ZoneScaling::MeleeMultiplier(attacker) * DungeonRescale::MeleeMultiplier(attacker);
    }

    float Level60NaxxramasSpellMultiplier(Unit const* attacker, SpellInfo const* spellInfo)
    {
        Creature const* creature = attacker ? attacker->ToCreature() : nullptr;
        if (!spellInfo || !creature || creature->GetLevel() != 63 || creature->GetMapId() != RaidRelease::MapNaxxramas)
            return 1.0f;

        Map const* map = creature->FindMap();
        if (!map || map->IsScriptedPrivateInstance() || !IsEligible(creature))
            return 1.0f;

        return CreatureScaling::NaxxramasSpellMultiplier(creature->GetEntry(), spellInfo->Id, map->GetSpawnMode());
    }

    float SpellDamageMultiplier(Unit const* target, Unit const* attacker, SpellInfo const* spellInfo)
    {
        float const encounterMultiplier = Level60NaxxramasSpellMultiplier(attacker, spellInfo);
        CreatureScaling::Context context;
        Creature const* creature = ScaledAttacker(target, attacker, context);
        if (!creature)
            return encounterMultiplier;
        bool const weaponSpell = spellInfo && (spellInfo->DmgClass == SPELL_DAMAGE_CLASS_MELEE ||
            spellInfo->DmgClass == SPELL_DAMAGE_CLASS_RANGED);
        return encounterMultiplier * CreatureScaling::SpellMultiplier(*Active(), context, creature->GetMapId(),
            creature->GetLevel(), weaponSpell) * ZoneScaling::SpellMultiplier(attacker) * DungeonRescale::SpellMultiplier(attacker, spellInfo, false);
    }

    template <typename T>
    void ScaleDamage(T& damage, Unit const* target, Unit const* attacker, SpellInfo const* spellInfo)
    {
        if (damage <= 0)
            return;
        if (float const multiplier = SpellDamageMultiplier(target, attacker, spellInfo); multiplier != 1.0f)
            damage = T(CreatureScaling::Scaled(uint32(damage), multiplier));
    }

    CreatureScaling::Formula ReadFormula(std::string const& key, CreatureScaling::Formula const& fallback)
    {
        std::string const text = sConfigMgr->GetOption<std::string>(key, fallback.Text());
        if (std::optional<CreatureScaling::Formula> formula = CreatureScaling::Formula::Parse(text))
            return *formula;
        LOG_ERROR("server.loading", "{} = \"{}\" is neither a number nor a formula of level; using {}", key, text,
            fallback.Text());
        return fallback;
    }

    CreatureScaling::Multipliers ReadMultipliers(std::string const& kind, CreatureScaling::Multipliers const& defaults)
    {
        CreatureScaling::Multipliers result;
        result.world = ReadFormula("CoA.CreatureScaling.World." + kind, defaults.world);
        result.dungeon = ReadFormula("CoA.CreatureScaling.Dungeon." + kind, defaults.dungeon);
        result.raid = ReadFormula("CoA.CreatureScaling.Raid." + kind, defaults.raid);
        result.maps = CreatureScaling::ParseMapMultipliers(sConfigMgr->GetOption<std::string>(
            "CoA.CreatureScaling.Map" + kind, CreatureScaling::FormatMapMultipliers(defaults.maps), false));
        return result;
    }

    CreatureScaling::SpellMultipliers ReadSpellMultipliers(CreatureScaling::SpellMultipliers const& defaults)
    {
        CreatureScaling::SpellMultipliers result;
        result.world = ReadFormula("CoA.CreatureScaling.World.SpellDamage", defaults.world);
        result.maps = CreatureScaling::ParseMapMultipliers(sConfigMgr->GetOption<std::string>(
            "CoA.CreatureScaling.MapSpellDamage", CreatureScaling::FormatMapMultipliers(defaults.maps), false));
        return result;
    }
}

float CreatureScaling::DamageMultiplier(Unit const* target, Unit const* attacker)
{
    return ::DamageMultiplier(target, attacker);
}

float CreatureScaling::SpellDamageMultiplier(Unit const* target, Unit const* attacker, SpellInfo const* spell)
{
    return ::SpellDamageMultiplier(target, attacker, spell);
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
        settings->damageSpread = ReadMultipliers("DamageSpread", defaults.damageSpread);
        settings->spellDamage = ReadSpellMultipliers(defaults.spellDamage);
        std::lock_guard<std::mutex> lock(SettingsMutex);
        Configured = std::move(settings);
        Publish();
    }

    void OnStartup() override
    {
        OnAfterConfigLoad(false);
        ProfessionRescale::Load();
        ZoneScaling::Load();
        DungeonRescale::Load();
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
            ">> CoA creature scaling {}: health {}/{}/{}, damage {}/{}/{}, damage spread {}/{}/{} (world/dungeon/raid), "
            "world spell damage {}, {} map health overrides, {} flex health entries kept",
            settings->enabled ? "enabled" : "disabled", settings->health.world.Text(), settings->health.dungeon.Text(),
            settings->health.raid.Text(), settings->damage.world.Text(), settings->damage.dungeon.Text(),
            settings->damage.raid.Text(), settings->damageSpread.world.Text(), settings->damageSpread.dungeon.Text(),
            settings->damageSpread.raid.Text(), settings->spellDamage.world.Text(), settings->health.maps.size(),
            FlexHealthEntries.size());
    }
};

class CoACreatureScalingHealth final : public AllCreatureScript
{
public:
    CoACreatureScalingHealth() : AllCreatureScript("CoACreatureScalingHealth") { }

    void OnBeforeCreatureSelectLevel(CreatureTemplate const*, Creature* creature, uint8& level) override
    {
        ZoneScaling::SelectLevel(creature, level);
        DungeonRescale::SelectLevel(creature, level);
    }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (ZoneScaling::Health(creature))
            return;
        uint8 level = creature->GetLevel();
        ZoneScaling::SelectLevel(creature, level);
        DungeonRescale::SelectLevel(creature, level);
        if (ZoneScaling::Health(creature))
            creature->SelectLevel();
    }

    void OnCreatureSelectLevel(CreatureTemplate const*, Creature* creature) override
    {
        if (std::optional<uint32> const health = DungeonRescale::Health(creature) ?
            DungeonRescale::Health(creature) : ZoneScaling::Health(creature))
        {
            creature->SetCreateHealth(*health);
            creature->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(*health));
            creature->SetMaxHealth(*health);
            creature->SetHealth(*health);
            creature->ResetPlayerDamageReq();
            return;
        }
        if (!Enabled || !IsEligible(creature) || HasFlexHealth(creature))
            return;
        Map const* map = creature->FindMap();
        CreatureScaling::Context const context = ContextOf(creature);
        float multiplier = context == CreatureScaling::Context::None ? 1.0f :
            CreatureScaling::Multiplier(Active()->health, context, creature->GetMapId(), creature->GetLevel());
        if (map && map->GetId() == RaidRelease::MapKarazhan && !map->IsScriptedPrivateInstance() &&
            creature->IsHostileToPlayers())
            multiplier *= KarazhanEnemyHealthMultiplier;
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
    CoACreatureScalingDamage() : UnitScript("CoACreatureScalingDamage", true, { UNITHOOK_MODIFY_MELEE_DAMAGE_RANGE,
        UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK })
    { }

    void ModifyMeleeDamageRange(Unit* target, Unit* attacker, float& minDamage, float& maxDamage) override
    {
        CreatureScaling::ScaleRange(minDamage, maxDamage, DamageMultiplier(target, attacker),
            DamageValue(target, attacker, &CreatureScaling::Settings::damageSpread));
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (!CoADungeonNormal::TunesSpell(attacker, spellInfo))
            ScaleDamage(damage, target, attacker, spellInfo);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (!CoADungeonNormal::TunesSpell(attacker, spellInfo))
            ScaleDamage(damage, target, attacker, spellInfo);
    }
};

void AddSC_CoACreatureScaling()
{
    new CoACreatureScalingWorld();
    new CoACreatureScalingHealth();
    new CoACreatureScalingDamage();
}
