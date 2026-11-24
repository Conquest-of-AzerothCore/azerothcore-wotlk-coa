#include "PetScale.h"
#include <algorithm>

namespace CoAPetBattles::Battle
{
    namespace
    {
        constexpr double TargetRadius = 0.40;
        constexpr double TargetReach = 0.75;
        constexpr double MinFallback = 0.1;
        constexpr double MaxFallback = 1.5;
        constexpr double UnknownScale = 0.4;
        constexpr double PetSize = 0.53;
        constexpr double CompanionMax = 0.9;
        constexpr double MinScale = 0.02;
        constexpr double MaxScale = 8.0;
        constexpr double Unmeasured = 0.01;
    }

    double ScaleFor(double radius, double reach)
    {
        std::optional<double> scale;
        if (radius > 0.05)
            scale = TargetRadius / radius;
        if (reach > 0.05)
        {
            double const byReach = TargetReach / reach;
            scale = scale ? std::min(*scale, byReach) : byReach;
        }
        if (!scale)
            return UnknownScale;
        return std::max(MinFallback, std::min(MaxFallback, *scale));
    }

    PetScale::PetScale(DataSet const& data, ModelInfoLookup modelInfo) : _data(&data), _modelInfo(std::move(modelInfo))
    {
    }

    double PetScale::FromSize(uint32_t species, double size) const
    {
        auto const found = _data->species.find(species);
        double scale = 0;
        if (found != _data->species.end() && found->second.companion)
        {
            scale = found->second.scale > 0 ? static_cast<double>(found->second.scale) : 1.0;
            if (size * scale > CompanionMax)
                scale = CompanionMax / size;
        }
        else
            scale = PetSize / size;
        return std::max(MinScale, std::min(MaxScale, scale));
    }

    double PetScale::Scale(uint32_t species) const
    {
        auto const size = _data->modelSizes.find(species);
        double const silhouette = size == _data->modelSizes.end() ? 0 : static_cast<double>(size->second.silhouette);
        if (silhouette > Unmeasured)
            return FromSize(species, silhouette);
        auto const found = _data->species.find(species);
        if (found == _data->species.end())
            return UnknownScale;
        if (found->second.scale > 0)
            return static_cast<double>(found->second.scale);
        if (found->second.companion)
            return 1.0;
        std::optional<std::pair<double, double>> const info = _modelInfo ? _modelInfo(species) : std::nullopt;
        return ScaleFor(info ? info->first : 0, info ? info->second : 0);
    }

    double PetScale::ScaleOf(uint32_t species, uint32_t display) const
    {
        auto const size = display ? _data->displaySizes.find(display) : _data->displaySizes.end();
        double const silhouette = size == _data->displaySizes.end() ? 0 : static_cast<double>(size->second.silhouette);
        if (silhouette <= Unmeasured)
            return Scale(species);
        return FromSize(species, silhouette);
    }
}
