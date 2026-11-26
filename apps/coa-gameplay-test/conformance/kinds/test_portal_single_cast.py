import unittest

from behaviours import behaviour_scenario
from coverage import BEHAVIOUR, BY_METRIC, EVENT, EVIDENCE, METRIC_EVIDENCE, metric_evidence, verdict_evidence
from kinds.portal_single_cast import (KIND, METRIC, control_label, portal_single_cast_spec,
                                      portal_single_cast_verdict, trial_label)
from profile import DBC_DIR, load_class_file
import run
from test_behaviours import FakeRun, base_verdict

APOCALYPTIC_ENTRY = {
    'spell': 301200, 'kind': KIND, 'variant': 'portal_single_cast', 'label_suffix': 'portal_single_cast',
    'name': 'Apocalyptic Skies (portal casts once from allowed set and disappears)',
    'quote': 'before disappearing.',
    'gate_spell': 301200, 'trigger_spell': 504904, 'learn': [504904, 500110, 800416, 805572],
    'entry': 533030, 'allowed_spells': [500110, 800416, 805572],
    'phase_auras': [[500706, 60, 'caster', 'caster'], [680601, 1, 'caster', 'caster'], [823764, 1, 'caster', 'caster']],
    'cast_power': 2000, 'cast_read_ms': 4000, 'direct_despawn_ms': 5000, 'direct_despawn_check_ms': 6200,
    'lifetime_ms': 12000, 'portals': 6, 'parts': 2}

SUNDERER_ENTRY = {
    **APOCALYPTIC_ENTRY, 'spell': 301068, 'gate_spell': 301068, 'quote_spell': 301988,
    'name': 'Sunderer of Realities (portal casts once from allowed set and disappears)',
    'setup_casts': [504904], 'setup_wait_ms': 3200, 'cancel_before_trial': [301067]}

DEPTHS_ENTRY = {
    'spell': 706911, 'kind': KIND, 'variant': 'portal_single_cast', 'label_suffix': 'portal_single_cast',
    'name': 'Depths of Madness (portal casts once from allowed set and disappears)',
    'quote': 'before disappearing',
    'gate_spell': 706911, 'trigger_spell': 500110, 'learn': [500110, 800416, 805572],
    'entry': 533030, 'allowed_spells': [500110, 800416, 805572],
    'phase_auras': [[823764, 1, 'caster', 'caster']],
    'cast_power': 2000, 'cast_read_ms': 4000, 'direct_despawn_ms': 5000, 'direct_despawn_check_ms': 6200,
    'lifetime_ms': 12000, 'portals': 3, 'parts': 4, 'feed': {'every_ms': 1700}}

CHANNELED_ENTRY = {
    **APOCALYPTIC_ENTRY, 'allowed_spells': [500110, 800416, 800432],
    'channeled_despawn_ms': 10000, 'channeled_despawn_check_ms': 10800}


def scenario_of(entry: dict):
    return behaviour_scenario(load_class_file(25), entry)


def seeded_runs(model: dict, chosen_cycle: list[int], overrides: dict | None = None) -> list[FakeRun]:
    parts = int(model['parts'])
    allowed = [int(spell) for spell in model['allowed_spells']]
    channeled = {int(spell) for spell in model['channeled_spells']}
    runs = []
    idx = 0
    for part in range(parts):
        values = {model['control']['count']: 0.0, model['control']['summons']: 0.0}
        cum_total = 0.0
        cum_spells = {spell: 0.0 for spell in allowed}
        for trial in model['trials']:
            chosen = chosen_cycle[idx % len(chosen_cycle)]
            idx += 1
            values[trial['pre']] = 0.0
            values[trial['pre_total']] = cum_total
            for spell in allowed:
                values[trial['pre_spells'][str(spell)]] = cum_spells[spell]
            values[trial['spawned']] = 1.0
            values[trial['alive']] = 1.0
            values[trial['total']] = 1.0
            for spell in allowed:
                values[trial['spells'][str(spell)]] = 1.0 if spell == chosen else 0.0
            values[trial['after_direct']] = 1.0 if chosen in channeled else 0.0
            if 'after_channeled' in trial:
                values[trial['after_channeled']] = 0.0
            cum_total += 1.0
            cum_spells[chosen] += 1.0
            values[trial['post_total']] = cum_total
            for spell in allowed:
                values[trial['post_spells'][str(spell)]] = cum_spells[spell]
        if overrides and part in overrides:
            values.update(overrides[part])
        runs.append(FakeRun(values))
    return runs


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class PortalSingleCastTests(unittest.TestCase):
    def test_generates_valid_scenarios_for_deterministic_setup_feed_and_channeled(self):
        for entry, expect_feed, expect_channeled in (
                (APOCALYPTIC_ENTRY, False, False),
                (SUNDERER_ENTRY, False, False),
                (DEPTHS_ENTRY, True, False),
                (CHANNELED_ENTRY, False, True)):
            with self.subTest(spell=entry['spell'], channeled=expect_channeled):
                scenario, [exp] = scenario_of(entry)
                validated = run.validate(scenario)
                steps = validated['steps']
                loops = [step for step in steps if step['action'] == 'cast_until_owned_creature']
                self.assertEqual(bool(loops), expect_feed)
                if expect_feed:
                    self.assertEqual(len(loops), 1 + entry['portals'])
                self.assertEqual('after_channeled' in exp.model['trials'][0], expect_channeled)
                totals = [step for step in steps if step.get('metric') == METRIC]
                per_trial = 3 * (1 + len(entry['allowed_spells']))
                self.assertEqual(len(totals), entry['portals'] * per_trial)
                self.assertTrue(all(step.get('triggered') is False for step in totals))
                cumulative = [step for step in totals if step.get('cumulative') is True]
                self.assertEqual(len(cumulative), entry['portals'] * 2 * (1 + len(entry['allowed_spells'])))

    def test_evidence_class_is_event_and_counts_as_behaviour(self):
        self.assertNotIn(METRIC, METRIC_EVIDENCE)
        self.assertEqual(metric_evidence()[METRIC], EVENT)
        _, [exp] = scenario_of(APOCALYPTIC_ENTRY)
        verdict = portal_single_cast_verdict(base_verdict(exp),
                                             seeded_runs(exp.model, [500110, 800416, 805572]), exp.model)
        self.assertEqual(verdict.status, 'ok')
        self.assertEqual(verdict.detail['metric'], METRIC)
        self.assertEqual(EVIDENCE[verdict.check], BY_METRIC)
        self.assertEqual(verdict_evidence(verdict, APOCALYPTIC_ENTRY['quote'], {}), BEHAVIOUR)

    def test_seeded_ok_for_direct_and_channeled_despawn_branches(self):
        _, [exp] = scenario_of(APOCALYPTIC_ENTRY)
        verdict = portal_single_cast_verdict(base_verdict(exp),
                                             seeded_runs(exp.model, [500110, 800416, 805572]), exp.model)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertEqual(verdict.detail['observed'], 12)
        self.assertEqual(verdict.detail['spells'], {500110: 4, 800416: 4, 805572: 4})

        _, [chan_exp] = scenario_of(CHANNELED_ENTRY)
        chan_verdict = portal_single_cast_verdict(base_verdict(chan_exp),
                                                  seeded_runs(chan_exp.model, [500110, 800416, 800432]),
                                                  chan_exp.model)
        self.assertEqual(chan_verdict.status, 'ok', chan_verdict.explanation)
        self.assertEqual(chan_verdict.detail['spells'], {500110: 4, 800416: 4, 800432: 4})

    def test_mutant_wrong_allowed_set_or_missing_early_despawn_alerts(self):
        mutant_entry = {**APOCALYPTIC_ENTRY, 'allowed_spells': [500110, 800416]}
        _, [mutant_exp] = scenario_of(mutant_entry)
        runs = seeded_runs(mutant_exp.model, [500110, 800416],
                           {0: {mutant_exp.model['trials'][0]['spells']['500110']: 0.0,
                                mutant_exp.model['trials'][0]['spells']['800416']: 0.0,
                                mutant_exp.model['trials'][0]['total']: 1.0}})
        self.assertEqual(portal_single_cast_verdict(base_verdict(mutant_exp), runs, mutant_exp.model).status, 'alert')

        _, [exp] = scenario_of(APOCALYPTIC_ENTRY)
        no_despawn = seeded_runs(exp.model, [500110, 800416, 805572],
                                 {1: {exp.model['trials'][2]['after_direct']: 1.0}})
        self.assertEqual(portal_single_cast_verdict(base_verdict(exp), no_despawn, exp.model).status, 'alert')

    def test_mutant_second_cast_between_cast_read_and_despawn_alerts(self):
        _, [exp] = scenario_of(APOCALYPTIC_ENTRY)
        t0 = exp.model['trials'][0]
        for override in (
                {0: {t0['post_total']: 2.0, t0['post_spells']['500110']: 2.0}},
                {0: {t0['post_total']: 2.0, t0['post_spells']['800416']: 1.0}},
                {0: {t0['post_total']: 2.0}}):
            with self.subTest(branch='direct', override=override):
                runs = seeded_runs(exp.model, [500110, 800416, 805572], override)
                verdict = portal_single_cast_verdict(base_verdict(exp), runs, exp.model)
                self.assertEqual(verdict.status, 'alert')
                self.assertIn('full-lifetime', verdict.explanation)

        _, [chan_exp] = scenario_of(CHANNELED_ENTRY)
        ct = chan_exp.model['trials'][2]
        for override in (
                {0: {ct['post_total']: 4.0, ct['post_spells']['800432']: 2.0}},
                {0: {ct['post_total']: 4.0}}):
            with self.subTest(branch='channeled', override=override):
                runs = seeded_runs(chan_exp.model, [500110, 800416, 800432], override)
                verdict = portal_single_cast_verdict(base_verdict(chan_exp), runs, chan_exp.model)
                self.assertEqual(verdict.status, 'alert')
                self.assertIn('full-lifetime', verdict.explanation)

    def test_alerts_on_double_cast_zero_cast_control_leak_missing_spawn_or_channeled_lingering(self):
        _, [exp] = scenario_of(APOCALYPTIC_ENTRY)
        t0 = exp.model['trials'][0]
        cases = (
            {0: {t0['total']: 2.0, t0['spells']['500110']: 2.0}},
            {0: {t0['total']: 2.0, t0['spells']['500110']: 1.0}},
            {0: {t0['total']: 0.0, t0['spells']['500110']: 0.0}},
            {0: {t0['alive']: 0.0, t0['total']: -1.0}},
            {0: {t0['spawned']: 0.0}},
            {0: {t0['spawned']: 2.0}},
            {0: {control_label(exp.label, 'count'): 1.0}},
            {0: {control_label(exp.label, 'summons'): 1.0}},
        )
        for override in cases:
            with self.subTest(override=override):
                runs = seeded_runs(exp.model, [500110, 800416, 805572], override)
                self.assertEqual(portal_single_cast_verdict(base_verdict(exp), runs, exp.model).status, 'alert')

        _, [chan_exp] = scenario_of(CHANNELED_ENTRY)
        ct = chan_exp.model['trials'][2]
        lingering = seeded_runs(chan_exp.model, [500110, 800416, 800432], {0: {ct['after_channeled']: 1.0}})
        self.assertEqual(portal_single_cast_verdict(base_verdict(chan_exp), lingering, chan_exp.model).status, 'alert')
        direct_late = seeded_runs(chan_exp.model, [500110, 800416, 800432],
                                  {0: {chan_exp.model['trials'][0]['after_channeled']: 1.0}})
        self.assertEqual(portal_single_cast_verdict(base_verdict(chan_exp), direct_late, chan_exp.model).status,
                         'alert')

    def test_unmeasured_on_missing_read_feed_cap_leftover_or_missing_part(self):
        _, [exp] = scenario_of(APOCALYPTIC_ENTRY)
        runs = seeded_runs(exp.model, [500110, 800416, 805572])
        runs[0].values.pop(trial_label(exp.label, 1, 'total'))
        self.assertEqual(portal_single_cast_verdict(base_verdict(exp), runs, exp.model).status, 'unmeasured')

        missing_post = seeded_runs(exp.model, [500110, 800416, 805572])
        missing_post[0].values.pop(trial_label(exp.label, 1, 'post_total'))
        self.assertEqual(portal_single_cast_verdict(base_verdict(exp), missing_post, exp.model).status, 'unmeasured')

        decreased = seeded_runs(exp.model, [500110, 800416, 805572],
                                {0: {exp.model['trials'][1]['post_total']: 0.0}})
        self.assertEqual(portal_single_cast_verdict(base_verdict(exp), decreased, exp.model).status, 'unmeasured')

        leftover = seeded_runs(exp.model, [500110, 800416, 805572], {0: {exp.model['trials'][1]['pre']: 1.0}})
        self.assertEqual(portal_single_cast_verdict(base_verdict(exp), leftover, exp.model).status, 'unmeasured')

        few_parts = seeded_runs(exp.model, [500110, 800416, 805572])[:1]
        self.assertEqual(portal_single_cast_verdict(base_verdict(exp), few_parts, exp.model).status, 'unmeasured')

        _, [feed_exp] = scenario_of(DEPTHS_ENTRY)
        cap_hit = seeded_runs(feed_exp.model, [500110, 800416, 805572],
                              {0: {feed_exp.model['trials'][0]['spawned']: 0.0,
                                   feed_exp.model['trials'][0]['alive']: 0.0,
                                   feed_exp.model['trials'][0]['total']: -1.0}})
        self.assertEqual(portal_single_cast_verdict(base_verdict(feed_exp), cap_hit, feed_exp.model).status,
                         'unmeasured')

    def test_refuses_anecdote_bad_timings_missing_channeled_branch_and_bad_feed(self):
        for bad in (
                {**APOCALYPTIC_ENTRY, 'portals': 1, 'parts': 1},
                {**APOCALYPTIC_ENTRY, 'portals': 5, 'parts': 1},
                {**APOCALYPTIC_ENTRY, 'cast_read_ms': 6200},
                {**APOCALYPTIC_ENTRY, 'direct_despawn_check_ms': 11600},
                {**APOCALYPTIC_ENTRY, 'direct_despawn_check_ms': 4900},
                {**APOCALYPTIC_ENTRY, 'allowed_spells': [500110, 800432]},
                {**CHANNELED_ENTRY, 'channeled_despawn_check_ms': 11800},
                {**CHANNELED_ENTRY, 'channeled_despawn_check_ms': 6000},
                {**APOCALYPTIC_ENTRY, 'learn': [301200, 504904]},
                {**APOCALYPTIC_ENTRY, 'allowed_spells': [500110, 500110]},
                {**APOCALYPTIC_ENTRY, 'allowed_spells': [99999999]},
                {**SUNDERER_ENTRY, 'quote_spell': 500110},
                {**DEPTHS_ENTRY, 'gate_spell': 301200},
                {**DEPTHS_ENTRY, 'setup_casts': [500110]},
                {**DEPTHS_ENTRY, 'feed': {'every_ms': 1000}}):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                scenario_of(bad)
        self.assertEqual(portal_single_cast_spec(APOCALYPTIC_ENTRY).portals, 6)


if __name__ == '__main__':
    unittest.main()
