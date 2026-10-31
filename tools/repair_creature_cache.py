import argparse
import hashlib
import json
import os
from pathlib import Path
import struct
import subprocess
import tempfile


def parse_cache(data):
    if len(data) < 32 or data[:4] != b'BOMW' or struct.unpack_from('<I', data, 4)[0] != 12340:
        raise ValueError('Expected a 3.3.5a creaturecache.wdb')
    rows = []
    seen = set()
    offset = 24
    while offset + 8 <= len(data):
        entry, size = struct.unpack_from('<II', data, offset)
        if entry == 0:
            if size or any(data[offset:]):
                raise ValueError('Invalid cache terminator')
            return data[:24], rows, data[offset:]
        if entry in seen or size == 0 or size > len(data) - offset - 8:
            raise ValueError('Duplicate, empty or truncated cache record')
        seen.add(entry)
        rows.append((entry, data[offset:offset + 8 + size]))
        offset += 8 + size
    raise ValueError('Missing cache terminator')


def metadata(record):
    offset = 8
    for _ in range(6):
        offset = record.index(b'\0', offset) + 1
    return struct.unpack_from('<II', record, offset)


def invalidate(data, entry, expected_flags, expected_type):
    header, rows, tail = parse_cache(data)
    matching = [record for record_id, record in rows if record_id == entry]
    if not matching:
        return data, len(rows)
    if metadata(matching[0]) != (expected_flags, expected_type):
        raise ValueError('Entry metadata differs from the reviewed defect; no changes made')
    remaining = [(record_id, record) for record_id, record in rows if record_id != entry]
    result = header + b''.join(record for _, record in remaining) + tail
    if parse_cache(result) != (header, remaining, tail):
        raise ValueError('Cache preservation check failed')
    return result, len(remaining)


def ensure_closed():
    if os.name != 'nt':
        raise RuntimeError('Apply requires Windows so client closure can be checked; inspection works offline')
    command = 'if (Get-Process Ascension,Wow -ErrorAction SilentlyContinue) {exit 1} else {exit 0}'
    result = subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command', command],
                            capture_output=True, check=False)
    if result.returncode:
        raise RuntimeError('Close Ascension/WoW before applying the cache repair')


def apply(cache, before, after, check_closed=ensure_closed):
    check_closed()
    if cache.read_bytes() != before:
        raise RuntimeError('Cache changed since inspection')
    if before == after:
        return None
    backup_fd, backup_name = tempfile.mkstemp(prefix=cache.name + '.backup-', dir=cache.parent)
    backup = Path(backup_name)
    with os.fdopen(backup_fd, 'wb') as stream:
        stream.write(before)
        stream.flush()
        os.fsync(stream.fileno())
    if backup.read_bytes() != before:
        raise RuntimeError('Backup verification failed')
    staged_fd, staged_name = tempfile.mkstemp(prefix=cache.name + '.repair-', dir=cache.parent)
    staged = Path(staged_name)
    try:
        with os.fdopen(staged_fd, 'wb') as stream:
            stream.write(after)
            stream.flush()
            os.fsync(stream.fileno())
        check_closed()
        if cache.read_bytes() != before:
            raise RuntimeError('Cache changed before replacement; backup retained')
        os.replace(staged, cache)
        if cache.read_bytes() != after:
            raise RuntimeError('Readback failed; backup retained at ' + str(backup))
    finally:
        if staged.exists():
            staged.unlink()
    return backup


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cache', type=Path, required=True)
    parser.add_argument('--entry', type=int, required=True)
    parser.add_argument('--expected-type', type=int, required=True)
    parser.add_argument('--expected-flags', type=int, required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    if args.entry <= 0:
        parser.error('--entry must be positive')
    cache = args.cache.resolve(strict=True)
    before = cache.read_bytes()
    after, preserved = invalidate(before, args.entry, args.expected_flags, args.expected_type)
    backup = apply(cache, before, after) if args.apply else None
    print(json.dumps({
        'action': 'applied' if args.apply and before != after else 'unchanged' if before == after else 'preview',
        'entry': args.entry,
        'preserved_records': preserved,
        'removed_records': int(before != after),
        'before_sha256': hashlib.sha256(before).hexdigest(),
        'after_sha256': hashlib.sha256(after).hexdigest(),
        'backup': str(backup) if backup else None,
    }, indent=2))


if __name__ == '__main__':
    main()
