from bisect import bisect_left
import math
import random
import unittest

from behaviours import behaviour_scenario
from compare import judge_behaviour
from kinds.proc_gate_interval import edge_reading
from profile import DBC_DIR
import run
from test_behaviours import FakeRun, base_verdict

ECLIPSE = 811117
ECLIPSE_HIT = 802717
LEECH = 803287
POTION = 801661
INGREDIENT = 801664
HEX = 801693
CLASS_FILE = {'class_id': 13, 'name': 'Witch Doctor', 'race': 1, 'level': 60, 'skill_lines': [],
              'reference_stats': {}}
ENTRY = {'spell': INGREDIENT, 'name': 'Ingredient: Bloodthistle (Potion leech once every 0.5 sec)',
         'kind': 'proc_gate_interval', 'label_suffix': 'gate', 'quote': 'Can only occur once every 0.5 sec.',
         'gate_ms': 500, 'learn': [92085, INGREDIENT, POTION],
         'setup_casts': [[INGREDIENT, 'caster'], [POTION, 'caster']], 'trigger_casts': [[ECLIPSE, 'dummy']],
         'cast_auras': [[561136, 5]], 'cast_power': 2000, 'cast_wait_ms': 1600, 'control_ms': 1400, 'windows': 4,
         'window_ms': 1400, 'since_spell': ECLIPSE,
         'trigger': {'stream': 'spell_damage', 'spell': ECLIPSE_HIT, 'target': 'dummy'},
         'output': {'stream': 'spell_heal', 'spell': LEECH, 'target': 'caster'}, 'amount_pct': 5,
         'cause_auras': [[802975, POTION]], 'fixture': {'spell_power': 2000, 'ranged_hit_rating': 10000}}
WARDS = {'spell': 807450, 'name': 'Hexfire Mass (Serpent Ward once every 3 sec)', 'kind': 'proc_gate_interval',
         'label_suffix': 'gate', 'quote': 'Can only occur once every 3 sec.', 'gate_ms': 3000, 'learn': [HEX],
         'talent': 807450, 'forced_talent': 807450,
         'trigger_casts': [[HEX, 'dummy'], [HEX, 'dummy2'], [HEX, 'dummy3'], [HEX, 'dummy4']], 'cast_power': 2000,
         'cast_wait_ms': 2250, 'control_ms': 1000, 'windows': 1, 'window_casts': False, 'window_ms': 12500,
         'since_spell': HEX, 'trigger': {'stream': 'spell_damage', 'spell': HEX},
         'output': {'event': 'spawn', 'source_entry': 50587}, 'dummies': 4}
FAIR = (5, 3, 250.0, 500.0, 500.0)
EDGE = (5, 2, 250.0, 750.0, 750.0)
LEECH_GATE = {**ENTRY, 'windows': 7, 'window_ms': 100, 'cast_auras': [[561136, 3]]}
WARD_TALENT = 807450
LEAD_WARDS = {**WARDS, 'cast_wait_ms': 2020, 'control_ms': 935, 'window_ms': 6150,
              'lead_targets': ['dummy', 'dummy2', 'dummy3']}
LATE_MS = 25
STEP_MS = 3
SEEDS = range(200)
HEX_PERIOD = 3000
HEX_DURATION = 24000
ECLIPSE_PERIOD = 250
ECLIPSE_HIT_AMOUNT = 75.0
INGREDIENT_WAIT_MS = 1600
POTION_WAIT_MS = 1600
DB_WORK = 0.2
STEP_MODELS = ({}, {'db_work': DB_WORK}, {'lanes': True}, {'lanes': True, 'db_work': DB_WORK})
SPLASH = 802712
SPIRIT = 561136
MISSILE_YD_PER_S = 25.0
MISSILE_MIN_YD = 5.0
POTION_MS = 15000
REACHES = (0.389, 1.5, 2.0)
EDGE_SEEDS = range(60)
LANE_SEEDS = range(1000)
EDGE_GATE = {'spell': INGREDIENT, 'name': 'Ingredient: Bloodthistle (Potion leech once every 0.5 sec)',
             'kind': 'proc_gate_interval', 'variant': 'gate', 'label_suffix': 'gate',
             'quote': 'Can only occur once every 0.5 sec.', 'gate_ms': 500, 'learn': [92085, INGREDIENT, POTION],
             'setup_casts': [[INGREDIENT, 'caster'], [POTION, 'caster']], 'trigger_casts': [[ECLIPSE, 'dummy2']],
             'cast_auras': [[SPIRIT, 3]], 'cast_power': 2000, 'cast_wait_ms': 1600, 'control_ms': 1400,
             'windows': 21, 'window_ms': 100, 'since_spell': ECLIPSE,
             'trigger': {'stream': 'spell_damage', 'spell': ECLIPSE_HIT, 'target': 'dummy2'},
             'output': {'stream': 'spell_heal', 'spell': LEECH, 'target': 'caster'}, 'amount_pct': 5,
             'cause_auras': [[802975, POTION]], 'cause_every': 7, 'dummies': 2, 'dummy_step_yd': 2.0,
             'edge_streams': [{'stream': 'spell_damage', 'spell': SPLASH, 'target': 'dummy'},
                              {'stream': 'spell_damage', 'spell': ECLIPSE_HIT, 'target': 'dummy2'}],
             'edge_hits': 3, 'relocate_yd': [-6.6, -0.18],
             'fixture': {'spell_power': 2000, 'ranged_hit_rating': 10000, 'spell_hit_rating': 10000}}


def gate_values(expectation, windows, control=(5, 0), amount=75.0, released=None) -> dict:
    model = expectation.model
    values, triggers, outputs = {}, 0.0, 0.0

    def edge(labels: dict, side: str):
        values[labels[f'{side} triggers']], values[labels[f'{side} outputs']] = triggers, outputs
        if f'{side} amount' in labels:
            values[labels[f'{side} amount']] = triggers * amount

    edge(model['control'], 'start')
    triggers, outputs = triggers + control[0], outputs + control[1]
    edge(model['control'], 'end')
    for labels, (fired, answered, trigger_gap, shortest, longest) in zip(model['windows'], windows):
        edge(labels, 'start')
        triggers, outputs = triggers + fired, outputs + answered
        edge(labels, 'end')
        values[labels['trigger gap max']] = trigger_gap
        values[labels['output gap min']], values[labels['output gap max']] = shortest, longest
    if model['released']:
        values[model['released']] = 0.0 if released is None else released
    return values


def counted(stamps, moment) -> float:
    return float(sum(1 for stamp in stamps if stamp <= moment))


def interval_reads(stamps, since=None) -> tuple[float, float, float]:
    kept = sorted(stamp for stamp in stamps if since is None or stamp >= since)
    gaps = [after - before for before, after in zip(kept, kept[1:])]
    first = float(kept[0] - since) if kept and since is not None else math.nan
    return first, float(min(gaps)) if gaps else math.nan, float(max(gaps)) if gaps else math.nan


def gated(triggers, gate, opened) -> list[int]:
    outputs = []
    for stamp in sorted(triggers):
        if stamp > opened and (not outputs or stamp - outputs[-1] >= gate):
            outputs.append(stamp)
    return outputs


def step_times(steps, rng=None, db_work=0.0, lanes=False) -> tuple[list[int], list[int]]:
    now, updates, times = 0, [0], []
    for step in steps:
        times.append(now)
        if step['action'] != 'wait':
            now += STEP_MS * (2 if rng is not None and rng.random() < db_work else 1)
            updates.append(now)
            continue
        left = step['ms']
        while left > 0:
            size = min(left, rng.randint(STEP_MS, LATE_MS) if lanes else LATE_MS)
            now, left = now + size, left - size
            updates.append(now)
    return times, updates


def stamped(updates, due) -> int | None:
    index = bisect_left(updates, due)
    return updates[index] if index < len(updates) else None


def ward_run(scenario, gate, seed=0, **model) -> dict:
    steps = scenario['steps']
    times, updates = step_times(steps, random.Random(seed) if model else None, **model)
    casts = [(times[index], step['target']) for index, step in enumerate(steps) if step['action'] == 'cast']
    learned = next(times[index] for index, step in enumerate(steps)
                   if step['action'] == 'learn' and step['spell'] == WARD_TALENT)
    hits = {target: [cast] + [stamp for stamp in (stamped(updates, cast + tick * HEX_PERIOD)
                                                  for tick in range(1, HEX_DURATION // HEX_PERIOD + 1)) if stamp]
            for cast, target in casts}
    spawns = gated([stamp for stamps in hits.values() for stamp in stamps[1:]], gate, learned)
    reads = {step['label']: times[index] for index, step in enumerate(steps) if step['action'] == 'assert'}
    return {'casts': casts, 'learned': learned, 'hits': hits, 'spawns': spawns, 'reads': reads, 'updates': updates}


def ward_values(expectation, scenario, gate, seed=0, **model) -> dict:
    simulated = ward_run(scenario, gate, seed, **model)
    hits, spawns, latest = simulated['hits'], simulated['spawns'], simulated['casts'][-1][0]
    union = sorted(stamp for stamps in hits.values() for stamp in stamps)
    values = {expectation.model['released']: 0.0}
    for labels in [expectation.model['control']] + expectation.model['windows']:
        for read, label in labels.items():
            moment = simulated['reads'][label]
            seen_spawns = [stamp for stamp in spawns if stamp <= moment]
            if read.endswith('triggers'):
                values[label] = counted(union, moment)
            elif read.endswith('outputs'):
                values[label] = float(len(seen_spawns))
            elif read == 'trigger gap max':
                values[label] = interval_reads([stamp for stamp in union if stamp <= moment], latest)[2]
            elif read in ('output gap min', 'output gap max'):
                values[label] = interval_reads(seen_spawns)[1 if read.endswith('min') else 2]
            elif read == 'lead output first':
                values[label] = float(seen_spawns[0]) if seen_spawns else math.nan
            elif read == 'lead cast first':
                values[label] = float(latest)
            else:
                target, gap = read.removeprefix('lead ').split(' ', 1)
                stamps = [stamp for stamp in hits[target] if stamp <= moment]
                values[label] = interval_reads(stamps, latest)[('first gap', 'min gap', 'max gap').index(gap)]
    return values


def leech_values(expectation, seed, gate, per_hit=False) -> dict:
    rng = random.Random(seed)
    constant = rng.randrange(LATE_MS)
    model = expectation.model
    spirits = LEECH_GATE['cast_auras'][0][1]

    def eclipse(cast: int) -> list[int]:
        return [cast + hit * ECLIPSE_PERIOD + (rng.randrange(LATE_MS) if per_hit else constant)
                for hit in range(1, spirits + 1)]

    control_hits = eclipse(0)
    opened = LEECH_GATE['cast_wait_ms'] + LEECH_GATE['control_ms'] + INGREDIENT_WAIT_MS
    cast = opened + POTION_WAIT_MS
    windows = []
    for _ in model['windows']:
        cast += rng.randint(3, 15)
        windows.append((cast, eclipse(cast), cast + LEECH_GATE['cast_wait_ms'] + LEECH_GATE['window_ms']))
        cast = windows[-1][2]
    hits = control_hits + [stamp for _, stamps, _ in windows for stamp in stamps]
    heals = gated(hits, gate, opened)
    control = model['control']
    values = {control['start triggers']: 0.0, control['start outputs']: 0.0, control['start amount']: 0.0,
              control['end triggers']: counted(hits, opened), control['end outputs']: counted(heals, opened),
              control['end amount']: counted(hits, opened) * ECLIPSE_HIT_AMOUNT}
    start = opened
    for labels, (cast, stamps, end) in zip(model['windows'], windows):
        for side, moment in (('start', start), ('end', end)):
            values[labels[f'{side} triggers']] = counted(hits, moment)
            values[labels[f'{side} outputs']] = counted(heals, moment)
            values[labels[f'{side} amount']] = counted(hits, moment) * ECLIPSE_HIT_AMOUNT
        values[labels['trigger gap max']] = interval_reads(stamps, cast)[2]
        _, values[labels['output gap min']], values[labels['output gap max']] = interval_reads(
            [stamp for stamp in heals if stamp <= end], cast)
        start = end
    return values


def previous_update(updates, moment) -> int:
    return updates[max(bisect_left(updates, moment) - 1, 0)]


def edge_run(scenario, gate, seed=0, reach=1.5, late_order=False, **model) -> dict:
    steps = scenario['steps']
    rng = random.Random(seed)
    times, updates = step_times(steps, rng if model else None, **model)
    distance = {creature['id']: creature['distance'] for creature in scenario['creatures']}
    shift, splashes, hits, casts, potions = 0.0, [], [], [], []
    for index, step in enumerate(steps):
        if step['action'] == 'relocate':
            shift += step['dx']
        if step['action'] != 'cast':
            continue
        if step['spell'] == POTION:
            potions.append(times[index])
        if step['spell'] != ECLIPSE:
            continue
        cast = times[index]
        casts.append(cast)
        flight = math.floor(max(distance[step['target']] - shift - reach, MISSILE_MIN_YD) / MISSILE_YD_PER_S * 1000)
        origin = previous_update(updates, cast) if late_order else cast
        for tick in range(1, 4):
            stamp = stamped(updates, origin + tick * ECLIPSE_PERIOD)
            splashes.append(stamp)
            hits.append(stamped(updates, (previous_update(updates, stamp) if late_order else stamp) + flight))
    heals, opened = [], potions[0]
    for stamp, _ in sorted([(stamp, 0) for stamp in splashes] + [(stamp, 1) for stamp in hits]):
        active = any(potion <= stamp < potion + POTION_MS for potion in potions)
        if active and stamp > opened and (not heals or stamp - heals[-1] >= gate):
            heals.append(stamp)
    reads = {step['label']: times[index] for index, step in enumerate(steps) if step['action'] == 'assert'}
    return {'splashes': splashes, 'hits': hits, 'heals': heals, 'casts': casts, 'potions': potions, 'reads': reads}


def edge_values(expectation, scenario, gate, seed=0, **model) -> dict:
    simulated = edge_run(scenario, gate, seed, **model)
    streams = {'edge 0': simulated['splashes'], 'edge 1': simulated['hits'], 'output': simulated['heals']}
    values = {}
    for labels in [expectation.model['control']] + expectation.model['windows']:
        for read, label in labels.items():
            moment = simulated['reads'][label]
            if read.endswith('triggers'):
                values[label] = counted(simulated['hits'], moment)
            elif read.endswith('outputs'):
                values[label] = counted(simulated['heals'], moment)
            elif read.endswith('amount'):
                values[label] = counted(simulated['hits'], moment) * ECLIPSE_HIT_AMOUNT
            elif read.endswith(('start', 'end')):
                values[label] = counted(streams[read.rsplit(' ', 1)[0]], moment)
            else:
                parts = read.split(' ')
                cut = 2 if parts[0] == 'edge' else 1
                since = max(cast for cast in simulated['casts'] if cast <= moment)
                kept = [stamp for stamp in streams[' '.join(parts[:cut])] if stamp <= moment]
                position = ('first', 'gap min', 'gap max').index(' '.join(parts[cut:]))
                values[label] = interval_reads(kept, since)[position]
    return values


@unittest.skipUnless(DBC_DIR.is_dir(), f'server DBC set not found at {DBC_DIR}')
class ProcGateIntervalTests(unittest.TestCase):
    def judged(self, windows=(FAIR,) * 4, entry=ENTRY, **values):
        _, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        return judge_behaviour(base_verdict(expectation), FakeRun(gate_values(expectation, windows, **values)),
                               expectation)

    def test_the_control_round_comes_before_the_potion_and_the_windows_after(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, ENTRY)
        run.validate(scenario, run.SIMULATED_CLOCK)
        casts = [step['spell'] for step in scenario['steps'] if step['action'] == 'cast']
        self.assertEqual(casts, [ECLIPSE, INGREDIENT, POTION] + [ECLIPSE] * 4)
        self.assertEqual(scenario['players'][0]['spell_power'], 2000)

    def test_a_gate_pinned_by_an_accepted_and_a_refused_edge_hit_passes(self):
        verdict = self.judged(windows=(FAIR, EDGE, FAIR, EDGE))
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('a trigger 500 ms after an output was refused and an output followed the previous one after '
                      '500 ms, so the edge trigger was refused once and accepted once: the gate sits on the edge at '
                      '500 ms, inside 475 to 525 ms', verdict.explanation)
        self.assertNotIn('excluding', verdict.explanation)

    def test_a_bracket_inside_the_band_passes_with_the_excluded_gates_stated(self):
        verdict = self.judged(windows=(FAIR, (5, 2, 250.0, 730.0, 730.0), FAIR, FAIR))
        self.assertEqual(verdict.status, 'ok')
        self.assertIn('the gate lies above 480 ms (a trigger that late was refused) and at most 500 ms (the shortest '
                      'output interval): the bracket 480 to 500 ms lies inside 475 to 525 ms, excluding a gate at or '
                      'below 480 ms and one above 500 ms', verdict.explanation)

    def test_a_bracket_wider_than_the_band_is_unmeasured_with_the_bracket_stated(self):
        accepted = self.judged()
        self.assertEqual(accepted.status, 'unmeasured')
        self.assertIn('250 to 500 ms reaches outside 475 to 525 ms', accepted.explanation)
        refused = self.judged(windows=(EDGE,) * 4)
        self.assertEqual(refused.status, 'unmeasured')
        self.assertIn('500 to 750 ms reaches outside', refused.explanation)

    def test_near_mutants_at_three_fifths_and_seven_fifths_of_the_gate_do_not_pass(self):
        self.assertNotEqual(self.judged(windows=(FAIR,) * 4).status, 'ok')
        self.assertNotEqual(self.judged(windows=(EDGE,) * 4).status, 'ok')

    def test_the_mutant_without_a_gate_alerts(self):
        verdict = self.judged(windows=((5, 5, 250.0, 250.0, 250.0),) * 4)
        self.assertEqual(verdict.status, 'alert')
        self.assertEqual(verdict.measured, 250.0)

    def test_the_mutant_with_a_doubled_gate_alerts(self):
        self.assertEqual(self.judged(windows=((5, 2, 250.0, 1000.0, 1000.0),) * 4).status, 'alert')

    def test_an_output_in_the_control_alerts(self):
        self.assertEqual(self.judged(control=(5, 1)).status, 'alert')

    def test_a_missing_release_read_is_a_missing_measurement(self):
        _, [expectation] = behaviour_scenario(CLASS_FILE, WARDS)
        values = gate_values(expectation, ((20, 5, 750.0, 3000.0, 3750.0),), control=(9, 0))
        del values[expectation.model['released']]
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertIn('no measurement', verdict.explanation)
        self.assertIn('released', verdict.explanation)

    def test_a_leech_that_rounds_to_nothing_is_unmeasured(self):
        self.assertEqual(self.judged(amount=15.0).status, 'unmeasured')

    def test_triggers_wider_than_the_window_are_unmeasured(self):
        self.assertEqual(self.judged(windows=((3, 2, 500.0, 500.0, 500.0),) * 4).status, 'unmeasured')

    def test_a_single_output_per_window_is_unmeasured(self):
        self.assertEqual(self.judged(windows=((5, 1, 250.0, float('nan'), float('nan')),) * 4).status,
                         'unmeasured')

    def test_a_cause_aura_that_lapses_before_the_last_window_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**ENTRY, 'windows': 5})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {key: value for key, value in ENTRY.items() if key != 'cause_auras'})

    def test_the_eclipse_hits_cannot_miss(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, ENTRY)
        self.assertEqual(scenario['players'][0]['ranged_hit_rating'], 10000)

    def test_a_wait_shorter_than_the_global_cooldown_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**ENTRY, 'cast_wait_ms': 1000})

    def test_the_ward_timeline_starts_before_the_hexes_and_the_talent_follows_them(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, WARDS)
        run.validate(scenario, run.SIMULATED_CLOCK)
        actions = [(step['action'], step.get('spell')) for step in scenario['steps']]
        self.assertLess(actions.index(('encounter_start', None)), actions.index(('cast', HEX)))
        self.assertLess(actions.index(('spell_mod_mutant', 807450)), actions.index(('cast', HEX)))
        self.assertGreater(actions.index(('learn', 807450)), max(index for index, action in enumerate(actions)
                                                                 if action == ('cast', HEX)))
        self.assertEqual(len(scenario['creatures']), 4)

    def test_ward_spawns_three_to_four_ticks_apart_pass_and_a_kept_mutant_alerts(self):
        windows = ((20, 5, 750.0, 3000.0, 3750.0),)
        self.assertEqual(self.judged(windows=windows, entry=WARDS, control=(9, 0)).status, 'ok')
        self.assertEqual(self.judged(windows=windows, entry=WARDS, control=(9, 0), released=1.0).status, 'alert')
        self.assertEqual(self.judged(windows=((20, 20, 750.0, 750.0, 750.0),), entry=WARDS,
                                     control=(9, 0)).status, 'alert')

    def test_ward_gates_three_fifths_and_seven_fifths_of_the_stated_one_alert(self):
        self.assertEqual(self.judged(windows=((17, 6, 750.0, 2250.0, 2250.0),), entry=WARDS,
                                     control=(9, 0)).status, 'alert')
        self.assertEqual(self.judged(windows=((17, 3, 750.0, 4500.0, 4500.0),), entry=WARDS,
                                     control=(9, 0)).status, 'alert')

    def test_ward_gates_off_the_tick_edge_are_unmeasured(self):
        self.assertEqual(self.judged(windows=((17, 5, 750.0, 3000.0, 3000.0),), entry=WARDS,
                                     control=(9, 0)).status, 'unmeasured')
        self.assertEqual(self.judged(windows=((17, 4, 750.0, 3750.0, 3750.0),), entry=WARDS,
                                     control=(9, 0)).status, 'unmeasured')

    def test_a_window_past_the_hex_duration_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**WARDS, 'window_ms': 20000})

    def ward_verdicts(self, gate, entry=LEAD_WARDS, **model) -> list:
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, entry)
        return [judge_behaviour(base_verdict(expectation),
                                FakeRun(ward_values(expectation, scenario, gate, seed, **model)), expectation)
                for seed in (SEEDS if model else [0])]

    def leech_verdicts(self, gate, **jitter) -> list:
        _, [expectation] = behaviour_scenario(CLASS_FILE, LEECH_GATE)
        return [judge_behaviour(base_verdict(expectation), FakeRun(leech_values(expectation, seed, gate, **jitter)),
                                expectation) for seed in SEEDS]

    def test_the_lead_ward_schedule_learns_the_talent_between_the_lead_tick_and_the_first_spawn(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, LEAD_WARDS)
        run.validate(scenario, run.SIMULATED_CLOCK)
        self.assertEqual(expectation.model['lead']['since_target'], 'dummy4')
        reads = {step['label'] for step in scenario['steps'] if step['action'] == 'assert'}
        self.assertTrue(set(expectation.model['windows'][0].values()) <= reads)
        simulated = ward_run(scenario, 3000)
        casts = {target: cast for cast, target in simulated['casts']}
        latest = casts['dummy4']
        window_start = simulated['reads'][expectation.model['windows'][0]['start outputs']]
        self.assertEqual([cast - latest for cast in casts.values()], [-6087, -4058, -2029, 0])
        self.assertGreaterEqual(simulated['learned'] - (casts['dummy'] + 3 * HEX_PERIOD + LATE_MS), 20)
        self.assertGreaterEqual(latest + HEX_PERIOD - window_start, 20)
        self.assertEqual(simulated['spawns'][:3], simulated['hits']['dummy4'][1:4])

    def test_the_lead_ward_schedule_closes_inside_the_band_under_the_documented_step_model(self):
        for model in ({}, {'db_work': DB_WORK}):
            for verdict in self.ward_verdicts(3000, **model):
                self.assertEqual(verdict.status, 'ok', (model, verdict.explanation))
                self.assertEqual(verdict.measured, 3000.0)
                self.assertGreaterEqual(verdict.detail['reopened_by_ms'], 2850.0)
                self.assertIn('a lead tick', verdict.explanation)

    def test_a_full_step_of_spread_and_lateness_on_the_lead_dummy_keeps_the_bound_in_the_band(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, LEAD_WARDS)
        values = ward_values(expectation, scenario, 3000)
        window = expectation.model['windows'][0]
        values[window['lead dummy first gap']] -= LATE_MS - 1
        values[window['lead dummy min gap']] -= LATE_MS
        verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
        self.assertEqual(verdict.status, 'ok', verdict.explanation)
        self.assertGreaterEqual(verdict.detail['reopened_by_ms'], 2850.0)

    def test_a_lead_tick_needs_the_first_output_and_must_fall_before_the_shortest_output_interval(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, LEAD_WARDS)
        window = expectation.model['windows'][0]
        for label, shift in ((window['lead output first'], math.nan), (window['lead dummy max gap'], 100.0)):
            values = ward_values(expectation, scenario, 3000)
            values[label] += shift
            verdict = judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)
            self.assertEqual(verdict.status, 'unmeasured', verdict.explanation)
            self.assertNotIn('a lead tick 2900', verdict.explanation)

    def test_seeded_ward_gates_ten_percent_off_never_read_ok(self):
        for gate in (2700, 3300):
            for model in STEP_MODELS:
                for verdict in self.ward_verdicts(gate, **model):
                    self.assertNotEqual(verdict.status, 'ok', (gate, model, verdict.explanation))

    def test_jittered_steps_never_make_the_stated_ward_gate_alert(self):
        for model in STEP_MODELS[2:]:
            statuses = {verdict.status for verdict in self.ward_verdicts(3000, **model)}
            self.assertLessEqual(statuses, {'ok', 'unmeasured'}, model)

    def test_lead_targets_need_a_timeline_output_and_the_latest_cast_outside_them(self):
        for targets in (['dummy', 'dummy4'], ['dummy', 'dummy5'], ['dummy', 'dummy']):
            with self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, {**LEAD_WARDS, 'lead_targets': targets})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**LEAD_WARDS, 'window_casts': True})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**LEAD_WARDS, 'trigger_casts': LEAD_WARDS['trigger_casts'][:3]
                                            + [[HEX, 'dummy']]})

    def test_three_spirit_eclipse_windows_never_close_or_alert_for_the_stated_leech_gate(self):
        for per_hit in (False, True):
            for verdict in self.leech_verdicts(500, per_hit=per_hit):
                self.assertEqual(verdict.status, 'unmeasured', (per_hit, verdict.explanation))

    def test_seeded_leech_gates_ten_percent_off_never_read_ok_and_a_missing_gate_alerts(self):
        for gate in (450, 550):
            for per_hit in (False, True):
                for verdict in self.leech_verdicts(gate, per_hit=per_hit):
                    self.assertNotEqual(verdict.status, 'ok', (gate, per_hit, verdict.explanation))
        self.assertEqual({verdict.status for verdict in self.leech_verdicts(1)}, {'alert'})

    def edge_verdicts(self, gate, seeds=None, reach=1.5, late_order=False, **model) -> list:
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, EDGE_GATE)
        chosen = seeds if seeds is not None else (EDGE_SEEDS if model else [0])
        return [judge_behaviour(base_verdict(expectation),
                                FakeRun(edge_values(expectation, scenario, gate, seed, reach=reach,
                                                    late_order=late_order, **model)), expectation)
                for seed in chosen]

    def test_the_edge_schedule_renews_the_potion_and_sweeps_the_caster_back(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, EDGE_GATE)
        run.validate(scenario, run.SIMULATED_CLOCK)
        steps = scenario['steps']
        casts = [step['spell'] for step in steps if step['action'] == 'cast']
        self.assertEqual(casts[:4], [ECLIPSE, INGREDIENT, POTION, ECLIPSE])
        self.assertEqual(casts.count(POTION), 3)
        self.assertEqual(casts.count(ECLIPSE), 22)
        self.assertEqual([creature['distance'] for creature in scenario['creatures']], [3.0, 5.0])
        relocations = [step['dx'] for step in steps if step['action'] == 'relocate']
        self.assertEqual(len(relocations), 21)
        self.assertAlmostEqual(sum(relocations), -10.2)
        self.assertEqual(scenario['players'][0]['spell_hit_rating'], 10000)
        times, _ = step_times(steps)
        potions = [times[index] for index, step in enumerate(steps)
                   if step['action'] == 'cast' and step['spell'] == POTION]
        reads = {step['label']: times[index] for index, step in enumerate(steps) if step['action'] == 'assert'}
        for window in expectation.model['windows']:
            moment = reads[window['end outputs']]
            latest = max(potion for potion in potions if potion <= moment)
            self.assertLess(moment - latest, POTION_MS)
        self.assertEqual(expectation.model['edges'], {'streams': 2, 'hits': 3})
        self.assertTrue(set(expectation.model['windows'][0].values()) <= set(reads))

    def test_the_stated_leech_gate_closes_on_exact_edges_in_every_step_model(self):
        for model in STEP_MODELS:
            for late_order in (False, True):
                for verdict in self.edge_verdicts(500, late_order=late_order, **model):
                    self.assertEqual(verdict.status, 'ok', (model, late_order, verdict.explanation))
                    self.assertGreaterEqual(verdict.detail['reopened_by_ms'], 475.0)
                    self.assertLessEqual(verdict.measured, 525.0)

    def test_the_stated_leech_gate_closes_for_any_caster_combat_reach(self):
        for reach in REACHES:
            for model in ({}, {'lanes': True}):
                for verdict in self.edge_verdicts(500, seeds=range(20) if model else None, reach=reach, **model):
                    self.assertEqual(verdict.status, 'ok', (reach, model, verdict.explanation))

    def test_exact_edges_on_a_regular_grid_refuse_at_475_and_answer_at_500(self):
        [verdict] = self.edge_verdicts(500, seeds=[0])
        self.assertEqual((verdict.detail['reopened_by_ms'], verdict.measured), (475.0, 500.0))
        self.assertIn('the bracket 475 to 500 ms lies inside 475 to 525 ms', verdict.explanation)

    def test_the_stated_leech_gate_closes_in_a_thousand_lane_seeds_per_update_order(self):
        for late_order in (False, True):
            for seed, verdict in zip(LANE_SEEDS, self.edge_verdicts(500, seeds=LANE_SEEDS, late_order=late_order,
                                                                    lanes=True)):
                self.assertEqual(verdict.status, 'ok', (seed, late_order, verdict.explanation))
                self.assertGreaterEqual(verdict.detail['reopened_by_ms'], 475.0)
                self.assertLessEqual(verdict.measured, 525.0)

    def test_the_refused_probe_is_the_exact_first_missile_hit(self):
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, EDGE_GATE)
        values = edge_values(expectation, scenario, 500)
        probes = []
        for window in expectation.model['windows']:
            read = {name: values.get(label) for name, label in window.items()}
            reading = edge_reading(read, expectation.model)
            if reading.get('lower') == 475.0:
                probes.append(read['edge 1 first'] - read['output first'])
        self.assertTrue(probes)
        self.assertEqual(set(probes), {475.0})

    def test_a_missile_flies_at_least_five_yards(self):
        scenario, _ = behaviour_scenario(CLASS_FILE, {**EDGE_GATE, 'relocate_yd': [3.0, 0.0]})
        simulated = edge_run(scenario, 500)
        flights = {hit - splash for splash, hit in zip(simulated['splashes'], simulated['hits'])}
        self.assertEqual(flights, {200})

    def test_an_unpaired_edge_window_names_the_read_that_failed(self):
        model = {'edges': {'streams': 1, 'hits': 2}}
        paired = {'start triggers': 0.0, 'end triggers': 2.0, 'start outputs': 0.0, 'end outputs': 2.0,
                  'edge 0 start': 0.0, 'edge 0 end': 2.0, 'edge 0 first': 10.0, 'edge 0 gap min': 500.0,
                  'edge 0 gap max': 500.0, 'output first': 10.0, 'output gap min': 500.0, 'output gap max': 500.0}
        self.assertNotIn('why', edge_reading(paired, model))
        for change, why in (({'edge 0 gap max': 510.0}, 'shortest and longest intervals differ (500 and 510 ms)'),
                            ({'edge 0 gap min': math.nan}, 'first event and intervals are not all finite'),
                            ({'edge 0 end': 1.0}, 'drew 1 events, not 2'),
                            ({'end outputs': 1.0}, '1 outputs, fewer than two'),
                            ({'output gap min': math.nan}, 'output intervals are not all finite'),
                            ({'output gap max': 510.0}, 'output intervals differ (500 and 510 ms)')):
            self.assertIn(why, edge_reading({**paired, **change}, model).get('why', ''), change)

    def test_seeded_edge_gates_ten_percent_off_never_read_ok(self):
        for gate in (450, 550):
            for model in STEP_MODELS:
                for late_order in (False, True):
                    for verdict in self.edge_verdicts(gate, seeds=range(20) if model else None,
                                                      late_order=late_order, **model):
                        self.assertNotEqual(verdict.status, 'ok', (gate, model, late_order, verdict.explanation))

    def test_a_missing_or_short_leech_gate_alerts_on_exact_edges(self):
        for gate in (1, 400, 450):
            [verdict] = self.edge_verdicts(gate)
            self.assertEqual(verdict.status, 'alert', (gate, verdict.explanation))
            self.assertLess(verdict.measured, 475.0)

    def test_jittered_steps_never_make_the_stated_leech_gate_alert_on_exact_edges(self):
        for model in STEP_MODELS[2:]:
            for late_order in (False, True):
                statuses = {verdict.status for verdict in self.edge_verdicts(500, reach=0.389, late_order=late_order,
                                                                             **model)}
                self.assertLessEqual(statuses, {'ok', 'unmeasured'}, (model, late_order))

    def edge_window_verdict(self, change) -> object:
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, EDGE_GATE)
        values = edge_values(expectation, scenario, 500)
        change(values, expectation.model['windows'][4])
        return judge_behaviour(base_verdict(expectation), FakeRun(values), expectation)

    def test_a_first_output_that_is_not_the_first_trigger_is_unmeasured(self):
        def shift(values, window):
            values[window['output first']] += 1.0
        verdict = self.edge_window_verdict(shift)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('is not the first trigger', verdict.explanation)

    def test_a_lost_edge_hit_is_unmeasured(self):
        def lose(values, window):
            values[window['edge 1 end']] -= 1.0
        verdict = self.edge_window_verdict(lose)
        self.assertEqual(verdict.status, 'unmeasured')
        self.assertIn('edge stream 1 drew 2 events, not 3', verdict.explanation)

    def test_crossing_edge_bounds_are_unmeasured(self):
        def cross(values, window):
            values[window['output gap min']] = values[window['output gap max']] = \
                values[window['edge 1 first']] + values[window['edge 1 gap min']] + values[window['edge 1 gap max']] \
                - values[window['output first']]
        verdict = self.edge_window_verdict(cross)
        self.assertNotEqual(verdict.status, 'ok', verdict.explanation)

    def test_a_middle_hit_that_may_be_the_second_output_bounds_nothing(self):
        def straddle(values, window):
            opened = values[window['output first']]
            closed = opened + values[window['output gap min']]
            values[window['edge 1 gap max']] = closed - values[window['edge 1 first']]
        scenario, [expectation] = behaviour_scenario(CLASS_FILE, EDGE_GATE)
        values = edge_values(expectation, scenario, 500)
        straddle(values, expectation.model['windows'][0])
        window = {read: values.get(label) for read, label in expectation.model['windows'][0].items()}
        reading = edge_reading(window, expectation.model)
        opened, closed = window['output first'], window['output first'] + window['output gap min']
        middle = window['edge 1 first'] + window['edge 1 gap min']
        self.assertNotIn('why', reading)
        self.assertNotEqual(reading['lower'], middle - opened)
        self.assertLess(reading['lower'], closed - opened)

    def test_edge_streams_need_hits_one_cast_per_window_and_an_event_output(self):
        for change in ({'edge_hits': 4}, {'edge_hits': 0}, {'trigger_casts': [[ECLIPSE, 'dummy2'], [ECLIPSE, 'dummy']]},
                       {'output': {'event': 'spawn', 'source_entry': 50587}, 'windows': 1},
                       {'edge_streams': [{'stream': 'spell_damage', 'spell': SPLASH}]}):
            with self.assertRaises(ValueError):
                behaviour_scenario(CLASS_FILE, {**EDGE_GATE, **change})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**LEECH_GATE, 'relocate_yd': [-0.5, -0.1]})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**LEECH_GATE, 'edge_hits': 3})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**EDGE_GATE, 'cause_every': 0})

    def test_a_potion_renewed_too_late_is_refused(self):
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {**EDGE_GATE, 'cause_every': 8})
        with self.assertRaises(ValueError):
            behaviour_scenario(CLASS_FILE, {key: value for key, value in EDGE_GATE.items() if key != 'cause_every'})
