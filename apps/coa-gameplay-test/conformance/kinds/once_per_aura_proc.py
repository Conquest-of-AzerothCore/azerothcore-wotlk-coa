from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import (BEHAVIOUR_METRIC_DELTA, STRIKER, MetricDeltaStrike, behaviour_entry, prose_rule,
                        required_aura_steps, striker_creature, waited_ms)
from compare import Run, Verdict, missing_measurement
from hits import timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records, Unreadable
from values import Expectation, dataset, facts_of

KIND = 'once_per_aura_proc'
ORDER = 63
PROC_METRICS = frozenset({'spell_heal_count', 'spell_damage_count', 'spell_energize_count', 'spell_cast_count',
                          'aura_apply_count'})
TARGETED_PROC_METRICS = frozenset({'spell_heal_count', 'spell_damage_count', 'spell_energize_count'})
DEFAULT_PROC_METRIC = 'spell_heal_count'
DEFAULT_WAIT_MS = 300
CAST_SETTLE_MS = 200
MIN_WAIT_MS = 100
DURATION_MARGIN_MS = 1000
FIELDS = frozenset({'spell', 'name', 'kind', 'variant', 'label_suffix', 'quote', 'proc_spell', 'strike_spell',
                    'strike_health', 'strike_max_health', 'cast_power', 'proc_metric', 'striker_entry', 'wait_ms',
                    'caster_auras', 'observe_source'})


@dataclass(frozen=True)
class OncePerAuraProcSpec:
    spell: int
    name: str
    quote: str
    proc_spell: int
    strike_spell: int
    strike_health: int
    strike_max_health: int
    cast_power: int | None = None
    label_suffix: str = 'once_per_aura'
    proc_metric: str = DEFAULT_PROC_METRIC
    striker_entry: int | None = None
    wait_ms: int = DEFAULT_WAIT_MS
    caster_auras: tuple[tuple[int, int], ...] = ()


def positive_int(value, label_name: str, spell: int) -> int:
    if type(value) is not int or value < 1:
        raise ValueError(f'{spell} {KIND} {label_name} must be a positive int, not {value!r}')
    return value


def parse_caster_auras(raw, spell: int) -> tuple[tuple[int, int], ...]:
    if not raw:
        return ()
    parsed = []
    for item in raw:
        if not isinstance(item, (list, tuple)) or len(item) != 2:
            raise ValueError(f'{spell} {KIND} caster_auras items are [spell, stacks], not {item!r}')
        parsed.append((positive_int(item[0], 'caster_auras spell', spell),
                       positive_int(item[1], 'caster_auras stacks', spell)))
    return tuple(parsed)


def once_per_aura_proc_spec(entry: dict) -> OncePerAuraProcSpec:
    unknown = set(entry) - FIELDS
    if unknown:
        raise ValueError(f'{entry.get("spell")} {KIND} unknown fields {sorted(unknown)}')
    spell = positive_int(entry['spell'], 'spell', int(entry['spell']) if isinstance(entry.get('spell'), int) else 0)
    proc_spell = positive_int(entry['proc_spell'], 'proc_spell', spell)
    strike_spell = positive_int(entry['strike_spell'], 'strike_spell', spell)
    strike_health = positive_int(entry['strike_health'], 'strike_health', spell)
    strike_max_health = positive_int(entry['strike_max_health'], 'strike_max_health', spell)
    if strike_health >= strike_max_health:
        raise ValueError(f'{spell} {KIND} needs 0 < strike_health < strike_max_health')
    cast_power = entry.get('cast_power')
    if cast_power is not None and (type(cast_power) is not int or cast_power < 0):
        raise ValueError(f'{spell} {KIND} cast_power must be a non-negative int, not {cast_power!r}')
    proc_metric = entry.get('proc_metric', DEFAULT_PROC_METRIC)
    if proc_metric not in PROC_METRICS:
        raise ValueError(f'{spell} {KIND} proc_metric {proc_metric!r} is not one of {sorted(PROC_METRICS)}')
    striker_entry = entry.get('striker_entry')
    if striker_entry is not None:
        striker_entry = positive_int(striker_entry, 'striker_entry', spell)
    wait_ms = entry.get('wait_ms', DEFAULT_WAIT_MS)
    if type(wait_ms) is not int or wait_ms < MIN_WAIT_MS:
        raise ValueError(f'{spell} {KIND} wait_ms must be an int >= {MIN_WAIT_MS}, not {wait_ms!r}')
    caster_auras = parse_caster_auras(entry.get('caster_auras'), spell)
    return OncePerAuraProcSpec(spell, entry['name'], entry['quote'], proc_spell, strike_spell, strike_health,
                               strike_max_health, cast_power, entry.get('label_suffix', 'once_per_aura'), proc_metric,
                               striker_entry, wait_ms, caster_auras)


def mark(spec: OncePerAuraProcSpec, read: str) -> str:
    return f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix} {read}'


def proc_read(spec: OncePerAuraProcSpec, label_name: str) -> dict:
    fields = {'spell': spec.proc_spell}
    if spec.proc_metric in TARGETED_PROC_METRICS:
        fields['target'] = CASTER
    return measurement(label_name, CASTER, spec.proc_metric, **fields)


def strike_log_read(spec: OncePerAuraProcSpec, label_name: str) -> dict:
    return measurement(label_name, CASTER, 'spell_log_count', spell=spec.strike_spell, caster=STRIKER, target=CASTER)


def once_per_aura_proc_scenario(class_file: dict, spec: OncePerAuraProcSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    entry = behaviour_entry(records, spec.spell, spec.name, KIND, spec.quote, 1.0)
    for named, spell_id in (('proc_spell', spec.proc_spell), ('strike_spell', spec.strike_spell)):
        if not records.has_spell(spell_id):
            raise ValueError(f'{spec.spell} {KIND} unknown {named} {spell_id}')
    spell_facts = facts_of(records, spec.spell)
    if (spell_facts.mana_cost_percentage or spell_facts.mana_cost_per_level) and spec.cast_power is None:
        raise ValueError(f'{spec.spell} {KIND} casts {spec.spell} with a percentage or per-level cost: set cast_power')
    try:
        duration_ms = int(records.duration_ms(spec.spell))
    except Unreadable:
        duration_ms = 0
    if duration_ms > 0 and CAST_SETTLE_MS + 2 * spec.wait_ms + DURATION_MARGIN_MS > duration_ms:
        raise ValueError(f'{spec.spell} {KIND} strikes need {CAST_SETTLE_MS + 2 * spec.wait_ms + DURATION_MARGIN_MS} '
                         f'ms, past {duration_ms} ms duration of {spec.spell}')
    preset_auras = {aura for aura, _ in spec.caster_auras}

    def power_steps() -> list[dict]:
        if spec.cast_power is not None:
            return [{'action': 'set_power', 'actor': CASTER, 'power': spell_facts.power_type, 'value': spec.cast_power}]
        if spell_facts.mana_cost > 0:
            return [{'action': 'set_power', 'actor': CASTER, 'power': spell_facts.power_type,
                     'value': spell_facts.mana_cost}]
        return []

    def cast_aura(tag: str) -> tuple[list[dict], dict[str, str]]:
        reads = {'aura': mark(spec, f'{tag} aura'), 'cast_failure': mark(spec, f'{tag} cast_failure')}
        req_steps = [step for step in required_aura_steps(spell_facts) if step['spell'] not in preset_auras]
        steps = (power_steps()
                 + [{'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.spell}]
                 + req_steps
                 + [{'action': 'cast', 'actor': CASTER, 'spell': spec.spell, 'target': CASTER},
                    {'action': 'wait', 'label': f'{tag} settle', 'ms': CAST_SETTLE_MS},
                    measurement(reads['aura'], CASTER, 'aura', spell=spec.spell),
                    measurement(reads['cast_failure'], CASTER, 'cast_failure', spell=spec.spell)])
        return steps, reads

    def strike_phase(tag: str) -> tuple[list[dict], dict[str, str]]:
        reads = {'logs': mark(spec, f'{tag} logs'), 'aura': mark(spec, f'{tag} aura'),
                 'proc': mark(spec, f'{tag} proc')}
        steps = [{'action': 'set_combat_avoidance', 'actor': CASTER, 'dodge': 0, 'parry': 0, 'block': 0},
                 {'action': 'set_health', 'actor': CASTER, 'value': spec.strike_health,
                  'maximum': spec.strike_max_health},
                 {'action': 'cast', 'actor': STRIKER, 'spell': spec.strike_spell, 'target': CASTER},
                 {'action': 'wait', 'label': f'{tag} strike', 'ms': spec.wait_ms},
                 strike_log_read(spec, reads['logs']),
                 measurement(reads['aura'], CASTER, 'aura', spell=spec.spell),
                 proc_read(spec, reads['proc'])]
        return steps, reads

    baseline_reads = {'logs': mark(spec, 'baseline logs'), 'aura': mark(spec, 'baseline aura'),
                      'proc': mark(spec, 'baseline proc')}
    control_steps, control_reads = strike_phase('control')
    app1_cast_steps, app1_cast_reads = cast_aura('app1_cast')
    hit1_steps, hit1_reads = strike_phase('hit1')
    hit2_steps, hit2_reads = strike_phase('hit2')
    app2_cleared = mark(spec, 'app2 cleared aura')
    app2_cast_steps, app2_cast_reads = cast_aura('app2_cast')
    hit3_steps, hit3_reads = strike_phase('hit3')
    steps = (base_steps(class_file)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spec.spell}]
             + [{'action': 'set_aura', 'actor': CASTER, 'spell': aura, 'stacks': stacks}
                for aura, stacks in spec.caster_auras]
             + [strike_log_read(spec, baseline_reads['logs']),
                measurement(baseline_reads['aura'], CASTER, 'aura', spell=spec.spell),
                proc_read(spec, baseline_reads['proc'])]
             + control_steps
             + app1_cast_steps
             + hit1_steps
             + hit2_steps
             + [{'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.spell},
                measurement(app2_cleared, CASTER, 'aura', spell=spec.spell)]
             + app2_cast_steps
             + hit3_steps)
    fixture_note = ''
    if spec.caster_auras:
        named = ', '.join(f'{aura} x{stacks}' for aura, stacks in spec.caster_auras)
        fixture_note += f' Precondition caster auras set via set_aura: {named}.'
    if spell_facts.caster_aura_spell and spell_facts.caster_aura_spell not in preset_auras:
        fixture_note += (f' CasterAuraSpell {spell_facts.caster_aura_spell} is set via set_aura before each cast of '
                         f'{spec.spell} as a precondition fixture.')
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour once per aura proc',
        'contract': (f'Once-per-aura-application proc check for {spec.spell} triggering {spec.proc_spell} '
                     f'({spec.proc_metric}) on incoming {spec.strike_spell} strikes at caster health '
                     f'{spec.strike_health}/{spec.strike_max_health} (regeneration off, avoidance 0).{fixture_note} '
                     f'Control strike before casting {spec.spell} must land with 0 procs. Application 1 casts '
                     f'{spec.spell}: hit 1 must land with {spec.spell} still active and +1 proc; resetting health and '
                     f'landing hit 2 inside the same {spec.spell} application must keep {spec.spell} active with +0 '
                     f'procs. Cancelling and re-casting {spec.spell} (Application 2) then landing hit 3 must produce '
                     f'+1 proc (total 2), proving per-application once-only gating that resets on reapplication.'),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [striker_creature(class_file, MetricDeltaStrike(spec.strike_spell, spec.strike_health,
                                                                     spec.strike_max_health,
                                                                     striker_entry=spec.striker_entry))],
        'steps': steps}
    reads = {'baseline': baseline_reads, 'control': control_reads, 'app1_cast': app1_cast_reads,
             'hit1': hit1_reads, 'hit2': hit2_reads, 'app2_cleared': app2_cleared,
             'app2_cast': app2_cast_reads, 'hit3': hit3_reads}
    model = {'kind': KIND, 'metric': spec.proc_metric, 'quote': entry.quote, 'spell': spec.spell,
             'proc_spell': spec.proc_spell, 'strike_spell': spec.strike_spell, 'reads': reads}
    expectation = Expectation(mark(spec, '').rstrip(), BEHAVIOUR_METRIC_DELTA, spec.spell, spec.proc_spell, None,
                              '1 per application (control 0, hit1 +1, hit2 +0, hit3 +1)',
                              prose_rule(entry.quote, spec.spell), model)
    return timed(scenario, waited_ms(steps)), [expectation]


def collect_labels(reads: dict) -> list[str]:
    found = []
    for value in reads.values():
        if isinstance(value, dict):
            found.extend(value.values())
        else:
            found.append(value)
    return found


def once_per_aura_proc_verdict(base: Verdict, run: Run, model: dict) -> Verdict:
    reads = model['reads']
    missing = next((lbl for lbl in collect_labels(reads) if run.values.get(lbl) is None), None)
    if missing is not None:
        return replace(base, status='unmeasured', explanation=missing_measurement(run, missing))
    val = run.values
    b_logs, b_aura, b_proc = val[reads['baseline']['logs']], val[reads['baseline']['aura']], val[reads['baseline']['proc']]
    c_logs, c_aura, c_proc = val[reads['control']['logs']], val[reads['control']['aura']], val[reads['control']['proc']]
    a1_aura, a1_fail = val[reads['app1_cast']['aura']], val[reads['app1_cast']['cast_failure']]
    h1_logs, h1_aura, h1_proc = val[reads['hit1']['logs']], val[reads['hit1']['aura']], val[reads['hit1']['proc']]
    h2_logs, h2_aura, h2_proc = val[reads['hit2']['logs']], val[reads['hit2']['aura']], val[reads['hit2']['proc']]
    a2_clear = val[reads['app2_cleared']]
    a2_aura, a2_fail = val[reads['app2_cast']['aura']], val[reads['app2_cast']['cast_failure']]
    h3_logs, h3_aura, h3_proc = val[reads['hit3']['logs']], val[reads['hit3']['aura']], val[reads['hit3']['proc']]
    detail = {'metric': model['metric'], 'control_delta': c_proc - b_proc, 'hit1_delta': h1_proc - c_proc,
              'hit2_delta': h2_proc - h1_proc, 'hit3_delta': h3_proc - h2_proc,
              'auras': {'control': c_aura, 'app1_cast': a1_aura, 'hit1': h1_aura, 'hit2': h2_aura,
                        'app2_cleared': a2_clear, 'app2_cast': a2_aura, 'hit3': h3_aura},
              'strike_deltas': [c_logs - b_logs, h1_logs - c_logs, h2_logs - h1_logs, h3_logs - h2_logs]}
    if b_aura != 0 or b_proc != 0:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'baseline not clean: aura={b_aura:g}, proc={b_proc:g}')
    if detail['strike_deltas'] != [1.0, 1.0, 1.0, 1.0]:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'strike {model["strike_spell"]} log deltas {detail["strike_deltas"]}, expected '
                                   f'[1, 1, 1, 1] (a strike missed or was avoided)')
    if c_aura != 0 or a1_fail != 0 or a1_aura != 1 or a2_clear != 0 or a2_fail != 0 or a2_aura != 1:
        return replace(base, status='unmeasured', detail=detail,
                       explanation=f'aura cast precondition failed: control_aura={c_aura:g}, app1_fail={a1_fail:g}, '
                                   f'app1_aura={a1_aura:g}, cleared={a2_clear:g}, app2_fail={a2_fail:g}, '
                                   f'app2_aura={a2_aura:g}')
    if detail['control_delta'] != 0:
        return replace(base, status='alert', measured=detail['control_delta'], expected=0.0, detail=detail,
                       explanation=f'control fired {detail["control_delta"]:g} proc(s) of {model["proc_spell"]} '
                                   f'without {model["spell"]} active')
    if h1_aura != 1 or detail['hit1_delta'] != 1:
        return replace(base, status='alert', measured=detail['hit1_delta'], expected=1.0, detail=detail,
                       explanation=f'application 1 hit 1: aura={h1_aura:g} (expected 1), proc delta='
                                   f'{detail["hit1_delta"]:g} (expected 1)')
    if h2_aura != 1 or detail['hit2_delta'] != 0:
        return replace(base, status='alert', measured=detail['hit2_delta'], expected=0.0, detail=detail,
                       explanation=f'application 1 hit 2 (same aura): aura={h2_aura:g} (expected 1), proc delta='
                                   f'{detail["hit2_delta"]:g} (expected 0)')
    if h3_aura != 1 or detail['hit3_delta'] != 1:
        return replace(base, status='alert', measured=detail['hit3_delta'], expected=1.0, detail=detail,
                       explanation=f'application 2 hit 3 (reapplied aura): aura={h3_aura:g} (expected 1), proc delta='
                                   f'{detail["hit3_delta"]:g} (expected 1)')
    return replace(base, status='ok', measured=1.0, expected=1.0, low=1.0, high=1.0, detail=detail,
                   explanation=f'{model["proc_spell"]} ({model["metric"]}) deltas across 4 landed '
                               f'{model["strike_spell"]} strikes: control 0, app1 hit1 +1 (aura 1), app1 hit2 +0 '
                               f'(aura 1), app2 hit3 +1 after cancel+recast (aura 1)')


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return once_per_aura_proc_scenario(class_file, once_per_aura_proc_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} {BEHAVIOUR_METRIC_DELTA} {entry.get('label_suffix', 'once_per_aura')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: once_per_aura_proc_verdict}
