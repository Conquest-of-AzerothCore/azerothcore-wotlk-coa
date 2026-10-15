CLI_DESCRIPTION = """Compile the actual Player stat methods with the Classic+ curves and check them against 1.12.

Expected vanilla values are transcribed from vmangos (player_crit_per_agility and player_dodge_per_agility
migrations 20260703210621, 20260711022757 and 20260711025640; StatSystem.cpp base crit and dodge;
Unit.cpp GetSpellCritFromIntellect and GetRegenHPPerSpirit; Player.cpp RegenerateHealth). Whether a component
keeps the CoA client value is derived here by comparing the client gt*.dbc rows with the stock 3.3.5 rows in
data/sql/base/db_world.
"""
import argparse
import math
import os
from pathlib import Path
import re
import runpy
import shutil
import struct
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
VANILLA_CLASSES = (1, 2, 3, 4, 5, 7, 8, 9, 11)
VMANGOS_AGILITY_PER_CRIT = {
    (1, 1): 4.0, (1, 10): 5.20021, (1, 58): 19.1939, (1, 60): 20.0,
    (2, 1): 4.65116, (2, 10): 5.81395, (2, 20): 8.1367, (2, 49): 16.0514, (2, 60): 19.7628,
    (3, 1): 4.59982, (3, 10): 6.7981, (3, 60): 52.9101,
    (4, 1): 2.29991, (4, 10): 3.50017, (4, 60): 28.9855,
    (5, 1): 10.0, (5, 10): 11.0011, (5, 60): 20.0,
    (7, 1): 6.06061, (7, 10): 7.27273, (7, 13): 7.57576, (7, 21): 9.23551, (7, 60): 19.685,
    (8, 1): 11.1111, (8, 10): 12.2249, (8, 60): 19.4553,
    (9, 1): 6.66667, (9, 10): 7.66871, (9, 60): 20.0,
    (11, 1): 4.87805, (11, 10): 6.34115, (11, 60): 20.0,
}
VMANGOS_AGILITY_PER_DODGE = {
    (1, 1): 4.0, (1, 10): 5.20021, (1, 60): 20.0,
    (2, 1): 4.65116, (2, 10): 5.81395, (2, 60): 19.7628,
    (3, 1): 2.29991, (3, 10): 3.4002, (3, 60): 26.5252,
    (4, 1): 1.14995, (4, 10): 1.75009, (4, 60): 14.4928,
    (5, 1): 10.0, (5, 10): 11.0011, (5, 60): 20.0,
    (7, 1): 6.06061, (7, 10): 7.27273, (7, 60): 19.685,
    (8, 1): 11.1111, (8, 10): 12.2249, (8, 60): 19.4553,
    (9, 1): 6.66667, (9, 10): 7.66871, (9, 60): 20.0,
    (11, 1): 4.87805, (11, 10): 6.34115, (11, 60): 20.0,
}
TURTLE_BINARY_AGILITY_PER_CRIT_60 = {1: 20, 2: 20, 3: 53, 4: 29, 5: 20, 7: 20, 8: 20, 9: 20, 11: 20}
VMANGOS_CLASS_BASE_PCT = {1: 0.0, 2: 0.7, 3: 0.0, 4: 0.0, 5: 3.0, 7: 1.7, 8: 3.2, 9: 2.0, 11: 0.9}
VMANGOS_SPELL_CRIT = {2: (3.70, 14.77, 0.65), 5: (2.97, 10.03, 0.82), 7: (3.54, 11.51, 0.80),
                      8: (3.70, 14.77, 0.65), 9: (3.18, 11.30, 0.82), 11: (3.33, 12.41, 0.79)}
VMANGOS_HEALTH_REGEN = {1: (1.26, -22.6), 2: (0.25, 0.0), 3: (0.43, -5.5), 4: (0.84, -13.0), 5: (0.15, 1.4),
                        7: (0.28, -3.6), 8: (0.11, 1.0), 9: (0.12, 1.5), 11: (0.11, 1.0)}
FIELDS = ('crit', 'dodge_diminishing', 'dodge', 'spell_crit', 'health_regen', 'shaman_ap', 'healed')


def client_rows(directory, name):
    raw = (directory / (name + '.dbc')).read_bytes()
    count, fields, size = struct.unpack_from('<3I', raw, 4)
    assert fields == 1 and size == 4, name
    return list(struct.unpack_from('<' + str(count) + 'f', raw, 20))


def stock_rows(table):
    text = (ROOT / 'data/sql/base/db_world' / (table + '.sql')).read_text()
    text = text[text.index('INSERT INTO'):]
    return {int(index): float(value) for index, value in re.findall(r'\((\d+),([-0-9.eE]+)\)', text)}


def same(client, stock, indexes):
    return all(math.isclose(client[i], stock.get(i, math.nan), rel_tol=1e-5, abs_tol=1e-9) for i in indexes)


def vanilla_rate(table, player_class, level):
    level = min(level, 60)
    if (player_class, level) in table:
        return table[player_class, level]
    below = max(known for c, known in table if c == player_class and known < level)
    above = min(known for c, known in table if c == player_class and known > level)
    low, high = table[player_class, below], table[player_class, above]
    return low + (high - low) * (level - below) / (above - below)


def weight(level):
    return 1.0 if level <= 60 else max(0.0, (80 - level) / 20)


def blend(vanilla, current, level):
    return vanilla * weight(level) + current * (1 - weight(level))


def compile_and_run(code, parser):
    msvc = os.name == 'nt'
    compiler = (str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe') if msvc else
                shutil.which(os.environ.get('CXX', 'c++')))
    if not compiler:
        parser.error('A C++20 compiler is required; set CXX or VCToolsInstallDir')
    with tempfile.TemporaryDirectory(prefix='coa-classic-stats-') as directory:
        out = Path(directory)
        cpp, exe = out / 'stats.cpp', out / ('stats.exe' if msvc else 'stats')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/wd4244', '/utf-8', str(cpp), '/Fe' + str(exe)]
                 if msvc else ['-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        return subprocess.run([str(exe)], cwd=out, check=True, timeout=15, capture_output=True, text=True).stdout


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--dbc-dir', type=Path, help='CoA client DBC directory (default: the worldserver DataDir)')
    args = parser.parse_args()
    directory = args.dbc_dir or dbc_dir()
    method = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']

    melee_base = client_rows(directory, 'gtChanceToMeleeCritBase')
    melee = client_rows(directory, 'gtChanceToMeleeCrit')
    spell_base = client_rows(directory, 'gtChanceToSpellCritBase')
    spell = client_rows(directory, 'gtChanceToSpellCrit')
    oct_hp = client_rows(directory, 'gtOCTRegenHP')
    hp_per_spirit = client_rows(directory, 'gtRegenHPPerSpt')
    stock_melee_base = stock_rows('gtchancetomeleecritbase_dbc')
    stock_melee = stock_rows('gtchancetomeleecrit_dbc')
    stock_spell_base = stock_rows('gtchancetospellcritbase_dbc')
    stock_spell = stock_rows('gtchancetospellcrit_dbc')
    stock_oct_hp = stock_rows('gtoctregenhp_dbc')
    stock_hp_per_spirit = stock_rows('gtregenhpperspt_dbc')

    def levels(player_class):
        return [(player_class - 1) * 100 + level - 1 for level in range(1, 61)]

    warrior_level_10 = 9
    assert melee[warrior_level_10] != stock_melee[warrior_level_10]
    assert math.isclose(melee[warrior_level_10], 0.009811, rel_tol=1e-6)
    assert math.isclose(stock_melee[warrior_level_10], 0.002012, rel_tol=1e-6)
    keeps_melee_base = {c: not same(melee_base, stock_melee_base, [c - 1]) for c in VANILLA_CLASSES}
    keeps_spell_base = {c: not same(spell_base, stock_spell_base, [c - 1]) for c in VANILLA_CLASSES}
    keeps_spell_ratio = {c: not same(spell, stock_spell, levels(c)) for c in VANILLA_CLASSES}
    assert all(same(melee, stock_melee, [i for i in levels(c) if i != warrior_level_10]) for c in VANILLA_CLASSES)
    assert all(same(oct_hp, stock_oct_hp, levels(c)) and same(hp_per_spirit, stock_hp_per_spirit, levels(c))
               for c in VANILLA_CLASSES)
    assert {c for c, kept in keeps_melee_base.items() if kept} == {1, 11}
    assert {c for c, kept in keeps_spell_base.items() if kept} == {2, 3, 7, 8}
    assert {c for c, kept in keeps_spell_ratio.items() if kept} == {11}
    for player_class, rate in TURTLE_BINARY_AGILITY_PER_CRIT_60.items():
        assert math.isclose(VMANGOS_AGILITY_PER_CRIT[player_class, 60], rate, rel_tol=0.03)

    shared = (ROOT / 'src/server/shared/SharedDefines.h').read_text()
    enums = ''.join(method(shared, 'enum ' + name) + ';\n' for name in ('Classes', 'Stats', 'Powers'))
    source = re.search(r'^#define MAX_CLASSES .*', shared, re.M)[0] + '\n'
    source += method(shared, 'constexpr Classes GetLegacyClassForCustomClass(') + '\n'
    header = (ROOT / 'src/server/game/Entities/Player/ClassicPlusStats.h').read_text()
    source += re.sub(r'^#include.*\n', '', header, flags=re.M)
    player = (ROOT / 'src/server/game/Entities/Player/Player.cpp').read_text()
    native = ''.join(method(player, signature) + '\n' for signature in (
        'float Player::GetMeleeCritFromAgility()', 'void Player::GetDodgeFromAgility(',
        'float Player::GetSpellCritFromIntellect()', 'float Player::OCTRegenHPPerSpirit()',
        'void Player::RegenerateHealth()'))
    stats = (ROOT / 'src/server/game/Entities/Unit/StatSystem.cpp').read_text()
    branch = method(stats, 'else if (getClass() == CLASS_SON_OF_ARUGAL')
    native += ('float Player::ShamanBranchAttackPower()\n{\n    float level = float(GetLevel());\n'
               '    float val2 = 0.0f;\n' + branch[branch.index('{'):] + '\n    return val2;\n}\n')

    def store(name, entry, values):
        return (f'Store<{entry}, {len(values)}> {name}{{{{{{' +
                ', '.join('{' + repr(value) + 'f}' for value in values) + '}}};\n')

    dbc = (store('sGtChanceToMeleeCritBaseStore', 'GtBaseEntry', melee_base) +
           store('sGtChanceToMeleeCritStore', 'GtRatioEntry', melee) +
           store('sGtChanceToSpellCritBaseStore', 'GtBaseEntry', spell_base) +
           store('sGtChanceToSpellCritStore', 'GtRatioEntry', spell) +
           store('sGtOCTRegenHPStore', 'GtRatioEntry', oct_hp) +
           store('sGtRegenHPPerSptStore', 'GtRatioEntry', hp_per_spirit))

    cases = {}

    def case(name, player_class, level, strength=50.0, agility=80.0, intellect=100.0, spirit=90.0,
             create_agility=None, polymorphed=False, standing=True):
        cases[name] = dict(player_class=player_class, level=level, strength=strength, agility=agility,
                           intellect=intellect, spirit=spirit, polymorphed=polymorphed, standing=standing,
                           create_agility=agility if create_agility is None else create_agility)

    for player_class in list(VANILLA_CLASSES) + [6, 13, 16, 17, 18, 21, 26, 29, 30, 32]:
        for level in (1, 10, 60, 61, 70, 79, 80):
            case(f'c{player_class}_l{level}', player_class, level, create_agility=60.0)
    case('gap_paladin_l30', 2, 30)
    case('gap_shaman_l17', 7, 17)
    case('gap_warrior_l59', 1, 59)
    case('warlock_l30', 9, 30)
    case('warrior_l30', 1, 30)
    case('warrior_l9', 1, 9, agility=26.0)
    case('warrior_l10', 1, 10, agility=26.0)
    case('warrior_l11', 1, 11, agility=26.0)
    case('custom_warrior_template_l10', 18, 10, agility=26.0)
    for level in (30, 60, 70, 80):
        case(f'sit_l{level}', 1, level, spirit=100.0, standing=False)
        case(f'poly_l{level}', 8, level, polymorphed=True)
        case(f'custom_poly_l{level}', 24, level, polymorphed=True)
    case('low_spirit_rogue', 4, 20, spirit=10.0)
    lines = []
    for name, c in cases.items():
        lines.append(f'    Measure("{name}", MakePlayer({c["player_class"]}, {c["level"]}, {c["strength"]}f, '
                     f'{c["agility"]}f, {c["intellect"]}f, {c["spirit"]}f, {c["create_agility"]}f), '
                     f'{str(c["polymorphed"]).lower()}, {str(c["standing"]).lower()});')

    code = (HERE / 'harness.cpp').read_text()
    code = code.replace('// ENUMS', enums).replace('// SOURCE', source).replace('// NATIVE_DBC', dbc)
    code = code.replace('// NATIVE', native).replace('// DBC_CASES', '\n'.join(lines))
    results = {}
    for line in compile_and_run(code, parser).splitlines():
        name, classic, *values = line.split()
        results[name, classic == '1'] = dict(zip(FIELDS, map(float, values)))

    def check(label, actual, expected, tolerance=2e-5):
        assert math.isclose(actual, expected, rel_tol=tolerance, abs_tol=tolerance), (label, actual, expected)

    def vanilla_melee_crit(player_class, level, agility):
        base = melee_base[player_class - 1] * 100 if keeps_melee_base[player_class] else \
            VMANGOS_CLASS_BASE_PCT[player_class]
        return base + agility / vanilla_rate(VMANGOS_AGILITY_PER_CRIT, player_class, level)

    def vanilla_dodge(player_class, level, agility):
        return VMANGOS_CLASS_BASE_PCT[player_class] + agility / vanilla_rate(VMANGOS_AGILITY_PER_DODGE,
                                                                             player_class, level)

    def vanilla_spell_crit(player_class, level, intellect):
        index = (player_class - 1) * 100 + level - 1
        if player_class not in VMANGOS_SPELL_CRIT:
            return None
        base, rate0, rate1 = VMANGOS_SPELL_CRIT[player_class]
        base = spell_base[player_class - 1] * 100 if keeps_spell_base[player_class] else base
        per_point = spell[index] * 100 if keeps_spell_ratio[player_class] else 1 / (rate0 + rate1 * min(level, 60))
        return base, per_point

    def vanilla_health_regen(player_class, level, spirit, client):
        per_spirit, flat = VMANGOS_HEALTH_REGEN[player_class]
        return blend(max(0.0, per_spirit * spirit + flat), client, level)

    def truncated(label, healed, expected):
        assert healed in {math.floor(expected - 1e-4), math.floor(expected + 1e-4)}, (label, healed, expected)

    def client_health_regen(player_class, level, spirit):
        index = (player_class - 1) * 100 + level - 1
        return (min(spirit, 50) * oct_hp[index] + max(spirit - 50, 0) * hp_per_spirit[index]) * 2

    checked = 0
    for name, c in cases.items():
        off, on = results[name, False], results[name, True]
        player_class, level = c['player_class'], c['level']
        if player_class not in VANILLA_CLASSES or level >= 80:
            for field in FIELDS:
                check(f'{name} {field} unchanged', on[field], off[field], 1e-6)
            checked += 1
            continue
        if not re.fullmatch(r'c\d+_l\d+', name):
            continue
        index = (player_class - 1) * 100 + level - 1
        ratio = stock_melee[index] if index == warrior_level_10 else melee[index]
        client_crit = (melee_base[player_class - 1] + c['agility'] * ratio) * 100
        check(f'{name} crit off', off['crit'], client_crit)
        check(f'{name} crit', on['crit'], blend(vanilla_melee_crit(player_class, level, c['agility']),
                                                   off['crit'], level))
        check(f'{name} dodge', on['dodge'] + on['dodge_diminishing'],
              blend(vanilla_dodge(player_class, level, c['agility']),
                    off['dodge'] + off['dodge_diminishing'], level))
        spell_crit = vanilla_spell_crit(player_class, level, c['intellect'])
        client_spell = (spell_base[player_class - 1] + c['intellect'] * spell[index]) * 100
        check(f'{name} spell crit off', off['spell_crit'], client_spell)
        if spell_crit is None:
            check(f'{name} spell crit', on['spell_crit'], off['spell_crit'], 1e-6)
        else:
            check(f'{name} spell crit', on['spell_crit'],
                  blend(spell_crit[0] + c['intellect'] * spell_crit[1], off['spell_crit'], level))
        check(f'{name} regen off', off['health_regen'], client_health_regen(player_class, level, c['spirit']))
        check(f'{name} spirit regen formula', on['health_regen'], off['health_regen'], 1e-6)
        truncated(f'{name} healed off', off['healed'], off['health_regen'])
        truncated(f'{name} healed', on['healed'], vanilla_health_regen(player_class, level, c['spirit'],
                                                                      off['health_regen']))
        if player_class == 7:
            check(f'{name} shaman ap off', off['shaman_ap'], 2 * level + c['strength'] + c['agility'] - 20)
            check(f'{name} shaman ap', on['shaman_ap'],
                  blend(2 * level + 2 * c['strength'] - 20, off['shaman_ap'], level))
        else:
            check(f'{name} ap', on['shaman_ap'], off['shaman_ap'], 1e-6)
        checked += 1

    check('warrior 60 agility per crit', results['c1_l60', True]['crit'] - melee_base[0] * 100, 80 / 20.0)
    check('rogue 60 agility per crit', results['c4_l60', True]['crit'], 80 / 28.9855)
    check('hunter 60 agility per crit', results['c3_l60', True]['crit'], 80 / 52.9101)
    check('mage 60 crit', results['c8_l60', True]['crit'], 3.2 + 80 / 19.4553)
    check('paladin 30 interpolated', results['gap_paladin_l30', True]['crit'],
          0.7 + 80 / (8.1367 + (16.0514 - 8.1367) * 10 / 29))
    check('shaman 17 interpolated', results['gap_shaman_l17', True]['crit'],
          1.7 + 80 / (7.57576 + (9.23551 - 7.57576) * 4 / 8))
    check('warrior 59 interpolated', results['gap_warrior_l59', True]['crit'] - melee_base[0] * 100,
          80 / ((19.1939 + 20.0) / 2))
    check('rogue 60 dodge', results['c4_l60', True]['dodge'] + results['c4_l60', True]['dodge_diminishing'],
          80 / 14.4928)
    check('druid 60 dodge', results['c11_l60', True]['dodge'] + results['c11_l60', True]['dodge_diminishing'],
          0.9 + 80 / 20.0)
    check('mage 60 spell crit', results['c8_l60', True]['spell_crit'], spell_base[7] * 100 + 100 / 53.77)
    check('priest 60 spell crit', results['c5_l60', True]['spell_crit'], 2.97 + 100 / 59.23)
    check('warlock 30 spell crit', results['warlock_l30', True]['spell_crit'], 3.18 + 100 / (11.30 + 0.82 * 30))
    truncated('warrior 30 regen', results['warrior_l30', True]['healed'], 1.26 * 90 - 22.6)
    assert results['low_spirit_rogue', True]['healed'] == 0 < results['low_spirit_rogue', False]['healed']
    check('shaman 60 ap', results['c7_l60', True]['shaman_ap'], 2 * 60 + 2 * 50 - 20)
    check('shaman 70 ap', results['c7_l70', True]['shaman_ap'], ((140 + 100 - 20) + (140 + 50 + 80 - 20)) / 2)

    for suffix in ('l9', 'l10', 'l11'):
        for classic in (False, True):
            assert results['warrior_' + suffix, classic]['crit'] < 10, (suffix, classic)
            assert results['warrior_' + suffix, classic]['dodge'] < 10, (suffix, classic)
    check('warrior 10 crit stock', results['warrior_l10', False]['crit'],
          (melee_base[0] + 26 * stock_melee[warrior_level_10]) * 100)
    check('warrior 10 dodge stock', results['warrior_l10', False]['dodge'], results['warrior_l9', False]['dodge'])
    defect_crit = (melee_base[0] + 26 * melee[warrior_level_10]) * 100
    assert defect_crit > 25 and results['warrior_l10', False]['crit'] < 7

    for level in (30, 60, 70, 80):
        sit_off, sit_on = results[f'sit_l{level}', False], results[f'sit_l{level}', True]
        truncated(f'sit off {level}', sit_off['healed'], sit_off['health_regen'] * 1.33)
        truncated(f'sit {level}', sit_on['healed'], vanilla_health_regen(1, level, 100.0, sit_on['health_regen']) *
                  blend(1.5, 1.33, level))
        assert results[f'poly_l{level}', False]['healed'] == 100000 // 3
        assert results[f'poly_l{level}', True]['healed'] == int(100000 * blend(0.1, 1 / 3, level) + 1e-3), level
        assert results[f'custom_poly_l{level}', True]['healed'] == 100000 // 3
    assert results['sit_l60', True]['healed'] == int((1.26 * 100 - 22.6) * 1.5)
    print(f'PASS: {checked} class/level cases; vanilla crit, dodge, spell crit, HP regen, sitting, polymorph and '
          f'Shaman AP to 60, blend to the unchanged WotLK/client value at 80, custom classes unchanged, '
          f'Warrior level 10 row corrected for crit and dodge')


if __name__ == '__main__':
    main()
