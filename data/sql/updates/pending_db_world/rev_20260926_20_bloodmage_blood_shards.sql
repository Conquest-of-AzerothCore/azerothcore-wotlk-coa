-- Blood Shards (804849, Bloodmage level 30 passive): "Shadow Damage dealt now generates 1 Blood Shard, plus 1 additional
-- if it critically strikes, up to 8. Dealing damage with Veinburst will now expend all stacks of Blood Shards, each
-- dealing ${$504115m1+$AP*0.05+$SP*.1}". Nothing implemented the shards: the passive's proc aura has no proc flags
-- and its generator (506640) is a dummy. bloodmage_blood_shards now keeps the count on 505366 (8 stacks) with one
-- orbiting visual per shard (505349-505356); the shards end when the first visual's duration runs out, and the
-- visuals go with the counter when it is cancelled.
-- Talents built on them: the level 20 passive 807787 (Bloodmoon Blast generates), Battleweaver 801963, Inhumane
-- 807488 and Bloodchaser 523721 (each launch spends a stored shard, 506639 "Consume 1"), Everlasting Hunt 804686.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (505349, 505366) AND `ScriptName` IN
('aura_ascension_bloodmage_blood_shard_expiry', 'aura_ascension_bloodmage_blood_shard_counter');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(505349, 'aura_ascension_bloodmage_blood_shard_expiry'),
(505366, 'aura_ascension_bloodmage_blood_shard_counter');
