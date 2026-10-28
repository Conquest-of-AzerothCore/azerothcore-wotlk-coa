import argparse
from pathlib import Path
import struct


SCARLET_CRUSADER = 301172
FIELD_DESCRIPTION_ENUS = 170
FIELD_TOOLTIP_ENUS = 187
TEXTS = {
    FIELD_DESCRIPTION_ENUS: (
        b"Using a |cffffffffOath|r transforms your next |cffffffffTemplar Strike|r into "
        b"|cffffffffScarlet Strike|r.",
        b"Your next |cffffffffArgent Blade|r is transformed into |cffffffffScarlet Hammer|r.",
    ),
    FIELD_TOOLTIP_ENUS: (
        b"Your Chastise is transformed into Scarlet Hammer.",
        b"Your Argent Blade is transformed into Scarlet Hammer.",
    ),
}


def transform(raw):
    magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
    if magic != b"WDBC" or fields != 234 or size != 936 or len(raw) != 20 + count * size + strings_size:
        raise ValueError("Expected a complete 234-field CoA Spell.dbc")
    strings_at = 20 + count * size
    records = bytearray(raw[20:strings_at])
    strings = bytearray(raw[strings_at:])
    rows = [index * size for index in range(count)
            if struct.unpack_from("<I", records, index * size)[0] == SCARLET_CRUSADER]
    if len(rows) != 1:
        raise ValueError(f"Spell {SCARLET_CRUSADER} must have exactly one row")
    for field, (old, new) in TEXTS.items():
        at = rows[0] + field * 4
        offset = struct.unpack_from("<I", records, at)[0]
        current = bytes(strings[offset:strings.index(b"\0", offset)])
        if current == new:
            continue
        if current != old:
            raise ValueError(f"Unexpected text in field {field} of Scarlet Crusader: {current!r}")
        struct.pack_into("<I", records, at, len(strings))
        strings += new + b"\0"
    return struct.pack("<4s4I", magic, count, fields, size, len(strings)) + bytes(records) + bytes(strings)


def main():
    parser = argparse.ArgumentParser(
        description="Point Scarlet Crusader's tooltip at Argent Blade in a separate Spell.dbc candidate.",
        epilog="This does not modify an installed client, package an MPQ or publish the client patch.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("Use a separate output path; never overwrite the input")
    candidate = transform(args.input.read_bytes())
    with args.output.open("xb") as output:
        output.write(candidate)
    print(f"Prepared Scarlet Crusader {SCARLET_CRUSADER} with the Argent Blade tooltip: {args.output}")


if __name__ == "__main__":
    main()
