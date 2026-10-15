# Client configuration

With `CoA.Enable` enabled, character login sends one `SMSG_COA_CONFIG` (`0x58D`) before the character is
added to the map, on a fresh login and on a reconnect to a character still in the world. Reloading world
configuration resends it to sessions with a player in the world.

`Extensions.dll` replaces its integer, boolean, float and rate maps with each packet, so every value has to
travel in the same packet. `BuildAscensionCoAConfig` collects the core's XP rates and every source registered
with `RegisterAscensionClientConfig`; modules add their values there instead of sending their own packet.

The packet follows the six-section layout from PR #4128, revision
`1340ce91e16b6583f608249c0630c90d709ffe07`: integers, booleans, floats, rates, integer vectors and float
vectors. Each section begins with a uint32 entry count. Entries contain a uint32 byte length, an ASCII key
without a terminator, and the value: int32, uint8, or IEEE-754 float. The vector sections stay empty.

Booleans:

| Key | Source | Value |
| --- | --- | --- |
| `CONFIG_ALLOW_TICKETS` | player tickets | `AllowTickets`, toggled by `.ticket togglesystem` |
| `CONFIG_CHARACTER_ADVANCEMENT_BUILD_INSPECT_ENABLED` | CoA | always on; shows the inspect frame's Build tab |
| `CONFIG_RECOVERY_VENDORED_ITEM_ENABLED` | `mod-item-recovery` | present while `ItemRecovery.Enable` is on |
| `CONFIG_CHALLENGE_ENABLED`, `CONFIG_CHALLENGE_CREATOR_ENABLED`, game-mode `_ENABLE` / `_HIDDEN` keys | `mod-coa-challenges` | present while challenges are enabled |

Rates, 31 supported XP settings:

- `RATE_XP_GLOBAL` and `RATE_XP_PROFESSION` come from `Rate.XP.Global` and `Rate.XP.Profession`.
- `RATE_XP_KILL`, `RATE_XP_KILL_TBC` and `RATE_XP_KILL_WOTLK` come from `Rate.XP.Kill`, `Rate.XP.Kill.TBC`
  and `Rate.XP.Kill.WotLK`; the quest keys likewise from `Rate.XP.Quest`, `Rate.XP.Quest.TBC` and
  `Rate.XP.Quest.WotLK`.
- `RATE_XP_EXPLORE`, `RATE_XP_ELITE` and `RATE_XP_DUNGEON_ELITE` come from `Rate.XP.Explore`,
  `Rate.XP.Elite` and `Rate.XP.DungeonElite`.
- `RATE_XP_PROFESSION_<DIFFICULTY>_MODIFIER` comes from the gray, green, yellow and orange settings.
- `RATE_XP_PROFESSION_<PROFESSION>_MODIFIER` comes from each of the 16 implemented profession settings.
  The client's `FIRST_AID` spelling maps to `Rate.XP.Profession.FirstAid`.

All values come from the core's validated, cached configuration, whose defaults equal the captured
realm's rates. The capture itself is not replayed.

The table describes realm base rates. Dynamic XP's player choices, XP buffs, and the provisional
`Rate.XP.Profession.BaseFraction` remain server-side; no verified client keys exist here for those values.
The packet does not make the client calculate an exact XP award or add a new visible UI panel.

`python -B tools/verify_all.py --stages harness --harness coa_config --harness challenge_config` compiles the
production builder and the challenges source with the real WorldPacket/ByteBuffer writer and isolated
world/session dependencies, and decodes the bytes independently. The `login-native-account-state` gameplay
scenario checks that a login sends exactly one config packet holding the rates and the booleans above.
