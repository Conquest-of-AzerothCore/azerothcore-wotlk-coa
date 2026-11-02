# 0008. Share reputation across an account by raising it at login

- Status: accepted
- Date: 2026-11-02

## Context

Ascension shared reputation between all characters of an account (#9918, citing the Project Ascension wiki page
"Realm Wide Features"; #1432). CoA stored reputation only per character in `character_reputation`, so every alt
had to farm Timbermaw, Argent Dawn and the rest again.

Constraints:

- Base reputation depends on race and class (`FactionEntry::BaseRepRaceMask/BaseRepClassMask`), and
  `character_reputation.standing` is stored relative to that base. Exalted Darnassus on an Alliance character
  must not reach a Horde alt, whose base standing with Darnassus is Hated.
- A reputation loss on one alt (killing Timbermaw furbolgs, Booty Bay guards) must not lower the others.
- Rank-capped content must keep working: quests with `RequiredMaxRepFaction` and kill rewards with
  `MaxStanding` already refuse rewards past their rank, so a shared standing has to go through the normal
  standing state rather than a parallel store.

## Considered options

1. An `account_reputation` table written on every change and applied at login. Needs a migration to seed it
   from existing characters and a second source of truth that can drift from `character_reputation`.
2. At login, read the other characters' rows from `character_reputation` and raise the logging-in character
   to the best shared absolute standing. No new table, no migration, existing characters count at once.
3. Rewrite `ReputationMgr` storage to be keyed by account. Large change to inherited code, hard to merge
   upstream, and still needs per-race base handling.

## Decision

Option 2. `AscensionAccountReputation` (a login `PlayerScript`) loads the other non-deleted characters of the
account, converts each row to an absolute standing with that character's race and class, and keeps a faction when
the characters share a team or both have the same base standing for it, and only when that character earned
standing above its own base. Hidden factions, such as profession specializations, stay per character. The
logging-in character is raised to the highest shared standing through `ReputationMgr::SetOneFactionReputation`,
never lowered. `ReputationMgr` gained static base-standing and default-flag lookups by race and class mask so the
script reuses the core rule.

## Consequences

- Progress becomes shared at the next login of each alt, not live. Only one character per account is normally
  online, so the difference is invisible in play.
- A character that lost reputation is raised back to the account's best standing at its next login.
- Rank-capped quests and kills stop rewarding an alt once the shared standing passes their cap, because they
  read the same standing.
- Reaching a rank on an alt this way updates achievements and reputation-objective quests through the usual
  standing path.
- A relog immediately after logout may read the previous character's last saved state; the next login catches
  up.
