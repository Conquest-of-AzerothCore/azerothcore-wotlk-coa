#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The shrine in the Eastern Plaguelands by Zul'Mashar; his map (890)
    // starts at its graveyard (WorldSafeLocs 6090).
    coa_world_boss_instance::Config const Boss = {
        "Atal'zul", 67532, 890,
        { 3353.02f, -4844.59f, 167.44f, 0.0f },
        978090, 0,
        { 3335.884f, -4842.772f, 167.134f, 5.1617f },
        978091,
    };
}

void AddCoaAtalzulInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_atalzul_altar_coa", "go_atalzul_exit_coa", "go_atalzul_leave_coa",
        "atalzul_instance_death_coa", Boss);
}
