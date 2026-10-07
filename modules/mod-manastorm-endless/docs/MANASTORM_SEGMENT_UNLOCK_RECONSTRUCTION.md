# Segment unlock reconstruction

SQL 46 maps 96 distinct segments: 69 introduction chains (87 targets) and nine direct grants.
Existing canonical unlock IDs are preserved; 52 duplicate introductions are disabled.
The original definitions are checked against the supplied 2026-10-07 export and Patch-M
ManastormMessages/DungeonEncounter data. Each retained introduction message has a
completion message at trigger depth + 1. The CSV records actual stored message IDs;
paired tracks use native DBC presentation, while Mode 1 retains the existing message metadata.

The additional Altar of Storms chain maps Lady Sevine, segments 554/555.
Ascension explicitly identifies this boss in that Manastorm:
https://ascension.gg/fr/changelog/2026?page=137
Messages 7/18 announce depth 55; messages 261/272 announce permanent availability at 56.

Direct grants use unique encounter-name matches for messages 265,276,280,311,736,737,740,741,1205.
No next-run encounter is fabricated for these. Adeline retains the supplied unusual depth 8600.

## Activation

Build the accompanying datastore change, apply SQL 46 after SQL 45, and restart.
Mappings can be enabled while their segments stay disabled. The loader drops unavailable
introduction tracks and defers direct definitions with no enabled targets. Disabled segment
grants are skipped. Enabling a valid segment with its teleport activates its configured gate
on restart/reload. Merely assigning a teleport does not set segment enabled=1.
Enabled but invalid content and missing segment IDs remain validation errors.
Native Mode 2 transport and Mode 1 remain unchanged.

No teleport, objective, creature pool, affix policy, reward rule or character history is populated.
Mapped targets have STARTING_UNLOCKED cleared; their other flags are preserved.

## Evidence limits

This is the complete currently resolved mapping, not proof that all 1017 segments need gates.
The unresolved CSV retains 46 content messages for areas/variants without a unique supported
segment mapping, including some paired normal/endgame messages and the creature-only Dead Mire row.
These are audited but intentionally unimplemented. In particular, selecting a forced variant
for Seastomper/Firebeard or equating Caer Darrow with every Scholomance encounter would be a guess.
Equipment-unlock messages are loot-bracket evidence, not dungeon-unlock evidence.

Verification: SQL executed twice against an in-memory SQLite model of the supplied export;
enablement/teleport preservation, deferred introductions/direct grants, track activation and
missing-target validation boundaries checked. C++/SQL style checks passed.
No C++ build, MySQL application or in-game test was performed.
