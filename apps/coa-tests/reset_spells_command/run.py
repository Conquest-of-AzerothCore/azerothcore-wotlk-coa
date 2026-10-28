from pathlib import Path
import os
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def method(text, signature):
    start = text.index(signature)
    end = text.index('{', start) + 1
    depth = 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end]


def main():
    commands = (ROOT / 'src/server/scripts/Commands/cs_reset.cpp').read_text(encoding='utf-8')
    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    code = code.replace('// ACTUAL_RESET_SPELLS', method(commands, 'static bool HandleResetSpellsCommand('))
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    with tempfile.TemporaryDirectory(prefix='reset-spells-command-') as directory:
        out = Path(directory)
        cpp = out / 'actual.cpp'
        executable = out / ('harness.exe' if os.name == 'nt' else 'harness')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/utf-8', str(cpp), '/Fe' + str(executable)]
                 if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(executable)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=30)
    print('PASS: .reset spells flags an offline character for reset at login and resets an online one at once')


if __name__ == '__main__':
    main()
