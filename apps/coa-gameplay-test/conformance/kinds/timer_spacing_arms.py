from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, dummy_fixture, dummy_id, prose_rule, waited_ms
from compare import FLOAT_EPSILON, Run, Verdict, missing_measurement
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import (CAST_MARGIN_MS, FORCE_CRIT_RATINGS, FORCED_CRIT_RATING, GCD_WAIT_MS, Expectation, cast_distance,
                    dataset, facts_of, fixture_health_step)

KIND = 'timer_spacing_arms'
ORDER = 31
ARMS = ('blocked', 'allowed')
CONTROL = 'control'
VARIANTS = ('cooldown_cut', 'chain_copy', 'chain_control')
CHAIN_VARIANTS = ('chain_copy', 'chain_control')
BAND_PCT = 10
SPARE_EDGE_YD = 0.5
READ_WAIT_MS = 500


@dataclass(frozen=True)
class TimerSpacingSpec:
    spell: int
    name: str
    quote: str
    variant: str
    timer_ms: int
    gaps: tuple[int, int]
    hit_spell: int
    label_suffix: str
    cooldown_spell: int = 0
    cut_spell: int = 0
    cut_effect: int = 0
    caster_health_pct: int = 0
    force_crit: str = ''
    seed_spell: int = 0
    aura_spell: int = 0
    spares: int = 0
    radius: float = 0.0
    cast_power: int = 0

    @property
    def control_arm(self) -> bool:
        return self.variant == 'chain_control'


def band(spec: TimerSpacingSpec) -> tuple[tuple[float, float], tuple[float, float]]:
    margin = spec.timer_ms * BAND_PCT / 100
    return (spec.timer_ms - margin, spec.timer_ms), (spec.timer_ms, spec.timer_ms + margin)


def timer_spacing_spec(entry: dict) -> TimerSpacingSpec:
    gaps = tuple(int(gap) for gap in entry['gaps'])
    spec = TimerSpacingSpec(int(entry['spell']), entry['name'], entry['quote'], entry['variant'],
                            int(entry['timer_ms']), gaps, int(entry['hit_spell']),
                            entry.get('label_suffix', KIND), int(entry.get('cooldown_spell', 0)),
                            int(entry.get('cut_spell', 0)), int(entry.get('cut_effect', 0)),
                            int(entry.get('caster_health_pct', 0)), entry.get('force_crit', ''),
                            int(entry.get('seed_spell', 0)), int(entry.get('aura_spell', 0)),
                            int(entry.get('spares', 0)), float(entry.get('radius', 0.0)),
                            int(entry.get('cast_power', 0)))
    if spec.variant not in VARIANTS or len(gaps) != 2 or spec.timer_ms <= 0:
        raise ValueError(f'{spec.spell} {KIND} needs a variant of {VARIANTS}, a positive timer_ms and two gaps')
    (blocked_low, blocked_high), (allowed_low, allowed_high) = band(spec)
    if not (blocked_low <= gaps[0] < blocked_high and allowed_low < gaps[1] <= allowed_high):
        raise ValueError(f'{spec.spell} {KIND} gaps {list(gaps)} must lie in [{blocked_low:g}, {blocked_high:g}) '
                         f'and ({allowed_low:g}, {allowed_high:g}]')
    if spec.variant == 'cooldown_cut' and (not spec.cooldown_spell or not spec.cut_spell
                                           or spec.force_crit not in FORCE_CRIT_RATINGS):
        raise ValueError(f'{spec.spell} {KIND} cooldown_cut needs a cooldown_spell, a cut_spell and a force_crit of '
                         f'{sorted(FORCE_CRIT_RATINGS)}')
    if spec.variant in CHAIN_VARIANTS and (not spec.seed_spell or not spec.aura_spell or spec.spares < 3
                                         or spec.radius <= SPARE_EDGE_YD):
        raise ValueError(f'{spec.spell} {KIND} chain_copy needs a seed_spell, an aura_spell, at least three spare '
                         f'dummies and a radius')
    return spec


def mark(spec: TimerSpacingSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def cast(records: Records, spell: int, target: str, cast_power: int, **extra) -> list[dict]:
    facts = facts_of(records, spell)
    value = cast_power if facts.mana_cost_percentage or facts.mana_cost_per_level else facts.mana_cost
    power = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': value}] if value > 0 else []
    return power + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell},
                    {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': target, **extra}]


def expected_effects(spec: TimerSpacingSpec) -> dict[str, int]:
    return {ARMS[0]: 1, ARMS[1]: 2}


def timer_spacing_scenario(class_file: dict, spec: TimerSpacingSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    chain = spec.variant in CHAIN_VARIANTS
    target = dummy_id(0) if chain else CASTER
    stream, since = ('spell_damage', spec.seed_spell) if chain else ('spell_heal', spec.cooldown_spell)
    hit = facts_of(records, spec.hit_spell)
    creatures = []
    travel_ms = 0
    if chain:
        primary = cast_distance(records, spec.hit_spell)
        step = (spec.radius - SPARE_EDGE_YD) / spec.spares
        creatures = [dummy_fixture(0, class_file, primary)] + [
            dummy_fixture(index, class_file, primary + step * index) for index in range(1, spec.spares + 1)]
        speed = records.field('Spell', spec.hit_spell, 'Speed')
        travel_ms = math.ceil(primary / speed * 1000) if speed else 0

    def health() -> list[dict]:
        return [fixture_health_step(CASTER, spec.caster_health_pct)] if spec.caster_health_pct else []

    def effect_reads(arm: str, moment: str) -> list[dict]:
        if chain:
            return [measurement(mark(spec, f'{arm} {moment} {dummy_id(index)}'), dummy_id(index), 'aura',
                                spell=spec.aura_spell, caster=CASTER) for index in range(1, spec.spares + 1)]
        return [measurement(mark(spec, f'{arm} {moment} critical'), CASTER, 'spell_heal_count',
                            spell=spec.hit_spell, target=CASTER, critical=True)]

    def hits_read(arm: str) -> dict:
        fields = {'spell': spec.hit_spell, 'target': target}
        if not chain:
            fields['critical'] = True
        return measurement(mark(spec, f'{arm} spacing'), CASTER, 'event_interval_min_ms', stream=stream,
                           since_spell=since, **fields)

    def opened_read(name: str) -> dict:
        return measurement(mark(spec, f'{name} opened'), CASTER, 'spell_go_count', spell=since)

    def arm(name: str, gap: int) -> list[dict]:
        if chain:
            opening = cast(records, spec.seed_spell, dummy_id(0), spec.cast_power) + [
                {'action': 'wait', 'label': f'{name} seed and global cooldown',
                 'ms': facts_of(records, spec.seed_spell).cast_time_ms + CAST_MARGIN_MS + GCD_WAIT_MS}]
        else:
            opening = [{**step, 'label': mark(spec, f'{name} cooldown start')} if step['action'] == 'cast' else step
                       for step in cast(records, spec.cooldown_spell, CASTER, spec.cast_power)] + [
                {'action': 'wait', 'label': f'{name} global cooldown', 'ms': GCD_WAIT_MS},
                {'action': 'restore_charges', 'actor': CASTER, 'spell': spec.hit_spell}]
        steps = (opening + effect_reads(name, 'start') + health() + cast(records, spec.hit_spell, target, spec.cast_power)
                 + [{'action': 'wait', 'label': mark(spec, f'{name} gap'), 'ms': gap}] + health()
                 + cast(records, spec.hit_spell, target, spec.cast_power, ignore_gcd=True)
                 + [{'action': 'wait', 'label': f'{name} hits',
                     'ms': max(travel_ms + hit.cast_time_ms + READ_WAIT_MS, GCD_WAIT_MS)}])
        if not chain:
            steps.append(measurement(mark(spec, f'{name} cooldown'), CASTER, 'cooldown_ms',
                                     spell=spec.cooldown_spell))
        return steps + effect_reads(name, 'end') + [hits_read(name), opened_read(name)]

    learned = (spec.seed_spell, spec.hit_spell) if chain else (spec.cooldown_spell, spec.hit_spell)
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in dict.fromkeys(learned)]
             + (arm(CONTROL, spec.gaps[1]) if spec.control_arm else [])
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + arm(ARMS[0], spec.gaps[0]) + arm(ARMS[1], spec.gaps[1]))
    player = player_fixture(class_file)
    if spec.force_crit:
        player[FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
    (blocked_low, blocked_high), (allowed_low, allowed_high) = band(spec)
    effect = (f'new {spec.aura_spell} copies of the caster on {spec.spares} spare dummies within {spec.radius:g} yd'
              if chain else f'the cooldown of {spec.cooldown_spell} cut by critical heals')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour timer spacing',
        'contract': (f'{spec.spell} is learned; two arms each make two real {spec.hit_spell} hits, the second cast '
                     f'with ignore_gcd {spec.gaps[0]} ms (blocked arm) and {spec.gaps[1]} ms (allowed arm) after '
                     f'the first. The {spec.timer_ms} ms timer of the tooltip allows one effect in the blocked arm and '
                     f'two in the allowed arm, counted as {effect}. An arm counts only when its measured spacing of '
                     f'the hits lies in [{blocked_low:g}, {blocked_high:g}) or ({allowed_low:g}, {allowed_high:g}] '
                     f'ms.' + (f' A control arm before {spec.spell} is learned makes the same two hits '
                               f'{spec.gaps[1]} ms apart and must give no new copy.' if spec.control_arm else '')),
        'players': [player],
        'steps': steps}
    if creatures:
        scenario['creatures'] = creatures
    model = {'kind': KIND, 'variant': spec.variant, 'metric': 'event_interval_min_ms', 'quote': entry.quote,
             'expected': expected_effects(spec), 'bands': {ARMS[0]: [blocked_low, blocked_high],
                                                           ARMS[1]: [allowed_low, allowed_high]},
             'reads': {name: {'spacing': mark(spec, f'{name} spacing'), 'opened': mark(spec, f'{name} opened'),
                              'start': [read['label'] for read in effect_reads(name, 'start')],
                              'end': [read['label'] for read in effect_reads(name, 'end')]} for name in ARMS}}
    if spec.control_arm:
        model[CONTROL] = {'spacing': mark(spec, f'{CONTROL} spacing'), 'opened': mark(spec, f'{CONTROL} opened'),
                          'start': [read['label'] for read in effect_reads(CONTROL, 'start')],
                          'end': [read['label'] for read in effect_reads(CONTROL, 'end')], 'expected': 0}
    if not chain:
        model['cooldown'] = {'recovery_ms': float(records.field('Spell', spec.cooldown_spell, 'RecoveryTime')),
                             'cut_ms': abs(records.single_value(spec.cut_spell, spec.cut_effect))}
        for name in ARMS:
            model['reads'][name]['cooldown'] = mark(spec, f'{name} cooldown')
            model['reads'][name]['cooldown_start'] = mark(spec, f'{name} cooldown start')
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.hit_spell, None,
                              '1', prose_rule(entry.quote, spec.spell), model)
    budget = waited_ms(steps)
    return timed(scenario, budget), [expectation]


def elapsed_window(run: Run, start_label: str, end_label: str) -> tuple[float, float] | None:
    labels = [step.get('label') for step in run.steps]
    if start_label not in labels or end_label not in labels or run.max_step_ms is None:
        return None
    start, end = labels.index(start_label), labels.index(end_label)
    between = run.steps[start + 1:end + 1]
    low = sum(float(step.get('elapsed_ms', 0)) for step in between)
    return low, low + run.max_step_ms * len(between)


def cuts_of(run: Run, model: dict, name: str) -> tuple[int | None, str]:
    reads, cooldown = model['reads'][name], model['cooldown']
    window = elapsed_window(run, reads['cooldown_start'], reads['cooldown'])
    if window is None:
        return None, f'{name}: no step timing between {reads["cooldown_start"]!r} and {reads["cooldown"]!r}'
    remaining = run.values[reads['cooldown']]
    high = (cooldown['recovery_ms'] - remaining - window[0]) / cooldown['cut_ms']
    low = (cooldown['recovery_ms'] - remaining - window[1]) / cooldown['cut_ms']
    whole = list(range(math.ceil(low - FLOAT_EPSILON), math.floor(high + FLOAT_EPSILON) + 1))
    text = f'{name}: cooldown {remaining:g} ms after {window[0]:g}-{window[1]:g} ms, cuts {low:.2f}-{high:.2f}'
    if len(whole) != 1:
        return None, text + ' (no single whole count in the window)'
    return whole[0], text


def timer_spacing_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    labels = [label for reads in model['reads'].values()
              for key, value in reads.items() if key not in ('cooldown_start',)
              for label in (value if isinstance(value, list) else [value])]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    notes, effects = [], {}
    control = model.get(CONTROL)
    if control:
        missing = next((label for label in [control['spacing'], control['opened'], *control['start'],
                                            *control['end']] if run.values.get(label) is None), None)
        if missing is not None:
            return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
        if run.values[control['opened']] != 1:
            return replace(base, status='unmeasured',
                           explanation=f'{CONTROL}: {run.values[control["opened"]]:g} opening casts by its end, 1 '
                                       f'needed, so its reads are not its own')
        low, high = model['bands'][ARMS[1]]
        spacing = run.values[control['spacing']]
        if not low < spacing <= high:
            return replace(base, status='unmeasured',
                           explanation=f'{CONTROL} spacing {spacing:g} ms outside its band {low:g}-{high:g}')
        copies = sum(run.values[label] for label in control['end']) - sum(run.values[label]
                                                                         for label in control['start'])
        notes.append(f'{CONTROL}: spacing {spacing:g} ms, {copies:g} new copies before the learn')
        if copies != control['expected']:
            return replace(base, measured=copies, expected=float(control['expected']), low=0.0, high=0.0,
                           explanation=f'{CONTROL} arm without {base.spell_id}: {"; ".join(notes)}')
    for count, name in enumerate(ARMS, 2 if control else 1):
        reads = model['reads'][name]
        if run.values[reads['opened']] != count:
            return replace(base, status='unmeasured',
                           explanation=f'{name}: {run.values[reads["opened"]]:g} opening casts by its end, {count} '
                                       f'needed, so its spacing and cooldown reads are not its own')
        spacing = run.values[reads['spacing']]
        low, high = model['bands'][name]
        inside = low <= spacing < high if name == ARMS[0] else low < spacing <= high
        notes.append(f'{name}: spacing {spacing:g} ms')
        if not inside:
            return replace(base, status='unmeasured',
                           explanation=f'{name} spacing {spacing:g} ms outside its band {low:g}-{high:g}: '
                                       f'{"; ".join(notes)}')
        gained = sum(run.values[label] for label in reads['end']) - sum(run.values[label] for label in reads['start'])
        if model['variant'] == 'cooldown_cut':
            if gained != 2:
                return replace(base, status='unmeasured',
                               explanation=f'{name}: {gained:g} critical heals, two are needed: {"; ".join(notes)}')
            cuts, text = cuts_of(run, model, name)
            notes.append(text)
            if cuts is None:
                return replace(base, status='unmeasured', explanation='; '.join(notes))
            effects[name] = cuts
        else:
            notes.append(f'{name}: {gained:g} new copies')
            effects[name] = gained
    expected = model['expected']
    ok = all(effects[name] == expected[name] for name in ARMS)
    return replace(base, status='ok' if ok else 'alert', measured=float(effects[ARMS[1]] - effects[ARMS[0]]),
                   expected=float(expected[ARMS[1]] - expected[ARMS[0]]), low=1.0, high=1.0,
                   detail={name: effects[name] for name in ARMS},
                   explanation=f'effects per arm {effects} against {expected}: {"; ".join(notes)}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return timer_spacing_scenario(class_file, timer_spacing_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: timer_spacing_verdict}
