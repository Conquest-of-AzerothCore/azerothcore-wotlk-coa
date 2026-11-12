# 0238. A removed cooldown's verdict states its global-cooldown limit

- Status: accepted
- Date: 2026-11-12

## Context

ADR 0234 judges a removed cooldown (Justicar of the Light 707663 on Benediction 578276, claim 261) by a second cast
attempted after the global cooldown: refused without the talent, accepted with it. Such a cast cannot tell a cooldown
left below that wait from none. The mentor asked that the verdict state that limit, with a cooldown readback as
supporting data (owner-rulings, "Justicar", 2026-11-12).

## Decision

A cost gate whose reduction removes the cooldown carries `removal` in its model (the gated spell's StartRecoveryTime
and the harness's global-cooldown wait), and its cast-gate verdict states the attempt time, the global cooldown and
that a cooldown left below the attempt time is not told apart from none. Other gates are unchanged, and every
scenario regenerates byte-identical.

## Consequences

- Justicar's removal arms now attempt the second cast 1700 ms after the first (`margin_ms` 100 after the 1600 ms
  wait, 450 ms after Benediction's 1250 ms global cooldown): refused for cooldown (67) without the talent, accepted
  (0) with it, both runs on build f8370be27d42 (20261112-034627 / -034659).
- A `metric_delta` readback reads Benediction's `cooldown_ms` 100 ms after a cast: 5894 without the talent, 0 with
  it. It is data, beside the cast proof.
