#ifndef COA_PET_BATTLE_ENGINE_TYPES_H
#define COA_PET_BATTLE_ENGINE_TYPES_H

#include "Catalog.h"
#include "Rng.h"
#include <array>
#include <initializer_list>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace CoAPetBattles::Engine
{
    struct PetAbility
    {
        uint32_t id = 0;
        std::string name;
        std::string retailName;
        std::string icon;
        std::string text;
        std::string tip;
        double family = 0;
        double cooldown = 0;
        std::vector<Turn> turns;
        std::vector<Turn> procs;
        bool priority = false;
        std::optional<double> vis;
        bool ranged = false;
        std::optional<std::string> vmode;
        std::optional<double> vpre;
        bool vhop = false;
        bool vdmg = false;
    };

    struct Pet;

    struct Aura
    {
        uint32_t id = 0;
        double left = 0;
        bool perm = false;
        States states;
        std::optional<double> skip;
        std::optional<double> on;
        std::optional<double> pwr;
        std::optional<std::string> fam;
        Pet* src = nullptr;
        std::optional<double> charges;
        double ticks = 0;
        std::optional<double> hot;
    };

    class AuraTable
    {
    public:
        using List = std::vector<Aura>;

        AuraTable() : _list(std::make_shared<List>()) { }
        AuraTable(std::initializer_list<Aura> auras) : _list(std::make_shared<List>(auras)) { }
        AuraTable(AuraTable const& other) : _list(std::make_shared<List>(*other._list)) { }
        AuraTable& operator=(AuraTable const& other)
        {
            _list = std::make_shared<List>(*other._list);
            return *this;
        }

        std::shared_ptr<List> Share() const { return _list; }
        void Replace() { _list = std::make_shared<List>(); }

        List::iterator begin() { return _list->begin(); }
        List::iterator end() { return _list->end(); }
        List::const_iterator begin() const { return _list->begin(); }
        List::const_iterator end() const { return _list->end(); }
        size_t size() const { return _list->size(); }
        bool empty() const { return _list->empty(); }
        Aura& operator[](size_t index) { return (*_list)[index]; }
        Aura const& operator[](size_t index) const { return (*_list)[index]; }
        Aura& front() { return _list->front(); }
        void push_back(Aura const& aura) { _list->push_back(aura); }
        List::iterator erase(List::iterator first, List::iterator last) { return _list->erase(first, last); }
        List::iterator erase(List::iterator position) { return _list->erase(position); }
        void clear() { _list->clear(); }

    private:
        std::shared_ptr<List> _list;
    };

    struct Channel
    {
        int32_t slot = 0;
        double turn = 0;
    };

    enum class PortalSwap
    {
        None,
        Healthiest,
        Random,
    };

    struct Pet
    {
        uint32_t species = 0;
        std::string name;
        std::string icon;
        std::string family;
        double level = 0;
        double quality = 0;
        std::array<std::optional<PetAbility>, 3> abil;
        std::array<double, 3> cd {};
        double max = 0;
        double baseMax = 0;
        double hp = 0;
        double power = 0;
        double speed = 0;
        AuraTable auras;
        std::optional<Channel> channel;
        double lastTaken = 0;
        std::optional<double> undeadLeft;
        std::optional<std::string> useFam;
        std::map<uint32_t, double> ramp;
        bool corpseUsed = false;
        PortalSwap portalSwap = PortalSwap::None;
        bool captured = false;
        bool noTrap = false;
        bool revived = false;
        std::optional<double> dragonRound;
        uint32_t display = 0;

        PetAbility const* Ability(int32_t slot) const
        {
            return slot >= 1 && slot <= 3 && abil[slot - 1] ? &*abil[slot - 1] : nullptr;
        }
    };
}

#endif
