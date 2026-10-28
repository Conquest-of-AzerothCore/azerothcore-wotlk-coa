# CoA talents: catalog, commands and the client's character-advancement service

Use this reference for anything touching CoA talent points, ranks, specializations or the talent window's
state. The live pieces are `src/server/coa/AscensionCoATalentData.*` (catalog),
`AscensionCoATalentState.*` (spellbook-derived state and wire form) and `AscensionClassService` in
`AscensionCompat.cpp` (rules, commands, packets).

## Where the state lives

- The server holds no talent table. A held rank is the rank's spell in `character_spell`; the active
  specialization is the player setting `core.ascension_active_spec` (`character_settings`, loaded and saved
  even with `PlayerSettings.Enabled = 0`). `AscensionCoATalentState::KnownRank` derives an entry's rank as the
  highest rank spell the character owns.
- The catalog is `CharacterAdvancement.dbc` (entries, ranks, costs, level, tab) with `ChrSpecs.dbc`
  (specializations and their identity passive), read from the client DBC set. `CharacterAdvancementEssence.dbc`
  gives the cumulative point budget: key = class id (12–32), all match flags 0, one row per level. At level 10
  the class tree has 1 point, at 11 both trees have 1, at 60 it is 26/25, at 80 36/35. Every paid entry costs
  1 point per rank; automatic entries (both costs 0, not a selectable free group) are granted by
  `SynchronizeProgression`, never bought.

## Specialization names: internal token vs displayed name

`ChrSpecs.dbc` carries **two** name columns and they are not interchangeable:

- field 2 — the internal token (`DISPLACEMENT`, `FIREARMS`, `MOONBOW`…), matching
  `CharacterAdvancementTabTypes.dbc` field 1. This is the join key: `LoadCoATalentData` maps a
  `CharacterAdvancement` row's tab to a spec through (`ChrClasses` token, tab token), all uppercased.
- field 29 — the name the client displays. **The core never reads it**: `LoadCoATalentData` loads
  `ChrSpecs.dbc` with 29 fields, so index 29 is out of range by one, and the field is also absent from the
  talent wire form.

For **36 of the 101 specs** the two differ, so the internal token is not a safe label for a spec in an issue,
a PR description or a report. The Chronomancer is the trap, because its three names are also offset against
each other:

| Spec id | Internal token | Displayed | Skill line |
|---|---|---|---|
| 31 | `DISPLACEMENT` | Time | 81 `Time` |
| 32 | `DUALITY` | Infinite | 79 `Infinite` |
| 33 | `TIME` | Artificer | 80 `Artificer` |

An audit grouped by internal token therefore files the Artificer wand talents under a heading reading "Time",
which a player reads as wrong data (PR #4324). Tab 87 `Class` is the shared class tree and belongs to no spec.

When naming a spec for a human, read field 29 (or `SkillLine.dbc`, which uses the displayed names); when
joining tables, use field 2.

## Talent rules

`SetTalentRank` is the one owner of the rules: class, active specialization, rank count, level, automatic entries
immutable, budget. A rank above the held one must fit the tree's budget (`Spent` over the known entries versus
`GetCoATalentBudget`). A native upload must also pay for omitted ranks before any state changes;
`IsUnpricedRemoval` excludes automatic entries and archetype signatures, while original FREE_UNLEARN entries
and characters at level 10 or below have no removal charge. `SwitchSpecialization` removes every class talent
spell when the specialization changes, then grants the new specialization's automatic entries. `ResetPaidTalents` removes every paid rank of the class; automatic grants
and the specialization stay. Clients reach them only through the native packets below; there is no chat command.

## Stored builds

Native uploads are complete wanted builds, including archetype switches. They do not restore omitted purchases
from an archetype's history after budget validation. `ApplyKnownEntriesUpload` uses
`SwitchSpecialization(..., restoreStoredBuild = false)` and applies the validated uploaded ranks. Saved
specialization slots remain independent presets and restore their complete validated entries and action bars.
Legacy archetype records in `core.ascension_build.<spec>` are separate from those slot records; they cannot
inject additional ranks into a native upload. The active spellbook remains the truth at login.

## Specialization slots and Tomes

CoA classes use the original 20-slot client container. Slot I is unlocked on login; Tomes II–XX teach the
remaining spells in `AscensionWildcard::SPECIALIZATION_SWAP_SPELLS`. Reading a Tome requires the previous
unlock, consumes the item on success and leaves the active build untouched. Already-owned unlocks refuse
item use. The pending world migration restores the original `ItemAddon.dbc` / `ItemSpells.dbc` mappings,
creates the four missing server templates for Tomes IX–XII and stocks the existing Bazaar vendor.

Casting an unlocked slot's original spell runs its normal five-second cast and interruptions. The server
intercepts `SPELL_EFFECT_TALENT_SPEC_SELECT`, validates the target build with the native upload rules, then
saves the outgoing archetype, purchased/free-choice ranks and all packed action buttons. New slots have no
archetype or purchases. Saved builds must fit the character's current level and point budget; a refusal
preserves the active slot. Archetype switching guards also apply when entering an empty slot.

`core.ascension_slot.active` stores the active index. `core.ascension_slot.<index>` holds a versioned record
with class, archetype, entries and actions, without a fixed entry cap. The active slot is refreshed on every
player save. A slot switch saves spells, action buttons and settings through the normal character transaction;
login reads the active spellbook and action bar rather than reapplying a stale snapshot. Slot I retains the
legacy `core.ascension_build.<spec>` / `core.ascension_bar.<spec>` archetype histories; the other slots use
`core.ascension_slot.<index>.build.<spec>` / `.bar.<spec>` so histories cannot leak between slots. Class
changes invalidate all these records and reset the active slot, preserving purchased unlock spells.

These slots use the existing native packets and client spells. They do not implement named loadout requests
`0x0778`–`0x077A` or the Mystic Enchant profiles also mentioned in the original Tome descriptions.

## The client's character-advancement service (Extensions.dll)

Opcodes and layouts come from the reconstructed `Extensions.dll` (`firstoni-dev/ascension-extensions-reconstruction`,
`docs/DLL_REFERENCE.md`, module `AscCAMgr`); the client build is the authority.

- `SMSG 0x0725` active specialization: `u32 slotIndex, u32 slotCount`. Its first arrival builds the
  per-character container the next packet needs, so it always goes first. CoA classes receive the active index
  and capacity 20; the original learned spells gate access to locked slots. The
  client does not read the specialization from it: `GetActiveChrSpec` is the first `ChrSpecs` row whose identity
  entry (+0x70, `CoASpecialization::IdentityEntryId`) the build holds.
- `SMSG 0x0726` known entries: `u32 count`, then `u32 entryId, u32 rank, u32 0, u8 0, u32 0, u32 0` per record.
  Always the complete set; the client diffs it, fires `ASCENSION_KNOWN_ENTRY_UPDATED/REMOVED` and answers
  `C_CharacterAdvancement.IsKnownID` / `GetTalentRankByID` from it. Sent after the initial 0x0725 and again
  after every upload, reset, specialization switch and level change.
- `CMSG 0x0727` known-entries upload (`ApplyPendingBuild`): same records, the client's complete wanted set (an
  unlearn is a smaller set, never a delta). It arrives on the network thread (`CanPacketReceiveEarly`), so it is
  queued by account and applied on the player's own update. `SwitchActiveChrSpec` only edits the pending build:
  it drops the old specialization's entries and adds the new identity entry and the entry of the
  specialization's signature spell (`ChrSpecs` +0x60, `SignatureEntryId`). `SpecializationOf` reads the
  specialization from the upload's ranked specialization entries; entries of two specializations refuse it.
  `ApplyKnownEntriesUpload` validates every row, the budget and removal payment before switching, then applies
  the complete uploaded set. An identity-and-signature-only upload leaves other purchases absent, including
  when returning to a previously used archetype. A saved slot supplies its own complete build and skips
  ordinary unlearn charges. The native switch
  helper also removes the departed specialization's shared signature, matching the DLL's `LeaveSpec`.
  The server prices the state the set leads to (including ranks the
  progression pass hands back to omitted entries) and applies removals before additions through
  `SetTalentRank`; an upload that changes nothing still runs the progression pass. Any failure refuses the
  whole upload. 0x0726 always follows, then `SMSG 0x072C` {result, learn result, u32 entry, u32 rank}
  (`CHARACTER_ADVANCEMENT_UPDATE_ENTRIES_RESULT`): `CA_UPDATE_ENTRIES_OK`, or `_BAD_ENTRY` (unknown or
  foreign entry, rank past the entry, missing server spell, mixed or invalid specialization),
  `_NOT_TRAVERSIBLE` (`CA_LEARN_LOW_LEVEL`, `CA_LEARN_GROUP` for mutually exclusive free choices,
  `CA_LEARN_MISSING_AE` / `_TE` over budget) or `_UNKNOWN`
  (malformed upload, missing budget row). The CoA frame plays its apply sound on success; the general CA
  frame shows a refusal as a red error.
- `CMSG_UNLEARN_TALENTS` (0x0213, `C_CharacterAdvancement.UnlearnAllTalents`): queued with the uploads in
  arrival order and handled by `ResetPaidTalents`, then 0x0726 and `SMSG 0x072B` with `CA_PURGE_TALENTS_OK`,
  `CA_PURGE_TALENTS_NO_PURGE_ITEM` when the original item, mark or gold price cannot be paid,
  or `CA_PURGE_TALENTS_NO_KNOWN_TALENTS` when nothing was removed. Successful paid removals and purges raise
  the reset counters sent in SMSG 0x0926; an unaffordable upload answers `CA_UPDATE_ENTRIES_BAD_UPDATE_COSTS`
  without modifying the build. The CoA talent frame resets through
  `ClearPendingBuild` and an upload instead.
- `CMSG 0x06E1` inspect (`C_CharacterAdvancement.InspectUnit`, u64 guid): `SMSG 0x06E2` answers a `CA_INSPECT_*`
  string; on `CA_INSPECT_OK` the guid, active slot index, slot capacity and the target's known entries in the
  0x0726 layout.
  Missing, not-in-world and out-of-range (`INSPECT_DISTANCE`) targets get their own results.
- Timing: the client keys this state off its local player object, which does not exist during the loading
  screen. `OnPlayerLogin` only queues the state; the first `CMSG_SET_ACTIVE_MOVER` of the session sends it
  (`OnPlayerActiveMover`). The Ghost harness login never sends that packet: a test that needs the state calls
  `bot.ActivateCharacterAdvancement(t)` after registering its packet hook.
- Opcode identities: `0x0523` is `CMSG_CUSTOM_ASCENSION_POINT_SPEND_REQUEST`, `0x061A` is
  `CMSG_CREATURE_QUERY_BULK`, `0x064A` is `SMSG_PATCH_CHARACTER_ADVANCEMENT` (unused: the client loads its own
  catalogue). Despite its name, `0x0523` carries no talent points: its five senders are the vanity-collection Lua
  functions (`C_VanityCollection` and `RequestDeliver*CollectionItem`), each writing
  `{u8 Enum.VanityCurrency, u32 item}`. Currency 2 (Donation Points) comes from both Deliver and the web-shop
  buy; the server handles it as a delivery through `DeliverVanityItem`.

## Checks

- `python -B tools/verify_all.py --stages harness --harness talent_state`: budgets, rank derivation, point
  accounting, packet layout, upload parsing and the specialization each upload selects, compiled against the
  real catalog, plus uncapped slot record serialization and malformed-record rejection.
- Gameplay scenarios pick specializations and ranks with the `specialization` and `advancement_rank` actions,
  which inject the same 0x0727 upload through the early packet hook.
- `character-advancement-specialization-*` scenarios cover independent builds, full action bars, native
  cast refusals, all Tome unlocks, large saved builds, real database relogs and class-change invalidation.
- Ghost `e2e/coa/talents/authority_test.go`: persistence across a relog, budget refusal, reset, the 0x0725/0x0726
  sequence and the 0x0727 upload against a running slot.
