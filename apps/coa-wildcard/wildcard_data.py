import struct
import subprocess
from pathlib import Path


class Dbc:
    def __init__(self, directory, name):
        data = (Path(directory) / name).read_bytes()
        magic, count, fields, size, _ = struct.unpack_from("<4s4I", data)
        if magic != b"WDBC":
            raise ValueError(f"{name} is not a WDBC file")
        self.strings = data[20 + count * size:]
        self.rows = [struct.unpack_from(f"<{fields}I", data, 20 + index * size) for index in range(count)]

    def text(self, offset):
        end = self.strings.find(b"\0", offset)
        return self.strings[offset:end].decode("utf-8", "replace") if end >= 0 else ""


def add_dbc_argument(parser):
    parser.add_argument("--dbc", type=Path, required=True, help="directory with the CoA client DBC files")


def add_world_arguments(parser):
    parser.add_argument("--mysql", type=Path, default=Path("mysql"), help="MySQL client")
    parser.add_argument("--defaults-file", type=Path, required=True, help="MySQL client option file")
    parser.add_argument("--database", required=True, help="world database")


def world_query(args):
    command = [str(args.mysql), f"--defaults-extra-file={args.defaults_file}", "--batch", "--skip-column-names",
               args.database, "--execute"]

    def query(sql):
        output = subprocess.run(command + [sql], capture_output=True, text=True, check=True).stdout
        return [line.split("\t") for line in output.splitlines()]
    return query


def write_lines(path, lines):
    Path(path).write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
