import argparse
import json
import os
from pathlib import Path
import runpy
import shutil
import struct
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    parser = argparse.ArgumentParser(
        description='Verify captured ItemStat loading, template integration and wire replies.')
    parser.add_argument('--dbc-dir', type=Path)
    args = parser.parse_args()
    source = (ROOT / 'src/server/coa/AscensionItemScaling.cpp').read_text(encoding='utf-8')
    buffer = (ROOT / 'src/server/shared/Packets/ByteBuffer.cpp').read_text(encoding='utf-8')
    fixture = json.loads((HERE / 'fixtures.json').read_text(encoding='utf-8'))
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in [
        ('STARTUP', source[source.index('std::atomic<bool> liftsEnabled'):source.index('using CurveKey =')]),
        ('CONFIGURATION', method(source, 'class Configuration : public WorldScript') + ';'),
        ('BUILD_TEMPLATE', method(source, 'std::unique_ptr<ItemTemplate> BuildTemplate(')),
        ('HANDLE_QUERY', method(source, 'void HandleStatQuery(') if 'void HandleStatQuery(' in source else
         'void HandleStatQuery(WorldSession*, WorldPacket const&) { }'),
        ('BYTE_BUFFER', '\n'.join(method(buffer, signature) for signature in (
            'void ByteBuffer::append(uint8 const* src, std::size_t cnt)',
            'ByteBufferPositionException::ByteBufferPositionException(',
        ))),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, text)
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler.'
    includes = [ROOT / path for path in ('src/common', 'src/common/Utilities', 'src/server/shared',
                'src/server/shared/Packets', 'src/server/shared/DataStores', 'src/server/game/Server',
                'src/server/game/Server/Protocol', 'src/server/game/Entities/Item', 'src/server/coa')]
    with tempfile.TemporaryDirectory(prefix='coa-captured-item-stats-') as directory:
        out = Path(directory)
        cpp = out / 'harness.cpp'
        cpp.write_text(harness, encoding='utf-8')
        data = out / 'dbc' / 'ItemStat.dbc'
        data.parent.mkdir()
        data.write_bytes(struct.pack('<4s4I', b'WDBC', len(fixture['rows']), 39, 156, 0) +
                         b''.join(struct.pack('<39I', *row) for row in fixture['rows']))
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', *['/I' + str(p) for p in includes],
                     str(cpp), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', '-Wall', '-Wextra', '-Werror', *['-I' + str(p) for p in includes],
                     str(cpp), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        command = [str(executable), str(data)]
        if args.dbc_dir and (args.dbc_dir / 'ItemStat.dbc').is_file():
            command.append(str(args.dbc_dir / 'ItemStat.dbc'))
        subprocess.run(command, cwd=out, check=True, timeout=90)


if __name__ == '__main__':
    main()
