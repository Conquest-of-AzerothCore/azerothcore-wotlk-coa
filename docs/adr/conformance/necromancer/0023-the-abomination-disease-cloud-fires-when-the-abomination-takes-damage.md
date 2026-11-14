# 0023. The Abomination's disease cloud fires when the Abomination takes damage

- Status: accepted
- Date: 2026-11-13
- Split from ADR 0530 before publication (mentor ruling 2, 2026-11-13): this ADR keeps the class fix; the harness and
  conformance tool changes its regression needs are [ADR 0530](../../0530-a-strike-may-target-an-owned-creature.md)
  (shared).

## Context

Raise: Abomination 500335 ("Nature damage to enemies"): an Abomination 50068 cast Disease Cloud 802353 on itself
every 3000 ms while in combat or while a hostile player stood in the cloud (`UpdateAI` event 2, `PlayerInCloud`).
The owner ruled (Q-a1-7, option a, 2026-11-13, [class rulings](rulings.md)) that the cloud fires only when the
Abomination is attacked; the live logs fit that trigger in 7% of hits only, the ruling decides. Fix note FN-own-4 was
approved by the mentor (09:3x) with the condition that the harness change making an enemy cast at another actor's
minion is test-only (G-39); that change is shared ADR 0530.

## Decision

- `npc_ascension_necromancer::DamageTaken`: an Abomination 50068 that takes damage (`damage > 0`) from an attacker its
  owner may attack, while not pacified and not controlled, casts 802353 on itself. Every damaging hit counts, a
  periodic tick included; no minimum gap was ruled. The 3000 ms pulse and `PlayerInCloud` are removed. The cloud
  stays the area hit around the Abomination.

## Consequences

- Regression (class file 500335, using the owned-creature strikes of shared ADR 0530): `cloud` (script_hit): both arms
  raise the Abomination and command it into the dummy; the control arm, in combat but not attacked, counts no 802353
  hit; the treatment arm's striker hits the Abomination once per trial and the cloud hits the dummy at the modelled
  amount. `cloud_per_strike` (metric_delta): a raised Abomination not attacked casts no 802353 (control); commanded
  into the dummy and struck 4 times it casts at least 4 (owned_creature_spell_cast_count). Runs read 4 to 6: further
  damaging hits on the Abomination, most likely the striker's melee answer to a cloud, which no metric reads (not
  verified). `cloud_unattacked` (the mentor's control arm): commanded into the dummy, in combat but not attacked for
  7000 ms (more than two old pulse periods), the Abomination casts no cloud. No metric reads damage taken by an owned
  creature, so the casts are not judged equal to damage-taken events.
- Cloud hits feed the minion proc branch and the Chomp trigger (707283 trigger_count 500335): their rates fall when
  the Abomination is not attacked. The out-of-combat PvP pulse is gone. Under heavy attack (several attackers, ticks)
  the cloud can fire more often than the old pulse.
