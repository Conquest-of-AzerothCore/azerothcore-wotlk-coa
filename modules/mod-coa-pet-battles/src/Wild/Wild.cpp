#include "Wild.h"
#include "Engine/PetFactory.h"
#include <algorithm>
#include <cmath>

namespace CoAPetBattles::Wild
{
    namespace
    {
        constexpr double FullTurn = 6.2832;

        double Squared(double dx, double dy)
        {
            return dx * dx + dy * dy;
        }

        std::optional<WildPlayer> FindPlayer(std::vector<WildPlayer> const& players, uint64_t character)
        {
            for (WildPlayer const& player : players)
                if (player.character == character)
                    return player;
            return std::nullopt;
        }

        std::vector<WildPlayer> Sorted(std::vector<WildPlayer> players)
        {
            std::sort(players.begin(), players.end(),
                [](WildPlayer const& a, WildPlayer const& b) { return a.character < b.character; });
            return players;
        }
    }

    Registry::Registry(std::shared_ptr<Engine::Catalog const> catalog, DataSet const& data, WildSettings settings,
        Battle::PetScale const& scale, WildWorld& world, Engine::Rng& rng)
        : _catalog(std::move(catalog)), _data(data), _settings(settings), _scale(scale), _world(world), _rng(rng)
    {
    }

    void Registry::UseCatalog(std::shared_ptr<Engine::Catalog const> catalog)
    {
        _catalog = std::move(catalog);
    }

    void Registry::UseSettings(WildSettings settings)
    {
        _settings = settings;
    }

    std::string const& Registry::NameOf(uint32_t species) const
    {
        static std::string const unknown;
        auto const found = _data.species.find(species);
        return found == _data.species.end() ? unknown : found->second.name;
    }

    bool Registry::IsWildSpecies(uint32_t species) const
    {
        auto const found = _data.species.find(species);
        return found != _data.species.end() && found->second.wild;
    }

    bool Registry::IsAdoptSpecies(uint32_t species) const
    {
        auto const found = _data.species.find(species);
        return found != _data.species.end() && found->second.wild && found->second.critter;
    }

    uint8_t Registry::PetLevelOf(Pet const& pet) const
    {
        return PetLevel(_data, _catalog->Config().maxLevel, pet.level, pet.zone);
    }

    bool Registry::Cooling(uint32_t species, uint32_t map, double x, double y, uint32_t now)
    {
        double const spacing = _settings.spacing;
        for (size_t i = _cooldowns.size(); i-- > 0;)
        {
            Cooldown const& cooldown = _cooldowns[i];
            if (cooldown.until <= now)
                _cooldowns.erase(_cooldowns.begin() + static_cast<std::ptrdiff_t>(i));
            else if (cooldown.species == species && cooldown.map == map &&
                Squared(cooldown.x - x, cooldown.y - y) < spacing * spacing)
                return true;
        }
        return false;
    }

    bool Registry::WildNear(uint32_t species, uint32_t map, double x, double y) const
    {
        double const spacing = _settings.spacing;
        for (auto const& [key, pet] : _pets)
            if (pet.species == species && pet.map == map && Squared(pet.x - x, pet.y - y) < spacing * spacing)
                return true;
        return false;
    }

    Spot Registry::SpawnSpot(RealCreature const& mob, uint32_t map)
    {
        for (uint32_t i = 0; i < _settings.tries; ++i)
        {
            double const angle = _rng.Fraction() * FullTurn;
            double const distance = _settings.spotMin + _rng.Fraction() * (_settings.spotMax - _settings.spotMin);
            double const x = mob.x + std::cos(angle) * distance;
            double const y = mob.y + std::sin(angle) * distance;
            std::optional<double> const height = _world.Ground(map, x, y);
            if (height && *height > -1000 && std::abs(*height - mob.z) <= _settings.maxHeightDifference)
                return { map, x, y, mob.z + 1.0 };
        }
        double const angle = _rng.Fraction() * FullTurn;
        return { map, mob.x + std::cos(angle) * _settings.fallbackDistance,
            mob.y + std::sin(angle) * _settings.fallbackDistance, mob.z };
    }

    void Registry::Spawn(WildPlayer const& player, uint32_t species, RealCreature const& mob,
        std::vector<uint32_t> const& types, uint32_t now)
    {
        Spot const at = SpawnSpot(mob, player.map);
        std::optional<SpawnedPet> const spawned = _world.Spawn(species, at, _rng.Fraction() * FullTurn);
        if (!spawned)
            return;
        Pet pet;
        pet.species = species;
        pet.level = mob.level;
        pet.zone = player.zone;
        pet.map = player.map;
        pet.x = at.x;
        pet.y = at.y;
        pet.z = at.z;
        pet.born = now;
        pet.types = types;
        pet.display = spawned->display;
        _pets[spawned->key] = pet;
        _world.Scale(spawned->key, _scale.ScaleOf(species, spawned->display));
        _world.Settle(spawned->key, at);
        _world.Wander(spawned->key, _settings.wander);
    }

    void Registry::Adopt(WildPlayer const& player, uint32_t species, RealCreature const& mob,
        std::vector<uint32_t> const& types, uint32_t now)
    {
        Pet pet;
        pet.species = species;
        pet.level = mob.level;
        pet.zone = player.zone;
        pet.map = player.map;
        pet.x = mob.x;
        pet.y = mob.y;
        pet.z = mob.z;
        pet.born = now;
        pet.types = types;
        pet.adopted = true;
        _pets[mob.guid] = pet;
        _world.Adopt(mob.guid);
    }

    void Registry::Remove(uint64_t key, bool startCooldown, bool consume)
    {
        auto const found = _pets.find(key);
        if (found == _pets.end())
            return;
        Pet const pet = found->second;
        if (_world.Where(key))
        {
            if (pet.adopted && !consume)
                _world.Release(key);
            else
                _world.Despawn(key);
        }
        if (startCooldown)
            _cooldowns.push_back({ pet.species, pet.map, pet.x, pet.y, _world.UnixNow() + _settings.cooldownSeconds });
        _pets.erase(key);
    }

    void Registry::Scan(WildPlayer const& player, uint32_t now)
    {
        double const spacing = _settings.spacing;
        uint32_t near = 0;
        std::set<uint32_t> here;
        for (auto const& [key, pet] : _pets)
            if (pet.map == player.map && Squared(pet.x - player.x, pet.y - player.y) < spacing * spacing)
            {
                ++near;
                here.insert(pet.species);
            }
        if (near >= _settings.maxArea)
            return;
        auto const last = _scanned.find(player.character);
        if (last != _scanned.end() && last->second.map == player.map && !last->second.spawned &&
            now - last->second.at < _settings.rescanIdleSeconds &&
            Squared(last->second.x - player.x, last->second.y - player.y) < _settings.moveRescan * _settings.moveRescan)
            return;
        std::map<uint32_t, std::vector<RealCreature>> found;
        std::vector<uint32_t> types;
        for (RealCreature const& creature : _world.RealCreaturesNear(player.character, _settings.search))
        {
            if (!IsWildSpecies(creature.entry))
                continue;
            if (IsAdoptSpecies(creature.entry) && _pets.count(creature.guid))
                continue;
            if (!found.count(creature.entry))
                types.push_back(creature.entry);
            found[creature.entry].push_back(creature);
        }
        std::sort(types.begin(), types.end());
        uint32_t spawned = 0;
        for (uint32_t species : types)
        {
            if (near >= _settings.maxArea)
                break;
            std::vector<RealCreature> const& mobs = found[species];
            RealCreature const mob = mobs[static_cast<size_t>(_rng.Roll(1, static_cast<int32_t>(mobs.size())) - 1)];
            if (!here.count(species) && !WildNear(species, player.map, mob.x, mob.y) &&
                !Cooling(species, player.map, mob.x, mob.y, now))
            {
                if (IsAdoptSpecies(species))
                    Adopt(player, species, mob, types, now);
                else
                    Spawn(player, species, mob, types, now);
                ++near;
                here.insert(species);
                ++spawned;
            }
        }
        _scanned[player.character] = { player.map, player.x, player.y, now, spawned > 0 };
    }

    void Registry::Tick()
    {
        uint32_t const now = _world.UnixNow();
        std::vector<WildPlayer> const players = Sorted(_world.Players());
        double const leave = _settings.leave;
        std::vector<uint64_t> keys;
        for (auto const& [key, pet] : _pets)
            keys.push_back(key);
        for (uint64_t key : keys)
        {
            auto const found = _pets.find(key);
            if (found == _pets.end())
                continue;
            Pet& pet = found->second;
            std::optional<Spot> const live = _world.Where(key);
            if (live)
            {
                pet.x = live->x;
                pet.y = live->y;
            }
            bool near = false;
            for (WildPlayer const& player : players)
                if (player.map == pet.map && Squared(player.x - pet.x, player.y - pet.y) < leave * leave)
                {
                    near = true;
                    break;
                }
            if (near)
                pet.away.reset();
            else if (!pet.away)
                pet.away = now;
            bool const gone = pet.away && now - *pet.away >= _settings.awayGraceSeconds;
            if (gone || now - pet.born > _settings.lifetimeSeconds || !live)
                Remove(key, false, false);
        }
        for (WildPlayer const& player : players)
            if (player.scans)
                Scan(player, now);
    }

    void Registry::Blips()
    {
        double const spacing = _settings.spacing;
        double const reach = spacing + 40;
        for (WildPlayer const& player : Sorted(_world.Players()))
        {
            std::string parts;
            uint32_t count = 0;
            for (auto& [key, pet] : _pets)
            {
                double dx = pet.x - player.x;
                double dy = pet.y - player.y;
                if (pet.map == player.map && Squared(dx, dy) < reach * reach)
                    if (std::optional<Spot> const live = _world.Where(key))
                    {
                        pet.x = live->x;
                        pet.y = live->y;
                        dx = pet.x - player.x;
                        dy = pet.y - player.y;
                    }
                if (pet.map == player.map && Squared(dx, dy) < spacing * spacing && count < _settings.maxArea + 2)
                {
                    if (count++)
                        parts += ";";
                    parts += std::to_string(static_cast<long long>(std::floor(dx + 0.5))) + "," +
                        std::to_string(static_cast<long long>(std::floor(dy + 0.5))) + "," +
                        std::to_string(pet.species) + "," + std::to_string(pet.level ? pet.level : 1) + "," +
                        NameOf(pet.species);
                }
            }
            if (count)
            {
                _world.Send(player.character, "pbw", "pets", parts);
                _hadBlips.insert(player.character);
            }
            else if (_hadBlips.erase(player.character))
                _world.Send(player.character, "pbw", "pets", "none");
        }
    }

    std::optional<std::string> Registry::Hello(uint64_t key) const
    {
        auto const found = _pets.find(key);
        if (found == _pets.end())
            return std::nullopt;
        return "Challenge " + NameOf(found->second.species) + " to a pet battle";
    }

    std::vector<uint32_t> Registry::ZonePool(uint32_t zone) const
    {
        std::vector<uint32_t> pool;
        if (!_data.zones.count(zone))
            return pool;
        for (ZoneSpecies const& row : _data.zoneSpecies)
            if (row.zone == zone)
                pool.push_back(row.species);
        return pool;
    }

    std::vector<Battle::EnemySpec> Registry::BuildEnemies(Pet const& pet)
    {
        uint8_t const level = PetLevelOf(pet);
        std::vector<Battle::EnemySpec> team;
        Battle::EnemySpec first;
        first.species = pet.species;
        first.level = level;
        first.display = pet.display;
        first.quality = Engine::RollQuality(*_catalog, _rng);
        first.breed = Engine::RollBreed(*_catalog, first.species, _rng);
        team.push_back(first);
        if (level <= _settings.soloMaxLevel)
            return team;
        std::vector<uint32_t> pool = ZonePool(pet.zone);
        if (pool.empty())
            pool = pet.types.empty() ? std::vector<uint32_t> { pet.species } : pet.types;
        std::vector<uint32_t> candidates;
        for (uint32_t species : pool)
            if (species != pet.species && _data.species.count(species))
                candidates.push_back(species);
        if (candidates.empty())
            candidates.push_back(pet.species);
        for (int i = 0; i < 2; ++i)
        {
            size_t const k = static_cast<size_t>(_rng.Roll(1, static_cast<int32_t>(candidates.size())) - 1);
            Battle::EnemySpec extra;
            extra.species = candidates[k];
            extra.level = level;
            extra.quality = Engine::RollQuality(*_catalog, _rng);
            extra.breed = Engine::RollBreed(*_catalog, extra.species, _rng);
            team.push_back(extra);
            if (candidates.size() > 1)
                candidates.erase(candidates.begin() + static_cast<std::ptrdiff_t>(k));
        }
        return team;
    }

    void Registry::Select(uint64_t character, uint64_t key, uint32_t option, double x, double y)
    {
        if (option != 1)
            return;
        auto const found = _pets.find(key);
        if (found == _pets.end())
            return;
        std::optional<Spot> const where = _world.Where(key);
        if (!where)
            return;
        if (_world.InBattle(character))
        {
            _world.Say(character, "You are already in a pet battle.");
            return;
        }
        double const range = _settings.talkRange;
        if (Squared(x - where->x, y - where->y) > range * range)
        {
            _world.Say(character, "You are too far away from it.");
            return;
        }
        if (_world.StartBattle(character, BuildEnemies(found->second)))
            Remove(key, true, true);
    }

    void Registry::EndAll()
    {
        std::map<uint64_t, Pet> pets;
        pets.swap(_pets);
        for (auto const& [key, pet] : pets)
        {
            if (!_world.Where(key))
                continue;
            if (pet.adopted)
                _world.Release(key);
            else
                _world.Despawn(key);
        }
    }

    std::vector<std::string> Registry::Describe(uint64_t character)
    {
        std::vector<std::string> lines;
        std::optional<WildPlayer> const player = FindPlayer(_world.Players(), character);
        if (!player)
            return lines;
        uint32_t const now = _world.UnixNow();
        double const spacing = _settings.spacing;
        for (auto const& [key, pet] : _pets)
        {
            double const d2 = Squared(pet.x - player->x, pet.y - player->y);
            if (pet.map != player->map || d2 >= spacing * spacing)
                continue;
            lines.push_back(std::to_string(pet.species) + " " + NameOf(pet.species) + " L" +
                std::to_string(PetLevelOf(pet)) + " " + (pet.adopted ? "adopted" : "spawned") + " " +
                std::to_string(static_cast<long long>(std::floor(std::sqrt(d2) + 0.5))) + "yd " +
                std::to_string(now - pet.born) + "s");
        }
        return lines;
    }

    std::optional<uint64_t> Registry::Nearest(uint64_t character, double range)
    {
        std::optional<WildPlayer> const player = FindPlayer(_world.Players(), character);
        if (!player)
            return std::nullopt;
        std::optional<uint64_t> best;
        double bestDistance = range * range;
        for (auto const& [key, pet] : _pets)
        {
            std::optional<Spot> const where = _world.Where(key);
            if (!where || pet.map != player->map)
                continue;
            double const d2 = Squared(where->x - player->x, where->y - player->y);
            if (d2 <= bestDistance)
            {
                best = key;
                bestDistance = d2;
            }
        }
        return best;
    }
}
