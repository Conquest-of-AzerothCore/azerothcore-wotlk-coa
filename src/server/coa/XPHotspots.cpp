#include "XPHotspotRules.h"
#include "XPHotspotPainting.h"
#include "Chat.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <boost/bind/placeholders.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <cctype>
#include <array>
#include <map>
#include <mutex>
#include <sstream>
#include <set>

namespace XPHotspots
{
using namespace Acore::ChatCommands;
namespace
{
using Tree = boost::property_tree::ptree;
std::recursive_mutex Mutex;
std::map<uint32, Location> Locations;
std::set<uint32> ActiveIds;
std::map<uint32, Tree> Records;
std::map<ObjectGuid, Location> Drafts;
std::map<ObjectGuid, Location> PaintUndo;
struct LocalPaintUpload
{
    Location Base;
    std::string Edits;
    uint32 Parts = 0;
    uint32 Next = 0;
};
std::map<ObjectGuid, LocalPaintUpload> LocalPaint;
std::map<ObjectGuid, std::vector<Point>> TraceDrafts;
std::map<ObjectGuid, std::vector<std::pair<uint32, uint32>>> MergeSources;
std::map<ObjectGuid, RequestWindow> Requests;
std::map<ObjectGuid, uint32> Seen;
std::map<ObjectGuid, uint32> Timers;
std::map<uint32, std::vector<std::string>> Masks;
std::map<uint32, std::pair<uint32, std::vector<std::string>>> MaskWork;
std::map<uint32, Location> MaskRequests;
bool Enabled = false;
GeneralSettings General;
std::string Brand;
uint32 Generation = 1;
uint32 LocationIdFloor = 1000000;
constexpr uint32 LocationIdFloorSetting = 1000;
uint32 MaxContinent = 2;
uint32 Buff = 993945;
uint32 WorldTimer = 0;
constexpr char Prefix[] = "XPHOT\t";
thread_local bool TextReply = false;

uint64 Now()
{
    return GameTime::GetGameTime().count();
}

std::array<float, 4> Bounds(uint32 zone)
{
    float top = 0, left = 0, bottom = 100, right = 100;
    Zone2MapCoordinates(top, left, zone);
    Zone2MapCoordinates(bottom, right, zone);
    return {top, bottom, left, right};
}

Tree Parse(std::string const& text)
{
    Tree tree;
    std::istringstream stream(text);
    boost::property_tree::read_json(stream, tree);
    return tree;
}

std::string JSON(Tree const& tree)
{
    std::ostringstream stream;
    boost::property_tree::write_json(stream, tree, false);
    return stream.str();
}

Location Read(Tree const& t)
{
    Location r;
    r.Id = t.get<uint32>("id");
    r.Revision = t.get<uint32>("revision", 1);
    r.Name = t.get<std::string>("name");
    r.Map = t.get<uint32>("map");
    r.Zone = t.get<uint32>("zone");
    r.Continent = t.get<uint32>("continent", 3);
    r.Kind = t.get<std::string>("kind");
    r.Source = t.get<std::string>("source", "gm");
    r.Center = {t.get<double>("x", 0), t.get<double>("y", 0)};
    r.Radius = t.get<double>("radius", 0);
    r.Bonus = t.get<uint32>("xp", 150);
    r.Duration = t.get<uint32>("duration", 3600);
    r.Weight = t.get<uint32>("weight", 1);
    r.Cooldown = t.get<uint32>("cooldown", 3600);
    r.Queued = t.get<uint64>("queued", 0);
    r.Starts = t.get<uint64>("starts", 0);
    r.Ends = t.get<uint64>("ends", 0);
    r.LastEnd = t.get<uint64>("lastEnd", 0);
    r.Enabled = t.get<bool>("enabled", false);
    r.Valid = t.get<bool>("valid", false);
    r.Icon = t.get<bool>("icon", true);
    r.Highlight = t.get<bool>("highlight", true);
    r.Retired = t.get<bool>("retired", false);
    if (auto points = t.get_child_optional("points"))
        for (auto const& child : *points)
            r.Points.push_back({child.second.get<double>("x"), child.second.get<double>("y")});
    if (auto parts = t.get_child_optional("parts"))
        for (auto const& child : *parts)
        {
            if (r.Parts.size() >= 8 || child.second.get<std::string>("kind") == "union")
                throw std::runtime_error("Invalid compound hotspot");
            r.Parts.push_back(Read(child.second));
        }
    return r;
}

Tree Write(Location const& r)
{
    Tree t = Records.contains(r.Id) ? Records.at(r.Id) : Tree();
    t.put("id", r.Id);
    t.put("revision", r.Revision);
    t.put("name", r.Name);
    t.put("map", r.Map);
    t.put("zone", r.Zone);
    t.put("continent", r.Continent);
    t.put("kind", r.Kind);
    t.put("source", r.Source);
    t.put("x", r.Center.X);
    t.put("y", r.Center.Y);
    t.put("radius", r.Radius);
    t.put("xp", r.Bonus);
    t.put("duration", r.Duration);
    t.put("weight", r.Weight);
    t.put("cooldown", r.Cooldown);
    t.put("queued", r.Queued);
    t.put("starts", r.Starts);
    t.put("ends", r.Ends);
    t.put("lastEnd", r.LastEnd);
    t.put("enabled", r.Enabled);
    t.put("valid", r.Valid);
    t.put("icon", r.Icon);
    t.put("highlight", r.Highlight);
    t.put("retired", r.Retired);
    Tree parts;
    for (auto part : r.Parts)
    {
        part.Id = 0;
        parts.push_back({"", Write(part)});
    }
    t.put_child("parts", parts);
    Tree points;
    for (auto p : r.Points)
    {
        Tree point;
        point.put("x", p.X);
        point.put("y", p.Y);
        points.push_back({"", point});
    }
    t.put_child("points", points);
    if (r.Kind == "zone" && Masks.contains(r.Zone))
    {
        Tree mask;
        bool foundArea = false;
        for (auto const& row : Masks.at(r.Zone))
        {
            foundArea = foundArea || row.find('1') != std::string::npos;
            Tree value;
            value.put_value(row);
            mask.push_back({"", value});
        }
        t.put_child("mask", mask);
        t.put("outlineUnavailable", !foundArea);
    }
    auto area = Bounds(r.Zone);
    if (area[0] > area[1] && area[2] > area[3])
    {
        Tree bounds;
        for (float value : area)
        {
            Tree coordinate;
            coordinate.put_value(value);
            bounds.push_back({"", coordinate});
        }
        t.put_child("bounds", bounds);
    }
    return t;
}

bool BuildMask(Location const& r)
{
    if (r.Kind != "zone" || Masks.contains(r.Zone))
        return true;
    auto area = Bounds(r.Zone);
    auto entry = sMapStore.LookupEntry(r.Map);
    if (area[0] <= area[1] || area[2] <= area[3] || !entry || entry->Instanceable())
    {
        Masks[r.Zone] = {};
        return true;
    }
    auto map = sMapMgr->CreateBaseMap(r.Map);
    if (!map || map->Instanceable())
        return true;
    auto& work = MaskWork[r.Zone];
    if (work.second.empty())
        work.second.resize(64);
    uint32 stop = std::min(4096u, work.first + 32);
    for (; work.first < stop; ++work.first)
    {
        uint32 x = work.first % 64;
        uint32 y = work.first / 64;
        float worldX = area[0] + (area[1] - area[0]) * (y + 0.5f) / 64;
        float worldY = area[2] + (area[3] - area[2]) * (x + 0.5f) / 64;
        work.second[y] += map->GetZoneId(PHASEMASK_NORMAL, worldX, worldY, 10000) == r.Zone ? '1' : '0';
    }
    if (work.first < 4096)
        return false;
    Masks[r.Zone] = std::move(work.second);
    MaskWork.erase(r.Zone);
    return true;
}

bool Allowed(Location const& r)
{
    auto map = sMapStore.LookupEntry(r.Map);
    auto area = sAreaTableStore.LookupEntry(r.Zone);
    return !r.Retired && r.Valid && map && !map->Instanceable() && r.Continent <= MaxContinent &&
        (r.Kind != "zone" || (area && area->mapid == r.Map && !area->zone));
}

bool RotationAllowed(Location const& r)
{
    return Allowed(r) && RotationShapeAllowed(General, r.Kind);
}

bool SaveMany(std::vector<Location> const& rows, GeneralSettings const* settings = nullptr)
{
    auto transaction = WorldDatabase.BeginTransaction();
    std::vector<Tree> trees;
    for (auto const& r : rows)
    {
        auto tree = Write(r);
        tree.erase("mask");
        tree.erase("outlineUnavailable");
        auto* statement = WorldDatabase.GetPreparedStatement(WORLD_REP_XP_HOTSPOT);
        statement->SetData(0, r.Id);
        statement->SetData(1, JSON(tree));
        transaction->Append(statement);
        trees.push_back(std::move(tree));
    }
    if (settings)
        for (size_t i = 0; i < SettingCount; ++i)
        {
            auto* statement = WorldDatabase.GetPreparedStatement(WORLD_UPD_XP_HOTSPOT_SETTING);
            statement->SetData(0, uint32(i + 1));
            statement->SetData(1, settings->Values[i]);
            transaction->Append(statement);
        }
    if (!WorldDatabase.AsyncCommitTransaction(transaction).m_future.get())
        return false;
    if (settings)
        General = *settings;
    for (size_t i = 0; i < rows.size(); ++i)
    {
        auto const& r = rows[i];
        Locations[r.Id] = r;
        if (r.Enabled && r.Ends > Now() && RotationAllowed(r))
            ActiveIds.insert(r.Id);
        else
            ActiveIds.erase(r.Id);
        Records[r.Id] = std::move(trees[i]);
    }
    ++Generation;
    return true;
}

bool Save(Location const& r)
{
    return SaveMany({r});
}

void Send(Player* player, std::string const& text)
{
    if (TextReply)
    {
        ChatHandler(player->GetSession()).SendSysMessage(text.c_str());
        return;
    }
    WorldPacket packet;
    ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, player, player,
        std::string(Prefix) + text);
    player->SendDirectMessage(&packet);
}

void SendRow(Player* player, Tree const& tree)
{
    auto text = JSON(tree);
    uint32 count = (text.size() + 179) / 180;
    for (uint32 i = 0; i < count; ++i)
        Send(player, "R|" + std::to_string(i) + "|" + std::to_string(count) + "|" + text.substr(i * 180, 180));
}

bool GM(Player* player)
{
    return player->GetSession()->GetSecurity() >= SEC_GAMEMASTER;
}

size_t FactionQuota(Location const& r)
{
    auto area = sAreaTableStore.LookupEntry(r.Zone);
    if (area && area->team == AREATEAM_ALLY)
        return Alliance;
    if (area && area->team == AREATEAM_HORDE)
        return Horde;
    return Neutral;
}

void SendGeneral(Player* player)
{
    std::string packet = "G";
    for (auto value : General.Values)
        packet += "|" + std::to_string(value);
    Send(player, packet);
}

void Snapshot(Player* player, uint32 map, uint32 zone, uint32 page, bool catalog, std::string search)
{
    bool gm = GM(player);
    Send(player, "ACCESS|" + std::to_string(player->GetSession()->GetSecurity()));
    std::vector<Location const*> rows;
    uint64 now = Now();
    std::transform(search.begin(), search.end(), search.begin(), [](unsigned char c) { return std::tolower(c); });
    for (auto const& [id, r] : Locations)
    {
        if (r.Retired)
            continue;
        std::string name = r.Name;
        if (!search.empty())
            std::transform(name.begin(), name.end(), name.begin(), [](unsigned char c) { return std::tolower(c); });
        if (catalog && gm ? (map == UINT32_MAX || r.Map == map) && (!zone || r.Zone == zone) &&
            (search.empty() || name.find(search) != std::string::npos || std::to_string(id) == search) :
            RotationAllowed(r) && r.Ends > now)
            rows.push_back(&r);
    }
    uint32 perPage = catalog && gm ? 12 : 20;
    uint32 pages = std::max(1u, uint32((rows.size() + perPage - 1) / perPage));
    page = std::clamp(page, 1u, pages);
    if (TextReply)
    {
        Send(player, "Hotspots page " + std::to_string(page) + "/" + std::to_string(pages));
        for (uint32 i = (page - 1) * perPage; i < std::min(uint32(rows.size()), page * perPage); ++i)
            Send(player, std::to_string(rows[i]->Id) + " " + rows[i]->Name + " | " +
                (rows[i]->Enabled ? "enabled" : "disabled") + " | +" + std::to_string(rows[i]->Bonus) +
                "% | " + std::to_string(rows[i]->Duration / 60) + " minutes");
        return;
    }
    if (gm)
        SendGeneral(player);
    Send(player, "BRAND|" + Brand);
    Send(player, "B|" + std::to_string(Generation) + "|" + std::to_string(gm) + "|" +
        std::to_string(General.Values[Announcements]) + "|" + std::to_string(now) + "|" + std::to_string(page) + "|" +
        std::to_string(pages));
    for (uint32 i = (page - 1) * perPage; i < std::min(uint32(rows.size()), page * perPage); ++i)
    {
        auto tree = Write(*rows[i]);
        tree.erase("original");
        tree.put("allowed", Allowed(*rows[i]));
        SendRow(player, tree);
    }
    if (gm && Drafts.contains(player->GetGUID()))
    {
        auto const& draft = Drafts.at(player->GetGUID());
        if (draft.Kind == "zone" && Masks.contains(draft.Zone))
        {
            auto tree = Write(draft);
            tree.erase("original");
            tree.put("outline", true);
            SendRow(player, tree);
        }
    }
    Send(player, "E");
}

void SyncBuff(Player* player)
{
    Location const* best = nullptr;
    if (Enabled && player->IsInWorld() && player->FindMap() && !player->GetMap()->Instanceable() &&
        !sScriptMgr->OnPlayerHasNoBonusExperience(player))
        for (uint32 id : ActiveIds)
        {
            auto const& r = Locations.at(id);
            if (r.Ends > Now() && RotationAllowed(r) && Contains(r, player->GetMapId(), player->GetZoneId(),
                {player->GetPositionX(), player->GetPositionY()}) && (!best || r.Bonus > best->Bonus))
                best = &r;
        }
    if (!best)
    {
        player->RemoveAurasDueToSpell(Buff);
        return;
    }
    if (!player->HasAura(Buff))
        player->CastSpell(player, Buff, true);
    if (auto aura = player->GetAura(Buff))
    {
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
            if (auto effect = aura->GetEffect(i); effect && effect->GetAuraType() == SPELL_AURA_MOD_XP_PCT &&
                effect->GetAmount() != int32(best->Bonus))
                effect->ChangeAmount(best->Bonus);
        auto now = Now();
        auto remaining = int32((best->Ends > now ? std::min<uint64>(best->Ends - now, 86400) : 0) * 1000);
        if (std::abs(aura->GetDuration() - remaining) > 2000)
        {
            aura->SetMaxDuration(best->Duration * 1000);
            aura->SetDuration(remaining);
        }
    }
}

uint32 Continent(uint32 map, uint32 zone)
{
    if (map == 571)
        return 2;
    if (map == 530 && zone != 3430 && zone != 3433 && zone != 3487 &&
        zone != 3524 && zone != 3525 && zone != 3557)
        return 1;
    return map == 0 || map == 1 || map == 530 ? 0 : 3;
}

void Execute(Player* player, std::string const& command)
{
    std::istringstream input(command);
    std::string action;
    input >> action;
    uint32 map = player->GetMapId(), zone = player->GetZoneId(), page = 1;
    if (action == "sync" || action == "list")
    {
        input >> map >> zone >> page;
        std::string search;
        std::getline(input >> std::ws, search);
        Snapshot(player, map, zone, page, action == "list", search);
        return;
    }
    if (action == "outline")
    {
        uint32 id = 0;
        input >> id;
        if (Locations.contains(id) && Locations.at(id).Kind == "zone" &&
            !Masks.contains(Locations.at(id).Zone) && MaskRequests.size() < 20 &&
            (GM(player) || (RotationAllowed(Locations.at(id)) && Locations.at(id).Ends > Now())))
            MaskRequests[Locations.at(id).Zone] = Locations.at(id);
        return;
    }
    if (!GM(player))
    {
        Send(player, "ERROR|Game Master permission required.");
        return;
    }
    if (!CanManage(player->GetSession()->GetSecurity(), action))
    {
        Send(player, "ERROR|Level 3 GM is required to permanently delete hotspots.");
        return;
    }
    uint32 account = player->GetSession()->GetAccountId();
    ObjectGuid owner = player->GetGUID();
    if (action == "localbegin")
    {
        uint32 id = 0, revision = 0, parts = 0;
        LocalPaint.erase(owner);
        if (!(input >> id >> revision >> parts) || !parts || parts > 126 || !Drafts.contains(owner) ||
            Drafts.at(owner).Id != id || Drafts.at(owner).Revision != revision)
        {
            Send(player, "ERROR|Draft changed. Local painting retained; reopen the original draft before retrying.");
            return;
        }
        LocalPaint[owner] = {Drafts.at(owner), {}, parts, 0};
        return;
    }
    if (action == "localpart")
    {
        if (!LocalPaint.contains(owner))
            return;
        auto& upload = LocalPaint.at(owner);
        uint32 index = 0;
        if (!(input >> index) || index != upload.Next || index >= upload.Parts)
        {
            LocalPaint.erase(owner);
            Send(player, "ERROR|Incomplete drawing upload. Nothing saved; retry Save Draft.");
            return;
        }
        std::string part;
        std::getline(input >> std::ws, part);
        ++upload.Next;
        if (upload.Edits.size() + part.size() > 24000)
        {
            LocalPaint.erase(owner);
            Send(player, "ERROR|Local drawing exceeds the upload limit. Undo some strokes and retry.");
            return;
        }
        upload.Edits += part;
        return;
    }
    if (action == "general")
    {
        input >> std::ws;
        if (input.eof())
        {
            SendGeneral(player);
            return;
        }
        GeneralSettings settings;
        uint32 apply = 2;
        for (auto& value : settings.Values)
            if (!(input >> value))
            {
                Send(player, "ERROR|Invalid general settings. Nothing was saved.");
                return;
            }
        std::string extra;
        if (!(input >> apply) || apply > 1 || (input >> extra) || !ValidSettings(settings) ||
            settings.Values[SettingsRevision] != General.Values[SettingsRevision])
        {
            Send(player, "ERROR|Invalid or stale general settings. Refresh and try again.");
            return;
        }
        ++settings.Values[SettingsRevision];
        std::vector<Location> changes;
        if (apply)
            for (auto const& [id, row] : Locations)
            {
                if (row.Retired)
                    continue;
                auto r = row;
                r.Bonus = settings.Values[DefaultBonus];
                r.Duration = settings.Values[DefaultDuration];
                r.Cooldown = settings.Values[DefaultCooldown];
                if (r.Ends > Now())
                    r.Ends = r.Starts + r.Duration;
                ++r.Revision;
                changes.push_back(r);
            }
        if (!SaveMany(changes, &settings))
        {
            Send(player, "ERROR|Database save failed. General settings unchanged.");
            return;
        }
        LOG_INFO("commands.gm", "XPHotspots account {} saved general settings revision {}, apply defaults {}",
            account, settings.Values[SettingsRevision], apply);
        SendGeneral(player);
        Send(player, "OK|General settings saved. Rotation limits apply within one second.");
        return;
    }
    if (action == "new" || action == "newmap")
    {
        Location r;
        r.Bonus = General.Values[DefaultBonus];
        r.Duration = General.Values[DefaultDuration];
        r.Cooldown = General.Values[DefaultCooldown];
        input >> r.Kind;
        r.Map = player->GetMapId();
        r.Zone = player->GetZoneId();
        r.Continent = Continent(r.Map, r.Zone);
        r.Center = {player->GetPositionX(), player->GetPositionY()};
        if (action == "newmap")
        {
            if (!(input >> r.Map >> r.Zone >> r.Center.X >> r.Center.Y))
            {
                Send(player, "ERROR|Draft creation failed: invalid map coordinates. Reopen a zone map and try again.");
                return;
            }
            auto entry = sMapStore.LookupEntry(r.Map);
            auto area = sAreaTableStore.LookupEntry(r.Zone);
            if (!entry || entry->Instanceable() || !area || area->mapid != r.Map || area->zone ||
                !std::isfinite(r.Center.X) || !std::isfinite(r.Center.Y) ||
                std::abs(r.Center.X) > 20000 || std::abs(r.Center.Y) > 20000)
            {
                Send(player, "ERROR|Draft creation rejected for map " + std::to_string(r.Map) +
                    ", zone " + std::to_string(r.Zone) + ". Choose an outdoor zone map.");
                return;
            }
            r.Continent = Continent(r.Map, r.Zone);
        }
        std::getline(input >> std::ws, r.Name);
        r.Radius = 150;
        if (r.Kind != "circle" && r.Kind != "zone" && r.Kind != "polygon")
        {
            Send(player, "ERROR|Choose circle, zone or polygon.");
            return;
        }
        Drafts[owner] = r;
        PaintUndo.erase(owner);
        TraceDrafts.erase(owner);
        MergeSources.erase(owner);
        if (r.Kind == "zone" && !Masks.contains(r.Zone) && MaskRequests.size() < 20)
            MaskRequests[r.Zone] = r;
    }
    else if (action == "name")
    {
        if (!Drafts.contains(owner))
            return;
        std::string name;
        std::getline(input >> std::ws, name);
        if (name.empty() || name.size() > 100 || name.find('|') != std::string::npos)
            return;
        Drafts[owner].Name = name;
    }
    else if (action == "merge")
    {
        std::vector<std::pair<uint32, uint32>> sources;
        Location r;
        r.Bonus = General.Values[DefaultBonus];
        r.Duration = General.Values[DefaultDuration];
        r.Cooldown = General.Values[DefaultCooldown];
        r.Kind = "union";
        r.Source = "gm-merge";
        uint32 id = 0, revision = 0;
        std::set<uint32> ids;
        while (input >> id >> revision)
        {
            if (sources.size() >= 8 || !Locations.contains(id) || !ids.insert(id).second)
                return;
            auto const& part = Locations.at(id);
            if (part.Revision != revision || part.Retired || !Valid(part) || part.Kind == "zone" ||
                (!sources.empty() && (part.Map != r.Map || part.Zone != r.Zone)))
            {
                Send(player, "ERROR|Choose current non-zone areas on the same map and zone.");
                return;
            }
            if (sources.empty())
            {
                r.Map = part.Map;
                r.Zone = part.Zone;
                r.Continent = part.Continent;
                r.Name = part.Name;
                r.Center = part.Center;
            }
            sources.emplace_back(id, revision);
            if (part.Kind == "union")
                r.Parts.insert(r.Parts.end(), part.Parts.begin(), part.Parts.end());
            else
                r.Parts.push_back(part);
        }
        if (sources.size() < 2 || !Valid(r))
        {
            Send(player, "ERROR|Merge requires 2 to 8 areas, with at most 8 component boundaries.");
            return;
        }
        Drafts[owner] = r;
        MergeSources[owner] = std::move(sources);
        Send(player, "OK|Preview the combined area. Save retires its source entries; enable the saved area separately.");
    }
    else if (action == "tracebegin" || action == "tracepoints" || action == "traceend")
    {
        if (!Drafts.contains(owner) || Drafts.at(owner).Kind != "polygon")
            return;
        if (action == "tracebegin")
        {
            TraceDrafts[owner].clear();
            return;
        }
        if (!TraceDrafts.contains(owner))
            return;
        auto& points = TraceDrafts.at(owner);
        if (action == "tracepoints")
        {
            Point point;
            while (input >> point.X >> point.Y)
            {
                if (points.size() >= MaxPolygonPoints || !std::isfinite(point.X) || !std::isfinite(point.Y) ||
                    std::abs(point.X) > 20000 || std::abs(point.Y) > 20000)
                {
                    TraceDrafts.erase(owner);
                    Send(player, "ERROR|Invalid traced boundary. Draft unchanged.");
                    return;
                }
                points.push_back(point);
            }
            return;
        }
        if (!ValidPolygon(points))
        {
            TraceDrafts.erase(owner);
            Send(player, "ERROR|Traced boundary crosses itself or has too few points. Draft unchanged.");
            return;
        }
        PaintUndo[owner] = Drafts.at(owner);
        Drafts[owner].Points = points;
        Drafts[owner].Center = points.front();
        Drafts[owner].Source = "gm-trace";
        TraceDrafts.erase(owner);
    }
    else if (action == "shape" || action == "paintbegin" || action == "paintundo" || action == "brush")
    {
        if (!Drafts.contains(owner))
            return;
        auto candidate = Drafts.at(owner);
        if (action == "paintbegin")
        {
            PaintUndo[owner] = candidate;
            return;
        }
        if (action == "paintundo")
        {
            if (!PaintUndo.contains(owner))
                return;
            candidate = PaintUndo.at(owner);
            PaintUndo.erase(owner);
        }
        else if (action == "shape")
        {
            std::string kind;
            input >> kind;
            if (!ChangeShape(candidate, kind))
            {
                Send(player, "ERROR|Only circle and polygon drafts can convert. Preview a smaller boundary if needed.");
                return;
            }
            PaintUndo[owner] = Drafts.at(owner);
        }
        else if (action == "brush")
        {
            Point from, to;
            double radius = 0;
            std::string kind;
            if (!(input >> from.X >> from.Y >> to.X >> to.Y >> radius >> kind) ||
                (kind != "round" && kind != "square"))
                return;
            try
            {
                if (!Paint(candidate, from, to, radius, kind == "square"))
                {
                    Send(player, "ERROR|Brush must touch a valid polygon. Boundary too complex, disconnected or contains holes; undo or use smaller strokes.");
                    return;
                }
            }
            catch (std::exception const&)
            {
                Send(player, "ERROR|Brush boundary could not be combined. Draft unchanged.");
                return;
            }
        }
        Drafts[owner] = std::move(candidate);
    }
    else if (action == "point" || action == "center" || action == "radius" || action == "vertex")
    {
        if (!Drafts.contains(owner))
        {
            Send(player, "ERROR|Create or edit a draft first.");
            return;
        }
        auto& r = Drafts[owner];
        if (r.Kind == "union")
        {
            Send(player, "ERROR|Combined boundaries preserve their source shapes.");
            return;
        }
        uint32 vertex = 0;
        if (action == "vertex" && (!(input >> vertex) || !vertex || vertex > r.Points.size()))
            return;
        Point p{player->GetPositionX(), player->GetPositionY()};
        if (action == "radius")
        {
            double radius = 0;
            if (input >> radius && std::isfinite(radius) && radius >= 1 && radius <= 5000)
                r.Radius = radius;
        }
        else
        {
            if (input >> p.X)
            {
                if (!(input >> p.Y))
                    return;
            }
            if (!std::isfinite(p.X) || !std::isfinite(p.Y) || std::abs(p.X) > 20000 || std::abs(p.Y) > 20000 ||
                !sMapStore.LookupEntry(r.Map))
                return;
            if (action == "center")
            {
                r.Center = p;
                auto map = sMapMgr->CreateBaseMap(r.Map);
                if (!map || map->Instanceable())
                    return;
                r.Zone = map->GetZoneId(PHASEMASK_NORMAL, p.X, p.Y, 10000);
                r.Continent = Continent(r.Map, r.Zone);
                if (r.Kind == "zone" && !Masks.contains(r.Zone) && MaskRequests.size() < 20)
                    MaskRequests[r.Zone] = r;
            }
            else if (action == "vertex")
                r.Points[vertex - 1] = p;
            else if (r.Kind == "polygon" && r.Points.size() < MaxPolygonPoints)
                r.Points.push_back(p);
        }
    }
    else if (action == "edit")
    {
        uint32 id = 0;
        input >> id;
        if (!Locations.contains(id) || Locations.at(id).Retired)
            return;
        Drafts[owner] = Locations.at(id);
        PaintUndo.erase(owner);
        TraceDrafts.erase(owner);
        MergeSources.erase(owner);
    }
    else if (action == "undo" || action == "clear")
    {
        if (!Drafts.contains(owner))
            return;
        auto& points = Drafts[owner].Points;
        if (action == "clear")
            points.clear();
        else if (!points.empty())
            points.pop_back();
    }
    else if (action == "settings")
    {
        if (!Drafts.contains(owner))
            return;
        auto r = Drafts.at(owner);
        if (!(input >> r.Bonus >> r.Duration >> r.Weight >> r.Cooldown >> r.Icon >> r.Highlight))
            return;
        if (r.Bonus > 1000 || r.Duration < 60 || r.Duration > 86400 || r.Weight > 1000 || r.Cooldown > 604800)
            return;
        Drafts[owner] = r;
    }
    else if (action == "save" || action == "localsave")
    {
        if (!Drafts.contains(owner))
        {
            Send(player, "ERROR|No current draft. Select and edit a hotspot first.");
            return;
        }
        auto r = Drafts.at(owner);
        if (action == "localsave")
        {
            if (!LocalPaint.contains(owner))
            {
                Send(player, "ERROR|Local drawing upload is missing. Local painting retained; retry Save Draft.");
                return;
            }
            auto upload = std::move(LocalPaint.at(owner));
            LocalPaint.erase(owner);
            r = std::move(upload.Base);
            if (upload.Next != upload.Parts ||
                (r.Id && (!Locations.contains(r.Id) || Locations.at(r.Id).Revision != r.Revision)))
            {
                Send(player, "ERROR|Incomplete upload or hotspot changed. Nothing saved; local drawing retained.");
                return;
            }
            std::string paintError;
            if (!ApplyLocalPaint(r, upload.Edits, &paintError))
            {
                Send(player, "ERROR|" + (paintError.empty() ? std::string("Drawing exceeds input limits or has an invalid trace.") : paintError) +
                    " Nothing saved; undo or correct the red preview.");
                return;
            }
        }

        input >> std::ws;
        if (!input.eof())
        {
            if (!(input >> r.Bonus >> r.Duration >> r.Weight >> r.Cooldown >> r.Icon >> r.Highlight >> r.Radius))
            {
                Send(player, "ERROR|Invalid hotspot settings. Nothing was saved.");
                return;
            }
            std::getline(input >> std::ws, r.Name);
        }
        if (!Valid(r) || (r.Id && (!Locations.contains(r.Id) || Locations.at(r.Id).Revision != r.Revision)))
        {
            Send(player, "ERROR|Invalid boundary or stale edit. Reload the location and try again.");
            return;
        }
        if (!r.Id)
            r.Id = std::max(LocationIdFloor, Locations.empty() ? 1u : Locations.rbegin()->first + 1);
        else
        {
            auto const& current = Locations.at(r.Id);
            r.Starts = current.Starts;
            r.Ends = current.Ends;
            r.LastEnd = current.LastEnd;
            r.Queued = current.Queued;
        }
        ++r.Revision;
        r.Valid = true;
        if (r.Ends > Now())
            r.Ends = r.Starts + r.Duration;
        std::vector<Location> changes;
        if (MergeSources.contains(owner))
            for (auto [id, revision] : MergeSources.at(owner))
            {
                auto part = Locations.at(id);
                if (part.Revision != revision || part.Retired)
                {
                    Send(player, "ERROR|A merge source changed. Select the areas again.");
                    return;
                }
                part.Retired = true;
                part.Enabled = false;
                part.Ends = 0;
                part.Queued = 0;
                ++part.Revision;
                changes.push_back(part);
            }
        changes.push_back(r);
        if (!SaveMany(changes))
        {
            Send(player, "ERROR|Database save failed.");
            return;
        }
        Drafts[owner] = r;
        PaintUndo.erase(owner);
        TraceDrafts.erase(owner);
        MergeSources.erase(owner);
        if (action == "localsave")
            Send(player, "LOCALSAVED");
        LOG_INFO("commands.gm", "XPHotspots account {} saved location {} revision {}", account, r.Id, r.Revision);
    }
    else if (action == "teleport" || action == "delete")
    {
        uint32 id = 0, revision = 0;
        if (!(input >> id >> revision) || !revision || !Locations.contains(id) ||
            Locations.at(id).Revision != revision)
        {
            Send(player, "ERROR|Location changed or no longer exists. Refresh first.");
            return;
        }
        auto const r = Locations.at(id);
        if (action == "teleport")
        {
            if (!Allowed(r) || !Valid(r) || player->IsInCombat() || player->IsInFlight() ||
                player->IsBeingTeleported() || player->GetVehicle() || !player->IsAlive())
            {
                Send(player, "ERROR|Cannot teleport to this hotspot in the current state.");
                return;
            }
            auto entry = sMapStore.LookupEntry(r.Map);
            if (!entry || entry->Instanceable() || !MapMgr::IsValidMapCoord(r.Map, r.Center.X, r.Center.Y))
            {
                Send(player, "ERROR|Hotspot center is not on a valid outdoor map.");
                return;
            }
            auto map = sMapMgr->CreateBaseMap(r.Map);
            float x = r.Center.X, y = r.Center.Y;
            float z = map->GetHeight(x, y, MAX_HEIGHT);
            if (!std::isfinite(z) || z <= INVALID_HEIGHT || !MapMgr::IsValidMapCoord(r.Map, x, y, z))
            {
                Send(player, "ERROR|Safe terrain height is unavailable at this hotspot center.");
                return;
            }
            player->SaveRecallPosition();
            if (player->TeleportTo(r.Map, x, y, z, player->GetOrientation()))
                LOG_INFO("commands.gm", "XPHotspots account {} teleported to location {}", account, id);
            return;
        }
        uint32 floor = std::max(LocationIdFloor, Locations.rbegin()->first + 1);
        auto transaction = WorldDatabase.BeginTransaction();
        auto remove = WorldDatabase.GetPreparedStatement(WORLD_DEL_XP_HOTSPOT);
        remove->SetData(0, id);
        transaction->Append(remove);
        auto counter = WorldDatabase.GetPreparedStatement(WORLD_UPD_XP_HOTSPOT_SETTING);
        counter->SetData(0, LocationIdFloorSetting);
        counter->SetData(1, floor);
        transaction->Append(counter);
        if (!WorldDatabase.AsyncCommitTransaction(transaction).m_future.get())
        {
            Send(player, "ERROR|Database delete failed. Location was retained.");
            return;
        }
        LocationIdFloor = floor;
        Locations.erase(id);
        Records.erase(id);
        ActiveIds.erase(id);
        for (auto it = Drafts.begin(); it != Drafts.end();)
        {
            bool affected = it->second.Id == id;
            if (auto sources = MergeSources.find(it->first); sources != MergeSources.end())
                affected = affected || std::any_of(sources->second.begin(), sources->second.end(),
                    [id](auto const& source) { return source.first == id; });
            if (affected)
            {
                if (auto editor = ObjectAccessor::FindPlayer(it->first))
                    Send(editor, "DRAFTCLEARED|A hotspot used by this draft was permanently deleted.");
                MergeSources.erase(it->first);
                it = Drafts.erase(it);
            }
            else
                ++it;
        }
        ++Generation;
        LOG_INFO("commands.gm", "XPHotspots account {} permanently deleted location {}", account, id);
        Send(player, "DELETED|" + std::to_string(id));
        Send(player, "OK|Hotspot permanently deleted.");
        return;
    }
    else if (action == "enable" || action == "disable" || action == "next" || action == "stop")
    {
        uint32 id = 0, revision = 0;
        input >> id >> revision;
        if (!Locations.contains(id))
            return;
        auto r = Locations.at(id);
        if (revision && revision != r.Revision)
        {
            Send(player, "ERROR|Location changed. Refresh before editing.");
            return;
        }
        if (action == "next" && !RotationAllowed(r))
        {
            Send(player, "ERROR|Only full-zone hotspots can activate while the global filter is enabled.");
            return;
        }
        if ((action == "enable" || action == "next") && (!Allowed(r) || !Valid(r)))
        {
            Send(player, "ERROR|Location geometry or realm map restrictions prevent activation.");
            return;
        }
        if (action == "enable")
            r.Enabled = true;
        if (action == "disable")
            r.Enabled = false;
        if (action == "next")
        {
            if (r.Ends > Now())
            {
                Send(player, "ERROR|This location is already active.");
                return;
            }
            r.Enabled = true;
            r.Queued = Now();
            for (auto const& [otherId, other] : Locations)
                r.Queued = std::max(r.Queued, other.Queued + 1);
        }
        if (action == "stop" || action == "disable")
        {
            r.LastEnd = Now();
            r.Ends = 0;
            r.Queued = 0;
        }
        ++r.Revision;
        if (!Save(r))
            Send(player, "ERROR|Database save failed.");
        else
        {
            LOG_INFO("commands.gm", "XPHotspots account {} applied {} to location {}", account, action, id);
            Send(player, "OK|Location updated.");
        }
        return;
    }
    else if (action == "announce")
    {
        uint32 value = 2;
        if (!(input >> value) || value > 1)
            return;
        auto settings = General;
        settings.Values[Announcements] = value;
        ++settings.Values[SettingsRevision];
        if (!SaveMany({}, &settings))
        {
            Send(player, "ERROR|Database save failed.");
            return;
        }
        LOG_INFO("commands.gm", "XPHotspots account {} set announcements to {}", account, value);
        SendGeneral(player);
        Send(player, "OK|Announcement setting saved.");
        return;
    }
    else if (action == "cancel")
    {
        Drafts.erase(owner);
        LocalPaint.erase(owner);
        PaintUndo.erase(owner);
        TraceDrafts.erase(owner);
        MergeSources.erase(owner);
        Send(player, "OK|Draft discarded.");
        return;
    }
    else if (action != "preview" && action != "paintend")
    {
        Send(player, "ERROR|Commands: list, new, edit, center, radius, point, undo, clear, settings, "
            "preview, save, enable, disable, next, stop, announce, cancel.");
        return;
    }
    if (Drafts.contains(owner))
    {
        if (TextReply)
        {
            auto const& r = Drafts.at(owner);
            Send(player, "Draft " + std::to_string(r.Id) + ": " + r.Name + " (" + r.Kind + "), center " +
                std::to_string(r.Center.X) + ", " + std::to_string(r.Center.Y) + ", radius " +
                std::to_string(r.Radius) + ", points " + std::to_string(r.Points.size()));
            return;
        }
        auto t = Write(Drafts.at(owner));
        t.put("draft", true);
        SendRow(player, t);
        if (action == "shape" || action == "paintend")
            Send(player, "PAINTREADY");
        else if (action != "brush")
            Send(player, "OK|Draft updated. Save then enable to join the rotation.");
    }
}

class Service final : public WorldScript
{
public:
    Service() : WorldScript("XPHotspots") { }

    void OnStartup() override
    {
        std::lock_guard lock(Mutex);
        Enabled = sConfigMgr->GetOption<bool>("XPHotspots.Enable", false);
        Brand = sConfigMgr->GetOption<std::string>("XPHotspots.Brand", "");
        if (Brand.size() > 32 || std::any_of(Brand.begin(), Brand.end(),
            [](unsigned char c) { return c < 32 || c == '|'; }))
            Brand.clear();
        uint32 expansion = std::min(2u, sWorld->getIntConfig(CONFIG_EXPANSION));
        MaxContinent = std::min(expansion, sConfigMgr->GetOption<uint32>("XPHotspots.MaxContinent", 2));
        General.Values[ActiveCount] = std::clamp(sConfigMgr->GetOption<uint32>("XPHotspots.ActiveCount", 3), 0u, 20u);
        Buff = sConfigMgr->GetOption<uint32>("XPHotspots.BuffSpell", 993945);
        if (!Enabled)
            return;
        auto spell = sSpellMgr->GetSpellInfo(Buff);
        bool validBuff = spell && spell->HasAura(SPELL_AURA_MOD_XP_PCT);
        if (spell)
            for (auto const& effect : spell->GetEffects())
                if (effect.Effect && (effect.Effect != SPELL_EFFECT_APPLY_AURA ||
                    effect.ApplyAuraName != SPELL_AURA_MOD_XP_PCT || effect.MiscValue != 1))
                    validBuff = false;
        if (!validBuff)
        {
            Enabled = false;
            LOG_ERROR("server.loading", "XPHotspots disabled: buff {} must only apply monster-kill XP", Buff);
            return;
        }
        if (auto settings = WorldDatabase.Query(WorldDatabase.GetPreparedStatement(WORLD_SEL_XP_HOTSPOT_SETTING)))
        {
            auto loaded = General;
            do
            {
                uint32 id = settings->Fetch()[0].Get<uint32>();
                if (id >= 1 && id <= SettingCount)
                    loaded.Values[id - 1] = settings->Fetch()[1].Get<uint32>();
                else if (id == LocationIdFloorSetting)
                    LocationIdFloor = std::max(LocationIdFloor, settings->Fetch()[1].Get<uint32>());
            } while (settings->NextRow());
            if (ValidSettings(loaded))
                General = loaded;
            else
                LOG_ERROR("server.loading", "Invalid XP hotspot general settings; using startup defaults");
        }
        if (auto rows = WorldDatabase.Query(WorldDatabase.GetPreparedStatement(WORLD_SEL_XP_HOTSPOTS)))
            do
            {
                try
                {
                    auto t = Parse(rows->Fetch()[1].Get<std::string>());
                    auto id = rows->Fetch()[0].Get<uint32>();
                    if (id != t.get<uint32>("id"))
                        continue;
                    if (id < UINT32_MAX)
                        LocationIdFloor = std::max(LocationIdFloor, id + 1);
                    if (t.get<bool>("retired", false))
                        continue;
                    auto r = Read(t);
                    if (r.Id != id)
                        continue;
                    r.Valid = r.Valid && Valid(r);
                    Records[r.Id] = t;
                    Locations[r.Id] = r;
                    if (r.Enabled && r.Ends > Now() && RotationAllowed(r))
                    {
                        ActiveIds.insert(r.Id);
                        if (r.Kind == "zone")
                            MaskRequests[r.Zone] = r;
                    }
                }
                catch (std::exception const& e)
                {
                    LOG_ERROR("server.loading", "Invalid hotspot record: {}", e.what());
                }
            } while (rows->NextRow());
    }

    void OnUpdate(uint32 diff) override
    {
        if (!Enabled)
            return;
        std::lock_guard lock(Mutex);
        if (!MaskRequests.empty())
        {
            auto request = MaskRequests.begin();
            if (BuildMask(request->second))
            {
                MaskRequests.erase(MaskRequests.begin());
                ++Generation;
            }
        }
        if ((WorldTimer += diff) < 1000)
            return;
        WorldTimer = 0;
        uint64 now = Now();
        std::vector<uint32> activeZones;
        std::array<uint32, SettingCount> counts{};
        for (auto const& [id, r] : Locations)
        {
            if (r.Ends && (r.Ends <= now || !RotationAllowed(r) || !r.Enabled ||
                !QuotaAvailable(General, counts, ContinentQuota(r.Map, r.Zone), FactionQuota(r))))
            {
                auto changed = r;
                changed.LastEnd = std::min(r.Ends, now);
                changed.Ends = 0;
                if (!Save(changed))
                    return;
            }
            if (r.Ends > now)
            {
                ++counts[ActiveCount];
                ++counts[ContinentQuota(r.Map, r.Zone)];
                ++counts[FactionQuota(r)];
                activeZones.push_back(r.Zone);
            }
        }
        while (counts[ActiveCount] < General.Values[ActiveCount])
        {
            std::vector<Location const*> candidates;
            uint32 total = 0;
            for (auto const& [id, r] : Locations)
                if (RotationAllowed(r) && Eligible(r, MaxContinent, now) &&
                    QuotaAvailable(General, counts, ContinentQuota(r.Map, r.Zone), FactionQuota(r)) &&
                    std::find(activeZones.begin(), activeZones.end(), r.Zone) == activeZones.end())
                {
                    candidates.push_back(&r);
                    total += r.Weight;
                }
            if (candidates.empty())
                break;
            auto selected = Select(candidates, total ? urand(1, total) : 0);
            if (!selected)
                break;
            auto r = *selected;
            if (r.Kind == "zone")
                MaskRequests[r.Zone] = r;
            r.Starts = now;
            r.Ends = now + r.Duration;
            r.Queued = 0;
            if (!Save(r))
                break;
            ++counts[ActiveCount];
            ++counts[ContinentQuota(r.Map, r.Zone)];
            ++counts[FactionQuota(r)];
            activeZones.push_back(r.Zone);
            if (General.Values[Announcements])
            {
                auto message = "XP Hotspot: " + r.Name + " — +" + std::to_string(r.Bonus) +
                    "% monster-kill XP for " + std::to_string(r.Duration / 60) + " minutes.";
                std::shared_lock playersLock(*HashMapHolder<Player>::GetLock());
                for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
                    if (player->IsInWorld())
                        ChatHandler(player->GetSession()).SendSysMessage(message.c_str());
            }
        }
    }
};

class Players final : public PlayerScript
{
public:
    Players() : PlayerScript("XPHotspotsPlayer", {PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT, PLAYERHOOK_ON_REWARD_KILL_REWARDER}) { }

    void OnPlayerLogin(Player* p) override
    {
        if (!Enabled)
            return;
        std::lock_guard lock(Mutex);
        SyncBuff(p);
    }

    void OnPlayerLogout(Player* p) override
    {
        std::lock_guard lock(Mutex);
        if (Enabled)
            p->RemoveAurasDueToSpell(Buff);
        Timers.erase(p->GetGUID());
        Seen.erase(p->GetGUID());
        Drafts.erase(p->GetGUID());
        PaintUndo.erase(p->GetGUID());
        TraceDrafts.erase(p->GetGUID());
        LocalPaint.erase(p->GetGUID());
        MergeSources.erase(p->GetGUID());
        Requests.erase(p->GetGUID());
    }

    void OnPlayerUpdate(Player* p, uint32 diff) override
    {
        if (!Enabled)
            return;
        std::lock_guard lock(Mutex);
        if ((Timers[p->GetGUID()] += diff) < 500)
            return;
        Timers[p->GetGUID()] = 0;
        SyncBuff(p);
        if (Seen[p->GetGUID()] != Generation)
        {
            Seen[p->GetGUID()] = Generation;
            Send(p, "CHANGED|" + std::to_string(Generation));
        }
    }

    void OnPlayerRewardKillRewarder(Player* p, KillRewarder*, bool, float&) override
    {
        if (!Enabled)
            return;
        std::lock_guard lock(Mutex);
        SyncBuff(p);
    }

    bool OnPlayerCanUseChat(Player* p, uint32 type, uint32 language, std::string& message, Player* receiver) override
    {
        if (type != CHAT_MSG_WHISPER || language != LANG_ADDON || !message.starts_with(Prefix))
            return true;
        if (receiver != p)
            return false;
        std::lock_guard lock(Mutex);
        ObjectGuid owner = p->GetGUID();
        uint64 now = GameTime::GetGameTimeMS().count();
        if (message.size() > 255)
            return false;
        if (!Requests[owner].Accept(now))
        {
            Send(p, "ERROR|Too many hotspot requests. Wait a moment and retry the last action.");
            return false;
        }
        if (!Enabled)
        {
            Send(p, "OFF");
            return false;
        }
        try
        {
            Execute(p, message.substr(sizeof(Prefix) - 1));
        }
        catch (std::exception const&)
        {
            Send(p, "ERROR|Invalid hotspot request.");
        }
        return false;
    }
};

class Commands final : public CommandScript
{
public:
    Commands() : CommandScript("XPHotspotCommands") { }
    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commands = {{"hotspot", Handle, rbac::RBAC_PERM_COMMAND_EVENT_START, Console::No}};
        return commands;
    }
    static bool Handle(ChatHandler* handler, char const* args)
    {
        std::lock_guard lock(Mutex);
        if (!Enabled || !GM(handler->GetPlayer()))
        {
            handler->SendSysMessage("XP hotspots are disabled or Game Master permission is required.");
            return true;
        }
        TextReply = true;
        try
        {
            Execute(handler->GetPlayer(), args && *args ? args : "list");
        }
        catch (std::exception const&)
        {
            handler->SendSysMessage("Invalid hotspot command.");
        }
        TextReply = false;
        return true;
    }
};

class SpellContract final : public GlobalScript
{
public:
    SpellContract() : GlobalScript("XPHotspotSpellContract", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}),
        _enabled(sConfigMgr->GetOption<bool>("XPHotspots.Enable", false)),
        _spell(sConfigMgr->GetOption<uint32>("XPHotspots.BuffSpell", 993945)) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (!_enabled || !info || info->Id != _spell)
            return;
        info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
    }

private:
    bool _enabled;
    uint32 _spell;
};
}
}

void AddSC_XPHotspots()
{
    new XPHotspots::Service();
    new XPHotspots::Players();
    new XPHotspots::Commands();
    new XPHotspots::SpellContract();
}
