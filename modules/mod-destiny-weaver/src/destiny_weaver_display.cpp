/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

// The Destiny Weavers' models, delivered by the realm instead of by a client patch.
//
// The live service's ten Weavers stood on five displays in the 4492xx range - ids that exist in
// no client anywhere, because the live server *streamed* their rows. Its client carries handlers
// for exactly that: SMSG_PATCH_CREATURE_DISPLAY_INFO (0x0976) reads one sixteen-dword row plus the
// four texture-variation names that follow it, and SMSG_PATCH_CREATURE_DISPLAY_INFO_EXTRA (0x0975)
// reads one twenty-one-dword row plus its bake name, each adding the row or updating the one it
// already holds. Both ids are read off the client's own opcode table, and that table agrees with
// the three ids this realm already speaks (0x05F4 spell attributes, 0x0667 level scaling,
// 0x0697 appearances).
//
// So the same rows now arrive over the wire, once per login, and the realm's `CreatureDisplayInfo`
// / `CreatureDisplayInfoExtra` tables stay the single source of truth (the data header is
// generated from them). Nothing here changes what the displays look like; it changes who carries
// them, which is what keeps a model fix from being a client download.
#include "destiny_weaver.h"

#include "Config.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include "destiny_weaver_display_data.h"

#include <cstring>

namespace
{
    /// The client's own ids for the display-row pushes. See the header of this file for how they
    /// were read out of its opcode table.
    constexpr uint16 SMSG_PATCH_CREATURE_DISPLAY_INFO = 0x0976;
    constexpr uint16 SMSG_PATCH_CREATURE_DISPLAY_INFO_EXTRA = 0x0975;

    constexpr char const *ENABLE_KEY = "DestinyWeaver.DisplayStream.Enable";

    using DestinyWeaverDisplayData::DisplayRow;
    using DestinyWeaverDisplayData::ExtraRow;
    using DestinyWeaverDisplayData::Displays;
    using DestinyWeaverDisplayData::Extras;

    /// A name on the wire: a uint32 length, then that many bytes - no terminator.
    void AppendName(WorldPacket &packet, char const *name)
    {
        uint32 const length = name ? uint32(std::strlen(name)) : 0;
        packet << length;
        if (length)
            packet.append(reinterpret_cast<uint8 const *>(name), length);
    }

    /// One extra row: id + twenty dwords, then the bake name.
    void SendExtraRow(Player *player, ExtraRow const &row)
    {
        WorldPacket packet(SMSG_PATCH_CREATURE_DISPLAY_INFO_EXTRA,
                           sizeof(row.Fields) + sizeof(uint32) +
                               (row.BakeName ? std::strlen(row.BakeName) : 0));
        packet.append(reinterpret_cast<uint8 const *>(row.Fields), sizeof(row.Fields));
        AppendName(packet, row.BakeName);
        player->SendDirectMessage(&packet);
    }

    /// One display row: id + fifteen dwords, then the four texture names. The four in-row texture
    /// slots stay exactly as the table holds them; the client skips them and reads the names.
    void SendDisplayRow(Player *player, DisplayRow const &row)
    {
        std::size_t extra = 0;
        for (char const *texture : row.Textures)
            extra += sizeof(uint32) + (texture ? std::strlen(texture) : 0);

        WorldPacket packet(SMSG_PATCH_CREATURE_DISPLAY_INFO, sizeof(row.Fields) + extra);
        packet.append(reinterpret_cast<uint8 const *>(row.Fields), sizeof(row.Fields));
        for (char const *texture : row.Textures)
            AppendName(packet, texture);
        player->SendDirectMessage(&packet);
    }
}

class destiny_weaver_display_script : public PlayerScript
{
public:
    destiny_weaver_display_script()
        : PlayerScript("destiny_weaver_display_script", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player *player) override
    {
        if (!player || !player->GetSession())
            return;

        if (!sConfigMgr->GetOption<bool>("DestinyWeaver.Enable", true) ||
            !sConfigMgr->GetOption<bool>(ENABLE_KEY, true))
            return;

        // The extra row first: a display row names it, and the client resolves one from the other.
        for (ExtraRow const &row : Extras)
            SendExtraRow(player, row);

        for (DisplayRow const &row : Displays)
            SendDisplayRow(player, row);

        LOG_DEBUG("module.destiny_weaver", "Streamed {} display and {} extra rows to {}",
                  sizeof(Displays) / sizeof(Displays[0]),
                  sizeof(Extras) / sizeof(Extras[0]), player->GetName());
    }
};

void AddSC_destiny_weaver_display()
{
    new destiny_weaver_display_script();
}
