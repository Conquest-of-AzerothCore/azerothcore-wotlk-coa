import argparse
from pathlib import Path
import struct


FIELDS = 28
FLAGS_FIELD = 1
MODEL_PATH_FIELD = 2
NO_ATTACHED_WEAPONS = 0x10
FORM_MODELS = {
    20612: (r"creature\nerubianbeetle\custom_nerubianbeetle.mdx", 0x8),
    22063: (r"creature\flyingnerubian2\custom_flyingnerubian2.mdx", 0x0),
    23813: (r"creature\maldraxxusmutant\maldraxxusmutant_noarmor.mdx", 0x1000),
}


def hide_attached_weapons(raw, offsets, strings, model_id):
    model_path, source_flags = FORM_MODELS[model_id]
    offset = offsets.get(model_id)
    if offset is None:
        raise ValueError(f"Missing Venomancer form model row {model_id}")

    path_offset, = struct.unpack_from("<I", raw, offset + MODEL_PATH_FIELD * 4)
    end = strings.find(b"\0", path_offset) if path_offset < len(strings) else -1
    if end < 0 or strings[path_offset:end].decode("utf-8").lower() != model_path:
        raise ValueError(f"Unexpected model path for Venomancer form model row {model_id}")

    flags_offset = offset + FLAGS_FIELD * 4
    flags, = struct.unpack_from("<I", raw, flags_offset)
    if flags not in {source_flags, source_flags | NO_ATTACHED_WEAPONS}:
        raise ValueError(f"Unexpected flags for Venomancer form model row {model_id}: {flags:#x}")
    struct.pack_into("<I", raw, flags_offset, flags | NO_ATTACHED_WEAPONS)


def transform(raw):
    if len(raw) < 20:
        raise ValueError(f"Expected a complete {FIELDS}-field CreatureModelData.dbc")

    magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
    strings_at = 20 + count * size
    if (magic != b"WDBC" or fields != FIELDS or size != FIELDS * 4 or
            len(raw) != strings_at + strings_size):
        raise ValueError(f"Expected a complete {FIELDS}-field CreatureModelData.dbc")

    offsets = {}
    for index in range(count):
        offset = 20 + index * size
        model_id, = struct.unpack_from("<I", raw, offset)
        if model_id in offsets:
            raise ValueError(f"Duplicate CreatureModelData row {model_id}")
        offsets[model_id] = offset

    result = bytearray(raw)
    strings = raw[strings_at:]
    for model_id in FORM_MODELS:
        hide_attached_weapons(result, offsets, strings, model_id)
    return bytes(result)


def main():
    parser = argparse.ArgumentParser(
        description="Prepare a CreatureModelData.dbc candidate whose Venomancer form models hide attached weapons.",
        epilog="This does not modify an installed client, package an MPQ or publish the client patch.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("Use a separate output path; never overwrite the input")
    candidate = transform(args.input.read_bytes())
    with args.output.open("xb") as output:
        output.write(candidate)
    rows = ", ".join(str(model_id) for model_id in FORM_MODELS)
    print(f"Prepared CreatureModelData rows {rows} with flag {NO_ATTACHED_WEAPONS:#x}: {args.output}")


if __name__ == "__main__":
    main()
