CLI_DESCRIPTION = """Run native DBC loading and ping regressions without a server or database.

Uses the real DBC storage/loader and Player regeneration/WorldSocket ping methods.
Only database overlays, sessions, configuration and the clock are isolated.
Pass --dbc-dir to additionally verify the installed regeneration tables.
"""

import argparse
import os
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--dbc-dir', type=Path)
    parser.add_argument('--source-ref', help='Read changed production code from a local Git ref for regression checks.')
    args = parser.parse_args()

    def source(name):
        if args.source_ref:
            return git_source(['git', 'show', f'{args.source_ref}:{name}'], cwd=ROOT).decode('utf-8')
        return (ROOT / name).read_text(encoding='utf-8')

    socket = source('src/server/game/Server/WorldSocket.cpp')
    socket_header = source('src/server/game/Server/WorldSocket.h')
    player = source('src/server/game/Entities/Player/Player.cpp')
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in [
        ('PING_STATE', socket_header[socket_header.index('    TimePoint _LastPingTime;'):
                                     socket_header.index('    std::mutex _worldSessionLock;')]),
        ('SOCKET_CONSTRUCTOR', method(socket, 'WorldSocket::WorldSocket(')),
        ('PING', method(socket, 'bool WorldSocket::HandlePing(')),
        ('HP_REGEN', method(player, 'float Player::OCTRegenHPPerSpirit(')),
        ('MP_REGEN', method(player, 'float Player::OCTRegenMPPerSpirit(')),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, text)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler (VS Developer PowerShell on Windows).'
    with tempfile.TemporaryDirectory(prefix='coa-client-compat-') as directory:
        out = Path(directory)
        (out / 'Define.h').write_text('''#pragma once
#include <cstdint>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <iterator>
#include <string>
using uint8 = std::uint8_t;
using int8 = std::int8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;
#define ACORE_ENDIAN 0
#define ACORE_BIGENDIAN 1
''', encoding='utf-8')
        (out / 'Common.h').write_text('#pragma once\n#include "Define.h"\n', encoding='utf-8')
        (out / 'Errors.h').write_text('''#pragma once
#include <cassert>
#define ASSERT(condition, ...) assert(condition)
#define ASSERT_NOTNULL(value) (assert(value), (value))
''', encoding='utf-8')
        (out / 'DBCStore.cpp').write_text(source('src/server/shared/DataStores/DBCStore.cpp'), encoding='utf-8')
        (out / 'harness.cpp').write_text(harness, encoding='utf-8')
        for name, ratio in [('gtOCTRegenHP.dbc', 0.25), ('gtRegenHPPerSpt.dbc', 0.5),
                            ('gtRegenMPPerSpt.dbc', 0.01)]:
            values = [0.0 if name == 'gtRegenMPPerSpt.dbc' and i // 100 == 11 else ratio
                      for i in range(3200)]
            (out / name).write_bytes(struct.pack('<4s4I', b'WDBC', 3200, 1, 4, 0)
                                    + struct.pack('<3200f', *values))
        (out / 'indexed.dbc').write_bytes(struct.pack('<4s4IIfIf', b'WDBC', 2, 2, 8, 0, 2, 1.5, 7, 2.5))
        (out / 'invalid.dbc').write_bytes(struct.pack('<4s4I2f', b'WDBC', 1, 1, 8, 0, 1.0, 2.0))
        includes = [out, ROOT / 'src/server/shared/DataStores', ROOT / 'src/common/DataStores', ROOT / 'src/common']
        sources = [out / 'harness.cpp', out / 'DBCStore.cpp', ROOT / 'src/common/DataStores/DBCFileLoader.cpp']
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', '/D_CRT_SECURE_NO_WARNINGS',
                     *['/I' + str(p) for p in includes], *map(str, sources), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', *['-I' + str(p) for p in includes], *map(str, sources), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        command = [str(executable), str(out)]
        if args.dbc_dir:
            command.append(str(args.dbc_dir.resolve()))
        subprocess.run(command, cwd=out, check=True)


if __name__ == '__main__':
    main()
