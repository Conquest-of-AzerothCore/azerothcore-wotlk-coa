#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The shrine stands in Azshara. In his map (881) Ascension's 64601 fights; it starts at its graveyard
    // (WorldSafeLocs 6081), by the shrine at the entrance.
    coa_world_boss_instance::Config const Azuregos = {
        "Azuregos", 64601, 881,
        { 2948.83f, -4882.32f, 241.06f, 1.7613f },
        978070, 1,
        { 2597.352f, -5993.585f, 103.908f, 0.7092f },
        978071,
    };
}

void AddCoaAzuregosInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_azuregos_altar_coa", "go_azuregos_exit_coa", "go_azuregos_leave_coa",
        "azuregos_instance_death_coa", Azuregos);
}
