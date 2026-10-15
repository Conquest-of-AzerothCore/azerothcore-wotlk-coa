import argparse
import ast
import json
from pathlib import Path
import re
import subprocess
import sys
import tokenize

from comment_policy import language, violations


ROOT = Path(__file__).resolve().parents[1]


def git(root, *arguments):
    return subprocess.run(['git', '-c', 'core.quotepath=false', *arguments], cwd=root,
                          check=True, capture_output=True).stdout.decode('utf-8')


def owned_files(root=ROOT):
    names = git(root, 'ls-files', '--cached', '--others', '--exclude-standard', '-z').split('\0')
    return sorted({name for name in names if language(name) and (root / name).is_file()})


def added_lines(base, root=ROOT):
    diff = git(root, 'diff', '--no-ext-diff', '--no-textconv', '--no-renames', '--unified=0', base, '--')
    result = {}
    current = None
    for line in diff.splitlines():
        if line.startswith('+++ '):
            name = line[4:].rstrip('\t')
            if name.startswith('"'):
                name = ast.literal_eval(name)
            current = name[2:] if name.startswith('b/') else None
            if current and language(current):
                result.setdefault(current, set())
            else:
                current = None
        elif current and line.startswith('@@ '):
            match = re.match(r'@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@', line)
            if not match:
                raise ValueError('Unsupported Git diff hunk')
            start, count = int(match[1]), int(match[2] or 1)
            result[current].update(range(start, start + count))
    for name in git(root, 'ls-files', '--others', '--exclude-standard', '-z').split('\0'):
        if language(name):
            result[name] = None
    return result


def check(base='HEAD', all_files=False, root=ROOT):
    paths = dict.fromkeys(owned_files(root)) if all_files else added_lines(base, root)
    issues, checked = [], 0
    for name, lines in sorted(paths.items()):
        path = root / name
        if not path.exists():
            continue
        if path.is_symlink():
            raise ValueError(f'Refusing to inspect a source symlink: {name}')
        source = path.read_text(encoding='utf-8')
        for comment in violations(source, name, lines):
            issues.append({'path': name, 'line': comment.line, 'kind': comment.kind,
                           'message': 'Express intent in code or tests; explanatory comments/docstrings are disabled'})
        checked += 1
    return {'status': 'failed' if issues else 'passed', 'checked_files': checked,
            'scope': 'CoA-owned C++ and Python; legal notices, tool directives and test generator markers preserved',
            'issues': issues}


def main(argv=None):
    parser = argparse.ArgumentParser(description='Reject explanatory comments in CoA-owned C++ and Python code')
    parser.add_argument('--base', default='HEAD')
    parser.add_argument('--all', action='store_true', help='Check every owned source file, including existing comments')
    args = parser.parse_args(argv)
    try:
        result = check(args.base, args.all)
        print(json.dumps(result, indent=2))
        return int(result['status'] != 'passed')
    except (OSError, ValueError, SyntaxError, tokenize.TokenError, subprocess.CalledProcessError) as error:
        print(f'Comment check failed: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
