# Heal sum (`behaviour_metric_delta`, `kind: "heal_sum"`, ADR 1118, provisional)

One heal is read on every unit it may reach: the caster, up to 7 ally players (`allies`, the `ally_heal_reach`
format: `{id, dx, dy, grouped, health, maximum}`) and up to 8 fixture creatures (`creatures`: `{id, entry, distance,
faction}`, standing `distance` yd along x from the caster, faction 35 by default, level 60). A creature counts for a
heal that needs no group (`TARGET_CHECK_ALLY`) only when the caster may assist it: `Unit::_IsValidAssistTarget` lets a
player assist a creature that is not flagged for PvP only when its template carries `CREATURE_TYPE_FLAG_CAN_ASSIST`
or `CREATURE_TYPE_FLAG_TREAT_AS_RAID_UNIT`, so the entry names such an entry (631, type_flags 0x1000). It is how a
target cap above the 8 players a scenario holds is reached.

Each phase reads, on every unit, the caster's `spell_heal_count`, `spell_heal_total` and `spell_effective_heal_total`
of each judged spell (start reads), makes the real `casts` in order (the `ally_heal_reach` cast: base mana, cooldown
reset, the `CasterAuraSpell` set as a precondition fixture, the cast at the caster or an ally, `watch_ms` in `poll_ms`
waits) and reads them again (end reads); the checks judge the window's increments. `learn` lists spells learned once;
with `gate_spell` a control phase runs first and the gate is learned before the treatment phase.

`checks` (each its own label `<spell> behaviour_metric_delta <name>`, an optional `quote` of the same tooltip):

- `cap`: the treatment heals of `spell` summed over all units equal `expected` (whole, compared exactly); with a gate
  the control sum equals `control_expected`. `witness` names the phase (`control`, or `treatment`) in which every
  unit must take at least one heal of `spell`, so each was a candidate: a unit no heal reached makes the verdict
  `unmeasured`, never `ok`, because a missing candidate would hide an uncapped selection. A random selection of n of
  m candidates over k casts leaves a given unit out with probability ((m - n) / m)^k; state that bound when the
  witness is the treatment window.
- `pair`: the treatment total of `spell` on unit `on` against `expected` times the effective healing of `source` on
  unit `source_on` in the same window, inside the stated `band` (`[low, high]` added to that centre) with its
  `band_reason` (rounding only); with a gate the control total of `spell` on `on` is 0. No `source` heal, or an
  overheal of it, is `unmeasured` (the healing done is then not the heal amount).

Witch Doctor: Jungle Booms 705859 `booms_targets` (the Jungle Shrooms pulse on the caster and seven grouped allies: 8
without the talent, 5 with it), Splash Potion 567736 `splash_cap` (six splashes over the caster and eight creatures
631: 48 heals, every unit healed) and Loa's Brew 501205 `echo_half` (the echo on the previous target after a Brew at
a new one: half of that Brew's effective heal).
