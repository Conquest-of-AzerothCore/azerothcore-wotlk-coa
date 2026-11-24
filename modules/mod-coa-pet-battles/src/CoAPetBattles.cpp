#include "AccountScript.h"
#include "PetBattleDataStore.h"
#include "Player.h"
#include "PlayerScript.h"
#include "Protocol/AddonChannel.h"
#include "SharedDefines.h"
#include "Store/PetJournalStore.h"
#include "WorldScript.h"

namespace
{
    class PetBattlesWorld : public WorldScript
    {
    public:
        PetBattlesWorld() : WorldScript("coa_pet_battles_world",
            { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE }) { }

        void OnAfterConfigLoad(bool) override
        {
            sPetBattleData->LoadSettings();
        }

        void OnStartup() override
        {
            sPetBattleData->Load();
        }

        void OnUpdate(uint32 diff) override
        {
            sAddonChannel->Update(diff);
            sPetJournals->Update();
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
        }

        void OnPlayerLogout(Player* player) override
        {
            sAddonChannel->Forget(player);
            sPetJournals->Logout(player);
        }

        void OnPlayerLearnSpell(Player* player, uint32 spellId) override
        {
            sPetJournals->LearnSpell(player, spellId);
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
    AddSC_coa_pet_battles_commands();
}
