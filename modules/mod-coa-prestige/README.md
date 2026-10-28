# mod-coa-prestige

Chromie's Prestige Mode for Conquest of Azeroth. A character at the realm level cap asks Chromie to wind back
time. It returns to level 1 and levels again with an experience bonus. Its specialization stays
locked until it reaches that cap again, and every activation pays the Prestige rewards.

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
- the character is a Conquest of Azeroth class, or a stock class on Warcraft Reborn, at
  the configured realm level cap (`MaxPlayerLevel`);
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
   are removed). All equipped gear is mailed to the character; bags and their contents are retained.
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

## Warcraft Reborn

A stock class on a Warcraft Reborn realm prestiges like a Conquest of Azeroth class, with the same
requirements, rewards, reset and lock. Its specialization is its talent spec (1 or 2). Instead of
class talents, the active talent spec's talents are reset, every Mystic Enchant in the active preset
is removed, and the Reborn class spells above level 1 are forgotten (starting spells are learned
again). Activating the other talent spec is refused until the Prestige level.

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

## Prestige caches and daily quests

The generic Classic Prestigious Cache (1287330) converts to the highest configured populated Classic
pool allowed by `Ascension.CallboardCache.ReleaseStage`. The same release check applies when opening
an already-owned named cache and when selecting content tokens. `ClassicStages` can restrict the
available pools further; it cannot unlock a tier ahead of the shared release stage. At the Mythic
Dungeon release, only the existing Heroic Dungeon Prestige pool is available; no new Mythic pool is
invented. An unavailable cache is kept, not consumed or downgraded.

TBC pools remain controlled by `TbcStages` and require a realm cap of at least 70. TBC generic caches
never fall back to Classic gear. No WotLK pool has been recovered, so the WotLK generic cache is kept
with an unavailable message. Pool contents, stat preference and configured token probabilities remain
unchanged; the probabilities are reconstruction settings, not confirmed universal Ascension rates.

Daily quests 80954/80955/80956 rotate through game events 191/192/193. The existing daily grants,
quest progress, XP auras, completion rewards and turn-in gossip remain implemented. Main Prestige
rewards still pay at activation; historical activation/completion policies vary by realm and are not
changed without version-specific evidence and an entitlement migration.

## Not implemented

- Temporal Contracts. The client's tab for them is disabled.
- The Draft reset. Conquest of Azeroth has no Draft mode.

## Open questions

- **Experience bonus.** The client tooltip says "by 300%", while the aura's Spell.dbc amount is 150.
  The dummy aura does not supply this multiplier. `CoAPrestige.ExperienceBonusPercent = 300`
  is 300% of baseline (3x total), applied by the challenge XP hook.
- **Cache.** The client's window shows the Prestigious Cache 97304, which nothing on this server can
  open. The default reward is 1287330, the Prestigious Cache CoA opens into the newest released tier.
- **"1x Experience" trials.** The challenge XP hook excludes the Prestige multiplier when
  `CHALLENGE_RULES_TYPE_NO_BONUS_EXPERIENCE` is active, including Resolute.

## Realm level cap and classless characters

Prestige follows `MaxPlayerLevel` (for example 60, 70 or 80) on every realm.
The resolved value governs activation, replayable quest reset, completion, daily max-level credit,
experience-bonus eligibility and specialization-lock messages. `CoAPrestige.RequiredLevel` is retired and
ignored, including existing explicit values. The core's MaxPlayerLevel setting requires a restart to change.
A realm capped at level 1 cannot prestige, to prevent reward loops without any releveling.

CoA, Wildcard and Warcraft Reborn retain their existing reset implementations. Free Pick resets its active
advancement build without charging unlearning costs, updates its saved active-slot copy and honors the
Prestige specialization lock. Ordinary classes reset their active talents. Other saved builds are retained. The reset preserves Group 1 and ROW_RETAINED entries using upstream's
existing reset-retention rule; it does not import Area 52's separate storage schema or reset policy.

Area 52 uses an explicitly registered Prestige reset handler, ahead of the Dawnrise Free Pick path.
Its scoped integration is in [integrations/area52](integrations/area52/README.md). It validates and
resets only the active, unlocked build and enchant specializations, preserving other specializations
and collections. The full Area 52 backend is deliberately not part of this change.

The stock client's Prestige window has its own level-60 checks. Prepare its existing UI file with:

```sh
python tools/patch_prestige_client.py /extracted/PrestigeMode.lua /staging/PrestigeMode.lua
```

The tool changes only the MAX_LEVEL assignment to the existing client GetMaxLevel() API and refuses an
unknown baseline or overwriting the input. Distribute the staged file at
Interface/AddOns/AscensionUI/Gossips/PrestigeMode.lua using the realm's normal client patch process.
This is an existing UI replacement, not a new addon or DLL. It updates the threshold and all labels which
already read MAX_LEVEL. No client installation or binary is included.
