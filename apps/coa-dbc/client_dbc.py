CLI_DESCRIPTION = """Extract, check and compare the CoA client DBC set the worldserver loads.

The worldserver reads DataDir/dbc once at startup. That directory must hold the client's own
tables: with a stock or partial set the core silently drops every item limit, gameobject
spawn, display or currency that references a row only the CoA client has. Game files are never
committed, so the set is produced locally from a client installation.
"""

import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[2]
FORMATS = ROOT / "src/server/shared/DataStores/DBCfmt.h"
STORES = ROOT / "src/server/game/DataStores/DBCStores.cpp"
MANIFEST = "client-dbc.manifest.json"
HEADER = struct.Struct("<4s4I")
PREFIX = "dbfilesclient\\"
BASE_ARCHIVES = ("common", "common-2", "expansion", "lichking")
LOCALE_ARCHIVES = ("locale", "speech", "expansion-locale", "expansion-speech", "lichking-locale", "lichking-speech")
LOCALE_DIRECTORY = re.compile(r"[a-z]{2}[A-Z]{2}\Z")
PROCESS_OPTIONS = {"creationflags": subprocess.CREATE_NO_WINDOW} if os.name == "nt" else {}


class Table:

    def __init__(self, name, data):
        if len(data) < HEADER.size or data[:4] != b"WDBC":
            raise ValueError(f"{name}: not a WDBC file")
        _, self.rows, self.fields, self.record_size, self.string_size = HEADER.unpack_from(data)
        if HEADER.size + self.rows * self.record_size + self.string_size != len(data):
            raise ValueError(f"{name}: header does not match the file size")
        self.name = name
        self.data = data
        self.string_start = HEADER.size + self.rows * self.record_size

    @classmethod
    def read(cls, path):
        return cls(Path(path).name, Path(path).read_bytes())

    def record(self, index):
        start = HEADER.size + index * self.record_size
        return self.data[start:start + self.record_size]

    def string(self, offset):
        if offset >= self.string_size:
            return b""
        start = self.string_start + offset
        end = self.data.find(b"\0", start)
        return self.data[start:end if end >= 0 else len(self.data)]


def core_stores(root=ROOT):
    active = lambda path: "\n".join(line for line in path.read_text(encoding="utf-8").splitlines()
                                    if not line.lstrip().startswith("//"))
    formats = dict(re.findall(r'char constexpr (\w+)\[\] = "([^"]*)";', active(root / FORMATS.relative_to(ROOT))))
    source = active(root / STORES.relative_to(ROOT))
    storages = dict(re.findall(r"^\s*(?:static\s+)?DBCStorage\s*<\s*\w+\s*>\s*(\w+)\((\w+)\);", source, re.M))
    loads = re.findall(r'^\s*LOAD_DBC\((\w+),\s*"([^"]+)",\s*"([^"]+)"\);', source, re.M)
    if not loads:
        raise ValueError("No LOAD_DBC entries found in " + str(STORES))
    return [(file, formats[storages[store]], table) for store, file, table in loads]


def file_format(table, fmt):
    if fmt == "df" and table.fields == 1 and table.record_size == 4:
        return "f"
    return fmt


def record_struct(table, fmt):
    codes = {"f": "f", "i": "i", "n": "i", "d": "i", "s": "I", "b": "B", "x": "4x", "X": "x"}
    widths = {"b": 1, "X": 1}
    used = max((i for i, kind in enumerate(fmt) if kind not in "xX"), default=-1) + 1
    size = sum(widths.get(kind, 4) for kind in fmt[:used])
    if size > table.record_size:
        return None
    return struct.Struct("<" + "".join(codes[kind] for kind in fmt[:used]) + f"{table.record_size - size}x")


def layout_problems(table, fmt):
    fmt = file_format(table, fmt)
    if table.fields != len(fmt):
        return [f"{table.fields} fields, the core expects {len(fmt)}"]
    if record_struct(table, fmt) is None:
        return [f"record size {table.record_size} is too small for the fields the core reads"]
    return []


def invalid_strings(table, fmt):
    fmt = file_format(table, fmt)
    positions = [i for i, kind in enumerate(k for k in fmt if k not in "xX") if kind == "s"]
    if not positions:
        return 0
    records = table.data[HEADER.size:table.string_start]
    return sum(values[i] >= table.string_size
               for values in record_struct(table, fmt).iter_unpack(records) for i in positions)


def unindexed_rows(table, fmt):
    fmt = file_format(table, fmt)
    kinds = [kind for kind in fmt if kind not in "xX"]
    key = next((i for i, kind in enumerate(kinds) if kind in "nd"), None)
    if key is None:
        return 0
    records = table.data[HEADER.size:table.string_start]
    return sum(values[key] == -1 for values in record_struct(table, fmt).iter_unpack(records))


def values(table, fmt):
    fmt = file_format(table, fmt)
    reader = record_struct(table, fmt)
    kinds = [kind for kind in fmt if kind not in "xX"]
    key = next((i for i, kind in enumerate(kinds) if kind in "nd"), None)
    strings = {}

    def resolve(offset):
        if offset not in strings:
            strings[offset] = table.string(offset)
        return strings[offset]

    result = {}
    records = table.data[HEADER.size:table.string_start]
    for row, raw in enumerate(reader.iter_unpack(records)):
        row_values = tuple(resolve(value) if kinds[i] == "s" else value for i, value in enumerate(raw))
        result[row if key is None else raw[key]] = row_values
    return result


def raw_records(table):
    if table.fields == 1 or table.record_size < 4:
        return {row: table.record(row) for row in range(table.rows)}
    return {struct.unpack_from("<I", table.data, HEADER.size + row * table.record_size)[0]: table.record(row)
            for row in range(table.rows)}


def dbc_files(directory):
    directory = Path(directory)
    if not directory.is_dir():
        return {}
    return {path.name: path for path in directory.iterdir() if path.is_file() and path.suffix.lower() == ".dbc"}


def check(directory, root=ROOT):
    files = dbc_files(directory)
    folded = {name.lower(): path for name, path in files.items()}
    problems = []
    notes = []
    for file, fmt, _ in core_stores(root):
        path = folded.get(file.lower())
        if path is None:
            problems.append(f"{file}: missing")
            continue
        if file not in files:
            problems.append(f"{file}: stored as {path.name}; case-sensitive systems cannot open it")
        try:
            table = Table.read(path)
        except ValueError as error:
            problems.append(str(error))
            continue
        layout = layout_problems(table, fmt)
        problems.extend(f"{file}: {problem}" for problem in layout)
        invalid = 0 if layout else invalid_strings(table, fmt)
        if invalid:
            notes.append(f"{file}: {invalid} string fields point outside the string block and load as empty")
        unindexed = 0 if layout else unindexed_rows(table, fmt)
        if unindexed:
            notes.append(f"{file}: {unindexed} rows have index -1 and are left out of the index table")
    return problems, notes


def diff(old_directory, new_directory, root=ROOT):
    old_directory, new_directory = Path(old_directory), Path(new_directory)
    formats = {file.lower(): fmt for file, fmt, _ in core_stores(root)}
    old_files = {name.lower(): path for name, path in dbc_files(old_directory).items()}
    new_files = {name.lower(): path for name, path in dbc_files(new_directory).items()}
    report = []
    for name in sorted(old_files.keys() | new_files.keys()):
        entry = {"file": (new_files.get(name) or old_files[name]).name, "core": name in formats}
        if name not in new_files or name not in old_files:
            entry["status"] = "only in " + ("old" if name in old_files else "new")
            report.append(entry)
            continue
        old_data, new_data = old_files[name].read_bytes(), new_files[name].read_bytes()
        if old_data == new_data:
            continue
        try:
            old, new = Table(name, old_data), Table(name, new_data)
        except ValueError as error:
            entry["status"] = str(error)
            report.append(entry)
            continue
        fmt = formats.get(name)
        comparable = fmt is not None and not layout_problems(old, fmt) and not layout_problems(new, fmt)
        if fmt is None and (old.fields, old.record_size) != (new.fields, new.record_size):
            entry["status"] = f"layout {old.fields}x{old.record_size} -> {new.fields}x{new.record_size}"
            report.append(entry)
            continue
        if comparable:
            old_rows, new_rows = values(old, fmt), values(new, fmt)
        else:
            old_rows, new_rows = raw_records(old), raw_records(new)
        entry.update(
            status="rows differ" if comparable else "raw bytes compared, string offsets included",
            removed=sorted(old_rows.keys() - new_rows.keys()),
            added=sorted(new_rows.keys() - old_rows.keys()),
            changed=sorted(key for key in old_rows.keys() & new_rows.keys() if old_rows[key] != new_rows[key]))
        if entry["added"] or entry["removed"] or entry["changed"]:
            report.append(entry)
    return report


def archive_rank(relative):
    parts = relative.replace("\\", "/").split("/")
    locale = len(parts) > 1
    stem = parts[-1].rsplit(".", 1)[0].lower()
    if not stem.startswith("patch"):
        known = BASE_ARCHIVES if not locale else LOCALE_ARCHIVES
        prefix = re.sub(r"-[a-z]{2}[a-z]{2}\Z", "", stem) if locale else stem
        return (1 if locale else 0, known.index(prefix) if prefix in known else len(known), stem)
    suffix = stem[len("patch"):].lstrip("-")
    if locale:
        number = suffix.rsplit("-", 1)[1] if "-" in suffix else "1"
        return (3, int(number) if number.isdigit() else 0, stem)
    if not suffix or suffix.isdigit():
        return (2, int(suffix or 0), stem)
    return (4, 0, suffix)


def client_archives(data_directory, replacements, original=False):
    data_directory = Path(data_directory)
    archives = {}
    for path in data_directory.iterdir():
        if path.is_file() and path.suffix.lower() == ".mpq":
            archives[path.name] = path
        elif path.is_dir() and LOCALE_DIRECTORY.fullmatch(path.name):
            archives.update({f"{path.name}/{item.name}": item for item in path.iterdir()
                             if item.is_file() and item.suffix.lower() == ".mpq"})
    if original:
        for name, path in archives.items():
            untouched = next((item for item in path.parent.iterdir()
                              if item.is_file() and item.name.lower() == path.name.lower() + ".original"), None)
            if untouched:
                archives[name] = untouched
    folded = {name.lower(): name for name in archives}
    for name, replacement in replacements.items():
        key = folded.get(name.replace("\\", "/").lower())
        if key is None:
            raise ValueError(f"--archive {name}: no such archive in {data_directory}")
        if not Path(replacement).is_file():
            raise ValueError(f"--archive {name}: {replacement} does not exist")
        archives[key] = Path(replacement)
    return sorted(archives.items(), key=lambda item: archive_rank(item[0]))


class MpqCli:

    def __init__(self, executable):
        self.executable = str(executable)

    def run(self, *arguments):
        completed = subprocess.run([self.executable, *map(str, arguments)], capture_output=True, **PROCESS_OPTIONS)
        if completed.returncode:
            raise RuntimeError(f"mpqcli {arguments[0]} failed for {arguments[-1]}: "
                               + completed.stderr.decode("utf-8", "replace").strip())
        return completed.stdout.decode("utf-8", "replace")

    def list(self, archive):
        return [line.strip() for line in self.run("list", archive).splitlines() if line.strip()]

    def extract(self, archive, member, directory):
        self.run("extract", "-f", member, "-o", directory, archive)
        return Path(directory) / member.replace("/", "\\").rsplit("\\", 1)[-1]


def extract(data_directory, output, mpq, replacements=None, log=print, original=False, root=ROOT):
    output = Path(output)
    if output.exists() and any(output.iterdir()):
        raise ValueError(f"{output} is not empty")
    archives = client_archives(data_directory, replacements or {}, original)
    carriers = {}
    for relative, path in archives:
        members = [name for name in mpq.list(path) if name.lower().replace("/", "\\").startswith(PREFIX)
                   and name.lower().endswith(".dbc")]
        for member in members:
            carriers.setdefault(member.lower().replace("/", "\\"), []).append((relative, path, member))
        if members:
            log(f"{relative}: {len(members)} DBC files")
    if not carriers:
        raise ValueError(f"No DBFilesClient tables found in {data_directory}")
    output.mkdir(parents=True, exist_ok=True)
    canonical = {file.lower(): file for file, _, _ in core_stores(root)}
    files = {}
    with tempfile.TemporaryDirectory() as scratch:
        for key in sorted(carriers):
            relative, path, member = carriers[key][-1]
            extracted = mpq.extract(path, member, scratch)
            table = Table.read(extracted)
            name = member.replace("/", "\\").rsplit("\\", 1)[-1]
            name = canonical.get(name.lower(), name)
            target = output / name
            shutil.move(extracted, target)
            files[name] = {
                "archive": relative, "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
                "rows": table.rows, "fields": table.fields, "recordSize": table.record_size,
                "overridden": [carrier[0] for carrier in carriers[key][:-1]]}
    manifest = {
        "format": 1,
        "created": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "client": str(Path(data_directory).resolve()),
        "archives": [{"name": relative, "source": str(path.resolve()), "bytes": path.stat().st_size}
                     for relative, path in archives],
        "files": files}
    (output / MANIFEST).write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def parse_replacements(items):
    result = {}
    for item in items or []:
        name, separator, path = item.partition("=")
        if not separator or not name or not path:
            raise ValueError(f"--archive expects NAME=PATH, got {item}")
        result[name] = path
    return result


def print_diff(report, ids):
    for entry in report:
        if "added" not in entry:
            print(f"{entry['file']}: {entry['status']}")
            continue
        counts = ", ".join(f"{len(entry[kind])} {kind}" for kind in ("added", "removed", "changed") if entry[kind])
        print(f"{entry['file']}: {counts}" + ("" if entry["status"] == "rows differ" else f" ({entry['status']})"))
        if ids:
            for kind in ("added", "removed", "changed"):
                if entry[kind]:
                    print(f"  {kind}: " + " ".join(map(str, entry[kind])))


def main(argv=None):
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION.splitlines()[0])
    commands = parser.add_subparsers(dest="command", required=True)

    command = commands.add_parser("extract", help="extract the client's effective DBC set from its archives")
    command.add_argument("client_data", type=Path, help="the client's Data directory")
    command.add_argument("output", type=Path, help="an empty or new directory")
    command.add_argument("--mpqcli", required=True, type=Path, help="mpqcli executable")
    command.add_argument("--original", action="store_true",
                         help="read the launcher's untouched NAME.ORIGINAL copy of any locally replaced archive")
    command.add_argument("--archive", action="append", metavar="NAME=PATH",
                         help="read PATH in place of the client archive NAME, e.g. patch-T.MPQ=patch-T.MPQ.ORIGINAL")

    command = commands.add_parser("check", help="verify a set loads with this source tree's DBC formats")
    command.add_argument("directory", type=Path)

    command = commands.add_parser("diff", help="compare two DBC sets row by row")
    command.add_argument("old", type=Path)
    command.add_argument("new", type=Path)
    command.add_argument("--ids", action="store_true", help="list the added, removed and changed IDs")

    arguments = parser.parse_args(argv)
    try:
        if arguments.command == "extract":
            manifest = extract(arguments.client_data, arguments.output, MpqCli(arguments.mpqcli),
                               parse_replacements(arguments.archive), original=arguments.original)
            print(f"{len(manifest['files'])} tables written to {arguments.output}")
            problems, notes = check(arguments.output)
        elif arguments.command == "check":
            problems, notes = check(arguments.directory)
        else:
            print_diff(diff(arguments.old, arguments.new), arguments.ids)
            return 0
    except (OSError, ValueError, RuntimeError) as error:
        print(error, file=sys.stderr)
        return 1
    for note in notes:
        print(note)
    for problem in problems:
        print(problem, file=sys.stderr)
    print(f"{len(core_stores())} core tables checked, {len(problems)} problems")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
