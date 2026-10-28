#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <optional>
#include <unordered_map>
#include <vector>

using uint32 = std::uint32_t;

constexpr std::uint32_t ABILITY_ROLL_COST = 2;
constexpr std::uint32_t TALENT_ROLL_COST = 1;
constexpr std::uint32_t TALENT_POOL_START_LEVEL = 10;

struct Slot
{
    std::uint32_t EntryId = 0;
    bool Locked = false;
    std::uint32_t Rank = 1;
    bool Talent = false;
};

struct Essence
{
    std::uint32_t Level = 0;
    std::uint32_t Ability = 0;
    std::uint32_t Talent = 0;
};

struct Tables
{
    std::unordered_map<std::uint32_t, std::uint32_t> AbilityCosts;
};

Tables Loaded;

// ACTUAL_STRUCT_SPENT

// ACTUAL_SPENT_ESSENCE

// ACTUAL_POOL_LEVEL

int failures = 0;

void Check(bool value, char const* name)
{
    failures += !value;
    std::printf("%s: %s\n", value ? "PASS" : "FAIL", name);
}

int main()
{
    constexpr std::uint32_t RUNE = 41841;
    Loaded.AbilityCosts = { { 1, 2 }, { 2, 2 }, { 3, 2 }, { 4, 2 }, { 1000, 2 }, { RUNE, 0 } };
    std::vector<Essence> const budget = { { 1, 8, 0 }, { 10, 10, 0 }, { 12, 12, 0 } };
    std::vector<Slot> const starters = { { 1 }, { 2 }, { 3 }, { 4 } };
    std::vector<Slot> withRune = starters;
    withRune.push_back({ RUNE });

    Check(SpentEssence(withRune).Ability == 8, "a rune entry costs its Wildcard essence (0), not a roll's 2");
    Check(PoolLevel(budget, starters, 10, false).has_value(), "four starters leave level 10's ability roll open");
    Check(PoolLevel(budget, withRune, 10, false).has_value(),
        "a rune rolled at level 10 leaves that roll's essence unspent, as the client shows it");
    std::vector<Slot> full = withRune;
    full.push_back({ 1000 });
    Check(!PoolLevel(budget, full, 10, false).has_value(), "a priced ability then spends it");
    return failures ? 1 : 0;
}
