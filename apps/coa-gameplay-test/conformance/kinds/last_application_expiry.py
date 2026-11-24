import math
from dataclasses import dataclass, replace
from pathlib import Path

from behaviours import BEHAVIOUR_METRIC_DELTA, behaviour_entry, cleaned_tooltip, prose_rule, waited_ms
from bonus import bonus_band
from hits import MAX_ACCELERATED_SCENARIO_MS, creature_fixture, timed
from profile import CASTER, DBC_DIR, base_steps, measurement, player_fixture
from tooltip import Records
from values import (DUMMY_ENTRY, Expectation, FORCE_CRIT_RATINGS, FORCED_CRIT_RATING, GCD_WAIT_MS, TARGET, dataset,
                    facts_of)

KIND = 'last_application_expiry'
ORDER = 22

LAST_APPLICATION_STEP_OVERHEAD_MS = 9
FEED_STAMP_MS = 100
FEED_RESIDUAL = 0.0005
FEED_STAMPS = ('applies', 'first')
FORCE_HIT_RATINGS = {'melee': 'melee_hit_rating', 'spell': 'spell_hit_rating', 'ranged': 'ranged_hit_rating'}
ARMS = ('control', 'treatment')


@dataclass(frozen=True)
class LastApplicationSpec:
    spell: int
    name: str
    quote: str
    gate_spell: int
    trigger_spell: int
    aura: int
    expected_ms: int
    control_window_ms: int
    window_ms: int
    trigger_power: int | None = None
    poll_ms: int = 50
    label_suffix: str = 'last_application_expiry'
    caster: bool = False
    repeat: tuple[int, int] | None = None
    no_refresh: bool = False
    forced_roll: int | None = None
    feed_every_ms: int | None = None
    feed_stop_aura: int | None = None
    force_crit: str | None = None
    quote_spell: int | None = None
    trigger_target: str = TARGET
    poll_before_cast: bool = False
    same_stamp_applies: bool = False


AURA_HOLDERS = {False: TARGET, True: CASTER}


def last_application_spec(entry: dict) -> LastApplicationSpec:
    spec = LastApplicationSpec(int(entry['spell']), entry['name'], entry['quote'], int(entry['gate_spell']),
                               int(entry['trigger_spell']), int(entry['aura']), int(entry['expected_ms']),
                               int(entry['control_window_ms']), int(entry['window_ms']),
                               int(entry['trigger_power']) if entry.get('trigger_power') is not None else None,
                               int(entry.get('poll_ms', 50)), entry.get('label_suffix', 'last_application_expiry'),
                               entry.get('caster', False), repeat_of(entry.get('repeat')),
                               entry.get('no_refresh', False),
                               None if entry.get('forced_roll') is None else int(entry['forced_roll']),
                               *feed_of(entry),
                               entry.get('force_crit'),
                               int(entry['quote_spell']) if 'quote_spell' in entry else None,
                               entry.get('trigger_target', TARGET), entry.get('poll_before_cast', False),
                               entry.get('same_stamp_applies', False))
    if spec.trigger_target not in (TARGET, CASTER):
        raise ValueError(f'{spec.spell} last_application_expiry casts its trigger at {TARGET} or {CASTER}')
    if not all(isinstance(flag, bool) for flag in (spec.caster, spec.no_refresh, spec.poll_before_cast,
                                                   spec.same_stamp_applies)):
        raise ValueError(f'{spec.spell} last_application_expiry caster, no_refresh, poll_before_cast and '
                         f'same_stamp_applies are true or false')
    if spec.same_stamp_applies and spec.feed_every_ms is None:
        raise ValueError(f'{spec.spell} last_application_expiry accepts same-stamp applies only on a stamped feed')
    if spec.no_refresh and spec.repeat is None:
        raise ValueError(f'{spec.spell} last_application_expiry judges no refresh only over repeated trigger casts')
    if spec.forced_roll is not None and spec.repeat is None:
        raise ValueError(f'{spec.spell} last_application_expiry forces the roll only over repeated trigger casts')
    if spec.force_crit is not None and spec.force_crit not in FORCE_CRIT_RATINGS:
        raise ValueError(f'{spec.spell} last_application_expiry force_crit is one of {sorted(FORCE_CRIT_RATINGS)}, '
                         f'not {spec.force_crit!r}')
    if spec.feed_every_ms is not None:
        if spec.repeat is not None or spec.forced_roll is not None or spec.no_refresh:
            raise ValueError(f'{spec.spell} last_application_expiry feeds the trigger instead of repeat, forced_roll '
                             f'and no_refresh')
        if spec.feed_stop_aura is None and not spec.caster:
            raise ValueError(f'{spec.spell} last_application_expiry feed stops on an aura of the caster: name '
                             f'stop_aura when the judged aura is on the dummy')
        if spec.feed_every_ms < GCD_WAIT_MS:
            raise ValueError(f'{spec.spell} last_application_expiry feed casts at least {GCD_WAIT_MS} ms apart')
    if spec.repeat is not None and spec.repeat[0] * spec.repeat[1] >= spec.expected_ms:
        raise ValueError(f'{spec.spell} last_application_expiry repeats its trigger past the stated duration')
    if spec.poll_ms < 10 or spec.expected_ms <= 0 or spec.window_ms <= spec.expected_ms + bonus_band(spec.expected_ms):
        raise ValueError(f'{spec.spell} last_application_expiry polls at least every 10 ms over a window longer than '
                         f'the stated duration and its band')
    if spec.control_window_ms < spec.poll_ms:
        raise ValueError(f'{spec.spell} last_application_expiry needs a control window of at least one poll')
    return spec


def feed_of(entry: dict) -> tuple[int | None, int | None]:
    raw = entry.get('feed')
    if raw is None:
        return None, None
    if not isinstance(raw, dict) or not {'every_ms'} <= set(raw) <= {'every_ms', 'stop_aura'} or not all(
            isinstance(value, int) and not isinstance(value, bool) and value > 0 for value in raw.values()):
        raise ValueError(f'last_application_expiry feed is {{"every_ms": ms, "stop_aura": spell}} (stop_aura '
                         f'optional), not {raw!r}')
    return raw['every_ms'], raw.get('stop_aura')


def feed_casts(records: Records, spec: LastApplicationSpec) -> int:
    chance = records.field('Spell', spec.gate_spell, 'ProcChance') / 100
    if not 0 < chance < 1:
        raise ValueError(f'{spec.spell} last_application_expiry feed needs a gate spell {spec.gate_spell} with a '
                         f'proc chance between 0 and 100%')
    return math.ceil(math.log(FEED_RESIDUAL) / math.log(1 - chance))


def repeat_of(raw) -> tuple[int, int] | None:
    if raw is None:
        return None
    if not isinstance(raw, dict) or set(raw) != {'count', 'every_ms'} or not all(
            isinstance(raw[key], int) and not isinstance(raw[key], bool) and raw[key] > 0 for key in raw):
        raise ValueError(f'last_application_expiry repeat is {{"count": casts, "every_ms": ms}}, not {raw!r}')
    return raw['count'], raw['every_ms']


def last_application_label(spec: LastApplicationSpec, read: str) -> str:
    return f'{spec.spell} {spec.label_suffix} {read}'


def last_application_scenario(class_file: dict, spec: LastApplicationSpec) -> tuple[dict, list[Expectation]]:
    records = Records(dataset(Path(class_file.get('dbc_dir', DBC_DIR))))
    quoted = spec.spell
    if spec.quote_spell is not None and spec.quote_spell != spec.spell:
        if f'@s:{spec.quote_spell}:' not in cleaned_tooltip(records, spec.spell):
            raise ValueError(f'{spec.spell} last_application_expiry quotes {spec.quote_spell}, whose tooltip the '
                             f'{spec.spell} tooltip does not embed')
        quoted = spec.quote_spell
    entry = behaviour_entry(records, quoted, spec.name, KIND, spec.quote, float(spec.expected_ms))
    facts = facts_of(records, spec.trigger_spell)
    reads = {}
    feeding = spec.feed_every_ms is not None
    max_casts = feed_casts(records, spec) if feeding else 0
    stop_aura = (spec.feed_stop_aura or spec.aura) if feeding else None
    feed_reads = {}

    def arm(name: str, window_ms: int) -> list[dict]:
        power = spec.trigger_power if spec.trigger_power is not None else facts.mana_cost
        cast = {'action': 'cast', 'actor': CASTER, 'spell': spec.trigger_spell, 'target': spec.trigger_target}
        steps = [{'action': 'wait', 'label': f'{name} before the cast', 'ms': GCD_WAIT_MS},
                 {'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power},
                 {'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.trigger_spell},
                 {'action': 'select', 'actor': CASTER, 'target': TARGET}]
        rows, elapsed = [], 0
        holder = AURA_HOLDERS[spec.caster]
        reads_of = ('time', 'applied', 'aura', 'stacks') if spec.no_refresh else ('time', 'applied', 'aura')
        recasts = [every * index for count, every in [spec.repeat or (0, 0)] for index in range(1, count)]

        def poll() -> list[dict]:
            row = [last_application_label(spec, f'{name} {len(rows)} {read}') for read in reads_of]
            rows.append(row)
            reads = [measurement(row[0], CASTER, 'game_time_ms'),
                     measurement(row[1], holder, 'aura_apply_count', spell=spec.aura),
                     measurement(row[2], holder, 'aura', spell=spec.aura)]
            return reads + ([measurement(row[3], holder, 'aura_stacks', spell=spec.aura)] if spec.no_refresh else [])

        stamped = feeding and name == ARMS[1]
        if stamped:
            start = last_application_label(spec, f'{name} timeline start')
            steps += [measurement(start, CASTER, 'game_time_ms'),
                      {'action': 'encounter_start', 'actor': CASTER, 'boss_entry': DUMMY_ENTRY}]
        if spec.no_refresh or feeding or spec.poll_before_cast:
            steps += poll()
        if feeding:
            stop = last_application_label(spec, f'{name} stop')
            remaining = last_application_label(spec, f'{name} remaining')
            feed_reads[name] = {'stop': stop, 'remaining': remaining}
            steps += [{'action': 'cast_until_aura', 'label': last_application_label(spec, f'{name} feed'),
                       'actor': CASTER, 'spell': spec.trigger_spell, 'target': TARGET, 'aura': stop_aura,
                       'every_ms': spec.feed_every_ms, 'max_casts': max_casts, 'cast_power': power,
                       'power': facts.power_type, 'reset_cooldown': True},
                      measurement(stop, CASTER, 'aura', spell=stop_aura),
                      measurement(remaining, holder, 'aura_duration_ms', spell=spec.aura)]
        else:
            steps.append(cast)
        if stamped:
            applied = {'event': 'aura_applied', 'spell': spec.aura, 'target_actors': [holder]}
            stamps = {stamp: last_application_label(spec, f'{name} timeline {stamp}') for stamp in FEED_STAMPS}
            feed_reads[name] |= {'stamps': {'start': start, **stamps}}
            steps += [measurement(stamps['applies'], CASTER, 'timeline_count', **applied),
                      measurement(stamps['first'], CASTER, 'timeline_first_ms', **applied)]
        while elapsed <= window_ms:
            while recasts and recasts[0] <= elapsed:
                recasts.pop(0)
                if spec.forced_roll is not None:
                    steps.append({'action': 'set_power', 'actor': CASTER, 'power': facts.power_type, 'value': power})
                steps.append(dict(cast))
            steps += poll() + [{'action': 'wait', 'label': f'{name} poll', 'ms': spec.poll_ms}]
            elapsed += spec.poll_ms + LAST_APPLICATION_STEP_OVERHEAD_MS
        reads[name] = rows
        return steps

    cleared = [{'action': 'cancel_aura', 'actor': CASTER, 'spell': aura}
               for aura in dict.fromkeys((stop_aura, spec.aura)) if feeding and (aura == stop_aura or spec.caster)]
    steps = (base_steps(class_file)
             + ([{'action': 'learn', 'actor': CASTER, 'spell': spec.trigger_spell}] if feeding else [])
             + arm(ARMS[0], spec.control_window_ms)
             + [{'action': 'learn', 'actor': CASTER, 'spell': spell}
                for spell in dict.fromkeys((spec.gate_spell, spec.trigger_spell))]
             + cleared
             + arm(ARMS[1], spec.window_ms))
    scenario = {
        'schema': 1,
        'name': f'Conformance {class_file["name"]} {spec.name} {spec.spell} behaviour last application expiry',
        'contract': (f'{spec.trigger_spell} cast at the dummy before {spec.gate_spell} is learned (control: refused, '
                     f'no {spec.aura}) and after it; every {spec.poll_ms} ms the game time, the dummy\'s '
                     f'{spec.aura} application count (every new aura and every refresh) and its presence are read. '
                     f'The last application lies between the two reads where the count last rises; from there the '
                     f'aura must be gone after {spec.expected_ms} ms, the stamped bracket inside the G-19 band.'),
        'players': [{**player_fixture(class_file), 'allow_regeneration': False}],
        'creatures': [creature_fixture(class_file)],
        'steps': steps}
    if spec.forced_roll is not None:
        from metric_delta_options import forced_roll
        forced_roll.fixtures(class_file, spec, forced_roll.ForcedRoll(spec.forced_roll), scenario)
    if spec.force_crit is not None:
        scenario['players'][0][FORCE_CRIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
        scenario['players'][0][FORCE_HIT_RATINGS[spec.force_crit]] = FORCED_CRIT_RATING
        scenario['contract'] += (f' The {FORCE_CRIT_RATINGS[spec.force_crit]} and {FORCE_HIT_RATINGS[spec.force_crit]} '
                                 f'fixtures are {FORCED_CRIT_RATING}, so every cast lands and is critical, in both '
                                 f'arms.')
    if spec.caster:
        scenario['contract'] += ' The aura is read on the caster, not the dummy.'
    if feeding:
        scenario['contract'] = scenario['contract'].replace(
            f'cast at the dummy before {spec.gate_spell} is learned (control: refused, no {spec.aura}) and after it',
            f'known in both arms; {spec.gate_spell} is learned after the control arm (control: no {spec.aura})')
        scenario['contract'] += (
            f' The cast_until_aura step casts it every {spec.feed_every_ms} ms (power and cooldown reset before each '
            f'cast), at most {max_casts} casts per arm, until {stop_aura} is on the caster: one roll per cast at the '
            f'ProcChance of {spec.gate_spell} leaves at most {FEED_RESIDUAL:.2%} of a run without the grant after '
            f'{max_casts} casts. Before the measured arm {stop_aura} is cancelled on the caster, the aura and its '
            f'application count are read, and nothing is cast but the loop, which stops at the first grant, so no '
            f'earlier grant is on. A loop that reaches its cap leaves the arm unmeasured. The grant is at most '
            f'{FEED_STAMP_MS} ms before the first poll after the loop, the remaining duration is read right after '
            f'the stop, and the expected duration is the DBC one. An encounter timeline opened before the measured '
            f'feed (after a game time read) stamps every apply of {spec.aura} on the holder in the game time base: '
            f'the aura\'s age at the first read after the loop is at most that read minus the start read and the '
            f'first apply stamp; above {FEED_STAMP_MS} ms, without a stamp, or with any count of stamped applies '
            f'but one (a refresh or a second apply leaves the last application unstamped), the arm is unmeasured. '
            f'The timeline is process global, so the scenario runs exclusive in a batch.')
    if spec.same_stamp_applies:
        scenario['contract'] += (
            f' Two or more stamped applies are accepted only when the run\'s recorded timeline holds exactly that '
            f'many aura_applied events of {spec.aura} on the holder, all at one game time; the age is then taken '
            f'from that shared stamp. Applies at different game times, a count that differs from the stamped one or '
            f'no recorded timeline leave the arm unmeasured.')
    if spec.trigger_target == CASTER:
        scenario['contract'] += f' {spec.trigger_spell} is cast at the caster, not the dummy.'
    if spec.repeat is not None:
        scenario['contract'] += (f' {spec.trigger_spell} is cast up to {spec.repeat[0]} times per arm (inside its '
                                 f'poll window), {spec.repeat[1]} ms apart.')
    if spec.poll_before_cast and not spec.no_refresh:
        scenario['contract'] += (' One poll precedes the cast, so an application at the cast itself is seen as a '
                                 'rise from that read.')
    if spec.no_refresh:
        scenario['contract'] += (' Its stack count is read at every poll, and one poll precedes the first cast: no '
                                 'refresh means one counted application while the stacks still rise, the duration '
                                 'timed from that first application.')
    model = {'kind': KIND, 'metric': 'aura_apply_count', 'quote': entry.quote, 'reads': reads,
             'expected': spec.expected_ms}
    if spec.no_refresh:
        model['no_refresh'] = True
    if feeding:
        model['feed'] = {'reads': feed_reads, 'max_casts': max_casts, 'stop_aura': stop_aura,
                         'stamp_ms': FEED_STAMP_MS}
        if spec.same_stamp_applies:
            model['feed']['same_stamp'] = {'aura': spec.aura, 'holder': AURA_HOLDERS[spec.caster]}
    if spec.forced_roll is not None:
        from metric_delta_options import forced_roll
        model['forced_roll'] = {'talent': spec.forced_roll, 'released_label': forced_roll.released_label(spec)}
    expectation = Expectation(f'{spec.spell} {BEHAVIOUR_METRIC_DELTA} {spec.label_suffix}', BEHAVIOUR_METRIC_DELTA,
                              spec.spell, spec.aura, None, str(spec.expected_ms), prose_rule(entry.quote, spec.spell),
                              model)
    if feeding:
        return (timed(scenario, waited_ms(steps) + len(ARMS) * max_casts * spec.feed_every_ms,
                      MAX_ACCELERATED_SCENARIO_MS), [expectation])
    return timed(scenario, waited_ms(steps)), [expectation]


def last_application_bracket(rows: list[tuple[float, float, float]]) -> tuple[float, float] | str:
    rises = [index for index in range(1, len(rows)) if rows[index][1] > rows[index - 1][1]]
    if not rises:
        return 'no application is seen after the cast'
    last = rises[-1]
    if not rows[last][2]:
        return 'the aura is absent at the read of its last application'
    gone = next((index for index in range(last + 1, len(rows)) if not rows[index][2]), None)
    if gone is None:
        return f'the aura is still on {rows[-1][0] - rows[last][0]:g} ms after its last application'
    return rows[gone - 1][0] - rows[last][0], rows[gone][0] - rows[last - 1][0]


def no_refresh_reading(rows: list[tuple[float, ...]]) -> str:
    applications = rows[-1][1] - rows[0][1]
    stacks = max(row[3] for row in rows)
    if applications > 1:
        return f'alert: {applications:g} counted applications, so a later one refreshed or reapplied the aura'
    if stacks < 2:
        return f'unmeasured: the stacks reached {stacks:g}, so no later application was seen to keep the duration'
    return f'one counted application while the stacks rose to {stacks:g} (no refresh)'


def last_application_verdict(base, run, model: dict):
    verdict = last_application_reading(base, run, model)
    roll = model.get('forced_roll')
    if roll is None:
        return verdict
    released = run.values.get(roll['released_label'])
    fixture = f'forcing fixture: a {roll["talent"]} SPELLMOD_CHANCE_OF_SUCCESS spell modifier mutant'
    if released is None or released != 0:
        return replace(verdict, status='alert', explanation=f'{verdict.explanation}; {fixture}: the modifier is still '
                                                            f'active at the end ({released})')
    return replace(verdict, explanation=f'{verdict.explanation}; {fixture}, released at the end')


def same_stamp_applies(run, same: dict | None, applies: float) -> tuple[bool, str]:
    if same is None or applies < 2:
        return False, ''
    stamps = [event.get('at_ms') for event in getattr(run, 'timeline', ())
              if event.get('event') == 'aura_applied' and str(event.get('spell')) == str(same['aura'])
              and event.get('target') == same['holder']]
    if not stamps:
        return False, ' (no recorded timeline)'
    if len(stamps) != applies:
        return False, f' ({len(stamps)} recorded applies of the aura on the {same["holder"]})'
    if len(set(stamps)) != 1:
        return False, f' (recorded at {", ".join(dict.fromkeys(str(stamp) for stamp in stamps))} ms)'
    return True, f'; {applies:g} stamped applies at one game time ({stamps[0]} ms), judged from that stamp'


def fed_age_void(run, stamps: dict, first_read: float, remaining: float, stamp_ms: float,
                 same: dict | None = None) -> str:
    read = {name: run.values.get(label) for name, label in stamps.items()}
    unreadable = [name for name, value in read.items() if value is None or not math.isfinite(float(value))]
    if unreadable or remaining <= 0:
        return (f'treatment: the aura\'s age at the first read is unreadable ({", ".join(unreadable) or "no aura"} at '
                f'the stop), so the stamped bracket is not proven')
    accepted, note = same_stamp_applies(run, same, read['applies'])
    if read['applies'] != 1 and not accepted:
        return (f'treatment: {read["applies"]:g} stamped applies, not one{" at one game time" if same else ""}'
                f'{note}, so the last application is not the stamped one and the stamped bracket is not proven')
    age = first_read - read['start'] - read['first']
    if age > stamp_ms:
        return (f'treatment: the aura is up to {age:g} ms old at the first read, above {stamp_ms:g} ms, so the '
                f'stamped bracket is not proven')
    return ''


def last_application_reading(base, run, model: dict):
    from compare import missing_measurement
    feed = model.get('feed')
    labels = [label for rows in model['reads'].values() for row in rows for label in row]
    labels += [label for reads in feed['reads'].values() for key, label in reads.items() if key != 'stamps'] \
        if feed else []
    missing = next((label for label in labels if run.values.get(label) is None), None)
    if missing is not None:
        return replace(base, explanation=missing_measurement(run, missing))
    rows = {name: [tuple(run.values[label] for label in row) for row in model['reads'][name]] for name in ARMS}
    expected = float(model['expected'])
    band = bonus_band(expected)
    control = rows['control']
    if control[-1][1] != control[0][1] or any(row[2] for row in control):
        return replace(base, status='alert', explanation='the control arm applied the aura without the gate')
    treatment, fed, age_void = rows['treatment'], '', ''
    if feed:
        reads = feed['reads']['treatment']
        stop, remaining = run.values[reads['stop']], run.values[reads['remaining']]
        if treatment[0][2]:
            return replace(base, status='unmeasured', explanation='treatment: the aura is on before the feed')
        if not stop:
            return replace(base, status='unmeasured',
                           explanation=f'treatment: the feed reached its cap of {feed["max_casts"]} casts without '
                                       f'{feed["stop_aura"]} (a void trial, neither a pass nor a fail)')
        treatment = [(treatment[1][0] - feed['stamp_ms'], *treatment[0][1:])] + treatment[1:]
        fed = f'; fed until {feed["stop_aura"]} at the stop, {remaining:g} ms left on the aura then'
        age_void = fed_age_void(run, reads['stamps'], treatment[1][0], remaining, feed['stamp_ms'],
                                feed.get('same_stamp'))
        if not age_void:
            fed += same_stamp_applies(run, feed.get('same_stamp'), run.values[reads['stamps']['applies']])[1]
    refresh = no_refresh_reading(rows['treatment']) if model.get('no_refresh') else ''
    if refresh.startswith('alert'):
        return replace(base, status='alert', explanation=f'treatment: {refresh[len("alert: "):]}')
    if refresh.startswith('unmeasured'):
        return replace(base, status='unmeasured', explanation=f'treatment: {refresh[len("unmeasured: "):]}')
    bracket = last_application_bracket([row[:3] for row in treatment])
    if isinstance(bracket, str):
        held = treatment[-1][0] - treatment[0][0]
        status = 'alert' if bracket.startswith('the aura is still on') and held > expected + band else 'unmeasured'
        return replace(base, status=status, explanation=f'treatment: {bracket}')
    low, high = bracket
    applications = treatment[-1][1] - treatment[0][1]
    if expected - band <= low and high <= expected + band:
        if age_void:
            return replace(base, status='unmeasured', explanation=age_void)
        status = 'ok'
    elif high < expected - band or low > expected + band:
        status = 'alert'
    else:
        status = 'unmeasured'
    return replace(base, status=status, measured=(low + high) / 2, expected=expected, low=expected - band,
                   high=expected + band,
                   explanation=f'{applications:g} applications; the aura lasted between {low:g} and {high:g} ms after '
                               f'the last one against {expected:g} +- {band:g} (stamped game time); control: none'
                               + (f'; {refresh}' if refresh else '') + fed)


def scenario(class_file: dict, entry: dict) -> tuple[dict, list[Expectation]]:
    return last_application_scenario(class_file, last_application_spec(entry))


def label(entry: dict) -> list[str]:
    return [f"{entry['spell']} behaviour_metric_delta {entry.get('label_suffix', 'last_application_expiry')}"]


JUDGES = {BEHAVIOUR_METRIC_DELTA: last_application_verdict}
