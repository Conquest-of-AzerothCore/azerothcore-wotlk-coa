# 0051. Entomb's Physical immunity is measured on an enemy player

- Status: accepted
- Date: 2026-11-13

## Context

Claim 302.2, Entomb 500341 "making them immune to Physical damage": Effect[2] aura 40 SPELL_AURA_SCHOOL_IMMUNITY,
MiscValue 1 (Physical). On the dummy the Physical Void Zone 92559 hit still landed after a real Entomb: partial school
immunity is dropped on NPCs by #6786 (212d773dde). Owner ruling Q-c7-1 (2026-11-13): keep #6786, the drop on NPCs is
by design; the entry moves onto an enemy player, plus a text item (Entomb's immunity applies to players, not NPCs).

## Decision

The `physical_immune` entry targets an enemy player (race 2, class 8, `enemy_player_class`, ADR 0561) instead of the
dummy. `spell_damage_count` is cumulative over the scenario: the control's Physical hit lands (1 damage log); after a
real Entomb the same hit adds none (still 1; a target without the immunity reads 2). The former expected 0 ignored the
control's log (incorrect test corrected). No server change.

## Consequences

- The NPC behaviour of #6786 is not measured as a defect; the text item stays with the owner.
