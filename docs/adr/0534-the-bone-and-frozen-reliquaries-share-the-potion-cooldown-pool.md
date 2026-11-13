# 0534. The Bone and Frozen Reliquaries share the potion cooldown pool

- Status: accepted
- Date: 2026-11-13

## Context

Bone Reliquary 11521 (spell 803767, family 27) and Frozen Reliquary 555555 (803773, family 29) both carried
item_template spellcategory_1 1153 with a 60000 ms category cooldown, but the category cooldown is applied only
within one spell family (Player.cpp:11877-11885), so the two did not block each other. The owner asked that they share
their cooldown with similar consumables such as healing and mana potions (Q-mb-1), authorized the SQL and confirmed
the full potion rule (09:3x): category 5004 (SPELL_CATEGORY_SHARED_POTION_COOLDOWN), one pooled use per combat, then
the cooldown after combat ends.

## Decision

- `rev_20261113_30_necromancer_reliquaries_potion_cooldown.sql`: one UPDATE sets spellcategory_1 5004 for 11521 and
  555555 (only where it is still 1153). Each item keeps its own 60000 ms; 5004 does not force a length (the pool
  applies the used item's category cooldown, Player.cpp:11880-11890). No other item in 1153 has a family 27 or 29
  spell, so no link is lost.
- Conformance tools: an `item_cooldown_gate` entry may set `label_suffix` (several entries per item) and
  `combat_kill_spell` (the in-combat arm: the ally attacks the dummy, uses `item`, is refused `shared_item` past the
  cooldown while in combat, the caster kills the dummy with that spell, and `shared_item` is refused after the combat
  end, still refused just before the cooldown from the combat end and accepted just after it).

## Consequences

- Out of combat the pooled cooldown starts at the use; in combat it is held until the user leaves combat and a second
  pooled use is refused meanwhile, so "once per minute" becomes "once per combat, then 60 s" in a fight. Text item for
  the owner's go: both reliquaries keep "Shares a cooldown with similar effects." (the Frozen Reliquary gains it) and
  state the once-per-combat behaviour.
- Regression (class file 803771 / 803777): a reliquary blocks a Healing Potion 929 and a Mana Potion 3827 and the
  reverse, the two reliquaries block each other both ways, the once-per-minute arms stay, and `pool_combat` reads the
  in-combat rule. A client's cached item data may show category 1153 until refreshed (not verified).
