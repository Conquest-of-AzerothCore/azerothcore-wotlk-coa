from behaviours import CORPSE
from profile import CASTER

NAME = 'corpse'
ORDER = 1


def parse(raw: dict) -> tuple[int, int, float]:
    if set(raw) != {'entry', 'health', 'distance'} or int(raw['health']) < 1 or float(raw['distance']) <= 0:
        raise ValueError(f'metric_delta corpse {raw!r} needs an entry, a positive health and a distance')
    return int(raw['entry']), int(raw['health']), float(raw['distance'])


def check(spec, corpse: tuple[int, int, float] | None):
    if spec.setup_target == CORPSE and (corpse is None or not spec.setup_only_after):
        raise ValueError(f'{spec.spell} kills a corpse fixture only when it declares one, in the treatment phase only')
    if corpse is not None and spec.setup_target != CORPSE:
        raise ValueError(f'{spec.spell} declares a corpse fixture that no setup cast kills')


def fixtures(class_file: dict, spec, corpse: tuple[int, int, float], scenario: dict):
    entry_id, health, distance = corpse
    scenario.setdefault('creatures', []).append(
        {'id': CORPSE, 'owner': CASTER, 'entry': entry_id, 'level': class_file['level'], 'health': health,
         'distance': distance, 'stationary': True})
