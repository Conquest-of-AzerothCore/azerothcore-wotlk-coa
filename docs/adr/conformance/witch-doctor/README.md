# Witch Doctor conformance ADRs

The Witch Doctor's (class 13) own conformance decisions: its fixes, their regressions and its class-scoped method
choices. They are numbered inside this folder from 0001, cited as "Witch Doctor ADR 00NN" (in JSON strings without a
link), and never renumbered once published. Decisions that bind every class stay in `docs/adr/` with the shared
numbers ([ADR 0583](../../0583-class-conformance-adrs-live-in-a-per-class-folder.md)).

| ADR | Title | Note |
|---|---|---|
| [0001](0001-spirit-chance-claims-run-set-spirits-in-two-stack-arms.md) | Spirit chance claims run set Spirits in two stack arms | proposed; class half of shared ADR 0662 (provisional number), kind `stack_chance_rate` |
| [0002](0002-gates-and-heal-cuts-run-on-dense-real-triggers.md) | Gates and heal cuts run on dense real triggers | proposed; class half of shared ADRs 0663 and 0664 (provisional numbers), kinds `proc_gate_interval`, `heal_cooldown_cut` |
| [0003](0003-bloodthistle-cauldron-field-refreshes-through-silence.md) | The Bloodthistle Cauldron field refreshes through silence | accepted; Bloodthistle #10643 |
| [0004](0004-potent-mixes-lowers-threat-through-the-threat-percent-aura.md) | Potent Mixes lowers threat through the threat percent aura | accepted |
| [0005](0005-hexfire-adept-transforms-only-the-top-malefic-wrath-rank.md) | Hexfire Adept transforms only the top Malefic Wrath rank | accepted; #12539 |
| [0006](0006-malignant-jinx-silences-the-jinxed-enemy-itself.md) | Malignant Jinx: the jinxed enemy casts the silence on itself | accepted |
| [0007](0007-malicious-golems-reads-golems-vigil.md) | Malicious Golems reads Golem's Vigil | accepted |
| [0008](0008-eye-of-kimbul-mark-removes-and-refuses-stealth-and-invisibility.md) | The Eye of Kimbul mark removes and refuses stealth and invisibility | accepted |
| [0009](0009-tiki-splash-joins-the-target-a-ally-list.md) | Tiki Splash joins the target A ally list of dynamic object auras | accepted (contributor decision 2026-11-22); engine file `SpellAuras.cpp`, gated on Witch Doctor ids |
| [0010](0010-soul-marionette-stuns-an-enemy-once.md) | Soul Marionette: an enemy already stunned takes the other explosions' damage only | accepted |
| [0011](0011-effigy-concoction-and-godslayer-read-their-spells-radii.md) | Cursed Effigy, Unstable Concoction and Godslayer read their spells' radii | accepted |
| [0012](0012-shadow-effigy-slows-every-enemy-in-its-field.md) | Shadow Effigy slows every enemy in its field radius | accepted |
| [0013](0013-beast-blood-is-cast-by-each-grouped-member-on-itself.md) | Beast Blood is cast by each grouped member on itself | accepted |
| [0014](0014-growing-malice-grows-the-hex-through-aura-271-alone.md) | Growing Malice grows the Hex through aura 271 alone | accepted |
| [0015](0015-dark-effigy-adds-two-enemies-through-its-jump-targets-alone.md) | Dark Effigy adds two enemies through its jump targets alone | accepted; mentor ruling M-58 |
| [0016](0016-overflowing-juju-scales-the-folded-spell-power-coefficient.md) | Overflowing Juju scales the folded spell power coefficient | accepted; mentor ruling M-59, amended by 0031 |
| [0017](0017-amphibimorph-makes-a-frog-a-beast.md) | Amphibimorph makes a frogged unit a Beast | accepted (contributor decision 2026-11-22); engine file `Unit.cpp`, gated on Witch Doctor ids |
| [0018](0018-voodoo-unleashed-cuts-shadow-puppets-by-504607.md) | Voodoo Unleashed cuts Shadow Puppets by 504607's 3 sec | accepted |
| [0019](0019-voodoo-strings-needs-threads-when-bad-juju-is-used.md) | Voodoo Strings needs Puppeteer's Threads on the enemy when Bad Juju is used | accepted |
| [0020](0020-graven-effigy-reaches-enemies-within-20-yd.md) | Graven Effigy reaches enemies within 20 yd | accepted; possible tooltip token slip noted |
| [0021](0021-spirit-eclipse-splash-reaches-5-yd.md) | Spirit Eclipse splash reaches 5 yd | accepted |
| [0022](0022-spirit-speed-lasts-while-spirits-are-held.md) | Spirit speed lasts while Spirits are held | accepted; dormant path (M-52) |
| [0023](0023-spirit-out-of-the-bottle-reaches-three-additional-allies.md) | Spirit Out Of The Bottle reaches three additional allies | accepted |
| [0024](0024-voodoo-strings-strikes-total-thirty-percent.md) | Voodoo Strings strikes total 30% over 3 sec | accepted; decision M-70 |
| [0025](0025-slither-makes-ranged-attacks-and-spells-miss.md) | Slither makes ranged attacks and spells miss | accepted (contributor decision 2026-11-22); engine file `Unit.cpp`, gated on Witch Doctor ids |
| [0026](0026-hireeks-jinx-lasts-eight-seconds-against-players.md) | Hir'eek's Jinx lasts eight seconds against players | accepted (contributor decision 2026-11-22); engine file `SpellMgr.cpp`, gated on Witch Doctor ids |
| [0027](0027-spirit-shock-locks-a-creatures-school.md) | Spirit Shock locks a creature's school | accepted |
| [0028](0028-voodoo-cauldron-heals-allies-within-fifteen-yards.md) | Voodoo Cauldron heals allies within 15 yd | accepted |
| [0029](0029-graven-effigy-lengthens-crowd-control.md) | Graven Effigy lengthens crowd control | accepted (contributor decision 2026-11-22); engine file `Unit.cpp`, gated on Witch Doctor ids |
| [0030](0030-soul-marionette-roots-for-eight-seconds.md) | Soul Marionette roots for 8 sec | accepted (contributor decision 2026-11-22) |
| [0031](0031-overflowing-juju-scales-malefic-arrow.md) | Overflowing Juju scales Malefic Arrow | accepted (contributor decision 2026-11-22); amends 0016 |
| [0032](0032-voodoo-fire-strikes-up-to-three-enemies.md) | Voodoo Fire strikes up to three enemies | accepted |
| [0033](0033-mojo-beam-drain-does-not-scale-with-branches.md) | Mojo Beam's drain does not scale with its branches | accepted, needs further investigation |
| [0034](0034-mojo-beam-grows-one-branch-per-tick.md) | Mojo Beam grows one branch per tick, with no cap of 8 | accepted |
| [0035](0035-malefic-arrow-keeps-one-rank-per-malefic-wrath-rank.md) | Malefic Arrow keeps one rank per Malefic Wrath rank | accepted |
