/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

// The loader generator derives this name from the module folder:
// "mod-scrolls-of-retreat" -> Addmod_scrolls_of_retreatScripts
void AddSC_scrolls_of_retreat();

void Addmod_scrolls_of_retreatScripts()
{
    // The scrolls' data - the two missing Scrolls of Defense, the four teleport destinations and
    // Tiraxis's two rotation rows - is
    // data/sql/updates/pending_db_world/rev_20260926_81_retreat_and_defense_scrolls.sql. Their
    // teleports are the client's own spells and a destination is a spell_target_position row, so no
    // script is needed for those.
    //
    // What data cannot say is the faction half of the two capital scrolls: each belongs to one side
    // only, and a refusal needs a line of its own rather than the client's generic cast error. That
    // is the script registered here.
    AddSC_scrolls_of_retreat();
}
