# 0118. CalcAmount-hooked reads are not measured, and every verdict carries its build

- Status: accepted
- Date: 2026-11-11

## Context

Of the 8 alerts investigated after round 10 on the Templar, 2 were server defects; 4 concerned behaviour that
already worked and 2 were wrong tests. Two tool causes stood out, and the owner adopted both remedies on 2026-11-10
(`owner-rulings-2026-11-10.md`, "Alert precision"):

- `spell_effect_value` returns `SpellEffectInfo::CalcValue`. An aura script `DoEffectCalcAmount` hook can set the
  applied amount afterwards (Staffguard 706583 and Untainted 705299 in `AscensionTemplarAuras.cpp:60-67`), so a
  CalcValue readback can alert on a correct server or pass on a wrong one.
- A verdict did not say which server build produced it, so a verdict judged before a fix could be reported after it.

The clause-spec prototype built both (commit a6322d5032); ADR 0116 carries them over.

## Considered options

1. List each hooked effect by hand in the class file (`disabled_foreign_effects`). Rejected as the rule: it depends on
   someone finding the hook, and the reason text goes stale.
2. Count the hooks on the running build: a harness metric reads the aura scripts bound to the spell and counts their
   `DoEffectCalcAmount` handlers for the effect. Chosen.
3. Stamp the build only on the report. Rejected: verdicts are merged across runs and outputs later.

## Decision

- Harness metric `spell_calc_amount_hooks` (`spell`, optional `effect`): `ScriptMgr::CreateAuraScripts` for the spell,
  `_Register` on each, count of `DoEffectCalcAmount` entries whose `IsEffectAffected` holds for the effect.
- `values.value_scenario` follows every judged `spell_effect_value` read (own or foreign effect) with
  `<label> calc_amount_hooks` of the same spell and effect. `compare` judges the read as before when the count is 0,
  gives the new status `not_measured` when it is above 0 (not an alert, never conformant, listed in `report.md`;
  `detail` keeps the status the read alone would have had), and `unmeasured` when the reading is missing.
- Each run carries the server commit parsed from `server_version` (`AzerothCore rev. <commit>`, `+` kept for a
  modified tree), the worldserver `binary_sha256` of `summary.json` and the `run_id`. `compare --build <sha256 or
  commit>` judges one build and refuses runs of any other; without it the results must hold one build (exit 5
  otherwise). Every verdict carries `server_commit`, `build` and `runs`, in `verdicts.json` (whose header names the
  shared build) and in three new `alerts.tsv` columns.

## Consequences

- Every generated value scenario gains one read per judged effect value read.
- The count covers aura scripts bound through `spell_script_names`, not global `OnAfterAuraEffectCalculateAmount`
  hooks, nor `passives.py` effect value reads; a read on those paths can still pass while the applied amount differs.
- A hook registered for every effect of a shared lifecycle script makes reads `not_measured` even for effects whose
  amount it does not change: conservative, never a false proof.
- The Templar class file still lists Staffguard 706583 and Untainted 705299 effect 0 as `disabled_foreign_effects`,
  so those two reads are not generated; removing the rows is a class-file change left to the Templar batch.
- Coverage refuses verdicts of another build in the commit of the two proof statuses (ADR 0120); the prove runner
  refuses a proof whose runs were judged on two builds (ADR 0121).
