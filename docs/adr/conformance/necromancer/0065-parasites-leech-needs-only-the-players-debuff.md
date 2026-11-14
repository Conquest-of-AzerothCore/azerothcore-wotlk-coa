# 0065. The Parasites leech needs only the player's debuff

- Status: accepted
- Date: 2026-11-13

## Context

Claim 396.0, Parasites 560729 (applied by the reachable talent Parasite Plague 560730, CharacterAdvancement 29946,
class 23): "Your Undead minions feast upon the parasites on hit, leeching $561319s1% of their damage dealt as Plague
Damage to the target." The minion branch of the damage event (AscensionNecromancerEvents.cpp:198-199) copied the leech
Parasites 561318 only when the target held 560729 from the player and the player held 561319. Nothing grants 561319
(no acquisition, no DBC link, coa-obtainable: none), so a 560730 player's minions never leeched although the debuff
lands (560730 rolls on any own damage, Q-mb-2). Live logs 103 and 104 (coa-log-history, 2026-08-10) show the 561318
leech from the player's minions (Abomination, Lesser Zombie: 299 damage and 302 heal events) wherever 560729 appears.
Mentor ruling (fix note FN-c10-396): confirmed defect.

## Options

- Grant 561319 to 560730 players: an invented grant; 561319 is a different spell with its own tooltip.
- Keep `HasAura(561319)` as an alternative condition: redundant, the debuff from the player already admits a 561319
  holder whose debuff landed.
- Gate the leech on the debuff from the player alone.

## Decision

The gate is `target->HasAura(560729, player->GetGUID())`. The percentage stays `Amount(561319)`, read from SpellInfo
(561319 Effect[0] BasePoints 14 + DieSides 1 = 15, the tooltip's $561319s1), not from an aura on the player.
Necromancer code only; no shared engine change and no cross-class link.

## Consequences

- With 560730 learned, a minion hit on a target carrying the player's 560729 casts 561318 (SPELL_EFFECT_HEALTH_LEECH,
  EffectValueMultiplier 1.0: the minion is healed for the damage the leech deals) for 15% of the hit.
- Regression: trigger `560730 trigger_magnitude_ratio parasites_leech` (the leech per Ghoul hit on the debuffed dummy
  against 0.15 after the dummy's Shadow resist) and behaviour `560729 behaviour_metric_delta parasites_leech` (no leech
  without the debuff, at least one with it). Without 560730 no debuff is applied (the existing 560730 entries).
