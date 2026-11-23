# 1021. Ally heals are read per ally player around a window

- Status: proposed (draft, Witch Doctor cycle 10 task T; provisional number, renumbered at merge, guide 14.4)
- Date: 2026-11-21
- Builds on: ADR 0581 (kind modules), ADR 0592 (radius_edge)

## Context

Witch Doctor heals choose their targets by script: Mojo Beam grows a branch to the first grouped ally within 15 yd of
each healed branch (`AscensionWitchDoctorBrewing.cpp`, `Tick`), Mojo Wave heals the two lowest-health grouped allies
within 15 yd of a Beam target (`Heal`), and `Allies()` (`AscensionWitchDoctorCompletion.cpp`) keeps only grouped,
living allies in line of sight, sorted by health. `metric_delta` places creatures only and reads one target;
`ally_heal_breadth` places allies at one distance from the caster and casts at the dummy; `party_stat_ratio` and
`party_pulse` read stats or pulses. The cycle 10 worklists hold 94 tool-gap and 38 no-route parts; 18 of them need
ally players at chosen places and a per-ally read: 9 a per-ally heal read with at most 7 allies, 4 more than 7 allies,
4 an aura or dispel read on allies and 1 a power read on an ally of another class (tool notes T-ally, T-ally2, T-pd,
T-c9-TB-1 and the unnamed "ally fixtures with a per-ally heal read" notes of 501117, 707212, 707617, 802487 and
500957). The harness already has
everything such a read needs: several player fixtures, `relocate` (dx and dy), `group`, `set_health` with a maximum
on a player actor and `spell_heal_count` / `spell_heal_total` / `spell_effective_heal_total` with a `target`.

## Options

1. `metric_delta` ally actors (a `MetricDeltaSpec` change in `behaviours.py`, owner-owned).
2. An option module: an option adds fixtures and steps at named points, but the verdict stays one metric read on one
   unit, so a per-ally pattern needs its own judge anyway.
3. A kind module that places the allies, makes real casts in bracketed windows and judges per-ally increments.

## Decision

Option 3, kind `ally_heal_reach` (`kinds/ally_heal_reach.py`, page `docs/kinds/ally_heal_reach.md`). Allies are player
fixtures moved by `relocate` steps (at most 20 yd each) to stated `dx, dy`, grouped or not, with an optional health
and maximum set at each phase start; `learn` lists spells learned once before the phases. Each phase reads every
ally's heal count, total and effective total of the judged spells at the start and the end of its window around the
real casts; a cast may refill the caster's power during its window (a precondition fixture for a channel whose drain
is not the claim). With `gate_spell` a control phase precedes the learn. Four judges: `reach` (healed and unhealed
allies, a reference that proves the cast ran, an optional witness that proves an unhealed ally was reachable, 0 in the
control), `offsets` (exact per-ally count offsets against a reference), `per_source` (heals of one spell per heal of
another, no source overheal) and `share` (mean heal against a stated share of the mean effective source heal, inside a
stated rounding band). The check is `behaviour_metric_delta` on `spell_heal_count` or `spell_heal_total`, both event
class in `coverage.METRIC_EVIDENCE`; no coverage row is added or overridden.

## Consequences

- Generated scenarios of classes 13, 15, 19 and 23 are byte-identical with the module and without its entries (temp
  copy, `diff -r`, 2026-11-21); the Witch Doctor class file gains three entries (501117 branches, 707617 wave, 802487
  unstable_radius), three scenarios and six labels for clauses 40, 41, 281 (two claims) and 331 (the radius claim).
- Schema 1 holds 8 players, so at most 7 allies; a cap above 6 (Healing Ward "8 nearby allies", Bones Potion "up to 8
  allies") needs schema 2 (25 players) and stays open.
- The positions assume all player fixtures spawn at the caster's point, as `ally_heal_breadth` and `party_pulse` do.
- A party holds the caster and 4 allies. The harness `group` step converts a full party to a raid before it adds the
  next member (`CoAGameplayTest.cpp`, `group`: `IsFull`, `ConvertToRaid`), so a fifth to seventh grouped ally stands
  in a second raid subgroup. Raid-wide searches (`IsInRaidWith`, the Witch Doctor `Friendly()`) still see it; a
  party-only search does not. A party-only claim keeps to 4 grouped allies, and the scenario contract names the allies
  past the party.
- Without a `witness_spell`, the 0 of an unhealed ally in `reach` cannot be told apart from a line of sight, spawn or
  relocation fault. The pass shows that the healed allies were reached and the unhealed ones were not. It can still
  alert on a heal that reaches too far, but its unhealed side is weaker than a witnessed one. The page asks for
  placement on the line of a healed ally and a stated limit, and the verdict names such allies.
- A cast's `CasterAuraSpell` is set by `set_aura` before the cast (`required_aura_steps`), a precondition fixture
  named in the contract; an entry states it with its cost reason (guide 3.4), and a claim about that aura cannot use
  this kind.
- A `share` check is unmeasured below its minimum count, so a server without the behaviour fails the `reach` or
  `per_source` check of the same entry instead; `share` is paired with one of them.
- Seeded tests in `kinds/test_ally_heal_reach.py`: the layout, the gate order, the refused specs, and for each judge
  the server shape (ok), the absent behaviour (alert) and the run that cannot show it (unmeasured).
- A later class may add a judge (a cap with headroom, a heal-per-ally amount) to the same module.
