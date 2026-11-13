from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset

KIND = 'bounce_amounts'
ORDER = 10

BOUNCE_BAND = 0.05
BOUNCE_FAR_MARGIN_YD = 16.0
BOUNCE_ARMS = ('control', 'treatment')


@dataclass(frozen=True)
class BounceAmountsSpec:
    spell: int
    name: str
    quote: str
    cast_spell: int
    hit_spell: int
    distances: tuple[float, ...]
    cast_wait_ms: int
    cast_power: int | None
    caster_auras: tuple[int, ...]
    label_suffix: str


def bounce_amounts_spec(entry: dict) -> BounceAmountsSpec:
    spec = BounceAmountsSpec(entry['spell'], entry['name'], entry['quote'], int(entry['cast_spell']),
                             int(entry['hit_spell']), tuple(float(value) for value in entry['distances']),
                             int(entry['cast_wait_ms']), entry.get('cast_power'),
                             tuple(int(spell) for spell in entry.get('caster_auras', ())),
                             entry.get('label_suffix', 'bounce_amounts'))
    if len(spec.distances) < 2 or list(spec.distances) != sorted(spec.distances) or spec.distances[0] <= 0:
        raise ValueError(f'{spec.spell} bounce_amounts needs the primary and at least one more dummy, nearest first')
    if spec.cast_wait_ms <= 0:
        raise ValueError(f'{spec.spell} bounce_amounts needs a positive cast_wait_ms')
    return spec


def bounce_dummy(index: int) -> str:
    return 'primary' if index == 0 else f'bounce{index}'


def bounce_label(spec: BounceAmountsSpec, arm: str, index: int, read: str) -> str:
    return f'{spec.spell} bounce_amounts {spec.label_suffix} {arm} {bounce_dummy(index)} {read}'


def expected_ratios(records: Records, spec: BounceAmountsSpec) -> list[float]:
    multiplier = float(records.field('Spell', spec.hit_spell, 'EffectDamageMultiplier[0]'))
    return [multiplier ** jump for jump in range(1, len(spec.distances))]


def bounce_amounts_scenario(class_file: dict, spec: BounceAmountsSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'bounce_amounts', spec.quote,
                            expected_ratios(records, spec)[0])
    ratios = expected_ratios(records, spec)
    far = len(spec.distances)
    distances = [*spec.distances, spec.distances[-1] + BOUNCE_FAR_MARGIN_YD]
    creatures = [{**creature_fixture(class_file), 'id': bounce_dummy(index), 'distance': distance}
                 for index, distance in enumerate(distances)]

    def reads(arm: str) -> list[dict]:
        return [measurement(bounce_label(spec, arm, index, read), CASTER, metric, spell=spec.hit_spell,
                            target=bounce_dummy(index))
                for index in range(far + 1)
                for read, metric in (('total', 'spell_damage_total'), ('count', 'spell_damage_count'))]

    def cast() -> list[dict]:
        return (hit_ratio_cast(records, spec.cast_spell, CASTER, bounce_dummy(0), spec.cast_power)
                + [{'action': 'wait', 'label': 'bounce cast', 'ms': spec.cast_wait_ms}])

    steps = (base_steps(class_file)
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': 1} for aura in spec.caster_auras]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}]
             + cast() + reads('control')
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + cast() + reads('treatment'))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour bounce amounts',
        'contract': (f'{spec.cast_spell} cast at the primary dummy without {spec.spell} (control), then with it '
                     f'learned (treatment); dummies at {list(spec.distances)} yd from the caster and one '
                     f'{BOUNCE_FAR_MARGIN_YD:g} yd beyond. The {spec.hit_spell} damage total and hit count of every '
                     f'dummy are read after each arm; the treatment hits are the difference. The control strikes '
                     f'the primary only; with the talent every further dummy is struck, the far one never, and the '
                     f'per-hit amounts, largest first, are the primary\'s times {[round(r, 4) for r in ratios]}.'),
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': KIND, 'metric': 'spell_damage_total', 'quote': entry.quote, 'ratios': ratios, 'band': BOUNCE_BAND, 'far_index': far,
             'reads': {arm: [[bounce_label(spec, arm, index, read) for read in ('total', 'count')]
                             for index in range(far + 1)] for arm in BOUNCE_ARMS}}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.hit_spell, None, f'{ratios[0]:g}',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def bounce_amounts_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for arm in BOUNCE_ARMS for row in model['reads'][arm] for label in row]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    control = [[run.values[label] for label in row] for row in model['reads']['control']]
    treatment = [[run.values[label] - before for label, before in zip(row, earlier)]
                 for row, earlier in zip(model['reads']['treatment'], control)]
    far = int(model['far_index'])
    if control[0][1] <= 0 or any(total or count for total, count in control[1:]):
        return replace(base, status='alert', explanation=f'control arm: the primary took {control[0][1]:g} hits and '
                                                         f'the other dummies {[count for _, count in control[1:]]}; '
                                                         f'only the primary may be struck without the talent')
    if treatment[far][1]:
        return replace(base, status='alert', explanation=f'the dummy beyond every bounce took {treatment[far][1]:g} '
                                                         f'hits')
    struck = treatment[:far]
    if any(count <= 0 for _, count in struck):
        return replace(base, status='alert', explanation=f'with the talent the dummies took '
                                                         f'{[count for _, count in struck]} hits; every dummy in '
                                                         f'reach must be struck')
    means = sorted((total / count for total, count in struck), reverse=True)
    primary = means[0]
    ratios = [mean / primary for mean in means[1:]]
    stated = [float(value) for value in model['ratios']]
    band = float(model['band'])
    inside = all(abs(ratio - value) <= band * value for ratio, value in zip(ratios, stated))
    return replace(base, status='ok' if inside else 'alert', measured=ratios[0], expected=stated[0],
                   low=stated[0] * (1 - band), high=stated[0] * (1 + band),
                   explanation=f'per-hit means largest first {[round(mean, 2) for mean in means]} over '
                               f'{[count for _, count in struck]} hits; ratios to the primary '
                               f'{[round(ratio, 4) for ratio in ratios]} against the stated '
                               f'{[round(value, 4) for value in stated]} (G-19 band {band:.0%} of each); the control '
                               f'struck the primary only and the far dummy was never struck')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return bounce_amounts_scenario(class_file, bounce_amounts_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'bounce_amounts')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: bounce_amounts_verdict}
