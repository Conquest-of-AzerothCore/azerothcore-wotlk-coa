#include "MythicPlusData.h"

#include "Config.h"
#include "DBCStores.h"
#include "Log.h"

#include <algorithm>
#include <cstring>
#include <fstream>
#include <iterator>
#include <sstream>
#include <string>

namespace CoaMythicPlus
{
    namespace
    {
        // A plain WDBC file: header, fixed-size records, string block. The
        // four tables here hold only 32-bit fields.
        struct RawDbc
        {
            uint32 records = 0;
            uint32 fields = 0;
            uint32 recordSize = 0;
            std::vector<char> bytes;

            uint32 U32(uint32 row, uint32 field) const
            {
                uint32 value;
                std::memcpy(&value, bytes.data() + 20 + row * recordSize + field * 4, 4);
                return value;
            }

            float F32(uint32 row, uint32 field) const
            {
                float value;
                std::memcpy(&value, bytes.data() + 20 + row * recordSize + field * 4, 4);
                return value;
            }
        };

        bool ReadDbc(std::string const& name, uint32 minFields, RawDbc& out)
        {
            std::string path = sConfigMgr->GetOption<std::string>("DataDir", ".") + "/dbc/" + name;
            std::ifstream file(path, std::ios::binary);
            if (!file)
            {
                LOG_ERROR("module", "Mythic+: {} not found", path);
                return false;
            }

            out.bytes.assign(std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>());
            if (out.bytes.size() < 20 || std::memcmp(out.bytes.data(), "WDBC", 4) != 0)
            {
                LOG_ERROR("module", "Mythic+: {} is not a DBC file", path);
                return false;
            }

            std::memcpy(&out.records, out.bytes.data() + 4, 4);
            std::memcpy(&out.fields, out.bytes.data() + 8, 4);
            std::memcpy(&out.recordSize, out.bytes.data() + 12, 4);
            if (out.fields < minFields || out.bytes.size() < 20 + size_t(out.records) * out.recordSize)
            {
                LOG_ERROR("module", "Mythic+: {} has an unexpected layout", path);
                return false;
            }
            return true;
        }

        std::vector<uint32> IdList(std::string text)
        {
            std::replace(text.begin(), text.end(), ',', ' ');
            std::istringstream in(text);
            std::vector<uint32> ids;
            for (uint32 id; in >> id;)
                ids.push_back(id);
            return ids;
        }

        uint64 Key(uint32 lfgId, uint32 level)
        {
            return (uint64(lfgId) << 32) | level;
        }
    }

    Data& Data::Instance()
    {
        static Data data;
        return data;
    }

    void Data::Load()
    {
        _dungeons.clear();
        _keystones.clear();
        _keystoneByDungeonLevel.clear();
        _keystonesByMap.clear();
        _scaling.clear();
        _affixes.clear();

        RawDbc timed;
        if (ReadDbc("TimedDungeons.dbc", 6, timed))
        {
            for (uint32 i = 0; i < timed.records; ++i)
            {
                TimedDungeon d;
                d.lfgId = timed.U32(i, 0);
                d.forcesTotal = timed.U32(i, 1);
                d.encountersRequired = timed.U32(i, 2);
                d.championsTotal = timed.U32(i, 3);
                d.timeLimitMs = timed.U32(i, 4);
                d.rewardMultiplier = timed.F32(i, 5);

                LFGDungeonEntry const* lfg = sLFGDungeonStore.LookupEntry(d.lfgId);
                if (!lfg)
                    continue;
                d.mapId = lfg->MapID;
                d.expansion = lfg->ExpansionLevel;
                _dungeons[d.lfgId] = d;
            }
        }

        RawDbc keys;
        if (ReadDbc("MythicKeystones.dbc", 3, keys))
        {
            for (uint32 i = 0; i < keys.records; ++i)
            {
                Keystone k { keys.U32(i, 0), keys.U32(i, 1), keys.U32(i, 2) };
                auto dungeon = _dungeons.find(k.lfgId);
                if (!k.item || !k.level || dungeon == _dungeons.end())
                    continue;
                _keystones[k.item] = k;
                // Pit of the Fangs and Halls of the Damned have two key series: an older one named after the
                // whole dungeon ("Keystone: Wailing Caverns") and a newer one with the wing in its name. New
                // keys come from the newer series; old ones still work.
                uint32& handedOut = _keystoneByDungeonLevel[Key(k.lfgId, k.level)];
                handedOut = std::max(handedOut, k.item);
                _keystonesByMap[dungeon->second.mapId].push_back(k.item);
            }
        }

        // The table holds every level twice (ids 0-99 and 100-199, same values).
        // Field 1 is the level, 3 magic damage %, 5 physical damage %, 6 health %
        // (C_MythicPlus.GetKeystoneInfo reads them in that order; a +9 key shows
        // +109 % health, +86 % physical, +86 % magic). All are bonuses on top
        // of the base value.
        //
        // Health does not follow the DBC bonus alone. Videos and combat logs of
        // the live server (48 runs, 14 logs, measured against Mythic) show that
        // +1 keeps the Mythic health, and from +2 on the multiplier is
        // Basis x (1 + health %) + Offset (1.1245 and -0.02 fit +2 to +22
        // within about 1 %). Damage keeps the plain DBC bonus.
        float const healthBasis = sConfigMgr->GetOption<float>("MythicPlus.Health.Basis", 1.1245f);
        float const healthOffset = sConfigMgr->GetOption<float>("MythicPlus.Health.Offset", -0.02f);
        RawDbc scaling;
        if (ReadDbc("MythicPlusScaling.dbc", 7, scaling))
        {
            for (uint32 i = 0; i < scaling.records; ++i)
            {
                uint32 level = scaling.U32(i, 1);
                Scaling s;
                s.health = level <= 1 ? 1.0f
                    : healthBasis * (1.0f + scaling.U32(i, 6) / 100.0f) + healthOffset;
                s.physical = 1.0f + scaling.U32(i, 5) / 100.0f;
                s.magic = 1.0f + scaling.U32(i, 3) / 100.0f;
                _scaling.emplace(level, s);
            }
        }

        // One row per week (field 1, 0-52) and level (field 2, 2-254); fields
        // 3-14 hold the affix spells in the order the client lists them.
        _disabledAffixes = IdList(sConfigMgr->GetOption<std::string>("MythicPlus.DisabledAffixes", "80087"));
        _affixSubstitutes = IdList(sConfigMgr->GetOption<std::string>("MythicPlus.AffixSubstitutes", "80046 80044 80026 80024 80032"));
        _swappedAffixRows.clear();
        RawDbc affixes;
        if (ReadDbc("MythicAffixes.dbc", 16, affixes))
        {
            for (uint32 i = 0; i < affixes.records; ++i)
            {
                std::vector<uint32> ids;
                for (uint32 f = 3; f <= 14; ++f)
                    if (uint32 id = affixes.U32(i, f))
                        ids.push_back(id);
                // A disabled affix (MythicPlus.DisabledAffixes) takes the first of
                // MythicPlus.AffixSubstitutes the row does not have yet. The
                // swapped rows go to the client at login (SMSG_PATCH_MYTHIC_AFFIXES).
                for (uint32& id : ids)
                    if (std::find(_disabledAffixes.begin(), _disabledAffixes.end(), id) != _disabledAffixes.end())
                        for (uint32 substitute : _affixSubstitutes)
                            if (std::find(ids.begin(), ids.end(), substitute) == ids.end())
                            {
                                id = substitute;
                                break;
                            }
                std::array<uint32, 16> row;
                for (uint32 f = 0; f < 16; ++f)
                    row[f] = affixes.U32(i, f);
                bool swapped = false;
                for (uint32 f = 3, next = 0; f <= 14; ++f)
                    if (row[f])
                    {
                        swapped |= row[f] != ids[next];
                        row[f] = ids[next++];
                    }
                if (swapped)
                    _swappedAffixRows.push_back(row);
                _lastAffixRowId = std::max(_lastAffixRowId, row[0]);
                _affixRowScale = row[15];
                _affixes[(affixes.U32(i, 1) << 16) | affixes.U32(i, 2)] = std::move(ids);
            }
        }

        // Field 0 encounter id, 1 creature, 2 LFG dungeon, 3 the LFG dungeon
        // again when this boss ends it.
        _wingEncounters.clear();
        RawDbc wings;
        if (ReadDbc("DungeonEncounterExtra.dbc", 4, wings))
            for (uint32 i = 0; i < wings.records; ++i)
                _wingEncounters[wings.U32(i, 2)].push_back({ wings.U32(i, 0), wings.U32(i, 1), wings.U32(i, 3) != 0 });

        LOG_INFO("server.loading", ">> Mythic+: {} timed dungeons, {} keystones, {} scaling levels, {} affix rows, {} wings",
            uint32(_dungeons.size()), uint32(_keystones.size()), uint32(_scaling.size()), uint32(_affixes.size()),
            uint32(_wingEncounters.size()));
    }

    TimedDungeon const* Data::GetDungeon(uint32 lfgId) const
    {
        auto itr = _dungeons.find(lfgId);
        return itr != _dungeons.end() ? &itr->second : nullptr;
    }

    Keystone const* Data::GetKeystone(uint32 item) const
    {
        auto itr = _keystones.find(item);
        return itr != _keystones.end() ? &itr->second : nullptr;
    }

    uint32 Data::GetKeystoneItem(uint32 lfgId, uint32 level) const
    {
        auto itr = _keystoneByDungeonLevel.find(Key(lfgId, level));
        return itr != _keystoneByDungeonLevel.end() ? itr->second : 0;
    }

    Scaling Data::GetScaling(uint32 level) const
    {
        if (_scaling.empty())
            return {};
        auto itr = _scaling.find(level);
        if (itr != _scaling.end())
            return itr->second;
        // Above the table: hold the last level.
        uint32 top = 0;
        for (auto const& [l, s] : _scaling)
            top = std::max(top, l);
        return level > top ? _scaling.at(top) : Scaling {};
    }

    std::vector<uint32> Data::GetAffixes(uint32 rotation, uint32 level) const
    {
        if (level < 2)
            return {};
        auto itr = _affixes.find((rotation << 16) | std::min<uint32>(level, 254));
        return itr != _affixes.end() ? itr->second : std::vector<uint32> {};
    }

    std::array<uint32, 16> Data::PlusOneAffixRow(uint32 rotation) const
    {
        std::array<uint32, 16> row {};
        row[0] = _lastAffixRowId + 1 + rotation;
        row[1] = rotation;
        row[2] = 1;
        row[15] = _affixRowScale;
        return row;
    }

    std::vector<WingEncounter> const* Data::GetWingEncounters(uint32 lfgId) const
    {
        auto itr = _wingEncounters.find(lfgId);
        return itr != _wingEncounters.end() ? &itr->second : nullptr;
    }

    std::vector<uint32> const* Data::GetKeystonesForMap(uint32 mapId) const
    {
        auto itr = _keystonesByMap.find(mapId);
        return itr != _keystonesByMap.end() ? &itr->second : nullptr;
    }

    std::vector<uint32> Data::GetKeyPool(uint32 level, uint32 maxExpansion) const
    {
        std::vector<uint32> pool;
        for (auto const& [lfgId, d] : _dungeons)
        {
            // Rows asking for 20 encounters in 130 minutes are placeholders,
            // not dungeons a key can open (assumption, see protokoll-20260926.md).
            if (d.expansion > maxExpansion || !d.forcesTotal || d.encountersRequired >= 20)
                continue;
            if (GetKeystoneItem(lfgId, level))
                pool.push_back(lfgId);
        }
        std::sort(pool.begin(), pool.end());
        return pool;
    }
}
