#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The shrine in Winterspring; his map (889) starts at its
    // graveyard (WorldSafeLocs 6089).
    coa_world_boss_instance::Config const Boss = {
        "Snowgrave", 64627, 889,
        { 4750.570f, -4936.066f, 695.831f, 0.6205f },
        978095, 1,
        { 5190.944f, -4909.031f, 752.04f, 1.7423f },
        978096,
    };
}

void AddCoaSnowgraveInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_snowgrave_altar_coa", "go_snowgrave_exit_coa", "go_snowgrave_leave_coa",
        "snowgrave_instance_death_coa", Boss);
}
