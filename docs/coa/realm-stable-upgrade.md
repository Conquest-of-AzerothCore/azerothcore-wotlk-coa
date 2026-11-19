# Realm branch based on the CoA stable release

`release/live-20261118-custom` starts at `live-2026-11-18.3` (`2bb971af00d4ac78c154feed493875c2cc4dcca3`).
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

## Normal workflow for realm release updates

When the realm owner requests an update to the latest release, follow this workflow. This document records the
procedure; it does not itself authorize an update or deployment.

The fork's `main` follows upstream development and is not a deployment source. Keep realm customizations on
`release/live-YYYYMMDD-custom` branches. The first realm release is `release/live-20261118-custom`, renamed from
`feat/live-20261118-custom`. A branch rename does not require reinstalling the server. Never replace `main` with
a force-push to promote a realm release.

1. Inspect remotes and fetch the official CoA releases. Select the latest stable release tag, rather than the
   development tip, and review its changes relative to the deployed release.
2. Create a new `release/live-YYYYMMDD-custom` branch from the current custom realm release in a separate
   worktree with its own build and private test databases. Merge the selected upstream release tag into it.
3. Resolve conflicts while preserving the paid raid registrar, raid scaling and loot tuning, T1 vendor offers,
   Thunderous adjustment, exploration logging fix, and configurable bot health weighting. Review whether
   upstream has replaced any custom fix before retaining or removing it.
4. Review Playerbots and Dungeon Clear separately. Preserve the recorded local module patches and pin tested
   module revisions; a core update does not authorize blindly updating every module.
5. Run affected verification through `tools/verify_all.py`, including source checks and a build. Exercise private
   database migrations, raid resets, MC/BWL scaling and loot, and bot behavior. Add real network login/relog and
   autonomous bot acceptance where native scenarios cannot observe the behavior. Report CoA-class coverage
   separately from original WoW-class coverage.
6. Review and push the tested release branch. Use a deployment tag such as `realm-YYYY-MM-DD.N` to identify the
   exact installed commit, and retain the tested module revisions alongside the release information.
7. Before deployment, confirm installation is authorized, back up all four live databases (including Playerbots),
   installed configs and binaries, then stop the server gracefully and install the verified candidate. Preserve
   existing `.conf` values, review new defaults, and verify source/module configuration paths and install prefix.
8. Check migrations and startup logs, then perform live acceptance with actual CoA bots: summons, shared instance
   entry, combat, raid health, difficulty-specific spawns/loot, raid registrar fees/resets, and relog persistence.
   Record the deployed revision/tag after acceptance. Keep the prior release and matching backups for rollback;
   reverting binaries alone does not undo database migrations.

For this realm, `origin` is the owner's fork, `upstream` is the official Conquest-of-AzerothCore repository, and
`zyth45` preserves access to the old core fork. Inspect actual remote URLs before fetching or publishing.
