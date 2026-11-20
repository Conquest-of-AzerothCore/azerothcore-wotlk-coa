-- Hearthsinger Forresten (10558): Mythic+ groups pull him behind the wall where the rats come in, about 65 yards from
-- his spawn (#12636). His Heroic and Mythic leash circle grows from 50 to 70 yards.
UPDATE `coa_boss_leash` SET `radius` = 70 WHERE `entry` = 10558;
