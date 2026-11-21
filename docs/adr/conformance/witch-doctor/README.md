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
| [0009](0009-tiki-splash-joins-the-target-a-ally-list.md) | Tiki Splash joins the target A ally list of dynamic object auras | proposed (owner question); engine file `SpellAuras.cpp` |
| [0010](0010-soul-marionette-stuns-an-enemy-once.md) | Soul Marionette: an enemy already stunned takes the other explosions' damage only | accepted |
| [0011](0011-effigy-concoction-and-godslayer-read-their-spells-radii.md) | Cursed Effigy, Unstable Concoction and Godslayer read their spells' radii | accepted |
| [0012](0012-shadow-effigy-slows-every-enemy-in-its-field.md) | Shadow Effigy slows every enemy in its field radius | accepted |
| [0013](0013-beast-blood-is-cast-by-each-grouped-member-on-itself.md) | Beast Blood is cast by each grouped member on itself | accepted |
| [0014](0014-growing-malice-grows-the-hex-through-aura-271-alone.md) | Growing Malice grows the Hex through aura 271 alone | accepted |
| [0015](0015-dark-effigy-adds-two-enemies-through-its-jump-targets-alone.md) | Dark Effigy adds two enemies through its jump targets alone | accepted; mentor ruling M-58 |
| [0016](0016-overflowing-juju-scales-the-folded-spell-power-coefficient.md) | Overflowing Juju scales the folded spell power coefficient | accepted; mentor ruling M-59, owner question Q-TA-1 |
| [0017](0017-amphibimorph-makes-a-frog-a-beast.md) | Amphibimorph makes a frogged unit a Beast | proposed (owner question); engine file `Unit.cpp` |
| [0018](0018-voodoo-unleashed-cuts-shadow-puppets-by-504607.md) | Voodoo Unleashed cuts Shadow Puppets by 504607's 3 sec | accepted |
| [0019](0019-voodoo-strings-needs-threads-when-bad-juju-is-used.md) | Voodoo Strings needs Puppeteer's Threads on the enemy when Bad Juju is used | accepted |
| [0020](0020-graven-effigy-reaches-enemies-within-20-yd.md) | Graven Effigy reaches enemies within 20 yd | accepted; possible tooltip token slip noted |
| [0021](0021-spirit-eclipse-splash-reaches-5-yd.md) | Spirit Eclipse splash reaches 5 yd | accepted |
