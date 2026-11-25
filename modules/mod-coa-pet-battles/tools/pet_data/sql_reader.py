import re
from pathlib import Path

UNESCAPES = {'\\': '\\', "'": "'", '"': '"', '0': '\0', 'n': '\n', 'r': '\r', 't': '\t', 'Z': '\x1a'}
INSERT = re.compile(r'INSERT INTO `(\w+)` \([^)]*\) VALUES\n')
INTEGER = re.compile(r'-?\d+')


def number(token):
    return int(token) if INTEGER.fullmatch(token) else float(token)


def parse_string(text, position):
    chars = []
    position += 1
    while text[position] != "'":
        if text[position] == '\\':
            escaped = text[position + 1]
            if escaped not in UNESCAPES:
                raise ValueError(f'unknown escape \\{escaped}')
            chars.append(UNESCAPES[escaped])
            position += 2
        else:
            chars.append(text[position])
            position += 1
    return ''.join(chars), position + 1


def parse_values(text, position):
    rows = []
    while True:
        if text[position] != '(':
            raise ValueError(f'expected ( at {position}')
        position += 1
        row = []
        while True:
            if text[position] == "'":
                value, position = parse_string(text, position)
            else:
                end = position
                while text[end] not in ',)':
                    end += 1
                value = number(text[position:end].strip())
                position = end
            row.append(value)
            if text[position] == ')':
                position += 1
                break
            position += 1
            while text[position] == ' ':
                position += 1
        rows.append(row)
        if text[position] == ';':
            return rows, position + 1
        if text[position:position + 2] != ',\n':
            raise ValueError(f'expected row separator at {position}')
        position += 2


def read(paths):
    tables = {}
    for path in paths:
        text = Path(path).read_text(encoding='utf-8')
        for name in re.findall(r'^DELETE FROM `(\w+)`;$', text, re.M):
            tables.setdefault(name, [])
        position = 0
        while match := INSERT.search(text, position):
            rows, position = parse_values(text, match.end())
            tables.setdefault(match.group(1), []).extend(rows)
    return tables
