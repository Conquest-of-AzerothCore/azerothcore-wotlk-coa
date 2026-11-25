import struct
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(HERE))

import companion_census
import sql_reader

WORLD_SQL = ROOT / 'data/sql/updates/pending_db_world'
NEW_ROWS = {84099: 16846, 84106: 905, 983876: 36871, 500589: 589, 9931400: 34930, 9931401: 36910, 355699: 6}


def classify(spell, creatures):
    return companion_census.classify(
        spell, creatures,
        creature_names={1: 'Mag\'har Grunt', 2: 'Tiny Shale Spider', 3: 'Flufftalon', 4: 'Young Wolf'},
        species_entries={4, 16846},
        species_by_name={'mag\'har grunt': 16846, 'young wolf': 4},
        kits_by_name={'tiny shale spider': 279},
        mapped={100: 4})


class ClassifyTest(unittest.TestCase):
    def test_a_mapped_spell_is_mapped(self):
        self.assertEqual(classify(100, [4]), ('mapped', 'species 4'))

    def test_a_creature_missing_from_creature_template(self):
        self.assertEqual(classify(200, [99]), ('missing-creature', ''))
        self.assertEqual(classify(201, []), ('missing-creature', 'no summon effect'))

    def test_a_creature_that_is_a_species(self):
        self.assertEqual(classify(300, [4]), ('species-match', 'species 4'))

    def test_an_exact_species_name(self):
        self.assertEqual(classify(301, [1]), ('species-match', 'species 16846'))

    def test_an_exact_kit_name(self):
        self.assertEqual(classify(400, [2]), ('kit-match', 'kit 279'))

    def test_nothing_matches(self):
        self.assertEqual(classify(500, [3]), ('needs-review', ''))


class SummonTest(unittest.TestCase):
    def test_summons_come_from_summon_effects(self):
        fields = 234
        rows = []
        for spell, effect, creature in ((10, 28, 700), (11, 6, 800), (12, 56, 900)):
            row = [0] * fields
            row[0], row[71], row[110] = spell, effect, creature
            rows.append(row)
        payload = b''.join(struct.pack(f'<{fields}I', *row) for row in rows)
        header = struct.pack('<4s4I', b'WDBC', len(rows), fields, fields * 4, 1)
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'Spell.dbc'
            path.write_bytes(header + payload + b'\0')
            self.assertEqual(companion_census.read_summons(path), {10: [700], 12: [900]})


class CommittedRowsTest(unittest.TestCase):
    def test_new_companion_rows_name_existing_species(self):
        paths = sorted(WORLD_SQL.glob('rev_2026112[34]_*_coa_pet_battles_*.sql'))
        tables = sql_reader.read(paths)
        species = {row[0] for row in tables['coa_pet_species']}
        companions = {row[0]: row[1] for row in tables['coa_pet_companion']}
        for spell, entry in NEW_ROWS.items():
            self.assertEqual(companions.get(spell), entry, spell)
        self.assertEqual(sorted(entry for entry in companions.values() if entry not in species), [])


if __name__ == '__main__':
    unittest.main()
