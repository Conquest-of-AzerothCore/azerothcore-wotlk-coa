# Avoided-swing reads (`behaviour_metric_delta`, `kind: "avoided_swing_reads"`, ADR 1259, provisional)

An effect that a dodged swing casts, read on the caster or a grouped ally rather than counted as a proc. `strikers`
aggressive stationary strikers (`striker_entry`, `striker_auras`, as the avoided proc trigger of `proc_avoided`) swing
at the caster, whose dodge and parry are set to 100% and 0% before every `swing_ms` window, so every swing is dodged.
Optional `learn` spells are learned before the engage. `control_windows` windows run before `spell` is learned, then
the control reads; `windows` windows run after the learn (mentor D-67: the treatment arm learns the passive). The
caster is then relocated 20 yd along x and waits 200 ms, so the stationary strikers stop swinging, its distance to
every striker is read, the avoided guards (no landed or blocked swing, no own swing since the engage) are asserted, and
the treatment reads follow.

The expected value comes from the server DBC of `observe_spell`, never from the entry. `read` is one of:

- `aura_edge`: the radius of `observe_spell` effect `effect`. Two grouped allies stand at radius - `margin_yd`
  (default 0.5) and radius + `margin_yd` along x. `ok` when the inner ally holds `observe_spell` after the treatment
  and the outer one does not; a player ally of a player caster gets no combat reach on a SRC area search
  (`Spell.cpp` `WorldObjectSpellAreaTargetCheck`).
- `stat_delta`: the value of `observe_spell` effect `effect`. One grouped ally at `ally_yd` (at least 10 yd, out of
  the strikers' reach). `ok` when its `metric` (`melee_crit_chance`) after the treatment less the control read lies
  within 0.01 of the value, and it holds the aura. Opt-in `baseline_read: true` reads the stat once more after the
  engage, before the control windows: the control read, taken after the dodges with the passive not yet learned, must
  equal it within 0.01 or the check alerts. With it, the tool stamps the learned contrast (`contrast: learned`, ADR
  1273, provisional) when the generated step list holds the baseline read, dodges, the control read, the single learn
  of `spell`, dodges and the treatment read in that order; no entry field sets the stamp.
- `duration_max`: the duration of `observe_spell`. One grouped ally at `ally_yd`; its remaining duration of
  `observe_spell` (`aura_duration_ms`) is read after every treatment window. `ok` when the largest read lies in
  `[duration - swing_ms - 100, duration]`: no read exceeds the full duration, and a read in the window after an
  application is at most one window and one 100 ms tick below it, so a duration 10% shorter or longer reads outside.
- `expiry_edge`: the duration D of `observe_spell` (ADR 1273, provisional). One grouped ally at `ally_yd`. The
  caster's dodged swings (`melee_attacks_taken`, dodged) are counted before the last treatment window, after the
  quieting relocation and at the end. After the relocation the caster's `melee_attack_taken_last_ms` (dodged) stamps
  the game time of the last dodge; `game_time_ms` is read before and after each of the ally's two `aura` reads of
  `observe_spell`, set about 0.9 D and D after that dodge. With h the game time before the held read and g the game
  time after the gone read, both less the dodge stamp, the run is void unless 0.9 D <= h, h + 100 < D <= g' (g' the
  game time before the gone read less the stamp) and g + 100 < 1.1 D, where 100 ms covers the dodge packet's lag
  behind the server's dodge. `ok` when the aura is held and then gone, which places D in (h, g + 100] ms of the last
  dodge: a duration 10% shorter or longer fails. Also void when the last window holds no dodge or a dodge follows
  the relocation. Requires `swing_ms + 200 < 0.1 D`. The ally's remaining duration at the stamp read gives a packet
  lag estimate in the explanation, not judged.
- `per_event`: the value of `observe_spell` effect `effect`. The caster's `spell_energize_total` and
  `spell_energize_count` of `observe_spell`; `ok` when the total equals the count times the value exactly over at
  least `min_events` (default 20) events after the learn. The energize log carries the uncapped amount
  (`Unit::EnergizeBySpell`).

An aura on an ally or an energize event before the learn alerts. `unmeasured` (void) on a missing read, a refused cast,
an ally more than 0.05 yd from its place, a caster within 17 yd of a striker after the relocation, or fewer than
`min_events` energize events.

Felsworn: Betrayer 300476 (Betrayer 520256 on the party: radius, critical strike chance and duration) and Illidari
Training 805249 (521210 Energy per dodge).
