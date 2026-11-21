import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
TOC = 'Interface/FrameXML/FrameXML.toc'
FRAMEXML = 'Interface/FrameXML/'
DEFAULT_LUA = ['XPHotspots.lua']


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def extend_toc(data, name='XPHotspots.lua'):
    text = data.decode('utf-8-sig')
    matches = [line for line in text.splitlines() if line.strip().lower() == name.lower()]
    if len(matches) > 1:
        raise ValueError(f'Duplicate {name} loader entries in the baseline')
    if matches:
        return data
    newline = b'\r\n' if b'\r\n' in data else b'\n'
    return data + (b'' if data.endswith(b'\n') else newline) + name.encode() + newline


def loader_entries(members, loads, lua_files):
    loads = [name.replace('/', '\\') for name in loads]
    for name in loads:
        if (FRAMEXML + name.replace('\\', '/')).lower() not in members:
            raise ValueError(f'Baseline has no {FRAMEXML}{name} to load')
    return loads + list(lua_files)


def package(baseline, output, executable, lua_files=None, loads=None):
    lua_files = list(lua_files or DEFAULT_LUA)
    baseline, output = Path(baseline).resolve(), Path(output).resolve()
    executable = str(Path(executable).resolve())
    if baseline == output or output.exists():
        raise ValueError('Output must be a new file, separate from the installed client')
    if not baseline.is_file():
        raise ValueError('Baseline archive does not exist')
    output.parent.mkdir(parents=True, exist_ok=True)
    original_hash = sha(baseline)

    def run(*args):
        result = subprocess.run([executable, *map(str, args)], capture_output=True)
        if result.returncode:
            raise RuntimeError(result.stderr.decode('utf-8', 'replace') or 'mpqcli operation failed')
        return result.stdout

    def inventory(directory):
        return {str(p.relative_to(directory)).replace('\\', '/').lower(): sha(p)
                for p in directory.rglob('*') if p.is_file() and not p.name.startswith('(')}

    with tempfile.TemporaryDirectory(prefix='hotspot-package-', dir=output.parent) as temporary:
        temp = Path(temporary)
        before, after = temp / 'before', temp / 'after'
        run('extract', '--keep', '--output', before, baseline)
        toc = next((p for p in before.rglob('*') if p.is_file() and
                    str(p.relative_to(before)).replace('\\', '/').lower() == TOC.lower()), None)
        if toc is None:
            raise ValueError('Baseline must contain the effective FrameXML.toc')
        wanted = inventory(before)
        payload = temp / 'payload'
        payload.mkdir()
        new_toc = payload / 'FrameXML.toc'
        toc_data = toc.read_bytes()
        for name in loader_entries(wanted, loads or [], lua_files):
            toc_data = extend_toc(toc_data, name)
        new_toc.write_bytes(toc_data)
        candidate = temp / 'candidate.MPQ'
        shutil.copyfile(baseline, candidate)
        members = [(TOC, new_toc)] + [(FRAMEXML + name, ROOT / 'client' / FRAMEXML / name) for name in lua_files]
        for member, source in members:
            run('add', '--overwrite', '--game', 'wow-wotlk', '--path', member.replace('/', '\\'),
                candidate, source)
            wanted[member.lower()] = sha(source)
        run('extract', '--keep', '--output', after, candidate)
        actual = inventory(after)
        if actual != wanted:
            raise RuntimeError('Archive readback differed from the expected complete member inventory')
        if sha(baseline) != original_hash:
            raise RuntimeError('Baseline changed while building; discard this candidate and retry')
        report = dict(baseline_sha256=original_hash, candidate_sha256=sha(candidate),
                      mpqcli_sha256=sha(executable), members_checked=len(actual),
                      changed_members=[member for member, _ in members], state='built; not installed or published')
        shutil.copyfile(candidate, output)
    output.with_suffix(output.suffix + '.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    return report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--mpqcli', type=Path, required=True)
    parser.add_argument('--lua', action='append', default=None,
                        help='FrameXML Lua file from client/Interface/FrameXML to add; repeatable, default XPHotspots.lua')
    parser.add_argument('--load', action='append', default=None,
                        help='FrameXML file already in the baseline to add to FrameXML.toc, loaded before the --lua files; '
                             'repeatable, path relative to Interface/FrameXML')
    args = parser.parse_args()
    print(json.dumps(package(args.baseline, args.output, args.mpqcli, args.lua, args.load), indent=2))


if __name__ == '__main__':
    main()
