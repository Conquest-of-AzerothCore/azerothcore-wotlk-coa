NAME = 'unlearn_before'
ORDER = 20


def parse(raw) -> list[int]:
    if not isinstance(raw, list) or not raw or not all(type(spell) is int and spell > 0 for spell in raw) \
            or len(set(raw)) != len(raw):
        raise ValueError(f'unlearn_before is a non-empty list of distinct spell ids, not {raw!r}')
    return list(raw)


def phase_steps(spec, spells: list[int], after: bool) -> list[dict]:
    from profile import CASTER
    if after:
        return []
    return [{'action': 'unlearn', 'actor': CASTER, 'spell': spell} for spell in spells]


def fixtures(class_file: dict, spec, spells: list[int], scenario: dict):
    scenario['contract'] += (f' The caster starts with {spells} (class starting spells); they are unlearned at the '
                             f'start of the before phase, so the before reading is taken without them.')
