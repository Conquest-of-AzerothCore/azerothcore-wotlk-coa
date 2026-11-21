# 0008. Arbalest Mastery stacks carry across Witchbane casts

- Status: accepted
- Date: 2026-11-15

## Context

The Arbalest Mastery 706240 tooltip reads: "Each subsequent shot of a Witchbane cast deals 15% more damage, up to a
maximum of 150%." Its progress aura 706241 stacks to 10 (StackAmount 10, 15% per stack) and lasts 1200 ms
(DurationIndex 509); every Witchbane shot 704342 adds one stack and refreshes the duration, and the shot's damage is
multiplied by 1 + 0.15 x stacks before the stack is added.

The Witch Hunter aura lifecycle script (`aura_ascension_witch_hunter_lifecycle`, `AscensionWitchHunterDefenses.cpp`)
removed 706241 whenever a family 21 aura with SpellFamilyFlags[1] 4194304 (the seven Witchbane channel ranks) was
applied or removed. With five shots per channel (D-143), the stack count could not pass 5 and the 10-stack cap of the
tooltip was unreachable.

Live combat logs (`coa-history spell 706241`, six logs) show the stacks carried across back-to-back channels: 441
applications against 1363 Witchbane casts, dose 10 seen 215 times and never above, and self-removal about 1.3 s after
the last shot. One log shows a tenth-stack shot at 924 against a first shot of 368 (2.51). Mentor ruling D-148 reads
the tooltip by that live behaviour; D-152 approves the change.

## Options

- Delete the two channel-boundary resets in the lifecycle script: the 1200 ms duration, refreshed by every shot,
  drops the aura 1.2 s after the last shot.
- Keep the resets and remove the aura on a timer of its own: duplicates the DBC duration.
- Keep the resets: the cap stays unreachable, against the live logs and D-148.

## Decision

The first option. `Apply` and `Removed` no longer remove 706241 at a Witchbane channel's start or end. The unlearn
cleanup in `OnUnitUpdate` (no 706240, remove 706241) stays.

## Consequences

- Chained Witchbane casts (the next cast within 1.2 s of the last shot) keep their stacks: the tenth stack is reached
  at the tenth shot, at the end of the second channel, and every later shot deals 2.5 times an unstacked shot. A
  channel that starts from no stack still deals 6.5 times an unstacked shot over its five shots.
- An interrupted or cancelled channel also keeps its stacks for 1.2 s after its last shot (the removal ran for every
  remove mode). Live behaviour on an interrupt was not checked.
- The 3935 scenario contract now says the helper disappears 1.2 s after the last shot rather than when the channel
  finishes.
- Counted pair 20261115-202911 / 20261115-203000 (worldserver a6743bcc587d): in
  `witch-hunter-arbalest-mastery-chained-stacks`, against the hunter's own first shot, a channel from no stack reads
  6.496 (6.5), the chained second channel 10.244 (10.25), the third and fourth 12.493 each (12.5, a tenth-stack shot
  at 2.4987), and an unchained fifth channel after the drop 6.496; 706241 holds 10 stacks after 10, 15 and 20 shots,
  1031 ms remain as the last shot lands, the aura outlasts the channel end and is gone at the next read. The 3935
  scenario, five other Witchbane scenarios and 37 generated Witchbane and Arbalest Mastery scenarios pass in both
  runs; `706240 effect_value 706241e0 #0` stays ok 15.
