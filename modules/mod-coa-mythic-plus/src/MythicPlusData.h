/*
 * Client tables Mythic+ is built on, read straight from the DBC files in DataDir.
 *
 * The core does not load these four; they are Ascension's own:
 *  - TimedDungeons.dbc    LFG dungeon -> enemy forces, required encounters,
 *                          champions, time limit (ms), reward multiplier.
 *                          The four logged runs of 23 Aug 2026 match it exactly.
 *  - MythicKeystones.dbc  keystone item -> LFG dungeon, keystone level.
 *  - MythicPlusScaling.dbc level -> health %, physical damage %, magic damage %.
 *  - MythicAffixes.dbc    week (day of the year / 7, as the client counts it) and
 *                          level -> affix spells. The client works the affixes
 *                          out the same way for the tracker and the socket.
 */

#ifndef MOD_COA_MYTHIC_PLUS_DATA_H
#define MOD_COA_MYTHIC_PLUS_DATA_H

#include "Define.h"

#include <array>
#include <unordered_map>
#include <vector>

namespace CoaMythicPlus
{
    struct TimedDungeon
    {
        uint32 lfgId = 0;
        uint32 forcesTotal = 0;
        uint32 encountersRequired = 0;
        uint32 championsTotal = 0;
        uint32 timeLimitMs = 0;
        float rewardMultiplier = 1.0f;
        uint32 mapId = 0;           // from LFGDungeons.dbc
        uint32 expansion = 0;       // from LFGDungeons.dbc
    };

    struct Keystone
    {
        uint32 item = 0;
        uint32 lfgId = 0;
        uint32 level = 0;
    };

    // DungeonEncounterExtra.dbc: the bosses of one LFG dungeon (wing) as the
    // client lists them in the tracker, with their client encounter id.
    struct WingEncounter
    {
        uint32 id = 0;
        uint32 creature = 0;
        bool final = false;
    };

    struct Scaling
    {
        float health = 1.0f;
        float physical = 1.0f;
        float magic = 1.0f;
    };

    class Data
    {
    public:
        static Data& Instance();

        void Load();

        TimedDungeon const* GetDungeon(uint32 lfgId) const;
        Keystone const* GetKeystone(uint32 item) const;
        uint32 GetKeystoneItem(uint32 lfgId, uint32 level) const;
        Scaling GetScaling(uint32 level) const;
        std::vector<uint32> GetAffixes(uint32 rotation, uint32 level) const;

        // Keystone items whose dungeon lies on this map (the Scarlet Monastery
        // wings share one map, so there can be several dungeons per map).
        std::vector<uint32> const* GetKeystonesForMap(uint32 mapId) const;
        bool IsKeystone(uint32 item) const { return _keystones.count(item) != 0; }

        // Dungeons a new key can point at, for this level.
        std::vector<uint32> GetKeyPool(uint32 level, uint32 maxExpansion) const;

        std::vector<WingEncounter> const* GetWingEncounters(uint32 lfgId) const;
        std::unordered_map<uint32, TimedDungeon> const& Dungeons() const { return _dungeons; }
        std::vector<uint32> const& DisabledAffixes() const { return _disabledAffixes; }
        std::vector<uint32> const& AffixSubstitutes() const { return _affixSubstitutes; }
        // MythicAffixes.dbc rows (all 16 fields) in which a disabled affix was swapped, as the client needs them.
        std::vector<std::array<uint32, 16>> const& SwappedAffixRows() const { return _swappedAffixRows; }
        // An empty MythicAffixes.dbc row for a +1 key of this week. The table starts at +2; without a row for +1 the
        // client falls back to its last row and shows that week's full set on a +1 key, which has no affixes.
        std::array<uint32, 16> PlusOneAffixRow(uint32 rotation) const;

    private:
        std::unordered_map<uint32, std::vector<WingEncounter>> _wingEncounters;
        std::vector<uint32> _disabledAffixes;
        std::vector<uint32> _affixSubstitutes;
        std::unordered_map<uint32, TimedDungeon> _dungeons;
        std::unordered_map<uint32, Keystone> _keystones;
        std::unordered_map<uint64, uint32> _keystoneByDungeonLevel;
        std::unordered_map<uint32, std::vector<uint32>> _keystonesByMap;
        std::unordered_map<uint32, Scaling> _scaling;
        std::unordered_map<uint32, std::vector<uint32>> _affixes;   // rotation << 16 | level
        std::vector<std::array<uint32, 16>> _swappedAffixRows;
        uint32 _lastAffixRowId = 0;
        uint32 _affixRowScale = 0;
    };
}

#endif
