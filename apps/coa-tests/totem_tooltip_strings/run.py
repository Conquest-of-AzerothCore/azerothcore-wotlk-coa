import re
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SOURCE = ROOT / 'src/server/coa/AscensionTotemTooltipStrings.cpp'
LOADER = ROOT / 'src/server/coa/CoAScriptLoader.cpp'
PUSHED_LUA = re.compile(r'constexpr char Lua\[\] = R"lua\((.*?)\)lua";', re.S)


def main():
    lua = shutil.which('lua5.1') or shutil.which('lua')
    if not lua:
        raise SystemExit('Lua 5.1 is required for the totem tooltip string regression.')

    source = SOURCE.read_text(encoding='utf-8')
    assert 'RunAscensionClientLua(player, chunk);' in source, 'the chunk goes through the shared client Lua sender'
    assert 'PLAYERHOOK_ON_LOGIN' in source, 'the chunk is sent at every login'
    loader = LOADER.read_text(encoding='utf-8')
    assert loader.count('AddSC_AscensionTotemTooltipStrings') == 2, 'the script is declared and registered'

    pushed = PUSHED_LUA.search(source)
    assert pushed, 'the pushed Lua is a raw string literal'
    with tempfile.TemporaryDirectory(prefix='coa-totem-tooltip-strings-') as directory:
        chunk = Path(directory) / 'chunk.lua'
        chunk.write_text(pushed.group(1), encoding='utf-8')
        subprocess.run([lua, str(HERE / 'harness.lua'), str(chunk)], check=True, timeout=60)


if __name__ == '__main__':
    main()
