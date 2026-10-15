from pathlib import Path
import runpy
import tempfile


ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'modules/mod-coa-challenges/src'
CONFIG = runpy.run_path(str(Path(__file__).resolve().parents[1] / 'coa_config/run.py'))


def main():
    config_source = (MODULE / 'CoA.Challenges.Config.cpp').read_text()
    source = CONFIG['method'](config_source, 'void AppendClientConfig(AscensionClientConfig& config)')
    with tempfile.TemporaryDirectory(prefix='coa-challenge-config-') as directory:
        out = Path(directory)
        support = CONFIG['write_support'](out)
        CONFIG['compile_and_run'](out, '''#include "AscensionCoAConfig.h"
#include "World.h"
#include "WorldPacket.h"
#include <cassert>
#include <fstream>
#include <string>
#define ASSERT(condition, ...) assert(condition)
''' + support + '''
struct TestConfig
{
    bool challengeEnabled = true;
    bool playerToggle = false;
    template <typename T> T GetOption(char const* key, T fallback)
    {
        if (std::string(key) == "CoAChallenges.ChallengeEnabled")
            return challengeEnabled;
        if (std::string(key) == "CoAChallenges.ChallengeCreatorEnabled")
            return false;
        if (std::string(key) == "CoAChallenges.GameModes.PlayerToggle")
            return playerToggle;
        return fallback;
    }
};
TestConfig config;
TestConfig* sConfigMgr = &config;
namespace CoAChallenges
{
    struct GameModeDef
    {
        char const* configKey;
        char const* hiddenKey;
        char const* name;
    };
    GameModeDef GameModes[] = { { "CONFIG_MODE_ENABLE", "CONFIG_MODE_HIDDEN", "Mode" },
                                { "CONFIG_OTHER_ENABLE", "CONFIG_OTHER_HIDDEN", "Other" } };
    bool challenges = true;
    bool gameModes = false;
    bool ChallengesEnabled() { return challenges; }
    bool GameModesEnabled() { return gameModes; }
    bool GameModeHidden(char const* name) { return std::string(name) == "Other"; }
''' + source + '''
}
void Write(char const* prefix, int index)
{
    WorldPacket const packet = BuildAscensionCoAConfig();
    assert(packet.GetOpcode() == 0x58D);
    std::ofstream file(std::string(prefix) + std::to_string(index), std::ios::binary);
    file.write(reinterpret_cast<char const*>(packet.contents()), packet.size());
}
int main(int, char** argv)
{
    RegisterAscensionClientConfig(&CoAChallenges::AppendClientConfig);
    config.challengeEnabled = false;
    Write(argv[1], 0);
    config.challengeEnabled = true;
    Write(argv[1], 1);
    CoAChallenges::gameModes = true;
    config.playerToggle = true;
    Write(argv[1], 2);
    CoAChallenges::challenges = false;
    Write(argv[1], 3);
}
''', 'packet')
        packets = [CONFIG['decode']((out / f'packet{index}').read_bytes()) for index in range(4)]
        flags = {'CONFIG_CHALLENGE_CREATOR_ENABLED': 0}
        assert packets[0][1] == {**flags, 'CONFIG_CHALLENGE_ENABLED': 0}
        assert packets[1][1] == {**flags, 'CONFIG_CHALLENGE_ENABLED': 1}
        assert packets[2][1] == {**flags, 'CONFIG_CHALLENGE_ENABLED': 1, 'CONFIG_MODE_ENABLE': 1,
                                 'CONFIG_MODE_HIDDEN': 0, 'CONFIG_OTHER_ENABLE': 1, 'CONFIG_OTHER_HIDDEN': 1}
        assert packets[3][1] == {}
        assert all(packet[3] == CONFIG['expected_rates'](1) for packet in packets)
    print('PASS: Challenges flags join the shared config packet beside the XP rates, follow config, '
          'lock or unlock game modes, hide unsupported modes and vanish when challenges are off')


if __name__ == '__main__':
    main()
