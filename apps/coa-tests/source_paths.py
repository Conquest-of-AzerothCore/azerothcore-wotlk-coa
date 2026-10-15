from pathlib import Path
import subprocess


RENAMED_PATHS = {
    'src/server/coa/': 'modules/mod-ascension-compat/src/',
    'apps/coa-tests/': 'modules/mod-ascension-compat/tests/',
}


def git_source(arguments, **kwargs):
    if len(arguments) != 3 or arguments[:2] != ['git', 'show'] or ':' not in arguments[2]:
        raise ValueError('Expected git show ref:path')
    reference, path = arguments[2].split(':', 1)
    root = kwargs.get('cwd', Path(__file__).resolve().parents[2])
    present = subprocess.run(['git', 'cat-file', '-e', arguments[2]], cwd=root,
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if present.returncode:
        for current, previous in RENAMED_PATHS.items():
            if path.startswith(current):
                arguments = ['git', 'show', f'{reference}:{previous}{path[len(current):]}']
                break
    return subprocess.check_output(arguments, **kwargs)
