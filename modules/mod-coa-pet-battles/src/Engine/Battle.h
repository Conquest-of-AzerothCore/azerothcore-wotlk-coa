#ifndef COA_PET_BATTLE_ENGINE_BATTLE_H
#define COA_PET_BATTLE_ENGINE_BATTLE_H

#include "Event.h"
#include "Types.h"
#include <array>
#include <map>
#include <optional>
#include <string>
#include <vector>

namespace CoAPetBattles::Engine
{
    enum class Side
    {
        P = 0,
        E = 1,
    };

    inline Side Other(Side side) { return side == Side::P ? Side::E : Side::P; }
    inline std::string SideName(Side side) { return side == Side::P ? "P" : "E"; }

    struct Weather
    {
        uint32_t id = 0;
        double left = 0;
    };

    struct Wall
    {
        uint32_t id = 0;
        double charges = 0;
        Side owner = Side::P;
    };

    struct Bomb
    {
        uint32_t id = 0;
        double left = 0;
        Pet* src = nullptr;
        std::optional<double> pwr;
    };

    struct Meteor
    {
        double left = 0;
        Side by = Side::P;
    };

    struct Battle
    {
        Battle(Catalog const& catalog, std::vector<Pet> p, std::vector<Pet> e, Rng& rng)
            : catalog(&catalog), pets { std::move(p), std::move(e) }, rng(&rng) { }
        Battle(Battle const&) = delete;
        Battle& operator=(Battle const&) = delete;

        Catalog const* catalog;
        std::array<std::vector<Pet>, 2> pets;
        std::array<int32_t, 2> active { 1, 1 };
        double round = 0;
        Rng* rng;
        std::optional<Weather> weather;
        std::optional<Wall> wall;
        std::array<std::optional<Bomb>, 2> bomb;
        std::optional<Meteor> meteor;
        std::array<bool, 2> acted { false, false };
        std::vector<int32_t> captured;
        bool resolving = false;
        std::map<uint16_t, int32_t> unknown;

        std::vector<Pet>& Team(Side side) { return pets[static_cast<size_t>(side)]; }
        std::vector<Pet> const& Team(Side side) const { return pets[static_cast<size_t>(side)]; }
        int32_t& Active(Side side) { return active[static_cast<size_t>(side)]; }
        int32_t Active(Side side) const { return active[static_cast<size_t>(side)]; }
        Pet& At(Side side, int32_t index) { return Team(side)[static_cast<size_t>(index) - 1]; }
        Pet const& At(Side side, int32_t index) const { return Team(side)[static_cast<size_t>(index) - 1]; }
        Pet& Current(Side side) { return At(side, Active(side)); }
        Pet const& Current(Side side) const { return At(side, Active(side)); }
        States const* WeatherStates() const;
    };

    struct StatusEntry
    {
        uint32_t aid = 0;
        std::string label;
        std::string icon;
        double turns = 0;
        double stacks = 1;
        bool bad = false;
        double power = 0;
        Pet const* src = nullptr;
    };

    bool Has(States const& states, std::string const& key);
    double Get(States const& states, std::string const& key);
    double Mod(Battle const* battle, Pet const& pet, std::string const& state);
    std::string EffFam(Pet const& pet);
    void SyncMax(Pet& pet);
    bool HasState(Battle const* battle, Pet const& pet, double stateId);
    bool Beneficial(States const& states);
    bool CantAct(Battle const* battle, Pet const& pet);
    bool Locked(Battle const* battle, Pet const& pet, std::string const& state);
    double Speed(Battle const* battle, Pet const& pet);
    bool Ready(Pet const& pet, int32_t slot);

    std::string AuraName(Catalog const& catalog, uint32_t id);
    std::optional<double> AuraTrigger(Catalog const& catalog, uint32_t id);
    bool DisplayHostile(Catalog const& catalog, uint32_t id);
    bool AuraGood(Catalog const& catalog, uint32_t id, States const& states, Pet const* holder, Pet const* src);
    std::string AuraNameFor(Catalog const& catalog, uint32_t id, Pet const* src);
    std::vector<Turn> const& MainTurns(AbilityDef const* ability);
    bool AuraHostile(Catalog const& catalog, uint32_t id);
    void ApplyAura(Battle& battle, std::vector<Event>& events, Side side, int32_t index, uint32_t id, double duration,
        bool skipTick, std::optional<double> maxStacks, Pet* source);
    void RemoveAura(Pet& pet, uint32_t id);
    void ConsumeAuras(Pet& pet, double event);

    std::vector<StatusEntry> StatusList(Catalog const& catalog, Pet const& pet);
    std::string StatusTip(Catalog const& catalog, StatusEntry const& entry);
    std::string StatusString(Catalog const& catalog, Pet const& pet);
    std::string TagText(Catalog const& catalog, Pet const& pet);
    std::optional<std::string> LockLabel(Catalog const& catalog, Pet const& pet);
    std::string LockText(Event const& event);
}

#endif
