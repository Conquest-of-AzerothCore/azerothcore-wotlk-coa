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

#define LOG_DEBUG(...) ((void)0)

// ACTUAL_CLIENT_LUA

namespace
{
    int failures = 0;

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

    bool OnlyHotPatches(std::vector<WorldPacket> const& sent)
    {
        for (WorldPacket const& packet : sent)
            if (packet.opcode != AscensionClientLuaHotPatchOpcode)
                return false;
        return true;
    }
}

std::string PayloadLua(WorldPacket const& packet)
{
    std::size_t offset = 0;
    Sized(packet.bytes, offset);
    Sized(packet.bytes, offset);
    return Sized(packet.bytes, offset);
}

int main()
{
    Check(GetAscensionClientLuaRoute(7) == AscensionClientLuaRoute::Unsupported,
        "an account that never logged in through the script has no hot-patch channel");
    Check(Run(Chunk()).empty(), "without a channel nothing is sent, and never the 0x5BC formatter sequence");

    BeginAscensionClientLuaSession(7);
    Check(GetAscensionClientLuaRoute(7) == AscensionClientLuaRoute::Queue,
        "right after login chunks wait for the client's capability packet");
    {
        AscensionClientLuaChunk full = Chunk();
        full.Lua = "State = {}";
        Check(Run(full).empty(), "a chunk sent before the capability packet is queued, nothing is sent");
        AscensionClientLuaChunk refresh = Chunk();
        refresh.Lua = "State.now = 1";
        Run(refresh);
        AscensionClientLuaChunk other = Chunk();
        other.Token = "FEL_COMMUTATION_WINDOW";
        Run(other);
    }
    {
        WorldSession session;
        Check(SetAscensionClientLuaCapability(&session, 1, 1) == 3, "the capability packet sends every queued chunk");
        Check(session.sent.size() == 3 && OnlyHotPatches(session.sent), "queued chunks go out as 0x8F0 packets");
        if (session.sent.size() == 3)
        {
            Check(PayloadLua(session.sent[0]) == "State = {}" && PayloadLua(session.sent[1]) == "State.now = 1",
                "two chunks for one token both arrive, the full state before the refresh that needs it");
            std::size_t offset = 0;
            Check(Sized(session.sent[2].bytes, offset) == "FEL_COMMUTATION_WINDOW", "queued chunks keep their order");
        }
        WorldSession again;
        Check(SetAscensionClientLuaCapability(&again, 1, 1) == 0 && again.sent.empty(),
            "a repeated capability packet (after /reload) resends nothing");
    }
    Check(GetAscensionClientLuaRoute(7) == AscensionClientLuaRoute::HotPatch, "a protocol 1 client gets the hot-patch route");
    {
        std::vector<WorldPacket> const sent = Run(Chunk("Ascension_Manastorm"));
        Check(sent.size() == 1 && OnlyHotPatches(sent), "the hot-patch route sends one 0x8F0 packet and nothing else");
        if (sent.size() == 1)
        {
            std::size_t offset = 0;
            Check(Sized(sent[0].bytes, offset) == "MANASTORM_UI_FIXES", "0x8F0 starts with the patch id");
            Check(Sized(sent[0].bytes, offset) == "Ascension_Manastorm", "then the target addon");
            Check(Sized(sent[0].bytes, offset) == "Sample = true", "then the Lua exactly as built, with no formatter wrapper");
            Check(offset == sent[0].bytes.size(), "0x8F0 has no trailing bytes");
        }
    }
    {
        std::vector<WorldPacket> const sent = Run(Chunk());
        std::size_t offset = 0;
        Sized(sent[0].bytes, offset);
        Check(Sized(sent[0].bytes, offset).empty() && offset + 4 + 13 == sent[0].bytes.size(),
            "an empty target is sent as a zero length without a zero-sized append");
    }

    ForgetAscensionClientLuaCapability(7);
    BeginAscensionClientLuaSession(7);
    {
        AscensionClientLuaChunk big = Chunk();
        big.Lua.assign(AscensionClientLuaQueueLimit / 2 - 64, 'x');
        Run(big);
        Run(big);
        Run(big);
        WorldSession session;
        Check(SetAscensionClientLuaCapability(&session, 1, 2) == 2,
            "the queue holds at most AscensionClientLuaQueueLimit bytes and refuses chunks beyond it");
    }

    ForgetAscensionClientLuaCapability(7);
    BeginAscensionClientLuaSession(7);
    Run(Chunk());
    {
        WorldSession session;
        Check(SetAscensionClientLuaCapability(&session, 0, 2) == 0 && session.sent.empty(),
            "a protocol 0 client drops what was queued");
    }
    Check(GetAscensionClientLuaRoute(7) == AscensionClientLuaRoute::Unsupported, "a protocol 0 client has no channel");
    Check(Run(Chunk()).empty(), "a protocol 0 client is sent nothing");

    ForgetAscensionClientLuaCapability(7);
    BeginAscensionClientLuaSession(7);
    Run(Chunk());
    ForgetAscensionClientLuaCapability(7);
    Check(GetAscensionClientLuaRoute(7) == AscensionClientLuaRoute::Unsupported, "logout forgets the capability");
    {
        WorldSession session;
        Check(SetAscensionClientLuaCapability(&session, 1, 2) == 0 && session.sent.empty(), "logout discards the queue");
    }

    ForgetAscensionClientLuaCapability(7);
    {
        WorldSession session;
        SetAscensionClientLuaCapability(&session, 1, 2);
    }
    BeginAscensionClientLuaSession(7);
    Check(GetAscensionClientLuaRoute(7) == AscensionClientLuaRoute::HotPatch,
        "a capability that arrives on the network thread before the login hook survives the login hook");
    {
        std::vector<WorldPacket> const sent = Run(Chunk());
        Check(sent.size() == 1 && OnlyHotPatches(sent), "so the login push goes out at once as 0x8F0");
    }

    if (failures)
        return 1;
    std::cout << "client_hot_patch: OK\n";
    return 0;
}
