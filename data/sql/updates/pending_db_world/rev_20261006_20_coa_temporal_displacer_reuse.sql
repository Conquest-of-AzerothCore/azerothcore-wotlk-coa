-- A Matter of Time (4971) hands out the Temporal Displacer (12627) and asks for
-- ten Temporal Parasites (10717), which only the displacer's own spell (16613)
-- reveals - three per cast, on a 30 second item cooldown. The item carried
-- spellcharges_1 = -25, and Spell::TakeCastItem treats a negative charge cost as
-- expendable: it decrements the item's own counter and destroys the item as soon
-- as that counter reads 0, which is what a player who has used the displacer once
-- runs into. The displacer is a quest tool that is handed back at the turn-in, so
-- it needs no charge cost at all; dropping the counter takes it out of that path
-- and leaves the cooldown as the only limit on its use.
UPDATE `item_template` SET `spellcharges_1` = 0 WHERE `entry` = 12627;
