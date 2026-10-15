#include "../../../src/server/coa/AscensionManastormProtocol.h"

#include "../src/ManastormClientConfig.h"
#include <string>
#include <bit>
#include <cassert>
#include <cstring>
#include <vector>

// Golden wire checks against the final recovered contract, independent of
// WorldSession, a running database, or the donor's gameplay implementation.
struct Buffer
{
    std::vector<unsigned char> bytes;

    Buffer& operator<<(std::uint32_t value)
    {
        for (unsigned shift = 0; shift < 32; shift += 8)
            bytes.push_back(static_cast<unsigned char>(value >> shift));
        return *this;
    }

    void append(std::uint8_t const* data, std::size_t size)
    {
        bytes.insert(bytes.end(), data, data + size);
    }

    Buffer& operator<<(std::uint8_t value)
    {
        bytes.push_back(value);
        return *this;
    }

    Buffer& operator<<(float value)
    {
        return *this << std::bit_cast<std::uint32_t>(value);
    }

    Buffer& operator<<(char const* value)
    {
        bytes.insert(bytes.end(), value, value + std::strlen(value) + 1);
        return *this;
    }
};

int main()
{
    using namespace Ascension::Manastorm;
    char const* const names[] = {"SOLO", "DUO", "TRIO", "GROUP", "SOLO_END_GAME",
        "DUO_END_GAME", "TRIO_END_GAME", "GROUP_END_GAME"};
    for (std::uint8_t type = 0; type < 8; ++type)
    {
        Buffer packet;
        WriteActive(packet, 51, 12, type, 2, 0.25f, 1278051);
        std::vector<unsigned char> expected = {51, 0, 0, 0, 12, 0, 0, 0};
        expected.insert(expected.end(), names[type], names[type] + std::strlen(names[type]) + 1);
        expected.insert(expected.end(), {2, 0, 0, 0, 0, 0, 128, 62, 99, 128, 19, 0});
        assert(packet.bytes == expected);
    }
    Buffer inactive;
    WriteActive(inactive, 0, 0, 0);
    assert(inactive.bytes.size() == 25);
    for (std::size_t i = 0; i < inactive.bytes.size(); ++i)
        if (i < 8 || i > 11)
            assert(inactive.bytes[i] == 0);

    Progress progress;
    progress[0] = {5};
    progress[4] = {5};
    Buffer snapshot;
    WriteProgress(snapshot, progress);
    std::vector<unsigned char> const expected = {
        8, 0, 0, 0,
        1, 0, 0, 0, 5, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 0, 0, 0, 5, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };
    assert(snapshot.bytes == expected);
    // Model the client's full replacement, not an incremental merge.
    std::map<std::string, std::uint32_t> clientInts;
    std::map<std::string, bool> clientBools;
    auto receive = [&](NativeClientConfig const& state)
    {
        Buffer config;
        state.Write(config);
        clientInts.clear();
        clientBools.clear();
        std::size_t cursor = 0;
        auto word = [&]()
        {
            std::uint32_t value = 0;
            for (unsigned shift = 0; shift < 32; shift += 8)
                value |= std::uint32_t(config.bytes.at(cursor++)) << shift;
            return value;
        };
        auto key = [&]()
        {
            auto size = word();
            std::string value;
            while (size--)
                value += char(config.bytes.at(cursor++));
            return value;
        };
        auto count = word();
        while (count--)
        {
            auto name = key();
            clientInts[name] = word();
        }
        count = word();
        while (count--)
        {
            auto name = key();
            auto value = config.bytes.at(cursor++);
            assert(value <= 1);
            clientBools[name] = value != 0;
        }
        for (unsigned section = 0; section < 4; ++section)
            assert(word() == 0);
        assert(cursor == config.bytes.size());
    };
    for (bool enabled : {false, true})
        for (bool challengeFirst : {false, true})
        {
            NativeClientConfig state;
            auto challengeLogin = [&]()
            {
                state.SetBool("CONFIG_CHALLENGE_ENABLED", true);
                state.SetBool("CONFIG_CHALLENGE_CREATOR_ENABLED", false);
                receive(state);
            };
            if (challengeFirst)
                challengeLogin();
            ManastormClientConfig::Apply(state, enabled);
            receive(state);
            if (!challengeFirst)
                challengeLogin();
            assert(clientInts.size() == 1);
            assert(clientInts.at("CONFIG_MANASTORM_LOADOUTS_MAX") == 4);
            assert(clientBools.size() == 5);
            for (auto name : {"CONFIG_MANASTORM_ENABLED", "CONFIG_MANASTORM_END_GAME_ENABLED",
                "CONFIG_MANASTORM_LOADOUTS_ENABLED"})
                assert(clientBools.at(name) == enabled);
            assert(clientBools.at("CONFIG_CHALLENGE_ENABLED"));
            assert(!clientBools.at("CONFIG_CHALLENGE_CREATOR_ENABLED"));
            state.SetBool("CONFIG_CHALLENGE_ENABLED", false);
            receive(state);
            assert(clientBools.at("CONFIG_MANASTORM_ENABLED") == enabled);
            ManastormClientConfig::Apply(state, !enabled);
            receive(state);
            assert(!clientBools.at("CONFIG_CHALLENGE_ENABLED"));
            assert(clientBools.at("CONFIG_MANASTORM_ENABLED") == !enabled);
            state.Clear();
            receive(state);
            assert(clientInts.empty() && clientBools.empty());
        }
}
