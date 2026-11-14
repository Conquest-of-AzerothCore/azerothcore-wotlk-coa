# 0660. The against-record flip test matches scenarios by entry and label

- Status: accepted
- Date: 2026-11-14

## Context

The tally of `conformance.py cycle` (ADR 0655) compared the pair with the record's two runs only on scenarios whose
file sha256 was unchanged. The ADR 0658 armor pin re-hashed 3099 of the 3731 generated Necromancer scenarios, so the
shared-pass pair of 2026-11-14 was compared with the record on 632 scenarios only, and the checkpoint did not say so.
Pooled verdicts (`part-1 + part-2 ...`) were never compared, because a joined key has no sha256.

## Options

1. Keep the sha256 match and show the skipped count.
2. Match by scenario key (the entry) and label/check, and show how many record scenarios matched.

## Decision

Option 2. A record verdict is compared when its label/check exists for the same scenario key in both manifests, for
every part of a pooled key, and its judge did not change (`judge_changed`). A record scenario with a file whose key or
labels the pair's manifest lacks is unmatched. The tally result carries `record_scenarios` (matched, unmatched and
the unmatched keys); the checkpoint JSON, the checkpoint markdown, the checkpoint log and the command output state the
counts, with a `WARNING` naming the first unmatched keys when the count is above 0.

Option 1 leaves a fixture change that re-hashes every scenario with no comparison against the record.

## Consequences

- A change of a scenario's set-up that keeps its key and labels is compared with the record; a flip then means the
  set-up change moved the verdict, which the cycle must explain.
- A judge change still excludes its label, as before.
