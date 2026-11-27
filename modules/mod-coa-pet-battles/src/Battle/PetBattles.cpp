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
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "PetBattleDataStore.h"
#include "Present/Packets.h"
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
        constexpr float LungeGap = 1.1f;
        constexpr float JumpSpeedXY = 9.0f;
        constexpr float JumpSpeedZ = 2.5f;
        constexpr uint32_t PrimeGuardSeconds = 5;
        constexpr int32_t FoodCategory = 11;
        constexpr uint32_t CrateObject = 193761;
        constexpr float CrateScale = 3.6f;
        constexpr uint32_t NormalPhase = 1;
        constexpr uint32_t AllPhases = 0x7FFFFFFF;
        constexpr float FollowBehind = 2.0f;
        constexpr float FollowAside = 1.0f;
        constexpr float FollowLeave = 22.0f;
        constexpr float FollowRefollow = 4.0f;
        constexpr float FollowDistance = 1.8f;
        constexpr float FollowAngle = 2.6f;
        constexpr float FollowMinRate = 1.4f;
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
            summon->SetRegeneratingHealth(false);
            _summons[++_lastHandle] = { character, side, summon->GetGUID(), summon->GetMapId(),
                summon->GetInstanceId() };
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

        void FlushRelease(Store::Journal& journal, std::function<void(bool)> complete) override
        {
            sPetJournals->Flush(journal, std::move(complete));
        }

        void SyncCompanions(uint64_t character) override
        {
            sPetJournals->SyncCompanions(Find(character));
        }

        void Show(uint64_t handle, uint64_t other, Cue const& cue) override
        {
            auto const record = _summons.find(handle);
            if (cue.kind == CueKind::Uncrate)
            {
                RemoveCrate(cue.character);
                return;
            }
            Creature* creature = StandIn(handle);
            if (!creature || record == _summons.end())
                return;
            auto const place = _places.find(record->second.character);
            switch (cue.kind)
            {
                case CueKind::Cast:
                {
                    Creature* target = other ? StandIn(other) : nullptr;
                    Present::SendVisualCast(creature, target ? target : creature, cue.value);
                    break;
                }
                case CueKind::Effect:
                    Present::SendVisualCast(creature, creature, cue.value);
                    break;
                case CueKind::Aura:
                case CueKind::Unaura:
                    Present::SendVisualAura(creature, cue.value, cue.kind == CueKind::Aura);
                    break;
                case CueKind::Emote:
                    creature->HandleEmoteCommand(cue.value);
                    break;
                case CueKind::Face:
                    if (place != _places.end())
                        creature->SetFacingTo(place->second.pets[Index(record->second.side)][3]);
                    break;
                case CueKind::Lunge:
                    if (Creature* target = Opponent(record->second))
                    {
                        float const dx = target->GetPositionX() - creature->GetPositionX();
                        float const dy = target->GetPositionY() - creature->GetPositionY();
                        float const distance = std::sqrt(dx * dx + dy * dy);
                        if (distance >= 0.1f)
                        {
                            float const k = std::max(0.0f, distance - LungeGap) / distance;
                            creature->GetMotionMaster()->MovePoint(0, creature->GetPositionX() + dx * k,
                                creature->GetPositionY() + dy * k, target->GetPositionZ());
                        }
                    }
                    break;
                case CueKind::Back:
                case CueKind::Jump:
                    if (place != _places.end())
                    {
                        auto const& home = place->second.pets[Index(record->second.side)];
                        if (cue.kind == CueKind::Jump)
                            creature->GetMotionMaster()->MoveJump(home[0], home[1], home[2], JumpSpeedXY, JumpSpeedZ);
                        else
                            creature->GetMotionMaster()->MovePoint(0, home[0], home[1], home[2]);
                    }
                    break;
                case CueKind::Health:
                    creature->SetMaxHealth(StandInHealth);
                    creature->SetHealth(std::max<uint32_t>(1, std::min<uint32_t>(cue.value, StandInHealth)));
                    break;
                case CueKind::Crate:
                    PlaceCrate(record->second.character, creature);
                    break;
                case CueKind::Uncrate:
                    break;
            }
        }

        void Prime(uint64_t character, uint32_t entry, uint32_t species, uint32_t display) override
        {
            if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(species))
                Present::SendCreatureRecord(Find(character), *creature, entry, display);
        }

        std::optional<uint32_t> PrimeAll(uint64_t character) override
        {
            Player* player = Find(character);
            if (!player)
                return std::nullopt;
            uint32_t const now = UnixNow();
            auto const last = _primed.find(character);
            if (last != _primed.end() && now - last->second < PrimeGuardSeconds)
                return std::nullopt;
            _primed[character] = now;
            Store::Journal* journal = sPetJournals->For(player);
            uint32_t count = 0;
            for (auto const& [species, row] : sPetBattleData->Data().species)
                if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(species))
                {
                    ++count;
                    Store::OwnedPet const* owned = journal ? journal->PetOfSpecies(species) : nullptr;
                    Present::SendCreatureRecord(player, *creature, species, owned ? owned->display : 0);
                }
            return count;
        }

        std::optional<uint8_t> FoodLevel(uint32_t item) override
        {
            ItemTemplate const* food = sObjectMgr->GetItemTemplate(item);
            if (!food || food->Class != ITEM_CLASS_CONSUMABLE || food->SubClass != ITEM_SUBCLASS_FOOD ||
                food->Spells[0].SpellCategory != FoodCategory)
                return std::nullopt;
            return static_cast<uint8_t>(std::max<uint32_t>(1, std::min<uint32_t>(food->RequiredLevel, 255)));
        }

        bool HasItem(uint64_t character, uint32_t item) override
        {
            Player* player = Find(character);
            return player && player->HasItemCount(item, 1);
        }

        void TakeItem(uint64_t character, uint32_t item) override
        {
            if (Player* player = Find(character))
                player->DestroyItemCount(item, 1, true);
        }

        void Summon(uint64_t character, uint32_t petId) override
        {
            sPetBattles->Followers().Summon(character, petId);
        }
        void Dismiss(uint64_t character) override { sPetBattles->Followers().Dismiss(character); }
        uint32_t Follower(uint64_t character) override
        {
            Store::Journal const* journal = JournalOf(character);
            return journal ? journal->SpeciesForPet(sPetBattles->Followers().Follower(character)) : 0;
        }
        uint32_t FollowerId(uint64_t character) override { return sPetBattles->Followers().Follower(character); }

        void DismissReleasedFollowers(uint32_t account, uint32_t petId) override
        {
            sPetBattles->Followers().DismissMatching(petId, [this, account](uint64_t character)
            {
                return Account(character) == account;
            });
        }
        void Suppress(uint64_t character, bool on) override { sPetBattles->Followers().Suppress(character, on); }

        void Refused(uint64_t character, std::string const& command) override
        {
            LOG_INFO("module", "Pet battle: character {} sent '{}', which is not offered; the turn is sent again",
                character, command.substr(0, 40));
        }

        uint32_t SweepStandIns(uint64_t character, float yards) override
        {
            Player* player = Find(character);
            if (!player)
                return 0;
            std::list<Creature*> standIns;
            StandInOf check { player };
            Acore::CreatureListSearcher<StandInOf> searcher(player, standIns, check);
            Cell::VisitObjects(player, searcher, yards);
            uint32_t removed = 0;
            for (Creature* creature : standIns)
            {
                if (Tracked(creature->GetGUID()) || sPetBattles->IsFollower(creature->GetGUID()))
                    continue;
                creature->DespawnOrUnsummon();
                ++removed;
            }
            return removed;
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
            _primed.erase(character);
            RemoveCrate(character);
        }

    private:
        struct StandInRecord
        {
            uint64_t character = 0;
            Side side = Side::P;
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

        Creature* Opponent(StandInRecord const& record) const
        {
            for (auto const& [handle, other] : _summons)
                if (other.character == record.character && other.side != record.side)
                    return StandIn(handle);
            return nullptr;
        }

        bool Tracked(ObjectGuid guid) const
        {
            for (auto const& [handle, record] : _summons)
                if (record.guid == guid)
                    return true;
            return false;
        }

        void PlaceCrate(uint64_t character, Creature* over)
        {
            RemoveCrate(character);
            GameObject* crate = over->GetMap()->SummonGameObject(CrateObject, over->GetPositionX(),
                over->GetPositionY(), over->GetPositionZ(), over->GetOrientation(), 0, 0, 0, 0, 0);
            if (!crate)
                return;
            crate->SetObjectScale(CrateScale);
            _crates[character] = { crate->GetGUID(), crate->GetMapId(), crate->GetInstanceId() };
        }

        void RemoveCrate(uint64_t character)
        {
            auto const found = _crates.find(character);
            if (found == _crates.end())
                return;
            if (Map* map = sMapMgr->FindMap(found->second.map, found->second.instance))
                if (GameObject* crate = map->GetGameObject(found->second.guid))
                    crate->DespawnOrUnsummon();
            _crates.erase(found);
        }

        struct CrateRecord
        {
            ObjectGuid guid;
            uint32_t map = 0;
            uint32_t instance = 0;
        };

        std::map<uint64_t, Place> _places;
        std::map<uint64_t, StandInRecord> _summons;
        std::map<uint64_t, CrateRecord> _crates;
        std::map<uint64_t, uint32_t> _primed;
        uint64_t _lastHandle = 0;
    };

    class ServerFollowerWorld : public Follow::FollowerWorld
    {
    public:
        bool Online(uint64_t character) const override
        {
            return Find(character) != nullptr;
        }

        bool Wanted(uint64_t character) const override
        {
            Player* player = Find(character);
            if (!player || !player->IsInWorld() || !player->IsAlive() || player->IsMounted())
                return false;
            uint32_t const phase = player->GetPhaseMask();
            return phase == NormalPhase || phase >= AllPhases;
        }

        bool Owns(uint64_t character, uint32_t petId) const override
        {
            Store::Journal* journal = sPetJournals->For(Find(character));
            return journal && journal->Pet(petId);
        }

        std::optional<uint64_t> SpawnFollower(uint64_t character, uint32_t petId) override
        {
            Player* player = Find(character);
            Store::Journal* journal = sPetJournals->For(player);
            Store::OwnedPet const* pet = journal ? journal->Pet(petId) : nullptr;
            if (!player || !pet)
                return std::nullopt;
            uint32_t const species = pet->species;
            float const o = player->GetOrientation();
            float const x = player->GetPositionX() - std::cos(o) * FollowBehind + std::cos(o + 1.57f) * FollowAside;
            float const y = player->GetPositionY() - std::sin(o) * FollowBehind + std::sin(o + 1.57f) * FollowAside;
            uint32_t const standIn = StandInEntry(sPetBattleData->Data(), species);
            TempSummon* summon = player->SummonCreature(standIn ? standIn : species, x, y, player->GetPositionZ(), o,
                TEMPSUMMON_MANUAL_DESPAWN);
            if (!summon)
                return std::nullopt;
            summon->SetReactState(REACT_PASSIVE);
            summon->SetFaction(PeacefulFaction);
            uint32_t display = pet->display;
            if (display)
                summon->SetDisplayId(display);
            else if ((display = summon->GetDisplayId()) && journal->SetDisplayOnce(petId, display))
            {
                sPetJournals->Flush(*journal);
                if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(species))
                    Present::SendCreatureRecord(player, *creature, species, display);
            }
            if (Battles* battles = sPetBattles->Registry())
                summon->SetObjectScale(static_cast<float>(battles->GetScale().ScaleOf(species, display)));
            summon->SetPhaseMask(NormalPhase, true);
            _followers[++_lastHandle] = { summon->GetGUID(), summon->GetMapId(), summon->GetInstanceId() };
            return _lastHandle;
        }

        void DespawnFollower(uint64_t handle) override
        {
            if (Creature* creature = Resolve(handle))
                creature->DespawnOrUnsummon();
            _followers.erase(handle);
        }

        bool Near(uint64_t character, uint64_t handle) const override
        {
            Player* player = Find(character);
            Creature* creature = Resolve(handle);
            return player && creature && creature->GetMapId() == player->GetMapId() &&
                player->GetDistance(creature) <= FollowLeave;
        }

        void Pace(uint64_t character, uint64_t handle) override
        {
            Player* player = Find(character);
            Creature* creature = Resolve(handle);
            if (!player || !creature)
                return;
            creature->SetSpeed(MOVE_RUN, std::max(FollowMinRate, player->GetSpeed(MOVE_RUN) / 7.0f * 1.3f), true);
            if (creature->GetMotionMaster()->GetCurrentMovementGeneratorType() != FOLLOW_MOTION_TYPE ||
                player->GetDistance(creature) > FollowRefollow)
                creature->GetMotionMaster()->MoveFollow(player, FollowDistance, FollowAngle, MOTION_SLOT_ACTIVE, false,
                    false);
        }

        void SendFollow(uint64_t character, uint32_t petId) override
        {
            if (Player* player = Find(character))
                if (Store::Journal* journal = sPetJournals->For(player))
                {
                    Battles const* battles = sPetBattles->Registry();
                    bool const ownedIds = battles && battles->UsesOwnedIds(character);
                    sAddonChannel->Send(player, "pbj", ownedIds ? "follow2" : "follow",
                        std::to_string(ownedIds ? petId : journal->SpeciesForPet(petId)));
                }
        }

        void Save(uint64_t character, uint32_t petId) override
        {
            if (petId)
            {
                Store::Journal const* journal = sPetJournals->For(Find(character));
                if (!journal)
                    return;
                CharacterDatabase.Execute("INSERT INTO `coa_pet_follower` (`guid`, `pet_id`) SELECT {}, {} "
                    "WHERE NOT EXISTS (SELECT 1 FROM `coa_pet_journal` "
                    "WHERE `account` = {} AND `pet_id` = {} AND `source` = {}) "
                    "ON DUPLICATE KEY UPDATE `pet_id` = VALUES(`pet_id`)", character, petId, journal->Account(),
                    petId, static_cast<uint8_t>(Store::PetSource::Released));
            }
            else
                CharacterDatabase.Execute("DELETE FROM `coa_pet_follower` WHERE `guid` = {}", character);
        }

        std::optional<uint32_t> Saved(uint64_t character) override
        {
            QueryResult result = CharacterDatabase.Query("SELECT `pet_id` FROM `coa_pet_follower` WHERE `guid` = {}",
                character);
            if (!result)
                return std::nullopt;
            return (*result)[0].Get<uint32>();
        }

        bool Holds(ObjectGuid guid) const
        {
            for (auto const& [handle, record] : _followers)
                if (record.guid == guid)
                    return true;
            return false;
        }

    private:
        struct Record
        {
            ObjectGuid guid;
            uint32_t map = 0;
            uint32_t instance = 0;
        };

        Creature* Resolve(uint64_t handle) const
        {
            auto const found = _followers.find(handle);
            if (found == _followers.end())
                return nullptr;
            Map* map = sMapMgr->FindMap(found->second.map, found->second.instance);
            Creature* creature = map ? map->GetCreature(found->second.guid) : nullptr;
            return creature && creature->IsInWorld() ? creature : nullptr;
        }

        std::map<uint64_t, Record> _followers;
        uint64_t _lastHandle = 0;
    };

    PetBattles* PetBattles::instance()
    {
        static PetBattles battles;
        return &battles;
    }

    PetBattles::PetBattles() : _world(std::make_unique<ServerWorld>()),
        _followerWorld(std::make_unique<ServerFollowerWorld>()),
        _followers(std::make_unique<Follow::Registry>(*_followerWorld, _scheduler)), _rng(std::random_device {}())
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

    Follow::Registry& PetBattles::Followers()
    {
        return *_followers;
    }

    Battles* PetBattles::Registry()
    {
        return Current();
    }

    bool PetBattles::IsFollower(ObjectGuid guid) const
    {
        return _followerWorld->Holds(guid);
    }

    void PetBattles::Login(Player* player)
    {
        if (player && player->GetSession() && !player->GetSession()->IsBot())
            _followers->Login(Character(player));
    }

    void PetBattles::Logout(Player* player)
    {
        if (!player)
            return;
        _followers->Logout(Character(player));
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
