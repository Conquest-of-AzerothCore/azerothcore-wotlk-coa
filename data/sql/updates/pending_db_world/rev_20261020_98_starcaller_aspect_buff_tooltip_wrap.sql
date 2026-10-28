-- Starcaller Aspect buff tooltips (#4007): the aura ToolTip of Aspect of the
-- Moonwell (574360) and Aspect of the Stars (800510, 803887, 803888) ends with
-- an @s:<spell>:0@ embed. The client wraps that embed in the spell tooltip but
-- prints it on one unwrapped line in the buff tooltip, so the Scattered Stars
-- details run outside the frame. Republish the unchanged DBC Description and a
-- ToolTip with the embedded spell's text written inline; tokens that belonged
-- to the embedded spell name it explicitly so the values stay the same.
-- Confirm in game: activate each Aspect and hover the buff.

DELETE FROM `coa_client_spell_description` WHERE `ID` IN (574360, 800510, 803887, 803888);
INSERT INTO `coa_client_spell_description` (`ID`,`Description`,`ToolTip`) VALUES
(574360,'While active, doubles the damage dealt and mana gained from consuming |cff66ccffScattered Stars|r.@s:804716:0@\r\n\r\n@ext:Shares a cooldown with other |cffffffffAspects|r.:ext@','Doubles the damage dealt and mana gained from consuming |cff66ccffScattered Stars|r.\r\n\r\n|cff66ccffConsume Scattered Stars|r: Deals ${$804995m1+$804995ppl1} additional Arcane Damage and regenerates $804994s2% maximum mana for each |cffffffffScattered Star|R consumed.'),
(800510,'Melee and ranged auto attacks now have a $h% chance to apply |cff66ccffScattered Stars|r and deal ${$m2+0+0.1*$spa+0.07*$AP} Arcane damage.@s:804378:0@\r\n\r\n@ext:Shares a cooldown with other |cffffffffAspects|r.:ext@','Melee and ranged auto attacks now have a $h% chance to apply |cff66ccffScattered Stars|r and deal ${$m2+$ppl2+0.1*$spa+0.07*$AP} Arcane damage.\r\n\r\n|cff66ccffScattered Stars|r: Can be consumed by spells to deal additional Arcane Damage.$?s704797[ and increases your Arcane Damage dealt by $704797s1%.][] Lasts $804378d, stacking $804378u times.'),
(803887,'Melee and ranged auto attacks now have a $h% chance to apply |cff66ccffScattered Stars|r and deal ${$m2+0+0.1*$spa+0.07*$AP} Arcane damage.@s:804378:0@\r\n\r\n@ext:Shares a cooldown with other |cffffffffAspects|r.:ext@','Melee and ranged auto attacks now have a $h% chance to apply |cff66ccffScattered Stars|r and deal ${$m2+$ppl2+0.1*$spa+0.07*$AP} Arcane damage.\r\n\r\n|cff66ccffScattered Stars|r: Can be consumed by spells to deal additional Arcane Damage.$?s704797[ and increases your Arcane Damage dealt by $704797s1%.][] Lasts $804378d, stacking $804378u times.'),
(803888,'Melee and ranged auto attacks now have a $h% chance to apply |cff66ccffScattered Stars|r and deal ${$m2+0+0.1*$spa+0.07*$AP} Arcane damage.@s:804378:0@\r\n\r\n@ext:Shares a cooldown with other |cffffffffAspects|r.:ext@','Melee and ranged auto attacks now have a $h% chance to apply |cff66ccffScattered Stars|r and deal ${$m2+$ppl2+0.1*$spa+0.07*$AP} Arcane damage.\r\n\r\n|cff66ccffScattered Stars|r: Can be consumed by spells to deal additional Arcane Damage.$?s704797[ and increases your Arcane Damage dealt by $704797s1%.][] Lasts $804378d, stacking $804378u times.');
