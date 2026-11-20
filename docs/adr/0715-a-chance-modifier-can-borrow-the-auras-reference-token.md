# 0715. A chance modifier can borrow the aura's reference token

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Flames of the Sinned 560207 (Witch Hunter): "While you have Flames of Sin active, the chance to trigger this effect is
increased by $803422s3%". Flames of Sin 803422 Effect[2] is a flat SPELLMOD_CHANCE_OF_SUCCESS (aura 107, MiscValue 18,
$s3 = 10), but its Description is empty, so `chance_modifiers` (ADR 0586), which reads the token from the modifier's own
tooltip, refused the entry (c11-inq stop on claim 97.0). Mentor decision D-160 (c12 tool batch item 5).

## Options

- Fall back to the aura's own tooltip for a reference token `$<modifier>s<n>` when the modifier shows none.
- A stated number in the class file: a value not read from the DBC.

## Decision

`procs.modifier_shown`: the modifier's own token first; otherwise a reference token naming the modifier, read from the
aura's tooltip, with effect `<n> - 1` of the modifier and the same flat-modifier check. The model gains
`chance_modifier_tooltips` (modifier to aura) only when a token is borrowed, and `compare.stated_chance` reads the
borrowed token from that tooltip.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (Refreshing Chill 300940 with Frigid Winds 504357 keeps its
  own token; no model key is added).
- Seeded tests: a reference to another spell or effect is refused; a changed borrowed token alerts in compare.
- Witch Hunter: `560207 proc_rate with 803422` (35%, Flames of Sin set before every Smite Evil cast).
