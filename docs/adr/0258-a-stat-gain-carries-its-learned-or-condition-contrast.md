# 0258. A stat gain carries its learned or condition contrast

- Status: accepted, with the mentor's conditions of 2026-11-12
- Date: 2026-11-12
- Amends: ADR 0120 (when a state read counts as behaviour) for `stat_gain`

## Context

ADR 0213 judges a `stat_gain` entry under the `behaviour_metric_delta` check name. Clause coverage counts a state read
(`armor`, `spell_power`, `attack_power`) of that check as behaviour only when the verdict detail carries the `learned`
contrast and the clause names the stat (ADR 0120, `coverage.promised_state`). The `metric_delta` model stamps that
contrast; the `stat_gain` model did not. So the counted pairs of Improved Benediction 705287 (claim 196, the grouped
ally's armor gains 0 without the talent and Agility + Stamina with it) and Libram of Fervor 805423 (claims 411 and 412,
Holy spell power and attack power read before and after a real cast with the Libram aura cleared first) stayed data.

## Options

1. Keep the claims at data. That ignores the arms that the entries already contain.
2. Stamp `learned` on every `stat_gain`. That would also count an entry whose arms all know the spell, where the
   gain shows the cast but not the claimed spell.
3. Stamp the contrast that the arms make, from the generator's model.
4. Stamp it in the judge, and only when run-time reads attribute the gain to the claimed aura.

## Decision

Option 4. The first version of this ADR took option 3; the mentor accepted the contrast only with attribution
conditions.

The generator gives an entry an `attribution` model in two cases, and no attribution otherwise:
- **Own cast.** The cast spell is the entry's spell and its aura is in `clear_auras`. This is Libram of Fervor.
- **Withheld talent.** The first arm lacks the entry's spell, states its control `gain`, and a later arm learns the
  spell. This is Improved Benediction: arm `without` (gain 0), then `with` 705287. Its attributed aura is 801409, the
  armor aura that Benediction triggers.

The entry's metric also needs a named read (`STAT_GAIN_READS`, rule 4 amendment point 2, 2026-11-12):
- `armor` is `Unit::GetArmor`, the client field `UNIT_FIELD_RESISTANCES` + 0;
- `attack_power` is `GetTotalAttackPowerValue(BASE_ATTACK)`, from the client fields `UNIT_FIELD_ATTACK_POWER`, its
  mods and its multiplier;
- `spell_power` is `SpellBaseDamageBonusDone`, the function the engine calls at use time.
  `UpdateSpellDamageAndHealingBonus` copies that function into `PLAYER_FIELD_MOD_DAMAGE_DONE_POS`.

The listed auras are the `clear_auras` plus the auras the cast applies according to the DBC: the cast spell itself
when an effect applies an aura, and each spell triggered by effect 64 or 142 that applies one.

Each arm with attribution adds these reads on the cast target:
- before the cast, every listed aura and `applied_aura_count`, after the clear step: a read, not only a request;
- after the cast, the same auras and count;
- before and after the cast, the caster's `spell_cast_count` of the cast spell. The harness counts a cast in the
  server's `OnSpellCast` hook, which runs only for a cast that passed its checks. This is the cast-landed read;
- then the `clear_auras` are removed and the stat is read again (`return`).

The judge stamps `contrast: learned` only when the gain checks hold and, in every arm, all of the following hold:
- the cast landed: the cast count rose. In the withheld control arm, this read is what tells "no aura without the
  talent" apart from a refused cast (re-review I1, 2026-11-12);
- each attributed aura reads absent before the cast. It reads present after the cast in every arm except the
  withheld one, which is the control: without 705287, Benediction leaves no 801409 at all;
- the aura count rises by exactly the number of listed auras that appeared, so no unlisted aura appeared;
- any other aura the cast applied comes with an arm without the spell, and that aura also appears in the arm without
  the spell. This is stricter than the ruling, which asks for that arm only when the other aura touches the same
  stat;
- the return read equals the reading before the cast.

Every other case gets `contrast: condition`. The verdict detail lists the auras each arm's cast applied
(`applied_auras`) and the read used (`read`, also in the explanation). The model carries no `contrast`, so
`compare.observed` stamps none.

**Amendment of ADR 0120.** ADR 0120 counts a state read as behaviour in a learned/unlearned contrast of
`passive_delta`, `behaviour_party_stat_ratio`, or `behaviour_metric_delta` outside its `setup_only_after` mode. For a
`stat_gain` `behaviour_metric_delta`, that contrast is now the judge's `learned` stamp, under the attribution above.
The own-cast case counts as a contrast: the reading before a real cast of the claimed spell, with its aura read
absent, is the unlearned side. Without attribution, a stat gain stays data. The rest of ADR 0120 is unchanged.

The harness gains `applied_aura_count`: the number of aura applications a unit holds. It is a read only.

## Consequences

- 705287 `armor` uses the withheld-talent contrast. 805423 `spell_power` and `attack_power` use the own-cast
  contrast. The three are the only `stat_gain` entries, so no other claim moves from data to behaviour through this
  ADR.
- The three stat-gain scenario files change, with the new reads. The other 1835 scenario files regenerate
  byte-identical.
- Seeded tests:
  - Both entries count as behaviour, and their applied auras are listed.
  - Thirteen mutants stay data:
    - arms that all learn 705287;
    - a withheld arm with no stated control gain;
    - a cast other than the entry's spell, with that spell's aura in `clear_auras`;
    - a Libram entry without `clear_auras`;
    - a metric with no named read;
    - the aura not cleared but refreshed, with the aura count unchanged;
    - the aura absent after the cast (Libram, and Benediction's `with` arm), count unchanged;
    - an unlisted aura that appears;
    - a stat that does not return;
    - a cast that did not land, in a treated arm and in the control arm;
    - another aura that the control arm does not show.
  - Each attribution mutant holds the other checks equal, so only its own guard catches it (re-review M1).
  - A coverage-class extension cannot fail with an alert: these mutants keep their ok status. Their signal is the
    evidence class, data instead of behaviour. That is how this ADR meets the goal's "a mutant that must alert".
  - Benediction's `without` arm stays behaviour with no aura after the cast.
  - A second applied aura keeps the Libram at data (no arm without it) and keeps Benediction behaviour (its
    `without` arm).
- Verdicts judged before this ADR carry no contrast or attribution, so the three scenarios were run again. Naming
  the read changed only the model: the pair 20261112-045107 / -045344 was judged again, with the same scenario
  files. The cast-landed read then changed those three files, and the counted pair is 20261112-051639 / -052004.
