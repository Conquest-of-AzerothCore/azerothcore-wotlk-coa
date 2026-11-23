import math
from dataclasses import replace

from profile import CASTER, measurement
from values import FORCE_CRIT_RATINGS, FORCED_CRIT_RATING, TARGET

KEY = 'critical_trials'
RATINGS = ('melee', 'spell')
SUPPRESSOR = 34640
SUPPRESSED_EFFECTS = (0, 1)
SUPPRESSED_AMOUNT = -100000
CONTROL_RISK = 0.0005
LANDED_HIT_METRIC = 'spell_damage_count'


def critical_rating(entry: dict) -> str | None:
    raw = entry.get(KEY)
    if raw is None:
        return None
    if not isinstance(raw, dict) or set(raw) != {'rating', 'source'} or raw['rating'] not in RATINGS \
            or not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError(f'Proc {entry["aura"]} {KEY} is {{"rating": {"|".join(RATINGS)}, "source": text}}, '
                         f'not {raw!r}')
    if entry['trigger']['action'] != 'cast' or entry.get('trial_casts') or entry.get('trial_readings') \
            or entry.get('most_procs_per_trigger') is not None or entry.get('event_actor'):
        raise ValueError(f'Proc {entry["aura"]} {KEY} counts the landed hits of a cast trigger on the dummy')
    return raw['rating']


def critical_fields(entry: dict) -> dict:
    return {'critical': True} if critical_rating(entry) else {}


def control_hits(chance_pct: float) -> int:
    chance = min(chance_pct, 100.0) / 100
    return 1 if chance >= 1 else math.ceil(math.log(CONTROL_RISK) / math.log(1 - chance))


def control_labels(aura: int, moment: str = 'end') -> dict[str, str]:
    return {part: f'{aura} proc critical control {moment} {part}' for part in ('events', 'crits', 'hits')}


def control_reads(entry: dict, spells: list[int], events: list[dict], moment: str) -> list[dict]:
    labels = control_labels(entry['aura'], moment)
    return ([{**step, 'label': f'{labels["events"]} {index}'} for index, step in enumerate(events)]
            + landed_hit_reads(labels['crits'], spells, True) + landed_hit_reads(labels['hits'], spells, False))


def suppression_steps() -> list[dict]:
    return ([{'action': 'set_aura', 'actor': CASTER, 'spell': SUPPRESSOR, 'stacks': 0},
             {'action': 'set_aura', 'actor': CASTER, 'spell': SUPPRESSOR, 'stacks': 1}]
            + [{'action': 'set_aura', 'actor': CASTER, 'spell': SUPPRESSOR, 'stacks': 1, 'effect': effect,
                'amount': SUPPRESSED_AMOUNT} for effect in SUPPRESSED_EFFECTS])


def landed_hit_reads(label: str, spells: list[int], critical: bool) -> list[dict]:
    return [measurement(f'{label} {spell}', CASTER, LANDED_HIT_METRIC, spell=spell, target=TARGET, critical=critical)
            for spell in spells]


def control_steps(class_file: dict, entry: dict, plan, spells: list[int], events: list[dict]) -> list[dict]:
    from hits import DRAIN_MS
    from procs import cast_attempts
    single = replace(plan, per_part=1)
    steps = control_reads(entry, spells, events, 'start')
    for _ in range(control_hits(plan.chance_pct)):
        steps += suppression_steps() + cast_attempts(class_file, entry, single)
    steps.append({'action': 'wait', 'label': 'critical control drain', 'ms': DRAIN_MS})
    steps += control_reads(entry, spells, events, 'end')
    return steps + [{'action': 'set_aura', 'actor': CASTER, 'spell': SUPPRESSOR, 'stacks': 0}]


def control_model(entry: dict, plan, spells: list[int], events: list[dict]) -> dict:
    def reads(moment: str) -> dict:
        labels = control_labels(entry['aura'], moment)
        return {'events': [f'{labels["events"]} {index}' for index in range(len(events))],
                'crits': [f'{labels["crits"]} {spell}' for spell in spells],
                'hits': [f'{labels["hits"]} {spell}' for spell in spells]}
    return {'start': reads('start'), 'end': reads('end'), 'minimum_hits': control_hits(plan.chance_pct),
            'source': entry[KEY]['source']}


def forced_player(player: dict, entry: dict) -> dict:
    return {**player, FORCE_CRIT_RATINGS[critical_rating(entry)]: FORCED_CRIT_RATING}


def rule(entry: dict, plan) -> str:
    return (f'; {KEY}: the trials are the critical landed hits only (the {critical_rating(entry)} crit rating fixture '
            f'at {FORCED_CRIT_RATING}), so the rate is the procs per critical hit; a control arm in part 1 with the '
            f'passive learned casts {control_hits(plan.chance_pct)} times under {SUPPRESSOR} (crit chance effects '
            f'{list(SUPPRESSED_EFFECTS)} at {SUPPRESSED_AMOUNT}%) and must read no critical hit (else unmeasured), at '
            f'least {control_hits(plan.chance_pct)} non-critical hits (else unmeasured) and no event (else alert), '
            f'which a crit-blind {plan.chance_pct:g}% roll passes with under {CONTROL_RISK:g} probability '
            f'({entry[KEY]["source"]})')


def control_verdict(verdict, parts: list):
    found = next(((run, expectation.model[KEY]) for _, run, expectation in parts if KEY in expectation.model), None)
    if found is None:
        return verdict
    run, control = found
    def total(labels):
        found = [run.values.get(label) for label in labels]
        return None if any(value is None or not math.isfinite(float(value)) for value in found) else sum(found)

    def delta(part):
        start, end = total(control['start'][part]), total(control['end'][part])
        return None if start is None or end is None else end - start
    events, crits, hits = delta('events'), delta('crits'), delta('hits')
    if events is None or crits is None or hits is None:
        text = 'a critical control reading is missing'
        return replace(verdict, status='alert' if verdict.status == 'alert' else 'unmeasured',
                       explanation=f'{verdict.explanation}; {text}')
    text = (f'critical control: {hits:g} non-critical hits, {crits:g} critical, {events:g} events (at least '
            f'{control["minimum_hits"]} non-critical hits, no critical hit, no event)')
    if events > 0:
        return replace(verdict, status='alert', explanation=f'{verdict.explanation}; {text}: a non-critical hit procs')
    if crits > 0 or hits < control['minimum_hits']:
        status = 'alert' if verdict.status == 'alert' else 'unmeasured'
        return replace(verdict, status=status, explanation=f'{verdict.explanation}; {text}: the control is not met')
    return replace(verdict, explanation=f'{verdict.explanation}; {text}')
