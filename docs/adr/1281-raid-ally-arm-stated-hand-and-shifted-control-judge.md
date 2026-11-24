# 1281. ally_arm raid of ten, a stated hand for a flat-then-percent weapon strike, and the shifted-control judge

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-24

## Context

Three Felsworn parts were tool gaps (triage groups B-ALLY, B-SH, B-SP2):

- 220.0, Taskmaster's Army 800220 "and it now affects all allies": Infernal Whipcrack 805243 caps its targets at 8
  (MaxAffectedTargets, `$i`) and carries SPELL_ATTR3_ONLY_ON_PLAYER, so only more than eight players tell "all" from
  the cap. `metric_delta` `ally_arm` offered 1 to 7 allies on scenario schema 1 (8 players). The harness already
  accepts schema 2 with 25 players (`CoAGameplayTest.cpp` `MaximumPlayers`) and converts a full party to a raid.
- 17.1, Betrayer 300476 "$804336s2% off-hand Weapon Damage": the strike 804336 has a normalized weapon effect with a
  flat point (Effect[0]) before the 40% weapon percent effect (Effect[1]). `script_hit` `normalized_percent`
  (ADR 0990) modelled only the other order with no flat part, and the main hand only. The DBC gives 804336 no
  off-hand attribute; the tooltip names the off hand.
- 253.0, Unphased 803645 "Increases your spell penetration by ${-($m1+0)}, scaling with your level": its effect value
  read is `ambiguous_tooltip` (sign). A behaviour read of the penetration needs either an engine formula of the resist
  chance (not a tooltip or DBC value) or an equality of two reads, which alone cannot be told from no effect
  (ruling D-360).

## Options

- 220.0: friendly creatures (refused targets, fw-l2); a count read through `aura_amount` or `spell_damage_taken`
  (readbacks, refused by `ally_arm`); `ally_arm` with up to nine allies on schema 2.
- 17.1: a new kind; the DBC hand (the expectation would then contradict the tooltip); the existing option widened to
  the engine's other order with an opt-in `hand` stated from the tooltip.
- 253.0: an engine resist formula as the expected value; a delta of 0 against a lowered fixture (D-360); a judge that
  needs equality with a shifted control and a stated separation from the unshifted control.

## Decision

- `ally_arm.allies` goes from 0 to 9 (`ally8`, `ally9`); more than eight players switch the scenario to schema 2 and
  the contract says so. Entries with seven allies or fewer generate byte-identically. Raid subgroup 2 is `ally5` to
  `ally9`. No judge, evidence class or tolerance changes (controller go).
- `script_hit` `normalized_percent` also models a normalized weapon effect with a flat part (one die side, no points per
  level) followed by a weapon percent effect, in the engine's sequence (`SpellEffects.cpp:4732-4747`):
  int((roll + int(flat x hand factor)) x percent / 100). `hand: "off"` states the tooltip's hand for that order only:
  the off-hand weapon of the entry's set and the off-hand factor 0.5 (`Unit.cpp:519`). The expectation follows the
  tooltip, so a server that strikes with the main hand alerts (controller go; the alert is a server lead, not a fix).
- `metric_delta` `shifted_control` (Felsworn D-108 and D-110, 2026-11-24): the resist chance against the dummy is read
  in a control (fixture resistance R), a shifted control (R minus the shift, its resistance read) and the treatment (R,
  the gate learned). The shift is the gate's DBC points at the caster level, stated in the entry and checked at
  generation; R is at least twice the shift. `ok` needs control - treatment >= discrimination_share x span and
  |shifted control - treatment| <= tolerance_share x span (span = control - shifted control); a span that does not move
  or a fixture read off is `unmeasured`. `spell_resist_chance` is a readback with a `CONTRAST_PROOF` learned row and the
  penetration words (the `spell_done_crit_chance` precedent, ADR 0691).

## Consequences

- 220.0 reads the count of the ten raid players holding 805243 (`800220 behaviour_metric_delta whipcrack_all`):
  Effect[2] of 805243 has a 15 yd radius against 20 yd for Effects[0-1], so the engine selects it apart
  (`Spell.cpp:1003-1004`). With the allies at 20.0 yd it reaches the caster alone, and the count without 800220 is 8 or
  9 (both the cap of 8), expected 8.5 +- 0.5; with 800220, 10. Per-ally distance arms prove the placement.
- 17.1 reads `300476 script_hit 804336 offhand_strike`. Code reading: the server casts 804336 with BASE_ATTACK
  (`Spell.cpp:597-603`, `AscensionFelswornEvents.cpp:227`); the pair alerts (59.6 and 60.2 against the off-hand 29.75,
  the main-hand model 59.4), an owner question, not a fix.
- `hand` without `normalized_percent`, any other value, or on the other effect order is refused.
- 253.0 reads `803645 behaviour_metric_delta spell_pen` (level 60, shift 60) and `spell_pen_level40` (level 40, shift
  40), tolerance_share 0.05 (excludes a penetration 10% off the shift under a resist chance linear in resistance) and
  discrimination_share 0.5 (excludes no penetration and half of it). It proves the caster's penetration as the engine
  applies it to the resist chance, not observed resists. A new readback metric with promise words cannot move a finished
  class: no finished class reads `spell_resist_chance`.
