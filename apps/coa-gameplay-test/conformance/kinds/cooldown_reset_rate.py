from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, banded_rate, missing_measurement, rate_judgement
from hits import creature_fixture, timed
from procs import band_trials_needed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, TARGET, dataset, facts_of

KIND = 'cooldown_reset_rate'
ORDER = 29
CLEAR_COOLDOWN_OPCODE = 0x1DE
MAXIMUM_STEPS = 10000


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


def cooldown_reset_rate_spec(entry: dict) -> CooldownResetRateSpec:
    spec = CooldownResetRateSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['talent']),
                                 int(entry['trigger_spell']), int(entry['reset_spell']), float(entry['chance_pct']),
                                 int(entry['casts']), int(entry['control_casts']), int(entry['cast_wait_ms']),
                                 entry.get('label_suffix', 'reset_rate'))
    if not 0 < spec.chance_pct < 100 or spec.control_casts < 1 or spec.cast_wait_ms < 1:
        raise ValueError(f'{spec.spell} {KIND} needs a chance below 100%, control casts and a wait between casts')
    if spec.casts < band_trials_needed(spec.chance_pct / 100):
        raise ValueError(f'{spec.spell} {KIND} casts {spec.casts} times, fewer than the '
                         f'{band_trials_needed(spec.chance_pct / 100)} trials its rate band needs')
    return spec


def reset_mark(spec: CooldownResetRateSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'


def cooldown_reset_rate_scenario(class_file: dict, spec: CooldownResetRateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.chance_pct)
    facts = facts_of(records, spec.trigger_spell)
    if facts.mana_cost or facts.mana_cost_percentage:
        raise ValueError(f'{spec.spell} {KIND} repeats {spec.trigger_spell}, which needs a cost-free trigger')

    def casts(count: int) -> list[dict]:
        return [step for _ in range(count) for step in (
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
                     f'must hold {spec.chance_pct:g}% in a Wilson 99% interval inside the G-20 band.'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    marks = ('control hits', 'control resets', 'treatment hits', 'treatment resets')
    model = {'kind': KIND, 'metric': 'server_packets', 'quote': entry.quote, 'chance_pct': spec.chance_pct,
             'minimum_trials': band_trials_needed(spec.chance_pct / 100),
             'reads': {mark: reset_mark(spec, mark) for mark in marks}}
    expectation = Expectation(reset_mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.trigger_spell,
                              None, f'{spec.chance_pct:g}%', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def cooldown_reset_rate_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    values = {mark: run.values.get(label) for mark, label in reads.items()}
    missing = next((mark for mark, value in values.items() if value is None), None)
    if missing:
        return replace(base, explanation=missing_measurement(run, reads[missing]))
    if values['control resets'] != 0:
        return replace(base, status='alert', explanation=f'{values["control resets"]:g} resets before the talent '
                                                         f'was learned (control)')
    trials = values['treatment hits'] - values['control hits']
    events = values['treatment resets'] - values['control resets']
    expected = float(model['chance_pct']) / 100
    status, low, high, why = rate_judgement(events, trials, int(model['minimum_trials']), expected)
    if low is not None:
        status, low, high, why = banded_rate(status, low, high, expected, why)
    return replace(base, status=status, measured=events / trials if trials > 0 else None, expected=expected,
                   low=low, high=high, detail={'resets': events, 'hits': trials},
                   explanation=f'no reset in the control ({values["control hits"]:g} hits); {events:g} resets in '
                               f'{trials:g} hits with the talent: {why}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return cooldown_reset_rate_scenario(class_file, cooldown_reset_rate_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'reset_rate')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: cooldown_reset_rate_verdict}
