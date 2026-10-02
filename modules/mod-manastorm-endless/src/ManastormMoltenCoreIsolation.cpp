#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllCreatureScript.h"
#include "AllMapScript.h"
#include "Creature.h"
#include "InstanceMap.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless";
    constexpr uint32 MAP_MOLTEN_CORE = 409;
    constexpr uint32 SEGMENT_LUCIFRON = 608;
    constexpr uint32 SEGMENT_MAGMADAR = 609;
    constexpr uint32 SEGMENT_SHAZZRAH = 612;
    constexpr uint32 SEGMENT_BARON_GEDDON = 613;
    constexpr uint32 SEGMENT_SULFURON = 614;
    constexpr uint32 DATA_LUCIFRON = 0;
    constexpr uint32 DATA_MAGMADAR = 1;
    constexpr uint32 DATA_SHAZZRAH = 4;
    constexpr uint32 DATA_GEDDON = 5;
    constexpr uint32 NPC_LUCIFRON = 12118;
    constexpr uint32 NPC_MAGMADAR = 11982;
    constexpr uint32 NPC_SHAZZRAH = 12264;
    constexpr uint32 NPC_BARON_GEDDON = 12056;

    bool GetSuppressedBoss(ManastormRun const& run, uint32& bossData, uint32& bossEntry)
    {
        switch (run.GetSegment().SegmentId)
        {
            case SEGMENT_LUCIFRON:
                bossData = DATA_MAGMADAR;
                bossEntry = NPC_MAGMADAR;
                return true;
            case SEGMENT_MAGMADAR:
                bossData = DATA_LUCIFRON;
                bossEntry = NPC_LUCIFRON;
                return true;
            case SEGMENT_SHAZZRAH:
                bossData = DATA_GEDDON;
                bossEntry = NPC_BARON_GEDDON;
                return true;
            case SEGMENT_BARON_GEDDON:
                bossData = DATA_SHAZZRAH;
                bossEntry = NPC_SHAZZRAH;
                return true;
            case SEGMENT_SULFURON:
                bossData = DATA_GEDDON;
                bossEntry = NPC_BARON_GEDDON;
                return true;
            default:
                return false;
        }
    }

    ManastormRun* GetRunForMap(Map* map)
    {
        if (!map || map->GetId() != MAP_MOLTEN_CORE || !map->GetInstanceId())
            return nullptr;

        ManastormMgr& mgr = ManastormMgr::Instance();

        for (auto const& playerRef : map->GetPlayers())
        {
            Player* player = playerRef.GetSource();
            if (!player)
                continue;

            ManastormRun* run = mgr.GetRunFor(player);
            if (!run || run->GetSegment().MapId != MAP_MOLTEN_CORE || run->GetInstanceId() != map->GetInstanceId())
                continue;

            return run;
        }

        return nullptr;
    }

    void ApplyMoltenCoreBossIsolation(Map* map, ManastormRun& run)
    {
        if (!map || map->GetId() != MAP_MOLTEN_CORE || run.GetSegment().MapId != MAP_MOLTEN_CORE || run.GetInstanceId() != map->GetInstanceId())
            return;

        uint32 bossData = 0;
        uint32 bossEntry = 0;
        if (!GetSuppressedBoss(run, bossData, bossEntry))
            return;

        InstanceMap* instanceMap = map->ToInstanceMap();
        if (!instanceMap)
            return;

        InstanceScript* instance = instanceMap->GetInstanceScript();
        if (!instance)
            return;

        if (instance->GetBossState(bossData) != DONE)
            instance->SetBossState(bossData, DONE);

        uint32 despawned = 0;
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* creature = spawn.second;
            if (!creature || !creature->IsInWorld() || creature->GetEntry() != bossEntry)
                continue;

            creature->DespawnOrUnsummon();
            ++despawned;
        }

        LOG_INFO(LOG_FILTER,
            "Manastorm MC isolation applied: run={} segment={} suppressedBossEntry={} bossData={} despawned={} instance={}.",
            run.GetRunId(), run.GetSegment().SegmentId, bossEntry, bossData, despawned, run.GetInstanceId());
    }

    class manastorm_molten_core_map_isolation : public AllMapScript
    {
    public:
        manastorm_molten_core_map_isolation() : AllMapScript("manastorm_molten_core_map_isolation") { }

        void OnPlayerEnterAll(Map* map, Player* player) override
        {
            if (!ManastormModuleConfig::Enabled() || !map || !player || map->GetId() != MAP_MOLTEN_CORE)
                return;

            ManastormRun* run = ManastormMgr::Instance().GetRunFor(player);
            if (!run)
                return;

            ApplyMoltenCoreBossIsolation(map, *run);
        }
    };

    class manastorm_molten_core_creature_isolation : public AllCreatureScript
    {
    public:
        manastorm_molten_core_creature_isolation() : AllCreatureScript("manastorm_molten_core_creature_isolation") { }

        void OnCreatureAddWorld(Creature* creature) override
        {
            if (!ManastormModuleConfig::Enabled() || !creature || creature->GetMapId() != MAP_MOLTEN_CORE)
                return;

            ManastormRun* run = GetRunForMap(creature->GetMap());
            if (!run)
                return;

            uint32 bossData = 0;
            uint32 bossEntry = 0;
            if (!GetSuppressedBoss(*run, bossData, bossEntry) || creature->GetEntry() != bossEntry)
                return;

            ApplyMoltenCoreBossIsolation(creature->GetMap(), *run);
        }
    };
}

void AddSC_manastorm_molten_core_isolation()
{
    new manastorm_molten_core_map_isolation();
    new manastorm_molten_core_creature_isolation();
}
