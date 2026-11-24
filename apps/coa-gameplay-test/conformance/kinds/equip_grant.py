from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from hits import timed
from profile import (CASTER, DBC_DIR, EQUIPMENT_SLOT_MAIN_HAND, EQUIPMENT_SLOT_OFF_HAND, base_steps, measurement,
                     player_fixture, skill_target)
from tooltip import Records
from values import Expectation, dataset

KIND = 'equip_grant'
ORDER = 49

EQUIP_GRANT_METRIC = 'equip_grant_accepted'
ARMS = ('unlearned', 'learned')
PAIR_KEYS = {'main_hand', 'off_hand', 'skill_line', 'source'}


@dataclass(frozen=True)
class EquipPair:
    main_hand: int
    off_hand: int
    skill_line: int
    source: str


@dataclass(frozen=True)
class EquipGrantSpec:
    spell: int
    name: str
    quote: str
    pairs: tuple[EquipPair, ...]
    label_suffix: str = 'equip'


def equip_pair(raw) -> EquipPair:
    if not isinstance(raw, dict) or set(raw) != PAIR_KEYS \
            or not all(type(raw[key]) is int and raw[key] > 0 for key in ('main_hand', 'off_hand', 'skill_line')) \
            or not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError(f'an equip_grant pair is {{main_hand, off_hand, skill_line: positive ids, source: text}}, '
                         f'not {raw!r}')
    return EquipPair(raw['main_hand'], raw['off_hand'], raw['skill_line'], raw['source'])


def equip_grant_spec(entry: dict) -> EquipGrantSpec:
    pairs = entry.get('pairs')
    if not isinstance(pairs, list) or not pairs:
        raise ValueError(f'{entry["spell"]} equip_grant needs a non-empty list of pairs')
    return EquipGrantSpec(int(entry['spell']), entry['name'], entry['quote'],
                          tuple(equip_pair(pair) for pair in pairs), entry.get('label_suffix', 'equip'))


def pair_label(spec: EquipGrantSpec, arm: str, index: int, slot: int) -> str:
    return f'{spec.spell} {spec.label_suffix} {arm} pair {index} slot {slot}'


def pair_steps(spec: EquipGrantSpec, arm: str, index: int, pair: EquipPair) -> list[dict]:
    learned = arm == 'learned'
    grants = [] if learned else [{'action': 'add_item', 'actor': CASTER, 'item': item}
                                 for item in (pair.main_hand, pair.off_hand)]
    steps = grants[:1] + [
        {'action': 'equip', 'actor': CASTER, 'item': pair.main_hand, 'slot': EQUIPMENT_SLOT_MAIN_HAND}] + grants[1:] + [
        {'action': 'equip', 'actor': CASTER, 'item': pair.off_hand, 'slot': EQUIPMENT_SLOT_OFF_HAND,
         **({} if learned else {'rejected': True})}]
    return steps + [measurement(pair_label(spec, arm, index, slot), CASTER, 'equipped_item', slot=slot)
                    for slot in (EQUIPMENT_SLOT_MAIN_HAND, EQUIPMENT_SLOT_OFF_HAND)]


def equip_grant_scenario(class_file: dict, spec: EquipGrantSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    skills = dict.fromkeys(pair.skill_line for pair in spec.pairs)
    steps = base_steps(class_file) + [
        {'action': 'set_skill', 'actor': CASTER, 'skill': line, 'value': skill_target(class_file),
         'maximum': skill_target(class_file)} for line in skills]
    steps.append({'action': 'unlearn', 'actor': CASTER, 'spell': spec.spell})
    for arm in ARMS:
        if arm == 'learned':
            steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.spell})
        for index, pair in enumerate(spec.pairs):
            steps += pair_steps(spec, arm, index, pair)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour equip grant',
        'contract': (f'{spec.spell} is unlearned, then for each pair both items are added, the main hand is '
                     f'equipped and the off hand equip must be refused (the harness fails the step when it is '
                     f'accepted); {spec.spell} is then learned and every pair is equipped again from the bags, the off '
                     f'hand equip now accepted. Pairs: '
                     + '; '.join(f'{pair.main_hand} with {pair.off_hand} (skill line {pair.skill_line}, '
                                 f'{pair.source})' for pair in spec.pairs)
                     + '. Each arm reads both hands with equipped_item: the off hand does not hold its item without '
                       'the grant and holds it with the grant, the main hand holds its item in both.'),
        'players': [player_fixture(class_file)],
        'creatures': [],
        'steps': steps}
    model = {'kind': KIND, 'metric': EQUIP_GRANT_METRIC, 'quote': entry.quote,
             'pairs': [{'main_hand': pair.main_hand, 'off_hand': pair.off_hand,
                        'reads': {arm: [pair_label(spec, arm, index, slot)
                                        for slot in (EQUIPMENT_SLOT_MAIN_HAND, EQUIPMENT_SLOT_OFF_HAND)]
                                  for arm in ARMS}}
                       for index, pair in enumerate(spec.pairs)]}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.spell, None, '1', prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def equip_grant_verdict(base, run, model: dict):
    from compare import missing_measurement
    labels = [label for pair in model['pairs'] for reads in pair['reads'].values() for label in reads]
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    texts, held = [], []
    for pair in model['pairs']:
        main, off = pair['main_hand'], pair['off_hand']
        unlearned = [run.values[label] for label in pair['reads']['unlearned']]
        learned = [run.values[label] for label in pair['reads']['learned']]
        good = unlearned[0] == main and unlearned[1] != off and learned == [main, off]
        held.append(good)
        texts.append(f'{main} with {off}: without the grant main {unlearned[0]:g} off {unlearned[1]:g}, with it main '
                     f'{learned[0]:g} off {learned[1]:g} ({"ok" if good else "off"})')
    accepted = sum(held)
    return replace(base, status='ok' if all(held) else 'alert', measured=float(accepted),
                   expected=float(len(held)), low=float(len(held)), high=float(len(held)),
                   explanation=f'{accepted} of {len(held)} pairs refused the off hand without the grant and '
                               f'held both items with it: ' + '; '.join(texts))


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return equip_grant_scenario(class_file, equip_grant_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'equip')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: equip_grant_verdict}
METRIC_EVIDENCE = {EQUIP_GRANT_METRIC: 'event'}
