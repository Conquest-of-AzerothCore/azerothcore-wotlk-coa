from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, LEARNED_CONTRAST, SPELL_FAILED_NOT_READY, behaviour_entry,
                        hit_ratio_cast, prose_rule, waited_ms)
from bonus import bonus_band
from compare import CONTRAST, Run, Verdict, missing_measurement
from hits import creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, dataset, facts_of, fixture_health_step, required_aura_steps

KIND = 'heal_cooldown_cut'
ORDER = 45

METRIC = 'cast_failure'
STOP_SETTLE_MS = 300
MINIMUM_STEP_MS = 50
MAXIMUM_ATTEMPTS = 200
MINIMUM_HEALS = 2
CONTROL = 'control'
TREATMENT = 'treatment'
INEFFECTIVE = 'ineffective'
INEFFECTIVE_STEP_MS = 500
FULL_HEALTH_PCT = 100
PRIMED_READS = ('result', 'time', 'heals', 'healed', 'effective')
HEALED_READS = ('heals', 'healed', 'effective')
ATTEMPT_READS = ('result', 'time', 'heals')


@dataclass(frozen=True)
class HealCutSpec:
    spell: int
    name: str
    quote: str
    talent: int
    gated_spell: int
    cooldown_ms: int
    heal_spell: int
    heal_ms: int
    expected_cut_ms: float
    learn: tuple[int, ...]
    setup_casts: tuple[tuple[int, str], ...]
    cast_power: int
    health_pct: int
    first_attempt_ms: int
    last_attempt_ms: int
    attempt_step_ms: int
    effective_only: bool
    label_suffix: str


def heal_cut_spec(entry: dict) -> HealCutSpec:
    spell = int(entry['spell'])
    spec = HealCutSpec(spell, entry['name'], entry['quote'], int(entry.get('talent', spell)),
                       int(entry['gated_spell']), int(entry['cooldown_ms']), int(entry['heal_spell']),
                       int(entry['heal_ms']), float(entry['expected_cut_ms']),
                       tuple(int(value) for value in entry.get('learn', ())),
                       tuple((int(cast), str(target)) for cast, target in entry.get('setup_casts', ())),
                       int(entry['cast_power']), int(entry.get('health_pct', 1)), int(entry['first_attempt_ms']),
                       int(entry['last_attempt_ms']), int(entry['attempt_step_ms']),
                       bool(entry.get('effective_only', True)), entry.get('label_suffix', 'heal_cut'))
    if spec.talent in spec.learn:
        raise ValueError(f'{spell} {KIND} learns {spec.talent} only between the control and the treatment')
    if spec.attempt_step_ms < MINIMUM_STEP_MS or spec.expected_cut_ms <= 0 or not 0 < spec.health_pct < 100:
        raise ValueError(f'{spell} {KIND} attempts every {MINIMUM_STEP_MS} ms or more, states a positive cut and '
                         f'keeps the healed unit below full health')
    if (spec.last_attempt_ms - spec.first_attempt_ms) // spec.attempt_step_ms + 1 > MAXIMUM_ATTEMPTS:
        raise ValueError(f'{spell} {KIND} makes at most {MAXIMUM_ATTEMPTS} attempts per arm')
    if not GCD_WAIT_MS + spec.heal_ms + STOP_SETTLE_MS <= spec.first_attempt_ms < spec.last_attempt_ms \
            < spec.cooldown_ms:
        raise ValueError(f'{spell} {KIND} attempts after the heal stops and inside the {spec.cooldown_ms} ms cooldown')
    return spec


def cut_mark(spec: HealCutSpec, mark: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {mark}'.rstrip()


def stated_cooldown_ms(records: Records, spell: int) -> int:
    return max(int(records.field('Spell', spell, 'RecoveryTime')),
               int(records.field('Spell', spell, 'CategoryRecoveryTime')))


def heal_cut_scenario(class_file: dict, spec: HealCutSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, spec.expected_cut_ms)
    if stated_cooldown_ms(records, spec.gated_spell) != spec.cooldown_ms:
        raise ValueError(f'{spec.spell} {KIND} states a {spec.cooldown_ms} ms cooldown for {spec.gated_spell}, whose '
                         f'DBC recovery is {stated_cooldown_ms(records, spec.gated_spell)} ms')
    amplitude = int(records.amplitude_ms(spec.heal_spell, 0))
    channel = int(records.duration_ms(spec.heal_spell))
    if amplitude <= 0 or not MINIMUM_HEALS * amplitude <= spec.heal_ms < channel:
        raise ValueError(f'{spec.spell} {KIND} heals for {spec.heal_ms} ms, which must hold {MINIMUM_HEALS} ticks of '
                         f'{amplitude} ms and end before the {channel} ms channel does')
    heals = spec.heal_ms // amplitude
    landing = [spec.cooldown_ms - spec.expected_cut_ms * count for count in (heals - 1, heals)]
    if not (spec.first_attempt_ms < min(landing) and max(landing) < spec.last_attempt_ms):
        raise ValueError(f'{spec.spell} {KIND} expects the recast between {min(landing):g} and {max(landing):g} ms, '
                         f'outside its attempts from {spec.first_attempt_ms} to {spec.last_attempt_ms} ms')
    gated, healing = facts_of(records, spec.gated_spell), facts_of(records, spec.heal_spell)
    heal_fields = {'spell': spec.heal_spell, 'target': CASTER}

    def power() -> dict:
        return {'action': 'set_power', 'actor': CASTER, 'power': gated.power_type, 'value': spec.cast_power}

    def heal_reads(role: str, moment: str, names: tuple[str, ...]) -> list[dict]:
        metrics = {'heals': 'spell_heal_count', 'healed': 'spell_heal_total',
                   'effective': 'spell_effective_heal_total'}
        return [measurement(cut_mark(spec, f'{role} {moment} {name}'), CASTER, metrics[name], **heal_fields)
                for name in names]

    def arm(role: str, health_pct: int, step_ms: int) -> tuple[list[dict], list[list[str]]]:
        steps = [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}
                 for spell in (spec.gated_spell, spec.heal_spell)]
        steps += [power(), *required_aura_steps(gated),
                  {'action': 'cast', 'actor': CASTER, 'spell': spec.gated_spell, 'target': CASTER},
                  measurement(cut_mark(spec, f'{role} primed result'), CASTER, METRIC, spell=spec.gated_spell),
                  measurement(cut_mark(spec, f'{role} primed time'), CASTER, 'game_time_ms')]
        steps += heal_reads(role, 'primed', HEALED_READS)
        steps += [{'action': 'wait', 'label': 'global cooldown', 'ms': GCD_WAIT_MS},
                  fixture_health_step(CASTER, health_pct), power(), *required_aura_steps(healing),
                  {'action': 'cast', 'actor': CASTER, 'spell': spec.heal_spell, 'target': CASTER},
                  {'action': 'wait', 'label': 'healing', 'ms': spec.heal_ms},
                  {'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.heal_spell},
                  {'action': 'wait', 'label': 'heal stop', 'ms': STOP_SETTLE_MS}]
        steps += heal_reads(role, 'stopped', HEALED_READS)
        steps.append({'action': 'wait', 'label': 'cut window',
                      'ms': spec.first_attempt_ms - GCD_WAIT_MS - spec.heal_ms - STOP_SETTLE_MS})
        attempts = []
        for moment in range(spec.first_attempt_ms, spec.last_attempt_ms + 1, step_ms):
            labels = [cut_mark(spec, f'{role} attempt {moment} {read}') for read in ATTEMPT_READS]
            steps += [power(), *required_aura_steps(gated),
                      {'action': 'cast', 'actor': CASTER, 'spell': spec.gated_spell, 'target': CASTER},
                      measurement(labels[0], CASTER, METRIC, spell=spec.gated_spell),
                      measurement(labels[1], CASTER, 'game_time_ms'),
                      measurement(labels[2], CASTER, 'spell_heal_count', **heal_fields),
                      {'action': 'wait', 'label': 'attempt spacing', 'ms': step_ms}]
            attempts.append(labels)
        return steps, attempts

    learned = dict.fromkeys((*spec.learn, *(cast for cast, _ in spec.setup_casts), spec.gated_spell,
                             spec.heal_spell))
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
    for cast, target in spec.setup_casts:
        steps += hit_ratio_cast(records, cast, CASTER, target, spec.cast_power)
    roles = [(CONTROL, spec.health_pct, spec.attempt_step_ms), (TREATMENT, spec.health_pct, spec.attempt_step_ms)]
    if spec.effective_only:
        roles.append((INEFFECTIVE, FULL_HEALTH_PCT, max(spec.attempt_step_ms, INEFFECTIVE_STEP_MS)))
    built = {role: arm(role, health, step) for role, health, step in roles}
    steps += built[CONTROL][0] + [{'action': 'learn', 'actor': CASTER, 'spell': spec.talent}]
    steps += [step for role, _, _ in roles[1:] for step in built[role][0]]
    ineffective = (f' Ineffective arm, the talent kept: the caster at full health, so every heal is overhealing; '
                   f'every attempt, one every {max(spec.attempt_step_ms, INEFFECTIVE_STEP_MS)} ms, refused.'
                   if spec.effective_only else '')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour heal cooldown cut',
        'contract': (f'Each arm casts {spec.gated_spell} ({spec.cooldown_ms} ms cooldown) at the caster, then '
                     f'{spec.heal_spell} at the caster (health set to {spec.health_pct}% of a fixture maximum, a '
                     f'precondition fixture, so every heal is effective) for {spec.heal_ms} ms before the channel is '
                     f'cancelled; from {spec.first_attempt_ms} to {spec.last_attempt_ms} ms after the first cast '
                     f'{spec.gated_spell} is attempted every {spec.attempt_step_ms} ms with the game time and the '
                     f'heal count. Control without {spec.talent}: every attempt refused. Treatment with it learned: '
                     f'the last refusal and the first cast bracket the cut per heal, (cooldown - elapsed) / heals, '
                     f'which must lie inside the G-19 band of {spec.expected_cut_ms:g} ms.{ineffective}'),
        'players': [player_fixture(class_file)],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'cooldown_ms': spec.cooldown_ms,
             'expected': spec.expected_cut_ms, 'band': bonus_band(spec.expected_cut_ms),
             'arms': {role: {'primed': {name: cut_mark(spec, f'{role} primed {name}') for name in PRIMED_READS},
                             'stopped': {name: cut_mark(spec, f'{role} stopped {name}') for name in HEALED_READS},
                             'attempts': built[role][1], 'effective': role != INEFFECTIVE}
                      for role, _, _ in roles}}
    expectation = Expectation(cut_mark(spec, ''), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.gated_spell, None,
                              f'{spec.expected_cut_ms:g} ms per heal', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def arm_values(run: Run, arm: dict) -> dict | str:
    labels = [*arm['primed'].values(), *arm['stopped'].values(), *(label for row in arm['attempts'] for label in row)]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return missing
    primed = {name: run.values[label] for name, label in arm['primed'].items()}
    stopped = {name: run.values[label] for name, label in arm['stopped'].items()}
    rows = [[run.values[label] for label in row] for row in arm['attempts']]
    effective = stopped['effective'] - primed['effective']
    return {'primed': primed, 'stopped': stopped, 'rows': rows, 'heals': stopped['heals'] - primed['heals'],
            'effective': effective, 'overheal': (stopped['healed'] - primed['healed']) - effective}


def refused_rows(role: str, values: dict, cooldown: float, edges: dict, base: Verdict,
                 cause: str) -> Verdict | None:
    early = next((row for row in values['rows'] if row[0] == 0), None)
    if early is not None:
        elapsed = early[1] - values['primed']['time']
        return replace(base, status='alert', **edges,
                       explanation=f'{cause} the recast went through {elapsed:g} ms after the first cast, inside its '
                                   f'{cooldown:g} ms cooldown')
    other = next((row for row in values['rows'] if row[0] != SPELL_FAILED_NOT_READY), None)
    if other is not None:
        return replace(base, status='unmeasured', **edges,
                       explanation=f'a {role} attempt {other[1] - values["primed"]["time"]:g} ms after the first cast '
                                   f'was refused with {other[0]:g}, not {SPELL_FAILED_NOT_READY} (not ready), so the '
                                   f'refusal does not show the cooldown')
    return None


def heal_cut_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    arms = {}
    for role, arm in model['arms'].items():
        values = arm_values(run, arm)
        if isinstance(values, str):
            return replace(base, explanation=missing_measurement(run, values))
        arms[role] = values
    for role, values in arms.items():
        if values['primed']['result'] != 0:
            return replace(base, status='unmeasured', explanation=f'the {role} priming cast was refused with '
                                                                  f'{values["primed"]["result"]:g}')
        if values['heals'] < MINIMUM_HEALS:
            return replace(base, status='unmeasured', explanation=f'the {role} arm read {values["heals"]:g} heals')
        effective_arm = model['arms'][role].get('effective', True)
        if effective_arm and values['overheal'] > 0.5:
            return replace(base, status='unmeasured', explanation=f'the {role} arm overhealed {values["overheal"]:g}, '
                                                                  f'so not every heal was effective')
        if not effective_arm and values['effective'] > 0.5:
            return replace(base, status='unmeasured', explanation=f'the {role} arm healed {values["effective"]:g} '
                                                                  f'effectively, so its heals were not all overhealing')
    cooldown, expected, band = float(model['cooldown_ms']), float(model['expected']), float(model['band'])
    edges = dict(expected=expected, low=expected - band, high=expected + band)
    control = arms[CONTROL]
    unrefused = refused_rows(CONTROL, control, cooldown, edges, base, 'without the talent')
    if unrefused is not None:
        return unrefused
    if INEFFECTIVE in arms:
        unrefused = refused_rows(INEFFECTIVE, arms[INEFFECTIVE], cooldown, edges, base,
                                 f'with the talent and {arms[INEFFECTIVE]["heals"]:g} heals that were all overhealing')
        if unrefused is not None:
            return unrefused
    treated = arms[TREATMENT]
    start_time, start_heals = treated['primed']['time'], treated['primed']['heals']

    def cut(row: list[float]) -> float | None:
        heals = row[2] - start_heals
        return (cooldown - (row[1] - start_time)) / heals if heals > 0 else None

    rows = treated['rows']
    first = next((index for index, row in enumerate(rows) if row[0] == 0), None)
    detail = {CONTRAST: LEARNED_CONTRAST, 'heals': treated['heals'], 'control_heals': control['heals'],
              **({'ineffective_heals': arms[INEFFECTIVE]['heals']} if INEFFECTIVE in arms else {})}
    ineffective_note = (f'; ineffective arm: every attempt refused after {arms[INEFFECTIVE]["heals"]:g} overhealing '
                        f'heals' if INEFFECTIVE in arms else '')
    if first is None or first == 0:
        bound = cut(rows[-1] if first is None else rows[0])
        beyond = bound is not None and (bound < expected - band if first is None else bound > expected + band)
        where = (f'every attempt was refused, so the cut is below {bound:.1f} ms per heal' if first is None else
                 f'the first attempt was already cast, so the cut is at least {bound:.1f} ms per heal')
        return replace(base, status='alert' if beyond else 'unmeasured', detail=detail, **edges,
                       explanation=f'{where} against {expected:g} +- {band:g}')
    refused = rows[first - 1]
    if refused[0] != SPELL_FAILED_NOT_READY:
        return replace(base, status='unmeasured', detail=detail, **edges,
                       explanation=f'the last refusal read {refused[0]:g}, not {SPELL_FAILED_NOT_READY} (not ready)')
    low, high = cut(rows[first]), cut(refused)
    if low is None or high is None:
        return replace(base, status='unmeasured', detail=detail, **edges,
                       explanation='no heal before the bracketing attempts')
    inside = expected - band <= low and high <= expected + band
    outside = high < expected - band or low > expected + band
    status = 'ok' if inside else 'alert' if outside else 'unmeasured'
    return replace(base, status=status, measured=(low + high) / 2, detail=detail, **edges,
                   explanation=f'control: every attempt refused after {control["heals"]:g} heals'
                               f'{ineffective_note}; treatment: refused '
                               f'at {refused[1] - start_time:g} ms after {refused[2] - start_heals:g} heals, cast at '
                               f'{rows[first][1] - start_time:g} ms after {rows[first][2] - start_heals:g}: '
                               f'{low:.1f} to {high:.1f} ms per heal against {expected:g} +- {band:g}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return heal_cut_scenario(class_file, heal_cut_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'heal_cut')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: heal_cut_verdict}
