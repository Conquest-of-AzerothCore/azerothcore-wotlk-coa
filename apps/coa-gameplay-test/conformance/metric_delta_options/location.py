from math import isfinite

NAME = 'location'
ORDER = 47
REQUIRED_KEYS = frozenset({'map', 'x', 'y', 'z', 'o'})
OPTIONAL_KEYS = frozenset({'ignore_access'})


def finite_float(value, key: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not isfinite(value):
        raise ValueError(f'location {key} must be a finite number, not {value!r}')
    return float(value)


def parse(raw) -> dict:
    if not isinstance(raw, dict) or not REQUIRED_KEYS <= set(raw) <= (REQUIRED_KEYS | OPTIONAL_KEYS):
        raise ValueError(f'location requires {sorted(REQUIRED_KEYS)} and optional {sorted(OPTIONAL_KEYS)}, not {raw!r}')
    map_id = raw['map']
    if type(map_id) is not int or map_id < 0:
        raise ValueError(f'location map must be a non-negative int, not {map_id!r}')
    result = {
        'map': map_id,
        'x': finite_float(raw['x'], 'x'),
        'y': finite_float(raw['y'], 'y'),
        'z': finite_float(raw['z'], 'z'),
        'o': finite_float(raw['o'], 'o'),
    }
    if 'ignore_access' in raw:
        if type(raw['ignore_access']) is not bool:
            raise ValueError(f'location ignore_access must be a bool, not {raw["ignore_access"]!r}')
        result['ignore_access'] = raw['ignore_access']
    return result


def check(spec, location):
    if location is None:
        return
    if spec.enemy_player_race:
        raise ValueError(f'{spec.spell} location cannot combine with enemy_player_race (which sets its own PvP location)')


def fixtures(class_file: dict, spec, location: dict, scenario: dict):
    scenario['location'] = dict(location)
    scenario['contract'] += (f' The scenario starts on map {location["map"]} at '
                             f'({location["x"]:g}, {location["y"]:g}, {location["z"]:g}).')
