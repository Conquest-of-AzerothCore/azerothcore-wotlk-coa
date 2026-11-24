from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, NO_CAST_FAILURE, OWN_CAST_CONTRAST, THREAT_SLOPE_WAIT_MS,
                        behaviour_entry, cast_gate_power_step, prose_rule, waited_ms)
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import DUMMY_DISTANCE, Expectation, dataset, facts_of, required_aura_steps

KIND = 'threat_above_control'
ORDER = 56

ARMS = ('treatment', 'control')
MINIMUM_SAMPLES = 3
MAXIMUM_SAMPLES = 5
DUMMY_SPACING_YD = 10.0
READS = ('health before', 'health after', 'threat before', 'threat after', 'cast_failure after')


@dataclass(frozen=True)
class ThreatAboveControlSpec:
    spell: int
    name: str
    quote: str
    hit_spell: int
    control_spell: int
    samples: int = 5
    settle_ms: int = 0
    label_suffix: str = 'threat_above_control'


def threat_above_control_spec(entry: dict) -> ThreatAboveControlSpec:
    samples = entry.get('samples', 5)
    settle = entry.get('settle_ms', 0)
    spec = ThreatAboveControlSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['hit_spell']),
                                  int(entry['control_spell']), samples, settle,
                                  entry.get('label_suffix', 'threat_above_control'))
    if type(samples) is not int or not MINIMUM_SAMPLES <= samples <= MAXIMUM_SAMPLES:
        raise ValueError(f'{spec.spell} {KIND} samples {samples!r}: a whole count from {MINIMUM_SAMPLES} to '
                         f'{MAXIMUM_SAMPLES} per arm (one fresh dummy each, under the harness creature cap)')
    if type(settle) is not int or settle < 0:
        raise ValueError(f'{spec.spell} {KIND} settle_ms {settle!r} is a whole number of at least 0')
    if spec.hit_spell == spec.control_spell:
        raise ValueError(f'{spec.spell} {KIND} needs a control spell other than the hit spell {spec.hit_spell}')
    return spec


def sample_label(spec: ThreatAboveControlSpec, arm: str, index: int, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {arm} {index} {read}'


def dummy_id(position: int) -> str:
    return f'threat_dummy_{position}'


def order(spec: ThreatAboveControlSpec) -> list[tuple[str, int]]:
    return [(arm, index) for index in range(1, spec.samples + 1) for arm in ARMS]


def sample_steps(records: Records, spec: ThreatAboveControlSpec, arm: str, index: int, position: int) -> list[dict]:
    spell = spec.hit_spell if arm == 'treatment' else spec.control_spell
    facts = facts_of(records, spell)
    dummy = dummy_id(position)
    labels = {read: sample_label(spec, arm, index, read) for read in READS}
    moved = [{'action': 'relocate', 'actor': CASTER, 'dx': DUMMY_SPACING_YD}] if position else []
    return (moved
            + [measurement(labels['health before'], dummy, 'health'),
               measurement(labels['threat before'], dummy, 'threat', target=CASTER),
               {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}]
            + cast_gate_power_step(facts) + required_aura_steps(facts)
            + [{'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': dummy},
               {'action': 'wait', 'ms': facts.cast_time_ms + THREAT_SLOPE_WAIT_MS + spec.settle_ms},
               measurement(labels['cast_failure after'], CASTER, 'cast_failure', spell=spell),
               measurement(labels['health after'], dummy, 'health'),
               measurement(labels['threat after'], dummy, 'threat', target=CASTER)])


def threat_above_control_scenario(class_file: dict, spec: ThreatAboveControlSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    samples = order(spec)
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                                      for spell in (spec.hit_spell, spec.control_spell)]
    for position, (arm, index) in enumerate(samples):
        steps += sample_steps(records, spec, arm, index, position)
    creatures = [{**creature_fixture(class_file), 'id': dummy_id(position),
                  'distance': DUMMY_DISTANCE + DUMMY_SPACING_YD * position} for position in range(len(samples))]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour threat above control',
        'contract': (f'{spec.samples} casts of {spec.hit_spell} and {spec.samples} of the control {spec.control_spell}, '
                     f'alternated, each at its own fresh dummy: the dummies stand {DUMMY_SPACING_YD:g} yd apart on '
                     f'one line and the caster steps {DUMMY_SPACING_YD:g} yd along it before each cast, so each cast '
                     f'reaches only the dummy {DUMMY_DISTANCE:g} yd ahead. A sample is the dummy\'s threat on the '
                     f'caster gained over the health it lost. Every {spec.hit_spell} sample must lie strictly above '
                     f'every control sample, proving the "{spec.quote}" clause as a direction, with no amount.'),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': KIND, 'metric': 'threat', 'contrast': OWN_CAST_CONTRAST, 'quote': entry.quote,
             'hit_spell': spec.hit_spell, 'control_spell': spec.control_spell,
             'samples': {arm: [{read: sample_label(spec, arm, index, read) for read in READS}
                               for index in range(1, spec.samples + 1)] for arm in ARMS}}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.hit_spell, None, 'above control', prose_rule(entry.quote, spec.spell),
                              model)
    return timed(scenario, waited_ms(steps)), [expectation]


def sample_value(values: dict, labels: dict) -> float | str:
    failure = values[labels['cast_failure after']]
    lost = values[labels['health before']] - values[labels['health after']]
    if failure != NO_CAST_FAILURE or lost <= 0:
        return f'cast_failure {failure:g}, health lost {lost:g}'
    return (values[labels['threat after']] - values[labels['threat before']]) / lost


def threat_above_control_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for arm in ARMS for sample in model['samples'][arm] for label in sample.values()]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    samples = {arm: [sample_value(run.values, sample) for sample in model['samples'][arm]] for arm in ARMS}
    void = next(((arm, index + 1, value) for arm in ARMS for index, value in enumerate(samples[arm])
                 if isinstance(value, str)), None)
    if void is not None:
        return replace(base, status='unmeasured',
                       explanation=f'{void[0]} sample {void[1]}: {void[2]}; no landed hit to divide by')
    lowest, highest = min(samples['treatment']), max(samples['control'])
    text = (f'threat per health lost: {model["hit_spell"]} {[round(value, 6) for value in samples["treatment"]]}, '
            f'control {model["control_spell"]} {[round(value, 6) for value in samples["control"]]}')
    status = 'ok' if lowest > highest else 'alert'
    rule = 'lies strictly above' if status == 'ok' else 'does not lie strictly above'
    return replace(base, status=status, measured=lowest, expected=highest, low=highest,
                   explanation=f'{text}; the lowest {model["hit_spell"]} sample {lowest:.6g} {rule} the highest '
                               f'control sample {highest:.6g} (direction only, no amount asserted)')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return threat_above_control_scenario(class_file, threat_above_control_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'threat_above_control')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: threat_above_control_verdict}
