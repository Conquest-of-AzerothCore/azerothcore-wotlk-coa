from dataclasses import dataclass
from math import isfinite

NAME = 'bystander'
ORDER = 48
BYSTANDER_ID = 'bystander'
REQUIRED_KEYS = frozenset({'entry', 'faction', 'distance'})
OPTIONAL_KEYS = frozenset({'reaction', 'stationary', 'health'})
DEFAULT_HEALTH = 100000
MAX_DISTANCE_YD = 100.0


@dataclass(frozen=True)
class BystanderSpec:
    entry: int
    faction: int
    distance: float
    reaction: int = 0
    stationary: bool = True
    health: int = DEFAULT_HEALTH


def parse(raw) -> BystanderSpec:
    if not isinstance(raw, dict) or not REQUIRED_KEYS <= set(raw) <= (REQUIRED_KEYS | OPTIONAL_KEYS):
        raise ValueError(f'bystander requires {sorted(REQUIRED_KEYS)} and optional {sorted(OPTIONAL_KEYS)}, '
                         f'not {raw!r}')
    entry = raw['entry']
    faction = raw['faction']
    distance = raw['distance']
    reaction = raw.get('reaction', 0)
    stationary = raw.get('stationary', True)
    health = raw.get('health', DEFAULT_HEALTH)
    if type(entry) is not int or entry < 1:
        raise ValueError(f'bystander entry must be a positive int, not {entry!r}')
    if type(faction) is not int or faction < 1:
        raise ValueError(f'bystander faction must be a positive int, not {faction!r}')
    if isinstance(distance, bool) or not isinstance(distance, (int, float)) or not isfinite(distance) \
            or not 0 < distance <= MAX_DISTANCE_YD:
        raise ValueError(f'bystander distance must be in (0, {MAX_DISTANCE_YD:g}] yd, not {distance!r}')
    if type(reaction) is not int or reaction not in (0, 1, 2):
        raise ValueError(f'bystander reaction must be 0, 1 or 2, not {reaction!r}')
    if type(stationary) is not bool:
        raise ValueError(f'bystander stationary must be a bool, not {stationary!r}')
    if type(health) is not int or health < 1:
        raise ValueError(f'bystander health must be a positive int, not {health!r}')
    return BystanderSpec(entry, faction, float(distance), reaction, stationary, health)


def fixtures(class_file: dict, spec, bystander: BystanderSpec, scenario: dict):
    from profile import CASTER
    creature = {
        'id': BYSTANDER_ID,
        'owner': CASTER,
        'entry': bystander.entry,
        'level': class_file['level'],
        'health': bystander.health,
        'distance': bystander.distance,
        'faction': bystander.faction,
        'reaction': bystander.reaction,
        'stationary': bystander.stationary,
    }
    scenario.setdefault('creatures', []).append(creature)
    scenario['contract'] += (f' A bystander creature ({BYSTANDER_ID}, entry {bystander.entry}, faction '
                             f'{bystander.faction}) stands {bystander.distance:g} yd away.')
