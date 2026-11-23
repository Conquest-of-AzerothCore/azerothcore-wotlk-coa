# 0035. Malefic Arrow keeps one rank per Malefic Wrath rank

- Status: accepted
- Date: 2026-11-23
- Amends: ADR 0005

## Context

ADR 0005 made both the Hexfire Wrath and the Malefic Arrow branches of `SyncReplacements` require the top Malefic
Wrath rank. Report #12539 and its fault concern Hexfire Wrath only: every rank stood in for the one Hexfire Wrath
807480, so the restore sent a supersede per rank and could leave a lower rank on the bar. Malefic Arrow has a rank
chain of its own (801674, 680908, 680909, 680910, 573265, 572364, 572365, 570240, 570241) that matches the nine
Malefic Wrath ranks one to one, and the branch picks for each Wrath rank the Arrow rank of the same rank, so no two
Wrath ranks share an Arrow and the #12539 fault cannot arise. With the top-rank rule a Shadowhunting Witch Doctor
was never taught the lower Arrow ranks: the catalog scenario `witchdoctor-shadowhunting-first-spec-single-grant`
("Each Malefic Wrath rank is therefore joined by the matching Malefic Arrow rank") read Malefic Arrow rank 1 as not
known on the full Witch Doctor run 20261123-015709.

## Decision

- Only the Hexfire Wrath branch requires the top rank. The Malefic Arrow branch swaps every known Malefic Wrath rank
  for its matching Arrow rank again, as before ADR 0005.

## Consequences

- Regressions: `witchdoctor-shadowhunting-first-spec-single-grant`, `witch-doctor-hexfire-adept-top-rank-12539` and
  `witch-doctor-hexfire-wrath-no-rank-chat-12637`.
