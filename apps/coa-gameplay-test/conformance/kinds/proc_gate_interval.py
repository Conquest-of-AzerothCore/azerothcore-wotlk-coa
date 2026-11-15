from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA, FORCED_CHANCE_PERCENT,
                        LEARNED_CONTRAST, OWN_CAST_CONTRAST, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms)
from bonus import bonus_band
from compare import CONTRAST, Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records, Unreadable
from values import DUMMY_ENTRY, Expectation, TARGET, dataset, facts_of, required_aura_steps

KIND = 'proc_gate_interval'
ORDER = 44

COUNT_METRICS = {'spell_damage': 'spell_damage_count', 'spell_heal': 'spell_heal_count',
                 'spell_energize': 'spell_energize_count'}
AMOUNT_METRICS = {'spell_damage': 'spell_damage_total', 'spell_heal': 'spell_heal_total'}
TIMELINE_EVENTS = frozenset({'spawn', 'cast', 'aura_applied'})
EVENT_GAP = {'min': 'event_interval_min_ms', 'max': 'event_interval_max_ms'}
TIMELINE_GAP = {'min': 'timeline_interval_min_ms', 'max': 'timeline_interval_max_ms'}
MAX_DUMMIES = 11
CAST_MARGIN_MS = 100
AURA_END_MARGIN_MS = 1000
MINIMUM_INTERVALS = 2
CONTROL = 'control'
WINDOW_READS = ('start triggers', 'start outputs', 'end triggers', 'end outputs', 'trigger gap max',
                'output gap min', 'output gap max')
AMOUNT_READS = ('start amount', 'end amount')


@dataclass(frozen=True)
class Stream:
    stream: str | None
    spell: int | None
    target: str | None
    event: str | None
    source_entry: int | None

    @property
    def timeline(self) -> bool:
        return self.event is not None


@dataclass(frozen=True)
class ProcGateSpec:
    spell: int
    name: str
    quote: str
    gate_ms: int
    learn: tuple[int, ...]
    talent: int | None
    setup_casts: tuple[tuple[int, str], ...]
    cause_auras: tuple[tuple[int, int], ...]
    trigger_casts: tuple[tuple[int, str], ...]
    control_ms: int
    windows: int
    window_casts: bool
    window_ms: int
    since_spell: int
    trigger: Stream
    output: Stream
    cast_auras: tuple[tuple[int, int], ...]
    cast_power: int | None
    cast_wait_ms: int
    dummies: int
    dummy_step_yd: float
    forced_talent: int | None
    amount_pct: float | None
    fixture: tuple[tuple[str, int], ...]
    label_suffix: str


def stream_of(raw: dict, role: str, spell: int) -> Stream:
    if 'event' in raw:
        event = raw['event']
        if event not in TIMELINE_EVENTS or not raw.get('source_entry'):
            raise ValueError(f'{spell} {KIND} {role} timeline needs one of {sorted(TIMELINE_EVENTS)} and a '
                             f'source_entry')
        return Stream(None, None, None, event, int(raw['source_entry']))
    stream = raw.get('stream')
    if stream not in COUNT_METRICS or not raw.get('spell'):
        raise ValueError(f'{spell} {KIND} {role} needs a stream of {sorted(COUNT_METRICS)} and a spell')
    return Stream(stream, int(raw['spell']), raw.get('target'), None, None)


def dummy_name(index: int) -> str:
    return TARGET if index == 0 else f'{TARGET}{index + 1}'


def proc_gate_spec(entry: dict) -> ProcGateSpec:
    spell = int(entry['spell'])
    spec = ProcGateSpec(
        spell, entry['name'], entry['quote'], int(entry['gate_ms']),
        tuple(int(value) for value in entry.get('learn', ())),
        int(entry['talent']) if entry.get('talent') is not None else None,
        tuple((int(cast), str(target)) for cast, target in entry.get('setup_casts', ())),
        tuple((int(aura), int(cast)) for aura, cast in entry.get('cause_auras', ())),
        tuple((int(cast), str(target)) for cast, target in entry['trigger_casts']),
        int(entry['control_ms']), int(entry['windows']), bool(entry.get('window_casts', True)),
        int(entry['window_ms']), int(entry['since_spell']), stream_of(entry['trigger'], 'trigger', spell),
        stream_of(entry['output'], 'output', spell),
        tuple((int(aura), int(stacks)) for aura, stacks in entry.get('cast_auras', ())),
        int(entry['cast_power']) if entry.get('cast_power') is not None else None, int(entry['cast_wait_ms']),
        int(entry.get('dummies', 1)), float(entry.get('dummy_step_yd', 2.0)),
        int(entry['forced_talent']) if entry.get('forced_talent') is not None else None,
        float(entry['amount_pct']) if entry.get('amount_pct') is not None else None,
        tuple((str(stat), int(value)) for stat, value in entry.get('fixture', {}).items()),
        entry.get('label_suffix', 'gate'))
    names = {CASTER} | {dummy_name(index) for index in range(spec.dummies)}
    if spec.gate_ms <= 0 or spec.windows < 1 or spec.control_ms < 0 or spec.window_ms <= 0:
        raise ValueError(f'{spell} {KIND} needs a positive gate, at least one window and positive waits')
    if spec.trigger.timeline:
        raise ValueError(f'{spell} {KIND} counts its triggers on an event stream, not on the timeline')
    if spec.output.timeline and spec.windows != 1:
        raise ValueError(f'{spell} {KIND} reads timeline outputs over one window only: the timeline intervals span '
                         f'the whole encounter')
    if not 1 <= spec.dummies <= MAX_DUMMIES:
        raise ValueError(f'{spell} {KIND} places 1 to {MAX_DUMMIES} dummies')
    targets = [target for _, target in spec.trigger_casts + spec.setup_casts]
    targets += [stream.target for stream in (spec.trigger, spec.output) if stream.target]
    if any(target not in names for target in targets):
        raise ValueError(f'{spell} {KIND} names a unit outside {sorted(names)}')
    if spec.since_spell not in {cast for cast, _ in spec.trigger_casts + spec.setup_casts}:
        raise ValueError(f'{spell} {KIND} reads its intervals since {spec.since_spell}, which it never casts')
    if spec.talent is None and not spec.setup_casts:
        raise ValueError(f'{spell} {KIND} needs a cause between the control and the windows: a talent or setup casts')
    if spec.setup_casts and 'cause_auras' not in entry:
        raise ValueError(f'{spell} {KIND} names the auras its setup casts leave as cause_auras ([aura, cast]), or []'
                         f' for a cause that does not lapse')
    if any(cast not in {setup for setup, _ in spec.setup_casts} for _, cast in spec.cause_auras):
        raise ValueError(f'{spell} {KIND} cause_auras name a cast outside its setup_casts')
    if spec.talent is not None and spec.talent in spec.learn:
        raise ValueError(f'{spell} {KIND} learns {spec.talent} only between the control and the windows')
    if spec.amount_pct is not None and (spec.amount_pct <= 0 or spec.trigger.stream not in AMOUNT_METRICS):
        raise ValueError(f'{spell} {KIND} amount_pct needs a positive share of a damage or heal trigger stream')
    return spec


def gate_mark(spec: ProcGateSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'.rstrip()


def minimum_wait_ms(records: Records, spell: int) -> int:
    return max(int(records.field('Spell', spell, 'StartRecoveryTime')), facts_of(records, spell).cast_time_ms) \
        + CAST_MARGIN_MS


def count_read(label: str, stream: Stream) -> dict:
    if stream.timeline:
        return measurement(label, CASTER, 'timeline_count', event=stream.event, source_entry=stream.source_entry)
    fields = {'spell': stream.spell, **({'target': stream.target} if stream.target else {})}
    return measurement(label, CASTER, COUNT_METRICS[stream.stream], **fields)


def gap_read(label: str, stream: Stream, edge: str, since_spell: int) -> dict:
    if stream.timeline:
        return measurement(label, CASTER, TIMELINE_GAP[edge], event=stream.event, source_entry=stream.source_entry)
    fields = {'stream': stream.stream, 'spell': stream.spell, 'since_spell': since_spell,
              **({'target': stream.target} if stream.target else {})}
    return measurement(label, CASTER, EVENT_GAP[edge], **fields)


def amount_read(label: str, stream: Stream) -> dict:
    fields = {'spell': stream.spell, **({'target': stream.target} if stream.target else {})}
    return measurement(label, CASTER, AMOUNT_METRICS[stream.stream], **fields)


def proc_gate_scenario(class_file: dict, spec: ProcGateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.gate_ms))
    for cast, _ in spec.trigger_casts:
        if spec.cast_wait_ms < minimum_wait_ms(records, cast):
            raise ValueError(f'{spec.spell} {KIND} waits {spec.cast_wait_ms} ms after {cast}, less than its '
                             f'{minimum_wait_ms(records, cast)} ms cast and global cooldown')
        facts = facts_of(records, cast)
        if (facts.mana_cost or facts.mana_cost_percentage or facts.mana_cost_per_level) and spec.cast_power is None:
            raise ValueError(f'{spec.spell} {KIND} casts {cast}, which costs power: name cast_power')
    round_ms = spec.cast_wait_ms * len(spec.trigger_casts)
    if not spec.window_casts:
        lasting = min(int(records.duration_ms(cast)) for cast, _ in spec.trigger_casts)
        if lasting > 0 and round_ms + spec.control_ms + spec.window_ms > lasting - AURA_END_MARGIN_MS:
            raise ValueError(f'{spec.spell} {KIND} reads {round_ms + spec.control_ms + spec.window_ms} ms after its '
                             f'first trigger cast, past the {lasting} ms its trigger aura lasts')
    band = bonus_band(float(spec.gate_ms))

    def trigger_round() -> list[dict]:
        steps = []
        set_auras = {aura for aura, _ in spec.cast_auras}
        for cast, target in spec.trigger_casts:
            facts = facts_of(records, cast)
            if spec.cast_power is not None:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                              'value': spec.cast_power})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': cast})
            steps += [step for step in required_aura_steps(facts) if step['spell'] not in set_auras]
            steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}
                      for aura, stacks in spec.cast_auras]
            steps += [{'action': 'cast', 'actor': CASTER, 'spell': cast, 'target': target},
                      {'action': 'wait', 'label': 'trigger cast', 'ms': spec.cast_wait_ms}]
        return steps

    def edge_reads(prefix: str, edge: str) -> list[dict]:
        reads = [count_read(gate_mark(spec, f'{prefix} {edge} triggers'), spec.trigger),
                 count_read(gate_mark(spec, f'{prefix} {edge} outputs'), spec.output)]
        if spec.amount_pct is not None:
            reads.append(amount_read(gate_mark(spec, f'{prefix} {edge} amount'), spec.trigger))
        return reads

    def gap_reads(prefix: str) -> list[dict]:
        return [gap_read(gate_mark(spec, f'{prefix} trigger gap max'), spec.trigger, 'max', spec.since_spell),
                gap_read(gate_mark(spec, f'{prefix} output gap min'), spec.output, 'min', spec.since_spell),
                gap_read(gate_mark(spec, f'{prefix} output gap max'), spec.output, 'max', spec.since_spell)]

    learned = (*spec.learn, *(cast for cast, _ in spec.trigger_casts + spec.setup_casts))
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                                      for spell in dict.fromkeys(learned)]
    if spec.output.timeline:
        steps.append({'action': 'encounter_start', 'actor': CASTER, 'boss_entry': DUMMY_ENTRY})
    if spec.forced_talent is not None:
        steps.append({'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': spec.forced_talent,
                      'op': FORCED_CHANCE_OP, 'percent': FORCED_CHANCE_PERCENT})
    steps += (edge_reads(CONTROL, 'start') + trigger_round()
              + [{'action': 'wait', 'label': 'control window', 'ms': spec.control_ms}] + edge_reads(CONTROL, 'end'))
    if spec.talent is not None:
        steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.talent})
    cast_starts = {}
    for cast, target in spec.setup_casts:
        cast_starts[cast] = len(steps)
        steps += hit_ratio_cast(records, cast, CASTER, target, spec.cast_power)
    windows = []
    for index in range(1, spec.windows + 1):
        prefix = f'w{index}'
        steps += edge_reads(prefix, 'start') + (trigger_round() if spec.window_casts else [])
        steps += [{'action': 'wait', 'label': 'gate window', 'ms': spec.window_ms}]
        steps += edge_reads(prefix, 'end') + gap_reads(prefix)
        windows.append({read: gate_mark(spec, f'{prefix} {read}')
                        for read in WINDOW_READS + (AMOUNT_READS if spec.amount_pct is not None else ())})
    for aura, cast in spec.cause_auras:
        try:
            lasting = int(records.duration_ms(aura))
        except Unreadable as error:
            raise ValueError(f'{spec.spell} {KIND} cause aura {aura} has no readable duration') from error
        held = waited_ms(steps[cast_starts[cast]:])
        if held > lasting - AURA_END_MARGIN_MS:
            raise ValueError(f'{spec.spell} {KIND} reads its last window {held} ms after the {cast} cast, past the '
                             f'{lasting} ms its cause aura {aura} lasts less {AURA_END_MARGIN_MS} ms')
    released = None
    if spec.forced_talent is not None:
        released = gate_mark(spec, 'released')
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
                  measurement(released, CASTER, 'spell_mod_mutants')]
    player = {**player_fixture(class_file), **dict(spec.fixture)}
    creatures = [{**creature_fixture(class_file), 'id': dummy_name(index),
                  'distance': creature_fixture(class_file)['distance'] + spec.dummy_step_yd * index}
                 for index in range(spec.dummies)]
    output = (f'{spec.output.event} events of creature {spec.output.source_entry} on the encounter timeline'
              if spec.output.timeline else f'{spec.output.spell} {spec.output.stream} events')
    cause = ' and '.join(filter(None, [f'{spec.talent} learned' if spec.talent is not None else '',
                                       'real casts of ' + ', '.join(str(cast) for cast, _ in spec.setup_casts)
                                       if spec.setup_casts else '']))
    forcing = (f' A forcing fixture raises the roll of {spec.forced_talent} by {FORCED_CHANCE_PERCENT}% (removed and '
               f'read gone at the end).' if spec.forced_talent is not None else '')
    fixtures = (' Precondition fixtures before every trigger cast: ' + ', '.join(f'{aura} x{stacks} by harness '
                                                                               f'set_aura'
                                                                               for aura, stacks in spec.cast_auras)
                + '.' if spec.cast_auras else '')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour proc gate interval',
        'contract': (f'Triggers are {spec.trigger.spell} {spec.trigger.stream} events, outputs are {output}, all '
                     f'stamped in game time.{forcing}{fixtures} Control: one round of '
                     + ', '.join(str(cast) for cast, _ in spec.trigger_casts)
                     + f' before {cause}: triggers and no output. Then {spec.windows} window(s), a trigger inside '
                       f'every gate window. The gate lies above the longest output interval less the longest trigger '
                       f'gap (a trigger that late was refused) and at most the shortest output interval; ok needs '
                       f'that whole bracket inside the stated {spec.gate_ms} ms +- the G-19 band ({band:g} ms), a '
                       f'bound beyond the band alerts, a wider bracket is unmeasured.'),
        'players': [player],
        'creatures': creatures,
        'steps': steps}
    gap_metric = (TIMELINE_GAP if spec.output.timeline else EVENT_GAP)['min']
    model = {'kind': KIND, 'metric': gap_metric, 'quote': entry.quote, 'gate_ms': spec.gate_ms, 'band': band,
             'control': {read: gate_mark(spec, f'{CONTROL} {read}')
                         for read in WINDOW_READS[:4] + (AMOUNT_READS if spec.amount_pct is not None else ())},
             'windows': windows, 'released': released, 'amount_pct': spec.amount_pct,
             'contrast': LEARNED_CONTRAST if spec.talent is not None else OWN_CAST_CONTRAST}
    expectation = Expectation(gate_mark(spec, ''), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger.spell, None,
                              f'{spec.gate_ms} ms', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def finite(value: float | None) -> bool:
    return value is not None and not math.isnan(value)


def window_reading(values: dict, model: dict) -> dict:
    triggers = values['end triggers'] - values['start triggers']
    outputs = values['end outputs'] - values['start outputs']
    reading = {'triggers': triggers, 'outputs': outputs, 'blocked': triggers - outputs}
    gaps = (values['trigger gap max'], values['output gap min'], values['output gap max'])
    if outputs >= 2 and all(finite(gap) for gap in gaps):
        reading.update({'trigger_gap': gaps[0], 'shortest': gaps[1], 'longest': gaps[2],
                        'bound': gaps[2] - gaps[0]})
    if model.get('amount_pct') is not None and triggers > 0:
        reading['leech'] = (values['end amount'] - values['start amount']) / triggers * model['amount_pct'] / 100
    return reading


def proc_gate_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    counted = [model['control']] + model['windows']
    for group in counted:
        for read, label in group.items():
            if 'gap' not in read and not finite(run.values.get(label)):
                return replace(base, explanation=missing_measurement(run, label))
    if model.get('released') and not finite(run.values.get(model['released'])):
        return replace(base, explanation=missing_measurement(run, model['released']))
    if model.get('released') and run.values.get(model['released']) != 0:
        return replace(base, status='alert', explanation=f'{run.values.get(model["released"])} forcing modifiers '
                                                         f'remain at the end')
    control = {read: run.values[label] for read, label in model['control'].items()}
    control_triggers = control['end triggers'] - control['start triggers']
    control_outputs = control['end outputs'] - control['start outputs']
    if control_outputs != 0:
        return replace(base, status='alert', explanation=f'{control_outputs:g} outputs in the control, before the '
                                                         f'cause, against {control_triggers:g} triggers')
    if control_triggers <= 0:
        return replace(base, status='unmeasured', explanation='the control drew no trigger, so it shows nothing')
    gate, band = float(model['gate_ms']), float(model['band'])
    readings = [window_reading({read: run.values.get(label) for read, label in window.items()}, model)
                for window in model['windows']]
    judged = [reading for reading in readings if 'shortest' in reading]
    summary = '; '.join(f'w{index} {reading["triggers"]:g} triggers, {reading["outputs"]:g} outputs'
                        + (f', outputs {reading["shortest"]:g} to {reading["longest"]:g} ms apart, triggers at most '
                           f'{reading["trigger_gap"]:g} ms apart' if 'shortest' in reading else '')
                        for index, reading in enumerate(readings, start=1))
    detail = {'windows': readings, CONTRAST: model.get('contrast', LEARNED_CONTRAST)}
    if any(reading['outputs'] > reading['triggers'] for reading in readings):
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'more outputs than triggers in a window, so the streams do not pair: {summary}')
    low_leech = [reading['leech'] for reading in readings if reading.get('leech', 1.0) < 1.0]
    if low_leech:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'a trigger amount of {min(low_leech):.2f} after the {model["amount_pct"]:g}% '
                                   f'share rounds a proc down to nothing: {summary}')
    if not judged:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'no window read two outputs: {summary}')
    shortest = min(reading['shortest'] for reading in judged)
    bound = max(reading['bound'] for reading in judged)
    edges = dict(measured=shortest, expected=gate, low=gate - band, high=gate + band)
    detail.update({'shortest_ms': shortest, 'reopened_by_ms': bound})
    if shortest < gate - band - 1e-9:
        return replace(base, status='alert', detail=detail, **edges,
                       explanation=f'an output followed the previous one after {shortest:g} ms, inside the stated '
                                   f'{gate:g} ms window less the {band:g} ms band: {summary}')
    if bound > gate + band + 1e-9:
        return replace(base, status='alert', detail=detail, **edges,
                       explanation=f'a trigger {bound:g} ms after an output was refused, past the stated {gate:g} '
                                   f'ms window plus the {band:g} ms band: {summary}')
    intervals = sum(reading['outputs'] - 1 for reading in judged)
    coarse = [reading['trigger_gap'] for reading in judged if reading['trigger_gap'] >= gate - band]
    if coarse or intervals < MINIMUM_INTERVALS or sum(reading['blocked'] for reading in judged) <= 0:
        why = (f'triggers {max(coarse):g} ms apart leave a window without a trigger' if coarse else
               f'{intervals:g} output intervals, fewer than {MINIMUM_INTERVALS}' if intervals < MINIMUM_INTERVALS
               else 'no trigger was refused')
        return replace(base, status='unmeasured', detail=detail, **edges, explanation=f'{why}: {summary}')
    bracket = (f'the gate lies above {bound:g} ms (a trigger that late was refused) and at most {shortest:g} ms (the '
               f'shortest output interval)')
    if bound < gate - band - 1e-9 or shortest > gate + band + 1e-9:
        return replace(base, status='unmeasured', detail=detail, **edges,
                       explanation=f'{bracket}: the bracket {bound:g} to {shortest:g} ms reaches outside '
                                   f'{gate - band:g} to {gate + band:g} ms, so a gate anywhere in it reads the same: '
                                   f'{summary}')
    control_note = f'no output in the control ({control_triggers:g} triggers)'
    if bound >= shortest - 1e-9:
        edge = f'{shortest:g} ms' if bound - shortest <= 1e-9 else f'{shortest:g} to {bound:g} ms'
        return replace(base, status='ok', detail=detail, **edges,
                       explanation=f'{control_note}; a trigger {bound:g} ms after an output was refused and an output '
                                   f'followed the previous one after {shortest:g} ms, so the edge trigger was refused '
                                   f'once and accepted once: the gate sits on the edge at {edge}, inside '
                                   f'{gate - band:g} to {gate + band:g} ms: {summary}')
    return replace(base, status='ok', detail=detail, **edges,
                   explanation=f'{control_note}; {bracket}: the bracket {bound:g} to {shortest:g} ms lies inside '
                               f'{gate - band:g} to {gate + band:g} ms, excluding a gate at or below {bound:g} ms '
                               f'and one above {shortest:g} ms: {summary}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return proc_gate_scenario(class_file, proc_gate_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'gate')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: proc_gate_verdict}
