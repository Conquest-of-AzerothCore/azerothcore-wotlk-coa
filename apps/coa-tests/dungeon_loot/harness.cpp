#include "DungeonLoot.h"
#include <cstdlib>
#include <iostream>

using uint32 = std::uint32_t;

void Require(bool value)
{
    if (!value)
    {
        std::cerr << "Dungeon loot regression failed\n";
        std::exit(1);
    }
}

int main()
{
    DungeonLoot::Variants const variants{{5193, {1555193, 1655193}}, {6220, {1556220, 0}}};
    Require(DungeonLoot::Resolve(variants, 5193, 1, false) == 1555193);
    Require(DungeonLoot::Resolve(variants, 5193, 2, false) == 1655193);
    Require(DungeonLoot::Resolve(variants, 5193, 0, false) == 5193);
    Require(DungeonLoot::Resolve(variants, 5193, 2, true) == 5193);
    Require(DungeonLoot::Resolve(variants, 6220, 1, false) == 1556220);
    Require(DungeonLoot::Resolve(variants, 6220, 2, false) == 6220);
    Require(DungeonLoot::Resolve(variants, 5193, 255, false) == 5193);
    Require(DungeonLoot::Resolve(variants, 99999, 1, false) == 99999);
    for (uint32 map : {33u, 34u, 36u, 43u, 47u, 48u, 70u, 90u, 109u, 129u, 189u,
                      209u, 229u, 230u, 289u, 329u, 349u, 389u, 429u, 645u, 936u, 937u})
    {
        Require(DungeonLoot::Difficulty(map, 1, true) == 1);
        Require(DungeonLoot::Difficulty(map, 2, true) == 2);
        Require(DungeonLoot::Difficulty(map, 0, true) == 0);
        Require(DungeonLoot::Difficulty(map, 3, true) == 0);
        Require(DungeonLoot::Difficulty(map, 2, false) == 0);
    }
    for (uint32 map : {0u, 1u, 409u, 531u, 574u})
        Require(DungeonLoot::Difficulty(map, 2, true) == 0);
    return 0;
}
