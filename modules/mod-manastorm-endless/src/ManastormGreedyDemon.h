#ifndef MANASTORM_GREEDY_DEMON_H
#define MANASTORM_GREEDY_DEMON_H

#include "Define.h"

#include <array>
#include <string>
#include <vector>

class Creature;
class GameObject;
class ManastormRun;
class Map;
class Player;

struct ManastormGreedyDemonRule
{
    uint32 CreatureEntry = 0;
    uint32 MinDepth = 1;
    uint32 BaseChanceBp = 0;
    uint32 ChancePerDepthBp = 0;
    uint32 MaxChanceBp = 0;
    uint32 EscapeDelayMs = 0;
    uint32 ShiftIntervalMs = 0;
    uint32 ShockIntervalMs = 0;
    uint32 ConfusionIntervalMs = 0;
    uint32 GoldMinCopper = 0;
    uint32 GoldMaxCopper = 0;
    uint32 UncommonWeight = 0;
    uint32 RareWeight = 0;
    uint32 EpicWeight = 0;
    bool Enabled = false;
};

struct ManastormGreedyLootCandidate
{
    uint32 ItemEntry = 0;
    uint8 Quality = 0;
    uint8 MinPlayerLevel = 1;
    uint8 MaxPlayerLevel = 80;
    uint32 Weight = 1;
};

class ManastormGreedyDemon
{
public:
    static ManastormGreedyDemon& Instance();

    bool Load();

    bool IsGreedyDemonEntry(uint32 entry) const;
    bool IsGreedyLootObject(uint32 entry) const;

    bool IsActiveGreedyDemon(
        Creature const* creature,
        ManastormRun const& run) const;

    bool TrySpawnForStage(
        Map* map,
        ManastormRun& run);

    bool ForceSpawn(
        Player* player,
        std::string& error);

    void OnKilled(
        Creature* creature,
        ManastormRun& run);

    bool ClaimLoot(
        Player* player,
        GameObject* gameObject);

    uint32 GetEscapeDelayMs() const
    {
        return _rule.EscapeDelayMs;
    }

    uint32 GetShiftIntervalMs() const
    {
        return _rule.ShiftIntervalMs;
    }

    uint32 GetShockIntervalMs() const
    {
        return _rule.ShockIntervalMs;
    }

    uint32 GetConfusionIntervalMs() const
    {
        return _rule.ConfusionIntervalMs;
    }

private:
    ManastormGreedyDemon() = default;

    bool SpawnForStage(
        Map* map,
        ManastormRun& run,
        bool force);

    uint8 RollLootQuality() const;

    uint32 SelectLootItem(
        uint8 quality,
        uint8 playerLevel) const;

    ManastormGreedyDemonRule _rule;
    std::array<
        std::vector<ManastormGreedyLootCandidate>,
        3> _lootPools;
    bool _loaded = false;
};

void AddSC_manastorm_greedy_demon();

#endif
