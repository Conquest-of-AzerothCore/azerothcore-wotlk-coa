import argparse
from pathlib import Path
import re
import struct
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
PENDING = ROOT / 'data/sql/updates/pending_db_world'
ROW = re.compile(r'\{ (\d+), (\d+), (\d+), (\d+), (\d+), (\d+), (\d+) \}')
BOUND = re.compile(r"\((\d+), 'spell_ascension_local_mount'\)")
MODEL = re.compile(r'^\((\d+), 0, (\d+), 1, 1\)', re.M)
FIXED = ('rev_20261009_84_mechagon_peacekeeper_mount_wrapper.sql',
         'rev_20261009_85_sunwarmed_furline_mount_wrapper.sql',
         'rev_20261009_86_mount_wrappers_unbound.sql')
REPORTED = (1245284, 9931327, 365431)


def read(path):
    return path.read_text(encoding='utf-8')


def dbc(directory, name):
    b = (directory / name).read_bytes()
    magic, count, fields, size, _ = struct.unpack_from('<4s4I', b)
    assert magic == b'WDBC' and size == fields * 4
    return {r[0]: struct.unpack('<%di' % fields, struct.pack('<%dI' % fields, *r))
            for r in struct.iter_unpack('<%dI' % fields, b[20:20 + count * size])}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dbc-dir', type=Path)
    args = parser.parse_args()
    args.dbc_dir = args.dbc_dir or dbc_dir()
    spells = dbc(args.dbc_dir, 'Spell.dbc')
    displays = dbc(args.dbc_dir, 'CreatureDisplayInfo.dbc')

    header = read(ROOT / 'src/server/coa/AscensionCollectibleSpellData.h')
    rows = [tuple(map(int, row)) for row in ROW.findall(header)]
    assert f'std::array<MountWrapper, {len(rows)}>' in header
    assert [row[0] for row in rows] == sorted({row[0] for row in rows})
    table = {row[0]: row for row in rows}

    bound = {int(spell) for path in PENDING.glob('*.sql') for spell in BOUND.findall(read(path))}
    assert set(table) <= bound

    fixed = {int(spell) for name in FIXED for spell in BOUND.findall(read(PENDING / name))}
    assert set(REPORTED) <= fixed <= set(table)
    for wrapper_id in fixed:
        _, creature, ground60, ground100, flying150, flying280, flying310 = table[wrapper_id]
        wrapper = spells[wrapper_id]
        assert (wrapper[71], wrapper[95], wrapper[72], wrapper[96], wrapper[73]) == (6, 78, 6, 4, 77)
        assert wrapper[110] == creature and ground60 and ground100
        for spell, ground, flying in ((ground60, 59, 0), (ground100, 99, 0),
                                      (flying150, 59, 149), (flying280, 99, 279)):
            if not spell:
                continue
            child = spells[spell]
            assert (child[71], child[95], child[110]) == (6, 78, creature)
            assert child[96] == 32 and child[80 + 1] == ground
            assert (child[97] == 207 and child[80 + 2] == flying) or (not flying and child[97] != 207)
        if flying310:
            assert spells[flying310][110] == creature

    created = {int(creature): int(display)
               for creature, display in MODEL.findall(read(PENDING / 'rev_20261009_87_mount_creatures_missing.sql'))}
    assert created and all(display in displays for display in created.values())
    assert 399302 not in created and {table[spell][1] for spell in fixed} >= set(created)


if __name__ == '__main__':
    main()
