from pathlib import Path
import runpy
import struct


tool = runpy.run_path(str(Path(__file__).with_name("night_hunters_howl_icon.py")))
SPELL_NAME = tool["SPELL_NAME"].encode("utf-8")
SOURCE_SPELL_IDS = tool["SOURCE_SPELL_IDS"]
TARGET_SPELL_IDS = tool["TARGET_SPELL_IDS"]
SPELL_ICON_ID_FIELD = tool["SPELL_ICON_ID_FIELD"]
SPELL_NAME_FIELD = tool["SPELL_NAME_FIELD"]
SOURCE_ICON_ID = tool["SOURCE_ICON_ID"]
INCORRECT_ICON_ID = tool["INCORRECT_ICON_ID"]


def make_dbc(spell_ids=None, source_icon=SOURCE_ICON_ID, target_icon=INCORRECT_ICON_ID,
             target_name=SPELL_NAME):
    ids = (*SOURCE_SPELL_IDS, *TARGET_SPELL_IDS, 42) if spell_ids is None else spell_ids
    strings = b"\0" + SPELL_NAME + b"\0Unrelated\0"
    spell_name_offset = 1
    unrelated_name_offset = spell_name_offset + len(SPELL_NAME) + 1
    rows = []
    for spell_id in ids:
        row = [0] * 234
        row[0] = spell_id
        row[SPELL_NAME_FIELD] = unrelated_name_offset if spell_id == 42 else spell_name_offset
        if spell_id in SOURCE_SPELL_IDS:
            row[SPELL_ICON_ID_FIELD] = source_icon
        elif spell_id in TARGET_SPELL_IDS:
            row[SPELL_ICON_ID_FIELD] = target_icon
            if target_name != SPELL_NAME:
                strings += target_name + b"\0"
                row[SPELL_NAME_FIELD] = len(strings) - len(target_name) - 1
        rows.extend(row)
    header = struct.pack("<4s4I", b"WDBC", len(ids), 234, 936, len(strings))
    return header + struct.pack(f"<{len(rows)}I", *rows) + strings


def assert_rejected(raw):
    try:
        tool["transform"](raw)
    except ValueError:
        return
    raise AssertionError("Invalid Night Hunter's Howl DBC was accepted")


def main():
    raw = make_dbc()
    result = tool["transform"](raw)
    assert tool["transform"](result) == result
    assert len(result) == len(raw)
    changed = {index for index, (before, after) in enumerate(zip(raw, result)) if before != after}
    expected = set()
    for index in range(len(TARGET_SPELL_IDS)):
        field = 20 + (len(SOURCE_SPELL_IDS) + index) * 936 + SPELL_ICON_ID_FIELD * 4
        expected.update(field + byte for byte in range(4) if raw[field + byte] != result[field + byte])
    assert changed == expected
    for index, spell_id in enumerate(TARGET_SPELL_IDS):
        record = 20 + (len(SOURCE_SPELL_IDS) + index) * 936
        assert struct.unpack_from("<I", result, record + SPELL_ICON_ID_FIELD * 4)[0] == SOURCE_ICON_ID
        assert struct.unpack_from("<I", result, record)[0] == spell_id

    assert_rejected(make_dbc(spell_ids=(*SOURCE_SPELL_IDS, *TARGET_SPELL_IDS[:-1])))
    assert_rejected(make_dbc(spell_ids=(*SOURCE_SPELL_IDS, *TARGET_SPELL_IDS, TARGET_SPELL_IDS[0])))
    assert_rejected(make_dbc(spell_ids=(SOURCE_SPELL_IDS[0], *SOURCE_SPELL_IDS, *TARGET_SPELL_IDS)))
    assert_rejected(make_dbc(source_icon=SOURCE_ICON_ID + 1))
    assert_rejected(make_dbc(target_icon=SOURCE_ICON_ID + 1))
    assert_rejected(make_dbc(target_name=b"Unexpected spell"))
    print("PASS: rank icon edits, idempotence, unrelated-byte preservation and invalid-row rejection")


if __name__ == "__main__":
    main()
