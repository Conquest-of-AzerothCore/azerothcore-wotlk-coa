import unittest

import coa_class_buffs as model
from coa_class_buffs import Buff, Effect, Groups


def aura(name, misc=0, target='TARGET_UNIT_TARGET_ALLY'):
    return Effect('SPELL_EFFECT_APPLY_AURA', name, misc, 1, target, 'TARGET_NONE', 0)


def buff(spell_id, family, *effects):
    return Buff(spell_id, f'Spell {spell_id}', family, tuple(effects))


def groups(members, rules=None):
    return Groups({key: set(value) for key, value in members.items()}, dict(rules or {}), {})


class SignatureTests(unittest.TestCase):
    def test_every_listed_aura_name_exists(self):
        known = set(model.enum_values('AuraType'))
        self.assertEqual(set(), (set(model.STAT_KEYS) | model.IGNORED_AURAS) - known)

    def test_signature_keys(self):
        beetle = buff(803657, 29, aura('SPELL_AURA_MOD_RESISTANCE', 1), aura('SPELL_AURA_MOD_STAT', -1))
        self.assertEqual(frozenset({'armor', 'stat:all'}), model.signature(beetle))
        self.assertEqual(frozenset({'stat:1'}), model.signature(buff(1, 20, aura('SPELL_AURA_MOD_STAT', 1))))
        exclusive_armor = buff(2, 20, aura('SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE', 1))
        self.assertEqual(frozenset({'armor'}), model.signature(exclusive_armor))
        all_schools = buff(3, 20, aura('SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE', 126))
        self.assertEqual(frozenset({'resistance:126'}), model.signature(all_schools))

    def test_ignored_effects_do_not_change_signature(self):
        plain = buff(1, 20, aura('SPELL_AURA_MOD_STAT', 1))
        with_dummy = buff(1, 20, aura('SPELL_AURA_MOD_STAT', 1), aura('SPELL_AURA_DUMMY'))
        self.assertEqual(model.signature(plain), model.signature(with_dummy))

    def test_unknown_aura_is_unclassified(self):
        self.assertIsNone(model.signature(buff(1, 20, aura('SPELL_AURA_MOD_STAT', 1), aura('SPELL_AURA_MOD_SCALE'))))

    def test_no_stat_effect_is_unclassified(self):
        self.assertIsNone(model.signature(buff(1, 20, aura('SPELL_AURA_DUMMY'))))


class StackRuleTests(unittest.TestCase):
    def test_ranks_resolve_to_first_rank(self):
        state = groups({2110001: {300857, 706741}}, {2110001: 1})
        first_rank = {300886: 300857, 707355: 706741}
        brutal, edict = buff(300886, 23), buff(707355, 31)
        self.assertEqual('exclusive', model.pair_outcome(brutal, edict, state, first_rank))

    def test_higher_rank_row_is_inert(self):
        state = groups({2110001: {300886, 706741}}, {2110001: 1})
        first_rank = {300886: 300857}
        self.assertIsNone(model.deciding_group(300886, 706741, state, first_rank))

    def test_lowest_ruled_group_decides(self):
        state = groups({1116: {707689, 712459}, 1138: {707689, 712459}, 2110012: {707689, 712459}},
                       {1116: 1, 1138: 2, 2110012: 1})
        self.assertEqual((1116, 1), model.deciding_group(707689, 712459, state, {}))

    def test_ruleless_lower_group_is_skipped(self):
        state = groups({100: {1, 2}, 200: {1, 2}}, {200: 2})
        self.assertEqual((200, 2), model.deciding_group(1, 2, state, {}))

    def test_shared_negative_subgroup_skips_group(self):
        state = groups({1083: {-2110711, -2110712}, 2110711: {572391, 572396}, 2110712: {578311}}, {1083: 4})
        self.assertIsNone(model.deciding_group(572391, 572396, state, {}))
        self.assertEqual((1083, 4), model.deciding_group(572391, 578311, state, {}))

    def test_different_family_without_rule_stacks(self):
        self.assertEqual('stacks', model.pair_outcome(buff(1, 20), buff(2, 21), groups({}), {}))
        self.assertEqual('family', model.pair_outcome(buff(1, 20), buff(2, 20), groups({}), {}))

    def test_rule_names(self):
        state = groups({10: {1, 2}, 11: {3, 4}, 12: {5, 6}}, {10: 2, 11: 3, 12: 4})
        self.assertEqual('per_caster', model.pair_outcome(buff(1, 20), buff(2, 21), state, {}))
        self.assertEqual('same_effect', model.pair_outcome(buff(3, 20), buff(4, 21), state, {}))
        self.assertEqual('highest', model.pair_outcome(buff(5, 20), buff(6, 21), state, {}))


class PlanTests(unittest.TestCase):
    def existing(self):
        return groups({2110001: {300857}, 2110004: {803651}, 1083: {-2110710}, 2110710: {300255},
                       2110711: {572391}, 2110712: {578311}, 2110713: {800196}, 2112508: {1}},
                      {2110001: 1, 2110004: 1, 1083: 4, 2112508: 4})

    def plan(self, buffs, exceptions=None, manual=None, state=None):
        return model.plan_categories(buffs, state or self.existing(), {}, exceptions or {}, manual or {})

    def test_same_signature_two_families_forms_category(self):
        first = buff(10, 19, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        second = buff(11, 22, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        plan = self.plan([first, second])
        self.assertEqual({2113001: frozenset({'resistance:4'})},
                         {key: value for key, value in plan.categories.items() if key >= 2113001})
        self.assertEqual({10, 11}, plan.members[2113001])

    def test_new_category_ids_follow_sorted_signatures(self):
        buffs = [buff(10, 19, aura('SPELL_AURA_MOD_RESISTANCE', 8)), buff(11, 22, aura('SPELL_AURA_MOD_RESISTANCE', 8)),
                 buff(12, 19, aura('SPELL_AURA_MOD_RESISTANCE', 4)), buff(13, 22, aura('SPELL_AURA_MOD_RESISTANCE', 4))]
        plan = self.plan(buffs)
        self.assertEqual(frozenset({'resistance:4'}), plan.categories[2113001])
        self.assertEqual(frozenset({'resistance:8'}), plan.categories[2113002])

    def test_one_family_signature_is_listed_not_grouped(self):
        buffs = [buff(10, 19, aura('SPELL_AURA_MOD_RESISTANCE', 4)), buff(11, 19, aura('SPELL_AURA_MOD_RESISTANCE', 4))]
        plan = self.plan(buffs)
        self.assertNotIn(2113001, plan.categories)
        self.assertEqual([10, 11], plan.single_class[frozenset({'resistance:4'})])

    def test_existing_category_reused_and_members_kept(self):
        current = buff(300857, 23, aura('SPELL_AURA_MOD_STAT', 0))
        newcomer = buff(20, 30, aura('SPELL_AURA_MOD_STAT', 1))
        other = buff(21, 31, aura('SPELL_AURA_MOD_STAT', 1))
        plan = self.plan([current, newcomer, other])
        self.assertEqual(frozenset({'stat:1'}), plan.categories[2110001])
        self.assertEqual({300857, 20, 21}, plan.members[2110001])
        self.assertTrue(any('300857' in line for line in plan.mismatches))

    def test_existing_category_takes_one_family_signature(self):
        state = groups({2110001: {300857}}, {2110001: 1})
        current = buff(300857, 23, aura('SPELL_AURA_MOD_STAT', 1))
        newcomer = buff(20, 30, aura('SPELL_AURA_MOD_STAT', 1))
        plan = self.plan([current, newcomer], state=state)
        self.assertEqual({300857, 20}, plan.members[2110001])

    def test_exception_excluded(self):
        armor = (aura('SPELL_AURA_MOD_RESISTANCE', 1), aura('SPELL_AURA_MOD_STAT', -1))
        plan = self.plan([buff(803651, 29, *armor), buff(523495, 25, *armor), buff(30, 27, *armor)],
                         exceptions={523495: 'live logs'})
        self.assertEqual(frozenset({'armor', 'stat:all'}), plan.categories[2110004])
        self.assertEqual({803651, 30}, plan.members[2110004])

    def test_intellect_only_goes_to_1083(self):
        plan = self.plan([buff(40, 33, aura('SPELL_AURA_MOD_STAT', 3)), buff(41, 33, aura('SPELL_AURA_MOD_STAT', 3)),
                          buff(300255, 20, aura('SPELL_AURA_MOD_STAT', 3))])
        self.assertEqual({2110714: {40, 41}}, plan.intellect_subgroups)
        self.assertNotIn(frozenset({'stat:3'}), plan.categories.values())

    def test_intellect_with_other_stat_is_own_category(self):
        effects = (aura('SPELL_AURA_MOD_STAT', 3), aura('SPELL_AURA_MOD_STAT', 4))
        plan = self.plan([buff(50, 19, *effects), buff(51, 22, *effects)])
        self.assertEqual(frozenset({'stat:3', 'stat:4'}), plan.categories[2113001])
        self.assertEqual({}, plan.intellect_subgroups)

    def test_manual_decision_overrides_signature(self):
        scripted = buff(60, 19, aura('SPELL_AURA_DUMMY'))
        dropped = buff(61, 22, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        partner = buff(62, 24, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        plan = self.plan([scripted, dropped, partner], manual={60: frozenset({'resistance:4'}), 61: None})
        self.assertEqual({60, 62}, plan.members[2113001])

    def test_unclassified_without_decision_is_listed(self):
        plan = self.plan([buff(70, 19, aura('SPELL_AURA_DUMMY'))])
        self.assertEqual([70], plan.unclassified)

    def test_apply_plan_adds_members_and_rules(self):
        buffs = [buff(10, 19, aura('SPELL_AURA_MOD_RESISTANCE', 4)), buff(11, 22, aura('SPELL_AURA_MOD_RESISTANCE', 4)),
                 buff(40, 33, aura('SPELL_AURA_MOD_STAT', 3))]
        state = self.existing()
        after = model.apply_plan(state, self.plan(buffs))
        self.assertEqual({10, 11}, after.members[2113001])
        self.assertEqual(1, after.rules[2113001])
        self.assertEqual('CoA class buffs: resistance:4', after.descriptions[2113001])
        self.assertIn(-2110714, after.members[1083])
        self.assertEqual({40}, after.members[2110714])
        self.assertNotIn(2113001, state.members)


if __name__ == '__main__':
    unittest.main()
