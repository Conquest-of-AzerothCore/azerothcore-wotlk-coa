/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AllCreatureScript.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Map.h"
#include "MapCollisionData.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "WorldScript.h"
#include <array>
#include <cmath>
#include <shared_mutex>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    constexpr uint32 MarkerEntry = 1;
    constexpr uint32 MarkerMilliseconds = 60000;
    constexpr std::size_t MaximumPoints = 64;
    constexpr uint32 RoomRays = 48;
    constexpr uint32 RoomExitWindow = 4;
    constexpr float RoomExitSlack = 1.15f;
    constexpr float RoomPadding = 2.0f;
    constexpr std::array<float, 2> RoomRayHeights = { 2.0f, 5.0f };

    struct Leash
    {
        float radius = 0.0f;
        std::vector<Position> points;
    };

    std::shared_mutex LeashLock;
    std::unordered_map<uint32, Leash> Leashes;
    std::unordered_map<ObjectGuid, uint32> LastEntry;

    bool InsidePolygon(std::vector<Position> const& points, float x, float y)
    {
        bool inside = false;
        for (std::size_t i = 0, j = points.size() - 1; i < points.size(); j = i++)
        {
            float const xi = points[i].GetPositionX(), yi = points[i].GetPositionY();
            float const xj = points[j].GetPositionX(), yj = points[j].GetPositionY();
            if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi)
                inside = !inside;
        }
        return inside;
    }

    bool Inside(Leash const& leash, Position const& home, float x, float y)
    {
        if (leash.points.size() >= 3)
            return InsidePolygon(leash.points, x, y);
        if (leash.radius > 0.0f)
            return home.GetExactDist2d(x, y) <= leash.radius;
        return true;
    }

    Optional<Leash> FindLeash(uint32 entry)
    {
        std::shared_lock lock(LeashLock);
        auto const itr = Leashes.find(entry);
        if (itr == Leashes.end())
            return {};
        return itr->second;
    }

    void LoadLeashes()
    {
        std::unordered_map<uint32, Leash> leashes;
        if (QueryResult result = WorldDatabase.Query("SELECT `entry`, `radius` FROM `coa_boss_leash`"))
        {
            do
            {
                Field* fields = result->Fetch();
                leashes[fields[0].Get<uint32>()].radius = fields[1].Get<float>();
            } while (result->NextRow());
        }
        if (QueryResult result = WorldDatabase.Query("SELECT `entry`, `x`, `y`, `z` FROM `coa_boss_leash_point` ORDER BY `entry`, `point`"))
        {
            do
            {
                Field* fields = result->Fetch();
                leashes[fields[0].Get<uint32>()].points.emplace_back(fields[1].Get<float>(), fields[2].Get<float>(), fields[3].Get<float>());
            } while (result->NextRow());
        }

        std::size_t const count = leashes.size();
        {
            std::unique_lock lock(LeashLock);
            Leashes = std::move(leashes);
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA boss leashes", count);
    }

    float RayLength(Map const* map, uint32 phaseMask, Position const& from, float angle, float reach)
    {
        MapCollisionData const& collision = map->GetMapCollisionData();
        float longest = 0.0f;
        for (float height : RoomRayHeights)
        {
            float const z = from.GetPositionZ() + height;
            float tx = from.GetPositionX() + std::cos(angle) * reach;
            float ty = from.GetPositionY() + std::sin(angle) * reach;
            float rx, ry, rz;
            if (collision.GetStaticTree().GetObjectHitPos(from.GetPositionX(), from.GetPositionY(), z, tx, ty, z, rx, ry, rz,
                -0.5f))
            {
                tx = rx;
                ty = ry;
            }
            if (collision.GetDynamicTree().GetObjectHitPos(phaseMask, from.GetPositionX(), from.GetPositionY(), z, tx, ty,
                z, rx, ry, rz, -0.5f))
            {
                tx = rx;
                ty = ry;
            }
            longest = std::max(longest, from.GetExactDist2d(tx, ty));
        }
        return longest;
    }

    std::vector<Position> RoomOutline(Map const* map, uint32 phaseMask, Position const& from, float reach)
    {
        std::array<float, RoomRays> length;
        for (uint32 i = 0; i < RoomRays; ++i)
            length[i] = RayLength(map, phaseMask, from, 2.0f * float(M_PI) * i / RoomRays, reach);

        std::vector<Position> outline;
        for (uint32 i = 0; i < RoomRays; ++i)
        {
            float const left = length[(i + RoomRays - RoomExitWindow) % RoomRays];
            float const right = length[(i + RoomExitWindow) % RoomRays];
            float const distance = std::min(reach, std::min(length[i], std::max(left, right) * RoomExitSlack) + RoomPadding);
            float const angle = 2.0f * float(M_PI) * i / RoomRays;
            outline.emplace_back(from.GetPositionX() + std::cos(angle) * distance,
                from.GetPositionY() + std::sin(angle) * distance, from.GetPositionZ());
        }
        return outline;
    }

    bool LeashedOnMap(Map const* map)
    {
        return map && map->IsNonRaidDungeon() && map->GetSpawnMode() != DUNGEON_DIFFICULTY_NORMAL;
    }
}

class CoABossLeashWorld final : public WorldScript
{
public:
    CoABossLeashWorld() : WorldScript("CoABossLeashWorld", { WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE }) { }

    void OnLoadCustomDatabaseTable() override
    {
        LoadLeashes();
    }
};

class CoABossLeashCheck final : public AllCreatureScript
{
public:
    CoABossLeashCheck() : AllCreatureScript("CoABossLeashCheck") { }

    void OnAllCreatureUpdate(Creature* creature, uint32) override
    {
        if (!creature->IsInCombat() || creature->IsInEvadeMode() || !creature->IsAlive() || !LeashedOnMap(creature->GetMap()))
            return;

        {
            std::shared_lock lock(LeashLock);
            auto const itr = Leashes.find(creature->GetEntry());
            if (itr == Leashes.end() || Inside(itr->second, creature->GetHomePosition(), creature->GetPositionX(), creature->GetPositionY()))
                return;
        }

        if (CreatureAI* ai = creature->AI())
            ai->EnterEvadeMode(CreatureAI::EVADE_REASON_BOUNDARY);
    }
};

class CoABossLeashCommands final : public CommandScript
{
public:
    CoABossLeashCommands() : CommandScript("CoABossLeashCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable leashCommands =
        {
            { "point", HandlePoint, SEC_GAMEMASTER, Console::No },
            { "undo", HandleUndo, SEC_GAMEMASTER, Console::No },
            { "radius", HandleRadius, SEC_GAMEMASTER, Console::No },
            { "clear", HandleClear, SEC_GAMEMASTER, Console::No },
            { "show", HandleShow, SEC_GAMEMASTER, Console::No },
            { "room", HandleRoom, SEC_GAMEMASTER, Console::No }
        };
        static ChatCommandTable commands =
        {
            { "leash", leashCommands }
        };
        return commands;
    }

    static Optional<uint32> ResolveEntry(ChatHandler* handler, Optional<uint32> entry)
    {
        Player* player = handler->GetPlayer();
        uint32 resolved = entry.value_or(0);
        if (!resolved)
            if (Creature* selected = handler->getSelectedCreature())
                resolved = selected->GetEntry();
        if (!resolved)
        {
            std::shared_lock lock(LeashLock);
            auto const itr = LastEntry.find(player->GetGUID());
            if (itr != LastEntry.end())
                resolved = itr->second;
        }
        if (!resolved || !sObjectMgr->GetCreatureTemplate(resolved))
        {
            handler->SendErrorMessage("Select the boss or give its creature entry.");
            return {};
        }
        std::unique_lock lock(LeashLock);
        LastEntry[player->GetGUID()] = resolved;
        return resolved;
    }

    static std::string BossName(uint32 entry)
    {
        CreatureTemplate const* info = sObjectMgr->GetCreatureTemplate(entry);
        return info ? info->Name : std::to_string(entry);
    }

    static bool HandlePoint(ChatHandler* handler, Optional<uint32> entryArg)
    {
        Optional<uint32> const entry = ResolveEntry(handler, entryArg);
        if (!entry)
            return false;

        Player* player = handler->GetPlayer();
        std::size_t index;
        {
            std::unique_lock lock(LeashLock);
            Leash& leash = Leashes[*entry];
            if (leash.points.size() >= MaximumPoints)
            {
                handler->SendErrorMessage("This leash already has {} points.", MaximumPoints);
                return false;
            }
            index = leash.points.size();
            leash.points.emplace_back(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ());
        }
        WorldDatabase.Execute("INSERT IGNORE INTO `coa_boss_leash` (`entry`, `radius`) VALUES ({}, 0)", *entry);
        WorldDatabase.Execute("REPLACE INTO `coa_boss_leash_point` (`entry`, `point`, `x`, `y`, `z`) VALUES ({}, {}, {}, {}, {})",
            *entry, index, player->GetPositionX(), player->GetPositionY(), player->GetPositionZ());
        handler->PSendSysMessage("{} ({}): leash point {} at {:.2f} {:.2f} {:.2f}.{}", BossName(*entry), *entry, index + 1,
            player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(),
            index + 1 < 3 ? " The area is active from 3 points." : "");
        return true;
    }

    static bool HandleUndo(ChatHandler* handler, Optional<uint32> entryArg)
    {
        Optional<uint32> const entry = ResolveEntry(handler, entryArg);
        if (!entry)
            return false;

        std::size_t index;
        {
            std::unique_lock lock(LeashLock);
            auto const itr = Leashes.find(*entry);
            if (itr == Leashes.end() || itr->second.points.empty())
            {
                handler->SendErrorMessage("{} has no leash points.", BossName(*entry));
                return false;
            }
            itr->second.points.pop_back();
            index = itr->second.points.size();
        }
        WorldDatabase.Execute("DELETE FROM `coa_boss_leash_point` WHERE `entry` = {} AND `point` = {}", *entry, index);
        handler->PSendSysMessage("{} ({}): removed leash point {}; {} left.", BossName(*entry), *entry, index + 1, index);
        return true;
    }

    static bool HandleRadius(ChatHandler* handler, float radius, Optional<uint32> entryArg)
    {
        if (radius < 0.0f || radius > 500.0f)
        {
            handler->SendErrorMessage("The radius must be between 0 and 500 yards.");
            return false;
        }
        Optional<uint32> const entry = ResolveEntry(handler, entryArg);
        if (!entry)
            return false;

        {
            std::unique_lock lock(LeashLock);
            Leashes[*entry].radius = radius;
        }
        WorldDatabase.Execute("REPLACE INTO `coa_boss_leash` (`entry`, `radius`) VALUES ({}, {})", *entry, radius);
        handler->PSendSysMessage("{} ({}): leash radius {} yards around the spawn point; leash points, when 3 or more, take precedence.",
            BossName(*entry), *entry, radius);
        return true;
    }

    static bool HandleClear(ChatHandler* handler, Optional<uint32> entryArg)
    {
        Optional<uint32> const entry = ResolveEntry(handler, entryArg);
        if (!entry)
            return false;

        {
            std::unique_lock lock(LeashLock);
            Leashes.erase(*entry);
        }
        WorldDatabase.Execute("DELETE FROM `coa_boss_leash_point` WHERE `entry` = {}", *entry);
        WorldDatabase.Execute("DELETE FROM `coa_boss_leash` WHERE `entry` = {}", *entry);
        handler->PSendSysMessage("{} ({}): leash removed.", BossName(*entry), *entry);
        return true;
    }

    static bool HandleRoom(ChatHandler* handler, Optional<float> reachArg, Optional<uint32> entryArg)
    {
        float const reach = reachArg.value_or(45.0f);
        if (reach < 10.0f || reach > 150.0f)
        {
            handler->SendErrorMessage("The reach must be between 10 and 150 yards.");
            return false;
        }
        Optional<uint32> const entry = ResolveEntry(handler, entryArg);
        if (!entry)
            return false;

        Player* player = handler->GetPlayer();
        Position from = player->GetPosition();
        Creature* selected = handler->getSelectedCreature();
        if (selected && selected->GetEntry() == *entry)
            from = selected->GetHomePosition();

        std::vector<Position> const outline = RoomOutline(player->GetMap(), player->GetPhaseMask(), from, reach);
        {
            std::unique_lock lock(LeashLock);
            Leashes[*entry].points = outline;
        }
        WorldDatabase.Execute("INSERT IGNORE INTO `coa_boss_leash` (`entry`, `radius`) VALUES ({}, 0)", *entry);
        WorldDatabaseTransaction trans = WorldDatabase.BeginTransaction();
        trans->Append("DELETE FROM `coa_boss_leash_point` WHERE `entry` = {}", *entry);
        for (std::size_t i = 0; i < outline.size(); ++i)
            trans->Append("INSERT INTO `coa_boss_leash_point` (`entry`, `point`, `x`, `y`, `z`) VALUES ({}, {}, {}, {}, {})",
                *entry, i, outline[i].GetPositionX(), outline[i].GetPositionY(), outline[i].GetPositionZ());
        WorldDatabase.CommitTransaction(trans);
        handler->PSendSysMessage("{} ({}): room leash with {} points around {:.1f} {:.1f}, cut at the exits. "
            "Check it with .leash show and fix single points with .leash undo / .leash point.",
            BossName(*entry), *entry, outline.size(), from.GetPositionX(), from.GetPositionY());
        return true;
    }

    static bool HandleShow(ChatHandler* handler, Optional<uint32> entryArg)
    {
        Optional<uint32> const entry = ResolveEntry(handler, entryArg);
        if (!entry)
            return false;

        Optional<Leash> const leash = FindLeash(*entry);
        if (!leash)
        {
            handler->PSendSysMessage("{} ({}) has no leash.", BossName(*entry), *entry);
            return true;
        }

        Player* player = handler->GetPlayer();
        handler->PSendSysMessage("{} ({}): radius {} yards, {} points.", BossName(*entry), *entry, leash->radius, leash->points.size());
        for (std::size_t i = 0; i < leash->points.size(); ++i)
        {
            Position const& point = leash->points[i];
            handler->PSendSysMessage("  {}: {:.2f} {:.2f} {:.2f}", i + 1, point.GetPositionX(), point.GetPositionY(), point.GetPositionZ());
            player->SummonCreature(MarkerEntry, point, TEMPSUMMON_TIMED_DESPAWN, MarkerMilliseconds);
        }

        if (leash->points.size() >= 3)
            handler->PSendSysMessage("You stand {} the leash area.",
                InsidePolygon(leash->points, player->GetPositionX(), player->GetPositionY()) ? "inside" : "outside");
        return true;
    }
};

void AddSC_CoABossLeash()
{
    new CoABossLeashWorld();
    new CoABossLeashCheck();
    new CoABossLeashCommands();
}
