#include "ScriptMgr.h"
#include "WorldBossInstance.h"

namespace
{
    // The Shrine of Lord Kazzak in the Tainted Scar; his map (882) starts at its graveyard (WorldSafeLocs 6082).
    coa_world_boss_instance::Config const Kazzak = {
        "Lord Kazzak", 64604, 882,
        { -12569.814f, -2373.242f, 53.649f, 2.5682f },
        9780137, 0,
        { -11665.856f, -2371.7654f, 0.5489f, 0.6004f },
        978074,
        { -12706.521f, -2272.987f, 54.937f, 2.5841f },
    };
}

void AddCoaKazzakInstanceScripts()
{
    coa_world_boss_instance::AddScripts("go_kazzak_altar_coa", "go_kazzak_exit_coa", "go_kazzak_leave_coa",
        "kazzak_instance_death_coa", Kazzak);
}
