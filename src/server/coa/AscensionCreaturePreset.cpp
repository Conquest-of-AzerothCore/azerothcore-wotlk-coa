#include "AscensionCreaturePreset.h"
#include "DatabaseEnv.h"
#include "QueryResult.h"
#include "Log.h"
#include "StringConvert.h"
#include <string_view>

namespace
{
uint32 Mix(uint32 value)
{
    value ^= value >> 16;
    value *= 0x7FEB352Du;
    value ^= value >> 15;
    value *= 0x846CA68Bu;
    value ^= value >> 16;
    return value;
}

uint8 Pick(std::vector<uint8> const& values, uint8 fallback, uint32 seed, uint32 salt)
{
    return values.empty() ? fallback : values[Mix(seed ^ (salt * 0x9E3779B9u)) % values.size()];
}
}

std::vector<uint8> ParsePresetVarietyValues(std::string_view text)
{
    std::vector<uint8> values;
    std::size_t pos = 0;
    while (pos < text.size())
    {
        std::size_t end = text.find_first_of(" ,", pos);
        if (end == std::string_view::npos)
            end = text.size();
        std::string_view token = text.substr(pos, end - pos);
        pos = end + 1;
        if (token.empty())
            continue;

        std::size_t dash = token.find('-');
        Optional<uint32> low = Acore::StringTo<uint32>(token.substr(0, dash));
        Optional<uint32> high = dash == std::string_view::npos ? low : Acore::StringTo<uint32>(token.substr(dash + 1));
        if (!low || !high || *low > *high || *high > 255)
            continue;
        for (uint32 value = *low; value <= *high; ++value)
            values.push_back(uint8(value));
    }
    return values;
}

CreatureDisplayPreset ApplyPresetVariety(CreatureDisplayPreset const& preset,
    CreatureDisplayPresetVariety const& variety, uint32 spawnSeed)
{
    uint32 const seed = Mix(spawnSeed ^ Mix(preset.entry));
    CreatureDisplayPreset varied = preset;
    varied.skin = Pick(variety.skins, preset.skin, seed, 1);
    varied.face = Pick(variety.faces, preset.face, seed, 2);
    varied.hair = Pick(variety.hairs, preset.hair, seed, 3);
    varied.haircolor = Pick(variety.hairColors, preset.haircolor, seed, 4);
    varied.facialhair = Pick(variety.facialHairs, preset.facialhair, seed, 5);
    return varied;
}

AscensionCreaturePresetMgr* AscensionCreaturePresetMgr::Instance()
{
    static AscensionCreaturePresetMgr instance;
    return &instance;
}

void AscensionCreaturePresetMgr::LoadFromDB()
{
    _presets.clear();
    _entryToDisplays.clear();
    LoadVarietiesFromDB();

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

void AscensionCreaturePresetMgr::LoadVarietiesFromDB()
{
    _varieties.clear();

    if (!WorldDatabase.Query("SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND "
        "TABLE_NAME = 'creature_display_preset_variety'"))
        return;

    QueryResult result = WorldDatabase.Query(
        "SELECT entry, gender, skins, faces, hair_styles, hair_colors, facial_hairs FROM creature_display_preset_variety");
    if (!result)
        return;

    do
    {
        Field* fields = result->Fetch();
        CreatureDisplayPresetVariety variety;
        variety.skins = ParsePresetVarietyValues(fields[2].Get<std::string_view>());
        variety.faces = ParsePresetVarietyValues(fields[3].Get<std::string_view>());
        variety.hairs = ParsePresetVarietyValues(fields[4].Get<std::string_view>());
        variety.hairColors = ParsePresetVarietyValues(fields[5].Get<std::string_view>());
        variety.facialHairs = ParsePresetVarietyValues(fields[6].Get<std::string_view>());
        _varieties[MakeKey(fields[0].Get<uint32>(), fields[1].Get<uint8>())] = std::move(variety);
    } while (result->NextRow());

    LOG_INFO("coa", ">> Loaded {} creature display preset varieties.", _varieties.size());
}

CreatureDisplayPreset AscensionCreaturePresetMgr::WithSpawnVariety(CreatureDisplayPreset const& preset,
    uint32 spawnSeed) const
{
    auto itr = _varieties.find(MakeKey(preset.entry, preset.gender));
    return itr == _varieties.end() ? preset : ApplyPresetVariety(preset, itr->second, spawnSeed);
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
