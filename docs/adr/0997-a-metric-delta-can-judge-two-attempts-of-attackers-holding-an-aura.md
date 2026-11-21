# 0997. A metric delta can judge two attempts of attackers holding an aura

- Status: accepted
- Date: 2026-11-17
- Builds on: ADR 0582, ADR 0625

## Context

Witchblight 681220 (owner ruling O-39, Witch Hunter ADR 0022 amendment) makes a holder's next damaging spell or special
attack miss and removes the aura. A regression has to cast the spell from the holder at the Witch Hunter and read each
attempt: the first must miss, the aura must be gone after it, and the next attempt must land as without the aura. No
kind does this: `taken_outcome` reads melee swings only; `taken_hit`, a `metric_delta` strike and `script_hit` set
auras on the caster, not on the striker; `aura_keep_rate` is caster-side and refuses a 0% keep chance. The fu-sfwb
diagnostic (exploratory, pair 20261117-071702 / -071738) measured that shape by hand. Mentor D-417 approved an opt-in
option with its own verdict.

## Decision

A `metric_delta` option module `attacker_attempts` (ADR 0582 option, opt-in): `{"spell", "trials", "wait_ms"}` (optionally `"attacker_auras": [ids]`, mentor D-420 a) builds an
aura arm of `trials` trials between two control arms of `ceil(trials / 4)` trials, 8 passive attackers casting the
spell twice per trial, with per-attempt SPELL_GO, damage log and aura reads. Its verdict replaces the metric delta's for
the entries that set it: `ok` iff no first attempt lands, the aura is gone after all of them and the second attempts'
landed share lies within +-5 points of the pooled control (99% Newcombe, Wilson per arm); a landed first attempt, an
aura left on, or a second attempt more than 5 points from the control alerts; a missing read, an attempt without
exactly one SPELL_GO, or a `pre` read that disagrees with its arm is unmeasured. The entry reads `spell_log_count`, an
event metric, so the audit counts it as behaviour. Provisional number, renumbered at merge (14.4).

## Consequences

- Seeded tests in `metric_delta_options/test_attacker_attempts.py`: the scenario shape, no attacker without the option,
  a passing reading, three alerting mutants (a landed first attempt, an aura left, a second attempt far from the
  control), unmeasured missing and silent reads, refused inputs.
- `attacker_auras` (D-420 a, category A of D-293, inert when unset): each attacker receives every listed aura once before
  the first arm, the trial loop never removes it, and a per-attacker read must show it (missing or 0 is unmeasured).
  A hit aura brings the control landing rate to about 100%, which narrows the interval of the second attempts.
- One scenario holds at most 10,000 steps, so `trials` stays at or below 74 (91 steps per aura trial, 83 per control
  trial); the fixture refuses more. Without a fixture, at the landing rates of the fu-sfwb diagnostic (96.8% spell,
  94.8% special attack) a second attempt at the control rate fails the +-5 band 3.8% (spell) and 37% (special attack)
  of pairs at 74 trials, above the 0.1% of D-343; the Witch Hunter entries therefore set the fixture.
- `running` and `landed` (fu-tick, owner ruling O-41 relayed by mentor D-413, category A of D-293, inert when unset):
  `"running": {"spell": D, "wait_ms": W}` makes every attacker cast `D` at the caster at the start of every trial of
  every arm, before the aura is set in the aura arm, and reads one window of `W` ms: `D` on the caster (`dot`), its
  periodic damage count and logged total per attacker (cumulative `spell_damage_count` / `spell_damage_total` with
  `periodic`), the caster's health before and after, and the aura on each attacker (`held`); `D` is then removed from the
  caster. The running part alerts when an aura-arm window leaves the aura gone, when the aura arm's pooled health loss
  is more than 5% from its logged ticks, or when its mean tick is more than 5% from the control mean; a window without
  `D` or without a tick, or a control health loss more than 5% from its logged ticks, is unmeasured.
  `"landed": "aura"` reads an attempt as landed when its spell is on the caster from that attacker after it (instead of
  the damage logs) and removes it from the caster after every attempt read, so a damage over time attempt is judged.
  Seeded tests: a passing window, three alerting mutants (a tick removing the aura, zeroed ticks, weaker ticks),
  unmeasured windows, the landed read and its alert, refused inputs. Scenario digests of entries without the fields are
  unchanged. With `running` an aura trial takes about 150 steps, and the summed waits stay under the 600 s real-clock
  timeout of `run.py validate` at 36 trials of 3500 + 2 x 2800 ms.
- `shield`, `running.tick` and `landed: "periodic"` (fu-ondmg, owner ruling O-41 and mentor D-425/D-426, category A of
  D-293, inert when unset):
  - `"shield": {"spell": S, "wait_ms": W, "caster_auras": [ids]}` reads a damage shield of a holder. In every trial of
    every arm, after the `pre` reads, one attacker in turn (`attacker1` to `attacker8`) receives `S` (read back as
    `on`), the caster auto-attacks it for `W` ms and stops; the caster's SMSG_SPELLDAMAGESHIELD count (opcode 591,
    `server_packets`) before and after, the last such packet's damage (word 5, `server_packet_u32`), the caster's health
    before and after, and the aura on the struck attacker (`held`) are read, then `S` is removed. `caster_auras` are set
    on the caster once before the first arm and read back. A window without a shield packet (the swing missed, was
    avoided or the shield was resisted) is left out. The shield part alerts when an aura-arm window with a packet leaves
    the aura gone, when the aura arm's pooled health loss is more than 5% from its packets times their damage, or when
    its mean loss per packet is more than 5% from the control mean; an arm without a packet, a control health loss more
    than 5% from its packets, the aura on a struck control attacker, or a missing fixture read is unmeasured. The
    harness keeps the first 256 payloads per opcode, so the damage word is read from the latest of those: the entries
    use a shield of fixed damage. `shield` and `running` are refused together.
  - `"running": {..., "tick": T}` reads the running effect's damage as the logs of its triggered tick spell `T`
    (`spell_damage_count` / `spell_damage_total` of `T`, without the periodic filter) instead of the periodic logs of
    `D`, for a periodic trigger aura whose ticks are cast spells.
  - `"landed": "periodic"` reads an attempt as landed when the cumulative periodic damage count of its spell from that
    attacker at the caster grows over the attempt (`ticks`), for a persistent-area damage over time whose aura lives on
    a dynamic object; the attempt wait must cover the area's duration so that no tick spills into the next attempt.
  - Seeded tests: the shield scenario shape (one struck attacker per trial, the shield set and removed, three packet
    reads per window, the caster fixture), a passing shield reading, two alerting mutants (a shield removing the aura,
    zeroed shields), a left-out window and an unmeasured arm, an aura on a struck control attacker and a missing caster
    fixture; the tick read without the periodic filter; the periodic landed read with its pass and alert; refused
    inputs. Scenario digests of entries without the fields are unchanged.
- `landed_tick` (fu-chan, owner ruling O-41, mentor D-427 and review26 I-1, category A of D-293, inert when unset):
  `"landed_tick": T`, only with the default `landed: "logs"`, reads an attempt as landed when the damage logs of the
  triggered tick spell `T` from that attacker at the caster grow over the attempt (`spell_log_count` of `T`), for an
  attempt spell that applies a periodic trigger aura and deals its damage through `T` (a damage over time on the target
  or a channel of pulses on the attacker). After every attempt read the attempt spell is removed from the caster and
  from the attacker, so the next attempt starts without it; the wait is sized to the first tick. Seeded tests: the read
  of `T`, the two removals per attacker and attempt, a passing reading, two alerting mutants (a landed first tick, the
  aura kept after it), the logs read of an entry without the field, refused inputs. Scenario digests of entries without
  the field are unchanged.
