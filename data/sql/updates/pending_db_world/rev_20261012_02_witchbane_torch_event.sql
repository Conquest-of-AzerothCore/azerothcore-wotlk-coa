-- Light Witchbane Torch (42521) sends event 15453 in the CoA client data (15452 in 3.3.5a)
DELETE FROM `event_scripts` WHERE `id` = 15453;
INSERT INTO `event_scripts` (`id`, `delay`, `command`, `datalong`, `datalong2`, `dataint`, `x`, `y`, `z`, `o`) VALUES
(15453, 0, 9, 5448, 20, 0, 0, 0, 0, 0);
