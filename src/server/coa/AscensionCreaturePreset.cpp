#include "AscensionCreaturePreset.h"
#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "Log.h"

AscensionCreaturePresetMgr* AscensionCreaturePresetMgr::Instance()
{
    static AscensionCreaturePresetMgr instance;
    return &instance;
}

void AscensionCreaturePresetMgr::LoadFromDB()
{
    _presets.clear();
    _entryToDisplays.clear();

    QueryResult result = WorldDatabase.Query(
        "SELECT entry, display_id, race, gender, class, skin, face, hair, haircolor, facialhair, guild_id, "
        "item_head, item_shoulders, item_body, item_chest, item_waist, item_legs, item_feet, item_wrists, "
        "item_hands, item_back, item_tabard FROM creature_display_preset");

    if (!result)
    {
        LOG_WARN("coa", ">> Table creature_display_preset is empty or missing.");
        return;
    }

    do
    {
        Field* fields = result->Fetch();
        CreatureDisplayPreset preset;
        preset.entry = fields[0].Get<uint32>();
        preset.display_id = fields[1].Get<uint32>();
        preset.race = fields[2].Get<uint8>();
        preset.gender = fields[3].Get<uint8>();
        preset.class_id = fields[4].Get<uint8>();
        preset.skin = fields[5].Get<uint8>();
        preset.face = fields[6].Get<uint8>();
        preset.hair = fields[7].Get<uint8>();
        preset.haircolor = fields[8].Get<uint8>();
        preset.facialhair = fields[9].Get<uint8>();
        preset.guild_id = fields[10].Get<uint32>();

        for (std::size_t i = 0; i < 11; ++i)
        {
            preset.items[i] = fields[11 + i].Get<uint32>();
        }

        uint64 key = MakeKey(preset.entry, preset.display_id);
        _presets[key] = preset;
        _entryToDisplays[preset.entry].push_back(preset.display_id);
    } while (result->NextRow());

    LOG_INFO("coa", ">> Loaded {} creature display presets into cache across {} unique creature entries.",
        _presets.size(), _entryToDisplays.size());
}

CreatureDisplayPreset const* AscensionCreaturePresetMgr::GetPreset(uint32 entry, uint32 displayId) const
{
    if (displayId != 0)
    {
        auto itr = _presets.find(MakeKey(entry, displayId));
        if (itr != _presets.end())
            return &itr->second;
    }

    auto listItr = _entryToDisplays.find(entry);
    if (listItr != _entryToDisplays.end() && !listItr->second.empty())
    {
        auto itr = _presets.find(MakeKey(entry, listItr->second.front()));
        if (itr != _presets.end())
            return &itr->second;
    }

    return nullptr;
}

CreatureDisplayPreset const* AscensionCreaturePresetMgr::GetPresetByGender(uint32 entry, uint8 gender) const
{
    auto listItr = _entryToDisplays.find(entry);
    if (listItr != _entryToDisplays.end())
    {
        for (uint32 disp : listItr->second)
        {
            auto itr = _presets.find(MakeKey(entry, disp));
            if (itr != _presets.end() && itr->second.gender == gender)
                return &itr->second;
        }

        if (!listItr->second.empty())
        {
            auto itr = _presets.find(MakeKey(entry, listItr->second.front()));
            if (itr != _presets.end())
                return &itr->second;
        }
    }
    return nullptr;
}

bool AscensionCreaturePresetMgr::HasPreset(uint32 entry, uint32 displayId) const
{
    if (displayId != 0)
        return _presets.find(MakeKey(entry, displayId)) != _presets.end();
    return _entryToDisplays.find(entry) != _entryToDisplays.end();
}

void AscensionCreaturePresetMgr::SetActivePresetOverride(ObjectGuid guid, uint32 entry, uint32 displayId)
{
    CreatureDisplayPreset const* preset = displayId ? GetPreset(entry, displayId) : GetPreset(entry);
    if (preset)
        _activePresetOverrides[guid] = MakeKey(preset->entry, preset->display_id);
}

void AscensionCreaturePresetMgr::ClearActivePresetOverride(ObjectGuid guid)
{
    _activePresetOverrides.erase(guid);
}

CreatureDisplayPreset const* AscensionCreaturePresetMgr::GetActivePresetOverride(ObjectGuid guid) const
{
    auto itr = _activePresetOverrides.find(guid);
    if (itr != _activePresetOverrides.end())
    {
        auto presetItr = _presets.find(itr->second);
        if (presetItr != _presets.end())
            return &presetItr->second;
    }
    return nullptr;
}
