CLI_DESCRIPTION = """Enforce the pending-SQL boundary; CI exceptions require the sql-change-authorized PR label."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def violations(paths, allow_historical_sql=False):
    return [path for path in paths if path.lower().endswith('.sql') and not allow_historical_sql
            and not re.match(r'^data/sql/updates/pending_db_[^/]+/[^/]+\.sql$', path)]


def changed_paths(base, root=ROOT):
    def git(*args):
        return subprocess.run(['git', *args], cwd=root, check=True, capture_output=True).stdout
    paths = set(git('diff', '--name-only', '--no-renames', '-z', base, '--').decode().split('\0'))
    paths.update(git('ls-files', '--others', '--exclude-standard', '-z').decode().split('\0'))
    return sorted(paths - {''})


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--base', default='HEAD')
    parser.add_argument('--allow-historical-sql', action='store_true',
                        help='Use only for a task explicitly authorizing SQL outside pending updates')
    args = parser.parse_args(argv)
    try:
        paths = changed_paths(args.base)
        rejected = violations(paths, args.allow_historical_sql)
        print(json.dumps({'changed_files': len(paths), 'sql_outside_pending': rejected,
                          'authorized_exception': args.allow_historical_sql}, indent=2))
        return int(bool(rejected))
    except subprocess.CalledProcessError:
        print('Cannot resolve the comparison base; fetch it before checking change boundaries', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
