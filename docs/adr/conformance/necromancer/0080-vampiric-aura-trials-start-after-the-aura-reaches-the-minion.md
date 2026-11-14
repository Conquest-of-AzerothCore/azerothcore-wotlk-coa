# 0080. Vampiric Aura trials start after the aura reaches the minion

- Status: accepted
- Date: 2026-11-14

## Context

Claims 10.0 and 11.0, Vampiric Aura 300241: "While you are below 50% health, your Undead minions now heal you for
$560607s2% of their damage dealt." Its `trigger_count` read 9 heals short of 2475 / 2473 Ghoul hits in the cycle 13
pair and again 9 short (2461 / 2470, 2465 / 2474) in the cycle 14 pair: exactly one per part in the nine parts that
attack right after the learn, none in part 1, whose learn follows the baseline phase. 300241 Effect[1] is a
PERIODIC_TRIGGER_SPELL of EffectAmplitude 1000 that casts 560607, whose Effect[1] (effect 190) reaches the summons, and
the heal needs the minion to hold 560607 from the owner (AscensionNecromancerEvents.cpp:97-98). The shared ADR 0650
first moved the held health ahead of the attack; the cycle 14 pair refuted that as the cause. Diagnostic
20261114-025240 (part 2 with reads after the learn, the attack and the first windows): without a wait the minion holds
no 560607 at the attack and window 1 reads 3 hits and 2 heals; with 1500 ms after the learn the minion holds 560607
before the attack and the part reads 268 heals in 268 hits.

## Options

- Count the first hit as a trial: a hit the engine cannot heal on, since the aura is not yet on the minion.
- Widen the count tolerance by one per part: ruled out by the mentor.
- Start the trials after the aura reaches the minion.

## Decision

The three Vampiric Aura entries (trigger count, gate absence, magnitude) wait `aura_settle_ms` 1500 after the learn,
more than the 1000 ms first tick of 300241 Effect[1], before the first attack. No server change: the minion receives
the aura on the passive's first tick as the DBC states.

## Consequences

- The scenarios of the three entries gain one 1500 ms wait; the Necromancer digests are refreshed.
- 10.0 and 11.0 stay not final in the cycle 14 pair (judged before the wait) and are judged again in the next pair.
