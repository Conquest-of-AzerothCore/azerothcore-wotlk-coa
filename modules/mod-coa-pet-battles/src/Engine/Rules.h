#ifndef COA_PET_BATTLE_ENGINE_RULES_H
#define COA_PET_BATTLE_ENGINE_RULES_H

#include <array>
#include <optional>
#include <string>

namespace CoAPetBattles::Engine
{
    inline constexpr std::array<char const*, 10> Families = { "Humanoid", "Dragonkin", "Flying", "Undead", "Critter",
        "Magic", "Elemental", "Beast", "Aquatic", "Mechanical" };
    inline constexpr double StrongMultiplier = 1.5;
    inline constexpr double WeakMultiplier = 2.0 / 3.0;

    struct Stats
    {
        double health = 0.0;
        double power = 0.0;
        double speed = 0.0;
    };

    std::optional<std::string> FamilyAt(double luaIndex);
    double QualityMult(double quality);
    Stats PetStats(double power, double speed, double stamina, double level, double quality, double maxLevel);
    double Matchup(std::string const& attacker, std::string const& defender);
    double Damage(double points, double power, std::string const& attacker, std::string const& defender,
        double dealtPercent, double takenPercent);
    double Heal(double points, double power);
}

#endif
