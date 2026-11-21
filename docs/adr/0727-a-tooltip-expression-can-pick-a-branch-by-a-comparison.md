# 0727. A tooltip expression can pick a branch by a comparison

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Ascension tooltips state a spell power term that follows the higher of two schools:
`${$cond($gt($sps, $sph), $m3+0+$sps*.175, $m3+0+$sph*.175)}` (Witch Hunter 501349 Tormentor, 805751's
`$805753m1` Twilight shots, claim 379.0). The expression reader had no functions and no `,` token, so these values
stayed unreadable and their labels had no expected value. Mentor decision D-185 (c13 tool batch item 6, design G2b in
the c12 gap designs), with a stop if a finished class's digests move.

## Options

- `$cond(a, b, c)` and `$gt(a, b)` inside `${...}`: arguments are full expressions separated by `,`; `$gt` is 1 when
  `a > b`, else 0; `$cond` is `b` when `a` is not 0, else `c`. Both branches are parsed, so the first effect token
  still names the value's effect.
- A general function table (`$max`, `$min`, `$lt`, ...): none of them appears in a tooltip the classes read.

## Decision

The two functions, with their exact argument counts; any other count is unreadable, as is a function name outside a
call.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: both branches are picked by the comparison at the fixture caster, and wrong argument counts stay
  unreadable.
- Witch Hunter: the Tormentor ranks 501344-501355 and 800162 read their `$m3` value (`effect_value e2 #0`), which
  renumbers their duration and periodic labels; 805751 reads `805751 effect_value 805753e0 #2` in place of the
  unreadable `805751 effect_value #2`. The ledger rows of 501349 and 805751 take the new labels. A value with
  spell power and attack power terms proves its base points only (D-57); the terms need a hit label.
