# 0497. An energize count is a proc event

- Status: accepted
- Date: 2026-11-13

## Context

Raising the Kirin Tor 805649: "Your Command spells now have a $h% chance to refund a portion of their Runic Power
cost." Its proc casts nothing: `player->EnergizeBySpell(player, 359505, ...)` (AscensionNecromancerAbilities.cpp:
320-321) only sends an energize log. A `procs` entry could count casts, spell damage, melee attacks or minion procs,
not energizes, although the harness reads `spell_energize_count` and the energize-amount expectations already use it.

## Decision

- `spell_energize_count` of `proc_spell` is a proc event metric (`procs.EVENT_METRICS`), read on the caster without a
  target.

## Consequences

- Raising the Kirin Tor's chance is read on Command: Undead casts (39.76% / 39.75% over about 23800 trials, inside the
  band 38%-42% of $h = 40).
- Templar `generate --class 19` and `--stack` are byte-identical. Test: `test_an_energize_count_is_a_proc_event`.
