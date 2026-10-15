#ifndef COA_LEGENDARY_RULES_H
#define COA_LEGENDARY_RULES_H

#include <algorithm>
#include <cstdint>
#include <optional>

namespace CoALegendary
{
    constexpr uint32_t ItemEntryBase = 9700000;
    constexpr uint32_t ItemEntryStride = 100;
    constexpr uint32_t AuraEntryBase = 9710000;
    constexpr uint32_t TooltipEntryBase = 9720000;
    constexpr uint32_t DesignCount = 64;
    constexpr uint32_t MaximumCreatureLevel = 60;
    constexpr uint32_t ItemLevelBonus = 12;
    constexpr uint32_t KillPowerDurationMs = 8000;

    enum class Power : uint8_t
    {
        Offense,
        Movement,
        Armor,
        Signature
    };

    enum class Condition : uint8_t
    {
        Always,
        Healthy,
        Wounded,
        AfterKill,
        OutOfCombat,
        InCombat
    };

    enum class Profile : uint8_t
    {
        Strength,
        Agility,
        Caster,
        StrengthHybrid,
        AgilityHybrid,
        IntellectHybrid,
        Universal
    };

    struct Design
    {
        char const* name;
        uint8_t classId;
        Power power;
        Condition condition;
        Profile profile;
        uint8_t inventoryType;
        uint32_t signatureSpell;
        uint8_t magnitude;
        uint8_t signatureMaskBit;
    };

    struct Variant
    {
        uint32_t design;
        uint32_t requiredLevel;
    };

    constexpr bool IsCustomClass(uint32_t classId)
    {
        return classId >= 12 && classId <= 32;
    }

    constexpr bool FitsClass(Design const& design, uint32_t classId)
    {
        return IsCustomClass(classId) && (!design.classId || design.classId == classId);
    }

    constexpr uint32_t ItemLevel(uint32_t requiredLevel)
    {
        return requiredLevel + ItemLevelBonus;
    }

    constexpr uint32_t EntryForLevel(uint32_t design, uint32_t requiredLevel)
    {
        return ItemEntryBase + design * ItemEntryStride + requiredLevel;
    }

    constexpr uint32_t TooltipForLevel(uint32_t design, uint32_t requiredLevel)
    {
        return TooltipEntryBase + design * ItemEntryStride + requiredLevel;
    }

    constexpr std::optional<Variant> DecodeEntry(uint32_t entry)
    {
        if (entry < ItemEntryBase)
            return std::nullopt;
        uint32_t const offset = entry - ItemEntryBase;
        uint32_t const design = offset / ItemEntryStride;
        uint32_t const level = offset % ItemEntryStride;
        if (design >= DesignCount || !level || level > MaximumCreatureLevel)
            return std::nullopt;
        return Variant{ design, level };
    }

    constexpr bool CanDrop(uint32_t classId, uint32_t playerLevel, uint32_t creatureLevel,
        uint32_t stopDropLevel, bool grantsKillReward)
    {
        return IsCustomClass(classId) && playerLevel > 0 && playerLevel < stopDropLevel &&
            creatureLevel > 0 && creatureLevel <= MaximumCreatureLevel && grantsKillReward;
    }

    constexpr bool ConditionActive(Condition condition, float healthPct, bool inCombat, uint32_t killPowerMs)
    {
        switch (condition)
        {
            case Condition::Always:
                return true;
            case Condition::Healthy:
                return healthPct >= 80.0f;
            case Condition::Wounded:
                return healthPct <= 35.0f;
            case Condition::AfterKill:
                return killPowerMs != 0;
            case Condition::OutOfCombat:
                return !inCombat;
            case Condition::InCombat:
                return inCombat;
        }
        return false;
    }

    constexpr int32_t AttackPowerBonus(uint32_t requiredLevel)
    {
        return int32_t(ItemLevel(requiredLevel) * 2);
    }

    constexpr int32_t SpellPowerBonus(uint32_t requiredLevel)
    {
        return int32_t(ItemLevel(requiredLevel));
    }

}

#endif
