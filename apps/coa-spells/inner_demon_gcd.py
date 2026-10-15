"""Give Inner Demon the shared global cooldown in a copied CoA Spell.dbc.

Inner Demon (804216) is the only Felsworn button whose client record carries no
global cooldown, so the client never greys it and the server never starts one.
Every other Felsworn ability checked uses recovery category 133 for 1000 ms.

This is source tooling for the matching client/server data delivery. It never
opens an MPQ or changes an installed client. Supply a separate output path when
packaging is requested; the input and all unrelated spell rows are preserved.
The server side of the same change lives in
src/server/coa/AscensionFelswornContracts.cpp.
"""

import argparse
from pathlib import Path
import struct


SPELL_ID = 804216
SPELL_FAMILY_FELSWORN = 20
RECOVERY_CATEGORY = 133
RECOVERY_TIME = 1000
FIELD_START_RECOVERY_CATEGORY = 205
FIELD_START_RECOVERY_TIME = 206
FIELD_SPELL_FAMILY = 208
EDITS = {FIELD_START_RECOVERY_CATEGORY: RECOVERY_CATEGORY, FIELD_START_RECOVERY_TIME: RECOVERY_TIME}


def transform(raw):
    magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
    if magic != b"WDBC" or fields != 234 or size != 936 or len(raw) != 20 + count * size + strings_size:
        raise ValueError("Expected a complete 234-field CoA Spell.dbc")
    strings_at = 20 + count * size
    strings = raw[strings_at:]
    records = bytearray(raw[20:strings_at])
    found = [index * size for index in range(count)
             if struct.unpack_from("<I", records, index * size)[0] == SPELL_ID]
    if len(found) != 1:
        raise ValueError("Inner Demon must have exactly one spell row")
    offset = found[0]
    row = list(struct.unpack_from("<234I", records, offset))
    if row[FIELD_SPELL_FAMILY] != SPELL_FAMILY_FELSWORN:
        raise ValueError("Unexpected spell family for Inner Demon")
    current = (row[FIELD_START_RECOVERY_CATEGORY], row[FIELD_START_RECOVERY_TIME])
    if current not in {(0, 0), (RECOVERY_CATEGORY, RECOVERY_TIME)}:
        raise ValueError(f"Unexpected recovery fields for Inner Demon: {current}")
    for field, value in EDITS.items():
        row[field] = value
    struct.pack_into("<234I", records, offset, *row)
    return struct.pack("<4s4I", magic, count, fields, size, strings_size) + bytes(records) + strings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("Use a separate output path; never overwrite the input")
    candidate = transform(args.input.read_bytes())
    with args.output.open("xb") as output:
        output.write(candidate)
    print(f"Prepared Inner Demon spell {SPELL_ID} with a {RECOVERY_TIME} ms global cooldown: {args.output}")


if __name__ == "__main__":
    main()
