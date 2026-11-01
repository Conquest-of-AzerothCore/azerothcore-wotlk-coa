# Reconstructed creature twins

This batch adds unspawned creature templates and partial Exiles loot using same-named templates already
present in the CoA baseline. These are reconstructions, not recovered Ascension encounter implementations.
The source identity is the captured template name; only missing captured templates use the mirror name.
Heroic/Mythic mirror aliases remain associated by creature ID. Same-name identity is a candidate rule,
not proof of equivalent mechanics. Multiple-name matches belong to a separate, held batch.

The generator accepts read-only JSON table exports, the preserved NPC mirror, target DBCs, and the earlier
item/quest baseline. It performs no database or network operations. Source inputs and DBCs stay local.
The generated SQL is self-contained; it requires the target world schema and referenced item/global data.

## Field policy

- Creature identity uses the captured name. Level and rank use explicit mirror metadata where present;
  missing numeric mirror levels retain the donor range and are listed in the manifest.
- Faction, unit class, combat flags, damage profile, attack timing and other combat fields come from the
  donor. Captured health/mana modifiers and valid classifications supersede donor values.
- Supported captured models are retained and their probabilities normalized. Unsupported displays are
  omitted. A creature without a supported captured model uses target-valid donor models; missing captured
  templates retain donor models and health/mana modifiers. Every fallback is listed by name.
- Root VerifiedBuild=-12341 marks reconstruction from a donor. This is a proposed convention for upstream
  confirmation. Child VerifiedBuild values retain their original provenance; some child columns are unsigned.
- Difficulty redirection, kill-credit substitution, pickpocket/skinning references, spawn paths, service flags,
  gossip menu and racial-leader status are cleared. No spawns, vendor inventories, trainers, quest relations,
  vehicle accessories or encounter placement are contributed. Vehicle references are donor-derived.
- C++ ScriptName bindings are omitted and listed as plain melee without recovered encounter mechanics.
  Portable SmartAI blocks are copied whole, including self-owned dialogue, selected dialogue locales,
  SourceType22 conditions and remapped self-targeted timed action lists. Ambiguous world/instance/GUID/path
  behavior withholds the entire creature. No arbitrary numeric replacement or partial AI block is shipped.
- Loot uses only distinct, named, positive stated chances. Missing, conflicting, duplicate, quest-sensitive
  or unknown-chance drops are excluded. New loot fields default to Reference=0, QuestRequired=0, LootMode=1,
  GroupId=0, MinCount=MaxCount=1. A creature with no safe drop rows keeps lootid=0.

## Application and preservation

The migration stages complete cohorts in temporary InnoDB tables inside one transaction. A preexisting
creature, orphan child record, shared loot owner, condition or AI/TAL collision skips that complete cohort.
Missing or newly quest-sensitive loot items also skip the cohort. The migration never replaces an existing
creature. Its DELETE statements use key-only temporary ownership tables whose destinations were proven
empty, followed by matching INSERTs. Reapplication skips the now-existing creatures, preserving operator
changes rather than overwriting them. A failed statement must abort its mysql session; never use --force.

The mutation assumes the ordinary exclusive world-migration workflow. No updater should modify the same
creature namespaces concurrently. SQL does not install DBCs, create spawn positions or implement missing
boss mechanics. Creatures become available only when explicitly spawned later by the maintainer.

## Reproduction

Run `python tools/coa_creature_sql.py --help` for the local-input interface. Input filenames are
`coa_world.<table>.json` and `asc_world.<table>.json`. The report records hashes, donor IDs, field fallbacks,
AI exclusions and planned loot counts. The DBC directory must be the intended target asset set.

Run the synthetic planner/AI tests and `test_coa_creature_migrations.py --mysql-bin /path/to/mysql/bin`.
The migration tests adapt the existing enchantment harness: fresh temporary datadir, unique named pipe or
socket, --skip-networking, and cleanup limited to the owned process and exact temporary directory.
Windows --no-monitor keeps that ownership direct. Add --before-ref to reproduce the missing-migration
failure. Test item references are synthetic; preserved-world comparisons and core startup checks are
separate local validation, recorded in the PR body. No in-game validation of this creature batch is claimed.

## Provenance and limits

The mirror is the 2026-08-29 db.exil.es crawl published by Duff-SPP. Its AGPL declaration concerns software,
not a grant of rights to the data. Captured template fields derive from locally preserved client caches;
donor behavior derives from the CoA world baseline. Only derived SQL, converter/tests and documentation
are contributed. No source archives, client JSON, DBCs, credentials or profiles are included.

NPC drop lists are capped at 20 and report zero observations. Stated drop chances are not measurements;
this batch is partial loot reconstruction. Approximated donor behavior may differ from Ascension. Named
exclusions stay outside this migration; they are not silently downgraded into allegedly working encounters.

## Local validation limit

On the current-world scratch snapshot, all 1,590 planned creatures and 19,496 loot rows were inserted;
reapplication preserved the complete affected-table snapshot. The core loaded all 32,753 creature definitions
without new faction, class, model or other creature diagnostics. Both the unmodified baseline and candidate
then exited with access violation 0xC0000005 before SmartAI loading. Full startup and runtime SmartAI validation
are therefore incomplete; the SmartAI evidence is the synthetic transformer suite and database integrity checks.
No live realm application or in-game validation of this batch is claimed.
