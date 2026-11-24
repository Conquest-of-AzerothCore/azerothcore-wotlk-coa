# Channel lengths (`metric_delta` `channel_lengths`, ADR 1275)

`channel_lengths` is `{"spell": end spell, "events": hits per channel, "cancel_ms": [at least 2 rising times],
"repeats": N}` on an entry whose trigger is the channel, cast at the dummy alone (no `area_dummies`), each cancel time
below the entry's `wait_ms`. After the after reading, the treatment phase is cast N times in all as the full channel,
then N times per cancel time with the plain wait after the trigger cast split by a `cancel_aura` of the channel (the
native `CMSG_CANCEL_AURA`, which interrupts the running channel) that many ms after the cast. A base read and a read
after each cast give the damage of `spell` on the dummy without critical, resisted or blocked hits, the count of those
hits and the count of all hits. Labels are `<spell> <metric> after channel <ms|full|base> <repeat> <read>`.

Judge (after the plain before/after judge, which it keeps): each cast must land `spell` `events` times (else alert);
the mean plain damage per length, over the casts with only plain hits, must rise strictly from the shortest channel to
the full one; a length with no such cast is `unmeasured`. A missing read alerts. It states no amount: a
direction-only claim (mentor D-100).

Named point: `verdict(verdict, run, value)` (`metric_delta_options.option_verdict`); `fixtures` adds the casts
and reads.

Felsworn: Carve 800206 `channel_lengths` (end slash 803715 after 650 ms, 1400 ms and the full channel, 5 casts each,
claim 204.0).
