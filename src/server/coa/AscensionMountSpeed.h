/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_MOUNT_SPEED_H
#define ASCENSION_MOUNT_SPEED_H

class Player;
class SpellInfo;

namespace AscensionMountSpeed
{
bool CanFly(Player* player, SpellInfo const* mount);
}

#endif
