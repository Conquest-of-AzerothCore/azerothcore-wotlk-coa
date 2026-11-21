NAME = 'area_dummies'
ORDER = 6
MAX_AREA_DUMMIES = 9


def area_dummy_id(index: int) -> str:
    return f'area{index + 1}'


def parse(raw) -> tuple[float, ...]:
    if not isinstance(raw, list) or not 1 <= len(raw) <= MAX_AREA_DUMMIES:
        raise ValueError(f'area_dummies takes a list of 1 to {MAX_AREA_DUMMIES} distances in yd, not {raw!r}')
    distances = tuple(float(distance) for distance in raw)
    if any(distance <= 0 for distance in distances):
        raise ValueError(f'area_dummies distances {list(distances)} must be positive')
    return distances


def check(spec, distances):
    if distances is None:
        return
    from behaviours import TARGET
    if spec.setup_casts and (spec.setup_target or spec.target) != TARGET:
        raise ValueError(f'{spec.spell} sets area_dummies with a setup target other than the dummy')


def fixtures(class_file: dict, spec, distances: tuple[float, ...], scenario: dict):
    from behaviours import TARGET
    primary = next((creature for creature in scenario.get('creatures', ()) if creature['id'] == TARGET), None)
    if primary is None:
        raise ValueError(f'{spec.spell} sets area_dummies without the dummy in its scenario')
    names = [area_dummy_id(index) for index in range(len(distances))]
    scenario['creatures'] += [{**primary, 'id': name, 'distance': distance}
                              for name, distance in zip(names, distances)]
    scenario['contract'] += (f' {len(distances)} more dummies ({", ".join(names)}) stand at {list(distances)} yd '
                             f'from the caster, copies of the dummy; setup casts never target them.')
