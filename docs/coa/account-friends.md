# Account-wide friends

Set `Social.AccountWideFriends = 1` in worldserver.conf and restart to share friends
and their notes across characters on the same account. The default is disabled.
This requires the Ascension client's existing friend metadata support; do not
enable it for stock Wrath clients. No new addon is required.

The list follows a friend's currently online character, subject to the existing
faction, security and visibility rules. The original character name is sent to
the client's existing “Added as” display. Account IDs are never displayed.
Friendship remains one-way. Ignore lists remain character-specific. Editable
display labels are outside this change.

## Migration and recovery

Apply the pending characters migration before enabling the setting. It creates
`account_friend` and `account_friend_migration`; it does not alter or remove
`character_social` rows. On first use, each account imports its current character
friendships, deduplicated by the friend's account. Own-account friends are excluded.
Identical notes are preserved; conflicting notes or more than 50 distinct friend
accounts reject the import and produce a server log entry for administrator
reconciliation. The original character list remains available on import failure.

The import and its completion marker use a single synchronous transaction. The
marker is read back before the account list is used. Subsequent removals do not
reimport old friendships. Deleting an originally added character falls back to
another surviving character on that friend's account.

Back up both new tables before changing this setting. Disabling it and restarting
returns to the preserved character lists; it does not copy later account-list
edits back to those legacy lists. Retain the new tables if re-enabling later.

## Protocol and verification

The native contact list remains the primary packet. Opcode `0x9C0` supplements
it with a little-endian uint32 pair count, followed by current-name/original-name
pairs. Each UTF-8 string has a uint32 byte length. The client uses these pairs for
its existing friend metadata API and update event.

Run `python3 -B tools/verify_all.py --stages source,harness --base origin/main
--harness account_friends`. The focused harness compiles the actual account-list
implementation and selected social functions against offline database/session
adapters. It covers shared identity, notes, visibility, login/logout projection,
metadata bytes, limits, migration conflicts, failed commits and disabled behavior.
It does not establish live client acceptance; compile and SQL qualification are
separate checks.

Contact-list requests run on the world-thread dispatcher. The shared cache and
account-list packet construction are also synchronized because asynchronous
Recruit-a-Friend callbacks can refresh lists from map threads. The regression
includes concurrent account additions and concurrent list refreshes.
