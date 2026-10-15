CLI_DESCRIPTION = """Exercise real proficiency synchronization across level changes and repeated logins."""
import argparse
import os
from pathlib import Path
import re
import runpy
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref")
    args = parser.parse_args()
    path = "src/server/coa/AscensionCompat.cpp"
    source = (git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode()
              if args.source_ref else ROOT.joinpath(path).read_text(encoding="utf-8"))
    shared = (ROOT / "src/server/shared/SharedDefines.h").read_text(encoding="utf-8")
    code = "#include <algorithm>\n#include <array>\n#include <cassert>\n#include <cstdint>\n"
    code += "#include <map>\n#include <unordered_set>\n"
    code += "using uint8=std::uint8_t;using uint16=std::uint16_t;using uint32=std::uint32_t;\n"
    code += method(shared, "enum SkillType") + ";\n"
    for name in ("AscensionCustomClassData.h", "AscensionLiveBaselineData.h"):
        header = (ROOT / "src/server/coa" / name).read_text(encoding="utf-8")
        code += re.sub(r'^#include.*\n', '', header, flags=re.M)
    code += r'''
#define LOG_INFO(...) ((void)0)
#define LOG_ERROR(...) ((void)0)
constexpr uint32 SPEC_MASK_ALL=3;
struct Skill{uint16 step,value,maximum;};
struct Guid{uint32 GetCounter()const{return 1;}};
struct Player
{
    uint8 cls=17;uint16 level=3;uint32 defenseUpdates=0;
    std::unordered_set<uint32> spells;
    std::map<uint16,Skill> skills{{SKILL_DEFENSE,{0,3,10}},{SKILL_UNARMED,{0,2,10}},
        {SKILL_ALCHEMY,{2,94,150}},{SKILL_RIDING,{1,75,75}}};
    Guid GetGUID()const{return {};}
    uint8 getClass()const{return cls;}
    bool HasSpell(uint32 id)const{return spells.count(id)!=0;}
    void learnSpell(uint32 id,bool){spells.insert(id);}
    void removeSpell(uint32 id,uint32,bool){spells.erase(id);}
    uint16 GetMaxSkillValueForLevel()const{return level*5;}
    bool HasSkill(uint16 id)const{return skills.count(id)!=0;}
    uint16 GetSkillStep(uint16 id)const{return skills.at(id).step;}
    void SetSkill(uint16 id,uint16 step,uint16 value,uint16 max)
    {if(value)skills[id]={step,value,max};else skills.erase(id);}
    void UpdateDefenseBonusesMod(){++defenseUpdates;}
};
bool IsAscensionCustomClass(Player const* p){return p && p->cls>=12 && p->cls<=32;}
struct Manager{bool GetSpellInfo(uint32){return true;}} manager;
auto sSpellMgr=&manager;
struct Service
{
    std::unordered_set<uint32> _proficiencySynchronizations;
'''
    code += method(source, "void SynchronizeProficiencies(") + "};\n"
    code += r'''
int main()
{
    Service service;
    for (uint8 cls=12;cls<=32;++cls)
    {
        Player p;p.cls=cls;
        for (uint16 level : std::array<uint16,5>{3,4,60,80,20})
        {
            p.level=level;
            for (int login=0;login<2;++login)
            {
                auto before=p.defenseUpdates;service.SynchronizeProficiencies(&p);
                for(uint16 id : std::array<uint16,2>{SKILL_DEFENSE,SKILL_UNARMED})
                {assert(p.skills.at(id).value==level*5);assert(p.skills.at(id).maximum==level*5);}
                assert(p.defenseUpdates==before+1);
                assert(p.skills.at(SKILL_ALCHEMY).value==94 && p.skills.at(SKILL_ALCHEMY).maximum==150);
                assert(p.skills.at(SKILL_RIDING).value==75 && p.skills.at(SKILL_RIDING).step==1);
                assert(service._proficiencySynchronizations.empty());
            }
        }
    }
    Player legacy;legacy.cls=1;service.SynchronizeProficiencies(&legacy);
    assert(legacy.skills.at(SKILL_DEFENSE).value==3 && legacy.skills.at(SKILL_UNARMED).value==2);
    Player missing;missing.skills.erase(SKILL_UNARMED);service.SynchronizeProficiencies(&missing);
    assert(!missing.HasSkill(SKILL_UNARMED));
}
'''
    assert "SynchronizeProficiencies(player);" in method(source, "void OnPlayerLevelChanged(")
    compiler = str(Path(os.environ["VCToolsInstallDir"]) / "bin/Hostx64/x64/cl.exe")
    with tempfile.TemporaryDirectory(prefix="coa-combat-skills-") as directory:
        out = Path(directory)
        cpp, exe = out / "skills.cpp", out / "skills.exe"
        cpp.write_text(code, encoding="utf-8")
        subprocess.run([compiler, "/nologo", "/std:c++20", "/EHsc", "/W4", "/WX", "/utf-8",
                        str(cpp), "/Fe" + str(exe)], cwd=out, check=True, timeout=60)
        subprocess.run([str(exe)], cwd=out, check=True, timeout=15)
    print("PASS: all CoA classes, login/level changes, Defense bonuses, professions and legacy classes")


if __name__ == "__main__":
    main()
