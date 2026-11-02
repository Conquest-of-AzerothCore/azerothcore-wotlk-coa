from pathlib import Path
import hashlib
import json
import shutil
import sys


def sha(data):
    return hashlib.sha256(data).hexdigest()


def prepare(root, settings, baseline_notes):
    root = Path(root)
    release = root / 'release'
    receipt = root / 'publication-inputs.json'
    if receipt.exists():
        verify(root)
        return
    if (root / 'release-config.json').exists():
        raise ValueError('Incomplete publication preparation requires reconciliation')
    source = Path(settings['templates'])
    templates = {
        name: source / name for name in
        ('publish_client_release.py', 'publication_common.py', 'publish_package.py', 'publication_tls.ps1')
    }
    templates['verify_channel_promotion.py'] = source.parent / 'verify_channel_promotion.py'
    configuration = {name: settings[name] for name in ('repo', 'tag', 'gh', 'launcher')}
    configuration['id'] = 'featured-catalog-' + sha((release / 'manifest.json').read_bytes())[:32]
    baseline = root / 'release-baseline'
    baseline.mkdir()
    for name, key in (('manifest.json', 'manifest'), ('area52.json', 'pointer')):
        entry = settings[key]
        data = Path(entry['path']).read_bytes()
        if sha(data) != entry['sha256']:
            raise ValueError('Publication baseline drift')
        (baseline / name).write_bytes(data)
    (baseline / 'PATCH-NOTES.md').write_bytes(baseline_notes)
    (release / 'PATCH-NOTES.md').write_bytes(baseline_notes)
    for name, path in templates.items():
        shutil.copyfile(path, root / name)
    (root / 'release-config.json').write_text(json.dumps(configuration, indent=2) + '\n', encoding='utf-8')
    files = {}
    for path in sorted(root.rglob('*')):
        if path.is_file():
            files[path.relative_to(root).as_posix()] = sha(path.read_bytes())
    receipt.write_text(json.dumps({'schema': 1, 'files': files, 'publication': 'prepared'}, indent=2) + '\n', encoding='utf-8')
    verify(root)


def verify(root):
    root = Path(root).resolve()
    receipt = json.loads((root / 'publication-inputs.json').read_text(encoding='utf-8'))
    if receipt['schema'] != 1 or receipt['publication'] != 'prepared':
        raise ValueError('Publication input seal invalid')
    for name, digest in receipt['files'].items():
        path = root / name
        if not path.resolve().is_relative_to(root) or path.is_symlink() or sha(path.read_bytes()) != digest:
            raise ValueError('Immutable publication input drift')
    for directory in ('release', 'release-baseline'):
        actual = {path.relative_to(root).as_posix() for path in (root / directory).rglob('*') if path.is_file()}
        expected = {name for name in receipt['files'] if name.startswith(directory + '/')}
        if actual != expected:
            raise ValueError('Unreviewed publication input added or removed')
    return receipt


if __name__=='__main__':
    verify(sys.argv[1])
