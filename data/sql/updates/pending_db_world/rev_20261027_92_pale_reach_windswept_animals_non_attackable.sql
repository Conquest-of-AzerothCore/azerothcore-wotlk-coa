-- #8773: Sheep 164156, Black Sheep 164157 and Dairy Cow 164158 use the stock "Prey" faction with no
-- non-attackable flag and trivial health, so an ordinary melee attack (or the aggro it provokes) kills
-- them before Almo's Bucket (365040, Windswept Milk 175074) or the Shears (365041, To Shear and Return
-- with Wool 175076) can land. Both item spells target a selected unit generically (TARGET_UNIT_TARGET_ANY),
-- not an enemy-only target, so Unit::IsValidAttackTarget is not consulted for that cast; blocking ordinary
-- attacks leaves Milking/Shearing, and the Dairy Cow's existing spellclick interaction, unaffected.
UPDATE `creature_template` SET `unit_flags` = `unit_flags` | 0x2 WHERE `entry` IN (164156, 164157, 164158);
