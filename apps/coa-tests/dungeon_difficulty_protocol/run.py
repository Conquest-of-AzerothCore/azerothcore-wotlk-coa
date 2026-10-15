import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']


def main():
    source = (ROOT / 'src/server/game/Handlers/MiscHandler.cpp').read_text(encoding='utf-8')
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    code = code.replace('// ACTUAL_HANDLER', method(source, 'void WorldSession::HandleSetDungeonDifficultyOpcode('))
    compat = (ROOT / 'src/server/coa/AscensionCompat.cpp').read_text(encoding='utf-8')
    signature = 'bool QueueAscensionDungeonDifficulty('
    bridge = method(compat, signature) if signature in compat else (
        'bool QueueAscensionDungeonDifficulty(WorldSession*, WorldPacket const&) { return false; }')
    code = code.replace('// ACTUAL_BRIDGE', bridge)
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler
    with tempfile.TemporaryDirectory(prefix='coa-dungeon-protocol-') as directory:
        out = Path(directory)
        cpp = out / 'protocol.cpp'
        exe = out / ('protocol.exe' if os.name == 'nt' else 'protocol')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
    early = method(compat, '[[nodiscard]] bool CanPacketReceiveEarly(')
    assert early.index('QueueAscensionDungeonDifficulty(session, packet)') < early.index('uint32 firstOpcode')
    print('PASS: native difficulty restrictions and acknowledgement; one-byte Ascension request queued safely')


if __name__ == '__main__':
    main()
