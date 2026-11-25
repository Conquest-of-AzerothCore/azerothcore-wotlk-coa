# 1211. A class file can correct a missing operator in a tooltip, under a ruling

- Status: proposed (provisional number, numbered at merge; for the owner's G-39 list)
- Date: 2026-11-22

## Context

Sun Cleric Protector of the Flame 560492: the Description reads
`${$560493m1*$<scalingbp>$spfi*0.12+$AP*0.03}`, with no operator before `$spfi`, so the tooltip reader leaves the token
unreadable and no expected amount comes from data. Mentor ruling D-166: the token is read as `+$spfi*0.12` (every
sibling formula of the class adds its spell power term; the coefficients 0.12 and 0.03 match
`AscensionSunClericData.h:82`); a ledger text_correction, no client text change.

## Options

- A client text row (`coa_client_spell_description`): changes what players see, needs an owner go.
- A per-entry formula: would let an entry write any expectation.
- A class-file correction limited to inserted `+` operators, under a recorded ruling.

## Decision

`tooltip_corrections` in the class file: `{"<spell>": {"text": ..., "ruling": ...}}`, read by `script_hit_model` in place
of the DBC Description (`tooltip_corrections.py`). Refused unless the ruling is a non-empty text and the corrected text
is the DBC Description with only `+` characters inserted.

The one correction recorded (Sun Cleric, D-166):

- spell 560492, DBC: `Avoiding an attack now also deals ${$560493m1*$<scalingbp>$spfi*0.12+$AP*0.03} Fire damage to the
  attacker.\r\n\r\nCan only occur once per sec.`
- read as: `Avoiding an attack now also deals ${$560493m1*$<scalingbp>+$spfi*0.12+$AP*0.03} Fire damage to the
  attacker.\r\n\r\nCan only occur once per sec.`

## Consequences

- No finished class file carries the key (a test checks classes 15, 19 and 23); their generation is byte-identical.
- The client tooltip still lacks the operator: a cosmetic typo for the owner.
- Seeded tests: the correction yields a readable amount, the bare class file stays unreadable, a changed figure or a
  missing ruling is refused.

## Addendum 2026-11-22: the script hit striker is engaged (round B design 2)

The first run of the 560492 entries read no 560493 hit in either arm: with `caster_avoidance`, `script_hit` set the avoidance but nothing engaged its hostile striker, so it never swung (no entry had used the option before). The caster now engages it once (`set_combat_avoidance`, `attack`, 2800 ms, `stop_attack`, the `proc_avoided` engage) before the control trials, and an assert at the end requires 0 own melee swings since the engage, so the caster's auto attack cannot be a trigger source. Only entries with `caster_avoidance` change; no finished class has one.
