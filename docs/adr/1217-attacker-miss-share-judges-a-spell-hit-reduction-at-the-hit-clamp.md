# 1217. Attacker miss share judges a spell hit reduction at the hit clamp

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Sun Shield 300348 (ledger row 33): "Reduces your chance to be hit by spells by $s1%" (Effect[0] aura 186,
BasePoints -4 + DieSides 1 = 3 points, every magic school). The `attacker_miss_share` kind compares melee miss
shares statistically; a 3-point spell hit change judged that way needs thousands of casts per arm. Mentor ruling
D-216.

## Options

- Statistical miss shares of creature spell casts (about 3,700 casts per arm for the band).
- Deterministic edges at the hit clamp: `HitChance` is clamped to 100% (`Unit::MagicSpellHitResult`), so an attacker
  whose hit chance sits exactly on the clamp never misses and one a point under it misses 1% of its casts. The
  creature fixture `spell_hit_bonus` moves the attacker's chance by whole points.

## Decision

The second option as an opt-in `variant: "spell_clamp"` of the kind: two control attackers (spell not learned) at
bonus 4 (clamp) and 3 (edge) fix the same-level base at 96%; two treatment attackers (learned) at 4 + E and 3 + E fix
the reduction at exactly E points, since the aura amounts are whole points. Each attacker casts N = 826 times, the
smallest count for which the four edge readings of a pair miss no cast on a correct server with probability at most
0.1%. Misses are SPELL_GO counts less damage logs. A calibration read (throwaway probe, never counted) confirmed that
a creature's triggered cast rolls hit.

## Consequences

- Absent by default: the variant is chosen by `variant`; no finished-class entry writes it, so the finished classes
  regenerate byte-identical, and the existing variants' scenarios and models are unchanged.
- Seeded tests (`kinds/test_attacker_miss_share.py`): placement, counts and order; refusals; a 3-point reduction
  passes, the 2-point mutant (a missless edge) and the 4-point mutant (a clamp miss) alert; off-base controls, short
  arms and aura reads off are unmeasured; the verdict is behaviour evidence.
- The base 96% is a code constant of `MagicSpellHitResult` checked by the control arms at run time; a server whose
  base differs gives unmeasured verdicts, never a pass.
