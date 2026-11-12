#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The shrine stands under the sea off Sardor Isle; the fight is in Depthbreaker's Hollow (884), which starts at its
    // graveyard (WorldSafeLocs 6084).
    coa_world_boss_instance::Config const Kaldros = {
        "Kaldros Depthbreaker", 978080, 884,
        { -4751.12f, 2466.51f, -82.41f, 0.0f },
        978080, 1,
        { -4748.838f, 2697.862f, -152.733f, 3.9223f },
        978081,
    };
}

void AddCoaKaldrosInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_kaldros_altar_coa", "go_kaldros_exit_coa", "go_kaldros_leave_coa",
        "kaldros_instance_death_coa", Kaldros);
}
