import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]
source = (ROOT / 'src/server/game/Achievements/AchievementMgr.cpp').read_text(encoding='utf-8')
start = source.index('bool AchievementGlobalMgr::IsStatisticCriteria(')
end = source.index('bool AchievementGlobalMgr::IsAverageCriteria(', start)
fixture = '''
#include <cassert>
#include <map>
struct AchievementEntry { unsigned categoryId; };
struct AchievementCriteriaEntry { unsigned referredAchievement; };
struct AchievementCategoryEntry { unsigned ID; unsigned parentCategory; };
template<class T> struct Store
{
    std::map<unsigned, T> rows;
    T const* LookupEntry(unsigned id) const
    {
        auto itr = rows.find(id);
        return itr == rows.end() ? nullptr : &itr->second;
    }
};
Store<AchievementEntry> sAchievementStore;
Store<AchievementCategoryEntry> sAchievementCategoryStore;
constexpr unsigned ACHIEVEMENT_CATEGORY_STATISTICS = 1, ACHIEVEMENT_CATEOGRY_GENERAL = 2;
struct AchievementGlobalMgr
{
    bool IsStatisticCriteria(AchievementCriteriaEntry const*) const;
    bool IsStatisticAchievement(AchievementEntry const*) const;
};
''' + source[start:end] + '''
int main()
{
    AchievementGlobalMgr mgr;
    AchievementEntry missing{14921};
    assert(!mgr.IsStatisticAchievement(&missing));
    assert(!mgr.IsStatisticAchievement(nullptr));
    assert(!mgr.IsStatisticCriteria(nullptr));
    AchievementCriteriaEntry orphan{999};
    assert(!mgr.IsStatisticCriteria(&orphan));
    sAchievementCategoryStore.rows = {
        {1, {1, 0}}, {2, {2, 0}}, {3, {3, 1}}, {4, {4, 2}}, {5, {5, 999}}, {6, {6, 3}}
    };
    AchievementEntry statistics{3}, general{4}, brokenParent{5}, nestedStatistics{6};
    assert(mgr.IsStatisticAchievement(&statistics));
    assert(mgr.IsStatisticAchievement(&nestedStatistics));
    assert(!mgr.IsStatisticAchievement(&general));
    assert(!mgr.IsStatisticAchievement(&brokenParent));
    sAchievementStore.rows[490] = missing;
    AchievementCriteriaEntry nexus{490};
    assert(!mgr.IsStatisticCriteria(&nexus));
    sAchievementCategoryStore.rows[14921] = {14921, 2};
    assert(!mgr.IsStatisticCriteria(&nexus));
    sAchievementStore.rows[491] = statistics;
    AchievementCriteriaEntry statisticCriteria{491};
    assert(mgr.IsStatisticCriteria(&statisticCriteria));
}
'''
compiler = shutil.which(os.environ.get('CXX', 'cl.exe' if os.name == 'nt' else 'c++'))
assert compiler, 'A C++20 compiler is required'
with tempfile.TemporaryDirectory(prefix='achievement-category-') as directory:
    out = Path(directory)
    cpp = out / 'test.cpp'
    exe = out / ('test.exe' if os.name == 'nt' else 'test')
    cpp.write_text(fixture, encoding='utf-8')
    flags = (['/nologo', '/std:c++20', '/EHsc', str(cpp), '/Fe' + str(exe)]
             if Path(compiler).stem.lower() == 'cl' else ['-std=c++20', str(cpp), '-o', str(exe)])
    subprocess.run([compiler, *flags], cwd=out, check=True, timeout=120)
    subprocess.run([str(exe)], cwd=out, check=True, timeout=30)
print('Achievement classification: missing records and valid ancestry passed')
