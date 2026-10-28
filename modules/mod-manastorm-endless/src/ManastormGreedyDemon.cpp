#include "ManastormGreedyDemon.h"

#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "GameObject.h"
#include "Log.h"
#include "ManastormMgr.h"
#include "ManastormRewards.h"
#include "ManastormRun.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryResult.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "SpellMgr.h"

#include <algorithm>
#include <limits>
#include <vector>

namespace
{
    constexpr char const* LOG_FILTER =
        "module.manastorm.endless.greedy";

    constexpr uint32 BASIS_POINTS = 10000;
    constexpr float TWO_PI = 6.28318530717958647692f;

    constexpr uint32 NPC_MANASTORM_HEART = 900025;

    constexpr uint32 SPELL_SHADOW_SHIFT = 875121;
    constexpr uint32 SPELL_FEL_PROTECTION = 875123;
    constexpr uint32 SPELL_SHADOW_ESCAPE_SPEED = 875126;
    constexpr uint32 SPELL_FEL_SHOCK = 875128;
    constexpr uint32 SPELL_SHADOW_ESCAPE_IMMUNITY = 875131;
    constexpr uint32 SPELL_FEL_CONFUSION = 875130;

    constexpr uint32 SPELL_UNCOMMON_LOOT_EXPLOSION = 760301;
    constexpr uint32 SPELL_RARE_LOOT_EXPLOSION = 760302;
    constexpr uint32 SPELL_EPIC_LOOT_EXPLOSION = 760303;

    constexpr uint32 GO_GREEDY_LOOT_UNCOMMON = 710014;
    constexpr uint32 GO_GREEDY_LOOT_RARE = 710015;
    constexpr uint32 GO_GREEDY_LOOT_EPIC = 710016;

    constexpr uint8 GREEDY_ITEM_QUALITY_UNCOMMON = 2;
    constexpr uint8 GREEDY_ITEM_QUALITY_RARE = 3;
    constexpr uint8 GREEDY_ITEM_QUALITY_EPIC = 4;

    constexpr uint32 ESCAPE_IMMUNITY_PREP_MS = 2500;
    constexpr uint32 ESCAPE_RUN_MS = 2000;

    uint32 LootSpellForQuality(uint8 quality)
    {
        switch (quality)
        {
            case GREEDY_ITEM_QUALITY_UNCOMMON:
                return SPELL_UNCOMMON_LOOT_EXPLOSION;
            case GREEDY_ITEM_QUALITY_RARE:
                return SPELL_RARE_LOOT_EXPLOSION;
            case GREEDY_ITEM_QUALITY_EPIC:
                return SPELL_EPIC_LOOT_EXPLOSION;
            default:
                return 0;
        }
    }

    uint32 LootObjectForQuality(uint8 quality)
    {
        switch (quality)
        {
            case GREEDY_ITEM_QUALITY_UNCOMMON:
                return GO_GREEDY_LOOT_UNCOMMON;
            case GREEDY_ITEM_QUALITY_RARE:
                return GO_GREEDY_LOOT_RARE;
            case GREEDY_ITEM_QUALITY_EPIC:
                return GO_GREEDY_LOOT_EPIC;
            default:
                return 0;
        }
    }

    uint8 QualityForLootObject(uint32 entry)
    {
        switch (entry)
        {
            case GO_GREEDY_LOOT_UNCOMMON:
                return GREEDY_ITEM_QUALITY_UNCOMMON;
            case GO_GREEDY_LOOT_RARE:
                return GREEDY_ITEM_QUALITY_RARE;
            case GO_GREEDY_LOOT_EPIC:
                return GREEDY_ITEM_QUALITY_EPIC;
            default:
                return 0;
        }
    }

    std::size_t QualityPoolIndex(uint8 quality)
    {
        return std::size_t(
            quality -
            GREEDY_ITEM_QUALITY_UNCOMMON);
    }
}

ManastormGreedyDemon&
ManastormGreedyDemon::Instance()
{
    static ManastormGreedyDemon instance;
    return instance;
}

bool ManastormGreedyDemon::Load()
{
    _loaded = false;
    _rule = {};

    for (auto& pool : _lootPools)
        pool.clear();

    QueryResult ruleResult =
        WorldDatabase.Query(
            "SELECT "
            "creature_entry, min_depth, "
            "base_chance_bp, chance_per_depth_bp, max_chance_bp, "
            "escape_delay_ms, shift_interval_ms, "
            "shock_interval_ms, confusion_interval_ms, "
            "gold_min_copper, gold_max_copper, "
            "uncommon_weight, rare_weight, epic_weight, enabled "
            "FROM manastorm_greedy_demon_rule "
            "WHERE rule_id = 1");

    if (!ruleResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Unable to load manastorm_greedy_demon_rule. "
            "Apply 24_manastorm_greedy_demon.sql.");

        return false;
    }

    Field* fields =
        ruleResult->Fetch();

    _rule.CreatureEntry =
        fields[0].Get<uint32>();
    _rule.MinDepth =
        fields[1].Get<uint32>();
    _rule.BaseChanceBp =
        fields[2].Get<uint32>();
    _rule.ChancePerDepthBp =
        fields[3].Get<uint32>();
    _rule.MaxChanceBp =
        fields[4].Get<uint32>();
    _rule.EscapeDelayMs =
        fields[5].Get<uint32>();
    _rule.ShiftIntervalMs =
        fields[6].Get<uint32>();
    _rule.ShockIntervalMs =
        fields[7].Get<uint32>();
    _rule.ConfusionIntervalMs =
        fields[8].Get<uint32>();
    _rule.GoldMinCopper =
        fields[9].Get<uint32>();
    _rule.GoldMaxCopper =
        fields[10].Get<uint32>();
    _rule.UncommonWeight =
        fields[11].Get<uint32>();
    _rule.RareWeight =
        fields[12].Get<uint32>();
    _rule.EpicWeight =
        fields[13].Get<uint32>();
    _rule.Enabled =
        fields[14].Get<uint8>() != 0;

    if (!_rule.Enabled)
    {
        _loaded = true;
        return true;
    }

    uint64 const qualityWeightTotal =
        uint64(_rule.UncommonWeight) +
        uint64(_rule.RareWeight) +
        uint64(_rule.EpicWeight);

    if (!_rule.CreatureEntry ||
        !_rule.MinDepth ||
        !_rule.MaxChanceBp ||
        _rule.MaxChanceBp > BASIS_POINTS ||
        _rule.BaseChanceBp > BASIS_POINTS ||
        _rule.GoldMinCopper >
            _rule.GoldMaxCopper ||
        _rule.GoldMaxCopper >
            uint32(
                std::numeric_limits<int32>::max()) ||
        !_rule.EscapeDelayMs ||
        !_rule.ShiftIntervalMs ||
        !_rule.ShockIntervalMs ||
        !_rule.ConfusionIntervalMs ||
        !qualityWeightTotal ||
        qualityWeightTotal >
            std::numeric_limits<uint32>::max() ||
        !sObjectMgr->GetCreatureTemplate(
            _rule.CreatureEntry))
    {
        LOG_ERROR(
            LOG_FILTER,
            "Enabled Greedy Demon rule is invalid.");

        return false;
    }

    constexpr uint32 requiredSpells[] =
    {
        SPELL_SHADOW_SHIFT,
        SPELL_FEL_PROTECTION,
        SPELL_SHADOW_ESCAPE_SPEED,
        SPELL_FEL_SHOCK,
        SPELL_SHADOW_ESCAPE_IMMUNITY,
        SPELL_FEL_CONFUSION,
        SPELL_UNCOMMON_LOOT_EXPLOSION,
        SPELL_RARE_LOOT_EXPLOSION,
        SPELL_EPIC_LOOT_EXPLOSION,
    };

    for (uint32 spellId : requiredSpells)
    {
        if (!sSpellMgr->GetSpellInfo(spellId))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Greedy Demon requires missing spell {}.",
                spellId);

            return false;
        }
    }

    constexpr uint32 requiredObjects[] =
    {
        GO_GREEDY_LOOT_UNCOMMON,
        GO_GREEDY_LOOT_RARE,
        GO_GREEDY_LOOT_EPIC,
    };

    for (uint32 entry : requiredObjects)
    {
        if (!sObjectMgr->GetGameObjectTemplate(entry))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Greedy Demon requires missing loot object {}.",
                entry);

            return false;
        }
    }

    QueryResult lootResult =
        WorldDatabase.Query(
            "SELECT "
            "item_entry, quality_tier, "
            "min_player_level, max_player_level, weight "
            "FROM manastorm_greedy_demon_loot_pool "
            "WHERE enabled = 1 "
            "ORDER BY quality_tier, item_entry");

    if (!lootResult)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Greedy Demon loot pool is empty. "
            "Apply 24_manastorm_greedy_demon.sql.");

        return false;
    }

    do
    {
        Field* lootFields =
            lootResult->Fetch();

        ManastormGreedyLootCandidate candidate;

        candidate.ItemEntry =
            lootFields[0].Get<uint32>();
        candidate.Quality =
            lootFields[1].Get<uint8>();
        candidate.MinPlayerLevel =
            lootFields[2].Get<uint8>();
        candidate.MaxPlayerLevel =
            lootFields[3].Get<uint8>();
        candidate.Weight =
            lootFields[4].Get<uint32>();

        if (candidate.Quality <
                GREEDY_ITEM_QUALITY_UNCOMMON ||
            candidate.Quality >
                GREEDY_ITEM_QUALITY_EPIC ||
            !candidate.ItemEntry ||
            !candidate.Weight ||
            !candidate.MinPlayerLevel ||
            candidate.MinPlayerLevel >
                candidate.MaxPlayerLevel)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Invalid Greedy Demon loot-pool row for item {}.",
                candidate.ItemEntry);

            return false;
        }

        ItemTemplate const* itemTemplate =
            sObjectMgr->GetItemTemplate(
                candidate.ItemEntry);

        if (!itemTemplate ||
            uint8(itemTemplate->Quality) !=
                candidate.Quality)
        {
            LOG_ERROR(
                LOG_FILTER,
                "Greedy Demon loot item {} is missing or has "
                "quality {} instead of configured quality {}.",
                candidate.ItemEntry,
                itemTemplate
                    ? uint32(itemTemplate->Quality)
                    : 0,
                uint32(candidate.Quality));

            return false;
        }

        candidate.ItemLevel =
            itemTemplate->ItemLevel;

        _lootPools[
            QualityPoolIndex(
                candidate.Quality)]
            .push_back(candidate);
    } while (lootResult->NextRow());

    for (uint8 quality =
            GREEDY_ITEM_QUALITY_UNCOMMON;
        quality <=
            GREEDY_ITEM_QUALITY_EPIC;
        ++quality)
    {
        if (_lootPools[
                QualityPoolIndex(
                    quality)]
                .empty())
        {
            LOG_ERROR(
                LOG_FILTER,
                "Greedy Demon loot pool has no enabled quality-{} items.",
                uint32(quality));

            return false;
        }
    }

    _loaded = true;

    LOG_INFO(
        LOG_FILTER,
        "Loaded Greedy Demon encounter: entry={} minDepth={} "
        "spawn={:.2f}%+{:.2f}%/depth cap={:.2f}% "
        "lootPools={}/{}/{}.",
        _rule.CreatureEntry,
        _rule.MinDepth,
        double(_rule.BaseChanceBp) / 100.0,
        double(_rule.ChancePerDepthBp) / 100.0,
        double(_rule.MaxChanceBp) / 100.0,
        _lootPools[0].size(),
        _lootPools[1].size(),
        _lootPools[2].size());

    return true;
}

bool ManastormGreedyDemon::IsGreedyDemonEntry(
    uint32 entry) const
{
    return _loaded &&
        _rule.Enabled &&
        entry ==
            _rule.CreatureEntry;
}

bool ManastormGreedyDemon::IsGreedyLootObject(
    uint32 entry) const
{
    return entry ==
            GO_GREEDY_LOOT_UNCOMMON ||
        entry ==
            GO_GREEDY_LOOT_RARE ||
        entry ==
            GO_GREEDY_LOOT_EPIC;
}

bool ManastormGreedyDemon::IsActiveGreedyDemon(
    Creature const* creature,
    ManastormRun const& run) const
{
    return creature &&
        IsGreedyDemonEntry(
            creature->GetEntry()) &&
        !run.GetGreedyDemonGuid()
            .IsEmpty() &&
        run.GetGreedyDemonGuid() ==
            creature->GetGUID();
}

bool ManastormGreedyDemon::TrySpawnForStage(
    Map* map,
    ManastormRun& run)
{
    return SpawnForStage(
        map,
        run,
        false);
}

bool ManastormGreedyDemon::ForceSpawn(
    Player* player,
    std::string& error)
{
    error.clear();

    if (!_loaded ||
        !_rule.Enabled)
    {
        error =
            "Greedy Demon encounter is disabled or not loaded.";
        return false;
    }

    if (!player ||
        !player->IsInWorld())
    {
        error =
            "A connected in-game player is required.";
        return false;
    }

    ManastormRun* run =
        ManastormMgr::Instance()
            .GetRunFor(player);

    if (!run ||
        run->GetState() !=
            ManastormRunState::Active)
    {
        error =
            "Greedy Demon can only be forced during an ACTIVE Manastorm stage.";
        return false;
    }

    Map* map =
        player->FindMap();

    if (!map ||
        map->GetId() !=
            run->GetSegment().MapId ||
        map->GetInstanceId() !=
            run->GetInstanceId())
    {
        error =
            "Player is not inside the current Manastorm stage instance.";
        return false;
    }

    if (!run->GetGreedyDemonGuid()
            .IsEmpty())
    {
        Creature* existing =
            map->GetCreature(
                run->GetGreedyDemonGuid());

        if (existing &&
            existing->IsAlive())
        {
            error =
                "A Greedy Demon is already active in this stage.";
            return false;
        }

        run->ClearGreedyDemonGuid();
    }

    if (!SpawnForStage(
            map,
            *run,
            true))
    {
        error =
            "Greedy Demon could not be spawned. Check worldserver logs.";
        return false;
    }

    return true;
}

bool ManastormGreedyDemon::SpawnForStage(
    Map* map,
    ManastormRun& run,
    bool force)
{
    if (!_loaded ||
        !_rule.Enabled ||
        !map ||
        run.GetState() !=
            ManastormRunState::Active ||
        run.GetDepth() <
            _rule.MinDepth ||
        (!force &&
            run.GreedyDemonRolled()))
    {
        return false;
    }

    if (!run.GetGreedyDemonGuid()
            .IsEmpty())
    {
        return false;
    }

    run.SetGreedyDemonRolled(true);

    uint32 chanceBp = BASIS_POINTS;

    if (!force)
    {
        uint64 const depthBonus =
            run.GetDepth() > 1
            ? uint64(run.GetDepth() - 1) *
                uint64(
                    _rule
                        .ChancePerDepthBp)
            : 0;

        uint64 const rawChance =
            uint64(
                _rule.BaseChanceBp) +
            depthBonus;

        chanceBp =
            uint32(
                std::min<uint64>(
                    _rule.MaxChanceBp,
                    rawChance));

        if (!chanceBp ||
            urand(1, BASIS_POINTS) >
                chanceBp)
        {
            return false;
        }
    }

    std::vector<Creature*> anchors;
    anchors.reserve(
        run.GetStageCreatureCount());

    ObjectGuid const objectiveGuid =
        run.GetObjectiveCreatureGuid();

    for (ObjectGuid const& guid :
        run.GetStageCreatureGuids())
    {
        Creature* creature =
            map->GetCreature(guid);

        if (!creature ||
            !creature->IsInWorld() ||
            !creature->IsAlive() ||
            creature->IsTrigger() ||
            creature->IsPet() ||
            creature->GetEntry() ==
                NPC_MANASTORM_HEART ||
            creature->GetGUID() ==
                objectiveGuid ||
            IsGreedyDemonEntry(
                creature->GetEntry()) ||
            ManastormRewards::Instance()
                .IsTreasureKeeperEntry(
                    creature->GetEntry()))
        {
            continue;
        }

        ObjectGuid::LowType const spawnId =
            creature->GetSpawnId();

        // Reconstruction placement policy:
        // anchor Greedy Demon near authored Chaotic-Link route creatures.
        // This keeps the treasure encounter on the intended path from the
        // stage entrance toward the objective without tying its mechanics
        // to Chaotic Link itself.
        if (!spawnId ||
            !run.IsChaoticLinkSpawn(
                spawnId))
        {
            continue;
        }

        anchors.push_back(
            creature);
    }

    WorldObject* anchor = nullptr;

    if (!anchors.empty())
    {
        anchor =
            anchors[
                urand(
                    0,
                    uint32(
                        anchors.size() -
                        1))];
    }
    else
    {
        for (ObjectGuid::LowType memberGuid :
            run.GetMembers())
        {
            Player* member =
                ObjectAccessor::FindConnectedPlayer(
                    ObjectGuid::Create<
                        HighGuid::Player>(
                            memberGuid));

            if (!member ||
                !member->IsInWorld() ||
                member->GetMap() !=
                    map)
            {
                continue;
            }

            anchor = member;
            break;
        }
    }

    if (!anchor)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm run {} rolled Greedy Demon at depth {} "
            "but no valid spawn anchor exists.",
            run.GetRunId(),
            run.GetDepth());

        return false;
    }

    Position const position =
        anchor->GetFirstCollisionPosition(
            8.0f,
            frand(
                0.0f,
                TWO_PI));

    Creature* demon =
        map->SummonCreature(
            _rule.CreatureEntry,
            position);

    if (!demon)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm run {} rolled Greedy Demon at depth {} "
            "but creature {} could not be summoned.",
            run.GetRunId(),
            run.GetDepth(),
            _rule.CreatureEntry);

        return false;
    }

    run.SetGreedyDemonGuid(
        demon->GetGUID());

    demon->SetFaction(14);
    demon->SetReactState(
        REACT_PASSIVE);
    demon->SetLootRewardDisabled(
        true);
    demon->SetReputationRewardDisabled(
        true);
    demon->SetLootMode(0);

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} {} Greedy Demon {} at depth {} "
        "near a Chaotic-Link route anchor (chance={:.2f}%).",
        run.GetRunId(),
        force ? "force-spawned" : "spawned",
        demon->GetGUID()
            .GetRawValue(),
        run.GetDepth(),
        force
            ? 100.0
            : double(chanceBp) /
                100.0);

    return true;
}

uint8 ManastormGreedyDemon::RollLootQuality() const
{
    uint64 const total64 =
        uint64(
            _rule.UncommonWeight) +
        uint64(
            _rule.RareWeight) +
        uint64(
            _rule.EpicWeight);

    if (!total64 ||
        total64 >
            std::numeric_limits<uint32>::max())
    {
        return 0;
    }

    uint32 const roll =
        urand(
            1,
            uint32(total64));

    if (roll <=
        _rule.UncommonWeight)
    {
        return GREEDY_ITEM_QUALITY_UNCOMMON;
    }

    if (roll <=
        _rule.UncommonWeight +
        _rule.RareWeight)
    {
        return GREEDY_ITEM_QUALITY_RARE;
    }

    return GREEDY_ITEM_QUALITY_EPIC;
}

void ManastormGreedyDemon::OnKilled(
    Creature* creature,
    ManastormRun& run)
{
    if (!IsActiveGreedyDemon(
            creature,
            run))
    {
        return;
    }

    uint8 const quality =
        RollLootQuality();

    uint32 const lootSpell =
        LootSpellForQuality(
            quality);

    uint32 const lootObject =
        LootObjectForQuality(
            quality);

    if (!lootSpell ||
        !lootObject)
    {
        LOG_ERROR(
            LOG_FILTER,
            "Manastorm run {} killed Greedy Demon but "
            "loot quality resolution failed.",
            run.GetRunId());

        run.ClearGreedyDemonGuid();
        return;
    }

    SpellCastResult const result =
        creature->CastSpell(
            creature,
            lootSpell,
            true);

    if (result !=
        SPELL_CAST_OK)
    {
        Map* map =
            creature->GetMap();

        if (map)
        {
            map->SummonGameObject(
                lootObject,
                creature->GetPositionX(),
                creature->GetPositionY(),
                creature->GetPositionZ(),
                creature->GetOrientation(),
                0.0f,
                0.0f,
                0.0f,
                1.0f,
                300);
        }

        LOG_WARN(
            LOG_FILTER,
            "Greedy Demon loot explosion spell {} failed for run {}; "
            "used direct GO {} fallback.",
            lootSpell,
            run.GetRunId(),
            lootObject);
    }

    LOG_INFO(
        LOG_FILTER,
        "Manastorm run {} killed Greedy Demon {} and created "
        "quality-{} loot object {}.",
        run.GetRunId(),
        creature->GetGUID()
            .GetRawValue(),
        uint32(quality),
        lootObject);

    run.ClearGreedyDemonGuid();
}

uint32 ManastormGreedyDemon::SelectLootItem(
    uint8 quality,
    uint8 playerLevel) const
{
    if (quality <
            GREEDY_ITEM_QUALITY_UNCOMMON ||
        quality >
            GREEDY_ITEM_QUALITY_EPIC)
    {
        return 0;
    }

    auto const& pool =
        _lootPools[
            QualityPoolIndex(
                quality)];

    uint32 const itemLevelCap =
        ManastormRewards::Instance()
            .GetReleasedItemLevelCap();

    auto const inLevelWindow =
        [playerLevel](ManastormGreedyLootCandidate const& candidate)
        {
            return playerLevel >=
                    candidate.MinPlayerLevel &&
                playerLevel <=
                    candidate.MaxPlayerLevel;
        };

    uint64 eligibleWeight = 0;

    for (ManastormGreedyLootCandidate const& candidate :
        pool)
    {
        if (candidate.ItemLevel <= itemLevelCap &&
            inLevelWindow(candidate))
        {
            eligibleWeight +=
                candidate.Weight;
        }
    }

    bool const useLevelWindow =
        eligibleWeight != 0;

    if (!useLevelWindow)
    {
        for (ManastormGreedyLootCandidate const& candidate :
            pool)
        {
            if (candidate.ItemLevel <= itemLevelCap)
            {
                eligibleWeight +=
                    candidate.Weight;
            }
        }
    }

    if (!eligibleWeight ||
        eligibleWeight >
            std::numeric_limits<uint32>::max())
    {
        return 0;
    }

    uint32 roll =
        urand(
            1,
            uint32(
                eligibleWeight));

    for (ManastormGreedyLootCandidate const& candidate :
        pool)
    {
        if (candidate.ItemLevel > itemLevelCap ||
            (useLevelWindow &&
             !inLevelWindow(candidate)))
        {
            continue;
        }

        if (roll <=
            candidate.Weight)
        {
            return candidate.ItemEntry;
        }

        roll -=
            candidate.Weight;
    }

    return 0;
}

bool ManastormGreedyDemon::ClaimLoot(
    Player* player,
    GameObject* gameObject)
{
    if (!player ||
        !gameObject ||
        !IsGreedyLootObject(
            gameObject->GetEntry()))
    {
        return true;
    }

    if (!_loaded ||
        !_rule.Enabled)
    {
        player->SendSystemMessage(
            "Greedy Demon loot is currently unavailable.");
        return true;
    }

    ManastormRun* run =
        ManastormMgr::Instance()
            .GetRunFor(player);

    if (!run)
    {
        player->SendSystemMessage(
            "This Greedy Demon loot belongs to a Manastorm run.");
        return true;
    }

    Map* map =
        player->FindMap();

    if (!map ||
        gameObject->GetMap() !=
            map)
    {
        return true;
    }

    bool const currentStage =
        map->GetId() ==
            run->GetSegment().MapId &&
        map->GetInstanceId() ==
            run->GetInstanceId() &&
        (run->GetState() ==
            ManastormRunState::Active ||
         run->GetState() ==
            ManastormRunState::StageComplete);

    bool const previousStage =
        run->HasPreviousStage() &&
        map->GetId() ==
            run->GetPreviousSegment().MapId &&
        map->GetInstanceId() ==
            run->GetPreviousInstanceId();

    if (!currentStage &&
        !previousStage)
    {
        player->SendSystemMessage(
            "This Greedy Demon loot is not part of your current Manastorm stage.");
        return true;
    }

    uint8 const quality =
        QualityForLootObject(
            gameObject->GetEntry());

    uint32 const itemEntry =
        SelectLootItem(
            quality,
            player->GetLevel());

    if (!itemEntry)
    {
        player->SendSystemMessage(
            "Greedy Demon loot could not resolve an item reward.");
        return true;
    }

    if (!player->AddItem(
            itemEntry,
            1))
    {
        player->SendSystemMessage(
            "Make room in your bags before opening the Greedy Demon loot.");
        return true;
    }

    uint32 goldCopper = 0;

    switch (quality)
    {
        case GREEDY_ITEM_QUALITY_UNCOMMON:
            goldCopper = 280000; // 3g + 5g + 20g visual burst.
            break;
        case GREEDY_ITEM_QUALITY_RARE:
            goldCopper = 920000; // 13g + 37g + 42g visual burst.
            break;
        case GREEDY_ITEM_QUALITY_EPIC:
            goldCopper = 930000; // 12g + 23g + 58g visual burst.
            break;
        default:
            break;
    }

    if (goldCopper)
    {
        player->ModifyMoney(
            int32(goldCopper));
    }

    gameObject->SetGameObjectFlag(
        GO_FLAG_NOT_SELECTABLE);

    gameObject->SetLootState(
        GO_JUST_DEACTIVATED,
        player);

    LOG_INFO(
        LOG_FILTER,
        "Player {} claimed Greedy Demon loot: "
        "run={} quality={} item={} goldCopper={}.",
        player->GetGUID()
            .GetCounter(),
        run->GetRunId(),
        uint32(quality),
        itemEntry,
        goldCopper);

    player->SendSystemMessage(
        "Greedy Demon loot secured.");

    return true;
}

struct npc_manastorm_greedy_demon :
    public ScriptedAI
{
    explicit npc_manastorm_greedy_demon(
        Creature* creature)
        : ScriptedAI(creature)
    {
    }

    void Reset() override
    {
        _started = false;
        _escapeState = 0;
        _pursuerGuid.Clear();
        _shiftTimer = 0;
        _shockTimer = 0;
        _confusionTimer = 0;
        _escapeTimer = 0;
        _escapePrepTimer = 0;
        _escapeRunTimer = 0;

        me->SetReactState(
            REACT_PASSIVE);

        me->GetMotionMaster()
            ->MoveRandom(8.0f);
    }

    void JustEngagedWith(
        Unit* who) override
    {
        StartChase(who);
    }

    void DamageTaken(
        Unit* attacker,
        uint32& /*damage*/,
        DamageEffectType /*damageType*/,
        SpellSchoolMask /*damageSchoolMask*/) override
    {
        StartChase(attacker);

        if (attacker)
        {
            _pursuerGuid =
                attacker->GetGUID();

            me->CastSpell(
                me,
                SPELL_FEL_PROTECTION,
                true);
        }
    }

    void UpdateAI(
        uint32 diff) override
    {
        if (!_started ||
            !me->IsAlive())
        {
            return;
        }

        if (_escapeState == 2)
        {
            if (diff >=
                _escapeRunTimer)
            {
                me->DespawnOrUnsummon();
                return;
            }

            _escapeRunTimer -=
                diff;

            return;
        }

        if (_escapeState == 1)
        {
            if (diff <
                _escapePrepTimer)
            {
                _escapePrepTimer -=
                    diff;
                return;
            }

            Unit* pursuer =
                ResolvePursuer();

            me->CastSpell(
                me,
                SPELL_SHADOW_ESCAPE_SPEED,
                true);

            if (pursuer)
            {
                me->GetMotionMaster()
                    ->MoveFleeing(
                        pursuer,
                        ESCAPE_RUN_MS);
            }

            _escapeState = 2;
            _escapeRunTimer =
                ESCAPE_RUN_MS;

            return;
        }

        if (diff >=
            _escapeTimer)
        {
            me->CastSpell(
                me,
                SPELL_SHADOW_ESCAPE_IMMUNITY,
                true);

            _escapeState = 1;
            _escapePrepTimer =
                ESCAPE_IMMUNITY_PREP_MS;

            return;
        }

        _escapeTimer -=
            diff;

        Unit* pursuer =
            ResolvePursuer();

        if (diff >=
            _shiftTimer)
        {
            me->CastSpell(
                me,
                SPELL_SHADOW_SHIFT,
                true);

            _shiftTimer =
                ManastormGreedyDemon::Instance()
                    .GetShiftIntervalMs();
        }
        else
        {
            _shiftTimer -=
                diff;
        }

        if (diff >=
            _shockTimer)
        {
            if (pursuer)
            {
                me->CastSpell(
                    pursuer,
                    SPELL_FEL_SHOCK,
                    true);
            }

            _shockTimer =
                ManastormGreedyDemon::Instance()
                    .GetShockIntervalMs();
        }
        else
        {
            _shockTimer -=
                diff;
        }

        if (diff >=
            _confusionTimer)
        {
            if (pursuer)
            {
                me->CastSpell(
                    pursuer,
                    SPELL_FEL_CONFUSION,
                    true);
            }

            _confusionTimer =
                ManastormGreedyDemon::Instance()
                    .GetConfusionIntervalMs();
        }
        else
        {
            _confusionTimer -=
                diff;
        }
    }

private:
    void StartChase(
        Unit* attacker)
    {
        if (!attacker)
            return;

        _pursuerGuid =
            attacker->GetGUID();

        if (_started)
            return;

        _started = true;

        ManastormGreedyDemon const& encounter =
            ManastormGreedyDemon::Instance();

        _shiftTimer =
            encounter
                .GetShiftIntervalMs();
        _shockTimer =
            encounter
                .GetShockIntervalMs();
        _confusionTimer =
            encounter
                .GetConfusionIntervalMs();
        _escapeTimer =
            encounter
                .GetEscapeDelayMs();

        me->CastSpell(
            me,
            SPELL_FEL_PROTECTION,
            true);

        me->GetMotionMaster()
            ->MoveFleeing(
                attacker);
    }

    Unit* ResolvePursuer() const
    {
        if (_pursuerGuid.IsEmpty())
            return nullptr;

        Unit* unit =
            ObjectAccessor::GetUnit(
                *me,
                _pursuerGuid);

        if (!unit ||
            !unit->IsAlive() ||
            unit->GetMap() !=
                me->GetMap())
        {
            return nullptr;
        }

        return unit;
    }

    bool _started = false;
    uint8 _escapeState = 0;
    ObjectGuid _pursuerGuid;
    uint32 _shiftTimer = 0;
    uint32 _shockTimer = 0;
    uint32 _confusionTimer = 0;
    uint32 _escapeTimer = 0;
    uint32 _escapePrepTimer = 0;
    uint32 _escapeRunTimer = 0;
};

class go_manastorm_greedy_loot :
    public GameObjectScript
{
public:
    go_manastorm_greedy_loot()
        : GameObjectScript(
            "go_manastorm_greedy_loot")
    {
    }

    bool OnGossipHello(
        Player* player,
        GameObject* gameObject) override
    {
        return ManastormGreedyDemon::Instance()
            .ClaimLoot(
                player,
                gameObject);
    }
};

void AddSC_manastorm_greedy_demon()
{
    RegisterCreatureAI(
        npc_manastorm_greedy_demon);

    new go_manastorm_greedy_loot();
}
