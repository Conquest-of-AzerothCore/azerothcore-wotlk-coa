#ifndef COA_PET_BATTLE_ENGINE_PET_FACTORY_H
#define COA_PET_BATTLE_ENGINE_PET_FACTORY_H

#include "BattleTypes.h"
#include "Rules.h"
#include <optional>
#include <string>
#include <vector>

namespace CoAPetBattles::Engine
{
    struct KitOption
    {
        int32_t slot = 0;
        int32_t option = 0;
        double unlock = 0;
        PetAbility ability;
    };

    struct FamilyMatchups
    {
        std::string name;
        std::string strong;
        std::string weak;
        std::string hurtBy;
        std::string resists;
    };

    PetAbility MakeAbility(KitEntry const& entry);
    std::vector<KitOption> Kit(Catalog const& catalog, uint32_t species);
    Stats StatsForPet(SpeciesDef const& species, double level, double quality, uint8_t maxLevel, uint8_t breed);
    Pet NewPet(Catalog const& catalog, uint32_t species, double level, std::optional<std::array<int32_t, 3>> picks,
        Rng& rng, std::optional<double> quality, std::optional<double> hp, uint8_t breed = 0);
    uint8_t RollBreed(Catalog const& catalog, uint32_t species, Rng& rng);
    double RollQuality(Catalog const& catalog, Rng& rng);
    double XPNeeded(Catalog const& catalog, double level);
    double XPPerWin(Catalog const& catalog, double level);
    FamilyMatchups FamilyInfo(std::string const& family);
}

#endif
