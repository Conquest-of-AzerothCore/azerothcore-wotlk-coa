/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_SKILLCARD_PROC_RULES_H
#define ASCENSION_SKILLCARD_PROC_RULES_H

#include <cstdint>
#include <array>
#include <string_view>

namespace AscensionSkillcard
{
inline constexpr std::array<std::uint32_t, 46> ImplementedSpells = {
    299986, 285930, 282040, 282105, 285537, 285240, 282029, 283949, 283251, 276808,
    281471, 277185, 283175, 283700, 283634, 285749, 285865, 283238, 273595, 283465,
    293200, 270424, 285100, 283927, 285739, 274125, 277505, 270327, 283471, 273121,
    281712, 281710, 285780, 277143, 274268,
    16580, 35102, 281352, 281543, 281782, 282279, 286217, 964993, 17933, 277588, 284041
};

inline bool Implemented(std::uint32_t id)
{
    for (std::uint32_t spell : ImplementedSpells)
        if (spell == id)
            return true;
    return false;
}

struct Event
{
    std::string_view Name;
    bool Damage = false;
    bool Heal = false;
    bool Cast = false;
    bool Periodic = false;
    bool Critical = false;
    bool Miss = false;
    bool Kill = false;
    bool RangedAuto = false;
    bool Offhand = false;
    bool MeleeAbility = false;
    bool Hunter = false;
    bool HunterShot = false;
    bool GlobalCooldown = false;
    bool Fire = false;
    bool Shadow = false;
    bool Holy = false;
    bool Frost = false;
    bool Magic = false;
    bool Qualified = false;
};

inline bool Allows(std::uint32_t id, Event const& event)
{
    bool const direct = event.Damage && !event.Periodic;
    auto const named = [&event](std::string_view name) { return event.Name == name; };
    switch (id)
    {
        case 299986: return direct && named("Arcane Barrage");
        case 285930: return event.Cast && named("Blink");
        case 282040: return event.Miss;
        case 282105: return event.Kill && event.Qualified;
        case 285537: return direct && event.Critical && named("Wrath") && event.Qualified;
        case 285240:
            return (event.Cast && (named("Lightning Bolt") || named("Chain Lightning"))) ||
                (event.Damage && named("Lightning Rod"));
        case 282029: return event.Heal && named("Tranquility");
        case 283949: return event.Heal && event.Qualified;
        case 283251: return event.Damage && named("Consecration");
        case 281681: return event.RangedAuto;
        case 276808: return event.Damage && (named("Shadow Bolt") || named("Seed of Corruption"));
        case 281471: return (event.Damage && named("Drain Soul")) || (event.Cast && named("Life Tap"));
        case 277185: return event.Cast && (named("Incinerate") || named("Soul Fire"));
        case 284943: return event.Cast && named("Vanish");
        case 283175: return event.Heal && named("Desperate Prayer") && event.Qualified;
        case 283700: return event.Heal && named("Renew");
        case 283634: return direct && event.Fire;
        case 285749: return direct && (named("Windfury Attack") || named("Windfury Weapon"));
        case 285865: return event.Damage && (event.Holy || event.Frost) && event.Qualified;
        case 283238: return direct && named("Shadow Bolt");
        case 273595: return event.Damage && !event.Periodic && event.Offhand && event.Qualified;
        case 278510: return event.Cast && event.Qualified;
        case 283465: return event.Cast && named("Demonic Leap");
        case 293200: return direct && (event.Fire || event.Shadow);
        case 270424: return event.Damage && event.Magic && event.Qualified;
        case 285100: return event.Damage && named("Hellfire");
        case 283927: return direct && named("Holy Fire");
        case 285739: return event.Cast && named("Holy Nova");
        case 274125: return event.Cast && named("Cone of Cold");
        case 284057: return event.Cast && named("Entangling Roots");
        case 277505:
            return event.Cast && event.MeleeAbility && !event.Hunter && event.GlobalCooldown;
        case 270327: return direct && event.Fire;
        case 277818: return event.Cast && named("Explosive Shot");
        case 283471: return direct && event.Fire && event.Qualified;
        case 273121: return direct;
        case 281712: return event.Cast && (named("Mangle (Cat)") || named("Mangle (Bear)") || named("Mangle"));
        case 281710: return event.Cast && event.HunterShot;
        case 285780: return (direct && named("Colossus Smash")) || (event.Damage && named("Stagger"));
        case 277143: return event.Damage && named("Drain Soul") && event.Qualified;
        case 274268: return direct && (named("Javelin") || named("Shield Slam") || named("Siegebreaker"));
        case 17933: return direct && event.Shadow && !event.Name.empty();
        case 16580:
            return direct && event.Critical && (named("Lightning Bolt") || named("Chain Lightning") ||
                named("Thunderstorm"));
        case 35102: return direct && (named("Chimera Shot") || named("Multi-Shot"));
        case 281352: return direct && named("Slam");
        case 281543: return event.Damage && event.Periodic && named("Moonfire");
        case 281782: return direct && event.Qualified;
        case 282279:
            return event.Cast && event.Qualified &&
                (named("Judgement") || event.Name.starts_with("Judgement of "));
        case 286217: return event.Cast && named("Grappling Hook");
        case 964993: return event.Kill;
        case 277588: return event.Damage && named("Hurricane");
        case 284041: return direct && named("Haunt");
        default: return false;
    }
}

inline bool ClearsCooldown(std::uint32_t remaining, std::int32_t adjustment)
{
    return !remaining || (adjustment < 0 && std::uint64_t(-std::int64_t(adjustment)) >= remaining);
}

inline std::uint8_t AddCharge(std::uint8_t current, std::uint8_t limit)
{
    return current < limit ? current + 1 : limit;
}

inline bool FullHealthAfterHeal(std::uint32_t health, std::uint32_t maximum, std::uint32_t effective)
{
    return maximum && effective && health >= maximum;
}
}

#endif
