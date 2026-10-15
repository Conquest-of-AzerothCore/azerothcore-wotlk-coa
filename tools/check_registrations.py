CLI_DESCRIPTION = """Check the CoA server's flat loader: each entry point must be defined and called exactly once,
and the worldserver must call the CoA loader exactly once.

This checks source wiring, not SQL spell bindings, compilation, or gameplay behavior.
Comments and string literals are ignored; conditional/non-flat loaders require explicit checker support.
"""

import argparse
from collections import defaultdict
import json
from pathlib import Path
import re
import sys


ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / 'src/server/coa'
WORLDSERVER = ROOT / 'src/server/apps/worldserver/Main.cpp'
NAME = r'(?:AddSC_\w+|Add(?:Ascension|CoA)\w*Scripts)'
DEFINITION = re.compile(r'\bvoid\s+(' + NAME + r')\s*\(\s*(?:void\s*)?\)\s*\{')
CALL = re.compile(r'\b(' + NAME + r')\s*\(\s*\)\s*;')
ROOT_CALL = re.compile(r'\bAddCoAScripts\s*\(\s*\)\s*;')
IGNORED = re.compile(
    r'//[^\n]*|/\*[\s\S]*?\*/|R"(?P<delimiter>[^ ()\\\t\r\n]{0,16})\([\s\S]*?\)(?P=delimiter)"'
    r'|"(?:\\[\s\S]|[^"\\])*"|\'(?:\\[^\n]|[^\'\\\n])*\'')


def code_only(source):
    return IGNORED.sub(lambda match: re.sub(r'[^\n]', ' ', match.group()), source)


def inspect(sources, worldserver=None):
    definitions = defaultdict(list)
    issues = []
    for path, text in sources.items():
        code = code_only(text)
        for match in DEFINITION.finditer(code):
            definitions[match[1]].append({'path': path, 'line': code.count('\n', 0, match.start()) + 1})
    loader_definitions = definitions.pop('AddCoAScripts', [])
    if len(loader_definitions) != 1:
        issues.append({'entry': 'AddCoAScripts', 'definitions': loader_definitions,
                       'message': 'Expected one CoA root loader across all sources'})
    if worldserver is not None:
        root_calls = len(ROOT_CALL.findall(code_only(worldserver)))
        if root_calls != 1:
            issues.append({'entry': 'AddCoAScripts', 'path': WORLDSERVER.relative_to(ROOT).as_posix(),
                           'calls': root_calls, 'message': 'The worldserver must call AddCoAScripts exactly once'})
    loader = code_only(sources.get('CoAScriptLoader.cpp', ''))
    entries = list(re.finditer(r'\bvoid\s+AddCoAScripts\s*\(\s*\)\s*\{', loader))
    if len(entries) != 1:
        return {'status': 'failed', 'definitions': len(definitions), 'calls': 0,
                'issues': [{'message': 'Expected exactly one AddCoAScripts loader definition'}]}
    start, end, depth = entries[0].end(), entries[0].end(), 1
    while end < len(loader) and depth:
        depth += (loader[end] == '{') - (loader[end] == '}')
        end += 1
    body = loader[start:end - 1]
    if depth or CALL.sub('', body).strip():
        issues.append({'path': 'CoAScriptLoader.cpp',
                       'message': 'Loader is not a flat list of registrations; update the checker for this structure'})
    calls = defaultdict(list)
    for match in CALL.finditer(body):
        line = loader.count('\n', 0, start + match.start()) + 1
        calls[match[1]].append({'path': 'CoAScriptLoader.cpp', 'line': line})
    for name in sorted(definitions.keys() | calls.keys()):
        defined, called = definitions.get(name, []), calls.get(name, [])
        if len(defined) != 1 or len(called) != 1:
            issues.append({'entry': name, 'definitions': defined, 'calls': called,
                           'message': f'{name}: expected one definition and one loader call; '
                                      f'found {len(defined)} definition(s), {len(called)} call(s)'})
    return {'status': 'failed' if issues else 'passed', 'definitions': len(definitions),
            'calls': sum(map(len, calls.values())), 'issues': issues}


def check(directory=MODULE, worldserver=WORLDSERVER):
    return inspect({path.relative_to(directory).as_posix(): path.read_text(encoding='utf-8')
                    for path in sorted(directory.rglob('*.cpp'))}, worldserver.read_text(encoding='utf-8'))


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.parse_args(argv)
    try:
        result = check()
        print(json.dumps(result, indent=2))
        return int(result['status'] != 'passed')
    except (OSError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
