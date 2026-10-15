from pathlib import Path
import os
import shutil
import struct
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
MODULE = HERE.parents[2] / 'src/server/coa'


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def main():
    source = (MODULE / 'AscensionManastorm.cpp').read_text(encoding='utf-8')
    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, signature in [('QUEUE', 'bool Queue('), ('COMPLETE', 'void Complete('),
                              ('GADGET', 'static Gadget const* FindGadget('), ('SET_LOADOUT', 'void SetLoadout(')]:
        harness = harness.replace('// ACTUAL_' + marker, method(source, signature))
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment (VS Developer PowerShell on Windows).'
    with tempfile.TemporaryDirectory(prefix='manastorm-tests-') as directory:
        out = Path(directory)
        path = out / 'actual.cpp'
        path.write_text(harness, encoding='utf-8')
        executable = out / ('harness.exe' if os.name == 'nt' else 'harness')
        if Path(compiler).stem.lower() == 'cl':
            args = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', '/I' + str(MODULE), str(path),
                    '/Fo' + str(out / 'actual.obj'), '/Fe' + str(executable)]
        else:
            args = ['-std=c++20', '-I' + str(MODULE), str(path), '-o', str(executable)]
        subprocess.run([compiler, *args], cwd=out, check=True)
        subprocess.run([str(executable), str(out)], cwd=out, check=True)
        names = ['SOLO', 'DUO', 'TRIO', 'GROUP', 'SOLO_END_GAME', 'DUO_END_GAME', 'TRIO_END_GAME', 'GROUP_END_GAME']
        for mode, name in enumerate(names):
            expected = struct.pack('<II', 51, 12) + name.encode() + b'\0' + struct.pack('<IfI', 0, 37.5, 1278051)
            assert (out / f'active-{mode}.bin').read_bytes() == expected
    print('PASS: actual queue/reward/loadout methods, transaction rollback/replays and eight native packet types.')


if __name__ == '__main__':
    main()
