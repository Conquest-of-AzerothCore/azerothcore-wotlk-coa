import os
from pathlib import Path
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def main():
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler
    with tempfile.TemporaryDirectory(prefix='coa-dungeon-health-') as directory:
        out = Path(directory)
        header = ROOT / 'src/server/game/Entities/Creature/DungeonHealth.h'
        if header.exists():
            shutil.copyfile(header, out / 'DungeonHealth.h')
        else:
            (out / 'DungeonHealth.h').write_text(
                '#include <cstdint>\n#include <map>\n#include <tuple>\n'
                'namespace DungeonHealth { using Values = std::map<std::tuple<uint32_t, uint32_t, uint32_t>, uint32_t>;'
                ' inline uint32_t Resolve(Values const&, uint32_t, uint8_t, uint32_t, uint32_t current,'
                ' uint32_t, bool, bool) { return current; }}', encoding='utf-8')
        exe = out / ('health.exe' if os.name == 'nt' else 'health')
        source = HERE / 'harness.cpp'
        flags = (['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/I' + str(out), str(source), '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl' else
                 ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-I' + str(out), str(source), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    creature = (ROOT / 'src/server/game/Entities/Creature/Creature.cpp').read_text(encoding='utf-8')
    world = (ROOT / 'src/server/game/World/World.cpp').read_text(encoding='utf-8')
    assert 'health = DungeonHealth::Resolve(' in creature
    assert 'Creature::LoadDungeonHealthOverrides();' in world
    print('PASS: observed HP, separate tiers, provisional estimates, Normal/map/pet exclusions and overflow bounds')


if __name__ == '__main__':
    main()
