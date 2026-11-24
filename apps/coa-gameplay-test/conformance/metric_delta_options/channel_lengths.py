from dataclasses import replace

NAME = 'channel_lengths'
ORDER = 42
FIELDS = {'spell', 'events', 'cancel_ms', 'repeats'}
PLAIN = {'critical': False, 'resisted': False, 'blocked': False}
READS = (('total', 'spell_damage_total', PLAIN), ('plain', 'spell_damage_count', PLAIN),
         ('struck', 'spell_damage_count', {}))
FULL = 'full'


def positive(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool) and value > 0


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) != FIELDS or not all(positive(raw[key]) for key in
                                                                  ('spell', 'events', 'repeats')) \
            or not isinstance(raw['cancel_ms'], list) or len(raw['cancel_ms']) < 2 \
            or not all(positive(ms) for ms in raw['cancel_ms']) \
            or any(low >= high for low, high in zip(raw['cancel_ms'], raw['cancel_ms'][1:])):
        raise ValueError(f'channel_lengths is {{"spell": end spell, "events": hits per channel, "cancel_ms": [at '
                         f'least 2 rising times], "repeats": casts per length}}, positive integers, not {raw!r}')
    return {**raw, 'cancel_ms': tuple(raw['cancel_ms'])}


def check(spec, lengths):
    if lengths is None:
        return
    if lengths['cancel_ms'][-1] >= spec.wait_ms:
        raise ValueError(f'{spec.spell} channel_lengths cancels inside the {spec.wait_ms} ms wait after the cast, '
                         f'not at {list(lengths["cancel_ms"])}')
    if spec.target != 'dummy' or dict(spec.options).get('area_dummies'):
        raise ValueError(f'{spec.spell} channel_lengths reads the end spell on the dummy alone')


def arms(lengths: dict) -> list:
    return [*lengths['cancel_ms'], FULL]


def read_label(spec, arm, repeat: int, read: str) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, "after")} channel {arm} {repeat} {read}'


def reads(spec, lengths: dict, arm, repeat: int) -> list[dict]:
    from profile import CASTER, measurement
    return [measurement(read_label(spec, arm, repeat, read), CASTER, metric, spell=lengths['spell'],
                        target=spec.target, **filters) for read, metric, filters in READS]


def cancelled(spec, block: list[dict], cancel_ms: int) -> list[dict]:
    from profile import CASTER
    casts = [index for index, step in enumerate(block) if step.get('action') == 'cast'
             and step.get('actor') == CASTER and step.get('spell') == spec.trigger_spell]
    if len(casts) != 1 or casts[0] + 1 >= len(block) or block[casts[0] + 1].get('action') != 'wait' \
            or block[casts[0] + 1].get('ms') != spec.wait_ms:
        raise ValueError(f'{spec.spell} channel_lengths needs one cast of {spec.trigger_spell} followed by its '
                         f'{spec.wait_ms} ms wait in the treatment phase')
    wait = casts[0] + 1
    return [dict(step) for step in block[:wait]] + [
        {'action': 'wait', 'ms': cancel_ms},
        {'action': 'cancel_aura', 'actor': CASTER, 'spell': spec.trigger_spell},
        {'action': 'wait', 'ms': spec.wait_ms - cancel_ms}] + [dict(step) for step in block[wait + 1:]]


def fixtures(class_file: dict, spec, lengths: dict, scenario: dict):
    from metric_delta_options.target_order import treatment_block
    steps = scenario['steps']
    start, end, block = treatment_block(spec, steps)
    cancelled(spec, block, lengths['cancel_ms'][0])
    added = reads(spec, lengths, FULL, 1)
    for repeat in range(2, lengths['repeats'] + 1):
        added += [dict(step) for step in block] + reads(spec, lengths, FULL, repeat)
    for cancel_ms in lengths['cancel_ms']:
        for repeat in range(1, lengths['repeats'] + 1):
            added += cancelled(spec, block, cancel_ms) + reads(spec, lengths, cancel_ms, repeat)
    scenario['steps'] = (steps[:start] + reads(spec, lengths, 'base', 0) + steps[start:end + 1] + added
                         + steps[end + 1:])
    scenario['contract'] += (f' The treatment cast of {spec.trigger_spell} is repeated {lengths["repeats"]} times '
                             f'as a full channel and {lengths["repeats"]} times per early end, the channel cancelled '
                             f'(cancel_aura) {list(lengths["cancel_ms"])} ms after the cast; after each cast the '
                             f'damage of {lengths["spell"]} on the dummy is read without critical, resisted or '
                             f'blocked hits, with its hit count ({lengths["events"]} per channel). The mean damage per '
                             f'channel length, over the casts without such a hit, must rise strictly from the shortest '
                             f'channel to the full one.')


def model(spec, lengths: dict) -> dict:
    return {NAME: {**lengths, 'cancel_ms': list(lengths['cancel_ms']), 'arms': arms(lengths),
                   'base': {read: read_label(spec, 'base', 0, read) for read, _, _ in READS},
                   'reads': {str(arm): [{read: read_label(spec, arm, repeat, read) for read, _, _ in READS}
                                        for repeat in range(1, lengths['repeats'] + 1)] for arm in arms(lengths)}}}


def scenario_order(lengths: dict) -> list[dict]:
    full = lengths['reads'][FULL]
    return [*full, *(row for arm in lengths['cancel_ms'] for row in lengths['reads'][str(arm)])]


def verdict(verdict, run, lengths: dict):
    from compare import missing_measurement
    rows = scenario_order(lengths)
    labels = [*lengths['base'].values(), *(label for row in rows for label in row.values())]
    values = run.values
    missing = next((label for label in labels if values.get(label) is None), None)
    if missing is not None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, missing))
    deltas, previous = {}, lengths['base']
    for row in rows:
        deltas[row['total']] = {read: values[label] - values[previous[read]] for read, label in row.items()}
        previous = row
    per_arm = {arm: [deltas[row['total']] for row in lengths['reads'][str(arm)]] for arm in lengths['arms']}
    wrong = [(arm, index + 1, delta['struck']) for arm, rows_of_arm in per_arm.items()
             for index, delta in enumerate(rows_of_arm) if delta['struck'] != lengths['events']]
    if wrong:
        return replace(verdict, status='alert', explanation=f'{lengths["spell"]} must land {lengths["events"]} '
                                                            f'times per channel, read (length, repeat, hits) {wrong}')
    damages = {arm: [delta['total'] for delta in rows_of_arm if delta['plain'] == lengths['events']]
               for arm, rows_of_arm in per_arm.items()}
    empty = [arm for arm, values_of_arm in damages.items() if not values_of_arm]
    if empty:
        return replace(verdict, status='unmeasured', explanation=f'channel lengths {empty} took a critical, '
                                                                 f'resisted or blocked hit in every repeat')
    means = [sum(damages[arm]) / len(damages[arm]) for arm in lengths['arms']]
    rising = all(low < high for low, high in zip(means, means[1:]))
    pairs = ', '.join(f'{arm if arm == FULL else f"{arm} ms"}: {mean:.2f} over {len(damages[arm])}'
                      for arm, mean in zip(lengths['arms'], means))
    lead = (f'mean plain damage of {lengths["spell"]} per channel length ({pairs}); judged strictly rising '
            f'with the channel length: {"rising" if rising else "not rising"}')
    if verdict.status != 'ok':
        return replace(verdict, explanation=f'{verdict.explanation}; {lead}')
    return replace(verdict, status='ok' if rising else 'alert', explanation=f'{verdict.explanation}; {lead}')
