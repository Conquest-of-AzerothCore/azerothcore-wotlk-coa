# 0024. A Thousand Cuts rolls once per Azzinoth's Assault

- Status: accepted (owner ruling Felsworn O-31 (2026-11-24, Felsworn ADR 0024))
- Date: 2026-11-24

## Context

A Thousand Cuts 704610 (server Spell.dbc, Description[enUS]): "Azzinoth's Assault now has a $h% chance to hit an
additional time with your main-hand Weapon." ($h = ProcChance 30). Azzinoth's Assault 801904 and its ranks deal no
damage of their own: Effect[0] and Effect[1] trigger the main-hand strike 520262 and the off-hand strike 572585.

The event handler's Check case 704610 rolled `Chance(player, 704610)` on every landed damage event of 520262 or
572585, so each Assault rolled twice. The extra 520262 it casts does not roll (the `State(player).event` guard). The
counted pair prove-final read 0.2297 and 0.2317 extra hits per landed strike, 0.3 / 1.3: about 0.60 extra hits per
Assault against the tooltip's 0.30 (owner question N-4).

## Options

- (a) One 30% roll per Assault (the tooltip).
- (b) Keep 30% per strike and correct the displayed text.

## Decision

Owner ruling Felsworn O-31 (2026-11-24): (a). `OnSpellBeforeEffects` of the Felsworn spell script sets `State(player).assaultRoll` for each
cast of a rank of 801904, before its launch phase triggers the strikes. Check case 704610 takes the flag
(`std::exchange`) on the first landed damage event of 520262 or 572585 and only then rolls the chance, so the second
strike of the same Assault cannot roll. No other file, SQL, DBC or client text changes.

## Consequences

- One roll per Assault that lands at least one strike; the extra hit stays a main-hand 520262.
- Regression: the Felsworn proc entry 704610 now counts one trial per completed Assault cast (`trial_casts`) with the
  extra 520262 hits beyond those casts as events, against 0.30; its baseline arm (before the talent is learned) reads
  no extra hit.
- Readers: 704610 and the flag are used only by the Felsworn event handler; 520262 and 572585 are Felsworn spells.
  No other class lists them.
