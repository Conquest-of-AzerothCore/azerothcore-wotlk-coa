-- Aldia Crayon 162802, the Spada majordomo of Seven Years of Bad Luck 1660057 (#12324): the captured quest texts
-- call him a man ("Return to the butler.", "As he speaks..."), but rev_20261002_00 gave him display 8632, a human
-- female. His live display 652414 is not in the CoA client. Use 11591 (Servant of Weldon Barov 11636), a dressed
-- human male servant the client draws (model 49, extra 8185, sex 0); the choice of stand-in is estimated.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 11591
WHERE `CreatureID` = 162802 AND `Idx` = 0 AND `CreatureDisplayID` = 8632;
