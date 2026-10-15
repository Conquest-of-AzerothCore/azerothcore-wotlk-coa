/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef RealmCard_h__
#define RealmCard_h__

#include "Define.h"
#include <cstddef>
#include <string>

// The Ascension realm list reads its cards from extra realm-list entries in the last realm category, named
// "name!expansion!gamemode!image!unlocked!page!index!descriptionSpell"; a realm without one is hidden.
struct RealmCardSlot
{
    uint8 Page;
    uint32 Index;
};

struct RealmCardStyle
{
    uint32 Expansion;
    uint32 GameMode;
    std::string Image;
};

RealmCardSlot GetRealmCardSlot(std::size_t order);

std::string BuildRealmCardName(std::string const& realmName, RealmCardStyle const& style, RealmCardSlot slot);

#endif
