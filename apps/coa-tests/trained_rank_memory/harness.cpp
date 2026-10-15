#include <algorithm>
#include <array>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <map>
#include <set>
#include <string>
#include <unordered_map>
#include <vector>

using uint8 = std::uint8_t;
using uint32 = std::uint32_t;

struct PlayerSetting
{
    uint32 value = 0;
};
using PlayerSettingVector = std::vector<PlayerSetting>;

struct SpellInfo
{
    uint32 Id = 0;
    uint32 BaseLevel = 0;
    uint32 SpellLevel = 0;
};

struct SpellMgr
{
    std::set<uint32> known;
    mutable SpellInfo info;
    SpellInfo const* GetSpellInfo(uint32 spellId) const
    {
        if (!known.contains(spellId))
            return nullptr;
        info.Id = spellId;
        info.BaseLevel = spellId % 100 * 10;
        return &info;
    }
};

SpellMgr spellMgr;
SpellMgr* sSpellMgr = &spellMgr;

struct Player
{
    std::set<uint32> spells;
    std::map<std::string, PlayerSettingVector> settings;
    std::vector<uint32> learnOrder;

    PlayerSettingVector const* FindPlayerSettings(std::string const& source) const
    {
        auto found = settings.find(source);
        return found == settings.end() ? nullptr : &found->second;
    }
    void UpdatePlayerSetting(std::string const& source, uint32 index, uint32 value)
    {
        PlayerSettingVector& stored = settings[source];
        if (stored.size() <= index)
            stored.resize(index + 1);
        stored[index].value = value;
    }
    bool HasSpell(uint32 spellId) const { return spells.contains(spellId); }
    void learnSpell(uint32 spellId)
    {
        spells.insert(spellId);
        learnOrder.push_back(spellId);
    }
};

struct Tables
{
    std::unordered_map<uint32, std::vector<uint32>> RankLadders;
    std::unordered_map<uint32, uint32> RankRoots;
};

Tables Loaded;

namespace Trainer
{
    struct Spell
    {
        uint32 SpellId = 0;
        uint32 MoneyCost = 0;
        std::array<uint32, 3> ReqAbility = { };
        uint8 ReqLevel = 0;
    };
}

uint32 TrainerPrice(uint32, uint32 level)
{
    return level * 100;
}
constexpr char TRAINED_RANKS_SETTING[] = "core.wildcard.trainedranks";

// ACTUAL_RANKS

void Expect(bool condition, char const* what)
{
    if (!condition)
    {
        std::cerr << "FAIL: " << what << "\n";
        std::exit(1);
    }
}

void Forget(Player& player, uint32 spellId)
{
    if (Loaded.RankRoots.contains(spellId))
        RememberTrainedRank(&player, spellId);
    player.spells.erase(spellId);
}

int main()
{
    Loaded.RankLadders[100] = { 100, 101, 102, 103 };
    Loaded.RankLadders[200] = { 200, 0, 202 };
    for (auto const& [root, ladder] : Loaded.RankLadders)
        for (std::size_t rank = 1; rank < ladder.size(); ++rank)
            if (ladder[rank])
                Loaded.RankRoots[ladder[rank]] = root;
    spellMgr.known = { 100, 101, 102, 103, 200, 202 };

    Player player;
    player.spells = { 100, 101, 102, 200, 202 };

    Forget(player, 102);
    Forget(player, 101);
    Forget(player, 100);
    Forget(player, 202);
    Forget(player, 200);
    Expect(player.spells.empty(), "unlearning removes every rank");

    Forget(player, 102);
    PlayerSettingVector const* stored = player.FindPlayerSettings(TRAINED_RANKS_SETTING);
    Expect(stored && std::count_if(stored->begin(), stored->end(), [](PlayerSetting s) { return s.value == 102; }) == 1,
           "a rank is remembered once");

    player.learnSpell(100);
    player.learnOrder.clear();
    RestoreTrainedRanks(&player, 100);
    Expect(player.learnOrder == std::vector<uint32>({ 101, 102 }), "re-learning rank 1 restores the trained ranks in order");
    Expect(!player.HasSpell(103), "a rank never trained is not granted");
    Expect(!player.HasSpell(202), "another ability's ranks stay remembered, not granted");

    stored = player.FindPlayerSettings(TRAINED_RANKS_SETTING);
    Expect(std::count_if(stored->begin(), stored->end(), [](PlayerSetting s) { return s.value == 101 || s.value == 102; }) == 0,
           "restored ranks are no longer remembered");

    Forget(player, 102);
    Expect((*stored)[0].value == 102 || (*stored)[1].value == 102, "a freed slot is reused");

    player.learnSpell(200);
    player.learnOrder.clear();
    RestoreTrainedRanks(&player, 200);
    Expect(player.learnOrder == std::vector<uint32>({ 202 }), "a ladder with a gap restores its remembered rank");

    player.learnOrder.clear();
    RestoreTrainedRanks(&player, 200);
    Expect(player.learnOrder.empty(), "restoring twice grants nothing more");

    Player trainee;
    trainee.spells = { 100, 101 };
    std::vector<Trainer::Spell> rows = RankTrainerRows(&trainee);
    Expect(rows.size() == 3, "every rank from 2 up of a known ability is listed, held ranks included");
    Expect(rows[0].SpellId == 101 && rows[0].ReqAbility[0] == 100, "rank 2 requires rank 1");
    Expect(rows[1].SpellId == 102 && rows[1].ReqAbility[0] == 101, "rank 3 requires rank 2");
    Expect(rows[2].SpellId == 103 && rows[2].ReqAbility[0] == 102 && rows[2].ReqLevel == 30, "rank 4 requires rank 3 and its level");
    Expect(std::none_of(rows.begin(), rows.end(), [](Trainer::Spell const& row) { return row.SpellId == 100; }),
           "rank 1 is never offered");
    trainee.spells.insert(102);
    std::vector<Trainer::Spell> const after = RankTrainerRows(&trainee);
    Expect(after.size() == rows.size() && after[1].SpellId == rows[1].SpellId, "buying a rank keeps the rows in place");
    trainee.spells.insert(200);
    rows = RankTrainerRows(&trainee);
    Expect(rows.size() == 4 && rows[3].SpellId == 202 && rows[3].ReqAbility[0] == 200, "a gap in a ladder is skipped");

    std::cout << "PASS: trained ranks come back when a Hero re-learns the ability\n";
    return 0;
}
