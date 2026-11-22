# Last-application expiries (`behaviour_metric_delta`, `kind: "last_application_expiry"`, ADR 0593)

An aura applied several times at unknown moments (one March of the Dead walker after another) is timed from its last
application. `trigger_spell` is cast at the dummy before `gate_spell` is learned (control) and after it; every
`poll_ms` the game time, the dummy's `aura_apply_count` of `aura` (a new aura and every refresh) and its presence are
read over `control_window_ms` and `window_ms`.

The last application lies between the two reads where the count last rises; the aura's removal between the last read
with it and the first without. The bracket `(gone_prev - last, gone - last_prev)` must lie inside the G-19 band around
`expected_ms`; one entirely outside it alerts, one straddling an edge is unmeasured. A control application alerts; an
aura still on past the band at the window's end alerts.

## Caster aura, repeated trigger and no refresh (ADR 0716)

Three optional fields, absent by default:

- `caster: true` reads the aura, its application count (and its stacks) on the caster instead of the dummy.
- `repeat: {"count": N, "every_ms": ms}` casts the trigger N times per arm, `every_ms` apart, inside the arm's poll
  window (a short control window holds only the first cast). The last cast must fall inside the stated duration.
- `no_refresh: true` (with `repeat`) also reads the aura's stacks at every poll and judges "does not refresh": the
  treatment must count exactly one application (more alert: a later one refreshed or reapplied the aura) while the
  stacks rise to 2 or more (fewer is unmeasured: no later application was seen), and the duration is then timed from
  that single application. One poll precedes the first cast, so the first application is seen as a rise even when
  it lands before the first poll after the cast.

Witch Hunter: Torch the Wicked! 560226 `no_refresh` (560227 on the caster, Flames of Sin 802850 cast 4 times 1000 ms
apart, 6000 ms from the first stack; claim 103.0).

## Forced roll (opt-in)

`forced_roll: <talent spell>` (needs `repeat`) raises the roll of that talent with the ADR 0588 spell-modifier mutant for
the whole scenario, removed at the end and read gone (a modifier still active alerts), and refills the trigger's
power before every recast so a costly trigger can be repeated. Absent, the scenario is unchanged.

Witch Hunter: Anguish 504742 `anguish_duration` (Dusk Blade 802258 cast 6 times 1600 ms apart on the dummy, Anguish
500566 read on the caster, 15000 ms from the last application; claim 71.1).

## Trigger at the caster (opt-in, ADR 1132)

`trigger_target: "caster"` casts the trigger at the caster instead of the dummy, for a self-cast or summon trigger
whose aura is read on the caster (`caster: true`). Absent, the trigger is cast at the dummy as before.

Witch Doctor: The True Spirit 802268 `true_lasts` (Serpent Ward 500960 at the caster, The True God 681233 on the
caster, 10000 ms from its application).

## Poll before the cast (opt-in, ADR 1152)

`poll_before_cast: true` reads one poll right before the cast in each arm, so an aura applied at the cast itself (a
summon that casts it inside an instant trigger) is seen as a rise from that read and timed from the cast. Absent, the
first poll follows the cast as before (`no_refresh` always reads that poll).

Witch Doctor: The True Spirit 802268 `true_lasts` (The True God 681233 from the Serpent Ward summon).
