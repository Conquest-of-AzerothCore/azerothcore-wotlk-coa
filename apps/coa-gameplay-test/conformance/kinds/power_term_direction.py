from dataclasses import dataclass, replace
import math
from pathlib import Path
import re
from statistics import NormalDist, fmean, variance

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, base_mana_steps, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of

KIND = 'power_term_direction'
ORDER = 47
ONE_SIDED_Z = NormalDist().inv_cdf(0.999)
MIN_SAMPLES = 10
MAXIMUM_STEPS = 10000
ATTACK_POWER_AURA = 99
ARMS = ('control low', 'control high', 'learned high', 'learned low')
REFUSED_FIELDS = frozenset({'expected', 'expected_gain', 'coefficient', 'tolerance'})
FIGURE = re.compile(r'\d|\$|%')
OK_TEXT = 'direction only: no figure judged'


@dataclass(frozen=True)
class PowerTermDirectionSpec:
    spell: int
    name: str
    quote: str
    talent: int
    cast_spell: int
    power_aura: int
    power_aura_source: str
    casts: int
    cast_wait_ms: int
    attempt_auras: tuple[tuple[int, int], ...] = ()
    label_suffix: str = 'power_direction'


def power_term_direction_spec(entry: dict) -> PowerTermDirectionSpec:
    spell = int(entry['spell'])
    refused = sorted(REFUSED_FIELDS & set(entry))
    if refused:
        raise ValueError(f'{spell} {KIND} judges a direction only and refuses the figure fields {refused}; a figure '
                         f'goes to stat_gain or hit_ratio with its own proof')
    if FIGURE.search(entry['quote']):
        raise ValueError(f'{spell} {KIND} quote {entry["quote"]!r} states a figure; a figure goes to stat_gain or '
                         f'hit_ratio with its own proof')
    auras = entry.get('attempt_auras', [])
    if not isinstance(auras, list) or not all(
            isinstance(aura, dict) and set(aura) == {'spell', 'stacks', 'source'} and isinstance(aura['spell'], int)
            and isinstance(aura['stacks'], int) and aura['stacks'] >= 1 and aura['source'] for aura in auras):
        raise ValueError(f'{spell} {KIND} attempt_auras lists {{"spell", "stacks", "source"}} caster auras')
    spec = PowerTermDirectionSpec(spell, entry['name'], entry['quote'], int(entry['talent']),
                                  int(entry['cast_spell']), int(entry['power_aura']), entry['power_aura_source'],
                                  int(entry['casts']), int(entry['cast_wait_ms']),
                                  tuple((aura['spell'], aura['stacks']) for aura in auras),
                                  entry.get('label_suffix', 'power_direction'))
    if spec.casts < MIN_SAMPLES or spec.cast_wait_ms < 1 or not spec.power_aura_source:
        raise ValueError(f'{spell} {KIND} needs at least {MIN_SAMPLES} casts per arm, a wait between casts and the '
                         f'source of its attack power aura')
    return spec


def mark(spec: PowerTermDirectionSpec, text: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {text}'


def arm_reads(spec: PowerTermDirectionSpec, arm: str) -> dict:
    return {'power': mark(spec, f'{arm} attack power'),
            'totals': [mark(spec, f'{arm} cast {cast} total') for cast in range(spec.casts + 1)],
            'counts': [mark(spec, f'{arm} cast {cast} count') for cast in range(spec.casts + 1)]}


def power_term_direction_scenario(class_file: dict, spec: PowerTermDirectionSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 0.0)
    if ATTACK_POWER_AURA not in facts_of(records, spec.power_aura).aura_names:
        raise ValueError(f'{spec.spell} {KIND} power aura {spec.power_aura} carries no SPELL_AURA_MOD_ATTACK_POWER')
    facts = facts_of(records, spec.cast_spell)
    mana = base_mana_steps(class_file, facts)
    if not mana and (facts.mana_cost or facts.mana_cost_percentage):
        raise ValueError(f'{spec.spell} {KIND} casts {spec.cast_spell}, whose cost is not a percentage of base mana')
    fixtures = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                for spell, stacks in spec.attempt_auras]
    reads = {arm: arm_reads(spec, arm) for arm in ARMS}

    def sample(arm: str, cast: int) -> list[dict]:
        return [measurement(reads[arm]['totals'][cast], CASTER, 'spell_damage_total', spell=spec.cast_spell,
                            target=TARGET, critical=False),
                measurement(reads[arm]['counts'][cast], CASTER, 'spell_damage_count', spell=spec.cast_spell,
                            target=TARGET, critical=False)]

    def phase(arm: str) -> list[dict]:
        steps = [measurement(reads[arm]['power'], CASTER, 'attack_power')] + sample(arm, 0)
        for cast in range(1, spec.casts + 1):
            steps += [*mana, *fixtures, {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell},
                      {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': TARGET},
                      {'action': 'wait', 'label': f'{arm} cast', 'ms': spec.cast_wait_ms}] + sample(arm, cast)
        return steps

    def power(stacks: int) -> dict:
        return {'action': 'set_aura', 'actor': CASTER, 'spell': spec.power_aura, 'stacks': stacks}

    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spec.cast_spell}]
             + phase('control low') + [power(1)] + phase('control high')
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}] + phase('learned high')
             + [power(0)] + phase('learned low'))
    if len(steps) > MAXIMUM_STEPS:
        raise ValueError(f'{spec.spell} {KIND} needs {len(steps)} steps, more than {MAXIMUM_STEPS}')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour power term direction',
        'contract': (f'{spec.cast_spell} is cast at the dummy {spec.casts} times in each of four arms: without '
                     f'{spec.talent} at the base attack power, without it with the attack power aura '
                     f'{spec.power_aura} ({spec.power_aura_source}), with {spec.talent} learned and the aura, and '
                     f'with {spec.talent} after the aura is removed. The attack power is read before each arm and '
                     f'each non-critical hit is one sample. The interaction (learned high - control high) - '
                     f'(learned low - control low) must exceed 0 at one-sided z {ONE_SIDED_Z:.2f} (Welch standard '
                     f'error) while the control arms do not grow with attack power: {OK_TEXT}.'
                     + ''.join(f' Aura {spell} is set on the caster at {stacks} stacks before each cast.'
                               for spell, stacks in spec.attempt_auras)),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'spell_damage_total', 'quote': entry.quote, 'z': ONE_SIDED_Z,
             'minimum_samples': MIN_SAMPLES, 'power_aura': spec.power_aura, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.talent, None,
                              'direction', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def arm_samples(values: dict, reads: dict) -> list[float]:
    totals, counts = [values[label] for label in reads['totals']], [values[label] for label in reads['counts']]
    return [totals[cast] - totals[cast - 1] for cast in range(1, len(totals))
            if counts[cast] - counts[cast - 1] == 1]


def welch(high: list[float], low: list[float]) -> tuple[float, float]:
    return fmean(high) - fmean(low), math.sqrt(variance(high) / len(high) + variance(low) / len(low))


def z_of(difference: float, error: float) -> float:
    if error > 0:
        return difference / error
    return math.inf if difference > 0 else -math.inf if difference < 0 else 0.0


def power_term_direction_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    labels = [label for arm in reads.values() for label in (arm['power'], *arm['totals'], *arm['counts'])]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    power = {arm: run.values[reads[arm]['power']] for arm in reads}
    if not (power['control high'] > power['control low'] and power['learned high'] > power['learned low']):
        return replace(base, status='unmeasured',
                       explanation=f'the attack power aura {model["power_aura"]} did not raise the attack power '
                                   f'(read {", ".join(f"{arm} {value:g}" for arm, value in power.items())})')
    samples = {arm: arm_samples(run.values, reads[arm]) for arm in reads}
    short = {arm: len(found) for arm, found in samples.items() if len(found) < model['minimum_samples']}
    if short:
        return replace(base, status='insufficient_trials',
                       explanation=f'fewer than {model["minimum_samples"]} non-critical hits in {short}')
    means = {arm: fmean(found) for arm, found in samples.items()}
    control, control_error = welch(samples['control high'], samples['control low'])
    learned, learned_error = welch(samples['learned high'], samples['learned low'])
    interaction, error = learned - control, math.hypot(control_error, learned_error)
    z, control_z, threshold = z_of(interaction, error), z_of(control, control_error), model['z']
    stated = (f'attack power {power["control low"]:g} / {power["control high"]:g} (control), '
              f'{power["learned low"]:g} / {power["learned high"]:g} (learned); mean non-critical hit '
              + ', '.join(f'{arm} {mean:.2f} ({len(samples[arm])})' for arm, mean in means.items())
              + f'; control growth {control:.2f} (z {control_z:.2f}), learned growth {learned:.2f}, interaction '
                f'{interaction:.2f} (Welch standard error {error:.2f}, z {z:.2f} against {threshold:.2f})')
    detail = {'interaction': interaction, 'standard_error': error, 'z': z, 'control_growth': control,
              'learned_growth': learned, 'means': means, 'attack_power': power}
    if abs(control_z) >= threshold:
        return replace(base, status='alert', measured=interaction, detail=detail,
                       explanation=f'without the passive the damage changes with attack power: {stated}')
    if z < threshold:
        return replace(base, status='alert', measured=interaction, detail=detail,
                       explanation=f'the passive adds no damage that grows with attack power: {stated}')
    return replace(base, status='ok', measured=interaction, detail=detail, explanation=f'{OK_TEXT}: {stated}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return power_term_direction_scenario(class_file, power_term_direction_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'power_direction')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: power_term_direction_verdict}
