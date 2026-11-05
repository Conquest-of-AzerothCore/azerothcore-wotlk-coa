#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // His map (883) starts at its graveyard (WorldSafeLocs 6083). The shrine stands by the Shrine of Setis until
    // Ascension's spot for it is known.
    coa_world_boss_instance::Config const Soggoth = {
        "The Will of Soggoth", 64605, 883,
        { 4410.54f, 269.28f, 78.02f, 0.0f },
        978077, 1,
        { -7852.7f, 1326.7f, -7.357f, 5.4786f },
        978078,
    };
}

void AddCoaSoggothInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_soggoth_altar_coa", "go_soggoth_exit_coa", "go_soggoth_leave_coa",
        "soggoth_instance_death_coa", Soggoth);
}
