# Crow's Cache

This optional level-60 High-Risk PvP event uses existing CoA client assets and server data.
It requires the CoA world database, client DBCs and terrain data, including cache item 1615010,
High-Risk aura 1004019, carry aura 1005000 and High-Risk chest template 994300.
Client archives and database dumps are not included.

## Installation

Build and install the server normally and let its database updater apply the pending world
and character migrations. Existing applied SQL files are unchanged.
Enable `CrowsCache.Enable = 1` in the server's `modules/coa.conf`, then restart the server.
The shipped default is disabled. Coordinate, interval and random-location settings are in
`src/server/coa/conf/coa.conf.dist`.

Copy this entire `CoACrowsCache` directory into the CoA client's `Interface/AddOns` directory.
Fully reopen the client after first installation; use `/reload` for later addon updates.
The marker uses the client's dungeon portal atlas, is 55 pixels wide and has the hover text
"High-Risk 60 PvP Event". An addon is required on each client that should display the marker.

## Event behavior

One location is chosen randomly per scheduled event: Abyssal Sands in Tanaris, Southwind Village
in Silithus, Weazel's Crater in Thousand Needles or the configured Barrens spot.
The chest appears every three hours, with warnings 30, 15, 5 and 1 minute before appearance.
The map marker appears at the first warning; the crow appears during the last five minutes.
The marker disappears when the initial chest is claimed. Unclaimed chests remain available.

A living level-60 High-Risk player claims the chest through a ten-second opening cast;
movement or any damage interrupts it. Carrying slows the player, removes mounted speed bonuses and blocks
stealth, invisibility and teleport spells outside delivery towns. Death drops an instant-claim
chest for another eligible player. Claimed caches expire after 24 hours.
Gadgetzan, Cenarion Hold and Ratchet permit opening the carried item out of combat.
Existing zone PvP rules remain in effect.

The seeded reward pool contains level-60 item-level-95 Heroic Bloodforged Naxxramas equipment.
Opening grants five distinct random equipment items and 20 each of Interlaced Scarlet Cloth,
Interlaced Plagueweave and Interlaced Winterweave. This pool is configurable through
`coa_crows_cache_rewards`; it does not automatically track future raid tiers.
Full bags retain the unopened cache.

## GM testing

- `.crows start 60`: one-minute Tanaris countdown.
- `.crows silithus 60`: one-minute Silithus countdown.
- `.crows needles 60`: one-minute Thousand Needles countdown.
- `.crows barrens 60`: one-minute Barrens countdown.
- `.crows visit`: teleport to the latest event before carrying its cache.
- `.crows here 60`: countdown at your position in any of those four zones.
- `.crows status`: inspect current events and the next scheduled appearance.
- `.crows cancel`: remove unclaimed events; preserve carried and dropped caches.
- `.crows schedule 10800`: set the next automatic appearance three hours from now.
- `.gps`: report exact position; clear your target to inspect yourself.

Manual events do not move the automatic schedule. Delivery towns are Gadgetzan for Tanaris
and Thousand Needles, Cenarion Hold for Silithus, and Ratchet for the Barrens.

## Validation

Focused verification passed the build, Crow's Cache unit checks, Lua map harness and four
accelerated native gameplay scenarios. The native scenarios exercise warnings, marker
transport, claiming, movement/damage interruption, death handoff and town delivery/rewards.
The Lua harness checks map projection and hover text. Actual client rendering and wider
production rollout are separate from those automated checks.
Use `tools/verify_all.py` as documented in `AGENTS.md` for verification.
On Linux, isolated module configurations must be staged in the server's compiled `CONF_DIR/modules`
directory, with the live server stopped and its configuration preserved and restored afterward.
