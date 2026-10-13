#!/usr/bin/env python3
"""Appends ItemDisplayInfo row 990001 (a copy of 30015 with InventoryIcon_1 = INV_GrootCoin) to a client DBC."""
import struct
import sys

DISPLAY, TEMPLATE, ICON_FIELD = 990001, 30015, 5

data = open(sys.argv[1], "rb").read()
magic, rows, fields, size, strings = struct.unpack("<4s4I", data[:20])
assert magic == b"WDBC" and fields == 25 and size == 100, (magic, fields, size)
records = data[20:20 + rows * size]
block = data[20 + rows * size:]
ids = [struct.unpack_from("<I", records, i * size)[0] for i in range(rows)]
assert DISPLAY not in ids, "display 990001 already exists in the client DBC"
values = list(struct.unpack_from("<25I", records, ids.index(TEMPLATE) * size))
values[0], values[ICON_FIELD] = DISPLAY, len(block)
block += b"INV_GrootCoin\0"
out = struct.pack("<4s4I", b"WDBC", rows + 1, fields, size, len(block)) + records + struct.pack("<25I", *values) + block
open(sys.argv[2], "wb").write(out)
print(f"{sys.argv[2]}: {rows + 1} rows")
