#include "AccountScript.h"
#include "AllCreatureScript.h"
#include "Battle/PetBattles.h"
#include "PetBattleDataStore.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Protocol/AddonChannel.h"
#include "SharedDefines.h"
#include "Store/PetJournalStore.h"
#include "Wild/WildPets.h"
#include "WorldScript.h"

namespace
{
    void Forward(std::string const& module, std::string const& action)
    {
        sAddonChannel->On(module, action, [module, action](Player* player, std::string const& payload)
        {
            sPetBattles->Message(player, module, action, payload);
        });
    }

    class PetBattlesWorld : public WorldScript
    {
    public:
        PetBattlesWorld() : WorldScript("coa_pet_battles_world",
            { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE, WORLDHOOK_ON_SHUTDOWN }) { }

        void OnAfterConfigLoad(bool) override
        {
            sPetBattleData->LoadSettings();
        }

        void OnStartup() override
        {
            sPetBattleData->Load();
            for (char const* action : { "start", "cmd", "quit", "clean" })
                Forward("pbt", action);
            for (char const* action : { "list", "abil", "setabil", "setteam", "active", "feed", "summon", "dismiss",
                "prime", "hello2", "list2", "abil2", "setabil2", "setteam2", "active2", "feed2", "summon2",
                "release2" })
                Forward("pbj", action);
        }

        void OnUpdate(uint32 diff) override
        {
            sAddonChannel->Update(diff);
            sPetBattles->Update(diff);
            sWildPets->Update(diff);
            sPetJournals->Update();
        }

        void OnShutdown() override
        {
            sWildPets->Shutdown();
            sPetBattles->Shutdown();
        }
    };

    class PetBattlesPlayer : public PlayerScript
    {
    public:
        PetBattlesPlayer() : PlayerScript("coa_pet_battles_player",
            { PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_LEARN_SPELL,
              PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT }) { }

        bool OnPlayerCanUseChat(Player* player, uint32 type, uint32 language, std::string& message,
            Player* receiver) override
        {
            if (type != CHAT_MSG_WHISPER || language != LANG_ADDON || receiver != player)
                return true;
            return !sAddonChannel->Receive(player, message);
        }

        void OnPlayerLogin(Player* player) override
        {
            sPetJournals->Login(player);
            sPetBattles->Login(player);
        }

        void OnPlayerLogout(Player* player) override
        {
            sPetBattles->Logout(player);
            sAddonChannel->Forget(player);
            sPetJournals->Logout(player);
        }

        void OnPlayerLearnSpell(Player* player, uint32 spellId) override
        {
            sPetJournals->LearnSpell(player, spellId);
        }
    };

    class PetBattlesWildCreatures : public AllCreatureScript
    {
    public:
        PetBattlesWildCreatures() : AllCreatureScript("coa_pet_battles_wild_creatures") { }

        bool CanCreatureGossipHello(Player* player, Creature* creature) override
        {
            return sWildPets->Hello(player, creature);
        }

        bool CanCreatureGossipSelect(Player* player, Creature* creature, uint32 /*sender*/, uint32 action) override
        {
            return sWildPets->Select(player, creature, action);
        }
    };

    class PetBattlesAccount : public AccountScript
    {
    public:
        PetBattlesAccount() : AccountScript("coa_pet_battles_account", { ACCOUNTHOOK_ON_BEFORE_ACCOUNT_DELETE }) { }

        void OnBeforeAccountDelete(uint32 accountId) override
        {
            sPetJournals->DeleteAccount(accountId);
        }
    };
}

void AddSC_coa_pet_battles_commands();

void AddSC_coa_pet_battles()
{
    new PetBattlesWorld();
    new PetBattlesPlayer();
    new PetBattlesAccount();
    new PetBattlesWildCreatures();
    AddSC_coa_pet_battles_commands();
}
