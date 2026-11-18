# Realm branch based on the CoA stable release

`feat/live-20261118-custom` starts at `live-2026-11-18.3` (`2bb971af00d4ac78c154feed493875c2cc4dcca3`).
It ports the realm's customizations rather than merging the full `coa-bots-2.9.5` history.

The customizations include the paid raid registrar and its corrected Stormwind placement, BWL health and loot
tuning across difficulties, missing T1 vendor offers, Molten Core schedule compatibility, exploration-log
deduplication, and the Thunderous critical-damage adjustment. Gameplay verification uses private module configs
and redirects the auxiliary Playerbots database as well as the three core databases.

The configurable bot health weighting is retained from the bot core fork. Keep the existing setting in
`mod_coa_raid_difficulty.conf` to retain the live realm balance:

```ini
CoaRaidDifficulty.BotMemberWeight = 0.7
```

Health rounds the weighted population and clamps it to 10 through 25. Loot continues to use the ordinary player
count. The setting is read at configuration load; the raid's health pool is selected at spawn or combat entry.

## External modules

Use the CoA/SquidBots versions of Playerbots and Dungeon Clear. The pinned revisions and local fixes are in
[module-patches/README.md](module-patches/README.md). Keep these repositories separate from core updates.
The optional NPC Enchanter module used by this realm is `azerothcore/mod-npc-enchanter` at
`af32add66eafc0e0eb8775999e76ceed75f18b74`.

The AI smoke scenario attaches real PlayerbotAI using the self-bot command, exercises Dungeon Clear configuration,
casts a spell with AI attached, and detaches AI. It does not establish remote bot login, autonomous rotations,
navigation, or dungeon completion. Those require separate acceptance on an isolated realm.

## Installing a verified candidate

Back up the databases and installed configuration before upgrading. Stop worldserver, then install from this
branch's own build directory with the intended installation prefix. A build configured under a temporary worktree
may use that worktree's `env/dist` prefix; inspect `CMAKE_INSTALL_PREFIX` and `CONF_DIR` before installing.
Keep the existing `.conf` files, review new `.conf.dist` settings, and let the normal database updater apply pending
migrations on startup. Startup can apply every unapplied migration in the checkout, not just realm customizations.

Restoring an older binary does not undo database migrations. Preserve a matching database backup for rollback.
Keep the old `coa-bots-2.9.5` branch available until bot and raid acceptance is complete.

For subsequent stable releases, create an integration branch, merge the chosen release tag, resolve conflicts,
and run the affected verification before deployment. Update external modules deliberately and preserve their fixes.
