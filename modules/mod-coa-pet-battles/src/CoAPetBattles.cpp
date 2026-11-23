#include "PetBattleDataStore.h"
#include "WorldScript.h"

namespace
{
    class PetBattlesWorld : public WorldScript
    {
    public:
        PetBattlesWorld() : WorldScript("coa_pet_battles_world",
            { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

        void OnAfterConfigLoad(bool) override
        {
            sPetBattleData->LoadSettings();
        }

        void OnStartup() override
        {
            sPetBattleData->Load();
        }
    };
}

void AddSC_coa_pet_battles_commands();

void AddSC_coa_pet_battles()
{
    new PetBattlesWorld();
    AddSC_coa_pet_battles_commands();
}
