from behaviours import CORPSE
from profile import CASTER

NAME = 'extra_corpses'
ORDER = 6


def corpse_id(index: int) -> str:
    return f'{CORPSE}{index + 2}'


def parse(raw: list) -> tuple[tuple[int, int, float], ...]:
    if not isinstance(raw, list) or not raw:
        raise ValueError(f'metric_delta extra_corpses {raw!r} lists at least one corpse')
    corpses = []
    for corpse in raw:
        if set(corpse) != {'entry', 'health', 'distance'} or int(corpse['health']) < 1 \
                or float(corpse['distance']) <= 0:
            raise ValueError(f'metric_delta extra corpse {corpse!r} needs an entry, a positive health and a distance')
        corpses.append((int(corpse['entry']), int(corpse['health']), float(corpse['distance'])))
    return tuple(corpses)


def check(spec, corpses):
    if corpses is None:
        return
    if dict(spec.options).get('corpse') is None or len(spec.setup_casts) != 1:
        raise ValueError(f'{spec.spell} extra_corpses joins a corpse fixture killed by one setup cast')


def setup_cast_steps(spec, corpses, index: int, after: bool) -> list[dict]:
    if not after or index != 0:
        return []
    steps = []
    for number in range(len(corpses)):
        steps.append({'action': 'reset_cooldown', 'actor': CASTER, 'spell': spec.setup_casts[0]})
        steps.append({'action': 'cast', 'actor': CASTER, 'spell': spec.setup_casts[0], 'target': corpse_id(number)})
        if spec.setup_wait_ms:
            steps.append({'action': 'wait', 'ms': spec.setup_wait_ms})
    return steps


def fixtures(class_file: dict, spec, corpses, scenario: dict):
    for number, (entry_id, health, distance) in enumerate(corpses):
        scenario.setdefault('creatures', []).append(
            {'id': corpse_id(number), 'owner': CASTER, 'entry': entry_id, 'level': class_file['level'],
             'health': health, 'distance': distance, 'stationary': True})
    scenario['contract'] += (f' {len(corpses)} more corpse fixture(s) stand at '
                             f'{[distance for _, _, distance in corpses]} yd, each killed by its own '
                             f'{spec.setup_casts[0]} cast in the treatment phase only.')
