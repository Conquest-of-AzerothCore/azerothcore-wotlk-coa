# 0006. The temporary Sun Ray is unlearned only once Scorch Marks is gone

- Status: accepted
- Date: 2026-11-22

## Context

Burning Heat 704908 streams the Sun Ray 504764 text: "Shine the light of the sun on an enemy, dealing
${$m1+0+$sph*1} Holy Damage and granting you Scorch Marks." Sun Ray Spell.dbc Effect[1] is TRIGGER_SPELL 807059
(Scorch Marks, DurationIndex 1, 10000 ms), and the class's cast hook also casts 807059 after a Sun Ray.

A player gets Sun Ray as a temporary spell: `Refresh` learns it while the marker 803238 is up and the Sunflare 800231
button is replaced by it. The Sun Ray cast consumes the marker, and the marker's removal runs `Refresh`, which called
`player->removeSpell(504764, SPEC_MASK_ALL, true)`. `Player::removeSpell` removes the aura of every TriggerSpell of
the removed spell (`Player.cpp:3776-3778`), so Scorch Marks was stripped right after the cast. Measured on the counted
pair of the b2a fix note: the player route (Horusath Blast 500154, then Sunflare turned into Sun Ray) read 807059 = 0
at 100 ms and at 6500 ms in both runs; the direct route, a harness-learned (permanent) Sun Ray that `removeSpell`
leaves alone, read 1. Live logs hold 296 applications of 807059 by players.

Mentor decision D-43 (2026-11-22) approved a fix in the class code only, with `Player::removeSpell` untouched, the
granted aura keeping its own duration and stacks, and a design that avoids the strip preferred over a re-apply.
Mentor decision D-46 (2026-11-22) added a cast check and an unlearn on the aura's end to that design (see Decision).

## Options

- Re-apply 807059 after the unlearn with the saved duration and stacks: the aura is removed and added again, its
  remove and apply handlers run, and it is accepted only if shown identical to the direct route.
- Unlearn Sun Ray outside the cast's aftermath: keep the temporary Sun Ray while 807059 is on the player and unlearn
  it on a later `Refresh`, when no Scorch Marks is left for `removeSpell` to strip.
- Change `Player::removeSpell`: shared engine code, refused by D-43.

## Decision

`Refresh` unlearns the temporary Sun Ray only when the replacement is over and the player holds no 807059 aura. The
aura the cast granted is never touched, so its duration and stacks are those of the direct route.

D-46 adds two parts in the class code:
- The removal of 807059, by expiry, consumption or any other removal, runs `Refresh` from the class's aura removal
  handler, so the temporary Sun Ray ends with the aura instead of on the next 500 ms refresh.
- The Sun Cleric cast check refuses a non-triggered Sun Ray 504764 with `SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW` when
  the marker 803238 is gone and the player's 504764 entry is the temporary one (`PLAYERSPELL_TEMPORARY`).

## Consequences

- The Sunflare button is restored as soon as the marker is consumed, as before; only the spell-map entry of Sun Ray
  stays while Scorch Marks is up (10 s, longer while another source refreshes 807059: a 500146 or Sunflare cast with
  806021, Dawn with 804625).
- Exploit concern, from code reading, not reproduced: without the cast check, the server would accept a crafted
  client packet casting the still-learned 504764 directly (`HasActiveSpell`, SpellHandler.cpp:461). Sun Ray is
  instant with no cooldown and no global cooldown in Spell.dbc, and each cast grants 807059 again, which would keep
  the unlearn deferred without end. The cast check closes it; the normal client has no Sun Ray button in that window.
- The check keys on the temporary entry, so a permanently learned Sun Ray is not refused. The harness `learn` action
  is a permanent `learnSpell`, so the class entries that learn 504764 and cast it without the marker are not refused
  and keep their route: for 704908 `scorch_granted_sunray`, `scorch_cost`, `scorch_period`, `scorch_duration`,
  `scorch_next`; for 806021 `free_cast`, `free_gate`, `faster_ticks`, `shorter_duration`, `shorter_held`,
  `shorter_gone`, `scorch_duration`. No hand-written scenario casts 504764. None is moved or dropped.
- The D-43 control is unchanged: the before phase of `scorch_granted` and `scorch_granted_early` lacks 704908,
  places no marker, keeps the Sunflare a Sunflare and reads 807059 = 0.
- Keyed to 504764 and 807059, both Sun Cleric spells only; no other class or engine file is changed.
- Regression: the 704908 entries `scorch_granted_early` (read 100 ms after the cast) and `scorch_granted` (6500 ms)
  of `apps/coa-gameplay-test/conformance/classes/sun_cleric.json`, both expecting 1 on the player route; control: the
  before phase without 704908 places no marker, the Sunflare stays a Sunflare and 807059 reads 0.
- Regression (D-46): `apps/coa-gameplay-test/scenarios/sun-cleric-sun-ray-temporary-cast-check.json`. On the player
  route, the temporary Sun Ray stays learned with Scorch Marks, a direct 504764 cast without the marker is refused
  (173) and completes no second Sun Ray; control: the same direct cast with the marker up completes. Removing 807059
  unlearns Sun Ray at once, and so does its expiry.
