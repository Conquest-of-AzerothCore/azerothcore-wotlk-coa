CLI_DESCRIPTION = """Check the vanilla 1.12 reputation spillover used for characters up to level 60."""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']

VMANGOS_SPILLOVER = {
    67: {68: 0.25, 76: 0.25, 81: 0.25, 530: 0.25},
    169: {21: 1.0, 369: 1.0, 470: 1.0, 577: 1.0},
    469: {47: 0.25, 54: 0.25, 69: 0.25, 72: 0.25},
}
TBC_CAPITALS = {67: 911, 469: 930}
CAPITALS = (47, 54, 68, 69, 72, 76, 81, 530, 911, 930)


def expected_rows():
    rows = []
    for faction, targets in VMANGOS_SPILLOVER.items():
        targets = dict(targets)
        if faction in TBC_CAPITALS:
            targets[TBC_CAPITALS[faction]] = 0.25
        rows.append((faction, targets))
    rows += [(capital, {}) for capital in CAPITALS]
    return rows


def main():
    argparse.ArgumentParser(description=CLI_DESCRIPTION).parse_args()
    manager = (ROOT / 'src/server/game/Reputation/ReputationMgr.cpp').read_text(encoding='utf-8')
    body = method(manager, 'bool ReputationMgr::SetReputation(')
    classic = body.index('ClassicPlusReputation::Find(factionEntry->ID)')
    assert body.index('CONFIG_CLASSIC_PLUS_REPUTATION_SPILLOVER') < classic
    assert body.index('ClassicPlusReputation::MaxLevel') < classic
    assert classic < body.index('sObjectMgr->GetRepSpilloverTemplate(factionEntry->ID)')

    checks = []
    for faction, targets in expected_rows():
        checks.append(f'    {{ auto const* s = Find({faction}); assert(s);')
        checks.append(f'      std::map<uint32, float> got; for (auto const& t : s->targets) if (t.faction) '
                      f'got[t.faction] = t.rate;')
        expected = ', '.join(f'{{{target}, {rate}f}}' for target, rate in sorted(targets.items()))
        checks.append(f'      assert((got == std::map<uint32, float>{{ {expected} }})); }}')
    code = '''#include "ClassicPlusReputation.h"
#include <cassert>
#include <map>
using namespace ClassicPlusReputation;
int main()
{
    static_assert(MaxLevel == 60);
    assert(!Find(21) && !Find(369) && !Find(1037) && !Find(0));
''' + '\n'.join(checks) + '''
    return 0;
}
'''
    compiler = shutil.which(os.environ.get('CXX', 'c++'))
    assert compiler, 'A C++20 compiler is required'
    with tempfile.TemporaryDirectory(prefix='coa-classic-reputation-') as directory:
        out = Path(directory)
        (out / 'main.cpp').write_text(code, encoding='utf-8')
        exe = out / 'classic_reputation'
        subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror',
                        '-I', str(ROOT / 'src/server/game/Reputation'), '-I', str(ROOT / 'src/common'),
                        str(out / 'main.cpp'), '-o', str(exe)], check=True)
        subprocess.run([str(exe)], check=True)
    print('PASS: vanilla Alliance, Horde and Steamwheedle spillover, no capital-to-capital spillover, '
          'gated by ClassicPlus.ReputationSpillover and level 60 before the database template')


if __name__ == '__main__':
    main()
