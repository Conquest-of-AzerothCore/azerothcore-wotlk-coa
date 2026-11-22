import struct
import tempfile
import unittest
from pathlib import Path

import coa_class_buffs as model
from coa_class_buffs import Buff, Effect, Groups


def aura(name, misc=0, target='TARGET_UNIT_TARGET_ALLY'):
    return Effect('SPELL_EFFECT_APPLY_AURA', name, misc, 1, target, 'TARGET_NONE', 0)


def buff(spell_id, family, *effects):
    return Buff(spell_id, f'Spell {spell_id}', family, tuple(effects))


def persistent_buff(spell_id, family, *effects):
    return Buff(spell_id, f'Spell {spell_id}', family, tuple(effects), True)


def groups(members, rules=None):
    return Groups({key: set(value) for key, value in members.items()}, dict(rules or {}), {})


class SignatureTests(unittest.TestCase):
    def test_every_listed_aura_name_exists(self):
        known = set(model.enum_values('AuraType'))
        listed = set(model.STAT_KEYS) | model.IGNORED_AURAS | model.NON_STAT_AURAS
        self.assertEqual(set(), listed - known)

    def test_aura_lists_do_not_overlap(self):
        self.assertEqual(set(), set(model.STAT_KEYS) & model.NON_STAT_AURAS)
        self.assertEqual(set(), set(model.STAT_KEYS) & model.IGNORED_AURAS)
        self.assertEqual(set(), model.IGNORED_AURAS & model.NON_STAT_AURAS)

    def test_flat_attack_power_gives_melee_and_ranged(self):
        flat = buff(1, 24, aura('SPELL_AURA_ASCENSION_MOD_ATTACK_POWER_FLAT'),
                    aura('SPELL_AURA_ASCENSION_MOD_SPELL_POWER_FLAT', 127))
        self.assertEqual(frozenset({'ap:melee', 'ap:ranged', 'spell_power:127'}), model.signature(flat))

    def test_hit_chance_and_cost_keys(self):
        self.assertEqual(frozenset({'hit:all'}),
                         model.signature(buff(1, 22, aura('SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT'))))
        self.assertEqual(frozenset({'cost_pct:127'}),
                         model.signature(buff(1, 19, aura('SPELL_AURA_MOD_POWER_COST_SCHOOL_PCT', 127))))

    def test_non_stat_effects_do_not_change_signature(self):
        plain = buff(1, 20, aura('SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE', 32))
        shielded = buff(1, 20, aura('SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE', 32), aura('SPELL_AURA_DAMAGE_SHIELD', 32))
        self.assertEqual(model.signature(plain), model.signature(shielded))

    def test_only_non_stat_effects_is_not_a_stat_buff(self):
        heal = buff(1, 20, aura('SPELL_AURA_PERIODIC_HEAL'), aura('SPELL_AURA_PROC_TRIGGER_SPELL'))
        self.assertEqual(frozenset(), model.signature(heal))

    def test_dummy_without_stat_is_unclassified_next_to_non_stat_effect(self):
        self.assertIsNone(model.signature(buff(1, 20, aura('SPELL_AURA_DUMMY'), aura('SPELL_AURA_PERIODIC_HEAL'))))

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
        unknown = aura('SPELL_AURA_OVERRIDE_CLASS_SCRIPTS')
        self.assertIsNone(model.signature(buff(1, 20, aura('SPELL_AURA_MOD_STAT', 1), unknown)))

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

    def test_honor_group_joins_cross_class_category(self):
        honor = buff(1, 24, aura('SPELL_AURA_MOD_STAT', 0))
        rite = buff(90, 36, aura('SPELL_AURA_MOD_STAT', 0))
        plan = self.plan([honor, rite])
        self.assertEqual(frozenset({'stat:0'}), plan.categories[2113001])
        self.assertEqual({1, 90}, plan.members[2113001])

    def test_recorded_decisions(self):
        grace = frozenset({'regen:0'})
        self.assertEqual({800852: grace, 300858: grace, 681160: grace},
                         {key: value for key, value in model.MANUAL.items() if value is not None})
        for timed in (300679, 504157, 704476, 804859, 804990, 806197, 502442, 800234, 805417, 806123):
            self.assertIsNone(model.MANUAL[timed])
        for passive in (300929, 300944, 560545, 300515, 504348, 804705):
            self.assertNotIn(passive, model.MANUAL)
        self.assertEqual(frozenset({model.INTELLECT_GROUP}), model.LEFT_ALONE_GROUPS)

    def test_decision_on_first_rank_covers_every_rank(self):
        first = buff(63, 26, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        higher = buff(64, 26, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        partner = buff(65, 24, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        other = buff(66, 22, aura('SPELL_AURA_MOD_RESISTANCE', 4))
        plan = model.plan_categories([first, higher, partner, other], self.existing(), {64: 63}, {}, {63: None})
        self.assertEqual({65, 66}, plan.members[2113001])

    def test_later_rank_with_another_stat_does_not_move_its_chain(self):
        first = buff(63, 26, aura('SPELL_AURA_MOD_RESISTANCE', 8))
        higher = buff(64, 26, aura('SPELL_AURA_MOD_RESISTANCE', 16))
        partners = [buff(65, 24, aura('SPELL_AURA_MOD_RESISTANCE', 16)), buff(66, 22, aura('SPELL_AURA_MOD_RESISTANCE', 16))]
        plan = model.plan_categories([first, higher, *partners], self.existing(), {64: 63}, {}, {})
        self.assertEqual([{65, 66}], [members for members in plan.members.values() if 65 in members])
        self.assertIn('64 (rank of 63) gives resistance:16, first rank gives resistance:8', plan.mismatches)

    def test_unclassified_without_decision_is_listed(self):
        plan = self.plan([buff(70, 19, aura('SPELL_AURA_DUMMY'))])
        self.assertEqual([70], plan.unclassified)

    def test_non_stat_buffs_get_no_category(self):
        heals = [buff(80, 19, aura('SPELL_AURA_PERIODIC_HEAL')), buff(81, 22, aura('SPELL_AURA_PERIODIC_HEAL'))]
        plan = self.plan(heals)
        self.assertEqual({}, {key: value for key, value in plan.members.items() if 80 in value or 81 in value})
        self.assertEqual([], plan.unclassified)
        self.assertEqual({}, plan.single_class)

    def test_auras_leave_a_category_with_timed_buffs(self):
        crit = aura('SPELL_AURA_MOD_CRIT_PCT')
        buffs = [buff(10, 19, crit), buff(11, 22, crit), persistent_buff(12, 20, crit), persistent_buff(13, 21, crit)]
        plan = self.plan(buffs)
        self.assertEqual({10, 11}, plan.members[2113001])
        self.assertEqual({12, 13}, plan.members[2113002])
        self.assertEqual(plan.categories[2113001], plan.categories[2113002])
        self.assertEqual({2113002}, plan.auras)

    def test_aura_categories_follow_every_timed_category(self):
        crit, fire = aura('SPELL_AURA_MOD_CRIT_PCT'), aura('SPELL_AURA_MOD_RESISTANCE', 4)
        buffs = [buff(10, 19, crit), buff(11, 22, crit), persistent_buff(12, 20, crit), persistent_buff(13, 21, crit),
                 buff(14, 19, fire), buff(15, 22, fire)]
        plan = self.plan(buffs)
        self.assertEqual({10, 11}, plan.members[2113001])
        self.assertEqual({14, 15}, plan.members[2113002])
        self.assertEqual({12, 13}, plan.members[2113003])

    def test_lone_aura_beside_timed_buffs_gets_no_category(self):
        fire = aura('SPELL_AURA_MOD_RESISTANCE', 4)
        plan = self.plan([buff(10, 19, fire), buff(11, 22, fire), persistent_buff(12, 20, fire)])
        self.assertEqual({10, 11}, plan.members[2113001])
        self.assertEqual(set(), plan.auras)
        self.assertNotIn(12, set().union(*plan.members.values()))

    def test_one_family_auras_beside_timed_buffs_are_listed(self):
        fire = aura('SPELL_AURA_MOD_RESISTANCE', 4)
        plan = self.plan([buff(10, 19, fire), buff(11, 22, fire), persistent_buff(12, 20, fire),
                          persistent_buff(13, 20, fire)])
        self.assertEqual(set(), plan.auras)
        self.assertEqual([12, 13], plan.single_class[frozenset({'resistance:4', 'aura'})])

    def test_auras_keep_the_id_when_the_timed_buff_stands_alone(self):
        shadow, fire = aura('SPELL_AURA_MOD_RESISTANCE', 32), aura('SPELL_AURA_MOD_RESISTANCE', 64)
        plan = self.plan([buff(10, 25, shadow), persistent_buff(11, 20, shadow), persistent_buff(12, 21, shadow),
                          buff(13, 19, fire), buff(14, 22, fire)])
        self.assertEqual({11, 12}, plan.members[2113001])
        self.assertEqual({2113001}, plan.auras)
        self.assertEqual({13, 14}, plan.members[2113002])
        self.assertEqual([10], plan.single_class[frozenset({'resistance:32'})])

    def test_signature_with_only_auras_keeps_one_category(self):
        fire = aura('SPELL_AURA_MOD_RESISTANCE', 4)
        plan = self.plan([persistent_buff(12, 20, fire), persistent_buff(13, 21, fire)])
        self.assertEqual({12, 13}, plan.members[2113001])
        self.assertEqual({2113001}, plan.auras)

    def test_aura_stays_out_of_an_existing_timed_category(self):
        state = groups({2110001: {300857}}, {2110001: 1})
        agility = aura('SPELL_AURA_MOD_STAT', 1)
        plan = self.plan([buff(300857, 23, agility), persistent_buff(20, 30, agility),
                          persistent_buff(21, 31, agility)], state=state)
        self.assertEqual({300857}, plan.members[2110001])
        self.assertEqual({20, 21}, plan.members[2113001])
        self.assertEqual({2113001}, plan.auras)

    def test_apply_plan_names_aura_categories(self):
        crit = aura('SPELL_AURA_MOD_CRIT_PCT')
        buffs = [buff(10, 19, crit), buff(11, 22, crit), persistent_buff(12, 20, crit), persistent_buff(13, 21, crit)]
        after = model.apply_plan(self.existing(), self.plan(buffs))
        self.assertTrue(after.descriptions[2113001].startswith('CoA class buffs: '))
        self.assertTrue(after.descriptions[2113002].startswith('CoA class auras: '))
        self.assertEqual(1, after.rules[2113002])

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


def area(name, misc=0, effect='SPELL_EFFECT_APPLY_AREA_AURA_RAID'):
    return Effect(effect, name, misc, 1, 'TARGET_UNIT_CASTER', 'TARGET_NONE', 0)


def self_aura(name, misc=0):
    return aura(name, misc, 'TARGET_UNIT_CASTER')


def trigger(spell_id):
    return Effect('SPELL_EFFECT_TRIGGER_SPELL', 'SPELL_AURA_NONE', 0, 0, 'TARGET_UNIT_CASTER', 'TARGET_NONE',
                  spell_id)


def record(family, *effects, passive=False, name='Spell', duration_index=0):
    return model.Record(name, family, model.PASSIVE_ATTRIBUTE if passive else 0, tuple(effects), duration_index)


class SelectionTests(unittest.TestCase):
    def test_every_listed_target_and_effect_name_exists(self):
        self.assertEqual(set(), model.ALLIED_TARGETS - set(model.enum_values('Targets')))
        self.assertEqual(set(), (model.AREA_AURA_EFFECTS | {model.APPLY_AURA}) - set(model.enum_values('SpellEffects')))

    def test_selection_rules(self):
        records = {
            1: record(20, aura('SPELL_AURA_MOD_STAT', 1)),
            2: record(10, aura('SPELL_AURA_MOD_STAT', 1)),
            3: record(20, self_aura('SPELL_AURA_MOD_STAT', 1)),
            4: record(20, aura('SPELL_AURA_MOD_STAT', 1), passive=True),
            5: record(20, aura('SPELL_AURA_MOD_STAT', 1)),
            6: record(21, area('SPELL_AURA_MOD_ATTACK_POWER_PCT', 0), passive=True),
            7: record(22, aura('SPELL_AURA_MOD_STAT', 1, 'TARGET_UNIT_CASTER_AREA_RAID')),
            8: record(23, area('SPELL_AURA_MOD_STAT', 1, 'SPELL_EFFECT_APPLY_AREA_AURA_PARTY')),
            9: record(24, area('SPELL_AURA_MOD_STAT', 1, 'SPELL_EFFECT_PERSISTENT_AREA_AURA')),
        }
        selected = model.select_buffs(records, {1, 2, 3, 4, 6, 7, 8, 9})
        self.assertEqual([1, 6, 7, 8], [buff.spell_id for buff in selected])

    def test_signature_uses_only_effects_that_reach_others(self):
        dark_aura = record(21, area('SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE', 32),
                           self_aura('SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE', 2), passive=True)
        void = record(31, area('SPELL_AURA_MOD_RESISTANCE_EXCLUSIVE', 32), passive=True)
        selected = model.select_buffs({1: dark_aura, 2: void}, {1, 2})
        self.assertEqual([frozenset({'resistance:32'})] * 2, [model.signature(buff) for buff in selected])

    def test_passive_and_endless_buffs_are_persistent(self):
        records = {1: record(20, area('SPELL_AURA_MOD_CRIT_PCT'), passive=True),
                   2: record(20, area('SPELL_AURA_MOD_CRIT_PCT'), duration_index=21),
                   3: record(20, area('SPELL_AURA_MOD_CRIT_PCT'), duration_index=30),
                   4: record(20, aura('SPELL_AURA_MOD_CRIT_PCT'))}
        selected = model.select_buffs(records, {1, 2, 3, 4}, frozenset({21}))
        self.assertEqual([True, True, False, False], [buff.persistent for buff in selected])

    def test_spell_dbc_row_keeps_its_duration(self):
        row = {'ID': 10, 'Name_Lang_enUS': 'Override', 'SpellClassSet': 25, 'Attributes': 0, 'DurationIndex': 21,
               'Effect_1': 6, 'EffectAura_1': 29, 'EffectMiscValue_1': 2, 'EffectBasePoints_1': 9}
        self.assertEqual(21, model.apply_overrides({}, [row])[10].duration_index)

    def test_triggered_spell_inherits_learnability(self):
        records = {1: record(20, trigger(2)), 2: record(20, trigger(3)), 3: record(20, aura('SPELL_AURA_MOD_STAT', 1)),
                   4: record(20, aura('SPELL_AURA_MOD_STAT', 1))}
        self.assertEqual({1, 2, 3}, model.learnable_spells({1}, set(), records))

    def test_higher_rank_of_learnable_spell_is_learnable(self):
        records = {1: record(20), 2: record(20)}
        self.assertEqual({1, 2, 5}, model.learnable_spells(set(), {1, 5}, records, {2: 1}))

    def test_spell_dbc_row_replaces_dbc_effects(self):
        records = {10: record(25, aura('SPELL_AURA_MOD_STAT', 1))}
        row = {'ID': 10, 'Name_Lang_enUS': 'Override', 'SpellClassSet': 25, 'Attributes': 0,
               'Effect_1': 6, 'EffectAura_1': 29, 'EffectMiscValue_1': 2, 'EffectBasePoints_1': 9,
               'ImplicitTargetA_1': 21, 'ImplicitTargetB_1': 0, 'EffectTriggerSpell_1': 0}
        for index in (2, 3):
            row.update({f'Effect_{index}': 0, f'EffectAura_{index}': 0, f'EffectMiscValue_{index}': 0,
                        f'EffectBasePoints_{index}': 0, f'ImplicitTargetA_{index}': 0,
                        f'ImplicitTargetB_{index}': 0, f'EffectTriggerSpell_{index}': 0})
        result = model.apply_overrides(records, [row])
        selected = model.select_buffs(result, {10})
        self.assertEqual('Override', result[10].name)
        self.assertEqual(frozenset({'stat:2'}), model.signature(selected[0]))
        self.assertEqual(frozenset({'stat:1'}), model.signature(model.select_buffs(records, {10})[0]))


class PendingFileTests(unittest.TestCase):
    def test_later_file_touching_a_migrated_group_is_reported(self):
        with tempfile.TemporaryDirectory() as folder:
            pending = Path(folder)
            (pending / 'rev_1795_buffs.sql').write_text('DELETE FROM `spell_group` WHERE `id` IN (2110001);\n',
                                                        encoding='utf-8')
            (pending / 'rev_20261009_50_old.sql').write_text('(2110001, 300857),\n', encoding='utf-8')
            (pending / 'rev_20261009_51_other.sql').write_text('(1083, -1082),\n', encoding='utf-8')
            self.assertEqual(['rev_20261009_50_old.sql'],
                             model.files_after_migration(pending, 'rev_1795_buffs.sql', {2110001}))

    def test_committed_class_buff_migrations_sort_last(self):
        pending = model.ROOT / 'data' / 'sql' / 'updates' / 'pending_db_world'
        for name in ('rev_20261122_01_coa_class_buff_cross_class_categories.sql',
                     'rev_20261122_02_coa_class_buff_greater_pairs.sql'):
            with self.subTest(name=name):
                groups = model.migration_groups(pending / name)
                self.assertTrue({2110001, 2113001} <= groups or {2106090, 2106096} <= groups)
                self.assertEqual([], model.files_after_migration(pending, name, groups))

    def test_unapplied_pending_world_file_reported(self):
        with tempfile.TemporaryDirectory() as folder:
            pending = Path(folder)
            for name in ('rev_1.sql', 'rev_2.sql', 'create_sql.sh', '.dummy'):
                (pending / name).write_text('', encoding='utf-8')
            self.assertEqual(['rev_2.sql'], model.pending_world_files_applied({'rev_1.sql'}, pending))


class RankChainTests(unittest.TestCase):
    known = {10, 11, 12, 13, 20, 30, 31, 40, 41, 42}

    def test_client_chain_wins_over_a_table_chain_that_reuses_its_rank(self):
        client = [(10, 10, 1), (10, 11, 2), (10, 12, 3)]
        result = model.rank_chains(client, [(20, 20, 1), (20, 12, 2)], self.known)
        self.assertEqual(10, result[12])
        self.assertNotIn(20, result)

    def test_table_extends_a_client_chain(self):
        client = [(10, 10, 1), (10, 11, 2)]
        table = [(10, 10, 1), (10, 11, 2), (10, 12, 3), (10, 13, 4)]
        self.assertEqual({10: 10, 11: 10, 12: 10, 13: 10}, model.rank_chains(client, table, self.known))

    def test_shorter_table_chain_keeps_the_client_chain(self):
        client = [(10, 10, 1), (10, 11, 2), (10, 12, 3)]
        self.assertEqual(10, model.rank_chains(client, [(10, 10, 1), (10, 11, 2)], self.known)[12])

    def test_table_adds_chains_the_client_lacks(self):
        self.assertEqual({30: 30, 31: 30}, model.rank_chains([], [(30, 30, 1), (30, 31, 2)], self.known))

    def test_broken_chains_are_skipped(self):
        client = [(40, 40, 1), (40, 42, 3)]
        table = [(30, 30, 1), (30, 99, 2)]
        self.assertEqual({}, model.rank_chains(client, table, self.known))

    def test_spell_rank_rows_read_from_client_file(self):
        rows = [(1, 10, 10, 1), (2, 10, 11, 2)]
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'SpellRank.dbc'
            payload = b'WDBC' + struct.pack('<4I', len(rows), 4, 16, 1)
            payload += b''.join(struct.pack('<4I', *row) for row in rows) + b'\0'
            path.write_bytes(payload)
            self.assertEqual([(10, 10, 1), (10, 11, 2)], model.spell_rank_rows(path))


class OutputTests(unittest.TestCase):
    def state(self):
        return Groups({2110001: {300857}, 1083: {-2110710}, 2110710: {300255}},
                      {2110001: 1, 1083: 4}, {2110001: 'Strength', 1083: "Intellect, 'highest'"})

    def buffs(self):
        return [buff(300857, 23, aura('SPELL_AURA_MOD_STAT', 1)), buff(20, 30, aura('SPELL_AURA_MOD_STAT', 1)),
                buff(21, 30, aura('SPELL_AURA_MOD_STAT', 1)), buff(30, 19, area('SPELL_AURA_MOD_RESISTANCE', 4)),
                buff(31, 22, aura('SPELL_AURA_MOD_RESISTANCE', 4)), buff(40, 33, aura('SPELL_AURA_MOD_STAT', 3))]

    def plan(self):
        return model.plan_categories(self.buffs(), self.state(), {}, {}, {})

    def test_migration_sql_keeps_first_ranks_only(self):
        state = self.state()
        state.members[2110001].add(300886)
        sql = model.migration_sql(self.plan(), state, {300886: 300857})
        self.assertIn('(2110001, 300857)', sql)
        self.assertNotIn('300886', sql)

    def test_review_lists_pairs_a_lower_group_decides(self):
        state = self.state()
        state.members[5] = {300857, 20}
        state.rules[5] = 3
        plan = model.plan_categories(self.buffs(), state, {}, {}, {})
        text = model.review_markdown(self.buffs(), plan, state, model.apply_plan(state, plan), {}, [])
        section = text.split('## Decided by a lower group')[1].split('\n## ')[0]
        self.assertIn('| 2110001 | Spell 20 (20, family 30) | Spell 300857 (300857, family 23) | same_effect 5 |',
                      section)
        self.assertNotIn('Spell 21 (21, family 30) |', section)

    def test_migration_sql_shape(self):
        sql = model.migration_sql(self.plan(), self.state(), {})
        lines = sql.splitlines()
        self.assertTrue(sql.endswith('\n'))
        self.assertTrue(all(len(line) <= 120 for line in lines))
        group_delete = 'DELETE FROM `spell_group` WHERE `id` IN (1083, 2110001, 2110711, 2113001);'
        rule_delete = 'DELETE FROM `spell_group_stack_rules` WHERE `group_id` IN (1083, 2110001, 2113001);'
        self.assertIn(group_delete, lines)
        self.assertIn(rule_delete, lines)
        self.assertLess(lines.index(group_delete), lines.index(rule_delete))
        self.assertIn('INSERT INTO `spell_group` (`id`, `spell_id`) VALUES', lines)
        self.assertIn('INSERT INTO `spell_group_stack_rules` (`group_id`, `stack_rule`, `description`) VALUES', lines)
        self.assertIn('(1083, 4, \'Intellect, \\\'highest\\\'\'),', lines)
        self.assertIn("(2113001, 1, 'CoA class buffs: resistance:4');", lines)
        member_rows = [line for line in lines if line.startswith('(') and "'" not in line]
        self.assertEqual(['(1083, -2110711),', '(1083, -2110710),', '(2110001, 20),', '(2110001, 21),',
                          '(2110001, 300857),', '(2110711, 40),', '(2113001, 30),', '(2113001, 31);'], member_rows)

    def test_review_lists_changed_pairs(self):
        before = self.state()
        plan = self.plan()
        after = model.apply_plan(before, plan)
        text = model.review_markdown(self.buffs(), plan, before, after, {}, plan.unclassified)
        self.assertIn('| Spell 20 (20, family 30) | Spell 300857 (300857, family 23) | stacks | exclusive 2110001 |', text)
        self.assertIn('| Spell 20 (20, family 30) | Spell 21 (21, family 30) | family | exclusive 2110001 | same-class |',
                      text)
        self.assertNotIn('| Spell 300857 (300857, family 23) | Spell 40', text)

    def test_review_flags_area_aura_next_to_cast_buff(self):
        before = self.state()
        plan = self.plan()
        text = model.review_markdown(self.buffs(), plan, before, model.apply_plan(before, plan), {}, [])
        self.assertIn('2113001', text.split('## Area auras next to cast buffs')[1].split('##')[0])


if __name__ == '__main__':
    unittest.main()
