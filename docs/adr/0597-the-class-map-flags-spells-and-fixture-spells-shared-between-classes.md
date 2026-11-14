# 0597. The class map flags spells and fixture spells shared between classes

- Status: accepted
- Date: 2026-11-13

## Context

Classes share some spells: Templar and Necromancer both list 81 Dodge, 107 Block, 6603 Auto Attack and 552011
Resilient Constitution, and their class files both use spells as test fixtures (12096 Fear among them). A change to
the code, data or fixture of such a spell made for one class can move another class's results. The class map
(`class_map.py`) already built every class's spell list but did not say which ids other classes hold, and nothing
listed the spell ids several class files use. `--spell ID` cannot select conformance scenarios (catalog only).

## Considered options

1. Leave it to the contributor's search. Rejected: the inventory found the shared fixture by hand and missed nine.
2. Flag both kinds in the class map's output. Chosen.

## Decision

- Each spell entry of `class-map.json` carries `shared_with`: the other class ids (12 to 32) whose spell list holds
  the same id (`mark_shared_spells`).
- `class-map.json` carries `shared_class_file_spells`: every spell id that more than one class file under
  `classes/` uses, with the class ids and the keys it appears under. A class file's spell ids are the integers under
  keys ending in `spell`, `spells`, `aura` or `auras`, and the first element of each pair inside such a list
  (`[[823764, 1]]`); clause ledgers and consumption files are not class files.
- Rule (guide): touching the code, data or fixture of a flagged spell requires the snapshot check and the gameplay
  rerun of every finished class that uses it, by its snapshot generation (ADR 0590, 0591).

## Consequences

- At 019887b267 the class map flags the four base spells above in both classes' lists (each held by 20 other
  classes), and ten spell ids used by both class files: 1715 Hamstring, 12096 Fear, 37122 Domination, 41394 Light of
  the Naaru, 48101 Stamina, 92559 Void Zone, 600002 ARoy buff 3, 823764 beeg spellpen, 984954 Reg's Test Aura and
  1140480 Power of the Ashtongue.
- The class-file scan sees only classes with a class file; a class without one is covered by the spell-list flag only.
- A spell id stored under a key outside the naming rule is not seen.
