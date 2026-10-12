#!/usr/bin/env python3
"""Builds INV_GrootCoin.blp (64x64 BLP2, 256-colour palette, opaque, full mip chain) from the source art.

Deterministic: the same source and Pillow version give the same bytes.
Usage: python3 make_blp.py [source.png] [output.blp]
"""
import struct
import sys
from pathlib import Path

from PIL import Image

SIZE = 64


def mip_chain(image):
    levels = [image]
    while levels[-1].size[0] > 1:
        w, h = levels[-1].size
        levels.append(image.resize((max(1, w // 2), max(1, h // 2)), Image.LANCZOS))
    return levels


def encode(source):
    rgb = Image.open(source).convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)
    paletted = rgb.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    palette = paletted.getpalette()[: 256 * 3]
    palette += [0] * (256 * 3 - len(palette))
    levels = [paletted] + [
        level.convert("RGB").quantize(palette=paletted, dither=Image.Dither.NONE)
        for level in mip_chain(rgb)[1:]
    ]

    header_size = 4 + 4 + 4 + 4 + 4 + 16 * 4 + 16 * 4
    data = b""
    offsets, sizes = [], []
    cursor = header_size + 256 * 4
    for level in levels:
        pixels = level.tobytes()
        offsets.append(cursor)
        sizes.append(len(pixels))
        data += pixels
        cursor += len(pixels)
    offsets += [0] * (16 - len(offsets))
    sizes += [0] * (16 - len(sizes))

    out = b"BLP2" + struct.pack("<I", 1) + struct.pack("<BBBB", 1, 0, 0, 1)
    out += struct.pack("<II", SIZE, SIZE)
    out += struct.pack("<16I", *offsets) + struct.pack("<16I", *sizes)
    for i in range(256):
        r, g, b = palette[i * 3: i * 3 + 3]
        out += bytes((b, g, r, 255))
    return out + data


def main():
    here = Path(__file__).resolve().parent
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else here / "groot_coin_rim_1024.png"
    output = Path(sys.argv[2]) if len(sys.argv) > 2 else here / "INV_GrootCoin.blp"
    output.write_bytes(encode(source))
    preview = Image.open(output)
    preview.load()
    preview.convert("RGB").save(output.with_suffix(".preview.png"))
    print(f"{output}: {preview.size[0]}x{preview.size[1]}, {output.stat().st_size} bytes")


if __name__ == "__main__":
    main()
