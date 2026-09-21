#ifndef MANASTORM_NATIVE_PROTOCOL_H
#define MANASTORM_NATIVE_PROTOCOL_H

#include "Define.h"

namespace ManastormNativeOpcode
{
    // Client -> server
    constexpr uint16 Enter = 0x651;
    constexpr uint16 Leave = 0x665;
    constexpr uint16 SetLoadoutSlot = 0x689;

    // Server -> client
    constexpr uint16 UpdateConfigs = 0x58D;
    constexpr uint16 EnterResult = 0x652;
    constexpr uint16 LeaveResult = 0x666;
    constexpr uint16 ProgressUpdate = 0x65D;
    constexpr uint16 LevelCompleted = 0x65E;
    constexpr uint16 CompletedDepths = 0x65F;
    constexpr uint16 ActiveState = 0x660;
    constexpr uint16 Failed = 0x67B;
    constexpr uint16 DefinitionRow = 0x67D;
    constexpr uint16 MessageRow = 0x67E;
    constexpr uint16 ChaoticLink = 0x67F;
    constexpr uint16 FullLoadout = 0x688;
    constexpr uint16 SetLoadoutResult = 0x68A;
    constexpr uint16 LoadoutUpdate = 0x68B;
    constexpr uint16 PlayerGroupModifierRow = 0x68C;
    constexpr uint16 ModifierRow = 0x68D;
    constexpr uint16 RewardVisibility = 0x6AD;

    inline bool IsClientRequest(uint16 opcode)
    {
        return opcode == Enter ||
            opcode == Leave ||
            opcode == SetLoadoutSlot;
    }
}

namespace ManastormNativeResult
{
    constexpr char EnterOk[] = "ENTER_MANASTORM_OK";
    constexpr char EnterUnknown[] = "ENTER_MANASTORM_UNKNOWN";
    constexpr char EnterAlreadyActive[] = "ENTER_MANASTORM_ALREADY_ACTIVE";
    constexpr char EnterBadLevel[] = "ENTER_MANASTORM_BAD_LEVEL";
    constexpr char EnterNotGroupLeader[] = "ENTER_MANASTORM_NOT_GROUP_LEADER";

    constexpr char LeaveOk[] = "LEAVE_MANASTORM_OK";
    constexpr char LeaveUnknown[] = "LEAVE_MANASTORM_UNKNOWN";
    constexpr char LeaveNotActive[] = "LEAVE_MANASTORM_NOT_ACTIVE";

    constexpr char LoadoutNotKnown[] = "SET_MANASTORM_LOADOUT_NOT_KNOWN";
}

#endif
