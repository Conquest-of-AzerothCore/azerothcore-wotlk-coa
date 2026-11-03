-- Brimstone Bludgeon 520005 (#11004) is the temporary stand-in that the 800710 talent swaps Sever into. It used to be
-- learned as a permanent spell, so every login listed it beside Sever; the talent teaches it again on login.
DELETE FROM `character_spell` WHERE `spell` = 520005;
