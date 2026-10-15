CLI_DESCRIPTION = """Compile the actual central gain dispatch and mutation methods for issue #77."""
import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import struct
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402
from client_data import dbc_dir  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
MODULE = ROOT / 'src/server/coa'


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument('--before', help='Use this Git revision of the resource table as a negative control')
    parser.add_argument('--dbc-dir', type=Path,
                        help='Client DBC directory used to verify native resource caps')
    args = parser.parse_args()
    extract = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
    service = extract((MODULE / 'AscensionCompat.cpp').read_text(), 'class AscensionResourceService')
    methods = [extract(service, signature) for signature in (
        'static bool SpellDealsDamage(', 'static bool MatchesGainRule(',
        'static bool ApplyGainRule(', 'static void ModifyAuraStacks(')]
    cast = extract(service, 'void OnSpellCast(')
    methods.append(cast[:cast.index('        for (AscensionCompatData::NativePowerGainRule')] + '\n}')
    hit = extract(service, 'void OnSpellHitResult(')
    methods.append(hit[:hit.index('        for (AscensionCompatData::NativePowerGainRule')] + '\n(void)changed;\n}')
    header = (git_source(['git', 'show',
              f'{args.before}:src/server/coa/AscensionCustomResourceData.h'], cwd=ROOT, text=True)
              if args.before else (MODULE / 'AscensionCustomResourceData.h').read_text())
    code = header + Path(__file__).with_name('harness.cpp').read_text()
    code = code.replace('// NATIVE_STACK', extract(
        (ROOT / 'src/server/game/Spells/Auras/SpellAuras.cpp').read_text(), 'bool Aura::ModStackAmount('))
    raw = ((args.dbc_dir or dbc_dir()) / 'Spell.dbc').read_bytes()
    count = struct.unpack_from('<I', raw, 4)[0]
    resources = {r[0]: r[49] for r in struct.iter_unpack('<234I', raw[20:20 + count * 936])
                 if r[0] in {800058, 803102, 500906, 706613}}
    assert resources == {800058: 6, 803102: 100, 500906: 6, 706613: 10}, resources
    code += '\nstruct ResourceService {\n' + '\n'.join(methods) + '\n};\n'
    code += Path(__file__).with_name('cases.cpp').read_text()
    msvc = os.name == 'nt'
    compiler = (str(Path(os.environ['VCToolsInstallDir']) / 'bin/Hostx64/x64/cl.exe') if msvc else
                shutil.which(os.environ.get('CXX', 'c++')))
    if not compiler:
        parser.error('A C++20 compiler is required; set CXX or VCToolsInstallDir')
    with tempfile.TemporaryDirectory(prefix='coa-resource-generation-') as directory:
        out = Path(directory)
        cpp, exe = out / 'resources.cpp', out / ('resources.exe' if msvc else 'resources')
        cpp.write_text(code, encoding='utf-8')
        flags = (['/nologo', '/std:c++20', '/EHsc', '/W4', '/WX', '/utf-8', str(cpp), '/Fe' + str(exe)]
                 if msvc else ['-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(exe)])
        subprocess.run([compiler, *flags], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print('PASS: resource-gain event loops, ranks, hostile/miss/trigger gates, per-cast/per-target grants,\n      ward/caps and mitigated-to-zero damaging hits')


if __name__ == '__main__':
    main()
