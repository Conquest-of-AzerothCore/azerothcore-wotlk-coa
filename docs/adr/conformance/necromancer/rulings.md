# Necromancer conformance rulings

The owner rulings and method decisions for the Necromancer (class 23). The rules that bind every class, the Templar
precedents and the meaning of the columns ("Who decided", "Recorded in") are on the common page,
[class-conformance-rulings.md](../../../coa/class-conformance-rulings.md). "Recorded in" names the Necromancer ADR
in this folder that states or applies the decision; "No ADR found" means this page is its record.

Each is binding for the Necromancer only. The owner answered the 27 Necromancer owner questions on 2026-11-13 between
07:27 and 09:10 (UTC+1); the mentor relayed the answers and the actions. An owner ruling is the expected behaviour and
counts as the independent source of G-37 (criterion 3). A ruling that asks for a server change is not yet applied: it
still needs a fix note with the cause read, the narrowest change, a regression and an ADR.

## 1. No server change (conformant by ruling)

| Date, author | Spell and question | Ruling | Owner's words | Recorded in |
|---|---|---|---|---|
| 2026-11-13, owner, through the mentor | Abomination slow (Q-a1-2) | No slow; the text of 500335 loses the slow | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Putrid Claws base (Q-a1-5b) | No base amount: 10% of the hit | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Putrid Claws rate (Q-a1-5c) | Every hit, as the server does (after the Tomb King scope fix) | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Plaguefather (Q-a1-9) | Every damaging hit, as the server does | not recorded | [Necromancer ADR 0002](0002-plaguefather-emits-zombie-plague-on-every-damaging-hit.md) |
| 2026-11-13, owner, through the mentor | Diabolical "Casting spells" (Q-a2-2) | Necromancer spells only, as the server does | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Chomp and Rotling (Q-b1-1) | Per-level scaling is intended; the texts of 707283 and 806086 are aligned | "texte à aligner" ("text to align") | No ADR found |
| 2026-11-13, owner, through the mentor | Protect threat (Q-b2b-3) | The stock flat threat does not count | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Blight expunge (Q-b3b-2) | Keep 670; the text moves from $500217s2 to $500459s2 | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Blight six hits (Q-b3b-3) | Keep six hits; the text states the cast hit | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Frozen Bodies not consumed (Q-ma-1) | Keep it unconsumed; the text is aligned | "mais si on consomme le proc une fois arrivé à 10 stacks, comment ça se passe pour recréer 10 stacks et avoir de nouveau le proc pour glacial impact ? l'interface ne saura plus à combien de stacks on est non ?" ("but if the proc is consumed at 10 stacks, how do we build 10 stacks again for a new Glacial Impact proc? The interface would no longer know the stack count, would it?") | No ADR found |
| 2026-11-13, owner, through the mentor | Army of the North 561138 (Q-c1-1; claim 133.0) | The engine attack table: hits that reach the crit roll crit; a blocked, missed, dodged or parried hit is not a crit; the text states it | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Heartchill (Q-rb-1) | The engine convention x1.8 | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Frost Runes 705750 (Q-mb-3; claim 191.0) | Keep the server's 5% (705750's own chance); the text's $706473h token (15%, Death Runes) becomes 705750's own chance. Live players proc at about 3.4% per magic hit | not recorded | No ADR found |
| 2026-11-13, owner, through the mentor | Ghoul healing done -30% (Q-a1-6; claims 64, 67) | Keep 805290 Effect[1] (-30%); the texts of Raise: Ghoul's auto-attack heal and the Command heal state 70% of the current values (G-8). No heal curve: the owner first chose to remove the -30%, then reversed it (G-43) | "si c'est pour un niveau 60 pourquoi pas, on garde le -30%" ("for level 60, why not, we keep the -30%") | No ADR found |

## 2. Server changes ruled by the owner

| Date, author | Spell and question | Ruling | Owner's words | Recorded in |
|---|---|---|---|---|
| 2026-11-13, owner, through the mentor | Decaying Colossus (Q-a1-3) | Apply the 25% split: the caster takes 25% less and the Colossus takes it | not recorded | [Necromancer ADR 0016](0016-the-decaying-colossus-takes-a-quarter-of-its-casters-damage.md) |
| 2026-11-13, owner, through the mentor | Banshee drain (Q-a1-4) | The player's maximum mana caps the drain, not the Banshee's | not recorded | [Necromancer ADR 0017](0017-the-banshees-command-drain-is-capped-by-the-players-maximum-mana.md) |
| 2026-11-13, owner, through the mentor | Tomb King Putrid Claws baseline (Q-a1-5) | The claw is 10% of the post-mitigation hit, then resisted as a Plague hit (0.088 of the hit on the dummy) | not recorded | [Necromancer ADR 0018](0018-putrid-claws-copies-10-percent-of-the-hit-without-its-per-level-points.md) |
| 2026-11-13, owner, through the mentor | Abomination cloud (Q-a1-7) | The cloud fires only when the Abomination is attacked. The live logs fit this in 7% of hits only; the owner ruled it | not recorded | Pending (fix note) |
| 2026-11-13, owner, through the mentor | Bone Toss (Q-a1-8) | The Plaguefather casts Bone Toss 704706 on its current target every 1 s | "toute les 1sec" ("every 1 s") | Pending (fix note) |
| 2026-11-13, owner, through the mentor | Diabolical duration (Q-a2-1) | Stacks last 20 s (706504), not 30 s | not recorded | [Necromancer ADR 0019](0019-diabolical-stacks-last-20-seconds.md) |
| 2026-11-13, owner, through the mentor | Glacial Impact (Q-a3-1) | Always damage x (1 + the caster's Frost spell crit chance); the hit can still crit as usual, guaranteed under Glacier Lord. The formula is the owner's; the tooltip gives no number | "Pour moi les degats doivent augmenter en fonction du pourcentage de coup critique des sorts que l'on a. Donc si on a 25% de critique, cela augmente de 25% les dégâts, etc.." ("For me the damage should grow with our spell crit percentage: 25% crit adds 25% damage, and so on") | Pending (fix note) |
| 2026-11-13, owner, through the mentor | Foul Invocation (Q-b1-3) | Total Stamina | not recorded | [Necromancer ADR 0020](0020-foul-invocation-raises-total-stamina.md) |
| 2026-11-13, owner, through the mentor | Crypt Swarm slow (Q-b3b-1) | The slow is meant | "je ne vois pas le rapport entre Crypt Swarm et le passif ??" ("I do not see the link between Crypt Swarm and the passive??"), answered by the mentor: the $?s92123 condition names the Animation passive | Pending (fix note) |
| 2026-11-13, owner, through the mentor | March of the Dead schools (Q-b3b-6) | The spell's own schools (mask 40) | not recorded | [Necromancer ADR 0021](0021-march-of-the-dead-scales-with-plague-spell-power.md) |
| 2026-11-13, owner, through the mentor | Frozen Bodies stack bonus (Q-ma-2) | A single +3% per stack, as the tooltip says | "c'est peut etre un bonus caché donné par le live, mais on va s'en tenir à la tooltip, et on buffera si besoin plus tard" ("it may be a hidden live bonus, but we keep to the tooltip and buff later if needed") | [Necromancer ADR 0022](0022-a-frozen-bodies-stack-adds-3-percent-once.md) |
| 2026-11-13, owner, through the mentor | Parasite Plague 560730 (Q-mb-2; claim 123.0) | Any damage dealt rolls, as the tooltip says, not only periodic damage (the live logs lean to periodic only; the owner ruled for the tooltip) | not recorded | [Necromancer ADR 0015](0015-parasite-plague-rolls-on-every-own-damaging-hit.md) |
| 2026-11-13, owner, through the mentor | Bone and Frozen Reliquaries (Q-mb-1) | Both items share the healing and mana potion cooldown (category 5004). The owner authorized the item SQL | "Ici pour moi il faudrait que ces sorts partagent leur CD avec les consommables eéquivalent style potion de soin et de mana par exemple" ("these should share their cooldown with the equivalent consumables, such as healing and mana potions") | Pending (fix note) |

## 3. Scope and tools

| Date, author | Question | Ruling | Owner's words | Recorded in |
|---|---|---|---|---|
| 2026-11-13, owner, through the mentor | Resilient Constitution 552011 (Q-n1) | In scope: enter it in the ledger and test it against a player attacker | "Il faut tester et valider ce passif" ("this passive must be tested and validated") | No ADR found |
| 2026-11-13, owner, through the mentor | Minion "Weapon Damage" (Q-b2b-4) | Fund the tool extension, after research in the live logs: does Command: Skeletal Warriors 570042 track the player's weapon or the Warrior's? | "peut etre parles t-on des degats de l'arme du joueur ?" ("perhaps it means the player's weapon damage?") | No ADR found |
| 2026-11-13, owner, through the mentor | Chilling Presence (Q-b3b-5) | Run the pooled proof (G-20 step 2) | not recorded | No ADR found |

## 4. Open

None.
