#ifndef MOD_SKINPEELERQUEST_APEXSCALING_H
#define MOD_SKINPEELERQUEST_APEXSCALING_H

#include "Define.h"

#include <vector>

class Creature;
class Player;
class Unit;

namespace ApexScaling
{
    // Shared percentages. All three apex bosses use these exact values so their
    // offensive scaling is identical: only the ability names differ.
    constexpr float AUTO_PCT = 0.03f;        // per auto attack, pre-armour
    constexpr float WOLF_PCT = 0.01f;        // a summoned add's auto, per swing
    constexpr float ABILITY_PCT = 0.04f;     // a normal ability, per victim
    constexpr float ABILITY_BUDGET = 0.07f;  // total per ability hit, averaged pool
    constexpr float ABILITY_CAP_PCT = 0.10f; // no single victim takes more than this
    constexpr float HEAVY_PCT = 0.06f;       // a telegraphed heavy hit
    constexpr float PERIODIC_PCT = 0.015f;   // one damage-over-time tick
    constexpr uint32 CARRIER_PHYSICAL = 1004310;
    constexpr uint32 CARRIER_NATURE = 1004311;

    struct Profile
    {
        float Pct = 0.0f;
        uint32 Floor = 0;
        uint32 Ceiling = 0;
    };

    // Pool sizing shared by every apex boss: sample the group's real output for
    // fifteen seconds, then set the pool so the fight lasts the target time.
    struct Probe
    {
        uint32 Base = 0;
        uint32 Start = 0;
        uint64 Damage = 0;
        bool Done = false;
    };

    void ResetProbe(Probe& probe, Creature* creature);

    // True while players are still in reach: a momentary evade with the group
    // standing there is not the end of the pull.
    bool StillEngaged(Creature* creature);

    void ObserveProbe(Probe& probe, uint32 damage);

    bool ResolveProbe(Probe& probe, Creature* creature);

    uint32 Amount(Unit* victim, Profile const& profile);

    uint32 ApplyAmount(Creature* caster, Unit* victim, uint32 amount, uint32 carrierSpell);

    uint32 ApplyHit(Creature* caster, Unit* victim, Profile const& profile, uint32 carrierSpell);

    void ApplyAoe(Creature* caster, std::vector<Player*> const& targets, Profile const& profile,
        float budgetPct, float perTargetCapPct, uint32 carrierSpell);

    std::vector<Player*> EngagedPlayers(Creature* creature, float radius);

    void ScaleHealth(Creature* creature, uint32 baseHealth, float referenceItemLevel);

    void RestoreHealth(Creature* creature, uint32 baseHealth);

    // The bosses render at three times their model size, but the server hitbox comes
    // from creature_model_info rows that are placeholders for these custom displays.
    // Both fields are streamed to the client, so tuning them keeps client and server
    // on the same melee range instead of rejecting swings against the visible body.
    void TuneHitbox(Creature* creature);

    // A patrolling creature's leash area is measured from its current waypoint node,
    // not from the home position, so the first hit of a pull can be refused as "out
    // of leash" while the player is touching the boss. Open the leash window before
    // the threat reference is built so a landed opening hit engages in the same tick.
    // Only starts a pull: a boss that is already fighting keeps its victim.
    bool StartApexPull(Creature* creature, Unit* attacker);

    // Anything that pops the chase generator (Winded, a jump, a core reposition
    // spline, an evade frame) leaves the waypoint generator on top and the boss
    // patrols while in combat. Re-issue the chase when no higher movement is active.
    void KeepApexChase(Creature* creature);
}

#endif
