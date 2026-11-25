#ifndef COA_PET_BATTLE_BATTLE_PET_SCALE_H
#define COA_PET_BATTLE_BATTLE_PET_SCALE_H

#include "PetBattleData.h"
#include <functional>
#include <optional>
#include <utility>

namespace CoAPetBattles::Battle
{
    using ModelInfoLookup = std::function<std::optional<std::pair<double, double>>(uint32_t species)>;

    double ScaleFor(double radius, double reach);

    class PetScale
    {
    public:
        PetScale(DataSet const& data, ModelInfoLookup modelInfo);

        double Scale(uint32_t species) const;
        double ScaleOf(uint32_t species, uint32_t display) const;

    private:
        double FromSize(uint32_t species, double size) const;

        DataSet const* _data;
        ModelInfoLookup _modelInfo;
    };
}

#endif
