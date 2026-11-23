# 0349. Minion cooldown windows can open after a settle

- Status: accepted
- Date: 2026-11-13

## Context

Study of Death 704721 states "Frost and Physical damage dealt by your Undead minions now reduces the cooldown of
Unholy Frenzy by 0.5 sec". The minion `cooldown_delta` kind (ADR 0342) casts the observed spell and reads its cooldown
and the minion's counted events right away. Each Unholy Frenzy cast with 704721 known raises 5 Greater Zombies for
15 s (AscensionNecromancerAbilities.cpp:346-353). Their hits share the talent's 1 s gate
(AscensionNecromancerEvents.cpp:206-212) and are not the counted Ghoul's events, so a window right after the cast
reads about one cut per second, not one per Ghoul event.

## Options

- Count every minion's events: the 1 s gate still binds, so the cut per event would not be the stated value.
- Kill or dismiss the zombies with a harness action: a fixture that removes part of the cast's own effect.
- Wait after each observed cast until what it raised has expired, then open the window.

## Decision

A minion `cooldown_delta` entry may set `observe_settle_ms`, a non-negative integer. Each window then waits that long
after the observed cast before its first read; the attempt interval grows by the same amount, and the rule names the
wait. Entries without it generate unchanged (Templar `generate --class 19` and `--stack` byte-identical).

## Consequences

- Study of Death's per-event cut reads 505.7 and 506.1 ms per Ghoul damage event over 430 and 401 events (stated 500)
  and 0 without 704721, counted pair 20261113-003906/-003946, build b0d0ace11c2b, with a 17000 ms settle.
- A `cooldown_ms` read stays data evidence (ADR 0342); a behaviour proof of the 0.5 s needs bracketing gates.
