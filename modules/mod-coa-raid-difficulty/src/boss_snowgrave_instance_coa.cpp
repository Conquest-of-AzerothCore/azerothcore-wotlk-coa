#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The shrine in Winterspring (placeholder spot until it is taken in game); his map (889) starts at its
    // graveyard (WorldSafeLocs 6089).
    coa_world_boss_instance::Config const Boss = {
        "Korrim Snowgrave", 64627, 889,
        { 4741.1f, -4934.99f, 695.78f, 0.0f },
        978095, 1,
        { 4741.1f, -4934.99f, 885.43f, 0.0f },
        978096,
    };
}

void AddCoaSnowgraveInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_snowgrave_altar_coa", "go_snowgrave_exit_coa", "go_snowgrave_leave_coa",
        "snowgrave_instance_death_coa", Boss);
}
