# Necromancer Life Force and summon sizes — 2026-09-09

This document describes the Life Force, summon-size and UI source changes.
The [September 9 release summary](local-release-state.md) records their later
integration.

## Occupancy

Native `Spell::EffectSummonType` executes at HIT. `_handle_immediate_phase` clears the earlier script
prevention masks with `PrepareScriptHitHandlers`. The previous LAUNCH replacement consequently created
one custom summon and then allowed a native duplicate at HIT. The replacement now runs and suppresses
the native effect at HIT, once per spell bundle. The actual native dispatch/reset functions reproduce
the old duplicate and verify the correction.

Each successful creature is registered synchronously; the loop checks free capacity per creature and
the AI checks again before admitting a paid minion. Native/helper paths cannot bypass this admission.
Costs follow spell rank roots; the legacy permanent Abomination and skeleton Raise helpers share their
ordinary costs. Failed summons never occupy Life Force. Death, despawn, ownership, map and phase cleanup
retain the existing GUID rules. A capacity reduction preserves living minions and prevents further
paid summons until enough capacity becomes free.

Raise costs remain 1/2/3, with Grave Mages reducing a Skeletal Mage from 2 to 1. Animate spells and
explicitly free temporary armies retain their recovered resource rules, including free Plaguefathers.
They can coexist with a full Raise army; that is distinct from the unintended duplicate Raise.

## Growth and UI

Base capacity is 2, plus native operation-31 spell modifiers targeting Life Force. Level does not add
capacity continuously. Current local progression teaches Scourge Apprentice Training (680283), +1 at
level 10 for Necromancer. Animation specialization 35 grants Summoning Adept (92123), another +1 from
level 10 subject to its identity dependency, and Summoning Expert (807494), +1 at level 30. The selected
Master Animator talent (504431) adds another +1. Thus current ordinary local progression is 2 before
level 10 and 3 afterward; Animation can reach 4 at level 10, 5 at level 30 and 6 with Master Animator.
These are the checked local acquisition rules, not a claim of official server parity.

The permanent 805011 aura now transmits total capacity in its stack count. Visual aura 525004 transmits
only free capacity, disappearing at zero. The client reads both helpful and harmful forms and displays
free/total in the existing orb, with total determining button slots. It does not infer maximum capacity
from the remaining amount. The native GetSpellMaxStack fallback is used before the server aura arrives.
Server and Lua changes must be installed together; the Lua candidate is not for the old server alone.

## Models

The review of all 33 templates used previously verified installation data and
model DBCs; it did not include a fresh live database query. Crypt Fiend
50323/display 17308 gets template DisplayScale 0.5. Ten other large army models
receive scoped reductions. Exact scale changes and approximate model heights
are documented in the
[summon-size migration](../../data/sql/updates/pending_db_world/rev_20260909_03_necromancer_summon_sizes.sql).

Migration 03 changes only guarded template-model links. Shared model-info, display DBCs, player models,
world NPC templates, existing SQL and all 22 other summon scales are preserved. Giants remain larger
than ordinary skeletons. Bounds are an offline size estimate; actual animated appearance is pending
gameplay inspection. Native object scaling also scales each affected summon's radius and combat reach.

Before installation, require all 11 links to be the exact old or intended new display/scale combination.
Never overwrite a conflicting template. Do not rerun the old Necromancer completion generator against
its already applied migrations.
