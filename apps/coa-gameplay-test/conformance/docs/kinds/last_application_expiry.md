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

## Feed (opt-in, Felsworn ADR 0003, provisional)

A grant that only a rolled proc earns, with no way to force the roll (Felsworn `Chance()` rolls the raw ProcChance,
`AscensionFelsworn.cpp:231-239`), is earned for real: `feed: {"every_ms": ms, "stop_aura": spell}` replaces the single
cast and `repeat` by the harness step `cast_until_aura` (owner-approved). `trigger_spell` is known in both arms and cast
every `every_ms` (at least the 1600 ms global cooldown wait) with its power and cooldown reset before each cast, until
`stop_aura` is on the caster (default `aura`, which then needs `caster: true`; name it when the judged aura sits on the
dummy). `max_casts` is computed from the ProcChance of `gate_spell`, one roll per cast: `ceil(ln 0.0005 / ln(1 - p))`,
47 at 15% and 9 at 60%, so a run without a grant is at most 0.05% likely. A loop that reaches its cap leaves the
treatment arm unmeasured (never a fail, never a pass). The control arm runs the same loop with the gate unlearned and
alerts on any application.

Each arm reads the game time, the application count and the presence of `aura` once before the loop; the treatment arm
cancels `stop_aura` on the caster first and is unmeasured when the aura is already on. After the loop it reads
`stop_aura` on the caster and the remaining duration of `aura` (`aura_duration_ms`, supporting data), then polls as
before. The grant is dated by the stop: the step checks the aura on every world update, so the first poll is at most
100 ms after it, and that read replaces the pre-loop read as the earlier end of the last application's bracket. The
verdict is the unchanged bracket test of the kind, the explanation names the remaining duration read at the stop.
The treatment arm reads the game time and opens an encounter timeline (`encounter_start` on the dummy) before its
loop, and after the stop reads `timeline_count` and `timeline_first_ms` of `aura_applied` for `aura` on its holder;
timeline stamps and `game_time_ms` share one game time base. The aura's age at the first poll is at most that poll's
game time less the start read and the first apply stamp. An `ok` is voided (`unmeasured`) when that age is above
100 ms, a stamp is missing, the stamped apply count is not one (a refresh or a second apply is not the stamped first
apply), or the remaining duration is not above 0 (mentor D-21, Felsworn ADR 0004): the 100 ms stamp is then not
proven. A failing bracket still alerts. The timeline is process global, so a fed scenario runs exclusive in a batch.
`feed` excludes `repeat`, `forced_roll` and `no_refresh`.

`same_stamp_applies: true` (with `feed` only; ADR 1289, provisional, mentor D-116 and D-117) accepts a stamped apply
count of two or more when the run's recorded timeline (`result.json` `timeline`, read into the run by `compare`) holds
exactly that many `aura_applied` events of `aura` on the holder and they all share one `at_ms`: the age is then taken
from that shared stamp and the explanation says so. Applies at different game times, a recorded count that differs
from the stamped one, or no recorded timeline keep the arm `unmeasured`. It adds no step; one apply is judged as
without it. Felsworn: Legionfall 801899, whose Annihilan Strike lands two strikes that each roll the grant.

`force_crit` (`melee`, `spell` or `ranged`) sets the matching crit and hit rating fixtures for both arms, so every
cast lands and is critical. `quote_spell` takes the
quote from the tooltip of a spell the entry's own tooltip embeds (`@s:N:`), as the window variant of `aura_fed_effect`
does.

Felsworn: Legionfall 801899 (Annihilan Strike 801903 feeding 801902, 15000 ms); Malice of Gul'dan 800214 (Fel Fireball
801312 every 2000 ms with spell crit and hit forced, feeding Felstrike 802678 on the dummy, 6000 ms, and Fragment of
Malice 800239 on the caster, 5000 ms).

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
