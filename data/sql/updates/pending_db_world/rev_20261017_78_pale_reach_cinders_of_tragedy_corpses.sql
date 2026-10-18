-- Cinders of Tragedy (175060): players could not throw the Torch (Thrown Torch 365019) at the corpses. The spell is helpful,
-- and a player's helpful spell is refused on units flagged immune to players (unit_flags 256) or hostile to the caster, so
-- every throw failed. The soldier and troll corpses (used only for this quest) are friendly to everyone and no longer immune
-- to players; they keep their dead look, the burn script and the "Corpses burned" credit.
UPDATE `creature_template` SET `faction` = 35, `unit_flags` = `unit_flags` & ~256 WHERE `entry` IN (164072, 164073);
