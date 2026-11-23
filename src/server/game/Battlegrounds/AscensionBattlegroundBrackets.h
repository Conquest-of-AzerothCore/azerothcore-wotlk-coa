/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_BATTLEGROUND_BRACKETS_H
#define ASCENSION_BATTLEGROUND_BRACKETS_H

#include "DBCEnums.h"
#include "Define.h"
#include <string>

struct PvPDifficultyEntry;

namespace AscensionBattlegroundBrackets
{
    void Configure(bool enabled, std::string ranges);
    PvPDifficultyEntry const* FindByLevel(uint32 mapId, uint32 level);
    bool FindById(uint32 mapId, BattlegroundBracketId id, PvPDifficultyEntry const*& entry);
    uint32 WidenedMaxLevel(uint32 mapId, BattlegroundBracketId id);
}

#endif
