#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <memory>
#include <string>
#include <string_view>
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
    uint32 GetAccountId() const { return 1; }
    void SendPacket(WorldPacket const* packet) { sent.push_back(*packet); }
    std::vector<WorldPacket> sent;
};

namespace DataMap
{
    struct Base { };
}

namespace GameTime
{
    std::chrono::seconds clock{100};
    std::chrono::seconds GetGameTime() { return clock; }
}

struct PlayerData
{
    template<class T> T* GetDefault(char const*)
    {
        if (!value)
            value = std::make_shared<T>();
        return static_cast<T*>(value.get());
    }
    std::shared_ptr<void> value;
};

struct Guid
{
    uint32 GetCounter() const { return 1; }
};

struct Player
{
    WorldSession* GetSession() const { return session; }
    Guid GetGUID() const { return {}; }
    WorldSession* session = nullptr;
    PlayerData CustomData;
};

struct ManastormRun { };

struct ManastormRewards
{
    static ManastormRewards& Instance()
    {
        static ManastormRewards rewards;
        return rewards;
    }
    std::string CoATokenClientState(uint32, ManastormRun const*, bool includeClock = true) const
    {
        if (includeClock && Value != "{enabled=false}")
            return Value.substr(0, Value.size() - 1) + ",now=" + std::to_string(GameTime::clock.count()) + "}";
        return Value;
    }
    std::string Value = "{enabled=false}";
};

#define LOG_DEBUG(...) ((void)0)

// ACTUAL_CLIENT_LUA

// ACTUAL_UI_FIXES

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

    struct Reader
    {
        std::vector<uint8> const& bytes;
        std::size_t offset = 0;

        template<class T>
        T Get()
        {
            T value{};
            std::memcpy(&value, bytes.data() + offset, sizeof(T));
            offset += sizeof(T);
            return value;
        }

        std::string Sized()
        {
            uint32 size = Get<uint32>();
            std::string text(reinterpret_cast<char const*>(bytes.data() + offset), size);
            offset += size;
            return text;
        }
    };

    AscensionClientLuaChunk SampleChunk()
    {
        AscensionClientLuaChunk chunk;
        chunk.RequirementTypeId = 24;
        chunk.RequirementId = 16262;
        chunk.Token = "MANASTORM_UI_FIXES";
        chunk.Lua = "Sample = true";
        return chunk;
    }

}

int main(int argc, char** argv)
{
    if (argc < 3)
        return 2;

    AscensionClientLuaChunk const chunk = SampleChunk();
    {
        WorldSession session;
        Player player;
        player.session = &session;
        BeginAscensionClientLuaSession(1);
        RunAscensionClientLua(&player, chunk);
        Check(session.sent.empty(), "before the capability packet the chunk waits, with no 0x5BC formatter fallback");
        Check(SetAscensionClientLuaCapability(&session, 1, 2) == 1 && session.sent.size() == 1 &&
            session.sent[0].opcode == AscensionClientLuaHotPatchOpcode,
            "the capability packet releases the waiting chunk as one 0x8F0 packet");
        if (session.sent.size() == 1)
        {
            Reader hotPatch{ session.sent[0].bytes };
            Check(hotPatch.Sized() == chunk.Token, "0x8F0 names the token");
            Check(hotPatch.Sized().empty(), "an empty target runs at once");
            Check(hotPatch.Sized() == chunk.Lua, "0x8F0 carries the Lua without the formatter wrapper");
        }
    }
    {
        WorldSession session;
        Player player;
        player.session = &session;
        ForgetAscensionClientLuaCapability(1);
        RunAscensionClientLua(&player, chunk);
        Check(session.sent.empty(), "a client without the hot-patch channel is sent nothing");
    }
    {
        Player player;
        RunAscensionClientLua(&player, chunk);
        RunAscensionClientLua(nullptr, chunk);
    }

    BeginAscensionClientLuaSession(1);
    {
        WorldSession session;
        SetAscensionClientLuaCapability(&session, 1, 2);
    }
    {
        WorldSession session;
        Player player;
        player.session = &session;
        auto& rewards = ManastormRewards::Instance();
        rewards.Value = "{enabled=false}";
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        Check(session.sent.empty(), "initial disabled token mode sends nothing");
        rewards.Value = "{enabled=true,earned=0}";
        GameTime::clock = std::chrono::seconds(100);
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        std::size_t first = session.sent.size();
        Check(first > 0, "initial enabled token state sends a payload");
        GameTime::clock = std::chrono::seconds(101);
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        Check(session.sent.size() == first, "a new second alone does not resend reward Lua");
        GameTime::clock = std::chrono::seconds(160);
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        Check(session.sent.size() > first, "unchanged state periodically resynchronizes the client clock");
        if (session.sent.size() > first)
        {
            auto const& bytes = session.sent[first].bytes;
            std::string payload(bytes.begin(), bytes.end());
            Check(payload.find("receivedAt=GetTime()") != std::string::npos,
                "clock refresh resets client elapsed time");
            Check(payload.find("local function ApplyCoALootState") == std::string::npos,
                "clock refresh omits the full reward UI implementation");
        }
        std::size_t synced = session.sent.size();
        GameTime::clock = std::chrono::seconds(161);
        rewards.Value = "{enabled=true,earned=1}";
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        Check(session.sent.size() > synced, "reward changes send immediately inside the clock refresh interval");
        std::size_t changed = session.sent.size();
        GameTime::clock = std::chrono::seconds(90);
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        Check(session.sent.size() > changed, "server clock rollback resynchronizes instead of waiting for old time");
        rewards.Value = "{enabled=false}";
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        std::size_t disabled = session.sent.size();
        GameTime::clock = std::chrono::seconds(200);
        ManastormClientUIFixes::SendCoALootState(&player, nullptr);
        Check(session.sent.size() == disabled, "disabled state does not send periodic clock updates");
    }

    Check(ManastormClientUIFixes::BuildLua(0).empty(), "mask 0 pushes nothing");
    for (uint32 mask = 0; mask <= ManastormClientUIFixes::FIX_ALL; ++mask)
    {
        std::string const formatter = BuildAscensionClientLuaFormatter("MANASTORM_UI_FIXES",
            ManastormClientUIFixes::BuildLua(mask));
        Check(formatter.find(")lua\"") == std::string::npos, "the Lua never contains the raw-string delimiter");
        std::string path = std::string(argv[1]) + "/chunk-" + (mask < 10 ? "0" : "") + std::to_string(mask) + ".lua";
        std::ofstream(path, std::ios::binary) << "return function(value) " << formatter << " end";
    }

    {
        std::ifstream in(argv[2], std::ios::binary);
        std::string const window((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        Check(!window.empty(), "the Fel Commutation window Lua is read");
        std::ofstream(std::string(argv[1]) + "/fel-window-chunk.lua", std::ios::binary)
            << "return function(value) " << BuildAscensionClientLuaFormatter("FEL_COMMUTATION_WINDOW", window) << " end";

        WorldSession session;
        Player player;
        player.session = &session;
        SendAscensionClientLuaFormatter(&player, 23, "FEL_COMMUTATION_WINDOW", window);
        Check(session.sent.size() == 1 && session.sent[0].opcode == SMSG_COA_PATCH_CHALLENGE_REQUIREMENT_TYPE,
            "the formatter-only push sends just the requirement type patch");
    }

    if (failures)
        return 1;
    std::cout << "manastorm_ui_fixes packets: OK\n";
    return 0;
}
