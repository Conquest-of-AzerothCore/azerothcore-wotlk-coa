# Summon edge (`behaviour_metric_delta`, `kind: "summon_edge"`, ADR 1111, provisional)

A field or pulse searched around a summon (an idol, effigy or ward) is bracketed at its edge measured from the code's
own centre, the summon. `summon_spell` is cast at the caster and summons `summon_entry`; after `settle_ms` two players
are placed by the harness at that summon (`relocate` with `around_owner`, ADR 1110): on one line along `bearing`
(radians on the world axes, default 0), at the summon's height, `radius` + the summon's combat reach + the player's
combat reach + `inside_yd` (between -2 and -0.25) and + `beyond_yd` (between 0.25 and 2) from it. `role` `ally`
groups both with the caster; `enemy` makes them players of `enemy_player_race` (default 2) at the PvP location, all
three PvP flagged. `learn` lists spells learned before the summon.

`metric` and `fields` name the read: `spell_energize_count` (the players' mana is set to 1 first; the read is the
caster's view of the logs on each player, so `fields` takes `caster_entry` for a summon's energize) counted over the
`wait_ms` window, or `aura` on each player at the end of the window. With `witness` (event reads only) the caster's
own count must rise in the window, or the verdict is unmeasured: the summon did not pulse.

The summon's position and reach and each player's position and reach are read at the start and the end of the window.
The verdict is unmeasured when a player stands less than 0.25 yd on its side of the edge (the 3D distance less the
radius and both reaches), or in a grid cell the search does not visit: `Cell::VisitObjects` visits the cells of the
`radius` square around the summon, and a point within 0.05 yd of a cell edge counts as unvisited. Otherwise the inside
player must be reached (a count of at least 1, or the aura present) and the beyond player never.

Witch Doctor: Spirit Idol 500961 `ally_edge` (Energize 805282 from creature 50106, Allies() within 30 yd) and Shadow
Effigy 505339 `enemy_edge` (the field 504761 of creature 50119 on enemy players within 30 yd).
