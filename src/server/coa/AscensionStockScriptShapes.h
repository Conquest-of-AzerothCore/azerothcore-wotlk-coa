/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_STOCK_SCRIPT_SHAPES_H
#define ASCENSION_STOCK_SCRIPT_SHAPES_H

#include <cstdint>
#include <limits>

class SpellInfo;

namespace AscensionStockScriptShapes
{
constexpr std::int32_t KEEP = std::numeric_limits<std::int32_t>::min();
constexpr std::int32_t ANY = KEEP;

enum Effect : std::int32_t
{
    EFFECT_NONE = 0,
    EFFECT_INSTAKILL = 1,
    EFFECT_SCHOOL_DAMAGE = 2,
    EFFECT_DUMMY = 3,
    EFFECT_APPLY_AURA = 6,
    EFFECT_LEARN_SPELL = 36,
    EFFECT_TRIGGER_SPELL = 64,
    EFFECT_SUMMON_OBJECT_WILD = 76,
    EFFECT_SCRIPT_EFFECT = 77
};

enum Aura : std::int32_t
{
    AURA_NONE = 0,
    AURA_DUMMY = 4,
    AURA_MOD_CHARM = 6,
    AURA_PERIODIC_HEAL = 8,
    AURA_MOD_THREAT = 10,
    AURA_MOD_STUN = 12,
    AURA_OBS_MOD_HEALTH = 20,
    AURA_PERIODIC_TRIGGER_SPELL = 23,
    AURA_MOD_DECREASE_SPEED = 33,
    AURA_MOD_INCREASE_HEALTH = 34,
    AURA_PROC_TRIGGER_SPELL = 42,
    AURA_MOD_WEAPON_CRIT_PERCENT = 52,
    AURA_MOD_CASTING_SPEED_NOT_STACK = 65,
    AURA_CHANNEL_DEATH_ITEM = 86,
    AURA_MOD_MELEE_HASTE = 138,
    AURA_PERIODIC_DUMMY = 226,
    AURA_MOD_SPELL_HEALING_OF_ATTACK_POWER = 238
};

enum Target : std::int32_t
{
    TARGET_UNIT_CASTER = 1,
    TARGET_UNIT_TARGET_ENEMY = 6,
    TARGET_UNIT_SRC_AREA_ENTRY = 7,
    TARGET_UNIT_SRC_AREA_ENEMY = 15,
    TARGET_UNIT_DEST_AREA_ENEMY = 16,
    TARGET_DEST_CASTER = 18,
    TARGET_UNIT_CASTER_AREA_PARTY = 20,
    TARGET_SRC_CASTER = 22,
    TARGET_UNIT_TARGET_ANY = 25
};

constexpr std::int32_t SOUL_SHARD = 6265;

struct Shape
{
    std::int32_t Effect = ANY;
    std::int32_t Aura = ANY;
    std::int32_t TargetA = ANY;
};

struct Slot
{
    std::int32_t Effect = KEEP;
    std::int32_t Aura = KEEP;
    std::int32_t TargetA = KEEP;
    std::int32_t TargetB = KEEP;
    std::int32_t Radius = KEEP;
    std::int32_t BasePoints = KEEP;
    std::int32_t DieSides = KEEP;
    std::int32_t Amplitude = KEEP;
    std::int32_t MiscValue = KEEP;
    std::int32_t MiscValueB = KEEP;
    std::int32_t Trigger = KEEP;
    std::int32_t ItemType = KEEP;
};

struct Restore
{
    std::uint32_t SpellId;
    std::uint8_t EffectIndex;
    Shape Broken;
    Slot Stock;
};

constexpr Restore Aura(std::uint32_t spellId, std::uint8_t index, std::int32_t aura, std::int32_t amplitude = KEEP)
{
    return { spellId, index, { EFFECT_APPLY_AURA, ANY, ANY }, { KEEP, aura, KEEP, KEEP, KEEP, KEEP, KEEP, amplitude } };
}

constexpr Restore DrainSoulShard(std::uint32_t spellId)
{
    return { spellId, 1, { EFFECT_APPLY_AURA, AURA_NONE, ANY },
        { KEEP, AURA_CHANNEL_DEATH_ITEM, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, SOUL_SHARD } };
}

constexpr Restore PartyBuff(std::uint32_t spellId, std::uint8_t index)
{
    return { spellId, index, { EFFECT_APPLY_AURA, ANY, TARGET_UNIT_CASTER },
        { KEEP, KEEP, TARGET_UNIT_CASTER_AREA_PARTY } };
}

constexpr Restore MaxHealthPercentHeal(std::uint32_t spellId, std::uint8_t index)
{
    return { spellId, index, { EFFECT_APPLY_AURA, AURA_PERIODIC_HEAL, ANY }, { KEEP, AURA_OBS_MOD_HEALTH } };
}

constexpr Restore Targets(std::uint32_t spellId, std::uint8_t index, std::int32_t targetA, std::int32_t targetB,
    std::int32_t radius)
{
    return { spellId, index, {}, { KEEP, KEEP, targetA, targetB, radius } };
}

constexpr Restore RESTORES[] = {
    Aura(30675, 0, AURA_DUMMY), Aura(30678, 0, AURA_DUMMY), Aura(30679, 0, AURA_DUMMY),
    Aura(51685, 0, AURA_PERIODIC_DUMMY, 2000), Aura(51686, 0, AURA_PERIODIC_DUMMY, 2000),
    Aura(51687, 0, AURA_PERIODIC_DUMMY, 2000), Aura(51688, 0, AURA_PERIODIC_DUMMY, 2000),
    Aura(51689, 0, AURA_PERIODIC_DUMMY, 2000),
    Aura(59088, 1, AURA_DUMMY), Aura(59089, 1, AURA_DUMMY),

    DrainSoulShard(1120), DrainSoulShard(8288), DrainSoulShard(8289), DrainSoulShard(11675), DrainSoulShard(27217),
    DrainSoulShard(47855),

    PartyBuff(24604, 0), PartyBuff(24604, 1), PartyBuff(53434, 0), PartyBuff(53434, 1), PartyBuff(64491, 0),
    PartyBuff(64491, 1), PartyBuff(64492, 0), PartyBuff(64492, 1), PartyBuff(64493, 0), PartyBuff(64493, 1),
    PartyBuff(64494, 0), PartyBuff(64494, 1), PartyBuff(64495, 0), PartyBuff(64495, 1),

    { 37594, 0, { ANY, AURA_PERIODIC_DUMMY, ANY },
        { KEEP, AURA_PROC_TRIGGER_SPELL, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, 18350 } },
    { 42760, 0, { ANY, AURA_DUMMY, ANY },
        { KEEP, AURA_PROC_TRIGGER_SPELL, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, 42755 } },
    { 69682, 0, { EFFECT_APPLY_AURA, AURA_NONE, ANY }, { EFFECT_SCRIPT_EFFECT } },
    { 12021, 0, { EFFECT_APPLY_AURA, AURA_NONE, ANY }, { KEEP, AURA_DUMMY } },
    { 31702, 0, { EFFECT_APPLY_AURA, AURA_NONE, ANY }, { EFFECT_SCRIPT_EFFECT } },
    { 31703, 1, { EFFECT_NONE, ANY, ANY }, { EFFECT_SCRIPT_EFFECT } },
    { 31704, 1, { EFFECT_NONE, ANY, ANY }, { EFFECT_SCRIPT_EFFECT } },
    { 43648, 0, { ANY, AURA_DUMMY, ANY }, { KEEP, AURA_MOD_STUN } },
    { 24324, 0, { EFFECT_APPLY_AURA, AURA_DUMMY, ANY },
        { EFFECT_SCRIPT_EFFECT, AURA_NONE, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY } },
    { 24324, 1, { EFFECT_NONE, ANY, ANY }, { EFFECT_APPLY_AURA, AURA_MOD_STUN, TARGET_UNIT_CASTER } },

    Targets(31298, 0, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, KEEP),
    { 9347, 0, {}, { KEEP, AURA_PERIODIC_TRIGGER_SPELL, KEEP, KEEP, KEEP, KEEP, KEEP, 11000, KEEP, KEEP, 24573 } },
    { 30019, 0, {}, { KEEP, KEEP, KEEP, KEEP, 22 } },
    { 30019, 1, {}, { KEEP, AURA_PERIODIC_DUMMY, TARGET_UNIT_CASTER, KEEP, KEEP, -1, KEEP, 2000 } },
    { 30019, 2, {}, { EFFECT_APPLY_AURA, AURA_MOD_CHARM, TARGET_UNIT_TARGET_ANY, KEEP, KEEP, 98 } },
    Targets(24778, 0, TARGET_DEST_CASTER, TARGET_UNIT_DEST_AREA_ENEMY, 15),
    { 40414, 2, {}, { EFFECT_SCRIPT_EFFECT, KEEP, TARGET_UNIT_TARGET_ENEMY, KEEP, KEEP, 40414, 1, KEEP, KEEP, KEEP,
        0 } },
    { 49026, 2, {}, { EFFECT_SCRIPT_EFFECT, KEEP, TARGET_UNIT_TARGET_ENEMY, KEEP, KEEP, 49028, 1, KEEP, KEEP, KEEP,
        0 } },
    { 33525, 0, {}, { EFFECT_APPLY_AURA, AURA_PERIODIC_TRIGGER_SPELL, KEEP, KEEP, KEEP, KEEP, 1, 2000, KEEP, KEEP,
        39187 } },
    { 33525, 1, {}, { EFFECT_SCRIPT_EFFECT, AURA_NONE, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, 0 } },
    Targets(30843, 0, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, KEEP),
    Targets(30843, 1, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, KEEP),
    Targets(802, 0, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENTRY, 20),
    Targets(802, 1, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENTRY, 20),
    Targets(802, 2, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENTRY, 20),
    Targets(804, 0, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENTRY, 23),
    Targets(804, 1, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENTRY, 23),
    Targets(804, 2, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENTRY, 23),
    { 30421, 2, {}, { KEEP, AURA_MOD_INCREASE_HEALTH, KEEP, KEEP, KEEP, -1001, 1 } },
    { 63521, 0, {}, { EFFECT_SCRIPT_EFFECT, KEEP, KEEP, KEEP, KEEP, KEEP, 1, KEEP, 0 } },
    { 47948, 0, {}, { EFFECT_SCRIPT_EFFECT } },
    { 47422, 0, {}, { EFFECT_SCRIPT_EFFECT, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, 0 } },
    { 22247, 0, {}, { EFFECT_APPLY_AURA, AURA_MOD_DECREASE_SPEED, TARGET_DEST_CASTER, TARGET_UNIT_DEST_AREA_ENEMY, 9,
        -81, 1, 0, 0, 0, 0 } },
    { 22247, 1, {}, { EFFECT_APPLY_AURA, AURA_MOD_MELEE_HASTE, TARGET_DEST_CASTER, TARGET_UNIT_DEST_AREA_ENEMY, 9,
        -401, 1, 0, 0, 0, 0 } },
    { 22247, 2, {}, { EFFECT_APPLY_AURA, AURA_MOD_CASTING_SPEED_NOT_STACK, TARGET_DEST_CASTER,
        TARGET_UNIT_DEST_AREA_ENEMY, 9, -81, 1, 0, 0, 0, 0 } },
    { 64702, 0, {}, { EFFECT_SCHOOL_DAMAGE, KEEP, KEEP, KEEP, KEEP, 82874 } },
    { 64702, 1, {}, { EFFECT_INSTAKILL, AURA_NONE, KEEP, KEEP, KEEP, KEEP, 0 } },
    Targets(62166, 0, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, 28),
    Targets(62166, 1, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, 28),
    Targets(62166, 2, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, 28),
    Targets(63981, 0, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, 28),
    Targets(63981, 1, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, 28),
    Targets(63981, 2, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, 28),
    { 37676, 0, {}, { KEEP, AURA_DUMMY, TARGET_SRC_CASTER, TARGET_UNIT_SRC_AREA_ENEMY, 33, KEEP, KEEP, KEEP, 0, 0 } },
    { 45235, 1, {}, { EFFECT_SCRIPT_EFFECT, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, 0 } },
    { 45236, 0, {}, { EFFECT_SUMMON_OBJECT_WILD, AURA_NONE, TARGET_DEST_CASTER, 0, 0, 0, 1, 0, 187366, 0, 0 } },
};

constexpr Restore DEAD_CATALOG_SLOTS[] = {
    { 65139, 0, { EFFECT_NONE, ANY, ANY }, { EFFECT_LEARN_SPELL, KEEP, TARGET_UNIT_CASTER, KEEP, KEEP, KEEP, KEEP, KEEP,
        KEEP, KEEP, 33891 } },
    { 65139, 1, { EFFECT_NONE, ANY, ANY }, { EFFECT_LEARN_SPELL, KEEP, TARGET_UNIT_CASTER, KEEP, KEEP, KEEP, KEEP, KEEP,
        KEEP, KEEP, 5420 } },
    { 19387, 0, { EFFECT_NONE, ANY, ANY }, { EFFECT_APPLY_AURA } },
    { 19387, 1, { EFFECT_NONE, ANY, ANY }, { EFFECT_APPLY_AURA } },
    { 853512, 0, { ANY, AURA_DUMMY, ANY }, { KEEP, AURA_MOD_SPELL_HEALING_OF_ATTACK_POWER } },
    { 853512, 1, { ANY, AURA_DUMMY, ANY }, { KEEP, AURA_MOD_WEAPON_CRIT_PERCENT } },
    { 853512, 2, { ANY, AURA_DUMMY, ANY }, { KEEP, AURA_PROC_TRIGGER_SPELL, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP,
        KEEP, 853513 } },
    { 760100, 0, { EFFECT_DUMMY, ANY, ANY }, { EFFECT_TRIGGER_SPELL, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP, KEEP,
        KEEP, 760101 } },
    { 57340, 0, { EFFECT_APPLY_AURA, AURA_DUMMY, ANY }, { KEEP, AURA_MOD_THREAT } },
    MaxHealthPercentHeal(28176, 1), MaxHealthPercentHeal(28189, 1), MaxHealthPercentHeal(47892, 1),
    MaxHealthPercentHeal(47893, 1), MaxHealthPercentHeal(355621, 1), MaxHealthPercentHeal(1128176, 1),
    MaxHealthPercentHeal(1128189, 1), MaxHealthPercentHeal(1147892, 1), MaxHealthPercentHeal(1147893, 1),
};

constexpr bool Matches(Shape const& broken, std::int32_t effect, std::int32_t aura, std::int32_t targetA)
{
    return (broken.Effect == ANY || broken.Effect == effect) && (broken.Aura == ANY || broken.Aura == aura) &&
        (broken.TargetA == ANY || broken.TargetA == targetA);
}
}

void ApplyAscensionStockScriptShapes(SpellInfo* spellInfo);

#endif
