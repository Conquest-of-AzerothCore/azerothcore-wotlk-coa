import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE.parent))
from client_data import dbc_dir  # noqa: E402


def main():
    structures = (ROOT / 'src/server/shared/DataStores/DBCStructure.h').read_text(encoding='utf-8')
    found = re.search(r'struct TalentSpellPos\n\{.*?\n\};', structures, re.S)
    assert found, 'DBCStructure.h defines TalentSpellPos'

    stores = (ROOT / 'src/server/game/DataStores/DBCStores.cpp').read_text(encoding='utf-8')
    assert 'sTalentSpellPosMap[talentInfo->RankID[j]] = TalentSpellPos(talentInfo->TalentID, j);' in stores, \
        'LoadDBCStores indexes each talent rank spell by its talent id'

    code = (HERE / 'harness.cpp').read_text(encoding='utf-8').replace('// ACTUAL_TALENT_SPELL_POS', found.group(0))

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler
    with tempfile.TemporaryDirectory(prefix='coa-talent-spell-positions-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        exe = out / ('harness.exe' if os.name == 'nt' else 'harness')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe), str(dbc_dir() / 'Talent.dbc')], cwd=out, check=True, timeout=30)


if __name__ == '__main__':
    main()
