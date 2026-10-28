from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
PENDING_DIR = ROOT / 'data/sql/updates/pending_db_world'

DELETE_RE = re.compile(
    r'DELETE\s+FROM\s+`smart_scripts`\s+WHERE\s+`entryorguid`\s*(=|IN)\s*'
    r'(\d+|\([^)]*\))\s+AND\s+`source_type`\s*=\s*(\d+)\s*;', re.S)
INSERT_RE = re.compile(
    r'INSERT(?:\s+IGNORE)?\s+INTO\s+`smart_scripts`\s*\(([^)]+)\)\s*VALUES\s*(.+?);', re.S)


def molten_core_files():
    return sorted(PENDING_DIR.glob('*molten_core*.sql'))


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


def is_difficulty_variant(entryorguid):
    return 100000 <= entryorguid < 400000


def replay_effective_state(files):
    state = {}
    for path in files:
        text = path.read_text(encoding='utf-8')
        for match in DELETE_RE.finditer(text):
            kind, body, source_type = match.group(1), match.group(2), int(match.group(3))
            entries = [int(body)] if kind == '=' else [int(v) for v in re.findall(r'\d+', body)]
            for entryorguid in entries:
                state.pop((entryorguid, source_type), None)
        for match in INSERT_RE.finditer(text):
            columns = [name.strip(' `') for name in match.group(1).split(',')]
            if 'entryorguid' not in columns or 'source_type' not in columns:
                continue
            entry_index = columns.index('entryorguid')
            source_index = columns.index('source_type')
            for row in value_tuples(match.group(2)):
                cells = [cell.strip() for cell in row.split(',')]
                if len(cells) <= max(entry_index, source_index):
                    continue
                try:
                    entryorguid = int(cells[entry_index])
                    source_type = int(cells[source_index])
                except ValueError:
                    continue
                state[(entryorguid, source_type)] = True
    return state


class MoltenCoreSmartScriptsBaseEntryTests(unittest.TestCase):
    def test_no_effective_smart_scripts_row_keyed_on_a_difficulty_variant_entry(self):
        state = replay_effective_state(molten_core_files())
        survivors = sorted(entryorguid for (entryorguid, source_type) in state
                            if source_type == 0 and is_difficulty_variant(entryorguid))
        self.assertEqual(survivors, [],
                          'after replaying every pending Molten Core SQL file in order, these '
                          'smart_scripts rows are still keyed on a difficulty_entry_1..3 variant '
                          'entry -- Creature::UpdateEntry keeps a real spawn\'s GetEntry() at the '
                          'base entry, so such a row never loads; author it on the base entry with '
                          'an event_flags difficulty bit instead: ' + repr(survivors))


if __name__ == '__main__':
    unittest.main()
