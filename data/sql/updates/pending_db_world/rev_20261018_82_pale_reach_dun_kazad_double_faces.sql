-- Durakh, Hargin Furrhide and Gormo Bouldertoe in Dun Kazad have dressed dwarf models with their own face and clothes;
-- an outfit preset left over from before was drawn on top of them, giving two faces at once. The presets go.
DELETE FROM `creature_display_preset` WHERE `entry` IN (164386, 164414, 164467);
