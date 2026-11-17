import math
import unittest

from mitigation import REFERENCE_TARGET, TargetProfile, expected_mitigation

PHYSICAL = 1
HOLY = 2
SHADOW = 32

SCOURGEBANE_LEVEL_60_NONCRIT_TOTAL = 398219
SCOURGEBANE_LEVEL_60_NONCRIT_HITS = 1548
SCOURGEBANE_PENETRATED_NONCRIT_TOTAL = 85486
SCOURGEBANE_PENETRATED_NONCRIT_HITS = 290
PVE_POWER_RING_BONUS_PER_HIT = 2
MEASURED_HOLY_KEPT = (SCOURGEBANE_LEVEL_60_NONCRIT_TOTAL / SCOURGEBANE_LEVEL_60_NONCRIT_HITS) / (
    SCOURGEBANE_PENETRATED_NONCRIT_TOTAL / SCOURGEBANE_PENETRATED_NONCRIT_HITS - PVE_POWER_RING_BONUS_PER_HIT)

MEASURED_ARMOR_REDUCED_PER_1000 = {528: 913, 562: 908}


class TargetMitigationTest(unittest.TestCase):
    def test_reference_target_holy_mitigation(self):
        model = expected_mitigation(HOLY, REFERENCE_TARGET, caster_level=60)
        self.assertAlmostEqual(model.mean, MEASURED_HOLY_KEPT, delta=0.005)
        self.assertAlmostEqual(model.mean, 0.88, places=9)

    def test_reference_target_holy_partial_resist_variance(self):
        resisted = {0.0: 0.20, 0.1: 0.45, 0.2: 0.30, 0.3: 0.05}
        mean = sum(share * fraction for fraction, share in resisted.items())
        variance = sum(share * fraction ** 2 for fraction, share in resisted.items()) - mean ** 2
        model = expected_mitigation(HOLY, REFERENCE_TARGET, caster_level=60)
        self.assertAlmostEqual(model.variance, variance, places=9)

    def test_magic_mitigation_keeps_the_partial_resist_shares_and_armor_has_none(self):
        holy = expected_mitigation(HOLY, REFERENCE_TARGET, caster_level=60)
        for step, share in enumerate((0.20, 0.45, 0.30, 0.05, 0, 0, 0, 0, 0, 0, 0)):
            self.assertAlmostEqual(holy.resist_shares[step], share, places=9)
        self.assertEqual(expected_mitigation(PHYSICAL, REFERENCE_TARGET, caster_level=60).resist_shares, ())

    def test_armor_mitigation_level_60(self):
        target = TargetProfile(entry=36, level=60, armor=528, resistances={})
        model = expected_mitigation(PHYSICAL, target, caster_level=60)
        self.assertAlmostEqual(model.mean, 1 - 528 / (528 + 85 * 60 + 400), places=9)
        self.assertEqual(model.variance, 0.0)

    def test_armor_mitigation_matches_measured_armor_probe(self):
        for armor, measured in MEASURED_ARMOR_REDUCED_PER_1000.items():
            with self.subTest(armor=armor):
                target = TargetProfile(entry=36, level=60, armor=armor, resistances={})
                model = expected_mitigation(PHYSICAL, target, caster_level=60)
                self.assertEqual(math.ceil(1000 * model.mean), measured)

    def test_armor_outside_vanilla_levels_uses_wotlk_constant(self):
        target = TargetProfile(entry=36, level=80, armor=10000, resistances={})
        level = 80 + 4.5 * (80 - 59)
        reduction = 0.1 * 10000 / (8.5 * level + 40)
        model = expected_mitigation(PHYSICAL, target, caster_level=80)
        self.assertAlmostEqual(model.mean, 1 - reduction / (1 + reduction), places=6)

    def test_penetration_removes_linear_resistance(self):
        for penetration, kept in ((30, 0.94), (60, 1.0), (100, 1.0)):
            with self.subTest(penetration=penetration):
                model = expected_mitigation(HOLY, REFERENCE_TARGET, caster_level=60, penetration=penetration)
                self.assertAlmostEqual(model.mean, kept, places=9)
        self.assertEqual(expected_mitigation(HOLY, REFERENCE_TARGET, 60, penetration=60).variance, 0.0)

    def test_authored_resistance_adds_to_level_baseline(self):
        target = TargetProfile(entry=1, level=60, armor=0, resistances={SHADOW: 40})
        self.assertAlmostEqual(expected_mitigation(SHADOW, target, 60).mean, 0.8, places=9)
        self.assertAlmostEqual(expected_mitigation(HOLY, target, 60).mean, 0.88, places=9)

    def test_multi_school_takes_weakest_resistance(self):
        target = TargetProfile(entry=1, level=60, armor=0, resistances={SHADOW: 40})
        self.assertAlmostEqual(expected_mitigation(HOLY | SHADOW, target, 60).mean, 0.88, places=9)

    def test_resist_is_capped_at_75_percent(self):
        target = TargetProfile(entry=1, level=60, armor=0, resistances={HOLY: 1000})
        self.assertAlmostEqual(expected_mitigation(HOLY, target, 60).mean, 0.25, places=9)

    def test_physical_component_uses_armor_without_resist(self):
        target = TargetProfile(entry=1, level=60, armor=0, resistances={HOLY: 1000})
        model = expected_mitigation(PHYSICAL | HOLY, target, 60)
        self.assertEqual((model.mean, model.variance), (1.0, 0.0))


if __name__ == '__main__':
    unittest.main()
