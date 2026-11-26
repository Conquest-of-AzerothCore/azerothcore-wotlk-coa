from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
MODULE = ROOT / 'modules/mod-manastorm-endless'

STUBS = {
    'Define.h': '''#pragma once
#include <cstdint>
using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using uint64 = std::uint64_t;
using int32 = std::int32_t;
''',
    'ObjectGuid.h': '''#pragma once
#include "Define.h"
#include <functional>
enum class HighGuid { Player, Unit };
struct ObjectGuid
{
    using LowType = uint32;
    uint64 raw = 0;
    static ObjectGuid const Empty;
    template <HighGuid> static ObjectGuid Create(LowType low) { return { low }; }
    uint64 GetRawValue() const { return raw; }
    LowType GetCounter() const { return LowType(raw); }
    bool IsEmpty() const { return raw == 0; }
    void Clear() { raw = 0; }
    bool operator==(ObjectGuid const& other) const { return raw == other.raw; }
    bool operator!=(ObjectGuid const& other) const { return raw != other.raw; }
};
inline ObjectGuid const ObjectGuid::Empty{};
namespace std
{
    template <> struct hash<ObjectGuid>
    {
        std::size_t operator()(ObjectGuid const& guid) const noexcept { return std::size_t(guid.raw); }
    };
}
''',
    'Position.h': '''#pragma once
#include "Define.h"
struct WorldLocation
{
    uint32 mapId = 0;
};
''',
    'Config.h': '''#pragma once
#include <map>
#include <string>
#include <type_traits>
struct ConfigStub
{
    std::map<std::string, std::string> values;
    template <class T> T GetOption(std::string const& name, T const& fallback) const
    {
        auto const found = values.find(name);
        if (found == values.end())
            return fallback;
        if constexpr (std::is_same_v<T, bool>)
            return found->second == "1";
        else if constexpr (std::is_floating_point_v<T>)
            return T(std::stod(found->second));
        else
            return T(std::stoll(found->second));
    }
};
inline ConfigStub* ConfigInstance()
{
    static ConfigStub config;
    return &config;
}
#define sConfigMgr ConfigInstance()
''',
    'Log.h': '''#pragma once
template <class... Args>
inline void ConsumeLogArgs(Args const&...) {}
inline int& LogErrors()
{
    static int errors = 0;
    return errors;
}
#define LOG_ERROR(...) (ConsumeLogArgs(__VA_ARGS__), ++LogErrors())
#define LOG_WARN(...) ConsumeLogArgs(__VA_ARGS__)
#define LOG_INFO(...) ConsumeLogArgs(__VA_ARGS__)
#define LOG_DEBUG(...) ConsumeLogArgs(__VA_ARGS__)
''',
    'AscensionFreepick.h': '''#pragma once
namespace AscensionFreepick
{
    struct Realm
    {
        bool ConquestOfAzeroth = true;
    };
    inline Realm ReadRealm() { return {}; }
}
''',
    'ManastormReleaseStage.h': '''#pragma once
#include "Define.h"
namespace RaidRelease
{
    inline uint32 ReleasedStage() { return 8; }
}
namespace ManastormReleaseStage
{
    constexpr uint32 AllReleased = 8;
}
''',
    'CoA.Prestige.API.h': '#pragma once\n',
    'CoA.Challenges.Review.h': '#pragma once\n',
    'destiny_weaver.h': '#pragma once\n',
    'gtest/gtest.h': '''#pragma once
#include <cmath>
#include <cstdlib>
#include <vector>
inline std::vector<void(*)()>& GTestRegistry() { static std::vector<void(*)()> tests; return tests; }
struct GTestRegistrar { GTestRegistrar(void(*fn)()) { GTestRegistry().push_back(fn); } };
#define TEST(suite, name) void suite##_##name(); static GTestRegistrar reg_##suite##_##name(&suite##_##name); void suite##_##name()
#define EXPECT_EQ(a, b) do { if (!((a) == (b))) std::exit(1); } while (0)
#define EXPECT_GT(a, b) do { if (!((a) > (b))) std::exit(1); } while (0)
#define EXPECT_LT(a, b) do { if (!((a) < (b))) std::exit(1); } while (0)
#define EXPECT_NEAR(a, b, eps) do { if (!(std::fabs(double(a) - double(b)) <= double(eps))) std::exit(1); } while (0)
#define EXPECT_DOUBLE_EQ(a, b) EXPECT_NEAR(a, b, 1e-12)
''',
}


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def verify_group_scaling_sql():
    pending = ROOT / 'data/sql/updates/pending_db_world'
    matches = [p for p in pending.glob('zzz_*.sql') if 'manastorm_Endgame_group_scaling' in p.read_text(encoding='utf-8')
               and '(15, 15, 9.40, 3.10, 1, 1, 1)' in p.read_text(encoding='utf-8')]
    assert len(matches) == 1, 'Expected zzz_* pending raid group scaling SQL migration for 6..15 members'
    assert matches[0].name > 'zz_manastorm_tuning_curve.sql'
    text = matches[0].read_text(encoding='utf-8')
    for count in range(6, 16):
        hp = f'{1.0 + 0.6 * (count - 1):.2f}'
        normal_dmg = f'{1.0 + 0.05 * (count - 1):.2f}'
        endgame_dmg = f'{1.0 + 0.15 * (count - 1):.2f}'
        assert f'({count}, {count}, {hp}, {normal_dmg}, 1, 1, 1)' in text
        assert f'({count}, {count}, {hp}, {endgame_dmg}, 1, 1, 1)' in text


def main():
    conf = (MODULE / 'conf/manastorm-endless.conf.dist').read_text(encoding='utf-8')
    assert re.search(r'^Manastorm\.ExperienceRate = 0\.3$', conf, re.M), 'conf.dist must ship the 0.3 rate'
    verify_group_scaling_sql()
    manager = (MODULE / 'src/ManastormMgr.cpp').read_text(encoding='utf-8')
    datastore = (MODULE / 'src/ManastormDataStore.cpp').read_text(encoding='utf-8')
    experience = (MODULE / 'src/ManastormExperience.cpp').read_text(encoding='utf-8')
    helpers = '\n'.join([method(manager, 'double GetEndlessExperienceMultiplier('),
                         method(manager, 'double ResolveExternalKillXPMultiplier('),
                         method(manager, 'uint32 ScaleUnsignedValue('),
                         method(experience, 'uint32 ClampXP(')])
    methods = '\n'.join([method(manager, 'void ManastormMgr::OnPlayerGiveXP('),
                         method(manager, 'void ManastormMgr::OnHeal('),
                         method(datastore, 'ManastormScalingPoint ManastormDataStore::GetScalingForDepth(\n'
                                           '    uint32 depth,\n'
                                           '    uint32 memberCount'),
                         method(datastore, 'double ManastormDataStore::GetGroupHealthMultiplier('),
                         method(experience, 'bool ManastormExperience::PrepareCompletion(')])
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    with tempfile.TemporaryDirectory(prefix='manastorm-experience-rate-') as directory:
        out = Path(directory)
        for name, text in STUBS.items():
            target = out / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text, encoding='utf-8')
        for name in ['ManastormDefines.h', 'ManastormRun.h', 'ManastormRun.cpp',
                     'ManastormExperienceFormula.h', 'ManastormModuleConfig.h', 'ManastormModuleConfig.cpp']:
            shutil.copyfile(MODULE / 'src' / name, out / name)
        harness = out / 'harness.cpp'
        harness.write_text((HERE / 'harness.cpp').read_text(encoding='utf-8')
                           .replace('// ACTUAL_HELPERS', helpers).replace('// ACTUAL_METHODS', methods),
                           encoding='utf-8')
        sources = [str(harness), str(out / 'ManastormRun.cpp'), str(out / 'ManastormModuleConfig.cpp')]
        exe = out / ('checks.exe' if os.name == 'nt' else 'checks')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/I' + str(out), *sources, '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl'
                 else ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-Wno-switch',
                       '-I' + str(out), *sources, '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
        unit_src = out / 'unit_runner.cpp'
        unit_src.write_text((MODULE / 'tests/ManastormExperienceFormulaTest.cpp').read_text(encoding='utf-8')
                            + '\nint main() { for (auto fn : GTestRegistry()) fn(); return 0; }\n',
                            encoding='utf-8')
        unit_exe = out / ('unit_checks.exe' if os.name == 'nt' else 'unit_checks')
        unit_flags = (['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/I' + str(out),
                       str(unit_src), '/Fe' + str(unit_exe)]
                      if Path(compiler).stem.lower() == 'cl'
                      else ['-std=c++20', '-Wall', '-Wextra', '-Werror',
                            '-I' + str(out), str(unit_src), '-o', str(unit_exe)])
        subprocess.run([compiler, *unit_flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(unit_exe)], cwd=out, check=True, timeout=30)


if __name__ == '__main__':
    main()
