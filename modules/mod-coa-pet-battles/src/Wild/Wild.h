#ifndef COA_PET_BATTLE_WILD_WILD_H
#define COA_PET_BATTLE_WILD_WILD_H

#include "Battle/Battles.h"
#include "Battle/PetScale.h"
#include "Engine/Catalog.h"
#include "Engine/Rng.h"
#include "PetBattleData.h"
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

namespace CoAPetBattles::Wild
{
    struct Spot
    {
        uint32_t map = 0;
        double x = 0;
        double y = 0;
        double z = 0;
    };

    struct WildPlayer
    {
        uint64_t character = 0;
        uint32_t map = 0;
        uint32_t zone = 0;
        double x = 0;
        double y = 0;
        double z = 0;
        bool scans = false;
    };

    struct RealCreature
    {
        uint64_t guid = 0;
        uint32_t entry = 0;
        double x = 0;
        double y = 0;
        double z = 0;
        uint32_t level = 0;
    };

    struct SpawnedPet
    {
        uint64_t key = 0;
        uint32_t display = 0;
    };

    class WildWorld
    {
    public:
        virtual ~WildWorld() = default;
        virtual std::vector<WildPlayer> Players() = 0;
        virtual std::vector<RealCreature> RealCreaturesNear(uint64_t character, double range) = 0;
        virtual std::optional<double> Ground(uint32_t map, double x, double y) = 0;
        virtual std::optional<SpawnedPet> Spawn(uint32_t species, Spot at, double facing) = 0;
        virtual void Scale(uint64_t key, double scale) = 0;
        virtual void Settle(uint64_t key, Spot at) = 0;
        virtual void Wander(uint64_t key, double radius) = 0;
        virtual std::optional<Spot> Where(uint64_t key) = 0;
        virtual void Adopt(uint64_t key) = 0;
        virtual void Release(uint64_t key) = 0;
        virtual void Despawn(uint64_t key) = 0;
        virtual void Send(uint64_t character, std::string_view module, std::string_view action,
            std::string const& payload) = 0;
        virtual void Say(uint64_t character, std::string const& text) = 0;
        virtual bool StartBattle(uint64_t character, std::vector<Battle::EnemySpec> enemies) = 0;
        virtual uint32_t UnixNow() const = 0;
    };

    class Registry
    {
    public:
        Registry(std::shared_ptr<Engine::Catalog const> catalog, DataSet const& data, WildSettings settings,
            Battle::PetScale const& scale, WildWorld& world, Engine::Rng& rng);

        void Tick();
        void Blips();
        std::optional<std::string> Hello(uint64_t key) const;
        void Select(uint64_t character, uint64_t key, uint32_t option, double x, double y);
        void EndAll();
        void UseCatalog(std::shared_ptr<Engine::Catalog const> catalog);
        void UseSettings(WildSettings settings);
        bool IsWild(uint64_t key) const { return _pets.count(key) != 0; }
        size_t Count() const { return _pets.size(); }
        std::vector<std::string> Describe(uint64_t character);
        std::optional<uint64_t> Nearest(uint64_t character);

    private:
        struct Pet
        {
            uint32_t species = 0;
            uint32_t level = 0;
            uint32_t zone = 0;
            uint32_t map = 0;
            double x = 0;
            double y = 0;
            double z = 0;
            uint32_t born = 0;
            std::vector<uint32_t> types;
            bool adopted = false;
            uint32_t display = 0;
            std::optional<uint32_t> away;
        };

        struct Cooldown
        {
            uint32_t species = 0;
            uint32_t map = 0;
            double x = 0;
            double y = 0;
            uint32_t until = 0;
        };

        struct Scanned
        {
            uint32_t map = 0;
            double x = 0;
            double y = 0;
            uint32_t at = 0;
            bool spawned = false;
        };

        bool Cooling(uint32_t species, uint32_t map, double x, double y, uint32_t now);
        bool WildNear(uint32_t species, uint32_t map, double x, double y) const;
        Spot SpawnSpot(RealCreature const& mob, uint32_t map);
        void Spawn(WildPlayer const& player, uint32_t species, RealCreature const& mob,
            std::vector<uint32_t> const& types, uint32_t now);
        void Adopt(WildPlayer const& player, uint32_t species, RealCreature const& mob,
            std::vector<uint32_t> const& types, uint32_t now);
        void Remove(uint64_t key, bool startCooldown, bool consume);
        void Scan(WildPlayer const& player, uint32_t now);
        std::vector<uint32_t> ZonePool(uint32_t zone) const;
        std::vector<Battle::EnemySpec> BuildEnemies(Pet const& pet);
        std::string const& NameOf(uint32_t species) const;
        bool IsWildSpecies(uint32_t species) const;
        bool IsAdoptSpecies(uint32_t species) const;
        uint8_t PetLevelOf(Pet const& pet) const;

        std::shared_ptr<Engine::Catalog const> _catalog;
        DataSet const& _data;
        WildSettings _settings;
        Battle::PetScale const& _scale;
        WildWorld& _world;
        Engine::Rng& _rng;
        std::map<uint64_t, Pet> _pets;
        std::vector<Cooldown> _cooldowns;
        std::map<uint64_t, Scanned> _scanned;
        std::set<uint64_t> _hadBlips;
    };
}

#endif
