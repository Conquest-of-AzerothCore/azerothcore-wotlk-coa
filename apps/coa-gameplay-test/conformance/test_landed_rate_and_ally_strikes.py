import unittest

from behaviours import behaviour_scenario
from profile import DBC_DIR, load_fixture_class_file
import run


def landed_entry(**changes) -> dict:
    return {'spell': 807905, 'kind': 'hit_ratio', 'label_suffix': 'hit_landed', 'name': 'Staff of the Coven',
            'quote': 'and your hit chance by $s2%.', 'expected': 1.0, 'observe_spell': 573026,
            'control': {}, 'treatment': {'learn': [807905]}, 'rate': 'landed', 'expected_points': 4, 'trials': 4,
            'cast_power': 1000, 'fixture': {'spell_hit_rating': 0}, **changes}


def eye_entry(**changes) -> dict:
    return {'spell': 503714, 'kind': 'hit_ratio', 'label_suffix': 'eye_damage', 'name': 'Eye of Kimbul',
            'quote': 'Critical strikes now apply Eye of Kimbul to enemies', 'expected': 1.05,
            'observe_spell': 807037, 'control': {}, 'treatment': {'learn': [503714]},
            'warmup': [573026, 573026], 'warmup_power': 1000, 'force_crit': 'spell', 'critical': True, 'trials': 2,
            'cast_power': 1000, **changes}


def field_entry(**changes) -> dict:
    return {'spell': 802719, 'kind': 'immunity', 'variant': 'field', 'name': 'Big Bad Voodoo',
            'quote': 'you are immune to all harmful spells and effects', 'aura': 802718,
            'effects': [{'spell': 1714, 'words': 'harmful spells'}], 'expired_extra_ms': 2500, **changes}


def ally_entry(**changes) -> dict:
    return {'spell': 802719, 'kind': 'taken_hit', 'label_suffix': 'ally_taken', 'judge': 'damage_ratio',
            'struck': 'ally', 'expected': 0.8, 'name': 'Big Bad Voodoo',
            'quote': 'their damage taken is reduced by $s2%.', 'strike_spell': 92559, 'trials': 2,
            'arms': [{'name': 'control'},
                     {'name': 'treatment', 'opening_casts': [[802719, 'caster']], 'opening_settle_ms': 500}],
            **changes}


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class LandedRateTests(unittest.TestCase):
    def test_landed_rate_reads_damage_events_over_cast_packets(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), landed_entry())
        run.validate(scenario)
        reads = {step['label']: step for step in scenario['steps'] if step.get('label', '').startswith(
            '807905 behaviour_hit_ratio hit_landed control 1 ')}
        total = reads['807905 behaviour_hit_ratio hit_landed control 1 total']
        count = reads['807905 behaviour_hit_ratio hit_landed control 1 count']
        self.assertEqual((total['metric'], total['spell'], total['target']), ('spell_damage_count', 573026, 'dummy'))
        self.assertEqual((count['metric'], count['spell']), ('spell_go_count', 573026))
        self.assertNotIn('target', count)
        self.assertEqual(scenario['players'][0]['spell_hit_rating'], 0)
        self.assertEqual(expectation.model['rate'], 'landed')
        self.assertIn('per cast of 573026', scenario['contract'])

    def test_landed_rate_refuses_swings_and_other_cast_spells(self):
        for changes in ({'cast_spell': 807037}, {'metric': 'spell_heal_total'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                behaviour_scenario(load_fixture_class_file(19), landed_entry(**changes))

    def test_warmup_power_sets_power_before_each_warmup_cast(self):
        scenario, _ = behaviour_scenario(load_fixture_class_file(19), eye_entry())
        run.validate(scenario)
        steps = scenario['steps']
        casts = [index for index, step in enumerate(steps) if step['action'] == 'cast' and step['spell'] == 573026]
        self.assertEqual(len(casts), 4)
        for index in casts:
            self.assertEqual(steps[index - 2], {'action': 'set_power', 'actor': 'caster', 'power': 0, 'value': 1000})
        without, _ = behaviour_scenario(load_fixture_class_file(19), {
            key: value for key, value in eye_entry().items() if key != 'warmup_power'})
        before = [without['steps'][index - 1]['action'] for index, step in enumerate(without['steps'])
                  if step['action'] == 'cast' and step['spell'] == 573026]
        self.assertEqual(before, ['reset_cooldown'] * 4)

    def test_warmup_power_needs_a_warmup(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(19), eye_entry(warmup=[]))


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class FieldAndAllyStrikeTests(unittest.TestCase):
    def test_expired_extra_ms_moves_the_expired_reading(self):
        def expired_time(entry: dict) -> int:
            scenario, _ = behaviour_scenario(load_fixture_class_file(19), entry)
            run.validate(scenario)
            elapsed = 0
            for step in scenario['steps']:
                if step.get('label') == '802719 immunity field 802719 expired':
                    return elapsed
                elapsed += step.get('ms', 0) if step['action'] == 'wait' else 0
            raise AssertionError('no expired reading')
        plain = {key: value for key, value in field_entry().items() if key != 'expired_extra_ms'}
        self.assertEqual(expired_time(field_entry()) - expired_time(plain), 2500)

    def test_expired_extra_ms_needs_a_carrier_aura(self):
        entry = {key: value for key, value in field_entry().items() if key != 'aura'}
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(19), entry)

    def test_damage_ratio_strikes_the_ally(self):
        scenario, [expectation] = behaviour_scenario(load_fixture_class_file(19), ally_entry())
        run.validate(scenario)
        strikes = [step for step in scenario['steps'] if step['action'] == 'cast' and step.get('actor') == 'striker']
        self.assertTrue(strikes)
        self.assertTrue(all(step['target'] == 'ally' for step in strikes))
        self.assertEqual(expectation.check, 'behaviour_hit_ratio')
        reads = [step for step in scenario['steps'] if step.get('label', '').endswith('treatment 1 damage')]
        self.assertEqual(reads[0]['target'], 'ally')
        self.assertIs(reads[0]['critical'], False)

    def test_ally_damage_ratio_refuses_caster_health(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(load_fixture_class_file(19), ally_entry(caster_health_pct=90,
                                                                       caster_max_health=100000))


if __name__ == '__main__':
    unittest.main()
