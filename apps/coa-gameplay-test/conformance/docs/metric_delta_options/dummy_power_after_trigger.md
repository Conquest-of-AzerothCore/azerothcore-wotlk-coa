# Dummy power after trigger (`metric_delta` `dummy_power_after_trigger`, ADR 1173, provisional)

`dummy_power_after_trigger` is `{"power": index, "value": n, "after_ms": ms}`, for an entry whose trigger is cast at
the dummy. `after_ms` after each trigger cast the dummy's power `index` is set to `value` (the harness `set_power`
with `target`, ADR 1173), and the entry's `wait_ms` follows; an uncast before phase sets it at the point of the
cast and waits `wait_ms` before its reading. The reading is then what the dummy gains in that window. Absent, the
scenario is unchanged.

Use it for a claim about a creature's power regeneration, separated from a drain the trigger also carries (a drain
finds nothing at 0).

Named points: `phase_steps`, `after_trigger_steps`, `fixtures`.

Witch Doctor: Mana Jinx 801925 `jinx_no_regen` (Mylentha Riverbend 11795 emptied to 0: at least 1622 mana regained in
7000 ms without the Jinx, 0 under it).
