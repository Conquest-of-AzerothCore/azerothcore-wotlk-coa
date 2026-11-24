import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import fixture_format


def full_report():
    return {
        'handlers': {name: 5 for name in fixture_format.REQUIRED_HANDLERS},
        'kinds': {kind: 1 for kind in fixture_format.EVENT_KINDS},
        'unknown': 0,
        'branches': {name: 3 for name in fixture_format.BRANCHES},
        'reachable_branches': list(fixture_format.BRANCHES),
    }


class FixtureFormatTest(unittest.TestCase):
    def test_fields_escape_round_trip(self):
        for text in ('a\tb', 'x\ny', 'c:\\d', 'plain', '', 'back\\t'):
            encoded = fixture_format.encode_field(text)
            self.assertNotIn('\t', encoded)
            self.assertNotIn('\n', encoded)
            self.assertEqual(fixture_format.decode_field(encoded), text)

    def test_canonical_event_sorts_fields(self):
        event = {'k': 'dmg', 'tidx': 2, 'dmg': 312, 'side': 'P'}
        self.assertEqual(fixture_format.canonical_event(event), 'k=dmg\tdmg=312\tside=P\ttidx=2')

    def test_canonical_event_flattens_nested_tables_and_formats_values(self):
        event = {'k': 'act', 'dmg': True, 'name': 'Lil\' K.T.\tx', 'tags': {'P': 'a', 'E': ''}, 'vis': 0.5}
        self.assertEqual(fixture_format.canonical_event(event),
                         "k=act\tdmg=true\tname=Lil' K.T.\\tx\ttags.E=\ttags.P=a\tvis=0.5")

    def test_lua_number_format(self):
        self.assertEqual(fixture_format.lua_number(312.0), '312')
        self.assertEqual(fixture_format.lua_number(0.35), '0.35')
        self.assertEqual(fixture_format.lua_number(1 / 3), '0.33333333333333')
        self.assertEqual(fixture_format.lua_number(1e20), '1e+20')
        self.assertEqual(fixture_format.lua_number(-0.0), '-0')
        self.assertEqual(fixture_format.lua_number(7), '7')

    def test_coverage_gate(self):
        self.assertEqual(fixture_format.coverage_failures(full_report()), [])
        report = full_report()
        report['handlers']['FX00'] = 4
        self.assertTrue(any('FX00' in failure for failure in fixture_format.coverage_failures(report)))
        report = full_report()
        for name in ('FX11', 'FX13', 'FX16', 'FX29', 'FX35'):
            report['handlers'].pop(name, None)
        self.assertEqual(fixture_format.coverage_failures(report), [])
        report = full_report()
        report['unknown'] = 1
        self.assertTrue(fixture_format.coverage_failures(report))
        report = full_report()
        del report['kinds']['trap']
        self.assertTrue(any('trap' in failure for failure in fixture_format.coverage_failures(report)))

    def test_branch_gate_counts_only_reachable_branches(self):
        report = full_report()
        report['branches']['reflect204'] = 2
        self.assertTrue(any('reflect204' in failure for failure in fixture_format.coverage_failures(report)))
        report['reachable_branches'].remove('reflect204')
        self.assertEqual(fixture_format.coverage_failures(report), [])
        report = full_report()
        report['branches'].pop('swap39')
        self.assertTrue(any('swap39' in failure for failure in fixture_format.coverage_failures(report)))

    def test_library_branches_are_required_even_when_unreachable(self):
        for name in fixture_format.LIBRARY_BRANCHES:
            report = full_report()
            report['reachable_branches'].remove(name)
            self.assertEqual(fixture_format.coverage_failures(report), [])
            report['branches'][name] = 2
            self.assertTrue(any(f'library branch {name}' in failure
                                for failure in fixture_format.coverage_failures(report)))


if __name__ == '__main__':
    unittest.main()
