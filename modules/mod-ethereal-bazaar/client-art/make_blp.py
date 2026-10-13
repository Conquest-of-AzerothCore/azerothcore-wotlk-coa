#!/usr/bin/env python3
"""Builds INV_GrootCoin.blp: 64x64 BLP2, DXT5 (alpha depth 8, alpha type 7), full mip chain.

The layout matches the client's own icons (e.g. Interface\\icons\\_KeyGoldBlood.blp in patch-I.MPQ): a 148-byte
header, no palette, then DXT5 mips 64..1 (levels under 4x4 still take one 16-byte block). The earlier 256-colour
palettized BLP rendered as a red question mark in the Ascension client.

Deterministic: the same source and Pillow version give the same bytes.
Usage: python3 make_blp.py [source.png] [output.blp]
"""
import struct
import sys
from pathlib import Path

from PIL import Image

SIZE = 64
HEADER_SIZE = 148


def rgb565(colour):
    r, g, b = colour[:3]
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)


def from565(value):
    return ((value >> 11) & 31) * 255 // 31, ((value >> 5) & 63) * 255 // 63, (value & 31) * 255 // 31


def alpha_block(pixels):
    alphas = [p[3] for p in pixels]
    a0, a1 = max(alphas), min(alphas)
    bits = 0
    if a0 != a1:
        palette = [a0, a1] + [((7 - i) * a0 + i * a1) // 7 for i in range(1, 7)]
        for i, alpha in enumerate(alphas):
            bits |= min(range(8), key=lambda j: abs(palette[j] - alpha)) << (3 * i)
    return struct.pack("<BB", a0, a1) + bits.to_bytes(6, "little")


def colour_block(pixels):
    luminance = lambda p: p[0] * 3 + p[1] * 6 + p[2]
    c0, c1 = rgb565(max(pixels, key=luminance)), rgb565(min(pixels, key=luminance))
    if c0 < c1:
        c0, c1 = c1, c0
    if c0 == c1:
        return struct.pack("<HHI", c0, c1, 0)
    e0, e1 = from565(c0), from565(c1)
    palette = [e0, e1, tuple((2 * a + b) // 3 for a, b in zip(e0, e1)), tuple((a + 2 * b) // 3 for a, b in zip(e0, e1))]
    bits = 0
    for i, p in enumerate(pixels):
        bits |= min(range(4), key=lambda j: sum((palette[j][t] - p[t]) ** 2 for t in range(3))) << (2 * i)
    return struct.pack("<HHI", c0, c1, bits)


def dxt5(image):
    width, height = image.size
    px = image.load()
    out = b""
    for by in range(0, max(height, 4), 4):
        for bx in range(0, max(width, 4), 4):
            block = [px[min(bx + x, width - 1), min(by + y, height - 1)] for y in range(4) for x in range(4)]
            out += alpha_block(block) + colour_block(block)
    return out


def encode(source):
    rgba = Image.open(source).convert("RGBA").resize((SIZE, SIZE), Image.LANCZOS)
    levels, size = [], SIZE
    while size >= 1:
        levels.append(dxt5(rgba.resize((size, size), Image.LANCZOS)))
        size //= 2
    offsets, sizes, cursor = [], [], HEADER_SIZE
    for level in levels:
        offsets.append(cursor)
        sizes.append(len(level))
        cursor += len(level)
    offsets += [0] * (16 - len(offsets))
    sizes += [0] * (16 - len(sizes))
    header = b"BLP2" + struct.pack("<I", 1) + struct.pack("<BBBB", 2, 8, 7, 1) + struct.pack("<II", SIZE, SIZE)
    return header + struct.pack("<16I", *offsets) + struct.pack("<16I", *sizes) + b"".join(levels)


def main():
    here = Path(__file__).resolve().parent
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else here / "groot_coin_rim_1024.png"
    output = Path(sys.argv[2]) if len(sys.argv) > 2 else here / "INV_GrootCoin.blp"
    output.write_bytes(encode(source))
    preview = Image.open(output)
    preview.load()
    preview.save(output.with_suffix(".preview.png"))
    print(f"{output}: {preview.size[0]}x{preview.size[1]}, {output.stat().st_size} bytes")


if __name__ == "__main__":
    main()
