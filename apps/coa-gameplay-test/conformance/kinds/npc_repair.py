from dataclasses import dataclass
from pathlib import Path

from behaviours import (BEHAVIOUR_CAST_CONDITION, ENEMY_PLAYER, ENEMY_PLAYER_SETTLE_MS, TAKEN_HIT_PVP_LOCATION,
                        behaviour_entry, cast_gate_power_step, prose_rule)
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import ALLY, Expectation, dataset, facts_of, required_aura_steps

KIND = 'npc_repair'
ORDER = 1


@dataclass(frozen=True)
class NpcRepairSpec:
    spell: int
    name: str
    quote: str
    entry: int
    item: int
    item_slot: int
    full: int
    loss_percent: float
    summon_wait_ms: int = 1500
    repair_wait_ms: int = 500


NPC_REPAIR_MONEY = 10_000_000
NPC_REPAIR_ARMS = ((CASTER, False), (CASTER, True), (ALLY, True), (ENEMY_PLAYER, True))


def npc_repair_label(spec: NpcRepairSpec, actor: str, summoned: bool, moment: str) -> str:
    return f'{spec.spell} npc_repair {actor} {"with" if summoned else "without"} {spec.entry} {moment}'


def npc_repair_spec(entry: dict) -> NpcRepairSpec:
    return NpcRepairSpec(entry['spell'], entry['name'], entry['quote'], entry['entry'], entry['item'],
                         entry['item_slot'], entry['full'], float(entry['loss_percent']),
                         entry.get('summon_wait_ms', 1500), entry.get('repair_wait_ms', 500))


def npc_repair_scenario(class_file: dict, spec: NpcRepairSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, 'npc_repair', spec.quote, float(spec.full))
    facts = facts_of(records, spec.spell)
    settled = base_steps(class_file)
    steps = list(settled)
    steps += [{'action': 'pvp', 'actor': CASTER, 'enabled': True},
              {'action': 'pvp', 'actor': ENEMY_PLAYER, 'enabled': True},
              {'action': 'group', 'actor': CASTER, 'target': ALLY},
              {'action': 'wait', 'label': 'pvp settle', 'ms': ENEMY_PLAYER_SETTLE_MS},
              {'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
    for actor in (CASTER, ALLY, ENEMY_PLAYER):
        steps += [{'action': 'add_item', 'actor': actor, 'item': spec.item},
                  {'action': 'equip', 'actor': actor, 'item': spec.item, 'slot': spec.item_slot},
                  {'action': 'money', 'actor': actor, 'copper': NPC_REPAIR_MONEY}]
    expectations = []
    rule = prose_rule(entry.quote, spec.spell)
    model = {'kind': 'npc_repair', 'quote': entry.quote}
    current = {actor: spec.full for actor in (CASTER, ALLY, ENEMY_PLAYER)}
    loss = int(spec.full * spec.loss_percent / 100)
    for actor, summoned in NPC_REPAIR_ARMS:
        if summoned and actor == CASTER:
            steps += cast_gate_power_step(facts) + required_aura_steps(facts) + [
                {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell},
                {'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER},
                {'action': 'wait', 'label': 'summon settle', 'ms': spec.summon_wait_ms}]
        worn = npc_repair_label(spec, actor, summoned, 'worn')
        repaired = npc_repair_label(spec, actor, summoned, 'after')
        refused = actor == ENEMY_PLAYER or not summoned
        current[actor] = max(0, current[actor] - loss)
        worn_value = current[actor]
        if not refused:
            current[actor] = spec.full
        steps += [{'action': 'durability_loss', 'actor': actor, 'percent': spec.loss_percent},
                  measurement(worn, actor, 'equipped_durability', item=spec.item),
                  {'action': 'repair_at', 'actor': actor, 'owner': CASTER, 'entry': spec.entry},
                  {'action': 'wait', 'label': f'{actor} repair settle', 'ms': spec.repair_wait_ms},
                  measurement(repaired, actor, 'equipped_durability', item=spec.item)]
        expectations.append(Expectation(worn, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.entry, None,
                                        str(worn_value), rule, dict(model)))
        expectations.append(Expectation(repaired, BEHAVIOUR_CAST_CONDITION, spec.spell, spec.entry, None,
                                        str(current[actor]), rule, dict(model)))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour npc repair',
        'contract': f'The caster, a grouped ally and an enemy player (both PvP-flagged) each wear item {spec.item} '
                    f'({spec.full} durability) worn by {spec.loss_percent:g}% of it before each request, and send a repair-all '
                    f'request to creature {spec.entry} of the caster: first before {spec.spell} is cast (no such '
                    f'creature, refused), then after it for the caster and the ally (repaired to {spec.full}) and '
                    f'the enemy (refused).',
        'players': [player_fixture(class_file), {**player_fixture(class_file), 'id': ALLY},
                    {**player_fixture(class_file), 'id': ENEMY_PLAYER, 'race': 2}],
        'location': dict(TAKEN_HIT_PVP_LOCATION),
        'steps': steps}
    return scenario, expectations


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return npc_repair_scenario(class_file, npc_repair_spec(entry))
