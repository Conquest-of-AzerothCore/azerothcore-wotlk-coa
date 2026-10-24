from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[1]
MODULE_SRC = ROOT / 'modules/mod-coa-raid-difficulty/src'
RAGNAROS = ROOT / 'src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/boss_ragnaros.cpp'
LUCIFRON_SQL = ROOT / 'data/sql/updates/pending_db_world/rev_20261005_20_molten_core_lucifron_impending_doom.sql'
SPELL_INFO_CORRECTIONS = ROOT / 'src/server/game/Spells/SpellInfoCorrections.cpp'


def source(path):
    return path.read_text(encoding='utf-8')


class MoltenCoreBossTimingTests(unittest.TestCase):
    def test_lucifron_impending_doom_follows_the_logged_window(self):
        match = re.search(
            r'`first_ms` = (\d+), `first_max_ms` = (\d+), `period_ms` = (\d+), `period_max_ms` = (\d+)',
            source(LUCIFRON_SQL))
        self.assertEqual(tuple(int(value) for value in match.groups()), (20900, 27500, 22200, 22600))

    def test_ragnaros_casts_both_super_novas_every_twelve_seconds(self):
        text = source(RAGNAROS)
        self.assertIn('SPELL_SUPER_NOVA_A                      = 2108627', text)
        self.assertIn('SPELL_SUPER_NOVA_B                      = 2108662', text)
        self.assertIn('SUPER_NOVA_A_FIRST = 10000ms', text)
        self.assertIn('SUPER_NOVA_B_FIRST = 15000ms', text)
        self.assertIn('SUPER_NOVA_PERIOD = 12000ms', text)

    def test_magmadar_cycles_the_ancient_spells_in_logged_order(self):
        text = source(MODULE_SRC / 'boss_magmadar_coa.cpp')
        order = re.search(r'ANCIENT_CYCLE_COA = \{\s*([^}]+)\}', text).group(1)
        self.assertEqual(re.findall(r'SPELL_ANCIENT_(\w+)_COA', order), ['HYSTERIA', 'DREAD', 'FURY', 'DESPAIR'])
        self.assertIn('ANCIENT_REPEAT_MIN_COA = 66600ms', text)
        self.assertIn('ANCIENT_REPEAT_MAX_COA = 70200ms', text)

    def test_shazzrah_blink_brings_time_stop_and_a_delayed_mass_slow(self):
        text = source(MODULE_SRC / 'boss_shazzrah_coa.cpp')
        self.assertIn('CastSpell(target, SPELL_TIME_STOP_COA, true)', text)
        self.assertIn('CastSpell(creatureCaster, SPELL_MASS_SLOW_COA, true)', text)
        self.assertIn('MASS_SLOW_DELAY_COA = 2000ms', text)

    def test_geddon_inferno_waves_add_heating_up(self):
        text = source(MODULE_SRC / 'boss_geddon_coa.cpp')
        self.assertIn('SPELL_HEATING_UP                   = 2105746', text)
        self.assertIn('AfterCast += SpellCastFn(spell_geddon_inferno_damage_coa::AddHeatingUp)', text)

    def test_geddon_living_bomb_leaves_burning_ground_at_the_carrier(self):
        text = source(MODULE_SRC / 'boss_geddon_coa.cpp')
        self.assertIn('SPELL_LIVING_BOMB_BURNING_GROUND_NORMAL = 2105713', text)
        self.assertIn('uint32 const burningGround = SPELL_LIVING_BOMB_BURNING_GROUND_NORMAL + offset', text)
        self.assertIn(
            'source->CastSpell(carrier->GetPositionX(), carrier->GetPositionY(), carrier->GetPositionZ(), '
            'burningGround, true)',
            text)

    def test_geddon_knock_up_apex_is_halved(self):
        text = source(SPELL_INFO_CORRECTIONS)
        match = re.search(r'ApplySpellFix\(\{ 2105712 \}, \[\]\(SpellInfo\* spellInfo\)\s*\{\s*'
                           r'spellInfo->Effects\[EFFECT_0\]\.BasePoints = (\d+);', text)
        self.assertIsNotNone(match)
        base_points = int(match.group(1))
        gravity = 19.29110527038574
        old_apex = (499 + 1) ** 2 * 0.1 ** 2 / (2 * gravity)
        new_apex = (base_points + 1) ** 2 * 0.1 ** 2 / (2 * gravity)
        self.assertLess(new_apex, old_apex / 1.9)
        self.assertGreater(new_apex, old_apex / 2.1)


if __name__ == '__main__':
    unittest.main()
