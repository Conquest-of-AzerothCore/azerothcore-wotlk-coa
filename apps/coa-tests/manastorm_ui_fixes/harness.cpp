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

    void CheckTriggerSequence(std::vector<WorldPacket> const& sent, AscensionClientLuaChunk const& chunk)
    {
        Check(sent.size() >= 5, "the trigger sequence sends five packets");
        if (sent.size() < 5)
            return;

        Check(sent[0].opcode == SMSG_COA_PATCH_CHALLENGE_REQUIREMENT_TYPE, "first packet patches the requirement type");
        Reader type{ sent[0].bytes };
        Check(type.Get<uint32>() == chunk.RequirementTypeId, "requirement type id leads the 36-byte block");
        for (int i = 0; i < 8; ++i)
            Check(type.Get<uint32>() == 0, "requirement type string placeholders are zero");
        Check(type.Sized() == chunk.Token, "string 1 is the token the lookup matches");
        Check(type.Sized() == chunk.Token, "string 2 is the name");
        for (int i = 0; i < 3; ++i)
            Check(type.Sized().empty(), "description and atlases are empty");
        Check(type.Sized() == BuildAscensionClientLuaFormatter(chunk.Token, chunk.Lua), "string 6 is formatter 1");
        Check(type.Sized().empty() && type.Sized().empty(), "formatters 2 and 3 are empty");
        Check(type.offset == sent[0].bytes.size(), "requirement type packet has no trailing bytes");

        Check(sent[1].opcode == SMSG_COA_CHALLENGE_REQUIREMENT, "second packet defines the requirement row");
        Reader requirement{ sent[1].bytes };
        Check(requirement.Get<uint32>() == chunk.RequirementId, "requirement row id");
        requirement.offset = 36;
        Check(requirement.Sized() == chunk.Token, "requirement row names the token");
        Check(requirement.offset == sent[1].bytes.size(), "requirement packet has no trailing bytes");

        Check(sent[2].opcode == SMSG_COA_CHALLENGE_ACTIVE_LIST && sent[2].bytes.size() == 30,
            "third packet activates exactly one 26-byte challenge record");
        Reader active{ sent[2].bytes };
        Check(active.Get<uint32>() == 1 && active.Get<uint32>() == 0 && active.Get<uint32>() == 5,
            "the named challenge 5 is active");

        for (uint32 i = 0; i < 2; ++i)
        {
            WorldPacket const& packet = sent[3 + i];
            Check(packet.opcode == SMSG_COA_CHALLENGE_CRITERIA_UPDATED && packet.bytes.size() == 33,
                "criteria updates are one 33-byte entry");
            Reader criteria{ packet.bytes };
            criteria.Get<uint32>();
            Check(criteria.Get<uint32>() == 5, "criteria belong to challenge 5");
            criteria.Get<uint32>();
            Check(criteria.Get<uint32>() == chunk.RequirementId, "criteria use the requirement row");
            criteria.offset = 24;
            Check(criteria.Get<uint32>() == i, "progress goes 0 then 1");
        }
    }

    int syncCalls = 0;
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
        RunAscensionClientLua(&player, chunk);
        CheckTriggerSequence(session.sent, chunk);
        Check(session.sent.size() == 6, "without a challenge state owner the list is cleared");
        if (session.sent.size() == 6)
            Check(session.sent[5].opcode == SMSG_COA_CHALLENGE_ACTIVE_LIST && session.sent[5].bytes.size() == 4,
                "the trailing packet is an empty active list");
    }
    {
        RegisterAscensionChallengeStateSync([](Player*) { ++syncCalls; });
        WorldSession session;
        Player player;
        player.session = &session;
        RunAscensionClientLua(&player, chunk);
        CheckTriggerSequence(session.sent, chunk);
        Check(session.sent.size() == 5 && syncCalls == 1, "the challenge state owner restores the real list");
    }
    {
        Player player;
        RunAscensionClientLua(&player, chunk);
        RunAscensionClientLua(nullptr, chunk);
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
