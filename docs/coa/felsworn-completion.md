# Felsworn completion policy — 2026-09-09

This is a local reconstruction from the pinned copied-client records and recovered changelog,
not the official backend. Source package only; installation and gameplay acceptance are separate.
The audit's 131 findings have 127 new/extended implementations and four retained mechanisms.
See the [release history](local-release-state.md) for later integration.

Felfury remains capped at six, with the existing two-stack spender gate and existing cost exemptions.
Generated Felfury drives Fury of Archimonde (ten generated points), Felspill and Demonic Blood,
including generation at capacity. Inner Demon consumes the available stacks for five seconds each.
Its selected appearance is preserved; otherwise the zero-display custom form falls back to native
Metamorphosis display25277. Form-bound talents and cloth/leather Demon Hide follow entry/exit.

Banes are exclusive per caster on each target; Pacts are exclusive on their owner. Other casters'
auras remain. Actual copied damage/healing cannot crit or receive a second set of damage modifiers.
Cripple spreading preserves the existing amount, remaining duration and next periodic tick.
Reapplied next-cast buffs receive a new generation; an older cast cannot remove the replacement.

Carve prepares in ten quarter-second steps, releases a normalized hit with each equipped hand,
and loses ten percentage points per additional target down to20%. The local weapon-percent rule
is20 + steps*(15 +0.265306*level); a full channel reaches the recovered level-dependent endpoint.
Grommash's critical bonus rises with preparation. Only the corresponding talents enable a full-channel
Felfury refund, dodge or the next instant multi-target Fireball. Fury of the Illidari makes six assaults
at500ms, chooses visible attackable targets, uses learned Twin Slice ranks and grants one Felfury per assault.

Archimonde's Wrath captures Energy before the native cost and adds its chance before one native critical
roll. Both Azzinoth hands, Carve release and delayed Sunder explosions retain that original snapshot.
Sargeras Embrace allows only Fireball/Ruin during its active channel, makes them instant and refunds
Energy. Its one damage tick occurs at the native5500ms endpoint, without an initial damage tick.

Doomstride checks full health and its ten-second lockout at the actual negative-debuff launch,
independently of UI refresh. It applies to pure Magic/Curse debuffs. Ordinary misses/immunity do not
consume it. Consume Magic damage requires a successful native buff steal; Felbreak mana drain requires
an interrupted cast. Fel Bargain consumes pairs of Energy, healing1% maximum health per pair. Manafeed
heals only mana actually removed. Agonizing Presence defers25% monster Physical damage into five payments
and reduces outgoing PvE damage by10%; remaining debt settles before logout persistence. Controlled pets
and player attackers do not enter that stagger path. Tyrannical Resolve absorbs half each incoming hit
up to one maximum-health pool, taunts nearby enemies and releases leech when it ends.

Where no coefficient was recovered, the local policy is explicit: Felcaked/Felblade add15%/20% Agility;
Burning Commander adds50% AP armor and5% AP resistance. Resolve's retaliation is1% maximum health per
received hit, capped at50% per enemy. Sunder makes three explosions along the facing direction at4/11/18yd,
300ms apart, with split damage and persistent ground damage; Pure Hatred adds explosions after2/4sec.
Betrayal records up to30 completed enemy casts, keeps its original deadline and releases the accumulated
base damage at expiry. Infernal Ruin counts successful casts. Illidari Barrier respects its exhaustion.

Infernal uses installed native display169 at scale0.65, half owner health, owner armor and a two-second
swing. Its damage basis is2*level +10% AP +15% max(Fire,Shadow SP), with80–120% weapon range and one-second
stat refresh. Lifetime is15sec (16sec for the Inner Demon extended summon); owner loss/death/map separation
ends it. Ten Fel Rifts use new private goober entries9000140–9000149 and native portal displays. Destinations
are pinned from the local game_tele table. Use requires the owner or same raid/party, same phase, proximity,
alive and out of combat. Existing portal templates are preserved.

[SQL05](../../data/sql/updates/pending_db_world/rev_20260909_05_felsworn_completion.sql)
contains 65 coefficient slots, 121 exact bindings, 38 combat proc rows and 12
guarded template/model inserts. Man'ari joins native Mark/Gift subgroup1078
(nested in1089); earlier raid groups remain.
Before installation, reject conflicting Infernal/model/rift definitions. Applied SQL is immutable.
No client patch or server DBC change is needed for Felsworn. Preserve the separate pending Necromancer
and Templar UI candidate and their SQL03/04. Original Ranger Elude files remain byte-identical.
