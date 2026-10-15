/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionCoAConfig.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "Tokenize.h"
#include <charconv>
#include <string_view>

namespace
{
struct ClientRate
{
    std::string_view key;
    ServerConfigs setting;
};

constexpr ClientRate ClientRates[] = {
    { "RATE_AUCTION_DEPOSIT", RATE_AUCTION_DEPOSIT },
    { "RATE_XP_GLOBAL", RATE_XP_GLOBAL },
    { "RATE_XP_KILL", RATE_XP_KILL },
    { "RATE_XP_KILL_TBC", RATE_XP_KILL_TBC },
    { "RATE_XP_KILL_WOTLK", RATE_XP_KILL_WOTLK },
    { "RATE_XP_QUEST", RATE_XP_QUEST },
    { "RATE_XP_QUEST_TBC", RATE_XP_QUEST_TBC },
    { "RATE_XP_QUEST_WOTLK", RATE_XP_QUEST_WOTLK },
    { "RATE_XP_EXPLORE", RATE_XP_EXPLORE },
    { "RATE_XP_PROFESSION", RATE_XP_PROFESSION },
    { "RATE_XP_ELITE", RATE_XP_ELITE },
    { "RATE_XP_DUNGEON_ELITE", RATE_XP_DUNGEON_ELITE },
    { "RATE_XP_PROFESSION_GRAY_MODIFIER", RATE_XP_PROFESSION_GRAY },
    { "RATE_XP_PROFESSION_GREEN_MODIFIER", RATE_XP_PROFESSION_GREEN },
    { "RATE_XP_PROFESSION_YELLOW_MODIFIER", RATE_XP_PROFESSION_YELLOW },
    { "RATE_XP_PROFESSION_ORANGE_MODIFIER", RATE_XP_PROFESSION_ORANGE },
    { "RATE_XP_PROFESSION_MINING_MODIFIER", RATE_XP_PROFESSION_MINING },
    { "RATE_XP_PROFESSION_HERBALISM_MODIFIER", RATE_XP_PROFESSION_HERBALISM },
    { "RATE_XP_PROFESSION_DISENCHANTING_MODIFIER", RATE_XP_PROFESSION_DISENCHANTING },
    { "RATE_XP_PROFESSION_SKINNING_MODIFIER", RATE_XP_PROFESSION_SKINNING },
    { "RATE_XP_PROFESSION_FISHING_MODIFIER", RATE_XP_PROFESSION_FISHING },
    { "RATE_XP_PROFESSION_BLACKSMITHING_MODIFIER", RATE_XP_PROFESSION_BLACKSMITHING },
    { "RATE_XP_PROFESSION_JEWELCRAFTING_MODIFIER", RATE_XP_PROFESSION_JEWELCRAFTING },
    { "RATE_XP_PROFESSION_ALCHEMY_MODIFIER", RATE_XP_PROFESSION_ALCHEMY },
    { "RATE_XP_PROFESSION_ENCHANTING_MODIFIER", RATE_XP_PROFESSION_ENCHANTING },
    { "RATE_XP_PROFESSION_LEATHERWORKING_MODIFIER", RATE_XP_PROFESSION_LEATHERWORKING },
    { "RATE_XP_PROFESSION_FIRST_AID_MODIFIER", RATE_XP_PROFESSION_FIRST_AID },
    { "RATE_XP_PROFESSION_COOKING_MODIFIER", RATE_XP_PROFESSION_COOKING },
    { "RATE_XP_PROFESSION_ENGINEERING_MODIFIER", RATE_XP_PROFESSION_ENGINEERING },
    { "RATE_XP_PROFESSION_TAILORING_MODIFIER", RATE_XP_PROFESSION_TAILORING },
    { "RATE_XP_PROFESSION_LOCKPICKING_MODIFIER", RATE_XP_PROFESSION_LOCKPICKING },
    { "RATE_XP_PROFESSION_INSCRIPTION_MODIFIER", RATE_XP_PROFESSION_INSCRIPTION },
};

std::vector<AscensionClientConfigSource>& Sources()
{
    static std::vector<AscensionClientConfigSource> sources;
    return sources;
}

template <typename Wire, typename Value>
void AppendSection(WorldPacket& packet, std::vector<std::pair<std::string, Value>> const& values)
{
    packet << uint32(values.size());
    for (auto const& [key, value] : values)
    {
        packet << uint32(key.size());
        packet.append(reinterpret_cast<uint8 const*>(key.data()), key.size());
        packet << Wire(value);
    }
}

std::string_view TrimSpaces(std::string_view text)
{
    std::size_t const first = text.find_first_not_of(' ');
    if (first == std::string_view::npos)
        return {};
    return text.substr(first, text.find_last_not_of(' ') - first + 1);
}

template <typename Value>
void AppendConfigList(std::string_view list, std::vector<std::pair<std::string, Value>>& out)
{
    for (std::string_view entry : Acore::Tokenize(list, ',', false))
    {
        std::size_t const separator = entry.find('=');
        if (separator == std::string_view::npos)
            continue;

        std::string_view const key = TrimSpaces(entry.substr(0, separator));
        std::string_view const value = TrimSpaces(entry.substr(separator + 1));
        int32 number = 0;
        auto const [end, error] = std::from_chars(value.data(), value.data() + value.size(), number);
        if (key.empty() || error != std::errc() || end != value.data() + value.size())
            continue;

        out.emplace_back(std::string(key), static_cast<Value>(number));
    }
}
}

void AppendAscensionClientConfigList(std::string_view list, std::vector<std::pair<std::string, bool>>& out)
{
    AppendConfigList(list, out);
}

void AppendAscensionClientConfigList(std::string_view list, std::vector<std::pair<std::string, int32>>& out)
{
    AppendConfigList(list, out);
}

void RegisterAscensionClientConfig(AscensionClientConfigSource source)
{
    Sources().push_back(source);
}

AscensionClientConfig CollectAscensionClientConfig()
{
    AscensionClientConfig config;
    for (ClientRate const& rate : ClientRates)
        config.Rates.emplace_back(std::string(rate.key), sWorld->getRate(rate.setting));
    for (AscensionClientConfigSource source : Sources())
        source(config);
    return config;
}

WorldPacket BuildAscensionCoAConfig()
{
    AscensionClientConfig const config = CollectAscensionClientConfig();
    WorldPacket packet(SMSG_COA_CONFIG);
    uint32 constexpr integerVectorConfigCount = 0;
    uint32 constexpr floatVectorConfigCount = 0;
    AppendSection<int32>(packet, config.Integers);
    AppendSection<uint8>(packet, config.Booleans);
    AppendSection<float>(packet, config.Floats);
    AppendSection<float>(packet, config.Rates);
    packet << integerVectorConfigCount << floatVectorConfigCount;
    return packet;
}

void SendAscensionCoAConfig(WorldSession* session)
{
    if (!session)
        return;

    WorldPacket packet = BuildAscensionCoAConfig();
    session->SendPacket(&packet);
}
