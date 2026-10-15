import gzip
import json
from pathlib import Path
import runpy
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'apps/coa-spells'))
tool = runpy.run_path(str(ROOT / 'apps/coa-spells/secondary_appearances.py'))
reader = runpy.run_path(str(ROOT / 'apps/coa-spells/runemaster_travel.py'))['read']


def main():
    for table, expected in tool['ROWS'].items():
        width = len(expected[0])
        ids = {row[0] for row in expected}
        captured = {}
        for path in (ROOT.parent / 'client-reference/coa-datamine/raw/tables' / table).glob('*.jsonl.gz'):
            with gzip.open(path, 'rt', encoding='utf-8') as source:
                for line in source:
                    row = json.loads(line)
                    if row['f0'] in ids:
                        captured[row['f0']] = [row[f'f{i}'] for i in range(width)]
        assert captured == {row[0]: row for row in expected}
        raw = (dbc_dir() / f'{table}.dbc').read_bytes()
        result = tool['transform'](raw, table)
        before, strings = reader(raw, width)
        after, new_strings = reader(result, width)
        assert after[:len(before)] == before and new_strings[:len(strings)] == strings
        assert {row[0] for row in after} == {row[0] for row in before} | ids
        assert tool['transform'](result, table) == result
        broken = bytearray(result)
        index = next(i for i, row in enumerate(after) if row[0] == expected[0][0])
        offset = 20 + index * width * 4 + 4
        struct.pack_into('<I', broken, offset, struct.unpack_from('<I', broken, offset)[0] ^ 1)
        try:
            tool['transform'](broken, table)
        except ValueError:
            pass
        else:
            raise AssertionError('Conflicting existing appearance was accepted')
    print('PASS: all captured rows, original records/string pool preserved, idempotence and conflict rejection')


if __name__ == '__main__':
    main()
