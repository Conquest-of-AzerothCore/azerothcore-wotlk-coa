#include "PetBattleData.h"
#include "Engine/Rules.h"
#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstdlib>
#include <set>
#include <sstream>
#include <tuple>

namespace CoAPetBattles
{
    namespace
    {
        using AbilitySlot = std::tuple<uint8_t, uint8_t, uint32_t>;

        std::string Text(std::initializer_list<std::string> parts)
        {
            std::string text;
            for (std::string const& part : parts)
                text += part;
            return text;
        }

        std::string Id(uint64_t value)
        {
            return std::to_string(value);
        }

        void CheckKitsAndAbilities(DataSet const& data, Report& report)
        {
            for (auto const& [entry, species] : data.species)
                if (!data.kits.count(species.kit))
                    report.errors.push_back(Text({ "species ", Id(entry), ": kit ", Id(species.kit), " missing" }));

            for (auto const& [id, kit] : data.kits)
                if (!Engine::FamilyAt(static_cast<double>(kit.family) + 1))
                    report.errors.push_back(Text({ "kit ", Id(id), ": family ", Id(kit.family), " unknown" }));

            for (KitAbility const& row : data.kitAbilities)
            {
                if (!data.kits.count(row.kit))
                    report.errors.push_back(Text({ "kit ability ", Id(row.kit), "/", Id(row.slot), ": kit missing" }));
                if (!data.abilities.count(row.ability))
                    report.errors.push_back(Text({ "kit ", Id(row.kit), ": ability ", Id(row.ability), " missing" }));
            }

            for (auto const& [id, ability] : data.abilities)
                if (ability.base && !data.abilities.count(ability.base))
                    report.errors.push_back(Text({ "ability ", Id(id), ": base ", Id(ability.base), " missing" }));
        }

        void CheckTurnsAndEffects(DataSet const& data, Report& report)
        {
            std::set<std::pair<uint32_t, uint8_t>> turns;
            for (AbilityTurn const& turn : data.turns)
            {
                turns.emplace(turn.ability, turn.turnIndex);
                if (!data.abilities.count(turn.ability))
                    report.errors.push_back(Text({ "turn ", Id(turn.ability), "/", Id(turn.turnIndex), ": ability ",
                        Id(turn.ability), " missing" }));
            }

            for (AbilityEffect const& effect : data.effects)
            {
                std::string const name = Text({ "effect ", Id(effect.ability), "/", Id(effect.turnIndex), "/",
                    Id(effect.effectIndex) });
                if (!turns.count({ effect.ability, effect.turnIndex }))
                    report.errors.push_back(name + ": turn missing");
                if (effect.aura && !data.abilities.count(effect.aura))
                    report.warnings.push_back(Text({ name, ": aura ", Id(effect.aura), " is not an ability" }));
            }

            std::set<uint32_t> usable;
            for (KitAbility const& row : data.kitAbilities)
                usable.insert(row.ability);
            for (Presentation const& row : data.presentations)
                usable.insert(row.ability);
            std::set<uint32_t> withTurns;
            for (AbilityTurn const& turn : data.turns)
                withTurns.insert(turn.ability);
            for (uint32_t ability : usable)
                if (data.abilities.count(ability) && !withTurns.count(ability))
                    report.errors.push_back(Text({ "ability ", Id(ability), " has no turns" }));
        }

        void CheckPresentations(DataSet const& data, Report& report)
        {
            std::map<uint32_t, std::set<AbilitySlot>> kitSlots;
            for (KitAbility const& row : data.kitAbilities)
                kitSlots[row.kit].emplace(row.slot, row.unlockLevel, row.ability);

            std::map<uint32_t, std::set<AbilitySlot>> speciesSlots;
            for (Presentation const& row : data.presentations)
            {
                std::string const name = Text({ "presentation ", Id(row.species), "/", Id(row.slot), "/",
                    Id(row.option) });
                if (!data.species.count(row.species))
                    report.errors.push_back(Text({ name, ": species ", Id(row.species), " missing" }));
                if (!data.abilities.count(row.ability))
                    report.errors.push_back(Text({ name, ": ability ", Id(row.ability), " missing" }));
                speciesSlots[row.species].emplace(row.slot, row.unlockLevel, row.ability);
            }

            for (auto const& [entry, species] : data.species)
            {
                if (!data.kits.count(species.kit))
                    continue;
                if (speciesSlots[entry] != kitSlots[species.kit])
                    report.errors.push_back(Text({ "species ", Id(entry), ": presentation does not match kit ",
                        Id(species.kit) }));
            }
        }

        void CheckWorldReferences(DataSet const& data, Report& report,
            std::function<bool(uint32_t)> const& creatureTemplateExists)
        {
            for (ZoneSpecies const& row : data.zoneSpecies)
            {
                if (!data.zones.count(row.zone))
                    report.errors.push_back(Text({ "zone species ", Id(row.zone), "/", Id(row.species), ": zone ",
                        Id(row.zone), " missing" }));
                if (!data.species.count(row.species))
                    report.errors.push_back(Text({ "zone species ", Id(row.zone), "/", Id(row.species), ": species ",
                        Id(row.species), " missing" }));
            }

            for (auto const& [spell, companion] : data.companions)
                if (!data.species.count(companion.species))
                    report.errors.push_back(Text({ "companion ", Id(spell), ": species ", Id(companion.species),
                        " missing" }));

            std::map<uint32_t, uint32_t> standInOwners;
            for (auto const& [entry, standIn] : data.standIns)
            {
                if (!data.species.count(entry))
                    report.errors.push_back(Text({ "stand-in ", Id(entry), ": species missing" }));
                auto const [owner, added] = standInOwners.emplace(standIn, entry);
                if (!added)
                    report.errors.push_back(Text({ "stand-in entry ", Id(standIn), " used by species ",
                        Id(owner->second), " and ", Id(entry) }));
            }

            for (auto const& [entry, species] : data.species)
            {
                if (!species.standin)
                    continue;
                auto const explicitStandIn = data.standIns.find(entry);
                bool const isExplicit = explicitStandIn != data.standIns.end();
                uint64_t const standIn = isExplicit ? explicitStandIn->second : uint64_t(StandInBase) + entry;
                bool const outside = isExplicit
                    ? standIn < ExplicitStandInBase || standIn > ExplicitStandInLimit : standIn > StandInLimit;
                if (outside)
                    report.errors.push_back(Text({ "species ", Id(entry), ": stand-in entry ", Id(standIn),
                        " outside reserved range" }));
                else if (!creatureTemplateExists(uint32_t(standIn)))
                    report.errors.push_back(Text({ "species ", Id(entry), ": stand-in template ", Id(standIn),
                        " missing" }));
            }
        }
    }

    uint32_t StandInEntry(DataSet const& data, uint32_t species)
    {
        auto const found = data.species.find(species);
        if (found == data.species.end() || !found->second.standin)
            return 0;
        auto const explicitStandIn = data.standIns.find(species);
        if (explicitStandIn != data.standIns.end())
            return explicitStandIn->second < ExplicitStandInBase || explicitStandIn->second > ExplicitStandInLimit ? 0
                : explicitStandIn->second;
        uint64_t const entry = uint64_t(StandInBase) + species;
        return entry > StandInLimit ? 0 : uint32_t(entry);
    }

    uint8_t PetLevel(DataSet const& data, uint8_t maxLevel, uint32_t mobLevel, uint32_t zone)
    {
        auto const found = data.zones.find(zone);
        if (found == data.zones.end())
        {
            double const proportional = std::floor(double(mobLevel) * maxLevel / 80.0 + 0.5);
            return uint8_t(std::max(1.0, std::min(double(maxLevel), proportional)));
        }
        Zone const& z = found->second;
        double const span = double(z.mobLevelMax) - z.mobLevelMin + 1;
        double const steps = double(z.petLevelMax) - z.petLevelMin + 1;
        double const level = z.petLevelMin + std::floor((double(mobLevel) - z.mobLevelMin) * steps / span);
        return uint8_t(std::max<double>(z.petLevelMin, std::min<double>(z.petLevelMax, level)));
    }

    Report Validate(DataSet const& data, std::function<bool(uint32_t)> const& creatureTemplateExists)
    {
        Report report;
        CheckKitsAndAbilities(data, report);
        CheckTurnsAndEffects(data, report);
        CheckPresentations(data, report);
        CheckWorldReferences(data, report, creatureTemplateExists);
        for (auto const& [entry, breeds] : data.breeds)
        {
            auto const species = data.species.find(entry);
            if (species == data.species.end() || !species->second.wild)
                report.errors.push_back("breed table references non-wild species " + std::to_string(entry));
            for (auto const& [breed, stats] : breeds)
                if (breed < 3 || breed > 12 || stats.stamina <= 0 || stats.power <= 0 || stats.speed <= 0)
                    report.errors.push_back("invalid breed " + std::to_string(breed) + " for species " +
                        std::to_string(entry));
        }
        if (!data.defaultBreeds.empty())
        {
            auto const balanced = data.defaultBreeds.find(BalancedBreed);
            if (balanced == data.defaultBreeds.end() || balanced->second.stamina || balanced->second.power ||
                balanced->second.speed)
                report.errors.push_back("default balanced breed must preserve base stats");
            for (auto const& [breed, stats] : data.defaultBreeds)
                if (breed < 3 || breed > 12)
                    report.errors.push_back("invalid default breed " + std::to_string(breed));
        }
        return report;
    }

    std::optional<std::array<uint32_t, 4>> ParseQualityWeights(std::string const& text)
    {
        std::istringstream stream(text);
        std::array<uint32_t, 4> weights {};
        std::string token;
        size_t count = 0;
        uint64_t sum = 0;
        while (stream >> token)
        {
            if (count == weights.size())
                return std::nullopt;
            uint32_t value = 0;
            auto const [end, error] = std::from_chars(token.data(), token.data() + token.size(), value);
            if (error != std::errc() || end != token.data() + token.size())
                return std::nullopt;
            weights[count++] = value;
            sum += value;
        }
        if (count != weights.size() || sum == 0)
            return std::nullopt;
        return weights;
    }

    std::optional<double> ParseDecimal(std::string const& text)
    {
        if (text.empty())
            return std::nullopt;
        char* end = nullptr;
        double const value = std::strtod(text.c_str(), &end);
        if (end != text.c_str() + text.size() || !std::isfinite(value))
            return std::nullopt;
        return value;
    }

    std::string DecimalText(double value)
    {
        std::array<char, 32> buffer {};
        auto const [end, error] = std::to_chars(buffer.data(), buffer.data() + buffer.size(), value);
        return error == std::errc() ? std::string(buffer.data(), end) : std::to_string(value);
    }
}
