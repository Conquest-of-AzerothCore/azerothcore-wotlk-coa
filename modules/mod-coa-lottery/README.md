# CoA lottery

Gold tickets cost 10 gold; the Ascension LotteryUI offers bundles of 1, 10, 100 and 1000.
Defaults: weekly draws, zero seed, 100% of ticket sales in the pot, and Sigil of Goldilocks (97393).
Configure `conf/mod-coa-lottery.conf.dist` through the normal module config directory.
Round settings are persisted and changes apply to the next round. Disabling pauses sales and draws.
Empty rounds extend by their original interval. Overdue populated rounds draw after startup.

Apply `data/sql/updates/pending_db_world/rev_20261009_01_coa_lottery.sql` to world and
`data/sql/updates/pending_db_characters/rev_20261009_01_coa_lottery.sql` to characters through the normal
server updater, then rebuild with modules enabled. These consolidated files replace the earlier untracked
lottery migrations and contain their final values. The character script preserves existing complete lottery
tables, entries, winners and control state when reapplied; partially upgraded older schemas need their
missing columns migrated before using the consolidated fresh-install schema.
The world migration restores Goldilocks (80539, display 89251) and Trade Prince Gallywix
(80540, display 75730) from the checksummed Ascension creature archive. It adds no world spawns.
Goldilocks is spawned automatically while the lottery runs and opens the unmodified LotteryUI.
For manual placement, disable CoALottery.SpawnGoldilocks and use `.npc add 80539`.
Gallywix is spawned automatically in Stormwind while the lottery runs. For manual placement,
disable CoALottery.SpawnGallywix and use `.npc add 80540`. He offers rules and recent-winner
dialogue; ticket purchases are on Goldilocks.
`CoALottery.BonusItems = "97393"` chooses the default companion. Use CSV, for example
`"97393,98073,99491"`, to choose uniformly from distinct item IDs when each new round starts.
The selected item is persisted in `coa_lottery_round.bonus_item`, shown in gossip, and attached
to the winner's gold mail in the same transaction. Restarting or reloading config keeps the current prize.
Empty rounds extend without selecting again. Empty CSV disables prizes; malformed CSV retains the last
valid pool and logs an error. Nonexistent item templates are skipped. Existing pre-upgrade rounds keep
their original no-bonus terms; the new pool applies to the next round.

No client Lua or assets are changed. With bonuses disabled, the base UI requires a positive bonus item ID and crashes for 0;
omitting the field instead advertises hardcoded item 97393. The server therefore supplies informational
item 9000805, named "No bonus reward", with existing display/icon 7798. This item is never awarded.
The base UI's decorative bonus panel remains visible, but it advertises no actual prize.
Custom displays require the Ascension client DBCs and model assets.

The core PlayerMenu::SendDynamicGossipMenu helper pushes session-specific NPC text before the menu,
alternates reserved text IDs 0x7FFF0000/0x7FFF0001, and answers queries only for the current GUID and ID.
No custom lottery opcodes are needed. Verify cached reopen and purchase refresh in the actual client.

Purchases save gold, tickets and the pot in one acknowledged transaction. Draws save the winner,
mail and next round in one transaction; online mail state is published only after a successful commit.
Completed rounds and their entries remain as an audit trail. Tickets of deleted characters are excluded
when loading and drawing a round. A failed draw retries at most once every five seconds. The pot is limited to the native gold cap; total sold tickets are limited to
21474 per round, even with a reduced contribution rate. This implementation assumes one worldserver
owns the realm's character database. Database acknowledgements block the world thread for each purchase
or draw; this favors correctness for a low-volume feature and is unsuitable for a heavily loaded database.

Verification: `python -B tools/verify_all.py --stages source,build,unit,harness --base HEAD --harness lottery`.
Reconfigure your existing build directory first so CMake discovers the new module and unit tests.
The standalone lottery harness compiles the actual dynamic gossip methods and rules without Boost;
its SQL transaction checks use SQLite with the MySQL upsert translated to SQLite syntax. Those checks
do not replace the full server build, MySQL migration validation or actual client acceptance.
Rules tests cover purchase boundaries and exhaustive weighted winner selection. In-game checks:
open Goldilocks; buy all bundles; reopen; check Gallywix rules and recent-winner gossip; compare two players' ticket counts; restart mid-round;
use a short configured interval for the next round and confirm exactly one mailed payout after restart.

The default Sigil of Goldilocks (97393) uses the normal item-learning spell 55884 to teach
92453, which summons noncombat companion 80541 with display 89251. Apply the pending
Goldilocks companion migration as well as the item and lottery migrations. Claiming the
mailed item records ownership in account_vanity_collection; use the sigil to learn it on
the winner, and other characters learn the owned spell at login with CoA.LearnOwnedCompanions
enabled. Earned sigils can be retrieved from the collection. Unlock-all vanity does not
grant unowned sigil spells or permit retrieval of unearned sigils. No client changes are required.

Acceptance: win/claim/use 97393, summon Goldilocks, log out and log into another character
on the same account and summon it there; a different account must not gain the spell.

Each successful draw now writes one permanent coa_lottery_winner record in the character
database, atomically with the jackpot mail and next round. It snapshots the winner's character
name, GUID and account ID; actual draw time (Unix seconds); gold in copper; bonus item ID/name;
winner and total eligible tickets; and payout mail ID. The round ID is unique. Records survive
character renames/deletion and expired mail. Account IDs are internal identifiers; omit them
from public exports. Empty-round extensions and failed payouts create no winner records.
The pending winner-history migration is required before starting the upgraded module.
Earlier completed rounds retain their original records in coa_lottery_round; they are not
backfilled with guessed names or actual draw times.

Newsletter/Discord/dialogue consumers can read this without joining live character or mail tables:

```sql
SELECT round_id, FROM_UNIXTIME(drawn_at) AS draw_time,
       winner_name, gold_copper / 10000.0 AS jackpot_gold,
       bonus_item, bonus_item_name, winner_tickets, total_tickets
FROM coa_lottery_winner
ORDER BY drawn_at DESC, round_id DESC
LIMIT 20;
```

For incremental announcements, remember the last published round_id and select records with
round_id greater than that value in ascending order. drawn_at is epoch time; FROM_UNIXTIME
uses the database session timezone. This feature stores history; publishing and dialogue
integration are separate consumers.

CoALottery.FakeTickets defaults to 100. Every new round receives that many house tickets
and 10 gold per house ticket, plus StartingJackpotGold: the default opening pot is 1,000 gold.
House seed uses the full ticket face value regardless of PotContributionPercent. House tickets
are persisted separately from player purchases, count toward the total ticket cap, and are
clamped to fit the gold cap after the configured seed. Set 0 to disable. Config reloads and
restarts do not add tickets or seed to the current round; pre-upgrade rounds have zero house tickets.

House tickets have the same selection weight as purchased tickets. A house ticket winning
records winner_name='Trade Prince Gallywix', house_win=1, destroyed_copper=the whole pot,
winner_guid=0, winner_account_id=0 and payout_mail_id=0. No mail, bonus item, or player gold
is granted. gold_copper still records the jackpot value; bonus_item is 0 because none was awarded.
The history record, completed round and next round commit atomically. Announcement consumers
can use winner_name directly and house_win/destroyed_copper to distinguish a house win.
The server log also names Gallywix. CoALottery.AnnounceWinners defaults to 1 and announces
player and house winners in-game after a successful commit; set 0 to disable. House announcements
state that the pot was destroyed. External publishing remains a separate consumer of the history table.
Rounds with only house tickets draw and destroy the pot; rounds with no tickets at all extend.
Apply rev_20261009_01_coa_lottery.sql before running the upgraded server.

Gallywix (80540) now offers exactly two gossip options: "What are the rules?" and
"Who has won recently?" His rules describe the active round's interval, contribution rate
and house tickets, equal ticket odds, mailed player rewards and destroyed house-win pots.
His ledger lists the five most recent winner records, newest first, with jackpot amounts
and purchased-ticket counts; house wins show house tickets and zero purchased tickets.
Names remain the recorded names at draw time. Both options stay available while ticket
sales are disabled. Gallywix cannot sell tickets, including through old purchase actions.
No client changes or additional migrations are needed for this dialogue.

With CoALottery.SpawnGallywix=1 (default), the module creates a temporary Gallywix on map 0
at (-8787.7705, 640.43396, 96.12781), facing orientation 0. His grid stays active. The managed
spawn appears after lottery initialization and is removed when the lottery or managed spawn
is disabled; a 30-second TaskScheduler check replaces a missing/dead managed spawn.
The module does not write a persistent creature spawn or remove manually placed NPCs.

CoALottery.Advertise=1 enables zone-wide monster yells from this managed NPC, in universal
language, every AdvertisementIntervalSeconds (default 1800; range 60..86400). The first ad
waits one interval; reloading config resets the ad timer. Ads pause when the lottery is
disabled/unavailable or a draw is overdue. Fifteen lines are shuffled without repeats within
a cycle or at the cycle boundary. Pot values and remaining time are read when the ad runs.
Named player lines choose a random visible human player (including visible GMs) in his zone within
AdvertisementPlayerRadius yards (default 60; range 1..500); with no candidate, he says
"You there". No player pointers survive the callback. Yells reach his entire zone, not the
whole realm. No additional SQL migration or client changes are needed.
The fifteen editable lines are in src/CoALotteryAdvertising.h.

Goldilocks (80539) is managed on map 0 at (-8788.967, 643.0418, 94.944855), facing 180 degrees,
with CoALottery.SpawnGoldilocks=1 by default. Scale is 0.5 at the beginning of a round,
1.0 halfway through and 1.5 at the deadline. It updates on the same advertising timer as
Gallywix (normally every 30 minutes), even with yells muted. New rounds and empty-round
extensions immediately reset scale; restart/replacement restores the current time-based
scale. The existing 30-second spawn check recovers either NPC and removes managed NPCs
when disabled. Goldilocks spawning is independent of SpawnGallywix.

Deleted entrants are excluded when loading/drawing. An empty eligible set is explicitly
distinguished from a database failure; with no surviving entrants the house can still win,
or a no-house round extends. If the chosen character is unavailable at the recipient lookup,
the payout is skipped before creating mail/items/history and a later draw refreshes eligibility.

## GM commands

All `.lottery` commands work in GM chat (security level 2 or higher) and the server console. Apply
`rev_20261009_01_coa_lottery.sql` to characters and
`rev_20261009_01_coa_lottery.sql` to world before running this version. `.lottery help` and
`.help lottery <subcommand>` provide usage.

- `.lottery info [name]`: inspect a character's current tickets, or round duration, remaining time, pause state,
  house tickets, pot, prize and the top 10 ticket holders by count.
- `.lottery refund *|name`: refund current paid entries by mail. Refunded tickets leave the draw and their actual
  contribution leaves the pot; the refund returns the full price paid even when the configured contribution is
  less than 100%. House tickets and seed gold remain. Repeating a refund cannot pay those tickets twice.
- `.lottery disable` / `.lottery enable`: pause/resume the countdown and hide/restore the managed NPCs and their
  advertisements. Enabling a stopped lottery starts a configured round. Pause and GM enable/disable overrides
  persist across server restarts and config reloads; the config enable setting applies until a GM override exists.
- `.lottery start [duration] [fakeTickets] [bonusItemId]`: start only when no round exists, including paused rounds.
  Duration accepts seconds or `s`, `m`, `h`, `d`, `w` suffixes (60 seconds to 365 days). Omitted positional values
  use configuration. An omitted bonus selects randomly from the configured pool; explicit `0` means no bonus.
  House tickets must fit the maximum pot and ticket count. Starting enables the lottery.
- `.lottery stop`: refund all paid current entries, cancel the round and disable. It stays stopped after restart.
- `.lottery restart`: refund/cancel, then start an enabled round using configured terms and a freshly selected prize.
- `.lottery draw [name]`: draw immediately, including a paused round, and start an enabled configured round.
  A specified existing character wins. A non-entrant gets a complimentary ticket, adding a full 10 gold to the pot
  regardless of contribution percentage. Winner history records `admin_forced` and `complimentary_tickets` so
  exports can distinguish this from a purchased entry. An unnamed empty draw with no house tickets errors.

Refunds and their entry removal/pot changes are committed together. Stop/restart include cancellation and the
next state/round in that same transaction. Deleted recipients receive no mail; their entries are removed during
refunds. NPCs are hidden immediately after a successful disable/stop. Commands do not refund historical rounds.

- `.lottery advertise`: immediately triggers one random Gallywix zone advertisement with live lottery values.
  Requires a running round and Gallywix spawning enabled. Bypasses the automatic advertisement enable setting
  without changing its timer. Apply world migration `rev_20261009_01_coa_lottery.sql` for command help.

Successful natural and GM draws immediately trigger a Gallywix zone yell with the winner and drawn pot,
plus five gold/green stock firework-show explosions 6?10 yards above him. House results explicitly announce
pot destruction. This runs after transaction acknowledgement, independently of automatic advertisement or
world-announcement settings, and requires the managed Gallywix spawn to be enabled. No client changes or SQL
migration are needed for these stock gameobjects. Fireworks use the core firework show's despawn-animation
and removal lifecycle.

The summonable Goldilocks companion (80541) uses model scale 0.33 after applying
`rev_20261009_01_coa_lottery.sql`. Reload/restart the server's creature templates and resummon
existing companions to pick up the scale. The lottery ticket NPC (80539) keeps its separate timed growth.

Companion 80541 uses normal ground movement (`Ground=1`, `Flight=0`), with hover disabled.
Reapply the consolidated world SQL, restart and resummon to pick up the movement setting.

The Stormwind pair spawns with orientation 3.14159265 radians (180 degrees).

The same lottery also manages a Horde pair on map 1 in Orgrimmar: Gallywix at
(1621.1122, -4419.4966, 14.876221), Goldilocks at (1623.0135, -4417.805, 14.7874975).
The Orgrimmar pair faces 270 degrees (4.71238898 radians), rotated 90 degrees counterclockwise from 180. Each city has independent spawn GUIDs and advertisement schedules, using the same
round, prize, ticket entries and pot. Disable/stop hides both pairs. Draw celebrations and manual advertisements
run in both cities, with nearby-player advertisements restricted to the local map and zone.
