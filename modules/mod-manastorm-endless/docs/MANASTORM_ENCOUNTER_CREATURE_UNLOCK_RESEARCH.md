# Encounter and creature unlock research

Research date: 2026-10-08. No gameplay, SQL, deployment or character state changed.

## Two content pools

An encounter stage is a `manastorm_segment`: map, DungeonEncounter ID, objective creature,
teleport, eligibility, weight and authored spawn roles. Boss objectives remain attached to
their segment; the generator selects a segment, rather than independently rolling a boss ID.

Randomized ordinary creatures are a separate `manastorm_creature_pool`. Each pool references
source segments through `manastorm_creature_pool_segment`. The datastore derives its distinct
creature entries from `manastorm_segment_spawn` rows with `CreaturePoolSource` flag 8, joined
to `creature.guid`. Ordinary route membership does not prove pool eligibility.

SQL 05 and `ManastormDataStore.cpp` explicitly preserve this distinction. Candidate resolution
exists, but exact original replacement chance, weighting and compatibility rules remain unknown.
The loader's candidate query is not an implementation of runtime random replacement.

Ascension's official announcement independently describes mixed creature combinations and
specific introduction levels that add maps, creatures and affixes to future pools:
https://ascension.gg/de/news/chapter-2-pre-patch-updates/461
That announcement supplies behavior, not a complete server-side creature-ID catalogue.

## What triggers an encounter unlock

`ManastormMgr::OnUnitDeath` requires the active run's registered objective GUID and the expected
runtime objective entry before recording stage completion. Killing another creature of the
same entry elsewhere does not grant an unlock. Trash deaths process route/Heart behavior separately.

`ManastormProgression::RecordStageCompletion` resolves triggers using completed depth, mode and
Normal/Endgame track. There is no fixed predecessor creature ID attached to those depth triggers:
the objective selected for that floor supplies the completion. It can vary between eligible stages.

For a staged introduction, completing depth D queues a pending unlock. The next selection forces
the track's configured introduction segment. Completing that specific pending segment persists
the permanent unlock and removes the pending row. Native messages describe this at D+1; the runtime
permanent-grant predicate checks the pending segment identity, not merely an arbitrary kill at D+1.
Direct grants resolve at their configured completed depth and do not invent an introduction boss.

## Creature-ID inventory

[MANASTORM_ENCOUNTER_UNLOCK_CREATURE_IDS.csv](MANASTORM_ENCOUNTER_UNLOCK_CREATURE_IDS.csv)
joins all 96 mapped segments / 78 distinct unlock IDs from SQL 46's saved mapping to the supplied
2026-10-07 segment export. It records track, trigger and expected introduction/completion depths,
segment ID, DungeonEncounter ID, native creature ID and runtime creature ID.

Native and runtime entries are different contracts. The native ID preserves recovered Ascension
identity; the runtime override chooses the actual server creature. The inventory incorporates
the repository's explicit Moonbrook, Grol and Allistarj restoration overrides:

| Encounter | Completed trigger | Introduction / permanent completion | Native ID | Runtime ID |
|---|---:|---:|---:|---:|
| Marisa du'Paige, both tracks | 5 | 6 | 84270 | 599 |
| Grol the Destroyer, both tracks | 70 | 71 | 83617 | 7665 |
| Archmage Allistarj, both tracks | 75 | 76 | 83618 | 7666 |
| Lucifron, Endgame | 235 | 236 | 12118 | 12118 |
| Ragnaros, Endgame | 350 | 351 | 11502 | 11502 |
| Kel'Thuzad, Endgame | 945 | 946 | 15990 | 15990 |

Export enabled/teleport columns are historical observations, not current live readiness.
Override sources are identified per row; unapplied migrations do not change a running database.
Unchanged export runtime values do not certify that every template/spawn/AI is usable today.
For example, Manaclaw Normal resolves to 10663 in the export, while its disabled Endgame row still
falls back to native 83859. No unverified Endgame override is invented here.

## Randomized creature IDs remain unresolved

The supplied `ManasstormSQLsASRequest.sql`, `Requested.sql`, and
`manastorm_world_live_2026-10-01.sql` contain no INSERT rows for either creature-pool table.
This is absence of membership evidence in these snapshots, not proof about today's live database.
Without pool-to-segment memberships and explicit eligible spawn roles, listing every mob from
an area as unlocked randomized content would invent membership.

Existing `manastorm_unresolved_segment_messages.csv` retains 46 unresolved content messages.
Especially informative are native message 1107: Endgame depth 58 unlocks Dead Mire randomized
creatures, and messages 1110/1111: depth 59 unlocks its map and creatures. These cannot be collapsed
into a single boss-kill unlock or used to infer exact candidate creature IDs.

The next targeted evidence needed is current exports of `manastorm_creature_pool`,
`manastorm_creature_pool_segment`, `manastorm_segment_spawn`, `manastorm_unlock_grant`, and the
referenced `creature` GUID/entry rows. Empty tables would establish a reconstruction gap;
populated tables would permit an exact pool/unlock/creature join without broad reverse engineering.

## Sources and validation

- Final native forensic report and protocol matrix in the read-only reference folder.
- Module SQL 05, SQL 46, existing segment mapping and unresolved-message inventories.
- Current generator, datastore, progression and objective-death code.
- Supplied `ManasstormSQLsASRequest.sql`, export timestamp 2026-10-07 14:54:38.
- SQL 52 Moonbrook, SQL 55 open-world Grol, SQL 56 open-world Allistarj.

All 96 rows were checked against exported segment ID, difficulty and encounter ID before writing
the inventory. No builds, live SQL execution or in-game completion tests were performed.

## Deeper DBC and template join

Decoded the actual reference `ManastormMessages.dbc`, rather than limiting the research to
previously mapped SQL unlocks. Its 291 records / 39 fields match the canonical forensic SHA256
`737adbca4c7891f3920356afd3cdac01aa06989ae3117c1264a1319b3d153770`.
English title is word 5; English description is word 22. Difficulty, completed depth and optional
Game Event ID are words 1, 2 and 3. Those fields are filters, not creature death criteria.

`DungeonEncounter.dbc` has 2080 records / 23 fields and matches SHA256
`f02642f3a02302f8b6d965a2ab3c0adb4f5b73117c6e0ece04bbb2c0facdded9`.
English name is word 5. `DungeonEncounterExtra.dbc` has 2069 records / 4 fields. For every named
future-unlock message, its encounter-extra word 1 agrees with the segment's native objective ID.
That corroborates the identity; it does not turn the remaining raw extra fields into death rules.

Two additional inventories preserve the complete investigation:

- `MANASTORM_MESSAGES_DECODED.csv`: all 291 messages, exact text and native filter values.
- `MANASTORM_FUTURE_CREATURE_MESSAGE_MATCHES.csv`: all 149 messages mentioning future Manastorms,
  with extracted actor names, exact SQL template-name candidates, matching segment variants,
  native/runtime objective IDs, encounter-extra corroboration and preceding introduction messages.

The 149 future messages comprise 71 named-encounter messages, 49 area/other-content messages,
28 affix messages and one explicit randomized-creature message. The 71 named messages cover
60 distinct encounter names; all 71 match track-specific encounter names and native objective IDs.
This includes Admiral Seastomper and Andre Firebeard even though their introduction variants
remain ambiguous for forced selection. Recovering identity does not require selecting a variant.

Title and description must both be read. Muckrake's title names the defeated creature while its
description names Ruins of Alterac. Nyx and Nocturna name Baradin Hold Arena in their description;
Leafborn Sentinel names Ashamane's Fall. Mechatron's message says "Unlocked Tinkertech Showdown"
without the usual "You have unlocked" prefix. The original Vaelastrasz introduction contains the
typo "Manastoorm". These cases are included without silently correcting the preserved raw text.

Compared names against 31,262 creature templates in supplied `LastRequirements.sql`, dated
2026-10-04 16:45:32. An exact name can return several entries: Patchwerk returns 16028 and 31099;
Kel'Thuzad returns 15990, 20350, 20423 and 25465. The segment/encounter join selects native
16028 and 15990 respectively. Choosing the lowest ID or every same-name template would be unsafe.

| Named content | Native objective | Exact-name SQL alternative | Interpretation |
|---|---:|---:|---|
| Muckrake | 83261 | 2421 | Native duplicate; alternative template identity only |
| Razelikh the Defiler | 84272 | 7664 | Native duplicate; alternative template identity only |
| Andre Firebeard | 83668 | 7883 | Creature identity resolved; stage variant still ambiguous |
| Admiral Seastomper | 103150 | none | Custom native identity; template absent from supplied export |
| Archmage Adeline | 103151 | none | Custom identity; unusual native depth 8600 retained |
| Nyx and Nocturna | 662953 | none | Custom named encounter; multi-actor behavior unresolved |
| Leafborn Sentinel | 662954 | none | Custom identity; template absent from supplied export |
| Xyron the Corruptor | 662963 | none | Custom identity; template absent from supplied export |
| Mechatron | 663012 | none | Custom identity; template absent from supplied export |

The alternatives above are not new runtime overrides. Template name equality identifies a
candidate, but does not establish correct abilities, encounter scripts, spawn placement or
native equivalence. Twenty named-message rows refer to native IDs absent from this supplied
template snapshot; some have suitable-looking named alternatives, others are custom bosses.

Area messages can be linked to mapped introduction stages at the same completion depth/track;
those associations are recorded separately. For example Moonbrook has Marisa as its objective.
This recovers the stage's boss, not every randomized creature that Moonbrook contributes.
An area name alone cannot establish exact trash membership.

## Introduction, death and presentation are separate contracts

The native client receives completed depth through opcode 0x65E and selects messages by depth,
difficulty and optional Game Event ID. The native message does not carry a killer, creature ID,
GUID, boss-death count or durable unlock grant. A "Defeated" title therefore establishes the
intended encounter milestone, not the original server's internal death predicate.

The current shared backend supplies that predicate:

1. A matching runtime objective entry entering the stage registers its exact GUID if none exists.
   Later duplicate GUIDs of the same entry are ignored as objectives.
2. Death processing requires an Active run on the creature's exact stage map/instance.
3. Only the registered objective GUID reaches objective completion; its entry is checked again.
   A same-entry duplicate does not complete the run. The killer parameter is unused in this path.
4. Completion looks up unlocks by run depth/mode/track, then writes rewards, completed depth,
   pending introduction and permanent ownership in the shared character transaction.
5. A pending introduction becomes permanent only when the completed segment matches its
   track-specific intro segment. Failed persistence fails the run rather than advancing it.
6. Pending introductions are explicitly enterable/retryable at their exact depth, including
   depths outside the ordinary 1,6,11,... checkpoints. Generator forcing bypasses permanent
   unlock and repeat filters while retaining track and configured depth eligibility checks.

Sixty-two named completion messages have a native introduction message at the prior depth on
the same track. Nine have no such prior-depth introduction: Adeline on both tracks, Mandokir,
Anub'Rekhan, Drakkisath on both tracks, Rend on both tracks, and Xyron. Existing SQL 46 maps these
as direct grants; that implementation awards them on completed depth, without requiring the
named boss as a distinct pending introduction. The original server may have additional rules
that these client files do not expose.

Game Event filtering is material: Vaelastrasz messages 39/293 require event 134 in the client.
Sending completed depth alone does not guarantee every message is shown. The CSV preserves
all event IDs rather than merging seasonal messages into unconditional milestones.

## Multi-creature completion requires a targeted audit

Twin Emperors segment 634 / encounter 4251 has native and exported runtime objective 15275,
whose template is Emperor Vek'nilash. The current generic completion path tracks one GUID; it
does not require a second Emperor death counter. This establishes a possible acceptance gap
between the encounter name and current completion criteria, not proof of the original rule.
Nyx and Nocturna similarly map to one custom native objective 662953, absent from the supplied
template export. Their name alone cannot establish whether that ID represents a controller,
one boss, a merged creature or a scripted encounter proxy.

Before claiming those encounters fully reconstructed, verify their source scripts/templates,
required actors, objective registration and death behavior. No gameplay changes are made here.
