# 0015. Twilight Frenzy can dodge and parry while channelling

- Status: accepted
- Date: 2026-11-16

## Context

Twilight Frenzy 805751 reads: "Spin around for $d, firing shots at nearby enemies [...]. Can dodge and parry and move
while active." (Spell.dbc server set, Description[enUS]). It is a 5000 ms self channel (DurationIndex 28).

`Unit::RollMeleeOutcomeAgainst` and the spell melee outcome paths in `Unit.cpp` set the victim's dodge, parry and
block chances to 0 while `IsNonMeleeSpellCast` reports a cast or channel, unless `Unit::CanDefendDuringChannel`
skips the channel. That CoA gate allowed only an aura 348 SPELL_AURA_ASCENSION_DEFEND_DURING_CAST against a
creature, or a Demon Hunter channelling Carve 800206. Twilight Frenzy was in neither list.

The counted pair 20261116-110350 / 20261116-110432 (worldserver sha256 b7612e8aa686a812..., server commit
109eea2659a6) forced the caster's dodge or parry chance to 100% and read 0 of 461 swings dodged and 0 of 460
parried during an active Frenzy channel, against 0 of 444 and 0 of 448 under the Witchbane 574320 control channel.

Archived live combat logs (Ascension, 2026-05-16 to 2026-08-31, before 99b87598bc) show creature swings dodged and
parried while the victim fired Frenzy shots 805753: 3 dodges and 5 parries in 37 swings for one player, 1 parry in
7 swings for another (for example `2026-08-15-12.46.19 WoWCombatLog.txt`, lines 4181-4289).

The owner chose option (a) on card Q-wh-22 (O-31); mentor D-295 queued the fix.

`AscensionWitchHunterCompletion.cpp` clears SPELL_ATTR5_ALLOW_ACTION_DURING_CHANNEL on 805751 so other abilities
break the channel (#1473). The avoidance gate does not read that attribute.

## Options

- (a) A line in `CanDefendDuringChannel` for a Witch Hunter player channelling 805751, as the Carve 800206 line.
- (b) Turn 805751 Effect[0] into aura 348 in Witch Hunter code: creature attackers only, never PvP, and it also
  lets the caster defend during a generic cast.
- (c) No change: the tooltip and the live logs stay contradicted.

## Decision

Option (a). `CanDefendDuringChannel` returns true for a player of class 15 whose active, unfinished channel is
805751 and whose generic spell slot is empty or finished. No other class or spell is affected, and the
SPELL_ATTR5_ALLOW_ACTION_DURING_CHANNEL strip stays.

## Consequences

- During Twilight Frenzy a Witch Hunter can dodge and parry melee swings and melee spells, against creatures and
  players. The same gate also lifts the block suppression, as it does for Carve.
- Other abilities still break the channel; `witch-hunter-channels-break-on-other-abilities` guards #1473.
- The movement part of the clause is unchanged.
- PvP is not measured: the regression and the live logs have creature attackers only.
- Regressions: `805751 behaviour_taken_outcome 805751 channel_dodge` and `805751 behaviour_taken_outcome 805751
  channel_parry`, each with the Witchbane 574320 channel as the control arm.
