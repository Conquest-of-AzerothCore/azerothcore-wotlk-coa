# 0132. Cast-state, immunity and threat-slope behaviour kinds

- Status: accepted
- Date: 2026-11-11

## Context

Lean Templar batch 1, chunk 1 (`lean/batch1-brief.md`) drew three clauses that no conformance check could prove in
game: Testament of Resolve 804228 "Usable while feared." and "granting immunity to fear, charm, and horrify effects",
and Faith Guard 705259 "High Threat Holy damage". The first two had no measurement at all or only the `$d` readback;
the third had no stated number until the owner ruling of 2026-11-10 (threat x2 on damage, the flat +100 kept,
"measure the x2 slope"). Lorescribe 804927 "Increases your Holy spell damage by $s3% of your Agility." already had a
learned-contrast `passive_delta` on `spell_power`, counted data because `coverage.STATE_PROMISES` named that stat
only by "spell power".

## Considered options

1. Extend `cast_condition` with a "feared" condition. Rejected: `cast_condition` refuses the spell when its
   condition is unmet; "usable while feared" allows it in a state that refuses others, so the contrast needs a
   control spell, not the same spell.
2. Read immunity with the in-process `spell_immune` probe. Rejected as proof: it is a readback (data); the clause
   promises that effects do not land.
3. New kinds `cast_state`, `immunity`, `threat_slope`, each judged exactly, with the observed outcome (a cast
   result, an aura on the caster, the creature's threat after a landed hit). Chosen.

## Decision

- `cast_state` (check `behaviour_cast_condition`): the dummy applies `state_aura`; `control_spell` must be refused
  with `blocked_result`, the state must hold, `spell` must go through.
- `immunity` (check `behaviour_immunity`, behaviour evidence): each fixture lands before the cast (`set_aura` from the
  dummy) and does not land after it in three real creature casts; a named word without a fixture stays an unproven
  claim.
- `threat_slope` (check `behaviour_threat_slope`, behaviour evidence): one landed hit of `hit_spell` at a fresh dummy,
  `(threat - flat) / health lost` within 0.001 of `expected_slope`, the flat part summed from the spell's
  `SPELL_EFFECT_THREAT` points.
- `STATE_PROMISES['spell_power']` also matches "spell damage".

## Consequences

- Three checks count as new check kinds in the batch report; the promise word is a counted rule change.
- The "spell damage" word reaches two Templar clauses, the only ledger clauses with "spell damage" and a
  `spell_power` label: Lorescribe 804927 (ok in both chunk 1 runs, now behaviour) and 705281 "Increases your Holy
  spell damage by $s1% of your attack power" (`705281 e0 spell_power 1` ok in round 10 run2, not rerun here).
- The charm claim of Testament of Resolve stays unproven: no charm fixture is built, since a charm aura would hand
  the player fixture to the dummy's control.
