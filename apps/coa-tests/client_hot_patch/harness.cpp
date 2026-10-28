#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <mutex>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;

constexpr uint16 SMSG_COA_CHALLENGE_ACTIVE_LIST = 0x596;
constexpr uint16 SMSG_COA_CHALLENGE_CRITERIA_UPDATED = 0x59A;
constexpr uint16 SMSG_COA_CHALLENGE_REQUIREMENT = 0x5B6;
constexpr uint16 SMSG_COA_PATCH_CHALLENGE_REQUIREMENT_TYPE = 0x5BC;

struct WorldPacket
{
    WorldPacket(uint16 opcode, std::size_t) : opcode(opcode) { }

    template<class T>
    void Put(T value)
    {
        uint8 raw[sizeof(T)];
        std::memcpy(raw, &value, sizeof(T));
        bytes.insert(bytes.end(), raw, raw + sizeof(T));
    }

    WorldPacket& operator<<(uint8 value) { Put(value); return *this; }
    WorldPacket& operator<<(uint16 value) { Put(value); return *this; }
    WorldPacket& operator<<(uint32 value) { Put(value); return *this; }
    WorldPacket& operator<<(float value) { Put(value); return *this; }
    void append(uint8 const* data, std::size_t size)
    {
        if (!size)
        {
            std::cerr << "FAIL: ByteBuffer::append asserts on a zero-sized value (pos " << bytes.size() << ")\n";
            std::exit(1);
        }
        bytes.insert(bytes.end(), data, data + size);
    }

    uint16 opcode;
    std::vector<uint8> bytes;
};

struct WorldSession
{
    uint32 GetAccountId() const { return accountId; }
    void SendPacket(WorldPacket const* packet) { sent.push_back(*packet); }
    uint32 accountId = 7;
    std::vector<WorldPacket> sent;
};

struct Player
{
    WorldSession* GetSession() const { return session; }
    WorldSession* session = nullptr;
};

// ACTUAL_CLIENT_LUA

namespace
{
    int failures = 0;
    int deferrals = 0;
    int syncs = 0;

    void Check(bool condition, std::string const& message)
    {
        if (!condition)
        {
            std::cerr << "FAIL: " << message << '\n';
            ++failures;
        }
    }

    std::string Sized(std::vector<uint8> const& bytes, std::size_t& offset)
    {
        uint32 size = 0;
        std::memcpy(&size, bytes.data() + offset, 4);
        std::string text(reinterpret_cast<char const*>(bytes.data() + offset + 4), size);
        offset += 4 + size;
        return text;
    }

    AscensionClientLuaChunk Chunk(std::string target = {})
    {
        AscensionClientLuaChunk chunk;
        chunk.RequirementTypeId = 24;
        chunk.RequirementId = 16262;
        chunk.Token = "MANASTORM_UI_FIXES";
        chunk.Lua = "Sample = true";
        chunk.TargetAddon = std::move(target);
        return chunk;
    }

    std::vector<WorldPacket> Run(AscensionClientLuaChunk const& chunk)
    {
        WorldSession session;
        Player player;
        player.session = &session;
        RunAscensionClientLua(&player, chunk);
        return session.sent;
    }

    bool IsFormatterRoute(std::vector<WorldPacket> const& sent)
    {
        return sent.size() == 5 && sent[0].opcode == SMSG_COA_PATCH_CHALLENGE_REQUIREMENT_TYPE &&
            sent[1].opcode == SMSG_COA_CHALLENGE_REQUIREMENT && sent[2].opcode == SMSG_COA_CHALLENGE_ACTIVE_LIST &&
            sent[3].opcode == SMSG_COA_CHALLENGE_CRITERIA_UPDATED && sent[4].opcode == SMSG_COA_CHALLENGE_CRITERIA_UPDATED;
    }
}

int main()
{
    using namespace std::chrono_literals;
    RegisterAscensionChallengeStateSync([](Player*) { ++syncs; });
    RegisterAscensionClientLuaDeferral([](Player*, AscensionClientLuaChunk const&) { ++deferrals; });
    auto const start = AscensionClientLuaClock::now();

    Check(GetAscensionClientLuaRoute(7, start) == AscensionClientLuaRoute::Formatter,
        "an account that never logged in through the script uses the formatter route");
    Check(IsFormatterRoute(Run(Chunk())) && syncs == 1, "the formatter route sends its five packets and restores the list");

    ResetAscensionClientLuaCapability(7, start);
    Check(GetAscensionClientLuaRoute(7, start + 1s) == AscensionClientLuaRoute::Wait,
        "right after login the route waits for the client's capability packet");
    Check(GetAscensionClientLuaRoute(7, start + 31s) == AscensionClientLuaRoute::Formatter,
        "a client that says nothing for 30 seconds gets the formatter route");
    Check(Run(Chunk()).empty() && deferrals == 1, "while waiting the chunk is handed to the deferral, nothing is sent");

    SetAscensionClientLuaCapability(7, 1, 1);
    Check(GetAscensionClientLuaRoute(7, start + 1s) == AscensionClientLuaRoute::HotPatch,
        "a protocol 1 client gets the hot-patch route");
    {
        std::vector<WorldPacket> const sent = Run(Chunk("Ascension_Manastorm"));
        Check(sent.size() == 1 && sent[0].opcode == AscensionClientLuaHotPatchOpcode, "the hot-patch route sends one 0x8F0 packet");
        if (sent.size() == 1)
        {
            std::size_t offset = 0;
            Check(Sized(sent[0].bytes, offset) == "MANASTORM_UI_FIXES", "0x8F0 starts with the patch id");
            Check(Sized(sent[0].bytes, offset) == "Ascension_Manastorm", "then the target addon");
            Check(Sized(sent[0].bytes, offset) == "Sample = true", "then the Lua exactly as built, with no formatter wrapper");
            Check(offset == sent[0].bytes.size(), "0x8F0 has no trailing bytes");
        }
        Check(syncs == 1, "the hot-patch route leaves the challenge list alone");
    }
    {
        std::vector<WorldPacket> const sent = Run(Chunk());
        std::size_t offset = 0;
        Sized(sent[0].bytes, offset);
        Check(Sized(sent[0].bytes, offset).empty() && offset + 4 + 13 == sent[0].bytes.size(),
            "an empty target is sent as a zero length without a zero-sized append");
    }

    SetAscensionClientLuaCapability(7, 0, 2);
    Check(GetAscensionClientLuaRoute(7, start) == AscensionClientLuaRoute::Formatter,
        "a client announcing protocol 0 gets the formatter route");

    ForgetAscensionClientLuaCapability(7);
    Check(GetAscensionClientLuaRoute(7, start) == AscensionClientLuaRoute::Formatter, "logout forgets the capability");

    if (failures)
        return 1;
    std::cout << "client_hot_patch: OK\n";
    return 0;
}
