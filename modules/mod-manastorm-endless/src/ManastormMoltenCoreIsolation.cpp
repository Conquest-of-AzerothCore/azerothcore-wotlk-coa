#include "ManastormModuleConfig.h"
#include "ManastormMgr.h"

#include "AllCreatureScript.h"
#include "AllMapScript.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "TemporarySummon.h"

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless";
    constexpr uint32 MAP_MOLTEN_CORE = 409;
    constexpr uint32 SEGMENT_LUCIFRON = 608;
    constexpr uint32 SEGMENT_MAGMADAR = 609;
    constexpr uint32 SEGMENT_SHAZZRAH = 612;
    constexpr uint32 SEGMENT_BARON_GEDDON = 613;
    constexpr uint32 SEGMENT_SULFURON = 614;
    constexpr uint32 SEGMENT_RAGNAROS = 670;
    constexpr uint32 DATA_LUCIFRON = 0;
    constexpr uint32 DATA_MAGMADAR = 1;
    constexpr uint32 DATA_GEHENNAS = 2;
    constexpr uint32 DATA_GARR = 3;
    constexpr uint32 DATA_SHAZZRAH = 4;
    constexpr uint32 DATA_GEDDON = 5;
    constexpr uint32 DATA_SULFURON = 6;
    constexpr uint32 DATA_GOLEMAGG = 7;
    constexpr uint32 DATA_MAJORDOMO_EXECUTUS = 8;
    constexpr uint32 DATA_RAGNAROS = 9;
    constexpr uint32 NPC_LUCIFRON = 12118;
    constexpr uint32 NPC_MAGMADAR = 11982;
    constexpr uint32 NPC_SHAZZRAH = 12264;
    constexpr uint32 NPC_BARON_GEDDON = 12056;
    constexpr uint32 NPC_MAJORDOMO_EXECUTUS = 12018;
    constexpr int32 ACTION_START_RAGNAROS_INTRO = -1;

    Position const MAJORDOMO_RAGNAROS_POSITION =
    {
        848.933f,
        -812.875f,
        -229.601f,
        4.046f
    };

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

        std::vector<ObjectGuid> bossGuids;
        for (auto const& spawn : map->GetCreatureBySpawnIdStore())
        {
            Creature* creature = spawn.second;
            if (!creature || !creature->IsInWorld() || creature->GetEntry() != bossEntry)
                continue;

            bossGuids.push_back(creature->GetGUID());
        }

        uint32 despawned = 0;
        for (ObjectGuid const& guid : bossGuids)
        {
            Creature* creature = map->GetCreature(guid);
            if (!creature || !creature->IsInWorld())
                continue;

            creature->DespawnOrUnsummon();
            ++despawned;
        }

        LOG_INFO(LOG_FILTER,
            "Manastorm MC isolation applied: run={} segment={} suppressedBossEntry={} bossData={} despawned={} instance={}.",
            run.GetRunId(), run.GetSegment().SegmentId, bossEntry, bossData, despawned, run.GetInstanceId());
    }

    void BootstrapMoltenCoreRagnaros(Map* map, ManastormRun& run)
    {
        if (!map || map->GetId() != MAP_MOLTEN_CORE || run.GetSegment().SegmentId != SEGMENT_RAGNAROS ||
            run.GetSegment().MapId != MAP_MOLTEN_CORE || run.GetInstanceId() != map->GetInstanceId())
            return;

        InstanceMap* instanceMap = map->ToInstanceMap();
        if (!instanceMap)
            return;

        InstanceScript* instance = instanceMap->GetInstanceScript();
        if (!instance)
            return;

        ObjectGuid const ragnarosGuid = instance->GetGuidData(DATA_RAGNAROS);
        if (!ragnarosGuid.IsEmpty())
        {
            if (Creature* ragnaros = instanceMap->GetCreature(ragnarosGuid))
            {
                if (ragnaros->IsInWorld())
                    return;
            }
        }

        if (instance->GetBossState(DATA_MAJORDOMO_EXECUTUS) != DONE)
            instance->SetBossState(DATA_MAJORDOMO_EXECUTUS, DONE);

        uint32 const prerequisiteBosses[] =
        {
            DATA_MAGMADAR,
            DATA_GEHENNAS,
            DATA_GARR,
            DATA_SHAZZRAH,
            DATA_GEDDON,
            DATA_SULFURON,
            DATA_GOLEMAGG
        };

        for (uint32 bossData : prerequisiteBosses)
        {
            if (instance->GetBossState(bossData) != DONE)
                instance->SetBossState(bossData, DONE);
        }

        Creature* majordomo = nullptr;
        ObjectGuid const majordomoGuid = instance->GetGuidData(DATA_MAJORDOMO_EXECUTUS);
        if (!majordomoGuid.IsEmpty())
            majordomo = instanceMap->GetCreature(majordomoGuid);

        if (!majordomo || !majordomo->IsInWorld())
            majordomo = map->SummonCreature(NPC_MAJORDOMO_EXECUTUS, MAJORDOMO_RAGNAROS_POSITION);

        if (!majordomo || !majordomo->AI())
        {
            LOG_ERROR(LOG_FILTER,
                "Manastorm MC Ragnaros bootstrap failed: run={} segment={} instance={} could not prepare Majordomo Executus.",
                run.GetRunId(), run.GetSegment().SegmentId, run.GetInstanceId());
            return;
        }

        majordomo->AI()->DoAction(ACTION_START_RAGNAROS_INTRO);

        LOG_INFO(LOG_FILTER,
            "Manastorm MC Ragnaros bootstrap started native Majordomo sequence: run={} segment={} instance={} majordomoGuid={}.",
            run.GetRunId(), run.GetSegment().SegmentId, run.GetInstanceId(), majordomo->GetGUID().GetRawValue());
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
            BootstrapMoltenCoreRagnaros(map, *run);
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
