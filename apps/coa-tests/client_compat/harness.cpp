#include "DBCStore.h"
#include "DBCDatabaseLoader.h"
#include <array>
#include <chrono>
#include <cmath>
#include <fstream>
#include <iostream>
#include <mutex>
#include <utility>

namespace
{
int failures = 0;
int checks = 0;
void Check(bool value, char const* name)
{
    ++checks;
    failures += !value;
    std::cout << (value ? "PASS: " : "FAIL: ") << name << '\n';
}
}

DBCDatabaseLoader::DBCDatabaseLoader(char const*, char const* format, std::vector<char*>& pool)
    : _sqlTableName(nullptr), _dbcFormat(format), _sqlIndexPos(0), _recordSize(4), _stringPool(pool) { }
char* DBCDatabaseLoader::Load(uint32& records, char**& index)
{
    assert(std::strcmp(_dbcFormat, "df") == 0 && records == 3200);
    char* row = new char[sizeof(float)];
    float value = 900.0f;
    std::memcpy(row, &value, sizeof(value));
    index[0] = row;
    return row;
}

struct GtOCTRegenHPEntry { float ratio; };
struct GtRegenHPPerSptEntry { float ratio; };
struct GtRegenMPPerSptEntry { float ratio; };
DBCStorage<GtOCTRegenHPEntry> sGtOCTRegenHPStore("df");
DBCStorage<GtRegenHPPerSptEntry> sGtRegenHPPerSptStore("df");
DBCStorage<GtRegenMPPerSptEntry> sGtRegenMPPerSptStore("df");
constexpr uint32 GT_MAX_LEVEL = 100;
constexpr uint32 STAT_SPIRIT = 4;
struct Player
{
    uint8 Class = 23;
    uint8 Level = 80;
    float Spirit = 100;
    uint8 GetLevel() const { return Level; }
    uint8 getClass() const { return Class; }
    float GetStat(uint32) const { return Spirit; }
    float OCTRegenHPPerSpirit();
    float OCTRegenMPPerSpirit();
};
// ACTUAL_HP_REGEN
// ACTUAL_MP_REGEN

template<class T>
bool VerifyFile(DBCStorage<T>& store, std::string const& path)
{
    if (!store.Load(path.c_str()))
        return false;
    std::ifstream input(path, std::ios::binary);
    uint32 header[5];
    input.read(reinterpret_cast<char*>(header), sizeof(header));
    if (header[2] != 1 || header[3] != 4 || header[1] != store.GetNumRows())
        return false;
    for (uint32 i = 0; i < header[1]; ++i)
    {
        float value;
        input.read(reinterpret_cast<char*>(&value), sizeof(value));
        if (!input || !store.LookupEntry(i) || store.LookupEntry(i)->ratio != value)
            return false;
    }
    return !store.LookupEntry(header[1]);
}

void TestDBC(std::string const& folder, bool installed)
{
    if (installed)
    {
        DBCStorage<GtOCTRegenHPEntry> hp("df");
        DBCStorage<GtRegenHPPerSptEntry> spirit("df");
        DBCStorage<GtRegenMPPerSptEntry> mana("df");
        Check(VerifyFile(hp, folder + "/gtOCTRegenHP.dbc") &&
            VerifyFile(spirit, folder + "/gtRegenHPPerSpt.dbc") &&
            VerifyFile(mana, folder + "/gtRegenMPPerSpt.dbc"), "all installed regeneration coefficients load exactly");
        return;
    }
    bool loaded = VerifyFile(sGtOCTRegenHPStore, folder + "/gtOCTRegenHP.dbc") &&
        VerifyFile(sGtRegenHPPerSptStore, folder + "/gtRegenHPPerSpt.dbc") &&
        VerifyFile(sGtRegenMPPerSptStore, folder + "/gtRegenMPPerSpt.dbc");
    Check(loaded, "implicit row IDs retain all 32 classes and valid zero coefficients");
    if (loaded)
    {
        bool formulas = true;
        Player player;
        for (uint8 classId = 1; classId <= 32; ++classId)
            for (uint8 level : {1, 10, 80, 100, 101})
            {
                player.Class = classId;
                player.Level = level;
                player.Spirit = 100;
                formulas &= player.OCTRegenHPPerSpirit() == 75.0f;
                formulas &= std::fabs(player.OCTRegenMPPerSpirit() - (classId == 12 ? 0.0f : 1.0f)) < 0.00001f;
                player.Spirit = 25;
                formulas &= player.OCTRegenHPPerSpirit() == 12.5f;
            }
        Check(formulas, "native regeneration formulas, spirit breakpoint and level cap for every class");
        player.Class = 33;
        Check(player.OCTRegenHPPerSpirit() == 0 && player.OCTRegenMPPerSpirit() == 0,
            "missing classes remain safely handled");
        sGtOCTRegenHPStore.LoadFromDB("test_overlay", sGtOCTRegenHPStore.GetFormat());
        Check(sGtOCTRegenHPStore.LookupEntry(0)->ratio == 900.0f &&
            sGtOCTRegenHPStore.LookupEntry(3199)->ratio == 0.25f,
            "SQL keeps explicit IDs and overrides existing rows without losing custom classes");
    }
    DBCStorage<GtOCTRegenHPEntry> indexed("df");
    Check(indexed.Load((folder + "/indexed.dbc").c_str()) && indexed.GetNumRows() == 8 &&
        !indexed.LookupEntry(0) && indexed.LookupEntry(2)->ratio == 1.5f && indexed.LookupEntry(7)->ratio == 2.5f,
        "explicit sparse-ID files retain their original layout");
    DBCStorage<GtOCTRegenHPEntry> invalid("df");
    Check(!invalid.Load((folder + "/invalid.dbc").c_str()), "invalid float record size is rejected");
}

struct TestClock
{
    using duration = std::chrono::steady_clock::duration;
    using time_point = std::chrono::time_point<TestClock>;
    static inline time_point Current{std::chrono::seconds(100)};
    static time_point now() { return Current; }
};
using TimePoint = TestClock::time_point;
#define steady_clock TestClock
#define LOG_ERROR(...) ((void)0)
constexpr uint32 CONFIG_MAX_OVERSPEED_PINGS = 0;
constexpr uint32 SMSG_PONG = 1;
namespace rbac { constexpr uint32 RBAC_PERM_SKIP_CHECK_OVERSPEED_PING = 23; }
struct World
{
    uint32 MaxStrikes = 2;
    uint32 getIntConfig(uint32) const { return MaxStrikes; }
} world;
World* sWorld = &world;
struct Config
{
    bool Enabled = false;
    bool AllowRemote = false;
    template<class T> T GetOption(char const* name, T fallback, bool = true) const
    {
        if (std::strcmp(name, "CoA.Enable") == 0)
            return T(Enabled);
        if (std::strcmp(name, "CoA.AllowRemoteClients") == 0)
            return T(AllowRemote);
        return fallback;
    }
} config;
Config* sConfigMgr = &config;
struct WorldSession
{
    bool GM = false;
    uint32 Latency = 0;
    bool HasPermission(uint32) const { return GM; }
    void SetLatency(uint32 value) { Latency = value; }
};
struct WorldPacket
{
    uint32 Values[2]{0, 42};
    uint32 Position = 0;
    WorldPacket() = default;
    WorldPacket(uint32, uint32) { }
    WorldPacket& operator>>(uint32& value) { value = Values[Position++]; return *this; }
    WorldPacket& operator<<(uint32) { return *this; }
};
struct IoContextTcpSocket { bool Loopback; };
struct Socket
{
    bool Loopback;
    explicit Socket(IoContextTcpSocket&& socket) : Loopback(socket.Loopback) { }
    Socket const& GetRemoteIpAddress() const { return *this; }
    bool is_loopback() const { return Loopback; }
};
namespace Acore::Crypto { void GetRandomBytes(std::array<uint8, 4>&) { } }
struct ClientPktHeader { uint32 Value; };
struct WorldSocket : Socket
{
    explicit WorldSocket(IoContextTcpSocket&& socket);
    bool HandlePing(WorldPacket& packet);
    std::array<uint8, 4> _authSeed{};
    // ACTUAL_PING_STATE
    std::mutex _worldSessionLock;
    WorldSession* _worldSession;
    bool _authed;
    std::size_t _sendBufferSize;
    bool _loggingPackets;
    bool _loggedFirstClientHeader;
    struct Buffer { void Resize(std::size_t) { } } _headerBuffer;
    uint32 Pongs = 0;
    void SendPacketAndLogOpcode(WorldPacket const&) { ++Pongs; }
};
// ACTUAL_SOCKET_CONSTRUCTOR
// ACTUAL_PING
#undef steady_clock

bool Ping(WorldSocket& socket, std::chrono::milliseconds elapsed)
{
    TestClock::Current += elapsed;
    WorldPacket packet;
    return socket.HandlePing(packet);
}

void TestPing(bool enabled, bool loopback, bool gm, bool expected, bool allowRemote = false)
{
    using namespace std::chrono_literals;
    config.Enabled = enabled;
    config.AllowRemote = allowRemote;
    WorldSession session;
    session.GM = gm;
    WorldSocket socket(IoContextTcpSocket{loopback});
    socket._worldSession = &session;
    bool connected = Ping(socket, 0ms);
    for (int i = 0; i < 24 && connected; ++i)
        connected = Ping(socket, 5s);
    Check(connected == expected && session.Latency == 42,
        enabled && (loopback || allowRemote) && !gm ?
        "ordinary Ascension account accepts two minutes of five-second pings" :
        gm ? "existing GM permission remains effective" : "unconfigured sessions retain the 27-second limit");
    Check(socket._ascensionCompatEnabled == (enabled && (loopback || allowRemote)),
        "the Ascension protocol requires loopback or explicit remote configuration");
}

void TestFlood(bool loopback = true)
{
    using namespace std::chrono_literals;
    config.Enabled = true;
    config.AllowRemote = !loopback;
    WorldSession session;
    WorldSocket socket(IoContextTcpSocket{loopback});
    socket._worldSession = &session;
    Check(Ping(socket, 0ms) && Ping(socket, 1s) && Ping(socket, 1s) && !Ping(socket, 1s),
        "ordinary Ascension accounts are still disconnected for sustained ping flooding");
    WorldSocket recovered(IoContextTcpSocket{loopback});
    recovered._worldSession = &session;
    Check(Ping(recovered, 0ms) && Ping(recovered, 1s) && Ping(recovered, 1s) && Ping(recovered, 4s) &&
        Ping(recovered, 1s), "jitter margin and good intervals reset overspeed strikes");
    config.Enabled = false;
    Check(Ping(recovered, 5s) && Ping(recovered, 5s), "ping compatibility is cached per connection");
    WorldSocket stock(IoContextTcpSocket{true});
    stock._worldSession = &session;
    Check(Ping(stock, 0ms) && Ping(stock, 30s) && Ping(stock, 27s), "ordinary stock ping cadence is accepted");
    sWorld->MaxStrikes = 0;
    Check(Ping(stock, 1ms) && Ping(stock, 1ms) && Ping(stock, 1ms) && Ping(stock, 1ms),
        "configured disabled overspeed enforcement remains effective");
    sWorld->MaxStrikes = 2;
    WorldSocket unauthenticated(IoContextTcpSocket{true});
    Check(!Ping(unauthenticated, 0ms), "unauthenticated pings remain rejected");
}

int main(int argc, char** argv)
{
    assert(argc >= 2);
    TestDBC(argv[1], false);
    if (argc > 2)
        TestDBC(argv[2], true);
    TestPing(true, true, false, true);
    TestPing(false, true, false, false);
    TestPing(true, false, false, false);
    TestPing(true, false, false, true, true);
    TestPing(false, false, false, false, true);
    TestPing(false, true, true, true);
    TestFlood();
    TestFlood(false);
    std::cout << checks - failures << '/' << checks << " checks passed\n";
    return failures ? 1 : 0;
}
