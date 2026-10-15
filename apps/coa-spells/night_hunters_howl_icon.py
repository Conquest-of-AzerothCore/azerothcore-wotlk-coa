import argparse
from pathlib import Path
import struct


SPELL_NAME = "Night Hunter's Howl"
SOURCE_ICON_ID = 30453
INCORRECT_ICON_ID = 2852
SPELL_ICON_ID_FIELD = 133
SPELL_ICON_ID_OFFSET = SPELL_ICON_ID_FIELD * 4
SPELL_NAME_FIELD = 136
SOURCE_SPELL_IDS = (500124, 501680, 501681, 501682, 501683)
TARGET_SPELL_IDS = (501684, 501685, 501686)


def transform(raw):
    if len(raw) < 20:
        raise ValueError("Expected a complete 234-field CoA Spell.dbc")

    magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
    strings_at = 20 + count * size
    if (magic != b"WDBC" or fields != 234 or size != 936 or
            len(raw) != strings_at + strings_size):
        raise ValueError("Expected a complete 234-field CoA Spell.dbc")

    strings = raw[strings_at:]
    spell_rows = {}
    for index in range(count):
        offset = 20 + index * size
        spell_id, = struct.unpack_from("<I", raw, offset)
        if spell_id in spell_rows:
            raise ValueError(f"Duplicate spell row {spell_id}")
        spell_rows[spell_id] = offset

    for spell_id in (*SOURCE_SPELL_IDS, *TARGET_SPELL_IDS):
        offset = spell_rows.get(spell_id)
        if offset is None:
            raise ValueError(f"Missing Night Hunter's Howl spell row {spell_id}")
        name_offset, = struct.unpack_from("<I", raw, offset + SPELL_NAME_FIELD * 4)
        if name_offset >= len(strings):
            raise ValueError(f"Invalid spell name for Night Hunter's Howl row {spell_id}")
        end = strings.find(b"\0", name_offset)
        if end < 0 or strings[name_offset:end].decode("utf-8") != SPELL_NAME:
            raise ValueError(f"Unexpected spell name for Night Hunter's Howl row {spell_id}")

    for spell_id in SOURCE_SPELL_IDS:
        offset = spell_rows[spell_id] + SPELL_ICON_ID_OFFSET
        icon_id, = struct.unpack_from("<I", raw, offset)
        if icon_id != SOURCE_ICON_ID:
            raise ValueError(f"Unexpected source icon for Night Hunter's Howl row {spell_id}: {icon_id}")

    offsets = tuple(spell_rows[spell_id] + SPELL_ICON_ID_OFFSET for spell_id in TARGET_SPELL_IDS)
    for spell_id, offset in zip(TARGET_SPELL_IDS, offsets):
        icon_id, = struct.unpack_from("<I", raw, offset)
        if icon_id not in {INCORRECT_ICON_ID, SOURCE_ICON_ID}:
            raise ValueError(f"Unexpected icon for Night Hunter's Howl row {spell_id}: {icon_id}")

    result = bytearray(raw)
    for offset in offsets:
        struct.pack_into("<I", result, offset, SOURCE_ICON_ID)
    return bytes(result)


def main():
    parser = argparse.ArgumentParser(
        description="Prepare corrected Night Hunter's Howl icons in a separate Spell.dbc candidate.",
        epilog="This does not modify an installed client, package an MPQ or publish the client patch.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("Use a separate output path; never overwrite the input")
    candidate = transform(args.input.read_bytes())
    with args.output.open("xb") as output:
        output.write(candidate)
    ranks = ", ".join(str(spell_id) for spell_id in TARGET_SPELL_IDS)
    print(f"Prepared Night Hunter's Howl ranks {ranks} with SpellIconID {SOURCE_ICON_ID}: {args.output}")


if __name__ == "__main__":
    main()
