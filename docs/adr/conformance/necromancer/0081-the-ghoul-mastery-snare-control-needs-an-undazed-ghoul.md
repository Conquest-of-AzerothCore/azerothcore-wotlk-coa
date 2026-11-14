# 0081. The Ghoul Mastery snare control needs an undazed Ghoul

- Status: accepted
- Date: 2026-11-14

## Context

Claim 389.0, Ghoul Mastery 503740: "chance to transform them into a Frenzied Ghoul." The control entry
`snare_control` read the Ghoul 50073's run speed rate 0.57143 before the learn in cycle 14 run 1 (record ok / ok, the
scenario unchanged), against 1.14286 in every other stored run. The striker is a defensive fixture (reaction 1) next
to the dummy. Once it is in combat its melee from behind casts Dazed 1604 (Unit.cpp:2315-2346; Effect[0] aura 33,
BasePoints -51, the same -50% as Hamstring 1715). Diagnostics with the aura listing read (ADR 0652): 0 of 240
isolated copies (20261114-030859, -031054), and 1 of 240 copies mixed with 720 generated scenarios (20261114-031546),
held 1604 at the before reading. That copy read 0.57143, and the caster's GUID matched the striker that cast 1715 later.
In the after phase 11 of 480 copies also held the striker's 1604 next to Hamstring, at the same -50%.

## Decision

`snare_control` sets `before_aura_absent` {1604, 50073} (ADR 0653): a control that holds Dazed is unmeasured, not a
failed claim. No server change: Dazed from behind is the engine's rule for a creature's melee.

## Consequences

- The `snare_control` scenario gains one read before the before reading; the Necromancer digests are refreshed.
- A dazed control still leaves 389.0 unproven in that run; it is no longer an alert.

## Addendum (cycle 16)

The `frenzied_snare_immune` entry of 503740 takes the same striker and the same untouched before phase (no talent, no
strike, before the Frenzied transform), so it can read the same Dazed 1604 at 0.57143 and alert. It sets
`before_aura_absent` {1604, 50073} too. The after phase is unchanged: a Dazed after the transform is not read
(whether 707014's snare immunity, Effect[2] aura 77 MiscValue 11, covers Dazed's mechanic is not read), and the
after reading is the one the Hamstring strike produces.

## Addendum (cycle 18)

The striker is pulled by the Ghoul itself: the Command makes the Ghoul cast Command: Ghouls 801514 (enemies within
10 yd of the Ghoul), which damages the striker; the defensive striker then melees the Ghoul and can daze it from behind.
Diagnostic 20261114-080834 showed this in 240/240 mixed copies, with 1604 in 5/240. That is game behaviour, so no
server change. Both 503740 entries now set the strike `reaction` 0 (ADR 0654): in 20261114-082317 the passive striker
made no swing and no copy held 1604. `before_aura_absent` stays as the guard.
