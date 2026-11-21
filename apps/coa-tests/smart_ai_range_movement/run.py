import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
method = runpy.run_path(str(ROOT / 'apps/coa-tests/client_compat/run.py'))['method']
source = (ROOT / 'src/server/game/AI/SmartScripts/SmartAI.cpp').read_text(encoding='utf-8')
body = method(source, 'void SmartAI::SetCurrentRangeMode(bool on, float range)')
harness = r'''
#include <cassert>
constexpr unsigned UNIT_STATE_NO_COMBAT_MOVEMENT = 1;
constexpr unsigned UNIT_STATE_MELEE_ATTACKING = 2;
struct Unit {};
struct MotionMaster
{
    unsigned chases = 0;
    float distance = -1;
    void MoveChase(Unit*, float range) { ++chases; distance = range; }
};
struct Creature
{
    unsigned state = 0;
    unsigned attacks = 0;
    Unit* victim = nullptr;
    MotionMaster motion;
    bool HasUnitState(unsigned mask) { return state & mask; }
    Unit* GetVictim() { return victim; }
    MotionMaster* GetMotionMaster() { return &motion; }
    void Attack(Unit* target, bool melee) { assert(target == victim && melee); ++attacks; }
};
struct SmartAI
{
    Creature* me;
    bool _currentRangeMode = false;
    float _attackDistance = 0;
    bool mCanAutoAttack = false;
    void SetCurrentRangeMode(bool on, float range);
};
'''
harness += body + r'''
int main()
{
    for (unsigned state = 0; state < 4; ++state)
        for (bool hasVictim : {false, true})
            for (bool on : {false, true})
                for (bool autoAttack : {false, true})
                {
                    Unit victim;
                    Creature creature;
                    creature.state = state;
                    creature.victim = hasVictim ? &victim : nullptr;
                    SmartAI ai{&creature};
                    ai.mCanAutoAttack = autoAttack;
                    ai.SetCurrentRangeMode(on, 25.0f);
                    assert(ai._currentRangeMode == on && ai._attackDistance == 25.0f);
                    bool chase = hasVictim && !(state & UNIT_STATE_NO_COMBAT_MOVEMENT);
                    assert(creature.motion.chases == unsigned(chase));
                    if (chase)
                        assert(creature.motion.distance == 25.0f);
                    bool attack = hasVictim && !on && autoAttack && !(state & UNIT_STATE_MELEE_ATTACKING);
                    assert(creature.attacks == unsigned(attack));
                }
}
'''
harness = '#include <initializer_list>\n' + harness
compiler = os.environ.get('CXX') or shutil.which('c++') or shutil.which('g++')
if not compiler:
    raise SystemExit('A C++20 compiler is required')
with tempfile.TemporaryDirectory(prefix='smart-ai-range-') as directory:
    path = Path(directory)
    cpp = path / 'test.cpp'
    binary = path / 'test'
    cpp.write_text(harness, encoding='utf-8')
    subprocess.run([compiler, '-std=c++20', '-Wall', '-Wextra', '-Werror', str(cpp), '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
print('PASS: range changes respect combat movement and preserve melee attack behavior (32 states)')
