#include "Catalog.h"
#include "Rules.h"
#include <algorithm>
#include <cmath>

namespace CoAPetBattles::Engine
{
    std::map<uint8_t, BreedStats> const& SpeciesDef::Breeds() const
    {
        return !retailBreeds.empty() || !defaultBreeds ? retailBreeds : *defaultBreeds;
    }

    Catalog::Catalog(DataSet const& data, Settings const& settings)
        : _settings(settings), _defaultBreeds(data.defaultBreeds), _presentations(data.presentations)
    {
        for (auto const& [id, ability] : data.abilities)
            _abilities[id] = { id, ability.name, static_cast<double>(ability.family),
                static_cast<double>(ability.cooldown), ability.description, {}, {} };

        std::map<std::pair<uint32_t, uint8_t>, size_t> turnIndex;
        std::vector<AbilityTurn> turns = data.turns;
        std::sort(turns.begin(), turns.end(), [](AbilityTurn const& a, AbilityTurn const& b)
        {
            return std::tie(a.ability, a.turnIndex) < std::tie(b.ability, b.turnIndex);
        });
        for (AbilityTurn const& row : turns)
        {
            auto ability = _abilities.find(row.ability);
            if (ability == _abilities.end())
                continue;
            turnIndex[{ row.ability, row.turnIndex }] = ability->second.turns.size();
            ability->second.turns.push_back({ static_cast<double>(row.turn), static_cast<double>(row.event), {} });
        }
        std::vector<AbilityEffect> effects = data.effects;
        std::sort(effects.begin(), effects.end(), [](AbilityEffect const& a, AbilityEffect const& b)
        {
            return std::tie(a.ability, a.turnIndex, a.effectIndex) < std::tie(b.ability, b.turnIndex, b.effectIndex);
        });
        for (AbilityEffect const& row : effects)
        {
            auto const index = turnIndex.find({ row.ability, row.turnIndex });
            if (index == turnIndex.end())
                continue;
            Fx fx { row.property, row.aura, {} };
            for (size_t i = 0; i < fx.p.size(); ++i)
                fx.p[i] = static_cast<double>(row.params[i]);
            _abilities[row.ability].turns[index->second].fx.push_back(fx);
        }
        for (auto& [id, ability] : _abilities)
            for (Turn const& turn : ability.turns)
                if (turn.event == 255)
                    ability.main.push_back(turn);

        for (AuraState const& row : data.auraStates)
            _states[row.aura][row.state] = static_cast<double>(row.value);
        for (auto const& [id, state] : data.states)
            _stateNames[id] = state.name;
        for (auto const& [level, row] : data.xp)
            _xp[level] = { static_cast<double>(row.wins), static_cast<double>(row.xpPerWin) };

        for (auto const& [entry, species] : data.species)
        {
            auto const kit = data.kits.find(species.kit);
            if (kit == data.kits.end())
            {
                _withoutKit.insert(entry);
                continue;
            }
            SpeciesDef def { entry, species.name, species.icon,
                FamilyAt(static_cast<double>(kit->second.family) + 1).value_or("Magic"),
                static_cast<double>(kit->second.power), static_cast<double>(kit->second.speed),
                static_cast<double>(kit->second.stamina), {}, {}, &_defaultBreeds };
            if (auto const breeds = data.breeds.find(entry); breeds != data.breeds.end())
                def.retailBreeds = breeds->second;
            _species[entry] = def;
        }
        for (Presentation const& row : _presentations)
        {
            auto species = _species.find(row.species);
            auto const ability = _abilities.find(row.ability);
            if (species == _species.end() || ability == _abilities.end())
                continue;
            species->second.kit.push_back({ row.slot + 1, row.option, static_cast<double>(row.unlockLevel), &row,
                &ability->second });
        }
        for (auto& [entry, species] : _species)
            std::sort(species.kit.begin(), species.kit.end(), [](KitEntry const& a, KitEntry const& b)
            {
                return std::tie(a.slot, a.option) < std::tie(b.slot, b.option);
            });
    }

    AbilityDef const* Catalog::Ability(uint32_t id) const
    {
        auto const found = _abilities.find(id);
        return found == _abilities.end() ? nullptr : &found->second;
    }

    States const* Catalog::StatesOf(uint32_t id) const
    {
        auto const found = _states.find(id);
        return found == _states.end() ? nullptr : &found->second;
    }

    std::string const* Catalog::StateName(double id) const
    {
        if (id < 0 || id != std::floor(id))
            return nullptr;
        auto const found = _stateNames.find(static_cast<uint32_t>(id));
        return found == _stateNames.end() ? nullptr : &found->second;
    }

    SpeciesDef const* Catalog::Species(uint32_t entry) const
    {
        auto const found = _species.find(entry);
        return found == _species.end() ? nullptr : &found->second;
    }

    std::array<double, 2> const* Catalog::Xp(double level) const
    {
        auto const found = _xp.find(static_cast<uint32_t>(level));
        return found == _xp.end() ? nullptr : &found->second;
    }

    std::vector<uint32_t> Catalog::SpeciesIds() const
    {
        std::vector<uint32_t> ids;
        for (auto const& [entry, species] : _species)
            ids.push_back(entry);
        return ids;
    }
}
