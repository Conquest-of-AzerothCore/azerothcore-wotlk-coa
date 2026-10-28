#ifndef XP_HOTSPOT_RULES_H
#define XP_HOTSPOT_RULES_H

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace XPHotspots
{
inline bool CanManage(uint32_t security, std::string_view action)
{
    return security >= 2 && (action != "delete" || security >= 3);
}

struct RequestWindow
{
    uint64_t Started = 0;
    uint32_t Count = 0;

    bool Accept(uint64_t now)
    {
        if (now - Started >= 1000)
        {
            Started = now;
            Count = 0;
        }
        if (Count >= 8)
            return false;
        ++Count;
        return true;
    }
};

enum Setting : size_t
{
    Announcements, ActiveCount, DefaultBonus, DefaultDuration, DefaultCooldown,
    EasternKingdoms, Kalimdor, Outland, Northrend, Alliance, Horde, Neutral, SettingsRevision, FullZoneOnly, SettingCount
};

struct GeneralSettings
{
    std::array<uint32_t, SettingCount> Values = {1, 3, 150, 3600, 3600, 20, 20, 20, 20, 20, 20, 20, 1, 0};
};

inline bool ValidSettings(GeneralSettings const& settings)
{
    auto const& v = settings.Values;
    return v[FullZoneOnly] <= 1 && v[Announcements] <= 1 && v[ActiveCount] <= 20 && v[DefaultBonus] <= 1000 &&
        v[DefaultDuration] >= 60 && v[DefaultDuration] <= 86400 && v[DefaultCooldown] <= 604800 &&
        v[SettingsRevision] > 0 && v[SettingsRevision] < UINT32_MAX &&
        std::all_of(v.begin() + EasternKingdoms, v.begin() + SettingsRevision,
            [](uint32_t cap) { return cap <= 20; });
}

inline bool RotationShapeAllowed(GeneralSettings const& settings, std::string const& kind)
{
    return !settings.Values[FullZoneOnly] || kind == "zone";
}

inline size_t ContinentQuota(uint32_t map, uint32_t zone)
{
    if (map == 0 || (map == 530 && (zone == 3430 || zone == 3433 || zone == 3487)))
        return EasternKingdoms;
    if (map == 1 || (map == 530 && (zone == 3524 || zone == 3525 || zone == 3557)))
        return Kalimdor;
    return map == 530 ? Outland : Northrend;
}

inline bool QuotaAvailable(GeneralSettings const& settings, std::array<uint32_t, SettingCount> const& counts,
    size_t continent, size_t faction)
{
    return counts[ActiveCount] < settings.Values[ActiveCount] &&
        counts[continent] < settings.Values[continent] && counts[faction] < settings.Values[faction];
}

constexpr size_t MaxPolygonPoints = 256;

struct Point
{
    double X = 0;
    double Y = 0;
};

struct Location
{
    uint32_t Id = 0;
    uint32_t Revision = 1;
    uint32_t Map = 0;
    uint32_t Zone = 0;
    uint32_t Continent = 0;
    std::string Name;
    std::string Kind = "circle";
    std::string Source = "gm";
    Point Center;
    double Radius = 150;
    std::vector<Point> Points;
    std::vector<Location> Parts;
    uint32_t Bonus = 150;
    uint32_t Duration = 3600;
    uint32_t Weight = 1;
    uint32_t Cooldown = 3600;
    uint64_t Queued = 0;
    uint64_t Starts = 0;
    uint64_t Ends = 0;
    uint64_t LastEnd = 0;
    bool Enabled = false;
    bool Valid = true;
    bool Icon = true;
    bool Highlight = true;
    bool Retired = false;
};

inline double Cross(Point a, Point b, Point p)
{
    return (b.X - a.X) * (p.Y - a.Y) - (b.Y - a.Y) * (p.X - a.X);
}

inline bool OnSegment(Point a, Point b, Point p)
{
    return std::abs(Cross(a, b, p)) < 0.0001 &&
        p.X >= std::min(a.X, b.X) - 0.0001 && p.X <= std::max(a.X, b.X) + 0.0001 &&
        p.Y >= std::min(a.Y, b.Y) - 0.0001 && p.Y <= std::max(a.Y, b.Y) + 0.0001;
}

inline bool Intersects(Point a, Point b, Point c, Point d)
{
    return OnSegment(a, b, c) || OnSegment(a, b, d) || OnSegment(c, d, a) || OnSegment(c, d, b) ||
        ((Cross(a, b, c) > 0) != (Cross(a, b, d) > 0) &&
         (Cross(c, d, a) > 0) != (Cross(c, d, b) > 0));
}

inline bool ValidPolygon(std::vector<Point> const& points)
{
    if (points.size() < 3 || points.size() > MaxPolygonPoints)
        return false;
    double area = 0;
    for (size_t i = 0; i < points.size(); ++i)
    {
        auto a = points[i];
        auto b = points[(i + 1) % points.size()];
        auto previous = points[(i + points.size() - 1) % points.size()];
        if (!std::isfinite(a.X) || !std::isfinite(a.Y) || std::abs(a.X) > 20000 ||
            std::abs(a.Y) > 20000 || (a.X == b.X && a.Y == b.Y))
            return false;
        if (std::abs(Cross(previous, a, b)) < 0.0001 &&
            (previous.X - a.X) * (b.X - a.X) + (previous.Y - a.Y) * (b.Y - a.Y) > 0)
            return false;
        area += a.X * b.Y - b.X * a.Y;
        for (size_t j = i + 1; j < points.size(); ++j)
            if (j != i + 1 && !(i == 0 && j == points.size() - 1) &&
                Intersects(a, b, points[j], points[(j + 1) % points.size()]))
                return false;
    }
    return std::abs(area) > 1;
}

inline bool Contains(Location const& row, uint32_t map, uint32_t zone, Point p)
{
    if (row.Map != map)
        return false;
    if (row.Kind == "zone")
        return row.Zone == zone;
    if (row.Kind == "circle")
        return std::hypot(p.X - row.Center.X, p.Y - row.Center.Y) <= row.Radius;
    if (row.Kind == "union")
        return std::any_of(row.Parts.begin(), row.Parts.end(), [&](Location const& part)
        {
            return Contains(part, map, zone, p);
        });
    bool inside = false;
    for (size_t i = 0, j = row.Points.size() - 1; i < row.Points.size(); j = i++)
    {
        auto a = row.Points[i];
        auto b = row.Points[j];
        if (OnSegment(a, b, p))
            return true;
        if ((a.Y > p.Y) != (b.Y > p.Y) && p.X < (b.X - a.X) * (p.Y - a.Y) / (b.Y - a.Y) + a.X)
            inside = !inside;
    }
    return inside;
}

inline bool Eligible(Location const& row, uint32_t continent, uint64_t now)
{
    return !row.Retired && row.Enabled && row.Valid && row.Continent <= continent && (row.Weight || row.Queued) &&
        row.Ends <= now && (row.Queued || row.LastEnd + row.Cooldown <= now);
}

inline Location const* Select(std::vector<Location> const& candidates, uint32_t roll)
{
    Location const* queued = nullptr;
    for (auto const& row : candidates)
        if (row.Queued && (!queued || row.Queued > queued->Queued))
            queued = &row;
    if (queued)
        return queued;
    if (!roll)
        return nullptr;
    for (auto const& row : candidates)
    {
        if (roll <= row.Weight)
            return &row;
        roll -= row.Weight;
    }
    return nullptr;
}
inline Location const* Select(std::vector<Location const*> const& candidates, uint32_t roll)
{
    Location const* queued = nullptr;
    for (auto const* row : candidates)
        if (row->Queued && (!queued || row->Queued > queued->Queued))
            queued = row;
    if (queued)
        return queued;
    if (!roll)
        return nullptr;
    for (auto const* row : candidates)
    {
        if (roll <= row->Weight)
            return row;
        roll -= row->Weight;
    }
    return nullptr;
}

inline bool Valid(Location const& row)
{
    return !row.Name.empty() && row.Name.size() <= 100 && row.Bonus <= 1000 &&
        std::none_of(row.Name.begin(), row.Name.end(), [](unsigned char c) { return c < 32 || c == '|'; }) &&
        row.Duration >= 60 && row.Duration <= 86400 && row.Weight <= 1000 && row.Cooldown <= 604800 &&
        std::isfinite(row.Center.X) && std::isfinite(row.Center.Y) &&
        std::abs(row.Center.X) <= 20000 && std::abs(row.Center.Y) <= 20000 &&
        ((row.Kind == "zone" && row.Zone) ||
         (row.Kind == "circle" && std::isfinite(row.Radius) && row.Radius >= 1 && row.Radius <= 5000) ||
         (row.Kind == "polygon" && ValidPolygon(row.Points)) ||
         (row.Kind == "union" && !row.Parts.empty() && row.Parts.size() <= 8 &&
          std::all_of(row.Parts.begin(), row.Parts.end(), [&](Location const& part)
          {
              return (part.Kind == "circle" || part.Kind == "polygon") &&
                  part.Map == row.Map && part.Zone == row.Zone && Valid(part);
          })));
}
}

#endif
