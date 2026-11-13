# 0239. Review fixes: a bonus judged in its stated unit and a removal read at the global cooldown

- Status: accepted
- Date: 2026-11-12

## Context

The side b review of R3 (lean/r3-review-b.md) found:
- I2: Combat Training 706320's hit ratios ("Increases the effectiveness of Oaths by $s1%", 20%) stated the derived
  ratio (1.0561, 1.0462), so the 5%-or-2-points band (ruling I1) applied to +5.61% and +4.62%, not to the stated 20%.
- I4: the removal arms of ADR 0234 attempt the second cast at the harness's 1600 ms wait plus `margin_ms`, so a residual
  cooldown below that wait passes. ADR 0234's "the finest wait the global cooldown leaves" is wrong: the spell's own
  global cooldown (Benediction 1250 ms) is the floor, not the harness wait.
- M1: ADR 0233's "1666 of 1666 scenarios" overstates it: Radiance 706318 changed on purpose (`armed_for`), and the two
  Tempests and four Holy Edge entries changed through their own data edits; the 1659 other scenarios were identical.
- M3: ADR 0237 does not say why the existing `client_packet` action was not used for the landing.

## Decision

- `hit_ratio` reads `stated: {"bonus", "parts"}`: the percent parts of the effect the talent scales that reach the
  observed spell. The expected ratio must equal prod(1 + part x (1 + bonus)) / prod(1 + part) (else the entry is
  refused). The judge reads the measured ratio and its 99% interval back as that bonus (by bisection, the function is
  monotone) and applies the band, the power rule and the excluded interval to the stated bonus.
- `cost_gate` reads `removal_wait_ms` for a removed cooldown: the second cast is attempted that long after the first,
  which must lie between the gated spell's StartRecoveryTime and its cooldown, and the remaining cooldown
  (`cooldown_ms`) is read right after the first cast in every arm; with the talent it must read 0.
- Claim 117 keeps the harness `fall` action of ADR 0237. `client_packet` cannot write a MovementInfo: its field kinds
  are u8, u32, u64, strings and a fixed set of object references, with no packed actor GUID, no float and no way to put
  the actor's run-time position into the packet, and a landing packet must carry the player's packed GUID and its
  current x, y, z (MovementHandler.cpp:357-396, `ReadMovementInfo`). Adding those kinds would be a larger harness
  change through the anticheat path than one call of the landing function.
- Entries without the new fields regenerate byte-identical.

## Consequences

- On build f8370be27d42, Combat Training reads +19.67%, +19.77% and +19.67% (99% intervals about +-0.6 to +-0.8)
  against 18-22% on Oath: Righteous Lunge, Condemn and Vindication, with 3 pooled parts of 80 trials per arm
  (diagnostic 20261112-035610).
- Justicar of the Light: Benediction's remaining cooldown reads 5997 ms right after a cast without the talent and 0
  with it; the second cast at 1350 ms (100 ms after its 1250 ms global cooldown) is refused (67) without and accepted
  with it.
- Seeded tests: the stated bonus round-trips through the ratio; a ratio that the derived band accepted alerts in the
  stated unit at 12% and 28%; an expected ratio off the stated bonus is refused; a residual cooldown alerts; a removal
  wait inside the global cooldown is refused.
