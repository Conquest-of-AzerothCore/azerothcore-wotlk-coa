from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import MAX_SCENARIO_MS, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, dataset, facts_of

KIND = 'gossip_ritual'
ORDER = 65
METRIC = 'nearby_creature_count'
TARGET_UNIT_CASTER = 1
TARGET_DEST_DEST = 87
TARGET_FLAG_DEST_LOCATION = 0x40
MIN_CHANNELERS = 2
MAX_CHANNELERS = 25
SCHEMA_1_MAX_PLAYERS = 8
DEFAULT_SPAWN_WAIT_MS = 1000
DEFAULT_DRAIN_WAIT_MS = 2500
DEFAULT_COMPLETE_WAIT_MS = 2500
MIN_WAIT_MS = 100
FIELDS = frozenset({'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'stone_entry', 'channel_aura',
                    'summon_entry', 'channelers', 'reagent_item', 'reagent_count', 'cast_power', 'spawn_wait_ms',
                    'drain_wait_ms', 'complete_wait_ms', 'observe_source'})


@dataclass(frozen=True)
class GossipRitualSpec:
    spell: int
    name: str
    quote: str
    stone_entry: int
    channel_aura: int
    summon_entry: int
    channelers: int
    reagent_item: int | None = None
    reagent_count: int = 1
    cast_power: int | None = None
    spawn_wait_ms: int = DEFAULT_SPAWN_WAIT_MS
    drain_wait_ms: int = DEFAULT_DRAIN_WAIT_MS
    complete_wait_ms: int = DEFAULT_COMPLETE_WAIT_MS
    label_suffix: str = KIND


def positive_int(value, field_name: str, spell: int) -> int:
    if type(value) is not int or value < 1:
        raise ValueError(f'{spell} {KIND} {field_name} must be a positive int, not {value!r}')
    return value


def gossip_ritual_spec(entry: dict) -> GossipRitualSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry.get("spell")} {KIND} unknown fields {sorted(unknown)}')
    spell = positive_int(entry['spell'], 'spell', int(entry['spell']) if isinstance(entry.get('spell'), int) else 0)
    stone_entry = positive_int(entry['stone_entry'], 'stone_entry', spell)
    channel_aura = positive_int(entry['channel_aura'], 'channel_aura', spell)
    summon_entry = positive_int(entry['summon_entry'], 'summon_entry', spell)
    if stone_entry == summon_entry:
        raise ValueError(f'{spell} {KIND} stone_entry and summon_entry must be distinct')
    channelers = entry['channelers']
    if type(channelers) is not int or not MIN_CHANNELERS <= channelers <= MAX_CHANNELERS:
        raise ValueError(f'{spell} {KIND} channelers must be an int in {MIN_CHANNELERS}..{MAX_CHANNELERS}, '
                         f'not {channelers!r}')
    reagent_raw = entry.get('reagent_item')
    reagent_item = None if reagent_raw is None else positive_int(reagent_raw, 'reagent_item', spell)
    if 'reagent_count' in entry and reagent_item is None:
        raise ValueError(f'{spell} {KIND} reagent_count requires reagent_item')
    reagent_count = positive_int(entry.get('reagent_count', 1), 'reagent_count', spell)
    cast_power = entry.get('cast_power')
    if cast_power is not None and (type(cast_power) is not int or cast_power < 0):
        raise ValueError(f'{spell} {KIND} cast_power must be a non-negative int, not {cast_power!r}')
    waits = {}
    for field_name, default in (('spawn_wait_ms', DEFAULT_SPAWN_WAIT_MS),
                                ('drain_wait_ms', DEFAULT_DRAIN_WAIT_MS),
                                ('complete_wait_ms', DEFAULT_COMPLETE_WAIT_MS)):
        value = entry.get(field_name, default)
        if type(value) is not int or value < MIN_WAIT_MS:
            raise ValueError(f'{spell} {KIND} {field_name} must be an int >= {MIN_WAIT_MS}, not {value!r}')
        waits[field_name] = value
    return GossipRitualSpec(spell, entry['name'], entry['quote'], stone_entry, channel_aura, summon_entry,
                            channelers, reagent_item, reagent_count, cast_power, waits['spawn_wait_ms'],
                            waits['drain_wait_ms'], waits['complete_wait_ms'], entry.get('label_suffix', KIND))


def mark(spec: GossipRitualSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def gossip_ritual_scenario(class_file: dict, spec: GossipRitualSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    facts = facts_of(records, spec.spell)
    channel_facts = facts_of(records, spec.channel_aura)
    targets_mask = records.field('Spell', spec.spell, 'Targets')
    needs_destination = TARGET_DEST_DEST in facts.target_a or bool(targets_mask & TARGET_FLAG_DEST_LOCATION)
    self_channel_aura = TARGET_UNIT_CASTER in channel_facts.target_a
    allies = tuple(f'ally{index}' for index in range(1, spec.channelers))
    reads = {
        'pre_stone': mark(spec, 'pre stone'),
        'pre_summon': mark(spec, 'pre summon'),
        'pre_aura': mark(spec, 'pre aura'),
        'pre_hp': mark(spec, 'pre hp'),
        'cast_failure': mark(spec, 'cast failure'),
        'stone_created': mark(spec, 'stone created'),
        'caster_channeling': mark(spec, 'caster channeling'),
        'hp_after_drain': mark(spec, 'hp after drain'),
        'summon_before_full': mark(spec, 'summon before full'),
        'stone_after_complete': mark(spec, 'stone after complete'),
        'summon_created': mark(spec, 'summon created'),
    }

    def channel_measurement(read_label: str) -> dict:
        if self_channel_aura:
            return measurement(read_label, CASTER, 'aura', spell=spec.channel_aura)
        return measurement(read_label, CASTER, 'owned_creature_count', entry=spec.stone_entry,
                           spell=spec.channel_aura, caster=CASTER)

    reagent_steps = ([{'action': 'add_item', 'actor': CASTER, 'item': spec.reagent_item, 'count': spec.reagent_count}]
                     if spec.reagent_item is not None else [])
    power_steps = ([{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': spec.cast_power}]
                   if spec.cast_power is not None else [])
    cast_step = {'action': 'cast', 'actor': CASTER, 'spell': spec.spell,
                 **({'destination_unit': CASTER} if needs_destination else {})}
    steps = (base_steps(class_file)
             + [{'action': 'group', 'actor': CASTER, 'target': ally} for ally in allies]
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + reagent_steps
             + [measurement(reads['pre_stone'], CASTER, 'owned_creature_count', entry=spec.stone_entry),
                measurement(reads['pre_summon'], CASTER, METRIC, entry=spec.summon_entry),
                channel_measurement(reads['pre_aura']),
                measurement(reads['pre_hp'], CASTER, 'health')]
             + power_steps
             + [cast_step,
                measurement(reads['cast_failure'], CASTER, 'cast_failure', spell=spec.spell),
                {'action': 'wait', 'label': f'{KIND} stone spawn', 'ms': spec.spawn_wait_ms},
                measurement(reads['stone_created'], CASTER, 'owned_creature_count', entry=spec.stone_entry),
                {'action': 'gossip_hello', 'actor': CASTER, 'entry': spec.stone_entry},
                {'action': 'wait', 'label': f'{KIND} drain wait', 'ms': spec.drain_wait_ms},
                channel_measurement(reads['caster_channeling']),
                measurement(reads['hp_after_drain'], CASTER, 'health'),
                measurement(reads['summon_before_full'], CASTER, METRIC, entry=spec.summon_entry)]
             + [{'action': 'gossip_hello', 'actor': ally, 'entry': spec.stone_entry} for ally in allies]
             + [{'action': 'wait', 'label': f'{KIND} complete wait', 'ms': spec.complete_wait_ms},
                measurement(reads['stone_after_complete'], CASTER, 'owned_creature_count', entry=spec.stone_entry),
                measurement(reads['summon_created'], CASTER, METRIC, entry=spec.summon_entry)])
    players = [{**player_fixture(class_file), 'allow_regeneration': False},
               *({**player_fixture(class_file), 'id': ally, 'allow_regeneration': False} for ally in allies)]
    scenario = {
        'schema': 2 if spec.channelers > SCHEMA_1_MAX_PLAYERS else 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour gossip ritual',
        'contract': (f'{spec.channelers} grouped same-class players ({CASTER}, {allies[0]}..{allies[-1]}) with '
                     f'regeneration disabled. Pre-cast controls verify 0 ritual stone ({spec.stone_entry}), 0 summon '
                     f'({spec.summon_entry}), 0 channel aura ({spec.channel_aura}), and positive health on {CASTER}. '
                     f'{CASTER} casts {spec.spell} (cast_failure == 0) to spawn stone {spec.stone_entry} (count 1), '
                     f'then activates it via gossip_hello and waits {spec.drain_wait_ms} ms to verify channel aura '
                     f'{spec.channel_aura} == 1, caster health strictly below pre_hp, and premature summon count == 0. '
                     f'The remaining {len(allies)} grouped allies activate stone {spec.stone_entry} via gossip_hello '
                     f'and after {spec.complete_wait_ms} ms the stone must despawn (0) and {METRIC} of summon '
                     f'{spec.summon_entry} must read 1.'),
        'players': players,
        'steps': steps}
    model = {'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'spell': spec.spell,
             'stone_entry': spec.stone_entry, 'channel_aura': spec.channel_aura, 'summon_entry': spec.summon_entry,
             'channelers': spec.channelers, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.spell, None, '1',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps), MAX_SCENARIO_MS), [expectation]


def gossip_ritual_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    val = run.values

    def require_present(*keys: str) -> str | None:
        return next((reads[key] for key in keys if val.get(reads[key]) is None), None)

    missing = require_present('pre_stone', 'pre_summon', 'pre_aura', 'pre_hp', 'cast_failure', 'stone_created')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    pre = {key: val[reads[key]] for key in ('pre_stone', 'pre_summon', 'pre_aura', 'pre_hp')}
    if pre['pre_stone'] != 0 or pre['pre_summon'] != 0 or pre['pre_aura'] != 0 or pre['pre_hp'] <= 0:
        return replace(base, status='unmeasured', detail={'metric': METRIC, 'pre': pre},
                       explanation=f'pre-cast baseline not clean: {pre}')
    cast_failure = val[reads['cast_failure']]
    if cast_failure != 0:
        return replace(base, status='alert', measured=0.0, expected=1.0,
                       detail={'metric': METRIC, 'cast_failure': cast_failure},
                       explanation=f'ritual cast {model["spell"]} failed with cast_failure={cast_failure:g}')
    stone = val[reads['stone_created']]
    if stone != 1:
        return replace(base, status='alert', measured=stone, expected=1.0,
                       detail={'metric': METRIC, 'stone_created': stone},
                       explanation=f'{model["spell"]} created {stone:g} stone creature(s) of entry '
                                   f'{model["stone_entry"]}, expected 1')
    missing = require_present('caster_channeling', 'hp_after_drain', 'summon_before_full')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    channeling = val[reads['caster_channeling']]
    hp_after_drain = val[reads['hp_after_drain']]
    before_full = val[reads['summon_before_full']]
    if channeling != 1:
        return replace(base, status='alert', measured=channeling, expected=1.0,
                       detail={'metric': METRIC, 'stone_created': stone, 'caster_channeling': channeling},
                       explanation=f'gossip_hello on stone {model["stone_entry"]} left channel aura '
                                   f'{model["channel_aura"]}={channeling:g}, expected 1')
    if hp_after_drain >= pre['pre_hp']:
        return replace(base, status='alert', measured=pre['pre_hp'] - hp_after_drain, expected=1.0,
                       detail={'metric': METRIC, 'hp_before': pre['pre_hp'], 'hp_after_drain': hp_after_drain},
                       explanation=f'caster health did not drain while channeling ({pre["pre_hp"]:g} -> '
                                   f'{hp_after_drain:g})')
    if before_full != 0:
        return replace(base, status='alert', measured=before_full, expected=0.0,
                       detail={'metric': METRIC, 'summon_before_full': before_full},
                       explanation=f'summon {model["summon_entry"]} appeared prematurely ({before_full:g}) '
                                   f'before all {model["channelers"]} channelers joined')
    missing = require_present('stone_after_complete', 'summon_created')
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    stone_after = val[reads['stone_after_complete']]
    summon_created = val[reads['summon_created']]
    detail = {'metric': METRIC, 'stone_created': stone, 'caster_channeling': channeling,
              'hp_before': pre['pre_hp'], 'hp_after_drain': hp_after_drain,
              'summon_before_full': before_full, 'stone_after_complete': stone_after,
              'summon_created': summon_created}
    if stone_after != 0:
        return replace(base, status='alert', measured=stone_after, expected=0.0, detail=detail,
                       explanation=f'ritual stone {model["stone_entry"]} remained alive ({stone_after:g}) after '
                                   f'{model["channelers"]} channelers completed the ritual')
    if summon_created != 1:
        return replace(base, status='alert', measured=summon_created, expected=1.0, detail=detail,
                       explanation=f'completing ritual on stone {model["stone_entry"]} left {METRIC}='
                                   f'{summon_created:g} for summon {model["summon_entry"]}, expected 1')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0, detail=detail,
                   explanation=f'stone {model["stone_entry"]} (0->1->0), channel {model["channel_aura"]} (0->1), '
                               f'hp ({pre["pre_hp"]:g}->{hp_after_drain:g}), summon {model["summon_entry"]} '
                               f'{METRIC}: 0 -> 0 -> 1')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return gossip_ritual_scenario(class_file, gossip_ritual_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: gossip_ritual_verdict}
METRIC_EVIDENCE = {METRIC: 'event'}
