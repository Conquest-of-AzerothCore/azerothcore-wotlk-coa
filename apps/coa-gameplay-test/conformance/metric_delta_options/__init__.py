from functools import cache
from importlib import import_module
import pkgutil


@cache
def option_modules() -> tuple:
    found = [import_module(f'{__name__}.{module.name}') for module in pkgutil.iter_modules(__path__)
             if not module.name.startswith('test_')]
    return tuple(sorted(found, key=lambda module: (module.ORDER, module.NAME)))


def parsed_options(entry: dict) -> tuple[tuple[str, object], ...]:
    return tuple((module.NAME, module.parse(entry[module.NAME])) for module in option_modules()
                 if entry.get(module.NAME) is not None)


def checked_options(spec):
    present = dict(spec.options)
    for module in option_modules():
        if hasattr(module, 'check'):
            module.check(spec, present.get(module.NAME))


def option_fixtures(class_file: dict, spec, scenario: dict):
    present = dict(spec.options)
    for module in option_modules():
        if module.NAME in present and hasattr(module, 'fixtures'):
            module.fixtures(class_file, spec, present[module.NAME], scenario)
