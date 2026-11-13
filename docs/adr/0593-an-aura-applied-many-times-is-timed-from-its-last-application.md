# 0593. An aura applied many times is timed from its last application

- Status: accepted
- Date: 2026-11-13

## Context

March of the Dead 707007 raises six walkers that explode at unknown times and each apply 707010 ("for $707010d",
claim 206.1). An expiry pair from the cast measures the first walker, not the duration (design T8). `aura_apply_count`
already counts every new aura and every refresh (`OnAuraApply` from `Unit::_AddAura` and the refresh path), so a
stamped poll of it locates the last application without new harness code.

## Options

1. A harness stamp of the last application (new recording, C++ beyond a read).
2. A kind that polls the game time, the apply count and the aura's presence together.

## Decision

Option 2, kind `last_application_expiry`: the trigger cast before `gate_spell` is learned (control) and after it;
`poll_ms` reads over the window. The duration is bracketed from the two reads around the last rise of the count to the
two reads around the aura's removal and judged in the G-19 band.

## Consequences

- 206.1 at 25 ms polls: pilot 20261113-150027 read 2996 to 3070 ms after the last of 6 applications (ok).
- Slower polls widen the bracket; a bracket across a band edge is unmeasured, not ok.
