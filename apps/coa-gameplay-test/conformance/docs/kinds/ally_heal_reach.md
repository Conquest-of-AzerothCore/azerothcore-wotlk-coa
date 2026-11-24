# Ally heal reach (`behaviour_metric_delta`, `kind: "ally_heal_reach"`, ADR 1021, provisional)

Ally players stand where an area, chain or branch heal decides who it reaches, and the caster's heals on each ally are
read per window. `allies` lists up to 24 players (schema 1 holds 8 with the caster; more than 7 allies make the
scenario schema 2, which holds 25, ADR 1122), each `{id, dx, dy}` in yards from
the caster's spawn on the world axes (moved by `relocate` steps of at most 20 yd), `grouped` (true: joined to the
caster's group, which script searches such as `Friendly()` need; false: a same-faction player outside the group) and
an optional `health` with its `maximum` (both or neither, health below the maximum, regeneration off: a fixed health
order for a lowest-health pick, and a pool no window can overheal).

Grouping is the harness `group` step, one per grouped ally in list order. A party holds the caster and 4 allies: on
the fifth grouped ally the step converts the full party to a raid (`CoAGameplayTest.cpp`, `group`: `IsFull` then
`ConvertToRaid`), and that ally and every later one join another raid subgroup. A search that needs the raid or only
the group (`IsInRaidWith`, `Friendly()`) still sees them; a party-only search (same subgroup, `IsInSameGroupWith`, a
party aura or a "party members" heal) does not. Keep a party-only claim to at most 4 grouped allies; the scenario
contract names the allies past the party when there are more.

Each phase sets the health, reads every ally's `spell_heal_count`, `spell_heal_total` and
`spell_effective_heal_total` of each judged spell from the caster (start reads), makes the real `casts` in order and
reads them again (end reads); a check judges the increments, so heals outside the window never count. A cast is
`{spell, target, watch_ms, poll_ms (250), refill_power, end_ms}`: the base mana (or the flat cost) is set, the
cooldown reset and the cast made at `target` (an ally id or `caster`), then `watch_ms` passes in `poll_ms` waits, each
followed by a `set_power` to `refill_power` when given (a precondition fixture for a channel whose drain is not the
claim), and `end_ms` is waited after the end reads (a channel left to run out before the next phase). A cast whose
spell has a `CasterAuraSpell` gets that aura on the caster by `set_aura` right before it (`required_aura_steps`, as in
`metric_delta`), a precondition fixture so the cast is not refused for its caster aura; the scenario contract names
each such aura, and an entry states it with its cost reason in `observe_source` (guide 3.4). An entry whose claim is
that caster aura cannot use this kind. `learn` lists
spells learned once before the phases (the cast spells are learned too). With `gate_spell` a control phase runs first
and the gate is learned before the treatment phase; without it there is one treatment phase.

`checks` (each its own label `<spell> behaviour_metric_delta <name>`, an optional `quote` of the same tooltip):

- `reach`: in the treatment window every `healed` ally takes at least one heal of `spell` and every `unhealed` ally
  none; with a gate, no ally takes one in the control window. `reference` must take at least `minimum` heals of
  `witness_spell` (else `spell`), or the verdict is unmeasured (the cast did not run). With `witness_spell` each
  `unhealed` ally must take one, so its 0 is a selection and not a placement fault. Without `witness_spell` an
  `unhealed` ally's 0 is not told apart from a line of sight, spawn or relocation fault that keeps it out of every
  search: the check then shows only that the healed allies were reached and the unhealed ones were not. It can still
  alert (a heal that reaches too far), but its pass on the unhealed side is weaker; place an unwitnessed ally on the
  line of a healed one, just past it (as a radius bracket does), state the limit in `observe_source`, and use a
  witness whenever some heal of the same cast reaches that ally. The verdict names unwitnessed unhealed allies.
- `offsets`: each ally's treatment count of `spell` equals the `reference` count plus its stated offset; the
  reference needs `minimum` (2 or more) heals.
- `per_source`: the treatment heals of `spell` over all allies equal `per_event` times the heals of `source`; a
  `source` overheal is unmeasured (an overheal leaves nothing to share); with a gate, the control window reads 0.
- `share`: the mean heal of `spell` against `expected` times the mean effective heal of `source`, inside the stated
  `band` (`[low, high]` added to that centre) with its `band_reason` (rounding only); the control window reads 0.
  Fewer than `minimum` heals of `spell` (or of `source`) is unmeasured, so a server without the behaviour fails the
  `reach` or `per_source` check of the same entry, not `share`; pair `share` with one of them.

Counts are compared exactly; `reach`, `offsets` and `per_source` read the metric `spell_heal_count`, `share`
`spell_heal_total` (both event class). A gate is required for `per_source` and `share`.

Witch Doctor: Mojo Beam 501117 branches (`branch_grow`, `branch_heals`, clauses 40 and 41), Mojo Wave 707617
(`wave_lowest`, `wave_cap`, `wave_share`, clause 281) and Unstable Concoction 802487 (`unstable_radius`, a 20 yd
bracket of grouped allies around the marked caster, clause 331).

## Ally effects (ADR 1100, provisional)

Opt-in fields for claims that are not heals:

- Fixtures: `auras` on an ally and `caster_auras` on the entry (`[spell, stacks]`, set with `set_aura` at each phase
  start), `caster_health` (`[health, maximum]`, regeneration off) and `gate_settle_ms` (a wait after the gate learn,
  for a talent whose replacement syncs on a timer).
- Cast fields: `power_reads` (the caster's power right before the cast and at the end of its watch), `gap_ms` (a wait
  after the cast) and `probes` (ms after the cast, whole polls of the watch: every fixture aura is set again with a
  refusable `set_aura`, which leaves an immune unit without it, and the judged auras are read).
- `count`: the `reference` ally's heals of `spell` in the treatment window equal `expected` (a whole number); with a
  gate the control window reads 0.
- `aura_reach`: at the end of each phase the `reference` unit (an ally or `caster`) has lost `aura` (else unmeasured:
  the cast did not run), each `removed` unit lost it in the treatment only, each `kept` unit keeps it.
- `immune_window`: the `immune` units refuse `aura` at the `early_ms` probe and take it at `late_ms` in the treatment,
  and take it at `early_ms` in the control.
- `drain`: the power spent over the watch of `high_cast` exceeds that of `low_cast` (cast indexes with `power_reads`);
  a `low_cast` that spent nothing is unmeasured. Evidence metric `power`, contrast `own_cast`. With `relation`
  `equal` (ADR 1181) the two casts must spend the same power within `tolerance`, for a drain that does not depend on
  what tells the casts apart.
- `health_share`: the `levelled` units (allies with a health fixture, or `caster` with `caster_health`) end the window
  within `tolerance` health points of each other from a start spread of at least ten tolerances (else unmeasured), and
  the `apart` units move by no more than the tolerance.
- `reach` takes `control_allowed`: allies whose control heals are allowed (a gated claim about the allies beyond a
  target the control heals too).

Witch Doctor: Disciple of Sseratus 300660 `hex_jump`, For Da Loa! 705906 `mass_reach` and `mass_immune`, Spirit Link
Idol 706369 `link_share`, Mojo Beam 501117 `beam_lasts` and `beam_drain`, Spirit Out Of The Bottle 301175
`bottle_allies`.
