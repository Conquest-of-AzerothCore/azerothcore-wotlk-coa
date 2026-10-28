import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
source = (ROOT / 'src/server/coa/AscensionAchievementConditions.cpp').read_text(encoding='utf-8')
start_marker = 'if (achievementCriteria->requiredType != ACHIEVEMENT_CRITERIA_TYPE_LEARN_SKILLLINE_SPELLS)'
end_marker = 'return !data || data->Meets(mgr->GetPlayer(), nullptr);'
start = source.index(start_marker)
end = source.index(end_marker, start) + len(end_marker)
body = source[start:end]
fixture = '''
#include <cassert>
#include <cstddef>
constexpr unsigned ACHIEVEMENT_CRITERIA_TYPE_LEARN_SKILLLINE_SPELLS = 75;
struct AchievementCriteriaEntry { unsigned requiredType; };
struct AchievementEntry {};
struct CriteriaProgress {};
struct Player {};
struct AchievementCriteriaDataSet
{
    bool result;
    bool Meets(Player const*, std::nullptr_t) const { return result; }
};
struct AchievementMgr
{
    Player* player;
    Player* GetPlayer() const { return player; }
};
struct AchievementGlobalMgr
{
    AchievementCriteriaDataSet* dataSet = nullptr;
    AchievementCriteriaDataSet const* GetCriteriaDataSet(AchievementCriteriaEntry const*) const { return dataSet; }
};
AchievementGlobalMgr globalMgrInstance;
AchievementGlobalMgr* sAchievementMgr = &globalMgrInstance;

bool IsCompletedCriteria(AchievementMgr* mgr, AchievementCriteriaEntry const* achievementCriteria,
    AchievementEntry const*, CriteriaProgress const*)
{
    ''' + body + '''
}

int main()
{
    Player player;
    AchievementMgr mgr{&player};

    AchievementCriteriaEntry reachLevel{5};
    assert(IsCompletedCriteria(&mgr, &reachLevel, nullptr, nullptr));

    AchievementCriteriaEntry learnSkillLineSpells{75};
    sAchievementMgr->dataSet = nullptr;
    assert(IsCompletedCriteria(&mgr, &learnSkillLineSpells, nullptr, nullptr));

    AchievementCriteriaDataSet blocked{false};
    sAchievementMgr->dataSet = &blocked;
    assert(!IsCompletedCriteria(&mgr, &learnSkillLineSpells, nullptr, nullptr));

    AchievementCriteriaDataSet allowed{true};
    sAchievementMgr->dataSet = &allowed;
    assert(IsCompletedCriteria(&mgr, &learnSkillLineSpells, nullptr, nullptr));
}
'''
compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
assert compiler, 'A C++20 compiler is required'
with tempfile.TemporaryDirectory(prefix='learn-skillline-criteria-gate-') as directory:
    out = Path(directory)
    cpp = out / 'test.cpp'
    exe = out / ('test.exe' if os.name == 'nt' else 'test')
    cpp.write_text(fixture, encoding='utf-8')
    flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)]
             if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(exe)])
    subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
    subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
print('LearnSkillLineSpellsCriteriaDataGate: reach-level criteria untouched, '
      'ungated/allowed/blocked learn-skillline-spells criteria resolve correctly')
