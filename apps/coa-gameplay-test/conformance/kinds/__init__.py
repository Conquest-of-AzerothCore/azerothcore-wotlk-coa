from functools import cache
from importlib import import_module
import pkgutil


@cache
def kind_modules() -> tuple:
    found = [import_module(f'{__name__}.{module.name}') for module in pkgutil.iter_modules(__path__)
             if not module.name.startswith('test_')]
    return tuple(sorted(found, key=lambda module: (module.ORDER, module.KIND)))


def kind_names() -> tuple[str, ...]:
    return tuple(module.KIND for module in kind_modules())


def kind_module(kind: str | None):
    return next((module for module in kind_modules() if module.KIND == kind), None)


def kind_judge(check: str, kind: str | None):
    module = kind_module(kind)
    return getattr(module, 'JUDGES', {}).get(check) if module else None


def kind_pooled_judge(kind: str | None):
    module = kind_module(kind)
    return getattr(module, 'POOLED_JUDGE', None) if module else None


def kind_labels() -> dict:
    return {module.KIND: module.label for module in kind_modules() if hasattr(module, 'label')}


def kind_rows(table: str) -> dict:
    return {key: value for module in kind_modules() for key, value in getattr(module, table, {}).items()}
