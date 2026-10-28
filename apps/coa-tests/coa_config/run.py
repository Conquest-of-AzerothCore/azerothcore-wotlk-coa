import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'src/server/coa'
INCLUDE_DIRS = [MODULE, ROOT / 'src/common', ROOT / 'src/common/Utilities', ROOT / 'src/server/shared/Packets',
                ROOT / 'src/server/game/Server', ROOT / 'src/server/game/Server/Protocol']


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def decode(data, *, allow_duplicate_keys=False):
    offset = 0

    def take(fmt):
        nonlocal offset
        result = struct.unpack_from(fmt, data, offset)[0]
        offset += struct.calcsize(fmt)
        return result

    sections = []
    for value_format in ('<i', '<B', '<f', '<f'):
        values = {}
        for _ in range(take('<I')):
            length = take('<I')
            key = data[offset:offset + length].decode('ascii')
            offset += length
            assert '\0' not in key and (allow_duplicate_keys or key not in values)
            values[key] = take(value_format)
        sections.append(values)
    assert [take('<I') for _ in range(2)] == [0, 0]
    assert offset == len(data)
    return sections


def config_names():
    config = (ROOT / 'src/server/game/World/WorldConfig.h').read_text()
    config_enum = re.search(r'enum ServerConfigs\s*\{.*?\};', config, re.S)[0]
    return config_enum, re.findall(r'^\s*(\w+)\s*(?:=\s*0)?\s*[,}]', config_enum, re.M)


def write_support(out):
    config_enum, _ = config_names()
    (out / 'World.h').write_text('#pragma once\n#include "Define.h"\n' + config_enum + '''
struct TestWorld
{
    float scale = 1;
    float getRate(ServerConfigs setting) const { return scale * (float(setting) + 0.25f); }
};
inline TestWorld world;
inline TestWorld* sWorld = &world;
''')
    (out / 'WorldSession.h').write_text('''#pragma once
#include "WorldPacket.h"
struct Player
{
    bool inWorld = false;
    bool IsInWorld() const { return inWorld; }
};
class WorldSession
{
public:
    WorldPacket sent;
    Player* player = nullptr;
    uint32 packets = 0;
    Player* GetPlayer() const { return player; }
    void SendPacket(WorldPacket const* packet) { sent = *packet; ++packets; }
};
''')
    buffer_source = (ROOT / 'src/server/shared/Packets/ByteBuffer.cpp').read_text()
    return '\n'.join(method(buffer_source, signature) for signature in (
        'void ByteBuffer::append(uint8 const* src, std::size_t cnt)',
        'ByteBufferPositionException::ByteBufferPositionException(',
    ))


def compile_and_run(out, main_source, packet_prefix):
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler, 'A C++20 compiler is required'
    (out / 'main.cpp').write_text(main_source)
    command = [compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror']
    command += [flag for path in [out, *INCLUDE_DIRS] for flag in ('-I', str(path))]
    command += [str(out / 'main.cpp'), str(MODULE / 'AscensionCoAConfig.cpp'),
                str(ROOT / 'src/common/Utilities/Tokenize.cpp'), '-o', str(out / 'test')]
    subprocess.run(command, check=True)
    subprocess.run([str(out / 'test'), str(out / packet_prefix)], check=True)


def expected_rates(scale):
    _, names = config_names()
    expected = {'RATE_XP_GLOBAL': 'RATE_XP_GLOBAL', 'RATE_XP_PROFESSION': 'RATE_XP_PROFESSION',
                'RATE_AUCTION_DEPOSIT': 'RATE_AUCTION_DEPOSIT'}
    for key in ('KILL KILL_TBC KILL_WOTLK QUEST QUEST_TBC QUEST_WOTLK EXPLORE ELITE DUNGEON_ELITE').split():
        expected[f'RATE_XP_{key}'] = f'RATE_XP_{key}'
    for suffix in ('GRAY GREEN YELLOW ORANGE MINING HERBALISM DISENCHANTING SKINNING FISHING '
                   'BLACKSMITHING JEWELCRAFTING ALCHEMY ENCHANTING LEATHERWORKING FIRST_AID '
                   'COOKING ENGINEERING TAILORING LOCKPICKING INSCRIPTION').split():
        expected[f'RATE_XP_PROFESSION_{suffix}_MODIFIER'] = f'RATE_XP_PROFESSION_{suffix}'
    return {key: scale * (names.index(setting) + 0.25) for key, setting in expected.items()}


def verify_reload(out, support):
    source = (MODULE / 'AscensionCompat.cpp').read_text()
    hook = method(source, 'void OnAfterConfigLoad(bool reload)').replace(' override', '')
    registration = method(source[source.index('void AddAscensionCompatScripts()'):],
                          'RegisterAscensionClientConfig([]') + ');'
    configured = method(source, 'void AppendConfiguredClientConfigs(')
    compile_and_run(out, '''#include "AscensionCoAConfig.h"
#include "World.h"
#include "WorldSession.h"
#include <cassert>
#include <fstream>
#include <map>
#include <sstream>
#include <type_traits>
#define ASSERT(condition, ...) assert(condition)
''' + support + '''
struct AscensionCompatConfig
{
    enum Key { ENABLED, CLIENT_BOOLEAN_CONFIGS, CLIENT_INTEGER_CONFIGS };
    bool enabled = true;
    std::string booleans;
    std::string integers = "CONFIG_TEST_INTEGER=7";
    template <typename T> T GetConfigValue(Key key) const
    {
        if constexpr (std::is_same_v<T, bool>)
            return enabled;
        else
            return key == CLIENT_BOOLEAN_CONFIGS ? booleans : integers;
    }
} ascensionCompatConfig;

struct SessionManager
{
    std::map<uint32, WorldSession*> sessions;
    auto const& GetAllSessions() const { return sessions; }
} sessionManager;
SessionManager* sWorldSessionMgr = &sessionManager;

void ReportRenamedConfiguration() { }
''' + hook + '\n' + configured + '''
int main(int, char** argv)
{
''' + registration + '''
    RegisterAscensionClientConfig(AppendConfiguredClientConfigs);
    Player connected{true};
    Player loading{false};
    WorldSession online;
    WorldSession transferring;
    WorldSession authenticating;
    online.player = &connected;
    transferring.player = &loading;
    sessionManager.sessions = {{1, &online}, {2, &transferring}, {3, &authenticating}, {4, nullptr}};
    OnAfterConfigLoad(false);
    assert(online.packets == 0);

    for (int index = 0; index != 6; ++index)
    {
        ascensionCompatConfig.enabled = index == 0 || index == 3 || index == 4;
        ascensionCompatConfig.booleans = index == 4 ? "CONFIG_THROWN_WEAPON_APPEARANCES_ENABLED=0" :
            index == 5 ? "CONFIG_THROWN_WEAPON_APPEARANCES_ENABLED=1" : "";
        world.scale = index + 1;
        OnAfterConfigLoad(true);
        assert(online.packets == uint32(index + 1) && "every reload must replace the connected client's config");
        assert(transferring.packets == 0 && authenticating.packets == 0);
        assert(online.sent.GetOpcode() == 0x58D);
        std::ofstream file(std::string(argv[1]) + std::to_string(index), std::ios::binary);
        file.write(reinterpret_cast<char const*>(online.sent.contents()), online.sent.size());
    }
}
''', 'reload')
    for index, enabled in enumerate((1, 0, 0, 1, 0, 1)):
        integers, booleans, floats, rates = decode((out / f'reload{index}').read_bytes(),
                                                 allow_duplicate_keys=index >= 4)
        assert integers == {'CONFIG_TEST_INTEGER': 7}
        assert booleans == {'CONFIG_CHARACTER_ADVANCEMENT_BUILD_INSPECT_ENABLED': 1,
                            'CONFIG_THROWN_WEAPON_APPEARANCES_ENABLED': enabled}
        assert floats == {} and rates == expected_rates(index + 1)


def main():
    with tempfile.TemporaryDirectory(prefix='coa-config-') as directory:
        out = Path(directory)
        support = write_support(out)
        compile_and_run(out, '''#include "AscensionCoAConfig.h"
#include "World.h"
#include "WorldSession.h"
#include <cassert>
#include <fstream>
#include <sstream>
#define ASSERT(condition, ...) assert(condition)
''' + support + '''
void Write(char const* prefix, int index, WorldPacket const& packet)
{
    assert(packet.GetOpcode() == 0x58D);
    std::ofstream file(std::string(prefix) + std::to_string(index), std::ios::binary);
    file.write(reinterpret_cast<char const*>(packet.contents()), packet.size());
}

int main(int, char** argv)
{
    SendAscensionCoAConfig(nullptr);
    for (int i = 0; i != 3; ++i)
    {
        world.scale = i;
        WorldSession session;
        SendAscensionCoAConfig(&session);
        Write(argv[1], i, session.sent);
    }
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        config.Integers.emplace_back("CONFIG_TEST_INTEGER", -3);
        config.Booleans.emplace_back("CONFIG_TEST_ON", true);
        config.Floats.emplace_back("CONFIG_TEST_FLOAT", 1.5f);
        config.Rates.emplace_back("RATE_TEST", 2.5f);
    });
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        config.Booleans.emplace_back("CONFIG_TEST_OFF", false);
    });
    world.scale = 1;
    Write(argv[1], 3, BuildAscensionCoAConfig());
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        AppendAscensionClientConfigList(" CONFIG_LIST_OFF =0,CONFIG_LIST_ON= 1,missing,=1,CONFIG_LIST_WORD=yes,,",
                                        config.Booleans);
        AppendAscensionClientConfigList("CONFIG_LIST_INTEGER=-7,CONFIG_LIST_PARTIAL=4x", config.Integers);
    });
    Write(argv[1], 4, BuildAscensionCoAConfig());
}
''', 'packet')
        for scale in range(3):
            integers, booleans, floats, rates = decode((out / f'packet{scale}').read_bytes())
            assert (integers, booleans, floats) == ({}, {}, {})
            assert rates == expected_rates(scale)
        integers, booleans, floats, rates = decode((out / 'packet3').read_bytes())
        assert integers == {'CONFIG_TEST_INTEGER': -3}
        assert booleans == {'CONFIG_TEST_ON': 1, 'CONFIG_TEST_OFF': 0}
        assert floats == {'CONFIG_TEST_FLOAT': 1.5}
        assert rates == {**expected_rates(1), 'RATE_TEST': 2.5}
        integers, booleans, _, _ = decode((out / 'packet4').read_bytes())
        assert integers == {'CONFIG_TEST_INTEGER': -3, 'CONFIG_LIST_INTEGER': -7}
        assert booleans == {'CONFIG_TEST_ON': 1, 'CONFIG_TEST_OFF': 0, 'CONFIG_LIST_OFF': 0, 'CONFIG_LIST_ON': 1}
        verify_reload(out, support)
    print(f'PASS: opcode, six sections, {len(expected_rates(1))} rate mappings, key framing, refreshed rates, '
          'null session, registered integer, boolean, float and rate values share one packet, '
          'configured NAME=value lists skip malformed entries, complete reload packets across disable/re-enable, '
          'session filtering and explicit override precedence')


if __name__ == '__main__':
    main()
