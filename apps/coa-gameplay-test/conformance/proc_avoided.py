from profile import CASTER, measurement
from values import fixture_health_step

AVOIDED = 'avoided'
STRIKER_ID = 'striker'
MAX_STRIKERS = 10
DODGED, PARRIED, LANDED, FULL_BLOCKED = 2, 3, 1, 5
TRIAL_STATES = {'dodged': DODGED, 'parried': PARRIED}
GUARD_STATES = {'landed': LANDED, 'blocked': FULL_BLOCKED}
TRIALS_PER_ATTEMPT = 'trials_per_attempt'
TRIGGER_FIELDS = {'action', 'striker_entry', 'swing_ms', 'dodge', 'parry', 'strikers', 'striker_auras', 'count_misses',
                  'miss_exclusion', 'learn'}
READING_NAME = 'avoided swings (dodged + parried)'
MISSES_READING_NAME = 'avoided swings (dodged + parried + missed)'
MISSED = 'missed'
MISSED_METRIC = 'melee_missed_taken'
ATTACK_BALANCE = 'attack_balance'


def is_avoided(entry: dict) -> bool:
    return entry['trigger']['action'] == AVOIDED


def checked_trigger(entry: dict) -> dict:
    trigger, aura = entry['trigger'], entry['aura']
    if set(trigger) - TRIGGER_FIELDS:
        raise ValueError(f'Proc {aura} avoided trigger has unknown fields {sorted(set(trigger) - TRIGGER_FIELDS)}')
    numbers = {name: trigger.get(name) for name in ('striker_entry', 'swing_ms', 'dodge', 'parry')}
    if any(isinstance(value, bool) or not isinstance(value, (int, float)) for value in numbers.values()):
        raise ValueError(f'Proc {aura} avoided trigger needs a striker_entry, swing_ms, dodge and parry')
    if not (isinstance(trigger['striker_entry'], int) and trigger['striker_entry'] > 0
            and isinstance(trigger['swing_ms'], int) and trigger['swing_ms'] > 0):
        raise ValueError(f'Proc {aura} avoided trigger needs a positive striker_entry and swing_ms')
    if min(trigger['dodge'], trigger['parry']) < 0 or trigger['dodge'] + trigger['parry'] != 100:
        raise ValueError(f'Proc {aura} avoided trigger dodge and parry must be non-negative and sum to 100, so no '
                         f'swing lands')
    count = strikers(entry)
    if isinstance(count, bool) or not isinstance(count, int) or not 1 <= count <= MAX_STRIKERS:
        raise ValueError(f'Proc {aura} avoided trigger strikers must be a whole number from 1 to {MAX_STRIKERS}')
    auras = striker_auras(entry)
    if not isinstance(auras, list) or any(isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0
                                          for spell in auras):
        raise ValueError(f'Proc {aura} avoided trigger striker_auras must be a list of positive spell ids')
    if type(trigger.get('count_misses', False)) is not bool:
        raise ValueError(f'Proc {aura} avoided trigger count_misses is a boolean')
    exclusion = trigger.get('miss_exclusion')
    if exclusion is not None and (not counts_misses(entry) or not isinstance(exclusion, dict)
                                  or set(exclusion) != {'min_share'} or isinstance(exclusion['min_share'], bool)
                                  or not isinstance(exclusion['min_share'], (int, float))
                                  or not 0 < exclusion['min_share'] < 0.5):
        raise ValueError(f'Proc {aura} avoided trigger miss_exclusion is {{"min_share": 0 to 0.5 exclusive}} and '
                         f'needs count_misses true')
    learn = trigger.get('learn', [])
    if not isinstance(learn, list) or len(set(learn)) != len(learn) or aura in learn or any(
            isinstance(spell, bool) or not isinstance(spell, int) or spell <= 0 for spell in learn):
        raise ValueError(f'Proc {aura} avoided trigger learn is a list of distinct positive spell ids other than the '
                         f'passive')
    if entry.get('trial_readings') or entry.get(TRIALS_PER_ATTEMPT):
        raise ValueError(f'Proc {aura} avoided trigger sets its own trial reading and trials per attempt')
    return trigger


def counts_misses(entry: dict) -> bool:
    return entry['trigger'].get('count_misses', False) is True


def miss_exclusion_share(entry: dict) -> float | None:
    exclusion = entry['trigger'].get('miss_exclusion')
    return None if exclusion is None else float(exclusion['min_share'])


def miss_exclusion_model(entry: dict, trials_label: str) -> dict | None:
    share = miss_exclusion_share(entry)
    return None if share is None else {'min_share': share, 'missed': trial_labels(trials_label, True)[MISSED]}


def learned(entry: dict) -> list:
    return entry['trigger'].get('learn', [])


def striker_auras(entry: dict) -> list:
    return entry['trigger'].get('striker_auras', [])


def strikers(entry: dict) -> int:
    return entry['trigger'].get('strikers', 1)


def striker_ids(entry: dict) -> list[str]:
    return [STRIKER_ID if index == 1 else f'{STRIKER_ID}_{index}' for index in range(1, strikers(entry) + 1)]


def striker_fixtures(class_file: dict, entry: dict) -> list[dict]:
    from behaviours import STRIKER_DISTANCE, STRIKER_HEALTH
    return [{'id': striker, 'owner': CASTER, 'entry': entry['trigger']['striker_entry'], 'level': class_file['level'],
             'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'reaction': 2, 'stationary': True}
            for striker in striker_ids(entry)]


def trial_labels(trials_label: str, misses: bool = False) -> dict[str, str]:
    labels = {outcome: trials_label if outcome == 'dodged' else f'{trials_label} {outcome}' for outcome in TRIAL_STATES}
    return {**labels, MISSED: f'{trials_label} {MISSED}'} if misses else labels


def guard_label(aura: int, name: str) -> str:
    return f'{aura} avoided guard {name}'


def snapshot_name(aura: int, name: str) -> str:
    return f'avoided_{aura}_{name.replace(" ", "_")}'


def guard_reads(entry: dict) -> dict[str, dict]:
    reads = {name: {'actor': CASTER, 'metric': 'melee_attacks_taken', 'victim_state': state}
             for name, state in GUARD_STATES.items()}
    reads['own swings'] = {'actor': CASTER, 'metric': 'melee_attack_count'}
    return reads


def engage_steps(entry: dict) -> list[dict]:
    from behaviours import AVOIDING_ENGAGE_MS
    steps = [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned(entry)]
    steps += [{'action': 'set_aura', 'actor': CASTER, 'target': striker, 'caster': striker, 'spell': aura,
               'stacks': 1} for striker in striker_ids(entry) for aura in striker_auras(entry)]
    for striker in striker_ids(entry):
        steps += avoidance_steps(entry) + [{'action': 'attack', 'actor': CASTER, 'target': striker},
                  {'action': 'wait', 'label': f'engage {striker}', 'ms': AVOIDING_ENGAGE_MS},
                  {'action': 'stop_attack', 'actor': CASTER}]
    return steps + [{'action': 'snapshot', **read, 'save_as': snapshot_name(entry['aura'], name)}
                    for name, read in guard_reads(entry).items()]


def guard_steps(entry: dict) -> list[dict]:
    return [{'action': 'assert', 'label': guard_label(entry['aura'], name), **read, 'equals': 0,
             'relative_to': snapshot_name(entry['aura'], name)} for name, read in guard_reads(entry).items()]


def avoidance_steps(entry: dict) -> list[dict]:
    from procs import attempt_auras
    trigger = entry['trigger']
    return [fixture_health_step(CASTER, 100), *attempt_auras(entry),
            {'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': trigger['dodge'], 'parry': trigger['parry']}]


def attempt_steps(entry: dict, attempts: int, swing_ms: int) -> list[dict]:
    return [step for _ in range(attempts) for step in avoidance_steps(entry) + [{'action': 'wait', 'ms': swing_ms}]]


def trial_steps(trials_label: str, attempts_label: str | None = None, misses: bool = False) -> list[dict]:
    steps = [measurement(label, CASTER, MISSED_METRIC) if outcome == MISSED
             else measurement(label, CASTER, 'melee_attacks_taken', victim_state=TRIAL_STATES[outcome])
             for outcome, label in trial_labels(trials_label, misses).items()]
    if attempts_label:
        steps.append(measurement(attempts_label, CASTER, 'melee_attacks_taken'))
    return steps


def reading(trials_label: str, misses: bool = False) -> dict:
    return {'name': MISSES_READING_NAME if misses else READING_NAME,
            'labels': list(trial_labels(trials_label, misses).values()), 'minus_events': False}


def attack_balance(trials_label: str, attempts_label: str) -> dict:
    return {'total': attempts_label, 'parts': list(trial_labels(trials_label, True).values())}


def attack_imbalance(balance: dict, values: dict) -> str | None:
    total = values.get(balance['total'])
    parts = [values.get(label) for label in balance['parts']]
    if total is None or None in parts:
        return 'no attack balance reads'
    if total != sum(parts):
        return (f'{total:g} attacks taken against {sum(parts):g} dodged, parried and missed with no landed or '
                f'blocked swing, so a swing outcome is miscounted')
    return None


def trial_rule(entry: dict) -> str:
    trigger = entry['trigger']
    carried = f', each carrying {striker_auras(entry)} (harness set_aura)' if striker_auras(entry) else ''
    return (f'trials: melee swings of {strikers(entry)} aggressive stationary striker(s) {trigger["striker_entry"]} '
            f'({trigger["swing_ms"]} ms swings{carried}) that the caster dodged or parried (melee_attacks_taken victim states '
            f'{DODGED} and {PARRIED}, summed)'
            + (f' or that missed it ({MISSED_METRIC}, added; a part whose attacks taken differ from the dodged, '
               f'parried and missed swings is void)' if counts_misses(entry) else '')
            + f'; before every swing interval the caster\'s health is set to full and '
            f'its dodge and parry to {trigger["dodge"]:g}% and {trigger["parry"]:g}% (set_combat_avoidance), so no '
            f'swing lands'
            + (f', and the caster\'s auras {[aura["spell"] for aura in entry["attempt_auras"]]} are set (harness '
               f'set_aura, a precondition fixture)' if entry.get('attempt_auras') else '')
            + f'; '
            + (f'the caster learns {learned(entry)} before the engage (a precondition, in every part); '
               if learned(entry) else '')
            + f'the caster engages each striker once, at the same set health and avoidance, before the '
            f'passive is learned and stops attacking; '
            f'the dodged and parried swings and the events up to that point are a held baseline; after the window '
            f'the caster\'s own auto attacks and the landed or fully blocked swings since the engage must be 0, or '
            f'the part fails before its reads (a second trigger source is never judged)'
            + (f'; part 1 holds baseline swing intervals before the learn, with no event allowed'
               if entry.get('baseline') else '')
            + (f'; the miss share is read in the same run: under {miss_exclusion_share(entry):g} the part cannot '
               f'separate a server that ignores misses and is unmeasured, otherwise the rate that server would '
               f'read, the stated chance x (1 - miss share), must lie outside the interval'
               if miss_exclusion_share(entry) is not None else ''))


def engage_ms(entry: dict) -> int:
    from behaviours import AVOIDING_ENGAGE_MS
    return strikers(entry) * AVOIDING_ENGAGE_MS


def baseline_swings(entry: dict, plan) -> int:
    from procs import baseline_attempts
    return baseline_attempts(plan.chance_pct)


def holds_swings(entry: dict, part: int) -> bool:
    return bool(entry.get('baseline')) and part == 0


def baseline_steps(entry: dict, plan, swings: bool) -> list[dict]:
    from hits import DRAIN_MS
    from procs import baseline_labels, event_steps
    from proc_stacks import avoided_attempt_steps, counts_stacks, drain_steps
    labels = baseline_labels(entry['aura'])
    steps = engage_steps(entry)
    if counts_stacks(entry):
        if swings:
            steps += avoided_attempt_steps(entry, baseline_swings(entry, plan), plan.attempt_ms, True)
            steps += drain_steps(entry, {'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS}, True)
        return steps + trial_steps(labels['trials'], misses=counts_misses(entry))
    if swings:
        steps += attempt_steps(entry, baseline_swings(entry, plan), plan.attempt_ms)
        steps.append({'action': 'wait', 'label': 'baseline drain', 'ms': DRAIN_MS})
    return steps + trial_steps(labels['trials'], misses=counts_misses(entry)) + [
        {**event_steps(entry)[0], 'label': labels['events']}]


def avoided_baseline_model(entry: dict, plan, part: int) -> dict:
    from procs import baseline_labels, proc_measurements
    labels = baseline_labels(entry['aura'])
    misses = counts_misses(entry)
    own, held = trial_labels(proc_measurements(entry['aura'])['trials'], misses), trial_labels(labels['trials'], misses)
    from proc_stacks import STACK_EVENTS, baseline_model, counts_stacks
    attempts = baseline_swings(entry, plan) if holds_swings(entry, part) else 0
    stacks = {STACK_EVENTS: baseline_model(entry, attempts, labels['trials'])} if counts_stacks(entry) else {}
    if stacks and not attempts:
        stacks[STACK_EVENTS]['reads'] = []
    return {**labels, 'attempts': attempts,
            'added_trials': {own[outcome]: held[outcome] for outcome in own if outcome != 'dodged'}, **stacks}


def baseline_ms(entry: dict, plan, part: int) -> int:
    from hits import DRAIN_MS
    swings = baseline_swings(entry, plan) * plan.attempt_ms + DRAIN_MS if holds_swings(entry, part) else 0
    return engage_ms(entry) + swings
