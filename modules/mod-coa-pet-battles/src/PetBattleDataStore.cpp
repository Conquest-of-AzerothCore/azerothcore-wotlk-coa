#include "PetBattleDataStore.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "QueryResult.h"
#include <string>

namespace CoAPetBattles
{
    namespace
    {
        constexpr size_t MaxLoggedErrors = 20;

        template<typename Reader>
        void ReadRows(char const* query, Reader reader)
        {
            if (QueryResult result = WorldDatabase.Query(query))
            {
                do
                    reader(result->Fetch());
                while (result->NextRow());
            }
        }

        DataSet ReadDataSet()
        {
            DataSet data;
            ReadRows("SELECT `entry`, `name`, `kit`, `wild`, `companion`, `critter`, `synthetic`, `standin`, `icon`, "
                "`scale` FROM `coa_pet_species`", [&data](Field* f)
            {
                Species row { f[0].Get<uint32>(), f[1].Get<std::string>(), f[2].Get<uint32>(), f[3].Get<uint8>() != 0,
                    f[4].Get<uint8>() != 0, f[5].Get<uint8>() != 0, f[6].Get<uint8>() != 0, f[7].Get<uint8>() != 0,
                    f[8].Get<std::string>(), f[9].Get<float>() };
                data.species[row.entry] = row;
            });
            ReadRows("SELECT `species`, `entry` FROM `coa_pet_standin`", [&data](Field* f)
            {
                data.standIns[f[0].Get<uint32>()] = f[1].Get<uint32>();
            });
            ReadRows("SELECT `id`, `name`, `family`, `power`, `speed`, `stamina` FROM `coa_pet_kit`", [&data](Field* f)
            {
                Kit row { f[0].Get<uint32>(), f[1].Get<std::string>(), f[2].Get<uint8>(), f[3].Get<int16>(),
                    f[4].Get<int16>(), f[5].Get<int16>() };
                data.kits[row.id] = row;
            });
            ReadRows("SELECT `kit`, `slot`, `unlock_level`, `ability` FROM `coa_pet_kit_ability`", [&data](Field* f)
            {
                data.kitAbilities.push_back({ f[0].Get<uint32>(), f[1].Get<uint8>(), f[2].Get<uint8>(),
                    f[3].Get<uint32>() });
            });
            ReadRows("SELECT `id`, `name`, `family`, `cooldown`, `description`, `base` FROM `coa_pet_ability`",
                [&data](Field* f)
            {
                Ability row { f[0].Get<uint32>(), f[1].Get<std::string>(), f[2].Get<int8>(), f[3].Get<uint8>(),
                    f[4].Get<std::string>(), f[5].Get<uint32>() };
                data.abilities[row.id] = row;
            });
            ReadRows("SELECT `ability`, `turn_index`, `turn`, `event` FROM `coa_pet_ability_turn`", [&data](Field* f)
            {
                data.turns.push_back({ f[0].Get<uint32>(), f[1].Get<uint8>(), f[2].Get<uint8>(), f[3].Get<uint8>() });
            });
            ReadRows("SELECT `ability`, `turn_index`, `effect_index`, `property`, `aura`, `param0`, `param1`, `param2`, "
                "`param3`, `param4`, `param5` FROM `coa_pet_ability_effect`", [&data](Field* f)
            {
                AbilityEffect row { f[0].Get<uint32>(), f[1].Get<uint8>(), f[2].Get<uint8>(), f[3].Get<uint16>(),
                    f[4].Get<uint32>(), {} };
                for (size_t i = 0; i < row.params.size(); ++i)
                    row.params[i] = f[5 + i].Get<int32>();
                data.effects.push_back(row);
            });
            ReadRows("SELECT `property`, `param_index`, `label` FROM `coa_pet_effect_property`", [&data](Field* f)
            {
                data.labels.push_back({ f[0].Get<uint16>(), f[1].Get<uint8>(), f[2].Get<std::string>() });
            });
            ReadRows("SELECT `id`, `name` FROM `coa_pet_state`", [&data](Field* f)
            {
                State row { f[0].Get<uint16>(), f[1].Get<std::string>() };
                data.states[row.id] = row;
            });
            ReadRows("SELECT `aura`, `state`, `value` FROM `coa_pet_aura_state`", [&data](Field* f)
            {
                data.auraStates.push_back({ f[0].Get<uint32>(), f[1].Get<std::string>(), f[2].Get<int32>() });
            });
            ReadRows("SELECT `level`, `wins`, `xp_per_win` FROM `coa_pet_xp`", [&data](Field* f)
            {
                XpLevel row { f[0].Get<uint8>(), f[1].Get<uint16>(), f[2].Get<uint16>() };
                data.xp[row.level] = row;
            });
            ReadRows("SELECT `zone`, `name`, `pet_level_min`, `pet_level_max`, `mob_level_min`, `mob_level_max` "
                "FROM `coa_pet_zone`", [&data](Field* f)
            {
                Zone row { f[0].Get<uint32>(), f[1].Get<std::string>(), f[2].Get<uint8>(), f[3].Get<uint8>(),
                    f[4].Get<uint8>(), f[5].Get<uint8>() };
                data.zones[row.zone] = row;
            });
            ReadRows("SELECT `zone`, `species` FROM `coa_pet_zone_species`", [&data](Field* f)
            {
                data.zoneSpecies.push_back({ f[0].Get<uint32>(), f[1].Get<uint32>() });
            });
            ReadRows("SELECT `species`, `slot`, `option`, `unlock_level`, `ability`, `name`, `retail_name`, `icon`, "
                "`tooltip`, `visual_spell`, `ranged`, `visual_mode`, `pre_spell`, `hop`, `spell_deals_damage`, "
                "`goes_first` FROM `coa_pet_presentation`", [&data](Field* f)
            {
                data.presentations.push_back({ f[0].Get<uint32>(), f[1].Get<uint8>(), f[2].Get<uint8>(),
                    f[3].Get<uint8>(), f[4].Get<uint32>(), f[5].Get<std::string>(), f[6].Get<std::string>(),
                    f[7].Get<std::string>(), f[8].Get<std::string>(), f[9].Get<uint32>(), f[10].Get<uint8>() != 0,
                    f[11].Get<std::string>(), f[12].Get<uint32>(), f[13].Get<uint8>() != 0, f[14].Get<uint8>() != 0,
                    f[15].Get<uint8>() != 0 });
            });
            ReadRows("SELECT `species`, `width`, `height`, `silhouette` FROM `coa_pet_model_size`", [&data](Field* f)
            {
                ModelSize row { f[0].Get<uint32>(), f[1].Get<float>(), f[2].Get<float>(), f[3].Get<float>() };
                data.modelSizes[row.species] = row;
            });
            ReadRows("SELECT `display`, `silhouette` FROM `coa_pet_display_size`", [&data](Field* f)
            {
                DisplaySize row { f[0].Get<uint32>(), f[1].Get<float>() };
                data.displaySizes[row.display] = row;
            });
            ReadRows("SELECT `spell`, `species` FROM `coa_pet_companion`", [&data](Field* f)
            {
                Companion row { f[0].Get<uint32>(), f[1].Get<uint32>() };
                data.companions[row.spell] = row;
            });
            ReadRows("SELECT `species`, `breed`, `stamina`, `power`, `speed` FROM `coa_pet_breed`", [&data](Field* f)
            {
                data.breeds[f[0].Get<uint32>()][f[1].Get<uint8>()] = {
                    f[2].Get<int16>(), f[3].Get<int16>(), f[4].Get<int16>() };
            });
            ReadRows("SELECT `breed`, `stamina`, `power`, `speed` FROM `coa_pet_breed_default`", [&data](Field* f)
            {
                data.defaultBreeds[f[0].Get<uint8>()] = { f[1].Get<int16>(), f[2].Get<int16>(), f[3].Get<int16>() };
            });
            return data;
        }

        void LogReport(Report const& report)
        {
            for (std::string const& warning : report.warnings)
                LOG_WARN("server.loading", "Pet battle data: {}", warning);
            for (size_t i = 0; i < report.errors.size() && i < MaxLoggedErrors; ++i)
                LOG_ERROR("server.loading", "Pet battle data: {}", report.errors[i]);
            if (!report.errors.empty())
                LOG_ERROR("server.loading", "Pet battle data has {} errors and {} warnings; pet battles stay disabled",
                    report.errors.size(), report.warnings.size());
        }
    }

    namespace
    {
        double ReadDecimal(std::string const& key, double fallback)
        {
            std::string const text = sConfigMgr->GetOption<std::string>(key, DecimalText(fallback));
            if (std::optional<double> value = ParseDecimal(text))
                return *value;
            LOG_ERROR("server.loading", "{} '{}' is not a decimal number; using {}", key, text, fallback);
            return fallback;
        }

        uint32_t Whole(std::string const& name, uint32_t fallback)
        {
            return sConfigMgr->GetOption<uint32>("CoAPetBattles.Wild." + name, fallback);
        }

        float Distance(std::string const& name, float fallback)
        {
            return float(ReadDecimal("CoAPetBattles.Wild." + name, fallback));
        }

        WildSettings ReadWild()
        {
            WildSettings wild;
            wild.enabled = sConfigMgr->GetOption<bool>("CoAPetBattles.Wild.Enable", wild.enabled);
            wild.tickMs = Whole("TickMs", wild.tickMs);
            wild.blipMs = Whole("BlipMs", wild.blipMs);
            wild.search = Distance("Search", wild.search);
            wild.spacing = Distance("Spacing", wild.spacing);
            wild.maxArea = Whole("MaxArea", wild.maxArea);
            wild.cooldownSeconds = Whole("CooldownSeconds", wild.cooldownSeconds);
            wild.lifetimeSeconds = Whole("LifetimeSeconds", wild.lifetimeSeconds);
            wild.leave = Distance("Leave", wild.leave);
            wild.awayGraceSeconds = Whole("AwayGraceSeconds", wild.awayGraceSeconds);
            wild.moveRescan = Distance("MoveRescan", wild.moveRescan);
            wild.rescanIdleSeconds = Whole("RescanIdleSeconds", wild.rescanIdleSeconds);
            wild.talkRange = Distance("TalkRange", wild.talkRange);
            wild.soloMaxLevel = uint8_t(Whole("SoloMaxLevel", wild.soloMaxLevel));
            wild.spotMin = Distance("SpotMin", wild.spotMin);
            wild.spotMax = Distance("SpotMax", wild.spotMax);
            wild.maxHeightDifference = Distance("MaxHeightDifference", wild.maxHeightDifference);
            wild.tries = Whole("Tries", wild.tries);
            wild.fallbackDistance = Distance("FallbackDistance", wild.fallbackDistance);
            wild.wander = Distance("Wander", wild.wander);
            return wild;
        }
    }

    PetBattleDataStore* PetBattleDataStore::instance()
    {
        static PetBattleDataStore store;
        return &store;
    }

    void PetBattleDataStore::LoadSettings()
    {
        _enabled = sConfigMgr->GetOption<bool>("CoAPetBattles.Enable", true);
        Settings settings;
        settings.maxLevel = sConfigMgr->GetOption<uint8>("CoAPetBattles.MaxLevel", settings.maxLevel);
        std::string const weights = sConfigMgr->GetOption<std::string>("CoAPetBattles.QualityWeights", "55 28 13 4");
        if (std::optional<std::array<uint32_t, 4>> parsed = ParseQualityWeights(weights))
            settings.qualityWeights = *parsed;
        else
            LOG_ERROR("server.loading", "CoAPetBattles.QualityWeights '{}' is not four whole numbers; using defaults",
                weights);
        settings.captureHealth = ReadDecimal("CoAPetBattles.CaptureHealth", settings.captureHealth);
        settings.regenPercent = sConfigMgr->GetOption<uint32>("CoAPetBattles.RegenPercent", settings.regenPercent);
        settings.regenSeconds = sConfigMgr->GetOption<uint32>("CoAPetBattles.RegenSeconds", settings.regenSeconds);
        settings.fedPercent = sConfigMgr->GetOption<uint32>("CoAPetBattles.FedPercent", settings.fedPercent);
        settings.fedStepSeconds = sConfigMgr->GetOption<uint32>("CoAPetBattles.FedStepSeconds",
            settings.fedStepSeconds);
        settings.fedSeconds = sConfigMgr->GetOption<uint32>("CoAPetBattles.FedSeconds", settings.fedSeconds);
        settings.xpStep = ReadDecimal("CoAPetBattles.XpStep", settings.xpStep);
        _settings = settings;
        _wild = ReadWild();
        if (_loaded)
            _catalog = std::make_shared<Engine::Catalog const>(_data, _settings);
    }

    void PetBattleDataStore::Load()
    {
        _loaded = false;
        _catalog.reset();
        _data = DataSet();
        if (!_enabled)
            return;
        if (!WorldDatabase.Query("SHOW TABLES LIKE 'coa_pet_species'"))
        {
            LOG_ERROR("server.loading", "Pet battle tables missing; pet battles stay disabled");
            return;
        }

        DataSet data = ReadDataSet();
        Report const report = Validate(data,
            [](uint32_t entry) { return sObjectMgr->GetCreatureTemplate(entry) != nullptr; });
        LogReport(report);
        if (!report.errors.empty())
            return;

        LOG_INFO("server.loading", "Loaded pet battles: {} species, {} kits, {} kit abilities, {} abilities, {} turns, "
            "{} effects, {} effect labels, {} states, {} aura states, {} xp levels, {} zones, {} zone species, "
            "{} presentations, {} model sizes, {} display sizes, {} companions, {} breed-enabled species",
            data.species.size(), data.kits.size(), data.kitAbilities.size(), data.abilities.size(), data.turns.size(), data.effects.size(),
            data.labels.size(), data.states.size(), data.auraStates.size(), data.xp.size(), data.zones.size(),
            data.zoneSpecies.size(), data.presentations.size(), data.modelSizes.size(), data.displaySizes.size(),
            data.companions.size(), data.breeds.size());
        _data = std::move(data);
        _catalog = std::make_shared<Engine::Catalog const>(_data, _settings);
        _loaded = true;
    }

    Species const* PetBattleDataStore::FindSpecies(uint32_t entry) const
    {
        auto const found = _data.species.find(entry);
        return found == _data.species.end() ? nullptr : &found->second;
    }

    Ability const* PetBattleDataStore::FindAbility(uint32_t id) const
    {
        auto const found = _data.abilities.find(id);
        return found == _data.abilities.end() ? nullptr : &found->second;
    }

    Zone const* PetBattleDataStore::FindZone(uint32_t zone) const
    {
        auto const found = _data.zones.find(zone);
        return found == _data.zones.end() ? nullptr : &found->second;
    }

    std::vector<Presentation const*> PetBattleDataStore::PresentationsOf(uint32_t species) const
    {
        std::vector<Presentation const*> rows;
        for (Presentation const& row : _data.presentations)
            if (row.species == species)
                rows.push_back(&row);
        return rows;
    }

    uint32_t PetBattleDataStore::StandInEntry(uint32_t species) const
    {
        return CoAPetBattles::StandInEntry(_data, species);
    }
}
