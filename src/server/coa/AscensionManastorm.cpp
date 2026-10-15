/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionManastorm.h"
#include "AscensionManastormData.h"
#include "AscensionManastormProtocol.h"
#include "AscensionManastormRules.h"
#include "AscensionManastormGadgets.h"
#include "AllSpellScript.h"
#include "AllCreatureScript.h"
#include "AllMapScript.h"
#include "Bag.h"
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "DatabaseEnv.h"
#include "EventMap.h"
#include "GameObject.h"
#include "GameTime.h"
#include "GossipDef.h"
#include "GlobalScript.h"
#include "Group.h"
#include "InstanceScript.h"
#include "Item.h"
#include "ItemScript.h"
#include "Log.h"
#include "LootMgr.h"
#include "Mail.h"
#include "MailMgr.h"
#include "Map.h"
#include "MapMgr.h"
#include "ModelIgnoreFlags.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptedGossip.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Spell.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "TemporarySummon.h"
#include "UnitScript.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldScript.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <deque>
#include <list>
#include <map>
#include <mutex>
#include <set>
#include <string_view>

namespace
{
    using namespace Ascension::Manastorm;
    using namespace Acore::ChatCommands;
    constexpr uint32 GuideEntry = 80919;
    constexpr uint32 SafetyBubble = 93306;
    constexpr uint32 SafetyBubbleHelper = 93307;
    constexpr uint32 LinkSpell = 93459;
    constexpr uint32 HeartyHeal = 93312;
    constexpr uint32 Leeching = 93344;
    constexpr uint32 UnrelentingSpeed = 93353;
    constexpr uint32 TribalFury = 93422;
    constexpr uint32 PortalAura = 93338;
    constexpr uint32 EventProgressRefresh = 1;
    constexpr uint32 EventCacheDelivery = 2;
    constexpr std::array<uint32, 3> StarterItems = {254041, 97895, 254042};

    struct Request
    {
        uint64 token;
        uint16 opcode;
        uint32 depth;
        uint32 spell = 0;
    };

    struct RewardMail
    {
        Mail mail{};
        std::vector<std::unique_ptr<Item>> items;
    };

    struct Encounter
    {
        Phase phase = Phase::Idle;
        uint32 depth = 0;
        uint32 instanceId = 0;
        uint32 level = 0;
        uint32 bossBaseHealth = 0;
        uint32 guideAction = 0;
        uint32 sceneIndex = 0;
        uint8 mode = 0;
        uint32 bonusCaches = 0;
        uint32 resurrectionCharges = 5;
        bool treasureSpawned = false;
        ObjectGuid treasure;
        std::map<ObjectGuid, float> enemyDamage;
        std::map<ObjectGuid, time_t> hearts;
        ObjectGuid boss;
        ObjectGuid guide;
        ObjectGuid portal;
        std::set<ObjectGuid> portalArmed;
        std::set<ObjectGuid> guards;
        time_t transferStarted = 0;
        bool initialized = false;
        ObjectGuid owner;
        std::set<ObjectGuid> members;
        uint32 pendingCommits = 0;
        bool finished = false;
    };

    struct Run
    {
        std::shared_ptr<Encounter> encounter = std::make_shared<Encounter>();
        bool needsTransfer = false;
        uint64 token = 0;
        Progress progress;
        uint32 pendingXP = 0;
        bool awardingXP = false;
        bool xpClaimPending = false;
        bool cachesPending = false;
        bool cacheSpaceWarning = false;
        std::array<uint32, LoadoutSlots> slots{};
        std::array<uint32, 8> pity{};
        std::array<uint32, 8> caches{};
        WorldLocation returnLocation;
        EventMap uiEvents;
        time_t lastSeen = 0;
        time_t lastRequest = 0;
        bool databaseReady = false;
        bool commitReady = false;
        bool commitSucceeded = false;
        bool progressDirty = false;
        bool loadoutDirty = false;
        bool loadoutPending = false;
        uint32 pendingSlot = 0;
        char const* slotResult = nullptr;
        Scene const& GetScene() const { return Scenes.at(encounter->sceneIndex); }
        uint32 MaxCompleted() const { return progress[encounter->mode].empty() ? 0 : progress[encounter->mode].back(); }
    };

    class ManastormService
    {
    public:
        static ManastormService& Get()
        {
            static ManastormService service;
            return service;
        }

        void Configure()
        {
            enabled.store(sConfigMgr->GetOption<bool>("Ascension.Manastorm.Enable", false));
        }

        void ValidateScenes()
        {
            if (!enabled.load())
                return;
            for (uint32 i = 0; i < Scenes.size(); ++i)
            {
                Scene const& scene = Scenes[i];
                Map* map = sMapMgr->CreateBaseMap(scene.map);
                if (!map || !map->IsNonRaidDungeon())
                    continue;
                auto valid = [map](Spawn const& spawn)
                {
                    if (!spawn.entry)
                        return true;
                    float const ground = map->GetHeight(PHASEMASK_NORMAL, spawn.x, spawn.y, spawn.z + 2, true, 10);
                    return sObjectMgr->GetCreatureTemplate(spawn.entry) && std::isfinite(ground)
                        && std::abs(ground - spawn.z) <= 4;
                };
                if (!valid(scene.entrance) || !valid(scene.boss)
                    || !std::all_of(scene.guards.begin(), scene.guards.end(), valid))
                    continue;
                std::vector<Spawn> points = {scene.entrance, scene.boss};
                for (Spawn const& guard : scene.guards)
                    if (guard.entry)
                        points.push_back(guard);
                std::vector<bool> reachable(points.size(), false);
                reachable[0] = true;
                for (std::size_t pass = 0; pass < points.size(); ++pass)
                    for (std::size_t a = 0; a < points.size(); ++a)
                        for (std::size_t b = 0; b < points.size(); ++b)
                            if (reachable[a] && !reachable[b])
                            {
                                Spawn const& from = points[a];
                                Spawn const& to = points[b];
                                float const distance = std::hypot(from.x - to.x, from.y - to.y);
                                if (distance > 70 || !map->isInLineOfSight(from.x, from.y, from.z + 1.5f,
                                    to.x, to.y, to.z + 1.5f, PHASEMASK_NORMAL, LINEOFSIGHT_ALL_CHECKS,
                                    VMAP::ModelIgnoreFlags::Nothing))
                                    continue;
                                bool walkable = true;
                                uint32 const steps = uint32(distance / 4) + 1;
                                for (uint32 step = 1; step < steps; ++step)
                                {
                                    float const t = float(step) / steps;
                                    float const z = from.z + (to.z - from.z) * t;
                                    float const ground = map->GetHeight(PHASEMASK_NORMAL,
                                        from.x + (to.x - from.x) * t, from.y + (to.y - from.y) * t, z + 2, true, 10);
                                    if (!std::isfinite(ground) || std::abs(ground - z) > 3)
                                    {
                                        walkable = false;
                                        break;
                                    }
                                }
                                if (walkable)
                                    reachable[b] = true;
                            }
                if (std::all_of(reachable.begin(), reachable.end(), [](bool value) { return value; }))
                    validScenes.push_back(i);
            }
            LOG_INFO("coa", "Manastorm: {} of {} scenes have available templates and geometry",
                validScenes.size(), Scenes.size());
            uint32 const opening = uint32(std::count_if(validScenes.begin(), validScenes.end(), [](uint32 index)
            {
                return Scenes[index].unlock == 1;
            }));
            LOG_INFO("coa", "Manastorm: {} validated opening rooms", opening);
            if (!opening)
            {
                enabled.store(false);
                LOG_ERROR("coa", "Manastorm disabled: no reachable opening room is installed");
            }
        }

        bool IsAwardingXP(Player const* player)
        {
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            return itr != runs.end() && itr->second.awardingXP;
        }

        SpellCastResult CheckUtility(Player* player, uint32 spell)
        {
            Gadget const* gadget = FindGadget(spell);
            if (!gadget && spell != 254440 && spell != 93309 && spell != 93311)
                return SPELL_CAST_OK;
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr == runs.end() || !OwnsScene(player, itr->second))
                return SPELL_FAILED_NOT_HERE;
            Run const& run = itr->second;
            if (run.encounter->phase != Phase::Preparing && run.encounter->phase != Phase::Running && run.encounter->phase != Phase::Completed)
                return SPELL_FAILED_NOT_READY;
            if (spell == 93309 && (!run.encounter->resurrectionCharges || player->IsInCombat()))
                return player->IsInCombat() ? SPELL_FAILED_AFFECTING_COMBAT : SPELL_FAILED_NO_CHARGES_REMAIN;
            if (gadget && !gadget->passive && (!player->HasSpell(spell)
                || std::find(run.slots.begin(), run.slots.end(), spell) == run.slots.end()))
                return SPELL_FAILED_NOT_READY;
            return SPELL_CAST_OK;
        }

        void UsedResurrection(Player* player)
        {
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr != runs.end() && OwnsScene(player, itr->second) && itr->second.encounter->resurrectionCharges)
                --itr->second.encounter->resurrectionCharges;
        }

        bool Queue(WorldSession* session, WorldPacket const& packet)
        {
            uint16 const opcode = packet.GetOpcode();
            if (opcode != Enter && opcode != Leave && opcode != SetSlot)
                return false;
            uint64 const token = session->GetScriptPacketToken();
            if (!token || !enabled.load())
                return true;
            if ((opcode == Enter && packet.size() != 4) || (opcode == Leave && packet.size() != 0)
                || (opcode == SetSlot && packet.size() != 8))
                return true;
            uint32 const depth = opcode != Leave ? packet.read<uint32>(0) : 0;
            uint32 const spell = opcode == SetSlot ? packet.read<uint32>(4) : 0;
            std::lock_guard<std::mutex> lock(queueMutex);
            auto& queue = requests[session->GetAccountId()];
            if (queue.size() < MaxQueuedRequests)
                queue.push_back({token, opcode, depth, spell});
            return true;
        }

        void Login(Player* player)
        {
            if (!enabled.load())
                return;
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto& run = runs[player->GetGUID()];
            run.token = ++nextToken;
            run.uiEvents.Reset();
            run.uiEvents.ScheduleEvent(EventProgressRefresh, 2s);
            run.cachesPending = true;
            run.cacheSpaceWarning = false;
            run.uiEvents.ScheduleEvent(EventCacheDelivery, 250ms);
            player->GetSession()->SetScriptPacketToken(run.token);
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_CLEARS);
            statement->SetData(0, player->GetGUID().GetCounter());
            PreparedQueryResult result = CharacterDatabase.Query(statement);
            run.progress = {};
            run.databaseReady = false;
            if (result)
            {
                do
                {
                    Field* fields = result->Fetch();
                    uint8 const mode = fields[0].Get<uint8>();
                    uint32 const depth = fields[1].Get<uint32>();
                    if (mode == 255 && !depth)
                        run.databaseReady = true;
                    else if (mode < run.progress.size() && depth)
                        run.progress[mode].push_back(depth);
                } while (result->NextRow());
            }
            SendProgress(player, run, true);
            run.progressDirty = run.databaseReady;
            LoadBonusAndSlots(player, run);
            SendLoadout(player, run);

            if (run.encounter->depth && run.encounter->instanceId && GameTime::GetGameTime().count() - run.lastSeen <= ReconnectSeconds)
            {
                Map* map = sMapMgr->FindMap(run.GetScene().map, run.encounter->instanceId);
                if (map && map->IsScriptedPrivateInstance()
                    && map->ToInstanceMap()->IsScriptedPrivateMember(player->GetGUID())
                    && run.encounter->phase != Phase::Failed && run.encounter->phase != Phase::Leaving)
                {
                    player->PrepareScriptedPrivateInstance(run.GetScene().map, run.returnLocation, run.encounter->owner, run.encounter->members);
                    player->SetScriptedPrivateInstanceId(run.encounter->instanceId);
                    auto const& entry = run.GetScene().entrance;
                    if (player->TeleportTo(run.GetScene().map, entry.x, entry.y, entry.z, entry.o, 0, nullptr, true))
                        return;
                    player->ClearScriptedPrivateInstance();
                }
            }
            ClearUtilities(player);
            run.encounter = std::make_shared<Encounter>();
            run.needsTransfer = false;
            SendActive(player, run);
        }

        void Logout(Player* player)
        {
            player->GetSession()->SetScriptPacketToken(0);
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr != runs.end())
            {
                itr->second.token = 0;
                itr->second.lastSeen = GameTime::GetGameTime().count();
            }
            if (player->GetSession()->IsBot())
                return;
            std::lock_guard<std::mutex> queueLock(queueMutex);
            requests.erase(player->GetSession()->GetAccountId());
        }

        void MapChanged(Player* player)
        {
            if (player->IsBeingTeleported())
                return;
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr == runs.end())
                return;
            Run& run = itr->second;
            if (run.encounter->depth && !OwnsScene(player, run) && run.encounter->phase != Phase::Transferring
                && run.encounter->phase != Phase::Leaving && run.encounter->phase != Phase::Committing)
            {
                ClearBubble(player);
                ClearUtilities(player);
                player->ClearScriptedPrivateInstance();
                run.encounter = std::make_shared<Encounter>();
                run.needsTransfer = false;
                SendActive(player, run);
            }
        }

        void PollTransactions()
        {
            std::lock_guard<std::recursive_mutex> lock(mutex);
            for (auto itr = transactions.begin(); itr != transactions.end();)
            {
                if (itr->InvokeIfReady())
                    itr = transactions.erase(itr);
                else
                    ++itr;
            }
            time_t const now = GameTime::GetGameTime().count();
            for (auto itr = runs.begin(); itr != runs.end();)
            {
                if (!itr->second.token && now - itr->second.lastSeen > ReconnectSeconds
                    && (itr->second.encounter->phase != Phase::Committing || itr->second.commitReady))
                    itr = runs.erase(itr);
                else
                    ++itr;
            }
            for (auto itr = readyMails.begin(); itr != readyMails.end();)
            {
                auto run = runs.find(itr->first);
                if (run == runs.end() || !run->second.token)
                    std::erase_if(itr->second, [now](auto const& mail)
                    {
                        return now - mail->mail.deliver_time > ReconnectSeconds;
                    });
                if (itr->second.empty())
                    itr = readyMails.erase(itr);
                else
                    ++itr;
            }
        }

        void UpdatePlayer(Player* player, uint32 diff)
        {
            if (!enabled.load())
                return;
            std::deque<Request> incoming;
            if (!player->GetSession()->IsBot())
            {
                std::lock_guard<std::mutex> lock(queueMutex);
                auto itr = requests.find(player->GetSession()->GetAccountId());
                if (itr != requests.end())
                {
                    incoming.swap(itr->second);
                    requests.erase(itr);
                }
            }
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr == runs.end())
                return;
            Run& run = itr->second;
            if (run.loadoutDirty)
            {
                run.loadoutDirty = false;
                SendLoadout(player, run);
                if (run.slotResult)
                {
                    WorldPacket result(SetSlotResult, 48);
                    result << run.pendingSlot << run.slotResult;
                    player->SendDirectMessage(&result);
                    WorldPacket update(UpdateSlot, 8);
                    update << run.pendingSlot << run.slots[run.pendingSlot];
                    player->SendDirectMessage(&update);
                    if (std::string_view(run.slotResult) == "SET_MANASTORM_LOADOUT_OK")
                        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::ManastormActiveSlot,
                            run.slots[run.pendingSlot]);
                    run.slotResult = nullptr;
                }
                if (std::all_of(run.slots.begin(), run.slots.end(), [player](uint32 spell)
                    { return spell && player->HasSpell(spell); }))
                    sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::ManastormFullLoadout, 0);
            }
            auto delivered = readyMails.find(player->GetGUID());
            if (delivered != readyMails.end())
            {
                for (auto const& mail : delivered->second)
                    if (!player->GetMail(mail->mail.messageID))
                    {
                        player->AddMail(new Mail(mail->mail));
                        for (auto& item : mail->items)
                            if (item && !player->GetMItem(item->GetGUID().GetCounter()))
                                player->AddMItem(item.release());
                        player->AddNewMailDeliverTime(mail->mail.deliver_time);
                    }
                readyMails.erase(delivered);
            }
            if (run.progressDirty)
            {
                run.progressDirty = false;
                SendProgress(player, run, false);
                for (auto const& depths : run.progress)
                    for (uint32 depth : depths)
                        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::ManastormDepthCleared, depth);
            }
            if (run.databaseReady && run.pendingXP && !run.xpClaimPending && !player->IsBeingTeleported() && player->IsAlive()
                && (run.encounter->phase == Phase::Idle || run.encounter->phase == Phase::Completed))
                ClaimXP(player, run);
            if (run.needsTransfer && run.encounter->instanceId && !player->IsBeingTeleported()
                && run.encounter->phase != Phase::Leaving && !OwnsScene(player, run))
            {
                player->PrepareScriptedPrivateInstance(run.GetScene().map, run.returnLocation,
                    run.encounter->owner, run.encounter->members);
                player->SetScriptedPrivateInstanceId(run.encounter->instanceId);
                Spawn const& entry = run.GetScene().entrance;
                if (!player->TeleportTo(run.GetScene().map, entry.x, entry.y, entry.z, entry.o, 0, nullptr, true))
                    run.encounter->phase = Phase::Leaving;
            }
            if (run.encounter->phase == Phase::Leaving && !player->IsBeingTeleported() && OwnsScene(player, run))
                Exit(player, run);
            if (run.encounter->phase == Phase::Committing && run.commitReady && !player->IsBeingTeleported()
                && !OwnsScene(player, run))
            {
                if (!run.commitSucceeded)
                    ChatHandler(player->GetSession()).SendSysMessage(
                        "Manastorm could not save this clear. No reward was issued.");
                run.commitReady = false;
                ClearBubble(player);
                player->ClearScriptedPrivateInstance();
                run.encounter = std::make_shared<Encounter>();
                run.needsTransfer = false;
                SendActive(player, run);
            }
            run.uiEvents.Update(diff);
            while (uint32 event = run.uiEvents.ExecuteEvent())
            {
                if (event == EventProgressRefresh)
                {
                    SendProgress(player, run, false);
                    run.uiEvents.ScheduleEvent(EventProgressRefresh, 5s);
                }
                else if (event == EventCacheDelivery && run.cachesPending)
                {
                    if (run.databaseReady && !player->IsBeingTeleported() && player->IsInWorld()
                        && !player->IsInCombat() && !run.xpClaimPending)
                        DeliverCaches(player, run);
                    if (run.cachesPending)
                        run.uiEvents.ScheduleEvent(EventCacheDelivery, 2s);
                }
            }
            for (auto const& request : incoming)
            {
                if (request.token != run.token || !player->IsInWorld() || player->IsBeingTeleported())
                    continue;
                time_t const now = GameTime::GetGameTime().count();
                if (now == run.lastRequest)
                    continue;
                run.lastRequest = now;
                if (request.opcode == Enter)
                    Start(player, run, request.depth);
                else if (request.opcode == SetSlot)
                    SetLoadout(player, run, request.depth, request.spell);
                else
                    Exit(player, run);
            }
            if (run.encounter->phase == Phase::Leaving && !player->IsBeingTeleported() && !OwnsScene(player, run))
            {
                ClearStarterItems(player);
                run.encounter = std::make_shared<Encounter>();
                run.needsTransfer = false;
                player->ClearScriptedPrivateInstance();
                SendActive(player, run);
                SendResult(player, LeaveResult, "LEAVE_MANASTORM_OK");
                player->SaveToDB(false, false);
            }
            if (run.encounter->phase == Phase::Transferring && !player->IsBeingTeleported() && !OwnsScene(player, run)
                && GameTime::GetGameTime().count() - run.encounter->transferStarted > 10)
            {
                player->ClearScriptedPrivateInstance();
                run.encounter = std::make_shared<Encounter>();
                run.needsTransfer = false;
                SendActive(player, run);
                SendResult(player, EnterResult, "ENTER_MANASTORM_UNKNOWN");
            }
        }

        bool Command(Player* player, std::string const& action, uint32 depth = 1)
        {
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr == runs.end() || !enabled.load())
            {
                ChatHandler(player->GetSession()).SendSysMessage("Manastorm is not available on this server.");
                return true;
            }
            Run& run = itr->second;
            if (action == "enter")
                Start(player, run, depth);
            else if (action == "leave")
                Exit(player, run);
            else if ((action == "next" || action == "start") && OwnsScene(player, run))
                run.encounter->guideAction = action == "next" ? 2 : 1;
            else
            {
                SendProgress(player, run, true);
                SendActive(player, run);
                ChatHandler(player->GetSession()).PSendSysMessage(
                    "Manastorm: depth {}, completed {}, resurrection charges {}.",
                    run.encounter->depth, run.MaxCompleted(), run.encounter->resurrectionCharges);
            }
            return true;
        }

        void Entered(InstanceMap* map, Player* player)
        {
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr == runs.end() || !map->IsScriptedPrivateMember(player->GetGUID())
                || itr->second.encounter->owner != map->GetScriptedPrivateOwner())
                return;
            Run& run = itr->second;
            run.needsTransfer = false;
            run.encounter->instanceId = map->GetInstanceId();
            if (!run.encounter->initialized)
            {
                run.encounter->guards.clear();
                auto const& scene = run.GetScene();
                Creature* boss = SpawnEnemy(map, scene.boss, run, true);
                if (!boss)
                {
                    FailRun(player, run);
                    return;
                }
                run.encounter->boss = boss->GetGUID();
                for (auto const& spawn : scene.guards)
                    if (spawn.entry)
                    {
                        Creature* guard = SpawnEnemy(map, spawn, run, false);
                        if (!guard)
                        {
                            FailRun(player, run);
                            return;
                        }
                        run.encounter->guards.insert(guard->GetGUID());
                    }
                run.encounter->phase = Phase::Preparing;
                run.encounter->initialized = true;
                auto const& entry = scene.entrance;
                player->CastSpell(entry.x, entry.y, entry.z, SafetyBubble, true);
                SpawnGuide(player, run, entry);
                ChatHandler(player->GetSession()).SendSysMessage(
                    "Manastorm: leave the safety bubble to begin. Defeat the boss; nearby guards empower Chaotic Link.");
            }
            SendActive(player, run);
            if (run.encounter->phase == Phase::Completed)
            {
                WorldPacket completed(CompletedLevel, 4);
                completed << run.encounter->depth;
                player->SendDirectMessage(&completed);
            }
            else if (run.encounter->phase == Phase::Preparing || run.encounter->phase == Phase::Running)
                UpdateLink(player, run);
            SendProgress(player, run, false);
            SendResult(player, EnterResult, "ENTER_MANASTORM_OK");
            sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::ManastormEntered, 0);
            player->SaveToDB(false, false);
        }

        void UpdateInstance(InstanceMap* map, uint32)
        {
            Player* player = FindOwner(map);
            if (!player || !player->IsInWorld())
                return;
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr == runs.end() || !OwnsScene(player, itr->second))
                return;
            Run& run = itr->second;
            if (player->IsBeingTeleported())
                return;
            if (run.encounter->phase == Phase::Committing && !run.encounter->pendingCommits)
            {
                bool failed = false;
                for (ObjectGuid guid : run.encounter->members)
                {
                    auto member = runs.find(guid);
                    if (member != runs.end() && member->second.encounter == run.encounter
                        && member->second.commitReady && !member->second.commitSucceeded)
                        failed = true;
                }
                if (failed)
                {
                    run.encounter->phase = Phase::Failed;
                    ChatHandler(player->GetSession()).SendSysMessage("Manastorm could not save every party reward. "
                        "Successfully saved rewards remain in the mail; return from your saved checkpoint.");
                    FailRun(player, run);
                    return;
                }
                for (auto const& reference : map->GetPlayers())
                    if (Player* member = reference.GetSource())
                        if (auto state = runs.find(member->GetGUID()); state != runs.end()
                            && state->second.encounter == run.encounter && state->second.commitReady)
                        {
                            state->second.commitReady = false;
                            Finish(member, state->second);
                        }
            }
            if (!player->IsAlive())
            {
                FailRun(player, run);
                return;
            }
            if (run.encounter->guideAction == 2)
            {
                run.encounter->guideAction = 0;
                if (CanAdvance(run.encounter->phase, run.encounter->depth))
                    Transfer(player, run, run.encounter->depth + 1);
                return;
            }
            if (run.encounter->phase == Phase::Preparing)
            {
                uint32 arrived = 0;
                for (auto const& reference : map->GetPlayers())
                    if (Player* member = reference.GetSource())
                        if (map->IsScriptedPrivateMember(member->GetGUID()) && !member->IsBeingTeleported())
                            ++arrived;
                if (arrived < run.encounter->members.size())
                {
                    if (GameTime::GetGameTime().count() - run.encounter->transferStarted > 30)
                        FailRun(player, run);
                    return;
                }
                auto const& entry = run.GetScene().entrance;
                bool outside = false;
                for (auto const& reference : map->GetPlayers())
                    if (Player* member = reference.GetSource())
                        outside = outside || (member->IsAlive() && member->GetExactDist(entry.x, entry.y, entry.z) > 8.0f);
                if (run.encounter->guideAction == 1 || outside)
                {
                    run.encounter->guideAction = 0;
                    for (auto const& reference : map->GetPlayers())
                        if (Player* member = reference.GetSource())
                            ClearBubble(member);
                    run.encounter->phase = Phase::Running;
                    if (Creature* boss = map->GetCreature(run.encounter->boss))
                        boss->SetReactState(REACT_AGGRESSIVE);
                    for (auto const& guid : run.encounter->guards)
                        if (Creature* guard = map->GetCreature(guid))
                            guard->SetReactState(REACT_AGGRESSIVE);
                }
            }
            if (run.encounter->phase == Phase::Running)
                for (auto heart = run.encounter->hearts.begin(); heart != run.encounter->hearts.end();)
                {
                    GameObject* object = map->GetGameObject(heart->first);
                    Player* collector = nullptr;
                    for (auto const& reference : map->GetPlayers())
                        if (Player* member = reference.GetSource())
                            if (object && member->IsAlive() && member->IsWithinDistInMap(object, 2.5f))
                            {
                                collector = member;
                                break;
                            }
                    if (!object || collector || heart->second < GameTime::GetGameTime().count())
                    {
                        if (collector)
                            HealFromHeart(collector);
                        if (object)
                            object->Delete();
                        heart = run.encounter->hearts.erase(heart);
                    }
                    else
                        ++heart;
                }
            if (run.encounter->phase == Phase::Completed && CanAdvance(run.encounter->phase, run.encounter->depth))
                if (Creature* portal = map->GetCreature(run.encounter->portal))
                {
                    for (auto const& reference : map->GetPlayers())
                        if (Player* member = reference.GetSource())
                        {
                            float const distance = member->GetExactDist(portal);
                            if (distance > 6.0f)
                                run.encounter->portalArmed.insert(member->GetGUID());
                            else if (run.encounter->portalArmed.contains(member->GetGUID()) && distance <= 2.5f)
                                run.encounter->guideAction = 2;
                        }
                }
        }

        void Death(Unit* unit)
        {
            if (!unit || !unit->IsInWorld() || !unit->FindMap() || !unit->GetMap()->IsScriptedPrivateInstance())
                return;
            InstanceMap* map = unit->GetMap()->ToInstanceMap();
            Player* player = FindOwner(map);
            if (!player)
                return;
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            if (itr == runs.end() || !OwnsScene(player, itr->second))
                return;
            Run& run = itr->second;
            if (run.encounter->phase != Phase::Running || !player->IsAlive())
                return;
            if (unit->GetGUID() == run.encounter->boss)
            {
                run.encounter->phase = Phase::Committing;
                for (auto const& reference : map->GetPlayers())
                    if (Player* member = reference.GetSource())
                        if (auto state = runs.find(member->GetGUID()); state != runs.end()
                            && state->second.encounter == run.encounter)
                            Complete(member, state->second);
            }
            else if (unit->GetGUID() == run.encounter->treasure)
            {
                run.encounter->treasure.Clear();
                run.encounter->bonusCaches += 2;
                ChatHandler(player->GetSession()).SendSysMessage("Treasure Keeper defeated: two additional caches secured.");
            }
            else if (run.encounter->guards.erase(unit->GetGUID()))
            {
                UpdateLink(player, run);
                if (GameObject* heart = map->SummonGameObject(80779, unit->GetPosition(), 0, 0, 0, 1, 60))
                    run.encounter->hearts[heart->GetGUID()] = GameTime::GetGameTime().count() + 60;
                if (!run.encounter->treasureSpawned && roll_chance_f(std::min(10.0f, 2.0f + run.encounter->depth * 0.015f)))
                {
                    run.encounter->treasureSpawned = true;
                    Spawn const spawn{10111377, unit->GetPositionX(), unit->GetPositionY(), unit->GetPositionZ(),
                        unit->GetOrientation()};
                    if (Creature* treasure = SpawnEnemy(map, spawn, run, false))
                    {
                        run.encounter->treasure = treasure->GetGUID();
                        treasure->RemoveAurasDueToSpell(UnrelentingSpeed);
                        treasure->RemoveAurasDueToSpell(Leeching);
                        treasure->RemoveAurasDueToSpell(TribalFury);
                        treasure->SetReactState(REACT_AGGRESSIVE);
                    }
                }
            }
        }

        void Damage(Unit* attacker, Unit* victim, uint32& damage)
        {
            if (!victim || !victim->IsInWorld() || !victim->FindMap() || !victim->GetMap()->IsScriptedPrivateInstance())
                return;
            std::lock_guard<std::recursive_mutex> lock(mutex);
            Player* member = FindOwner(victim->GetMap()->ToInstanceMap());
            if (!member)
                return;
            auto itr = runs.find(member->GetGUID());
            if (itr == runs.end() || itr->second.encounter->instanceId != victim->GetInstanceId())
                return;
            Run const& run = itr->second;
            if (run.encounter->phase != Phase::Running)
                damage = 0;
            else if (attacker)
            {
                auto scale = run.encounter->enemyDamage.find(attacker->GetGUID());
                if (scale != run.encounter->enemyDamage.end())
                    damage = uint32(std::min(50000000.0f, float(damage) * scale->second));
                if (attacker->GetGUID() == run.encounter->boss)
                    damage = uint32(std::min(100000000.0f, float(damage) * LinkedDamage(uint32(run.encounter->guards.size()))));
            }
            if (damage && attacker && attacker->IsAlive() && attacker->HasAura(Leeching)
                && (attacker->GetGUID() == run.encounter->boss || run.encounter->guards.contains(attacker->GetGUID())))
                if (SpellInfo const* info = sSpellMgr->GetSpellInfo(Leeching))
                {
                    uint32 const amount = std::min(damage, victim->GetHealth()) * 30 / 100;
                    HealInfo healInfo(attacker, attacker, amount, info, info->GetSchoolMask());
                    attacker->HealBySpell(healInfo, false);
                }
        }

        bool Gossip(Player* player, Creature* creature, uint32 action)
        {
            std::lock_guard<std::recursive_mutex> lock(mutex);
            auto itr = runs.find(player->GetGUID());
            bool const companion = creature->GetEntry() == GuideEntry && creature->IsSummon()
                && creature->ToTempSummon()->GetSummonerGUID() == player->GetGUID();
            bool const guide = itr != runs.end() && OwnsScene(player, itr->second)
                && creature->GetGUID() == itr->second.encounter->guide;
            if (itr == runs.end() || (!guide && !companion)
                || !player->IsAlive() || player->IsInCombat()
                || !player->IsWithinDistInMap(creature, INTERACTION_DISTANCE))
                return false;
            if (!action || action == 10)
            {
                ClearGossipMenuFor(player);
                if (action == 10)
                {
                    for (uint32 i = 0; i < Gadgets.size(); ++i)
                    {
                        Gadget const& gadget = Gadgets[i];
                        if (player->HasSpell(gadget.spell) || (gadget.previous && !player->HasSpell(gadget.previous))
                            || player->HasItemCount(gadget.item, 1, true))
                            continue;
                        if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(gadget.item))
                            AddGossipItemFor(player, GOSSIP_ICON_VENDOR,
                                item->Name1 + " - " + std::to_string(gadget.cost) + " Bonzo Bolts", GOSSIP_SENDER_MAIN, 100 + i);
                    }
                    if (!player->HasSpell(93418) && !player->HasItemCount(98074, 1, true))
                        AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "Cogsley companion - 10 Bedlam Bullion",
                            GOSSIP_SENDER_MAIN, 20);
                    AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "Exchange 1 Bedlam Bullion for 10 Bonzo Bolts",
                        GOSSIP_SENDER_MAIN, 21);
                    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Back", GOSSIP_SENDER_MAIN, 1);
                    SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
                    return true;
                }
                if (guide && CanAdvance(itr->second.encounter->phase, itr->second.encounter->depth))
                    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Continue the Manastorm", GOSSIP_SENDER_MAIN, 2);
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Collect rewards from the mailbox", GOSSIP_SENDER_MAIN, 4);
                AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "Manastorm potions and upgrades", GOSSIP_SENDER_MAIN, 10);
                AddGossipItemFor(player, GOSSIP_ICON_VENDOR, "Repair equipment and sell items", GOSSIP_SENDER_MAIN, 5);
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Replace missing starter potions", GOSSIP_SENDER_MAIN, 6);
                if (guide)
                    AddGossipItemFor(player, GOSSIP_ICON_CHAT, "Leave the Manastorm", GOSSIP_SENDER_MAIN, 3);
                SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, creature->GetGUID());
            }
            else
            {
                CloseGossipMenuFor(player);
                if (action == 3)
                    Exit(player, itr->second);
                else if (action == 2)
                    itr->second.encounter->guideAction = 2;
                else if (action == 1)
                    Gossip(player, creature, 0);
                else if (action == 4)
                    player->GetSession()->SendShowMailBox(creature->GetGUID());
                else if (action == 5)
                    player->GetSession()->SendListInventory(creature->GetGUID());
                else if (action == 6)
                    GiveStarterItems(player);
                else if (action == 20 && !player->HasSpell(93418) && !player->HasItemCount(98074, 1, true))
                    BuyItem(player, 98074, 1, 1297307, 10);
                else if (action == 21)
                    BuyItem(player, 1297308, 10, 1297307, 1);
                else if (action >= 100 && action - 100 < Gadgets.size())
                {
                    Gadget const& gadget = Gadgets[action - 100];
                    if (!player->HasSpell(gadget.spell) && (!gadget.previous || player->HasSpell(gadget.previous))
                        && !player->HasItemCount(gadget.item, 1, true))
                        BuyItem(player, gadget.item, 1, 1297308, gadget.cost);
                }
            }
            return true;
        }

    private:
        void SpawnGuide(Player* player, Run& run, Spawn const& position)
        {
            if (Creature* previous = player->GetMap()->GetCreature(run.encounter->guide))
                previous->DespawnOrUnsummon();
            if (Creature* guide = player->GetMap()->SummonCreature(GuideEntry,
                Position(position.x, position.y, position.z, position.o)))
            {
                guide->SetFaction(35);
                guide->SetReactState(REACT_PASSIVE);
                guide->ReplaceAllNpcFlags(UNIT_NPC_FLAG_GOSSIP | UNIT_NPC_FLAG_MAILBOX | UNIT_NPC_FLAG_REPAIR
                    | UNIT_NPC_FLAG_VENDOR);
                run.encounter->guide = guide->GetGUID();
            }
        }

        void BuyItem(Player* player, uint32 entry, uint32 count, uint32 currency, uint32 price)
        {
            if (!player->HasItemCount(currency, price))
            {
                ChatHandler(player->GetSession()).SendSysMessage("You do not have enough Manastorm currency.");
                return;
            }
            ItemPosCountVec positions;
            InventoryResult const result = player->CanStoreNewItem(NULL_BAG, NULL_SLOT, positions, entry, count);
            if (result != EQUIP_ERR_OK)
            {
                player->SendEquipError(result, nullptr, nullptr, entry);
                return;
            }
            Item* item = player->StoreNewItem(positions, entry, true);
            if (!item)
                return;
            player->DestroyItemCount(currency, price, true);
            player->SendNewItem(item, count, true, false);
            sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::ManastormPurchase, entry);
            player->SaveToDB(false, false);
        }

        static Gadget const* FindGadget(uint32 spell)
        {
            auto itr = std::find_if(Gadgets.begin(), Gadgets.end(), [spell](Gadget const& gadget)
            {
                return gadget.spell == spell;
            });
            return itr == Gadgets.end() ? nullptr : &*itr;
        }

        void LoadBonusAndSlots(Player* player, Run& run)
        {
            bool bonusReady = false;
            bool slotsReady = false;
            auto* bonus = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_BONUS);
            bonus->SetData(0, player->GetGUID().GetCounter());
            if (PreparedQueryResult result = CharacterDatabase.Query(bonus))
                do
                {
                    Field* fields = result->Fetch();
                    uint8 const mode = fields[0].Get<uint8>();
                    if (mode == 255)
                        bonusReady = true;
                    else if (mode < run.pity.size())
                    {
                        run.pity[mode] = std::min(10000u, fields[1].Get<uint32>());
                        run.caches[mode] = fields[2].Get<uint32>();
                    }
                } while (result->NextRow());
            auto* slots = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_LOADOUT);
            slots->SetData(0, player->GetGUID().GetCounter());
            if (PreparedQueryResult result = CharacterDatabase.Query(slots))
                do
                {
                    Field* fields = result->Fetch();
                    uint8 const slot = fields[0].Get<uint8>();
                    if (slot == 255)
                        slotsReady = true;
                    else if (slot < run.slots.size())
                    {
                        uint32 const spell = fields[1].Get<uint32>();
                        run.slots[slot] = player->HasSpell(spell) && FindGadget(spell) ? spell : 0;
                    }
                } while (result->NextRow());
            auto* xp = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_XP);
            xp->SetData(0, player->GetGUID().GetCounter());
            PreparedQueryResult xpResult = CharacterDatabase.Query(xp);
            if (xpResult)
                run.pendingXP = uint32(std::min<uint64>(xpResult->Fetch()[0].Get<uint64>(), 1000000000));
            run.databaseReady = run.databaseReady && bonusReady && slotsReady && bool(xpResult);
        }

        void ClaimXP(Player* player, Run& run)
        {
            uint32 const amount = run.pendingXP;
            run.pendingXP = 0;
            run.xpClaimPending = true;
            run.awardingXP = true;
            player->GiveXP(amount, nullptr);
            run.awardingXP = false;
            auto transaction = CharacterDatabase.BeginTransaction();
            player->SaveToDB(transaction, false, false);
            auto* claim = CharacterDatabase.GetPreparedStatement(CHAR_CLAIM_MANASTORM_XP);
            claim->SetData(0, amount);
            claim->SetData(1, player->GetGUID().GetCounter());
            transaction->Append(claim);
            ObjectGuid const guid = player->GetGUID();
            uint64 const token = run.token;
            transactions.emplace_back(CharacterDatabase.AsyncCommitTransaction(transaction));
            transactions.back().AfterComplete([this, guid, token](bool success)
            {
                if (auto itr = runs.find(guid); itr != runs.end())
                {
                    itr->second.xpClaimPending = false;
                    if (itr->second.token != token)
                        ReloadXP(guid, itr->second);
                    if (!success)
                    {
                        itr->second.databaseReady = false;
                        LOG_ERROR("coa", "Manastorm XP save failed for {}; relog required", guid.ToString());
                    }
                }
            });
        }

        static bool HasStoredItem(Player* player, Item* item)
        {
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_INVENTORY_ITEM);
            statement->SetData(0, player->GetGUID().GetCounter());
            statement->SetData(1, item->GetGUID().GetCounter());
            PreparedQueryResult result = CharacterDatabase.Query(statement);
            return result && result->Fetch()[0].Get<uint32>() == 1;
        }

        static void AppendCacheStack(Player* player, Item* stack, CharacterDatabaseTransaction transaction)
        {
            uint32 const count = stack->GetCount();
            ItemUpdateState const state = stack->GetState();
            bool const queued = stack->IsInUpdateQueue();
            if (queued)
                stack->RemoveFromUpdateQueueOf(player);
            stack->SetCount(count + 1);
            stack->FSetState(ITEM_CHANGED);
            stack->SaveToDB(transaction);
            stack->SetCount(count);
            stack->FSetState(state);
            if (queued)
                stack->AddToUpdateQueueOf(player);
        }

        void DeliverCaches(Player* player, Run& run)
        {
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_CACHES);
            statement->SetData(0, player->GetGUID().GetCounter());
            PreparedQueryResult result = CharacterDatabase.Query(statement);
            if (!result)
                return;
            bool found = false;
            do
            {
                Field* fields = result->Fetch();
                uint32 const itemGuid = fields[11].Get<uint32>();
                if (!itemGuid)
                    continue;
                found = true;
                uint32 const entry = fields[12].Get<uint32>();
                if (!IsCache(entry) || fields[2].Get<uint32>() != 1)
                {
                    LOG_ERROR("coa", "Invalid pending Manastorm cache {} for {}",
                        itemGuid, player->GetGUID().ToString());
                    return;
                }
                auto item = std::make_unique<Item>();
                if (!item->LoadFromDB(itemGuid, player->GetGUID(), fields, entry))
                    return;
                item->SetState(ITEM_UNCHANGED);
                ItemPosCountVec positions;
                InventoryResult const error = player->CanStoreItem(NULL_BAG, NULL_SLOT, positions, item.get());
                if (error != EQUIP_ERR_OK || positions.size() != 1 || positions.front().count != 1)
                {
                    if (!run.cacheSpaceWarning)
                    {
                        ChatHandler(player->GetSession()).SendSysMessage(
                            "Your Manastorm cache is saved. Free bag space and it will be delivered automatically.");
                        run.cacheSpaceWarning = true;
                    }
                    return;
                }
                uint16 const position = positions.front().pos;
                uint8 const bagSlot = uint8(position >> 8);
                Bag* bag = bagSlot == INVENTORY_SLOT_BAG_0 ? nullptr : player->GetBagByPos(bagSlot);
                if (bagSlot != INVENTORY_SLOT_BAG_0 && (!bag || !HasStoredItem(player, bag)))
                    return;
                Item* stack = player->GetItemByPos(position);
                if (stack && (!HasStoredItem(player, stack) || stack->IsInTrade()))
                    return;
                auto transaction = CharacterDatabase.BeginTransaction();
                if (stack)
                {
                    AppendCacheStack(player, stack, transaction);
                    Item::DeleteFromDB(transaction, itemGuid);
                }
                else
                {
                    auto* inventory = CharacterDatabase.GetPreparedStatement(CHAR_INS_MANASTORM_CACHE_INVENTORY);
                    inventory->SetData(0, player->GetGUID().GetCounter());
                    inventory->SetData(1, bag ? bag->GetGUID().GetCounter() : 0);
                    inventory->SetData(2, uint8(position));
                    inventory->SetData(3, itemGuid);
                    transaction->Append(inventory);
                }
                auto* claim = CharacterDatabase.GetPreparedStatement(CHAR_DEL_MANASTORM_CACHE);
                claim->SetData(0, itemGuid);
                claim->SetData(1, player->GetGUID().GetCounter());
                transaction->Append(claim);
                if (!CharacterDatabase.AsyncCommitTransaction(transaction).m_future.get())
                {
                    LOG_ERROR("coa", "Manastorm cache delivery failed for {}; reward retained",
                        player->GetGUID().ToString());
                    return;
                }
                Item* stored = player->StoreItem(positions, item.release(), true);
                player->ItemAddedQuestCheck(entry, 1);
                player->UpdateAchievementCriteria(ACHIEVEMENT_CRITERIA_TYPE_OWN_ITEM, entry, 1);
                sScriptMgr->OnPlayerStoreNewItem(player, stored, 1);
                player->SendNewItem(stored, 1, true, false);
                run.cacheSpaceWarning = false;
            } while (result->NextRow());
            run.cachesPending = found;
        }

        void ReloadXP(ObjectGuid guid, Run& run)
        {
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_XP);
            statement->SetData(0, guid.GetCounter());
            if (PreparedQueryResult result = CharacterDatabase.Query(statement))
                run.pendingXP = uint32(std::min<uint64>(result->Fetch()[0].Get<uint64>(), 1000000000));
            else
                run.databaseReady = false;
        }

        void SendLoadout(Player* player, Run const& run)
        {
            WorldPacket packet(LoadoutData, 20);
            packet << uint32(run.slots.size());
            for (uint32 spell : run.slots)
                packet << spell;
            player->SendDirectMessage(&packet);
        }

        void SetLoadout(Player* player, Run& run, uint32 slot, uint32 spell)
        {
            char const* error = nullptr;
            Gadget const* gadget = FindGadget(spell);
            if (!run.databaseReady || run.loadoutPending)
                error = "SET_MANASTORM_LOADOUT_UNKNOWN";
            else if (slot >= LoadoutSlots)
                error = "SET_MANASTORM_LOADOUT_OUT_OF_RANGE";
            else if (run.encounter->phase != Phase::Idle)
                error = "SET_MANASTORM_LOADOUT_ACTIVE_MANASTORM";
            else if (spell && (!gadget || gadget->passive))
                error = "SET_MANASTORM_LOADOUT_BAD_SPELL";
            else if (spell && !player->HasSpell(spell))
                error = "SET_MANASTORM_LOADOUT_NOT_KNOWN";
            else if (spell)
            {
                for (Gadget const& other : Gadgets)
                    if (other.family == gadget->family && other.rank > gadget->rank && player->HasSpell(other.spell))
                        error = "SET_MANASTORM_LOADOUT_BAD_RANK";
                for (uint32 i = 0; i < run.slots.size(); ++i)
                    if (i != slot)
                        if (Gadget const* other = FindGadget(run.slots[i]))
                            if (other->family == gadget->family)
                                error = "SET_MANASTORM_LOADOUT_ALREADY_SET";
            }
            if (error)
            {
                WorldPacket packet(SetSlotResult, 64);
                packet << slot << error;
                player->SendDirectMessage(&packet);
                return;
            }
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_REP_MANASTORM_LOADOUT);
            statement->SetData(0, player->GetGUID().GetCounter());
            statement->SetData(1, uint8(slot));
            statement->SetData(2, spell);
            auto transaction = CharacterDatabase.BeginTransaction();
            transaction->Append(statement);
            run.loadoutPending = true;
            ObjectGuid const guid = player->GetGUID();
            transactions.emplace_back(CharacterDatabase.AsyncCommitTransaction(transaction));
            transactions.back().AfterComplete([this, guid, slot, spell](bool success)
            {
                auto itr = runs.find(guid);
                if (itr == runs.end())
                    return;
                Run& state = itr->second;
                if (success)
                    state.slots[slot] = spell;
                state.loadoutPending = false;
                state.loadoutDirty = true;
                state.pendingSlot = slot;
                state.slotResult = success ? "SET_MANASTORM_LOADOUT_OK" : "SET_MANASTORM_LOADOUT_UNKNOWN";
            });
        }

        void GiveStarterItems(Player* player)
        {
            for (uint32 item : StarterItems)
                if (!player->HasItemCount(item, 1, true))
                    if (!player->AddItem(item, 1))
                        ChatHandler(player->GetSession()).SendSysMessage(
                            "Make room in your bags, then ask Cogsley to replace your missing starter potions.");
        }

        void ClearStarterItems(Player* player)
        {
            for (uint32 item : StarterItems)
                player->DestroyItemCount(item, player->GetItemCount(item, true), true);
        }

        void HealFromHeart(Player* player)
        {
            uint32 rank = 0;
            for (Gadget const& gadget : Gadgets)
                if (gadget.passive && player->HasSpell(gadget.spell))
                    rank = std::max(rank, gadget.rank);
            float const ap = std::max(player->GetTotalAttackPowerValue(BASE_ATTACK),
                player->GetTotalAttackPowerValue(RANGED_ATTACK));
            uint32 const heal = uint32((10 + player->GetLevel() * 7
                + player->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_ALL) * 0.13247f + ap * 0.092729f)
                * (1.0f + rank * 0.25f));
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(HeartyHeal))
            {
                HealInfo healInfo(player, player, heal, info, info->GetSchoolMask());
                player->HealBySpell(healInfo, false);
            }
            player->EnergizeBySpell(player, HeartyHeal, player->GetMaxPower(POWER_MANA) * 15 / 100, POWER_MANA);
            player->CastSpell(player, 93394, true);
        }

        Player* FindOwner(InstanceMap* map)
        {
            std::lock_guard<std::recursive_mutex> lock(mutex);
            Player* fallback = nullptr;
            for (auto const& reference : map->GetPlayers())
                if (Player* player = reference.GetSource())
                {
                    auto itr = runs.find(player->GetGUID());
                    if (itr != runs.end() && OwnsScene(player, itr->second))
                    {
                        if (player->IsAlive() && !player->IsBeingTeleported())
                            return player;
                        fallback = player;
                    }
                }
            return fallback;
        }

        bool OwnsScene(Player const* player, Run const& run) const
        {
            Map* map = player->FindMap();
            return map && run.encounter->instanceId && player->GetMapId() == run.GetScene().map
                && player->GetInstanceId() == run.encounter->instanceId
                && map->IsScriptedPrivateInstance()
                && map->ToInstanceMap()->IsScriptedPrivateMember(player->GetGUID())
                && map->ToInstanceMap()->GetScriptedPrivateOwner() == run.encounter->owner;
        }

        void SendResult(Player* player, uint16 opcode, char const* result)
        {
            WorldPacket packet(opcode, 64);
            packet << result;
            player->SendDirectMessage(&packet);
        }

        void SendProgress(Player* player, Run const& run, bool initial)
        {
            WorldPacket packet(initial ? Data : ProgressUpdate, 128);
            if (!initial)
                packet << player->GetGUID().GetRawValue();
            WriteProgress(packet, run.progress);
            if (!initial && player->GetGroup())
                player->GetGroup()->BroadcastPacket(&packet, false);
            else
                player->SendDirectMessage(&packet);
        }

        void SendActive(Player* player, Run const& run)
        {
            bool const active = run.encounter->depth && run.encounter->phase != Phase::Idle && run.encounter->phase != Phase::Leaving;
            WorldPacket packet(ActiveData, 40);
            uint32 const stage = run.encounter->mode >= 4 ? run.GetScene().endgameStage : run.GetScene().stage;
            WriteActive(packet, active ? run.encounter->depth : 0, active ? stage : 0, run.encounter->mode, 0,
                CacheChance(run.pity[run.encounter->mode], std::max(1u, run.encounter->depth), run.encounter->mode >= 4) / 100.0f,
                CacheForLevel(player->GetLevel(), run.encounter->depth, run.encounter->mode >= 4));
            player->SendDirectMessage(&packet);
        }

        void Start(Player* player, Run& run, uint32 depth)
        {
            if (!player->IsInWorld() || !player->FindMap() || player->GetMap()->Instanceable())
            {
                SendResult(player, EnterResult, "ENTER_MANASTORM_UNKNOWN");
                return;
            }
            std::vector<Player*> party;
            Group* group = player->GetGroup();
            if (group && (!group->IsLeader(player->GetGUID()) || group->isRaidGroup() || group->GetMembersCount() > 5))
            {
                SendResult(player, EnterResult, "ENTER_MANASTORM_BAD_GROUP_SIZE");
                return;
            }
            for (auto const& reference : player->GetMap()->GetPlayers())
                if (Player* member = reference.GetSource())
                    if ((member == player || (group && member->GetGroup() == group))
                        && player->IsWithinDistInMap(member, 100.0f))
                        party.push_back(member);
            if (party.size() != (group ? group->GetMembersCount() : 1))
            {
                ChatHandler(player->GetSession()).SendSysMessage("Gather your party within 100 yards before entering.");
                SendResult(player, EnterResult, "ENTER_MANASTORM_BAD_GROUP_SIZE");
                return;
            }
            uint32 maxLevel = 0;
            uint32 minLevel = 255;
            for (Player* member : party)
            {
                maxLevel = std::max(maxLevel, uint32(member->GetLevel()));
                minLevel = std::min(minLevel, uint32(member->GetLevel()));
            }
            for (Player* member : party)
            {
                if (!sScriptMgr->OnPlayerCanEnterManastorm(member))
                {
                    SendResult(player, EnterResult, "ENTER_MANASTORM_UNKNOWN");
                    return;
                }
            }
            uint8 const mode = uint8(std::min<std::size_t>(party.size() - 1, 3)
                + (maxLevel >= std::max(60u, sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)) ? 4 : 0));
            char const* error = nullptr;
            if (minLevel < MinPlayerLevel)
                error = "ENTER_MANASTORM_TOO_LOW_PLAYER_LEVEL";
            else if (maxLevel - minLevel > 10)
                error = "ENTER_MANASTORM_BAD_GROUP_SIZE";
            for (Player* member : party)
            {
                auto itr = runs.find(member->GetGUID());
                if (itr == runs.end() || !itr->second.databaseReady || !member->IsAlive() || member->IsInCombat()
                    || member->IsBeingTeleported() || member->GetTransport() || member->GetVehicle() || member->duel)
                    error = "ENTER_MANASTORM_UNKNOWN";
                else if (itr->second.encounter->phase != Phase::Idle || itr->second.loadoutPending)
                    error = "ENTER_MANASTORM_ALREADY_ACTIVE";
                else if (member->IsInFlight())
                    error = "ENTER_MANASTORM_ON_FLIGHT_PATH";
                else
                {
                    auto const& progress = itr->second.progress[mode];
                    uint32 const completed = progress.empty() ? 0 : progress.back();
                    if (!CanStart(depth, completed, mode >= 4))
                        error = "ENTER_MANASTORM_BAD_LEVEL";
                }
            }
            if (error)
            {
                SendResult(player, EnterResult, error);
                return;
            }
            auto encounter = std::make_shared<Encounter>();
            encounter->owner = player->GetGUID();
            encounter->mode = mode;
            encounter->level = maxLevel;
            for (Player* member : party)
                encounter->members.insert(member->GetGUID());
            for (Player* member : party)
            {
                Run& state = runs.at(member->GetGUID());
                state.encounter = encounter;
                state.returnLocation = WorldLocation(member->GetMapId(), member->GetPositionX(), member->GetPositionY(),
                    member->GetPositionZ(), member->GetOrientation());
                GiveStarterItems(member);
            }
            Transfer(player, run, depth);
        }

        void Transfer(Player* player, Run& run, uint32 depth)
        {
            if (player->IsBeingTeleported() || player->IsInCombat() || !player->IsAlive())
                return;
            uint32 maxLevel = 0;
            uint32 present = 0;
            for (auto const& reference : player->GetMap()->GetPlayers())
                if (Player* member = reference.GetSource())
                    if (run.encounter->members.contains(member->GetGUID()) && !member->IsBeingTeleported())
                    {
                        ++present;
                        maxLevel = std::max(maxLevel, uint32(member->GetLevel()));
                    }
            if (present != run.encounter->members.size())
            {
                run.encounter->portalArmed.clear();
                ChatHandler(player->GetSession()).SendSysMessage("Wait for every party member before continuing.");
                return;
            }
            if (run.encounter->mode < 4 && maxLevel >= std::max(60u, sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)))
            {
                ChatHandler(player->GetSession()).SendSysMessage("Maximum level reached! Your rewards are saved. Enter again to begin endgame Manastorm.");
                Exit(player, run);
                return;
            }
            run.encounter->level = maxLevel;
            Phase const previousPhase = run.encounter->phase;
            uint32 const previousDepth = run.encounter->depth;
            uint32 const previousInstance = run.encounter->instanceId;
            uint32 const previousScene = run.encounter->sceneIndex;
            uint32 const previousMap = run.GetScene().map;
            ClearBubble(player);
            std::vector<uint32> choices;
            for (uint32 index : validScenes)
                if (Scenes[index].unlock <= depth && (index != previousScene || depth == 1))
                    choices.push_back(index);
            if (choices.empty() && Scenes[previousScene].unlock <= depth
                && std::find(validScenes.begin(), validScenes.end(), previousScene) != validScenes.end())
                choices.push_back(previousScene);
            if (choices.empty())
            {
                SendResult(player, EnterResult, "ENTER_MANASTORM_UNKNOWN");
                return;
            }
            run.encounter->sceneIndex = depth == 1 ? choices.front() : choices[urand(0, uint32(choices.size() - 1))];
            run.encounter->depth = depth;
            run.encounter->phase = Phase::Transferring;
            run.encounter->transferStarted = GameTime::GetGameTime().count();
            player->PrepareScriptedPrivateInstance(run.GetScene().map, run.returnLocation, run.encounter->owner, run.encounter->members);
            auto const& entry = run.GetScene().entrance;
            if (!player->TeleportTo(run.GetScene().map, entry.x, entry.y, entry.z, entry.o, 0, nullptr, true))
            {
                run.encounter->phase = previousPhase;
                run.encounter->depth = previousDepth;
                run.encounter->sceneIndex = previousScene;
                player->PrepareScriptedPrivateInstance(previousMap, run.returnLocation, run.encounter->owner, run.encounter->members);
                player->SetScriptedPrivateInstanceId(previousInstance);
                if (!previousInstance)
                    player->ClearScriptedPrivateInstance();
                SendResult(player, EnterResult, "ENTER_MANASTORM_UNKNOWN");
                return;
            }
            if (Map* previous = sMapMgr->FindMap(previousMap, previousInstance))
                if (previous->IsScriptedPrivateInstance())
                    previous->ToInstanceMap()->RequestScriptedPrivateUnload();
            run.encounter->instanceId = 0;
            run.encounter->initialized = false;
            run.encounter->guide.Clear();
            run.encounter->portal.Clear();
            run.encounter->portalArmed.clear();
            run.encounter->boss.Clear();
            run.encounter->guards.clear();
            run.commitReady = false;
            run.encounter->enemyDamage.clear();
            run.encounter->hearts.clear();
            run.encounter->treasure.Clear();
            run.encounter->treasureSpawned = false;
            run.encounter->bonusCaches = 0;
            run.encounter->resurrectionCharges = 5;
            run.encounter->finished = false;
            run.encounter->pendingCommits = 0;
            for (ObjectGuid guid : run.encounter->members)
                if (auto state = runs.find(guid); state != runs.end() && state->second.encounter == run.encounter)
                {
                    state->second.needsTransfer = true;
                    state->second.commitReady = false;
                }
        }

        Creature* SpawnEnemy(InstanceMap* map, Spawn const& spawn, Run& run, bool boss)
        {
            if (!sObjectMgr->GetCreatureTemplate(spawn.entry))
                return nullptr;
            float const ground = map->GetHeight(PHASEMASK_NORMAL, spawn.x, spawn.y, spawn.z + 2.0f, true, 10.0f);
            if (!std::isfinite(ground) || std::abs(ground - spawn.z) > 4.0f)
            {
                LOG_ERROR("coa", "Manastorm rejected geometry for scene {}, creature {}",
                    run.GetScene().stage, spawn.entry);
                return nullptr;
            }
            Creature* creature = map->SummonCreature(spawn.entry, Position(spawn.x, spawn.y, spawn.z, spawn.o));
            if (!creature)
                return nullptr;
            creature->SetLevel(run.encounter->level);
            creature->SetFaction(16);
            creature->SetReactState(REACT_PASSIVE);
            creature->SetLootRewardDisabled(true);
            creature->SetReputationRewardDisabled(true);
            creature->SetLootMode(0);
            float const scale = DepthStatMultiplier(run.encounter->depth);
            float const party = PartyStatMultiplier(uint32(run.encounter->members.size()));
            float const groupHealth = 4.2f * party;
            uint32 const health = uint32(std::min(500000000.0f,
                (140 + 35 * run.encounter->level) * scale * (boss ? 4.0f : 1.0f) * groupHealth));
            creature->SetMaxHealth(health);
            creature->SetHealth(health);
            float const ratio = float(run.encounter->level) / std::max(1u, uint32(creature->GetCreatureTemplate()->maxlevel));
            float const groupDamage = 1.4f * party;
            float const spellScale = std::clamp(ratio * ratio, 0.01f, 64.0f) * scale * groupDamage;
            run.encounter->enemyDamage[creature->GetGUID()] = spellScale;
            creature->SetInt32Value(UNIT_FIELD_ATTACK_POWER, 0);
            creature->SetBaseWeaponDamage(BASE_ATTACK, MINDAMAGE, (5.0f + run.encounter->level) * scale * groupDamage / spellScale);
            creature->SetBaseWeaponDamage(BASE_ATTACK, MAXDAMAGE, (8.0f + run.encounter->level * 1.4f) * scale * groupDamage / spellScale);
            creature->SetStatFlatModifier(UNIT_MOD_ARMOR, BASE_VALUE, float(run.encounter->level) * 20.0f * party);
            creature->UpdateArmor();
            creature->UpdateDamagePhysical(BASE_ATTACK);
            if (run.encounter->depth >= 6)
            {
                constexpr std::array<uint32, 3> affixes = {UnrelentingSpeed, Leeching, TribalFury};
                uint32 const affix = affixes[(run.encounter->depth - 6) % affixes.size()];
                if (affix != TribalFury || boss)
                    creature->AddAura(affix, creature);
            }
            if (boss)
                run.encounter->bossBaseHealth = health;
            return creature;
        }

        void UpdateLink(Player* player, Run& run)
        {
            uint32 const stacks = uint32(run.encounter->guards.size());
            if (Creature* boss = player->GetMap()->GetCreature(run.encounter->boss))
            {
                float const fraction = boss->GetHealthPct() / 100.0f;
                uint32 const health = LinkedHealth(run.encounter->bossBaseHealth, stacks);
                boss->SetMaxHealth(health);
                boss->SetHealth(std::max(1u, uint32(health * fraction)));
                if (stacks)
                {
                    if (Aura* aura = boss->AddAura(LinkSpell, boss))
                        aura->SetStackAmount(uint8(stacks));
                }
                else
                    boss->RemoveAurasDueToSpell(LinkSpell);
            }
            WorldPacket packet(ChaoticLink, 4);
            packet << stacks;
            for (auto const& reference : player->GetMap()->GetPlayers())
                if (Player* member = reference.GetSource())
                    member->SendDirectMessage(&packet);
        }

        void Complete(Player* player, Run& run)
        {
            run.encounter->phase = Phase::Committing;
            uint8 const mode = run.encounter->mode;
            bool const first = !std::binary_search(run.progress[mode].begin(), run.progress[mode].end(), run.encounter->depth);
            uint32 const chance = CacheChance(run.pity[mode], run.encounter->depth, mode >= 4);
            bool const wonCache = urand(1, 10000) <= chance;
            uint32 const pity = wonCache ? 0 : chance;
            uint32 const cacheCount = uint32(wonCache) + run.encounter->bonusCaches;
            uint32 const totalCaches = run.caches[mode] + cacheCount;
            auto reward = std::make_shared<RewardMail>();
            Mail* mail = &reward->mail;
            mail->messageID = sObjectMgr->GenerateMailID();
            mail->messageType = MAIL_CREATURE;
            mail->stationery = MAIL_STATIONERY_DEFAULT;
            mail->sender = GuideEntry;
            mail->receiver = player->GetGUID().GetCounter();
            mail->subject = "Manastorm: level " + std::to_string(run.encounter->depth);
            mail->body = first ? "A new depth conquered! Your bullion and bolts are enclosed. Caches go to your bags."
                : "Another storm conquered! Your bolts are enclosed. Caches go to your bags. Keep pushing deeper!";
            mail->money = player->GetLevel() * 20 * (1 + std::min(run.encounter->depth, 1000u) / 10);
            mail->deliver_time = GameTime::GetGameTime().count();
            mail->expire_time = mail->deliver_time + 30 * DAY;
            mail->checked = MAIL_CHECK_MASK_HAS_BODY;
            mail->state = MAIL_STATE_UNCHANGED;
            CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
            if (first)
            {
                auto* clear = CharacterDatabase.GetPreparedStatement(CHAR_INS_MANASTORM_CLEAR);
                clear->SetData(0, player->GetGUID().GetCounter());
                clear->SetData(1, mode);
                clear->SetData(2, run.encounter->depth);
                clear->SetData(3, run.GetScene().stage);
                clear->SetData(4, mail->messageID);
                clear->SetData(5, uint32(mail->deliver_time));
                transaction->Append(clear);
            }
            auto* bonus = CharacterDatabase.GetPreparedStatement(CHAR_REP_MANASTORM_BONUS);
            bonus->SetData(0, player->GetGUID().GetCounter());
            bonus->SetData(1, mode);
            bonus->SetData(2, pity);
            bonus->SetData(3, totalCaches);
            transaction->Append(bonus);
            std::vector<std::pair<uint32, uint32>> items;
            items.emplace_back(1297308, BoltReward(run.encounter->depth) + run.encounter->bonusCaches * 10);
            if (first)
                items.emplace_back(1297307, BullionReward(run.encounter->depth));
            for (uint32 i = 0; i < cacheCount; ++i)
                items.emplace_back(CacheForLevel(player->GetLevel(), run.encounter->depth, mode >= 4), 1);
            for (auto const& [entry, count] : items)
            {
                std::unique_ptr<Item> item(Item::CreateItem(entry, count, player));
                if (!item)
                {
                    run.commitReady = true;
                    run.commitSucceeded = false;
                    return;
                }
                if (IsCache(entry))
                {
                    item->SetBinding(true);
                    item->SaveToDB(transaction);
                    auto* pending = CharacterDatabase.GetPreparedStatement(CHAR_INS_MANASTORM_CACHE);
                    pending->SetData(0, item->GetGUID().GetCounter());
                    pending->SetData(1, player->GetGUID().GetCounter());
                    transaction->Append(pending);
                    continue;
                }
                item->SaveToDB(transaction);
                mail->AddItem(item->GetGUID().GetCounter(), entry);
                auto* attachment = CharacterDatabase.GetPreparedStatement(CHAR_INS_MAIL_ITEM);
                attachment->SetData(0, mail->messageID);
                attachment->SetData(1, item->GetGUID().GetCounter());
                attachment->SetData(2, mail->receiver);
                transaction->Append(attachment);
                reward->items.push_back(std::move(item));
            }
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_INS_MAIL);
            statement->SetData(0, mail->messageID);
            statement->SetData(1, mail->messageType);
            statement->SetData(2, int8(mail->stationery));
            statement->SetData(3, uint16(0));
            statement->SetData(4, mail->sender);
            statement->SetData(5, mail->receiver);
            statement->SetData(6, mail->subject);
            statement->SetData(7, mail->body);
            statement->SetData(8, true);
            statement->SetData(9, uint32(mail->expire_time));
            statement->SetData(10, uint32(mail->deliver_time));
            statement->SetData(11, mail->money);
            statement->SetData(12, uint32(0));
            statement->SetData(13, uint8(mail->checked));
            transaction->Append(statement);
            ObjectGuid const guid = player->GetGUID();
            uint32 const instanceId = run.encounter->instanceId;
            uint32 const depth = run.encounter->depth;
            bool const recruitAFriend = player->GetsRecruitAFriendBonus(true);
            float const xpMultiplier = player->GetTotalAuraMultiplier(SPELL_AURA_MOD_XP_PCT,
                [recruitAFriend](AuraEffect const* effect)
                {
                    return effect->GetId() != 818059 || !recruitAFriend;
                });
            uint32 const xp = mode < 4 ? uint32(sObjectMgr->GetXPForLevel(player->GetLevel()) *
                (first ? 0.075f : 0.06f) * xpMultiplier) : 0;
            uint64 const token = run.token;
            if (xp)
            {
                auto* voucher = CharacterDatabase.GetPreparedStatement(CHAR_ADD_MANASTORM_XP);
                voucher->SetData(0, guid.GetCounter());
                voucher->SetData(1, xp);
                transaction->Append(voucher);
            }
            auto encounter = run.encounter;
            ++encounter->pendingCommits;
            transactions.emplace_back(CharacterDatabase.AsyncCommitTransaction(transaction));
            transactions.back().AfterComplete([this, guid, instanceId, depth, reward, mode, pity, totalCaches, xp,
                encounter, token](bool success)
            {
                --encounter->pendingCommits;
                auto itr = runs.find(guid);
                if (success)
                {
                    sMailMgr->OnMailSent(guid.GetCounter());
                    readyMails[guid].push_back(reward);
                    if (itr != runs.end())
                    {
                        auto& progress = itr->second.progress[mode];
                        if (!std::binary_search(progress.begin(), progress.end(), depth))
                        {
                            progress.push_back(depth);
                            std::sort(progress.begin(), progress.end());
                        }
                        itr->second.progressDirty = true;
                        itr->second.pity[mode] = pity;
                        itr->second.caches[mode] = totalCaches;
                        itr->second.cachesPending = true;
                        itr->second.uiEvents.RescheduleEvent(EventCacheDelivery, 1ms);
                        if (itr->second.token != token)
                            ReloadXP(guid, itr->second);
                        else
                            itr->second.pendingXP += xp;
                    }
                }
                if (itr != runs.end() && itr->second.encounter->instanceId == instanceId && itr->second.encounter->depth == depth)
                {
                    itr->second.commitReady = true;
                    itr->second.commitSucceeded = success;
                }
            });
        }

        void Finish(Player* player, Run& run)
        {
            if (!std::binary_search(run.progress[run.encounter->mode].begin(), run.progress[run.encounter->mode].end(), run.encounter->depth))
            {
                run.progress[run.encounter->mode].push_back(run.encounter->depth);
                std::sort(run.progress[run.encounter->mode].begin(), run.progress[run.encounter->mode].end());
            }
            run.encounter->phase = Phase::Completed;
            if (!player->IsAlive())
            {
                player->ResurrectPlayer(1.0f);
                player->SpawnCorpseBones();
            }
            for (auto const& guid : run.encounter->guards)
                if (Creature* guard = player->GetMap()->GetCreature(guid))
                    guard->DespawnOrUnsummon();
            run.encounter->guards.clear();
            player->CombatStop(true);
            if (run.pendingXP && !run.xpClaimPending)
                ClaimXP(player, run);
            WorldPacket completed(CompletedLevel, 4);
            completed << run.encounter->depth;
            player->SendDirectMessage(&completed);
            SendProgress(player, run, false);
            SendActive(player, run);
            if (run.encounter->finished)
                return;
            run.encounter->finished = true;
            auto const& pos = run.GetScene().boss;
            if (Creature* portal = player->GetMap()->SummonCreature(12999, Position(pos.x, pos.y, pos.z, pos.o)))
            {
                portal->SetReactState(REACT_PASSIVE);
                portal->AddAura(PortalAura, portal);
                run.encounter->portal = portal->GetGUID();
            }
            SpawnGuide(player, run, pos);
            ChatHandler(player->GetSession()).SendSysMessage(
                "Manastorm complete. Cogsley has your mail, supplies and the way forward.");
        }

        void ClearBubble(Player* player)
        {
            player->RemoveDynObject(SafetyBubble);
            player->RemoveAurasDueToSpell(SafetyBubble);
            player->RemoveAurasDueToSpell(SafetyBubbleHelper);
        }

        void ClearUtilities(Player* player)
        {
            for (Gadget const& gadget : Gadgets)
                if (!gadget.passive)
                    player->RemoveAurasDueToSpell(gadget.spell);
            player->RemoveAurasDueToSpell(93311);
            player->RemoveAurasDueToSpell(254462);
        }

        void FailRun(Player* player, Run& run)
        {
            if (run.encounter->phase == Phase::Committing)
                return;
            if (run.encounter->phase != Phase::Failed)
            {
                WorldPacket failed(Fail, 0);
                player->SendDirectMessage(&failed);
            }
            run.encounter->phase = Phase::Failed;
            Exit(player, run);
        }

        void Exit(Player* player, Run& run)
        {
            if (run.encounter->phase == Phase::Idle)
            {
                SendResult(player, LeaveResult, "LEAVE_MANASTORM_NOT_ACTIVE");
                return;
            }
            if (player->IsBeingTeleported() || run.encounter->phase == Phase::Committing)
            {
                SendResult(player, LeaveResult, "LEAVE_MANASTORM_TRANSITION");
                return;
            }
            ClearBubble(player);
            ClearUtilities(player);
            player->CombatStop(true);
            if (!player->IsAlive())
            {
                player->ResurrectPlayer(0.5f);
                player->SpawnCorpseBones();
            }
            Phase const previous = run.encounter->phase;
            run.encounter->phase = Phase::Leaving;
            player->ClearScriptedPrivateInstance();
            if (!player->TeleportTo(run.returnLocation))
            {
                player->PrepareScriptedPrivateInstance(run.GetScene().map, run.returnLocation, run.encounter->owner, run.encounter->members);
                player->SetScriptedPrivateInstanceId(run.encounter->instanceId);
                run.encounter->phase = previous;
                SendResult(player, LeaveResult, "LEAVE_MANASTORM_UNKNOWN");
            }
            else if (Map* previousMap = sMapMgr->FindMap(run.GetScene().map, run.encounter->instanceId))
                if (previousMap->IsScriptedPrivateInstance())
                    previousMap->ToInstanceMap()->RequestScriptedPrivateUnload();
        }

        std::atomic<bool> enabled{false};
        std::atomic<uint64> nextToken{0};
        std::mutex queueMutex;
        std::recursive_mutex mutex;
        std::map<uint32, std::deque<Request>> requests;
        std::map<ObjectGuid, Run> runs;
        std::map<ObjectGuid, std::vector<std::shared_ptr<RewardMail>>> readyMails;
        std::vector<uint32> validScenes;
        std::list<TransactionCallback> transactions;
    };

    class ManastormInstance final : public InstanceScript
    {
    public:
        explicit ManastormInstance(InstanceMap* map) : InstanceScript(map) { }
        void OnPlayerEnter(Player* player) override
        {
            ManastormService::Get().Entered(instance->ToInstanceMap(), player);
        }
        void Update(uint32 diff) override { ManastormService::Get().UpdateInstance(instance->ToInstanceMap(), diff); }
    };

    class ManastormMaps final : public AllMapScript
    {
    public:
        ManastormMaps() : AllMapScript("AscensionManastormMaps") { }
        void OnBeforeCreateInstanceScript(InstanceMap* map, InstanceScript** script, bool, std::string, uint32) override
        {
            if (map->IsScriptedPrivateInstance())
                *script = new ManastormInstance(map);
        }
    };

    class ManastormPlayers final : public PlayerScript
    {
    public:
        ManastormPlayers() : PlayerScript("AscensionManastormPlayers") { }
        void OnPlayerLogin(Player* player) override { ManastormService::Get().Login(player); }
        void OnPlayerLogout(Player* player) override { ManastormService::Get().Logout(player); }
        void OnPlayerDeleteFromDB(CharacterDatabaseTransaction transaction, uint32 guid) override
        {
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_DEL_MANASTORM_CLEARS);
            statement->SetData(0, guid);
            transaction->Append(statement);
            for (auto id : {CHAR_DEL_MANASTORM_BONUS, CHAR_DEL_MANASTORM_LOADOUT, CHAR_DEL_MANASTORM_XP,
                CHAR_DEL_MANASTORM_CACHE_ITEMS, CHAR_DEL_MANASTORM_CACHES})
            {
                auto* extra = CharacterDatabase.GetPreparedStatement(id);
                extra->SetData(0, guid);
                transaction->Append(extra);
            }
        }
        void OnPlayerMapChanged(Player* player) override { ManastormService::Get().MapChanged(player); }
        void OnPlayerUpdate(Player* player, uint32 diff) override
        {
            ManastormService::Get().UpdatePlayer(player, diff);
        }
        void OnPlayerGiveXP(Player* player, uint32& amount, Unit*, uint8) override
        {
            Map const* map = player->FindMap();
            if (map && map->IsScriptedPrivateInstance() && !ManastormService::Get().IsAwardingXP(player))
                amount = 0;
        }
        bool OnPlayerPassedQuestKilledMonsterCredit(Player* player, Quest const*, uint32, uint32, ObjectGuid) override
        {
            Map const* map = player->FindMap();
            return !map || !map->IsScriptedPrivateInstance();
        }
        bool OnPlayerBeforeCriteriaProgress(Player* player, AchievementCriteriaEntry const* criteria) override
        {
            Map const* map = player->FindMap();
            return !map || !map->IsScriptedPrivateInstance()
                || criteria->requiredType != ACHIEVEMENT_CRITERIA_TYPE_KILL_CREATURE;
        }
    };

    class ManastormUnits final : public UnitScript
    {
    public:
        ManastormUnits() : UnitScript("AscensionManastormUnits") { }
        void OnUnitDeath(Unit* unit, Unit*) override { ManastormService::Get().Death(unit); }
        void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
        {
            ManastormService::Get().Damage(attacker, victim, damage);
        }
    };

    class ManastormSpells final : public AllSpellScript
    {
    public:
        ManastormSpells() : AllSpellScript("AscensionManastormSpells") { }
        void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
        {
            if (Player* player = spell->GetCaster()->ToPlayer())
            {
                SpellCastResult const utility = ManastormService::Get().CheckUtility(player, spell->GetSpellInfo()->Id);
                if (utility != SPELL_CAST_OK)
                    result = utility;
            }
        }
        void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32, uint32, bool) override
        {
            uint32 const id = spell->GetSpellInfo()->Id;
            if (!miss && target == spell->GetCaster() && spell->m_CastItem
                && ((id == 254440 && spell->m_CastItem->GetEntry() == 254041)
                    || (id == 93311 && spell->m_CastItem->GetEntry() == 254042)))
                if (Player* player = target->ToPlayer(); player && player->IsInWorld()
                    && ManastormService::Get().CheckUtility(player, id) == SPELL_CAST_OK)
                    sScriptMgr->OnPlayerCoAProgress(player, id == 254440 ? CoAProgressEvent::ManastormPotion
                        : CoAProgressEvent::ManastormEscape, id);
            if (!miss && spell->GetSpellInfo()->Id == 93309)
                if (Player* player = spell->GetCaster()->ToPlayer())
                    ManastormService::Get().UsedResurrection(player);
        }
    };

    class spell_ascension_manastorm_potion final : public SpellScript
    {
        PrepareSpellScript(spell_ascension_manastorm_potion);
        void Resource(SpellEffIndex effect)
        {
            PreventHitDefaultEffect(effect);
            GetCaster()->CastSpell(GetCaster(), 254462, true);
        }
        void Register() override
        {
            OnEffectHitTarget += SpellEffectFn(spell_ascension_manastorm_potion::Resource, EFFECT_2, 183);
        }
    };

    class ManastormLoot final : public GlobalScript
    {
    public:
        ManastormLoot() : GlobalScript("AscensionManastormLoot", {GLOBALHOOK_ON_BEFORE_LOOT_EQUAL_CHANCED}) { }
        bool OnBeforeLootEqualChanced(Player const* player, std::list<LootStoreItem*> entries,
            Loot& loot, LootStore const& store) override
        {
            if (!player || &store != &LootTemplates_Item)
                return true;
            Item const* container = player->GetItemByGuid(loot.containerGUID);
            constexpr std::array<uint32, 9> caches = {97877, 97878, 97879, 97880, 97881, 97882, 97883, 1278050, 1278051};
            if (!container || std::find(caches.begin(), caches.end(), container->GetEntry()) == caches.end()
                || entries.empty())
                return true;
            std::vector<LootStoreItem*> eligible;
            uint32 bestLevel = 0;
            for (LootStoreItem* entry : entries)
                if (ItemTemplate const* item = sObjectMgr->GetItemTemplate(entry->itemid))
                    if (player->CanUseItem(item) == EQUIP_ERR_OK
                        && (!item->GetSkill() || player->GetSkillValue(item->GetSkill())))
                    {
                        eligible.push_back(entry);
                        bestLevel = std::max(bestLevel, item->RequiredLevel);
                    }
            std::erase_if(eligible, [bestLevel](LootStoreItem const* entry)
            {
                return sObjectMgr->GetItemTemplate(entry->itemid)->RequiredLevel + 5 < bestLevel;
            });
            if (!eligible.empty())
                loot.AddItem(*eligible[urand(0, uint32(eligible.size() - 1))]);
            else
                loot.AddItem(**std::next(entries.begin(), urand(0, uint32(entries.size() - 1))));
            return false;
        }
    };

    class item_ascension_manastorm_cache final : public ItemScript
    {
    public:
        item_ascension_manastorm_cache() : ItemScript("item_ascension_manastorm_cache") { }
        bool OnUse(Player* player, Item* item, SpellCastTargets const&) override
        {
            if (player->IsAlive() && !player->IsInCombat())
                player->SendLoot(item->GetGUID(), LOOT_CORPSE);
            return true;
        }
    };

    class ManastormGuides final : public AllCreatureScript
    {
    public:
        ManastormGuides() : AllCreatureScript("AscensionManastormGuides") { }
        void OnCreatureAddWorld(Creature* creature) override
        {
            if (creature->GetEntry() == GuideEntry)
                creature->ReplaceAllNpcFlags(UNIT_NPC_FLAG_GOSSIP | UNIT_NPC_FLAG_MAILBOX | UNIT_NPC_FLAG_REPAIR
                    | UNIT_NPC_FLAG_VENDOR);
            if (creature->GetMap()->IsScriptedPrivateInstance())
            {
                creature->SetLootRewardDisabled(true);
                creature->SetReputationRewardDisabled(true);
                creature->SetLootMode(0);
            }
        }
        bool CanCreatureGossipHello(Player* player, Creature* creature) override
        {
            return ManastormService::Get().Gossip(player, creature, 0);
        }
        bool CanCreatureGossipSelect(Player* player, Creature* creature, uint32 sender, uint32 action) override
        {
            return sender == GOSSIP_SENDER_MAIN && ManastormService::Get().Gossip(player, creature, action);
        }
    };

    class ManastormWorld final : public WorldScript
    {
    public:
        ManastormWorld() : WorldScript("AscensionManastormWorld") { }
        void OnAfterConfigLoad(bool reload) override { if (!reload) ManastormService::Get().Configure(); }
        void OnUpdate(uint32) override { ManastormService::Get().PollTransactions(); }
        void OnStartup() override { ManastormService::Get().ValidateScenes(); }
    };

    class ManastormCommands final : public CommandScript
    {
    public:
        ManastormCommands() : CommandScript("AscensionManastormCommands") { }
        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable const manastormCommands = {
                {"enter", EnterCommand, SEC_PLAYER, Console::No},
                {"leave", LeaveCommand, SEC_PLAYER, Console::No},
                {"next", NextCommand, SEC_PLAYER, Console::No},
                {"start", StartCommand, SEC_PLAYER, Console::No},
                {"status", StatusCommand, SEC_PLAYER, Console::No}
            };
            static ChatCommandTable const commands = {
                {"manastorm", manastormCommands}
            };
            return commands;
        }
        static bool EnterCommand(ChatHandler* handler, uint32 depth)
        {
            return ManastormService::Get().Command(handler->GetPlayer(), "enter", depth);
        }
        static bool LeaveCommand(ChatHandler* handler)
        {
            return ManastormService::Get().Command(handler->GetPlayer(), "leave");
        }
        static bool NextCommand(ChatHandler* handler)
        {
            return ManastormService::Get().Command(handler->GetPlayer(), "next");
        }
        static bool StartCommand(ChatHandler* handler)
        {
            return ManastormService::Get().Command(handler->GetPlayer(), "start");
        }
        static bool StatusCommand(ChatHandler* handler)
        {
            return ManastormService::Get().Command(handler->GetPlayer(), "status");
        }
    };
}

bool QueueAscensionManastormPacket(WorldSession* session, WorldPacket const& packet)
{
    return ManastormService::Get().Queue(session, packet);
}

void AddAscensionManastormScripts()
{
    new ManastormWorld();
    new ManastormMaps();
    new ManastormPlayers();
    new ManastormUnits();
    new ManastormSpells();
    new ManastormLoot();
    new item_ascension_manastorm_cache();
    RegisterSpellScript(spell_ascension_manastorm_potion);
    new ManastormGuides();
    new ManastormCommands();
}
