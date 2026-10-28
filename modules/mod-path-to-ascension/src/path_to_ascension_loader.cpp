/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "PathToAscension.h"

// The loader generator derives this name from the module folder:
// "mod-path-to-ascension" -> Addmod_path_to_ascensionScripts
void Addmod_path_to_ascensionScripts()
{
    AddPathToAscensionProgressScripts();
    AddPathToAscensionRewardScripts();
}
