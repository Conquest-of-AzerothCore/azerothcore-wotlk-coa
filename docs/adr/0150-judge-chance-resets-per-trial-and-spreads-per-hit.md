# 0150. Judge chance-triggered resets per trial and aura spreads per hit

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0125 (behaviour judges) and ADR 0144 (custom mechanics by behaviour)

## Context

Two Templar head claims of the "scripted spells not behaviour proven" work item had no behaviour check that reaches
their class script path:

- Warrior of Dawn 560648, "Melee damage dealt now has a $h% chance to reset the cooldown and reduce the Energy cost
  of your next Argent Blade by $561156s1%." Its proc rate was measured, but the reset and the reduced cost were
  not: the labels were `unmodelled` and `not_measured`. The script resets the cooldown and casts 561156 in the same
  proc (`AscensionTemplarEvents.cpp:71-72`, `:152-154`); 561167's effect 195 is not on the path.
- Holy Tempest 301339, "Damage dealt by Righteous Tempest now spreads Condemn on affected enemies to a nearby enemy."
  The spread entry waited the whole Righteous Tempest and offered no dummy beyond the stated one, so its count was
  `insufficient_trials`.

A chance roll cannot open a cost gate on demand, and a cooldown that recovers in 5 s cannot wait for an auto-attack
proc. A spread read after five ticks counts five hits, not one.

## Options

1. Set 561156 directly through a cost gate's `talent_aura`. This exercises the generic modifier, not the script's
   reset; mech condition 4 forbids it for a head claim.
2. Attack until the proc appears, then gate the next cast. The proc is random and the cooldown short, so the wait
   cannot be bounded.
3. Judge each cast as its own trial: cast the reset spell from a reset cooldown, read its cooldown, the power left
   and the proc count; correlate them per trial.
4. For the spread, read after the first hit of the periodic trigger on the primary dummy, with one dummy beyond the
   stated count and every extra dummy beyond the trigger's reach.

## Decision

Options 3 and 4.

- New kind `proc_reset`, check `behaviour_proc_reset`, behaviour evidence. 20 casts without the passive and 100
  with it, each from a reset cooldown and twice the cost, regeneration off. The judge requires, in every trial: a
  fired trial reads no cooldown, a quiet one the cooldown still running, the cast after a fired trial costs the
  marker's one `SPELLMOD_COST` percent of the cost and every other cast the full cost, and no trial fires without
  the passive. Any fault is an `alert`; fewer than 3 fired, quiet or discounted trials is `insufficient_trials`.
  It relies on `Spell::_cast` sending the cooldown (Spell.cpp:4029) before the hits (:4134).
- Aura spread `first_tick: true`: one seed and cast per phase, the extra dummies placed between 5 yd beyond the
  trigger's radius and 0.5 yd inside the spread radius of the primary, `expected + 1` of them (headroom 1), read half
  a period after the cast. The primary dummy's hits of the trigger spell are read around the cast, and a read after
  any count other than one is `unmeasured`.

## Consequences

- Warrior of Dawn's reset and next-cast cost are judged through the class script; with the existing proc rate the
  clause is behaviour proven.
- Holy Tempest reads one copy on one of two dummies after one hit (diagnostic 20261111-171739). Righteous Tempest
  807274 hits at its cast as well as every 1000 ms, though its `AttributesEx5` has no initial-period flag; the hit
  guard keeps the read honest if that changes.
- The proc-reset scenario lasts about 3 minutes of game time; it fits one scenario.
