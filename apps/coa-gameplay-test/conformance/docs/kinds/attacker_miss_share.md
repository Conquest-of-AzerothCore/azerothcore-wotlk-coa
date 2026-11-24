# Attacker miss share (`behaviour_metric_delta`, `kind: "attacker_miss_share"`, ADR 1189)

A debuff that lowers an enemy's chance to hit ("reduces the target's chance to hit by 3%") is read on the swings the
enemies aim at the caster, never on the aura's amount or the unit's hit modifier. `attackers` (1 to 8, default 8)
aggressive, stationary attackers of `attacker_entry` (default the dummy entry, at the class level, 1M health, 3 yd)
melee the caster after one engaging swing each. Two arms of `arm_ms`, in whole cycles of `cycle_ms`, count
`melee_attacks_taken` (every swing) and `melee_attacks_taken` with `victim_state` 0 (a miss, `VICTIMSTATE_INTACT`):

- **control** first: no cast; the caster's health is set every cycle and `aura` is read on every attacker at each
  cycle end, where it must be absent;
- **treatment**: every cycle the caster's power is set (`base_mana` for a cost in percent of base mana), the cooldown
  of `cast_spell` is reset (a named precondition fixture, G-21 point 6, stated in the verdict) and `cast_spell` is
  cast at the first attacker. Counting starts `settle_ms` after the first cast, once `aura` from the caster is read on
  every attacker; the aura is read on every attacker again at each cycle end, where it must be held.
  `pre_cast` (ADR 1202, opt-in) lists spells cast at the first attacker before `cast_spell` in every treatment cycle,
  each with its power set, its cooldown reset (the same named fixture) and its cast time waited out; `settle_ms` and
  `cycle_ms` must cover the whole sequence.
  `relocate_dx` (ADR 1234, opt-in, a nonzero number of yards under the attackers' 3 yd) moves the caster once along x
  after the engage wait, before the first control read, so both arms are counted from the same position; the player
  cast needs the first attacker inside the 180 degree front arc (the caster faces +x) and the attackers settle on a
  3 yd circle around the caster, so a small step back keeps all of them in front while they still swing.

The aura is never set by the harness. Expected: the miss share rises by minus the amount of `aura` effect
`aura_effect`, which must be `SPELL_AURA_MOD_HIT_CHANCE` (54); `expected` must equal it. The judge sums swings and
misses per arm over every part and takes the difference of the shares in points against `expected`, with the
taken-outcome 99% normal interval and `bonus_status`: the band is the larger of 5% and 2 points, and a verdict needs
a half-width of at most half the band. Unmeasured: a missing part, fewer than 100 swings in an arm, a treatment aura
read 0 or a control aura read 1 on any attacker (the failing part is named), or a control share within `expected`
points of the 0 to 60% miss clamp (`Unit::MeleeSpellMissChance`).

`quote_spell` names the spell whose tooltip holds `quote` when the claim's tooltip embeds it (`@s:<id>:N@`); an
entry whose tooltip does not embed it is refused.

Refused: more than 8 attackers, arms that are not whole positive cycles, a cycle at or above the aura's duration, a
settle shorter than the cast, an aura effect that is not aura 54 or a stated value that differs from the DBC, a
percent-of-base-mana cost without `base_mana`, more than 10000 steps, or a wait over the accelerated cap.

The verdict stamps the metric `melee_attacks_taken`, already an event read in `coverage.METRIC_EVIDENCE`.

Sun Cleric: Sun Down 572752 (Solar Flare 807175 from the 572754 ground, claim "reduces the target's chance to hit by
$s1%"), label `572752 behaviour_metric_delta attacker_miss`.

## Spell clamp variant (`variant: "spell_clamp"`, ADR 1217, provisional)

For an aura 186 (`SPELL_AURA_MOD_ATTACKER_SPELL_HIT_CHANCE`) on the caster: fields `spell` (the aura's spell, also
the quoted tooltip), `quote`, `attacker_spell` (a magic damage spell of a school in the aura's MiscValue mask),
`expected` (whole points, equal to minus BasePoints plus DieSides), optional `aura_effect` (0), `attacker_entry`
and `label_suffix` (`spell_hit_taken`). Four stationary hostile attackers at the class level (base spell hit 96%,
`Unit::MagicSpellHitResult`) each cast `attacker_spell` at the caster N times, 300 ms apart (the harness creature
`cast`); their fixture `spell_hit_bonus` places the hit chance on the 100% clamp or one point under it: control
(the spell not learned) 4 and 3, treatment (learned, its aura read on the caster) 4 + expected and 3 + expected.
Misses are `spell_go_count` less `spell_log_count`. N is the smallest count with four edge arms missless on a
correct server at most 0.1% per pair (826), or the optional `casts` (ADR 1271, provisional): a whole count of at
least 826 for every arm, when the edge miss share read in a pair leaves more than 0.1% at the default. A control arm off its expectation, an arm short of N casts or an aura
read off is unmeasured; a treatment clamp miss or a missless treatment edge alerts (the reduction is more or less
than stated). The verdict stamps `spell_log_count`, an event read.

Calibration read rb7 (2026-11-22, a throwaway probe, never counted): a level 50 attacker's triggered Smite 585 missed
6 of 30 casts at the level 60 caster, so the creature cast rolls hit; a level 64 attacker missed none of 100.

Sun Cleric: Sun Shield 300348 "Reduces your chance to be hit by spells by $s1%" (3), label
`300348 behaviour_metric_delta spell_hit_taken`.

Felsworn: Armaments of the Legion 706266 and 707844 "Reduces your chance to be hit by spells by $s1%" (2 and 4),
`casts` 1100, labels `706266 behaviour_metric_delta spell_hit_taken` and `707844 behaviour_metric_delta
spell_hit_taken`.
