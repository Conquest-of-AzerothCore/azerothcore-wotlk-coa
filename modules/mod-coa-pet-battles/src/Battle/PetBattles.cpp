#include "PetBattles.h"
#include "CellImpl.h"
#include "Creature.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "PetBattleDataStore.h"
#include "Player.h"
#include "Protocol/AddonChannel.h"
#include "Store/PetJournalStore.h"
#include "TemporarySummon.h"
#include "World.h"
#include "WorldSession.h"
#include <cmath>
#include <random>

namespace CoAPetBattles::Battle
{
    namespace
    {
        constexpr float Ahead = 4.5f;
        constexpr float Aside = 2.2f;
        constexpr float Lift = 1.0f;
        constexpr float MaxRange = 40.0f;
        constexpr uint32_t PeacefulFaction = 35;
        constexpr uint32_t StandInHealth = 1000;
        constexpr uint64_t WatchdogMs = 5000;

        struct StandInOf
        {
            Player const* player;

            bool operator()(Creature* creature) const
            {
                return creature->IsSummon() && creature->ToTempSummon()->GetSummonerGUID() == player->GetGUID() &&
                    creature->GetFaction() == PeacefulFaction && creature->GetMaxHealth() == StandInHealth &&
                    creature->IsInWorld();
            }
        };

        Player* Find(uint64_t character)
        {
            return ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(
                static_cast<ObjectGuid::LowType>(character)));
        }

        uint64_t Character(Player* player)
        {
            return player->GetGUID().GetCounter();
        }

        size_t Index(Side side)
        {
            return side == Side::P ? 0 : 1;
        }
    }

    class ServerWorld : public World
    {
    public:
        struct Place
        {
            uint32_t map = 0;
            float x = 0;
            float y = 0;
            float z = 0;
            std::array<std::array<float, 4>, 2> pets {};
        };

        void Send(uint64_t character, std::string_view module, std::string_view action,
            std::string const& payload) override
        {
            sAddonChannel->Send(Find(character), module, action, payload);
        }

        bool Online(uint64_t character) const override
        {
            Player* player = Find(character);
            return player && player->IsInWorld();
        }

        bool Alive(uint64_t character) const override
        {
            Player* player = Find(character);
            return player && player->IsAlive();
        }

        bool InCombat(uint64_t character) const override
        {
            Player* player = Find(character);
            return player && player->IsInCombat();
        }

        bool Gm(uint64_t character) const override
        {
            Player* player = Find(character);
            return player && player->GetSession() && player->GetSession()->GetSecurity() >= SEC_GAMEMASTER;
        }

        uint32_t Account(uint64_t character) const override
        {
            Player* player = Find(character);
            return player && player->GetSession() ? player->GetSession()->GetAccountId() : 0;
        }

        void MarkOrigin(uint64_t character) override
        {
            Player* player = Find(character);
            if (!player)
                return;
            Place place;
            place.map = player->GetMapId();
            place.x = player->GetPositionX();
            place.y = player->GetPositionY();
            place.z = player->GetPositionZ();
            float const o = player->GetOrientation();
            float const fx = std::cos(o);
            float const fy = std::sin(o);
            float const lx = -std::sin(o);
            float const ly = std::cos(o);
            for (Side side : { Side::P, Side::E })
            {
                float const across = side == Side::P ? Aside : -Aside;
                place.pets[Index(side)] = { place.x + fx * Ahead + lx * across, place.y + fy * Ahead + ly * across,
                    place.z + Lift, 0 };
            }
            for (Side side : { Side::P, Side::E })
            {
                auto& me = place.pets[Index(side)];
                auto const& other = place.pets[Index(Engine::Other(side))];
                float facing = std::atan2(other[1] - me[1], other[0] - me[0]);
                if (facing < 0)
                    facing += 6.2832f;
                me[3] = facing;
            }
            _places[character] = place;
        }

        bool Away(uint64_t character) const override
        {
            Player* player = Find(character);
            auto const place = _places.find(character);
            if (!player || place == _places.end())
                return true;
            return player->GetMapId() != place->second.map ||
                player->GetDistance(place->second.x, place->second.y, place->second.z) > MaxRange;
        }

        std::optional<Spawned> Spawn(uint64_t character, Side side, uint32_t species, uint32_t display) override
        {
            Player* player = Find(character);
            auto const place = _places.find(character);
            if (!player || place == _places.end())
                return std::nullopt;
            uint32_t const standIn = StandInEntry(sPetBattleData->Data(), species);
            uint32_t const entry = standIn ? standIn : species;
            auto const& at = place->second.pets[Index(side)];
            TempSummon* summon = player->SummonCreature(entry, at[0], at[1], at[2], at[3], TEMPSUMMON_MANUAL_DESPAWN);
            if (!summon)
                return std::nullopt;
            summon->SetReactState(REACT_PASSIVE);
            summon->ReplaceAllUnitFlags(UnitFlags(0));
            summon->SetFaction(PeacefulFaction);
            if (display)
                summon->SetDisplayId(display);
            summon->SetMaxHealth(StandInHealth);
            summon->SetHealth(StandInHealth);
            _summons[++_lastHandle] = { character, summon->GetGUID(), summon->GetMapId(), summon->GetInstanceId() };
            return Spawned { _lastHandle, summon->GetDisplayId() };
        }

        void Scale(uint64_t handle, double scale) override
        {
            if (Creature* creature = StandIn(handle))
                creature->SetObjectScale(static_cast<float>(scale));
        }

        void Despawn(uint64_t handle) override
        {
            if (Creature* creature = StandIn(handle))
                creature->DespawnOrUnsummon();
            _summons.erase(handle);
        }

        std::vector<uint32_t> Displays(uint32_t species) const override
        {
            std::vector<uint32_t> displays;
            if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(species))
                for (CreatureModel const& model : creature->Models)
                    displays.push_back(model.CreatureDisplayID);
            return displays;
        }

        uint32_t UnixNow() const override
        {
            return static_cast<uint32_t>(GameTime::GetGameTime().count());
        }

        Store::Journal* JournalOf(uint64_t character) override
        {
            return sPetJournals->For(Find(character));
        }

        void Flush(Store::Journal& journal) override
        {
            sPetJournals->Flush(journal);
        }

        void SyncCompanions(uint64_t character) override
        {
            sPetJournals->SyncCompanions(Find(character));
        }

        size_t StandIns(uint64_t character) const
        {
            Player* player = Find(character);
            if (!player)
                return 0;
            std::list<Creature*> standIns;
            StandInOf check { player };
            Acore::CreatureListSearcher<StandInOf> searcher(player, standIns, check);
            Cell::VisitObjects(player, searcher, MaxRange * 2);
            return standIns.size();
        }

        void Forget(uint64_t character)
        {
            _places.erase(character);
        }

    private:
        struct Summon
        {
            uint64_t character = 0;
            ObjectGuid guid;
            uint32_t map = 0;
            uint32_t instance = 0;
        };

        Creature* StandIn(uint64_t handle) const
        {
            auto const found = _summons.find(handle);
            if (found == _summons.end())
                return nullptr;
            Map* map = sMapMgr->FindMap(found->second.map, found->second.instance);
            return map ? map->GetCreature(found->second.guid) : nullptr;
        }

        std::map<uint64_t, Place> _places;
        std::map<uint64_t, Summon> _summons;
        uint64_t _lastHandle = 0;
    };

    PetBattles* PetBattles::instance()
    {
        static PetBattles battles;
        return &battles;
    }

    PetBattles::PetBattles() : _world(std::make_unique<ServerWorld>()), _rng(std::random_device {}())
    {
        _scheduler.Every(WatchdogMs, [this]
        {
            if (_battles)
                _battles->Watchdog();
        });
    }

    PetBattles::~PetBattles() = default;

    Battles* PetBattles::Current()
    {
        std::shared_ptr<Engine::Catalog const> catalog = sPetBattleData->Catalog();
        if (!sPetBattleData->IsLoaded() || !catalog)
            return nullptr;
        if (catalog != _catalog && _battles)
        {
            _catalog = catalog;
            _battles->UseCatalog(_catalog);
        }
        else if (catalog != _catalog)
        {
            _catalog = catalog;
            _battles = std::make_unique<Battles>(_catalog, sPetBattleData->Data(),
                [](uint32_t species) -> std::optional<std::pair<double, double>>
                {
                    CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(species);
                    if (!creature || creature->Models.empty())
                        return std::nullopt;
                    CreatureModelInfo const* info = sObjectMgr->GetCreatureModelInfo(creature->Models.front().CreatureDisplayID);
                    if (!info)
                        return std::nullopt;
                    return std::make_pair(static_cast<double>(info->bounding_radius),
                        static_cast<double>(info->combat_reach));
                }, *_world, _scheduler, _rng);
        }
        return _battles.get();
    }

    void PetBattles::Update(uint32_t diff)
    {
        _scheduler.RunUntil(_scheduler.Now() + diff);
    }

    void PetBattles::Message(Player* player, std::string const& module, std::string const& action,
        std::string const& payload)
    {
        if (Battles* battles = player ? Current() : nullptr)
            battles->Message(Character(player), module, action, payload);
    }

    bool PetBattles::Challenge(Player* player, std::string const& enemies)
    {
        Battles* battles = player ? Current() : nullptr;
        return battles && battles->Challenge(Character(player), enemies);
    }

    bool PetBattles::StartWild(Player* player, std::vector<EnemySpec> enemies)
    {
        Battles* battles = player ? Current() : nullptr;
        return battles && battles->Start(Character(player), std::move(enemies));
    }

    void PetBattles::Logout(Player* player)
    {
        if (!player)
            return;
        if (_battles && ::World::IsStopped())
            _battles->Abandon(Character(player));
        else if (_battles)
            _battles->Logout(Character(player));
        _world->Forget(Character(player));
    }

    void PetBattles::Shutdown()
    {
        if (_battles)
            _battles->EndAll();
    }

    bool PetBattles::InBattle(Player* player) const
    {
        return player && _battles && _battles->InBattle(Character(player));
    }

    size_t PetBattles::StandIns(Player* player) const
    {
        return player ? _world->StandIns(Character(player)) : 0;
    }
}
