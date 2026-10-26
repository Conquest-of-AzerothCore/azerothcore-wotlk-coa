#include "CoAGameplayBalance.h"
#include <cassert>
#include <vector>

using namespace CoAGameplay::Balance;

int main()
{
    assert(ResolveStage(false, 0, false, 5000, 120000) == StageOutcome::Loss);
    assert(ResolveStage(true, 1, true, 5000, 120000) == StageOutcome::Invalid);
    assert(ResolveStage(true, 0, false, 5000, 120000) == StageOutcome::Win);
    assert(ResolveStage(true, 2, false, 120000, 120000) == StageOutcome::Timeout);
    assert(ResolveStage(true, 2, false, 119999, 120000) == StageOutcome::Running);

    ObjectGuid const guidA(HighGuid::Unit, 1u, 1u);
    ObjectGuid const guidB(HighGuid::Unit, 1u, 2u);
    ObjectGuid const guidC(HighGuid::Unit, 1u, 3u);

    {
        std::vector<SoloCandidate> const candidates = {
            { guidA, true, 50.0f, 10.0f },
            { guidB, true, 20.0f, 5.0f },
        };
        assert(SelectSoloTarget(candidates, guidA) == guidA);
    }
    {
        std::vector<SoloCandidate> const candidates = {
            { guidA, false, 50.0f, 10.0f },
            { guidB, true, 20.0f, 5.0f },
            { guidC, true, 10.0f, 5.0f },
        };
        assert(SelectSoloTarget(candidates, guidA) == guidC);
    }
    {
        std::vector<SoloCandidate> const candidates = {
            { guidA, true, 30.0f, 10.0f },
            { guidB, true, 30.0f, 2.0f },
        };
        assert(SelectSoloTarget(candidates, std::nullopt) == guidB);
    }
    {
        std::vector<SoloCandidate> const candidates = {
            { guidA, false, 10.0f, 1.0f },
            { guidB, true, 40.0f, 1.0f },
        };
        assert(SelectSoloTarget(candidates, std::nullopt) == guidB);
    }
    {
        std::vector<SoloCandidate> const candidates = {
            { guidA, false, 10.0f, 1.0f },
            { guidB, false, 40.0f, 1.0f },
        };
        assert(SelectSoloTarget(candidates, std::nullopt) == std::nullopt);
    }

    {
        std::vector<KitRule> const rules = {
            { 100, KitCondition::Always, 0, 0.0f, KitTarget::Self },
            { 200, KitCondition::Always, 0, 0.0f, KitTarget::Self },
        };
        auto const holds = [](KitRule const&) { return true; };
        auto const castable = [](KitRule const& rule) { return rule.spell != 100; };
        auto const result = NextKitRule(rules, holds, castable);
        assert(result == 1);
    }
    {
        std::vector<KitRule> const rules = {
            { 100, KitCondition::Always, 0, 0.0f, KitTarget::Self },
            { 200, KitCondition::Always, 0, 0.0f, KitTarget::Self },
        };
        auto const holds = [](KitRule const&) { return true; };
        auto const castable = [](KitRule const&) { return true; };
        auto const result = NextKitRule(rules, holds, castable);
        assert(result == 0);
    }
    {
        std::vector<KitRule> const rules = {
            { 100, KitCondition::SelfAuraMissing, 0, 0.0f, KitTarget::Self },
        };
        auto const holds = [](KitRule const&) { return false; };
        auto const castable = [](KitRule const&) { return true; };
        auto const result = NextKitRule(rules, holds, castable);
        assert(result == std::nullopt);
    }

    {
        SwingTally tally{};
        AddSwing(tally, SwingResult::Normal, 100);
        AddSwing(tally, SwingResult::Normal, 120);
        AddSwing(tally, SwingResult::Crit, 250);
        AddSwing(tally, SwingResult::Dodge, 0);
        assert(tally.swings == 4);
        assert(AverageNormalHit(tally) == 110.0f);
    }
}
