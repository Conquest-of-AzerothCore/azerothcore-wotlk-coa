-- Ancestral Keg (gameobject 9000118) is a GAMEOBJECT_TYPE_SPELLCASTER; Data0 is the spell it casts on its user.
-- rev_20260930_62 added the row without Data0, so using the placed keg did nothing (#5802).
-- Spell.dbc has exactly three spells named "Ancestral Keg": 804748 (places the object), 570762 (periodic
-- trigger aura, 2000 ms, triggering 572066) and 572066 (HEAL_PCT 4 + ENERGIZE_PCT 4).
UPDATE `gameobject_template` SET `Data0` = 570762 WHERE `entry` = 9000118;
