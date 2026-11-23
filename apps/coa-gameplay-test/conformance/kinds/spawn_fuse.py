from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA, FORCED_CHANCE_PERCENT,
                        behaviour_entry, prose_rule, waited_ms)
from bonus import bonus_band
from compare import Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_ENTRY, Expectation, GCD_WAIT_MS, TARGET, dataset, facts_of

KIND = 'spawn_fuse'
ORDER = 28


@dataclass(frozen=True)
class SpawnFuseSpec:
    spell: int
    name: str
    quote: str
    talent: int
    trigger_spell: int
    entry: int
    fuse_spell: int
    expected_ms: int
    casts: int
    control_casts: int
    settle_ms: int
    cast_power: int | None = None
    label_suffix: str = 'fuse'


def spawn_fuse_spec(entry: dict) -> SpawnFuseSpec:
    spec = SpawnFuseSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['talent']),
                         int(entry['trigger_spell']), int(entry['entry']), int(entry['fuse_spell']),
                         int(entry['expected_ms']), int(entry['casts']), int(entry['control_casts']),
                         int(entry['settle_ms']), entry.get('cast_power'), entry.get('label_suffix', 'fuse'))
    if spec.casts < 1 or spec.control_casts < 1 or spec.settle_ms <= spec.expected_ms:
        raise ValueError(f'{spec.spell} {KIND} needs control and treatment casts and a settle past the stated fuse')
    return spec


def fuse_mark(spec: SpawnFuseSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def spawn_fuse_scenario(class_file: dict, spec: SpawnFuseSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, float(spec.expected_ms))
    facts = facts_of(records, spec.trigger_spell)
    power = spec.cast_power if spec.cast_power is not None else facts.mana_cost
    spawns = {'event': 'spawn', 'source_entry': spec.entry}
    fuses = {'event': 'cast', 'spell': spec.fuse_spell, 'source_entry': spec.entry}

    def casts(count: int) -> list[dict]:
        powered = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power}] if power else []
        return [step for _ in range(count) for step in (
            *powered,
            {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
            {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET},
            {'action': 'wait', 'label': 'cast', 'ms': GCD_WAIT_MS})]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell},
                {'action': 'encounter_start', 'actor': CASTER, 'boss_entry': DUMMY_ENTRY},
                {'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': spec.talent, 'op': FORCED_CHANCE_OP,
                 'percent': FORCED_CHANCE_PERCENT}]
             + casts(spec.control_casts)
             + [{'action': 'wait', 'label': 'control settle', 'ms': spec.settle_ms},
                measurement(fuse_mark(spec, 'control spawns'), CASTER, 'timeline_count', **spawns),
                {'action': 'learn', 'actor': CASTER, 'spell': spec.talent}]
             + casts(spec.casts)
             + [{'action': 'wait', 'label': 'treatment settle', 'ms': spec.settle_ms},
                measurement(fuse_mark(spec, 'spawns'), CASTER, 'timeline_count', **spawns),
                measurement(fuse_mark(spec, 'first spawn'), CASTER, 'timeline_first_ms', **spawns),
                measurement(fuse_mark(spec, 'first fuse'), CASTER, 'timeline_first_ms', **fuses),
                {'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
                measurement(fuse_mark(spec, 'released'), CASTER, 'spell_mod_mutants')])
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour spawn fuse {spec.label_suffix}',
        'contract': (f'An encounter timeline records every spawn and cast on the map from the start. A forcing fixture '
                     f'raises the roll of {spec.talent} by {FORCED_CHANCE_PERCENT}% (removed at the end and read '
                     f'gone). Control: {spec.control_casts} casts of {spec.trigger_spell} at the dummy without '
                     f'{spec.talent}: no creature {spec.entry} spawns. Treatment: {spec.casts} casts with it learned; '
                     f'the first {spec.fuse_spell} cast by a creature {spec.entry} must follow the first spawn of '
                     f'{spec.entry} by {spec.expected_ms} ms within the G-19 band.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'timeline_first_ms', 'quote': entry.quote, 'expected_ms': spec.expected_ms,
             'band': bonus_band(float(spec.expected_ms)),
             'reads': {mark: fuse_mark(spec, mark)
                       for mark in ('control spawns', 'spawns', 'first spawn', 'first fuse', 'released')}}
    expectation = Expectation(fuse_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell,
                              None, str(spec.expected_ms), prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def spawn_fuse_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    values = {mark: run.values.get(label) for mark, label in reads.items()}
    for mark in ('control spawns', 'spawns', 'released'):
        if values[mark] is None:
            return replace(base, explanation=missing_measurement(run, reads[mark]))
    if values['control spawns'] != 0 or values['released'] != 0:
        return replace(base, status='alert', explanation=f'the control spawned {values["control spawns"]:g} and '
                                                         f'{values["released"]:g} forcing modifiers remain')
    spawn, fuse = values['first spawn'], values['first fuse']
    if values['spawns'] < 1 or spawn is None or spawn != spawn:
        return replace(base, status='unmeasured', explanation='no creature spawned in the treatment')
    if fuse is None or fuse != fuse:
        return replace(base, status='alert', explanation=f'{values["spawns"]:g} creatures spawned and none cast the '
                                                         f'fuse spell')
    measured = fuse - spawn
    expected, band = float(model['expected_ms']), float(model['band'])
    low, high = expected - band, expected + band
    status = 'ok' if low - 1e-9 <= measured <= high + 1e-9 else 'alert'
    return replace(base, status=status, measured=measured, expected=expected, low=low, high=high,
                   detail={'first_spawn_ms': spawn, 'first_fuse_ms': fuse, 'spawns': values['spawns']},
                   explanation=f'no creature in the control; in the treatment {values["spawns"]:g} spawned, the '
                               f'first at {spawn:g} ms of the timeline and the first fuse cast at {fuse:g} ms: '
                               f'{measured:g} ms against the stated {expected:g} ms, band {low:g} to {high:g}: '
                               f'{status}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return spawn_fuse_scenario(class_file, spawn_fuse_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'fuse')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: spawn_fuse_verdict}
