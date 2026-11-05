#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The shrine stands on the Feralas coast; the fight is in Depthbreaker's Hollow (884), which starts at its
    // graveyard (WorldSafeLocs 6084).
    coa_world_boss_instance::Config const Kaldros = {
        "Kaldros Depthbreaker", 978080, 884,
        { -4751.12f, 2466.51f, -82.41f, 0.0f },
        978080, 1,
        { -4300.0f, 2360.0f, -0.84f, 0.0f },
        978081,
    };
}

void AddCoaKaldrosInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_kaldros_altar_coa", "go_kaldros_exit_coa", "go_kaldros_leave_coa",
        "kaldros_instance_death_coa", Kaldros);
}
