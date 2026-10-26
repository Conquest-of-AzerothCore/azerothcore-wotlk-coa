/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_CREATURE_SCALING_H
#define COA_CREATURE_SCALING_H

class SpellInfo;
class Unit;

namespace CreatureScaling
{
float DamageMultiplier(Unit const* target, Unit const* attacker);
float SpellDamageMultiplier(Unit const* target, Unit const* attacker, SpellInfo const* spell);

class TestOverride
{
public:
    TestOverride();
    ~TestOverride();
    TestOverride(TestOverride const&) = delete;
    TestOverride& operator=(TestOverride const&) = delete;
};
}

#endif
