from dataclasses import dataclass
from pathlib import Path
import re

from hits import creature_fixture
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import COLOR_CODE, Records
from values import CAST_MARGIN_MS, Expectation, dataset, facts_of, required_aura_steps

BEHAVIOUR_COUNT = 'behaviour_count'
BEHAVIOUR_RATIO = 'behaviour_ratio'
BEHAVIOUR_DURATION = 'behaviour_duration'
BEHAVIOUR_TRIGGER = 'behaviour_trigger'
BEHAVIOUR_CHECKS = (BEHAVIOUR_COUNT, BEHAVIOUR_RATIO, BEHAVIOUR_DURATION, BEHAVIOUR_TRIGGER)
KINDS = ('count', 'ratio', 'duration', 'trigger')
PROSE = 'prose: '
BEFORE = 'before'
AFTER = 'after'
LINE_BREAKS = re.compile(r'\s+')


class NotModelled(Exception):
    pass


@dataclass(frozen=True)
class BehaviourEntry:
    spell: int
    name: str
    tooltip: str
    kind: str
    quote: str
    expected: float


def cleaned_tooltip(records: Records, spell_id: int) -> str:
    return LINE_BREAKS.sub(' ', COLOR_CODE.sub('', records.field('Spell', spell_id, 'Description[enUS]')))


def prose_rule(quote: str, spell_id: int) -> str:
    return f'{PROSE}"{quote}" ({spell_id})'


def behaviour_entry(records: Records, spell_id: int, name: str, kind: str, quote: str, expected: float
                    ) -> BehaviourEntry:
    if kind not in KINDS:
        raise ValueError(f'behaviour kind {kind!r} is not one of {KINDS}')
    tooltip = cleaned_tooltip(records, spell_id)
    if quote not in tooltip:
        raise ValueError(f'{spell_id} tooltip {tooltip!r} does not contain the quote {quote!r}')
    return BehaviourEntry(spell_id, name, tooltip, kind, quote, expected)


HIT_METRICS = frozenset({'spell_damage_count', 'aura'})


@dataclass(frozen=True)
class TargetCountSpec:
    spell: int
    name: str
    quote: str
    expected: int
    target_rank: int
    radius: float
    radius_reason: str
    metric: str = 'spell_damage_count'
    repeats: int = 5


def dummy_id(index: int) -> str:
    return 'primary' if index == 0 else f'extra{index}'


def dummy_fixture(index: int, class_file: dict, distance: float) -> dict:
    fixture = creature_fixture(class_file)
    fixture['id'] = dummy_id(index)
    fixture['distance'] = distance
    return fixture


def hit_label(spell: TargetCountSpec, index: int, moment: str) -> str:
    return f'{spell.spell} {dummy_id(index)} {spell.metric} {moment}'


def hit_measurement(spec: TargetCountSpec, index: int, moment: str) -> dict:
    if spec.metric not in HIT_METRICS:
        raise NotModelled(f'target-count metric {spec.metric!r} is not one of {sorted(HIT_METRICS)}')
    label = hit_label(spec, index, moment)
    if spec.metric == 'spell_damage_count':
        return measurement(label, CASTER, spec.metric, spell=spec.target_rank, target=dummy_id(index))
    return measurement(label, dummy_id(index), spec.metric, spell=spec.target_rank, caster=CASTER)


def target_count_scenario(class_file: dict, spec: TargetCountSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'count', spec.quote, spec.expected)
    dummy_count = spec.expected + 1
    primary_distance = 3.0
    distances = [primary_distance] + [
        primary_distance + spec.radius * (index / dummy_count) for index in range(1, dummy_count)]
    creatures = [dummy_fixture(index, class_file, distances[index]) for index in range(dummy_count)]

    facts = facts_of(records, spec.target_rank)
    wait_ms = facts.cast_time_ms + CAST_MARGIN_MS

    def cast_steps() -> list[dict]:
        steps = []
        for _ in range(spec.repeats):
            if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.target_rank})
            steps += required_aura_steps(facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.target_rank, 'target': dummy_id(0)})
            steps.append({'action': 'wait', 'ms': wait_ms})
        return steps

    def measure(moment: str) -> list[dict]:
        return [hit_measurement(spec, index, moment) for index in range(dummy_count)]

    before_labels = [hit_label(spec, index, BEFORE) for index in range(1, dummy_count)]
    after_labels = [hit_label(spec, index, AFTER) for index in range(1, dummy_count)]
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour count',
        'contract': f'{spec.repeats} casts per phase, "ever hit at least once" per dummy rather than a single-'
                    f'cast snapshot: {spec.radius_reason}',
        'players': [player_fixture(class_file)],
        'creatures': creatures,
        'steps': base_steps(class_file) + cast_steps() + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + cast_steps() + measure(AFTER)}
    label = f'{spec.spell} behaviour_count'
    model = {'kind': 'count', 'dummy_labels': list(zip(before_labels, after_labels)), 'expected': spec.expected,
             'quote': entry.quote}
    expectation = Expectation(label, BEHAVIOUR_COUNT, spec.spell, spec.target_rank, None, str(spec.expected),
                              prose_rule(entry.quote, spec.spell), model)
    return scenario, [expectation]


@dataclass(frozen=True)
class HealingRatioSpec:
    spell: int
    name: str
    quote: str
    expected: float
    targets: tuple[tuple[int, str], ...]


def healing_ratio_scenario(class_file: dict, spec: HealingRatioSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'ratio', spec.quote, spec.expected)

    def label(rank_id: int, moment: str) -> str:
        return f'{spec.spell} {rank_id} spell_healing_done {moment}'

    def cast_all() -> list[dict]:
        steps = []
        for rank_id, _ in spec.targets:
            facts = facts_of(records, rank_id)
            if facts.mana_cost > 0 and not facts.mana_cost_percentage and not facts.mana_cost_per_level:
                steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type,
                             'value': facts.mana_cost})
            steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': rank_id})
            steps += required_aura_steps(facts)
            steps.append({'action': 'cast', 'actor': CASTER, 'spell': rank_id, 'target': CASTER})
            steps.append({'action': 'wait', 'ms': facts.cast_time_ms + CAST_MARGIN_MS})
        return steps

    def measure(moment: str) -> list[dict]:
        return [measurement(label(rank_id, moment), CASTER, 'spell_healing_done', spell=rank_id, target=CASTER)
                for rank_id, _ in spec.targets]

    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour ratio',
        'contract': 'No-combat with/without check: healing of the named spells, measured before and after the '
                    'passive is learned.',
        'players': [player_fixture(class_file)],
        'steps': base_steps(class_file) + cast_all() + measure(BEFORE) +
                 [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}] + cast_all() + measure(AFTER)}
    expectations = []
    for rank_id, name in spec.targets:
        model = {'kind': 'ratio', 'before_label': label(rank_id, BEFORE), 'after_label': label(rank_id, AFTER),
                 'expected': spec.expected, 'quote': entry.quote, 'target_name': name}
        expectations.append(Expectation(f'{spec.spell} {rank_id} behaviour_ratio', BEHAVIOUR_RATIO, spec.spell,
                                        rank_id, None, str(spec.expected), prose_rule(entry.quote, spec.spell),
                                        model))
    return scenario, expectations


def target_count_spec(entry: dict) -> TargetCountSpec:
    return TargetCountSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'], entry['target_rank'],
                           entry['radius'], entry['radius_reason'], entry.get('metric', 'spell_damage_count'),
                           entry.get('repeats', 5))


def healing_ratio_spec(entry: dict) -> HealingRatioSpec:
    return HealingRatioSpec(entry['spell'], entry['name'], entry['quote'], entry['expected'],
                            tuple((target, name) for target, name in entry['targets']))


def behaviour_scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    if entry['kind'] == 'count':
        return target_count_scenario(class_file, target_count_spec(entry))
    if entry['kind'] == 'ratio':
        return healing_ratio_scenario(class_file, healing_ratio_spec(entry))
    raise NotModelled(f'behaviour kind {entry["kind"]!r} has no scenario builder')


def behaviour_entries(class_file: dict, spell_ids: list[int] | None) -> list[dict]:
    entries = class_file.get('behaviours', [])
    if spell_ids is None:
        return entries
    chosen = [entry for entry in entries if entry['spell'] in spell_ids]
    unknown = set(spell_ids) - {entry['spell'] for entry in chosen}
    if unknown:
        raise ValueError(f'Spells {sorted(unknown)} are not {class_file["name"]} behaviour entries')
    return chosen
