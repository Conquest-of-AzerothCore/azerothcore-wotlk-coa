#ifndef TRAINING_DUMMY_IMMUNITIES_H
#define TRAINING_DUMMY_IMMUNITIES_H

#include "Creature.h"
#include "SpellAuraDefines.h"

inline void ApplyTrainingDummyMovementImmunity(Creature* dummy)
{
    for (uint32 effect : {SPELL_EFFECT_KNOCK_BACK, SPELL_EFFECT_KNOCK_BACK_DEST,
        SPELL_EFFECT_PULL, SPELL_EFFECT_PULL_TOWARDS, SPELL_EFFECT_PULL_TOWARDS_DEST})
        dummy->ApplySpellImmune(0, IMMUNITY_EFFECT, effect, true);
    for (uint32 mechanic : {MECHANIC_FEAR, MECHANIC_HORROR, MECHANIC_DISORIENTED, MECHANIC_CHARM})
        dummy->ApplySpellImmune(0, IMMUNITY_MECHANIC, mechanic, true);
    for (uint32 aura : {SPELL_AURA_MOD_FEAR, SPELL_AURA_MOD_CONFUSE, SPELL_AURA_MOD_CHARM,
        SPELL_AURA_MOD_POSSESS, SPELL_AURA_MOD_POSSESS_PET})
        dummy->ApplySpellImmune(0, IMMUNITY_STATE, aura, true);
}

inline void SetTrainingDummyCrowdControlImmunity(Creature* dummy, bool enabled)
{
    constexpr uint32 source = 9780200;
    uint64 mask = 0;
    for (uint32 mechanic : {MECHANIC_CHARM, MECHANIC_DISORIENTED, MECHANIC_DISARM, MECHANIC_DISTRACT,
        MECHANIC_FEAR, MECHANIC_GRIP, MECHANIC_ROOT, MECHANIC_SILENCE, MECHANIC_SLEEP, MECHANIC_SNARE,
        MECHANIC_STUN, MECHANIC_FREEZE, MECHANIC_KNOCKOUT, MECHANIC_POLYMORPH, MECHANIC_BANISH,
        MECHANIC_SHACKLE, MECHANIC_TURN, MECHANIC_HORROR, MECHANIC_INTERRUPT, MECHANIC_DAZE, MECHANIC_SAPPED})
    {
        dummy->ApplySpellImmune(source, IMMUNITY_MECHANIC, mechanic, false);
        if (enabled)
            dummy->ApplySpellImmune(source, IMMUNITY_MECHANIC, mechanic, true);
        mask |= uint64(1) << mechanic;
    }
    for (uint32 effect : {SPELL_EFFECT_KNOCK_BACK, SPELL_EFFECT_KNOCK_BACK_DEST,
        SPELL_EFFECT_PULL, SPELL_EFFECT_PULL_TOWARDS, SPELL_EFFECT_PULL_TOWARDS_DEST,
        SPELL_EFFECT_INTERRUPT_CAST, SPELL_EFFECT_DISTRACT})
    {
        dummy->ApplySpellImmune(source, IMMUNITY_EFFECT, effect, false);
        if (enabled)
            dummy->ApplySpellImmune(source, IMMUNITY_EFFECT, effect, true);
    }
    for (AuraType aura : {SPELL_AURA_MOD_FEAR, SPELL_AURA_MOD_CONFUSE, SPELL_AURA_MOD_CHARM,
        SPELL_AURA_MOD_POSSESS, SPELL_AURA_MOD_POSSESS_PET, SPELL_AURA_MOD_STUN, SPELL_AURA_MOD_ROOT,
        SPELL_AURA_MOD_SILENCE, SPELL_AURA_MOD_PACIFY, SPELL_AURA_MOD_PACIFY_SILENCE,
        SPELL_AURA_MOD_DECREASE_SPEED, SPELL_AURA_MOD_DISARM, SPELL_AURA_MOD_DISARM_OFFHAND,
        SPELL_AURA_MOD_DISARM_RANGED})
    {
        dummy->ApplySpellImmune(source, IMMUNITY_STATE, aura, false);
        if (enabled)
        {
            dummy->ApplySpellImmune(source, IMMUNITY_STATE, aura, true);
            dummy->RemoveAurasByType(aura);
        }
    }
    if (enabled)
        dummy->RemoveAurasWithMechanic(mask);
}

#endif
