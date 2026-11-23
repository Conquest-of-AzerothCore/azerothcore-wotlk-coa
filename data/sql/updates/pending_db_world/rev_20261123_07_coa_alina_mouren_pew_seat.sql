-- Alina Mouren (164634) floated above her pew in the Graysky Chapel of Light. GeneralChurchPew01 has its seat 0.63 yd
-- above the floor (311.162); a medium-chair sit with the root 0.1 yd above the floor and 0.4 yd forward of the seat
-- centre puts her on the seat with her knees past its front edge.
UPDATE `creature` SET `position_x` = -7158.14, `position_y` = 1209.497, `position_z` = 311.26
    WHERE `guid` = 9920749 AND `id` = 164634;
UPDATE `creature_addon` SET `bytes1` = 5 WHERE `guid` = 9920749;
