#ifndef COA_PET_BATTLE_ENGINE_DESCRIBE_H
#define COA_PET_BATTLE_ENGINE_DESCRIBE_H

#include "Catalog.h"
#include <optional>
#include <string>
#include <vector>

namespace CoAPetBattles::Engine
{
    struct DescribeSource
    {
        std::string text;
        std::vector<Turn> const* turns = nullptr;
        double family = -1;
        std::optional<uint32_t> id;
    };

    std::optional<double> LuaToNumber(std::string const& text);
    std::optional<double> LuaArith(std::string const& text);
    std::string Describe(Catalog const& catalog, DescribeSource const& ability, double power,
        bool* usedUnorderedFallback = nullptr);
    std::string AuraTip(Catalog const& catalog, uint32_t id, double power);
}

#endif
