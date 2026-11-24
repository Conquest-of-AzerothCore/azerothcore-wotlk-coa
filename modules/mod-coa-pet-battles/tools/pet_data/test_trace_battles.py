import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import fixture_format
import trace_battles

SESSIONS = HERE.parents[1] / 'tests' / 'fixtures' / 'sessions.txt'
WORLD = HERE.parents[1] / 'tests' / 'fixtures' / 'battle_world.txt'
TAGS = {'SESSION', 'PLAYER', 'JOURNAL', 'ROLL', 'IN', 'OUT', 'WORLD', 'JOURNAL_AFTER', 'END'}


def sessions():
    current = None
    for line in SESSIONS.read_text(encoding='utf-8').splitlines():
        fields = line.split('\t')
        if fields[0] == 'SESSION':
            current = {'name': fields[2], 'lines': []}
        current['lines'].append(fields)
        if fields[0] == 'END':
            yield current
            current = None


class SessionFixtureTest(unittest.TestCase):
    def test_every_line_has_a_known_tag_and_sessions_close(self):
        open_session = False
        for line in SESSIONS.read_text(encoding='utf-8').splitlines():
            tag = line.split('\t', 1)[0]
            self.assertIn(tag, TAGS, line[:80])
            if tag == 'SESSION':
                self.assertFalse(open_session)
                open_session = True
            elif tag == 'END':
                self.assertTrue(open_session)
                open_session = False
        self.assertFalse(open_session)

    def test_coverage_gate_passes(self):
        self.assertEqual(trace_battles.coverage_failures(SESSIONS.read_text(encoding='utf-8')), [])

    def test_messages_fit_the_wire_and_name_a_player(self):
        for session in sessions():
            for fields in session['lines']:
                if fields[0] in ('IN', 'OUT'):
                    player, text = fixture_format.decode_field(fields[2]).split(' ', 1)
                    self.assertRegex(player, r'^p\d+$')
                    if fields[0] == 'OUT':
                        self.assertLessEqual(len(text), 240, text[:60])

    def test_times_never_go_backwards(self):
        for session in sessions():
            times = [int(fields[1]) for fields in session['lines'] if fields[0] in ('IN', 'OUT', 'WORLD')]
            self.assertEqual(times, sorted(times), session['name'])

    def test_stand_ins_are_gone_when_a_session_ends(self):
        for session in sessions():
            alive = 0
            for fields in session['lines']:
                if fields[0] == 'WORLD':
                    alive += 1 if fields[2].startswith('spawn ') else -1
            self.assertEqual(alive, 0, session['name'])

    def test_world_rows_cover_every_session_species(self):
        world = trace_battles.read_world(WORLD)
        self.assertTrue(world['displays'])
        for session in sessions():
            for fields in session['lines']:
                if fields[0] == 'WORLD':
                    self.assertIn(int(fields[2].split(' ')[1]), world['displays'], session['name'])


if __name__ == '__main__':
    unittest.main()
