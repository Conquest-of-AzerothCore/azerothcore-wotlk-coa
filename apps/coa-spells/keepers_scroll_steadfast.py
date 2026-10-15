"""Give Keeper's Scroll: Steadfast its buff and tooltip in a copied CoA Spell.dbc.

Steadfast (91770) ships as an empty dummy effect with no duration and no
tooltip, so the buff it shows in the client has no description. Its sibling
Keeper's Scroll: Zoomer (92443) is the same buff done right: +25% mounted speed
for one hour, with a tooltip. The Steadfast row borrows Zoomer's effect fields
and points at Zoomer's tooltip string, so no string is added. Zoomer's aura
(32) is the one a mount's own speed uses, so the higher of the two wins and the
scroll adds nothing on a 60% or 100% mount; Steadfast takes Crusader Aura's
stacking mount speed aura (172) instead.

This is source tooling for the matching client/server data delivery. It never
opens an MPQ or changes an installed client. Supply a separate output path when
packaging is requested; the input and all unrelated spell rows are preserved.
The server side of the same change lives in
src/server/coa/AscensionKeepersScrollSteadfast.cpp.
"""

import argparse
from pathlib import Path
import struct


STEADFAST = 91770
ZOOMER = 92443
FIELD_DURATION_INDEX = 40
FIELD_STACK_AMOUNT = 49
FIELD_EFFECT_0 = 71
FIELD_EFFECT_DIE_SIDES_0 = 74
FIELD_EFFECT_BASE_POINTS_0 = 80
FIELD_EFFECT_AURA_0 = 95
FIELD_EFFECT_MISC_VALUE_0 = 110
FIELD_TOOLTIP_ENUS = 187
BORROWED_FIELDS = (FIELD_DURATION_INDEX, FIELD_STACK_AMOUNT, FIELD_EFFECT_0, FIELD_EFFECT_DIE_SIDES_0,
                   FIELD_EFFECT_BASE_POINTS_0, FIELD_EFFECT_AURA_0, FIELD_EFFECT_MISC_VALUE_0,
                   FIELD_TOOLTIP_ENUS)
ZOOMER_TOOLTIP = b"Mounted Movement Speed increased by $s1%. Only applies in this zone."
SPELL_EFFECT_DUMMY = 3
SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK = 172


def transform(raw):
    magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
    if magic != b"WDBC" or fields != 234 or size != 936 or len(raw) != 20 + count * size + strings_size:
        raise ValueError("Expected a complete 234-field CoA Spell.dbc")
    strings_at = 20 + count * size
    strings = raw[strings_at:]
    records = bytearray(raw[20:strings_at])
    offsets = {}
    for index in range(count):
        spell_id = struct.unpack_from("<I", records, index * size)[0]
        if spell_id in (STEADFAST, ZOOMER):
            if spell_id in offsets:
                raise ValueError(f"Spell {spell_id} must have exactly one row")
            offsets[spell_id] = index * size
    if set(offsets) != {STEADFAST, ZOOMER}:
        raise ValueError("Steadfast and Zoomer must both have a spell row")
    zoomer = struct.unpack_from("<234I", records, offsets[ZOOMER])
    tooltip = zoomer[FIELD_TOOLTIP_ENUS]
    if strings[tooltip:strings.index(b"\0", tooltip)] != ZOOMER_TOOLTIP:
        raise ValueError("Unexpected tooltip for Zoomer")
    row = list(struct.unpack_from("<234I", records, offsets[STEADFAST]))
    wanted = {field: zoomer[field] for field in BORROWED_FIELDS}
    wanted[FIELD_EFFECT_AURA_0] = SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK
    already_done = all(row[field] == value for field, value in wanted.items())
    if row[FIELD_EFFECT_0] != SPELL_EFFECT_DUMMY and not already_done:
        raise ValueError(f"Unexpected effect for Steadfast: {row[FIELD_EFFECT_0]}")
    for field, value in wanted.items():
        row[field] = value
    struct.pack_into("<234I", records, offsets[STEADFAST], *row)
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
    print(f"Prepared Keeper's Scroll: Steadfast {STEADFAST} with a stacking mount speed buff "
          f"and Zoomer's tooltip: {args.output}")


if __name__ == "__main__":
    main()
