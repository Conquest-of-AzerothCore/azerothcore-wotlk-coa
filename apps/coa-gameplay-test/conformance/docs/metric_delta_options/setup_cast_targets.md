# Setup cast targets (`metric_delta` `setup_cast_targets`, ADR 1256)

`setup_cast_targets` is a list of scenario units (`caster`, `dummy`, `enemy`, `corpse`), one per entry of
`setup_casts`, in the same order. Each setup cast is made at its own unit instead of `setup_target` (or the entry's
target). The list has the length of `setup_casts`; the option is refused with `setup_target`, `gate_cast` or
`attack_swings`. A unit the scenario does not otherwise hold needs it there (`select_dummy` for the dummy). Absent, the
scenario is unchanged.

Named points: `setup_cast_target(spec, value, index)` (new, read where the setup cast step is built), `fixtures`
(contract sentence).

Felsworn: Demonic Embrace 520257 `below_six` (Burning Hatred 805239 at the caster, Sargeron Smite 802060 and Bane of Fire
707901 at the dummy: five Felfury).
