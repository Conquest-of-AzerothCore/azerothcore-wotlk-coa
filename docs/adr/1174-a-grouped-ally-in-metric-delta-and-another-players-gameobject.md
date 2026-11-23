# 1174. A grouped ally in metric_delta and the use of another player's gameobject

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 1139, ADR 1112

## Context

Two clauses act on the caster's allies: Mojo Cauldron 807908 "Raid members may interact with the Cauldron" (the
object is party only, GameObject.cpp:1913-1925) and War Golem 800330 "redirecting harmful spells cast on nearby
allies to itself" (AscensionWitchDoctorSummons.cpp:696-710). metric_delta had no friendly second player, and the
harness `use_gameobject` used only an object the acting player owns (tool notes T-c11-d-1 and of cycle 8 B12).

## Decision

- Harness: `use_gameobject` takes an optional `owner` player whose object the actor uses.
- metric_delta option `grouped_ally` (`dy`, `grouped`): a second player of the caster's race and class beside the
  caster, grouped with it or not.
- `use_gameobject_after` takes `"user": "ally"`; `dummy_casts_at_caster` takes `"target": "ally"` (ADR 1171).

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13
gains 807908 `ally_mojo`, `stranger_mojo` and 800330 `golem_redirect`. The harness change needs a build.
