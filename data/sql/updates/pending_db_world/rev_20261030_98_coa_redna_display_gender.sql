-- Redna (161820) has the dwarf female display 3766 alone, but its gender link to 3765 spawned her male half the
-- time. Dun Garok Priest (2346) and Expeditionary Priest (14393) list both displays, so they keep their mix.
UPDATE `creature_model_info` SET `DisplayID_Other_Gender` = 0 WHERE `DisplayID` IN (3765, 3766);
