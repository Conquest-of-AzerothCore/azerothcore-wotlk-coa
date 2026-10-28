import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']

CLIENT_LUA = ROOT / 'src/server/coa/AscensionClientLua.cpp'
CLIENT_LUA_HEADER = ROOT / 'src/server/coa/AscensionClientLua.h'
UI_FIXES = ROOT / 'modules/mod-manastorm-endless/src/ManastormClientUIFixes.cpp'
UI_FIXES_HEADER = ROOT / 'modules/mod-manastorm-endless/src/ManastormClientUIFixes.h'
FEL_COMMUTATION = ROOT / 'src/server/coa/AscensionFelCommutation.cpp'
RAW_LUA = re.compile(r'constexpr std::string_view \w+ = R"lua\(.*?\)lua";', re.S)
FEL_WINDOW_LUA = re.compile(r'constexpr char WindowLua\[\] = R"lua\((.*?)\)lua";', re.S)


def client_lua_source():
    source = CLIENT_LUA_HEADER.read_text(encoding='utf-8') + CLIENT_LUA.read_text(encoding='utf-8')
    return re.sub(r'^#include "[^"]+"\n', '', source, flags=re.M)


def ui_fixes_source():
    source = UI_FIXES.read_text(encoding='utf-8')
    header = UI_FIXES_HEADER.read_text(encoding='utf-8')
    fixes = re.search(r'enum Fix : uint32\s*\{.*?\};', header, re.S).group(0)
    constants = '\n'.join(RAW_LUA.findall(source))
    build = method(source, 'std::string BuildLua(uint32 fixes)')
    return ('namespace ManastormClientUIFixes\n{\n' + fixes + '\nnamespace\n{\n' + constants
            + '\n}\n' + build + '\n}\n')


def compile_and_run(out, compiler, code, args):
    cpp = out / 'harness.cpp'
    exe = out / ('harness.exe' if os.name == 'nt' else 'harness')
    cpp.write_text(code, encoding='utf-8')
    flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)]
             if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(exe)])
    subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
    subprocess.run([str(exe), *args], cwd=out, check=True, timeout=30)


def main():
    lua = shutil.which('lua5.1') or shutil.which('lua')
    if not lua:
        raise SystemExit('Lua 5.1 is required for the pushed client Lua regression.')
    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler

    code = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    code = code.replace('// ACTUAL_CLIENT_LUA', client_lua_source())
    code = code.replace('// ACTUAL_UI_FIXES', ui_fixes_source())

    fel = FEL_COMMUTATION.read_text(encoding='utf-8')
    assert 'RunAscensionClientLua(' in fel and 'SendCriteriaUpdate' not in fel, \
        'Fel Commutation sends its window through the shared client Lua sender'

    with tempfile.TemporaryDirectory(prefix='coa-manastorm-ui-fixes-') as directory:
        out = Path(directory)
        window = out / 'fel-window.lua'
        window.write_text('local showToggle = false' + FEL_WINDOW_LUA.search(fel).group(1), encoding='utf-8')
        compile_and_run(out, compiler, code, [str(out), str(window)])
        chunks = sorted(out.glob('chunk-*.lua'))
        assert len(chunks) == 16, f'expected one chunk per fix mask, got {len(chunks)}'
        assert (out / 'fel-window-chunk.lua').exists(), 'the Fel Commutation window chunk is written'
        subprocess.run([lua, str(HERE / 'harness.lua'), str(out)], check=True, timeout=60)


if __name__ == '__main__':
    main()
