from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, ally_group_steps, ally_players, behaviour_entry, prose_rule, waited_ms
from compare import NO_CAST_FAILURE, Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, timed
from procs import HEAL_COUNT, HEAL_POOL, rate_band, residual_sizing, residual_z, wilson_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, CAST_MARGIN_MS, Expectation, dataset, facts_of

HEAL_RATE = 'heal_rate'
FEED_TARGETS = {'ally': ALLY, 'self': CASTER}
RATE_FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'feed_spell', 'aura', 'chance_spell',
               'feed_target', 'feed_power', 'rolls', 'residual_target', 'min_detectable', 'observe_source',
               'haste_aura'}
COOLDOWN_FIELDS = ('RecoveryTime', 'CategoryRecoveryTime')
APPLY_AURA = 6
MOD_CASTING_SPEED_NOT_STACK = 65
INSTANT_CAST_AMOUNT = 1000
EFFECTS = range(3)
CLASS_MASKS = range(9)


@dataclass(frozen=True)
class RateSpec:
    spell: int
    name: str
    quote: str
    feed_spell: int
    aura: int
    chance_spell: int
    feed_target: str
    feed_power: int
    rolls: int
    residual_target: float
    min_detectable: float
    label_suffix: str
    haste_aura: int = 0


def is_rate(entry: dict) -> bool:
    variant = entry.get('variant', '')
    return variant == HEAL_RATE or variant.startswith(f'{HEAL_RATE}_')


def rate_spec(entry: dict) -> RateSpec:
    unknown = set(entry) - RATE_FIELDS
    if unknown or entry.get('feed_target') not in FEED_TARGETS or not isinstance(entry.get('rolls'), int) \
            or entry['rolls'] < 1:
        raise ValueError(f'{entry.get("spell")} aura_fed_effect {HEAL_RATE} takes {sorted(RATE_FIELDS)}, a '
                         f'feed_target of {sorted(FEED_TARGETS)} and a positive integer rolls; unknown '
                         f'{sorted(unknown)}')
    return RateSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['feed_spell']), int(entry['aura']),
                    int(entry.get('chance_spell', entry['spell'])), entry['feed_target'], int(entry['feed_power']),
                    entry['rolls'], float(entry['residual_target']), float(entry['min_detectable']),
                    entry['label_suffix'], int(entry.get('haste_aura', 0)))


def mark(spec: RateSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def rate_sizing(records: Records, spec: RateSpec) -> tuple[float, dict]:
    chance = records.field('Spell', spec.chance_spell, 'ProcChance')
    if not 0 < chance < 100:
        raise ValueError(f'{spec.spell} {HEAL_RATE} needs a ProcChance of {spec.chance_spell} between 0 and 100')
    sizing = residual_sizing({'aura': spec.spell, 'band': True, 'residual_target': spec.residual_target,
                              'min_detectable': spec.min_detectable}, chance)
    return chance / 100, sizing


def haste_amount(records: Records, aura: int) -> int:
    field = lambda name: records.field('Spell', aura, name)
    used = [index for index in EFFECTS if field(f'Effect[{index}]')]
    clean = (used and all(field(f'Effect[{index}]') == APPLY_AURA
                          and field(f'EffectApplyAuraName[{index}]') == MOD_CASTING_SPEED_NOT_STACK
                          for index in used)
             and not field('ProcFlags') and not field('SpellFamilyName')
             and not any(field(f'EffectSpellClassMask[{mask}]') for mask in CLASS_MASKS))
    amounts = {records.single_value(aura, index) for index in used} if clean else set()
    if len(amounts) != 1 or not 0 < next(iter(amounts)) < INSTANT_CAST_AMOUNT:
        raise ValueError(f'haste_aura {aura} must apply only SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK below '
                         f'{INSTANT_CAST_AMOUNT}, with no proc flags, spell family or class mask')
    return int(next(iter(amounts)))


def cast_ms(records: Records, spec: RateSpec) -> int:
    cast = facts_of(records, spec.feed_spell).cast_time_ms
    if not spec.haste_aura:
        return cast
    return math.ceil(cast * 100 / (100 + haste_amount(records, spec.haste_aura)))


def roll_ms(records: Records, spec: RateSpec) -> int:
    cooldown = max(records.field('Spell', spec.feed_spell, field) for field in COOLDOWN_FIELDS)
    gcd = 0 if spec.haste_aura else records.field('Spell', spec.feed_spell, 'StartRecoveryTime')
    step = cast_ms(records, spec) + CAST_MARGIN_MS
    if cooldown or gcd > step or records.field('Spell', spec.feed_spell, 'Speed'):
        raise ValueError(f'{spec.spell} {HEAL_RATE} feed {spec.feed_spell} needs no cooldown, no travel and a '
                         f'global cooldown within its {step} ms roll')
    return step


def rate_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = rate_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    chance, sizing = rate_sizing(records, spec)
    step_ms = roll_ms(records, spec)
    power = facts_of(records, spec.feed_spell).power_type
    target = FEED_TARGETS[spec.feed_target]
    other = CASTER if target == ALLY else None
    described = behaviour_entry(records, spec.spell, spec.name, 'aura_fed_effect', spec.quote, chance)

    def roll(index: int) -> list[dict]:
        return [{'action': 'set_health', 'actor': target, 'value': 1, 'maximum': HEAL_POOL},
                {'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura},
                {'action': 'set_power', 'actor': CASTER, 'power': power, 'value': spec.feed_power},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.feed_spell, 'target': target,
                 **({'ignore_gcd': True} if spec.haste_aura else {})},
                {'action': 'wait', 'label': f'roll {index} lands', 'ms': step_ms},
                measurement(mark(spec, f'roll {index} aura'), CASTER, 'aura', spell=spec.aura),
                measurement(mark(spec, f'roll {index} heals'), CASTER, HEAL_COUNT, spell=spec.feed_spell,
                            target=target)]

    targets = {ALLY} if target == ALLY else set()
    steps = (base_steps(class_file) + ally_group_steps(targets)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell, spec.spell))])
    if spec.haste_aura:
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.haste_aura, 'stacks': 1},
                  measurement(mark(spec, 'cast time'), CASTER, 'spell_cast_time_ms', spell=spec.feed_spell)]
    for index in range(spec.rolls):
        steps += roll(index)
    steps.append(measurement(mark(spec, 'failure'), CASTER, 'cast_failure', spell=spec.feed_spell))
    if other:
        steps.append(measurement(mark(spec, 'other effective'), CASTER, 'spell_effective_heal_total',
                                 spell=spec.feed_spell, target=other))
    band = rate_band(chance)
    z = residual_z(spec.residual_target)
    reads = {'rolls': [{'aura': mark(spec, f'roll {index} aura'), 'heals': mark(spec, f'roll {index} heals')}
                       for index in range(spec.rolls)],
             'failure': mark(spec, 'failure'), **({'other': mark(spec, 'other effective')} if other else {}),
             **({'cast_time': mark(spec, 'cast time')} if spec.haste_aura else {})}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed rate',
        'contract': (f'{spec.spell} is learned.'
                     + (f' The haste aura {spec.haste_aura} (only SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK '
                        f'{haste_amount(records, spec.haste_aura)}, no proc, family or class mask) is set on the '
                        f'caster before the rolls, the cast time of {spec.feed_spell} is read once after it, and '
                        f'every feed is cast with ignore_gcd.' if spec.haste_aura else '')
                     + f' {spec.rolls} rolls, each one {spec.feed_spell} cast at the {spec.feed_target} ({target}) '
                     f'set to 1 health of a {HEAL_POOL} maximum, after {spec.aura} '
                     f'is cancelled on the caster; {step_ms} ms later (cast time {cast_ms(records, spec)} + '
                     f'{CAST_MARGIN_MS} ms) {spec.aura} '
                     f'is read on the caster (1 = the roll succeeded) and {HEAL_COUNT} of {spec.feed_spell} on the '
                     f'{spec.feed_target} must have risen by exactly 1, and the last cast failure of '
                     f'{spec.feed_spell} must be {NO_CAST_FAILURE}'
                     + (f', and the effective healing of {spec.feed_spell} on the caster (full health) must be 0'
                        if other else '')
                     + f', else the run is unmeasured. The aura is never set by the harness. The rate is the share of '
                     f'rolls reading {spec.aura}; the Wilson interval at z {z:.3f} (residual_target '
                     f'{spec.residual_target:g} per pair) must lie inside {(chance - band) * 100:g}% to '
                     f'{(chance + band) * 100:g}% (ProcChance {chance * 100:g} of {spec.chance_spell}, band '
                     f'max(5% relative, 2 points), G-20); an interval outside the band alerts, one straddling its '
                     f'edge is unmeasured with the interval stated; the band needs {sizing["trials"]} rolls at a '
                     f'{spec.min_detectable:g}-point minimum detectable shift.'),
        'players': [player_fixture(class_file)] + ally_players(class_file, targets),
        'creatures': [],
        'steps': steps}
    model = {'kind': 'aura_fed_effect', 'variant': HEAL_RATE, 'metric': 'aura', 'quote': described.quote,
             'expected': chance, 'band': band, 'z': z, 'needed': sizing['trials'], 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.feed_spell, None,
                              f'{chance:g}', prose_rule(described.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def rate_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    labels = [label for roll in reads['rolls'] for label in roll.values()]
    labels += [reads[key] for key in ('failure', 'other', 'cast_time') if key in reads]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    heals = [run.values[roll['heals']] for roll in reads['rolls']]
    if heals != [float(index + 1) for index in range(len(heals))]:
        first = next(index for index, value in enumerate(heals) if value != index + 1)
        return replace(base, status='unmeasured',
                       explanation=f'void: roll {first} read {heals[first]:g} heals, {first + 1} needed (a refused '
                                   f'or extra feed heal)')
    failure = run.values[reads['failure']]
    other = run.values.get(reads.get('other', ''), 0.0)
    if failure != NO_CAST_FAILURE or other:
        return replace(base, status='unmeasured',
                       explanation=f'void: last feed cast failure {failure:g}, effective heal on the caster {other:g}')
    auras = [run.values[roll['aura']] for roll in reads['rolls']]
    if any(value not in (0.0, 1.0) for value in auras):
        return replace(base, status='unmeasured', explanation=f'aura reads outside 0 and 1: {sorted(set(auras))}')
    events, trials = sum(auras), float(len(auras))
    low, high = wilson_interval(events, trials, model['z'])
    chance, band = model['expected'], model['band']
    inside = chance - band <= low and high <= chance + band
    outside = high < chance - band or low > chance + band
    status = 'ok' if inside else 'alert' if outside else 'unmeasured'
    return replace(base, status=status, measured=events / trials, expected=chance, low=chance - band,
                   high=chance + band,
                   explanation=f'{events:g} of {trials:g} rolls read the aura: rate {events / trials:.4f}, Wilson '
                               f'interval {low:.4f} to {high:.4f} (z {model["z"]:.3f}) against the band '
                               f'{chance - band:.4f} to {chance + band:.4f}'
                               + ('' if inside or outside else
                                  f'; interval stated, the band needs {model["needed"]} rolls')
                               + (f'; hasted cast time read {run.values[reads["cast_time"]]:g} ms'
                                  if 'cast_time' in reads else ''))
