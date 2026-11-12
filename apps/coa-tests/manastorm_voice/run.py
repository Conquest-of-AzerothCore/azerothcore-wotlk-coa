from pathlib import Path
import os
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
VOICE = ROOT / 'modules/mod-manastorm-endless/src/ManastormVoiceOfMillhouse.cpp'


def method(source, signature):
    start = source.index(signature)
    end = source.index('{', start) + 1
    depth = 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[start:end]


def main():
    source = VOICE.read_text(encoding='utf-8')
    assert 'SummonCreature(' not in source
    assert 'PreparedEmitterGuid' not in source
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    code = code.replace('// ACTUAL_READY', method(source, 'bool IsMemberReadyForVoice('))
    code = code.replace('// ACTUAL_PLAY', method(source, 'bool PlayForMember('))
    code = code.replace('// ACTUAL_INTRO', method(source, 'void OnPlayerEnteredProtection('))
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    with tempfile.TemporaryDirectory(prefix='manastorm-voice-') as directory:
        out = Path(directory)
        cpp = out / 'actual.cpp'
        executable = out / ('harness.exe' if os.name == 'nt' else 'harness')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/utf-8', str(cpp), '/Fe' + str(executable)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(executable)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=30)
    print('PASS: Millhouse voice lines play from the listener; the intro waits for a settled arrival.')


if __name__ == '__main__':
    main()
