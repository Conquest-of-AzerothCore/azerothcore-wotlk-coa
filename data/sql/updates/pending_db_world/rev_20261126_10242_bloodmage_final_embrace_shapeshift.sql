-- #10242: Final Embrace (524865) uses all three effect slots (transform, +15% speed, Hematoma trigger) and has no
-- SPELL_AURA_MOD_SHAPESHIFT effect, so UNIT_FIELD_BYTES_2 shapeshift form stays 0 (client GetShapeshiftForm() = 0,
-- action bars and form conditions do not activate, creature type stays Humanoid).
-- Ascension ships the hidden companion 525047 ("Final Embrace", rank "Shapeshift SLS", SPELL_ATTR1_NO_AURA_ICON,
-- SPELL_ATTR2_USE_SHAPESHIFT_BAR, infinite duration, SPELL_AURA_MOD_SHAPESHIFT MiscValue 57 Cursed Form), observed
-- applied and removed alongside 524865 in 161/161 CoA live combat log casts.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 524865 AND `spell_effect` = 525047 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(524865, 525047, 2, 'CoA Final Embrace - Cursed Form shapeshift helper');

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = -525047 AND `spell_effect` = -524865 AND `type` = 0;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(-525047, -524865, 0, 'CoA Final Embrace - drop buff when shapeshift ends');
