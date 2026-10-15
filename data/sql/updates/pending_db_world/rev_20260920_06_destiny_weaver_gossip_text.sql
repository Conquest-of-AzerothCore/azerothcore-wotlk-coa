-- Destiny Weaver: the greeting as it reads on screen, not as the client cache stored it.
--
-- npc_text 30520 was recovered verbatim from the live client's text cache, and that cache stores the
-- text with its line breaks flattened: the three blocks are separated by runs of four spaces, and
-- the two service names are wrapped in literal "**".  A 3.3.5 client renders neither - the space
-- runs show up as stray gaps and the asterisks show as asterisks.  The wording is kept; what is
-- corrected is its presentation, and its consistency with the two options below it:
--
--   * the paragraph breaks are written as $B, which is how every other long text in the archive is
--     stored (npc_text and page rows alike) and which the client turns into a line break;
--   * the runs of spaces collapse to one space at the end of a sentence;
--   * the "**" are dropped, since the client has no bold to turn them into;
--   * the two services are named exactly as the menu names them - "Experience bonuses" and "Open
--     world scaling" - so the greeting and the options read as one voice instead of two;
--   * both genders are written.  The core sends the male and the female variant of every option
--     (`text0_*` and `text1_*`) and the client picks by the character's gender, so a row whose
--     `text1_*` is empty shows a female character no greeting at all;
--   * option 1 (probability 0, never chosen) is kept equal to option 0 so the row cannot drift.
--
-- A client caches npc_text in Cache/WDB/<locale>/<realm>/npccache.wdb and reads that before asking
-- the server, so an edited greeting is only visible to a client whose cache does not already hold
-- that id.  That is a client cache, not a server one: delete the file, or the WDB folder, to see a
-- text change on a client that has already cached it.
--
-- 19175 is the pointer text that sends new characters here; it is corrected the same way.

UPDATE `npc_text` SET
    `text0_0` = 'Greetings, Hero.$B$BI offer two services to customize your adventure:$B$BExperience bonuses: I can disable every bonus experience source - Potions of Experience, Auras of Experience and Refer a Friend - so you progress at the base rate.$B$BOpen world scaling: I can make creatures in the open world match your level, for a consistent challenge.',
    `text0_1` = 'Greetings, Hero.$B$BI offer two services to customize your adventure:$B$BExperience bonuses: I can disable every bonus experience source - Potions of Experience, Auras of Experience and Refer a Friend - so you progress at the base rate.$B$BOpen world scaling: I can make creatures in the open world match your level, for a consistent challenge.',
    `text1_0` = 'Greetings, Hero.$B$BI offer two services to customize your adventure:$B$BExperience bonuses: I can disable every bonus experience source - Potions of Experience, Auras of Experience and Refer a Friend - so you progress at the base rate.$B$BOpen world scaling: I can make creatures in the open world match your level, for a consistent challenge.',
    `text1_1` = 'Greetings, Hero.$B$BI offer two services to customize your adventure:$B$BExperience bonuses: I can disable every bonus experience source - Potions of Experience, Auras of Experience and Refer a Friend - so you progress at the base rate.$B$BOpen world scaling: I can make creatures in the open world match your level, for a consistent challenge.'
WHERE `ID` = 30520;

UPDATE `npc_text` SET
    `text0_0` = 'To enable or disable your experience bonuses and open world scaling, seek out the Destiny Weaver.$B$BThe location has been marked on your map with a red flag.',
    `text0_1` = 'To enable or disable your experience bonuses and open world scaling, seek out the Destiny Weaver.$B$BThe location has been marked on your map with a red flag.',
    `text1_0` = 'To enable or disable your experience bonuses and open world scaling, seek out the Destiny Weaver.$B$BThe location has been marked on your map with a red flag.',
    `text1_1` = 'To enable or disable your experience bonuses and open world scaling, seek out the Destiny Weaver.$B$BThe location has been marked on your map with a red flag.'
WHERE `ID` = 19175;
