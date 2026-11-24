# 1269. A power term direction can vary Agility or maximum health and sample a barrier's absorbed strike

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-24
- Supplements [ADR 1192](1192-rate-judges-take-a-residual-heal-trials-and-a-power-term-direction.md)

## Context

Three Felsworn clauses state a term with no figure (class-end triage group B-PTD, mentor D-90 and D-94):

- Felcaked Blades 574145: "Twin Slice and Sargeron Smite now additionally scale with your Agility." The server adds
  Agility x 0.15 to effect 0 of Sargeron Smite 802060 and of the Twin Slice strikes (`AscensionFelswornContracts.cpp`,
  `ModifySpellEffectBaseValue`).
- Felblade 574146: "Damage dealt by Fel Fireball, Sargeron Smite, and Twin Slice now additionally scales with your
  Agility." Agility x 0.20 on the same effect of Fel Fireball 801312, Sargeron Smite and Twin Slice.
- Pure Hatred 803478: "Your Hateforged Barrier now also scales with your maximum health." 10% of the maximum health is
  added to effect 0 (`SPELL_AURA_SCHOOL_ABSORB`) of the Hateforged Barrier chain.

`power_term_direction` (ADR 1192) judges such a direction, but only for attack power (an aura 99 fixture and an
`attack_power` read), only for damage on the dummy from the cast spell itself, and only for spells that cost a
percentage of base mana. Twin Slice 801901 deals its damage through 808303 and 808304 and, like Fel Fireball, costs
a flat amount of power type 3. A Felsworn's melee attack power is `2 x level + Strength + Agility - 20` (the class
file's reference stats, 312 = 120 + 82 + 130 - 20), and Sargeron Smite carries an attack power coefficient
(`AscensionFelswornData.h`), so an Agility aura alone also raises the damage without the passive and the control
check alerts.

## Options

- A new kind per stat and per sample source.
- Opt-in fields on `power_term_direction`, with the statistics, quantiles, control check and closing keys unchanged.

For the barrier sample (controller decision after mentor D-94):

- (a) the aura's `aura_amount` after each cast: a readback, classed data in `coverage.METRIC_EVIDENCE`, so the claim
  stays uncounted;
- (b) an event `evidence_metric` for that readback: an evidence-class change;
- (c) the absorbed amount (`spell_absorb_total`, an event read) of one strike larger than the barrier after each cast.

## Decision

The second option, with (c) for the barrier. Every field is optional; without them the model, contract, steps and
verdict text stay byte-identical (the finished-class scenarios regenerate unchanged).

- `power_metric`: `agility` (the power aura must carry `SPELL_AURA_MOD_STAT` of Agility; read `stat` 1) or
  `max_health` (aura 34 or 133; read `max_health`). Such an arm reads the stat and the attack power before and after
  the arm; the verdict is `unmeasured` unless the high arms read higher than the low arms both before and after, each
  arm's stat reads the same before and after, and the attack power reads the same in all eight reads (the fixtures'
  effect is measured, mentor D-94 condition 4: a moved fixture voids the run, never alerts). The verdict and contract
  name the stat.
- `power_stacks` and `power_companions` (`[{"spell", "stacks", "source"}]`): the power aura's stacks, and auras set
  with it in the high arms and removed with it. They hold another input equal, here the attack power that Agility
  gives (QA Test +100 Agility 300111 x3, Raid Debuff 3 (70) 530003 -312 attack power, Attack Power 12 9141 +12).
- `hit_spell`: the spell whose non-critical damage on the dummy is read (default the cast spell).
- `cast_power`: a `set_power` of the cast spell's power type before each cast, refused below its flat cost.
- `sample: "absorb"` with `strike_spell` and `refill_spell`: the cast spell's effect 0 must be
  `SPELL_AURA_SCHOOL_ABSORB`. Before each cast the previous barrier is cleared (`set_aura` 0) and the refill spell
  restores the caster's health; after the cast its presence is read, a passive striker (creature entry 36, as in
  `taken_total_ratio`) strikes the caster once, the presence is read again, and the strike's `spell_absorb_total` and
  `spell_log_count` are read. A sample is the absorbed amount of a strike that met a barrier present after the cast,
  gone after the strike, with one strike logged; a refused cast or an unbroken barrier is no sample. The model metric
  is `spell_absorb_total`. The sample proves the direction of the term only; that the barrier absorbs damage is
  proven elsewhere (mentor D-94 condition 3).

## Consequences

- Felsworn entries: 574145 on Sargeron Smite and Twin Slice (808303), 574146 on Fel Fireball, Sargeron Smite and Twin
  Slice, 30 casts per arm; 803478 on Hateforged Barrier 707527 with Infernal Constitution 805256 (+10% maximum health),
  Ray of Pain 54416 (2000 Shadow) and Full Heal 17683, 40 casts per arm. The entry states the margin of the strike
  over the largest learned barrier.
- The kind's tests seed each option, with mutants (no term, a fixture whose stat falls back, unbroken and refused
  barriers) that must alert or void.
- Residual risk: the strike margin rests on an upper bound of the maximum health; a stronger caster can make the
  barrier outlast the strike, which voids samples (`insufficient_trials`), never passes them.
