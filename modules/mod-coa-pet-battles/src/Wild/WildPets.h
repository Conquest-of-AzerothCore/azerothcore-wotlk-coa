#ifndef COA_PET_BATTLE_WILD_WILD_PETS_H
#define COA_PET_BATTLE_WILD_WILD_PETS_H

#include "Wild.h"
#include <memory>
#include <string>
#include <vector>

class Creature;
class Player;

namespace CoAPetBattles::Wild
{
    class ServerWildWorld;

    class WildPets
    {
    public:
        static WildPets* instance();

        void Update(uint32_t diff);
        void Shutdown();
        bool Hello(Player* player, Creature* creature);
        bool Select(Player* player, Creature* creature, uint32_t action);
        std::vector<std::string> Describe(Player* player);
        size_t Count();
        bool ChallengeNearest(Player* player);

    private:
        WildPets();
        ~WildPets();
        Registry* Current();

        std::unique_ptr<ServerWildWorld> _world;
        Engine::SeededRng _rng;
        std::shared_ptr<Engine::Catalog const> _catalog;
        std::unique_ptr<Battle::PetScale> _scale;
        std::unique_ptr<Registry> _registry;
        uint32_t _sinceTick = 0;
        uint32_t _sinceBlips = 0;
    };
}

#define sWildPets CoAPetBattles::Wild::WildPets::instance()

#endif
