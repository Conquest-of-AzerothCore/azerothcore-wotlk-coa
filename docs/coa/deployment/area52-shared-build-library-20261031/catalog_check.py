from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
W=Path(os.environ['AREA52_LIBRARY_WORKSPACE']);T=W/'shared-build-library-20261031'
S=Path('/home/dml/builds/area52-playerbots-20261026/source')
A=Path('/home/dml/games/ascension-freepick-test/private/active-build-source')
sys.path[:0]=[str(S/'apps/coa-tests'),str(W/'build-architect-library/tools'),str(W/'build-architect-library/tests')]
from coa_talent_catalog import STUBS
from native_wire import encode_wire
from test_library import sample
from native_catalog import NativeCatalog
D=T/'catalog';D.mkdir(exist_ok=True)
F=T/'catalog-native';F.mkdir(exist_ok=True)
hashes={}
for name in ('CharacterAdvancement.dbc','CharacterAdvancementClassTypes.dbc','CharacterAdvancementEssence.dbc','MysticEnchant.dbc','Spell.dbc'):
    data=subprocess.check_output(['docker','exec','ascension-freepick-worldserver','cat','/data/dbc/'+name])
    (D/name).write_bytes(data);hashes[name]=hashlib.sha256(data).hexdigest()
for name,content in STUBS.items():(F/name).write_text(content)
names=['AscensionFreePick.h','AscensionFreePickRules.cpp','Area52BuildSelection.h','Area52BuildProtocol.h','AscensionMysticEnchantCatalog.h','AscensionMysticEnchantCatalog.cpp','AscensionCoATalentState.h','AscensionCoATalentData.h']
source_hashes={}
for name in names:
    rel=Path('src/server/coa')/name;p=A/rel if (A/rel).exists() else S/rel
    shutil.copyfile(p,F/name);source_hashes[str(rel)]=hashlib.sha256(p.read_bytes()).hexdigest()
args=['docker','run','--rm','--network','none','-v',str(S)+':/workspace:ro','-v',str(T)+':/results',
      'local/ascension-freepick-builder:20261001','g++','-std=c++20','-O2','-I/results/catalog-native',
      '-I/workspace/src/server/shared/DataStores','-I/workspace/src/common','/results/catalog_validator.cpp',
      '/results/catalog-native/AscensionFreePickRules.cpp','/results/catalog-native/AscensionMysticEnchantCatalog.cpp',
      '/workspace/src/server/shared/DataStores/ClientDBC.cpp','-o','/results/library-validator']
subprocess.run(args,check=True)
def validate(build):
    wire=encode_wire(build,123,'Alias',1,2)
    return subprocess.check_output([str(T/'library-validator'),str(D)],input=wire.hex()+'\n',text=True).strip()
build=sample();build['RandomEnchants']=[]
assert validate(build)=='OK',validate(build)
bad=dict(build,Spells=[dict(build['Spells'][0],Spell=999999999)])
assert validate(bad).startswith('REJECT')
bad=dict(build,RandomEnchants=[{'Enchant':86576,'Stacks':17,'Level':80}])
assert validate(bad).startswith('REJECT')
rows=subprocess.check_output([str(T/'library-validator'),str(D)],input='CATALOG\n',text=True).splitlines()
assert rows[-1]=='END'
spells=sorted({int(s[2:]) for s in rows if s.startswith('S ')})
enchants=sorted({int(s[2:]) for s in rows if s.startswith('E ')})
record={'schema':1,'catalog':'area52-v1','files':hashes,'source':source_hashes,'spell_ids':spells,'enchant_ids':enchants,'validator_sha256':hashlib.sha256((T/'library-validator').read_bytes()).hexdigest()}
mounts=json.loads(subprocess.check_output(['docker','inspect','ascension-freepick-worldserver','--format','{{json .Mounts}}'],text=True))
effective={}
for name in hashes:
    target='/data/dbc/'+name
    candidates=[m for m in mounts if target==m['Destination'] or target.startswith(m['Destination']+'/')]
    mount=max(candidates,key=lambda m:len(m['Destination']))
    path=Path(mount['Source'])/target[len(mount['Destination']):].lstrip('/')
    assert hashlib.sha256(path.read_bytes()).hexdigest()==hashes[name]
    effective[name]=str(path)
record['effective_sources']=effective
record['effective_source_root']=str(A)
record['fallback_source_root']=str(S)
(T/'catalog-data.json').write_text(json.dumps(record,indent=2))
validator=NativeCatalog(T/'catalog-data.json',T/'library-validator',D)
assert validator.validate(build) is None
assert validator.validate(bad) is not None
source=(T/'source/src/server/coa/Area52BuildService.cpp').read_text()
functions=[]
for signature in ('std::string Hex(', 'bool Unhex(', 'bool Id(', 'bool Current(', 'bool ReadRecord(', 'char const* Validate('):
    start=source.index(signature);end=source.index('\n}\n',start)+3
    functions.append(source[start:end])
(T/'routing_actual_functions.inc').write_text('\n'.join(functions))
subprocess.run(['docker','run','--rm','--network','none','-v',str(T)+':/results',
    'local/ascension-freepick-builder:20261001','g++','-std=c++20','-I/results/catalog-native',
    '-I/results/source/src/server/coa','/results/routing_fixture.cpp','-o','/results/routing-fixture'],check=True)
subprocess.run([str(T/'routing-fixture')],check=True)
import unittest
suite=unittest.defaultTestLoader.discover(str(W/'build-architect-library/tests'))
assert unittest.TextTestRunner(verbosity=1).run(suite).wasSuccessful()
(T/'catalog-checks.json').write_text(json.dumps({'passed':True,'spells':len(spells),'enchants':len(enchants),'scope':'actual native loader, Select and ValidateSlots; individual player ownership and runtime eligibility remain native activation checks'},indent=2))
print('Native catalog helper and actual effective DBC validation passed')
