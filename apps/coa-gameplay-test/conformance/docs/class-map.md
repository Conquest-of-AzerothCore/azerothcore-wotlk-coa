# Class map

`class_map.py` maps every spell of all 21 CoA classes (12-32) to the code that touches it, so a class's conformance work
can start where the risk is. It reads a source tree and the server DBC set and writes only into its output directory. A
run took 28 s on the tree that adds it. It is the first step of the class workflow ([class conformance
guide](../../../../docs/coa/class-conformance.md), 9.1).

## Run

From the repository root, with `W` a source tree (a worktree or this checkout):

    python3 -B apps/coa-gameplay-test/conformance/class_map.py --worktree W --out OUT [--dbc-dir DIR] \
      [--log-events EVENTS.csv]

- `--worktree`: the source tree to read. The script imports and runs that tree's conformance modules, so point it only
  at a tree you trust. It must hold `apps/coa-gameplay-test/conformance`, `apps/coa-dbc` and `src/`, and it must be a
  Git checkout, because the map records its commit.
- `--out`: the output directory, created if needed.
- `--dbc-dir`: the DBC set. The default is the conformance tool's server DBC set (`profile.DBC_DIR`).
- `--log-events`: optional event counts from your own combat logs (below). Without it, every log column is 0.

Outputs:
- `OUT/class-map.json`: every spell of every class, with the server commit and the Spell.dbc sha256;
- `OUT/class-map-table.md`: one row per class.

Keep the outputs out of Git. `class-map.json` also records the absolute `--worktree` and DBC paths. Each developer
regenerates them, because the log columns come from their own logs.

### The log events file

The file is a CSV with no header. It has one line per (event, spell id): `EVENT,SPELL_ID,COUNT`.
- Count `SPELL_*` and `RANGE_*` combat log events whose source is a player.
- `SPELL_CAST_SUCCESS` and `SPELL_CAST_START` count as casts; every other event counts as "other".

For 3.3.5-format `WoWCombatLog.txt` files, where a player's GUID starts with `0x00000000` and the spell id is the eighth
field, this pipeline builds it:

    cat LOGS/*.txt | LC_ALL=C awk -F, \
      '$2 ~ /^0x00000000/ && $8 ~ /^[0-9]+$/ { n=index($1,"  "); e=substr($1,n+2);
        if (e ~ /^(SPELL|RANGE)_/) c[e "," $8]++ } END { for (k in c) print k "," c[k] }' \
      > EVENTS.csv

## What a row of the JSON holds, per spell

- `source`: one of two values.
  - `advancement`: a `CharacterAdvancement.dbc` rank spell of the class's custom ClassType, the same set as
    `classes.class_spells`.
  - `base_candidate`: a row of `AscensionCompatData::ClassSpells` in `src/server/coa/AscensionCustomClassData.h` that is
    not in the advancement set.
- `ranks`: the base spell plus the chain of `AscensionSpellProgressionData.h`.
- `tooltip`, `sentences`, `tokens`, `token_kinds`, `literals`: read from `Description[enUS]`.
- `foreign_spells`: spells named by a `$<id>` token or an `@s:<id>:` mark.
- `triggered_spells`: `EffectTriggerSpell[0..2]` of every rank.
- `risk`, the first that applies:
  - `scripted`: a rank, a foreign spell or a triggered spell appears as a whole-word number in a `.cpp` or `.h` file of
    `src/server/coa` (hits listed as `file:line:kind:id`);
  - `family_mask`: its `SpellFamilyName` is the class's dominant family, and its flags intersect a mask tested in the
    class's own files (`Family(...)`, `SpellFamilyFlags[w] & m`, `flag96(...)`);
  - `core_script`: the only hits are in `src/server/scripts` or `src/server/game`, for ids of 10000 and above;
  - `data_row`: the only hits are in `*Data.h` files (coefficient or contract tables);
  - `stock`: no hit.
- `unhandled`: effects of a rank or of a triggered spell that the server has no handler for, read from the two handler
  tables (`SpellEffects[]` in `SpellEffects.cpp`, `AuraEffectHandler[]` in `SpellAuraEffects.cpp`):
  - `EffectNULL`, `EffectUnused`, `HandleNULL` or `HandleUnused`;
  - a `nullptr` entry whose enum name no `.cpp` file uses;
  - an id past the table;
  - a spell modifier operation of 32 or more (`MAX_SPELLMOD`).

  Effects 20 and 78 (dodge, attack) are left out, because the stock core handles them elsewhere.
- `script_only`: effects that do nothing without a script (`EffectDummy`, `EffectScriptEffect`, `HandleAuraDummy`).
- `gap`: the class of a spell with no code hit (`stock` or `data_row`) is `unhandled`, else `script_only`, else `none`.
  A spell with code is `covered_by_code`. `unhandled` and `script_only` are the spells most likely never reimplemented:
  their data comes from a client whose server no longer exists.
- `custom_mechanics`: mechanics that stock 3.3.5 does not have and that this fork had to reconstruct. These are effects
  of 165 and above, auras of 317 and above, and modifier operations of 29 and above.
- `log_casts`, `log_other_events`: events in your log events file whose spell id is a rank of the spell.
- `log_linked_events`: the same for its foreign and triggered spells.

Per class:
- `own_files`: the code files that at least 5 of its spells hit, and at least 10% of the most-hit file, minus the shared
  files;
- `shared_files`: files that three or more classes hit that way.

## Check against the Templar

The Templar's bucket file had a `script_touch` flag built independently from its ledger. On the 169 spells both hold,
the two agree on 168: 105 scripted, 63 not. The one difference is a spell the ledger marks touched through a family mask
and this map marks `data_row`.

## Limits

- A handler existing does not show it does what the lost server did: the custom handlers are reconstructions.
- `script_only` with no code hit can still work, if a script reaches the spell without naming its id.
- `stock` is an upper bound. The map does not see code that reaches a spell by its name, by an aura type, by an effect
  type, or through SQL (`spell_proc`, `spell_script_names`, `spell_custom_attr`). In `src/server/scripts` and
  `src/server/game` it counts only ids of 10000 and above (`core_script`).
- A whole-word number match can be a coincidence for small ids. The Templar check found none.
- `base_candidate` is not proof that players obtain the spell. The Templar's spell set was confirmed by hand ([spell
  sets](spell-sets.md)). For other classes, the log columns give some evidence, if you have logs.
- Combat logs do not store a class. A spell id shared by two classes counts for both.
- Sentences and tokens indicate size; they are not a clause count. When first counted, on 2026-11-11, the Templar had
  297 sentences and 334 tokens here, for 433 ledger claims.
- Harness files (`CoAGameplay*`) and the two generated headers (`AscensionSpellProgressionData.h`,
  `AscensionLiveBaselineData.h`) are not counted as touches.

## Cross-class candidates noted during the Templar work

- **Aura 354** (`SPELL_AURA_ASCENSION_PROC_PERCENT_EVENT`). The core acts on it only for 8 hard-coded spell ids.
  - At bc391cd7bc, 131 spells of the 21 classes carry it, 6 of them Templar.
  - Four have no class code: Tempest Calling 707615 (class 16), Rapid Strikes 560341 (class 21), and Windsage 705568 and
    Decoder 706523 (class 32).
  - On the Templar, the class script does the work, so nothing was tested there.

  Check it first when a second class starts ([class conformance guide](../../../../docs/coa/class-conformance.md), 9.2).
