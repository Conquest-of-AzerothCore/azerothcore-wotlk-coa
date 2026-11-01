from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
sys.dont_write_bytecode=True
ROOT=Path(os.environ.get('AREA52_PACKAGE_DIR',Path(__file__).resolve().parents[1]))
TX=Path(os.environ.get('AREA52_TRANSACTION_DIR',ROOT))
sys.path.insert(0,str(ROOT/'worker/tools'))
from refresh import RealmDatabase
from native_catalog import NativeCatalog
from worker_service import Remote,token_file

BASE=Path('/home/dml/games/ascension-freepick-test/private/build-library')
CONFIG=Path('/home/dml/games/ascension-freepick-test/private/pending-20261013/worldserver.conf')
UNIT=Path('/etc/systemd/system/area52-build-library.service')
TABLES=('area52_library_import','area52_library_refresh','area52_library_publication')
sql=RealmDatabase('ascension-freepick-database')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def system(*args):
    result=subprocess.run(['systemctl',*args],capture_output=True,text=True)
    if result.returncode:raise RuntimeError('Worker service operation failed; details withheld')
    return result.stdout.strip()

def exists(table):
    return sql("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='"+table+"';")=='1'

def preflight():
    meta=json.loads((ROOT/'worker-install.json').read_text())
    if sha(CONFIG)!=meta['config_before']:raise RuntimeError('Server configuration baseline changed')
    if (BASE/'runtime').exists() or (BASE/'runtime.pending').exists() or UNIT.exists():raise RuntimeError('Preserve existing worker installation; reconciliation required')
    if any(exists(table) for table in TABLES):raise RuntimeError('Preserve existing library tables; reconciliation required')
    catalog=NativeCatalog(ROOT/'worker/catalog-data.json',ROOT/'worker/library-validator',ROOT/'worker/catalog')
    remote=Remote(token_file(BASE/'github-token'))
    if len(remote.head())!=40:raise RuntimeError('Library repository readback failed')
    catalog.check()

def backup():
    preflight()
    directory=TX/'library-backup';directory.mkdir(exist_ok=False)
    shutil.copy2(CONFIG,directory/'worldserver.conf')
    (directory/'before.json').write_text(json.dumps({'tables_absent':list(TABLES),'runtime_absent':True,'unit_absent':True}))

def apply():
    preflight()
    for path in sorted((ROOT/'migrations').glob('*.sql')):sql(path.read_text())
    BASE.mkdir(mode=0o700,parents=True,exist_ok=True)
    pending=BASE/'runtime.pending'
    shutil.copytree(ROOT/'worker',pending)
    (pending/'library-validator').chmod(0o700)
    os.replace(pending,BASE/'runtime')
    content=CONFIG.read_bytes()
    if b'CoA.BuildLibrary.Enable' in content:raise RuntimeError('Unexpected library configuration key')
    CONFIG.write_bytes(content+b'\nCoA.BuildLibrary.Enable = 1\n')
    shutil.copyfile(ROOT/'area52-build-library.service',UNIT)
    UNIT.chmod(0o644)
    system('daemon-reload')
    (TX/'library-backup/after.json').write_text(json.dumps({'config_after':sha(CONFIG),'unit':sha(UNIT)}))

def verify():
    meta=json.loads((ROOT/'worker-install.json').read_text())
    if sha(CONFIG)!=meta['config_after'] or sha(UNIT)!=sha(ROOT/'area52-build-library.service'):raise RuntimeError('Worker configuration readback failed')
    for path in (ROOT/'worker').rglob('*'):
        if path.is_file() and sha(BASE/'runtime'/path.relative_to(ROOT/'worker'))!=sha(path):raise RuntimeError('Worker artifact readback failed')
    if not all(exists(table) for table in TABLES):raise RuntimeError('Library schema missing')
    NativeCatalog(BASE/'runtime/catalog-data.json',BASE/'runtime/library-validator',BASE/'runtime/catalog').check()

def rollback():
    backup_dir=TX/'library-backup'
    meta=json.loads((ROOT/'worker-install.json').read_text())
    original=backup_dir/'worldserver.conf'
    if sha(original)!=meta['config_before']:raise RuntimeError('Private configuration backup changed')
    allowed={meta['config_before'],hashlib.sha256(original.read_bytes()+b'\nCoA.BuildLibrary.Enable = 1\n').hexdigest()}
    if sha(CONFIG) not in allowed:raise RuntimeError('Server configuration drift; preserve for recovery')
    for table in TABLES:
        if not exists(table):continue
        condition=" WHERE id<>1 OR generation<>0 OR state<>'idle'" if table=='area52_library_refresh' else ''
        if sql('SELECT COUNT(*) FROM '+table+condition+';')!='0':raise RuntimeError('Library has new activity; preserve for recovery')
    if UNIT.exists():
        if sha(UNIT)!=sha(ROOT/'area52-build-library.service'):raise RuntimeError('Worker unit changed')
        status=subprocess.run(['systemctl','is-active','--quiet','area52-build-library.service']).returncode
        if status==0:raise RuntimeError('Worker already running; preserve for publication recovery')
        UNIT.unlink();system('daemon-reload')
    for directory in (BASE/'runtime',BASE/'runtime.pending'):
        if not directory.exists():continue
        for path in directory.rglob('*'):
            if path.is_file():
                source=ROOT/'worker'/path.relative_to(directory)
                if not source.is_file() or sha(path)!=sha(source):raise RuntimeError('Worker files changed; preserve for recovery')
        if directory.resolve().parent!=BASE.resolve():raise RuntimeError('Unexpected rollback path')
        shutil.rmtree(directory)
    CONFIG.write_bytes(original.read_bytes())
    for table in reversed(TABLES):
        if exists(table):sql('DROP TABLE '+table+';')

def start():
    verify()
    system('enable','--now','area52-build-library.service')
    if system('is-active','area52-build-library.service')!='active':raise RuntimeError('Worker did not start')
    receipt=TX/'publication/library-worker-started.json';receipt.parent.mkdir(exist_ok=True)
    receipt.write_text(json.dumps({'service':'area52-build-library.service','started':True}))

if __name__=='__main__':globals()[sys.argv[1]]()
