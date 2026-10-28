-- Touch of Moonlight 574328 hides its Lunar Eclipse line behind $?s524781
-- (knows the Lunar Phase passive), but Starcaller code grants 524781 only as
-- an aura: Refresh() casts it on anyone with Lunar Eclipse 800386
-- (AscensionStarcaller.cpp) and no path teaches it as a spell, so the clause
-- never renders even while Eclipse works -- exactly the report in #7950, where
-- a level-10 Starcaller pressed Lunar Eclipse, saw Touch proc, and found no
-- Lunar text. Every sibling Lunar heal (Moonwell Splash 800370, Moonflow)
-- shows its Lunar line unconditionally and Huntress Shot gates its own on the
-- spell that grants the effect ($?s92134), so re-gate this clause on knowing
-- Lunar Eclipse ($?s800386) and keep every other byte of the DBC text.
-- AscensionCompat streams this table to the client as SMSG_PATCH_SPELL at
-- login. The stale DBC ToolTip naming Huntress Shot is left alone: an empty
-- ToolTip here means "keep DBC", so this channel cannot clear it.
DELETE FROM `coa_client_spell_description` WHERE `ID` = 574328;
INSERT INTO `coa_client_spell_description` (`ID`,`Description`) VALUES
(574328,'|cffffffffDrains $574329s1% Maximum Mana|r\nQuickly heal an ally with Elune''s touch$?s574329[ for ${($m1+$POWER1*0.08+$SP*0.2+$RAP*.1)*((100+$887014ppl3)/100)}][], scaling with maximum mana.$?s800386[\r\n\r\n|cffffffffLunar Eclipse|r: This spell is instant and refunds its mana cost and 1 stack of |cffffffffLunar Phase|r.][]');
