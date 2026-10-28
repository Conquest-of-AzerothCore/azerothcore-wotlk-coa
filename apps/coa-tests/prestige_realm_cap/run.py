from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[3]


def extract(source, signature):
    start = source.index(signature)
    opening = source.index("{", start)
    depth = 1
    end = opening + 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end]


def main():
    source = (ROOT / "src/server/coa/AscensionFreepick.cpp").read_text()
    reset = extract(source, "std::uint32_t PrestigeSpecialization(Player* player)")
    code = r'''#include "CoAPrestigeRules.h"
#include <cassert>
#include <map>
#include <string>
#include <vector>
using uint32 = std::uint32_t;
struct Entry { uint32 EntryId; };
constexpr uint32 ROW_RETAINED = 2;
struct Row
{
    uint32 Group = 0;
    uint32 Flags = 0;
    bool Has(uint32 flag) const { return Flags & flag; }
};
struct Catalog
{
    std::map<uint32, Row> rows;
    Row const* Find(uint32 id) const { auto i = rows.find(id); return i == rows.end() ? nullptr : &i->second; }
} Loaded;
struct Player
{
    bool freepick = true;
    uint32 active = 2;
    std::map<std::string, std::vector<Entry>> builds;
    unsigned notifications = 0;
    unsigned removed = 0;
};
bool IsFreepickHero(Player* p) { return p->freepick; }
uint32 ActiveSpecialization(Player* p) { return p->active; }
std::string SpecializationBuildSetting(uint32 n) { return "slot" + std::to_string(n); }
std::vector<Entry> StoredEntries(Player* p) { return p->builds["current"]; }
void Store(Player* p, std::vector<Entry> entries, std::string key = "current") { p->builds[key] = entries; }
void SyncSpells(Player* p, std::vector<Entry> before, std::vector<Entry> after)
{
    p->removed += before.size() - after.size();
}
void SendSpecializationState(Player* p) { ++p->notifications; }
''' + reset + r'''
int main()
{
    for (uint32 cap : {60u, 70u, 80u})
    {
        CoAPrestige::ActivationFacts f;
        f.requiredLevel = CoAPrestige::ResolveRequiredLevel(cap);
        f.specialization = 1;
        for (uint32 level : {cap - 1, cap, cap + 1})
        {
            f.level = level;
            assert(CoAPrestige::CheckActivation(f) == (level < cap ?
                CoAPrestige::Refusal::BelowLevel : CoAPrestige::Refusal::None));
        }
        CoAPrestige::State active{1, true, 3};
        assert(CoAPrestige::IsSpecializationSwitchAllowed(active, 3));
        assert(!CoAPrestige::IsSpecializationSwitchAllowed(active, 2));
    }
    Loaded.rows = {{1, {}}, {2, {}}, {4, {1, 0}}, {5, {0, ROW_RETAINED}}};
    for (uint32 slot : {0u, 1u, 2u, 3u})
    {
        Player p;
        p.active = slot;
        p.builds["current"] = {{1}, {2}, {4}, {5}};
        p.builds[SpecializationBuildSetting(slot)] = {{1}, {2}, {4}, {5}};
        p.builds["untouched"] = {{3}};
        assert(PrestigeSpecialization(&p) == 2);
        assert(p.builds["current"].size() == 2);
        assert(p.builds["current"][0].EntryId == 4 && p.builds["current"][1].EntryId == 5);
        assert(p.builds[SpecializationBuildSetting(slot)].size() == 2);
        assert(p.builds["untouched"].size() == 1);
        assert(p.removed == 2 && p.notifications == 1);
        assert(PrestigeSpecialization(&p) == 0);
        assert(p.removed == 2);
    }
    Player other;
    other.freepick = false;
    other.builds["current"] = {{1}};
    assert(PrestigeSpecialization(&other) == 0);
    assert(other.builds["current"].size() == 1 && other.notifications == 0);
}
'''
    with tempfile.TemporaryDirectory() as directory:
        cpp = Path(directory) / "prestige.cpp"
        binary = Path(directory) / "prestige"
        cpp.write_text(code)
        subprocess.run([os.environ.get("CXX", "c++"), "-std=c++20", "-Wall", "-Wextra", "-Werror",
                        "-I", str(ROOT / "modules/mod-coa-prestige/src"), str(cpp), "-o", str(binary)], check=True)
        subprocess.run([str(binary)], check=True)
    print("Prestige native cap/activation and active-slot reset checks passed; engine side effects mocked")


if __name__ == "__main__":
    main()
