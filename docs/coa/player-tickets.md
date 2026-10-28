# Player tickets

The original Help menu opens the Ascension ticket window, which talks to the server through the
`Extensions.dll` ticket packets. Tickets are separate from AzerothCore's `gm_ticket` tickets: the Help menu
still asks for a stock ticket with `GetGMTicket()`, and must be told there is none, because its layout has
no view for one.

## Player side

| Request | Packet | Answer |
| --- | --- | --- |
| Open a ticket | `CMSG 0x0703` {u8 priority, u8 category, title, description, affected character} | `SMSG 0x0701` ticket, then `0x0704` result |
| Send a message | `CMSG 0x0707` {[ticket id], text, u8 GM only} | `SMSG 0x0708` result and message, then `0x0702` ticket |
| Mark a message read | `CMSG 0x071D` {[ticket id], u32 message} | `SMSG 0x0702` ticket when it changes, then `0x071E` result |
| Reopen | `CMSG 0x0719` {[ticket id]} | `SMSG 0x0702` ticket, then `0x071A` result |
| Close or resolve | `CMSG 0x0705` {[ticket id]} | `SMSG 0x0702` ticket, then `0x0706` result |

- An account has one current ticket: the latest one its owner has not closed. It is sent with `0x0701` at
  login and survives a GM closing it, so the player can reopen it or mark it resolved.
- Titles take 1-128 letters on one line and messages 1-2048 letters; up to 200 messages per ticket.
  The affected character is `AFFECTED_CHARACTERS_NONE`, `AFFECTED_CHARACTERS_ALL` or a character of
  the account.
- The player's copy numbers its messages 1..n in order. GM notes are never sent to the player.
- `AllowTickets` (and `.ticket togglesystem`) enables ticket creation and the Help menu's
  `CONFIG_ALLOW_TICKETS`.
- `SMSG_ACCOUNT_INFO` (0x09BB) is sent at login: the account's GM level and its characters, which the ticket
  window offers as the affected character.

Statuses: `OPEN` when created or reopened, `WAITING_FOR_GAME_MASTER` after a player message,
`WAITING_FOR_PLAYER` after a GM reply, `CLOSED` when a GM or the player closes it.

## GM commands

Game masters are told about new tickets, player messages, reopened and closed tickets. A ticket is named by
its number or by any character of its account.

| Command | Effect |
| --- | --- |
| `.support list` | Current tickets with status, owner, message count and assignee |
| `.support view <ticket or character>` | The ticket's details and every message, including GM notes |
| `.support reply <ticket or character> <text>` | Answers the player |
| `.support note <ticket or character> <text>` | Adds a note only GMs see |
| `.support close <ticket or character>` | Closes the ticket; the player may reopen or resolve it |
| `.support assign <ticket or character> [name]` | Assigns the ticket, or clears the assignment |

Tickets and messages are stored in `ascension_player_ticket` and `ascension_player_ticket_message`.
Resolved tickets stay in the database but leave the list.

## Verification

`python -B tools/verify_all.py --stages harness --harness player_ticket` checks the ticket rules and decodes
every record with the DLL's field order. The `player-ticket-native-requests` gameplay scenario drives the
packets and GM commands on a server.
