import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def mirror_entry(**changes) -> dict:
    return {'spell': 681007, 'name': "Fool's Play (the copy casts the target's spell back at it)",
            'kind': 'metric_delta', 'label_suffix': 'mirror', 'quote': 'and replicates their spells back on them',
            'trigger_spell': 681007, 'target': 'dummy', 'measure_actor': 'caster', 'cast_power': 2000,
            'gate_timing': 'start', 'trigger_only_after': True, 'metric': 'spell_damage_count',
            'fields': {'spell': 2653, 'target': 'dummy', 'caster_entry': 300660}, 'before_expected': 0,
            'expected': 3, 'wait_ms': 500, 'expire_ms': 500,
            'dummy_casts_at_caster': {'spell': 2653, 'casts': 3, 'gap_ms': 1500, 'lead_ms': 1000}, **changes}


def dummy_casts(scenario: dict) -> list[int]:
    return [index for index, step in enumerate(scenario['steps'])
            if step['action'] == 'cast' and step['actor'] == 'dummy']


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class DummyCastsAtCasterTests(unittest.TestCase):
    def test_the_dummy_casts_untriggered_at_the_caster_in_both_phases(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(23), mirror_entry())
        run.validate(scenario)
        steps = scenario['steps']
        casts = dummy_casts(scenario)
        self.assertEqual(len(casts), 6)
        self.assertTrue(all(steps[index]['target'] == 'caster' and steps[index]['triggered'] is False
                            for index in casts))
        labels = [step.get('label') for step in steps]
        before = labels.index(expectation.model['before_label'])
        trigger = next(index for index, step in enumerate(steps) if step['action'] == 'cast'
                       and step['spell'] == 681007)
        self.assertEqual(sum(index < before for index in casts), 3)
        self.assertEqual(sum(index > trigger for index in casts), 3)

    def test_a_cast_before_phase_casts_after_each_trigger(self):
        entry = mirror_entry(gate_timing='between', trigger_only_after=False, gate_spell=536213)
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        steps = scenario['steps']
        triggers = [index for index, step in enumerate(steps) if step['action'] == 'cast'
                    and step['spell'] == 681007]
        casts = dummy_casts(scenario)
        self.assertEqual(len(triggers), 2)
        self.assertEqual(sum(triggers[0] < index < triggers[1] for index in casts), 3)

    def test_without_the_option_the_dummy_casts_nothing(self):
        entry = {key: value for key, value in mirror_entry().items() if key != 'dummy_casts_at_caster'}
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        self.assertEqual(dummy_casts(scenario), [])

    def test_refused_inputs(self):
        for raw in ({'spell': 2653, 'casts': 0, 'gap_ms': 1500, 'lead_ms': 0},
                    {'spell': 2653, 'casts': 3, 'gap_ms': 500, 'lead_ms': 0}, {'spell': 2653}):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(23), mirror_entry(dummy_casts_at_caster=raw))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23), mirror_entry(target='enemy', enemy_player_race=2))
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(23),
                               mirror_entry(target='caster', fields={'spell': 2653, 'target': 'caster'}))

    def test_a_self_cast_trigger_keeps_the_dummy_that_casts_at_the_caster(self):
        entry = mirror_entry(target='caster', measure_actor='dummy', metric='aura',
                             fields={'spell': 504762, 'caster': 'caster'})
        scenario, _ = behaviour_scenario(load_fixture_class_file(23), entry)
        run.validate(scenario)
        steps = scenario['steps']
        trigger = next(index for index, step in enumerate(steps) if step['action'] == 'cast'
                       and step['spell'] == 681007)
        self.assertEqual(steps[trigger]['target'], 'caster')
        self.assertEqual(len(scenario['creatures']), 1)
        self.assertEqual(sum(index > trigger for index in dummy_casts(scenario)), 3)


if __name__ == '__main__':
    unittest.main()
