from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from run import HERE, MODULE, method


def compile_run(compiler, directory, name, source):
    path = directory / (name + '.cpp')
    path.write_text(source, encoding='utf-8')
    executable = directory / (name + ('.exe' if os.name == 'nt' else ''))
    if Path(compiler).stem.lower() == 'cl':
        args = ['/nologo', '/std:c++20', '/EHsc', '/utf-8', '/I' + str(MODULE), str(path),
                '/Fo' + str(directory / (name + '.obj')), '/Fe' + str(executable)]
    else:
        args = ['-std=c++20', '-I' + str(MODULE), str(path), '-o', str(executable)]
    subprocess.run([compiler, *args], cwd=directory, check=True)
    subprocess.run([str(executable)], cwd=directory, check=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--autobalance', type=Path, required=True)
    parser.add_argument('--before-source', type=Path, required=True)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    compiler = shutil.which(os.environ.get('CXX', 'cl' if os.name == 'nt' else 'c++'))
    assert compiler, 'Enable the C++20 compiler environment.'
    source = (MODULE / 'AscensionManastorm.cpp').read_text(encoding='utf-8')
    item_source = (MODULE.parents[2] / 'src/server/game/Entities/Item/Item.cpp').read_text(encoding='utf-8')
    cache = (HERE / 'cache_delivery.cpp').read_text(encoding='utf-8')
    for marker, text, signature in [
        ('STORED_ITEM', source, 'static bool HasStoredItem('),
        ('STACK', source, 'static void AppendCacheStack('),
        ('DELIVER', source, 'void DeliverCaches('),
        ('ITEM_STATE', item_source, 'void Item::SetState('),
        ('ITEM_ADD_QUEUE', item_source, 'void Item::AddToUpdateQueueOf('),
        ('ITEM_REMOVE_QUEUE', item_source, 'void Item::RemoveFromUpdateQueueOf('),
    ]:
        cache = cache.replace('// ACTUAL_' + marker, method(text, signature))
    upstream = (args.autobalance / 'src/AutoBalance.cpp').read_text(encoding='utf-8')
    upstream_manifest = json.loads((args.autobalance / 'source.json').read_text(encoding='utf-8'))
    assert upstream_manifest['commit'] == '3020acda28a23b532ff9b7515dc4de41a4ef0be8'
    assert hashlib.sha256((args.autobalance / 'src/AutoBalance.cpp').read_bytes()).hexdigest() == \
        upstream_manifest['files']['src/AutoBalance.cpp']['sha256']
    scaling = r'''
#include "AscensionManastormRules.h"
#include <cassert>
#include <map>
#include <set>
using uint32 = std::uint32_t;
using namespace Ascension::Manastorm;
struct AutoBalanceInflectionPointSettings { float value, curveFloor, curveCeiling; };
struct AutoBalanceMapInfo { float adjustedPlayerCount = 1; };
struct Data { AutoBalanceMapInfo info; template<class T> T* GetDefault(char const*) { return &info; } };
struct Map { Data CustomData; };
uint32 GetMapMaxPlayers(Map*) { return 5; }
// ACTUAL_UPSTREAM
constexpr int BASE_ATTACK=0, MINDAMAGE=0, MAXDAMAGE=1, UNIT_FIELD_ATTACK_POWER=0, UNIT_MOD_ARMOR=0, BASE_VALUE=0;
struct Creature {
    uint32 health=0; float armor=0, weapon[2]{};
    struct Template { uint32 maxlevel=16; } definition;
    Template const* GetCreatureTemplate() const { return &definition; }
    uint32 GetGUID() const { return 1; }
    void SetMaxHealth(uint32 value) { health=value; }
    void SetHealth(uint32 value) { assert(value==health); }
    void SetInt32Value(int, int) { }
    void SetBaseWeaponDamage(int, int which, float value) { weapon[which]=value; }
    void SetStatFlatModifier(int, int, float value) { armor=value; }
    void UpdateArmor() { }
    void UpdateDamagePhysical(int) { }
};
struct Encounter { uint32 level=10,depth=1; std::set<uint32> members{1}; std::map<uint32,float> enemyDamage; };
struct Run { Encounter data; Encounter* encounter=&data; };
void Before(Creature* creature, Run& run, bool boss) { // ACTUAL_BEFORE
}
void After(Creature* creature, Run& run, bool boss) { // ACTUAL_AFTER
}
int main() {
    Map map;
    for (uint32 n=1;n<=5;++n) {
        map.CustomData.info.adjustedPlayerCount=float(n);
        assert(std::abs(PartyStatMultiplier(n)-getDefaultMultiplier(&map,{2.5f,0,1}))<0.000001f);
    }
    assert(PartyStatMultiplier(0)==PartyStatMultiplier(1));
    assert(PartyStatMultiplier(UINT32_MAX)==1.0f);
    assert(DepthStatMultiplier(0)==1 && std::isfinite(DepthStatMultiplier(UINT32_MAX)));
    for (uint32 level : {10u,20u,40u,80u}) for (uint32 depth : {1u,5u,25u,100u,16384u})
    for (uint32 n=1;n<=5;++n) for (bool boss : {false,true}) {
        Run before,after;
        for (Run* run : {&before,&after}) {
            run->encounter->level=level;run->encounter->depth=depth;run->encounter->members.clear();
            for (uint32 i=1;i<=n;++i) run->encounter->members.insert(i);
        }
        Creature a,b;Before(&a,before,boss);After(&b,after,boss);
        assert(b.health>0 && std::isfinite(b.weapon[0]) && std::isfinite(b.weapon[1]));
        if (n==5) assert(std::abs(double(a.health)-b.health)<=1 && std::abs(a.armor-b.armor)<0.01f);
        if (n==1 && depth==1) {
            assert(b.health<a.health*0.52 && b.health>a.health*0.51);
            assert(b.armor<a.armor*0.124);
            float oldDamage=a.weapon[1]*before.encounter->enemyDamage.at(1);
            float damage=b.weapon[1]*after.encounter->enemyDamage.at(1);
            assert(damage<oldDamage*0.174 && damage>oldDamage*0.172);
        }
        uint32 health=b.health; After(&b,after,boss); assert(b.health==health);
    }
}
'''
    old = args.before_source.read_text(encoding='utf-8')
    def scaling_block(text):
        start = text.index('            float const scale =', text.index('Creature* SpawnEnemy('))
        return text[start:text.index('            if (run.encounter->depth >= 6)', start)]
    scaling = scaling.replace('// ACTUAL_UPSTREAM', method(upstream, 'float getDefaultMultiplier('))
    scaling = scaling.replace('// ACTUAL_BEFORE', scaling_block(old)).replace('// ACTUAL_AFTER', scaling_block(source))
    with tempfile.TemporaryDirectory(prefix='manastorm-solo-tests-') as directory:
        compile_run(compiler, Path(directory), 'cache-delivery', cache)
        compile_run(compiler, Path(directory), 'scaling', scaling)
    report = {
        'passed': True,
        'cacheDelivery': 'Actual delivery and native item-queue methods: bags, stacks, full inventory, commit/read failure, '
                         'slot collision, unsaved bag, owner boundary, post-commit disconnect and replay.',
        'scaling': 'Actual before/after spawn blocks: 200 cases and exact pinned AutoBalance five-player curve.',
        'upstreamCommit': upstream_manifest['commit'],
        'sourceSHA256': hashlib.sha256((MODULE / 'AscensionManastorm.cpp').read_bytes()).hexdigest(),
    }
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
