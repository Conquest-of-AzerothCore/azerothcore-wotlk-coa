from pathlib import Path
import runpy
import struct


tool = runpy.run_path(str(Path(__file__).with_name("venomancer_form_weapons.py")))
FIELDS = tool["FIELDS"]
FORM_MODELS = tool["FORM_MODELS"]
NO_ATTACHED_WEAPONS = tool["NO_ATTACHED_WEAPONS"]
FLAGS_FIELD = tool["FLAGS_FIELD"]
MODEL_PATH_FIELD = tool["MODEL_PATH_FIELD"]
SPIDER_MODEL_ID = 12035
SPIDER_MODEL_PATH = r"creature\spider\spider.mdx"


def make_dbc(model_ids=(SPIDER_MODEL_ID, *FORM_MODELS), flags=None, paths=None):
    flags = flags or {}
    paths = paths or {}
    strings = b"\0"
    path_offsets = {}
    rows = []
    for model_id in model_ids:
        default_path, default_flags = FORM_MODELS.get(model_id, (SPIDER_MODEL_PATH, 0x1002))
        path = paths.get(model_id, default_path).encode("utf-8")
        if path not in path_offsets:
            path_offsets[path] = len(strings)
            strings += path + b"\0"
        row = [0] * FIELDS
        row[0] = model_id
        row[FLAGS_FIELD] = flags.get(model_id, default_flags)
        row[MODEL_PATH_FIELD] = path_offsets[path]
        rows.extend(row)
    header = struct.pack("<4s4I", b"WDBC", len(model_ids), FIELDS, FIELDS * 4, len(strings))
    return header + struct.pack(f"<{len(rows)}I", *rows) + strings


def flags_offset(index):
    return 20 + index * FIELDS * 4 + FLAGS_FIELD * 4


def assert_rejected(raw):
    try:
        tool["transform"](raw)
    except ValueError:
        return
    raise AssertionError("Invalid CreatureModelData.dbc was accepted")


def main():
    model_ids = (SPIDER_MODEL_ID, *FORM_MODELS)
    raw = make_dbc()
    result = tool["transform"](raw)
    assert tool["transform"](result) == result
    assert len(result) == len(raw)

    expected_changes = set()
    for index, model_id in enumerate(model_ids):
        offset = flags_offset(index)
        flags, = struct.unpack_from("<I", result, offset)
        if model_id in FORM_MODELS:
            assert flags == FORM_MODELS[model_id][1] | NO_ATTACHED_WEAPONS
            expected_changes.update(range(offset, offset + 4))
        else:
            assert flags == 0x1002
    changed = {index for index, (before, after) in enumerate(zip(raw, result)) if before != after}
    assert changed and changed <= expected_changes

    for model_id, (path, _) in FORM_MODELS.items():
        assert tool["transform"](make_dbc(paths={model_id: path.upper()})) != raw
        assert_rejected(make_dbc(model_ids=tuple(other for other in model_ids if other != model_id)))
        assert_rejected(make_dbc(model_ids=(*model_ids, model_id)))
        assert_rejected(make_dbc(flags={model_id: 0x2}))
        assert_rejected(make_dbc(paths={model_id: SPIDER_MODEL_PATH}))
    assert_rejected(raw[:-1])
    print("PASS: Venomancer form model flags, idempotence, unrelated-byte preservation and invalid-row rejection")


if __name__ == "__main__":
    main()
