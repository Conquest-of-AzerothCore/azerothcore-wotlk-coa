import argparse
from collections import defaultdict
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser()
parser.add_argument('--dbc-dir', type=Path, required=True)
args = parser.parse_args()
file = ROOT / 'data/sql/updates/pending_db_world/rev_20261121_17_coa_hellfire_ilvl63_affixes.sql'
if not file.exists():
    file = Path(str(file) + '.draft')
mapping = [tuple(map(int, match)) for match in re.findall(r'\(3483, (\d+), (\d+), (\d+)\)', file.read_text())]
assert mapping
blob = (args.dbc_dir / 'ItemRandomProperties.dbc').read_bytes()
magic, count, fields, stride, _ = struct.unpack_from('<4s4I', blob)
assert magic == b'WDBC' and fields == 24 and stride == 96
strings = blob[20 + count * stride:]
properties = {}
for index in range(count):
    record = struct.unpack_from('<24I', blob, 20 + index * stride)
    offset = record[7]
    properties[record[0]] = strings[offset:strings.index(b'\0', offset)]
by_item = defaultdict(dict)
for item, original, scaled in mapping:
    assert properties[original] == properties[scaled], (item, original, scaled)
    assert 0 < scaled <= 32767
    by_item[item][original] = scaled
for transforms in by_item.values():
    for scaled in transforms.values():
        assert transforms[scaled] == scaled
assert by_item[24575][8600] == 8600
print(f'PASS: {len(mapping)} affix mappings retain client-known names, fit saved item IDs, '
      f'and remain unchanged on repeated normalization across {len(by_item)} items')
