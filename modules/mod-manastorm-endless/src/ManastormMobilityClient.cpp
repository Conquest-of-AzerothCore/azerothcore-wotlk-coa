#include "ManastormMobilityClient.h"

#include "ClientDBC.h"
#include "Config.h"
#include "Log.h"
#include "ManastormMgr.h"
#include "ManastormModuleConfig.h"
#include "ManastormRun.h"
#include "Map.h"
#include "Player.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <array>
#include <filesystem>
#include <string>

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless";
    constexpr uint16 PATCH_SPELL_OPCODE = 0x092A;
    constexpr uint32 FIRST_MOBILITY_SPELL = 1300179;
    constexpr uint32 MOBILITY_SPELL_COUNT = 7;
    constexpr uint32 CLIENT_FAMILY_WORD = 144;
    constexpr uint32 ELEMENTAL_BURST_FAMILY = 38;
    constexpr std::array<uint32, 4> STRING_FIELDS = { 136, 170, 153, 187 };

    struct SpellRow
    {
        std::array<uint32, 170> Values{};
        std::array<std::string, 4> Strings;
    };

    std::array<SpellRow, MOBILITY_SPELL_COUNT> originalRows;
    bool ready = false;

    void SendRow(Player* player, SpellRow const& row, bool patch)
    {
        WorldPacket packet(PATCH_SPELL_OPCODE, 1024);
        for (std::size_t word = 0; word < row.Values.size(); ++word)
            packet << (patch && word == CLIENT_FAMILY_WORD ? ELEMENTAL_BURST_FAMILY : row.Values[word]);

        // Native 0x092A uses name, description, rank, tooltip, each with a DWORD byte length.
        for (std::string const& text : row.Strings)
        {
            packet << uint32(text.size());
            if (!text.empty())
                packet.append(reinterpret_cast<uint8 const*>(text.data()), text.size());
        }

        player->SendDirectMessage(&packet);
    }
}

void ManastormMobilityClient::Load()
{
    ready = false;
    if (!ManastormModuleConfig::Enabled() || !ManastormModuleConfig::IsNativeClientMode() ||
        !sConfigMgr->GetOption<bool>("Manastorm.MobilityClientFamily38Test", false))
        return;

    ClientDBC dbc;
    std::string const path = (std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "Spell.dbc").string();
    if (!dbc.Load(path, 234))
        return;

    std::array<bool, MOBILITY_SPELL_COUNT> found{};
    for (uint32 index = 0; index < dbc.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = dbc.GetRecord(index);
        uint32 const id = record.GetUInt32(0);
        if (id < FIRST_MOBILITY_SPELL || id >= FIRST_MOBILITY_SPELL + MOBILITY_SPELL_COUNT)
            continue;

        std::size_t const rank = id - FIRST_MOBILITY_SPELL;
        SpellRow& row = originalRows[rank];
        uint32 word = 0;
        for (uint32 field = 0; field < 234;)
        {
            bool const localized = field == 136 || field == 153 || field == 170 || field == 187;
            row.Values[word++] = localized ? 0 : record.GetUInt32(field);
            field += localized ? 17 : 1;
        }

        for (std::size_t string = 0; string < STRING_FIELDS.size(); ++string)
            row.Strings[string] = std::string(record.GetString(STRING_FIELDS[string]));

        // Refuse a mismatched client table; never manufacture or repurpose a spell ID.
        if (word != row.Values.size() || record.GetUInt32(95) != 313 ||
            record.GetUInt32(122) != 0xFFFFFFFF || record.GetUInt32(123) != 0xFFFFFFFF ||
            record.GetUInt32(124) != 0xFFFFFFFF)
        {
            LOG_ERROR(LOG_FILTER, "Mobility client test disabled: unexpected DBC selectors for spell {}.", id);
            return;
        }
        found[rank] = true;
    }

    for (bool exists : found)
        if (!exists)
        {
            LOG_ERROR(LOG_FILTER, "Mobility client test disabled: Spell.dbc is missing a Mobility rank.");
            return;
        }

    ready = true;
    LOG_INFO(LOG_FILTER, "Mobility client family-38 test ready; only native Manastorm sessions receive patches.");
}

void ManastormMobilityClient::Sync(Player* player)
{
    if (!ready || !player || !player->GetSession() || player->GetSession()->IsBot())
        return;

    ManastormRun const* run = ManastormMgr::Instance().GetRunFor(player);
    Map const* map = player->FindMap();
    bool const patch = run && map && map->IsScriptedPrivateInstance() &&
        player->GetMapId() == run->GetSegment().MapId && player->GetInstanceId() == run->GetInstanceId();

    for (SpellRow const& row : originalRows)
        SendRow(player, row, patch);

    LOG_INFO(LOG_FILTER, "Mobility client family-38 test: {} seven rows for {} on map {} instance {}.",
        patch ? "patched" : "restored", player->GetGUID().ToString(), player->GetMapId(), player->GetInstanceId());
}
