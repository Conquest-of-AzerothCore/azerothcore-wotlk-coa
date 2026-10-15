#ifndef AZEROTHCORE_ASCENSION_CREATURE_PRESET_H
#define AZEROTHCORE_ASCENSION_CREATURE_PRESET_H

#include "Common.h"
#include "ObjectGuid.h"
#include <array>
#include <unordered_map>
#include <vector>

struct CreatureDisplayPreset
{
    uint32 entry = 0;
    uint32 display_id = 0;
    uint8 race = 0;
    uint8 gender = 0;
    uint8 class_id = 0;
    uint8 skin = 0;
    uint8 face = 0;
    uint8 hair = 0;
    uint8 haircolor = 0;
    uint8 facialhair = 0;
    uint32 guild_id = 0;
    std::array<uint32, 11> items = {0};
};

class AscensionCreaturePresetMgr
{
public:
    static AscensionCreaturePresetMgr* Instance();

    void LoadFromDB();

    [[nodiscard]] CreatureDisplayPreset const* GetPreset(uint32 entry, uint32 displayId = 0) const;
    [[nodiscard]] CreatureDisplayPreset const* GetPresetByGender(uint32 entry, uint8 gender) const;
    [[nodiscard]] bool HasPreset(uint32 entry, uint32 displayId = 0) const;
    [[nodiscard]] std::size_t GetPresetCount() const { return _presets.size(); }

    void SetActivePresetOverride(ObjectGuid guid, uint32 entry, uint32 displayId = 0);
    void ClearActivePresetOverride(ObjectGuid guid);
    [[nodiscard]] CreatureDisplayPreset const* GetActivePresetOverride(ObjectGuid guid) const;

private:
    static uint64 MakeKey(uint32 entry, uint32 displayId)
    {
        return (uint64(entry) << 32) | uint64(displayId);
    }

    std::unordered_map<uint64, CreatureDisplayPreset> _presets;
    std::unordered_map<uint32, std::vector<uint32>> _entryToDisplays;
    std::unordered_map<ObjectGuid, uint64> _activePresetOverrides;
};

#define sAscensionPresets AscensionCreaturePresetMgr::Instance()

#endif
