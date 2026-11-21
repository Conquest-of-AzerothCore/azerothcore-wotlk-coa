#include <array>
#include <cassert>
#include <cstdint>
#include <unordered_map>
#include <unordered_set>
#include <utility>
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

enum class VoiceKind
{
    None,
    Intro
};

struct PendingVoice
{
    uint64 RunId = 0;
    uint32 DelayMs = 0;
    uint32 MapId = 0;
    uint32 InstanceId = 0;
    uint32 SoundId = 0;
    VoiceKind Kind = VoiceKind::None;
    bool FollowMemberPosition = false;
    std::vector<ObjectGuid::LowType> Members;
};

enum class ManastormRunState
{
    Preparing,
    Active
};

struct ManastormSegment
{
    uint32 MapId = 0;
};

struct ManastormRun
{
    uint64 runId = 0;
    ManastormRunState state = ManastormRunState::Preparing;
    ManastormSegment segment;
    uint32 instance = 0;
    std::vector<ObjectGuid::LowType> members;

    uint64 GetRunId() const { return runId; }
    ManastormRunState GetState() const { return state; }
    ManastormSegment const& GetSegment() const { return segment; }
    uint32 GetInstanceId() const { return instance; }
    std::vector<ObjectGuid::LowType> const& GetMembers() const { return members; }
};

struct RunVoiceState
{
    bool FirstManastorm = false;
    uint32 IntroSound = 0;
    std::unordered_set<ObjectGuid::LowType> IntroDeliveredMembers;
    uint32 LastIntroSound = 0;
};

std::unordered_map<uint64, RunVoiceState> RunStates;
std::vector<PendingVoice> PendingVoices;

constexpr uint32 INTRO_FIRST_TIME = 113142;
constexpr std::array<uint32, 1> INTRO_RECURRING = {{ 113141 }};
constexpr uint32 INTRO_SETTLE_MS = 500;

uint32 PickSound(std::array<uint32, 1> const& pool, uint32)
{
    return pool[0];
}

PendingVoice BuildVoice(ManastormRun const& run, uint32 soundId, uint32 delayMs, VoiceKind kind)
{
    PendingVoice voice;
    voice.RunId = run.GetRunId();
    voice.DelayMs = delayMs;
    voice.MapId = run.GetSegment().MapId;
    voice.InstanceId = run.GetInstanceId();
    voice.SoundId = soundId;
    voice.Kind = kind;
    voice.Members = run.GetMembers();
    return voice;
}

// ACTUAL_READY

// ACTUAL_PLAY

// ACTUAL_INTRO

void PlaysLinesFromTheListener()
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
}

void QueuesTheIntroOnceTheArrivalSettles()
{
    WorldSession session;
    Player member;
    member.guid.value = 9;
    member.session = &session;
    member.teleporting = true;
    member.map = 230;
    member.instance = 41;

    ManastormRun run;
    run.runId = 5;
    run.segment.MapId = 230;
    run.instance = 41;
    run.members = {9, 10};
    RunStates[run.runId].FirstManastorm = true;

    OnPlayerEnteredProtection(run, &member);
    assert(PendingVoices.empty());
    assert(!RunStates[run.runId].IntroDeliveredMembers.contains(9));

    member.teleporting = false;
    member.instance = 40;
    OnPlayerEnteredProtection(run, &member);
    assert(PendingVoices.empty());
    assert(!RunStates[run.runId].IntroDeliveredMembers.contains(9));

    member.instance = 41;
    OnPlayerEnteredProtection(run, &member);
    assert(PendingVoices.size() == 1);
    assert(PendingVoices[0].SoundId == INTRO_FIRST_TIME);
    assert(PendingVoices[0].Kind == VoiceKind::Intro);
    assert(PendingVoices[0].DelayMs == INTRO_SETTLE_MS);
    assert(PendingVoices[0].Members == std::vector<ObjectGuid::LowType>{9});
    assert(RunStates[run.runId].IntroDeliveredMembers.contains(9));

    OnPlayerEnteredProtection(run, &member);
    assert(PendingVoices.size() == 1);
}

int main()
{
    PlaysLinesFromTheListener();
    QueuesTheIntroOnceTheArrivalSettles();
    return 0;
}
