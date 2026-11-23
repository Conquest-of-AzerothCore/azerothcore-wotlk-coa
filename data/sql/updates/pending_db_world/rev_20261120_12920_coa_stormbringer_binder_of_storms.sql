-- #12920 Binder of Storms 707542: "Damage dealt by Conduction now has a 60% chance to summon a Thunder Orb."
-- In play Conduction 567560 is always a triggered cast (Deluge, Torrential Wrath), and a proc entry without
-- PROC_ATTR_TRIGGERED_CAN_PROC (2) ignores triggered spells, so no Thunder Orb ever appeared.
UPDATE `spell_proc` SET `AttributesMask` = 2 WHERE `SpellId` = 707542;
