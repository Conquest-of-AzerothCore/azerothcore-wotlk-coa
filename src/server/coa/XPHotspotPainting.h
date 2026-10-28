#ifndef XP_HOTSPOT_PAINTING_H
#define XP_HOTSPOT_PAINTING_H

#include "XPHotspotRules.h"
#include <boost/geometry.hpp>
#include <sstream>

namespace XPHotspots
{
inline bool Paint(Location& row, Point from, Point to, double radius, bool square, std::string* error = nullptr)
{
    auto fail = [&](char const* reason)
    {
        if (error)
            *error = reason;
        return false;
    };
    namespace bg = boost::geometry;
    using XY = bg::model::d2::point_xy<double>;
    using Polygon = bg::model::polygon<XY>;
    if (row.Kind != "polygon" || !std::isfinite(radius) || radius < 5 || radius > 1000 ||
        !std::isfinite(from.X) || !std::isfinite(from.Y) || !std::isfinite(to.X) || !std::isfinite(to.Y) ||
        std::abs(from.X) > 19000 || std::abs(from.Y) > 19000 ||
        std::abs(to.X) > 19000 || std::abs(to.Y) > 19000 ||
        std::hypot(to.X - from.X, to.Y - from.Y) > 5000)
        return false;
    bg::model::multi_point<XY> samples;
    for (Point center : {from, to})
        for (size_t i = 0; i < (square ? 4u : 24u); ++i)
        {
            double angle = 6.283185307179586 * i / (square ? 4 : 24) + (square ? 0.7853981633974483 : 0);
            double reach = radius * (square ? std::sqrt(2.0) : 1);
            samples.emplace_back(center.X + reach * std::cos(angle), center.Y + reach * std::sin(angle));
        }
    Polygon stroke;
    bg::convex_hull(samples, stroke);
    Polygon result = stroke;
    if (row.Points.size() >= 3)
    {
        if (!ValidPolygon(row.Points))
            return false;
        Polygon original;
        for (Point point : row.Points)
            original.outer().emplace_back(point.X, point.Y);
        bg::correct(original);
        std::vector<Polygon> joined;
        bg::union_(original, stroke, joined);
        if (joined.size() != 1)
            return fail("Brush must overlap the existing area; separate islands require another hotspot.");
        if (!joined.front().inners().empty())
            return fail("Stroke encloses a hole. Fill the gap or undo this stroke.");
        result = joined.front();
    }
    if (result.outer().size() > MaxPolygonPoints + 1)
    {
        for (double tolerance : {2.0, 5.0, 10.0, 20.0})
        {
            Polygon reduced;
            bg::simplify(result, reduced, tolerance);
            if (bg::is_valid(reduced) && reduced.outer().size() <= MaxPolygonPoints + 1)
            {
                result = std::move(reduced);
                break;
            }
        }
    }
    std::vector<Point> points;
    for (size_t i = 0; i + 1 < result.outer().size(); ++i)
    {
        Point point{bg::get<0>(result.outer()[i]), bg::get<1>(result.outer()[i])};
        if (points.empty() || std::hypot(point.X - points.back().X, point.Y - points.back().Y) > 1e-7)
            points.push_back(point);
    }
    if (points.size() > 1 && std::hypot(points.front().X - points.back().X,
        points.front().Y - points.back().Y) <= 1e-7)
        points.pop_back();
    if (points.size() > MaxPolygonPoints)
        return fail("Boundary exceeds 256 points after 20-yard smoothing. Undo or simplify this stroke.");
    if (!ValidPolygon(points))
        return fail("Boundary intersects itself or exceeds map coordinates. Undo this stroke.");
    if (row.Points.size() < 3)
        row.Center = from;
    row.Points = std::move(points);
    row.Source = "gm-paint";
    return true;
}

inline bool ChangeShape(Location& row, std::string const& kind)
{
    if ((kind != "circle" && kind != "polygon") || (row.Kind != "circle" && row.Kind != "polygon"))
        return false;
    if (kind == row.Kind)
        return true;
    if (kind == "circle")
    {
        if (!ValidPolygon(row.Points))
            return false;
        Point center;
        for (Point point : row.Points)
        {
            center.X += point.X / row.Points.size();
            center.Y += point.Y / row.Points.size();
        }
        double radius = 1;
        for (Point point : row.Points)
            radius = std::max(radius, std::hypot(point.X - center.X, point.Y - center.Y));
        if (radius > 5000)
            return false;
        row.Center = center;
        row.Radius = radius;
        row.Points.clear();
    }
    else
    {
        row.Points.clear();
        for (size_t i = 0; i < 24; ++i)
        {
            double angle = 6.283185307179586 * i / 24;
            row.Points.push_back({row.Center.X + row.Radius * std::cos(angle),
                row.Center.Y + row.Radius * std::sin(angle)});
        }
        if (!ValidPolygon(row.Points))
            return false;
    }
    row.Kind = kind;
    row.Source = "gm-shape";
    return true;
}
inline bool ApplyLocalPaint(Location& row, std::string const& edits, std::string* error = nullptr)
{
    if (edits.size() > 24000 || row.Kind != "polygon")
        return false;
    Location candidate = row;
    std::istringstream stream(edits);
    std::string operation;
    size_t count = 0;
    while (std::getline(stream, operation, ';'))
    {
        if (operation.empty() || ++count > 192)
            return false;
        std::istringstream input(operation);
        std::string kind, extra;
        input >> kind;
        if (kind == "T")
            candidate.Points.clear();
        else if (kind == "P")
        {
            Point point;
            if (!(input >> point.X >> point.Y) || candidate.Points.size() >= MaxPolygonPoints ||
                !std::isfinite(point.X) || !std::isfinite(point.Y) ||
                std::abs(point.X) > 20000 || std::abs(point.Y) > 20000)
                return false;
            candidate.Points.push_back(point);
        }
        else if (kind == "B")
        {
            Point from, to;
            double radius = 0;
            uint32_t square = 0;
            if (!(input >> from.X >> from.Y >> to.X >> to.Y >> radius >> square) || square > 1 ||
                !Paint(candidate, from, to, radius, square != 0, error))
                return false;
        }
        else
            return false;
        if (input >> extra)
            return false;
    }
    if (!count || !ValidPolygon(candidate.Points))
        return false;
    candidate.Source = "gm-local-paint";
    row = std::move(candidate);
    return true;
}

}

#endif
