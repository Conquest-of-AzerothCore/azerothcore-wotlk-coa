CLI_DESCRIPTION = """Run spell modifier packet regressions without a server or database.

Compiles the production Player::AddSpellMod and the login spell modifier resend against
the real flag96, SpellModOp, SpellModType and SpellModifier definitions. Only the session,
packet and spell store are isolated. Pass --source-ref to test another Git ref.
"""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / 'client_compat/run.py'))['method']
SPELL_MODIFIER_HELPERS = (
    'bool Player::UsesAscensionSpellModifierLayout(',
    'uint32 Player::GetClientSpellModCount(',
    'void Player::SendSpellModifier(',
)


def declaration(source, start_marker):
    text = method(source, start_marker)
    end = source.index(text) + len(text)
    return text + source[end:source.index('\n', end)]


def line(source, prefix):
    return next(text for text in source.splitlines() if text.startswith(prefix))


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--source-ref', help='Read changed production code from a local Git ref for regression checks.')
    args = parser.parse_args()

    def source(name):
        if args.source_ref:
            return git_source(['git', 'show', f'{args.source_ref}:{name}'], cwd=ROOT).decode('utf-8')
        return (ROOT / name).read_text(encoding='utf-8')

    util = source('src/common/Utilities/Util.h')
    defines = source('src/server/game/Spells/SpellDefines.h')
    player_header = source('src/server/game/Entities/Player/Player.h')
    player = source('src/server/game/Entities/Player/Player.cpp')
    handler = source('src/server/game/Handlers/CharacterHandler.cpp')
    spell_mod_ops = '\n'.join([declaration(defines, 'enum SpellModOp'),
                               line(defines, '#define MAX_SPELLMOD '),
                               line(defines, '#define MAX_CLIENT_SPELLMOD ')])

    harness = (HERE / 'harness.cpp').read_text(encoding='utf-8')
    for marker, text in [
        ('FLAG96', declaration(util, 'class flag96')),
        ('SPELL_MOD_OPS', spell_mod_ops),
        ('SPELL_MOD_TYPE', declaration(player_header, 'enum SpellModType')),
        ('SPELL_MODIFIER', declaration(player_header, 'struct SpellModifier')),
        ('SPELL_MOD_CONTAINER', line(player_header, 'typedef std::unordered_set<SpellModifier*> SpellModContainer;')),
        ('ADD_SPELL_MOD', '\n\n'.join([method(player, signature) for signature in SPELL_MODIFIER_HELPERS
                                       if signature in player] + [method(player, 'void Player::AddSpellMod(')])),
        ('LOGIN_RESEND', method(handler, '    // Xinef: we need to resend all spell mods')),
    ]:
        harness = harness.replace('// ACTUAL_' + marker, text)

    compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable a C++20 compiler (VS Developer PowerShell on Windows).'
    with tempfile.TemporaryDirectory(prefix='coa-spell-modifier-packets-') as directory:
        out = Path(directory)
        (out / 'harness.cpp').write_text(harness, encoding='utf-8')
        executable = out / ('regressions.exe' if os.name == 'nt' else 'regressions')
        if Path(compiler).stem.lower() == 'cl':
            flags = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', str(out / 'harness.cpp'), '/Fe' + str(executable)]
        else:
            flags = ['-std=c++20', str(out / 'harness.cpp'), '-o', str(executable)]
        subprocess.run([compiler, *flags], cwd=out, check=True)
        subprocess.run([str(executable)], cwd=out, check=True)


if __name__ == '__main__':
    main()
