# Dynamic XP

Experience-rate control for 3.3.5a, vendored from
[azerothcore/mod-dynamic-xp](https://github.com/azerothcore/mod-dynamic-xp) with the
additions described below.

## Players

| command | effect |
| --- | --- |
| `.xp` | shows your rate and where it comes from |
| `.xp <rate>` | your own flat rate, one of `Dynamic.XP.Preset.Allowed` (default `1` to `5`) |
| `.xp default` | drop your choice and follow the realm again |

The choice is stored per character (`core.dynamic_xp.preset` in `character_settings`), so
it survives relogs and restarts. Players who never pick a rate follow the realm value. A character
that stored a rate the list no longer offers (for example `7` or the old per-band curve) is put
back on the realm rate at login, and stays there if that rate is offered again later.

## Game masters

| command | effect |
| --- | --- |
| `.xp realm` | shows the realm rate |
| `.xp realm <rate>` | sets the realm rate, one of `Dynamic.XP.Preset.Allowed` |

The realm rate is written back to `dynamicxp.conf` and is the default for every character
without a choice of its own; changing it leaves personal rates alone.

## Configuration

All keys live in `conf/dynamicxp.conf.dist`:

- `Dynamic.XP.Preset` - the realm rate (default `1`, no bonus); a rate the allowed list does
  not offer falls back to `1`.
- `Dynamic.XP.Preset.Allowed` - the offered rates as a comma-separated list of whole numbers
  from `1` to `31` (default `1,2,3,4,5`); `1` is always offered.
- `Dynamic.XP.Preset.PlayerChoice` - `1` (default) lets players choose their own rate,
  `0` restricts the choice to game masters.
- `Dynamic.XP.Rate.Announce` - `0` (default) stays silent; `1` tells each player their
  rate on login.
- `Dynamic.XP.Reminder.Enable` - the realm-wide note about `.xp` (default `1`).
- `Dynamic.XP.Reminder.Interval` - minutes between reminders (default `40`, `0` disables
  the repeat).
- `Dynamic.XP.Reminder.Message` - the text of that note, sent as-is including colour codes;
  empty (default) lists the offered rates.

The reminder is announced when a player logs in and then every `Interval` minutes, and it
respects the per-player setting that turns automatic announcements off.

## The storage key

Keep the `core.` prefix on `core.dynamic_xp.preset` while `EnablePlayerSettings` is `0`:
`Player::_SavePlayerSettings` and `_LoadCharacterSettings` skip every source that does not
start with it, so a differently named key would be held in memory and lost on relog.
