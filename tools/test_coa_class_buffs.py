import tempfile
import unittest
from pathlib import Path

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


def area(name, misc=0, effect='SPELL_EFFECT_APPLY_AREA_AURA_RAID'):
    return Effect(effect, name, misc, 1, 'TARGET_UNIT_CASTER', 'TARGET_NONE', 0)


def self_aura(name, misc=0):
    return aura(name, misc, 'TARGET_UNIT_CASTER')


def trigger(spell_id):
    return Effect('SPELL_EFFECT_TRIGGER_SPELL', 'SPELL_AURA_NONE', 0, 0, 'TARGET_UNIT_CASTER', 'TARGET_NONE',
                  spell_id)


def record(family, *effects, passive=False, name='Spell'):
    return model.Record(name, family, model.PASSIVE_ATTRIBUTE if passive else 0, tuple(effects))


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
    def test_unapplied_pending_world_file_reported(self):
        with tempfile.TemporaryDirectory() as folder:
            pending = Path(folder)
            for name in ('rev_1.sql', 'rev_2.sql', 'create_sql.sh', '.dummy'):
                (pending / name).write_text('', encoding='utf-8')
            self.assertEqual(['rev_2.sql'], model.pending_world_files_applied({'rev_1.sql'}, pending))


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

    def test_migration_sql_shape(self):
        sql = model.migration_sql(self.plan(), self.state())
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
