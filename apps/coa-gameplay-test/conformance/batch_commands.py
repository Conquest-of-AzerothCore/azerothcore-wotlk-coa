import json
from pathlib import Path
import sys

from aura354 import Aura354Error, aura354_lines, aura354_rows
from audit import audit_document
from buckets import (BucketError, bucket_counts, bucket_document, class_family, class_glob, clause_keys, read_json,
                     read_sources)
from coverage import EvidenceError
from profile import DBC_DIR, DbcSetMismatch, load_class_file, server_dbc_dir

REPOSITORY = Path(__file__).resolve().parents[3]
FAILED = 2


def write_json(path: Path, document) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(document, indent=1) + '\n', encoding='utf-8')
    return path


def audit_command(args) -> int:
    try:
        document = audit_document(args.class_id, args.clauses, args.results, args.base_results, args.manifest,
                                  args.hooked, args.build, args.consumption)
    except (EvidenceError, DbcSetMismatch, ValueError, OSError) as error:
        print(f'No coverage audit: {error}', file=sys.stderr)
        return FAILED
    write_json(args.out, document)
    figures = document['figures']
    print(f"{args.out}: {figures['claims']} claims, {figures['behaviour']} behaviour, {figures['data']} data, "
          f"{figures['unproven']} unproven; {len(document['results_disagree'])} labels disagree across --results")
    return 0


def class_sources(args, class_file: dict, class_map: dict | None) -> tuple[dict[str, str], str]:
    if class_map is not None:
        paths = class_map['classes'][str(args.class_id)]['own_files']
        return read_sources(args.source_root, paths=paths), f'the class map own_files {paths}'
    pattern = class_glob(class_file['name'])
    return read_sources(args.source_root, pattern=pattern), pattern


def buckets_command(args) -> int:
    from classes import PROGRESSION_HEADER, class_spells, dataset
    from tooltip import Records
    try:
        class_file = load_class_file(args.class_id)
        dbc_dir = server_dbc_dir(args.dbc_dir or class_file.get('dbc_dir', DBC_DIR))
        records = Records(dataset(dbc_dir))
        class_map = read_json(args.class_map, None)
        if class_map is not None and str(args.class_id) not in class_map.get('classes', {}):
            raise BucketError(f'class {args.class_id} is not in {args.class_map}')
        sources, source_name = class_sources(args, class_file, class_map)
        if class_map is not None:
            family = class_map['classes'][str(args.class_id)]['family']
        else:
            family = class_family(records, [spell.spell_id for spell in
                                            class_spells(dbc_dir, args.class_id, PROGRESSION_HEADER)])
        settled = clause_keys(read_json(args.settled, []), str(args.settled))
        standing = clause_keys(read_json(args.standing_alerts, []), str(args.standing_alerts))
        document = bucket_document(read_json(args.coverage, None), read_json(args.manifest, {}), class_file, sources,
                                   source_name, family, records, settled, standing,
                                   {'class_id': args.class_id, 'coverage': str(args.coverage),
                                    'manifest': str(args.manifest) if args.manifest else None,
                                    'class_map': str(args.class_map) if args.class_map else None,
                                    'source_root': str(args.source_root), 'dbc_dir': str(dbc_dir),
                                    'standing_alerts': str(args.standing_alerts) if args.standing_alerts else None})
    except (BucketError, DbcSetMismatch, ValueError, KeyError, OSError) as error:
        print(f'No bucket file: {error}', file=sys.stderr)
        return FAILED
    write_json(args.out, document)
    touched = sum(row['script_touch'] for row in document['clauses'])
    print(f"{args.out}: {len(document['clauses'])} clauses {bucket_counts(document['clauses'])}, {touched} script "
          f"touched, {len(sources)} source files, family {family}")
    return 0


def aura354_command(args) -> int:
    try:
        rows = aura354_rows(json.loads(args.class_map.read_text(encoding='utf-8')), args.class_id)
    except (Aura354Error, OSError, ValueError) as error:
        print(error, file=sys.stderr)
        return FAILED
    print('\n'.join(aura354_lines(rows, args.class_id)))
    if args.out:
        print(write_json(args.out, {'class_id': args.class_id, 'class_map': str(args.class_map), 'spells': rows}))
    return 0


def add_batch_commands(commands) -> dict:
    auditing = commands.add_parser('audit', help='write a coverage audit of a clause ledger: every claim with its '
                                                 'evidence, labels and alert labels, from merged compare outputs')
    auditing.add_argument('--class', dest='class_id', type=int, required=True)
    auditing.add_argument('--clauses', type=Path, required=True, help='the clause ledger classes/<name>_clauses.json')
    auditing.add_argument('--results', type=Path, nargs='*', default=[],
                          help='compare output directories (verdicts.json), merged in order: a later one replaces '
                               'the labels of the earlier ones; none for a class without verdicts')
    auditing.add_argument('--base-results', dest='base_results', type=Path,
                          help='a compare output directory merged first, below every --results')
    auditing.add_argument('--manifest', type=Path,
                          help='a generated manifest: its observed metrics are stamped on metric verdicts that lack '
                               'one')
    auditing.add_argument('--hooked', type=Path,
                          help='a JSON list of labels, or of {"labels": [...]} objects, judged not_measured')
    auditing.add_argument('--build', help='the build stamped on every merged verdict; without it the merged '
                                          'verdicts must come from one build')
    auditing.add_argument('--consumption', type=Path, help='a consumption file (classes/<name>_consumption.json)')
    auditing.add_argument('--out', type=Path, required=True, help='the coverage audit JSON to write')
    bucketing = commands.add_parser('buckets', help='write the bucket file of conformance.py sample and packets '
                                                    'from a coverage audit')
    bucketing.add_argument('--class', dest='class_id', type=int, required=True)
    bucketing.add_argument('--coverage', type=Path, required=True, help='the JSON of conformance.py audit')
    bucketing.add_argument('--out', type=Path, required=True, help='the bucket file to write')
    bucketing.add_argument('--manifest', type=Path,
                           help='a generated manifest: rank ids, token readbacks, spell names, uncited alert quotes')
    bucketing.add_argument('--class-map', dest='class_map', type=Path,
                           help='a class map JSON: the class own_files and family; without it the class code is '
                                'src/server/coa/**/Ascension<class name>* and the family the most common '
                                'SpellFamilyName of the class spells')
    bucketing.add_argument('--settled', type=Path,
                           help='a JSON list of {"spell", "clause", "why"}: alerts settled since, bucketed by evidence')
    bucketing.add_argument('--standing-alerts', dest='standing_alerts', type=Path,
                           help='a JSON list of {"spell", "clause"}: clauses with a standing alert from outside the '
                                'audit set')
    bucketing.add_argument('--source-root', dest='source_root', type=Path, default=REPOSITORY,
                           help='the tree the class code is read from (this repository)')
    bucketing.add_argument('--dbc-dir', dest='dbc_dir', type=Path, help='the server DBC set')
    checking = commands.add_parser('aura354', help='list the class spells carrying aura 354 from a class map, with '
                                                   'their risk, and flag those without class code')
    checking.add_argument('--class-map', dest='class_map', type=Path, required=True)
    checking.add_argument('--class', dest='class_id', type=int, required=True)
    checking.add_argument('--out', type=Path, help='also write the rows as JSON')
    return {'audit': audit_command, 'buckets': buckets_command, 'aura354': aura354_command}
