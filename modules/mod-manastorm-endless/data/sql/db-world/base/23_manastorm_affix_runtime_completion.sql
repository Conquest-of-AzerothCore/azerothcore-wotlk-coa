-- Manastorm affix runtime completion.
--
-- These affixes previously had recovered DBC spell graphs but unresolved
-- server-only runtime edges (helper activation / chase / dummy callback).
--
-- SRC completion:
--   93341 Creeping Frost      -> 80916 owns 93342 field
--   21    Cold Snap           -> 80924 owns 93446; 80925 owns 93448
--   31    Fungal              -> 80914 owns 93379 + 293370/293371 summon gate
--   41    Reflecting          -> bounded damage-reflection callback
--   61    Bone Storm          -> 80913 owns 93371 and chases nearest Hero
--   101   Overwhelming Energy -> 80917 owns 93414
--
-- Reflecting percentage semantics are a documented reconstruction:
-- the DBC amount BP29 => 30 is treated as 30% at Rank 1.
--

UPDATE `manastorm_affix_catalog`
SET `bounded_runtime` = 1
WHERE `affix_id` IN
(
    21,
    31,
    41,
    61,
    101,
    93341
);
