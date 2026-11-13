# Necromancer conformance ADRs

The Necromancer's (class 23) own conformance decisions: its fixes, their regressions and its class-scoped method
choices. They are numbered inside this folder, cited as "Necromancer ADR 00NN" (in JSON strings without a link), and
never renumbered once published. Decisions that bind every class stay in `docs/adr/` with the shared numbers
([ADR 0583](../../0583-class-conformance-adrs-live-in-a-per-class-folder.md)). The owner's Necromancer rulings are in
[rulings.md](rulings.md).

Moved on 2026-11-13 from `docs/adr/`, in the order of their old numbers. A mixed ADR was split before publication: its
class half is here, its tool half keeps the old number in `docs/adr/`.

| ADR | Old number | Title | Note |
|---|---|---|---|
| [0001](0001-ghoul-frenzy-heal-scales-with-intellect-and-spell-power.md) | 0322 | Ghoul Frenzy's heal scales with Intellect and spell power | moved |
| [0002](0002-plaguefather-emits-zombie-plague-on-every-damaging-hit.md) | 0324 | The Plaguefather emits Zombie Plague on every damaging hit | moved |
| [0003](0003-necromancer-minion-procs-roll-on-the-minions-copy-of-the-talent.md) | 0344 | Necromancer minion procs roll on the minion's copy of the talent | moved |
| [0004](0004-necromancer-summons-only-auras-recalculate-through-the-owned-aura.md) | 0345 | Necromancer summons-only auras recalculate through the owned aura | moved |
| [0005](0005-putricides-formula-blasts-once-per-proc.md) | 0350 | Putricide's Formula blasts once per proc | moved |
| [0006](0006-plague-of-undeath-dispel-reaches-the-dispelled-unit.md) | 0382 | Plague of Undeath's dispel reaches the dispelled unit | moved |
| [0007](0007-the-skeletal-rogue-command-strikes-two-to-five-times.md) | 0383 | The Skeletal Rogue's Command strikes 2 to 5 times | class half; tool half stays shared as [ADR 0383](../../0383-strike-bursts-read-minion-hits-around-a-scripted-strike.md) |
| [0008](0008-bone-reliquary-heals-only-the-missing-health-it-states.md) | 0406 | Bone Reliquary heals only the missing health it states | moved |
| [0009](0009-cast-while-casting-necromancer-spells-roll-the-on-cast-talents.md) | 0408 | Cast-while-casting Necromancer spells roll the on-cast talents | moved |
| [0010](0010-damnation-doubles-its-increase-below-35-percent.md) | 0409 | Damnation doubles its increase below 35% health | moved |
| [0011](0011-bonefreeze-takes-the-damage-interrupt-outside-the-family-contracts.md) | 0421 | Bonefreeze takes the damage interrupt outside the family contracts | moved |
| [0012](0012-flesh-to-worms-ticks-can-critically-strike.md) | 0442 | Flesh to Worms's ticks can critically strike | moved |
| [0013](0013-plague-horde-is-cast-by-the-minion-on-itself.md) | 0483 | Plague Horde is cast by the minion on itself | moved |
| [0014](0014-tomb-king-claws-copy-only-other-minions-hits.md) | 0486 | Tomb King claws copy only other minions' hits | moved |
| [0015](0015-parasite-plague-rolls-on-every-own-damaging-hit.md) | 0496 | Parasite Plague rolls on every own damaging hit | moved |
| [0016](0016-the-decaying-colossus-takes-a-quarter-of-its-casters-damage.md) | 0520 | The Decaying Colossus takes a quarter of its caster's damage | moved |
| [0017](0017-the-banshees-command-drain-is-capped-by-the-players-maximum-mana.md) | 0521 | The Banshee's Command drain is capped by the player's maximum mana | moved |
| [0018](0018-putrid-claws-copies-10-percent-of-the-hit-without-its-per-level-points.md) | 0522 | Putrid Claws copies 10% of the hit without its per-level points | moved |
| [0019](0019-diabolical-stacks-last-20-seconds.md) | 0523 | Diabolical stacks last 20 seconds | moved |
| [0020](0020-foul-invocation-raises-total-stamina.md) | 0524 | Foul Invocation raises total Stamina | moved |
| [0021](0021-march-of-the-dead-scales-with-shadow-and-nature-spell-power.md) | 0525 | March of the Dead scales with Shadow and Nature spell power | moved |
| [0022](0022-a-frozen-bodies-stack-adds-3-percent-once.md) | 0526 | A Frozen Bodies stack adds 3% once | moved |
| [0023](0023-the-abomination-disease-cloud-fires-when-the-abomination-takes-damage.md) | 0530 | The Abomination's disease cloud fires when the Abomination takes damage | class half; tool half stays shared as [ADR 0530](../../0530-a-strike-may-target-an-owned-creature.md) |
| [0024](0024-the-plaguefather-casts-bone-toss-on-its-target-every-second.md) | 0531 | The Plaguefather casts Bone Toss on its target every second | moved |
| [0025](0025-crypt-swarm-summoning-adept-slow-lasts-three-seconds.md) | 0532 | Crypt Swarm's Summoning Adept slow lasts three seconds | moved |
| [0026](0026-glacial-impact-damage-grows-with-the-caster-frost-spell-crit-chance.md) | 0533 | Glacial Impact damage grows with the caster's Frost spell crit chance | class half; tool half stays shared as [ADR 0533](../../0533-a-hit-ratio-arm-may-set-its-aura-amounts.md) |
| [0027](0027-the-bone-and-frozen-reliquaries-share-the-potion-cooldown-pool.md) | 0534 | The Bone and Frozen Reliquaries share the potion cooldown pool | class half; tool half stays shared as [ADR 0534](../../0534-an-item-cooldown-gate-may-read-a-pool-held-through-combat.md) |
| [0028](0028-a-soulfreeze-chain-is-read-alone-on-a-frozen-dummy.md) | 0538 | A Soulfreeze chain is read alone on a frozen dummy | moved |
| [0029](0029-command-skeletal-warriors-doubles-the-weapon-roll.md) | 0547 | Command: Skeletal Warriors doubles the weapon roll, not the flat part | class half; tool half stays shared as [ADR 0547](../../0547-a-minion-strike-ratio-may-take-off-a-flat-part.md) |
| [0030](0030-mana-drains-and-burns-reach-a-necromancers-mana-pool.md) | 0561 | Mana drains and burns reach a Necromancer's mana pool | class half; tool half stays shared as [ADR 0561](../../0561-metric-delta-may-set-the-enemy-player-class.md) |
| [0031](0031-raising-the-kirin-tor-refunds-a-fixed-10-runic-power.md) | 0562 | Raising the Kirin Tor refunds a fixed 10 Runic Power | moved |
| [0032](0032-frozen-bodies-ten-stack-crit-has-no-second-multiplier.md) | 0563 | Frozen Bodies' 10-stack Glacial Impact crits without a second 1.5x | moved |
| [0040](0040-necromancer-area-radii-are-bracketed-at-their-edge.md) | - | Necromancer area radii are bracketed at their edge | new |
| [0041](0041-march-of-the-dead-slow-is-timed-from-the-last-explosion.md) | - | March of the Dead's slow is timed from the last explosion | new |
| [0042](0042-transfer-life-range-and-the-bone-construct-speed.md) | - | Transfer Life's range and the Bone Construct's speed | new |
| [0043](0043-graveyard-leaves-one-corpse-per-raised-undead.md) | - | Graveyard leaves one corpse per raised Undead | new |
| [0044](0044-the-hook-halt-waits-for-an-enemy-movement-order.md) | - | The Hook's halt waits for an enemy movement order | new, superseded by ADR 0604 |
| [0045](0045-dominion-of-frost-gate-is-read-with-two-minions.md) | - | The Dominion of Frost gate is read with two minions | new |
| [0046](0046-study-of-death-cut-is-bracketed-by-repeated-casts.md) | - | The Study of Death cut is bracketed by repeated casts | new |
| [0050](0050-command-bonefreeze-casts-once-at-its-target.md) | - | Command: Bonefreeze casts once at its target | new |
| [0051](0051-entomb-physical-immunity-is-measured-on-an-enemy-player.md) | - | Entomb's Physical immunity is measured on an enemy player | new |
| [0052](0052-underking-random-pick-is-attributed-per-cycle.md) | - | The Underking random pick is attributed per cycle | new |
