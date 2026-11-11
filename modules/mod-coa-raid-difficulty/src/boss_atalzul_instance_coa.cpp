#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The shrine in the Eastern Plaguelands by Zul'Mashar; his map (890)
    // starts at its graveyard (WorldSafeLocs 6090).
    coa_world_boss_instance::Config const Boss = {
        "Atal'zul", 67532, 890,
        { 3307.54f, -4849.5786f, 167.9613f, 3.2970f },
        978090, 0,
        { 3322.411f, -4846.606f, 167.1479f, 5.1839f },
        978091,
    };
}

void AddCoaAtalzulInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_atalzul_altar_coa", "go_atalzul_exit_coa", "go_atalzul_leave_coa",
        "atalzul_instance_death_coa", Boss);
}
