#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // His map (883) starts at its graveyard (WorldSafeLocs 6083). The shrine stands in Darkshore, by the Master's Glaive.
    coa_world_boss_instance::Config const Soggoth = {
        "The Will of Soggoth", 64605, 883,
        { 4410.54f, 269.28f, 78.02f, 0.0f },
        978077, 1,
        { 4548.818f, 343.048f, 48.731f, 6.0221f },
        978078,
    };
}

void AddCoaSoggothInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_soggoth_altar_coa", "go_soggoth_exit_coa", "go_soggoth_leave_coa",
        "soggoth_instance_death_coa", Soggoth);
}
