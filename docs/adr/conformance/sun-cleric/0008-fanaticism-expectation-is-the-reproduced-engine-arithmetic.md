# 0008. Fanaticism expectation is the reproduced engine arithmetic

- Status: accepted
- Date: 2026-11-22
- Supersedes: the expected figures and the Horusath Blast sentence of [0007](0007-fanaticism-compounds-on-the-gavel-flat-damage.md).
  Its decision (a), accept the stock engine order, stands.

## Context

ADR 0007 stated Gavel of Wrath +27.77%, Gavel of Grace +24.54%, Gavel of Light +22.46% and Horusath Blast exactly
+20%. The counted pair 20261122-013639 / -013852 read all four below those values, in both runs, and three of the
eight 99% intervals excluded them. The review asked for the cause before a band-based acceptance (guide section 5:
an accepted engine behaviour counts only when the engine computation reproduces the read).

Two terms were missing from 0007:

- The Gavel mean hit was taken from a measured control mean divided by (1 - r), which has no integer truncation and
  no data-only source for W.
- Horusath Blast was assumed to be a plain +20% with no flat term. It is a Holy `SCHOOL_DAMAGE` spell: its value is
  truncated to int32 after the +20%, and the dummy resists Holy through the monster linear resistance.

## Decision

The expectation is the engine arithmetic enumerated over every random roll, with float32 where the code uses float.
Every input is data or a read of a stat, never a measured bonus.

Gavels (Physical, `Spell::EffectWeaponDmg`, `SpellEffects.cpp:4668-4756`):

- Weapon roll: `urand(uint32(min), uint32(max))` (`Unit.cpp:3621`), with min and max = weapon damage + attack power / 14
  x the attack power multiplier (`StatSystem.cpp:728, :767`). Item 2529 is two-handed, so the multiplier is 3.3
  (`Unit.cpp:15156-15157`); attack power is 70 (the scenario's `attack_power` step). Rolls are 90..119.
- Flat value F: `BasePoints + irand(1, DieSides)` (`SpellInfo.cpp:511`), per-level term truncated
  (`SpellInfo.cpp:497`, 0 for Gavel of Light), then with the passive `float(value) x 1.2f`
  (`SpellInfo.cpp:531`, `Player.cpp:10622, :10677`) and `int32` (`SpellInfo.cpp:592`).
- Weapon percent: 100 becomes `int32(100 x 1.2f)` = 120 the same way; the loop adds F to the roll before it applies the
  percent, in DBC order (Effect 0 flat, Effect 1 percent; `SpellEffects.cpp:4731-4743`), with `ApplyPct` truncating to
  int (`Util.h:52-66`).
- Armor 528 (the `dummy_armor` entry), `tmp = x / (1 + x)` with x = 528 / (85 x 60 + 400), and the hit is
  `uint32(ceil(damage x (1 - tmp)))` (`Unit.cpp:2550-2560`).

Horusath Blast (Holy, `SCHOOL_DAMAGE`):

- Value: 72 + `int32(5 x 1.06)` (level capped at MaxLevel 15, minus 10; `SpellInfo.cpp:490-497`) + `irand(1, 12)`; with the passive
  `int32(float(value) x 1.2f)`.
- No spell power term (the reference character has none) and no attack power coefficient aura.
- Monster linear resistance (`CoA.MonsterResistance.Enable 1`, `PerLevel 1.0`, `PerPercent 5.0`;
  `src/server/coa/conf/coa.conf.dist:146-149`): 60 x 1.0 / 5.0 / 100 = 12% average resist (`Unit.cpp:2563-2610`).
  Partial resist i/10 with probability `0.5 - 2.5 x |0.1 i - 0.12|` (`Unit.cpp:2671`: 20%, 45%, 30%, 5% for i = 0..3),
  resisted amount `damage x i / 10` in integer division (`Unit.cpp:2690`) subtracted (`Unit.cpp:2720`).

| Spell | Mean hit without | Mean hit with | Ratio | Expected bonus |
|---|---|---|---|---|
| Gavel of Wrath 800617 | 141.4576 | 179.8455 | 1.27137 | +27.14% |
| Gavel of Grace 800614 | 118.1583 | 146.3333 | 1.23845 | +23.85% |
| Gavel of Light 800611 | 106.7667 | 129.9000 | 1.21667 | +21.67% |
| Horusath Blast 500154 | 73.8708 | 88.1542 | 1.19336 | +19.34% |

Cross-check against the counted pair (not an input): control means 141.218 / 141.639, 118.391 / 118.369,
106.713 / 106.849 and 74.098 / 73.908; treatment means 179.744 / 179.069 (Wrath) and 88.034 / 88.274 (Horusath); the
eight bonus readings (+27.28 / +26.43, +23.69 / +23.89, +21.85 / +21.26, +18.81 / +19.44) all lie inside their own 99%
intervals around the values above. Pair f1 of ADR 0007 (+27.39 / +27.10, +23.76 / +23.84, +21.74 / +21.60, +19.33)
does too.

The claim is judged in the G-19 band (the larger of 5% of the bonus and 2 points). The band is not widened.

## Consequences

- The class file's four `effect_*` entries carry the ratios above; their `expected_source` states the arithmetic.
- The offset below +20% that ADR 0007 left unexplained is the int32 truncation of the 1.2 factor on integer values
  (each Gavel's flat value and the percent-scaled sum, Horusath's value), the Horusath resist, and the `ceil` of the
  armor reduction. A change of the reference weapon, attack power or the dummy armor moves the table; it is
  recomputed from the same terms.
- No server change, no client data change.
