from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, ally_group_steps, ally_players, behaviour_entry, dummy_fixture,
                        dummy_id, prose_rule, waited_ms)
from compare import NO_CAST_FAILURE, Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, timed
from procs import HEAL_COUNT, HEAL_POOL, rate_band, residual_sizing, residual_z, wilson_interval
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, CAST_MARGIN_MS, Expectation, cast_distance, dataset, facts_of

HEAL_RATE = 'heal_rate'
DAMAGE_RATE = 'damage_rate'
DAMAGE_FEED_TARGET = 'dummy'
SCHOOL_DAMAGE = 2
FEED_TARGETS = {'ally': ALLY, 'self': CASTER}
RATE_FIELDS = {'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'feed_spell', 'aura', 'chance_spell',
               'feed_target', 'feed_power', 'rolls', 'residual_target', 'min_detectable', 'observe_source',
               'haste_aura', 'parts', 'spare_parts', 'haste_agreement', 'learn_talent'}
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
    parts: int = 1
    spare_parts: int = 0
    haste_agreement: str = ''
    learn_talent: bool = True


def rate_family(variant: str) -> str | None:
    return next((family for family in (HEAL_RATE, DAMAGE_RATE)
                 if variant == family or variant.startswith(f'{family}_')), None)


def is_rate(entry: dict) -> bool:
    return rate_family(entry.get('variant', '')) is not None


def is_rate_model(model: dict) -> bool:
    return model.get('variant') in (HEAL_RATE, DAMAGE_RATE)


def rate_spec(entry: dict) -> RateSpec:
    damage = rate_family(entry.get('variant', '')) == DAMAGE_RATE
    unknown = set(entry) - (RATE_FIELDS - {'haste_aura', 'haste_agreement'} if damage else RATE_FIELDS - {'learn_talent'})
    targets = {DAMAGE_FEED_TARGET} if damage else FEED_TARGETS
    if unknown or entry.get('feed_target') not in targets or not isinstance(entry.get('rolls'), int) \
            or entry['rolls'] < 1:
        raise ValueError(f'{entry.get("spell")} aura_fed_effect {HEAL_RATE} takes {sorted(RATE_FIELDS)}, a '
                         f'feed_target of {sorted(FEED_TARGETS)} and a positive integer rolls; unknown '
                         f'{sorted(unknown)}')
    parts, spare = entry.get('parts', 1), entry.get('spare_parts', 0)
    pooled = isinstance(parts, int) and parts > 1
    if not isinstance(parts, int) or not isinstance(spare, int) or parts < 1 \
            or (pooled and not 1 <= spare < parts) or (not pooled and spare) \
            or (pooled and entry.get('haste_aura') and not str(entry.get('haste_agreement', '')).strip()):
        raise ValueError(f'{entry.get("spell")} {HEAL_RATE} pooled parts need 1 <= spare_parts < parts, and a '
                         f'haste_aura on pooled parts needs its haste_agreement')
    learn = entry.get('learn_talent', True)
    if not isinstance(learn, bool) or (not learn and pooled):
        raise ValueError(f'{entry.get("spell")} {DAMAGE_RATE} learn_talent is a boolean, and false (the control arm) '
                         f'takes a single part')
    return RateSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['feed_spell']), int(entry['aura']),
                    int(entry.get('chance_spell', entry['spell'])), entry['feed_target'], int(entry['feed_power']),
                    entry['rolls'], float(entry['residual_target']), float(entry['min_detectable']),
                    entry['label_suffix'], int(entry.get('haste_aura', 0)), parts, spare,
                    str(entry.get('haste_agreement', '')), learn)


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
    if rate_family(entry.get('variant', '')) == DAMAGE_RATE:
        return damage_rate_scenario(class_file, entry)
    spec = rate_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    chance, sizing = rate_sizing(records, spec)
    step_ms = roll_ms(records, spec)
    power = facts_of(records, spec.feed_spell).power_type
    target = FEED_TARGETS[spec.feed_target]
    other = CASTER if target == ALLY else None
    described = behaviour_entry(records, spec.spell, spec.name, 'aura_fed_effect', spec.quote, chance)
    kept = (spec.parts - spec.spare_parts) * spec.rolls
    if spec.parts > 1 and kept < sizing['trials']:
        raise ValueError(f'{spec.spell} {HEAL_RATE} pools {spec.parts} parts of {spec.rolls} rolls with '
                         f'{spec.spare_parts} spare: {kept} rolls, below the {sizing["trials"]} the band needs')

    def roll(index: int) -> list[dict]:
        return [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura},
                {'action': 'set_power', 'actor': CASTER, 'power': power, 'value': spec.feed_power},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.feed_spell, 'target': target,
                 **({'ignore_gcd': True} if spec.haste_aura else {})},
                {'action': 'wait', 'label': f'roll {index} lands', 'ms': step_ms},
                measurement(mark(spec, f'roll {index} aura'), CASTER, 'aura', spell=spec.aura)]

    targets = {ALLY} if target == ALLY else set()
    steps = (base_steps(class_file) + ally_group_steps(targets)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell, spec.spell))]
             + [{'action': 'set_health', 'actor': target, 'value': 1, 'maximum': HEAL_POOL}])
    if spec.haste_aura:
        steps += [{'action': 'set_aura', 'actor': CASTER, 'spell': spec.haste_aura, 'stacks': 1},
                  measurement(mark(spec, 'cast time'), CASTER, 'spell_cast_time_ms', spell=spec.feed_spell),
                  measurement(mark(spec, 'haste start'), CASTER, 'aura', spell=spec.haste_aura)]
    for index in range(spec.rolls):
        steps += roll(index)
    steps += [measurement(mark(spec, 'heals'), CASTER, HEAL_COUNT, spell=spec.feed_spell, target=target),
              measurement(mark(spec, 'heal total'), CASTER, 'spell_heal_total', spell=spec.feed_spell, target=target),
              measurement(mark(spec, 'effective total'), CASTER, 'spell_effective_heal_total', spell=spec.feed_spell,
                          target=target),
              measurement(mark(spec, 'failure'), CASTER, 'cast_failure', spell=spec.feed_spell)]
    if spec.haste_aura:
        steps.append(measurement(mark(spec, 'haste end'), CASTER, 'aura', spell=spec.haste_aura))
    if other:
        steps.append(measurement(mark(spec, 'other effective'), CASTER, 'spell_effective_heal_total',
                                 spell=spec.feed_spell, target=other))
    band = rate_band(chance)
    z = residual_z(spec.residual_target)
    reads = {'rolls': [mark(spec, f'roll {index} aura') for index in range(spec.rolls)],
             'heals': mark(spec, 'heals'), 'heal_total': mark(spec, 'heal total'),
             'effective_total': mark(spec, 'effective total'), 'failure': mark(spec, 'failure'),
             **({'other': mark(spec, 'other effective')} if other else {}),
             **({'cast_time': mark(spec, 'cast time'), 'haste': [mark(spec, 'haste start'), mark(spec, 'haste end')]}
                if spec.haste_aura else {})}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed rate',
        'contract': (f'{spec.spell} is learned.'
                     + (f' The haste aura {spec.haste_aura} (only SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK '
                        f'{haste_amount(records, spec.haste_aura)}, no proc, family or class mask) is set on the '
                        f'caster before the rolls, the cast time of {spec.feed_spell} is read once after it, the '
                        f'aura must read 1 at the start and the end, and every feed is cast with ignore_gcd'
                        + (f' ({spec.haste_agreement})' if spec.haste_agreement else '') + '.'
                        if spec.haste_aura else '')
                     + f' The {spec.feed_target} ({target}) is set once to 1 health of a {HEAL_POOL} maximum. '
                     f'{spec.rolls} rolls, each one {spec.feed_spell} cast at it after {spec.aura} '
                     f'is cancelled on the caster; {step_ms} ms later (cast time {cast_ms(records, spec)} + '
                     f'{CAST_MARGIN_MS} ms) {spec.aura} '
                     f'is read on the caster (1 = the roll succeeded). At the end {HEAL_COUNT} of {spec.feed_spell} '
                     f'on the {spec.feed_target} must equal the rolls (no refused or extra heal), its effective '
                     f'healing must equal its healing (every heal effective), and the last cast failure of '
                     f'{spec.feed_spell} must be {NO_CAST_FAILURE}'
                     + (f', and the effective healing of {spec.feed_spell} on the caster (full health) must be 0'
                        if other else '')
                     + f', else the run is unmeasured. The aura is never set by the harness. The rate is the share of '
                     f'rolls reading {spec.aura}; the Wilson interval at z {z:.3f} (residual_target '
                     f'{spec.residual_target:g} per pair) must lie inside {(chance - band) * 100:g}% to '
                     f'{(chance + band) * 100:g}% (ProcChance {chance * 100:g} of {spec.chance_spell}, band '
                     f'max(5% relative, 2 points), G-20); an interval outside the band alerts, one straddling its '
                     f'edge is unmeasured with the interval stated; the band needs {sizing["trials"]} rolls at a '
                     f'{spec.min_detectable:g}-point minimum detectable shift.'
                     + (f' Pooled: {spec.parts} identical parts of {spec.rolls} rolls, {spec.spare_parts} of them '
                        f'spare; a part with any void or missing read is excluded whole, and the pooled rolls of the '
                        f'kept parts must reach {sizing["trials"]}, else the run is unmeasured (fixed before the '
                        f'run: {kept} rolls if {spec.spare_parts} part(s) drop out).' if spec.parts > 1 else '')),
        'players': [player_fixture(class_file)] + ally_players(class_file, targets),
        'creatures': [],
        'steps': steps}
    model = {'kind': 'aura_fed_effect', 'variant': HEAL_RATE, 'metric': 'aura', 'quote': described.quote,
             'expected': chance, 'band': band, 'z': z, 'needed': sizing['trials'], 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.feed_spell, None,
                              f'{chance:g}', prose_rule(described.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def part_counts(run: Run, model: dict) -> tuple[float, float, float | None, str | None]:
    reads = model['reads']
    labels = list(reads['rolls'])
    labels += [reads[key] for key in ('heals', 'heal_total', 'effective_total', 'failure', 'other', 'cast_time')
               if key in reads]
    labels += reads.get('haste', [])
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return 0.0, 0.0, None, missing_measurement(run, missing)
    heals, rolls = run.values[reads['heals']], len(reads['rolls'])
    if heals != rolls:
        return 0.0, 0.0, None, f'void: {heals:g} feed heals for {rolls} rolls (a refused or extra feed heal)'
    total, effective = run.values[reads['heal_total']], run.values[reads['effective_total']]
    if effective != total or total <= 0:
        return 0.0, 0.0, None, f'void: effective feed healing {effective:g} of {total:g} (an overheal)'
    failure = run.values[reads['failure']]
    other = run.values.get(reads.get('other', ''), 0.0)
    if failure != NO_CAST_FAILURE or other:
        return 0.0, 0.0, None, f'void: last feed cast failure {failure:g}, effective heal on the caster {other:g}'
    haste = [run.values[label] for label in reads.get('haste', [])]
    if any(value != 1.0 for value in haste):
        return 0.0, 0.0, None, f'void: the haste aura read {haste} at the part start and end, 1 needed'
    auras = [run.values[label] for label in reads['rolls']]
    if any(value not in (0.0, 1.0) for value in auras):
        return 0.0, 0.0, None, f'aura reads outside 0 and 1: {sorted(set(auras))}'
    cast_time = run.values[reads['cast_time']] if 'cast_time' in reads else None
    return sum(auras), float(len(auras)), cast_time, None


def control_judgement(base: Verdict, events: float, trials: float, needed: int, notes: str) -> Verdict:
    status = 'alert' if events else 'ok' if trials >= needed else 'unmeasured'
    return replace(base, status=status, measured=events / trials, expected=0.0, low=0.0, high=0.0,
                   explanation=f'{events:g} of {trials:g} rolls read the aura with the talent unlearned, 0 expected'
                               + ('' if status != 'unmeasured' else f'; the arm needs {needed} rolls') + notes)


def rate_judgement(base: Verdict, events: float, trials: float, model: dict, needed: int, notes: str) -> Verdict:
    if model.get('control'):
        return control_judgement(base, events, trials, needed, notes)
    low, high = wilson_interval(events, trials, model['z'])
    chance, band = model['expected'], model['band']
    inside = chance - band <= low and high <= chance + band
    outside = high < chance - band or low > chance + band
    status = 'ok' if inside and trials >= needed else 'alert' if outside else 'unmeasured'
    return replace(base, status=status, measured=events / trials, expected=chance, low=chance - band,
                   high=chance + band,
                   explanation=f'{events:g} of {trials:g} rolls read the aura: rate {events / trials:.4f}, Wilson '
                               f'interval {low:.4f} to {high:.4f} (z {model["z"]:.3f}) against the band '
                               f'{chance - band:.4f} to {chance + band:.4f}'
                               + ('' if status != 'unmeasured' else
                                  f'; interval stated, the band needs {needed} rolls')
                               + notes)


def cast_note(times: list[float]) -> str:
    return f'; hasted cast time read {", ".join(f"{value:g}" for value in sorted(set(times)))} ms' if times else ''


def counts_of(model: dict):
    return damage_part_counts if model['variant'] == DAMAGE_RATE else part_counts


def rate_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    events, trials, cast_time, problem = counts_of(model)(run, model)
    if problem is not None:
        return replace(base, status='unmeasured', explanation=problem)
    return rate_judgement(base, events, trials, model, model['needed'],
                          cast_note([cast_time] if cast_time is not None else []))


def pooled_rate_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    events, trials, times, excluded = 0.0, 0.0, [], []
    for index, run in enumerate(runs):
        part_events, part_trials, cast_time, problem = counts_of(model)(run, model)
        if problem is not None:
            excluded.append(f'part {index + 1}: {problem}')
            continue
        events, trials = events + part_events, trials + part_trials
        times += [cast_time] if cast_time is not None else []
    notes = (f'; {len(runs) - len(excluded)} of {len(runs)} parts pooled'
             + (f', excluded whole: {"; ".join(excluded)}' if excluded else '') + cast_note(times))
    if trials < model['needed']:
        return replace(base, status='unmeasured',
                       explanation=f'{trials:g} pooled rolls, {model["needed"]} needed for the band{notes}')
    return rate_judgement(base, events, trials, model, model['needed'], notes)


def damage_roll_ms(records: Records, spec: RateSpec) -> int:
    effects = [records.field('Spell', spec.feed_spell, f'Effect[{index}]') for index in EFFECTS]
    if SCHOOL_DAMAGE not in effects or records.field('Spell', spec.feed_spell, 'Speed'):
        raise ValueError(f'{spec.spell} {DAMAGE_RATE} feed {spec.feed_spell} needs a SCHOOL_DAMAGE effect and no '
                         f'travel')
    return facts_of(records, spec.feed_spell).cast_time_ms + CAST_MARGIN_MS


CONTROL_CONTRACT = (
    'Control arm: {spec.spell} is unlearned and never learned. One stationary dummy stands {distance:g} yd from the '
    'caster. {rolls} rolls, each one {spec.feed_spell} cast at the dummy with ignore_gcd after {spec.aura} is '
    'cancelled on the caster and the cooldown of {spec.feed_spell} is reset; {step} ms later (cast time {cast} + '
    '{margin} ms) {spec.aura} is read on the caster. At the end spell_go_count of {spec.feed_spell} and its '
    'spell_damage_count on the dummy must equal the rolls, the last cast failure must be 0, and the dummy must read '
    'alive with health above 0, else the run is unmeasured. The aura is never set by the harness. Any roll reading '
    '{spec.aura} alerts; {rolls} rolls with none is ok (a {spec.spell} rate of 40% would leave none with probability '
    '0.6^{rolls}).')


def damage_rate_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    spec = rate_spec(entry)
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    chance, sizing = rate_sizing(records, spec)
    step_ms = damage_roll_ms(records, spec)
    power = facts_of(records, spec.feed_spell).power_type
    target = dummy_id(0)
    distance = cast_distance(records, spec.feed_spell)
    described = behaviour_entry(records, spec.spell, spec.name, 'aura_fed_effect', spec.quote, chance)
    kept = (spec.parts - spec.spare_parts) * spec.rolls
    control = not spec.learn_talent
    if spec.parts > 1 and kept < sizing['trials']:
        raise ValueError(f'{spec.spell} {DAMAGE_RATE} pools {spec.parts} parts of {spec.rolls} rolls with '
                         f'{spec.spare_parts} spare: {kept} rolls, below the {sizing["trials"]} the band needs')

    def roll(index: int) -> list[dict]:
        return [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura},
                {'action': 'set_power', 'actor': CASTER, 'power': power, 'value': spec.feed_power},
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.feed_spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.feed_spell, 'target': target, 'ignore_gcd': True},
                {'action': 'wait', 'label': f'roll {index} lands', 'ms': step_ms},
                measurement(mark(spec, f'roll {index} aura'), CASTER, 'aura', spell=spec.aura)]

    steps = (base_steps(class_file)
             + ([{'action': 'unlearn', 'actor': CASTER, 'spell': spec.spell}] if control else [])
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell,) if control else (spec.feed_spell, spec.spell))])
    for index in range(spec.rolls):
        steps += roll(index)
    steps += [measurement(mark(spec, 'casts'), CASTER, 'spell_go_count', spell=spec.feed_spell),
              measurement(mark(spec, 'hits'), CASTER, 'spell_damage_count', spell=spec.feed_spell, target=target),
              measurement(mark(spec, 'failure'), CASTER, 'cast_failure', spell=spec.feed_spell),
              measurement(mark(spec, 'dummy alive'), target, 'alive'),
              measurement(mark(spec, 'dummy health'), target, 'health')]
    band = rate_band(chance)
    z = residual_z(spec.residual_target)
    reads = {'rolls': [mark(spec, f'roll {index} aura') for index in range(spec.rolls)],
             'casts': mark(spec, 'casts'), 'hits': mark(spec, 'hits'), 'failure': mark(spec, 'failure'),
             'alive': mark(spec, 'dummy alive'), 'health': mark(spec, 'dummy health')}
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour aura fed rate',
        'contract': (CONTROL_CONTRACT.format(spec=spec, rolls=spec.rolls, distance=distance, step=step_ms,
                                             cast=facts_of(records, spec.feed_spell).cast_time_ms,
                                             margin=CAST_MARGIN_MS) if control else
                     f'{spec.spell} is learned. One stationary dummy stands {distance:g} yd from the caster. '
                     f'{spec.rolls} rolls, each one {spec.feed_spell} cast at the dummy with ignore_gcd after '
                     f'{spec.aura} is cancelled on the caster and the cooldown of {spec.feed_spell} is reset; '
                     f'{step_ms} ms later (cast time {facts_of(records, spec.feed_spell).cast_time_ms} + '
                     f'{CAST_MARGIN_MS} ms) {spec.aura} is read on the caster (1 = the roll succeeded). At the end '
                     f'spell_go_count of {spec.feed_spell} and its spell_damage_count on the dummy must equal the '
                     f'rolls (no refused, extra or empty cast), the last cast failure of {spec.feed_spell} must be '
                     f'{NO_CAST_FAILURE}, and the dummy must read alive with health above 0, else the run is '
                     f'unmeasured. The aura is never set by the harness. The rate is the share of rolls reading '
                     f'{spec.aura}; the Wilson interval at z {z:.3f} (residual_target {spec.residual_target:g} per '
                     f'pair) must lie inside {(chance - band) * 100:g}% to {(chance + band) * 100:g}% (ProcChance '
                     f'{chance * 100:g} of {spec.chance_spell}, band max(5% relative, 2 points), G-20); an interval '
                     f'outside the band alerts, one straddling its edge is unmeasured with the interval stated; the '
                     f'band needs {sizing["trials"]} rolls at a {spec.min_detectable:g}-point minimum detectable '
                     f'shift.'
                     + (f' Pooled: {spec.parts} identical parts of {spec.rolls} rolls, {spec.spare_parts} of them '
                        f'spare; a part with any void or missing read is excluded whole, and the pooled rolls of the '
                        f'kept parts must reach {sizing["trials"]}, else the run is unmeasured (fixed before the '
                        f'run: {kept} rolls if {spec.spare_parts} part(s) drop out).' if spec.parts > 1 else '')),
        'players': [player_fixture(class_file)],
        'creatures': [dummy_fixture(0, class_file, distance)],
        'steps': steps}
    model = {'kind': 'aura_fed_effect', 'variant': DAMAGE_RATE, 'metric': 'aura', 'quote': described.quote,
             'expected': chance, 'band': band, 'z': z, 'needed': sizing['trials'], 'reads': reads}
    if control:
        model.update({'control': True, 'expected': 0.0, 'band': 0.0, 'needed': spec.rolls})
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.feed_spell, None,
                              f'{chance:g}', prose_rule(described.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def damage_part_counts(run: Run, model: dict) -> tuple[float, float, float | None, str | None]:
    reads = model['reads']
    labels = list(reads['rolls']) + [reads[key] for key in ('casts', 'hits', 'failure', 'alive', 'health')]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return 0.0, 0.0, None, missing_measurement(run, missing)
    rolls = len(reads['rolls'])
    casts, hits = run.values[reads['casts']], run.values[reads['hits']]
    if casts != rolls:
        return 0.0, 0.0, None, f'void: {casts:g} feed casts went off for {rolls} rolls (a refused or extra cast)'
    if hits != rolls:
        return 0.0, 0.0, None, f'void: {hits:g} feed hits on the dummy for {rolls} rolls (a cast that landed nothing)'
    failure = run.values[reads['failure']]
    if failure != NO_CAST_FAILURE:
        return 0.0, 0.0, None, f'void: last feed cast failure {failure:g}'
    alive, health = run.values[reads['alive']], run.values[reads['health']]
    if alive != 1.0 or health <= 0:
        return 0.0, 0.0, None, f'void: the dummy read alive {alive:g}, health {health:g} at the part end'
    auras = [run.values[label] for label in reads['rolls']]
    if any(value not in (0.0, 1.0) for value in auras):
        return 0.0, 0.0, None, f'aura reads outside 0 and 1: {sorted(set(auras))}'
    return sum(auras), float(len(auras)), None, None
