CLI_DESCRIPTION = """Run the Keeper's Scroll: Eonar kill hook against controlled kills, zones and proc rolls.

Compiles modules/mod-coa-titan-scrolls/src/TitanScrollEonarKill.cpp with stand-ins for the killer, the killed
creature, the area table, the per-character view of the creature and roll_chance_i, so the proc roll is forced
both ways. The expected chance and heal come from 993957's client record: ProcChance 10 and the tooltip's
"granting 5% of creature health". Pass --dbc-dir (or set COA_DBC_DIR) to check them against Spell.dbc, and
--source-ref to run the same cases on another Git ref.
"""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import sys
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']

sys.path.insert(0, str(HERE.parent))
from client_data import SERVER_DBC_DIR  # noqa: E402
from source_paths import git_source  # noqa: E402

HOOK = 'modules/mod-coa-titan-scrolls/src/TitanScrollEonarKill.cpp'
SPELL_DEFINES = 'src/server/game/Spells/SpellDefines.h'
DBC_ENUMS = 'src/server/shared/DataStores/DBCEnums.h'
BUFF = 993957
BLESSING = 993963
CHANCE = 10
HEAL_PERCENT = 5
SPELL_PROC_CHANCE = 35
SPELL_TOOLTIP_ENUS = 187


def client_record(dbc_dir):
    spell_dbc = dbc_dir / 'Spell.dbc'
    if not spell_dbc.is_file():
        return f'{spell_dbc} not found, client record check skipped'
    blob = spell_dbc.read_bytes()
    count, fields, size, _ = struct.unpack_from('<4I', blob, 4)
    strings = 20 + count * size
    rows = {}
    for index in range(count):
        offset = 20 + index * size
        if struct.unpack_from('<I', blob, offset)[0] in (BUFF, BLESSING):
            row = struct.unpack_from(f'<{fields}I', blob, offset)
            rows[row[0]] = row
    assert set(rows) == {BUFF, BLESSING}, f'Spell.dbc lacks {sorted({BUFF, BLESSING} - set(rows))}'
    start = strings + rows[BUFF][SPELL_TOOLTIP_ENUS]
    tooltip = blob[start:blob.index(b'\0', start)].decode('utf-8', errors='replace')
    assert rows[BUFF][SPELL_PROC_CHANCE] == CHANCE, f'{BUFF} ProcChance is {rows[BUFF][SPELL_PROC_CHANCE]}'
    assert f'granting {HEAL_PERCENT}% of creature health' in tooltip, f'{BUFF} tooltip reads {tooltip!r}'
    return f'client record: {BUFF} ProcChance {CHANCE}, tooltip "{HEAL_PERCENT}% of creature health"'


def harness(source):
    defines = source(SPELL_DEFINES)
    typedef = next(line for line in defines.splitlines() if line.endswith('> CustomSpellValueMod;'))
    capital = re.search(r'AREA_FLAG_CAPITAL\s*=\s*(0x[0-9A-Fa-f]+)', source(DBC_ENUMS)).group(1)
    native = '\n'.join([method(defines, 'enum SpellValueMod') + ';', method(defines, 'enum TriggerCastFlags') + ';',
                        typedef, method(defines, 'class CustomSpellValues') + ';',
                        f'constexpr uint32 AREA_FLAG_CAPITAL = {capital};'])
    hook = re.sub(r'^#include.*\n', '', source(HOOK), flags=re.M)
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in (('// NATIVE', native), ('// SOURCE', hook)):
        assert code.count(marker + '\n') == 1
        code = code.replace(marker + '\n', text + '\n')
    return code


def compile_and_run(code):
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Set CXX to a C++20 compiler (a Visual Studio developer prompt provides cl.exe on Windows).'
    defines = {'BUFF_SPELL': f'{BUFF}u', 'BLESSING_SPELL': f'{BLESSING}u', 'EXPECTED_CHANCE': CHANCE,
               'EXPECTED_HEAL_PERCENT': HEAL_PERCENT}
    with tempfile.TemporaryDirectory(prefix='coa-titan-scroll-eonar-', ignore_cleanup_errors=True) as directory:
        out = Path(directory)
        cpp, exe = out / 'eonar.cpp', out / ('eonar.exe' if os.name == 'nt' else 'eonar')
        cpp.write_text(code, encoding='utf-8')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', '/UNDEBUG',
                     *[f'/D{key}={value}' for key, value in defines.items()], str(cpp), '/Fe' + str(exe)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-UNDEBUG',
                     *[f'-D{key}={value}' for key, value in defines.items()], str(cpp), '-o', str(exe)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--dbc-dir', type=Path, default=Path(os.environ.get('COA_DBC_DIR') or SERVER_DBC_DIR))
    parser.add_argument('--source-ref', help='Read the hook and native headers from a local Git ref.')
    args = parser.parse_args()

    def source(name):
        if args.source_ref:
            return git_source(['git', 'show', f'{args.source_ref}:{name}'], cwd=ROOT).decode('utf-8')
        return (ROOT / name).read_text(encoding='utf-8')

    record = client_record(args.dbc_dir)
    compile_and_run(harness(source))
    print('PASS: no buff, summon, critter, totem and capital kills neither roll nor cast; a failed roll casts '
          f'nothing; a {CHANCE}% roll that succeeds casts {BLESSING} at the corpse with {HEAL_PERCENT}% of the '
          f'shown maximum health per tick, falling back to the real maximum; {record}')


if __name__ == '__main__':
    main()
