#include "ApexScaling.h"

#include "Creature.h"
#include "CreatureAI.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "Player.h"
#include "Spell.h"
#include "Timer.h"
#include "Unit.h"

#include <algorithm>
#include <cmath>

namespace
{
    constexpr float APEX_SCAN_RADIUS = 60.0f;

    // Shared pool blueprint. Kept here so all three bosses behave identically.
    constexpr uint32 APEX_PROBE_MS = 15000;
    constexpr float APEX_TARGET_TTK_S = 240.0f;
    // One or two players must not be able to finish an apex boss at all, so their
    // pool is aimed well past any realistic attempt instead of the normal target.
    constexpr float APEX_SOLO_TTK_S = 600.0f;
    // The probe samples an opening burst: cooldowns are up and there is no movement.
    // Sustained output over a real fight is lower, so the pool is sized against that.
    constexpr float APEX_SUSTAIN_FACTOR = 0.85f;
    constexpr float APEX_POOL_MIN_FACTOR = 0.75f;
    constexpr float APEX_POOL_MAX_FACTOR = 40.0f;
}

namespace ApexScaling
{
    void ResetProbe(Probe& probe, Creature* creature)
    {
        probe = Probe();
        if (!creature)
            return;

        // Create health, not the current maximum: ScaleHealth writes the maximum,
        // so reading it back would compound the factor on every re-initialisation.
        probe.Base = creature->GetCreateHealth() ? creature->GetCreateHealth()
                                                 : creature->GetMaxHealth();
    }

    bool StillEngaged(Creature* creature)
    {
        return creature && !EngagedPlayers(creature, APEX_SCAN_RADIUS).empty();
    }

    void ObserveProbe(Probe& probe, uint32 damage)
    {
        if (probe.Done || !damage)
            return;

        if (!probe.Start)
            probe.Start = getMSTime();

        probe.Damage += damage;
    }

    bool ResolveProbe(Probe& probe, Creature* creature)
    {
        if (!creature || probe.Done || !probe.Start)
            return false;

        uint32 const now = getMSTime();
        if (now < probe.Start + APEX_PROBE_MS)
            return false;

        probe.Done = true;

        // This is three to five player content. A solo player or a duo must not be
        // able to finish it, so their fight is deliberately longer than five minutes
        // instead of the normal target.
        std::size_t const players = EngagedPlayers(creature, APEX_SCAN_RADIUS).size();
        float const ttk = players <= 2 ? APEX_SOLO_TTK_S : APEX_TARGET_TTK_S;

        float const seconds = float(APEX_PROBE_MS) / 1000.0f;
        float const dps = float(probe.Damage) / seconds;
        uint32 const base = probe.Base ? probe.Base : creature->GetMaxHealth();

        uint32 const floorHealth = uint32(float(base) * APEX_POOL_MIN_FACTOR);
        uint32 const ceilingHealth = uint32(float(base) * APEX_POOL_MAX_FACTOR);
        uint32 const target = std::clamp<uint32>(uint32(dps * APEX_SUSTAIN_FACTOR * ttk),
            std::max<uint32>(floorHealth, base / 2), ceilingHealth);

        // Keep the fraction of the bar the group has already removed.
        float const fraction = std::max(0.01f, creature->GetHealthPct() / 100.0f);
        creature->SetMaxHealth(target);
        creature->SetHealth(std::max<uint32>(1, uint32(float(target) * fraction)));

        LOG_INFO("coa", "APEX: {} probe {:.0f} damage over {:.0f}s = {:.0f} dps -> pool {} (base {})",
            creature->GetEntry(), float(probe.Damage), seconds, dps, target, base);

        return true;
    }

    uint32 Amount(Unit* victim, Profile const& profile)
    {
        if (!victim)
            return 0;

        uint32 const pool = victim->GetMaxHealth();
        uint32 amount = uint32(profile.Pct * float(pool));

        if (amount < profile.Floor)
            amount = profile.Floor;
        if (profile.Ceiling && amount > profile.Ceiling)
            amount = profile.Ceiling;

        return std::min(amount, pool);
    }

    uint32 ApplyAmount(Creature* caster, Unit* victim, uint32 amount, uint32 carrierSpell)
    {
        if (!caster || !victim || !victim->IsAlive() || !amount || !carrierSpell)
            return 0;

        // Base points are zero-based, so the stored value is amount - 1. Routing the
        // hit through a real spell keeps armour, resistances, absorbs, crit and the
        // combat log on the engine's own path instead of a hand-applied number.
        caster->CastCustomSpell(carrierSpell, SPELLVALUE_BASE_POINT0, int32(amount) - 1, victim, true);
        return amount;
    }

    uint32 ApplyHit(Creature* caster, Unit* victim, Profile const& profile, uint32 carrierSpell)
    {
        return ApplyAmount(caster, victim, Amount(victim, profile), carrierSpell);
    }

    void ApplyAoe(Creature* caster, std::vector<Player*> const& targets, Profile const& profile,
        float budgetPct, float perTargetCapPct, uint32 carrierSpell)
    {
        if (!caster || targets.empty())
            return;

        struct Hit
        {
            Player* Target;
            uint32 Amount;
        };

        std::vector<Hit> hits;
        uint64 pool = 0;
        uint64 rawTotal = 0;

        for (Player* player : targets)
        {
            if (!player || !player->IsAlive())
                continue;

            uint32 const raw = Amount(player, profile);
            hits.push_back({player, raw});
            pool += player->GetMaxHealth();
            rawTotal += raw;
        }

        if (hits.empty())
            return;

        // The budget caps how much the whole group takes from one tick, so the
        // healer's workload does not grow with the headcount. Scaling every hit
        // by the same ratio keeps each player's share of their own pool equal.
        uint64 const cap = uint64(budgetPct * float(pool) / float(hits.size()));
        float const scale = (cap && rawTotal > cap) ? float(cap) / float(rawTotal) : 1.0f;

        for (Hit const& hit : hits)
        {
            uint32 amount = uint32(float(hit.Amount) * scale);
            if (amount < profile.Floor)
                amount = profile.Floor;

            uint32 const capAmount = uint32(perTargetCapPct * float(hit.Target->GetMaxHealth()));
            if (capAmount && amount > capAmount)
                amount = capAmount;

            ApplyAmount(caster, hit.Target, amount, carrierSpell);
        }
    }

    std::vector<Player*> EngagedPlayers(Creature* creature, float radius)
    {
        std::vector<Player*> players;
        if (!creature)
            return players;

        Map::PlayerList const& list = creature->GetMap()->GetPlayers();
        for (Map::PlayerList::const_iterator itr = list.begin(); itr != list.end(); ++itr)
        {
            Player* player = itr->GetSource();
            if (!player || !player->IsAlive() || !player->InSamePhase(creature))
                continue;
            if (creature->GetExactDist2d(player) > radius)
                continue;

            players.push_back(player);
        }

        return players;
    }

    void ScaleHealth(Creature* creature, uint32 baseHealth, float /*referenceItemLevel*/)
    {
        if (!creature || !baseHealth)
            return;

        std::size_t const players = EngagedPlayers(creature, APEX_SCAN_RADIUS).size();

        // Headcount and gear are deliberately not factors here. The pool is sized from the
        // damage the group actually produces once the probe has run, so a solo player and a
        // five player group end up with the same fight length. It starts deliberately large
        // so the fifteen second probe cannot remove a big share of the bar before it is sized.
        uint32 const scaled = std::max<uint32>(1, baseHealth * 4);

        creature->SetMaxHealth(scaled);
        creature->SetHealth(scaled);

        float const upstream = creature->GetCreateHealth()
            ? float(baseHealth) / float(creature->GetCreateHealth()) : 1.0f;
        LOG_INFO("coa", "APEX: {} base {} (create {} x{:.2f}) -> {} (players {}, probe owns the pool)",
            creature->GetEntry(), baseHealth, creature->GetCreateHealth(), upstream,
            scaled, uint32(players));
    }

    void RestoreHealth(Creature* creature, uint32 baseHealth)
    {
        if (!creature || !baseHealth)
            return;

        creature->SetMaxHealth(baseHealth);
        creature->SetHealth(baseHealth);
    }

    void TuneHitbox(Creature* creature)
    {
        if (!creature)
            return;

        // Re-applied by the update paths as well: a display or scale refresh calls
        // Creature::SetObjectScale, which rebuilds both fields from creature_model_info.
        if (creature->GetBoundaryRadius() == 3.0f && creature->GetCombatReach() == 5.0f)
            return;

        // The three models render at three times their natural size, but the server
        // hitbox comes from the creature_model_info rows behind the custom displays:
        // 1.0/1.0 placeholders for two of them and no row at all for Stormfang, which
        // fell back to the 0.389 world-object size. The resulting 5.0-5.83 yard melee
        // window sits inside the visible body. Both fields are replicated to the
        // client, so the client's prediction uses the same numbers again.
        creature->SetFloatValue(UNIT_FIELD_BOUNDINGRADIUS, 3.0f);
        creature->SetFloatValue(UNIT_FIELD_COMBATREACH, 5.0f);
    }

    bool StartApexPull(Creature* creature, Unit* attacker)
    {
        if (!creature || !attacker || !creature->IsAlive() || !attacker->IsAlive())
            return false;

        // Hits during the evade walk are no-ops in the core; let the evade finish
        // instead of clearing UNIT_STATE_EVADE (which would allow re-pull resets).
        if (creature->IsInEvadeMode())
            return false;

        // Start a pull only. A boss that already has a victim keeps tank threat.
        if (creature->IsEngaged() && creature->GetVictim())
            return false;

        // A patrolling creature's leash area is measured from the current waypoint
        // node, which can be tens of yards ahead of its actual position. The core
        // refreshes this window after the AI/script damage hooks, so a spell or DoT
        // pull builds its first threat reference offline and engagement is deferred
        // (or lost). Opening the window first makes the pull engage synchronously.
        creature->UpdateLeashExtensionTime();
        creature->AI()->AttackStart(attacker);
        return true;
    }

    void KeepApexChase(Creature* creature)
    {
        if (!creature || !creature->IsAlive() || creature->IsInEvadeMode() || !creature->IsInCombat())
            return;

        Unit* victim = creature->GetVictim();
        if (!victim)
            return;

        // Only restore a lost chase: never interrupt a jump, knockback or an active
        // chase generator.
        MovementGeneratorType const motion = creature->GetMotionMaster()->GetCurrentMovementGeneratorType();
        if (motion == WAYPOINT_MOTION_TYPE || motion == IDLE_MOTION_TYPE)
            creature->GetMotionMaster()->MoveChase(victim);
    }
}
