from pathlib import Path
import os
import subprocess
import tempfile
import json
import hashlib

ROOT = Path(__file__).resolve().parents[3]


def main():
    baseline = os.environ.get('AREA52_PRESTIGE_BASELINE')
    if baseline:
        integration = ROOT / 'modules/mod-coa-prestige/integrations/area52'
        manifest = json.loads((integration / 'baseline.json').read_text())
        digest = lambda text: hashlib.sha256(text.encode()).hexdigest()
        prerequisite = os.environ.get('AREA52_PRESTIGE_PREREQUISITE')
        prerequisite_manifest = {}
        if prerequisite:
            prerequisite = Path(prerequisite)
            prerequisite_manifest = json.loads((prerequisite / 'baseline.json').read_text())
            for name, hashes in prerequisite_manifest.items():
                assert hashes['after_normalized_sha256'] == manifest[name]['before_normalized_sha256'], name
        with tempfile.TemporaryDirectory() as directory:
            destination = Path(directory)
            for name, hashes in manifest.items():
                path = Path(baseline) / name
                if hashes['before_normalized_sha256'] is not None:
                    text = path.read_text()
                    expected = prerequisite_manifest.get(name, hashes)['before_normalized_sha256']
                    assert digest(text) == expected, name
                    target = destination / name
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(text)
                else:
                    assert not path.exists(), name
            if prerequisite:
                subprocess.run(['git', 'apply', '--check', str(prerequisite / 'repair.patch')],
                               cwd=destination, check=True)
                subprocess.run(['git', 'apply', str(prerequisite / 'repair.patch')], cwd=destination, check=True)
                for name, hashes in prerequisite_manifest.items():
                    assert digest((destination / name).read_text()) == hashes['after_normalized_sha256'], name
            subprocess.run(['git', 'apply', '--check', str(integration / 'prestige.patch')],
                           cwd=destination, check=True)
            subprocess.run(['git', 'apply', str(integration / 'prestige.patch')], cwd=destination, check=True)
            for name, hashes in manifest.items():
                assert digest((destination / name).read_text()) == hashes['after_normalized_sha256'], name
            subprocess.run(['git', 'apply', '--reverse', str(integration / 'prestige.patch')],
                           cwd=destination, check=True)
            for name, hashes in manifest.items():
                path = destination / name
                if hashes['before_normalized_sha256'] is None:
                    assert not path.exists(), name
                else:
                    assert digest(path.read_text()) == hashes['before_normalized_sha256'], name
            if prerequisite:
                subprocess.run(['git', 'apply', '--reverse', str(prerequisite / 'repair.patch')],
                               cwd=destination, check=True)
                for name, hashes in prerequisite_manifest.items():
                    assert digest((destination / name).read_text()) == hashes['before_normalized_sha256'], name
    code = r'''#include "AscensionPrestigeReset.h"
#include <array>
#include <cassert>
#include <map>
#include <set>
#include <string>
#include <vector>
#include <cstdint>
struct Field { unsigned value = 0; bool operator==(Field const&) const = default; };
struct PendingBars { std::map<unsigned, unsigned> Buttons; };
struct State { bool Loaded = true; bool Busy = false; };
constexpr unsigned PLAYERSPELL_REMOVED = 3;
struct Learned { unsigned specMask = 0; unsigned State = 0; };
struct SpellInfo { unsigned SpellLevel = 1; };
struct SpellManager
{
    SpellInfo low{1}, high{60};
    SpellInfo const* GetSpellInfo(unsigned id) { return id == 501 ? &low : &high; }
} SpellManagerInstance;
auto* sSpellMgr = &SpellManagerInstance;
struct Custom
{
    PendingBars bars;
    State state;
    template<class T> T* Get(char const*)
    {
        if constexpr (std::is_same_v<T, State>) return &state;
        else return &bars;
    }
};
class Player
{
public:
    Custom CustomData;
    bool applies = true, world = true, alive = true, combat = false, battleground = false;
    bool arena = false, teleport = false, buildReady = true, casting = false, applyFailure = false;
    unsigned native = 0, specs = 2, preset = 0, unlockedPresets = 2, notifications = 0, sync = 0;
    std::map<std::string, std::vector<Field>> settings;
    std::set<unsigned> spells, collection{111, 222, 333};
    std::map<unsigned, Learned> history{{500, {0, 0}}, {501, {0, 0}}, {502, {2, 0}}, {503, {0, 0}}};
    std::map<unsigned, Learned*> GetSpellMap()
    {
        std::map<unsigned, Learned*> result;
        for (auto& [spell, value] : history) result[spell] = &value;
        return result;
    }
    bool IsInWorld() const { return world; }
    bool FindMap() const { return world; }
    bool IsAlive() const { return alive; }
    bool IsInCombat() const { return combat; }
    bool InBattleground() const { return battleground; }
    bool InArena() const { return arena; }
    bool IsBeingTeleported() const { return teleport; }
    bool HasSpell(unsigned spell) const { return spells.contains(spell); }
    unsigned GetActiveSpec() const { return native; }
    unsigned GetSpecsCount() const { return specs; }
    unsigned GetLevel() const { return 80; }
    std::vector<Field> const* FindPlayerSettings(std::string const& key) const
    {
        auto i = settings.find(key);
        return i == settings.end() ? nullptr : &i->second;
    }
    void UpdatePlayerSetting(std::string const& key, unsigned index, unsigned value)
    {
        auto& v = settings[key];
        if (v.size() <= index) v.resize(index + 1);
        v[index].value = value;
    }
};
namespace AscensionMysticEnchant
{
constexpr char StateKey[] = "state";
bool CanChange(Player* p, State const* s)
{
    return p->applies && p->world && p->alive && !p->combat && !p->battleground && !p->arena &&
        !p->casting && s && s->Loaded && !s->Busy;
}
unsigned ActivePreset(Player const* p) { return p->preset; }
unsigned PresetCount(Player const* p) { return p->unlockedPresets; }
std::string Setting(Player const* p) { return "core.freepick.mystic." + std::to_string(p->preset); }
std::array<unsigned, 17> ReadSlots(Player const* p)
{
    std::array<unsigned, 17> slots{};
    if (auto v = p->FindPlayerSettings(Setting(p)))
        for (unsigned i = 0; i < slots.size() && i < v->size(); ++i) slots[i] = (*v)[i].value;
    return slots;
}
void Synchronize(Player* p) { ++p->sync; }
void SendSlots(Player* p) { ++p->notifications; }
#include "Area52PrestigeEnchantReset.inc"
}
namespace Area52Build
{
bool CanSwitchSpecialization(Player* p) { return p->buildReady; }
void PauseAutoLearnForReset(Player*) { }
void RestoreSpecialization(Player*) { }
}
namespace AscensionFreePick
{
constexpr char ActiveSlotSetting[] = "core.area52.spec.active";
constexpr char ActiveBuildSetting[] = "core.area52.active_build";
constexpr char PendingBarsKey[] = "pending";
constexpr std::array<unsigned, 20> SpecializationSpells{100,101,102,103,104,105,106,107,108,109,
    110,111,112,113,114,115,116,117,118,119};
int Data = 0;
std::set<unsigned> ClassSpells{500, 501, 502};
bool Applies(Player const* p) { return p && p->applies; }
bool Validate(int, unsigned, std::vector<unsigned>, std::vector<unsigned>) { return true; }
std::vector<Field> KnownEntries(Player* p) { return p->settings["selected"]; }
bool Apply(Player* p, std::vector<unsigned>, bool charge, bool specializationChange)
{
    assert(!charge && specializationChange);
    if (p->applyFailure) return false;
    p->settings["selected"].clear();
    return true;
}
std::string SlotSetting(unsigned slot, char const* suffix)
{
    return "core.area52.spec." + std::to_string(slot) + suffix;
}
void StoreValues(Player* p, std::string const& key, std::vector<unsigned> const& values)
{
    assert(values.empty());
    for (auto& v : p->settings[key]) v.value = 0;
}
void SendArea52Advancement(Player* p) { ++p->notifications; }
void SendArea52Specialization(Player* p) { ++p->notifications; }
#include "Area52PrestigeReset.inc"
}
Player Make(unsigned build, unsigned enchant)
{
    Player p;
    p.native = (enchant + 1) % 2;
    p.preset = enchant;
    p.settings["core.area52.spec.active"] = {{build}};
    p.settings["selected"] = {{1}, {2}, {3}};
    p.settings["core.area52.active_build"] = {{700}, {0}, {1}, {1}};
    for (unsigned b = 0; b < 20; ++b)
    {
        p.spells.insert(100 + b);
        for (auto suffix : {".entries", ".ranks", ".active_build", ".bars"})
            p.settings[AscensionFreePick::SlotSetting(b, suffix)] = {{b + 1}, {b + 20}};
    }
    p.settings["core.freepick.mystic.0"] = {{111}, {222}};
    p.settings["core.freepick.mystic.1"] = {{333}};
    p.CustomData.bars.Buttons[1] = 123;
    return p;
}
int main()
{
    using namespace AscensionFreePick;
    for (unsigned build = 0; build < 20; ++build)
        for (unsigned enchant = 0; enchant < 20; ++enchant)
        {
            Player p = Make(build, enchant);
            p.unlockedPresets = 20;
            for (unsigned i = 2; i < 20; ++i)
                p.settings["core.freepick.mystic." + std::to_string(i)] = {{400+i}};
            auto const before = p.settings;
            auto const collection = p.collection;
            auto const unlocks = p.spells;
            AscensionPrestigeReset::Plan plan;
            AscensionPrestigeReset::Result result;
            std::string error;
            assert(PreparePrestigeReset(&p, plan, error));
            assert(plan.Build == build && plan.Enchants == enchant);
            assert(ResetPrestigeSpecialization(&p, plan, result, error));
            assert(result.Abilities == 3 && result.Enchants == (enchant ? 1 : 2));
            for (auto const& [key, values] : before)
            {
                bool changed = key == "selected" || key == "core.area52.active_build" ||
                    key == AscensionMysticEnchant::Setting(&p) ||
                    key.starts_with("core.area52.spec." + std::to_string(build) + ".");
                if (!changed) assert(p.settings.at(key) == values);
                else for (auto const value : p.settings.at(key)) assert(value.value == 0);
            }
            assert(p.collection == collection && p.spells == unlocks);
            assert(p.history[500].State == PLAYERSPELL_REMOVED);
            assert(p.history[501].State == 0 && p.history[502].State == 0 && p.history[503].State == 0);
            assert(p.CustomData.bars.Buttons.empty());
            assert(ResetPrestigeSpecialization(&p, plan, result, error));
            assert(result.Abilities == 0 && result.Enchants == 0);
        }
    for (unsigned failure = 0; failure < 13; ++failure)
    {
        Player p = Make(3, 1);
        AscensionPrestigeReset::Plan plan;
        AscensionPrestigeReset::Result result;
        std::string error;
        assert(PreparePrestigeReset(&p, plan, error));
        switch (failure)
        {
            case 0: p.applies = false; break;
            case 1: p.spells.erase(103); break;
            case 2: p.unlockedPresets = 1; break;
            case 3: p.CustomData.state.Busy = true; break;
            case 4: p.CustomData.state.Loaded = false; break;
            case 5: p.buildReady = false; break;
            case 6: p.combat = true; break;
            case 7: p.casting = true; break;
            case 8: p.preset = 0; break;
            case 9: p.settings[ActiveSlotSetting][0].value = 4; break;
            case 10: p.settings[ActiveSlotSetting][0].value = 99; break;
            case 11: p.applyFailure = true; break;
            case 12: p.world = false; break;
        }
        auto const before = p.settings;
        auto const collection = p.collection;
        assert(!ResetPrestigeSpecialization(&p, plan, result, error));
        assert(!error.empty() && before == p.settings && collection == p.collection);
        assert(p.sync == 0);
    }
}
'''
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory)
        cpp = path / 'test.cpp'
        cpp.write_text(code)
        executable = path / 'test'
        subprocess.run([os.environ.get('CXX', 'c++'), '-std=c++20', '-Wall', '-Wextra', '-Werror',
                        '-I' + str(ROOT / 'src/server/coa'),
                        '-I' + str(ROOT / 'modules/mod-coa-prestige/integrations/area52'),
                        str(cpp), '-o', str(executable)], check=True)
        subprocess.run([str(executable)], check=True)
    print('Area 52 Prestige: 400 build/enchant pairs, repeated resets and 13 rejection paths passed')


if __name__ == '__main__':
    main()
