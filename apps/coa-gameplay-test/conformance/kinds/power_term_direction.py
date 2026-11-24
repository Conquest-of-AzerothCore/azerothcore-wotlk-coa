from dataclasses import dataclass, replace
import math
from pathlib import Path
import re
from statistics import NormalDist, fmean, variance

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER, STRIKER_DISTANCE, STRIKER_HEALTH, TAKEN_HIT_STRIKER_ENTRY,
                        behaviour_entry, prose_rule, waited_ms)
from compare import Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, base_mana_steps, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from stack import student_t_quantile
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of

KIND = 'power_term_direction'
ORDER = 47
DIRECTION_PROBABILITY = 0.999
CONTROL_FALSE_ALERT_PER_PAIR = 0.001
CONTROL_FALSE_ALERT_PER_RUN = 1 - math.sqrt(1 - CONTROL_FALSE_ALERT_PER_PAIR)
CONTROL_PROBABILITY = 1 - CONTROL_FALSE_ALERT_PER_RUN / 2
MIN_SAMPLES = 10
MAXIMUM_STEPS = 10000
ATTACK_POWER_AURA = 99
STAT_AURA = 29
AGILITY = 1
HEALTH_AURAS = frozenset({34, 133})
ABSORB_AURA = 69
ATTACK_POWER = 'attack_power'
POWER_METRICS = {ATTACK_POWER: 'attack power', 'agility': 'Agility', 'max_health': 'maximum health'}
ABSORB = 'absorb'
STRIKE_SETTLE_MS = 500
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
    power_metric: str = ATTACK_POWER
    hit_spell: int | None = None
    cast_power: int | None = None
    sample: str | None = None
    strike_spell: int | None = None
    refill_spell: int | None = None
    power_stacks: int = 1
    power_companions: tuple[tuple[int, int, str], ...] = ()


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
    companions = entry.get('power_companions', [])
    if not isinstance(companions, list) or not all(
            isinstance(aura, dict) and set(aura) == {'spell', 'stacks', 'source'} and isinstance(aura['spell'], int)
            and isinstance(aura['stacks'], int) and aura['stacks'] >= 1 and aura['source'] for aura in companions):
        raise ValueError(f'{spell} {KIND} power_companions lists {{"spell", "stacks", "source"}} caster auras')
    power_stacks = entry.get('power_stacks', 1)
    if not isinstance(power_stacks, int) or power_stacks < 1:
        raise ValueError(f'{spell} {KIND} power_stacks is a positive stack count')
    spec = PowerTermDirectionSpec(spell, entry['name'], entry['quote'], int(entry['talent']),
                                  int(entry['cast_spell']), int(entry['power_aura']), entry['power_aura_source'],
                                  int(entry['casts']), int(entry['cast_wait_ms']),
                                  tuple((aura['spell'], aura['stacks']) for aura in auras),
                                  entry.get('label_suffix', 'power_direction'),
                                  entry.get('power_metric', ATTACK_POWER), entry.get('hit_spell'),
                                  entry.get('cast_power'), entry.get('sample'), entry.get('strike_spell'),
                                  entry.get('refill_spell'), power_stacks,
                                  tuple((aura['spell'], aura['stacks'], aura['source']) for aura in companions))
    if spec.power_metric not in POWER_METRICS:
        raise ValueError(f'{spell} {KIND} power_metric is one of {sorted(POWER_METRICS)}')
    if spec.hit_spell is not None and (not isinstance(spec.hit_spell, int) or spec.sample == ABSORB):
        raise ValueError(f'{spell} {KIND} hit_spell names the damage spell of a damage sample')
    if spec.cast_power is not None and (not isinstance(spec.cast_power, int) or spec.cast_power < 1):
        raise ValueError(f'{spell} {KIND} cast_power is a positive power value')
    if spec.sample not in (None, ABSORB):
        raise ValueError(f'{spell} {KIND} sample is {ABSORB!r} or absent')
    if (spec.sample == ABSORB) != (isinstance(spec.strike_spell, int) and isinstance(spec.refill_spell, int)):
        raise ValueError(f'{spell} {KIND} an absorb sample needs, and only it takes, a strike_spell and a '
                         f'refill_spell')
    if spec.casts < MIN_SAMPLES or spec.cast_wait_ms < 1 or not spec.power_aura_source:
        raise ValueError(f'{spell} {KIND} needs at least {MIN_SAMPLES} casts per arm, a wait between casts and the '
                         f'source of its attack power aura')
    return spec


def mark(spec: PowerTermDirectionSpec, text: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {text}'


def arm_reads(spec: PowerTermDirectionSpec, arm: str) -> dict:
    power = POWER_METRICS[spec.power_metric]
    reads = {'power': mark(spec, f'{arm} {power}')}
    if spec.power_metric != ATTACK_POWER:
        reads['power after'] = mark(spec, f'{arm} {power} after')
        reads['attack power'] = mark(spec, f'{arm} attack power')
        reads['attack power after'] = mark(spec, f'{arm} attack power after')
    if spec.sample == ABSORB:
        return {**reads, 'absorbs': [mark(spec, f'{arm} cast {cast} absorb') for cast in range(spec.casts + 1)],
                'logs': [mark(spec, f'{arm} cast {cast} strikes') for cast in range(spec.casts + 1)],
                'held': [mark(spec, f'{arm} cast {cast} held') for cast in range(1, spec.casts + 1)],
                'remaining': [mark(spec, f'{arm} cast {cast} remaining') for cast in range(1, spec.casts + 1)]}
    return {**reads, 'totals': [mark(spec, f'{arm} cast {cast} total') for cast in range(spec.casts + 1)],
            'counts': [mark(spec, f'{arm} cast {cast} count') for cast in range(spec.casts + 1)]}


def power_read(spec: PowerTermDirectionSpec, label: str) -> dict:
    if spec.power_metric == 'agility':
        return measurement(label, CASTER, 'stat', stat=AGILITY)
    return measurement(label, CASTER, spec.power_metric)


def check_power_aura(records: Records, spec: PowerTermDirectionSpec) -> None:
    auras = facts_of(records, spec.power_aura).aura_names
    if spec.power_metric == ATTACK_POWER:
        if ATTACK_POWER_AURA not in auras:
            raise ValueError(f'{spec.spell} {KIND} power aura {spec.power_aura} carries no '
                             f'SPELL_AURA_MOD_ATTACK_POWER')
    elif spec.power_metric == 'agility':
        if not any(aura == STAT_AURA and records.field('Spell', spec.power_aura, f'EffectMiscValue[{effect}]')
                   == AGILITY for effect, aura in enumerate(auras)):
            raise ValueError(f'{spec.spell} {KIND} power aura {spec.power_aura} carries no SPELL_AURA_MOD_STAT '
                             f'of Agility')
    elif not HEALTH_AURAS & set(auras):
        raise ValueError(f'{spec.spell} {KIND} power aura {spec.power_aura} carries no maximum health aura '
                         f'{sorted(HEALTH_AURAS)}')


def absorb_reads(spec: PowerTermDirectionSpec, reads: dict, cast: int) -> list[dict]:
    strike = {'spell': spec.strike_spell, 'caster': STRIKER, 'target': CASTER}
    return [measurement(reads['absorbs'][cast], CASTER, 'spell_absorb_total', **strike),
            measurement(reads['logs'][cast], CASTER, 'spell_log_count', **strike)]


def absorb_cast_steps(spec: PowerTermDirectionSpec, reads: dict, cast: int) -> list[dict]:
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.cast_spell, 'stacks': 0},
            {'action': 'cast', 'actor': CASTER, 'spell': spec.refill_spell, 'ignore_gcd': True},
            {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell},
            {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell},
            {'action': 'wait', 'label': 'barrier cast', 'ms': spec.cast_wait_ms},
            measurement(reads['held'][cast - 1], CASTER, 'aura', spell=spec.cast_spell),
            {'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
            {'action': 'wait', 'label': 'barrier strike', 'ms': STRIKE_SETTLE_MS},
            measurement(reads['remaining'][cast - 1], CASTER, 'aura', spell=spec.cast_spell),
            *absorb_reads(spec, reads, cast)]


def absorb_text(spec: PowerTermDirectionSpec) -> str:
    return (f'; before each cast the previous {spec.cast_spell} barrier is cleared (set_aura 0) and '
            f'{spec.refill_spell} refills the caster\'s health, then {spec.cast_spell} is cast, its presence read, '
            f'and a passive, stationary striker (creature entry {TAKEN_HIT_STRIKER_ENTRY}) strikes the caster once '
            f'with {spec.strike_spell}: the absorbed amount of that strike (spell_absorb_total) is one sample when the '
            f'barrier was up after the cast, gone after the strike and the strike logged once; a refused cast, an '
            f'unbroken barrier or a missing strike is no sample. The sample proves the direction of the term only, not '
            f'that the barrier absorbs damage.')


def power_term_direction_scenario(class_file: dict, spec: PowerTermDirectionSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 0.0)
    check_power_aura(records, spec)
    facts = facts_of(records, spec.cast_spell)
    if spec.sample == ABSORB and facts.aura_names[0] != ABSORB_AURA:
        raise ValueError(f'{spec.spell} {KIND} absorb sample needs {spec.cast_spell} effect 0 '
                         f'SPELL_AURA_SCHOOL_ABSORB')
    if spec.cast_power is not None:
        if spec.cast_power < facts.mana_cost or facts.mana_cost_percentage:
            raise ValueError(f'{spec.spell} {KIND} cast_power {spec.cast_power} does not pay the flat cost '
                             f'{facts.mana_cost} of {spec.cast_spell}')
        mana = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power}]
    else:
        mana = base_mana_steps(class_file, facts)
    if not mana and (facts.mana_cost or facts.mana_cost_percentage):
        raise ValueError(f'{spec.spell} {KIND} casts {spec.cast_spell}, whose cost is not a percentage of base mana')
    power_name = POWER_METRICS[spec.power_metric]
    hit_spell = spec.cast_spell if spec.hit_spell is None else spec.hit_spell
    fixtures = [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
                for spell, stacks in spec.attempt_auras]
    named = (f'{records.field("Spell", spec.power_aura, "SpellName[enUS]")} {spec.power_aura}'
             + (f' ({spec.power_stacks} stacks)' if spec.power_stacks != 1 else '')
             + ''.join(f' with {records.field("Spell", spell, "SpellName[enUS]")} {spell} ({stacks} stacks)'
                       for spell, stacks, _ in spec.power_companions)
             + ' set by harness set_aura on the caster for the high arms' + ''.join(
                 f', {records.field("Spell", spell, "SpellName[enUS]")} {spell} ({stacks} stacks) before each cast'
                 for spell, stacks in spec.attempt_auras))
    reads = {arm: arm_reads(spec, arm) for arm in ARMS}
    where = 'on the caster' if spec.sample == ABSORB else 'at the dummy'
    if spec.power_metric == ATTACK_POWER:
        read_text = 'The attack power is read before each arm'
    else:
        read_text = (f'The {power_name} and the attack power are read before and after each arm (the fixtures\' '
                     f'effect is measured); an arm whose {power_name} moved inside it, or an attack power that is not '
                     f'the same in every read, voids the run')
    if spec.sample == ABSORB:
        read_text += absorb_text(spec)
    elif spec.hit_spell is not None:
        read_text += f' and each non-critical hit of {spec.hit_spell} is one sample.'
    else:
        read_text += ' and each non-critical hit is one sample.'

    def sample(arm: str, cast: int) -> list[dict]:
        if spec.sample == ABSORB:
            return absorb_reads(spec, reads[arm], cast)
        return [measurement(reads[arm]['totals'][cast], CASTER, 'spell_damage_total', spell=hit_spell,
                            target=TARGET, critical=False),
                measurement(reads[arm]['counts'][cast], CASTER, 'spell_damage_count', spell=hit_spell,
                            target=TARGET, critical=False)]

    def phase(arm: str) -> list[dict]:
        steps = [power_read(spec, reads[arm]['power'])]
        if spec.power_metric != ATTACK_POWER:
            steps.append(measurement(reads[arm]['attack power'], CASTER, 'attack_power'))
        steps += sample(arm, 0)
        for cast in range(1, spec.casts + 1):
            if spec.sample == ABSORB:
                steps += [*mana, *fixtures, *absorb_cast_steps(spec, reads[arm], cast)]
                continue
            steps += [*mana, *fixtures, {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.cast_spell},
                      {'action': 'cast', 'actor': CASTER, 'spell': spec.cast_spell, 'target': TARGET},
                      {'action': 'wait', 'label': f'{arm} cast', 'ms': spec.cast_wait_ms}] + sample(arm, cast)
        if spec.power_metric != ATTACK_POWER:
            steps += [power_read(spec, reads[arm]['power after']),
                      measurement(reads[arm]['attack power after'], CASTER, 'attack_power')]
        return steps

    def power(on: bool) -> list[dict]:
        return [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks if on else 0}
                for spell, stacks in ((spec.power_aura, spec.power_stacks),
                                      *((spell, stacks) for spell, stacks, _ in spec.power_companions))]

    learned = [spec.cast_spell] + ([spec.refill_spell] if spec.sample == ABSORB else [])
    steps = (base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
             + phase('control low') + power(True) + phase('control high')
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}] + phase('learned high')
             + power(False) + phase('learned low'))
    if len(steps) > MAXIMUM_STEPS:
        raise ValueError(f'{spec.spell} {KIND} needs {len(steps)} steps, more than {MAXIMUM_STEPS}')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour power term direction',
        'contract': (f'{spec.cast_spell} is cast {where} {spec.casts} times in each of four arms: without '
                     f'{spec.talent} at the base {power_name}, without it with the {power_name} aura '
                     f'{spec.power_aura} ({spec.power_aura_source}), with {spec.talent} learned and the aura, and '
                     f'with {spec.talent} after the aura is removed. {read_text} The interaction (learned high - '
                     f'control high) - (learned low - control low) must reach the one-sided '
                     f'{DIRECTION_PROBABILITY:.1%} Student t quantile at its Welch-Satterthwaite degrees of freedom '
                     f'(Welch standard error; z '
                     f'{NormalDist().inv_cdf(DIRECTION_PROBABILITY):.2f} at infinite freedom) while the control arms '
                     f'do not grow with {power_name}: {OK_TEXT}. The control check is two-sided at the '
                     f'{CONTROL_PROBABILITY:.3%} Student t quantile at the control arms\' Welch-Satterthwaite '
                     f'degrees of freedom (z {NormalDist().inv_cdf(CONTROL_PROBABILITY):.2f} at infinite freedom): '
                     f'its false alert is {CONTROL_FALSE_ALERT_PER_RUN:.3%} per run and '
                     f'{CONTROL_FALSE_ALERT_PER_PAIR:.1%} per pair; a false pass needs the interaction above its '
                     f'quantile in both runs, at most {1 - DIRECTION_PROBABILITY:.1%} per run.'
                     + ''.join(f' Aura {spell} is set on the caster at {stacks} stacks before each cast.'
                               for spell, stacks in spec.attempt_auras)
                     + (f' The caster\'s power {facts.power_type} is set to {spec.cast_power} before each cast.'
                        if spec.cast_power is not None else '')
                     + ''.join(f' Aura {spell} is set at {stacks} stacks with the {power_name} aura in the high arms '
                               f'({source}).' for spell, stacks, source in spec.power_companions)),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)] + ([
            {'id': STRIKER, 'owner': CASTER, 'entry': TAKEN_HIT_STRIKER_ENTRY, 'level': class_file['level'],
             'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'stationary': True, 'spell_hit_bonus': 100}]
            if spec.sample == ABSORB else []),
        'steps': steps}
    model = {'kind': KIND, 'metric': 'spell_absorb_total' if spec.sample == ABSORB else 'spell_damage_total',
             'quote': entry.quote,
             'direction_probability': DIRECTION_PROBABILITY, 'control_probability': CONTROL_PROBABILITY,
             'minimum_samples': MIN_SAMPLES, 'power_aura': spec.power_aura, 'fixture': named, 'reads': reads}
    if spec.power_metric != ATTACK_POWER:
        model['power_name'] = power_name
    if spec.sample == ABSORB:
        model['sample'] = ABSORB
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.talent, None,
                              'direction', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def arm_samples(values: dict, reads: dict) -> list[float]:
    if 'absorbs' in reads:
        absorbs, logs = [values[label] for label in reads['absorbs']], [values[label] for label in reads['logs']]
        return [absorbs[cast] - absorbs[cast - 1] for cast in range(1, len(absorbs))
                if values[reads['held'][cast - 1]] == 1 and values[reads['remaining'][cast - 1]] == 0
                and logs[cast] - logs[cast - 1] == 1]
    totals, counts = [values[label] for label in reads['totals']], [values[label] for label in reads['counts']]
    return [totals[cast] - totals[cast - 1] for cast in range(1, len(totals))
            if counts[cast] - counts[cast - 1] == 1]


def z_of(difference: float, error: float) -> float:
    if error > 0:
        return difference / error
    return math.inf if difference > 0 else -math.inf if difference < 0 else 0.0


@dataclass(frozen=True)
class Statistic:
    difference: float
    error: float
    dof: float

    @property
    def z(self) -> float:
        return z_of(self.difference, self.error)


@dataclass(frozen=True)
class Judged:
    means: dict[str, float]
    control: Statistic
    learned_growth: float
    interaction: Statistic


def welch(difference: float, arms: list[tuple[float, int]]) -> Statistic:
    shares = sum(share for share, _ in arms)
    dof = shares ** 2 / sum(share ** 2 / (count - 1) for share, count in arms) if shares > 0 else math.inf
    return Statistic(difference, math.sqrt(shares), dof)


def judged_samples(samples: dict[str, list[float]]) -> Judged:
    means = {arm: fmean(found) for arm, found in samples.items()}
    arms = {arm: (variance(found) / len(found), len(found)) for arm, found in samples.items()}
    control = means['control high'] - means['control low']
    learned = means['learned high'] - means['learned low']
    return Judged(means, welch(control, [arms['control high'], arms['control low']]), learned,
                  welch(learned - control, list(arms.values())))


def reaches(z: float, probability: float, dof: float) -> bool:
    return z >= NormalDist().inv_cdf(probability) and z >= student_t_quantile(probability, dof)


def control_alerts(judged: Judged, probability: float = CONTROL_PROBABILITY) -> bool:
    return reaches(abs(judged.control.z), probability, judged.control.dof)


def direction_passes(judged: Judged, probability: float = DIRECTION_PROBABILITY) -> bool:
    return reaches(judged.interaction.z, probability, judged.interaction.dof)


def quantile_text(probability: float, dof: float) -> str:
    return f'{student_t_quantile(probability, dof):.2f} at {dof:.1f} degrees of freedom'


def power_term_direction_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    name = model.get('power_name', 'attack power')
    labels = [label for arm in reads.values() for read in arm.values()
              for label in (read if isinstance(read, list) else [read])]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    power = {arm: run.values[reads[arm]['power']] for arm in reads}
    after = {arm: run.values[reads[arm]['power after']] for arm in reads if 'power after' in reads[arm]}
    if not all(found['control high'] > found['control low'] and found['learned high'] > found['learned low']
               for found in (power, after) if found):
        return replace(base, status='unmeasured',
                       explanation=f'the {name} aura {model["power_aura"]} did not raise the {name} '
                                   f'(read {", ".join(f"{arm} {value:g}" for arm, value in power.items())}'
                                   + (f'; after {", ".join(f"{arm} {value:g}" for arm, value in after.items())}'
                                      if after else '') + ')')
    attack = ({arm: run.values[reads[arm]['attack power']] for arm in reads}
              if 'attack power' in reads['control low'] else {})
    attack_after = {arm: run.values[reads[arm]['attack power after']] for arm in reads
                    if 'attack power after' in reads[arm]}
    moved = [arm for arm in after if after[arm] != power[arm]]
    if moved or len({*attack.values(), *attack_after.values()}) > 1:
        return replace(base, status='unmeasured',
                       explanation=f'a fixture moved inside an arm: {name} before / after '
                                   + ', '.join(f'{arm} {power[arm]:g} / {after[arm]:g}' for arm in after)
                                   + '; attack power before / after '
                                   + ', '.join(f'{arm} {attack[arm]:g} / {attack_after.get(arm, attack[arm]):g}'
                                               for arm in attack))
    samples = {arm: arm_samples(run.values, reads[arm]) for arm in reads}
    short = {arm: len(found) for arm, found in samples.items() if len(found) < model['minimum_samples']}
    if short:
        unit = 'barriers' if model.get('sample') == ABSORB else 'non-critical hits'
        return replace(base, status='insufficient_trials',
                       explanation=f'fewer than {model["minimum_samples"]} {unit} in {short}')
    found = judged_samples(samples)
    control, interaction = found.control, found.interaction
    control_p, direction_p = model['control_probability'], model['direction_probability']
    sampled = 'mean barrier' if model.get('sample') == ABSORB else 'mean non-critical hit'
    stated = (f'{name} {power["control low"]:g} / {power["control high"]:g} (control), '
              f'{power["learned low"]:g} / {power["learned high"]:g} (learned)'
              + (f', after the arms {after["control low"]:g} / {after["control high"]:g} (control), '
                 f'{after["learned low"]:g} / {after["learned high"]:g} (learned)' if after else '')
              + (f'; attack power {", ".join(f"{arm} {value:g}" for arm, value in attack.items())}' if attack else '')
              + f'; {sampled} '
              + ', '.join(f'{arm} {mean:.2f} ({len(samples[arm])})' for arm, mean in found.means.items())
              + f'; control growth {control.difference:.2f} (z {control.z:.2f} against the two-sided t quantile '
                f'{quantile_text(control_p, control.dof)}), learned growth {found.learned_growth:.2f}, interaction '
                f'{interaction.difference:.2f} (Welch standard error {interaction.error:.2f}, z {interaction.z:.2f} '
                f'against the one-sided t quantile {quantile_text(direction_p, interaction.dof)}); '
                f'fixture: {model["fixture"]}')
    detail = {'interaction': interaction.difference, 'standard_error': interaction.error, 'z': interaction.z,
              'dof': interaction.dof, 'control_growth': control.difference, 'control_z': control.z,
              'control_dof': control.dof, 'learned_growth': found.learned_growth, 'means': found.means,
              'attack_power': power}
    if name != 'attack power':
        detail = {**detail, 'attack_power': attack, 'attack_power_after': attack_after, 'power': power,
                  'power_after': after}
    measured = interaction.difference
    quantity = 'absorb' if model.get('sample') == ABSORB else 'damage'
    if control_alerts(found, control_p):
        return replace(base, status='alert', measured=measured, detail=detail,
                       explanation=f'without the passive the {quantity} changes with {name}: {stated}')
    if not direction_passes(found, direction_p):
        return replace(base, status='alert', measured=measured, detail=detail,
                       explanation=f'the passive adds no {quantity} that grows with {name}: {stated}')
    return replace(base, status='ok', measured=measured, detail=detail, explanation=f'{OK_TEXT}: {stated}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return power_term_direction_scenario(class_file, power_term_direction_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'power_direction')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: power_term_direction_verdict}
