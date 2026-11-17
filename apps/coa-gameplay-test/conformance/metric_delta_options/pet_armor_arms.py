from dataclasses import dataclass, replace

NAME = 'pet_armor_arms'
ORDER = 23
METRIC = 'pet_melee_plain_damage'
COUNT_METRIC = 'pet_melee_plain_count'
METRIC_EVIDENCE = {METRIC: 'event'}
BARE = 'bare_dummy'
DUMMIES = ('dummy', BARE)
PHASES = ('without', 'with')
PROBE_SPELL = 6603
PROBE_AMOUNT = 1000
SUMMON_SETTLE_MS = 2000
AURA_SETTLE_MS = 600
SWITCH_SETTLE_MS = 500
MAX_TRIALS = 200
MAX_WINDOW_MS = 20000


@dataclass(frozen=True)
class PetArmorArms:
    summon: int
    entry: int
    bare_aura: int
    armor_aura: int
    trials: int
    window_ms: int


def parse(raw) -> PetArmorArms:
    keys = ('summon', 'entry', 'bare_aura', 'armor_aura', 'trials', 'window_ms')
    if not isinstance(raw, dict) or set(raw) != set(keys) or any(type(raw[key]) is not int or raw[key] < 1
                                                                 for key in keys) \
            or raw['trials'] > MAX_TRIALS or raw['window_ms'] > MAX_WINDOW_MS:
        raise ValueError(f'pet_armor_arms is {{{", ".join(keys)}}}, positive integers, at most {MAX_TRIALS} trials '
                         f'and {MAX_WINDOW_MS} ms windows, not {raw!r}')
    return PetArmorArms(**raw)


def check(spec, arms):
    if arms is not None and (spec.metric != METRIC or spec.fields or spec.strike is not None or spec.setup_casts
                             or spec.attack_swings or spec.target != 'caster'):
        raise ValueError(f'{spec.spell} pet_armor_arms reads the current pet\'s {METRIC} with no fields, strike, '
                         f'setup casts or attack swings, the trigger cast at the caster')


def label(spec, *parts: str) -> str:
    return ' '.join((f'{spec.spell} {spec.label_suffix} pet armor', *parts))


def swing_reads(spec, phase: str, dummy: str, mark: int) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(label(spec, phase, dummy, str(mark), read), CASTER, metric)
            for read, metric in (('total', METRIC), ('count', COUNT_METRIC))]


def probe_reads(spec, phase: str) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(label(spec, phase, dummy, 'armor reduced'), CASTER, 'armor_reduced_damage', pet=True,
                        spell=PROBE_SPELL, target=dummy) for dummy in DUMMIES]


def trigger_steps(spec) -> list[dict]:
    from profile import CASTER
    power = ([{'action': 'set_power', 'actor': CASTER, 'power': 0, 'value': spec.cast_power}]
             if spec.cast_power is not None else [])
    return power + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                    {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': CASTER},
                    {'action': 'wait', 'label': 'let the trigger aura reach the pet', 'ms': AURA_SETTLE_MS}]


def fixture_auras(arms: PetArmorArms) -> list[dict]:
    from profile import CASTER
    return [{'action': 'set_aura', 'actor': CASTER, 'spell': spell, 'stacks': stacks, 'target': dummy,
             'caster': CASTER} for spell, dummy in ((arms.armor_aura, 'dummy'), (arms.bare_aura, BARE))
            for stacks in (0, 1)]


def arm_steps(spec, arms: PetArmorArms, phase: str, dummy: str) -> list[dict]:
    from profile import CASTER, measurement
    steps = fixture_auras(arms) + [
             {'action': 'attack', 'actor': CASTER, 'target': dummy, 'pet': True},
             {'action': 'wait', 'label': f'pet switches to the {dummy}', 'ms': SWITCH_SETTLE_MS}]
    for trial in range(1, arms.trials + 1):
        if phase == 'with':
            steps += trigger_steps(spec)
        steps += fixture_auras(arms)
        steps += swing_reads(spec, phase, dummy, f'{trial} start')
        steps += [
                  {'action': 'wait', 'label': f'{phase} {dummy} swings {trial}', 'ms': arms.window_ms}]
        steps += swing_reads(spec, phase, dummy, trial)
        steps += [measurement(label(spec, phase, dummy, str(trial), 'armor', unit), unit, 'armor') for unit in DUMMIES]
    if phase == 'with':
        steps.append(measurement(label(spec, phase, dummy, 'aura'), CASTER, 'pet_aura_stacks',
                                 spell=spec.trigger_spell))
    return steps


def fixtures(class_file: dict, spec, arms: PetArmorArms, scenario: dict):
    from hits import MAX_ACCELERATED_SCENARIO_MS, timed
    from profile import CASTER, base_steps, measurement
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                                      for spell in (spec.spell, spec.trigger_spell, arms.summon, *spec.learn)]
    steps += [{'action': 'cast', 'actor': CASTER, 'spell': arms.summon, 'target': CASTER},
              {'action': 'wait', 'label': 'let the pet arrive', 'ms': SUMMON_SETTLE_MS},
              measurement(label(spec, 'pet entry'), CASTER, 'pet_entry'), *fixture_auras(arms)]
    steps += [measurement(label(spec, dummy, 'armor'), dummy, 'armor') for dummy in DUMMIES]
    steps += probe_reads(spec, 'without')
    for phase in PHASES:
        if phase == 'with':
            steps += trigger_steps(spec) + probe_reads(spec, 'with')
        for dummy in DUMMIES:
            steps += arm_steps(spec, arms, phase, dummy)
    steps.append({'action': 'stop_attack', 'actor': CASTER})
    scenario['steps'] = steps
    dummy = next(creature for creature in scenario['creatures'] if creature['id'] == 'dummy')
    scenario['creatures'].append({**dummy, 'id': BARE})
    scenario['contract'] = (
        f'Pet armor arms: the pet {arms.entry} is summoned by {arms.summon} and read back as the current pet '
        f'(pet_entry); its plain melee swings are read by its pet GUID, never by creature entry. Two dummies of the '
        f'same fixture: dummy, whose armor {arms.armor_aura} raises, and {BARE}, whose armor {arms.bare_aura} removes '
        f'(both fixtures removed and set again before every window, so each window holds a full duration; both '
        f'dummies\' armor read at every window end and required equal to the first reads). Four arms of '
        f'{arms.trials} windows of {arms.window_ms} ms, the pet attacking one '
        f'dummy at a time: without {spec.trigger_spell} on the dummy then the {BARE}, then with {spec.trigger_spell} '
        f'cast at the caster before every window (aura read on the pet at the end of the arm) on the dummy then the '
        f'{BARE}. Judged: with {spec.trigger_spell}, the per-hit plain damage on the dummy over the {BARE} is 1.0 '
        f'(armor ignored), within 5% of the ratio; contrast: without it the same ratio equals the read '
        f'armor_reduced_damage of the pet against the dummy ({PROBE_SPELL}, per {PROBE_AMOUNT}, READBACK data arm), '
        f'within 5%. The armor_reduced_damage reads with {spec.trigger_spell} are recorded as data.')
    waited = sum(step['ms'] for step in steps if step['action'] == 'wait')
    scenario.pop('timeout_ms', None)
    timed(scenario, waited, MAX_ACCELERATED_SCENARIO_MS)


def model(spec, arms: PetArmorArms) -> dict:
    reads = {phase: {dummy: [[label(spec, phase, dummy, str(mark), 'total'),
                              label(spec, phase, dummy, str(mark), 'count')] for trial in range(1, arms.trials + 1)
                              for mark in (f'{trial} start', trial)]
                     for dummy in DUMMIES} for phase in PHASES}
    return {NAME: {'entry': arms.entry, 'pet_entry': label(spec, 'pet entry'), 'reads': reads,
                   'armor': {dummy: label(spec, dummy, 'armor') for dummy in DUMMIES},
                   'probes': {phase: {dummy: label(spec, phase, dummy, 'armor reduced') for dummy in DUMMIES}
                              for phase in PHASES},
                   'auras': {dummy: label(spec, 'with', dummy, 'aura') for dummy in DUMMIES},
                   'window_armor': [label(spec, phase, dummy, str(trial), 'armor', unit) for phase in PHASES
                                    for dummy in DUMMIES for trial in range(1, arms.trials + 1) for unit in DUMMIES]}}


def ratio_bonus(run, reads: dict, expected_ratio: float):
    from bonus import RELATIVE_BAND, bonus_of, bonus_status, per_event_sample
    from compare import hit_ratio_series
    samples = {}
    for dummy in DUMMIES:
        found = hit_ratio_series(run, reads[dummy])
        if isinstance(found, str):
            return found
        totals, counts = (series[::2] for series in found)
        if sum(counts) == 0:
            return f'{dummy} has no measured swings'
        samples[dummy] = per_event_sample(totals, counts)
    bonus = replace(bonus_of(samples['dummy'], samples[BARE], (expected_ratio - 1) * 100),
                    fixed_band=RELATIVE_BAND * expected_ratio * 100)
    return bonus, bonus_status(bonus)


def verdict(verdict, run, arms: dict):
    from bonus import bonus_text
    values = run.values
    fixed = [arms['pet_entry'], *arms['armor'].values(), *arms['auras'].values(),
             *(label for probes in arms['probes'].values() for label in probes.values())]
    missing = next((label for label in fixed if values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='unmeasured', explanation=f'pet armor arms: {missing} was not read')
    armor = {dummy: values[arms['armor'][dummy]] for dummy in DUMMIES}
    probes = {phase: {dummy: values[label] for dummy, label in arms['probes'][phase].items()}
              for phase in PHASES}
    auras = {dummy: values[arms['auras'][dummy]] for dummy in DUMMIES}
    facts = (f'pet entry {values[arms["pet_entry"]]:g}, armor {armor["dummy"]:g} and {armor[BARE]:g}, '
             f'armor_reduced_damage per {PROBE_AMOUNT} without {probes["without"]} and with {probes["with"]} '
             f'(data), aura on the pet {auras}')
    window_armor = [values.get(read) for read in arms['window_armor']]
    held = all(read == armor[read_label.rsplit(' ', 1)[1]]
               for read, read_label in zip(window_armor, arms['window_armor']))
    facts += f', armor held at every window end: {held}'
    if values[arms['pet_entry']] != arms['entry'] or armor[BARE] != 0 or armor['dummy'] <= 0 or not held \
            or min(auras.values()) < 1 or probes['without'][BARE] != PROBE_AMOUNT:
        return replace(verdict, status='unmeasured',
                       explanation=f'pet armor arms: a precondition failed ({facts}): the pet must be {arms["entry"]}, '
                                   f'the {BARE} at 0 armor and unreduced, the dummy armored, the aura on the pet')
    control_ratio = probes['without']['dummy'] / PROBE_AMOUNT
    judged = {}
    for phase, expected in (('with', 1.0), ('without', control_ratio)):
        found = ratio_bonus(run, arms['reads'][phase], expected)
        if isinstance(found, str):
            return replace(verdict, status='unmeasured', explanation=f'pet armor arms: {found}')
        judged[phase] = found
    (claim, (claim_status, claim_reason, needed)), (control, (control_status, control_reason, _)) = \
        judged['with'], judged['without']
    statuses = {claim_status, control_status}
    status = 'alert' if 'alert' in statuses else claim_status if claim_status != 'ok' else control_status
    explanation = (f'pet armor arms, with the trigger, dummy over {BARE}: {bonus_text(claim)}, {claim_reason}; '
                   f'contrast without it, against the read ratio {control_ratio:.4g}: {bonus_text(control)}, '
                   f'{control_reason}; {facts}')
    return replace(verdict, status=status, measured=claim.measured, expected=claim.expected,
                   low=claim.expected - claim.band, high=claim.expected + claim.band, explanation=explanation,
                   detail={**(verdict.detail or {}), 'trials_needed': needed})
