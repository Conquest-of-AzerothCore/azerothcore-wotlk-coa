# 0026. Dawnsear and Daybreak 503625 take their tooltip coefficients

- Status: accepted (owner ruling O-15, 2026-11-22, relayed by the mentor)
- Date: 2026-11-22

## Context

Server Spell.dbc Description[enUS]:

- Dawnsear, all eight ranks (500146, 502366 to 502371, 554406): "Blast an enemy with burning light, dealing
  ${$m1+0+$spfi*0.765222} Fire damage."
- Daybreak 503625: "Make a prayer, healing an ally for ${$m1+0+$BH*0.7}." The other Daybreak ranks read
  `$BH*0.595`.

`SunClericCoefficients` (`src/server/coa/AscensionSunClericData.h`) gave the eight Dawnsear rows sp 1.0 and the
503625 row healing 0.595. `spell_bonus_data` holds 0 rows for these spells
(`rev_20260909_13_sun_cleric_completion.sql`), so the table is the only spell power channel. The rows arrived with
e36bc50aad (the bulk restoration of five classes, 2026-09-10), which states no source for them.

Measured on 554406 before the change: 20672 and 20745 at 20000 spell power (pair 20261122-012804 / -012843, build
33138890), a slope of 1.0 against the tooltip's 0.765222. Only the coabuildhub snapshot (local copy dated 2026-09-18)
backs 1.0, for ranks 1 and 2.

Owner ruling O-15 (2026-11-22): "Dawnsear uses 0.765222 and Daybreak rank 503625 uses 0.7, and the rule is standing
for the class: where the project's coefficient table and the DBC tooltip disagree and at most an older community
snapshot backs the table, the tooltip wins, without asking again."

## Options

- Keep the table and correct the client text to 100% and 59.5%.
- Use the tooltip coefficients (O-15).

## Decision

`SunClericCoefficients` sets the sp coefficient of the eight Dawnsear rows, effect 0, to 0.765222, and the healing
coefficient of 503625, effect 0, to 0.7. No SQL and no client text change: the tooltips already state these values.
Later disagreements between the table and the tooltip in this class follow the tooltip when at most an older
snapshot backs the table.

## Consequences

- A Dawnsear hit adds 0.765222 times the caster's Fire spell damage bonus, at every rank (about 23% less spell power
  share). A 503625 heal adds 0.7 times the caster's bonus healing.
- Grace 504070 ("Increases the spell damage bonus of Dawnsear by $s1%", $s1 = 20) reads Dawnsear's row in
  `sun_cleric_devotion_scaling` and adds 20% of that sp term: 0.2 x 0.765222 = 0.153044 times spell power instead of
  0.2. Dawnsear with Grace adds 0.918266 times spell power instead of 1.2; at 20000 spell power the hit reads
  669..748 + 18365.33. Grace's own ratio becomes (708.5 + 1.2 x 7652.22) / (708.5 + 7652.22) = 1.1831 at 10000 spell
  power, the value the class entry already expects (1.1868 before).
- Readers of these rows: `sun_cleric_scaling` (Sun Cleric family 33 spells, keyed by spell id) and
  `sun_cleric_devotion_scaling` (Dawnsear and Sunflare by SpellFamilyFlags word 1, only with Grace). No other class's
  file, fixture or code reads these rows.
- Regression in `apps/coa-gameplay-test/conformance/classes/sun_cleric.json`: `554406 behaviour_metric_delta
  damage_sp` against `damage_base`, `503625 behaviour_metric_delta heal_sp` against `heal_plain`, and
  `504070 behaviour_metric_delta dawnsear_damage_sp` against `554406 damage_sp`; each excludes the old coefficient.
