# Block charge strikes (`behaviour_metric_delta`, `kind: "block_charge_strikes"`, ADR 1195, provisional)

How many real blocks an aura with block charges lasts, without and with a talent that adds blocks. `shield` is equipped
with Block 107 learned, and each arm sets `set_combat_avoidance` with `block: 100` and dodge and parry at 0 (owner
ruling O-20). The arm casts `aura`, then a passive striker casts `strike_spell` at the caster one strike at a time,
one strike more than the expected count; `aura` and the blocked hit count (`spell_damage_count` with `blocked`) are
read after each strike. Expected: the aura ends on block `ProcCharges(aura)` in the control and on block
`ProcCharges(aura) + spell Effect[effect]` once `spell` is learned.

Judge: every read present, the aura present at the start of each arm and exactly one blocked hit per strike, else
unmeasured; an aura that does not end on a block, or ends on another count, alerts. Sun Cleric: Paying The Tithe
680647 and 681468 on Seraphic Bulwark 560095 (Speed Slash 2118233 strikes, shield 231296).

Optional `require_block: false` (ADR 1322; default `true`, byte-identical when omitted) tests non-shield charge-consuming
auras: skips learning Block 107 and equipping a shield (omits `shield`), sets `set_combat_avoidance` to `dodge: 0,
parry: 0, block: 0`, reads `spell_damage_count` without `blocked: true`, and judges `hits` per strike instead of
`blocks`. Optional `striker_untriggered: true` (default `false`) sends `triggered: false` on the striker casts for auras
whose `spell_proc` skips triggered spells; optional `striker_auras` sets fixture auras on the striker (such as 803393 for
+100% hit chance). Bloodmage: No Mercy 704660 on Thick Pelt 556233 (`require_block: false`, Impale 34580 untriggered
with striker aura 803393).
