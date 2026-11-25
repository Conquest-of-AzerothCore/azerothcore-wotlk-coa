from dataclasses import dataclass, replace
import math
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, cleaned_tooltip, prose_rule, waited_ms
from compare import Run, Verdict, missing_measurement
from hits import MAX_ACCELERATED_SCENARIO_MS, MAX_SCENARIO_MS, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import Expectation, GCD_WAIT_MS, MAX_SCENARIO_STEPS, TARGET, dataset, facts_of

KIND = 'portal_single_cast'
ORDER = 57
METRIC = 'owned_creature_total_cast_count'
METRIC_EVIDENCE = {METRIC: 'event'}
MIN_PORTALS = 6
DESPAWN_MARGIN_MS = 500
DEFAULT_RESIDUAL = 1e-3
PAIR_RUNS = 2
MAX_FEED_CASTS = 200
CHANNELED_ATTRIBUTES_EX = 0x44
SPAWN_SETTLE_MS = 100


@dataclass(frozen=True)
class FeedSpec:
    every_ms: int
    residual: float = DEFAULT_RESIDUAL
    control_casts: int | None = None


@dataclass(frozen=True)
class PortalSingleCastSpec:
    spell: int
    name: str
    quote: str
    gate_spell: int
    trigger_spell: int
    entry: int
    allowed_spells: tuple[int, ...]
    cast_read_ms: int
    direct_despawn_ms: int
    direct_despawn_check_ms: int
    lifetime_ms: int
    portals: int
    parts: int = 1
    label_suffix: str = KIND
    quote_spell: int | None = None
    learn: tuple[int, ...] = ()
    setup_casts: tuple[int, ...] = ()
    setup_wait_ms: int = 0
    cancel_before_trial: tuple[int, ...] = ()
    phase_auras: tuple[tuple[int, int, str, str], ...] = ()
    cast_power: int | None = None
    spawn_wait_ms: int | None = None
    channeled_despawn_ms: int | None = None
    channeled_despawn_check_ms: int | None = None
    feed: FeedSpec | None = None


def parse_feed(raw) -> FeedSpec | None:
    if raw is None:
        return None
    if not isinstance(raw, dict) or not {'every_ms'} <= set(raw) <= {'every_ms', 'residual', 'control_casts'}:
        raise ValueError(f'{KIND} feed is {{"every_ms": ms, "residual": float, "control_casts": n}} '
                         f'(residual and control_casts optional), not {raw!r}')
    every_ms = raw['every_ms']
    if not isinstance(every_ms, int) or isinstance(every_ms, bool) or every_ms < GCD_WAIT_MS:
        raise ValueError(f'{KIND} feed every_ms must be an int >= {GCD_WAIT_MS}, not {every_ms!r}')
    residual = float(raw.get('residual', DEFAULT_RESIDUAL))
    if not 0 < residual < 1:
        raise ValueError(f'{KIND} feed residual must be in (0, 1), not {residual!r}')
    control_casts = raw.get('control_casts')
    if control_casts is not None and (not isinstance(control_casts, int) or isinstance(control_casts, bool)
                                      or not 1 <= control_casts <= MAX_FEED_CASTS):
        raise ValueError(f'{KIND} feed control_casts must be in 1..{MAX_FEED_CASTS}, not {control_casts!r}')
    return FeedSpec(every_ms, residual, control_casts)


def parse_phase_auras(raw) -> tuple[tuple[int, int, str, str], ...]:
    if not raw:
        return ()
    parsed = []
    for item in raw:
        if not isinstance(item, (list, tuple)) or len(item) != 4:
            raise ValueError(f'{KIND} phase_auras entries are [spell, stacks, target, caster], not {item!r}')
        spell, stacks, target, caster = item
        if not isinstance(spell, int) or isinstance(spell, bool) or spell < 1:
            raise ValueError(f'{KIND} phase_auras spell must be positive int, not {spell!r}')
        if not isinstance(stacks, int) or isinstance(stacks, bool) or stacks < 0:
            raise ValueError(f'{KIND} phase_auras stacks must be non-negative int, not {stacks!r}')
        if target not in (CASTER, TARGET) or caster not in (CASTER, TARGET):
            raise ValueError(f'{KIND} phase_auras target and caster must be {CASTER!r} or {TARGET!r}')
        parsed.append((spell, stacks, target, caster))
    return tuple(parsed)


def portal_single_cast_spec(entry: dict) -> PortalSingleCastSpec:
    spell = int(entry['spell'])
    allowed = tuple(int(item) for item in entry['allowed_spells'])
    spec = PortalSingleCastSpec(
        spell, entry['name'], entry['quote'], int(entry.get('gate_spell', spell)), int(entry['trigger_spell']),
        int(entry['entry']), allowed, int(entry['cast_read_ms']), int(entry['direct_despawn_ms']),
        int(entry['direct_despawn_check_ms']), int(entry['lifetime_ms']), int(entry['portals']),
        int(entry.get('parts', 1)), entry.get('label_suffix', KIND),
        int(entry['quote_spell']) if entry.get('quote_spell') is not None else None,
        tuple(int(item) for item in entry.get('learn', ())),
        tuple(int(item) for item in entry.get('setup_casts', ())),
        int(entry.get('setup_wait_ms', 0)),
        tuple(int(item) for item in entry.get('cancel_before_trial', ())),
        parse_phase_auras(entry.get('phase_auras')),
        int(entry['cast_power']) if entry.get('cast_power') is not None else None,
        int(entry['spawn_wait_ms']) if entry.get('spawn_wait_ms') is not None else None,
        int(entry['channeled_despawn_ms']) if entry.get('channeled_despawn_ms') is not None else None,
        int(entry['channeled_despawn_check_ms']) if entry.get('channeled_despawn_check_ms') is not None else None,
        parse_feed(entry.get('feed')))
    if not spec.allowed_spells or len(set(spec.allowed_spells)) != len(spec.allowed_spells):
        raise ValueError(f'{spell} {KIND} needs at least one distinct spell in allowed_spells')
    if spec.entry < 1 or spec.portals < 1 or spec.parts < 1:
        raise ValueError(f'{spell} {KIND} needs positive entry, portals and parts')
    if spec.portals * spec.parts < MIN_PORTALS:
        raise ValueError(f'{spell} {KIND} plans {spec.portals * spec.parts} portals, below minimum {MIN_PORTALS}')
    if spec.gate_spell in spec.learn:
        raise ValueError(f'{spell} {KIND} learns gate_spell {spec.gate_spell} only between control and treatment')
    if spec.setup_wait_ms < 0:
        raise ValueError(f'{spell} {KIND} setup_wait_ms must be non-negative')
    if spec.feed is not None and spec.setup_casts:
        raise ValueError(f'{spell} {KIND} uses feed instead of setup_casts')
    if spec.cast_read_ms <= 0 or spec.direct_despawn_ms <= 0 or spec.lifetime_ms <= 0:
        raise ValueError(f'{spell} {KIND} timings must be positive')
    if not spec.cast_read_ms < spec.direct_despawn_check_ms <= spec.lifetime_ms - DESPAWN_MARGIN_MS:
        raise ValueError(f'{spell} {KIND} requires cast_read_ms < direct_despawn_check_ms <= '
                         f'lifetime_ms - {DESPAWN_MARGIN_MS}')
    if spec.direct_despawn_check_ms < spec.direct_despawn_ms:
        raise ValueError(f'{spell} {KIND} direct_despawn_check_ms must be at least direct_despawn_ms')
    if (spec.channeled_despawn_ms is None) != (spec.channeled_despawn_check_ms is None):
        raise ValueError(f'{spell} {KIND} sets channeled_despawn_ms and channeled_despawn_check_ms together')
    if spec.channeled_despawn_check_ms is not None:
        if not spec.direct_despawn_check_ms < spec.channeled_despawn_check_ms <= spec.lifetime_ms - DESPAWN_MARGIN_MS:
            raise ValueError(f'{spell} {KIND} requires direct_despawn_check_ms < channeled_despawn_check_ms <= '
                             f'lifetime_ms - {DESPAWN_MARGIN_MS}')
        if spec.channeled_despawn_check_ms < spec.channeled_despawn_ms:
            raise ValueError(f'{spell} {KIND} channeled_despawn_check_ms must be at least channeled_despawn_ms')
    return spec


def is_channeled_spell(records: Records, spell_id: int) -> bool:
    return bool(int(records.field('Spell', spell_id, 'AttributesEx') or 0) & CHANNELED_ATTRIBUTES_EX)


def feed_cast_caps(records: Records, spec: PortalSingleCastSpec) -> tuple[int, int]:
    assert spec.feed is not None
    chance = float(records.field('Spell', spec.gate_spell, 'ProcChance')) / 100.0
    if not 0 < chance < 1:
        raise ValueError(f'{spec.spell} {KIND} feed needs gate_spell {spec.gate_spell} with ProcChance in (0, 100)')
    total_portals = PAIR_RUNS * spec.parts * spec.portals
    per_portal = spec.feed.residual / total_portals
    max_casts = math.ceil(math.log(per_portal) / math.log(1.0 - chance))
    if max_casts > MAX_FEED_CASTS:
        raise ValueError(f'{spec.spell} {KIND} feed needs {max_casts} casts per portal (above {MAX_FEED_CASTS}): '
                         f'split portals across more parts')
    control = spec.feed.control_casts if spec.feed.control_casts is not None else math.ceil(
        math.log(spec.feed.residual) / math.log(1.0 - chance))
    if control > MAX_FEED_CASTS:
        raise ValueError(f'{spec.spell} {KIND} control feed needs {control} casts (above {MAX_FEED_CASTS})')
    return max_casts, control


def check_label(spec: PortalSingleCastSpec) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}'


def trial_label(prefix: str, trial: int, name: str) -> str:
    return f'{prefix} trial {trial} {name}'


def control_label(prefix: str, name: str) -> str:
    return f'{prefix} control {name}'


def fixture_steps(spec: PortalSingleCastSpec) -> list[dict]:
    steps = [{'action': 'cancel_aura', 'actor': CASTER, 'spell': aura} for aura in spec.cancel_before_trial]
    for aura, stacks, target, caster in spec.phase_auras:
        steps.append({'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks,
                      'target': target, 'caster': caster})
    return steps


def cast_sequence(records: Records, spec: PortalSingleCastSpec, spell_id: int) -> list[dict]:
    facts = facts_of(records, spell_id)
    power = spec.cast_power if spec.cast_power is not None else facts.mana_cost
    return [{'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power},
            {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spell_id},
            {'action': 'cast', 'actor': CASTER, 'spell': spell_id, 'target': TARGET}]


def portal_single_cast_scenario(class_file: dict, spec: PortalSingleCastSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    quoted = spec.spell
    if spec.quote_spell is not None and spec.quote_spell != spec.spell:
        if f'@s:{spec.quote_spell}:' not in cleaned_tooltip(records, spec.spell):
            raise ValueError(f'{spec.spell} {KIND} quotes {spec.quote_spell}, whose tooltip the {spec.spell} '
                             f'tooltip does not embed')
        quoted = spec.quote_spell
    for allowed in spec.allowed_spells:
        if not records.has_spell(allowed):
            raise ValueError(f'{spec.spell} {KIND} unknown spell {allowed} in allowed_spells')
    channeled = tuple(allowed for allowed in spec.allowed_spells if is_channeled_spell(records, allowed))
    if channeled and spec.channeled_despawn_check_ms is None:
        raise ValueError(f'{spec.spell} {KIND} allowed_spells contains channeled spell(s) {list(channeled)} '
                         f'without channeled_despawn_ms/channeled_despawn_check_ms')
    read_channeled = bool(channeled) and spec.channeled_despawn_check_ms is not None
    entry = behaviour_entry(records, quoted, spec.name, KIND, spec.quote, 1.0)
    trigger_facts = facts_of(records, spec.trigger_spell)
    spawn_wait = spec.spawn_wait_ms if spec.spawn_wait_ms is not None else trigger_facts.cast_time_ms + SPAWN_SETTLE_MS
    if spawn_wait < trigger_facts.cast_time_ms:
        raise ValueError(f'{spec.spell} {KIND} spawn_wait_ms ({spawn_wait}) is below trigger cast time '
                         f'({trigger_facts.cast_time_ms})')
    max_casts, control_casts = feed_cast_caps(records, spec) if spec.feed is not None else (0, 0)
    prefix = check_label(spec)
    power = spec.cast_power if spec.cast_power is not None else trigger_facts.mana_cost

    def deterministic_trigger(label_tag: str) -> list[dict]:
        steps = fixture_steps(spec)
        for setup_spell in spec.setup_casts:
            steps += cast_sequence(records, spec, setup_spell)
            if spec.setup_wait_ms:
                steps.append({'action': 'wait', 'label': f'{label_tag} setup wait', 'ms': spec.setup_wait_ms})
        steps += cast_sequence(records, spec, spec.trigger_spell)
        if spawn_wait:
            steps.append({'action': 'wait', 'label': f'{label_tag} spawn wait', 'ms': spawn_wait})
        return steps

    def feed_trigger(label_tag: str, cap: int) -> list[dict]:
        assert spec.feed is not None
        return fixture_steps(spec) + [
            {'action': 'cast_until_owned_creature', 'label': f'{prefix} {label_tag} feed', 'actor': CASTER,
             'spell': spec.trigger_spell, 'target': TARGET, 'entry': spec.entry, 'every_ms': spec.feed.every_ms,
             'max_casts': cap, 'cast_power': power, 'power': trigger_facts.power_type, 'reset_cooldown': True}]

    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((*spec.learn, spec.trigger_spell, *spec.setup_casts))]
             + [{'action': 'select', 'actor': CASTER, 'target': TARGET}])

    if spec.feed is not None:
        steps += feed_trigger('control', control_casts)
    else:
        steps += deterministic_trigger('control')
    control_reads = {'count': control_label(prefix, 'count'), 'summons': control_label(prefix, 'summons')}
    steps += [measurement(control_reads['count'], CASTER, 'owned_creature_count', entry=spec.entry),
              measurement(control_reads['summons'], CASTER, 'owned_creature_summon_count', entry=spec.entry)]

    steps.append({'action': 'learn', 'actor': CASTER, 'spell': spec.gate_spell})
    trials_model = []
    for index in range(1, spec.portals + 1):
        pre = trial_label(prefix, index, 'pre')
        pre_total = trial_label(prefix, index, 'pre_total')
        pre_spells = {str(allowed): trial_label(prefix, index, f'pre_spell_{allowed}')
                      for allowed in spec.allowed_spells}
        spawned = trial_label(prefix, index, 'spawned')
        alive = trial_label(prefix, index, 'alive')
        total = trial_label(prefix, index, 'total')
        spells = {str(allowed): trial_label(prefix, index, f'spell_{allowed}') for allowed in spec.allowed_spells}
        after_direct = trial_label(prefix, index, 'after_direct')
        after_channeled = trial_label(prefix, index, 'after_channeled') if read_channeled else None
        post_total = trial_label(prefix, index, 'post_total')
        post_spells = {str(allowed): trial_label(prefix, index, f'post_spell_{allowed}')
                       for allowed in spec.allowed_spells}
        steps += [measurement(pre, CASTER, 'owned_creature_count', entry=spec.entry),
                  measurement(pre_total, CASTER, METRIC, entry=spec.entry, triggered=False, cumulative=True)]
        for allowed in spec.allowed_spells:
            steps.append(measurement(pre_spells[str(allowed)], CASTER, METRIC, entry=spec.entry,
                                     spell=allowed, triggered=False, cumulative=True))
        if spec.feed is not None:
            steps += feed_trigger(f'trial {index}', max_casts)
        else:
            steps += deterministic_trigger(f'trial {index}')
        steps += [measurement(spawned, CASTER, 'owned_creature_count', entry=spec.entry),
                  {'action': 'wait', 'label': f'trial {index} cast read', 'ms': spec.cast_read_ms},
                  measurement(alive, CASTER, 'owned_creature_count', entry=spec.entry),
                  measurement(total, CASTER, METRIC, entry=spec.entry, triggered=False)]
        for allowed in spec.allowed_spells:
            steps.append(measurement(spells[str(allowed)], CASTER, METRIC, entry=spec.entry,
                                     spell=allowed, triggered=False))
        steps += [{'action': 'wait', 'label': f'trial {index} direct despawn',
                   'ms': spec.direct_despawn_check_ms - spec.cast_read_ms},
                  measurement(after_direct, CASTER, 'owned_creature_count', entry=spec.entry)]
        if read_channeled and spec.channeled_despawn_check_ms is not None and after_channeled is not None:
            steps += [{'action': 'wait', 'label': f'trial {index} channeled despawn',
                       'ms': spec.channeled_despawn_check_ms - spec.direct_despawn_check_ms},
                      measurement(after_channeled, CASTER, 'owned_creature_count', entry=spec.entry)]
        steps.append(measurement(post_total, CASTER, METRIC, entry=spec.entry, triggered=False, cumulative=True))
        for allowed in spec.allowed_spells:
            steps.append(measurement(post_spells[str(allowed)], CASTER, METRIC, entry=spec.entry,
                                     spell=allowed, triggered=False, cumulative=True))
        row = {'pre': pre, 'pre_total': pre_total, 'pre_spells': pre_spells, 'spawned': spawned, 'alive': alive,
               'total': total, 'spells': spells, 'after_direct': after_direct, 'post_total': post_total,
               'post_spells': post_spells}
        if after_channeled is not None:
            row['after_channeled'] = after_channeled
        trials_model.append(row)

    if len(steps) > MAX_SCENARIO_STEPS:
        raise ValueError(f'{spec.spell} {KIND} takes {len(steps)} steps, above {MAX_SCENARIO_STEPS}: add parts')

    despawn_branch = (f'direct despawn {spec.direct_despawn_ms} ms (checked absent at {spec.direct_despawn_check_ms} '
                      f'ms) / channeled despawn {spec.channeled_despawn_ms} ms (checked absent at '
                      f'{spec.channeled_despawn_check_ms} ms)'
                      if spec.channeled_despawn_ms is not None else
                      f'direct despawn {spec.direct_despawn_ms} ms (checked absent at {spec.direct_despawn_check_ms} '
                      f'ms)')
    feed_note = (f' Rolled spawn fed by cast_until_owned_creature every {spec.feed.every_ms} ms '
                 f'(control cap {control_casts}, treatment cap {max_casts} casts/portal; pair cap-hit union bound '
                 f'<= {spec.feed.residual:.1e} across {PAIR_RUNS * spec.parts * spec.portals} portals).'
                 if spec.feed is not None else
                 f' Deterministic spawn via {spec.trigger_spell} (spawn wait {spawn_wait} ms).')
    contract = (f'Per-summon single cast and post-cast despawn for creature {spec.entry}: control runs before '
                f'{spec.gate_spell} is learned (expects 0 summons and 0 living {spec.entry}). Treatment learns '
                f'{spec.gate_spell} and observes {spec.portals} portal(s)/part across {spec.parts} part(s) '
                f'({spec.portals * spec.parts} portals/run, '
                f'{PAIR_RUNS * spec.parts * spec.portals} per pair).{feed_note} '
                f'Each portal is checked 0 before trigger, 1 on spawn, 1 alive at +{spec.cast_read_ms} ms with '
                f'{METRIC}(triggered=false) == 1 and summed allowed spells {list(spec.allowed_spells)} == 1 '
                f'(channeled in DBC: {list(channeled)}), then absent after cast ({despawn_branch}) strictly before '
                f'summon lifetime {spec.lifetime_ms} ms, with post-despawn cumulative entry-scoped '
                f'{METRIC}(triggered=false, cumulative=true) delta == 1 across the whole lifetime.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour portal single cast',
        'contract': contract,
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    model = {
        'kind': KIND, 'metric': METRIC, 'quote': entry.quote, 'entry': spec.entry,
        'allowed_spells': list(spec.allowed_spells), 'channeled_spells': list(channeled),
        'control': control_reads, 'trials': trials_model, 'parts': spec.parts,
        'cast_read_ms': spec.cast_read_ms, 'direct_despawn_ms': spec.direct_despawn_ms,
        'direct_despawn_check_ms': spec.direct_despawn_check_ms,
        'channeled_despawn_ms': spec.channeled_despawn_ms,
        'channeled_despawn_check_ms': spec.channeled_despawn_check_ms,
        'lifetime_ms': spec.lifetime_ms, 'feed': spec.feed is not None}
    expectation = Expectation(prefix, BEHAVIOUR_METRIC_DELTA, spec.spell, spec.entry, None, '1',
                              prose_rule(entry.quote, quoted), model)
    feed_budget = sum(step['max_casts'] * step['every_ms'] for step in steps
                      if step['action'] == 'cast_until_owned_creature')
    cap_ms = MAX_ACCELERATED_SCENARIO_MS if spec.feed is not None else MAX_SCENARIO_MS
    return timed(scenario, waited_ms(steps) + feed_budget, cap_ms), [expectation]


def judge_single_run(run: Run, model: dict) -> tuple[str, dict[int, int], int, str]:
    control = model['control']
    for key in ('count', 'summons'):
        value = run.values.get(control[key])
        if value is None:
            return 'unmeasured', {}, 0, missing_measurement(run, control[key])
    if run.values[control['count']] != 0 or run.values[control['summons']] != 0:
        return ('alert', {}, 0,
                f'control spawned entry {model["entry"]} without gate '
                f'(count={run.values[control["count"]]:g}, summons={run.values[control["summons"]]:g})')
    allowed = [int(spell) for spell in model['allowed_spells']]
    channeled = {int(spell) for spell in model['channeled_spells']}
    spell_totals = {spell: 0 for spell in allowed}
    observed = 0
    for index, trial in enumerate(model['trials'], 1):
        required_labels = [trial['pre'], trial['pre_total'], *trial['pre_spells'].values(),
                           trial['spawned'], trial['alive'], trial['total'], trial['after_direct'],
                           *trial['spells'].values(), trial['post_total'], *trial['post_spells'].values()]
        if 'after_channeled' in trial:
            required_labels.append(trial['after_channeled'])
        for label in required_labels:
            if run.values.get(label) is None:
                return 'unmeasured', spell_totals, observed, missing_measurement(run, label)
        pre = run.values[trial['pre']]
        if pre != 0:
            return ('unmeasured', spell_totals, observed,
                    f'trial {index}: {pre:g} creature(s) already present before trigger')
        spawned = run.values[trial['spawned']]
        if spawned == 0:
            if model.get('feed'):
                return ('unmeasured', spell_totals, observed,
                        f'trial {index}: feed reached cap without spawning entry {model["entry"]}')
            return ('alert', spell_totals, observed,
                    f'trial {index}: expected spawn of entry {model["entry"]} did not appear')
        if spawned != 1:
            return ('alert', spell_totals, observed,
                    f'trial {index}: spawned {spawned:g} creatures of entry {model["entry"]}, expected 1')
        alive = run.values[trial['alive']]
        if alive != 1:
            return ('alert', spell_totals, observed,
                    f'trial {index}: read {alive:g} living creature(s) at '
                    f'+{model["cast_read_ms"]} ms, expected 1')
        total = run.values[trial['total']]
        counts = {spell: run.values[trial['spells'][str(spell)]] for spell in allowed}
        allowed_sum = sum(counts.values())
        if total != 1 or allowed_sum != 1 or any(count not in (0, 1) for count in counts.values()):
            return ('alert', spell_totals, observed,
                    f'trial {index}: total direct casts={total:g}, allowed={counts} '
                    f'(sum={allowed_sum:g}), expected exactly 1 cast in {allowed}')
        chosen = next(spell for spell, count in counts.items() if count == 1)
        if chosen in channeled:
            if 'after_channeled' not in trial:
                return ('unmeasured', spell_totals, observed,
                        f'trial {index}: channeled spell {chosen} has no channeled despawn read')
            after = run.values[trial['after_channeled']]
            check_ms = model['channeled_despawn_check_ms']
            if after != 0:
                return ('alert', spell_totals, observed,
                        f'trial {index}: portal still alive ({after:g}) at '
                        f'+{check_ms} ms after channeled spell {chosen} '
                        f'(lifetime {model["lifetime_ms"]} ms)')
        else:
            after = run.values[trial['after_direct']]
            check_ms = model['direct_despawn_check_ms']
            if after != 0:
                return ('alert', spell_totals, observed,
                        f'trial {index}: portal still alive ({after:g}) at '
                        f'+{check_ms} ms after direct spell {chosen} '
                        f'(lifetime {model["lifetime_ms"]} ms)')
            if 'after_channeled' in trial and run.values[trial['after_channeled']] != 0:
                late_after = run.values[trial['after_channeled']]
                return ('alert', spell_totals, observed,
                        f'trial {index}: portal present ({late_after:g}) at '
                        f'+{model["channeled_despawn_check_ms"]} ms after direct spell {chosen}')
        post_total_delta = run.values[trial['post_total']] - run.values[trial['pre_total']]
        post_counts = {spell: run.values[trial['post_spells'][str(spell)]] - run.values[trial['pre_spells'][str(spell)]]
                       for spell in allowed}
        post_allowed_sum = sum(post_counts.values())
        if post_total_delta < 0 or any(count < 0 for count in post_counts.values()):
            return ('unmeasured', spell_totals, observed,
                    f'trial {index}: cumulative direct cast counter decreased '
                    f'(total_delta={post_total_delta:g}, allowed_delta={post_counts})')
        if (post_total_delta != 1 or post_allowed_sum != 1
                or any(count not in (0, 1) for count in post_counts.values())
                or post_counts[chosen] != 1):
            return ('alert', spell_totals, observed,
                    f'trial {index}: full-lifetime direct casts delta={post_total_delta:g}, '
                    f'allowed_delta={post_counts} (sum={post_allowed_sum:g}), '
                    f'expected exactly 1 cast of {chosen} across whole lifetime')
        spell_totals[chosen] += 1
        observed += 1
    return 'ok', spell_totals, observed, ''


def portal_single_cast_verdict(base: Verdict, runs: list[Run], model: dict) -> Verdict:
    expected_parts = int(model.get('parts', 1))
    if len(runs) != expected_parts:
        return replace(base, status='unmeasured',
                       explanation=f'received {len(runs)} part(s), expected {expected_parts}')
    allowed = [int(spell) for spell in model['allowed_spells']]
    totals = {spell: 0 for spell in allowed}
    observed = 0
    planned = expected_parts * len(model['trials'])
    for part_index, run in enumerate(runs, 1):
        status, counts, count, why = judge_single_run(run, model)
        for spell, value in counts.items():
            totals[spell] = totals.get(spell, 0) + value
        observed += count
        if status != 'ok':
            return replace(base, status=status, measured=float(observed) / planned if planned else None,
                           expected=1.0, low=1.0, high=1.0,
                           detail={'metric': METRIC, 'observed': observed, 'planned': planned,
                                   'spells': totals, 'parts': len(runs)},
                           explanation=f'part {part_index}: {why}')
    despawn_text = (f'direct <= {model["direct_despawn_check_ms"]} ms / '
                    f'channeled <= {model["channeled_despawn_check_ms"]} ms'
                    if model.get('channeled_despawn_check_ms') is not None else
                    f'<= {model["direct_despawn_check_ms"]} ms')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0,
                   detail={'metric': METRIC, 'observed': observed, 'planned': planned,
                           'spells': totals, 'parts': len(runs)},
                   explanation=(f'{observed} of {planned} portals ({len(runs)} part(s)): every portal cast exactly 1 '
                                f'direct spell in {allowed} ({totals}) and disappeared before lifetime '
                                f'{model["lifetime_ms"]} ms ({despawn_text}); control: 0 spawns'))


def portal_single_cast_single_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    return portal_single_cast_verdict(base, [run], model)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return portal_single_cast_scenario(class_file, portal_single_cast_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', KIND)}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: portal_single_cast_single_verdict}
POOLED_JUDGE = portal_single_cast_verdict
