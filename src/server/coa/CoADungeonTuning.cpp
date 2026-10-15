/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AllCreatureScript.h"
#include "AllMapScript.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Config.h"
#include "Creature.h"
#include "DBCStores.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "SpellInfo.h"
#include "StringFormat.h"
#include "UnitScript.h"
#include "WorldScript.h"
#include "WorldSession.h"
#include <mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;

namespace
{
    struct Tuning
    {
        int32 physical = 0;
        int32 magic = 0;
        int32 health = 0;
    };

    bool Enabled = false;
    std::mutex Lock;
    std::unordered_map<uint32, Tuning> Tunings;

    bool Tuned(Map const* map, Tuning& out)
    {
        if (!Enabled || !map || !map->IsNonRaidDungeon())
            return false;
        std::lock_guard<std::mutex> guard(Lock);
        auto itr = Tunings.find(map->GetInstanceId());
        if (itr == Tunings.end())
            return false;
        out = itr->second;
        return true;
    }

    float Percent(int32 value)
    {
        return std::max(0.0f, 1.0f + value / 100.0f);
    }

    bool IsTunable(Creature const* creature)
    {
        return creature && !creature->IsPet() && !creature->IsTotem() && !creature->IsControlledByPlayer();
    }

    void ScaleHealth(Creature* creature, float factor)
    {
        if (!IsTunable(creature) || factor <= 0.0f || factor == 1.0f)
            return;
        float const pct = creature->GetMaxHealth() ? float(creature->GetHealth()) / creature->GetMaxHealth() : 1.0f;
        uint32 const health = std::max<uint32>(1, uint32(creature->GetCreateHealth() * factor));
        creature->SetCreateHealth(health);
        creature->SetStatFlatModifier(UNIT_MOD_HEALTH, BASE_VALUE, float(health));
        creature->UpdateMaxHealth();
        if (creature->IsAlive())
            creature->SetHealth(std::max<uint32>(1, uint32(creature->GetMaxHealth() * pct)));
    }

    float DamageFactor(Unit const* attacker, bool physical)
    {
        Creature const* creature = attacker ? attacker->ToCreature() : nullptr;
        Tuning tuning;
        if (!IsTunable(creature) || !Tuned(creature->GetMap(), tuning))
            return 1.0f;
        return Percent(physical ? tuning.physical : tuning.magic);
    }

    bool IsPhysical(SpellInfo const* spellInfo)
    {
        return !spellInfo || (spellInfo->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL);
    }

    char const* DifficultyName(Map const* map)
    {
        switch (map->GetDifficulty())
        {
            case DUNGEON_DIFFICULTY_NORMAL: return "Normal";
            case DUNGEON_DIFFICULTY_HEROIC: return "Heroic";
            case DUNGEON_DIFFICULTY_EPIC:   return "Mythic";
            default:                        return "?";
        }
    }

    std::string DungeonName(Map const* map)
    {
        for (LFGDungeonEntry const* entry : sLFGDungeonStore)
            if (entry && entry->MapID == map->GetId() && entry->Difficulty == uint32(map->GetDifficulty()) && entry->Name[0][0])
                return entry->Name[0];
        return map->GetMapName();
    }
}

class CoADungeonTuningWorld final : public WorldScript
{
public:
    CoADungeonTuningWorld() : WorldScript("CoADungeonTuningWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnAfterConfigLoad(bool) override
    {
        Enabled = sConfigMgr->GetOption<bool>("CoA.DungeonTuning.Enable", true);
    }
};

class CoADungeonTuningDamage final : public UnitScript
{
public:
    CoADungeonTuningDamage() : UnitScript("CoADungeonTuningDamage", true,
        { UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK }) { }

    void ModifyMeleeDamage(Unit*, Unit* attacker, uint32& damage) override
    {
        if (float f = DamageFactor(attacker, true); f != 1.0f)
            damage = uint32(damage * f);
    }

    void ModifySpellDamageTaken(Unit*, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (float f = DamageFactor(attacker, IsPhysical(spellInfo)); f != 1.0f)
            damage = int32(damage * f);
    }

    void ModifyPeriodicDamageAurasTick(Unit*, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (float f = DamageFactor(attacker, IsPhysical(spellInfo)); f != 1.0f)
            damage = uint32(damage * f);
    }
};

class CoADungeonTuningHealth final : public AllCreatureScript
{
public:
    CoADungeonTuningHealth() : AllCreatureScript("CoADungeonTuningHealth") { }

    void OnCreatureSelectLevel(CreatureTemplate const*, Creature* creature) override
    {
        Tuning tuning;
        if (Tuned(creature->FindMap(), tuning) && tuning.health)
            ScaleHealth(creature, Percent(tuning.health));
    }
};

class CoADungeonTuningInstances final : public AllMapScript
{
public:
    CoADungeonTuningInstances() : AllMapScript("CoADungeonTuningInstances", { ALLMAPHOOK_ON_DESTROY_INSTANCE }) { }

    void OnDestroyInstance(MapInstanced*, Map* map) override
    {
        std::lock_guard<std::mutex> guard(Lock);
        Tunings.erase(map->GetInstanceId());
    }
};

class CoADungeonTuningCommands final : public CommandScript
{
public:
    CoADungeonTuningCommands() : CommandScript("CoADungeonTuningCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable mythicTable =
        {
            { "damage", HandleDamage, SEC_PLAYER, Console::No },
            { "health", HandleHealth, SEC_PLAYER, Console::No },
        };
        static ChatCommandTable commandTable =
        {
            { "mythic", mythicTable },
        };
        return commandTable;
    }

    static bool HandleDamage(ChatHandler* handler, Optional<int32> percent, Optional<std::string> type)
    {
        Map* map = TuningMap(handler);
        if (!map)
            return false;
        if (!percent)
            return Report(handler, map, false);

        bool physical = true;
        bool magic = true;
        if (type)
        {
            physical = type->starts_with("p") || type->starts_with("me");
            magic = type->starts_with("ma") || type->starts_with("s");
            if (!physical && !magic)
            {
                handler->SendErrorMessage("Type: physical or magic.");
                return false;
            }
        }
        {
            std::lock_guard<std::mutex> guard(Lock);
            Tuning& tuning = Tunings[map->GetInstanceId()];
            int32 const value = std::clamp<int32>(*percent, -95, 1000);
            if (physical)
                tuning.physical = value;
            if (magic)
                tuning.magic = value;
        }
        return Report(handler, map, true);
    }

    static bool HandleHealth(ChatHandler* handler, Optional<int32> percent)
    {
        Map* map = TuningMap(handler);
        if (!map)
            return false;
        if (!percent)
            return Report(handler, map, false);

        float ratio;
        {
            std::lock_guard<std::mutex> guard(Lock);
            Tuning& tuning = Tunings[map->GetInstanceId()];
            float const before = Percent(tuning.health);
            tuning.health = std::clamp<int32>(*percent, -95, 1000);
            ratio = Percent(tuning.health) / before;
        }
        for (auto const& [spawnId, creature] : map->GetCreatureBySpawnIdStore())
            ScaleHealth(creature, ratio);
        return Report(handler, map, true);
    }

private:
    static Map* TuningMap(ChatHandler* handler)
    {
        if (!Enabled)
        {
            handler->SendErrorMessage("Dungeon test tuning is switched off (CoA.DungeonTuning.Enable).");
            return nullptr;
        }
        Player* player = handler->GetPlayer();
        Map* map = player ? player->GetMap() : nullptr;
        if (!map || !map->IsNonRaidDungeon())
        {
            handler->SendErrorMessage("Only inside a 5-man dungeon.");
            return nullptr;
        }
        return map;
    }

    static bool Report(ChatHandler* handler, Map* map, bool changed)
    {
        Tuning tuning;
        Tuned(map, tuning);
        std::string const text = Acore::StringFormat(
            "Test tuning {} ({}): physical {:+}% ({}%), magic {:+}% ({}%), health {:+}% ({}%)", DungeonName(map),
            DifficultyName(map), tuning.physical, 100 + tuning.physical, tuning.magic, 100 + tuning.magic,
            tuning.health, 100 + tuning.health);
        if (!changed)
        {
            handler->SendSysMessage(text);
            return true;
        }
        map->DoForAllPlayers([&text](Player* player) { ChatHandler(player->GetSession()).SendSysMessage(text); });
        LOG_INFO("server.dungeontuning", "TUNING map={} difficulty={} instance={} by={} physical={} magic={} health={}",
            map->GetId(), uint32(map->GetDifficulty()), map->GetInstanceId(), handler->GetPlayer()->GetName(),
            tuning.physical, tuning.magic, tuning.health);
        return true;
    }
};

void AddSC_CoADungeonTuning()
{
    new CoADungeonTuningWorld();
    new CoADungeonTuningDamage();
    new CoADungeonTuningHealth();
    new CoADungeonTuningInstances();
    new CoADungeonTuningCommands();
}
