from dataclasses import replace

NAME = 'ring_sum'
ORDER = 14
FIELDS = {'spell', 'share_pct', 'slots'}
READS = {'max_health': 'ring_sum_max_health'}
METRIC_EVIDENCE = dict.fromkeys(READS.values(), 'state')
STATE_PROMISES = dict.fromkeys(READS.values(), r'health|stack\w*')


def parse(raw) -> dict:
    if not isinstance(raw, dict) or set(raw) - {'read'} != FIELDS or not all(
            isinstance(raw[key], int) and not isinstance(raw[key], bool) and raw[key] > 0 for key in FIELDS) \
            or raw.get('read', 'max_health') not in READS:
        raise ValueError(f'ring_sum is {{"spell": hit spell, "share_pct": percent, "slots": ring size}}, positive '
                         f'integers, with an optional "read" among {sorted(READS)}, not {raw!r}')
    return dict(raw)


def check(spec, ring):
    if ring is None:
        return
    if 'read' in ring and (spec.metric != ring['read'] or spec.measure_actor != 'caster' or spec.fields):
        raise ValueError(f'{spec.spell} ring_sum read {ring["read"]} judges the caster\'s {ring["read"]} without '
                         f'fields, not {spec.measure_actor} {spec.metric} {spec.fields}')
    hits = [spell for spell in (*spec.setup_casts, spec.trigger_spell) if spell == ring['spell']]
    if len(hits) <= ring['slots']:
        raise ValueError(f'{spec.spell} ring_sum needs more than {ring["slots"]} casts of {ring["spell"]} in the '
                         f'treatment phase, so the oldest share leaves the ring; it has {len(hits)}')


def read_label(spec, index: int) -> str:
    from behaviours import metric_delta_label
    return f'{metric_delta_label(spec, "after")} ring read {index}'


def hit_casts(spec, ring: dict, steps: list[dict], start: int, end: int) -> list[int]:
    from profile import CASTER
    return [index for index in range(start, end) if steps[index].get('action') == 'cast'
            and steps[index].get('actor') == CASTER and steps[index].get('spell') == ring['spell']]


def fixtures(class_file: dict, spec, ring: dict, scenario: dict):
    from behaviours import metric_delta_label
    from profile import CASTER, measurement
    steps = scenario['steps']
    labels = [step.get('label') for step in steps]
    start = labels.index(metric_delta_label(spec, 'before'))
    end = labels.index(metric_delta_label(spec, 'after'))
    casts = hit_casts(spec, ring, steps, start, end)
    if len(casts) <= ring['slots']:
        raise ValueError(f'{spec.spell} ring_sum finds {len(casts)} casts of {ring["spell"]} in the treatment '
                         f'phase, not more than {ring["slots"]}')
    reads = [measurement(read_label(spec, index), CASTER, 'spell_damage_total', spell=ring['spell'],
                         target=spec.target) for index in range(len(casts) + 1)]
    marks = dict(zip([*casts, end], reads))
    scenario['steps'] = [step for index, step in enumerate(steps)
                         for step in ([marks[index]] if index in marks else []) + [step]]
    scenario['contract'] += (f' The treatment phase reads the damage of {ring["spell"]} on the {spec.target} before '
                             f'each of its {len(casts)} casts and before the judged reading; the increase is judged '
                             f'against the sum of {ring["share_pct"]}% of each of the last {ring["slots"]} hits '
                             f'(each share truncated), and must differ from the sum over every hit.')


def model(spec, ring: dict) -> dict:
    from behaviours import metric_delta_label
    casts = len([spell for spell in (*spec.setup_casts, spec.trigger_spell) if spell == ring['spell']])
    return {NAME: {**ring, 'before': metric_delta_label(spec, 'before'), 'after': metric_delta_label(spec, 'after'),
                   'reads': [read_label(spec, index) for index in range(casts + 1)]},
            **({'evidence_metric': READS[ring['read']]} if 'read' in ring else {})}


def verdict(verdict, run, ring: dict):
    from compare import missing_measurement
    labels = [ring['before'], ring['after'], *ring['reads']]
    values = [run.values.get(label) for label in labels]
    missing = next((label for label, value in zip(labels, values) if value is None), None)
    if missing is not None:
        return replace(verdict, status='alert', explanation=missing_measurement(run, missing))
    before, after, *reads = values
    hits = [int(later - earlier) for earlier, later in zip(reads, reads[1:])]
    shares = [hit * ring['share_pct'] // 100 for hit in hits]
    expected = sum(shares[-ring['slots']:])
    everything = sum(shares)
    measured = after - before
    lead = (f'hits {hits}, shares {shares}; increase {measured:g} against the last {ring["slots"]} shares '
            f'{expected} (every hit: {everything})')
    if any(hit <= 0 for hit in hits):
        return replace(verdict, status='unmeasured', measured=measured, expected=None, low=None, high=None,
                       explanation=f'{lead}; a cast dealt no damage, so its share is unknown')
    if expected == everything:
        return replace(verdict, status='unmeasured', measured=measured, expected=float(expected), low=None,
                       high=None, explanation=f'{lead}; the oldest share is 0, so the ring cannot be told apart')
    status = 'ok' if measured == expected else 'alert'
    return replace(verdict, status=status, measured=measured, expected=float(expected), low=float(expected),
                   high=float(expected), explanation=f'{lead}; an integer sum, compared exactly')
