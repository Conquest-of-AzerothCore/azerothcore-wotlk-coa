# 0023. A triggered strike takes its cast spell's weapon set

- Status: accepted
- Date: 2026-11-22

## Context

[ADR 0001](0001-reference-weapon-sets-per-specialization.md) maps every rank of the spells of tabs 70, 71, 72 and 90
to a weapon set. Glorious Execution 803913 (tab 90, Valkyr) triggers its two strikes through effects 142
(`TRIGGER_SPELL_WITH_VALUE`): 800691 main hand and 802566 off hand. They are not tab spells, so `spell_weapon_sets` did
not map them. `hits.py` judges a hit spell with `armed(class_file, requirement, hit_spell)`, so the model took the
default Seraphim set while the scenario wore Valkyr, the set of the entry spell.

## Options

- Leave the strikes unmapped: the model and the worn weapon disagree (a 2027 one-hand against two 2529 two-handers).
- Map each triggered strike to the set of the spell that casts it.

## Decision

`spell_weapon_sets` maps 800691 and 802566 to Valkyr, the set of 803913. A triggered strike takes the set of its cast
spell, so the judged weapon is the one the scenario wears.

## Consequences

- The model and the worn weapon agree for the Glorious Execution `script_hit` entries.
- Other entries that observe 800691 (Divine Vision, Vindicator, Sunsworn, ...) generate the same scenarios as before:
  the full-class generation from c0716cc8aa and from 629898545e differs only by the eight new files.
- A further triggered strike of a tab spell is mapped the same way when an entry judges it.
