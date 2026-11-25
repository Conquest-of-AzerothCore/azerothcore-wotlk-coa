import sys
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import trace_wild

WILD = HERE.parents[1] / 'tests' / 'fixtures' / 'wild.txt'
HEADER = {'ZONE', 'ZONESPECIES', 'TEMPLATE'}
TAGS = {'SITUATION', 'PLAYER', 'MOB', 'GROUND', 'GROUND_RECT', 'ROLL', 'ROLL_F', 'IN', 'OUT'}
INPUTS = {'tick', 'blips', 'move', 'combat', 'battle', 'alive', 'start', 'hello', 'select', 'vanish', 'wander',
          'shutdown'}
OUTPUTS = {'spawn', 'scale', 'settle', 'wander', 'adopt', 'release', 'despawn', 'menu', 'say', 'start', 'send'}


def situations():
    found = []
    for line in WILD.read_text(encoding='utf-8').splitlines():
        fields = line.split('\t')
        if fields[0] == 'SITUATION':
            found.append({'name': fields[2], 'lines': []})
        elif found:
            found[-1]['lines'].append(fields)
    return found


class WildFixtureTest(unittest.TestCase):
    def test_every_line_has_a_known_tag(self):
        started = False
        for line in WILD.read_text(encoding='utf-8').splitlines():
            tag = line.split('\t', 1)[0]
            started = started or tag == 'SITUATION'
            self.assertIn(tag, TAGS if started else HEADER, line[:80])

    def test_every_required_situation_is_recorded(self):
        names = [s['name'] for s in situations()]
        self.assertEqual(sorted(names), sorted(trace_wild.REQUIRED))

    def test_events_are_known_and_times_never_go_backwards(self):
        for situation in situations():
            times = []
            for fields in situation['lines']:
                if fields[0] in ('IN', 'OUT'):
                    times.append(int(fields[1]))
                    kind = fields[2].split(' ', 1)[0]
                    self.assertIn(kind, INPUTS if fields[0] == 'IN' else OUTPUTS, situation['name'])
            self.assertEqual(times, sorted(times), situation['name'])

    def test_situations_end_with_shutdown_and_nothing_left(self):
        for situation in situations():
            ins = [f[2] for f in situation['lines'] if f[0] == 'IN']
            self.assertEqual(ins[-1], 'shutdown', situation['name'])
            live = set()
            for fields in situation['lines']:
                if fields[0] == 'IN' and fields[2].startswith('vanish '):
                    live.discard(fields[2].split(' ')[1])
                if fields[0] != 'OUT':
                    continue
                kind, rest = fields[2].split(' ', 1)
                key = rest.split(' ', 1)[0]
                if kind in ('spawn', 'adopt'):
                    live.add(key)
                elif kind in ('despawn', 'release'):
                    live.discard(key)
            self.assertEqual(live, set(), situation['name'])

    def test_messages_fit_the_wire(self):
        for situation in situations():
            for fields in situation['lines']:
                if fields[0] == 'OUT' and fields[2].startswith('send '):
                    self.assertLessEqual(len(fields[2].split(' ', 2)[2]), 240, situation['name'])

    def test_every_output_kind_occurs(self):
        seen = {f[2].split(' ', 1)[0] for s in situations() for f in s['lines'] if f[0] == 'OUT'}
        self.assertEqual(seen, OUTPUTS)


if __name__ == '__main__':
    unittest.main()
