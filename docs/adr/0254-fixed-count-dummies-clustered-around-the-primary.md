# 0254. fixed_count dummies clustered around the primary

- Status: accepted
- Date: 2026-11-12

## Context

Claim 89, Norgannon's Wrath 524739 "to up to $524740i enemies" (10). The `cap` arm of ADR 0221 spreads eleven dummies
between 0.42 and 4.58 yd of the primary; its two counted runs struck 11, then 10, in one cast. The owner ruling of
2026-11-12 asks for fixed positions well inside the radius, the primary identified, and two runs.

## Decision

`fixed_count` gains `cluster_yd`, for a target-centred entry with `primary_distance_reads` and a value inside `radius`:
the additional dummies are placed at primary + cluster_yd x i / n instead of primary + radius x i / n, and their reads
are judged under `cluster_yd`. Entries without it regenerate byte-identical. Norgannon's Wrath `cap_cluster`: twelve
dummies within 2.5 yd of the primary (the explicit target of every cast), six casts, by the tooltip the primary and
exactly 9 others per cast.

## Consequences

- An 11 can then come neither from a dummy at the radius edge nor from a moved primary: only from which candidates the
  engine keeps. 524740 strikes its explicit target by TargetA and caps only its TargetB area list at
  MaxAffectedTargets with Acore::Containers::RandomResize (Spell.cpp:1404-1410); lean/radius.md has the result.
- Seeded tests: the dummies lie within the cluster, a seeded read outside it alerts, a cluster at the radius is
  refused, and the `cap` arm keeps `radius` as its bound.
- Its labels follow ADR 0240: `524739 cap_cluster behaviour_fixed_count`, with the suffix after the spell id in every
  dummy read. The counted pair 20261112-044346 / -044500 ran under the earlier `524739 behaviour_fixed_count
  cap_cluster` form, so the entry was run again under the merged labels.
