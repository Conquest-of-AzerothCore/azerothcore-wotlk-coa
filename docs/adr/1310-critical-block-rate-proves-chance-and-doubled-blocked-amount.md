# 1310. Critical block rate proves incoming critical block chance and exact doubled blocked amount

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39; G-39 harness note; Cultist ADR 0010

## Context

Cultist Shadowy Symbiosis `680574` (`Spell.dbc`) states: `"Your successful blocks now have a $s2% chance to
critically block for twice the normal amount. This effect is doubled while above 60 Insanity."` (`$s2 = 20%`).
Cultist ADR 0010 fixed `680574` so `Unit::GetTotalAuraModifier(SPELL_AURA_MOD_BLOCK_CRIT_CHANCE)` returns `20%` at
`0/59/60` Insanity and `40%` at `61` Insanity, but `critical_block_chance` is a `READBACK` metric (`data` evidence),
leaving `r242[0]` and `r243[0]` without a live combat-event proof of `Unit::isBlockCritical()` (`Unit.cpp:2083`,
`3719-3721`) or of the doubled blocked amount (`Unit.cpp:2084`).

`Unit::SendAttackStateUpdate` (`Unit.cpp:7858-7863`) already writes `uint32(damageInfo->blocked_amount)` inside
`SMSG_ATTACKERSTATEUPDATE` whenever `HitInfo & HITINFO_BLOCK`, right after `TargetState` and two `uint32` fields.
`CoAGameplayTest.cpp:1881-1891` stopped parsing after `victimState`, discarding `blocked_amount`.

## Options

- Reclassify `critical_block_chance` in `coverage.py` (`PARTNERED_CONTRASTS`). Rejected: that would promote a
  readback without ever testing combat block rolls or the `2x` blocked amount.
- Record `blocked_amount`, `damage`, and `victimState` from `SMSG_ATTACKERSTATEUPDATE` on `Actor` for incoming
  blocked hits, expose two opt-in read-only metrics (`melee_blocks_taken_count`, `melee_blocks_taken_total`), and
  build an opt-in pooled kind `critical_block_rate` (`ORDER = 59`). Chosen.

## Decision

1. **Opt-in harness reads `melee_blocks_taken_count` and `melee_blocks_taken_total`** (`CoAGameplayTest.cpp`,
   `run.py`):
   - `ObservePacket` parses the existing trailing `unknownAttackerState`, `meleeSpellId`, and conditional
     `blockedAmount` (when `hitInfo & HITINFO_BLOCK`) on `SMSG_ATTACKERSTATEUPDATE` and appends
     `{ blockedAmount, damage, victimState }` to `actor.meleeBlocksTaken` when `victim == actor.guid`.
   - `melee_blocks_taken_count` accepts optional `block_kind` in `all` (default), `normal` (`blockedAmount == B`,
     partial block), `critical` (`blockedAmount == 2 * B`, partial block), `other` (partial block with any other
     amount), or `full` (`victimState == VICTIMSTATE_BLOCKS`), where `B = player->GetShieldBlockValue()`.
   - `melee_blocks_taken_total` accepts optional `block_kind` in `all`, `normal`, `critical`, `other` and sums
     `blockedAmount`.
   - Purely read-only packet observation; zero gameplay effect and zero change to existing metrics.
2. **Opt-in behaviour kind `critical_block_rate`** (`kinds/critical_block_rate.py`, `ORDER = 59`):
   - Registers `METRIC_EVIDENCE = {'melee_blocks_taken_count': 'event', 'melee_blocks_taken_total': 'event'}` inside
     the kind module (zero edits to `coverage.py`).
   - Drives stationary melee strikers with AP/haste fixtures (`35785` ensures raw melee hits exceed `2 * B`, so no
     block is clamped to a full block) under `dodge = 0, parry = 0, block = 100`.
   - Verifies shield slot, precondition aura stacks (`after_setup_stacks`, including Insanity and threshold markers)
     at arm start, after every combat window (`window_ms`), and at arm end, and constant `block_value` `B` (start and
     end) in both unlearned control and learned treatment arms; any missing or drifted stack voids the arm as
     `unmeasured`.
   - Voids as `unmeasured` on any clamped full block (`full > 0`); alerts on any non-`1x/2x` amount (`other > 0`),
     any amount-ratio deviation from `2.0x`, any control critical block, or a 99% Wilson interval outside the G-20
     `±2 pt` band over the exact binomial minimum sample (`>= 14,716` at 20%, `>= 22,014` at 40%, pair residual
     false-fail and false-pass `<= 0.1%`).

## Consequences

- Strictly opt-in: finished classes regenerate byte-identical (`coverage.py` and `behaviours.py` untouched).
- Unlocks Cultist Shadowy Symbiosis `680574` rows `r242[0]` and `r243[0]` with full combat-event `behaviour`
  evidence for both rate (`20%` at 0 and 60 Insanity, `40%` at 61 Insanity) and exact `2.0x` blocked amount.
