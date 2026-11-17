# Attacker attempts (`metric_delta` `attacker_attempts`, ADR 0997)

`attacker_attempts` (`{"spell": S, "trials": T, "wait_ms": W}`, optionally `"attacker_auras": [ids]`) replaces the entry's phases with three arms in which
8 passive attackers (`attacker1` to `attacker8`, the dummy's creature entry, level of the class file, 3 yd) each cast
`S` at the caster twice per trial, `W` ms apart; the caster's dodge and parry are forced to 0. Before every trial the
entry's `spell` aura is removed from each attacker and, in the `aura` arm only (`T` trials), set again and read back
(`pre`); the two control arms (`control` first, `control2` last, `ceil(T / 4)` trials each) run without it. After
every attempt the attacker's SPELL_GO count of `S`, its damage logs at the caster and the aura on it are read.

`attacker_auras` (distinct spell ids read from the DBC) is a precondition fixture, inert when unset: each attacker
gets every listed aura once (stacks 1) before the first arm, the trial loop never removes it, and one read per
attacker and id follows; a read missing or at 0 makes the verdict `unmeasured`. A hit aura brings the control landing
rate to about 100% (a spell hit needs `SPELL_AURA_MOD_SPELL_HIT_CHANCE` or `SPELL_AURA_ASCENSION_MOD_HIT_CHANCE_ALL_PCT`,
a special attack's melee roll `SPELL_AURA_MOD_HIT_CHANCE`), which narrows the interval of the second attempts.

`running` (`{"spell": D, "wait_ms": W}`, inert when unset) reads an effect that runs before the aura: at the start
of every trial of every arm each attacker casts `D` at the caster, `D` on the caster is read back (`dot`), the aura is
then set in the `aura` arm only, and over `W` ms the periodic damage of `D` at the caster (count and logged total per
attacker), the caster's health before and after, and the aura on each attacker (`held`) are read; `D` is then removed
from the caster and the two attempts follow. `landed: "aura"` (default `"logs"`) reads an attempt as landed when its
spell is on the caster from that attacker after it, and removes that spell from the caster after every attempt read,
so a damage over time attempt is judged. `landed: "periodic"` reads an attempt as landed when the cumulative periodic
damage count of its spell from that attacker at the caster grows over the attempt (`ticks`), for a persistent-area
damage over time; the wait must cover the area's duration.

`landed_tick` (a spell id `T`, inert when unset, only with the default `landed: "logs"`) reads an attempt as landed
when the damage logs of the triggered tick spell `T` from that attacker at the caster grow over the attempt, for an
attempt spell that applies a periodic trigger aura (a damage over time or a channel of pulses); after every attempt
read the attempt spell is removed from the caster and from the attacker (a channel's own aura), so the next attempt
starts without it. The wait should cover the first tick only.

`running` takes an optional `tick` (`{"spell": D, "wait_ms": W, "tick": T}`): the window then reads the damage logs of
the triggered tick spell `T` (no periodic filter) instead of the periodic logs of `D`.

`shield` (`{"spell": S, "wait_ms": W}`, optionally `"caster_auras": [ids]`, inert when unset, refused with `running`)
reads a damage shield of a holder: in every trial of every arm, after the `pre` reads, one attacker in turn
(`attacker1` to `attacker8`) gets `S` (read back as `on`), the caster auto-attacks it for `W` ms and stops; the caster's
SMSG_SPELLDAMAGESHIELD count (591) before and after, the last such packet's damage (word 5), the caster's health before
and after and the aura on the struck attacker (`held`) are read, then `S` is removed. `caster_auras` are set on the
caster once before the first arm and read back. A window without a shield packet is left out. The harness keeps the
first 256 payloads per opcode: use a shield of fixed damage.

The entry reads `spell_log_count` at the caster, so the audit counts it as behaviour through its events. It sets no
strike, setup casts, forced chance or attack swings.

Verdict (its own, for entries that set the option):

- `alert` when a first attempt of the `aura` arm lands or leaves the aura on;
- `ok` when no first attempt lands, the aura is gone after every one of them, and the 99% Newcombe interval (Wilson
  per arm) of the second attempts' landed share against the pooled control attempts lies within +-5 points;
- `alert` when that difference is more than 5 points, `measured` (not final) when its interval crosses the band;
- `unmeasured` when a read is missing, an attempt sent other than one SPELL_GO, or a `pre` read disagrees with its arm.
- With `running`: `alert` when an `aura`-arm window leaves the aura gone, when that arm's pooled health loss is more than
  5% from its logged ticks, or when its mean tick is more than 5% from the control mean; `unmeasured` when a window has
  no `D` on the caster or no tick, or when the control health loss is more than 5% from its logged ticks.
- With `shield`: `alert` when an `aura`-arm window with a shield packet leaves the aura gone, when that arm's pooled
  health loss is more than 5% from its packets times their damage, or when its mean loss per packet is more than 5% from
  the control mean; `unmeasured` when an arm has no window with a packet, when the control health loss is more than 5%
  from its packets, when a struck control attacker carries the aura, or when a fixture read is missing.

Named points: `check`, `fixtures` (refuses more than 10,000 steps), `model`, `verdict`.

One scenario holds at most 10,000 steps (the harness limit): an `aura` trial takes 91 steps and a control trial 83, so
`trials` stays at or below 74 (the fixture adds 2 steps per attacker and id once).
With `running` an `aura` trial takes about 150 steps; the summed waits must also stay under the 600 s real-clock
timeout that `run.py validate` applies.
