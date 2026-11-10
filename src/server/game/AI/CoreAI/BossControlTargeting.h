/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef BOSS_CONTROL_TARGETING_H
#define BOSS_CONTROL_TARGETING_H

#include "UnitAI.h"

class SpellInfo;

// Vanilla 5-player dungeon bosses, on every difficulty, never use sleep, charm, possession, Zevrim Thornhoof's
// Sacrifice, Darkmaster Gandling's Shadow Portal, Shade of Eranikus' Deep Slumber or Lady Illucia Barov's Fear on a
// player whose specialization tanks or heals: they pick another player, and when nobody else qualifies they do not cast
// at all. Hex of Jammal'an also needs a second player engaged with the boss, so a lone player is never hexed. Area
// spells drop tanks and healers from their targets (except the splash of Doctor Theolen Krastinov's Ghoulish Potion),
// and a boss does not start one aimed at itself unless another player qualifies.
namespace BossControl
{
    bool IsControlSpell(SpellInfo const* spellInfo);
    bool Applies(Unit const* caster, SpellInfo const* spellInfo);
    bool IsProtectedTarget(Unit const* target);
    bool Forbids(Unit const* caster, Unit const* target, SpellInfo const* spellInfo);
    bool ForbidsCast(Unit const* caster, Unit const* explicitTarget, SpellInfo const* spellInfo);
    bool SparesAreaTargets(SpellInfo const* spellInfo);
}

struct BossControlTargetSelector
{
    BossControlTargetSelector(Unit const* unit, SpellInfo const* spellInfo, float dist, bool playerOnly,
        bool withMainTank, int32 aura)
        : _caster(unit), _spellInfo(spellInfo), _default(unit, dist, playerOnly, withMainTank, aura) { }

    bool operator()(Unit const* target) const
    {
        return _default(target) && !BossControl::Forbids(_caster, target, _spellInfo);
    }

private:
    Unit const* _caster;
    SpellInfo const* _spellInfo;
    DefaultTargetSelector _default;
};

#endif
