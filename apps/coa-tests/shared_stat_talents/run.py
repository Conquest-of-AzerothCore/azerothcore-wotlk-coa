from pathlib import Path
import re
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
EFFECT, DIE_SIDES, BASE_POINTS, TARGET_A, TARGET_B, AURA, MISC = 71, 74, 80, 86, 89, 95, 110
FAMILY, DESCRIPTION, AURA_DESCRIPTION = 208, 170, 187
STRENGTH, AGILITY, STAMINA, INTELLECT, SPIRIT = range(5)
PERCENT_AURA = 137

XOROTH, PRIMALIST, WITCH_DOCTOR = 23, 37, 19
SPELLS = {
    300382: (XOROTH, [STRENGTH], 4, 'Increases your Strength by $s1%.', 'Increases Strength by ${$w1}%.'),
    570100: (XOROTH, [STRENGTH], 9, 'Increases your Strength by $s1%.', ''),
    680936: (PRIMALIST, [STAMINA, INTELLECT], 4, 'Increases your Intellect and Stamina by $s1%.', ''),
    681477: (PRIMALIST, [STAMINA, INTELLECT], 9, 'Increases your Intellect and Stamina by $s1%.', ''),
    503608: (WITCH_DOCTOR, [AGILITY, INTELLECT], 4, 'Increases your Agility and Intellect by $s1%.', ''),
    503609: (WITCH_DOCTOR, [AGILITY, INTELLECT], 9, 'Increases your Agility and Intellect by $s1%.', ''),
    503775: (WITCH_DOCTOR, [SPIRIT], 9, '', 'Spirit increased by ${$w1}%.'),
}
TALENT_TEXT = 'Summoning an |cFFFFFFFFIdol|r now increases your Spirit by $503775s1% for $503775d.'

NEW_TEXTS = {
    'rev_*_knight_xorothian_strength_intellect.sql': {
        300382: ('Increases your Strength and Intellect by $s1%.', 'Increases Strength and Intellect by ${$w1}%.'),
        570100: ('Increases your Strength and Intellect by $s1%.', None),
    },
    'rev_*_primalist_focus_strength.sql': {
        680936: ('Increases your Strength, Intellect and Stamina by $s1%.', None),
        681477: ('Increases your Strength, Intellect and Stamina by $s1%.', None),
    },
    'rev_*_witch_doctor_juju_spirit_warden_stats.sql': {
        503608: ('Increases your Agility, Intellect and Spirit by $s1%.', None),
        503609: ('Increases your Agility, Intellect and Spirit by $s1%.', None),
        503774: ('Summoning an |cFFFFFFFFIdol|r now increases your Spirit and Agility by $503775s1% for $503775d.',
                 None),
        503775: ('', 'Spirit and Agility increased by ${$w1}%.'),
    },
}

CODE = {
    'src/server/coa/AscensionXorothContracts.cpp': ('(id == 300382 || id == 570100)', 'STAT_INTELLECT'),
    'src/server/coa/AscensionPrimalistTalents.cpp': ('SPELL_FOCUS_RANK_1 = 680936', 'STAT_STRENGTH'),
    'src/server/coa/AscensionWitchDoctorCompletion.h': ('JujuInjection = 503608', 'SpiritWardenBuff = 503775'),
    'src/server/coa/AscensionWitchDoctorCompletion.cpp': ('addStatPercent(EFFECT_2, STAT_SPIRIT)',
                                                          'addStatPercent(EFFECT_1, STAT_AGILITY)'),
}


def main():
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count, _, size, strings = struct.unpack_from('<4I', raw, 4)
    assert size == 936
    table = raw[20:20 + count * size]
    pool = raw[20 + count * size:20 + count * size + strings]
    rows = {r[0]: r for r in struct.iter_unpack('<234I', table) if r[0] in SPELLS or r[0] == 503774}

    def text(row, field):
        return pool[row[field]:pool.index(b'\0', row[field])].decode()

    def signed(value):
        return value - (1 << 32) if value >= 1 << 31 else value

    for spell, (family, stats, points, description, aura_description) in SPELLS.items():
        row = rows[spell]
        assert row[FAMILY] == family, spell
        used = len(stats)
        for slot in range(3):
            if slot < used:
                assert row[EFFECT + slot] == 6, (spell, slot)
                assert row[AURA + slot] == PERCENT_AURA, (spell, slot)
                assert row[MISC + slot] == stats[slot], (spell, slot)
                assert row[BASE_POINTS + slot] == points and row[DIE_SIDES + slot] == 1, (spell, slot)
                assert row[TARGET_A + slot] == 1 and row[TARGET_B + slot] == 0, (spell, slot)
            else:
                assert row[EFFECT + slot] == 0, (spell, slot)
                assert row[AURA + slot] == 0 and row[MISC + slot] == 0, (spell, slot)
                assert row[TARGET_A + slot] == 0 and row[TARGET_B + slot] == 0, (spell, slot)
                assert signed(row[BASE_POINTS + slot]) in (0, -1), (spell, slot)
        assert text(row, DESCRIPTION) == description, spell
        assert text(row, AURA_DESCRIPTION) == aura_description, spell
    assert text(rows[503774], DESCRIPTION) == TALENT_TEXT
    assert rows[503774][FAMILY] == WITCH_DOCTOR

    for path, markers in CODE.items():
        source = (ROOT / path).read_text()
        for marker in markers:
            assert marker in source, (path, marker)
    xoroth = (ROOT / 'src/server/coa/AscensionXorothContracts.cpp').read_text()
    block = re.search(r'if \(\(id == 300382 \|\| id == 570100\).*?\n    \}\n', xoroth, re.S)[0]
    for expected in ('SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE', 'intellect.BasePoints = strength.BasePoints;',
                     'intellect.DieSides = strength.DieSides;', 'intellect.MiscValue = STAT_INTELLECT;',
                     'intellect.TargetA = strength.TargetA;', 'intellect.Effect = SPELL_EFFECT_APPLY_AURA;'):
        assert expected in block, expected
    focus = (ROOT / 'src/server/coa/AscensionPrimalistTalents.cpp').read_text()
    block = re.search(r'class primalist_focus_stats.*?\n};\n', focus, re.S)[0]
    for expected in ('info->Effects[EFFECT_2].Effect', 'stamina.MiscValue != STAT_STAMINA',
                     'intellect.MiscValue != STAT_INTELLECT', 'strength.Effect = SPELL_EFFECT_APPLY_AURA;',
                     'strength.BasePoints = stamina.BasePoints;', 'strength.DieSides = stamina.DieSides;',
                     'strength.MiscValue = STAT_STRENGTH;', 'strength.TargetA = stamina.TargetA;'):
        assert expected in block, expected
    doctor = (ROOT / 'src/server/coa/AscensionWitchDoctorCompletion.cpp').read_text()
    block = re.search(r'auto addStatPercent.*?addStatPercent\(EFFECT_1, STAT_AGILITY\);\n', doctor, re.S)[0]
    for expected in ('added.BasePoints = source.BasePoints;', 'added.DieSides = source.DieSides;',
                     'added.TargetA = source.TargetA;', 'added.MiscValue = stat;',
                     'info->Effects[EFFECT_2].Effect', 'info->Effects[EFFECT_1].Effect',
                     'MiscValue == STAT_AGILITY', 'MiscValue == STAT_INTELLECT', 'MiscValue == STAT_SPIRIT',
                     'id == JujuInjection || id == JujuInjectionTwo', 'id == SpiritWardenBuff'):
        assert expected in block, expected

    folder = ROOT / 'data/sql/updates/pending_db_world'
    for pattern, expected_rows in NEW_TEXTS.items():
        files = list(folder.glob(pattern))
        assert len(files) == 1, pattern
        body = files[0].read_text()
        ids = ', '.join(str(spell) for spell in expected_rows)
        assert f'DELETE FROM `coa_client_spell_description` WHERE `ID` IN ({ids});' in body, pattern
        inserted = re.findall(r"^\((\d+), '((?:[^'\\]|\\.)*)', (NULL|'(?:[^'\\]|\\.)*')\)[,;]$", body, re.M)
        assert [int(row[0]) for row in inserted] == list(expected_rows), pattern
        for (spell, (new_text, new_aura)), row in zip(expected_rows.items(), inserted):
            assert row[1] == new_text, spell
            assert row[2] == ('NULL' if new_aura is None else "'" + new_aura + "'"), spell
    print('PASS: shared stat talents: base rows, effect rewrites and client text rows')


if __name__ == '__main__':
    main()
