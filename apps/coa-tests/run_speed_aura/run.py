from pathlib import Path
import re
import subprocess
import tempfile
import textwrap

root = Path(__file__).resolve().parents[3]
source = (root / 'src/server/coa/AscensionRunSpeed.cpp').read_text()
loader = (root / 'src/server/coa/CoAScriptLoader.cpp').read_text()
assert '    AddSC_AscensionRunSpeed();' in loader
unit = (root / 'src/server/game/Entities/Unit/Unit.cpp').read_text()
speed = unit[unit.index('void Unit::UpdateSpeed('):unit.index('float Unit::GetSpeed(')]
run = speed[speed.index('        case MOVE_RUN:'):speed.index('        case MOVE_SWIM:')]
calculation_start = speed.index('    float speed = std::max(')
calculation = speed[calculation_start:speed.index('    switch (mtype)', calculation_start)]
slow = speed[speed.index('    int32 slow = GetMaxNegativeAuraModifier('):speed.index('    if (float minSpeedMod')]
other_modes = speed[speed.index('        case MOVE_SWIM:'):speed.index('    // now we ready')]
assert 'SPELL_AURA_MOD_INCREASE_SPEED' not in other_modes
auras = (root / 'src/server/game/Spells/Auras/SpellAuras.cpp').read_text()
assert 'if (IsPassive() || (spellInfo->HasAttribute(SPELL_ATTR0_DO_NOT_DISPLAY)' in auras
code = Path(__file__).with_name('test.cpp').read_text()
code = code.replace('PRODUCTION_SOURCE', re.sub(r'^#include.*$', '', source, flags=re.M))
code = code.replace('RUN_BRANCH', run)
code = code.replace('SPEED_CALCULATION', textwrap.indent(calculation, '    '))
code = code.replace('SLOW_CALCULATION', textwrap.indent(slow, '    '))
with tempfile.TemporaryDirectory() as directory:
    path = Path(directory)
    (path / 'test.cpp').write_text(code)
    subprocess.run(['c++', '-std=c++20', '-Wall', '-Wextra', '-Werror', str(path / 'test.cpp'),
        '-o', str(path / 'test')], check=True)
    subprocess.run([str(path / 'test')], check=True)
print('PASS: production callbacks with mocked engine adapters; extracted native running-speed selection and arithmetic. '
    'No gameplay claim.')
