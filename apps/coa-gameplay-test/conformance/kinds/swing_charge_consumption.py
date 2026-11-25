from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, FORCE_CRIT_RATINGS, behaviour_entry, cleaned_tooltip, prose_rule,
                        waited_ms)
from compare import Run, Verdict, describe_failures, failure_reasons, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, FORCED_CRIT_RATING, TARGET, armed_for, dataset, facts_of

KIND = 'swing_charge_consumption'
ORDER = 58
TIME_MARGIN = 0.15
DEFAULT_TRIGGER_WAIT_MS = 400
DEFAULT_FINAL_TIMEOUT_MS = 4000
MIN_TRIGGER_WAIT_MS = 100
MIN_FINAL_TIMEOUT_MS = 500
FIELDS = frozenset({
    'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'quote_spell', 'gate_spell', 'trigger_spell',
    'aura', 'haste_auras', 'no_crit_aura', 'force_crit', 'cast_power', 'trigger_wait_ms', 'final_timeout_ms',
    'learn', 'hand', 'observe_source'})


@dataclass(frozen=True)
class SwingChargeSpec:
    spell: int
    name: str
    quote: str
    gate_spell: int
    trigger_spell: int
    aura: int
    haste_auras: tuple[int, ...]
    no_crit_aura: int | None
    force_crit: str | None
    cast_power: int | None
    trigger_wait_ms: int
    final_timeout_ms: int
    quote_spell: int | None
    learn: tuple[int, ...]
    hand: int
    label_suffix: str


def swing_charge_spec(entry: dict) -> SwingChargeSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry["spell"]} {KIND} has unknown fields {sorted(unknown)}')
    spell = int(entry['spell'])
    gate_spell = int(entry.get('gate_spell', spell))
    trigger_spell = int(entry['trigger_spell'])
    aura = int(entry['aura'])
    haste_raw = entry.get('haste_auras', ())
    if not isinstance(haste_raw, list) or any(isinstance(item, bool) or not isinstance(item, int) or item < 1
                                              for item in haste_raw):
        raise ValueError(f'{spell} {KIND} haste_auras must be a list of positive spell ids')
    no_crit_raw = entry.get('no_crit_aura')
    if no_crit_raw is not None and (isinstance(no_crit_raw, bool) or not isinstance(no_crit_raw, int)
                                    or no_crit_raw < 1):
        raise ValueError(f'{spell} {KIND} no_crit_aura must be a positive spell id')
    force_crit = entry.get('force_crit')
    if force_crit is not None and force_crit not in FORCE_CRIT_RATINGS:
        raise ValueError(f'{spell} {KIND} unknown force_crit {force_crit!r}')
    cast_power_raw = entry.get('cast_power')
    if cast_power_raw is not None and (isinstance(cast_power_raw, bool) or not isinstance(cast_power_raw, int)
                                       or cast_power_raw < 0):
        raise ValueError(f'{spell} {KIND} cast_power must be a non-negative integer')
    trigger_wait_ms = entry.get('trigger_wait_ms', DEFAULT_TRIGGER_WAIT_MS)
    if (isinstance(trigger_wait_ms, bool) or not isinstance(trigger_wait_ms, int)
            or trigger_wait_ms < MIN_TRIGGER_WAIT_MS):
        raise ValueError(f'{spell} {KIND} trigger_wait_ms must be >= {MIN_TRIGGER_WAIT_MS}')
    final_timeout_ms = entry.get('final_timeout_ms', DEFAULT_FINAL_TIMEOUT_MS)
    if (isinstance(final_timeout_ms, bool) or not isinstance(final_timeout_ms, int)
            or final_timeout_ms < MIN_FINAL_TIMEOUT_MS):
        raise ValueError(f'{spell} {KIND} final_timeout_ms must be >= {MIN_FINAL_TIMEOUT_MS}')
    quote_spell_raw = entry.get('quote_spell')
    quote_spell = None
    if quote_spell_raw is not None:
        if isinstance(quote_spell_raw, bool) or not isinstance(quote_spell_raw, int) or quote_spell_raw < 1:
            raise ValueError(f'{spell} {KIND} quote_spell must be a positive spell id')
        quote_spell = quote_spell_raw
    learn_raw = entry.get('learn', ())
    if not isinstance(learn_raw, (list, tuple)) or any(isinstance(item, bool) or not isinstance(item, int) or item < 1
                                                       for item in learn_raw):
        raise ValueError(f'{spell} {KIND} learn must be a list of positive spell ids')
    learn = tuple(learn_raw)
    if gate_spell in learn:
        raise ValueError(f'{spell} {KIND} learns gate_spell {gate_spell} only between control and treatment')
    hand = entry.get('hand', 0)
    if isinstance(hand, bool) or hand not in (0, 1):
        raise ValueError(f'{spell} {KIND} hand must be 0 or 1')
    return SwingChargeSpec(
        spell, entry['name'], entry['quote'], gate_spell, trigger_spell, aura, tuple(haste_raw),
        no_crit_raw, force_crit, cast_power_raw, trigger_wait_ms, final_timeout_ms, quote_spell,
        learn, hand, entry.get('label_suffix', KIND))


def mark(spec: SwingChargeSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def moment_reads(spec: SwingChargeSpec, moment: str) -> tuple[list[dict], dict[str, str]]:
    names = {
        'time': mark(spec, f'{moment} time'),
        'aura': mark(spec, f'{moment} aura'),
        'charges': mark(spec, f'{moment} charges'),
        'swings': mark(spec, f'{moment} swings'),
        'hits': mark(spec, f'{moment} hits'),
        'crits': mark(spec, f'{moment} crits'),
    }
    steps = [
        measurement(names['time'], CASTER, 'game_time_ms'),
        measurement(names['aura'], CASTER, 'aura', spell=spec.aura),
        measurement(names['charges'], CASTER, 'aura_charges', spell=spec.aura),
        measurement(names['swings'], CASTER, 'melee_attack_count', hand=spec.hand),
        measurement(names['hits'], CASTER, 'melee_damage_count', hand=spec.hand),
        measurement(names['crits'], CASTER, 'melee_damage_count', hand=spec.hand, critical=True),
    ]
    return steps, names


def swing_charge_scenario(class_file: dict, spec: SwingChargeSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    if spec.quote_spell is not None:
        if f'@s:{spec.quote_spell}:' not in cleaned_tooltip(records, spec.spell):
            raise ValueError(f'{spec.spell} {KIND} quote_spell {spec.quote_spell} is not embedded in '
                             f'{spec.spell} tooltip')
        quote_target = spec.quote_spell
    else:
        quote_target = spec.spell
    charges = int(records.field('Spell', spec.aura, 'ProcCharges') or 0)
    if charges < 2:
        raise ValueError(f'{spec.spell} {KIND} needs ProcCharges >= 2 on aura {spec.aura}, found {charges}')
    duration_ms = int(records.duration_ms(spec.aura) or 0)
    if duration_ms <= 0:
        raise ValueError(f'{spec.spell} {KIND} needs a finite positive duration on aura {spec.aura}')
    if spec.trigger_wait_ms >= duration_ms // 4:
        raise ValueError(f'{spec.spell} {KIND} trigger_wait_ms {spec.trigger_wait_ms} must be < {duration_ms // 4}')
    if spec.final_timeout_ms >= duration_ms:
        raise ValueError(f'{spec.spell} {KIND} final_timeout_ms {spec.final_timeout_ms} must be < {duration_ms}')
    for aura_id in spec.haste_auras:
        records.field('Spell', aura_id, 'Id')
    if spec.no_crit_aura is not None:
        records.field('Spell', spec.no_crit_aura, 'Id')
    entry = behaviour_entry(records, quote_target, spec.name, KIND, spec.quote, float(charges))
    class_file = armed_for(class_file, records, spec.spell)
    trigger_facts = facts_of(records, spec.trigger_spell)
    max_window_ms = int(duration_ms * (1.0 - TIME_MARGIN))

    def prepare_trigger() -> list[dict]:
        steps = [{'action': 'set_aura', 'actor': CASTER, 'spell': aura_id, 'stacks': 1}
                 for aura_id in spec.haste_auras]
        steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.aura, 'stacks': 0})
        if spec.no_crit_aura is not None:
            steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.no_crit_aura, 'stacks': 0})
        if spec.cast_power is not None:
            steps.append({'action': 'set_power', 'actor': CASTER, 'power': trigger_facts.power_type,
                          'value': spec.cast_power})
        steps += [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                  {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET},
                  {'action': 'wait', 'label': 'trigger settle', 'ms': spec.trigger_wait_ms}]
        return steps

    learn_spells = tuple(dict.fromkeys((spec.trigger_spell, *spec.learn)))
    control_aura = mark(spec, 'control aura')
    control_charges = mark(spec, 'control charges')
    start_steps, start_names = moment_reads(spec, 'start')
    pen_steps, pen_names = moment_reads(spec, 'penultimate')
    final_steps, final_names = moment_reads(spec, 'final')

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell_id} for spell_id in learn_spells]
             + prepare_trigger()
             + [measurement(control_aura, CASTER, 'aura', spell=spec.aura),
                measurement(control_charges, CASTER, 'aura_charges', spell=spec.aura),
                {'action': 'learn', 'actor': CASTER, 'spell': spec.gate_spell}]
             + prepare_trigger())
    if spec.no_crit_aura is not None:
        steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': spec.no_crit_aura, 'stacks': 1})
    steps += (start_steps
              + [{'action': 'attack_until_swings', 'label': 'consume N-1 charges', 'actor': CASTER, 'target': TARGET,
                  'swings': charges - 1, 'timeout_ms': max_window_ms, 'hand': spec.hand}]
              + pen_steps
              + [{'action': 'attack_until_swings', 'label': 'consume final charge', 'actor': CASTER, 'target': TARGET,
                  'swings': 1, 'timeout_ms': spec.final_timeout_ms, 'hand': spec.hand}]
              + final_steps)

    player = dict(player_fixture(class_file))
    if spec.force_crit is not None:
        player[FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour swing charge consumption',
        'contract': (f'Exact melee swing charge-consumption proof for {spec.aura} (ProcCharges {charges}, '
                     f'DurationIndex {duration_ms} ms from Spell.dbc) gated by {spec.gate_spell}. Control: triggers '
                     f'{spec.trigger_spell} before learning {spec.gate_spell} and requires aura == 0 and '
                     f'aura_charges == 0. Treatment: learns {spec.gate_spell}, applies haste fixtures '
                     f'{list(spec.haste_auras)}, triggers {spec.aura} via {spec.trigger_spell}, prevents melee crits '
                     f'({spec.no_crit_aura}), verifies initial aura == 1 and aura_charges == {charges}, delivers '
                     f'exactly {charges - 1} non-crit melee auto-attacks via attack_until_swings and requires '
                     f'aura == 1 and aura_charges == 1, then delivers 1 more non-crit swing and requires aura == 0 '
                     f'and aura_charges == 0 within {max_window_ms} ms (< {100 * (1 - TIME_MARGIN):g}% of '
                     f'{duration_ms} ms duration). Any refused cast, crit swing, swing mismatch, or elapsed time '
                     f'>= {max_window_ms} ms voids the run as unmeasured.'),
        'players': [player],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {
        'kind': KIND, 'metric': 'aura', 'quote': entry.quote,
        'expected_charges': charges, 'duration_ms': duration_ms, 'max_window_ms': max_window_ms,
        'reads': {
            'control': {'aura': control_aura, 'charges': control_charges},
            'start': start_names,
            'penultimate': pen_names,
            'final': final_names,
        }}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.aura, None,
                              f'{charges} swings', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps) + max_window_ms + spec.final_timeout_ms), [expectation]


def swing_charge_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    refused = '; '.join(f'{spell}: {describe_failures(reasons)}' for spell, reasons
                        in ((spell, failure_reasons(run, spell)) for spell in run.cast_failures) if reasons)
    if refused:
        return replace(base, status='unmeasured', explanation=f'refused cast voids swing charge proof: {refused}')
    reads = model['reads']
    all_labels = [label for group in reads.values() for label in group.values()]
    missing = next((label for label in all_labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    expected = int(model['expected_charges'])
    max_window_ms = int(model['max_window_ms'])
    ctrl = {key: run.values[label] for key, label in reads['control'].items()}
    start = {key: run.values[label] for key, label in reads['start'].items()}
    pen = {key: run.values[label] for key, label in reads['penultimate'].items()}
    final = {key: run.values[label] for key, label in reads['final'].items()}
    detail = {
        'metric': 'aura',
        'control_aura': ctrl['aura'], 'control_charges': ctrl['charges'],
        'start_aura': start['aura'], 'start_charges': start['charges'],
        'pen_aura': pen['aura'], 'pen_charges': pen['charges'],
        'final_aura': final['aura'], 'final_charges': final['charges'],
        'pen_swings': pen['swings'] - start['swings'],
        'pen_hits': pen['hits'] - start['hits'],
        'pen_crits': pen['crits'] - start['crits'],
        'final_swings': final['swings'] - start['swings'],
        'final_hits': final['hits'] - start['hits'],
        'final_crits': final['crits'] - start['crits'],
        'elapsed_ms': final['time'] - start['time'],
    }
    if ctrl['aura'] != 0 or ctrl['charges'] != 0:
        return replace(base, status='alert', measured=ctrl['charges'], expected=0.0, detail=detail,
                       explanation=f'control without gate_spell had aura {ctrl["aura"]:g}, charges '
                                   f'{ctrl["charges"]:g}')
    if start['aura'] != 1 or start['charges'] != expected:
        return replace(base, status='alert', measured=start['charges'], expected=float(expected), detail=detail,
                       explanation=f'treatment start had aura {start["aura"]:g}, charges {start["charges"]:g} '
                                   f'against expected {expected}')
    if (detail['pen_swings'] != expected - 1 or detail['pen_hits'] != expected - 1 or detail['pen_crits'] != 0
            or detail['final_swings'] != expected or detail['final_hits'] != expected or detail['final_crits'] != 0):
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'swing fixture mismatch: pen ({detail["pen_swings"]:g} swings, '
                                   f'{detail["pen_hits"]:g} hits, {detail["pen_crits"]:g} crits), final '
                                   f'({detail["final_swings"]:g} swings, {detail["final_hits"]:g} hits, '
                                   f'{detail["final_crits"]:g} crits) against {expected - 1}/{expected} non-crit hits')
    if detail['elapsed_ms'] <= 0 or detail['elapsed_ms'] >= max_window_ms:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'10 swings elapsed {detail["elapsed_ms"]:.0f} ms, outside (0, {max_window_ms}) ms '
                                   f'before duration expiry')
    if pen['aura'] != 1 or pen['charges'] != 1:
        return replace(base, status='alert', measured=pen['charges'], expected=1.0, detail=detail,
                       explanation=f'after {expected - 1} swings aura={pen["aura"]:g}, charges={pen["charges"]:g} '
                                   f'(expected aura=1, charges=1) in {pen["time"] - start["time"]:.0f} ms')
    if final['aura'] != 0 or final['charges'] != 0:
        return replace(base, status='alert', measured=final['charges'], expected=0.0, detail=detail,
                       explanation=f'after {expected} swings aura={final["aura"]:g}, charges={final["charges"]:g} '
                                   f'(expected aura=0, charges=0) in {detail["elapsed_ms"]:.0f} ms')
    return replace(base, status='ok', measured=float(expected), expected=float(expected),
                   low=float(expected), high=float(expected), detail=detail,
                   explanation=f'control 0/0; start 1/{expected}; after {expected - 1} swings 1/1; after {expected} '
                               f'swings 0/0 in {detail["elapsed_ms"]:.0f} ms (< {max_window_ms} ms)')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return swing_charge_scenario(class_file, swing_charge_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: swing_charge_verdict}
