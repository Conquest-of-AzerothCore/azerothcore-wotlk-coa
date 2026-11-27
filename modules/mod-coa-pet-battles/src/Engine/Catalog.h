#ifndef COA_PET_BATTLE_ENGINE_CATALOG_H
#define COA_PET_BATTLE_ENGINE_CATALOG_H

#include "PetBattleData.h"
#include <array>
#include <cstdint>
#include <map>
#include <set>
#include <string>
#include <vector>

namespace CoAPetBattles::Engine
{
    using States = std::map<std::string, double>;

    struct Fx
    {
        uint16_t prop = 0;
        uint32_t aura = 0;
        std::array<double, 6> p {};
    };

    struct Turn
    {
        double turn = 0;
        double event = 0;
        std::vector<Fx> fx;
    };

    struct AbilityDef
    {
        uint32_t id = 0;
        std::string name;
        double family = 0;
        double cooldown = 0;
        std::string text;
        std::vector<Turn> turns;
        std::vector<Turn> main;
    };

    struct KitEntry
    {
        int32_t slot = 0;
        int32_t option = 0;
        double unlock = 0;
        Presentation const* presentation = nullptr;
        AbilityDef const* ability = nullptr;
    };

    struct SpeciesDef
    {
        uint32_t entry = 0;
        std::string name;
        std::string icon;
        std::string family;
        double power = 0;
        double speed = 0;
        double stamina = 0;
        std::vector<KitEntry> kit;
        std::map<uint8_t, BreedStats> retailBreeds;
        std::map<uint8_t, BreedStats> const* defaultBreeds = nullptr;

        std::map<uint8_t, BreedStats> const& Breeds() const;
    };

    class Catalog
    {
    public:
        Catalog(DataSet const& data, Settings const& settings);
        Catalog(Catalog const&) = delete;
        Catalog& operator=(Catalog const&) = delete;

        Settings const& Config() const { return _settings; }
        AbilityDef const* Ability(uint32_t id) const;
        States const* StatesOf(uint32_t id) const;
        std::string const* StateName(double id) const;
        SpeciesDef const* Species(uint32_t entry) const;
        std::array<double, 2> const* Xp(double level) const;
        std::vector<uint32_t> SpeciesIds() const;
        bool KitMissing(uint32_t entry) const { return _withoutKit.count(entry) != 0; }

    private:
        Settings _settings;
        std::map<uint8_t, BreedStats> _defaultBreeds;
        std::map<uint32_t, AbilityDef> _abilities;
        std::map<uint32_t, States> _states;
        std::map<uint32_t, std::string> _stateNames;
        std::map<uint32_t, SpeciesDef> _species;
        std::map<uint32_t, std::array<double, 2>> _xp;
        std::vector<Presentation> _presentations;
        std::set<uint32_t> _withoutKit;
    };
}

#endif
