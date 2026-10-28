#ifndef MANASTORM_CLIENT_BRIDGE_H
#define MANASTORM_CLIENT_BRIDGE_H

#include "Define.h"

class Player;
class ManastormRun;
class WorldPacket;
class WorldSession;
class Group;

class ManastormClientBridge
{
public:
    static ManastormClientBridge& Instance();

    // Return true when a native request was consumed by the module.
    bool HandleIncoming(
        WorldSession* session,
        WorldPacket const& packet);

    void SendState(
        Player* player,
        ManastormRun const* run) const;

    void SendProgression(
        Player* player) const;

    void Login(Player* player) const;
    void SendConfig(Player* player) const;
    void SendGroupProgression(Group* group) const;
    void SendLoadout(Player* player) const;

    void SendStageCompleted(
        Player* player,
        uint32 depth) const;

    void BroadcastStageCompleted(
        ManastormRun const& run) const;

private:
    ManastormClientBridge() = default;

    void SendEnterResult(
        Player* player,
        char const* result) const;

    void SendLeaveResult(
        Player* player,
        char const* result) const;

    void SendLoadoutResult(
        Player* player,
        uint32 zeroBasedSlot,
        char const* result) const;

    void SendChaoticLink(
        Player* player,
        uint32 stacks) const;

    void SendFailed(
        Player* player) const;
};

void AddSC_manastorm_native_bridge();

#endif
