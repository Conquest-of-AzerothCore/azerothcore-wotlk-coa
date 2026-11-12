from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[3]
FIX = ROOT / 'data/sql/updates/pending_db_world/zzzz_rev_20261112_01_manastorm_horde_hub_return.sql'
TELEPORT_PAD = 20832
EXPECTED_PADS = {0: (6901535, 0), 1: (6901539, 1)}

HUB_INSERT = re.compile(r'INSERT\s+(IGNORE\s+)?INTO\s+`manastorm_hub_return`[^;]*?VALUES([^;]*);', re.I)
HUB_ROW = re.compile(r'\(\s*(\d+)\s*,\s*(\d+)\s*,\s*[\d.]+\s*\)')
HUB_DELETE = re.compile(r'DELETE\s+FROM\s+`manastorm_hub_return`\s+WHERE\s+`team_id`\s*=\s*(\d+)\s*;', re.I)
HUB_UPDATE = re.compile(r'UPDATE\s+`manastorm_hub_return`\s+SET\s+`gameobject_guid`\s*=\s*(\d+)'
                        r'\s+WHERE\s+`team_id`\s*=\s*(\d+)\s*;', re.I)
GAMEOBJECT_WRITE = re.compile(r'(INSERT\s+(?:IGNORE\s+)?INTO|DELETE\s+FROM|REPLACE\s+INTO)\s+`gameobject`\s([^;]*);',
                              re.I)
GUID_RANGE = re.compile(r'`?guid`?\s+BETWEEN\s+(\d+)\s+AND\s+(\d+)', re.I)
GAMEOBJECT_ROW = re.compile(r'\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,')


def world_update_files():
    files = [path for folder in ('data/sql/updates/db_world', 'data/sql/updates/pending_db_world')
             for path in (ROOT / folder).rglob('*.sql')]
    files += [path for folder in ROOT.glob('modules/*/data/sql/*')
              if folder.is_dir() and 'db-world' in folder.name for path in folder.rglob('*.sql')]
    return sorted(files, key=lambda path: path.name.encode('utf-8'))


def hub_statements(text):
    statements = [(match.start(), 'insert', bool(match[1]), HUB_ROW.findall(match[2]))
                  for match in HUB_INSERT.finditer(text)]
    statements += [(match.start(), 'delete', int(match[1])) for match in HUB_DELETE.finditer(text)]
    statements += [(match.start(), 'update', int(match[2]), int(match[1])) for match in HUB_UPDATE.finditer(text)]
    return [statement[1:] for statement in sorted(statements, key=lambda item: item[0])]


def apply_hub_statements(state, statements):
    for statement in statements:
        if statement[0] == 'insert':
            for team, guid in statement[2]:
                if not (statement[1] and int(team) in state):
                    state[int(team)] = int(guid)
        elif statement[0] == 'delete':
            state.pop(statement[1], None)
        elif statement[1] in state:
            state[statement[1]] = statement[2]
    return state


def apply_gameobject_writes(state, text, guids):
    for match in GAMEOBJECT_WRITE.finditer(text):
        if match[1].upper().startswith('DELETE'):
            predicate = match[2].split('WHERE', 1)[-1]
            if re.search(r'\bguid\b', predicate, re.I):
                ranges = [range(int(low), int(high) + 1) for low, high in GUID_RANGE.findall(predicate)]
                deleted = {int(value) for value in re.findall(r'\d+', GUID_RANGE.sub('', predicate))}
                deleted |= {guid for guid in guids if any(guid in span for span in ranges)}
            else:
                entries = {int(value) for value in re.findall(r'\d+', predicate)}
                deleted = {guid for guid, (entry, _) in state.items() if entry in entries}
            for guid in deleted & guids:
                state.pop(guid, None)
            continue
        for guid, entry, map_id in GAMEOBJECT_ROW.findall(match[2]):
            if int(guid) in guids:
                state[int(guid)] = (int(entry), int(map_id))
    return state


class FreshImportHubReturnTests(unittest.TestCase):
    def setUp(self):
        self.files = world_update_files()

    def test_fix_sorts_after_every_module_hub_return_write(self):
        order = [path.name for path in self.files]
        writers = [path.name for path in self.files
                   if 'modules' in path.parts and hub_statements(path.read_text(encoding='utf-8', errors='replace'))]
        self.assertIn('zz_manastorm_snapshot_2_world.sql', writers)
        for name in writers:
            self.assertLess(order.index(name), order.index(FIX.name))

    def test_fresh_import_points_each_team_at_its_teleport_pad(self):
        hubs, gameobjects = {}, {}
        guids = {guid for guid, _ in EXPECTED_PADS.values()}
        for path in self.files:
            text = path.read_text(encoding='utf-8', errors='replace')
            apply_hub_statements(hubs, hub_statements(text))
            apply_gameobject_writes(gameobjects, text, guids)
        self.assertEqual(hubs, {team: guid for team, (guid, _) in EXPECTED_PADS.items()})
        self.assertEqual(gameobjects[EXPECTED_PADS[1][0]], (TELEPORT_PAD, EXPECTED_PADS[1][1]))
        self.assertNotIn(6901536, hubs.values())

    def test_upgraded_server_moves_only_the_horde_row(self):
        state = {0: 6901535, 1: 6901536}
        apply_hub_statements(state, hub_statements(FIX.read_text(encoding='utf-8')))
        self.assertEqual(state, {0: 6901535, 1: 6901539})

    def test_simulator_deletes_pads_inside_guid_ranges(self):
        state = {6901535: (TELEPORT_PAD, 0), 6901539: (TELEPORT_PAD, 1)}
        apply_gameobject_writes(state, 'DELETE FROM `gameobject` WHERE `guid` BETWEEN 6901536 AND 6901540;',
                                set(state))
        self.assertEqual(state, {6901535: (TELEPORT_PAD, 0)})

    def test_simulator_deletes_pads_by_entry(self):
        state = {6901539: (TELEPORT_PAD, 1)}
        apply_gameobject_writes(state, f'DELETE FROM `gameobject` WHERE `id` = {TELEPORT_PAD};', set(state))
        self.assertEqual(state, {})

    def test_rerun_is_idempotent(self):
        statements = hub_statements(FIX.read_text(encoding='utf-8'))
        state = apply_hub_statements({0: 6901535, 1: 6901539}, statements)
        self.assertEqual(apply_hub_statements(dict(state), statements), state)


if __name__ == '__main__':
    unittest.main()
