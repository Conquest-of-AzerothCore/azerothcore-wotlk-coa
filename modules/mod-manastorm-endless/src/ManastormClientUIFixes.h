#ifndef MANASTORM_CLIENT_UI_FIXES_H
#define MANASTORM_CLIENT_UI_FIXES_H

#include "Define.h"
#include <string>

class Player;

namespace ManastormClientUIFixes
{
    enum Fix : uint32
    {
        FIX_GROUP_FINDER_KEYBIND = 0x1,
        FIX_REWARD_ANCHOR        = 0x2,
        FIX_QUEUE_LEVEL_GUARDS   = 0x4,
        FIX_EMPTY_LOADOUT_FLYOUT = 0x8,
        FIX_ALL                  = 0xF
    };

    uint32 ConfiguredFixes();
    std::string BuildLua(uint32 fixes);
    void ScheduleLoginPush(Player* player);
}

#endif
