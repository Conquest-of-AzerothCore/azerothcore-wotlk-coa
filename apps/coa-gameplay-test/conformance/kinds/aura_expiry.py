from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, FORCED_CHANCE_OP, FORCED_CHANCE_OWNER_AURA, FORCED_CHANCE_PERCENT,
                        behaviour_entry, cast_gate_power_step, prose_rule)
from compare import Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of

KIND = 'aura_expiry'
ORDER = 3


@dataclass(frozen=True)
class AuraExpirySpec:
    spell: int
    name: str
    quote: str
    aura: int
    entry: int
    marker_spell: int
    expected_ms: int
    command: int
    raise_spell: int
    onset_ms: int = 4000
    poll_ms: int = 100
    tail_ms: int | None = None
    band_ms: int | None = None
    raise_wait_ms: int = 3000
    label_suffix: str = 'aura_expiry'


def aura_expiry_spec(entry: dict) -> AuraExpirySpec:
    return AuraExpirySpec(entry['spell'], entry['name'], entry['quote'], int(entry['aura']), int(entry['entry']),
                          int(entry['marker_spell']), int(entry['expected_ms']), int(entry['command']),
                          int(entry['raise_spell']), int(entry.get('onset_ms', 4000)), int(entry.get('poll_ms', 100)),
                          entry.get('tail_ms'), entry.get('band_ms'), int(entry.get('raise_wait_ms', 3000)),
                          entry.get('label_suffix', 'aura_expiry'))


def aura_expiry_label(spec: AuraExpirySpec, index: int, read: str) -> str:
    return f'{spec.spell} aura_expiry {index} {read}'


def aura_expiry_scenario(class_file: dict, spec: AuraExpirySpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'aura_expiry', spec.quote, spec.expected_ms)
    if spec.poll_ms < 50 or spec.onset_ms < spec.poll_ms or spec.expected_ms <= 0:
        raise ValueError(f'{spec.spell} aura_expiry needs a positive duration and polls of at least 50 ms')
    tail_ms = spec.tail_ms if spec.tail_ms is not None else spec.expected_ms + 3000
    band_ms = spec.band_ms if spec.band_ms is not None else spec.expected_ms * 5 // 100
    power = facts_of(records, spec.command)
    reads = []

    def poll(index: int) -> list[dict]:
        labels = [aura_expiry_label(spec, index, read) for read in ('time', 'aura', 'marker')]
        reads.append(labels)
        return [measurement(labels[0], CASTER, 'game_time_ms'),
                measurement(labels[1], CASTER, 'owned_creature_count', entry=spec.entry, spell=spec.aura),
                measurement(labels[2], CASTER, 'owned_creature_spell_cast_count', entry=spec.entry,
                            spell=spec.marker_spell)]

    released = f'{spec.spell} aura_expiry released'
    switched = f'{spec.spell} aura_expiry switched'
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in (spec.spell, spec.command, spec.raise_spell)]
             + [{'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': spec.spell, 'op': FORCED_CHANCE_OP,
                 'percent': FORCED_CHANCE_PERCENT},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.raise_spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.raise_spell, 'target': CASTER},
                {'action': 'wait', 'label': 'raise settle', 'ms': spec.raise_wait_ms}]
             + cast_gate_power_step(power)
             + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.command},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.command, 'target': TARGET}]
             + poll(0))
    onset = spec.onset_ms // spec.poll_ms
    for index in range(1, onset + 1):
        steps += [{'action': 'wait', 'ms': spec.poll_ms}] + poll(index)
    steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
              {'action': 'spell_mod_mutant', 'actor': CASTER, 'spell': spec.spell, 'op': FORCED_CHANCE_OP,
               'percent': -100},
              measurement(switched, CASTER, 'spell_mod_mutants')]
    for index in range(onset + 1, onset + 1 + tail_ms // spec.poll_ms):
        steps += [{'action': 'wait', 'ms': spec.poll_ms}] + poll(index)
    steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': FORCED_CHANCE_OWNER_AURA, 'stacks': 0},
              measurement(released, CASTER, 'spell_mod_mutants')]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura expiry',
        'contract': f'{spec.spell} is known and its roll forced (a SPELLMOD_CHANCE_OF_SUCCESS +1000% spell modifier '
                    f'mutant); {spec.raise_spell} raises a creature {spec.entry} and {spec.command} sends it at the '
                    f'dummy. Every {spec.poll_ms} ms for {spec.onset_ms} ms the game time, the creatures of that entry '
                    f'carrying {spec.aura} and the casts of {spec.marker_spell} by the creature are read; then the '
                    f'forcing mutant is removed and a -100% one set, so no roll applies {spec.aura} again, and the '
                    f'reads go on for {tail_ms} ms. The last cast of {spec.marker_spell} and the first read without '
                    f'{spec.aura} after it bracket the aura\'s duration in game time.',
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    timed(scenario, sum(step['ms'] for step in steps if step['action'] == 'wait'), MAX_ACCELERATED_SCENARIO_MS)
    model = {'kind': 'aura_expiry', 'metric': 'owned_creature_count', 'quote': entry.quote, 'reads': reads,
             'switch_index': onset + 1, 'expected_ms': spec.expected_ms, 'band_ms': band_ms,
             'switched_label': switched, 'released_label': released}
    label = f'{spec.spell} behaviour_metric_delta {spec.label_suffix}'
    return scenario, [Expectation(label, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None, str(spec.expected_ms),
                                  prose_rule(entry.quote, spec.spell), model)]


def behaviour_aura_expiry_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    series = [[run.values.get(label) for label in labels] for labels in model['reads']]
    missing = [labels[0] for labels, values in zip(model['reads'], series) if any(value is None for value in values)]
    if missing:
        return replace(base, explanation=missing_measurement(run, missing[0]))
    times = [values[0] for values in series]
    present = [values[1] > 0 for values in series]
    marks = [values[2] for values in series]
    switch = model['switch_index']
    expected, band = float(model['expected_ms']), float(model['band_ms'])
    rises = [index for index in range(1, len(marks)) if marks[index] > marks[index - 1]]
    onset = [index for index in rises if index < switch]
    if not onset:
        return replace(base, status='unmeasured', explanation='no cast of the marker spell before the switch, so the '
                                                              'forced aura has no stamp')
    if any(index >= switch for index in rises):
        return replace(base, status='alert', explanation=f'the marker spell was cast again after the switch at read '
                                                         f'{min(index for index in rises if index >= switch)}: the '
                                                         f'roll was not stopped')
    last = onset[-1]
    if not present[last]:
        return replace(base, status='unmeasured', explanation=f'the aura is absent at the last cast\'s read {last}')
    gone = next((index for index in range(last + 1, len(present)) if not present[index]), None)
    if gone is None:
        return replace(base, status='alert', measured=times[-1] - times[last], expected=expected,
                       explanation=f'the aura outlasts the reads: still present {times[-1] - times[last]:g} ms after '
                                   f'the last cast')
    if not all(present[last:gone]):
        return replace(base, status='alert', explanation='the aura is absent between the last cast and its expiry')
    low, high = times[gone - 1] - times[last], times[gone] - times[last - 1]
    start = times[0]
    released = run.values.get(model['released_label'])
    status = 'ok' if expected - band <= low and high <= expected + band and released == 0 else 'alert'
    return replace(base, status=status, measured=(low + high) / 2, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'last cast of the marker in ({times[last - 1] - start:g}, {times[last] - start:g}] '
                               f'ms of game time after the command, the aura gone in ({times[gone - 1] - start:g}, '
                               f'{times[gone] - start:g}]: it lasted between {low:g} and '
                               f'{high:g} ms, against {expected:g} +- {band:g} (5%); the forcing mutant removed '
                               f'({released})')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return aura_expiry_scenario(class_file, aura_expiry_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta "
            f"{entry.get('label_suffix', 'aura_expiry')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: behaviour_aura_expiry_verdict}
