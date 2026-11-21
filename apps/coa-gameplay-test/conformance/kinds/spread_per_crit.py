from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, dummy_fixture, dummy_id, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import (CAST_MARGIN_MS, FORCE_CRIT_RATINGS, FORCED_CRIT_RATING, GCD_WAIT_MS, Expectation, cast_distance,
                    dataset, facts_of, required_aura_steps)

KIND = 'spread_per_crit'
ORDER = 30
ARMS = ('control', 'treatment')
SPARE_EDGE_YD = 0.5


@dataclass(frozen=True)
class SpreadPerCritSpec:
    spell: int
    name: str
    quote: str
    seed_spell: int
    aura_spell: int
    target_rank: int
    hit_spells: tuple[int, ...]
    spares: int
    radius: float
    force_crit: str
    label_suffix: str = 'spread_per_crit'


def spread_per_crit_spec(entry: dict) -> SpreadPerCritSpec:
    spec = SpreadPerCritSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['seed_spell']),
                             int(entry['aura_spell']), int(entry['target_rank']),
                             tuple(int(spell) for spell in entry['hit_spells']), int(entry['spares']),
                             float(entry['radius']), entry['force_crit'],
                             entry.get('label_suffix', 'spread_per_crit'))
    if spec.force_crit not in FORCE_CRIT_RATINGS or spec.spares < 2 or spec.radius <= SPARE_EDGE_YD \
            or not spec.hit_spells:
        raise ValueError(f'{spec.spell} {KIND} needs a force_crit of {sorted(FORCE_CRIT_RATINGS)}, at least two '
                         f'spare dummies, a radius and the spells whose crits are counted')
    return spec


def mark(spec: SpreadPerCritSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def spread_per_crit_scenario(class_file: dict, spec: SpreadPerCritSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    primary = cast_distance(records, spec.target_rank)
    step = (spec.radius - SPARE_EDGE_YD) / spec.spares
    creatures = [dummy_fixture(0, class_file, primary)] + [
        dummy_fixture(index, class_file, primary + step * index) for index in range(1, spec.spares + 1)]
    seed, hit = facts_of(records, spec.seed_spell), facts_of(records, spec.target_rank)
    wait_ms = int(records.duration_ms(spec.target_rank)) + hit.cast_time_ms + CAST_MARGIN_MS

    def cast(facts, spell: int) -> list[dict]:
        power = ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': facts.mana_cost}]
                 if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level else [])
        return power + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell}] + required_aura_steps(facts) + [
            {'action': 'cast', 'actor': CASTER, 'spell': spell, 'target': dummy_id(0)}]

    def reads(arm: str, moment: str) -> list[dict]:
        crits = [measurement(mark(spec, f'{arm} {moment} crits {spell}'), CASTER, 'spell_damage_count', spell=spell,
                             target=dummy_id(0), critical=True) for spell in spec.hit_spells]
        spares = [measurement(mark(spec, f'{arm} {moment} {dummy_id(index)}'), dummy_id(index), 'aura',
                              spell=spec.aura_spell, caster=CASTER) for index in range(1, spec.spares + 1)]
        return crits + spares

    def arm(name: str, gate: list[dict]) -> list[dict]:
        return (cast(seed, spec.seed_spell)
                + [{'action': 'wait', 'label': f'{name} seed and global cooldown',
                    'ms': seed.cast_time_ms + CAST_MARGIN_MS + GCD_WAIT_MS}]
                + gate + reads(name, 'start') + cast(hit, spec.target_rank)
                + [{'action': 'wait', 'label': f'{name} hits', 'ms': wait_ms}] + reads(name, 'end'))

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.seed_spell, spec.target_rank))]
             + arm(ARMS[0], [])
             + arm(ARMS[1], [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]))
    rating = FORCE_CRIT_RATINGS[spec.force_crit]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour spread per crit',
        'contract': (f'Each arm seeds {spec.seed_spell} on the primary dummy, then casts {spec.target_rank} at it with '
                     f'the {rating} fixture at {FORCED_CRIT_RATING}; {spec.spell} is learned after the treatment '
                     f'seed, so the seed\'s own crit spreads nothing. The critical hits of {list(spec.hit_spells)} on '
                     f'the primary and the {spec.aura_spell} of the caster on {spec.spares} spare dummies within '
                     f'{spec.radius:g} yd of it are read before and after the cast: no copy in the control, and '
                     f'exactly one new copy per critical hit with {spec.spell} while a spare stays free.'),
        'players': [{**player_fixture(class_file), rating: FORCED_CRIT_RATING}],
        'creatures': creatures,
        'steps': steps}
    model = {'kind': KIND, 'metric': 'spell_damage_count', 'quote': entry.quote, 'expected': 1.0,
             'reads': {name: {moment: {'crits': [mark(spec, f'{name} {moment} crits {spell}')
                                                 for spell in spec.hit_spells],
                                       'spares': [mark(spec, f'{name} {moment} {dummy_id(index)}')
                                                  for index in range(1, spec.spares + 1)]}
                              for moment in ('start', 'end')} for name in ARMS}}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.target_rank, None,
                              '1', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def spread_per_crit_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    totals = {}
    for name, moments in model['reads'].items():
        for moment, groups in moments.items():
            for group, labels in groups.items():
                values = [run.values.get(label) for label in labels]
                missing = next((label for label, value in zip(labels, values) if value is None), None)
                if missing is not None:
                    return replace(base, explanation=missing_measurement(run, missing))
                totals[name, moment, group] = sum(values)

    def gained(name: str, group: str) -> float:
        return totals[name, 'end', group] - totals[name, 'start', group]

    spares = len(model['reads']['control']['end']['spares'])
    control_crits, control_copies = gained('control', 'crits'), totals['control', 'end', 'spares']
    crits, copies = gained('treatment', 'crits'), gained('treatment', 'spares')
    held = totals['treatment', 'start', 'spares']
    reads = (f'control: {control_crits:g} crits, {control_copies:g} copies; treatment: {crits:g} crits, '
             f'{copies:g} new copies ({held:g} spares held one at the start)')
    if control_crits < 1:
        return replace(base, status='unmeasured', explanation=f'no critical hit in the control, so it shows nothing: '
                                                              f'{reads}')
    if control_copies:
        return replace(base, status='alert', explanation=f'copies without the talent: {reads}')
    if crits < 1 or held + crits >= spares:
        return replace(base, status='unmeasured', explanation=f'the treatment needs a critical hit and a spare left '
                                                              f'free after one copy per crit: {reads}')
    ratio = copies / crits
    return replace(base, status='ok' if copies == crits else 'alert', measured=ratio, expected=1.0, low=1.0, high=1.0,
                   detail={'crits': crits, 'copies': copies},
                   explanation=f'{ratio:g} copies per critical hit against exactly 1: {reads}')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return spread_per_crit_scenario(class_file, spread_per_crit_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'spread_per_crit')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: spread_per_crit_verdict}
