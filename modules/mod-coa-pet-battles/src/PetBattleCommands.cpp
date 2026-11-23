#include "Chat.h"
#include "CommandScript.h"
#include "Engine/Sim.h"
#include "PetBattleDataStore.h"
#include <random>

using namespace Acore::ChatCommands;

namespace
{
    class PetBattleCommands : public CommandScript
    {
    public:
        PetBattleCommands() : CommandScript("coa_pet_battles_commands") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable petBattleCommands =
            {
                { "sim", HandleSim, SEC_GAMEMASTER, Console::Yes },
            };
            static ChatCommandTable commands =
            {
                { "petbattle", petBattleCommands },
            };
            return commands;
        }

        static bool HandleSim(ChatHandler* handler, uint32 speciesA, uint32 speciesB, Optional<uint32> level,
            Optional<uint32> seed)
        {
            CoAPetBattles::Engine::Catalog const* catalog = sPetBattleData->Catalog();
            if (!sPetBattleData->IsLoaded() || !catalog)
            {
                handler->SendErrorMessage("pet battle data is not loaded", false);
                return false;
            }
            uint32 const chosenSeed = seed ? *seed : std::random_device {}();
            int32 const chosenLevel = level ? static_cast<int32>(std::min<uint32>(*level, 1000)) : 25;
            CoAPetBattles::Engine::SimResult const result =
                CoAPetBattles::Engine::RunSim(*catalog, speciesA, speciesB, chosenLevel, chosenSeed);
            if (!result.error.empty())
            {
                handler->SendErrorMessage(result.error, false);
                return false;
            }
            for (std::string const& line : result.lines)
                handler->SendSysMessage(line);
            return true;
        }
    };
}

void AddSC_coa_pet_battles_commands()
{
    new PetBattleCommands();
}
