import math
from dataclasses import replace

NAME = 'apply_stamp'
ORDER = 30
KEYS = {'aura', 'window', 'source'}
APPLIED = 'applied'
AFTER_TRIGGER = 'after_trigger'
ANCHOR = 'anchor'
STAMPS = ('cast_count', 'cast_upper', 'read_upper', 'count', 'clock', 'first')
OPEN_STAMPS = ('open_lower', 'open_upper', 'anchor', 'anchor_count')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) - {APPLIED, ANCHOR} != KEYS:
        raise ValueError(f'apply_stamp is {{"aura", "window", "source"}} with an optional "{APPLIED}" and its '
                         f'"{ANCHOR}", not {raw!r}')
    if APPLIED in raw and raw[APPLIED] != AFTER_TRIGGER:
        raise ValueError(f'apply_stamp {APPLIED} is {AFTER_TRIGGER!r} or absent, not {raw[APPLIED]!r}')
    if (APPLIED in raw) != (ANCHOR in raw):
        raise ValueError(f'apply_stamp {APPLIED} {AFTER_TRIGGER!r} and its {ANCHOR} come together')
    if ANCHOR in raw and (isinstance(raw[ANCHOR], bool) or not isinstance(raw[ANCHOR], int) or raw[ANCHOR] <= 0):
        raise ValueError(f'apply_stamp {ANCHOR} is the spell id of a phase aura, not {raw[ANCHOR]!r}')
    aura = raw['aura']
    if isinstance(aura, bool) or not isinstance(aura, int) or aura <= 0:
        raise ValueError(f'apply_stamp aura is a spell id, not {aura!r}')
    window = raw['window']
    if (not isinstance(window, list) or len(window) != 2
            or any(isinstance(bound, bool) or not isinstance(bound, int) for bound in window)
            or not 0 < window[0] <= window[1]):
        raise ValueError(f'apply_stamp window {window!r} needs 0 < low <= high in ms')
    if not isinstance(raw['source'], str) or not raw['source'].strip():
        raise ValueError('apply_stamp source cites the duration and the bound the window excludes')
    parsed = {'aura': aura, 'window': list(window), 'source': raw['source']}
    return {**parsed, APPLIED: AFTER_TRIGGER, ANCHOR: raw[ANCHOR]} if APPLIED in raw else parsed


def after_trigger(value: dict) -> bool:
    return value.get(APPLIED) == AFTER_TRIGGER


def check(spec, value):
    if value is None:
        return
    if spec.game_time is None:
        raise ValueError(f'{spec.spell} apply_stamp brackets the after reading from the game_time stamps')
    if after_trigger(value):
        anchor_aura(spec, value)
        return
    if spec.strike is None or spec.strike.after_trigger_ms is not None:
        raise ValueError(f'{spec.spell} apply_stamp opens its timeline before strikes that land before the trigger')


def labels(spec, value: dict) -> dict[str, str]:
    stamps = (*STAMPS, *OPEN_STAMPS) if after_trigger(value) else STAMPS
    return {stamp: f'{spec.spell} apply_stamp {stamp}' for stamp in stamps}


def applied(spec, value: dict) -> dict:
    return {'event': 'aura_applied', 'spell': value['aura'], 'target_actors': [spec.measure_actor]}


def anchor_aura(spec, value: dict) -> tuple[int, int, str, str]:
    found = [aura for aura in spec.phase_auras if aura[0] == value[ANCHOR]]
    if len(found) != 1 or found[0][1] < 1 or found[0][0] == value['aura']:
        raise ValueError(f'{spec.spell} apply_stamp anchor {value[ANCHOR]} is one phase aura of the entry, set with '
                         f'stacks, other than the stamped aura')
    return found[0]


def anchor_applied(spec, value: dict) -> dict:
    return {'event': 'aura_applied', 'spell': value[ANCHOR], 'target_actors': [anchor_aura(spec, value)[2]]}


def phase_steps(spec, value: dict, after: bool) -> list[dict]:
    from behaviours import CASTER, TAKEN_HIT_STRIKER_ENTRY
    from profile import measurement
    if not after:
        return []
    entry = None if spec.strike is None else spec.strike.striker_entry
    opened = {'action': 'encounter_start', 'actor': CASTER,
              'boss_entry': TAKEN_HIT_STRIKER_ENTRY if entry is None else entry}
    if not after_trigger(value):
        return [opened]
    from behaviours import phase_aura_step
    names = labels(spec, value)
    spell, stacks, on, by = anchor_aura(spec, value)
    return [measurement(names['open_lower'], CASTER, 'game_time_ms'), opened,
            phase_aura_step((spell, 0, on, by)), phase_aura_step((spell, stacks, on, by)),
            measurement(names['open_upper'], CASTER, 'game_time_ms')]


def after_trigger_steps(spec, value: dict, after: bool) -> list[dict]:
    from behaviours import CASTER
    from profile import measurement
    if not after:
        return []
    names = labels(spec, value)
    return [measurement(names['cast_count'], CASTER, 'timeline_count', **applied(spec, value)),
            measurement(names['cast_upper'], CASTER, 'game_time_ms')]


def fixtures(class_file: dict, spec, value: dict, scenario: dict):
    from behaviours import AFTER, CASTER, metric_delta_label
    from profile import measurement
    names = labels(spec, value)
    reads = [measurement(names['read_upper'], CASTER, 'game_time_ms'),
             measurement(names['count'], CASTER, 'timeline_count', **applied(spec, value)),
             measurement(names['clock'], CASTER, 'timeline_first_ms', event='cast', spell=spec.trigger_spell),
             measurement(names['first'], CASTER, 'timeline_first_ms', **applied(spec, value))]
    if after_trigger(value):
        reads += [measurement(names['anchor'], CASTER, 'timeline_first_ms', **anchor_applied(spec, value)),
                  measurement(names['anchor_count'], CASTER, 'timeline_count', **anchor_applied(spec, value))]
    after_label = metric_delta_label(spec, AFTER)
    scenario['steps'] = [step for original in scenario['steps']
                         for step in (original, *(reads if original.get('label') == after_label else ()))]
    low, high = value['window']
    if after_trigger(value):
        scenario['contract'] += (f' Apply stamp (after the trigger): an encounter timeline opened in the after phase, '
                                 f'with the game time read just before it opens and just after the phase aura '
                                 f'{value[ANCHOR]} is removed and set again right after the opening (the anchor), '
                                 f'stamps every apply of {value["aura"]} on the {spec.measure_actor}, the trigger '
                                 f'cast {spec.trigger_spell} and the anchor apply; timeline stamps are compared only '
                                 f'with each other; exactly one apply, none before the trigger cast, none before the '
                                 f'cast completes and exactly one anchor apply before it, else the trial is void; the '
                                 f'after reading is bracketed from that apply, at least the game time just before the '
                                 f'reading minus the upper anchor read and the apply\'s offset from the anchor, and at '
                                 f'most the game time just after the reading minus the lower anchor read and that '
                                 f'offset; '
                                 f'the bracket must lie in {low}..{high} ms ({value["source"]}).')
        return
    scenario['contract'] += (f' Apply stamp: an encounter timeline opened before the after phase\'s strikes stamps '
                             f'every apply of {value["aura"]} on the {spec.measure_actor} and the trigger cast '
                             f'{spec.trigger_spell} in one time base; the after reading is bracketed from the aura '
                             f'apply, at least the game time from just after the trigger cast (no apply after it) '
                             f'and at most the game time from just before it plus the trigger cast minus the first '
                             f'apply; the bracket must lie in {low}..{high} ms ({value["source"]}).')


def model(spec, value: dict) -> dict:
    from behaviours import game_time_labels
    cast, after, _ = game_time_labels(spec)
    return {NAME: {**value, 'stamps': labels(spec, value), 'cast_label': cast, 'after_label': after}}


def finite(values: dict, label: str) -> float | None:
    found = values.get(label)
    return float(found) if found is not None and math.isfinite(float(found)) else None


def verdict(verdict, run, recorded: dict):
    if verdict.status == 'unmeasured':
        return verdict
    stamps = recorded['stamps']
    read = {name: finite(run.values, label) for name, label in
            {**stamps, 'cast_lower': recorded['cast_label'], 'read_lower': recorded['after_label']}.items()}
    missing = [name for name, found in read.items() if found is None]
    if missing:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; apply stamp: {", ".join(missing)} missing')
    if after_trigger(recorded):
        return after_trigger_verdict(verdict, read, recorded)
    if read['count'] < 1:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; apply stamp: no apply of {recorded["aura"]} stamped')
    if read['cast_count'] != read['count']:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; apply stamp: {read["count"] - read["cast_count"]:g} '
                                   f'apply after the trigger cast, so the last apply is not bounded')
    offset = read['clock'] - read['first']
    low = read['read_lower'] - read['cast_upper']
    high = read['read_upper'] - read['cast_lower'] + offset
    window_low, window_high = recorded['window']
    text = (f'{verdict.explanation}; apply stamp: first apply {offset:g} ms before the trigger cast, '
            f'{read["count"]:g} applies, the after reading {low:g}..{high:g} ms after the aura apply (window '
            f'{window_low}..{window_high} ms, {recorded["source"]})')
    detail = {**(verdict.detail or {}), 'apply_bracket': [low, high]}
    if not (window_low <= low and high <= window_high):
        return replace(verdict, status='alert', detail=detail,
                       explanation=f'{text}: the bracket leaves its window, so the duration bound is not proven')
    return replace(verdict, detail=detail, explanation=text)


def after_trigger_verdict(verdict, read: dict, recorded: dict):
    void = None
    if read['cast_count'] != 0:
        void = f'{read["cast_count"]:g} apply of {recorded["aura"]} before the trigger cast'
    elif read['count'] != 1:
        void = f'{read["count"]:g} applies of {recorded["aura"]} after the trigger cast, not exactly one'
    elif read['first'] < read['clock']:
        void = f'the apply lies {read["clock"] - read["first"]:g} ms before the trigger cast completes'
    elif read['anchor_count'] != 1:
        void = f'{read["anchor_count"]:g} applies of the anchor {recorded[ANCHOR]}, not exactly one'
    elif read['first'] < read['anchor']:
        void = f'the apply lies {read["anchor"] - read["first"]:g} ms before the anchor'
    if void is not None:
        return replace(verdict, status='unmeasured',
                       explanation=f'{verdict.explanation}; apply stamp after the trigger: {void}, so the apply is '
                                   f'not bounded')
    offset = read['first'] - read['anchor']
    low = read['read_lower'] - read['open_upper'] - offset
    high = read['read_upper'] - read['open_lower'] - offset
    window_low, window_high = recorded['window']
    text = (f'{verdict.explanation}; apply stamp after the trigger: the apply {read["first"] - read["clock"]:g} ms '
            f'after the trigger cast completes, the after reading {low:g}..{high:g} ms after it (window '
            f'{window_low}..{window_high} ms, {recorded["source"]})')
    detail = {**(verdict.detail or {}), 'apply_bracket': [low, high]}
    if not (window_low <= low and high <= window_high):
        return replace(verdict, status='alert', detail=detail,
                       explanation=f'{text}: the bracket leaves its window, so the duration bound is not proven')
    return replace(verdict, detail=detail, explanation=text)
