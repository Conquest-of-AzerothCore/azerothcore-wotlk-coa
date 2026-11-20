# Relocate before trigger (`metric_delta` `relocate_before_trigger`, ADR 0713)

`relocate_before_trigger` is `{"dx": yards}`, nonzero and at most 40 yd. Right before every cast of the entry's
`trigger_spell` by the caster, the scenario moves the caster `dx` yd along x from where it stands (the harness
`relocate` step; the dummy stands on +x, so a negative `dx` moves away from it). A charge or leap that carried the
caster to the dummy in the control phase then starts the treatment phase from a distance again. It adds no check.
Absent, the scenario is unchanged.

Witch Hunter: Strategist 681156 `hunt_mana` (Hunt 802006, a charge with a 5 yd minimum range, under 807797).
