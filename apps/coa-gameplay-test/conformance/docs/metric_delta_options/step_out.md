# Step out (`metric_delta` `step_out`, ADR 1119, provisional)

`step_out` is `{"dx": yd, "after_ms": ms, "hold_ms": ms, "radius": yd, "side": "inside" | "beyond"}`. In the
treatment phase, `after_ms` after the trigger cast at the dummy, the caster is moved `dx` yd along x (at most 20,
the dummy stands on the x axis), held there `hold_ms` and moved back (named point `after_trigger_steps`). Right after
the move and at the end of the hold the scenario reads the caster's distance to the dummy, both heights and both
combat reaches. The verdict (named point `verdict`) is unmeasured unless both reads put the caster at least 0.25 yd
on its `side` of `radius`, measured as the 3D distance less both reaches (`WorldObject::IsWithinDistInMap`);
otherwise the plain judge stands. Absent, the scenario is unchanged.

Use it for an effect that acts only while the caster stays within a range of its target, read once on each side
of the edge (two entries, the inside one the control of the beyond one).

Witch Doctor: Veil of Darkness 802100 `range_inside` and `range_beyond` (the 806473 tick at 1500 ms lands with the
caster 0.5 yd inside 40 yd + both reaches, and not 0.5 yd beyond).
