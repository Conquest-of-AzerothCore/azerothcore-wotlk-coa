HANDLERS = [f'FX{index:02d}' for index in range(40)] + ['FX145', 'FX40']
LIBRARY_ONLY = ('FX11', 'FX13', 'FX16', 'FX29', 'FX35')
REQUIRED_HANDLERS = [name for name in HANDLERS if name not in LIBRARY_ONLY and name != 'FX40']
EVENT_KINDS = ('act', 'buff', 'debuff', 'dmg', 'dodge', 'dot', 'end', 'faint', 'heal', 'spawn', 'stunned', 'swap',
               'trap', 'turn', 'weather')
MINIMUM_HITS = 5
ESCAPES = {'\\': '\\\\', '\t': '\\t', '\n': '\\n'}
UNESCAPES = {'\\': '\\', 't': '\t', 'n': '\n'}


def encode_field(text):
    return ''.join(ESCAPES.get(char, char) for char in text)


def decode_field(text):
    chars, index = [], 0
    while index < len(text):
        if text[index] == '\\':
            chars.append(UNESCAPES[text[index + 1]])
            index += 2
        else:
            chars.append(text[index])
            index += 1
    return ''.join(chars)


def lua_number(value):
    return format(float(value), '.14g')


def value_text(value):
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return lua_number(value)
    if value is None:
        return 'nil'
    return encode_field(str(value))


def flatten(event, prefix=''):
    items = []
    for key, value in event.items():
        name = f'{prefix}{key}'
        if isinstance(value, dict):
            items += flatten(value, f'{name}.')
        else:
            items.append((name, value))
    return items


def canonical_event(event):
    items = [(key, value) for key, value in flatten(event) if key != 'k']
    return '\t'.join([f'k={value_text(event["k"])}'] +
                     [f'{key}={value_text(value)}' for key, value in sorted(items)])


def coverage_failures(report):
    failures = [f'{name}: {report["handlers"].get(name, 0)} hits, need {MINIMUM_HITS}'
                for name in REQUIRED_HANDLERS if report['handlers'].get(name, 0) < MINIMUM_HITS]
    failures += [f'event kind {kind} never appears' for kind in EVENT_KINDS if not report['kinds'].get(kind)]
    if report['unknown']:
        failures.append(f'unknown effect handler fired {report["unknown"]} times')
    return failures
