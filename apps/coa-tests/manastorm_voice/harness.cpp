#include <cassert>
#include <cstdint>
#include <vector>

using uint32 = uint32_t;
using uint64 = uint64_t;

#define LOG_DEBUG(...) ((void)0)

struct ObjectGuid
{
    using LowType = uint32;
    uint64 value = 0;
    uint32 GetCounter() const { return uint32(value); }
};

struct WorldSession {};

struct Player;

struct SoundEvent
{
    Player const* source;
    Player const* listener;
    uint32 sound;
};

std::vector<SoundEvent> sounds;

struct Player
{
    ObjectGuid guid;
    WorldSession* session = nullptr;
    bool inWorld = true;
    bool teleporting = false;
    uint32 map = 0;
    uint32 instance = 0;

    WorldSession* GetSession() const { return session; }
    bool IsInWorld() const { return inWorld; }
    bool IsBeingTeleported() const { return teleporting; }
    uint32 GetMapId() const { return map; }
    uint32 GetInstanceId() const { return instance; }
    ObjectGuid GetGUID() const { return guid; }

    void PlayDistanceSound(uint32 sound, Player* listener)
    {
        sounds.push_back({this, listener, sound});
    }
};

struct PendingVoice
{
    uint64 RunId = 0;
    uint32 MapId = 0;
    uint32 InstanceId = 0;
    uint32 SoundId = 0;
    bool FollowMemberPosition = false;
};

// ACTUAL_READY

// ACTUAL_PLAY

int main()
{
    WorldSession session;
    Player member;
    member.guid.value = 7;
    member.session = &session;
    member.map = 230;
    member.instance = 41;

    PendingVoice zoneLine;
    zoneLine.RunId = 3;
    zoneLine.MapId = 230;
    zoneLine.InstanceId = 41;
    zoneLine.SoundId = 132958;

    assert(PlayForMember(&member, zoneLine));
    assert(sounds.size() == 1);
    assert(sounds[0].source == &member);
    assert(sounds[0].listener == &member);
    assert(sounds[0].sound == 132958);

    PendingVoice deathLine = zoneLine;
    deathLine.SoundId = 113148;
    deathLine.MapId = 0;
    deathLine.InstanceId = 0;
    deathLine.FollowMemberPosition = true;
    assert(PlayForMember(&member, deathLine));
    assert(sounds.size() == 2);
    assert(sounds[1].source == &member && sounds[1].listener == &member && sounds[1].sound == 113148);

    PendingVoice otherInstance = zoneLine;
    otherInstance.InstanceId = 42;
    assert(!PlayForMember(&member, otherInstance));

    member.teleporting = true;
    assert(!PlayForMember(&member, zoneLine));
    member.teleporting = false;

    member.session = nullptr;
    assert(!PlayForMember(&member, zoneLine));

    assert(!PlayForMember(nullptr, zoneLine));
    assert(sounds.size() == 2);
    return 0;
}
