import math
from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, behaviour_entry, cleaned_tooltip, dummy_fixture, dummy_id, prose_rule,
                        waited_ms)
from compare import FLOAT_EPSILON, Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, cast_distance, dataset, facts_of

KIND = 'fed_charge_casts'
ORDER = 33
PAIR_RUNS = 2
FEED_TICKS = 1
ADD_PCT_MODIFIER = 108
SPELLMOD_CASTING_TIME = 10
FIGURE_BAND = 0.1
POLL_MARGIN_MS = 50
SETTLE_MS = 100
JUDGES_OF = ('charges', 'cut')
INSIDE, OUTSIDE, STRADDLE = 'inside', 'outside', 'straddle'


@dataclass(frozen=True)
class FedChargeSpec:
    spell: int
    name: str
    quote: str
    quote_spell: int
    feed_spell: int
    aura: int
    effect_spell: int
    charges: int
    every_ms: int
    residual_target: float
    feed_power: int
    effect_power: int
    trials: int
    min_judged: int
    poll_ms: int
    cut_effect: int = 0
    label_suffix: str = KIND


def fed_charge_spec(entry: dict) -> FedChargeSpec:
    spec = FedChargeSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['quote_spell']),
                         int(entry['feed_spell']), int(entry['aura']), int(entry['effect_spell']),
                         int(entry['charges']), int(entry['every_ms']), float(entry['residual_target']),
                         int(entry['feed_power']), int(entry['effect_power']), int(entry['trials']),
                         int(entry['min_judged']), int(entry['poll_ms']), int(entry.get('cut_effect', 0)),
                         entry.get('label_suffix', KIND))
    if not 0 < spec.residual_target < 1 or not 1 <= spec.min_judged <= spec.trials or spec.charges < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a residual_target in (0, 1), min_judged from 1 to trials and '
                         f'at least one charge')
    if not 0 < spec.poll_ms <= 2 * POLL_MARGIN_MS:
        raise ValueError(f'{spec.spell} {KIND} polls at most every {2 * POLL_MARGIN_MS} ms')
    return spec


def mark(spec: FedChargeSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cut_band(cast_ms: int, figure: float) -> tuple[float, float]:
    return (round(cast_ms * (1 - (1 + FIGURE_BAND) * figure / 100), 6),
            round(cast_ms * (1 - (1 - FIGURE_BAND) * figure / 100), 6))


def full_band(cast_ms: int) -> tuple[float, float]:
    return round(cast_ms * (1 - FIGURE_BAND), 6), round(cast_ms * (1 + FIGURE_BAND), 6)


def poll_offsets(band: tuple[float, float], poll_ms: int) -> list[int]:
    start, end = math.floor(band[0]) - POLL_MARGIN_MS, math.ceil(band[1]) + POLL_MARGIN_MS
    return list(range(start, end + 1, poll_ms))


def cut_figure(records: Records, spec: FedChargeSpec) -> float:
    effect = spec.cut_effect
    if (records.field('Spell', spec.aura, f'EffectApplyAuraName[{effect}]') != ADD_PCT_MODIFIER
            or records.field('Spell', spec.aura, f'EffectMiscValue[{effect}]') != SPELLMOD_CASTING_TIME):
        raise ValueError(f'{spec.spell} {KIND} needs {spec.aura} Effect[{effect}] ADD_PCT_MODIFIER on '
                         f'SPELLMOD_CASTING_TIME')
    value = records.single_value(spec.aura, effect)
    if not -100 < value < 0:
        raise ValueError(f'{spec.spell} {KIND} needs a cast time cut, not {value:g}% on {spec.aura}')
    return -value


def fed_charge_scenario(class_file: dict, spec: FedChargeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    if f'@s:{spec.quote_spell}:' not in cleaned_tooltip(records, spec.spell):
        raise ValueError(f'{spec.spell} {KIND} quotes {spec.quote_spell}, whose tooltip the {spec.spell} tooltip '
                         f'does not embed')
    quoted = cleaned_tooltip(records, spec.quote_spell)
    token = f'$s{spec.cut_effect + 1}%'
    if f'next {spec.charges} ' not in quoted or f'{token} reduced cast time' not in quoted:
        raise ValueError(f'{spec.spell} {KIND} needs the {spec.quote_spell} tooltip to say "next {spec.charges}" and '
                         f'"{token} reduced cast time"')
    entry = behaviour_entry(records, spec.quote_spell, spec.name, KIND, spec.quote, float(spec.charges))
    figure = cut_figure(records, spec)
    amount = -figure
    duration = int(records.duration_ms(spec.aura))
    chance = records.field('Spell', spec.spell, 'ProcChance') / 100
    if duration <= 0 or not 0 < chance < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a timed aura and a proc chance between 0 and 100%')
    effect = facts_of(records, spec.effect_spell)
    feed = facts_of(records, spec.feed_spell)
    cast_ms = effect.cast_time_ms
    if cast_ms <= 0:
        raise ValueError(f'{spec.spell} {KIND} needs an effect spell with a cast time')
    bands = {'cut': cut_band(cast_ms, figure), 'full': full_band(cast_ms)}
    polls = {name: poll_offsets(band, spec.poll_ms) for name, band in bands.items()}
    slot_ms = polls['full'][-1] + SETTLE_MS
    last_start = spec.charges * slot_ms
    if last_start + polls['full'][-1] >= duration * (1 - FIGURE_BAND):
        raise ValueError(f'{spec.spell} {KIND} casts {spec.charges + 1} {spec.effect_spell} in {slot_ms} ms slots, '
                         f'past {1 - FIGURE_BAND:g} of the {duration} ms aura')
    max_casts = math.ceil(math.log(spec.residual_target / (PAIR_RUNS * spec.trials))
                          / math.log((1 - chance) ** FEED_TICKS))
    target = dummy_id(0)

    def read(trial: str, name: str, metric: str, **fields) -> dict:
        return measurement(mark(spec, f'{trial} {name}'), CASTER, metric, **fields)

    def timed_cast(trial: str, index: int, band: str) -> tuple[list[dict], dict]:
        prefix = f'{trial} cast {index}'
        labels = {'aura': mark(spec, f'{prefix} aura'), 'prior': mark(spec, f'{prefix} prior'),
                  'start': mark(spec, f'{prefix} start'), 'sent': mark(spec, f'{prefix} sent'), 'band': band,
                  'polls': []}
        steps = [read(trial, f'cast {index} aura', 'aura', spell=spec.aura),
                 read(trial, f'cast {index} prior', 'spell_cast_count', spell=spec.effect_spell),
                 {'action': 'set_power', 'actor': CASTER, 'power': effect.power_type, 'value': spec.effect_power},
                 read(trial, f'cast {index} start', 'game_time_ms'),
                 {'action': 'cast', 'actor': CASTER, 'spell': spec.effect_spell, 'target': target,
                  'ignore_gcd': True},
                 read(trial, f'cast {index} sent', 'game_time_ms')]
        elapsed = 0
        for poll, offset in enumerate(polls[band]):
            names = {key: mark(spec, f'{prefix} poll {poll} {key}') for key in ('before', 'count', 'after')}
            labels['polls'].append(names)
            steps += [{'action': 'wait', 'label': f'{prefix} poll {poll}', 'ms': offset - elapsed},
                      measurement(names['before'], CASTER, 'game_time_ms'),
                      measurement(names['count'], CASTER, 'spell_cast_count', spell=spec.effect_spell),
                      measurement(names['after'], CASTER, 'game_time_ms')]
            elapsed = offset
        steps.append({'action': 'wait', 'label': f'{prefix} settles', 'ms': slot_ms - elapsed})
        return steps, labels

    def trial_steps(index: int) -> tuple[list[dict], dict]:
        trial = f'trial {index}'
        names = ('haste control', 'known start', 'grants start', 'fed at', 'aura stop', 'known stop', 'grants stop',
                 'amount', 'used', 'haste fed', 'grants end', 'went')
        labels = {name: mark(spec, f'{trial} {name}') for name in names}
        steps = [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura},
                 {'action': 'unlearn', 'actor': CASTER, 'spell': spec.spell},
                 read(trial, 'haste control', 'cast_speed_multiplier')]
        control, labels['control'] = timed_cast(trial, 'control', 'full')
        steps += control
        steps += [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell},
                  read(trial, 'known start', 'knows_spell', spell=spec.spell),
                  read(trial, 'grants start', 'aura_apply_count', spell=spec.aura),
                  {'action': 'cast_until_aura', 'label': mark(spec, f'{trial} feed'), 'actor': CASTER,
                   'spell': spec.feed_spell, 'target': target, 'aura': spec.aura, 'every_ms': spec.every_ms,
                   'max_casts': max_casts, 'cast_power': spec.feed_power, 'power': feed.power_type,
                   'reset_cooldown': True},
                  read(trial, 'fed at', 'game_time_ms'),
                  {'action': 'unlearn', 'actor': CASTER, 'spell': spec.spell},
                  read(trial, 'aura stop', 'aura', spell=spec.aura),
                  read(trial, 'known stop', 'knows_spell', spell=spec.spell),
                  read(trial, 'grants stop', 'aura_apply_count', spell=spec.aura),
                  read(trial, 'amount', 'aura_amount', spell=spec.aura, effect=spec.cut_effect),
                  read(trial, 'used', 'aura_script_value', spell=spec.aura, key=spec.aura),
                  read(trial, 'haste fed', 'cast_speed_multiplier')]
        labels['casts'] = []
        for cast in range(spec.charges + 1):
            cast_steps, cast_labels = timed_cast(trial, str(cast), 'cut' if cast < spec.charges else 'full')
            steps += cast_steps
            labels['casts'].append(cast_labels)
        steps += [read(trial, 'grants end', 'aura_apply_count', spell=spec.aura),
                  read(trial, 'went', 'spell_cast_count', spell=spec.effect_spell),
                  {'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.aura}]
        return steps, labels

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.feed_spell, spec.effect_spell))])
    reads = []
    for index in range(spec.trials):
        more, labels = trial_steps(index)
        steps += more
        reads.append(labels)
    distance = cast_distance(records, spec.effect_spell)
    contract = (
        f'{spec.aura} is earned for real: {spec.feed_spell} is cast at the dummy every {spec.every_ms} ms '
        f'(cast_until_aura, at most {max_casts} casts) until {spec.aura} is on the caster; the harness never sets it. '
        f'{spec.spell} is unlearned at the stop (Chance() rolls only while the caster holds it), so no later tick '
        f'grants {spec.aura} again or resets its used charges; {spec.aura} must still be on after the unlearn, with '
        f'Effect[{spec.cut_effect}] amount {amount:g} (Spell.dbc, the tooltip {token}). {spec.effect_spell} '
        f'({cast_ms} ms, CastingTimes.dbc) is then cast {spec.charges + 1} times with ignore_gcd, one every '
        f'{slot_ms} ms, each cast bracketed by game_time stamps and spell_cast_count polls every {spec.poll_ms} ms: '
        f'the cast time lies after the last pending poll and at or before the first completed one. The cast speed '
        f'multiplier is read 1 (no haste) before the control cast and after the unlearn. The first '
        f'{spec.charges} casts must lie in {bands["cut"][0]:g} to {bands["cut"][1]:g} ms (a {figure:g}% cut, '
        f'{FIGURE_BAND:g} of the figure), cast {spec.charges + 1} in {bands["full"][0]:g} to {bands["full"][1]:g} '
        f'ms (no cut). The game time is read when the feed stops; cast {spec.charges + 1} must start before '
        f'{1 - FIGURE_BAND:g} of the {duration} ms aura has passed since that stamp, so an uncut cast {spec.charges + 1} '
        f'is not the natural expiry; a trial past it is void. A control cast without the '
        f'talent or the aura opens each trial and must lie in the full band. A trial off a precondition is void; '
        f'fewer than {spec.min_judged} judged trials is unmeasured.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {spec.name} {spec.spell} behaviour fed charge casts',
        'contract': contract,
        'players': [player_fixture(class_file)],
        'creatures': [dummy_fixture(0, class_file, distance)],
        'steps': steps}
    shared = {'kind': KIND, 'metric': 'spell_cast_count', 'quote': entry.quote, 'reads': reads, 'bands': bands,
              'cast_ms': cast_ms, 'duration': duration,
              'charges': spec.charges, 'amount': amount, 'min_judged': spec.min_judged, 'max_casts': max_casts}
    expectations = [
        Expectation(mark(spec, 'charges'), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None, f'{spec.charges}',
                    prose_rule(entry.quote, spec.quote_spell),
                    {**shared, 'judge': 'charges', 'expected': float(spec.charges)}),
        Expectation(mark(spec, 'cut'), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, spec.cut_effect,
                    f'{figure:g}', prose_rule(entry.quote, spec.quote_spell),
                    {**shared, 'judge': 'cut', 'expected': figure})]
    windows = spec.trials * max_casts * spec.every_ms
    return timed(scenario, waited_ms(steps) + windows, MAX_ACCELERATED_SCENARIO_MS), expectations


def cast_bracket(values: dict, cast: dict) -> tuple[float, float]:
    prior = values[cast['prior']]
    low, high = 0.0, math.inf
    for poll in cast['polls']:
        if values[poll['count']] > prior:
            high = values[poll['after']] - values[cast['start']]
            break
        low = values[poll['before']] - values[cast['sent']]
    return low, high


def placed(bracket: tuple[float, float], band: tuple[float, float]) -> str:
    low, high = bracket
    if band[0] <= low and high <= band[1]:
        return INSIDE
    if high < band[0] or low > band[1]:
        return OUTSIDE
    return STRADDLE


def before_expiry(values: dict, trial: dict, duration: int) -> bool:
    return values[trial['casts'][-1]['start']] - values[trial['fed at']] < (1 - FIGURE_BAND) * duration


def trial_void(values: dict, trial: dict, duration: int) -> str | None:
    casts = [trial['control'], *trial['casts']]
    priors = [values[cast['prior']] for cast in casts] + [values[trial['went']]]
    unhasted = all(abs(values[trial[name]] - 1) <= FLOAT_EPSILON for name in ('haste control', 'haste fed'))
    checks = (('no haste', unhasted),
              ('control without the aura', values[trial['control']['aura']] == 0),
              ('known start', values[trial['known start']] == 1),
              ('one grant', values[trial['grants stop']] - values[trial['grants start']] == 1),
              ('aura after the unlearn', values[trial['aura stop']] == 1),
              ('unlearned', values[trial['known stop']] == 0),
              ('no grant after the stop', values[trial['grants end']] == values[trial['grants stop']]),
              ('every cast went off', all(after - before == 1 for before, after in zip(priors, priors[1:]))),
              (f'last cast past {1 - FIGURE_BAND:g} of the aura', before_expiry(values, trial, duration)))
    return next((name for name, held in checks if not held), None)


def fed_charge_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for trial in model['reads'] for label in trial_labels(trial)]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    values, bands = run.values, model['bands']
    judged, void, notes = [], [], []
    for index, trial in enumerate(model['reads']):
        reason = trial_void(values, trial, model['duration'])
        control = placed(cast_bracket(values, trial['control']), bands['full'])
        if reason is None and control != INSIDE:
            reason = f'control cast {control} the full band'
        if reason is not None:
            void.append(f'trial {index}: {reason}')
            continue
        brackets = [cast_bracket(values, cast) for cast in trial['casts']]
        places = [placed(bracket, bands[cast['band']]) for bracket, cast in zip(brackets, trial['casts'])]
        auras = [values[cast['aura']] for cast in trial['casts']]
        judged.append({'places': places, 'amount': values[trial['amount']], 'used': values[trial['used']]})
        notes.append(f'trial {index}: casts {[f"{low:g}..{high:g}" for low, high in brackets]} ms, aura before each '
                     f'{auras}, amount {values[trial["amount"]]:g}, used {values[trial["used"]]:g}')
    text = '; '.join(notes + ([f'void: {", ".join(void)}'] if void else []))
    charges = model['charges']
    if model['judge'] == 'cut':
        places = [place for trial in judged for place in trial['places'][:charges]]
        wrong_amount = [trial['amount'] for trial in judged if abs(trial['amount'] - model['amount']) > FLOAT_EPSILON]
        rule = (f'the first {charges} fed casts in {bands["cut"][0]:g} to {bands["cut"][1]:g} ms and the amount '
                f'{model["amount"]:g} at the grant')
        low, high = model['expected'] * (1 - FIGURE_BAND), model['expected'] * (1 + FIGURE_BAND)
    else:
        places = [place for trial in judged for place in trial['places']]
        wrong_amount = []
        rule = (f'{charges} fed casts in the cut band, cast {charges + 1} in {bands["full"][0]:g} to '
                f'{bands["full"][1]:g} ms')
        low = high = model['expected']
    if OUTSIDE in places or wrong_amount:
        status = 'alert'
    elif len(judged) < model['min_judged']:
        return replace(base, status='unmeasured',
                       explanation=f'{text}; fewer than {model["min_judged"]} judged trials')
    elif STRADDLE in places:
        return replace(base, status='unmeasured', explanation=f'{text}; a cast bracket straddles its band ({rule})')
    else:
        status = 'ok'
    return replace(base, status=status, measured=model['expected'] if status == 'ok' else None,
                   expected=model['expected'], low=low, high=high,
                   explanation=f'{text}; {rule}: {status}')


def trial_labels(trial: dict) -> list[str]:
    singles = [value for key, value in trial.items() if isinstance(value, str)]
    casts = [trial['control'], *trial['casts']]
    timed_reads = [cast[key] for cast in casts for key in ('aura', 'prior', 'start', 'sent')]
    polls = [label for cast in casts for poll in cast['polls'] for label in poll.values()]
    return singles + timed_reads + polls


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return fed_charge_scenario(class_file, fed_charge_spec(entry))


def label(entry: dict) -> list[str]:
    suffix = entry.get('label_suffix', KIND)
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {suffix} {read}" for read in JUDGES_OF]


JUDGES = {BEHAVIOUR_METRIC_DELTA: fed_charge_verdict}
