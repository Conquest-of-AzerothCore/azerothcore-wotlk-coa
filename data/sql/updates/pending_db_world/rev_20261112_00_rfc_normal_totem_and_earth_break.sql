-- Ragefire Chasm on Normal.
-- Oggleflint's Summon Greater Magma Totem (2102506) always summons creature 106017 through a wild summon
-- property (64), so the totem keeps its template level instead of Oggleflint's. 106017 is level 61, which made the
-- totem show as ?? to the level 13-18 group and let its Molten Magma hit with level 61 values. Heroic and Mythic
-- use its difficulty copies 206017 and 306017, so 106017 only serves Normal: give it Oggleflint's level.
UPDATE `creature_template` SET `minlevel` = 16, `maxlevel` = 16 WHERE `entry` = 106017;

-- Taragaman's Rumbling Earth pillars (663030) cast Earth Break (2102515, 800) on players within 4 yards, and
-- Oggleflint's totem casts Molten Magma (2102509). Their casters are summons, not the bosses, so both spells were
-- left out of the Normal kit list that already caps Massive Fire Nova (2102516): they hit with the 1.5 dungeon
-- creature scaling and no cap, a 1200 damage burst to a level 16 character. List them at their own rank.
DELETE FROM `coa_dungeon_normal_spell_damage` WHERE `spell_id` IN (2102509, 2102515);
INSERT INTO `coa_dungeon_normal_spell_damage` (`spell_id`, `normal_spell_id`, `high`, `comment`) VALUES
(2102509, 2102509, 1.0, 'Molten Magma: own Normal rank'),
(2102515, 2102515, 1.0, 'Earth Break: own Normal rank');
