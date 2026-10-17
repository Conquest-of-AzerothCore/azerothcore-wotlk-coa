#ifndef COA_ROTATION_ASSIST_H
#define COA_ROTATION_ASSIST_H

#include <cstdint>
#include <span>
#include <string_view>

namespace CoARotationAssist
{
    enum class RuleCondition : uint8_t
    {
        Ready,
        MissingDebuff,
        HasAura,
        MissingAura,
        AuraStacks,
        TargetAura,
        TargetHealth,
        SelfHealth,
        Mana,
        Resource
    };

    struct Rule
    {
        uint16_t Specialization;
        std::string_view Spell;
        RuleCondition When;
        std::string_view Argument;
        uint16_t Threshold;
        bool SelfOnly = false;
    };

    inline bool Matches(RuleCondition condition, float observed, uint16_t threshold)
    {
        switch (condition)
        {
            case RuleCondition::Ready:
                return true;
            case RuleCondition::MissingDebuff:
            case RuleCondition::MissingAura:
                return observed == 0;
            case RuleCondition::HasAura:
            case RuleCondition::TargetAura:
                return observed > 0;
            case RuleCondition::AuraStacks:
            case RuleCondition::Resource:
                return observed >= threshold;
            case RuleCondition::TargetHealth:
            case RuleCondition::SelfHealth:
            case RuleCondition::Mana:
                return observed < threshold;
        }
        return false;
    }

    template<class Resolve>
    uint32_t Select(std::span<Rule const> rules, uint32_t specialization, Resolve&& resolve)
    {
        for (Rule const& rule : rules)
            if (rule.Specialization == specialization)
                if (uint32_t spell = resolve(rule))
                    return spell;
        return 0;
    }
}

#endif
