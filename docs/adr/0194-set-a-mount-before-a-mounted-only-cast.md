# 0194. Set a mount before a mounted-only cast, and read an area aura beyond its radius

- Status: accepted
- Date: 2026-11-12

## Context

Crusader's Presence 562302 "Can only be used while Mounted": the Templar OnSpellCheckCast hook refuses the cast with
SPELL_FAILED_ONLY_MOUNTED (91) when the caster is not mounted, and the DBC carries no CasterAuraSpell for it. Its value
scenario's cast therefore failed, so its aura amount, duration and cooldown read `unmeasured` (claims 124 and 126).
Claim 125, "for all party and raid members within $a1 yds", had only a radius readback. Divine Charge 527023's
"increasing their movement speed by $527272s2%" (claim 101) had only a `not_measured` effect read.

## Considered options

1. A harness mount action. Rejected: Brown Horse 458's aura 78 already mounts the caster through `set_aura` (the
   cast_condition entry proves it).
2. A per-spell list of auras set before the cast, in the class file and in the entries that cast. Chosen.

## Decision

- Class-file section `cast_auras` (`spell`, `auras`, `reason`): a value scenario sets those auras on the caster just
  before casting that spell. `cast_applies_aura` and `aura_presence` entries take `caster_auras` for the same purpose.
- `aura_presence` takes `target_distance` (the grouped ally is relocated that far before the cast) and `present`
  (false: the ally must stay without the aura, and a second expectation requires the caster to carry it, so a failed
  cast cannot pass).
- Entries: 562302 duration with its expiry pair; 562302 aura presence on a grouped ally at 35 yd (inside the 40 yd
  radius) and at 45 yd (outside); 527023 `steed_speed`, run_speed_rate 1.0 to 2.0 in a learned contrast.

## Consequences

- One counted pair each: claims 124 (its aura amount now reads 50), 125, 126 and 101 become behaviour proven.
- 101's `effect_value 527272e1` label, `not_measured`, leaves the ledger; the run speed read is its evidence.
- The value scenario of 562302 changes (the mount before its cast); every other existing scenario regenerates
  byte-identical.
- Claim 128, "Does not stack with similar effects", stays open: a run speed read with a second NOT_STACK mounted-speed
  aura is a state read, and the clause names no stat, so coverage would count it as data (a mentor question).
- Tests: `test_behaviours.MountedCastTests`.
