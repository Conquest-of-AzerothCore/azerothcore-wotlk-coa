import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
WORLD_UPDATES = ROOT / 'data/sql/updates/pending_db_world'


def check_vaults_boss_variants():
    vaults = (WORLD_UPDATES / 'rev_20261028_60_vaults_of_the_inquisition.sql').read_text(encoding='utf-8')
    boss_drops = {
        int(item) for item in re.findall(r'^\(16270[034],(559\d+),0,', vaults, re.MULTILINE)
    }
    existing = vaults.split('INSERT INTO `coa_dungeon_loot_variant`', 1)[1].split(';', 1)[0]
    update = (WORLD_UPDATES / 'rev_20261123_81_coa_vaults_difficulty_loot.sql').read_text(encoding='utf-8')
    variants = {
        int(base): (int(heroic), int(mythic))
        for base, heroic, mythic in re.findall(r'^\((\d+),\s*(\d+),\s*(\d+)\)', existing + update, re.MULTILINE)
    }
    assert len(boss_drops) == 27
    assert boss_drops == variants.keys(), f'Missing or unexpected Vaults variants: {boss_drops ^ variants.keys()}'
    assert all(heroic and mythic and heroic != mythic for heroic, mythic in variants.values())


def main():
    check_vaults_boss_variants()
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler (VS Developer PowerShell on Windows).'
    with tempfile.TemporaryDirectory(prefix='coa-dungeon-loot-') as directory:
        out = Path(directory)
        cpp = out / 'dungeon_loot.cpp'
        exe = out / ('dungeon_loot.exe' if os.name == 'nt' else 'dungeon_loot')
        cpp.write_text(code, encoding='utf-8')
        include = ROOT / 'src/server/coa'
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', '/I' + str(include),
                     str(cpp), '/Fe' + str(exe)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-I' + str(include), str(cpp), '-o', str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    print('PASS: both tiers resolve, quest rows, empty tiers and unknown items keep the rolled item; '
          'Heroic/Mythic maps and store exclusions checked')


if __name__ == '__main__':
    main()
