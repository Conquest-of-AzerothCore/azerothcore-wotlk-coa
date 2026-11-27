# Bloodmage conformance ADRs

The Bloodmage's (class 20) own conformance decisions: its fixes, their regressions and its class-scoped method choices.
They are numbered inside this folder from 0001, cited as "Bloodmage ADR 00NN" (in JSON strings without a link), and
never renumbered once published. Decisions that bind every class stay in `docs/adr/` with the shared numbers
([ADR 0583](../../0583-class-conformance-adrs-live-in-a-per-class-folder.md)).

| ADR | Title | Note |
|---|---|---|
| [0001](0001-bloodmage-weapon-sets.md) | Bloodmage weapon sets | accepted (provisional number) |
| [0002](0002-bloodmage-base-spells-in-extra-spells.md) | Bloodmage base spells in extra_spells | accepted (provisional number) |
| [0003](0003-owner-ruling-o-9-blood-covenant-uses-max-health-for-cost.md) | Owner ruling O-9: Blood Covenant uses maximum health for cost | accepted (provisional number) |
| [0004](0004-owner-ruling-q-bm-5-bloodmage-native-parry.md) | Owner ruling Q-bm-5: grant native Parry (3127) to Bloodmage | accepted (provisional number) |
| [0005](0005-owner-ruling-q-bm-19-scarlet-delirium-pvp-duration-cap-8-seconds.md) | Owner ruling Q-bm-19: Scarlet Delirium caps PvP Fear duration at 8 seconds | accepted (provisional number) |
| [0006](0006-owner-ruling-q-bm-17-vital-shield-bloodmage-only-school-filter.md) | Owner ruling Q-bm-17: Bloodmage-only Shadow and Nature filter for Vital Shield | accepted (provisional number) |
| [0007](0007-owner-ruling-q-bm-22-fleshcraft-applies-sated-and-suppresses-stray-effects.md) | Owner ruling Q-bm-22: Fleshcraft applies Sated (532125) and suppresses stray DBC effects | accepted (provisional number) |
| [0008](0008-owner-ruling-q-bm-15-bloodmoon-strength-dodge-rating-scaling.md) | Owner ruling Q-bm-15 / O-11: Bloodmoon Strength scales with 0.25 of dodge rating | accepted (provisional number) |
| [0009](0009-bloodmage-vitality-scaling-consumptions-and-bonus-data.md) | Bloodmage vitality consumptions, Torture leech, stat scaling, raid groups, and bonus data | accepted (provisional number) |
| [0010](0010-fearmonger-uses-tick-rate-and-torment-periodic-crit.md) | Fearmonger uses 2308 ms tick rate (O-24) and Taldaram's Torment periodic ticks can crit | accepted (provisional number) |
| [0011](0011-ultra-instinct-three-percent-and-non-refreshing-duration-cut.md) | Owner ruling Q-bm-8: Ultra Instinct grants +3% crit damage and cuts remaining duration without refresh | accepted (provisional number) |
| [0012](0012-corrupted-blood-applies-to-all-bloodmage-damage.md) | Owner ruling Q-bm-13: Corrupted Blood increases all Bloodmage damage against afflicted targets | accepted (provisional number) |
| [0013](0013-red-thirst-aligns-all-effects-to-40-yards.md) | Owner ruling Q-bm-20: Red Thirst aligns melee/ranged haste and Worn Out radius to 40 yards | accepted (provisional number) |
| [0014](0014-sanguine-rupture-phantom-aura-and-o37-base-damage.md) | Owner ruling Q-bm-16 and Bloodwell Eruption: Sanguine Rupture phantom aura, O-37 base values, and crit mask | accepted (provisional number) |
| [0015](0015-bloodthorns-single-spell-power-application.md) | Owner ruling Q-bm-3: Bloodthorns applies +3.5% Shadow SP once without double-dipping | accepted (provisional number) |
| [0016](0016-shadow-vigil-updates-target-temp-threat-modifiers.md) | Owner ruling Q-bm-17: Shadow Vigil updates target temporary threat modifiers in Bloodmage C++ | accepted (provisional number) |
| [0017](0017-aortic-aegis-fans-cast-rank-blood-veil-to-target-subgroup.md) | Owner ruling Q-bm-22: Aortic Aegis fans cast-rank Blood Veil to the target's subgroup | accepted (provisional number) |
| [0018](0018-transgression-and-final-embrace-cursed-form-contracts.md) | Transgression Demon creature type and Final Embrace Blood Curse gate and Crimson Maw swap | accepted (provisional number) |
| [0019](0019-accursed-form-agility-ap-and-marrowbite-proc.md) | Accursed Form applies 804699 Agility-to-AP and procs Marrowbite 504553 | accepted (provisional number) |
| [0020](0020-liquify-pacifies-melee-and-bloodmoon-power-cleanses-on-apply.md) | Liquify pacifies melee attacks and Bloodmoon Power cleanses negative effects on apply | accepted (provisional number) |
| [0021](0021-blood-bond-redirect-blood-howl-taunt-and-blood-mark-sync.md) | Blood Bond threat redirect, Blood Howl empty-threat taunt, and Blood Mark aura sync | accepted (provisional number) |
| [0022](0022-blood-trails-clotting-vampyr-bite-acuity-and-animated-blood.md) | Acuity consumption, Trail of Blood gate, Animated Blood heal, Vampyr Bite interrupt, and Clotting gate | accepted (provisional number) |
| [0023](0023-darkfallen-lament-blood-feast-cup-runneth-over-and-proc-fixes.md) | Darkfallen Lament cap and immunity, Blood Feast burst, Cup Runneth Over, and proc updates | accepted (provisional number) |
| [0024](0024-bloodmage-family-26-class-mask-corrections.md) | Bloodmage family-26 EffectSpellClassMask corrections (Blood Plague, Gore Barrage, Eternal Curse, Dark Blood) | accepted (provisional number) |
| [0030](0030-black-heart-instant-rage-on-vampyrs-kiss-cast.md) | Owner ruling Q-bm-6: Black Heart grants 20% maximum Rage instantly on Vampyr's Kiss cast | accepted (provisional number) |
| [0031](0031-monstrous-howl-allows-750ms-gcd-on-all-six-charges.md) | Owner ruling Q-bm-9: Monstrous Howl lowers Bloodfang Bite GCD to 750 ms across all six charges | accepted (provisional number) |
| [0032](0032-eyes-in-the-night-3s-icd-and-guaranteed-direct-threat.md) | Owner ruling Q-bm-14: Eyes In The Night uses a 3 sec ICD and generates direct threat | accepted (provisional number) |
| [0033](0033-reave-flat-after-weapon-percent-and-condition-spell-ids.md) | Owner ruling Q-bm-21: Reave adds flat damage after weapon percent and fixes swapped bonus spell IDs | accepted (provisional number) |
| [0034](0034-bloodsores-consumption-and-blood-lord-retention.md) | Bloodsores consumption on Sanguine Rupture and Bloodmoon Blast with Blood Lord retention | accepted (provisional number) |
| [0035](0035-vampiric-fang-removes-wretched.md) | Vampiric Fang removes Wretched from Essence Harvester | accepted (provisional number) |
| [0036](0036-festering-maw-triggers-only-from-bite-wound-heals.md) | Festering Maw triggers Lunge cooldown reduction only from Bite Wound heals | accepted (provisional number) |
| [0037](0037-shadow-strength-howl-cast-aoe-damage.md) | Shadow Strength deals AoE Shadow damage on Howl casts | accepted (provisional number) |
| [0038](0038-sacrificial-rite-cursed-blood-attacker-damage.md) | Sacrificial Rite Cursed Blood deals Shadow damage when cursed attackers deal damage | accepted (provisional number) |
| [0039](0039-owner-rulings-server-kept-no-client-text-change.md) | Owner rulings Q-bm-7 and Q-bm-18: server behaviour kept without client text changes | accepted |
| [0040](0040-owner-rulings-server-kept-client-text-updated.md) | Owner rulings Q-bm-1, Q-bm-2, Q-bm-4, Q-bm-11, and Q-bm-12: server behaviour kept with updated client texts | accepted |
| [0041](0041-bloodmage-client-text-corrections-and-ledger-alignment.md) | Bloodmage client text overrides, candidate MPQ tooling, and ledger alignment | accepted |
