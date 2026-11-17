import struct
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import client_dbc  # noqa: E402


FORMATS = """
char constexpr Foofmt[] = "nsi";
char constexpr GtBarfmt[] = "df";
//char constexpr Unusedfmt[] = "n";
"""
STORES = """
DBCStorage <FooEntry> sFooStore(Foofmt);
static DBCStorage <GtBarEntry> sGtBarStore(GtBarfmt);
    LOAD_DBC(sFooStore,  "Foo.dbc",   "foo_dbc");
    LOAD_DBC(sGtBarStore, "gtBar.dbc", "gtbar_dbc");
    //LOAD_DBC(sUnusedStore, "Unused.dbc", "unused_dbc");
"""


def wdbc(records, fields, strings=b"\0", record_format=None):
    record_format = record_format or "<" + "I" * fields
    body = b"".join(struct.pack(record_format, *record) for record in records)
    size = struct.calcsize(record_format)
    return struct.pack("<4s4I", b"WDBC", len(records), fields, size, len(strings)) + body + strings


def source_tree(directory):
    (directory / "src/server/shared/DataStores").mkdir(parents=True)
    (directory / "src/server/game/DataStores").mkdir(parents=True)
    (directory / "src/server/shared/DataStores/DBCfmt.h").write_text(FORMATS, encoding="utf-8")
    (directory / "src/server/game/DataStores/DBCStores.cpp").write_text(STORES, encoding="utf-8")
    return directory


def valid_set(directory, name_offset=1, strings=b"\0Alpha\0"):
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "Foo.dbc").write_bytes(wdbc([(7, name_offset, 3)], 3, strings))
    (directory / "gtBar.dbc").write_bytes(wdbc([(0.5,), (1.5,)], 1, b"", "<f"))
    (directory / "SpellRank.dbc").write_bytes(wdbc([(1, 100, 100, 1), (2, 100, 101, 2)], 4))
    return directory


class FakeMpq:
    def __init__(self, archives):
        self.archives = archives

    def list(self, archive):
        return list(self.archives[Path(archive).name])

    def extract(self, archive, member, directory):
        target = Path(directory) / member.rsplit("\\", 1)[-1]
        target.write_bytes(self.archives[Path(archive).name][member])
        return target


class ClientDbcTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.path = Path(self.temporary.name)
        self.root = source_tree(self.path / "repo")

    def tearDown(self):
        self.temporary.cleanup()

    def test_core_stores_follow_active_loads(self):
        self.assertEqual(client_dbc.core_stores(self.root),
                         [("Foo.dbc", "nsi", "foo_dbc"), ("gtBar.dbc", "df", "gtbar_dbc"),
                          ("SpellRank.dbc", "niii", "spell_ranks")])

    def test_valid_set_has_no_problems(self):
        self.assertEqual(client_dbc.check(valid_set(self.path / "set"), self.root), ([], []))

    def test_check_reports_what_stops_the_core(self):
        directory = self.path / "set"
        directory.mkdir()
        (directory / "foo.dbc").write_bytes(wdbc([(7, 1)], 2, b"\0A\0"))
        problems, _ = client_dbc.check(directory, self.root)
        self.assertEqual(problems, [
            "Foo.dbc: stored as foo.dbc; case-sensitive systems cannot open it",
            "Foo.dbc: 2 fields, the core expects 3",
            "gtBar.dbc: missing",
            "SpellRank.dbc: missing"])

    def test_string_outside_block_is_a_note(self):
        directory = valid_set(self.path / "set", name_offset=0xFF00FE)
        problems, notes = client_dbc.check(directory, self.root)
        self.assertEqual(problems, [])
        self.assertEqual(notes, ["Foo.dbc: 1 string fields point outside the string block and load as empty"])

    def test_index_minus_one_is_a_note(self):
        directory = valid_set(self.path / "set")
        (directory / "Foo.dbc").write_bytes(wdbc([(7, 1, 3), (0xFFFFFFFF, 1, 4)], 3, b"\0Alpha\0"))
        problems, notes = client_dbc.check(directory, self.root)
        self.assertEqual(problems, [])
        self.assertEqual(notes, ["Foo.dbc: 1 rows have index -1 and are left out of the index table"])

    def test_diff_compares_values_not_offsets(self):
        old = valid_set(self.path / "old")
        new = valid_set(self.path / "new", name_offset=2, strings=b"\0\0Alpha\0")
        self.assertEqual(client_dbc.diff(old, new, self.root), [])
        (new / "Foo.dbc").write_bytes(wdbc([(7, 1, 4), (8, 1, 0)], 3, b"\0Alpha\0"))
        (new / "Extra.dbc").write_bytes(wdbc([(1,)], 1))
        report = client_dbc.diff(old, new, self.root)
        self.assertEqual(report[0], {"file": "Extra.dbc", "core": False, "status": "only in new"})
        self.assertEqual({key: report[1][key] for key in ("added", "removed", "changed")},
                         {"added": [8], "removed": [], "changed": [7]})

    def test_archive_rank_matches_client_load_order(self):
        names = ["patch-T.MPQ", "enUS/patch-enUS-3.MPQ", "patch-CZZ.MPQ", "common.MPQ", "patch-2.MPQ",
                 "enUS/locale-enUS.MPQ", "patch.MPQ", "enUS/lichking-locale-enUS.MPQ", "patch-C.MPQ",
                 "lichking.MPQ", "enUS/patch-enUS.MPQ", "patch-TA.MPQ", "common-2.MPQ"]
        self.assertEqual(sorted(names, key=client_dbc.archive_rank), [
            "common.MPQ", "common-2.MPQ", "lichking.MPQ", "enUS/locale-enUS.MPQ",
            "enUS/lichking-locale-enUS.MPQ", "patch.MPQ", "patch-2.MPQ", "enUS/patch-enUS.MPQ",
            "enUS/patch-enUS-3.MPQ", "patch-C.MPQ", "patch-CZZ.MPQ", "patch-T.MPQ", "patch-TA.MPQ"])

    def test_extract_takes_the_last_archive_honours_replacements_and_uses_core_names(self):
        client = self.path / "Data"
        (client / "enUS").mkdir(parents=True)
        for name in ("enUS/patch-enUS-3.MPQ", "patch-M.MPQ", "patch-T.MPQ", "patch-T.MPQ.ORIGINAL"):
            (client / name).write_bytes(b"")
        stock, custom, original = (wdbc([(i, 0, 0)], 3) for i in (1, 2, 3))
        mpq = FakeMpq({
            "patch-enUS-3.MPQ": {"DBFilesClient\\Foo.dbc": stock,
                                 "DBFilesClient\\gtBar.dbc": wdbc([(1.0,)], 1, b"", "<f")},
            "patch-M.MPQ": {"DBFilesClient\\Foo.dbc": custom, "DBFilesClient\\Custom.dbc": wdbc([(1,)], 1),
                            "Interface\\x.blp": b""},
            "patch-T.MPQ": {"DBFilesClient\\Foo.dbc": b"not used"},
            "patch-T.MPQ.ORIGINAL": {"DBFilesClient\\FOO.dbc": original}})
        output = self.path / "out"
        manifest = client_dbc.extract(client, output, mpq, {"patch-T.MPQ": client / "patch-T.MPQ.ORIGINAL"},
                                      log=lambda _: None, root=self.root)
        self.assertEqual({path.name for path in output.iterdir()},
                         {"Foo.dbc", "gtBar.dbc", "Custom.dbc", client_dbc.MANIFEST})
        self.assertEqual((output / "Foo.dbc").read_bytes(), original)
        self.assertEqual(manifest["files"]["Foo.dbc"]["archive"], "patch-T.MPQ")
        self.assertEqual(manifest["files"]["Foo.dbc"]["overridden"], ["enUS/patch-enUS-3.MPQ", "patch-M.MPQ"])
        self.assertTrue((output / client_dbc.MANIFEST).is_file())
        with self.assertRaises(ValueError):
            client_dbc.extract(client, output, mpq, log=lambda _: None, root=self.root)

    def test_spell_rank_is_checked_and_named_like_the_core_reads_it(self):
        directory = valid_set(self.path / "set")
        (directory / "SpellRank.dbc").unlink()
        (directory / "spellrank.dbc").write_bytes(wdbc([(1, 100, 100)], 3))
        problems, _ = client_dbc.check(directory, self.root)
        self.assertEqual(problems, ["SpellRank.dbc: stored as spellrank.dbc; case-sensitive systems cannot open it",
                                    "SpellRank.dbc: 3 fields, the core expects 4"])
        client = self.path / "Data"
        client.mkdir()
        (client / "patch.MPQ").write_bytes(b"")
        mpq = FakeMpq({"patch.MPQ": {"DBFilesClient\\spellrank.dbc": wdbc([(1, 100, 100, 1)], 4)}})
        client_dbc.extract(client, self.path / "out", mpq, log=lambda _: None, root=self.root)
        self.assertTrue((self.path / "out" / "SpellRank.dbc").is_file())

    def test_original_reads_untouched_archive_copies(self):
        client = self.path / "Data"
        client.mkdir()
        for name in ("patch-M.MPQ", "patch-T.MPQ", "patch-T.MPQ.ORIGINAL", "patch-M.MPQ.backup"):
            (client / name).write_bytes(b"")
        archives = dict(client_dbc.client_archives(client, {}, original=True))
        self.assertEqual(archives["patch-T.MPQ"].name, "patch-T.MPQ.ORIGINAL")
        self.assertEqual(archives["patch-M.MPQ"].name, "patch-M.MPQ")
        replaced = dict(client_dbc.client_archives(client, {"patch-T.MPQ": client / "patch-M.MPQ"}, original=True))
        self.assertEqual(replaced["patch-T.MPQ"].name, "patch-M.MPQ")


if __name__ == "__main__":
    unittest.main()
