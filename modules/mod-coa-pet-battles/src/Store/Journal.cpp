#include "Journal.h"
#include "Engine/Rules.h"
#include <algorithm>
#include <cmath>

namespace CoAPetBattles::Store
{
    namespace
    {
        uint8_t ClampLevel(Engine::Catalog const& catalog, double level)
        {
            double const maxLevel = static_cast<double>(catalog.Config().maxLevel);
            return static_cast<uint8_t>(std::max(1.0, std::min(maxLevel, level)));
        }

        bool ValidPicks(std::array<uint8_t, 3> const& picks)
        {
            return std::all_of(picks.begin(), picks.end(), [](uint8_t pick) { return pick == 1 || pick == 2; });
        }
    }

    uint32_t XpReward(Engine::Catalog const& catalog, uint8_t petLevel, uint8_t enemyLevel)
    {
        std::array<double, 2> const* row = catalog.Xp(ClampLevel(catalog, enemyLevel));
        if (!row)
            return 0;
        double const base = (*row)[1];
        int32_t const diff = int32_t(petLevel) - int32_t(enemyLevel);
        if (diff <= 0)
            return static_cast<uint32_t>(base);
        double const factor = 1 - diff * catalog.Config().xpStep;
        return factor > 0.001 ? static_cast<uint32_t>(std::floor(base * factor + 0.5)) : 0;
    }

    uint32_t XpNeeded(Engine::Catalog const& catalog, uint8_t level)
    {
        std::array<double, 2> const* row = catalog.Xp(ClampLevel(catalog, level));
        return row ? static_cast<uint32_t>((*row)[0] * (*row)[1]) : 0;
    }

    Journal::Journal(uint32_t account, Engine::Catalog const& catalog, std::vector<OwnedPet> pets,
        std::array<Team, TeamCount> teams, uint8_t activeTeam, uint32_t activeRevision)
        : _account(account), _catalog(&catalog), _teams(teams),
          _activeTeam(activeTeam >= 1 && activeTeam <= TeamCount ? activeTeam : 1), _activeRevision(activeRevision)
    {
        _revision = activeRevision;
        for (OwnedPet const& pet : pets)
        {
            _revision = std::max(_revision, pet.revision);
            std::string reason;
            if (Usable(pet, &reason))
                _pets[pet.species] = pet;
            else
            {
                _blocked.insert(pet.species);
                _rejected.push_back("account " + std::to_string(account) + " pet " + std::to_string(pet.species) +
                    ": " + reason);
            }
        }
        for (Team& team : _teams)
        {
            _revision = std::max(_revision, team.revision);
            for (uint32_t& slot : team.slots)
                if (slot && !_pets.count(slot))
                    slot = 0;
        }
    }

    uint8_t Journal::MaxLevel() const
    {
        return _catalog->Config().maxLevel;
    }

    bool Journal::Usable(OwnedPet const& pet, std::string* reason) const
    {
        std::string why;
        if (!_catalog->Species(pet.species))
            why = "species unknown";
        else if (pet.level < 1 || pet.level > MaxLevel())
            why = "level " + std::to_string(pet.level) + " outside 1-" + std::to_string(MaxLevel());
        else if (pet.quality < 1 || pet.quality > MaxQuality)
            why = "quality " + std::to_string(pet.quality) + " outside 1-4";
        else if (!ValidPicks(pet.picks))
            why = "ability picks must be 1 or 2";
        if (reason)
            *reason = why;
        return why.empty();
    }

    void Journal::Keep(OwnedPet pet)
    {
        pet.revision = ++_revision;
        _pets[pet.species] = pet;
        _writes.push_back({ RowKind::Pet, _account, pet.species, pet.revision });
    }

    void Journal::WriteTeam(uint8_t team)
    {
        Team& row = _teams[team - 1];
        row.revision = ++_revision;
        _writes.push_back({ RowKind::Team, _account, team, row.revision });
    }

    bool Journal::Owns(uint32_t species) const
    {
        return _pets.count(species) || _blocked.count(species);
    }

    OwnedPet const* Journal::Pet(uint32_t species) const
    {
        auto const found = _pets.find(species);
        return found == _pets.end() ? nullptr : &found->second;
    }

    std::vector<OwnedPet const*> Journal::Pets() const
    {
        std::vector<OwnedPet const*> pets;
        for (auto const& [species, pet] : _pets)
            pets.push_back(&pet);
        return pets;
    }

    bool Journal::Add(uint32_t species, uint8_t level, std::array<uint8_t, 3> picks, uint8_t quality,
        uint32_t display)
    {
        if (Owns(species) || !_catalog->Species(species))
            return false;
        OwnedPet pet;
        pet.species = species;
        pet.level = ClampLevel(*_catalog, level);
        pet.picks = ValidPicks(picks) ? picks : std::array<uint8_t, 3> { 1, 1, 1 };
        pet.quality = std::clamp<uint8_t>(quality, 1, MaxQuality);
        pet.display = display;
        _fed.erase(species);
        Keep(pet);
        return true;
    }

    CaptureResult Journal::Capture(uint32_t species, uint8_t level, std::array<uint8_t, 3> picks, uint8_t quality,
        uint32_t display)
    {
        uint8_t const outcome = Compare(species, quality, level);
        if (outcome == 2 || !_catalog->Species(species))
            return CaptureResult::Released;
        if (outcome == 1)
            _pets.erase(species);
        Add(species, level, picks, quality, display);
        return outcome == 1 ? CaptureResult::Replaced : CaptureResult::Added;
    }

    uint8_t Journal::Compare(uint32_t species, uint8_t quality, uint8_t level) const
    {
        if (_blocked.count(species))
            return 2;
        OwnedPet const* owned = Pet(species);
        if (!owned)
            return 0;
        uint8_t const wanted = ClampLevel(*_catalog, level);
        if (quality > owned->quality || (quality == owned->quality && wanted > owned->level))
            return 1;
        return 2;
    }

    bool Journal::SetPicks(uint32_t species, std::array<uint8_t, 3> picks)
    {
        OwnedPet const* owned = Pet(species);
        if (!owned || !ValidPicks(picks))
            return false;
        OwnedPet pet = *owned;
        pet.picks = picks;
        Keep(pet);
        return true;
    }

    bool Journal::SetDisplayOnce(uint32_t species, uint32_t display)
    {
        OwnedPet const* owned = Pet(species);
        if (!owned || owned->display || !display)
            return false;
        OwnedPet pet = *owned;
        pet.display = display;
        Keep(pet);
        return true;
    }

    std::optional<XpGain> Journal::GrantXp(uint32_t species, uint8_t enemyLevel, uint32_t)
    {
        OwnedPet const* owned = Pet(species);
        if (!owned)
            return std::nullopt;
        if (owned->level >= MaxLevel())
            return XpGain { 0, owned->level, 0 };
        OwnedPet pet = *owned;
        uint32_t const gain = XpReward(*_catalog, pet.level, enemyLevel);
        uint8_t const start = pet.level;
        pet.xp += gain;
        while (pet.level < MaxLevel())
        {
            uint32_t const needed = XpNeeded(*_catalog, pet.level);
            if (pet.xp < needed)
                break;
            pet.xp -= needed;
            ++pet.level;
        }
        if (pet.level >= MaxLevel())
            pet.xp = 0;
        if (pet.level > start)
        {
            pet.health = 0;
            pet.healthAt = 0;
            _fed.erase(species);
        }
        Keep(pet);
        return XpGain { gain, pet.level, static_cast<uint8_t>(pet.level - start) };
    }

    uint32_t Journal::MaxHealth(OwnedPet const& pet) const
    {
        Engine::SpeciesDef const* def = _catalog->Species(pet.species);
        if (!def)
            return 0;
        return static_cast<uint32_t>(Engine::PetStats(def->power, def->speed, def->stamina, pet.level, pet.quality,
            MaxLevel()).health);
    }

    uint32_t Journal::CurrentHealth(OwnedPet const& pet, uint32_t now) const
    {
        uint32_t const max = MaxHealth(pet);
        if (!pet.health)
            return max;
        if (now <= pet.healthAt)
            return std::min(max, pet.health);
        Settings const& settings = _catalog->Config();
        uint64_t const ticks = settings.regenSeconds ? (now - pet.healthAt) / settings.regenSeconds : 0;
        uint64_t const perTick = std::max<uint64_t>(1, uint64_t(max) * settings.regenPercent / 100);
        uint64_t health = pet.health + ticks * perTick;
        auto const fed = _fed.find(pet.species);
        if (fed != _fed.end() && fed->second.first == pet.healthAt && settings.fedStepSeconds)
        {
            uint64_t const until = std::min<uint64_t>(now, fed->second.second);
            uint64_t const steps =
                until > fed->second.first ? (until - fed->second.first) / settings.fedStepSeconds : 0;
            health += steps * (uint64_t(max) * settings.fedPercent / 100);
        }
        return static_cast<uint32_t>(std::min<uint64_t>(max, health));
    }

    FeedResult Journal::Feed(uint32_t species, uint8_t foodLevel, uint32_t now)
    {
        OwnedPet const* owned = Pet(species);
        if (!owned)
            return FeedResult::NotOwned;
        uint32_t const current = CurrentHealth(*owned, now);
        if (current >= MaxHealth(*owned))
            return FeedResult::FullHealth;
        if (foodLevel < owned->level)
            return FeedResult::TooWeak;
        OwnedPet pet = *owned;
        pet.health = current;
        pet.healthAt = now;
        Keep(pet);
        _fed[species] = { now, now + _catalog->Config().fedSeconds };
        return FeedResult::Fed;
    }

    bool Journal::SetHealth(uint32_t species, uint32_t health, uint32_t now)
    {
        OwnedPet const* owned = Pet(species);
        if (!owned)
            return false;
        OwnedPet pet = *owned;
        _fed.erase(species);
        uint32_t const value = std::max<uint32_t>(1, health);
        if (value >= MaxHealth(pet))
        {
            pet.health = 0;
            pet.healthAt = 0;
        }
        else
        {
            pet.health = value;
            pet.healthAt = now;
        }
        Keep(pet);
        return true;
    }

    size_t Journal::HealAll()
    {
        std::vector<OwnedPet> healed;
        for (auto const& [species, pet] : _pets)
        {
            OwnedPet copy = pet;
            copy.health = 0;
            copy.healthAt = 0;
            _fed.erase(species);
            healed.push_back(copy);
        }
        for (OwnedPet const& pet : healed)
            Keep(pet);
        return healed.size();
    }

    TeamResult Journal::SetTeam(uint8_t team, std::array<uint32_t, 3> slots)
    {
        if (team < 1 || team > TeamCount)
            return TeamResult::BadTeam;
        for (size_t i = 0; i < slots.size(); ++i)
        {
            if (!slots[i])
                continue;
            if (!_pets.count(slots[i]))
                return TeamResult::NotOwned;
            for (size_t j = 0; j < i; ++j)
                if (slots[j] == slots[i])
                    return TeamResult::Duplicate;
        }
        _teams[team - 1].slots = slots;
        WriteTeam(team);
        return TeamResult::Saved;
    }

    bool Journal::SetActiveTeam(uint8_t team)
    {
        if (team < 1 || team > TeamCount)
            return false;
        _activeTeam = team;
        _activeRevision = ++_revision;
        _writes.push_back({ RowKind::Account, _account, 0, _activeRevision });
        return true;
    }

    Team const& Journal::TeamAt(uint8_t team) const
    {
        return _teams[std::clamp<uint8_t>(team, 1, TeamCount) - 1];
    }

    std::array<uint32_t, 3> Journal::BattleTeam()
    {
        Team const& active = _teams[_activeTeam - 1];
        if (std::any_of(active.slots.begin(), active.slots.end(), [this](uint32_t s) { return s && _pets.count(s); }))
            return active.slots;
        std::vector<OwnedPet const*> pets = Pets();
        if (pets.empty())
            return active.slots;
        std::stable_sort(pets.begin(), pets.end(), [](OwnedPet const* a, OwnedPet const* b)
        {
            return a->level != b->level ? a->level > b->level : a->species < b->species;
        });
        std::array<uint32_t, 3> slots = { 0, 0, 0 };
        for (size_t i = 0; i < slots.size() && i < pets.size(); ++i)
            slots[i] = pets[i]->species;
        _teams[_activeTeam - 1].slots = slots;
        WriteTeam(_activeTeam);
        return slots;
    }

    std::vector<uint32_t> Journal::SyncCompanions(std::multimap<uint32_t, uint32_t> const& speciesSpells,
        std::function<bool(uint32_t)> const& knowsSpell)
    {
        std::vector<uint32_t> added;
        for (auto it = speciesSpells.begin(); it != speciesSpells.end(); it = speciesSpells.upper_bound(it->first))
        {
            uint32_t const species = it->first;
            if (Owns(species) || !_catalog->Species(species))
                continue;
            auto const [first, last] = speciesSpells.equal_range(species);
            if (std::any_of(first, last, [&knowsSpell](auto const& entry) { return knowsSpell(entry.second); }) &&
                Add(species, 1, { 1, 1, 1 }, 1, 0))
                added.push_back(species);
        }
        return added;
    }

    std::vector<RowWrite> Journal::TakeWrites()
    {
        std::vector<RowWrite> writes;
        writes.swap(_writes);
        return writes;
    }
}
