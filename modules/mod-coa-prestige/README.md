# mod-coa-prestige

Chromie's Prestige Mode for Conquest of Azeroth. A character at level 60 asks Chromie to wind back
time. It returns to level 1 and levels again with an experience bonus. Its specialization stays
locked until it reaches 60 again, and every activation pays the Prestige rewards.

## What the client expects

The client carries the whole interface, so this module is server-side only. It supplies what each
client piece reads:

- **The Prestige window.** `AscensionUI/Gossips/PrestigeMode.lua` redirects the gossip of creature
  178081 to its own window and finds its buttons by exact option text: `I would like to prestige!`,
  `I would like to purchase Prestige items!` and `GOSSIP_ACTION_EXPERIENCE_ITEMS`. Chromie offers
  those three options, in that order: activation, her 104 Prestige offers, and the Experience Items
  list (vendor entry 990782).
- **`GetPrestigeLevel()`.** Extensions.dll returns slots 2 and 3 of the table that
  `SMSG_UPDATE_OBJECT_ADDON` (0x0578) fills. The module sends the character's Prestige level and the
  account total at login, again once a reconnecting client is back on the map, on every map change,
  when Chromie is opened and after an activation.
- **`C_Player:IsPrestiged()`.** It is `HasAura(9930831)`, and mod-coa-challenges gates its Prestige
  trials on the same aura. The character carries that aura while Prestige Mode is active.
- **The "Prestige 1..10" achievements.** They count kill credit of creature 888101. Each activation
  grants one credit.

## Activation

Chromie refuses unless all of these hold:
- the character is a Conquest of Azeroth class at `CoAPrestige.RequiredLevel`;
- it has a specialization;
- it is alive, out of combat, not travelling and not in an instance.

Then, in this order:
1. The action bar's spells are remembered.
2. Exotic hunter pets are deleted across every stable slot. Other pets, including one put away by a
   mount, and totems are dismissed.
3. The quest log is emptied, and every ordinary zone or dungeon quest up to the Prestige level may be
   done again, including quests that scale with the character. Class, profession, raid, PvP, event and
   repeating quests stay done.
4. The class's talents are forgotten (`ForgetAscensionClassTalents`), including the stored class-tree
   and active-specialization builds. The builds of other specializations are kept.
5. Upgraded ranks above level 1 are removed. The character goes to level 1 through
   `Player::GiveLevel`, whose CoA progression pass removes the class abilities that level 1 does not
   allow. The rank left below a removed one is learned again, so it can be cast.
6. Temporary buffs and debuffs are removed, and the ruleset becomes War Mode (High-Risk and PvE Mode
   are removed). Equipment the character can no longer use goes to the
   bags, or to the mailbox if they are full. This includes a weapon or shield whose proficiency came
   from a forgotten talent.
7. The rewards (`CoAPrestige.Rewards`) are added to the bags, or mailed if they do not fit.
8. The hearthstone is bound to the racial starting location. The character is saved in one
   transaction with any mail, then teleported there.

Items, gold, currencies, reputation, professions and mounts are kept. A remembered spell returns to
its old button the next time the character learns any rank of it, if that button is empty.

While Prestige Mode is active:
- CoA refuses a switch to another specialization through the guard this module registers with
  `AddAscensionSpecializationSwitchGuard`.
- The Prestige Challenge aura multiplies every experience gain by
  `100% + CoAPrestige.ExperienceBonusPercent`.
- Reaching level 15 replaces War Mode with PvE Mode. From there the player chooses High-Risk or War
  Mode again in a rested area.

Reaching the required level again completes the cycle. It removes the aura and unlocks the
specialization.

The state is the player setting `core.coa_prestige`: level, active flag and locked specialization.
It is saved with the character, so a reset is never half-saved. The account total is read from the
other characters' settings at login.

## Wildcard Heroes

A Hero in Wildcard mode may prestige too. Instead of class talents it resets its active Wildcard
specialization (`AscensionWildcard::PrestigeSpecialization`): the build, stat path, slotted skill cards and the
specialization's Silas levelling track start over, and its Scrolls of Fortune (bags, bank and redeemed tokens),
Cases of Fortune and Bonus Manastorm Caches are deleted. The deleted scrolls become repurchasable at Silas at the
level cap. Chromie's window reads their count from SMSG 0x720, which is sent before her gossip menu. The
specialization lock covers the Wildcard specialization swap spells as well.

## Data

`data/sql/updates/pending_db_world/rev_20260925_02_coa_prestige_chromie.sql` adds:
- Chromie's template;
- the never-spawned template 990782;
- spawns in Stormwind (Trade District) and Orgrimmar (Valley of Strength), beside the Worldforged
  guardian;
- the vendor rows.

The spawn points are chosen, not recovered. Every price is a row of the client's
`ItemExtendedCost.dbc`.

## Tests

- Unit tests for the rules in `tests/CoAPrestigeRulesTest.cpp` run in the `unit` stage.
- Gameplay scenarios in `apps/coa-gameplay-test/scenarios/coa-prestige-*.json` cover activation,
  refusals and shops, the experience bonus, and the spawns.

## Not implemented

- The daily Prestige quest ("Today's Prestige Quest is ...").
- Temporal Contracts. The client's tab for them is disabled.
- The Draft reset. Conquest of Azeroth has no Draft mode.

## Open questions

- **Experience bonus.** The client tooltip says "by 300%", while the aura's Spell.dbc amount is 150.
  The default follows the amount.
- **Cache.** The client's window shows the Prestigious Cache 97304, which nothing on this server can
  open. The default reward is 1287330, the Prestigious Cache CoA opens into the newest released tier.
- **"1x Experience" trials.** The Prestige bonus still applies inside mod-coa-challenges' "Resolute
  1x Experience" trials, which only block experience items today.
