from dataclasses import dataclass
from pathlib import Path

from behaviours import (BEHAVIOUR_CAST_CONDITION, CAST_COMBAT_SETTLE_MS, COST_GATE_MARGIN_MS, NO_CAST_FAILURE,
                        SPELL_FAILED_NOT_READY, behaviour_entry, hit_ratio_cast, prose_rule, waited_ms)
from hits import TIMEOUT_MARGIN_MS, creature_fixture
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, Expectation, GCD_WAIT_MS, TARGET, dataset

KIND = 'item_cooldown_gate'
ORDER = 4


GATE_USE = ('cast_failure', 'spell_go_count')
ITEM_COOLDOWN_GATE_LABEL_ARMS = {
    'plain': (('first', GATE_USE), ('early', GATE_USE), ('ready', GATE_USE)),
    'shared': (('first', GATE_USE), ('early', GATE_USE), ('ready', GATE_USE), ('shared', ('cast_failure',))),
    'combat': (('combat_start', ('combat',)), ('first', GATE_USE), ('in_combat', ('cast_failure',)),
               ('combat_end', ('combat',)), ('after_combat', ('cast_failure',)),
               ('after_combat_early', ('cast_failure',)), ('after_combat_ready', ('cast_failure',))),
}


@dataclass(frozen=True)
class ItemCooldownGateSpec:
    spell: int
    name: str
    quote: str
    item: int
    item_spell: int
    cooldown_ms: int
    shared_item: int | None = None
    shared_spell: int | None = None
    margin_ms: int = COST_GATE_MARGIN_MS
    read_ms: int = 500
    label_suffix: str = ''
    combat_kill_spell: int | None = None


ITEM_COOLDOWN_GATE_ARMS = ('first', 'early', 'ready')


def item_cooldown_gate_label(spec: ItemCooldownGateSpec, arm: str, metric: str) -> str:
    suffix = f' {spec.label_suffix}' if spec.label_suffix else ''
    return f'{spec.spell} item_cooldown_gate {spec.item}{suffix} {arm} {metric}'


def item_cooldown_gate_spec(entry: dict) -> ItemCooldownGateSpec:
    spec = ItemCooldownGateSpec(entry['spell'], entry['name'], entry['quote'], entry['item'], entry['item_spell'],
                                int(entry['cooldown_ms']), entry.get('shared_item'), entry.get('shared_spell'),
                                int(entry.get('margin_ms', COST_GATE_MARGIN_MS)), 500, entry.get('label_suffix', ''),
                                entry.get('combat_kill_spell'))
    if (spec.shared_item is None) != (spec.shared_spell is None):
        raise ValueError(f'{spec.spell} item_cooldown_gate names a shared item and its spell together')
    if spec.combat_kill_spell is not None and (spec.shared_item is None or not spec.label_suffix):
        raise ValueError(f'{spec.spell} item_cooldown_gate in combat needs a shared item and a label_suffix')
    if not spec.read_ms < spec.cooldown_ms - spec.margin_ms - spec.read_ms:
        raise ValueError(f'{spec.spell} item_cooldown_gate cooldown {spec.cooldown_ms} ms leaves no early attempt')
    return spec


def item_cooldown_gate_scenario(class_file: dict, spec: ItemCooldownGateSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'item_cooldown_gate', spec.quote, float(spec.cooldown_ms))
    rule = prose_rule(entry.quote, spec.spell)
    model = {'kind': 'item_cooldown_gate', 'quote': entry.quote, 'cooldown_ms': spec.cooldown_ms}
    steps = base_steps(class_file) + [{'action': 'group', 'actor': CASTER, 'target': ALLY},
                                      {'action': 'add_item', 'actor': ALLY, 'item': spec.item, 'count': 3}]
    if spec.shared_item is not None:
        steps.append({'action': 'add_item', 'actor': ALLY, 'item': spec.shared_item})
    expectations = []

    def attempt(arm: str, item: int, spell: int, refused: bool, completed: int | None) -> list[dict]:
        failure = item_cooldown_gate_label(spec, arm, 'cast_failure')
        expectations.append(Expectation(failure, BEHAVIOUR_CAST_CONDITION, spec.spell, spell, None,
                                        str(SPELL_FAILED_NOT_READY if refused else NO_CAST_FAILURE), rule,
                                        {**model, 'arm': arm, 'item': item}))
        reads = [measurement(failure, ALLY, 'cast_failure', spell=spell)]
        if completed is not None:
            casts = item_cooldown_gate_label(spec, arm, 'spell_go_count')
            expectations.append(Expectation(casts, BEHAVIOUR_CAST_CONDITION, spec.spell, spell, None, str(completed),
                                            rule, {**model, 'arm': arm, 'item': item}))
            reads.append(measurement(casts, ALLY, 'spell_go_count', spell=spell))
        return ([{'action': 'use_item', 'actor': ALLY, 'item': item, 'spell': spell},
                 {'action': 'wait', 'label': f'{arm} read', 'ms': spec.read_ms}] + reads)

    early_ms = spec.cooldown_ms - spec.margin_ms
    if spec.combat_kill_spell is not None:
        return item_cooldown_gate_combat(class_file, records, spec, steps, attempt, expectations, rule, model)
    steps += attempt('first', spec.item, spec.item_spell, False, 1)
    steps += [{'action': 'wait', 'label': 'until just before the cooldown ends', 'ms': early_ms - spec.read_ms}]
    steps += attempt('early', spec.item, spec.item_spell, True, 1)
    steps += [{'action': 'wait', 'label': 'until just after the cooldown ends',
               'ms': 2 * spec.margin_ms - spec.read_ms}]
    steps += attempt('ready', spec.item, spec.item_spell, False, 2)
    if spec.shared_item is not None:
        steps += attempt('shared', spec.shared_item, spec.shared_spell, True, None)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour item cooldown gate',
        'contract': f'A grouped ally uses item {spec.item} (its spell {spec.item_spell}) through the real item-use '
                    f'handler: accepted first, refused {early_ms} ms later, accepted again '
                    f'{spec.cooldown_ms + spec.margin_ms} ms after the first use'
                    + (f', and item {spec.shared_item} (spell {spec.shared_spell}) refused right after it'
                       if spec.shared_item is not None else '')
                    + f', proving the "{spec.quote}" clause.',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY}],
        'steps': steps}
    return scenario, expectations


def item_cooldown_gate_combat(class_file: dict, records: Records, spec: ItemCooldownGateSpec, steps: list[dict],
                              attempt, expectations: list[Expectation], rule: str,
                              model: dict) -> tuple[dict, list[Expectation]]:
    def combat(moment: str, expected: int) -> dict:
        label = item_cooldown_gate_label(spec, moment, 'combat')
        expectations.append(Expectation(label, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.item_spell, None,
                                        str(expected), rule, {**model, 'arm': moment, 'item': spec.item}))
        return measurement(label, ALLY, 'combat')

    early_ms = spec.cooldown_ms - spec.margin_ms
    steps += [{'action': 'attack', 'actor': ALLY, 'target': TARGET},
              {'action': 'wait', 'label': 'enter combat', 'ms': CAST_COMBAT_SETTLE_MS}, combat('combat_start', 1)]
    steps += attempt('first', spec.item, spec.item_spell, False, 1)
    steps += [{'action': 'wait', 'label': 'past the cooldown, still in combat',
               'ms': spec.cooldown_ms + spec.margin_ms - spec.read_ms}]
    steps += attempt('in_combat', spec.shared_item, spec.shared_spell, True, None)
    steps += [{'action': 'stop_attack', 'actor': ALLY},
              {'action': 'set_health', 'actor': TARGET, 'value': 1},
              {'action': 'learn', 'actor': CASTER, 'spell': spec.combat_kill_spell}]
    steps += hit_ratio_cast(records, spec.combat_kill_spell)
    steps += [combat('combat_end', 0)]
    steps += attempt('after_combat', spec.shared_item, spec.shared_spell, True, None)
    steps += [{'action': 'wait', 'label': 'until just before the cooldown from the combat end ends',
               'ms': early_ms - GCD_WAIT_MS - 2 * spec.read_ms}]
    steps += attempt('after_combat_early', spec.shared_item, spec.shared_spell, True, None)
    steps += [{'action': 'wait', 'label': 'until just after the cooldown from the combat end ends',
               'ms': 2 * spec.margin_ms - spec.read_ms + GCD_WAIT_MS}]
    steps += attempt('after_combat_ready', spec.shared_item, spec.shared_spell, False, None)
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour item cooldown gate in combat',
        'contract': f'A grouped ally attacks the dummy (in combat) and uses item {spec.item} (its spell '
                    f'{spec.item_spell}) through the real item-use handler: accepted; {spec.cooldown_ms + spec.margin_ms}'
                    f' ms later, still in combat, item {spec.shared_item} (spell {spec.shared_spell}) is refused; '
                    f'then the caster kills the dummy with {spec.combat_kill_spell} (the dummy set to 1 health), the '
                    f'ally leaves combat and item {spec.shared_item} is refused right after, refused {early_ms} ms '
                    f'later and accepted {spec.cooldown_ms + spec.margin_ms} ms after the combat ended, proving the '
                    f'"{spec.quote}" clause under the shared potion rule.',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY}],
        'creatures': [creature_fixture(class_file)],
        'steps': steps,
        'timeout_ms': waited_ms(steps) + TIMEOUT_MARGIN_MS}
    return scenario, expectations


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return item_cooldown_gate_scenario(class_file, item_cooldown_gate_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} item_cooldown_gate {entry['item']}"
            + (f" {entry['label_suffix']}" if entry.get('label_suffix') else '')
            + f" {arm} {metric}"
            for arm, metrics in ITEM_COOLDOWN_GATE_LABEL_ARMS[
                'combat' if entry.get('combat_kill_spell') else
                'shared' if entry.get('shared_item') else 'plain']
            for metric in metrics]
