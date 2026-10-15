import gzip
import io
import json
import sys
import tarfile
from pathlib import Path


sys.path.insert(0, str(Path(__file__).resolve().parent))
import archive


def make_pack(members):
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode='w') as writer:
        for name, payload in members.items():
            info = tarfile.TarInfo(name)
            info.size = len(payload)
            writer.addfile(info, io.BytesIO(payload))
    return buffer.getvalue()


def test_safe_relative_accepts_archive_paths():
    assert archive.safe_relative('cachedata/by-mode/x/questcache.tsv.gz')
    assert archive.safe_relative('atlas/abe10abd7603c222b6ce.json.gz')


def test_safe_relative_rejects_traversal():
    for path in ('../secret', 'a/../../b', '/absolute', '', 'a/..'):
        try:
            archive.safe_relative(path)
        except ValueError:
            continue
        raise AssertionError(f'accepted unsafe path: {path}')


def test_safe_relative_rejects_unexpected_characters():
    for path in ('a b/c', 'drive:\\file', 'semi;colon'):
        try:
            archive.safe_relative(path)
        except ValueError:
            continue
        raise AssertionError(f'accepted unsafe path: {path}')


def test_pack_members_indexes_by_digest():
    payload = b'quest data'
    members = archive.pack_members(make_pack({'anything.bin': payload}))
    assert members == {archive.digest(payload): payload}


def test_pack_members_skips_directories():
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode='w') as writer:
        info = tarfile.TarInfo('folder')
        info.type = tarfile.DIRTYPE
        writer.addfile(info)
    assert archive.pack_members(buffer.getvalue()) == {}


def test_download_refuses_network_when_offline():
    try:
        archive.download('https://example.test/x', True)
    except ValueError as error:
        assert 'Offline' in str(error)
        return
    raise AssertionError('offline download did not refuse')


def test_fetch_cache_files_verifies_and_writes(tmp_path=None):
    import tempfile
    payload = b'quest rows'
    pack = make_pack({'member': payload})
    manifest = {
        'release': 'release-1',
        'packs': {'pack-a.tar': {'bytes': len(pack), 'sha256': archive.digest(pack),
                                 'url': 'https://example.test/pack-a.tar'}},
        'files': {'cachedata/by-mode/x/questcache.tsv.gz': {
            'bytes': len(payload), 'sha256': archive.digest(payload),
            'parts': [{'bytes': len(payload), 'pack': 'pack-a.tar', 'sha256': archive.digest(payload)}]}},
    }
    original = archive.download
    archive.download = lambda url, offline: pack
    try:
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            release, available, written = archive.fetch_cache_files(manifest, ['cachedata/'], cache, False)
            assert release == 'release-1'
            assert available == ['cachedata/by-mode/x/questcache.tsv.gz']
            assert written == available
            stored = cache / 'release-1/cachedata/by-mode/x/questcache.tsv.gz'
            assert stored.read_bytes() == payload
            _, _, again = archive.fetch_cache_files(manifest, ['cachedata/'], cache, True)
            assert again == []
    finally:
        archive.download = original


def test_fetch_cache_files_rejects_bad_pack_checksum():
    import tempfile
    manifest = {
        'release': 'release-1',
        'packs': {'pack-a.tar': {'bytes': 1, 'sha256': 'deadbeef', 'url': 'https://example.test/p'}},
        'files': {'cachedata/x.gz': {'bytes': 1, 'sha256': 'deadbeef',
                                     'parts': [{'bytes': 1, 'pack': 'pack-a.tar', 'sha256': 'deadbeef'}]}},
    }
    original = archive.download
    archive.download = lambda url, offline: b'not the pack'
    try:
        with tempfile.TemporaryDirectory() as folder:
            archive.fetch_cache_files(manifest, ['cachedata/'], Path(folder), False)
    except ValueError as error:
        assert 'checksum mismatch' in str(error)
        return
    finally:
        archive.download = original
    raise AssertionError('bad pack checksum was accepted')


def test_fetch_cache_files_requires_a_match():
    import tempfile
    manifest = {'release': 'r', 'packs': {}, 'files': {'other/x.gz': {'bytes': 0, 'sha256': '', 'parts': []}}}
    try:
        with tempfile.TemporaryDirectory() as folder:
            archive.fetch_cache_files(manifest, ['cachedata/'], Path(folder), True)
    except ValueError as error:
        assert 'matched' in str(error)
        return
    raise AssertionError('empty selection was accepted')


def pinned_dataset(release='release-1'):
    return json.dumps({'schema': 'ascension-dataset-1', 'release': release, 'packs': {}, 'files': {}}).encode()


def test_read_dataset_rejects_an_unpinned_manifest():
    import tempfile
    original = archive.download
    archive.download = lambda url, offline: pinned_dataset('moved-on')
    try:
        with tempfile.TemporaryDirectory() as folder:
            archive.read_dataset(Path(folder), False)
    except ValueError as error:
        assert 'checksum mismatch' in str(error)
        return
    finally:
        archive.download = original
    raise AssertionError('an unpinned dataset manifest was accepted')


def test_read_dataset_replaces_a_stale_cached_manifest():
    import tempfile
    pinned = pinned_dataset()
    original_download, original_sha256 = archive.download, archive.DATASET_SHA256
    archive.download = lambda url, offline: pinned
    archive.DATASET_SHA256 = archive.digest(pinned)
    try:
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            (cache / 'cache.json').write_bytes(pinned_dataset('stale'))
            assert archive.read_dataset(cache, False)['release'] == 'release-1'
            assert (cache / 'cache.json').read_bytes() == pinned
            assert archive.read_dataset(cache, True)['release'] == 'release-1'
    finally:
        archive.download, archive.DATASET_SHA256 = original_download, original_sha256


def atlas_files(revision='r1', zone_payload=b'{"points": []}'):
    manifest = {'schema': 'ascension-atlas-1', 'revision': revision,
                'zones': [{'key': 'elwynn', 'name': 'Elwynn Forest', 'file': 'atlas/elwynn.json.gz'}]}
    return {'atlas-manifest.json.gz': gzip.compress(json.dumps(manifest).encode()),
            'atlas/elwynn.json.gz': gzip.compress(zone_payload)}


def serve(files):
    return lambda url, offline: files[url[len(archive.PAGES_URL):]]


def test_fetch_atlas_verifies_cached_files_against_the_lock():
    import tempfile
    files = atlas_files()
    original = archive.download
    archive.download = serve(files)
    try:
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            _, manifest_sha256, _, written = archive.fetch_atlas([], cache, False)
            assert written == ['atlas/elwynn.json.gz']
            lock = json.loads((cache / 'atlas/lock.json').read_text(encoding='utf-8'))
            assert lock['manifest'] == manifest_sha256
            assert lock['files'] == {'atlas/elwynn.json.gz': archive.digest(files['atlas/elwynn.json.gz'])}
            assert archive.fetch_atlas([], cache, True)[3] == []
            stored = cache / 'atlas/atlas/elwynn.json.gz'
            stored.write_bytes(gzip.compress(b'{"points": ["tampered"]}'))
            assert archive.fetch_atlas([], cache, False)[3] == ['atlas/elwynn.json.gz']
            assert stored.read_bytes() == files['atlas/elwynn.json.gz']
    finally:
        archive.download = original


def test_fetch_atlas_refuses_a_changed_manifest_without_refresh():
    import tempfile
    original = archive.download
    try:
        with tempfile.TemporaryDirectory() as folder:
            cache = Path(folder)
            archive.download = serve(atlas_files())
            archive.fetch_atlas([], cache, False)
            changed = atlas_files('r2', b'{"points": [1]}')
            (cache / 'atlas/atlas-manifest.json.gz').write_bytes(changed['atlas-manifest.json.gz'])
            archive.download = serve(changed)
            try:
                archive.fetch_atlas([], cache, False)
            except ValueError as error:
                assert 'lock.json' in str(error)
            else:
                raise AssertionError('a changed atlas manifest was accepted without --refresh-atlas')
            revision, _, _, written = archive.fetch_atlas([], cache, False, refresh=True)
            assert revision == 'r2'
            assert written == ['atlas/elwynn.json.gz']
    finally:
        archive.download = original


def main():
    failures = 0
    for name, test in sorted(globals().items()):
        if not name.startswith('test_') or not callable(test):
            continue
        try:
            test()
        except AssertionError as error:
            failures += 1
            print(f'FAIL {name}: {error}')
        else:
            print(f'PASS {name}')
    print('FAILED' if failures else 'OK')
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
