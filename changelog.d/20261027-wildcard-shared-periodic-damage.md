# Shared caster-owned periodic damage repair

Restores the evidenced aura-214 cohort with MiscValueB=1 through native damage calculation and proc eligibility. It applies only to periodic damage from the debuff caster and the effect's school mask. The other aura-214 cohorts remain unchanged; no blanket NULL-handler replacement is assumed.

## 48181 — Haunt

Before: Its damage and return-heal handlers were already bound, but its caster-owned periodic Shadow damage bonus was ignored.

After this change: The existing debuff now participates in the native periodic damage-taken multiplier, restricted to its caster and Shadow school. Existing damage and healing handlers are reused.

## 274178 — Dark Winter

Before: Existing Frost-damage proc rules applied the debuff, but its periodic Shadow damage bonus was ignored.

After this change: The existing stacking debuff now increases periodic Shadow damage from its caster. Native proc filters, duration and stacking are retained.

## 277470 — Lich's Calling

Before: Existing proc rules applied the Frost debuff, but its damage bonus and eight-hit charge consumption were missing.

After this change: Periodic Frost damage from the debuff caster receives the native 30% modifier; the matching damage ticks consume its eight charges. Other casters and other schools do not consume them.

## 283848 — Impending Doom

Before: Existing spell filters applied the Shadow debuff, but its damage bonus and five-hit charge consumption were missing.

After this change: Periodic Shadow damage from the debuff caster receives the native 25% modifier; the matching damage ticks consume its five charges. Other casters and direct damage do not consume them.

## Delivery and limits

Includes pending world SQL `rev_20261027_04_wildcard_caster_periodic_damage_taken.sql` for the two charge consumers. Existing parent proc rows, Mystic Enchant rules and script bindings are reused. Earlier card-repair source and migrations remain unchanged and belong in the same future PR.

C++/SQL changed-file codestyle checks passed. Native dispatch/calculation/proc paths and fresh acore_world data were inspected. Compilation and server/gameplay tests were not run under the user's no-compilation restriction; SQL was not applied. All four card repairs remain FIXED_UNVERIFIED. Runtime acceptance must cover caster ownership, school selection, stack/charge lifetime, stacking with other damage modifiers and existing non-card consumers.
