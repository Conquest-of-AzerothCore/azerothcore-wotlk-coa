import argparse
from collections import Counter
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import sys
from typing import Iterator, Optional

ROLES = ('author', 'integrator', 'read-only', 'fix')
MAIN = 'main'
PROMPT_WINDOW = 1500
SYNTHETIC = '<synthetic>'
INTEGRATOR_DESCRIPTION = re.compile(r'integrat|pair|Merge (origin|main)', re.I)
READ_ONLY_PROMPT = re.compile(r'read-only|Read-only|read only')
READ_ONLY_DESCRIPTION = re.compile(
    r'review|sweep|tally|research|facts|Classify|Inventory|Draft|Compile|search|analysis|evidence|table|Group|'
    r'Structure|designs|Update report|Close-out|Verify|live check|flip causes|Owner-question blocks|Ledger reasons|'
    r'Update close-out|Text items', re.I)
FIX_DESCRIPTION = re.compile(r'fix|resize|Min-part|guard|drop extra|banded', re.I)
INDEPENDENT_REVIEWER = re.compile(r'independent reviewer')


class CostError(Exception):
    pass


def parse_time(text: str) -> datetime:
    moment = datetime.fromisoformat(text.replace('Z', '+00:00'))
    return moment if moment.tzinfo else moment.replace(tzinfo=timezone.utc)


def role_of(description: str, prompt: str) -> str:
    head = prompt[:PROMPT_WINDOW]
    if INDEPENDENT_REVIEWER.search(head):
        return 'read-only'
    if INTEGRATOR_DESCRIPTION.search(description):
        return 'integrator'
    if READ_ONLY_PROMPT.search(head) or READ_ONLY_DESCRIPTION.search(description):
        return 'read-only'
    if FIX_DESCRIPTION.search(description):
        return 'fix'
    return 'author'


def prompt_text(content) -> str:
    if isinstance(content, list):
        return ' '.join(block.get('text', '') for block in content if isinstance(block, dict))
    return content if isinstance(content, str) else ''


def read_transcript(path: Path):
    first = last = None
    prompt = None
    usage = {}
    with open(path, encoding='utf-8') as handle:
        for line in handle:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if not isinstance(entry, dict):
                continue
            stamp = entry.get('timestamp')
            if stamp:
                first = first or stamp
                last = stamp
            message = entry.get('message') if isinstance(entry.get('message'), dict) else None
            if message is None:
                continue
            if entry.get('type') == 'user' and prompt is None:
                prompt = prompt_text(message.get('content'))
            if entry.get('type') == 'assistant' and message.get('usage') and message.get('id'):
                if message.get('model') == SYNTHETIC:
                    continue
                usage[message['id']] = (stamp, message['usage'])
    return first, last, usage, prompt or ''


def description_of(path: Path) -> str:
    meta = path.with_name(path.name[:-len('.jsonl')] + '.meta.json')
    try:
        return json.loads(meta.read_text(encoding='utf-8')).get('description') or ''
    except (OSError, ValueError, AttributeError):
        return ''


def transcripts(root: Path) -> Iterator[Path]:
    return iter(sorted(root.rglob('*.jsonl')))


def empty_totals() -> Counter:
    return Counter(agents=0, input=0, cache_read=0, output=0, seconds=0.0)


def add_usage(totals: Counter, usage: dict) -> None:
    cache_read = usage.get('cache_read_input_tokens', 0)
    totals['input'] += usage.get('input_tokens', 0) + cache_read + usage.get('cache_creation_input_tokens', 0)
    totals['cache_read'] += cache_read
    totals['output'] += usage.get('output_tokens', 0)


def in_window(stamp: Optional[str], since: datetime, until: Optional[datetime]) -> bool:
    if not stamp:
        return False
    moment = parse_time(stamp)
    return moment >= since and (until is None or moment <= until)


def cost_totals(root: Path, since: datetime, until: Optional[datetime] = None) -> dict:
    if not root.is_dir():
        raise CostError('--transcripts is not a directory')
    agents = []
    mains = []
    for path in transcripts(root):
        first, last, usage, prompt = read_transcript(path)
        if path.name.startswith('agent-'):
            agents.append((path, first, last, usage, prompt))
        else:
            mains.append((path, first, last, usage, prompt))
    agents.sort(key=lambda item: item[1] or '')
    by_role = {role: empty_totals() for role in (*ROLES, MAIN)}
    seen = set()

    def collect(totals: Counter, usage: dict) -> None:
        for message_id, (stamp, used) in usage.items():
            if message_id in seen or not in_window(stamp, since, until):
                continue
            seen.add(message_id)
            add_usage(totals, used)

    for path, first, last, usage, prompt in agents:
        if not in_window(first, since, until):
            continue
        totals = by_role[role_of(description_of(path), prompt)]
        totals['agents'] += 1
        totals['seconds'] += (parse_time(last) - parse_time(first)).total_seconds()
        collect(totals, usage)
    for path, first, last, usage, prompt in mains:
        collect(by_role[MAIN], usage)
    roles = {}
    for role, totals in by_role.items():
        roles[role] = {'agents': totals['agents'], 'input': totals['input'], 'cache_read': totals['cache_read'],
                       'output': totals['output'], 'agent_minutes': round(totals['seconds'] / 60, 1)}
    whole = {key: sum(roles[role][key] for role in ROLES) for key in ('agents', 'input', 'cache_read', 'output')}
    whole['agent_minutes'] = round(sum(roles[role]['agent_minutes'] for role in ROLES), 1)
    return {'window': {'since': since.isoformat(), 'until': until.isoformat() if until else None},
            'roles': roles, 'agents_total': whole}


def write_cost(document: dict, out: Path) -> None:
    out.write_text(json.dumps(document, indent=2) + '\n', encoding='utf-8')


def add_cost_command(commands):
    costing = commands.add_parser(
        'cost', help='write aggregate token use and agent-minutes per role from local agent transcripts: no prompts, '
                     'paths, session ids or user names reach the output')
    costing.add_argument('--transcripts', type=Path, required=True,
                         help='a directory holding the transcript .jsonl files (and subagent agent-*.jsonl files); '
                              'there is no default')
    costing.add_argument('--since', required=True, help='ISO time; messages and agents before it are not counted')
    costing.add_argument('--until', help='ISO time; later messages and agents are not counted')
    costing.add_argument('--out', type=Path, required=True, help='the cost JSON to write')
    return {'cost': cost_command}


def cost_command(args) -> int:
    try:
        since = parse_time(args.since)
        until = parse_time(args.until) if args.until else None
        document = cost_totals(args.transcripts, since, until)
    except (CostError, ValueError) as error:
        print(f'cost: {error}', file=sys.stderr)
        return 2
    write_cost(document, args.out)
    whole = document['agents_total']
    print(f"{args.out}: {whole['agents']} agents, input {whole['input']}, output {whole['output']}, "
          f"{whole['agent_minutes']} agent-minutes")
    return 0
