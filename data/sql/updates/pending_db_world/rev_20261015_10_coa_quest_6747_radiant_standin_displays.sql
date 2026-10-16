-- Radiance Town, Coldridge Valley (#6747): the Radiant cult and the Radiant One Disguise get radiation-suit
-- stand-ins in place of the plain dwarf and gnome villager displays.
--
-- WHERE EACH VALUE COMES FROM
--   CreatureID, Idx, DisplayScale, Probability  existing creature_template_model rows
--     (rev_20260925_10_coa_dunmorogh_radiance.sql); only the displays change. 161775 keeps scale 1.25.
--   The original CoA displays 652021-652047 are missing from every client, the server DBC and SUB. These
--     replacements are INFERRED stand-ins, approved by the user on 2026-10-15. Evidence for a sealed radiation suit:
--     AscensionDB GO 520704 "Radiant Helmet" (display 515680 = Helm_Engi_C_01Diver), the plate icon on item
--     559142 "Radiant Armor Piece" dropped by Fanatics, quest 1660008 ("wouldn't fit in a helmet that small")
--     and the Radiant Fanatic chat line "You're about to see the stars" (SUB wow-ptr WoWChatLog.txt:108076).
--   Each display is in both the server and the installed client CreatureDisplayInfo.dbc. Source NPC per display:
--     25525   dwarf M, diving helmet, brass plate     28573 Underwater Construction Worker
--     141779  dwarf M, space helmet, gold plate       none (Ascension dwarf copy of Leprous Defender)
--     141780  dwarf F, space helmet, gold plate       none (Ascension dwarf copy of Leprous Defender)
--     32630   dwarf M, diving helmet, green mail      none
--     14656   dwarf F, glowing goggles, white robe    14628 Evonice Sootsmoker
--     27657   gnome M, diving helmet, brass plate     31689 Gnome Diver
--     10089   gnome M, diving helmet, brass plate     10776 Finkle Einhorn
--     32697   gnome F, diving helmet, green mail      none
--     6981    gnome M, space helmet, gold plate       6223 Leprous Defender (unchanged)
--     6982    gnome F, space helmet, gold plate       6223 Leprous Defender (unchanged)
--     47042   gnome M, space helmet, white-green      none
--     47043   gnome F, space helmet, white-green      none
DELETE FROM `creature_template_model`
WHERE `CreatureID` IN (161772, 161773, 161775, 161778, 161779, 161780, 161781, 161786);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`)
VALUES
(161772, 0, 25525, 1, 1),
(161772, 1, 141780, 1, 1),
(161772, 2, 27657, 1, 1),
(161772, 3, 32697, 1, 1),
(161773, 0, 141779, 1, 1),
(161773, 1, 141780, 1, 1),
(161773, 2, 6981, 1, 1),
(161773, 3, 6982, 1, 1),
(161786, 0, 32630, 1, 1),
(161786, 1, 14656, 1, 1),
(161786, 2, 47042, 1, 1),
(161786, 3, 47043, 1, 1),
(161775, 0, 10089, 1.25, 1),
(161778, 0, 25525, 1, 1),
(161779, 0, 141780, 1, 1),
(161780, 0, 32697, 1, 1),
(161781, 0, 27657, 1, 1);

-- creature_model_info for the new displays that had no row (worldserver logged "No model data exist" for
-- 32630, 32697, 47042, 47043; 141779 and 141780 also have no row). BoundingRadius, CombatReach and Gender are
-- copied from the replaced stand-in that uses the same CreatureDisplayInfo.ModelID (server DBC and installed
-- client agree). Each donor's values are also the most common creature_model_info row for that ModelID. Gender
-- matches CreatureDisplayInfoExtra.DisplaySexID. DisplayID_Other_Gender is 0.
--   32630, 141779  ModelID 53 DwarfMale     donor 3765  (0.347, 1.5, male)
--   141780         ModelID 54 DwarfFemale   donor 3766  (0.347, 1.5, female)
--   47042          ModelID 182 GnomeMale    donor 6921  (0.3519, 1.725, male)
--   32697, 47043   ModelID 183 GnomeFemale  donor 6975  (0.3519, 1.725, female)
DELETE FROM `creature_model_info` WHERE `DisplayID` IN (32630, 32697, 47042, 47043, 141779, 141780);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`)
VALUES
(32630, 0.347, 1.5, 0, 0),
(141779, 0.347, 1.5, 0, 0),
(141780, 0.347, 1.5, 1, 0),
(47042, 0.3519, 1.725, 0, 0),
(32697, 0.3519, 1.725, 1, 0),
(47043, 0.3519, 1.725, 1, 0);
