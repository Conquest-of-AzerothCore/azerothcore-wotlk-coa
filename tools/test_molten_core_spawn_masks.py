from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_DIR = ROOT / 'modules/mod-coa-raid-difficulty/data/sql/db-world/base'
PENDING_DIR = ROOT / 'data/sql/updates/pending_db_world'
MOLTEN_CORE_MAP_ID = 409

UPDATE_SPAWN_MASK_RE = re.compile(
    r'UPDATE\s+`(creature|gameobject)`\s+SET\s+`spawnMask`\s*=\s*(\d+)\s+WHERE\s+([^;]+);', re.S)
MAP_EQUALS_RE = re.compile(r'`map`\s*=\s*(\d+)')
MAP_IN_RE = re.compile(r'`map`\s*IN\s*\(([^)]+)\)')
INSERT_RE = re.compile(
    r'INSERT(?:\s+IGNORE)?\s+INTO\s+`(creature|gameobject)`\s*\(([^)]+)\)\s*VALUES\s*(.+?);', re.S)


def ordered_files():
    files = list(MODULE_DIR.glob('*.sql')) + list(PENDING_DIR.glob('*.sql'))
    return sorted(files, key=lambda path: path.name)


def statement_maps(where_clause):
    maps = {int(value) for value in MAP_EQUALS_RE.findall(where_clause)}
    for group in MAP_IN_RE.findall(where_clause):
        maps.update(int(value) for value in re.findall(r'\d+', group))
    return maps


def effective_spawn_mask(files, table):
    value, source = None, None
    for path in files:
        text = path.read_text(encoding='utf-8')
        for match in UPDATE_SPAWN_MASK_RE.finditer(text):
            found_table, new_value, where_clause = match.group(1), int(match.group(2)), match.group(3)
            if found_table == table and MOLTEN_CORE_MAP_ID in statement_maps(where_clause):
                value, source = new_value, path
    return value, source


def value_tuples(values_blob):
    tuples, current, depth, in_string = [], [], 0, False
    for char in values_blob:
        if char == "'":
            in_string = not in_string
        if char == '(' and not in_string:
            depth += 1
            if depth == 1:
                current = []
                continue
        if char == ')' and not in_string:
            depth -= 1
            if depth == 0:
                tuples.append(''.join(current))
                continue
        if depth >= 1:
            current.append(char)
    return tuples


def later_narrow_inserts(files, after):
    index = files.index(after)
    problems = []
    for path in files[index + 1:]:
        text = path.read_text(encoding='utf-8')
        for match in INSERT_RE.finditer(text):
            columns = [name.strip(' `') for name in match.group(2).split(',')]
            if 'map' not in columns or 'spawnMask' not in columns:
                continue
            map_index, mask_index = columns.index('map'), columns.index('spawnMask')
            for row in value_tuples(match.group(3)):
                cells = [cell.strip() for cell in row.split(',')]
                if len(cells) <= max(map_index, mask_index):
                    continue
                if cells[map_index] == str(MOLTEN_CORE_MAP_ID) and cells[mask_index] != '15':
                    problems.append((path.name, row))
    return problems


class MoltenCoreSpawnMaskTests(unittest.TestCase):
    def test_map_409_spawn_mask_ends_on_all_difficulties(self):
        files = ordered_files()
        creature_value, creature_source = effective_spawn_mask(files, 'creature')
        gameobject_value, gameobject_source = effective_spawn_mask(files, 'gameobject')
        self.assertEqual(creature_value, 15,
                          f'creature spawnMask for map {MOLTEN_CORE_MAP_ID} ends at '
                          f'{creature_value} from {creature_source}')
        self.assertEqual(gameobject_value, 15,
                          f'gameobject spawnMask for map {MOLTEN_CORE_MAP_ID} ends at '
                          f'{gameobject_value} from {gameobject_source}')

    def test_no_later_file_reintroduces_a_narrower_mask(self):
        files = ordered_files()
        _, creature_source = effective_spawn_mask(files, 'creature')
        _, gameobject_source = effective_spawn_mask(files, 'gameobject')
        restore_source = max(creature_source, gameobject_source, key=files.index)
        problems = later_narrow_inserts(files, restore_source)
        self.assertEqual(problems, [],
                          f'map {MOLTEN_CORE_MAP_ID} rows inserted after {restore_source.name} '
                          f'with a narrower spawnMask: {problems}')


if __name__ == '__main__':
    unittest.main()
