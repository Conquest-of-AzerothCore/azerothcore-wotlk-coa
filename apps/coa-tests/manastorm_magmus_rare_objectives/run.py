from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'modules/mod-manastorm-endless'
SOURCE = MODULE / 'src'

ARCHIVE_NATIVE_MODIFIERS = {
    83261: (78.120003, 1.0),
    83617: (97.656197, 1.0),
    83618: (97.656197, 20.0),
    83619: (97.656197, 12.0),
    83668: (78.120003, 1.0),
    83859: (97.650002, 2.0),
    84270: (60.6562, 8.0),
    84272: (97.656197, 10.0),
}


def function(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def substituted_segments():
    text = (MODULE / 'data/sql/db-world/updates/zz_manastorm_snapshot_2_world.sql').read_text(encoding='utf-8')
    start = text.index('INSERT INTO `manastorm_segment` (')
    text = text[start:text.index(';\n', start)]
    rows = re.findall(r'^\((\d+), (\d+), \d+, \d+, (\d+), \d+, (\d+), (\d+), \d+, \d+, \d+, \d+, \d+, \d+, \d+, \d+\)',
                      text, re.MULTILINE)
    return {int(segment): (int(native), int(runtime)) for segment, _, _, native, runtime in rows
            if int(native) and int(runtime) and int(native) != int(runtime)}


def native_templates():
    header = (SOURCE / 'ManastormSubstitutedObjectives.h').read_text(encoding='utf-8')
    return {int(entry): (float(health), float(mana)) for entry, health, mana in re.findall(
        r'\{(\d+), ([0-9.]+)f, ([0-9.]+)f\}', header)}


class SubstitutedObjectiveTests(unittest.TestCase):
    def test_table_matches_archive_captures(self):
        self.assertEqual(native_templates(), ARCHIVE_NATIVE_MODIFIERS)

    def test_every_substituted_segment_has_native_modifiers(self):
        segments = substituted_segments()
        self.assertEqual(sorted(segments), [407, 409, 411, 413, 474, 478, 480, 526, 527, 542, 543, 552, 553, 554, 555])
        self.assertEqual(segments[526], (84270, 599))
        self.assertEqual({native for native, _ in segments.values()}, set(ARCHIVE_NATIVE_MODIFIERS))

    def test_lookup_skips_native_and_unsubstituted_segments(self):
        header = (SOURCE / 'ManastormSubstitutedObjectives.h').read_text(encoding='utf-8')
        lookup = function(header, 'constexpr NativeTemplate const* Find(')
        self.assertIn('if (!nativeEntry || nativeEntry == runtimeEntry)', lookup)
        ratio = function(header, 'constexpr double Ratio(')
        self.assertIn('runtimeModifier > 0.0f ? double(nativeModifier) / double(runtimeModifier) : 1.0', ratio)

    def test_health_scaling_uses_native_baseline_before_chaotic_link(self):
        source = (SOURCE / 'ManastormMgr.cpp').read_text(encoding='utf-8')
        finder = function(source, 'FindSubstitutedObjectiveTemplate(\n        Creature const* creature')
        self.assertIn('IsObjectiveBoss(', finder)
        self.assertIn('segment.ObjectiveCreatureEntry', finder)
        self.assertIn('segment.NativeObjectiveCreatureEntry', finder)
        scaling = function(source, 'void ManastormMgr::ApplyCreatureHealthScaling(')
        native = scaling.index('FindSubstitutedObjectiveTemplate(')
        self.assertLess(native, scaling.index('run.GetScaling().HealthMultiplier'))
        self.assertLess(native, scaling.index('SetChaoticLinkBaseMaxHealth('))
        self.assertIn('runtimeTemplate->ModHealth', scaling)
        self.assertIn('runtimeTemplate->ModMana', scaling)
        mana = function(source, 'void ApplySubstitutedObjectiveMana(')
        for call in ('SetCreateMana(', 'SetStatFlatModifier(\n            UNIT_MOD_MANA', 'UpdateMaxPower(', 'SetPower('):
            self.assertIn(call, mana)


class MagmusTorchTests(unittest.TestCase):
    def setUp(self):
        self.source = (SOURCE / 'ManastormRuntimeCompat.cpp').read_text(encoding='utf-8')
        self.script = function(self.source, 'class manastorm_magmus_flame_keeper_torch')
        self.lootable = function(self.source, 'class manastorm_magmus_flame_keeper_lootable')

    def test_constants(self):
        for constant in ('MAP_BLACKROCK_DEPTHS = 230', 'NPC_SHADOWFORGE_FLAME_KEEPER = 9956',
                         'ITEM_SHADOWFORGE_TORCH = 11885', 'SEGMENT_MAGMUS_NORMAL = 428',
                         'SEGMENT_MAGMUS_ENDGAME = 457'):
            self.assertIn(constant, self.source)

    def test_scoped_to_magmus_stage_flame_keepers(self):
        keeper = function(self.source, 'bool IsMagmusStageFlameKeeper(')
        for guard in ('NPC_SHADOWFORGE_FLAME_KEEPER', 'MAP_BLACKROCK_DEPTHS', 'GetRunForStageCreature(',
                      'SEGMENT_MAGMUS_NORMAL', 'SEGMENT_MAGMUS_ENDGAME'):
            self.assertIn(guard, keeper)
        for script in (self.script, self.lootable):
            self.assertIn('ManastormModuleConfig::Enabled()', script)
            self.assertIn('IsMagmusStageFlameKeeper(creature)', script)

    def test_torch_joins_creature_loot_before_core_assigns_looters(self):
        self.assertIn('MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS', self.script)
        self.assertIn('&store != &LootTemplates_Creature', self.script)
        self.assertIn('loot->sourceWorldObjectGUID', self.script)
        loot = (ROOT / 'src/server/game/Loot/LootMgr.cpp').read_text(encoding='utf-8')
        fill = function(loot, 'bool Loot::FillLoot(')
        self.assertLess(fill.index('sScriptMgr->OnAfterLootTemplateProcess('), fill.index('FillNotNormalLootFor('))
        self.assertLess(fill.index('lootOwnerGUID = lootOwner->GetGUID()'),
                        fill.index('sScriptMgr->OnAfterLootTemplateProcess('))

    def test_adds_one_torch(self):
        self.assertRegex(self.script, r'LootStoreItem\(\s*ITEM_SHADOWFORGE_TORCH,\s*0,\s*100\.0f,\s*false,\s*'
                                      r'LOOT_MODE_DEFAULT,\s*0,\s*1,\s*1\)')
        self.assertLess(self.script.index('HoldsShadowforgeTorch(*loot)'), self.script.index('loot->AddItem('))

    def test_corpse_with_torch_is_lootable(self):
        self.assertIn('UNITHOOK_ON_UNIT_DEATH', self.lootable)
        self.assertIn('creature->loot.isLooted()', self.lootable)
        self.assertIn('HoldsShadowforgeTorch(\n                    creature->loot)', self.lootable)
        self.assertIn('SetDynamicFlag(\n                UNIT_DYNFLAG_LOOTABLE)', self.lootable)

    def test_health_scaling_resizes_player_damage_requirement(self):
        source = (SOURCE / 'ManastormMgr.cpp').read_text(encoding='utf-8')
        scaling = function(source, 'void ManastormMgr::ApplyCreatureHealthScaling(')
        reset = scaling.index('creature->ResetPlayerDamageReq()')
        self.assertLess(scaling.index('creature->SetHealth('), reset)
        self.assertLess(scaling.index('if (!creature->IsInCombat())'), reset)

    def test_registered(self):
        registration = function(self.source, 'void AddSC_manastorm_runtime_compat()')
        self.assertIn('new manastorm_magmus_flame_keeper_torch();', registration)
        self.assertIn('new manastorm_magmus_flame_keeper_lootable();', registration)

if __name__ == '__main__':
    unittest.main()
