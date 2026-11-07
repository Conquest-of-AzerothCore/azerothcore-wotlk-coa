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

#ifndef _STAFF_CHAT_TAG_H
#define _STAFF_CHAT_TAG_H

#include "DataMap.h"
#include "Define.h"
#include <string_view>

enum class StaffChatTag : uint8
{
    None,
    Moderator,
    CommunityManager,
    Administrator
};

struct StaffChatTagData : public DataMap::Base
{
    StaffChatTag Tag = StaffChatTag::None;
};

inline constexpr char const* STAFF_CHAT_TAG_KEY = "CoAStaffChatTag";

inline constexpr std::string_view STAFF_CHAT_PREFIXES[] =
{
    "|cff33bbff<MOD>|r ",
    "|cff33bbff<CM>|r ",
    "|cff33bbff<ADMIN>|r ",
};

inline std::string_view GetStaffChatPrefix(StaffChatTag tag)
{
    switch (tag)
    {
        case StaffChatTag::Moderator:        return STAFF_CHAT_PREFIXES[0];
        case StaffChatTag::CommunityManager: return STAFF_CHAT_PREFIXES[1];
        case StaffChatTag::Administrator:    return STAFF_CHAT_PREFIXES[2];
        default:                             return {};
    }
}

#endif
