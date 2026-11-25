#ifndef COA_PET_BATTLE_BATTLE_BATTLES_H
#define COA_PET_BATTLE_BATTLE_BATTLES_H

#include "Engine/Battle.h"
#include "Engine/Catalog.h"
#include "PetScale.h"
#include "Scheduler.h"
#include "Store/Journal.h"
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace CoAPetBattles::Battle
{
    using Side = Engine::Side;

    struct Spawned
    {
        uint64_t handle = 0;
        uint32_t display = 0;
    };

    enum class CueKind { Cast, Effect, Aura, Unaura, Emote, Face, Lunge, Back, Jump, Health, Crate, Uncrate };

    struct Cue
    {
        CueKind kind = CueKind::Effect;
        Side side = Side::P;
        Side target = Side::P;
        uint32_t value = 0;
        bool ranged = false;
        bool heal = false;
    };

    class World
    {
    public:
        virtual ~World() = default;
        virtual void Send(uint64_t character, std::string_view module, std::string_view action,
            std::string const& payload) = 0;
        virtual bool Online(uint64_t character) const = 0;
        virtual bool Alive(uint64_t character) const = 0;
        virtual bool InCombat(uint64_t character) const = 0;
        virtual bool Gm(uint64_t character) const = 0;
        virtual uint32_t Account(uint64_t character) const = 0;
        virtual void MarkOrigin(uint64_t character) = 0;
        virtual bool Away(uint64_t character) const = 0;
        virtual std::optional<Spawned> Spawn(uint64_t character, Side side, uint32_t species, uint32_t display) = 0;
        virtual void Scale(uint64_t handle, double scale) = 0;
        virtual void Despawn(uint64_t handle) = 0;
        virtual std::vector<uint32_t> Displays(uint32_t species) const = 0;
        virtual uint32_t UnixNow() const = 0;
        virtual Store::Journal* JournalOf(uint64_t character) = 0;
        virtual void Flush(Store::Journal& journal) = 0;
        virtual void SyncCompanions(uint64_t character) = 0;
        virtual void Show(uint64_t handle, uint64_t other, Cue const& cue) = 0;
        virtual void Prime(uint64_t character, uint32_t entry, uint32_t species, uint32_t display) = 0;
        virtual std::optional<uint32_t> PrimeAll(uint64_t character) = 0;
        virtual std::optional<uint8_t> FoodLevel(uint32_t item) = 0;
        virtual bool HasItem(uint64_t character, uint32_t item) = 0;
        virtual void TakeItem(uint64_t character, uint32_t item) = 0;
        virtual void Summon(uint64_t character, uint32_t species) = 0;
        virtual void Dismiss(uint64_t character) = 0;
        virtual uint32_t Follower(uint64_t character) = 0;
        virtual void Suppress(uint64_t character, bool on) = 0;
        virtual uint32_t SweepStandIns(uint64_t character, float yards) = 0;
    };

    struct EnemySpec
    {
        uint32_t species = 0;
        double level = 1;
        double quality = 1;
        uint32_t display = 0;
    };

    class Session;

    class Battles
    {
    public:
        Battles(std::shared_ptr<Engine::Catalog const> catalog, DataSet const& data, ModelInfoLookup modelInfo,
            World& world, Scheduler& scheduler, Engine::Rng& rng);
        ~Battles();

        void Message(uint64_t character, std::string const& module, std::string const& action,
            std::string const& payload);
        bool Start(uint64_t character, std::optional<std::vector<EnemySpec>> enemies);
        bool Challenge(uint64_t character, std::string const& payload);
        void Logout(uint64_t character);
        void Abandon(uint64_t character);
        uint32_t Clean(uint64_t character);
        void Watchdog();
        bool InBattle(uint64_t character) const;
        void EndAll();
        void UseCatalog(std::shared_ptr<Engine::Catalog const> catalog);

        World& GetWorld() { return _world; }
        Scheduler& GetScheduler() { return _scheduler; }
        Engine::Rng& GetRng() { return _rng; }
        std::shared_ptr<Engine::Catalog const> GetCatalog() const { return _catalog; }
        PetScale const& GetScale() const { return _scale; }
        void Unregister(uint64_t character, Session const* session);

    private:
        void Command(uint64_t character, std::string const& payload);
        void Quit(uint64_t character);
        bool OtherCharacterFighting(uint64_t character) const;
        void ClearLingering(uint64_t character);
        void FedRefresh(uint64_t character, uint32_t species, uint32_t remaining, uint64_t stepMs);

        std::shared_ptr<Engine::Catalog const> _catalog;
        PetScale _scale;
        World& _world;
        Scheduler& _scheduler;
        Engine::Rng& _rng;
        std::map<uint64_t, std::shared_ptr<Session>> _sessions;
        std::multimap<uint64_t, std::weak_ptr<Session>> _lingering;
    };
}

#endif
