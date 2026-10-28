#include "CoARotationAssist.h"
#include "CoARotationData.h"
#include <cassert>
#include <map>
#include <set>
#include <string_view>
#include <vector>

using namespace CoARotationAssist;

int main()
{
    assert(Matches(RuleCondition::MissingDebuff, 0, 0));
    assert(!Matches(RuleCondition::MissingDebuff, 1, 0));
    assert(Matches(RuleCondition::MissingAura, 0, 0));
    assert(!Matches(RuleCondition::HasAura, 0, 0));
    assert(Matches(RuleCondition::HasAura, 1, 0));
    assert(Matches(RuleCondition::TargetAura, 2, 0));
    assert(!Matches(RuleCondition::AuraStacks, 4, 5));
    assert(Matches(RuleCondition::AuraStacks, 5, 5));
    assert(!Matches(RuleCondition::Resource, 29, 30));
    assert(Matches(RuleCondition::Resource, 30, 30));
    assert(Matches(RuleCondition::SelfHealth, 44, 45));
    assert(!Matches(RuleCondition::SelfHealth, 45, 45));
    assert(Matches(RuleCondition::Mana, 19, 20));
    assert(!Matches(RuleCondition::Mana, 20, 20));
    assert(Matches(RuleCondition::TargetHealth, 19.9f, 20));
    assert(!Matches(RuleCondition::TargetHealth, 20, 20));

    std::set<uint16_t> specializations;
    for (Rule const& rule : Rules)
    {
        specializations.insert(rule.Specialization);
        assert(!rule.Spell.empty());
        assert(rule.When != RuleCondition::AuraStacks || rule.Threshold > 0);
    }
    assert(specializations.size() == 70);

    std::map<std::string_view, uint32_t> known = {{ "Ignite", 800791 }, { "Flare Bolt", 800790 }};
    bool dotPresent = false;
    std::set<uint32_t> unavailable;
    std::vector<uint32_t> attempted;
    auto choose = [&](uint32_t spec)
    {
        return Select(Rules, spec, [&](Rule const& rule)
        {
            auto const found = known.find(rule.Spell);
            if (found == known.end() || !Matches(rule.When, dotPresent, rule.Threshold))
                return uint32_t(0);
            attempted.push_back(found->second);
            return unavailable.contains(found->second) ? 0 : found->second;
        });
    };
    assert(choose(38) == 800791);
    assert(attempted == std::vector<uint32_t>{800791});
    dotPresent = true;
    attempted.clear();
    assert(choose(38) == 800790);
    assert(attempted == std::vector<uint32_t>{800790});
    dotPresent = false;
    unavailable.insert(800791);
    attempted.clear();
    assert(choose(38) == 800790);
    assert((attempted == std::vector<uint32_t>{800791, 800790}));
    unavailable.insert(800790);
    assert(choose(38) == 0);
    attempted.clear();
    assert(choose(0) == 0);
    assert(choose(999) == 0);
    assert(attempted.empty());
    known.clear();
    assert(choose(38) == 0);

    known = {{ "Reap", 1 }, { "Soul Strike", 2 }};
    unavailable.clear();
    assert(choose(56) == 2);
    unavailable.insert(2);
    assert(choose(56) == 1);
}
