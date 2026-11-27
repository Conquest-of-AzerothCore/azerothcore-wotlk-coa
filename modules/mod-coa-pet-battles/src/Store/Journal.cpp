#include "Journal.h"
#include "Engine/PetFactory.h"
#include <algorithm>
#include <cmath>
#include <limits>

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
            _lastPetId = std::max(_lastPetId, pet.id);
            if (pet.source == PetSource::Released)
                continue;
            if (pet.source == PetSource::Companion)
                _companionSpecies.insert(pet.species);
            std::string reason;
            if (Usable(pet, &reason))
            {
                _pets.emplace(pet.id, pet);
                _petIdsBySpecies.emplace(pet.species, pet.id);
            }
            else
            {
                _blockedSpecies.insert(pet.species);
                if (pet.source == PetSource::Legacy)
                    _blockedLegacySpecies.insert(pet.species);
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
        Engine::SpeciesDef const* def = _catalog->Species(pet.species);
        if (!pet.id)
            why = "missing pet ID";
        else if (!def)
            why = "species unknown";
        else if (pet.source > PetSource::Companion || (pet.breed && pet.source == PetSource::Legacy))
            why = "invalid acquisition source";
        else if (pet.breed && !def->Breeds().contains(pet.breed))
            why = "breed unavailable";
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

    OwnedPet const& Journal::Keep(OwnedPet pet)
    {
        pet.revision = ++_revision;
        auto const [position, inserted] = _pets.insert_or_assign(pet.id, pet);
        if (inserted)
            _petIdsBySpecies.emplace(pet.species, pet.id);
        if (pet.source == PetSource::Companion)
            _companionSpecies.insert(pet.species);
        _writes.push_back({ RowKind::Pet, _account, pet.id, pet.revision });
        return position->second;
    }

    void Journal::WriteTeam(uint8_t team)
    {
        Team& row = _teams[team - 1];
        row.revision = ++_revision;
        _writes.push_back({ RowKind::Team, _account, team, row.revision });
    }

    bool Journal::Owns(uint32_t species) const
    {
        return _petIdsBySpecies.contains(species) || _blockedSpecies.contains(species);
    }

    OwnedPet const* Journal::Pet(uint32_t petId) const
    {
        auto const found = _pets.find(petId);
        return found == _pets.end() ? nullptr : &found->second;
    }

    OwnedPet const* Journal::PetOfSpecies(uint32_t species) const
    {
        return Pet(PetIdForSpecies(species));
    }

    uint32_t Journal::PetIdForSpecies(uint32_t species) const
    {
        auto const found = _petIdsBySpecies.find(species);
        return found == _petIdsBySpecies.end() ? 0 : found->second;
    }

    uint32_t Journal::SpeciesForPet(uint32_t petId) const
    {
        OwnedPet const* pet = Pet(petId);
        return pet ? pet->species : 0;
    }

    std::vector<OwnedPet const*> Journal::Pets() const
    {
        std::vector<OwnedPet const*> pets;
        pets.reserve(_pets.size());
        for (auto const& [species, petId] : _petIdsBySpecies)
            pets.push_back(Pet(petId));
        return pets;
    }

    bool Journal::Add(uint32_t species, uint8_t level, std::array<uint8_t, 3> picks, uint8_t quality,
        uint32_t display)
    {
        if (Owns(species))
            return false;
        return AddPet({ .species = species, .level = level, .picks = picks, .quality = quality, .display = display })
            != nullptr;
    }

    OwnedPet const* Journal::AddPet(OwnedPet pet)
    {
        Engine::SpeciesDef const* def = _catalog->Species(pet.species);
        if (!def || (pet.breed && !def->Breeds().contains(pet.breed)) ||
            _lastPetId == std::numeric_limits<uint32_t>::max())
            return nullptr;
        pet.id = ++_lastPetId;
        pet.level = ClampLevel(*_catalog, pet.level);
        pet.picks = ValidPicks(pet.picks) ? pet.picks : std::array<uint8_t, 3> { 1, 1, 1 };
        pet.quality = std::clamp<uint8_t>(pet.quality, 1, MaxQuality);
        return &Keep(pet);
    }

    OwnedPet const* Journal::Capture(uint32_t species, uint8_t level, std::array<uint8_t, 3> picks, uint8_t quality,
        uint32_t display, uint8_t breed)
    {
        return AddPet({ .species = species, .breed = breed, .source = PetSource::Wild, .level = level, .picks = picks,
            .quality = quality, .display = display });
    }

    bool Journal::Release(uint32_t petId)
    {
        auto const found = _pets.find(petId);
        if (found == _pets.end() || found->second.source != PetSource::Wild)
            return false;
        auto const [first, last] = _petIdsBySpecies.equal_range(found->second.species);
        auto const index = std::find_if(first, last, [petId](auto const& entry) { return entry.second == petId; });
        _petIdsBySpecies.erase(index);
        _pets.erase(found);
        _fed.erase(petId);
        _writes.push_back({ RowKind::Release, _account, petId, ++_revision });
        for (uint8_t team = 1; team <= TeamCount; ++team)
        {
            auto& slots = _teams[team - 1].slots;
            if (std::find(slots.begin(), slots.end(), petId) == slots.end())
                continue;
            std::replace(slots.begin(), slots.end(), petId, 0u);
            WriteTeam(team);
        }
        return true;
    }

    bool Journal::SetPicks(uint32_t petId, std::array<uint8_t, 3> picks)
    {
        OwnedPet const* owned = Pet(petId);
        if (!owned || !ValidPicks(picks))
            return false;
        OwnedPet pet = *owned;
        pet.picks = picks;
        Keep(pet);
        return true;
    }

    bool Journal::SetDisplayOnce(uint32_t petId, uint32_t display)
    {
        OwnedPet const* owned = Pet(petId);
        if (!owned || owned->display || !display)
            return false;
        OwnedPet pet = *owned;
        pet.display = display;
        Keep(pet);
        return true;
    }

    std::optional<XpGain> Journal::GrantXp(uint32_t petId, uint8_t enemyLevel, uint32_t)
    {
        OwnedPet const* owned = Pet(petId);
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
            _fed.erase(petId);
        }
        Keep(pet);
        return XpGain { gain, pet.level, static_cast<uint8_t>(pet.level - start) };
    }

    uint32_t Journal::MaxHealth(OwnedPet const& pet) const
    {
        Engine::SpeciesDef const* def = _catalog->Species(pet.species);
        if (!def)
            return 0;
        return static_cast<uint32_t>(Engine::StatsForPet(*def, pet.level, pet.quality, MaxLevel(), pet.breed).health);
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
        auto const fed = _fed.find(pet.id);
        if (fed != _fed.end() && fed->second.first == pet.healthAt && settings.fedStepSeconds)
        {
            uint64_t const until = std::min<uint64_t>(now, fed->second.second);
            uint64_t const steps =
                until > fed->second.first ? (until - fed->second.first) / settings.fedStepSeconds : 0;
            health += steps * (uint64_t(max) * settings.fedPercent / 100);
        }
        return static_cast<uint32_t>(std::min<uint64_t>(max, health));
    }

    FeedResult Journal::Feed(uint32_t petId, uint8_t foodLevel, uint32_t now)
    {
        OwnedPet const* owned = Pet(petId);
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
        _fed[petId] = { now, now + _catalog->Config().fedSeconds };
        return FeedResult::Fed;
    }

    bool Journal::SetHealth(uint32_t petId, uint32_t health, uint32_t now)
    {
        OwnedPet const* owned = Pet(petId);
        if (!owned)
            return false;
        OwnedPet pet = *owned;
        _fed.erase(petId);
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
        for (auto const& [petId, pet] : _pets)
        {
            OwnedPet copy = pet;
            copy.health = 0;
            copy.healthAt = 0;
            _fed.erase(petId);
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

    std::array<uint32_t, 3> Journal::BattleTeam(bool ownedIds)
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
        size_t slot = 0;
        for (OwnedPet const* pet : pets)
        {
            if (!ownedIds && PetIdForSpecies(pet->species) != pet->id)
                continue;
            slots[slot++] = pet->id;
            if (slot == slots.size())
                break;
        }
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
            Engine::SpeciesDef const* def = _catalog->Species(species);
            if (_companionSpecies.contains(species) || _blockedLegacySpecies.contains(species) || !def)
                continue;
            auto const [first, last] = speciesSpells.equal_range(species);
            if (!std::any_of(first, last, [&knowsSpell](auto const& entry) { return knowsSpell(entry.second); }))
                continue;

            auto const [ownedFirst, ownedLast] = _petIdsBySpecies.equal_range(species);
            auto const legacy = std::find_if(ownedFirst, ownedLast, [this](auto const& entry)
            {
                return Pet(entry.second)->source == PetSource::Legacy;
            });
            if (legacy != ownedLast)
            {
                OwnedPet pet = *Pet(legacy->second);
                pet.source = PetSource::Companion;
                Keep(pet);
            }
            else
            {
                uint8_t const breed = def->retailBreeds.empty() && def->Breeds().contains(BalancedBreed) ?
                    BalancedBreed : 0;
                if (AddPet({ .species = species, .breed = breed, .source = PetSource::Companion }))
                    added.push_back(species);
            }
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
