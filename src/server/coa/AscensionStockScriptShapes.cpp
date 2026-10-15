/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionStockScriptShapes.h"
#include "DBCStores.h"
#include "SpellInfo.h"
#include <unordered_map>
#include <vector>

namespace AscensionStockScriptShapes
{
static_assert(EFFECT_APPLY_AURA == SPELL_EFFECT_APPLY_AURA && EFFECT_SCRIPT_EFFECT == SPELL_EFFECT_SCRIPT_EFFECT &&
    EFFECT_LEARN_SPELL == SPELL_EFFECT_LEARN_SPELL && EFFECT_TRIGGER_SPELL == SPELL_EFFECT_TRIGGER_SPELL &&
    EFFECT_SUMMON_OBJECT_WILD == SPELL_EFFECT_SUMMON_OBJECT_WILD && EFFECT_DUMMY == SPELL_EFFECT_DUMMY &&
    EFFECT_SCHOOL_DAMAGE == SPELL_EFFECT_SCHOOL_DAMAGE && EFFECT_INSTAKILL == SPELL_EFFECT_INSTAKILL);
static_assert(AURA_DUMMY == SPELL_AURA_DUMMY && AURA_MOD_CHARM == SPELL_AURA_MOD_CHARM &&
    AURA_MOD_THREAT == SPELL_AURA_MOD_THREAT &&
    AURA_MOD_STUN == SPELL_AURA_MOD_STUN && AURA_PERIODIC_TRIGGER_SPELL == SPELL_AURA_PERIODIC_TRIGGER_SPELL &&
    AURA_MOD_DECREASE_SPEED == SPELL_AURA_MOD_DECREASE_SPEED &&
    AURA_MOD_INCREASE_HEALTH == SPELL_AURA_MOD_INCREASE_HEALTH &&
    AURA_PROC_TRIGGER_SPELL == SPELL_AURA_PROC_TRIGGER_SPELL &&
    AURA_MOD_WEAPON_CRIT_PERCENT == SPELL_AURA_MOD_WEAPON_CRIT_PERCENT &&
    AURA_MOD_CASTING_SPEED_NOT_STACK == SPELL_AURA_MOD_CASTING_SPEED_NOT_STACK &&
    AURA_CHANNEL_DEATH_ITEM == SPELL_AURA_CHANNEL_DEATH_ITEM && AURA_MOD_MELEE_HASTE == SPELL_AURA_MOD_MELEE_HASTE &&
    AURA_PERIODIC_DUMMY == SPELL_AURA_PERIODIC_DUMMY &&
    AURA_MOD_SPELL_HEALING_OF_ATTACK_POWER == SPELL_AURA_MOD_SPELL_HEALING_OF_ATTACK_POWER);
static_assert(TARGET_UNIT_CASTER == ::TARGET_UNIT_CASTER && TARGET_UNIT_TARGET_ENEMY == ::TARGET_UNIT_TARGET_ENEMY &&
    TARGET_UNIT_SRC_AREA_ENTRY == ::TARGET_UNIT_SRC_AREA_ENTRY &&
    TARGET_UNIT_SRC_AREA_ENEMY == ::TARGET_UNIT_SRC_AREA_ENEMY &&
    TARGET_UNIT_DEST_AREA_ENEMY == ::TARGET_UNIT_DEST_AREA_ENEMY && TARGET_DEST_CASTER == ::TARGET_DEST_CASTER &&
    TARGET_UNIT_CASTER_AREA_PARTY == ::TARGET_UNIT_CASTER_AREA_PARTY && TARGET_SRC_CASTER == ::TARGET_SRC_CASTER &&
    TARGET_UNIT_TARGET_ANY == ::TARGET_UNIT_TARGET_ANY);

namespace
{
std::unordered_map<uint32, std::vector<Restore const*>> const& RestoresBySpell()
{
    static std::unordered_map<uint32, std::vector<Restore const*>> const bySpell = []
    {
        std::unordered_map<uint32, std::vector<Restore const*>> restores;
        for (Restore const& restore : RESTORES)
            restores[restore.SpellId].push_back(&restore);
        for (Restore const& restore : DEAD_CATALOG_SLOTS)
            restores[restore.SpellId].push_back(&restore);
        return restores;
    }();
    return bySpell;
}

void Apply(SpellEffectInfo& effect, Slot const& stock)
{
    if (stock.Effect != KEEP)
        effect.Effect = SpellEffects(stock.Effect);
    if (stock.Aura != KEEP)
        effect.ApplyAuraName = AuraType(stock.Aura);
    if (stock.TargetA != KEEP)
        effect.TargetA = SpellImplicitTargetInfo(uint32(stock.TargetA));
    if (stock.TargetB != KEEP)
        effect.TargetB = SpellImplicitTargetInfo(uint32(stock.TargetB));
    if (stock.Radius != KEEP)
        effect.RadiusEntry = stock.Radius ? sSpellRadiusStore.LookupEntry(uint32(stock.Radius)) : nullptr;
    if (stock.BasePoints != KEEP)
        effect.BasePoints = stock.BasePoints;
    if (stock.DieSides != KEEP)
        effect.DieSides = stock.DieSides;
    if (stock.Amplitude != KEEP)
        effect.Amplitude = stock.Amplitude;
    if (stock.MiscValue != KEEP)
        effect.MiscValue = stock.MiscValue;
    if (stock.MiscValueB != KEEP)
        effect.MiscValueB = stock.MiscValueB;
    if (stock.Trigger != KEEP)
        effect.TriggerSpell = uint32(stock.Trigger);
    if (stock.ItemType != KEEP)
        effect.ItemType = uint32(stock.ItemType);
}
}
}

void ApplyAscensionStockScriptShapes(SpellInfo* spellInfo)
{
    using namespace AscensionStockScriptShapes;
    auto const restores = RestoresBySpell().find(spellInfo->Id);
    if (restores == RestoresBySpell().end())
        return;
    for (Restore const* restore : restores->second)
    {
        SpellEffectInfo& effect = spellInfo->Effects[restore->EffectIndex];
        if (Matches(restore->Broken, int32(effect.Effect), int32(effect.ApplyAuraName),
            int32(effect.TargetA.GetTarget())))
            Apply(effect, restore->Stock);
    }
}
