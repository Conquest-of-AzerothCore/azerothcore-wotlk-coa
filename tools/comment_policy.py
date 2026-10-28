import ast
from dataclasses import dataclass
import io
from pathlib import Path
import re
import tokenize


OWNED_ROOTS = ('src/server/coa/', 'apps/coa-tests/', 'apps/coa-bugreport/', 'apps/coa-dbc/', 'apps/coa-gameplay-test/',
               'apps/coa-mechanics/', 'apps/coa-world-content/',
               'tools/', '.github/scripts/')
CPP_SUFFIXES = {'.c', '.cc', '.cpp', '.h', '.hpp'}
CPP_PARTS = re.compile(
    r'(?P<raw>(?:u8|u|U|L)?R"(?P<delimiter>[^ ()\\\t\r\n]{0,16})\([\s\S]*?\)(?P=delimiter)")'
    r'|(?P<number>\b[0-9][0-9A-Za-z_.\x27]*)'
    r'|(?P<string>(?:u8|u|U|L)?"(?:\\[\s\S]|[^"\\])*")'
    r'|(?P<char>(?:u8|u|U|L)?\x27(?:\\[\s\S]|[^\x27\\\n])*\x27)'
    r'|(?P<line>//(?:\\\r?\n|[^\n])*)|(?P<block>/\*[\s\S]*?(?:\*/|\Z))')
CPP_TOOL_DIRECTIVE = re.compile(
    r'//\s*(?:NOLINT(?:NEXTLINE|BEGIN|END)?(?:\([^\n]*\))?(?:\s.*)?|clang-format (?:off|on)|'
    r'IWYU pragma:[^\n]+)\s*\Z')
HARNESS_MARKER = re.compile(
    r'//\s*(?:ACTUAL_[A-Z_0-9]+|NATIVE(?:_[A-Z_0-9]+)?|ENUMS|SOURCE|POOLED_HEADER|DBC_CASES|METHODS)\s*\Z')
PYTHON_TOOL_DIRECTIVE = re.compile(
    r'#\s*(?:noqa(?:\s*:\s*[A-Z0-9, ]+)?|type:\s*(?:ignore(?:\[[^\n]+\])?|[^\n]+)|'
    r'(?:fmt|yapf):\s*[^\n]+|(?:pylint|ruff):\s*[^\n]+)\s*\Z')
LEGAL_NOTICE = re.compile(r'copyright|SPDX-License-Identifier|SPDX-FileCopyrightText', re.IGNORECASE)


@dataclass(frozen=True)
class Comment:
    start: int
    end: int
    line: int
    end_line: int
    text: str
    kind: str
    exemption: str | None = None


def language(path):
    name = Path(path).as_posix()
    if not name.startswith(OWNED_ROOTS):
        return None
    if Path(name).suffix in CPP_SUFFIXES:
        return 'cpp'
    if Path(name).suffix == '.py' or name == 'apps/coa-dbc/coa-dbc-viewer':
        return 'python'
    return None


def cpp_comments(source, path):
    found = []
    for match in CPP_PARTS.finditer(source):
        if match.lastgroup not in {'line', 'block'}:
            continue
        text = match.group()
        exemption = None
        if LEGAL_NOTICE.search(text) and not source[:match.start()].strip():
            exemption = 'legal notice'
        elif CPP_TOOL_DIRECTIVE.fullmatch(text):
            exemption = 'tool directive'
        elif str(path).startswith('apps/coa-tests/') and HARNESS_MARKER.fullmatch(text):
            exemption = 'test generator marker'
        start_line = source.count('\n', 0, match.start()) + 1
        found.append(Comment(match.start(), match.end(), start_line, start_line + text.count('\n'),
                             text, match.lastgroup, exemption))
    return found


def line_offsets(source):
    offsets = [0]
    for line in source.splitlines(keepends=True):
        offsets.append(offsets[-1] + len(line))
    return offsets


def python_comments(source):
    offsets = line_offsets(source)
    tokens = list(tokenize.generate_tokens(io.StringIO(source).readline))
    header_comments = []
    for token in tokens:
        if token.type == tokenize.COMMENT:
            header_comments.append(token)
        elif token.type not in {tokenize.NL, tokenize.NEWLINE, tokenize.ENCODING}:
            break
    legal_header = any(LEGAL_NOTICE.search(token.string) for token in header_comments)
    found = []
    for token in tokens:
        if token.type != tokenize.COMMENT:
            continue
        exemption = None
        if legal_header and token in header_comments:
            exemption = 'legal notice'
        elif token.start == (1, 0) and token.string.startswith('#!'):
            exemption = 'interpreter directive'
        elif token.start[0] <= 2 and re.fullmatch(r'#.*coding[:=]\s*[-\w.]+.*', token.string):
            exemption = 'encoding directive'
        elif PYTHON_TOOL_DIRECTIVE.fullmatch(token.string):
            exemption = 'tool directive'
        found.append(Comment(offsets[token.start[0] - 1] + token.start[1],
                             offsets[token.end[0] - 1] + token.end[1], token.start[0], token.end[0],
                             token.string, 'python', exemption))
    tree = ast.parse(source)
    for node in ast.walk(tree):
        if not isinstance(node, (ast.Module, ast.ClassDef, ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if ast.get_docstring(node, clean=False) is None:
            continue
        statement = node.body[0]
        lines = source.splitlines(keepends=True)
        start_column = len(lines[statement.lineno - 1].encode()[:statement.col_offset].decode())
        end_column = len(lines[statement.end_lineno - 1].encode()[:statement.end_col_offset].decode())
        start = offsets[statement.lineno - 1] + start_column
        end = offsets[statement.end_lineno - 1] + end_column
        exemption = 'legal notice' if isinstance(node, ast.Module) and LEGAL_NOTICE.search(source[start:end]) else None
        found.append(Comment(start, end, statement.lineno, statement.end_lineno, source[start:end],
                             'docstring', exemption))
    return found


def comments(source, path):
    kind = language(path)
    if kind == 'cpp':
        return cpp_comments(source, path)
    if kind == 'python':
        return python_comments(source)
    return []


def violations(source, path, added_lines=None):
    return [comment for comment in comments(source, path) if not comment.exemption
            and (added_lines is None or added_lines.intersection(range(comment.line, comment.end_line + 1)))]
