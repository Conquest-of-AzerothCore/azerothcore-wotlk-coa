#ifndef COA_PET_BATTLE_FOLLOW_FOLLOWERS_H
#define COA_PET_BATTLE_FOLLOW_FOLLOWERS_H

#include "Battle/Scheduler.h"
#include <cstdint>
#include <functional>
#include <map>
#include <optional>
#include <set>

namespace CoAPetBattles::Follow
{
    class FollowerWorld
    {
    public:
        virtual ~FollowerWorld() = default;
        virtual bool Online(uint64_t character) const = 0;
        virtual bool Wanted(uint64_t character) const = 0;
        virtual bool Owns(uint64_t character, uint32_t petId) const = 0;
        virtual std::optional<uint64_t> SpawnFollower(uint64_t character, uint32_t petId) = 0;
        virtual void DespawnFollower(uint64_t handle) = 0;
        virtual bool Near(uint64_t character, uint64_t handle) const = 0;
        virtual void Pace(uint64_t character, uint64_t handle) = 0;
        virtual void SendFollow(uint64_t character, uint32_t petId) = 0;
        virtual void Save(uint64_t character, uint32_t petId) = 0;
        virtual std::optional<uint32_t> Saved(uint64_t character) = 0;
    };

    class Registry
    {
    public:
        Registry(FollowerWorld& world, Battle::Scheduler& scheduler) : _world(world), _scheduler(scheduler) { }

        void Summon(uint64_t character, uint32_t petId);
        void Dismiss(uint64_t character);
        void DismissMatching(uint32_t petId, std::function<bool(uint64_t)> const& matches);
        void Login(uint64_t character);
        void Logout(uint64_t character);
        void Suppress(uint64_t character, bool on);
        uint32_t Follower(uint64_t character) const;
        bool Out(uint64_t character) const;
        bool IsFollower(uint64_t handle) const;
        void Tick();

    private:
        struct Entry
        {
            uint32_t petId = 0;
            uint64_t handle = 0;
        };

        void Set(uint64_t character, uint32_t petId);
        void Periodic();
        void Remove(Entry& entry);
        void Spawn(uint64_t character, Entry& entry);

        FollowerWorld& _world;
        Battle::Scheduler& _scheduler;
        std::map<uint64_t, Entry> _followers;
        std::set<uint64_t> _suppressed;
        bool _ticking = false;
    };
}

#endif
