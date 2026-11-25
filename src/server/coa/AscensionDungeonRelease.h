/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_DUNGEON_RELEASE_H
#define ASCENSION_DUNGEON_RELEASE_H

#include "Define.h"

class Map;
struct Position;

void CoASetDungeonReleaseStart(Map* map, Position const& start);
void CoAAddDungeonReleaseCheckpoint(uint32 mapId, uint32 bossId, Position const& position);

#endif
