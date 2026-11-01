# 64-quest log: server-side protocol change

> [!CAUTION]
> **CLIENT FILE CHANGES REQUIRED. Do not deploy this server change with the existing 25-slot client.**
> The server PR is intentionally a draft until matching client changes are implemented and verified.

The server supports 64 active quests. Daily quest completion limits remain unchanged.
Existing character quest-status rows need no schema change; the normal login/save paths use the expanded capacity.

## Required client changes

- Expand the native quest-log capacity, storage and all quest-slot loops from 25 to 64, including acceptance,
  removal, swapping, objective updates and login reconstruction.
- Match `UpdateFields.h`: slots 26–64 add 195 words after the old quest log. Every player update field from
  `PLAYER_VISIBLE_ITEM_1_ENTRYID` through `PLAYER_END` moves by 195 words. Item, unit, gameobject and corpse
  layouts are unchanged. The player visibility mask has five entries per quest: party-visible quest ID,
  followed by four private words for state, counters and timer.
- Match the player extension packet `0x0578`: reward XP occupies fields 88–151 and quest levels occupy
  fields 152–215. These ranges replace the old 36–60 and 61–85 ranges. The packet remains GUID, field, value.
  The client keeps 88 unit fields (0–87) per GUID and ignores higher indices, so its unit table must grow to
  at least 216 fields. The new ranges start after that table because every existing index is taken: 86 is read
  by the attachment fix and 87 is the item-ladder preview flag (`PlayerScales`); 36–99 would overwrite both.
- Update FrameXML/addon limits, quest-log counters and scrolling to display and operate on all 64 entries.
  Updating Lua limits alone is insufficient; the native and extension field layouts must also match.

No client binaries, patches or distribution files are included in this server-only change. Existing clients
cannot safely interpret the shifted player fields. Coordinate the server and client releases.

## Verification

Run `GTEST_FILTER='AscensionQuestLog.*' python -B tools/verify_all.py --stages build,unit,harness
--harness quest_log_capacity` (on one line). The unit tests check packet field boundaries and visibility flags;
the focused harness exercises the actual quest-slot methods across all 64 slots, full-log detection, removal
and reuse, swapping and equipment-field preservation.

Client acceptance remains pending: accept 64 quests, reject the 65th, progress/complete/abandon quests above
slot 25, reorder the first and last slots, relog, and verify quest levels, XP, equipment and other player values.
