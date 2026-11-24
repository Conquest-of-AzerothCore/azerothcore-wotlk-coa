# TBC Jewelcrafting level-60 conversion

The current pinned run covers TBC Jewelcrafting equipment at item levels 60–77, with all original proc and
on-use effects preserved. Non-equipment outputs receive character-level requirement caps only. It changes
49 equipment templates, 167 gem item requirements and 82 recipe-book requirements. Lower requirements,
profession skill ranks, reagents, quantities, costs, binding and acquisition restrictions remain intact.
Test items 33060, 34627 and 34967 are excluded. Wrath equipment, gems, quests and training are outside scope.
The TBC crafting/training spells have no character-level gates above 60; the audited level-65 trainer entry
is Wrath and remains unchanged.

## Regeneration

```sh
python3 apps/coa-world-content/professions/build.py \
  --low 60 --high 77 --output /path/to/output-directory
```

The pinned baseline is `apps/coa-tests/tbc_jewelcrafting_rescale/baseline.json`. This helper regenerates this
specific cohort; it does not discover arbitrary professions or expansions. A new cohort requires its own
provenance audit and baseline. Changing the band may require additional matching armor donors.

Original equipment anchors are 83 and 159. Linear interpolation with half-up rounding produces:

| Original | Target |
|---:|---:|
| 83 | 60 |
| 88 | 61 |
| 93 | 62 |
| 97 | 63 |
| 99, 100, 102 | 64 |
| 109 | 66 |
| 114, 115 | 67 |
| 125 | 69 |
| 159 | 77 |

Permanent stats, resistances and Power use effective quality/slot RandPropPoints budget ratios. The three
cloth headpieces use matching item-level-69 epic armor donors. Permanent weapon damage is rebudgeted using
an existing client-known effect. Socket counts/colors remain intact; socket bonuses use exact matching
client-known enchantments. Random-affix families retain their aggregate chance while mapping to lower-budget
native properties. Original shared pools and spells remain unchanged. Purchasing materials can still bypass
acquisition effort; the conversion adds no new phase locks. Preserved procs, guardian summons and on-use
bonuses may be strong relative to the smaller permanent budgets.

## Runtime and deployment boundary

`CoAProfessionRescaleData.h` must match the generated migration. Runtime activation requires the expected
item level, level requirement and new property pool, so the compiled profile is inactive on original data.
The normal fixed-item path bypasses captured native stat ladders and supplies the converted Power values.
Profession headpieces retain converted worn armor rather than authored pre-conversion armor. Login sends
fresh queries for all 298 changed templates, including recipe books. Existing affixes normalize before
inventory stat application, at item arrival, in mail previews and for loaded auctions. Deferred inventory
writes survive the initial unchanged-state reset and save after character loading. No character migration is
needed. The shared gem-requirements component caps original in-memory enchantment requirements without
changing gem effects, identities or activation conditions.

The migration is active as `rev_20261122_03_coa_tbc_jewelcrafting_level60.sql` for the next startup. It includes the
approved gem item caps, superseding the standalone `rev_20261122_01_coa_tbc_gems_level60.sql.draft` for this
conversion; leave that earlier draft inactive. No live database changes or server installation are performed
by generation or verification. During the maintenance window, install the matching build and let the normal updater apply the selected
migrations. The Hellfire boss-damage and Faith vendor migrations are also approved for this rollout.
Do not also apply the SQL manually.

This implementation introduces no downloadable client patch: all item, spell, affix and socket-bonus IDs are
already client-known, and changed item templates use existing server delivery. The previous gem-scaling MPQ
is obsolete and must not be distributed. Actual rendered-client acceptance remains separate from the
artifact/runtime checks.

## Verification and acceptance

Run `tools/verify_all.py` with the checkout's settings, stages `source,build,harness`, and harnesses
`tbc_jewelcrafting_rescale`, `profession_item_runtime`, `native_item_stat_query`, `tbc_gem_rescale` and
`tbc_gem_client`. The SQL checks use private temporary MySQL instances. No second worldserver is launched.

In game, verify recipe-book learning and crafting at 60 with the required profession skill; representative
low/middle/high crafts; pre-existing equipped/bank/mail/auction items; a newly crafted random affix;
headpiece armor; original proc/on-use magnitudes; Power, socket bonuses and preview item levels. Test both a
normal gem and meta gem at 60 with the realm's existing client. Confirm their original bonuses, profession
restrictions and activation conditions, and verify Wrath recipes/gems remain restricted as before.

## Remaining TBC professions

The remaining TBC conversion uses the same 60–77 equipment band and preserves proc and on-use effects.
The five independent original ranges are Alchemy 90–159, Blacksmithing 88–159, Engineering 68–159,
Leatherworking 70–159, and Tailoring 93–159. The corresponding equipment counts are 6, 113, 40, 106,
and 71. Ammunition, consumables, bags, mounts, scopes, armor kits, and other non-equipment outputs
use the character-level gate policy. Profession ranks, riding skill, reagents, reputation requirements,
crafting quantities and specialization restrictions retain their existing values.

The pinned cohort and before-and-after values are in `tbc_remaining_baseline.json`. It records equipment
and recipe identities, permanent budget changes, and access changes for 56 recipe books, 19 other items,
11 trainer rows and 15 quests. Cogspinner Goggles retain their native suffix pool and use the normal
item-level-derived suffix factor. Positive random properties reuse client-known families and canonical
mappings through shared per-budget pools. The approved socket exceptions use a +2 bonus to the original
stat on Flamebane Bracers, Hyper-Vision Goggles, Gloves of Immortal Dusk, Unyielding Bracers, Bracers of
Havok, and Vengeance Wrap. The Great Earthforged Hammer's armor stays at its original value because
the matching armor benchmark would increase it.

Regenerate the two fixed-band artifacts from the pinned inputs with:

```sh
python3 -B apps/coa-world-content/professions/build_remaining.py --output /path/to/output-directory
```

The generated runtime data lives in `CoAProfessionRescaleRemainingData.h` and the world updater uses
`rev_20261124_00_coa_tbc_remaining_professions.sql`. Build from the same checkout as the migration.
The focused harnesses `tbc_remaining_professions`, `profession_item_runtime` and `native_item_stat_query`
exercise artifact equality, SQLite replay, runtime activation, existing-copy affixes and stat queries
without starting a server. MySQL updater and rendered-client acceptance are separate checks.
