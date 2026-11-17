# Caster aura gate (`behaviour_cast_gate`, `kind: "caster_aura_gate"`, ADR 0694)

A spell whose DBC `CasterAuraSpell` must be on the caster. The entry's spell is attempted at the dummy (placed by its
range) with that aura removed, which must be refused with SPELL_FAILED_CASTER_AURASTATE (22), then with the aura set
by harness `set_aura` (the gate fixture), which must succeed. Unlike `cast_gate`, the blocked attempt sets no
required aura.

With `crit_ability` and `force_crit` (an earned arm), the spells of `earned_learn` are learned, the aura is removed,
`crit_ability` is cast at the dummy with every hit forced to crit, the aura must be on the caster (1) and an attempt
with no fixture must succeed (0). The same crit is made once before, with only the spell and the crit ability
learned, and its aura read is recorded with the `knows_spell` reads of `known_probes` at both stages
(`<spell> behaviour_cast_gate probe ...`), so a run shows whether the learned rank alone earns the aura.

Quickdraw 806851: CasterAuraSpell 680244, earned by a forced Darkslayer 804179 crit, with the first rank 804193
learned for the earned arm and probed.
