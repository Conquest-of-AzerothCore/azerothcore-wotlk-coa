#include <cassert>
#include <cstdint>
#include <vector>
using uint8 = std::uint8_t;
using uint32 = std::uint32_t;
enum Difficulty { Normal, Heroic, Mythic };
constexpr uint32 MAX_DUNGEON_DIFFICULTY = 3;
constexpr uint32 CMSG_COA_SET_DUNGEON_DIFFICULTY = 0x773;
constexpr uint32 MSG_SET_DUNGEON_DIFFICULTY = 0x329;
constexpr uint32 INSTANCE_RESET_CHANGE_DIFFICULTY = 1;
#define LOG_DEBUG(...) ((void)0)
struct WorldPacket
{
    uint32 opcode;
    std::vector<uint8> bytes;
    WorldPacket(uint32 op, uint32 = 0) : opcode(op) {}
    uint32 GetOpcode() const { return opcode; }
    std::size_t size() const { return bytes.size(); }
    template<class T> T read(std::size_t at) const { return static_cast<T>(bytes.at(at)); }
    WorldPacket& operator<<(uint32 value)
    {
        for (uint32 shift = 0; shift < 32; shift += 8)
            bytes.push_back(static_cast<uint8>(value >> shift));
        return *this;
    }
};
namespace WorldPackets::Instance { struct SetDungeonDifficultyClient { uint32 Mode; }; }
struct Map
{
    bool dungeon = false;
    bool IsDungeon() const { return dungeon; }
    bool IsNonRaidDungeon() const { return dungeon; }
};
struct Group;
struct Player
{
    Map map;
    Group* group = nullptr;
    Difficulty difficulty = Heroic;
    uint32 confirmations = 0;
    uint32 confirmed = 99;
    bool inWorld = true;
    Difficulty GetDungeonDifficulty() const { return difficulty; }
    Group* GetGroup() const { return group; }
    uint32 GetGUID() const { return 1; }
    bool IsInWorld() const { return inWorld; }
    Map* GetMap() { return &map; }
    Map* FindMap() { return &map; }
    void SendDungeonDifficulty(bool) { ++confirmations; confirmed = difficulty; }
    void SetDungeonDifficulty(Difficulty value) { difficulty = value; }
    static void ResetInstances(uint32, uint32, bool) {}
};
struct GroupReference
{
    Player* player;
    GroupReference* following = nullptr;
    Player* GetSource() { return player; }
    GroupReference* next() { return following; }
};
struct Group
{
    bool leader = true;
    GroupReference* first = nullptr;
    Difficulty difficulty = Heroic;
    bool IsLeader(uint32) const { return leader; }
    GroupReference* GetFirstMember() { return first; }
    void ResetInstances(uint32, bool, Player*) {}
    void SetDungeonDifficulty(Difficulty value) { difficulty = value; }
};
struct WorldSession
{
    Player* _player;
    std::vector<WorldPacket> queued;
    void QueuePacket(WorldPacket* packet) { queued.push_back(*packet); delete packet; }
    void HandleSetDungeonDifficultyOpcode(WorldPackets::Instance::SetDungeonDifficultyClient& packet);
};
// ACTUAL_HANDLER
// ACTUAL_BRIDGE
int main()
{
    Player player;
    WorldSession session{&player, {}};
    WorldPackets::Instance::SetDungeonDifficultyClient change{Mythic};
    session.HandleSetDungeonDifficultyOpcode(change);
    assert(player.difficulty == Mythic);
    assert(player.confirmations == 1 && player.confirmed == Mythic);
    player.map.dungeon = true;
    change.Mode = Heroic;
    session.HandleSetDungeonDifficultyOpcode(change);
    assert(player.difficulty == Mythic);
    player.map.dungeon = false;
    Group group;
    player.group = &group;
    group.leader = false;
    session.HandleSetDungeonDifficultyOpcode(change);
    assert(group.difficulty == Heroic);
    group.leader = true;
    Player member;
    member.map.dungeon = true;
    GroupReference reference{&member};
    group.first = &reference;
    change.Mode = Mythic;
    player.difficulty = Heroic;
    session.HandleSetDungeonDifficultyOpcode(change);
    assert(group.difficulty == Heroic);
    member.map.dungeon = false;
    session.HandleSetDungeonDifficultyOpcode(change);
    assert(group.difficulty == Mythic);
    WorldPacket request(CMSG_COA_SET_DUNGEON_DIFFICULTY);
    request.bytes = {2};
    assert(QueueAscensionDungeonDifficulty(&session, request));
    assert(session.queued.size() == 1);
    assert(session.queued[0].opcode == MSG_SET_DUNGEON_DIFFICULTY);
    assert((session.queued[0].bytes == std::vector<uint8>{2, 0, 0, 0}));
    for (auto bytes : {std::vector<uint8>{}, std::vector<uint8>{3}, std::vector<uint8>{255},
                      std::vector<uint8>{2, 0}})
    {
        request.bytes = bytes;
        assert(QueueAscensionDungeonDifficulty(&session, request));
        assert(session.queued.size() == 1);
    }
    request.bytes = {2};
    assert(QueueAscensionDungeonDifficulty(nullptr, request));
    WorldPacket unrelated(0x774);
    assert(!QueueAscensionDungeonDifficulty(&session, unrelated));
}
