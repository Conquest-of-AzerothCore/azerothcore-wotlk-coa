from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, banded_rate, missing_measurement, rate_judgement
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from procs import band_trials_needed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of

KIND = 'cooldown_reset_rate'
ORDER = 29
CLEAR_COOLDOWN_OPCODE = 0x1DE
MAXIMUM_STEPS = 10000
MAX_DUMMY_DISTANCE_YD = 100


@dataclass(frozen=True)
class CooldownResetRateSpec:
    spell: int
    name: str
    quote: str
    talent: int
    trigger_spell: int
    reset_spell: int
    chance_pct: float
    casts: int
    control_casts: int
    cast_wait_ms: int
    label_suffix: str = 'reset_rate'
    cast_power: int | None = None
    attempt_auras: tuple[tuple[int, int], ...] = ()
    parts: int = 1
    dummy_distance: float | None = None


def attempt_auras_of(spell: int, raw) -> tuple[tuple[int, int], ...]:
    if raw is None:
        return ()
    if not isinstance(raw, list) or not raw or not all(
            isinstance(aura, dict) and set(aura) == {'spell', 'stacks', 'source'} and isinstance(aura['spell'], int)
            and isinstance(aura['stacks'], int) and aura['stacks'] >= 0 and aura['source'] for aura in raw):
        raise ValueError(f'{spell} {KIND} attempt_auras lists {{"spell", "stacks", "source"}} caster auras')
    return tuple((aura['spell'], aura['stacks']) for aura in raw)


def cooldown_reset_rate_spec(entry: dict) -> CooldownResetRateSpec:
    spec = CooldownResetRateSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['talent']),
                                 int(entry['trigger_spell']), int(entry['reset_spell']), float(entry['chance_pct']),
                                 int(entry['casts']), int(entry['control_casts']), int(entry['cast_wait_ms']),
                                 entry.get('label_suffix', 'reset_rate'),
                                 None if entry.get('cast_power') is None else int(entry['cast_power']),
                                 attempt_auras_of(int(entry['spell']), entry.get('attempt_auras')),
                                 int(entry.get('parts', 1)),
                                 None if entry.get('dummy_distance') is None else float(entry['dummy_distance']))
    if spec.dummy_distance is not None and not 0 < spec.dummy_distance <= MAX_DUMMY_DISTANCE_YD:
        raise ValueError(f'{spec.spell} {KIND} places the dummy {spec.dummy_distance:g} yd away, outside (0, '
                         f'{MAX_DUMMY_DISTANCE_YD}] yd')
    if not 0 < spec.chance_pct < 100 or spec.control_casts < 1 or spec.cast_wait_ms < 1 or spec.parts < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a chance below 100%, control casts, a wait between casts and at '
                         f'least one part')
    if spec.casts * spec.parts < band_trials_needed(spec.chance_pct / 100):
        raise ValueError(f'{spec.spell} {KIND} casts {spec.casts} times in {spec.parts} pooled parts, fewer than the '
                         f'{band_trials_needed(spec.chance_pct / 100)} trials its rate band needs')
    return spec


def reset_mark(spec: CooldownResetRateSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def cooldown_reset_rate_scenario(class_file: dict, spec: CooldownResetRateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.chance_pct)
    facts = facts_of(records, spec.trigger_spell)
    if spec.cast_power is None and (facts.mana_cost or facts.mana_cost_percentage):
        raise ValueError(f'{spec.spell} {KIND} repeats {spec.trigger_spell}, which needs a cost-free trigger or a '
                         f'cast_power')
    if spec.cast_power is not None and (facts.mana_cost_percentage or facts.mana_cost_per_level
                                        or not facts.mana_cost <= spec.cast_power):
        raise ValueError(f'{spec.spell} {KIND} cast_power {spec.cast_power} must cover the flat cost '
                         f'{facts.mana_cost} of {spec.trigger_spell}')
    refill = ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power}]
              if spec.cast_power is not None else [])
    refill += [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks}
               for spell, stacks in spec.attempt_auras]

    def casts(count: int) -> list[dict]:
        return [step for _ in range(count) for step in (
            *refill,
            {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET},
            {'action': 'wait', 'label': 'cast', 'ms': spec.cast_wait_ms})]

    def reads(phase: str) -> list[dict]:
        return [measurement(reset_mark(spec, f'{phase} hits'), CASTER, 'spell_damage_count',
                            spell=spec.trigger_spell, target=TARGET),
                measurement(reset_mark(spec, f'{phase} resets'), CASTER, 'server_packets',
                            opcode=CLEAR_COOLDOWN_OPCODE, row=spec.reset_spell)]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell},
                {'action': 'learn', 'actor': CASTER, 'spell': spec.reset_spell}]
             + casts(spec.control_casts) + reads('control')
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}]
             + casts(spec.casts) + reads('treatment'))
    if len(steps) > MAXIMUM_STEPS:
        raise ValueError(f'{spec.spell} {KIND} needs {len(steps)} steps, more than {MAXIMUM_STEPS}')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour cooldown reset rate',
        'contract': (f'{spec.trigger_spell} is cast at the dummy {spec.control_casts} times before {spec.talent} is '
                     f'learned (control: no SMSG_CLEAR_COOLDOWN of {spec.reset_spell}) and {spec.casts} times after; '
                     f'the clear-cooldown packets of {spec.reset_spell} per damaging hit of {spec.trigger_spell} '
                     f'must hold {spec.chance_pct:g}% in a Wilson 99% interval inside the G-20 band.'
                     + (f' The power of {spec.trigger_spell} is set to {spec.cast_power} before each cast.'
                        if spec.cast_power is not None else '')
                     + ''.join(f' Aura {spell} is set on the caster at {stacks} stacks before each cast.'
                               for spell, stacks in spec.attempt_auras)
                     + (f' This case is one of {spec.parts} identical pooled parts: the rate is judged on the hits '
                        f'and resets summed over every part (at least {band_trials_needed(spec.chance_pct / 100)} '
                        f'trials, so a conformant server fails the Wilson 99% interval inside the band with a '
                        f'probability of at most 1%), and a missing part leaves the claim unmeasured.'
                        if spec.parts > 1 else '')
                     + (f' The dummy stands {spec.dummy_distance:g} yd from the caster.'
                        if spec.dummy_distance is not None else '')),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file) if spec.dummy_distance is None
                      else creature_fixture(class_file, spec.dummy_distance)],
        'steps': steps}
    marks = ('control hits', 'control resets', 'treatment hits', 'treatment resets')
    model = {'kind': KIND, 'metric': 'server_packets', 'quote': entry.quote, 'chance_pct': spec.chance_pct,
             'minimum_trials': band_trials_needed(spec.chance_pct / 100),
             'reads': {mark: reset_mark(spec, mark) for mark in marks}}
    expectation = Expectation(reset_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell,
                              None, f'{spec.chance_pct:g}%', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), [expectation]


def cooldown_reset_rate_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return cooldown_reset_rate_pooled_verdict(base, [run], model)


def cooldown_reset_rate_pooled_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    reads = model['reads']
    values = {mark: 0.0 for mark in reads}
    for run in runs:
        found = {mark: run.values.get(label) for mark, label in reads.items()}
        missing = next((mark for mark, value in found.items() if value is None), None)
        if missing:
            return replace(base, explanation=missing_measurement(run, reads[missing]))
        if found['control resets'] != 0:
            where = f' in {run.key}' if len(runs) > 1 else ''
            return replace(base, status='alert', explanation=f'{found["control resets"]:g} resets before the talent '
                                                             f'was learned (control){where}')
        for mark, value in found.items():
            values[mark] += value
    trials = values['treatment hits'] - values['control hits']
    events = values['treatment resets'] - values['control resets']
    expected = float(model['chance_pct']) / 100
    status, low, high, why = rate_judgement(events, trials, int(model['minimum_trials']), expected)
    if low is not None:
        status, low, high, why = banded_rate(status, low, high, expected, why)
    return replace(base, status=status, measured=events / trials if trials > 0 else None, expected=expected,
                   low=low, high=high, detail={'resets': events, 'hits': trials},
                   explanation=f'no reset in the control ({values["control hits"]:g} hits); {events:g} resets in '
                               f'{trials:g} hits with the talent' + (f' over {len(runs)} pooled parts'
                                                                      if len(runs) > 1 else '') + f': {why}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return cooldown_reset_rate_scenario(class_file, cooldown_reset_rate_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'reset_rate')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: cooldown_reset_rate_verdict}
POOLED_JUDGE = cooldown_reset_rate_pooled_verdict
