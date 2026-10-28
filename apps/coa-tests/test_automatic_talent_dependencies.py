CLI_DESCRIPTION = """Check spec progression data; optionally exercise the matching client rank function.

--dbc-dir is the client DBC set the server loads; the module's talent loader is compiled to read it.
Use --client-addon-dir to check generated Lua and CharacterAdvancementStateCompat.lua
with lupa's Lua 5.1 runtime. No server build, database, or game client is needed.
"""

import argparse
from pathlib import Path
import re
import unittest

from coa_talent_catalog import catalog_text


CLIENT_ADDON = None
DBC_DIR = None
CATALOG = None
SPEC_ROOTS = {
    3997: 4031, 4037: 0, 4041: 0, 4505: 4006, 4525: 4025, 7750: 9905,
    12086: 4006, 12201: 4053, 12645: 4005, 12646: 4005, 12853: 4033,
    13572: 4003, 29857: 4039, 31165: 4015, 31171: 4021, 31175: 4025,
    31183: 4033, 31202: 4054, 66733: 4061,
}
OTHER_ROOTS = {12166: 4016, 17414: 4011, 29485: 4026, 30229: 4018, 31164: 4014, 31194: 4046}
INSPIRATION_CHOICES = [(13616, 29216), (11214, 29214), (7836, 10836), (11836, 11837)]


def read_catalog():
    global CATALOG
    if DBC_DIR is None:
        raise unittest.SkipTest("Pass --dbc-dir to read the talent catalog from the client DBCs.")
    if CATALOG is None:
        CATALOG = catalog_text(DBC_DIR)
    return CATALOG


def read_free_choice_groups():
    block = read_catalog().split("CoASelectableFreeEntries =", 1)[1].split("CoAAutomaticDependencies =", 1)[0]
    return {int(entry): int(group) for entry, group in re.findall(r"\{(\d+), (\d+)\}", block)}


def read_header():
    text = read_catalog()
    fields = "class_id spec_id spell_count ae_cost te_cost level spell1 spell2 spell3".split()
    entries = {}
    for line in text.splitlines():
        values = list(map(int, re.findall(r"\d+", line))) if line.startswith("    {") else []
        if len(values) == 10:
            entries[values[0]] = dict(zip(fields, values[1:]))
    block = text.split("CoAAutomaticDependencies =", 1)[1]
    dependencies = {int(entry): [int(value) for value in (first, second) if int(value)]
                    for entry, first, second in re.findall(r"\{(\d+), \{\{(\d+), (\d+)\}\}\}", block)}
    return entries, dependencies


class AutomaticDependencies(unittest.TestCase):
    def test_reported_nodes_keep_spec_roots(self):
        entries, dependencies = read_header()
        for entry_id, root in SPEC_ROOTS.items():
            with self.subTest(entry=entry_id):
                entry = entries[entry_id]
                self.assertGreater(entry["spec_id"], 0)
                self.assertEqual((entry["ae_cost"], entry["te_cost"]), (0, 0))
                self.assertEqual(dependencies.get(entry_id, []), [root] if root else [])

    def test_other_dependencies_are_preserved(self):
        _, dependencies = read_header()
        self.assertEqual({key: value for key, value in dependencies.items() if key not in SPEC_ROOTS},
                         {key: [root] for key, root in OTHER_ROOTS.items()})

    def test_no_automatic_spec_depends_on_paid_class_talent(self):
        entries, dependencies = read_header()
        self.assertTrue(entries)
        for entry_id, required_ids in dependencies.items():
            entry = entries[entry_id]
            for required_id in required_ids:
                with self.subTest(entry=entry_id, required=required_id):
                    required = entries[required_id]
                    self.assertEqual(required["class_id"], entry["class_id"])
                    self.assertFalse(entry["spec_id"] and required["spec_id"] == 0
                                     and (required["ae_cost"] or required["te_cost"]))


class FreeChoiceGroups(unittest.TestCase):
    def test_inspiration_level_choices_are_selectable_pairs(self):
        groups = read_free_choice_groups()
        for first, second in INSPIRATION_CHOICES:
            with self.subTest(entries=(first, second)):
                self.assertIn(first, groups)
                self.assertIn(second, groups)
                self.assertEqual(groups[first], groups[second])

    def test_every_free_choice_group_pairs_two_free_entries_of_one_tree_and_level(self):
        entries, dependencies = read_header()
        members = {}
        for entry_id, group in read_free_choice_groups().items():
            members.setdefault(group, []).append(entry_id)
        self.assertEqual(len(members), 24)
        for group, entry_ids in members.items():
            with self.subTest(group=group):
                self.assertEqual(len(entry_ids), 2)
                first, second = (entries[entry_id] for entry_id in entry_ids)
                for key in ("class_id", "spec_id", "level"):
                    self.assertEqual(first[key], second[key])
                for entry_id in entry_ids:
                    self.assertEqual((entries[entry_id]["ae_cost"], entries[entry_id]["te_cost"]), (0, 0))
                    self.assertNotIn(entry_id, dependencies)


class ClientAutomaticRanks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if CLIENT_ADDON is None:
            raise unittest.SkipTest("Pass --client-addon-dir to exercise client Lua.")
        from lupa.lua51 import LuaRuntime
        cls.vm = LuaRuntime()
        cls.vm.execute((CLIENT_ADDON / "CoATalentNodeData.lua").read_text(encoding="utf-8-sig"))
        cls.vm.execute("""
            function GetFallbackEntry(id) return ASCENSION_LOCAL_COA_TALENT_NODES_BY_ID[id] end
            function UnitLevel() return testLevel end
            function GetMappedClassAndSpec() return testClass, testSpec end
            function IsKnownSpell(id) return known[id] or false end
        """)
        source = (CLIENT_ADDON / "CharacterAdvancementStateCompat.lua").read_text(encoding="utf-8-sig")
        for name in ("GetMaxRank", "GetAutomaticFreeRank"):
            function = re.search(r"    local function " + name + r"\([^\n]*\).*?\n    end", source, re.S)
            if not function:
                raise AssertionError(f"Missing client function: {name}")
            cls.vm.execute(function[0].replace("local function", "function", 1))
        cls.nodes = cls.vm.globals().ASCENSION_LOCAL_COA_TALENT_NODES_BY_ID

    def prepare(self, entry_id, level=80):
        entry = self.nodes[entry_id]
        self.vm.globals().testClass = entry.Class
        self.vm.globals().testSpec = entry.Tab
        self.vm.globals().testLevel = level
        self.vm.globals().known = self.vm.table()
        return entry

    def rank(self, entry):
        return self.vm.globals().GetAutomaticFreeRank(entry)

    def test_client_and_server_dependencies_match(self):
        entries, dependencies = read_header()
        self.assertEqual(len(list(self.nodes.keys())), len(entries))
        for entry_id, entry in entries.items():
            if entry["ae_cost"] or entry["te_cost"]:
                continue
            self.assertEqual(list(self.nodes[entry_id].RequiredIDs.values()),
                             dependencies.get(entry_id, []), entry_id)

    def test_spec_roots_unlock_without_buying_shared_talents_or_resetting(self):
        for entry_id, root in SPEC_ROOTS.items():
            with self.subTest(entry=entry_id):
                entry = self.prepare(entry_id)
                if root:
                    self.assertEqual(self.rank(entry), 0)
                    for spell in self.nodes[root].Spells.values():
                        self.vm.globals().known[spell] = True
                self.assertEqual(self.rank(entry), 1)
                self.vm.globals().testSpec = "another specialization"
                self.assertEqual(self.rank(entry), 0)
                self.vm.globals().testSpec = entry.Tab
                self.vm.globals().testClass = "another class"
                self.assertEqual(self.rank(entry), 0)

    def test_level_gate_and_explicit_choices_remain(self):
        entry = self.prepare(4041, level=9)
        self.assertEqual(self.rank(entry), 0)
        self.vm.globals().testLevel = 10
        self.assertEqual(self.rank(entry), 1)
        self.assertIsNone(self.rank(self.prepare(9172)))
        self.assertIsNone(self.rank(self.prepare(7229)))


class ClientSpecializationTabs(unittest.TestCase):
    def setUp(self):
        if CLIENT_ADDON is None:
            self.skipTest("Pass --client-addon-dir to exercise client Lua.")
        from lupa.lua51 import LuaRuntime
        self.vm = LuaRuntime(unpack_returned_tuples=True)
        self.vm.execute("""
            level, activeSpec = 11, 60
            known, messages = {}, {}
            format, tinsert = string.format, table.insert
            function wipe(t) for k in pairs(t) do t[k] = nil end end
            function table.invert(t)
                local result = {}
                for k, v in pairs(t) do result[v] = k end
                return result
            end
            function IsDefaultClass() return false end
            function UnitClass() return "Primalist", "WILDWALKER" end
            function UnitGUID() return "Primalist-test" end
            function UnitLevel() return level end
            function IsSpellKnown(id) return known[id] end
            function SendChatMessage(message) table.insert(messages, message) end
            function CreateFrame()
                return {RegisterEvent = function() end, SetScript = function() end}
            end
            C_ClassInfo = {
                GetAllSpecs = function() return {58, 59, 60, 95} end,
                GetSpecInfoByID = function(id)
                    local tokens = {[58] = "LIFE", [59] = "PRIMAL", [60] = "MOUNTAINKING", [95] = "GEOMANCY"}
                    return {ID = id, Class = "WILDWALKER", Spec = tokens[id]}
                end,
            }
            C_CharacterAdvancement = {GetActiveChrSpec = function() return activeSpec end}
            CharacterAdvancementUtil = {}
        """)
        utility = CLIENT_ADDON.parents[1] / "FrameXML/Util/CharacterAdvancementUtil.lua"
        source = utility.read_text(encoding="utf-8-sig")
        self.vm.execute(source[source.index("function CharacterAdvancementUtil.GetClassDBCByFile("):])
        for name in ("CoATalentNodeData.lua", "CharacterAdvancementCompat.lua",
                     "CharacterAdvancementStateCompat.lua"):
            self.vm.execute((CLIENT_ADDON / name).read_text(encoding="utf-8-sig"))

    def test_mountain_king_tree_uses_client_token(self):
        self.vm.execute("""
            local tab = CharacterAdvancementUtil.GetSpecDBCByFile("MOUNTAINKING")
            local entries = C_CharacterAdvancement.GetEntriesByClass("Primalist", tab)
            assert(#entries == 40, "Mountain King must expose all 40 nodes")
            local ids = {}
            for _, entry in ipairs(entries) do
                assert(entry.Tab == "Mountain King")
                ids[entry.ID] = true
            end
            assert(ids[4064] and ids[9214], "Both progression passives must be present")
            for _, other in ipairs({"Life", "Primal", "Geomancy", "Class"}) do
                assert(#C_CharacterAdvancement.GetEntriesByClass("Primalist", other) > 0)
            end
            assert(#C_CharacterAdvancement.GetEntriesByClass("Ranger", tab) == 0)
        """)

    def test_mountain_king_passives_follow_level_and_spec(self):
        self.vm.execute("""
            local rank = C_CharacterAdvancement.GetPendingRankByEntryID
            level = 9
            assert(rank(4064) == 0)
            level = 11
            assert(rank(4064) == 1, "Mountain Giant must unlock at level 10")
            assert(rank(9214) == 0, "King of the Mountain requires level 20")
            level = 20
            assert(rank(9214) == 1)
            assert(C_CharacterAdvancement.SwitchActiveChrSpec(95))
            assert(rank(4064) == 0 and rank(9214) == 0)
        """)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--client-addon-dir", type=Path)
    parser.add_argument("--dbc-dir", type=Path)
    args, remaining = parser.parse_known_args()
    CLIENT_ADDON = args.client_addon_dir
    DBC_DIR = args.dbc_dir
    unittest.main(argv=[__file__, *remaining])
