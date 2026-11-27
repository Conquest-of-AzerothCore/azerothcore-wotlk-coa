#include "Followers.h"
#include <vector>

namespace CoAPetBattles::Follow
{
    namespace
    {
        constexpr uint64_t TickMs = 2000;
        constexpr uint64_t FirstTickMs = 200;
    }

    void Registry::Remove(Entry& entry)
    {
        if (entry.handle)
            _world.DespawnFollower(entry.handle);
        entry.handle = 0;
    }

    void Registry::Spawn(uint64_t character, Entry& entry)
    {
        if (std::optional<uint64_t> const handle = _world.SpawnFollower(character, entry.petId))
        {
            entry.handle = *handle;
            _world.Pace(character, *handle);
        }
    }

    void Registry::Set(uint64_t character, uint32_t petId)
    {
        auto const found = _followers.find(character);
        if (found != _followers.end())
        {
            Remove(found->second);
            _followers.erase(found);
        }
        if (petId)
        {
            _followers[character] = { petId, 0 };
            if (!_ticking)
            {
                _ticking = true;
                _scheduler.After(TickMs, [this] { Periodic(); });
            }
            _scheduler.After(FirstTickMs, [this] { Tick(); });
        }
        _world.Save(character, petId);
        _world.SendFollow(character, petId);
    }

    void Registry::Summon(uint64_t character, uint32_t petId)
    {
        if (_world.Owns(character, petId))
            Set(character, petId);
    }

    void Registry::Dismiss(uint64_t character)
    {
        Set(character, 0);
    }

    void Registry::DismissMatching(uint32_t petId, std::function<bool(uint64_t)> const& matches)
    {
        std::vector<uint64_t> dismissed;
        for (auto const& [character, entry] : _followers)
            if (entry.petId == petId && matches(character))
                dismissed.push_back(character);
        for (uint64_t character : dismissed)
            Dismiss(character);
    }

    void Registry::Login(uint64_t character)
    {
        if (_followers.count(character))
            return;
        std::optional<uint32_t> const petId = _world.Saved(character);
        if (petId && *petId && _world.Owns(character, *petId))
            Set(character, *petId);
    }

    void Registry::Logout(uint64_t character)
    {
        auto const found = _followers.find(character);
        if (found != _followers.end())
        {
            Remove(found->second);
            _followers.erase(found);
        }
        _suppressed.erase(character);
    }

    void Registry::Suppress(uint64_t character, bool on)
    {
        if (on)
            _suppressed.insert(character);
        else
            _suppressed.erase(character);
    }

    uint32_t Registry::Follower(uint64_t character) const
    {
        auto const found = _followers.find(character);
        return found == _followers.end() ? 0 : found->second.petId;
    }

    bool Registry::Out(uint64_t character) const
    {
        auto const found = _followers.find(character);
        return found != _followers.end() && found->second.handle != 0;
    }

    bool Registry::IsFollower(uint64_t handle) const
    {
        for (auto const& [character, entry] : _followers)
            if (handle && entry.handle == handle)
                return true;
        return false;
    }

    void Registry::Periodic()
    {
        Tick();
        if (_followers.empty())
            _ticking = false;
        else
            _scheduler.After(TickMs, [this] { Periodic(); });
    }

    void Registry::Tick()
    {
        std::vector<uint64_t> characters;
        for (auto const& [character, entry] : _followers)
            characters.push_back(character);
        for (uint64_t character : characters)
        {
            auto const found = _followers.find(character);
            if (found == _followers.end())
                continue;
            Entry& entry = found->second;
            if (!_world.Online(character))
            {
                Remove(entry);
                continue;
            }
            if (!_world.Owns(character, entry.petId))
            {
                Set(character, 0);
                continue;
            }
            bool const want = _world.Wanted(character) && !_suppressed.count(character);
            if (!want)
                Remove(entry);
            else if (!entry.handle || !_world.Near(character, entry.handle))
            {
                Remove(entry);
                Spawn(character, entry);
            }
            else
                _world.Pace(character, entry.handle);
        }
    }
}
