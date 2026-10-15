/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "DatabaseEnv.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <string_view>

namespace
{
    constexpr uint16 SMSG_ACCOUNT_INFO = 0x09BB;

    constexpr std::array<uint32, 5> GameMasterLevels = { 0, 1, 2, 6, 7 };
    constexpr std::array<std::string_view, 3> GenderTokens = { "GENDER_MALE", "GENDER_FEMALE", "GENDER_NONE" };
    constexpr std::array<std::string_view, 12> RaceTokens = { "", "RACE_HUMAN", "RACE_ORC", "RACE_DWARF",
        "RACE_NIGHTELF", "RACE_UNDEAD_PLAYER", "RACE_TAUREN", "RACE_GNOME", "RACE_TROLL", "RACE_GOBLIN",
        "RACE_BLOODELF", "RACE_DRAENEI" };
    constexpr std::array<std::string_view, 33> ClassTokens = { "", "CLASS_WARRIOR", "CLASS_PALADIN", "CLASS_HUNTER",
        "CLASS_ROGUE", "CLASS_PRIEST", "CLASS_DEATH_KNIGHT", "CLASS_SHAMAN", "CLASS_MAGE", "CLASS_WARLOCK",
        "CLASS_HERO", "CLASS_DRUID", "CLASS_BARBARIAN", "CLASS_WITCH_DOCTOR", "CLASS_DEMON_HUNTER",
        "CLASS_WITCH_HUNTER", "CLASS_STORMBRINGER", "CLASS_KNIGHT_OF_XOROTH", "CLASS_GUARDIAN", "CLASS_MONK",
        "CLASS_SON_OF_ARUGAL", "CLASS_RANGER", "CLASS_CHRONOMANCER", "CLASS_NECROMANCER", "CLASS_PYROMANCER",
        "CLASS_CULTIST", "CLASS_STARCALLER", "CLASS_SUN_CLERIC", "CLASS_TINKER", "CLASS_VENOMANCER", "CLASS_REAPER",
        "CLASS_PRIMALIST", "CLASS_RUNEMASTER" };

    template <typename Value, std::size_t Count>
    Value Lookup(std::array<Value, Count> const& values, std::size_t index)
    {
        return values[std::min(index, Count - 1)];
    }

    template <std::size_t Count>
    std::string_view Token(std::array<std::string_view, Count> const& tokens, std::size_t index)
    {
        return index < Count ? tokens[index] : std::string_view();
    }

    void SendAccountInfo(WorldSession* session, QueryResult const& result)
    {
        WorldPacket packet(SMSG_ACCOUNT_INFO, 64);
        packet << uint32(0) << Lookup(GameMasterLevels, session->GetSecurity()) << uint8(0) << uint8(0);
        packet << uint32(result ? result->GetRowCount() : 0);
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                uint8 const race = fields[3].Get<uint8>();
                packet << fields[0].Get<std::string>() << Token(GenderTokens, fields[1].Get<uint8>());
                packet << uint32(fields[2].Get<uint8>()) << Token(ClassTokens, fields[4].Get<uint8>());
                packet << Token(RaceTokens, race);
                packet << (Player::TeamIdForRace(race) == TEAM_ALLIANCE ? "Alliance" : "Horde");
            } while (result->NextRow());
        }
        session->SendPacket(&packet);
    }

    class AscensionAccountInfoPlayer final : public PlayerScript
    {
    public:
        AscensionAccountInfoPlayer() : PlayerScript("AscensionAccountInfoPlayer",
            { PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP }) { }

        void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket&) override
        {
            WorldSession* session = player->GetSession();
            if (session->IsBot())
                return;

            std::string const query = Acore::StringFormat("SELECT `name`, `gender`, `level`, `race`, `class` "
                "FROM `characters` WHERE `account` = {} AND `deleteInfos_Name` IS NULL "
                "ORDER BY COALESCE(`order`, `guid`)", session->GetAccountId());
            session->GetQueryProcessor().AddCallback(CharacterDatabase.AsyncQuery(query).WithCallback(
                [session](QueryResult result) { SendAccountInfo(session, result); }));
        }
    };
}

void AddAscensionAccountInfoScripts()
{
    new AscensionAccountInfoPlayer();
}
