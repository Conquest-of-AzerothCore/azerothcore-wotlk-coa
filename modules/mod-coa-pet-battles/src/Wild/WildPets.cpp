#include "WildPets.h"
#include "Battle/PetBattles.h"
#include "CellImpl.h"
#include "Chat.h"
#include "Creature.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "PetBattleDataStore.h"
#include "Player.h"
#include "Protocol/AddonChannel.h"
#include "ScriptedGossip.h"
#include "TemporarySummon.h"
#include "WorldSession.h"
#include <random>

namespace CoAPetBattles::Wild
{
    namespace
    {
        constexpr uint32_t PeacefulFaction = 35;
        constexpr uint32_t NormalPhase = 1;
        constexpr uint32_t AllPhases = 0x7FFFFFFF;

        uint64_t Character(Player const* player)
        {
            return player->GetGUID().GetCounter();
        }

        Player* Find(uint64_t character)
        {
            return ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(
                static_cast<ObjectGuid::LowType>(character)));
        }

        bool Human(Player const* player)
        {
            return player && player->IsInWorld() && player->GetSession() && !player->GetSession()->IsBot();
        }

        struct SeedCandidate
        {
            Player const* player;
            float range;

            bool operator()(Creature* creature) const
            {
                if (!creature->IsAlive() || creature->IsInCombat() || !creature->GetSpawnId() ||
                    player->GetExactDist(creature) > range)
                    return false;
                auto const& species = sPetBattleData->Data().species;
                auto const found = species.find(creature->GetEntry());
                return found != species.end() && found->second.wild;
            }
        };
    }

    class ServerWildWorld : public WildWorld
    {
    public:
        std::vector<WildPlayer> Players() override
        {
            std::vector<WildPlayer> players;
            for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
            {
                if (!Human(player))
                    continue;
                uint32_t const phase = player->GetPhaseMask();
                bool const scans = player->IsAlive() && !player->IsInCombat() && !sPetBattles->InBattle(player) &&
                    (phase == NormalPhase || phase >= AllPhases) && sPetBattleData->FindZone(player->GetZoneId());
                players.push_back({ Character(player), player->GetMapId(), player->GetZoneId(),
                    player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), scans });
            }
            return players;
        }

        std::vector<RealCreature> RealCreaturesNear(uint64_t character, double range) override
        {
            std::vector<RealCreature> list;
            Player* player = Find(character);
            if (!player)
                return list;
            std::list<Creature*> creatures;
            SeedCandidate check { player, static_cast<float>(range) };
            Acore::CreatureListSearcher<SeedCandidate> searcher(player, creatures, check);
            Cell::VisitObjects(player, searcher, static_cast<float>(range));
            for (Creature* creature : creatures)
                list.push_back({ KeyOf(creature), creature->GetEntry(), creature->GetPositionX(),
                    creature->GetPositionY(), creature->GetPositionZ(), creature->GetLevel() });
            return list;
        }

        std::optional<double> Ground(uint32_t mapId, double x, double y) override
        {
            Map* map = sMapMgr->FindMap(mapId, 0);
            if (!map)
                return std::nullopt;
            float const height = map->GetHeight(NormalPhase, float(x), float(y), MAX_HEIGHT);
            if (height <= INVALID_HEIGHT)
                return std::nullopt;
            return double(height);
        }

        std::optional<SpawnedPet> Spawn(uint32_t species, Spot at, double facing) override
        {
            Map* map = sMapMgr->FindMap(at.map, 0);
            uint32_t const standIn = sPetBattleData->StandInEntry(species);
            if (!map)
            {
                LOG_ERROR("module", "Wild pet {}: map {} is not loaded", species, at.map);
                return std::nullopt;
            }
            TempSummon* summon = map->SummonCreature(standIn ? standIn : species,
                Position(float(at.x), float(at.y), float(at.z), float(facing)));
            if (!summon)
            {
                LOG_ERROR("module", "Wild pet {}: creature {} could not be summoned at {} {} {} on map {}", species,
                    standIn ? standIn : species, at.x, at.y, at.z, at.map);
                return std::nullopt;
            }
            summon->SetReactState(REACT_PASSIVE);
            summon->SetFaction(PeacefulFaction);
            summon->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            summon->SetPhaseMask(NormalPhase, true);
            return SpawnedPet { KeyOf(summon), summon->GetDisplayId() };
        }

        void Scale(uint64_t key, double scale) override
        {
            if (Creature* creature = Resolve(key))
                creature->SetObjectScale(float(scale));
        }

        void Settle(uint64_t key, Spot at) override
        {
            if (Creature* creature = Resolve(key))
                creature->GetMotionMaster()->MovePoint(0, float(at.x), float(at.y), float(at.z));
        }

        void Wander(uint64_t key, double radius) override
        {
            if (Creature* creature = Resolve(key))
            {
                creature->SetWanderDistance(float(radius));
                creature->GetMotionMaster()->MoveRandom(float(radius));
            }
        }

        std::optional<Spot> Where(uint64_t key) override
        {
            Creature* creature = Resolve(key);
            if (!creature)
            {
                Forget(key);
                return std::nullopt;
            }
            return Spot { creature->GetMapId(), creature->GetPositionX(), creature->GetPositionY(),
                creature->GetPositionZ() };
        }

        void Adopt(uint64_t key) override
        {
            if (Creature* creature = Resolve(key))
            {
                creature->SetFaction(PeacefulFaction);
                creature->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            }
        }

        void Release(uint64_t key) override
        {
            if (Creature* creature = Resolve(key))
            {
                CreatureTemplate const* creatureTemplate = creature->GetCreatureTemplate();
                creature->ReplaceAllNpcFlags(NPCFlags(creatureTemplate->npcflag));
                creature->SetFaction(creatureTemplate->faction);
            }
            Forget(key);
        }

        void Despawn(uint64_t key) override
        {
            if (Creature* creature = Resolve(key))
                creature->DespawnOrUnsummon();
            Forget(key);
        }

        void Send(uint64_t character, std::string_view module, std::string_view action,
            std::string const& payload) override
        {
            if (Player* player = Find(character))
                sAddonChannel->Send(player, module, action, payload);
        }

        void Say(uint64_t character, std::string const& text) override
        {
            if (Player* player = Find(character))
                ChatHandler(player->GetSession()).SendSysMessage(text);
        }

        bool StartBattle(uint64_t character, std::vector<Battle::EnemySpec> enemies) override
        {
            Player* player = Find(character);
            return player && sPetBattles->StartWild(player, std::move(enemies));
        }

        uint32_t UnixNow() const override
        {
            return static_cast<uint32_t>(GameTime::GetGameTime().count());
        }

        std::optional<uint64_t> Known(Creature const* creature) const
        {
            auto const found = _keys.find(Identity(creature));
            return found == _keys.end() ? std::nullopt : std::optional(found->second);
        }

    private:
        struct Handle
        {
            uint32_t map = 0;
            uint32_t instance = 0;
            ObjectGuid guid;
        };

        static std::tuple<uint32_t, uint32_t, uint64_t> Identity(Creature const* creature)
        {
            return { creature->GetMapId(), creature->GetInstanceId(), creature->GetGUID().GetRawValue() };
        }

        uint64_t KeyOf(Creature* creature)
        {
            auto const identity = Identity(creature);
            auto const found = _keys.find(identity);
            if (found != _keys.end())
                return found->second;
            uint64_t const key = ++_lastKey;
            _keys[identity] = key;
            _handles[key] = { creature->GetMapId(), creature->GetInstanceId(), creature->GetGUID() };
            return key;
        }

        Creature* Resolve(uint64_t key) const
        {
            auto const found = _handles.find(key);
            if (found == _handles.end())
                return nullptr;
            Map* map = sMapMgr->FindMap(found->second.map, found->second.instance);
            Creature* creature = map ? map->GetCreature(found->second.guid) : nullptr;
            return creature && creature->IsInWorld() ? creature : nullptr;
        }

        void Forget(uint64_t key)
        {
            auto const found = _handles.find(key);
            if (found == _handles.end())
                return;
            _keys.erase({ found->second.map, found->second.instance, found->second.guid.GetRawValue() });
            _handles.erase(found);
        }

    public:
        void Prune(Registry const& registry)
        {
            for (auto it = _handles.begin(); it != _handles.end();)
            {
                if (registry.IsWild(it->first))
                {
                    ++it;
                    continue;
                }
                _keys.erase({ it->second.map, it->second.instance, it->second.guid.GetRawValue() });
                it = _handles.erase(it);
            }
        }

    private:
        std::map<std::tuple<uint32_t, uint32_t, uint64_t>, uint64_t> _keys;
        std::map<uint64_t, Handle> _handles;
        uint64_t _lastKey = 0;
    };

    WildPets* WildPets::instance()
    {
        static WildPets pets;
        return &pets;
    }

    WildPets::WildPets() : _world(std::make_unique<ServerWildWorld>()), _rng(std::random_device {}()) { }

    WildPets::~WildPets() = default;

    Registry* WildPets::Current()
    {
        std::shared_ptr<Engine::Catalog const> catalog = sPetBattleData->Catalog();
        if (!sPetBattleData->IsLoaded() || !catalog)
            return nullptr;
        if (!_registry)
        {
            _scale = std::make_unique<Battle::PetScale>(sPetBattleData->Data(),
                [](uint32_t species) -> std::optional<std::pair<double, double>>
                {
                    CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(species);
                    if (!creature || creature->Models.empty())
                        return std::nullopt;
                    CreatureModelInfo const* info =
                        sObjectMgr->GetCreatureModelInfo(creature->Models.front().CreatureDisplayID);
                    if (!info)
                        return std::nullopt;
                    return std::make_pair(double(info->bounding_radius), double(info->combat_reach));
                });
            _registry = std::make_unique<Registry>(catalog, sPetBattleData->Data(), sPetBattleData->Wild(), *_scale,
                *_world, _rng);
            _catalog = catalog;
        }
        else if (catalog != _catalog)
        {
            _registry->UseCatalog(catalog);
            _catalog = catalog;
        }
        _registry->UseSettings(sPetBattleData->Wild());
        return _registry.get();
    }

    void WildPets::Update(uint32_t diff)
    {
        Registry* registry = Current();
        if (!registry)
            return;
        WildSettings const& settings = sPetBattleData->Wild();
        if (!settings.enabled)
        {
            if (registry->Count())
                registry->EndAll();
            return;
        }
        _sinceTick += diff;
        _sinceBlips += diff;
        if (_sinceTick >= settings.tickMs)
        {
            _sinceTick = 0;
            registry->Tick();
            _world->Prune(*registry);
        }
        if (_sinceBlips >= settings.blipMs)
        {
            _sinceBlips = 0;
            registry->Blips();
        }
    }

    void WildPets::Shutdown()
    {
        if (_registry)
            _registry->EndAll();
    }

    bool WildPets::Hello(Player* player, Creature* creature)
    {
        Registry* registry = Current();
        std::optional<uint64_t> const key = registry ? _world->Known(creature) : std::nullopt;
        std::optional<std::string> const text = key ? registry->Hello(*key) : std::nullopt;
        if (!text)
            return false;
        ClearGossipMenuFor(player);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, *text, GOSSIP_SENDER_MAIN, 1);
        AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Never mind", GOSSIP_SENDER_MAIN, 2);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
        return true;
    }

    bool WildPets::Select(Player* player, Creature* creature, uint32_t action)
    {
        Registry* registry = Current();
        std::optional<uint64_t> const key = registry ? _world->Known(creature) : std::nullopt;
        if (!key || !registry->IsWild(*key))
            return false;
        CloseGossipMenuFor(player);
        registry->Select(Character(player), *key, action, player->GetPositionX(), player->GetPositionY());
        return true;
    }

    std::vector<std::string> WildPets::Describe(Player* player)
    {
        Registry* registry = Current();
        return registry ? registry->Describe(Character(player)) : std::vector<std::string>();
    }

    bool WildPets::ChallengeNearest(Player* player)
    {
        Registry* registry = Current();
        std::optional<uint64_t> const key =
            registry ? registry->Nearest(Character(player), registry->Config().spacing) : std::nullopt;
        std::optional<Spot> const at = key ? registry->Location(*key) : std::nullopt;
        if (!at)
            return false;
        player->NearTeleportTo(float(at->x), float(at->y), float(at->z), player->GetOrientation());
        registry->Select(Character(player), *key, 1, at->x, at->y);
        return true;
    }

    size_t WildPets::Count()
    {
        Registry* registry = Current();
        return registry ? registry->Count() : 0;
    }
}
