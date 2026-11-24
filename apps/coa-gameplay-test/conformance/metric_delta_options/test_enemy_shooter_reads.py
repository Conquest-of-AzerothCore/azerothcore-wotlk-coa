import unittest

import run


def step(**changes) -> dict:
    return {'action': 'assert', 'label': 'read', 'actor': 'caster', 'min': 0, 'max': 1, **changes}


def scenario(*steps) -> dict:
    return {'schema': 1, 'name': 'reads', 'players': [{'id': 'caster', 'race': 1, 'class': 27}], 'steps': list(steps)}


class SchoolMaskAndUnitFlagTests(unittest.TestCase):
    def test_school_mask_is_a_range_checked_filter_of_spell_damage_reads(self):
        for metric in ('spell_damage_count', 'spell_damage_total'):
            run.validate(scenario(step(metric=metric, spell=572850, school_mask=1, target='caster')))
        for changes in ({'school_mask': 0}, {'school_mask': 128}):
            with self.subTest(changes=changes), self.assertRaises(Exception):
                run.validate(scenario(step(**{'metric': 'spell_damage_count', 'spell': 572850, 'school_mask': 1,
                                              'target': 'caster', **changes})))

    def test_unit_flag_set_needs_a_target_field_and_mask(self):
        run.validate(scenario(step(metric='unit_flag_set', target='caster', field=2, mask=1024)))
        for changes in ({'field': 3}, {'mask': 0}, {'target': None}):
            with self.subTest(changes=changes), self.assertRaises(Exception):
                read = step(metric='unit_flag_set', target='caster', field=2, mask=1024)
                read.update(changes)
                read = {key: value for key, value in read.items() if value is not None}
                run.validate(scenario(read))

    def test_field_and_mask_belong_to_unit_flag_set_only(self):
        with self.assertRaises(Exception):
            run.validate(scenario(step(metric='attack_power', field=1)))


if __name__ == '__main__':
    unittest.main()
