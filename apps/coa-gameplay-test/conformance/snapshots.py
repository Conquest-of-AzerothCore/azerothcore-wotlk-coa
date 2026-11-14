import argparse
import hashlib
import json
from pathlib import Path
import sys
import tempfile

from conformance import generate
from profile import DBC_DIR

SNAPSHOTS_DIR = Path(__file__).resolve().parent / 'snapshots'
TOOL = 'apps/coa-gameplay-test/conformance/'
FINISHED_CLASSES = {19: 'templar', 23: 'necromancer'}
GENERATIONS = {19: {'all': [], 'stack': ['--stack']}, 23: {'all': []}}
SHOWN = 20
SCHEMA = 1


def snapshot_path(class_id: int, directory: Path = SNAPSHOTS_DIR) -> Path:
    return Path(directory) / f'{FINISHED_CLASSES[class_id]}.json'


def directory_digests(directory: Path) -> dict[str, str]:
    directory = Path(directory)
    return {path.relative_to(directory).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted(directory.rglob('*')) if path.is_file()}


def generated_digests(class_id: int, arguments: list[str]) -> dict[str, str]:
    with tempfile.TemporaryDirectory() as directory:
        out = Path(directory) / 'out'
        generate(class_id, out, stack='--stack' in arguments)
        return directory_digests(out)


def class_snapshot(class_id: int, generator=generated_digests) -> dict:
    return {'schema': SCHEMA, 'class_id': class_id, 'class_name': FINISHED_CLASSES[class_id],
            'generations': {name: {'arguments': arguments, 'files': generator(class_id, arguments)}
                            for name, arguments in GENERATIONS[class_id].items()}}


def differences(expected: dict[str, str], actual: dict[str, str]) -> dict[str, list[str]]:
    return {'changed': sorted(name for name in expected.keys() & actual.keys() if expected[name] != actual[name]),
            'added': sorted(actual.keys() - expected.keys()),
            'removed': sorted(expected.keys() - actual.keys())}


def generate_command(class_id: int, arguments: list[str], out: str) -> str:
    return ' '.join(['python -B', TOOL + 'conformance.py', 'generate', '--class', str(class_id), *arguments,
                     '--out', out])


def mismatch_message(class_id: int, name: str, arguments: list[str], found: dict[str, list[str]]) -> str:
    lines = [f'{FINISHED_CLASSES[class_id]} ({class_id}) generation "{name}" differs from its committed digests:']
    for kind, files in found.items():
        if files:
            lines.append(f'  {kind} ({len(files)}): ' + ', '.join(files[:SHOWN])
                         + (f', ... {len(files) - SHOWN} more' if len(files) > SHOWN else ''))
    lines += ['  Regenerate and diff locally:',
              '    ' + generate_command(class_id, arguments, '<A>') + '   (on the base commit, a throwaway worktree)',
              '    ' + generate_command(class_id, arguments, '<B>') + '   (on this tree)',
              '    diff -r <A> <B>',
              '  If every difference is intended, run python -B ' + TOOL + f'snapshots.py write --class {class_id}'
              ' and commit the digest file with the change; the diff is the review evidence.',
              '  If not, the change altered a finished class\'s generated scenarios: fix it.']
    return '\n'.join(lines)


def check(class_id: int, directory: Path = SNAPSHOTS_DIR, generator=generated_digests) -> list[str]:
    path = snapshot_path(class_id, directory)
    if not path.is_file():
        return [f'{path} is missing; run python -B {TOOL}snapshots.py write --class {class_id}']
    committed = json.loads(path.read_text(encoding='utf-8'))
    problems = []
    if set(committed['generations']) != set(GENERATIONS[class_id]):
        problems.append(f'{path.name} records generations {sorted(committed["generations"])}, '
                        f'expected {sorted(GENERATIONS[class_id])}; rewrite it with snapshots.py write')
    for name, arguments in GENERATIONS[class_id].items():
        expected = committed['generations'].get(name, {}).get('files', {})
        found = differences(expected, generator(class_id, arguments))
        if any(found.values()):
            problems.append(mismatch_message(class_id, name, arguments, found))
    return problems


def write(class_id: int, directory: Path = SNAPSHOTS_DIR, generator=generated_digests) -> Path:
    path = snapshot_path(class_id, directory)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(class_snapshot(class_id, generator), indent=2, sort_keys=True) + '\n',
                    encoding='utf-8')
    return path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description='committed scenario digests of the finished classes')
    parser.add_argument('command', choices=('check', 'write'))
    parser.add_argument('--class', dest='class_id', type=int, choices=sorted(FINISHED_CLASSES), required=True)
    args = parser.parse_args(argv)
    if not DBC_DIR.is_dir():
        print(f'skipped: client DBC set not found at {DBC_DIR}; this check runs in the local source stage only')
        return 0
    if args.command == 'write':
        print(write(args.class_id))
        return 0
    problems = check(args.class_id)
    for problem in problems:
        print(problem)
    if not problems:
        print(f'{FINISHED_CLASSES[args.class_id]} ({args.class_id}): generated scenarios match the committed digests')
    return int(bool(problems))


if __name__ == '__main__':
    sys.exit(main())
