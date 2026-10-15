/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license.
 */

// The loader generator derives this name from the module folder:
// "mod-battlehorn" -> Addmod_battlehornScripts
void Addmod_battlehornScripts()
{
    // The Battle Horn is restored by its item row alone
    // (data/sql/updates/pending_db_world/rev_20260926_80_battle_horn_item.sql):
    // the item's own spells are the client's, and the core already implements both
    // of their effects. A script for the horn would be registered here.
}
