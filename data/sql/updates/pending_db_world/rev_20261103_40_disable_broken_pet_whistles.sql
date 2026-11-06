-- Beastmaster's Whistles whose beast cannot be summoned (#10984). The Vanity tab withholds them in code
-- (IsBrokenCosmeticPetToken); this file takes the seven Mana Ray whistles out of Tiraxis' rotating Ethereal Bazaar
-- stock. Their creatures (225600-225607) have a pet family but no tameable type flag, so applying the appearance is
-- refused with APPLY_APPEARANCES_BAD_CREATURE_TEMPLATE. item_template rows stay: a deleted template would delete
-- every copy a player already owns at login. The statement writes fixed values, so a reapply changes nothing.
DELETE FROM `ethereal_bazaar_pool` WHERE `item` IN (
  333413,  -- Fel-infused Mana Ray
  333414,  -- Marshlands Mana Ray
  333415,  -- Camouflaged Mana Ray
  333417,  -- Arcane Mana Ray
  333418,  -- Fel Corrupted Mana Ray
  333419,  -- Zangar Mana Ray
  333420   -- Ivory Mana Ray
);
