from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys,tempfile
from client_state import ensure_closed
ROOT=Path(os.environ.get('AREA52_PACKAGE_DIR',Path(__file__).resolve().parents[1]))
TX=Path(os.environ.get('AREA52_TRANSACTION_DIR',ROOT))
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def cfg():return json.loads((ROOT/'qualification.json').read_text())
def sql(database,statement):
    result=subprocess.run(['docker','exec','-i','ascension-freepick-database','mysql','--defaults-extra-file=/run/secrets/mysql-root.cnf','-BNr',database],input=statement,text=True,capture_output=True)
    if result.returncode:raise RuntimeError('Catalog SQL operation failed; credentials withheld')
    return result.stdout.strip()
def absent():
    if sql('acore_characters',"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='acore_characters' AND table_name='area52_draft_pet';")!='0':raise RuntimeError('Draft pet schema already exists; reconcile')
    if sql('acore_world','SELECT COUNT(*) FROM creature_template WHERE entry=9906554;')!='0' or sql('acore_world','SELECT COUNT(*) FROM creature_template_model WHERE CreatureID=9906554;')!='0':raise RuntimeError('Locust baseline changed')
def task(phase):
    row=cfg()
    if phase not in ('preflight','enable','verify'):raise RuntimeError('Invalid catalog task phase')
    source=ROOT/'hooks/Catalog-Task.ps1'
    bridge_root=Path(row['task_bridge_root']).resolve()
    if not str(bridge_root).startswith('/mnt/c/') or not bridge_root.is_dir():raise RuntimeError('Catalog task requires a Windows-accessible bridge directory')
    with tempfile.TemporaryDirectory(prefix='catalog-task-bridge-',dir=bridge_root) as temporary:
        bridge=Path(temporary);copy=bridge/source.name
        shutil.copyfile(source,copy)
        if sha(copy)!=sha(source):raise RuntimeError('Catalog task bridge hash mismatch')
        script=subprocess.check_output(['wslpath','-w',str(copy)],text=True).strip()
        result=subprocess.run([row['powershell'],'-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',script,'-Runtime',row['runtime_windows'],'-Phase',phase],cwd=bridge,capture_output=True)
        marker=('A52_CATALOG_TASK_OK:'+phase).encode()
        if result.returncode or marker not in result.stdout.splitlines():
            reason='script_not_accessible' if b'does not exist' in result.stderr else 'execution_or_readback_failed'
            raise RuntimeError('Catalog scheduled-task '+phase+' failed: exit='+str(result.returncode)+', reason='+reason+'; response bodies withheld')
def preflight():
    ensure_closed();row=cfg();absent()
    if sha(row['client'])!=row['client_before']:raise RuntimeError('Installed client baseline changed')
    if hashlib.sha256(sql('acore_characters',row['assignment_query']).encode()).hexdigest()!=row['assignments']:raise RuntimeError('Featured assignments changed; reassemble client catalog')
    if Path(row['runtime']).exists():raise RuntimeError('Existing catalog runtime must be preserved and reconciled')
    task('preflight')
def backup():
    preflight()
    path=TX/'catalog-client-before.MPQ'
    if path.exists():raise RuntimeError('Preserve existing client backup')
    shutil.copyfile(cfg()['client'],path)
    if sha(path)!=cfg()['client_before']:raise RuntimeError('Client backup mismatch')
def replace(source,target):
    target=Path(target);pending=target.with_name(target.name+'.featured-pending')
    if pending.exists():raise RuntimeError('Existing pending file requires recovery')
    shutil.copyfile(source,pending);pending.replace(target)
def apply():
    preflight();row=cfg()
    sql('acore_characters',(ROOT/'sql/pet.sql').read_text())
    sql('acore_world',(ROOT/'sql/locust.sql').read_text())
    shutil.copytree(ROOT/'runtime',row['runtime'])
    replace(ROOT/'client/patch-E.MPQ',row['client'])
def verify(runtime_mutable=False):
    row=cfg()
    if sha(row['client'])!=row['client_after']:raise RuntimeError('Client installation readback mismatch')
    for relative,digest in row['runtime_files'].items():
        if runtime_mutable and relative.startswith('outbox/'):
            continue
        if sha(Path(row['runtime'])/relative)!=digest:raise RuntimeError('Catalog runtime readback mismatch')
    for check in row['world']:
        if hashlib.sha256(sql('acore_world',check['query']).encode()).hexdigest()!=check['sha256']:raise RuntimeError('Locust migration readback mismatch')
    columns=sql('acore_characters',"SELECT IS_NULLABLE FROM information_schema.columns WHERE TABLE_SCHEMA='acore_characters' AND TABLE_NAME='area52_draft_pet' AND COLUMN_NAME='pet_number';")
    if columns!='YES':raise RuntimeError('Draft pet recovery schema mismatch')
def rollback():
    ensure_closed();row=cfg()
    client=Path(row['client']);backup=TX/'catalog-client-before.MPQ'
    if sha(backup)!=row['client_before'] or sha(client) not in (row['client_before'],row['client_after']):raise RuntimeError('Concurrent client edit; preserve rollback evidence')
    exists=sql('acore_characters',"SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='acore_characters' AND table_name='area52_draft_pet';")
    if exists=='1':
        if sql('acore_characters','SELECT COUNT(*) FROM area52_draft_pet;')!='0':raise RuntimeError('Draft pet activity exists; preserve data for recovery')
    for check in row['world']:
        actual=sql('acore_world',check['query'])
        if actual and hashlib.sha256(actual.encode()).hexdigest()!=check['sha256']:raise RuntimeError('Concurrent locust edit; preserve recovery data')
    runtime=Path(row['runtime'])
    if runtime.exists():
        expected=set(row['runtime_files'])
        actual={p.relative_to(runtime).as_posix() for p in runtime.rglob('*') if p.is_file()}
        if actual!=expected or any(sha(runtime/name)!=row['runtime_files'][name] for name in expected):raise RuntimeError('Runtime changed; preserve for recovery')
        if runtime.resolve()!=Path('/mnt/c/Users/danie/Documents/Codex/area52-featured-catalog-runtime').resolve():raise RuntimeError('Unexpected runtime rollback path')
    if exists=='1':sql('acore_characters','DROP TABLE area52_draft_pet;')
    sql('acore_world','DELETE FROM creature_template_model WHERE CreatureID=9906554; DELETE FROM creature_template WHERE entry=9906554;')
    if runtime.exists():
        shutil.rmtree(runtime)
    replace(backup,client)
def enable():
    verify(runtime_mutable=True);task('enable');task('verify')
if __name__=='__main__':
    {'preflight':preflight,'backup':backup,'apply':apply,'verify':verify,'rollback':rollback,'enable':enable}[sys.argv[1]]()
