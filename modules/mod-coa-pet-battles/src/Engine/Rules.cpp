#include "Rules.h"
#include <algorithm>
#include <cmath>
#include <map>

namespace CoAPetBattles::Engine
{
    namespace
    {
        std::map<std::string, std::string> const Strong = { { "Humanoid", "Dragonkin" }, { "Dragonkin", "Magic" },
            { "Magic", "Flying" }, { "Flying", "Aquatic" }, { "Aquatic", "Elemental" }, { "Elemental", "Mechanical" },
            { "Mechanical", "Beast" }, { "Beast", "Critter" }, { "Critter", "Undead" }, { "Undead", "Humanoid" } };
        std::map<std::string, std::string> const Weak = { { "Humanoid", "Beast" }, { "Dragonkin", "Undead" },
            { "Flying", "Dragonkin" }, { "Undead", "Aquatic" }, { "Critter", "Humanoid" }, { "Magic", "Mechanical" },
            { "Elemental", "Critter" }, { "Beast", "Flying" }, { "Aquatic", "Magic" }, { "Mechanical", "Elemental" } };

        double Base(double modifier)
        {
            return 8.0 + modifier / 100.0;
        }
    }

    std::optional<std::string> FamilyAt(double luaIndex)
    {
        if (luaIndex < 1.0 || luaIndex > static_cast<double>(Families.size()) || luaIndex != std::floor(luaIndex))
            return std::nullopt;
        return Families[static_cast<size_t>(luaIndex) - 1];
    }

    double QualityMult(double quality)
    {
        return 1.0 + 0.1 * std::max(1.0, std::min(4.0, quality));
    }

    Stats PetStats(double power, double speed, double stamina, double level, double quality, double maxLevel)
    {
        level = std::max(1.0, std::min(maxLevel, level));
        double const q = QualityMult(quality);
        Stats stats;
        stats.health = std::floor(Base(stamina) * level * q * 5 + 100 + 0.5);
        stats.power = Base(power) * level * q;
        stats.speed = Base(speed) * level * q;
        return stats;
    }

    double Matchup(std::string const& attacker, std::string const& defender)
    {
        auto const strong = Strong.find(attacker);
        if (strong != Strong.end() && strong->second == defender)
            return StrongMultiplier;
        auto const weak = Weak.find(attacker);
        if (weak != Weak.end() && weak->second == defender)
            return WeakMultiplier;
        return 1.0;
    }

    double Damage(double points, double power, std::string const& attacker, std::string const& defender,
        double dealtPercent, double takenPercent)
    {
        double d = points * (1 + power / 20) * Matchup(attacker, defender);
        d = d * (1 + dealtPercent / 100) * (1 + takenPercent / 100);
        return std::max(1.0, std::floor(d + 0.5));
    }

    double Heal(double points, double power)
    {
        return std::max(1.0, std::floor(points * (1 + power / 20) + 0.5));
    }
}
