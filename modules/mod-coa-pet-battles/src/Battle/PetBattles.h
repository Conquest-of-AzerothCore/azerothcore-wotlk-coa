#ifndef COA_PET_BATTLE_BATTLE_PET_BATTLES_H
#define COA_PET_BATTLE_BATTLE_PET_BATTLES_H

#include "Battles.h"
#include "Engine/Rng.h"
#include "Follow/Followers.h"
#include "ObjectGuid.h"
#include <memory>
#include <string>

class Player;

namespace CoAPetBattles::Battle
{
    class ServerWorld;
    class ServerFollowerWorld;

    class PetBattles
    {
    public:
        static PetBattles* instance();

        void Update(uint32_t diff);
        void Message(Player* player, std::string const& module, std::string const& action, std::string const& payload);
        bool Challenge(Player* player, std::string const& enemies);
        bool StartWild(Player* player, std::vector<EnemySpec> enemies);
        void Login(Player* player);
        void Logout(Player* player);
        Follow::Registry& Followers();
        Battles* Registry();
        bool IsFollower(ObjectGuid guid) const;
        void Shutdown();
        bool InBattle(Player* player) const;
        size_t StandIns(Player* player) const;

    private:
        PetBattles();
        ~PetBattles();
        Battles* Current();

        std::unique_ptr<ServerWorld> _world;
        std::unique_ptr<ServerFollowerWorld> _followerWorld;
        std::unique_ptr<Follow::Registry> _followers;
        Scheduler _scheduler;
        Engine::SeededRng _rng;
        std::shared_ptr<Engine::Catalog const> _catalog;
        std::unique_ptr<Battles> _battles;
    };
}

#define sPetBattles CoAPetBattles::Battle::PetBattles::instance()

#endif
