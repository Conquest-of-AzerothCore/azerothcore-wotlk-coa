from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER, STRIKER_DISTANCE, STRIKER_HEALTH, behaviour_entry,
                        prose_rule, waited_ms)
from hits import MAX_ACCELERATED_SCENARIO_MS, base_mana_steps, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import MAX_SCENARIO_STEPS, Expectation, dataset, facts_of

KIND = 'strike_miss_share'
ORDER = 47
CONTROL, TREATMENT = 'control', 'treatment'
CASTER_HEALTH = 1_000_000
SETTLE_MS = 300
STRIKER_ENTRY = 36
PASSIVE = 0


@dataclass(frozen=True)
class Refused:
    spell: int
    result: int
    attack_ms: int


@dataclass(frozen=True)
class StrikeMissShareSpec:
    spell: int
    name: str
    quote: str
    label_suffix: str
    trigger_spell: int
    trigger_aura: int
    strike_spell: int
    strikes: int
    strike_wait_ms: int
    trigger_wait_ms: int
    burst_ms: int
    control_bursts: int
    treatment_bursts: int
    control_minimum_share: float
    refused: Refused | None = None


def positive(entry: dict, name: str) -> int:
    value = entry[name]
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValueError(f'{entry["spell"]} {KIND} {name} is a positive whole number, not {value!r}')
    return value


def strike_miss_share_spec(entry: dict) -> StrikeMissShareSpec:
    raw = entry.get('refused')
    refused = None if raw is None else Refused(int(raw['spell']), int(raw['result']), int(raw['attack_ms']))
    spec = StrikeMissShareSpec(entry['spell'], entry['name'], entry['quote'], entry['label_suffix'],
                               positive(entry, 'trigger_spell'), positive(entry, 'trigger_aura'),
                               positive(entry, 'strike_spell'), positive(entry, 'strikes'),
                               positive(entry, 'strike_wait_ms'), positive(entry, 'trigger_wait_ms'),
                               positive(entry, 'burst_ms'), positive(entry, 'control_bursts'),
                               positive(entry, 'treatment_bursts'), float(entry['control_minimum_share']), refused)
    busy = spec.trigger_wait_ms + spec.strikes * spec.strike_wait_ms + SETTLE_MS
    if busy >= spec.burst_ms:
        raise ValueError(f'{spec.spell} {KIND} strikes for {busy} ms, not inside a burst of {spec.burst_ms} ms')
    if not 0 < spec.control_minimum_share <= 1:
        raise ValueError(f'{spec.spell} {KIND} control_minimum_share lies in (0, 1]')
    if refused is not None and (refused.result <= 0 or refused.attack_ms <= 0
                                or spec.trigger_wait_ms + SETTLE_MS + refused.attack_ms >= spec.burst_ms):
        raise ValueError(f'{spec.spell} {KIND} refused needs a failure code and an attack inside the burst')
    return spec


def check_label(spec: StrikeMissShareSpec, suffix: str = '') -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}{suffix}'


def read_label(spec: StrikeMissShareSpec, arm: str, burst: int | str, moment: str, read: str) -> str:
    return f'{spec.spell} {KIND} {spec.label_suffix} {arm} {burst} {moment} {read}'


def power_steps(class_file: dict, records: Records, spell: int) -> list[dict]:
    facts = facts_of(records, spell)
    steps = base_mana_steps(class_file, facts)
    if not steps and facts.mana_cost > 0:
        steps = [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
    return steps + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}]


def trigger_steps(class_file: dict, records: Records, spec: StrikeMissShareSpec) -> list[dict]:
    return power_steps(class_file, records, spec.trigger_spell) + [
        {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': CASTER},
        {'action': 'wait', 'label': f'{KIND} trigger', 'ms': spec.trigger_wait_ms}]


def strike_reads(spec: StrikeMissShareSpec, arm: str, burst: int, moment: str) -> list[dict]:
    return [measurement(read_label(spec, arm, burst, moment, 'go'), CASTER, 'spell_go_count',
                        spell=spec.strike_spell, caster=STRIKER),
            measurement(read_label(spec, arm, burst, moment, 'logs'), CASTER, 'spell_log_count',
                        spell=spec.strike_spell, caster=STRIKER, target=CASTER)]


def burst_steps(class_file: dict, records: Records, spec: StrikeMissShareSpec, arm: str, burst: int) -> list[dict]:
    steps = [{'action': 'set_health', 'actor': CASTER, 'value': CASTER_HEALTH, 'maximum': CASTER_HEALTH}]
    if arm == TREATMENT:
        steps += trigger_steps(class_file, records, spec)
    steps += strike_reads(spec, arm, burst, 'before')
    for _ in range(spec.strikes):
        steps += [{'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                  {'action': 'wait', 'label': f'{KIND} strike', 'ms': spec.strike_wait_ms}]
    steps += [{'action': 'wait', 'label': f'{KIND} settle', 'ms': SETTLE_MS}] + strike_reads(spec, arm, burst, 'after')
    steps.append(measurement(read_label(spec, arm, burst, 'after', 'aura'), CASTER, 'aura', spell=spec.trigger_aura))
    rest = spec.burst_ms - SETTLE_MS - spec.strikes * spec.strike_wait_ms
    if arm == TREATMENT:
        rest -= spec.trigger_wait_ms
    return steps + [{'action': 'wait', 'label': f'{KIND} burst end', 'ms': rest}]


def refused_steps(class_file: dict, records: Records, spec: StrikeMissShareSpec, arm: str) -> list[dict]:
    refused = spec.refused
    steps = trigger_steps(class_file, records, spec) if arm == TREATMENT else []
    steps += [measurement(read_label(spec, arm, 'refused', 'before', 'go'), CASTER, 'spell_go_count',
                          spell=refused.spell, caster=CASTER)]
    steps += power_steps(class_file, records, refused.spell)
    steps += [{'action': 'cast', 'actor': CASTER, 'spell': refused.spell, 'target': STRIKER},
              {'action': 'wait', 'label': f'{KIND} refused cast', 'ms': SETTLE_MS},
              measurement(read_label(spec, arm, 'refused', 'after', 'go'), CASTER, 'spell_go_count',
                          spell=refused.spell, caster=CASTER),
              measurement(read_label(spec, arm, 'refused', 'after', 'failure'), CASTER, 'cast_failure',
                          spell=refused.spell),
              measurement(read_label(spec, arm, 'refused', 'before', 'swings'), CASTER, 'melee_attack_count'),
              {'action': 'attack', 'actor': CASTER, 'target': STRIKER},
              {'action': 'wait', 'label': f'{KIND} attack', 'ms': refused.attack_ms},
              {'action': 'stop_attack', 'actor': CASTER},
              measurement(read_label(spec, arm, 'refused', 'after', 'swings'), CASTER, 'melee_attack_count'),
              measurement(read_label(spec, arm, 'refused', 'after', 'aura'), CASTER, 'aura',
                          spell=spec.trigger_aura)]
    used = SETTLE_MS + refused.attack_ms + (spec.trigger_wait_ms if arm == TREATMENT else 0)
    return steps + [{'action': 'wait', 'label': f'{KIND} refused end', 'ms': spec.burst_ms - used}]


def bursts_model(spec: StrikeMissShareSpec, arm: str, count: int) -> list[dict]:
    return [{moment: {read: read_label(spec, arm, burst, moment, read) for read in ('go', 'logs')}
             for moment in ('before', 'after')} | {'aura': read_label(spec, arm, burst, 'after', 'aura')}
            for burst in range(1, count + 1)]


def refused_model(spec: StrikeMissShareSpec, arm: str) -> dict:
    return {read: read_label(spec, arm, 'refused', moment, read)
            for moment, read in (('after', 'failure'), ('after', 'aura'))} | {
        'go': [read_label(spec, arm, 'refused', moment, 'go') for moment in ('before', 'after')],
        'swings': [read_label(spec, arm, 'refused', moment, 'swings') for moment in ('before', 'after')]}


def strike_miss_share_scenario(class_file: dict, spec: StrikeMissShareSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 0.0)
    learned = [spec.trigger_spell, *([spec.refused.spell] if spec.refused else [])]
    steps = base_steps(class_file) + [{'action': 'learn', 'actor': CASTER, 'spell': spell} for spell in learned]
    for arm, count in ((CONTROL, spec.control_bursts), (TREATMENT, spec.treatment_bursts)):
        if spec.refused:
            steps += refused_steps(class_file, records, spec, arm)
        for burst in range(1, count + 1):
            steps += burst_steps(class_file, records, spec, arm, burst)
    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} takes {len(steps)} steps, above {MAX_SCENARIO_STEPS}')
    refused = (f' Before the bursts of each arm the caster attempts {spec.refused.spell} at the striker and attacks '
               f'it for {spec.refused.attack_ms} ms (the treatment right after its own {spec.trigger_spell} cast): '
               f'allowed and swinging in the control, refused with {spec.refused.result} and no swing in the '
               f'treatment.' if spec.refused else '')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour strike miss share',
        'contract': (f'A passive striker (creature {STRIKER_ENTRY}, {STRIKER_DISTANCE:g} yd, no hit bonus) casts '
                     f'{spec.strike_spell} at the caster {spec.strikes} times per burst, {spec.strike_wait_ms} ms '
                     f'apart; {spec.control_bursts} control bursts without {spec.trigger_spell} must land at least '
                     f'{spec.control_minimum_share:g} of their sent strikes, then {spec.treatment_bursts} treatment '
                     f'bursts, each right after a real {spec.trigger_spell} cast at the caster with '
                     f'{spec.trigger_aura} read on it after the burst, must land none. Each strike is counted '
                     f'sent by the striker\'s SPELL_GO and landed by its damage log at the caster.{refused}'),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [{'id': STRIKER, 'owner': CASTER, 'entry': STRIKER_ENTRY, 'level': class_file['level'],
                       'health': STRIKER_HEALTH, 'distance': STRIKER_DISTANCE, 'stationary': True,
                       'reaction': PASSIVE}],
        'steps': steps}
    model = {'kind': KIND, 'metric': 'spell_log_count', 'quote': entry.quote, 'strikes': spec.strikes,
             'minimum_share': spec.control_minimum_share,
             'bursts': {CONTROL: bursts_model(spec, CONTROL, spec.control_bursts),
                        TREATMENT: bursts_model(spec, TREATMENT, spec.treatment_bursts)}}
    expectations = [Expectation(check_label(spec), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.strike_spell, None, '0',
                                prose_rule(entry.quote, spec.spell), model)]
    if spec.refused:
        arms = {CONTROL: refused_model(spec, CONTROL), TREATMENT: refused_model(spec, TREATMENT)}
        common = {'kind': KIND, 'quote': entry.quote, 'arms': arms, 'result': spec.refused.result}
        expectations += [
            Expectation(check_label(spec, '_cast'), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.refused.spell, None,
                        str(spec.refused.result), prose_rule(entry.quote, spec.spell),
                        {**common, 'metric': 'cast_failure', 'mode': 'cast'}),
            Expectation(check_label(spec, '_attack'), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.refused.spell, None, '0',
                        prose_rule(entry.quote, spec.spell),
                        {**common, 'metric': 'melee_attack_count', 'mode': 'attack'})]
    return timed(scenario, waited_ms(steps), MAX_ACCELERATED_SCENARIO_MS), expectations


def missing(run, labels: list[str]) -> str | None:
    from compare import missing_measurement
    found = next((name for name in labels if run.values.get(name) is None), None)
    return None if found is None else missing_measurement(run, found)


def burst_counts(run, model: dict, arm: str) -> tuple[list[tuple[int, int, bool]], str | None]:
    bursts = model['bursts'][arm]
    labels = [name for burst in bursts for moment in ('before', 'after') for name in burst[moment].values()]
    labels += [burst['aura'] for burst in bursts]
    absent = missing(run, labels)
    if absent:
        return [], absent
    return [(int(round(run.values[burst['after']['go']] - run.values[burst['before']['go']])),
             int(round(run.values[burst['after']['logs']] - run.values[burst['before']['logs']])),
             run.values[burst['aura']] > 0) for burst in bursts], None


def share_verdict(base, run, model: dict):
    counts = {}
    for arm in (CONTROL, TREATMENT):
        found, absent = burst_counts(run, model, arm)
        if absent:
            return replace(base, explanation=absent)
        counts[arm] = found
    strikes = model['strikes']
    unsent = [arm for arm, found in counts.items() if any(sent != strikes for sent, _, _ in found)]
    if unsent:
        return replace(base, status='unmeasured',
                       explanation=f'a burst of {unsent} sent another number of strikes than {strikes} (SPELL_GO)')
    sent = {arm: sum(go for go, _, _ in found) for arm, found in counts.items()}
    landed = {arm: sum(logs for _, logs, _ in found) for arm, found in counts.items()}
    control_share = landed[CONTROL] / sent[CONTROL]
    if control_share < model['minimum_share']:
        return replace(base, status='unmeasured', measured=control_share,
                       explanation=f'the control landed {landed[CONTROL]} of {sent[CONTROL]} strikes, below the '
                                   f'{model["minimum_share"]:g} share that shows the strike reaches the caster')
    if any(not held for _, _, held in counts[TREATMENT]):
        return replace(base, status='unmeasured',
                       explanation='the trigger aura was gone after a treatment burst: its strikes were not covered')
    if any(held for _, _, held in counts[CONTROL]):
        return replace(base, status='unmeasured', explanation='the trigger aura was on the caster in a control burst')
    share = landed[TREATMENT] / sent[TREATMENT]
    return replace(base, status='ok' if landed[TREATMENT] == 0 else 'alert', measured=share, expected=0.0, low=0.0,
                   high=0.0,
                   explanation=f'control {landed[CONTROL]} of {sent[CONTROL]} strikes landed; treatment '
                               f'{landed[TREATMENT]} of {sent[TREATMENT]} landed with the trigger aura on the caster '
                               f'after every burst; none may land; a count is compared exactly')


def refused_reads(run, arm: dict) -> tuple[dict, str | None]:
    labels = [arm['failure'], arm['aura'], *arm['go'], *arm['swings']]
    absent = missing(run, labels)
    if absent:
        return {}, absent
    return {'failure': int(run.values[arm['failure']]), 'aura': run.values[arm['aura']] > 0,
            'go': int(round(run.values[arm['go'][1]] - run.values[arm['go'][0]])),
            'swings': int(round(run.values[arm['swings'][1]] - run.values[arm['swings'][0]]))}, None


def refused_verdict(base, run, model: dict):
    reads = {}
    for arm in (CONTROL, TREATMENT):
        found, absent = refused_reads(run, model['arms'][arm])
        if absent:
            return replace(base, explanation=absent)
        reads[arm] = found
    control, treatment = reads[CONTROL], reads[TREATMENT]
    if model['mode'] == 'cast':
        if control['go'] < 1 or control['failure']:
            return replace(base, status='unmeasured',
                           explanation=f'the control cast did not go through (SPELL_GO {control["go"]}, failure '
                                       f'{control["failure"]})')
        if not treatment['aura']:
            return replace(base, status='unmeasured', explanation='the trigger aura was gone at the treatment read')
        ok = treatment['go'] == 0 and treatment['failure'] == model['result']
        return replace(base, status='ok' if ok else 'alert', measured=float(treatment['failure']),
                       expected=float(model['result']), low=float(model['result']), high=float(model['result']),
                       explanation=f'control cast allowed (SPELL_GO {control["go"]}); treatment SPELL_GO '
                                   f'{treatment["go"]} and failure {treatment["failure"]} against {model["result"]}')
    if control['swings'] < 1:
        return replace(base, status='unmeasured', explanation='the control attack made no swing')
    if not treatment['aura']:
        return replace(base, status='unmeasured', explanation='the trigger aura was gone at the treatment read')
    return replace(base, status='ok' if treatment['swings'] == 0 else 'alert', measured=float(treatment['swings']),
                   expected=0.0, low=0.0, high=0.0,
                   explanation=f'control {control["swings"]} swings, treatment {treatment["swings"]} with the '
                               f'trigger aura on; a count is compared exactly')


def strike_miss_share_verdict(base, run, model: dict):
    return share_verdict(base, run, model) if 'bursts' in model else refused_verdict(base, run, model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return strike_miss_share_scenario(class_file, strike_miss_share_spec(entry))


def label(entry: dict) -> list[str]:
    base = f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry['label_suffix']}"
    return [base] + ([f'{base}_cast', f'{base}_attack'] if entry.get('refused') else [])


JUDGES = {BEHAVIOUR_METRIC_DELTA: strike_miss_share_verdict}
