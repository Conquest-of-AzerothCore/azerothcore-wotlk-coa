#!/usr/bin/env python3
import hashlib
import importlib.util
from pathlib import Path
import re
import os
import shutil
import tempfile
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / "modules/mod-manastorm-endless"
EXPORTS = MODULE / "docs/manual-sql-postinstall"
spec = importlib.util.spec_from_file_location("prepare_postinstall", EXPORTS / "prepare_postinstall.py")
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


class IntegrationTests(unittest.TestCase):
    def test_original_exports_unchanged(self):
        expected = {
            "Gametele.sql": "2f57893b0373ecb49d3ea9793d0310c15133bf55b4935188960355672c21171f",
            "ManastormWorldDBExport-RUNTHIS.sql": "3b4fbe8f1c25cac82944286238aa3ced47b09997182398717e0bbf4921e2c215",
            "CharactersManastormEXPORT-RunThisInCharacterDB.sql": "2f9b3affca7485415ebea73ef7fe036700c3eab0a6ec2b73e5fa0ee36fbf229f",
        }
        for name, digest in expected.items():
            content = (EXPORTS / name).read_bytes().replace(b"\r\n", b"\n")
            self.assertEqual(hashlib.sha256(content).hexdigest(), digest)

    def test_teleports_preserve_every_authored_tuple(self):
        source = (EXPORTS / "Gametele.sql").read_text(encoding="utf-8-sig")
        result, count = prepare.teleport_sql(source)
        self.assertEqual(count, 163)
        values = re.findall(r" VALUES (.*);$", source, re.M)
        generated = re.findall(r" VALUES (.*) ON DUPLICATE KEY UPDATE", result, re.M)
        self.assertEqual(values, generated)
        self.assertNotIn("`acore_world`.", result)

    def test_teleport_import_stops_on_foreign_ids_before_any_upsert(self):
        source = (EXPORTS / "Gametele.sql").read_text(encoding="utf-8-sig")
        result, _ = prepare.teleport_sql(source)
        guard = result.index("INSERT INTO `manastorm_tele_guard`")
        self.assertLess(guard, result.index("INSERT INTO `game_tele`"))
        self.assertIn("CHECK (`foreign_teleport_found` = 0)", result)
        owners = result[result.index("INSERT INTO `manastorm_tele_owner`"):guard]
        self.assertIn("(2038, 'Manastorm_SFK_RETHILGORE_A')", owners)
        self.assertIn("(2038, 'UWES_SFK_RETHILGORE_A')", owners)
        self.assertIn("(2103, 'Manastorm_OpenWorld_Marisadu''Paige')", owners)

    def test_world_preserves_rows_without_destructive_ddl(self):
        source = (EXPORTS / "ManastormWorldDBExport-RUNTHIS.sql").read_text(encoding="utf-8-sig")
        result, count = prepare.world_sql(source)
        self.assertEqual(count, 135197)
        before = re.findall(r"^INSERT INTO `([^`]+)` VALUES (.*);$", source, re.M)
        statements = re.findall(r"^INSERT INTO `([^`]+)` \([^\n]+?\) VALUES\n(.*?) ON DUPLICATE KEY UPDATE",
                                result, re.M | re.S)
        after = [(table, values) for table, body in statements for values in body.split(",\n")]
        self.assertEqual(before, after)
        self.assertLess(max(len(body) for _, body in statements), 2 * prepare.BATCH_BYTES)
        self.assertFalse(re.search(r"^(DROP|TRUNCATE|DELETE|REPLACE)\b", result, re.M))
        self.assertNotIn("FOREIGN_KEY_CHECKS", result)
        self.assertEqual(result.count("ADD COLUMN `source_field_"), 3)
        self.assertIn("SET `flags` = `flags` | 17", result)

    def test_committed_snapshot_updates_match_generator(self):
        files, _, _ = prepare.snapshots()
        self.assertEqual([path.name for path in prepare.stale_snapshots(files)], [])
        updates = sorted(path.name for path in prepare.UPDATES.glob("*.sql"))
        self.assertEqual(updates[-2:], [path.name for path in files])

    def test_prepared_metadata_ddl_escapes_embedded_quotes(self):
        source = (EXPORTS / "ManastormWorldDBExport-RUNTHIS.sql").read_text(encoding="utf-8-sig")
        result, _ = prepare.world_sql(source)
        statements = [line for line in result.splitlines() if line.startswith("SET @ms_sql =")]
        self.assertEqual(len(statements), 3)
        for statement in statements:
            self.assertRegex(statement, r"^SET @ms_sql = IF\(@ms_column_exists = 0, '(?:[^']|'')*', 'DO 0'\);$")
            self.assertIn("COMMENT ''Raw ManastormMessages.dbc", statement)

    def test_duplicate_link_add_repairs_missing_affix_role(self):
        source = (MODULE / "src/ManastormCommands.cpp").read_text(encoding="utf-8")
        block = source[source.index("        uint32 const addFlags ="):]
        self.assertIn("ManastormSegmentSpawnFlags::AffixEligible;", block.split("WorldDatabase", 1)[0])
        self.assertIn("if (enabled && (flags & requiredFlags) == requiredFlags)", source)
        self.assertIn('"`flags` = (`flags` | VALUES(`flags`)), "', block)

    def test_relocated_donor_has_no_gameplay_registration(self):
        coa = ROOT / "src/server/coa"
        source = (coa / "AscensionManastorm.cpp").read_text(encoding="utf-8")
        registration = source[source.index("void AddAscensionManastormItemScripts()") :]
        self.assertEqual(re.findall(r"new\s+(\w+)\s*\(", registration),
                         ["item_ascension_manastorm_cache"])
        self.assertNotIn("QueueAscensionManastormPacket", (coa / "AscensionCompat.cpp").read_text(encoding="utf-8"))
        self.assertNotIn("AddAscensionManastormScripts();", (coa / "CoAScriptLoader.cpp").read_text(encoding="utf-8"))
        gadgets = (coa / "AscensionManastormGadgets.h").read_text(encoding="utf-8")
        self.assertIn("std::array<Gadget, 149>", gadgets)

    def test_percent_damage_dispatch_preserves_feature_modes(self):
        source = (ROOT / "src/server/game/Spells/SpellEffects.cpp").read_text(encoding="utf-8")
        functions = []
        for name in ("EffectAscensionHealthPctDamage", "EffectAscensionPctDamage"):
            begin = source.index("void Spell::" + name + "(SpellEffIndex effIndex)")
            brace = source.index("{", begin)
            depth = 1
            end = brace + 1
            while depth:
                depth += (source[end] == "{") - (source[end] == "}")
                end += 1
            functions.append(source[begin:end])
        fixture = r"""
#include <algorithm>
#include <cassert>
#include <cstdint>
#include <limits>
using uint32 = std::uint32_t;
using int32 = std::int32_t;
using int64 = std::int64_t;
using SpellEffIndex = unsigned;
constexpr int SPELL_EFFECT_HANDLE_LAUNCH_TARGET = 1;
constexpr int BASE_ATTACK = 0;
constexpr int SPELL_DIRECT_DAMAGE = 0;
struct SpellInfo { uint32 Id; struct Effect { int32 MiscValue; } Effects[1]; };
struct Unit {
    bool alive = true;
    bool IsAlive() const { return alive; }
    uint32 GetMaxHealth() const { return 1000; }
    uint32 CalculateDamage(int, bool, bool) const { return 200; }
    uint32 CountPctFromMaxHealth(int32 percent) const { return 1000 * percent / 100; }
    uint32 SpellDamageBonusTaken(Unit*, SpellInfo const*, uint32 amount, int) const { return amount * 3; }
};
uint32 CalculatePct(uint32 value, int32 percent) { return value * percent / 100; }
struct Spell {
    int effectHandleMode = SPELL_EFFECT_HANDLE_LAUNCH_TARGET;
    Unit* unitTarget;
    Unit* m_caster;
    Unit* m_originalCaster;
    SpellInfo const* m_spellInfo;
    int32 damage = 25;
    int32 m_damage = 0;
    void EffectAscensionHealthPctDamage(SpellEffIndex effIndex);
    void EffectAscensionPctDamage(SpellEffIndex effIndex);
};
"""
        fixture += "\n".join(functions)
        fixture += r"""
int main() {
    Unit target, caster;
    auto hit = [&](uint32 id, int32 mode) {
        SpellInfo info{id, {{mode}}};
        Spell spell{1, &target, &caster, &caster, &info};
        spell.EffectAscensionPctDamage(0);
        return spell.m_damage;
    };
    assert(hit(93358, 1) == 250);
    assert(hit(115171, 1) == 250);
    assert(hit(115190, 1) == 250);
    assert(hit(93008, 2) == 250);
    assert(hit(93050, 2) == 250);
    assert(hit(800000, 1) == 150);
    assert(hit(800000, 0) == 750);
    assert(hit(800000, 2) == 750);
    target.alive = false;
    assert(hit(93358, 1) == 0);
    target.alive = true;
    SpellInfo info{93358, {{1}}};
    Spell spell{0, &target, &caster, &caster, &info};
    spell.EffectAscensionPctDamage(0);
    assert(spell.m_damage == 0);
    spell.effectHandleMode = 1;
    spell.unitTarget = nullptr;
    spell.EffectAscensionPctDamage(0);
    assert(spell.m_damage == 0);
}
"""
        with tempfile.TemporaryDirectory(prefix="manastorm-percent-") as directory:
            temporary = Path(directory)
            (temporary / "fixture.cpp").write_text(fixture, encoding="utf-8")
            if os.name == "nt":
                installs = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Microsoft Visual Studio"
                vcvars = next(installs.glob("2022/*/VC/Auxiliary/Build/vcvars64.bat"), None)
                self.assertIsNotNone(vcvars, "MSVC C++20 compiler required")
                command = f'cmd.exe /d /c call "{vcvars}" >nul && cl /nologo /std:c++20 /EHsc fixture.cpp /Fe:fixture.exe /Fo:fixture.obj'
                executable = temporary / "fixture.exe"
            else:
                compiler = shutil.which("c++") or shutil.which("clang++") or shutil.which("g++")
                self.assertIsNotNone(compiler, "C++20 compiler required")
                command = [compiler, "-std=c++20", "fixture.cpp", "-o", "fixture"]
                executable = temporary / "fixture"
            result = subprocess.run(command, cwd=temporary, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            result = subprocess.run([str(executable)], cwd=temporary, text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_private_spawn_definitions_preserve_original_records(self):
        baseline = (ROOT / "data/sql/base/db_world/creature.sql").read_text(encoding="utf-8")
        sql = (MODULE / "data/sql/db-world/updates/zz_manastorm_private_creature_restoration.sql").read_text(encoding="utf-8")
        rows = re.findall(r"^\((\d+),([^\n]+)\)[,;]$", sql, re.M)
        self.assertEqual(len(rows), 14)
        self.assertEqual(len({guid for guid, _ in rows}), 14)
        self.assertNotRegex(sql, r"(?i)(?:INSERT INTO|UPDATE|DELETE FROM) `creature`")
        self.assertNotIn("manastorm_segment_spawn", sql)
        for guid, values in rows:
            original = re.search(r"^\(" + guid + r",([^\n]+)\)[,;]$", baseline, re.M)
            self.assertIsNotNone(original)
            fields = [guid] + original[1].split(",")
            expected = [fields[0], fields[1], fields[4], fields[8], fields[9], *fields[10:23]]
            self.assertEqual([guid] + values.split(","), expected)

    def test_private_spawn_production_admission_guard(self):
        source = (ROOT / "src/server/game/Entities/Creature/Creature.cpp").read_text(encoding="utf-8")
        start = source.index("bool Creature::LoadCreatureFromDB(")
        start = source.index("{", start) + 1
        end = source.index("    if (!allowDuplicate)", start)
        guard = source[start:end]
        fixture = r"""
#include <cassert>
struct CreatureData { int mapid; int spawnId; };
struct Map { bool privateMap; int id;
    bool IsScriptedPrivateInstance() const {return privateMap;}
    int GetId() const {return id;}
};
struct ObjectMgr { bool native = false; bool GetCreatureData(int) const {return native;} } manager;
auto sObjectMgr = &manager;
bool allowed(int spawnId, Map* map, CreatureData const* privateData) {
""" + guard + r"""
return true;
}
int main() {
    Map publicMap{false, 129}, privateMap{true, 129};
    CreatureData data{129, 13366};
    assert(!allowed(13366, nullptr, &data));
    assert(allowed(13366, &publicMap, nullptr));
    assert(!allowed(13366, &publicMap, &data));
    assert(allowed(13366, &privateMap, &data));
    assert(!allowed(31953, &privateMap, &data));
    data.mapid = 329;
    assert(!allowed(13366, &privateMap, &data));
    data.mapid = 129;
    manager.native = true;
    assert(!allowed(13366, &privateMap, &data));
    manager.native = false;
    data.spawnId = 0;
    assert(!allowed(0, &privateMap, &data));
}
"""
        with tempfile.TemporaryDirectory(prefix="manastorm-private-") as directory:
            temporary = Path(directory)
            (temporary / "fixture.cpp").write_text(fixture, encoding="utf-8")
            if os.name == "nt":
                installs = Path(os.environ.get("ProgramFiles", "C:/Program Files")) / "Microsoft Visual Studio"
                vcvars = next(installs.glob("2022/*/VC/Auxiliary/Build/vcvars64.bat"), None)
                self.assertIsNotNone(vcvars)
                command = f'cmd.exe /d /c call "{vcvars}" >nul && cl /nologo /std:c++20 /EHsc fixture.cpp /Fe:fixture.exe /Fo:fixture.obj'
                executable = temporary / "fixture.exe"
            else:
                compiler = shutil.which("c++") or shutil.which("clang++") or shutil.which("g++")
                self.assertIsNotNone(compiler)
                command = [compiler, "-std=c++20", "fixture.cpp", "-o", "fixture"]
                executable = temporary / "fixture"
            compiled = subprocess.run(command, cwd=temporary, text=True, capture_output=True)
            self.assertEqual(compiled.returncode, 0, compiled.stdout + compiled.stderr)
            executed = subprocess.run([str(executable)], cwd=temporary, text=True, capture_output=True)
            self.assertEqual(executed.returncode, 0, executed.stdout + executed.stderr)

    def test_native_config_uses_upstream_collector(self):
        source = (MODULE / "src/ManastormClientBridge.cpp").read_text(encoding="utf-8")
        self.assertIn("RegisterAscensionClientConfig(", source)
        self.assertIn("SendAscensionCoAConfig(session)", source)
        self.assertNotIn("SendNativeClientConfig", source)
        for key in ("CONFIG_MANASTORM_LOADOUTS_MAX", "CONFIG_MANASTORM_ENABLED",
                    "CONFIG_MANASTORM_END_GAME_ENABLED", "CONFIG_MANASTORM_LOADOUTS_ENABLED"):
            self.assertIn(key, source)
        rewards = (MODULE / "src/ManastormRewards.cpp").read_text(encoding="utf-8")
        self.assertIn("sScriptMgr->OnPlayerGetGameModeMask(player)", rewards)


if __name__ == "__main__":
    unittest.main()
