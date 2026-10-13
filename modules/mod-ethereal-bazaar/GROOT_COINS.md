# Groot Coins

Staff reward useful bug reports with **Groot Coins** (item 910001), a soulbound
coin sent by in-game mail. Players exchange the coins they carry with Tiraxis
for **Bazaar Tokens** (item 975001). The feature lives in this module:
`src/GrootCoin*.{h,cpp}`, registered from `bazaar_loader.cpp`.

## Allocations

| What | Value | Where |
| --- | --- | --- |
| Coin item | 910001 | `GrootCoin::COIN_ITEM`, world migration `rev_20261012_60_groot_coin_item.sql` |
| Coin display (Release A) | 30015, the Bazaar Token icon | same |
| Custom display (Release B, reserved, not shipped) | 990001 | `client-art/` |
| RBAC: issue awards | 1001 `Command: groot award` | auth migration `rev_20261012_60_groot_coin_rbac.sql`, `RBAC.h` |
| RBAC: read the audit | 1002 `Command: groot audit` | same |
| Tiraxis gossip actions | 9100-9199 (existing menus use 1-5) | `GrootCoinScripts.cpp` |
| Exchange NPC | Tiraxis, entry 900007, script `npc_tiraxis` | unchanged |
| Audit tables | `grootcoin_award`, `grootcoin_award_mail`, `grootcoin_exchange`, `grootcoin_exchange_item` | characters migration `rev_20261012_60_groot_coin_audit.sql` |

### Collision evidence (12 Oct 2026, read-only)

- Local dev databases (`coa_dev_world`, `coa_dev_auth`, `coa_dev_characters`, MySQL 8.0.46):
  no `item_template` or `item_dbc` row for 910001; no `itemdisplayinfo_dbc` row for 990001 (the overlay
  table is empty); `currencytypes_dbc` has no row for 910001 or 975001; `rbac_permissions` holds only 1000
  in the custom range, and no `rbac_linked_permissions` or `rbac_account_permissions` row uses 1001/1002;
  no `item_instance` of 910001.
- Installed client DBCs (`env/dist/data/dbc`): `Item.dbc` (563,770 records) has 975001 but not 910001;
  `ItemDisplayInfo.dbc` (129,695 records, highest id 171,126) has 30015 but not 990001. `Spell.dbc` has a
  spell 910001, which is a separate namespace.
- Source: no other use of 910001 or 990001; `RBAC.h` custom block ended at 1000; no pending auth migration
  uses 1001/1002; Tiraxis gossip uses actions 1-5.
- The world and auth migrations only delete their own definitions (`name = 'Groot Coin'`,
  `name LIKE 'Command: groot %'`), so a row that took one of these ids in the meantime makes the update fail
  instead of being overwritten. Check the live PTR databases the same way before deploying there.

## Configuration

In `ethereal_bazaar.conf` (read once at startup; no reload):

```
GrootCoin.Enable = 0          # .groot award
GrootCoin.ExchangeEnable = 0  # Tiraxis exchange
GrootCoin.TokensPerCoin = 100
GrootCoin.MaxAward = 25
GrootCoin.ExternalAwardsEnable = 0  # pay rows from groot_coin_award_queue (also needs Enable = 1)
GrootCoin.QueuePollInterval = 60    # seconds between queue reads, minimum 5
```

Both switches ship off. Turning either off later stops new awards or exchanges only: the coin item, its client
registration and every audit row stay, so held coins keep displaying. A rate change applies to new exchanges;
every exchange row stores the rate it used.

### Startup checks

With either switch on, startup checks the coin template (class 15/0, bind on pickup, no price, no unique limit
or duration, stack at least `MaxAward`), its `item_dbc` row matching the template, the client item
registration, the Bazaar Token template and that the rate fits a token stack for 10 coins, `EtherealBazaar.Enable`,
`CoA.SendDisplayPatches`, that creature 900007 runs `npc_tiraxis`, `MaxAward` in 1-1000 and the five Groot Coin
tables (four audit tables and the award queue). Any failure disables both parts with `Groot Coin: ...` lines in the server log and in `.groot status`;
nothing else in the bazaar is affected.

## Permissions

Nothing is granted by the migrations. An administrator grants each designated staff account explicitly, for
the realm in question (check `.help rbac account grant` first; `-1` means every realm):

```
.rbac account grant <staff-account> 1001 <realm-id>
.rbac account grant <staff-account> 1002 <realm-id>
```

`.groot award` additionally requires Game Master security (level 2+) on the session, refuses awards to the
issuer's own account, and is not available from the console. 1002 alone gives read-only access, also from the
console. Ordinary `.additem` access remains a separate administrative power this module cannot restrict.

## Commands

```
.groot award <character> <amount> <issue-number> "<reason>" "<attribution-ref>"
.groot history <character> [count]      # default 20, at most 100
.groot inspect <award-id|exchange-id>
.groot status
```

- `amount`: whole number 1 to `MaxAward`. `issue-number`: the plain number of an issue in
  jealous-sound/azerothcore-wotlk-coa (no `#`, no URL).
- `reason` (up to 255 characters) and `attribution-ref` (up to 128) are required. The attribution reference
  records how the reporting account was verified, for example the private `<account>-<report-id>.report`
  receipt. Never copy account ids or attribution references into public GitHub issues.
- The character is resolved and its account frozen into the award, so a later rename or transfer does not
  redirect it. Deleted characters are rejected.
- One award per account per issue. Repeating the same award reports the existing award id; a different amount
  or character for the same issue and account is reported as a conflict. Nothing is sent in either case.

## Reward procedure

1. Resolve duplicate tracker issues to the canonical issue.
2. Verify the contribution was useful and, by default, that the fix is verified. "Closed" is not "fixed".
3. Verify the reporting account (in-game report receipt or an authenticated support check).
4. The player names a character on that account.
5. `.groot award ...`; keep the award id it prints.
6. The player claims the mail (kept 90 days) and exchanges coins at Tiraxis.

Pilot amounts: 1 small actionable report, 3 useful reproduction, 5 major blocker or investigation,
10 exceptional investigation, up to 25 by explicit staff judgement. These are provisional.

## Website / external awards

A website, bot or script can request awards without a game session by inserting rows into the characters table
`groot_coin_award_queue`. With `GrootCoin.Enable = 1` and `GrootCoin.ExternalAwardsEnable = 1` the worldserver
reads up to 20 pending rows every `GrootCoin.QueuePollInterval` seconds and pays each one through the same code
as `.groot award`: the `MaxAward` cap, the audit row, the soulbound coin and the mail. With either switch off,
the queue is not read and rows wait unchanged.

| Column | Set by | Meaning |
| --- | --- | --- |
| `id` | database | Auto-increment row id. |
| `source` | requester | Who asks, e.g. `website` or `github`: 1-32 of `a-z 0-9 - _`. `gm` is reserved. |
| `source_ref` | requester | The requester's own id for this award, e.g. `bug:1234` or `7447`; 1-64 printable characters. |
| `character_guid` | requester | `characters.guid` of the character that receives the mail. |
| `amount` | requester | Coins, 1 to `GrootCoin.MaxAward`. |
| `reason` | requester | Shown in the mail and stored in the audit; 1-255 printable characters. |
| `requested_by_account` | requester | Auth account id of the staff member approving it. Must be Game Master (security 2+) on this realm and must not own the character. |
| `status` | server | `pending` (default), `done` or `failed`. |
| `error` | server | Why a row failed. |
| `award_id` | server | The `grootcoin_award` id that paid it; use `.groot inspect <award_id>`. |
| `created_at` / `processed_at` | database / server | When it was queued and settled. |

(`source`, `source_ref`) is unique in the queue and again in `grootcoin_award`, so it is the requester's
idempotency key: inserting the same request twice fails with a duplicate-key error, and a request can never be
paid twice. In-game awards are stored with source `gm` and no reference, so they are not limited by that key.

Request an award:

```sql
INSERT INTO groot_coin_award_queue (source, source_ref, character_guid, amount, reason, requested_by_account)
VALUES ('website', 'bug:1234', <guid>, 1, 'Confirmed bug #1234', <gm account id>);
```

A duplicate-key error on this insert means the request already exists; read its status instead of retrying
with a new reference. Read back the outcome:

```sql
SELECT status, error, award_id, processed_at FROM groot_coin_award_queue
WHERE source = 'website' AND source_ref = 'bug:1234';
```

How rows settle:

- `done`: the coins are in the recipient's mailbox. The row is set `done` in the same transaction that writes
  the coin, the mail and the audit row, so `done` and the award exist together or not at all.
- `failed`: nothing was sent. `error` says why: invalid source, reference, amount or reason; the character does
  not exist or was deleted; the requester is not a Game Master or owns the character; or the reference was
  already used for a different character or amount. Fix the cause and queue a new reference; failed rows are
  never retried.
- `pending` after a poll: still being processed, or the outcome was unknown (database error, server stopped
  mid-award). It is read again on a later poll. If its award had in fact committed, the key lookup finds it and
  marks the row `done` with that award id instead of paying again.

The website needs an account on the characters database with `INSERT` and `SELECT` on
`groot_coin_award_queue` only. It never writes `status`, `error`, `award_id` or `processed_at`.

## How delivery stays exactly-once

An award creates the coin with its soulbound flag set, and writes the item, the mail, the mail item, the award
row and the award-mail link in **one** characters transaction. The mail is staged with
`MailDraft::StageMailTo`, which runs the usual mail hook and appends the rows but changes nothing in memory;
`PublishStagedMail` updates an online recipient's mailbox only after the commit callback reported success, on
the world thread, re-resolving the recipient by GUID. An offline recipient (or one who logs out meanwhile) sees
the mail at the next login. If the commit reports failure the award key is read back: our own award id means it
did commit; another id means a concurrent award won; no row means it rolled back. When even that read fails the
award is listed under "Needs reconciliation" in `.groot status` and logged; do **not** simply re-run it,
inspect it first. A mail hook that suppresses the mail aborts the award before anything is written.

Mail expires after 90 days like any other mail. A missing mail is never re-sent automatically; it may have been
claimed or deleted. `.groot inspect <award-id>` shows whether the mail is still in the mailbox.

## How the exchange stays exactly-once

Player flow: Tiraxis -> "I want to exchange Groot Coins" -> carried balance and rate -> 1, 5 or 10 -> a
confirmation with a pop-up -> result. Back and Cancel spend nothing.

- Only coins in the backpack and equipped bags count; bank, mail, guild bank, buyback and auction coins never do.
- Choosing an amount stores a server-side quote (random nonce, NPC GUID, coins, tokens, rate) valid 60 seconds.
  Confirming consumes it once; a stale, replayed, different-NPC or changed-rate confirmation is rejected.
- The payout is the integer rate times the coins, checked for overflow and against the token stack size. The
  tokens must fit one free slot or an existing stack; otherwise nothing happens. Bazaar Tokens are a currency
  (BagFamily 8192), so they normally go to the Currency tab and full bags do not block an exchange. The slot a
  coin stack would free is not counted.
- The tokens are plain item 975001 stored in the bags. No level bonus, test-zone bonus or loot multiplier is
  applied, and there is no reverse conversion.
- The database is written before memory. One transaction holds guard rows, the coin debits, the token credit
  and the audit row. Each guard row's CHECK fails the whole transaction if the database does not hold exactly
  the stack counts and positions the server has in memory. The involved stacks are always written again through
  the normal inventory save first, and that save is waited for. If a guard still fails (for example a save of
  the same stack was in flight on another database worker), nothing was spent and the exchange is tried once
  more after a fresh save.
- The map thread waits up to five seconds for the acknowledgement, so no other action of that player
  interleaves. Only on success is the inventory changed in memory, with the GUIDs and counts the database
  already holds; later saves rewrite the same values. A definite failure therefore leaves memory untouched.
- A missing acknowledgement keeps the exchange pending (no further exchanges for that character) until the
  outcome is read back by exchange id. If the character changed the involved stacks in the meantime, the
  exchange is listed for reconciliation.

Known limit: a server with more than one characters-database async worker could in principle let an older,
already queued inventory save of the same stack land after the exchange. The guard rows reject the opposite
order. Keep `CharacterDatabase.WorkerThreads = 1` (the default) on realms with the exchange enabled.

## Interop: a second exchange entry point

A vanity store (or any NPC) can offer the same exchange without new rules:

```cpp
#include "GrootCoin.h"

GrootCoin::Vendor const vendor{ creature, "vanity_store" };   // stored in grootcoin_exchange.source
GrootCoin::ExchangeResult result = GrootCoin::TryExchange(player, vendor, coins);   // 1, 5 or 10
ChatHandler(player->GetSession()).SendSysMessage(std::string(GrootCoin::Describe(result)));
```

`TryExchange` quotes and confirms in one call, for a UI that already asked the player to confirm. A gossip UI
can use `CreateQuote` / `ConfirmQuote` / `CancelQuote` as Tiraxis does. The vendor must be a creature the player
can interact with; the tokens arrive as ordinary Bazaar Tokens, so anything that charges item 975001 can spend
them. Keep any new gossip action ids clear of 9100-9199 on Tiraxis.

### FirstOni Vanity Store

The Vanity Store (in progress, client side through Extensions.dll) keeps its prices in the world table
`coa_client_vanity_collection` (`ItemID`, `DonationPointCost`, `SeasonalPointCost`, `BazaarTokenCost`). The
server reads it at startup and sends it to the client at login, and Wardrobe purchases may use the same path.
Groot Coins do not touch that table, its prices or Extensions.dll: the exchange only puts plain item 975001 in
the player bags, which is what a `BazaarTokenCost` purchase spends. A later "convert Groot Coins" action in the
Vanity window can call `GrootCoin::TryExchange` with its own `Vendor` source (for example `"vanity_store"`)
instead of reimplementing the exchange.

## Release A and Release B (custom icon)

Release A (this change) uses display 30015, so the coin works with today's client: the server registers 910001
with `Ascension::ClientItemPatches` unconditionally and streams its `item_dbc` row (`CoA.SendDisplayPatches`).

Release B adds the custom icon. See `client-art/README.md`. Its display row and the item's display switch are
**not** part of this change; ship the texture through the launcher first.

## Rollback, corrections and wipes

- Rollback: set both switches to 0 and restart. Keep the item, its `item_dbc` row and all `grootcoin_*` rows.
  Never remove the coin template while players hold coins. There is no down migration.
- Corrections: there is no `.groot give` or `.groot remove`. A wrong award is corrected by an administrator
  with ordinary item tools, recorded in your staff log with the award id; the award row is never edited.
  Spent coins are not clawed back automatically.
- Wipes: awards are not replayed. The audit log is not a wallet and does not show outstanding balances. Back up
  the characters database including the `grootcoin_*` tables; carrying value across a wipe needs its own
  procedure. Do not delete award rows to pay again.

## Testing

`python -B tools/verify_all.py --stages build,unit` runs `GrootCoinRules.*` (amount, issue, text, history,
rate and overflow, UUID rules). The acceptance matrix in the implementation brief still needs an in-game pass;
see the playtest list in the change description.
