from pathlib import Path
import re
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
EFFECT, DIE_SIDES, BASE_POINTS, TARGET_A, TARGET_B, AURA, MISC = 71, 74, 80, 86, 89, 95, 110
FAMILY, DESCRIPTION, AURA_DESCRIPTION = 208, 170, 187
RANKS = {300382: 4, 570100: 9}
NEW_TEXT = 'Increases your Strength and Intellect by $s1%.'
NEW_AURA_TEXT = 'Increases Strength and Intellect by ${$w1}%.'


def main():
    raw = (dbc_dir() / 'Spell.dbc').read_bytes()
    count, _, size, strings = struct.unpack_from('<4I', raw, 4)
    assert size == 936
    table = raw[20:20 + count * size]
    pool = raw[20 + count * size:20 + count * size + strings]
    rows = {r[0]: r for r in struct.iter_unpack('<234I', table) if r[0] in RANKS}

    def text(row, field):
        return pool[row[field]:pool.index(b'\0', row[field])].decode()

    for spell, points in RANKS.items():
        row = rows[spell]
        assert row[FAMILY] == 23, spell
        assert row[EFFECT:EFFECT + 3] == (6, 0, 0), spell
        assert row[AURA:AURA + 3] == (137, 0, 0), spell
        assert row[MISC:MISC + 3] == (0, 0, 0), spell
        assert row[BASE_POINTS] == points and row[DIE_SIDES] == 1, spell
        assert row[TARGET_A] == 1 and row[TARGET_B] == 0, spell
        assert text(row, DESCRIPTION) == 'Increases your Strength by $s1%.', spell
    assert text(rows[300382], AURA_DESCRIPTION) == 'Increases Strength by ${$w1}%.'
    assert text(rows[570100], AURA_DESCRIPTION) == ''

    source = (ROOT / 'src/server/coa/AscensionXorothContracts.cpp').read_text()
    block = re.search(r'if \(\(id == 300382 \|\| id == 570100\).*?\n    \}\n', source, re.S)[0]
    for expected in ('SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE', 'intellect.BasePoints = strength.BasePoints;',
                     'intellect.DieSides = strength.DieSides;', 'intellect.MiscValue = STAT_INTELLECT;',
                     'intellect.TargetA = strength.TargetA;', 'intellect.Effect = SPELL_EFFECT_APPLY_AURA;'):
        assert expected in block, expected

    sql = next((ROOT / 'data/sql/updates/pending_db_world').glob('rev_*_knight_xorothian_strength_intellect.sql'))
    body = sql.read_text()
    assert "DELETE FROM `coa_client_spell_description` WHERE `ID` IN (300382, 570100);" in body
    inserted = re.findall(r"^\((\d+), '([^']*)', (NULL|'[^']*')\)[,;]$", body, re.M)
    assert [row[0] for row in inserted] == ['300382', '570100']
    assert all(row[1] == NEW_TEXT for row in inserted)
    assert inserted[0][2] == "'" + NEW_AURA_TEXT + "'" and inserted[1][2] == 'NULL'
    print('PASS: Xorothian Strength base rows, Intellect effect rewrite and client text rows')


if __name__ == '__main__':
    main()
