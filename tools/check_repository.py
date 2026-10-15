import ast
import json
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN = {'.mpq', '.dbc', '.wtf', '.wdb', '.pdb', '.dmp', '.pfx', '.pem'}
PATTERN = re.compile(rb'(?:github_pat_|gh[pousr]_|sk-proj-)[A-Za-z0-9_]{20,}')
ACCOUNT = re.compile(rb'(?i)WTF[/\\]+Account[/\\]+[^/\\\s"\x27]+@')
SYNTAX_EXCEPTIONS = {
    '.devcontainer/devcontainer.json': 'Upstream JSON-with-comments configuration',
    '.vscode/extensions.json': 'Upstream JSON-with-comments configuration',
    '.vscode/settings.json': 'Upstream JSON-with-comments configuration',
    'deps/libmpq/bindings/python/mpq.py': 'Preserved upstream Python 2 binding',
}


def main():
    git = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=ROOT, capture_output=True)
    if git.returncode == 0:
        paths = [ROOT / p.decode('utf-8') for p in git.stdout.split(b'\0') if p]
    else:
        paths = [p for p in ROOT.rglob('*') if p.is_file() and not {'.git', '.local', '__pycache__'} & set(p.relative_to(ROOT).parts)]
    issues = []
    checked = 0
    for path in paths:
        name = path.relative_to(ROOT).as_posix()
        if path.is_symlink():
            raw = os.readlink(path).encode('utf-8')
            target = path.resolve()
            if not target.is_relative_to(ROOT) or not target.exists():
                issues.append((name, 'broken or external symbolic link'))
        elif not path.is_file():
            issues.append((name, 'tracked file missing'))
            continue
        else:
            raw = path.read_bytes()
        if path.suffix.lower() in FORBIDDEN or path.name == '.env' or '/WTF/' in '/' + name:
            issues.append((name, 'private/generated artifact'))
        if PATTERN.search(raw):
            issues.append((name, 'credential pattern'))
        if ACCOUNT.search(raw):
            issues.append((name, 'personal account path'))
        if path.suffix == '.ps1':
            lines = raw.decode('utf-8-sig').splitlines()
            for index, line in enumerate(lines):
                if re.search(r'(?i)password', line):
                    for follow in lines[index + 1:index + 4]:
                        if re.search(r'\.WriteLine\(\s*[\x27\x22][^\x27\x22]+[\x27\x22]\s*\)', follow):
                            issues.append((name, 'literal administrator credential after password prompt'))
                            break
        if path.suffix == '.py' and name not in SYNTAX_EXCEPTIONS:
            try:
                ast.parse(raw.decode('utf-8-sig'), filename=name)
            except (SyntaxError, UnicodeError) as error:
                issues.append((name, 'Python syntax: ' + type(error).__name__))
        if path.suffix == '.json' and name not in SYNTAX_EXCEPTIONS:
            try:
                json.loads(raw.decode('utf-8-sig'))
            except (ValueError, UnicodeError):
                issues.append((name, 'invalid JSON'))
        checked += 1
    print(json.dumps({'checkedFiles': checked, 'issues': issues,
                      'reviewedSyntaxExceptions': {name: reason for name, reason in SYNTAX_EXCEPTIONS.items() if (ROOT / name).is_file()},
                      'scope': 'tracked source artifact/credential patterns and Python/JSON syntax; not a complete secret/license audit'}, indent=2))
    return bool(issues)


if __name__ == '__main__':
    sys.exit(main())
