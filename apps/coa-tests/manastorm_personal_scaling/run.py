from fractions import Fraction
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'modules/mod-manastorm-endless/src'
WEAVER = ROOT / 'modules/mod-destiny-weaver/src/destiny_weaver_scaling.cpp'


def function(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


class PersonalScalingTests(unittest.TestCase):
    def test_group_scope_membership_and_departure_stability(self):
        source = (MODULE / 'ManastormMgr.cpp').read_text(encoding='utf-8')
        gate = function(source, 'bool ManastormMgr::HasPersonalLevelScaling(')
        for expected in ('!map->IsScriptedPrivateInstance()', 'GetRunForStage(map->GetId(), map->GetInstanceId())',
                         'run->GetMode() == ManastormMode::Solo', 'viewer->FindMap() == map',
                         'GetRunFor(viewer) == run'):
            self.assertIn(expected, gate)
        self.assertNotIn('GetMembers().size()', gate)
        removal = function((MODULE / 'ManastormRun.h').read_text(encoding='utf-8'), 'bool RemoveMember(')
        self.assertNotIn('_mode =', removal)

    def test_personal_levels_and_existing_world_controls(self):
        source = WEAVER.read_text(encoding='utf-8')
        view = function(source, 'bool ViewFor(')
        self.assertIn('level = viewer->GetLevel()', view)
        self.assertIn('if (level == own && !personalInstance)', view)
        self.assertIn('map->IsScriptedPrivateInstance() && !personalInstance', view)
        self.assertIn('ScalingBlocksFor(viewer)', view)
        self.assertIn('ScaleDungeonCreatureLevelForViewer', view)
        self.assertIn('ScaleCreatureLevelForViewer', view)
        eligible = function(source, 'bool ViewableCreature(')
        self.assertIn('creature->IsControlledByPlayer()', eligible)
        self.assertIn('(creature->isWorldBoss() && !personalInstance)', eligible)

    def test_depth_and_group_multipliers_survive_view_conversion(self):
        source = WEAVER.read_text(encoding='utf-8')
        view = function(source, 'bool ViewFor(')
        self.assertIn('creature->GetMaxHealth()', view)
        self.assertIn('uint64(realMaxHealth) * view.Stats.Health', view)
        self.assertIn('double(realMaxHealth) / double(view.MaxHealth)', view)
        sql = (ROOT / 'data/sql/base/db_world/creature_classlevelstats.sql').read_text(encoding='utf-8')
        rows = {int(level): int(health) for level, health in re.findall(r'^\((\d+),1,(\d+),', sql, re.M)}
        self.assertIn(20, rows)
        self.assertIn(60, rows)
        for level in (20, 60):
            for depth_factor, group_factor in ((1, 1), (2, 3), (7, 5)):
                real = rows[60] * depth_factor * group_factor
                personal = real * rows[level] // rows[60]
                self.assertEqual(personal, rows[level] * depth_factor * group_factor)
                self.assertEqual(Fraction(personal, 10) * Fraction(real, personal), Fraction(real, 10))

    def test_percentage_damage_converts_once_in_each_direction(self):
        real, personal = 20000, 2000
        self.assertEqual(Fraction(personal, 10) * Fraction(real, personal), 2000)
        player_health = 1000
        for factor in (Fraction(1, 10), Fraction(1), Fraction(2)):
            basis = Fraction(player_health, 1) / factor
            self.assertEqual(basis / 10 * factor, 100)
        unit = (ROOT / 'src/server/game/Entities/Unit/Unit.cpp').read_text(encoding='utf-8')
        helper = function(unit, 'uint32 LocalLevelScaling::PersonalDamageHealthFor(')
        self.assertIn('ViewMaxHealthFor(viewer, creature)', helper)
        self.assertIn('double(health) / factor', helper)
        self.assertIn('return health;', helper)
        effects = (ROOT / 'src/server/game/Spells/SpellEffects.cpp').read_text(encoding='utf-8')
        for signature in ('void Spell::EffectAscensionPctDamage(', 'void Spell::EffectAscensionHealthPctDamage('):
            self.assertIn('PersonalDamageHealthFor(m_caster, unitTarget)', function(effects, signature))
        auras = (ROOT / 'src/server/game/Spells/Auras/SpellAuraEffects.cpp').read_text(encoding='utf-8')
        self.assertIn('PersonalDamageHealthFor(caster, target)', auras)

    def test_healing_threat_pets_and_boss_level_wiring(self):
        source = WEAVER.read_text(encoding='utf-8')
        heal = function(source, 'double HealReceivedForCore(')
        self.assertIn('PersonalInstanceScalingFor(map, from)', heal)
        self.assertIn('PersonalInstanceScalingFor(map, to)', heal)
        self.assertIn('personalInstance ? from->GetLevel()', heal)
        self.assertIn('HealsShareOfHealth(spell)', heal)
        self.assertIn('OwningPlayer(attacker)', source)
        self.assertIn('OwningPlayer(target)', source)
        unit = (ROOT / 'src/server/game/Entities/Unit/Unit.cpp').read_text(encoding='utf-8')
        self.assertIn('PoolFactor(source, threatOwner->ToCreature())', unit)
        creature = (ROOT / 'src/server/game/Entities/Creature/Creature.cpp').read_text(encoding='utf-8')
        level = function(creature, 'uint8 Creature::getLevelForTarget(')
        self.assertLess(level.index('PersonalInstanceScalingFor'), level.index('if (!isWorldBoss()'))

    def test_resolver_lifecycle(self):
        source = (MODULE / 'Manastorm.cpp').read_text(encoding='utf-8')
        self.assertIn('PersonalInstanceScalingOwner.store([]', source)
        self.assertIn('PersonalInstanceScalingOwner.store(nullptr', source)
        source = WEAVER.read_text(encoding='utf-8')
        self.assertIn('CreatureViewDamageOwner.store(available ? &ViewDamageForCore', source)
        self.assertIn('CreatureViewDamageOwner.store(nullptr)', source)


if __name__ == '__main__':
    unittest.main()
