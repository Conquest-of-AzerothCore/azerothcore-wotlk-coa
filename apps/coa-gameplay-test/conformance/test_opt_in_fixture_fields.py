import unittest

from behaviours import NotModelled, behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
from pathlib import Path
import sys

from values import FIXTURE_MAX_HEALTH

sys.path.append(str(Path(__file__).resolve().parents[1]))
import run

CLASS_FILE = load_fixture_class_file(23)

GLEAMING_VIGIL = {
    'spell': 704585, 'name': 'Gleaming Vigil (Physical damage taken at 79% from below)', 'kind': 'taken_hit',
    'variant': 'taken_band_from_below', 'label_suffix': 'taken_band_from_below', 'judge': 'damage_ratio',
    'expected': 0.95, 'quote': 'plus an additional $s2% while above 80% health.', 'strike_spell': 92559,
    'caster_health_pct': 79, 'caster_max_health': 100000, 'trials': 3,
    'arms': [{'name': 'control', 'unlearn': [704585]}, {'name': 'treatment', 'learn': [704585]}]}

VALKYRS_CALLING = {
    'spell': 520024, 'name': "Valkyr's Calling (spell immunity)", 'kind': 'immunity', 'variant': 'spells',
    'quote': 'Target an enemy and leap into the air, becoming immune to all physical attacks and spells for $d.',
    'effects': [{'spell': 12323, 'words': 'spells'}], 'aura': 520025, 'cast_target': 'dummy'}

HOPE = {
    'spell': 300349, 'name': 'Hope (a critical heal cuts Solar Invocation by 1 s)', 'kind': 'cost_gate',
    'label_suffix': 'cd_gate',
    'quote': 'Your critical heals now reduce the cooldown of Solar Invocation spells by $/1000;804512s1 sec.',
    'gated_spell': 800764, 'resource': 'cooldown', 'reduction': 1000, 'target': 'caster',
    'after_casts': [[503624, 'caster']], 'after_wait_ms': 1600, 'caster_health_pct': 30}


def health_steps(scenario: dict) -> list[dict]:
    return [step for step in scenario['steps'] if step['action'] == 'set_health' and step['actor'] == 'caster']


def without(entry: dict, *keys: str) -> dict:
    return {key: value for key, value in entry.items() if key not in keys}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class TakenHitHealthFromTests(unittest.TestCase):
    def test_each_arm_enters_its_health_from_the_stated_percent_with_settles(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, {**GLEAMING_VIGIL, 'caster_health_from_pct': 50})
        run.validate(scenario)
        steps = scenario['steps']
        entries = [index for index, step in enumerate(steps)
                   if step['action'] == 'set_health' and step['value'] == 50000]
        self.assertEqual(len(entries), 2)
        for index in entries:
            self.assertEqual(steps[index + 1]['action'], 'wait')
            self.assertEqual((steps[index + 2]['action'], steps[index + 2]['value']), ('set_health', 79000))
            self.assertEqual(steps[index + 3]['ms'], 1000)
        self.assertFalse(scenario['players'][0]['allow_regeneration'])
        self.assertIn('entering it from 50%', scenario['contract'])

    def test_without_the_field_the_scenario_is_unchanged_in_shape(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, GLEAMING_VIGIL)
        self.assertFalse(any(step['value'] == 50000 for step in health_steps(scenario)))
        self.assertNotIn('allow_regeneration', scenario['players'][0])

    def test_the_entry_percent_needs_a_caster_health_and_another_percent(self):
        for entry in ({**GLEAMING_VIGIL, 'caster_health_from_pct': 79},
                      {**GLEAMING_VIGIL, 'caster_health_from_pct': 0},
                      {**without(GLEAMING_VIGIL, 'caster_health_pct'), 'caster_health_from_pct': 50}):
            with self.subTest(entry=entry.get('caster_health_from_pct')), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ImmunityCastTargetTests(unittest.TestCase):
    def test_the_spell_is_cast_at_the_dummy_and_the_carrier_is_read_on_the_caster(self):
        scenario, expectations = behaviour_scenario(CLASS_FILE, VALKYRS_CALLING)
        run.validate(scenario)
        steps = scenario['steps']
        cast = next(index for index, step in enumerate(steps)
                    if step['action'] == 'cast' and step['spell'] == 520024)
        self.assertEqual((steps[cast]['actor'], steps[cast]['target']), ('caster', 'dummy'))
        applied = next(step for step in steps if step.get('label') == '520024 immunity spells 520024 applied')
        self.assertEqual((applied['actor'], applied['spell']), ('caster', 520025))
        self.assertFalse(any(step.get('label') == '520025 applied settle' for step in steps))
        self.assertIn('cast at the dummy', scenario['contract'])
        self.assertEqual(len(expectations), 6)

    def test_without_the_field_the_cast_targets_the_subject_after_a_settle(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, without(VALKYRS_CALLING, 'cast_target'))
        steps = scenario['steps']
        self.assertEqual(next(step for step in steps if step['action'] == 'cast' and step['spell'] == 520024)
                         ['target'], 'caster')
        self.assertTrue(any(step.get('label') == '520025 applied settle' for step in steps))

    def test_a_with_arm_longer_than_the_carrier_or_a_bad_target_is_refused(self):
        two = {**VALKYRS_CALLING, 'effects': [{'spell': 12323, 'words': 'spells'},
                                              {'spell': 47021, 'words': 'spells'}]}
        with self.assertRaises(NotModelled):
            behaviour_scenario(CLASS_FILE, two)
        for entry in ({**VALKYRS_CALLING, 'cast_target': 'caster'}, without(VALKYRS_CALLING, 'aura'),
                      {**VALKYRS_CALLING, 'target': 'ally'}):
            with self.subTest(entry=entry), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, entry)


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class CostGateCasterHealthTests(unittest.TestCase):
    def test_every_arm_sets_the_caster_health_just_before_its_after_casts(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, HOPE)
        run.validate(scenario)
        steps = scenario['steps']
        heals = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 503624]
        self.assertTrue(heals)
        for index in heals:
            before = steps[max(0, index - 8):index]
            self.assertIn({'action': 'set_health', 'actor': 'caster', 'value': 30 * FIXTURE_MAX_HEALTH // 100,
                           'maximum': FIXTURE_MAX_HEALTH}, before)
        self.assertIn('30% health before every arm', scenario['contract'])

    def test_without_the_field_no_caster_health_is_set(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, without(HOPE, 'caster_health_pct'))
        self.assertEqual(health_steps(scenario), [])

    def test_the_caster_health_needs_after_casts_and_a_percent_below_full(self):
        for entry in ({**HOPE, 'caster_health_pct': 100}, {**HOPE, 'caster_health_pct': 0},
                      {**without(HOPE, 'after_casts'), 'caster_health_pct': 30}):
            with self.subTest(entry=entry.get('caster_health_pct')), self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, entry)


if __name__ == '__main__':
    unittest.main()
