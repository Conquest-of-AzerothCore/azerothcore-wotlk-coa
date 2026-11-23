from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from procs import wilson_interval
from profile import (CASTER, DBC_DIR, base_steps, measurement, off_hand_steps, off_hand_weapon, one_hand_main,
                     player_fixture)
from tooltip import Records
from values import Expectation, TARGET, armed_for, dataset

KIND = 'extra_strikes'
ORDER = 44
CONTROL = 'control'
TREATMENT = 'treatment'
ARMS = (CONTROL, TREATMENT)
OFF_HAND = 1
MAIN_HAND = 0
STRIKE_METRIC = 'spell_damage_count'
SETTLE_MS = 1000
READS = ('off_hand_hits', 'main_hand_hits', 'procs')


@dataclass(frozen=True)
class ExtraStrikesSpec:
    spell: int
    name: str
    quote: str
    strikes: int
    strike_spells: tuple[int, ...]
    proc_marker: int
    chance_pct: float
    swings: int
    control_swings: int
    off_hand_item: int | None = None
    label_suffix: str = 'extra_strikes'


def extra_strikes_spec(entry: dict) -> ExtraStrikesSpec:
    spec = ExtraStrikesSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['strikes']),
                            tuple(int(spell) for spell in entry['strike_spells']), int(entry['proc_marker']),
                            float(entry['chance_pct']), int(entry['swings']), int(entry['control_swings']),
                            None if entry.get('off_hand_item') is None else int(entry['off_hand_item']),
                            entry.get('label_suffix', 'extra_strikes'))
    if spec.strikes < 1 or spec.swings < 1 or spec.control_swings < 1 or not 0 < spec.chance_pct < 100:
        raise ValueError(f'{spec.spell} {KIND} needs strikes, swings and control swings, and a chance below 100%')
    if not spec.strike_spells or len(set(spec.strike_spells)) != len(spec.strike_spells) or \
            spec.proc_marker in spec.strike_spells:
        raise ValueError(f'{spec.spell} {KIND} needs distinct strike spells and a proc marker that is not one of them')
    return spec


def label_prefix(spell: int, suffix: str) -> str:
    return f'{spell} {BEHAVIOUR_METRIC_DELTA} {suffix}'


def read_label(prefix: str, arm: str, mark: str, read: str) -> str:
    return f'{prefix} {arm} {mark} {read}'


def strike_read(spell: int, metric: str) -> str:
    return f'{metric} {spell}'


def arm_reads(spec: ExtraStrikesSpec, arm: str, mark: str) -> list[dict]:
    prefix = label_prefix(spec.spell, spec.label_suffix)
    steps = [measurement(read_label(prefix, arm, mark, 'off_hand_hits'), CASTER, 'melee_damage_count', hand=OFF_HAND),
             measurement(read_label(prefix, arm, mark, 'main_hand_hits'), CASTER, 'melee_damage_count',
                         hand=MAIN_HAND),
             measurement(read_label(prefix, arm, mark, 'procs'), CASTER, 'spell_cast_count', spell=spec.proc_marker)]
    for spell in spec.strike_spells:
        steps += [measurement(read_label(prefix, arm, mark, strike_read(spell, 'spell_cast_count')), CASTER,
                              'spell_cast_count', spell=spell),
                  measurement(read_label(prefix, arm, mark, strike_read(spell, STRIKE_METRIC)), CASTER,
                              STRIKE_METRIC, spell=spell, target=TARGET)]
    return steps


def armed_off_hand(class_file: dict, records: Records, spec: ExtraStrikesSpec) -> tuple[dict, dict, list[dict]]:
    if spec.off_hand_item is not None:
        off_hand = off_hand_weapon(class_file, spec.off_hand_item)
        armed = one_hand_main(class_file)
        if armed is None:
            raise ValueError(f'{spec.spell} {KIND} dual wields, which needs a one-handed main-hand weapon')
        return armed, off_hand, off_hand_steps(spec.off_hand_item)
    armed = armed_for(class_file, records, spec.spell)
    off_hand = armed.get('weapon_sets', {}).get(armed.get('weapon_set'), {}).get('off_hand')
    if not off_hand:
        raise ValueError(f'{spec.spell} {KIND} needs an off-hand weapon: an off_hand_item or a weapon set with one')
    return armed, off_hand, []


def extra_strikes_scenario(class_file: dict, spec: ExtraStrikesSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.strikes)
    class_file, off_hand, equip = armed_off_hand(class_file, records, spec)
    speed = int(off_hand['speed_ms'])
    steps = base_steps(class_file) + equip
    for arm, swings in ((CONTROL, spec.control_swings), (TREATMENT, spec.swings)):
        if arm == TREATMENT:
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
        steps += arm_reads(spec, arm, 'start')
        steps += [{'action': 'attack', 'actor': CASTER, 'target': TARGET},
                  {'action': 'wait', 'label': f'{arm} swings', 'ms': swings * speed},
                  {'action': 'stop_attack', 'actor': CASTER},
                  {'action': 'wait', 'label': f'{arm} settle', 'ms': SETTLE_MS}]
        steps += arm_reads(spec, arm, 'end')
    strikes = ', '.join(str(spell) for spell in spec.strike_spells)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour extra strikes',
        'contract': (f'The caster dual wields (off-hand speed {speed} ms) and auto-attacks the dummy for '
                     f'{spec.control_swings} off-hand swing intervals without {spec.spell} (control) and '
                     f'{spec.swings} with it learned (treatment). Each arm reads its off-hand and main-hand damaging '
                     f'swings, the casts of the proc marker {spec.proc_marker} (one per proc) and the casts and '
                     f'landed hits of the strike spells [{strikes}] at the dummy. The control must show no proc and '
                     f'no strike; in the treatment the landed strikes must be exactly {spec.strikes} per proc, as '
                     f'many as the strike casts. The proc share of the off-hand hits is reported with its Wilson '
                     f'99% interval against the stated {spec.chance_pct:g}%, not judged.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': STRIKE_METRIC, 'quote': entry.quote, 'strikes': spec.strikes,
             'chance_pct': spec.chance_pct, 'prefix': label_prefix(spec.spell, spec.label_suffix),
             'strike_spells': list(spec.strike_spells), 'proc_marker': spec.proc_marker}
    expectation = Expectation(label_prefix(spec.spell, spec.label_suffix), BEHAVIOUR_METRIC_DELTA, spec.spell,
                              spec.strike_spells[0], None, str(spec.strikes), prose_rule(entry.quote, spec.spell),
                              model)
    return timed(scenario, waited_ms(steps)), [expectation]


def arm_counts(run: Run, model: dict, arm: str) -> tuple[dict, str | None]:
    names = [*READS, *(strike_read(spell, metric) for spell in model['strike_spells']
                       for metric in ('spell_cast_count', STRIKE_METRIC))]
    counts = {}
    for name in names:
        start, end = (read_label(model['prefix'], arm, mark, name) for mark in ('start', 'end'))
        for read in (start, end):
            if run.values.get(read) is None:
                return counts, missing_measurement(run, read)
        counts[name] = run.values[end] - run.values[start]
    counts['strike_casts'] = sum(counts[strike_read(spell, 'spell_cast_count')] for spell in model['strike_spells'])
    counts['strikes'] = sum(counts[strike_read(spell, STRIKE_METRIC)] for spell in model['strike_spells'])
    return counts, None


def pooled_counts(runs: list[Run], model: dict) -> tuple[dict, str | None]:
    totals = {}
    for run in runs:
        for arm in ARMS:
            counts, problem = arm_counts(run, model, arm)
            if problem is not None:
                return totals, problem
            for name, value in counts.items():
                totals[f'{arm} {name}'] = totals.get(f'{arm} {name}', 0) + value
    return totals, None


def chance_text(procs: float, hits: float, chance_pct: float) -> str:
    if hits <= 0:
        return f'no off-hand hit to set the proc share against the stated {chance_pct:g}%'
    low, high = wilson_interval(procs, hits)
    return (f'proc share {procs:g} of {hits:g} off-hand hits = {procs / hits:.4f}, Wilson 99% interval '
            f'[{low:.4f}, {high:.4f}] against the stated {chance_pct / 100:.4f} (reported, not judged)')


def extra_strikes_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    totals, problem = pooled_counts(runs, model)
    if problem is not None:
        return replace(base, status='unmeasured', explanation=problem)
    expected = int(model['strikes'])
    procs, strikes, casts = (totals[f'{TREATMENT} {name}'] for name in ('procs', 'strikes', 'strike_casts'))
    control = (totals[f'{CONTROL} procs'], totals[f'{CONTROL} strike_casts'], totals[f'{CONTROL} strikes'])
    detail = {**{name.replace(' ', '_'): value for name, value in totals.items()}, 'parts': len(runs)}
    reads = (f'control: {control[0]:g} procs, {control[1]:g} strike casts and {control[2]:g} strikes over '
             f'{totals[f"{CONTROL} off_hand_hits"]:g} off-hand hits; treatment: {procs:g} procs, {casts:g} strike '
             f'casts and {strikes:g} landed strikes over {totals[f"{TREATMENT} off_hand_hits"]:g} off-hand and '
             f'{totals[f"{TREATMENT} main_hand_hits"]:g} main-hand hits; '
             f'{chance_text(procs, totals[f"{TREATMENT} off_hand_hits"], float(model["chance_pct"]))}')
    if any(control):
        return replace(base, status='alert', detail=detail, explanation=f'the control arm struck or procced: {reads}')
    if procs <= 0:
        return replace(base, status='unmeasured', detail=detail, explanation=f'no proc in the treatment arm: {reads}')
    measured = strikes / procs
    status = 'ok' if strikes == expected * procs and casts == strikes else 'alert'
    return replace(base, status=status, measured=measured, expected=float(expected), detail=detail,
                   explanation=(f'{measured:.4g} landed strikes per proc against the stated {expected}; exactly '
                                f'{expected} per proc and every strike cast landed required: {reads}'))


def extra_strikes_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return extra_strikes_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return extra_strikes_scenario(class_file, extra_strikes_spec(entry))


def label(entry: dict) -> list[str]:
    return [label_prefix(entry['spell'], entry.get('label_suffix', 'extra_strikes'))]


JUDGES = {BEHAVIOUR_METRIC_DELTA: extra_strikes_single_verdict}
POOLED_JUDGE = extra_strikes_verdict
