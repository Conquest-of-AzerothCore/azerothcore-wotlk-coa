#ifndef ASCENSION_CUSTOM_RESOURCE_DATA_H
#define ASCENSION_CUSTOM_RESOURCE_DATA_H

#include <array>
#include <cstdint>

namespace AscensionCompatData
{
enum class ResourceMutation : std::uint8_t
{
    AuraStacks,
    TriggerSpell
};

enum class ResourceGainEvent : std::uint8_t
{
    Cast,
    FirstSuccessfulHostileTarget,
    EachSuccessfulHostileTarget,
    FirstSuccessfulDamagingHit,
    EachSuccessfulDamagingHit,
    FirstCriticalDamagingHit,
    EachCriticalDamagingHit,
    PeriodicDamageTick,
    Block
};

enum class ResourceConsumption : std::uint8_t
{
    None,
    Fixed,
    All
};

struct ResourceDisplay
{
    std::uint8_t ClassId;
    std::uint32_t SpellId;
    std::uint16_t DisplayMaximum;
    char const* Name;
};

inline constexpr std::array<ResourceDisplay, 32> ResourceDisplays =
{{
    {12, 805813, 10, "Barbarian resource"},
    {14, 800058, 0, "Felfury"},
    {16, 803102, 100, "Static"},
    {17, 500906, 6, "Demonfire"},
    {19, 704576, 10, "Oath chain"},
    {19, 804903, 0, "Templar combo: Judgment"},
    {19, 804904, 0, "Templar combo: Absolution"},
    {19, 804922, 0, "Templar combo: Inquisition"},
    {19, 804924, 0, "Templar combo: Conviction"},
    {19, 805332, 0, "Templar combo: Devotion"},
    {20, 680687, 10, "Bloodmage resource"},
    {20, 706613, 10, "Blood thirst"},
    {21, 804329, 5, "Advantage"},
    {22, 804455, 5, "Echo Fragment"},
    {23, 525004, 0, "Life Force visual"},
    {23, 805011, 0, "Life Force"},
    {24, 807389, 100, "Heat"},
    {24, 807533, 0, "Ember"},
    {25, 500706, 100, "Insanity"},
    {25, 800431, 6, "Void Rune"},
    {26, 802985, 0, "Lunar Phase"},
    {27, 500149, 0, "Solar Power"},
    {27, 804584, 0, "Sunset"},
    {28, 801816, 100, "Scrap"},
    {29, 804972, 5, "Brood Mark"},
    {30, 500363, 3, "Reaped Soul"},
    {30, 805077, 3, "Soul Fragment"},
    {30, 803031, 1, "Soul Infusion"},
    {31, 680441, 15, "Earthshaping"},
    {32, 500282, 0, "Runemaster arcane sigil"},
    {32, 500271, 0, "Runemaster fire sigil"},
    {32, 500285, 0, "Runemaster frost sigil"}
}};

struct ResourceThresholdRule
{
    std::uint8_t ClassId;
    std::uint32_t ResourceSpellId;
    std::uint8_t Amount;
    std::uint32_t ThresholdSpellId;
};

inline constexpr std::array<ResourceThresholdRule, 7> ResourceThresholdRules =
{{
    {14, 800058, 2, 803468},
    {16, 803102, 10, 706668},
    {16, 803102, 20, 681016},
    {16, 803102, 25, 681126},
    {16, 803102, 40, 573249},
    {16, 803102, 50, 707050},
    {25, 800431, 2, 520343}
}};

struct ResourceGainRule
{
    std::uint8_t ClassId;
    std::uint32_t FirstSpellId;
    std::uint32_t LastSpellId;
    std::uint32_t ResourceSpellId;
    std::int16_t Amount;
    ResourceMutation Mutation;
    ResourceGainEvent Event = ResourceGainEvent::Cast;
    std::uint32_t RequiredAuraSpellId = 0;
    std::uint32_t ForbiddenAuraSpellId = 0;
    std::uint8_t ChancePercent = 100;
};

inline constexpr std::array<ResourceGainRule, 189> ResourceGainRules =
{{
    {14, 524706, 524706, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 805240, 805240, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit},
    {14, 704368, 704368, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 706415, 706420, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 800209, 800209, 800058, 1, ResourceMutation::AuraStacks},
    {14, 800204, 800204, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 803484, 803487, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 563268, 563268, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 800210, 800210, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 802405, 802409, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 560759, 560762, 800058, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 572803, 572804, 800058, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {14, 801903, 801903, 800058, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},

    {16, 501421, 501432, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},
    {16, 801844, 801844, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},
    {16, 807105, 807111, 803102, 25, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},
    {16, 500043, 500043, 803102, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 0, 800098},
    {16, 500925, 500925, 803102, 40, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 0, 800098},
    {16, 500927, 500927, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 0, 800098},
    {16, 560032, 560032, 803102, 50, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 0, 800098},
    {16, 570138, 570141, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},
    {16, 804036, 804036, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},
    {16, 560030, 560030, 803102, 50, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 0, 800098},

    {17, 801016, 801016, 500906, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 501511, 501520, 500906, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 805555, 805555, 500906, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 680939, 680944, 500906, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 804883, 804883, 500906, 1, ResourceMutation::AuraStacks},

    {14, 501257, 501261, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 520817, 0, 60},
    {14, 547210, 547211, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 520817, 0, 60},
    {14, 801901, 801901, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 520817, 0, 60},
    {14, 563268, 563268, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 520817, 0, 60},
    {14, 800210, 800210, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 520817, 0, 60},
    {14, 802405, 802409, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 520817, 0, 60},

    {14, 501257, 501261, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 801892},
    {14, 547210, 547211, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 801892},
    {14, 801901, 801901, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 801892},
    {14, 560759, 560762, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 801892},
    {14, 572803, 572804, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 801892},
    {14, 801903, 801903, 800058, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 801892},

    {16, 501438, 501441, 803102, 5, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulHostileTarget, 0, 800098},
    {16, 582303, 582304, 803102, 5, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulHostileTarget, 0, 800098},
    {16, 801851, 801851, 803102, 5, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulHostileTarget, 0, 800098},
    {16, 500928, 500928, 803102, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::PeriodicDamageTick, 0, 800098},
    {16, 501403, 501411, 803102, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::PeriodicDamageTick, 0, 800098},

    {16, 803002, 803002, 803102, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 0, 800098},
    {16, 500045, 500045, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},
    {16, 501476, 501484, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},
    {16, 500193, 500193, 803102, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 800098},

    {17, 805555, 805555, 500906, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 707390},
    {17, 680939, 680944, 500906, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 707390},
    {17, 800340, 800340, 500906, 2, ResourceMutation::AuraStacks, ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 501508, 501510, 500906, 2, ResourceMutation::AuraStacks, ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 578119, 578119, 500906, 2, ResourceMutation::AuraStacks, ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 804353, 804353, 500906, 2, ResourceMutation::AuraStacks, ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 806869, 806874, 500906, 2, ResourceMutation::AuraStacks, ResourceGainEvent::FirstSuccessfulHostileTarget},
    {17, 520005, 520005, 500906, 1, ResourceMutation::AuraStacks, ResourceGainEvent::FirstSuccessfulHostileTarget},

    {21, 800086, 800086, 804329, 1, ResourceMutation::AuraStacks},
    {21, 800088, 800088, 804329, 1, ResourceMutation::AuraStacks},
    {21, 806359, 806359, 804329, 1, ResourceMutation::AuraStacks},
    {21, 806360, 806360, 804329, 1, ResourceMutation::AuraStacks},
    {21, 807820, 807820, 804329, 1, ResourceMutation::AuraStacks},
    {21, 800093, 800093, 804329, 1, ResourceMutation::AuraStacks},
    {21, 803851, 803851, 804329, 1, ResourceMutation::AuraStacks},
    {21, 803859, 803864, 804329, 1, ResourceMutation::AuraStacks},
    {21, 520227, 520227, 804329, 2, ResourceMutation::AuraStacks},
    {21, 573243, 573246, 804329, 2, ResourceMutation::AuraStacks},
    {21, 806345, 806345, 804329, 2, ResourceMutation::AuraStacks},
    {21, 806437, 806443, 804329, 1, ResourceMutation::AuraStacks},
    {21, 803104, 803104, 804329, 2, ResourceMutation::AuraStacks},
    {21, 803852, 803852, 804329, 2, ResourceMutation::AuraStacks},

    {24, 803819, 803825, 807389, 20, ResourceMutation::AuraStacks},
    {24, 556833, 556837, 807389, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit},
    {24, 572890, 572890, 807389, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit},
    {24, 500649, 500652, 807389, 50, ResourceMutation::AuraStacks},
    {24, 535650, 535651, 807389, 30, ResourceMutation::AuraStacks},
    {24, 582762, 582764, 807389, 30, ResourceMutation::AuraStacks},
    {24, 802119, 802119, 807533, 2, ResourceMutation::AuraStacks},

    {24, 502020, 502031, 807389, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::PeriodicDamageTick},
    {24, 800791, 800791, 807389, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::PeriodicDamageTick},
    {24, 801905, 801905, 807389, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit},
    {24, 502107, 502113, 807389, 30, ResourceMutation::AuraStacks},
    {24, 802107, 802107, 807389, 30, ResourceMutation::AuraStacks},
    {24, 504380, 504380, 807389, 30, ResourceMutation::AuraStacks},
    {24, 500135, 500135, 807389, 50, ResourceMutation::AuraStacks},
    {24, 502055, 502056, 807389, 50, ResourceMutation::AuraStacks},
    {24, 800816, 800816, 807389, 50, ResourceMutation::AuraStacks},
    {24, 805477, 805477, 807389, 50, ResourceMutation::AuraStacks},
    {24, 807620, 807623, 807389, 50, ResourceMutation::AuraStacks},

    {24, 800790, 800790, 807389, 20, ResourceMutation::AuraStacks},
    {24, 502011, 502019, 807389, 20, ResourceMutation::AuraStacks},
    {24, 800806, 800806, 807389, 30, ResourceMutation::AuraStacks},
    {24, 502044, 502052, 807389, 30, ResourceMutation::AuraStacks},
    {24, 800806, 800806, 807389, 30, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 804230},
    {24, 502044, 502052, 807389, 30, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 804230},
    {24, 805496, 805496, 807389, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit},
    {24, 807406, 807410, 807389, 20, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit},
    {24, 806611, 806611, 807389, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 504754},
    {24, 807615, 807619, 807389, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 504754},

    {25, 500714, 500714, 500706, 10, ResourceMutation::AuraStacks},
    {25, 502235, 502243, 500706, 10, ResourceMutation::AuraStacks},
    {25, 502213, 502220, 500706, 10, ResourceMutation::AuraStacks},
    {25, 800446, 800446, 500706, 10, ResourceMutation::AuraStacks},
    {25, 560109, 560109, 500706, 10, ResourceMutation::AuraStacks},
    {25, 578263, 578263, 500706, 20, ResourceMutation::AuraStacks},
    {25, 806222, 806222, 500706, 20, ResourceMutation::AuraStacks},
    {25, 806825, 806828, 500706, 20, ResourceMutation::AuraStacks},
    {25, 805572, 805572, 500706, 10, ResourceMutation::AuraStacks},
    {25, 806893, 806897, 500706, 10, ResourceMutation::AuraStacks},
    {25, 807969, 807969, 500706, 10, ResourceMutation::AuraStacks},
    {25, 500720, 500720, 500706, 20, ResourceMutation::AuraStacks},
    {25, 502114, 502124, 500706, 20, ResourceMutation::AuraStacks},
    {25, 800416, 800416, 500706, 10, ResourceMutation::AuraStacks},
    {25, 502173, 502184, 500706, 10, ResourceMutation::AuraStacks},
    {25, 500712, 500712, 500706, 20, ResourceMutation::AuraStacks},

    {25, 500110, 500110, 500706, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 807512},
    {25, 502135, 502143, 500706, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 807512},
    {25, 805116, 805116, 500706, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachCriticalDamagingHit, 301180},
    {25, 806498, 806499, 500706, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachCriticalDamagingHit, 301180},
    {25, 806829, 806833, 500706, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachCriticalDamagingHit, 301180},
    {25, 503487, 503488, 500706, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 681087},
    {25, 524876, 524876, 500706, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 681087},
    {25, 572140, 572141, 500706, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 681087},
    {25, 572715, 572715, 500706, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 681087},
    {25, 804208, 804208, 500706, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 681087},
    {25, 0, 0, 500706, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::Block, 706182},

    {28, 504527, 504527, 801816, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {28, 504589, 504593, 801816, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {28, 572888, 572888, 801816, 10, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},

    {29, 800880, 800880, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit, 92143},
    {29, 502896, 502904, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit, 92143},
    {29, 504705, 504705, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {29, 800882, 800882, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {29, 502905, 502911, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {29, 706962, 706962, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {29, 707084, 707090, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {29, 0, 0, 804972, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::PeriodicDamageTick, 706036, 0, 10},

    {30, 500517, 500521, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 500646, 500646, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget},

    {30, 500357, 500357, 805077, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 500357, 500357, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 504056, 504058, 805077, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 504056, 504058, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 504557, 504557, 805077, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 504557, 504557, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 505151, 505151, 805077, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 505151, 505151, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 573302, 573303, 805077, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 573302, 573303, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 505170, 505170, 805077, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 505170, 505170, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 505326, 505326, 805077, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 505326, 505326, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 801328, 801328, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 803834, 803839, 355461, 1, ResourceMutation::TriggerSpell,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 803992, 803992, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 503286, 503289, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 503324, 503324, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 503531, 503531, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 805258, 805258, 500363, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 806818, 806824, 500363, 3, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulDamagingHit},
    {30, 805185, 805185, 500363, 1, ResourceMutation::AuraStacks},

    {30, 500376, 500376, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 706731},
    {30, 502679, 502684, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 706731},
    {30, 504622, 504622, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 706731},
    {30, 500376, 500376, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 520056},
    {30, 502679, 502684, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 520056},
    {30, 504622, 504622, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 520056},
    {30, 801624, 801624, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 560412},
    {30, 802422, 802428, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 560412},
    {30, 800172, 800172, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 704552},
    {30, 502668, 502671, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 704552},
    {30, 567531, 567532, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::FirstCriticalDamagingHit, 704552},

    {30, 800174, 800174, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast},
    {30, 502989, 502994, 500363, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast},

    {31, 500402, 500402, 680441, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 502769, 502777, 680441, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 503258, 503264, 680441, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 803981, 803981, 680441, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 560171, 560175, 680441, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 582532, 582532, 680441, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 804433, 804433, 680441, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 680442, 680442, 680441, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 681114, 681117, 680441, 2, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},
    {31, 807432, 807432, 680441, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92149},

    {22, 520175, 520175, 804455, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 92120},
    {22, 520702, 520707, 804455, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::EachSuccessfulDamagingHit, 92120},
    {22, 561284, 561284, 804455, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92120},
    {22, 561354, 561357, 804455, 1, ResourceMutation::AuraStacks,
        ResourceGainEvent::Cast, 92120}
}};

struct NativePowerGainRule
{
    std::uint8_t ClassId;
    std::uint32_t FirstSpellId;
    std::uint32_t LastSpellId;
    std::uint8_t PowerType;
    std::int16_t InternalAmount;
    ResourceGainEvent Event = ResourceGainEvent::Cast;
    std::uint32_t RequiredAuraSpellId = 0;
    std::uint32_t ForbiddenAuraSpellId = 0;
    std::uint32_t AmountSpellId = 0;
};

inline constexpr std::array<NativePowerGainRule, 16> NativePowerGainRules =
{{
    {19, 0, 0, 3, 10, ResourceGainEvent::PeriodicDamageTick, 301253},
    {23, 704355, 704355, 6, 200,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 704680},
    {23, 707399, 707402, 6, 200,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 704680},
    {23, 707911, 707911, 6, 200,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 704680},
    {30, 572341, 572342, 6, 150,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 573316, 573319, 6, 150,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 573321, 573322, 6, 150,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 800172, 800172, 6, 150,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 502668, 502671, 6, 150,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 567531, 567532, 6, 150,
        ResourceGainEvent::FirstSuccessfulHostileTarget},
    {30, 801624, 801624, 6, 200,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 0, 359504},
    {30, 802422, 802428, 6, 200,
        ResourceGainEvent::FirstSuccessfulHostileTarget, 0, 0, 359504},
    {31, 680442, 680442, 1, 10, ResourceGainEvent::EachSuccessfulDamagingHit},
    {31, 681114, 681117, 1, 10, ResourceGainEvent::EachSuccessfulDamagingHit},
    {31, 680442, 680442, 1, 10, ResourceGainEvent::PeriodicDamageTick},
    {31, 681114, 681117, 1, 10, ResourceGainEvent::PeriodicDamageTick}
}};

struct ResourceCostRule
{
    std::uint8_t ClassId;
    std::uint32_t FirstSpellId;
    std::uint32_t LastSpellId;
    std::uint32_t ResourceSpellId;
    std::uint8_t Amount;
    ResourceConsumption Consumption;
    std::uint32_t PreserveCostAuraSpellId = 0;
    std::uint8_t PreserveCostChancePercent = 0;
};

inline constexpr std::array<ResourceCostRule, 71> ResourceCostRules =
{{
    {14, 801904, 801904, 800058, 2, ResourceConsumption::Fixed,
        705137, 30},
    {14, 803470, 803475, 800058, 2, ResourceConsumption::Fixed,
        705137, 30},
    {14, 800206, 800206, 800058, 2, ResourceConsumption::Fixed},
    {14, 520236, 520236, 800058, 2, ResourceConsumption::Fixed},
    {14, 520688, 520693, 800058, 2, ResourceConsumption::Fixed},
    {14, 501292, 501299, 800058, 2, ResourceConsumption::Fixed,
        804219, 25},
    {14, 801895, 801895, 800058, 2, ResourceConsumption::Fixed,
        804219, 25},
    {14, 802060, 802060, 800058, 2, ResourceConsumption::Fixed},
    {14, 501314, 501321, 800058, 2, ResourceConsumption::Fixed},
    {14, 705121, 705121, 800058, 2, ResourceConsumption::Fixed},

    {16, 500038, 500038, 803102, 25, ResourceConsumption::Fixed},
    {16, 501469, 501475, 803102, 25, ResourceConsumption::Fixed},
    {16, 500039, 500039, 803102, 40, ResourceConsumption::Fixed},
    {16, 501442, 501449, 803102, 40, ResourceConsumption::Fixed},
    {16, 500041, 500041, 803102, 25, ResourceConsumption::Fixed},
    {16, 500040, 500040, 803102, 50, ResourceConsumption::Fixed},
    {16, 501388, 501399, 803102, 50, ResourceConsumption::Fixed},
    {16, 800227, 800227, 803102, 50, ResourceConsumption::Fixed},
    {16, 501415, 501420, 803102, 50, ResourceConsumption::Fixed},
    {16, 802354, 802354, 803102, 20, ResourceConsumption::Fixed},
    {16, 570161, 570166, 803102, 20, ResourceConsumption::Fixed},
    {16, 801839, 801839, 803102, 50, ResourceConsumption::Fixed},
    {16, 501450, 501458, 803102, 50, ResourceConsumption::Fixed},
    {16, 532751, 532751, 803102, 50, ResourceConsumption::Fixed},
    {16, 567555, 567555, 803102, 20, ResourceConsumption::None},
    {16, 705672, 705672, 803102, 20, ResourceConsumption::None},
    {16, 706625, 706625, 803102, 50, ResourceConsumption::Fixed},
    {16, 707543, 707543, 803102, 10, ResourceConsumption::Fixed},
    {16, 800098, 800098, 803102, 1, ResourceConsumption::All},
    {16, 800099, 800099, 803102, 40, ResourceConsumption::Fixed},
    {16, 801847, 801847, 803102, 1, ResourceConsumption::All},
    {16, 501433, 501437, 803102, 1, ResourceConsumption::All},
    {16, 567518, 567520, 803102, 1, ResourceConsumption::All},
    {16, 804035, 804035, 803102, 20, ResourceConsumption::Fixed},
    {16, 804830, 804830, 803102, 40, ResourceConsumption::Fixed},
    {16, 805288, 805288, 803102, 20, ResourceConsumption::None},
    {16, 806124, 806124, 803102, 40, ResourceConsumption::Fixed},
    {16, 806430, 806436, 803102, 40, ResourceConsumption::Fixed},
    {16, 806400, 806400, 803102, 50, ResourceConsumption::Fixed},
    {16, 807713, 807717, 803102, 50, ResourceConsumption::Fixed},
    {16, 503352, 503360, 803102, 40, ResourceConsumption::Fixed},
    {16, 804017, 804017, 803102, 40, ResourceConsumption::Fixed},

    {24, 502057, 502063, 807533, 1, ResourceConsumption::Fixed},
    {24, 534600, 534604, 807533, 1, ResourceConsumption::Fixed},
    {24, 535509, 535512, 807533, 1, ResourceConsumption::Fixed},
    {24, 567589, 567590, 807533, 1, ResourceConsumption::Fixed},
    {24, 570750, 570750, 807533, 1, ResourceConsumption::Fixed},
    {24, 572159, 572160, 807533, 1, ResourceConsumption::Fixed},
    {24, 572618, 572623, 807533, 1, ResourceConsumption::Fixed},
    {24, 578307, 578309, 807533, 1, ResourceConsumption::Fixed},
    {24, 680369, 680369, 807533, 1, ResourceConsumption::Fixed},
    {24, 704278, 704278, 807533, 1, ResourceConsumption::Fixed},
    {24, 706854, 706854, 807533, 1, ResourceConsumption::Fixed},
    {24, 800792, 800792, 807533, 1, ResourceConsumption::Fixed},
    {24, 801915, 801915, 807533, 1, ResourceConsumption::Fixed},
    {24, 802174, 802174, 807533, 1, ResourceConsumption::Fixed},
    {24, 802791, 802791, 807533, 1, ResourceConsumption::Fixed},
    {24, 803407, 803410, 807533, 1, ResourceConsumption::Fixed},
    {24, 805500, 805500, 807533, 1, ResourceConsumption::Fixed},

    {24, 502085, 502087, 807533, 1, ResourceConsumption::None},
    {24, 520320, 520320, 807533, 1, ResourceConsumption::None},
    {24, 520751, 520751, 807533, 1, ResourceConsumption::None},
    {24, 572892, 572894, 807533, 1, ResourceConsumption::None},
    {24, 800818, 800818, 807533, 1, ResourceConsumption::None},
    {24, 520019, 520019, 807533, 1, ResourceConsumption::Fixed},

    {22, 524853, 524853, 804455, 1, ResourceConsumption::All},
    {22, 804435, 804435, 804455, 1, ResourceConsumption::All},
    {22, 804438, 804438, 804455, 1, ResourceConsumption::All},
    {22, 806203, 806203, 804455, 1, ResourceConsumption::All},
    {22, 572417, 572417, 804455, 1, ResourceConsumption::All},
    {22, 804503, 804503, 804455, 1, ResourceConsumption::All}
}};
}

#endif
