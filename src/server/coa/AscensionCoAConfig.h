/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_COA_CONFIG_H
#define ASCENSION_COA_CONFIG_H

#include "Define.h"
#include <string>
#include <string_view>
#include <utility>
#include <vector>

class WorldPacket;
class WorldSession;

struct AscensionClientConfig
{
    std::vector<std::pair<std::string, int32>> Integers;
    std::vector<std::pair<std::string, bool>> Booleans;
    std::vector<std::pair<std::string, float>> Floats;
    std::vector<std::pair<std::string, float>> Rates;
};

using AscensionClientConfigSource = void (*)(AscensionClientConfig& config);

void RegisterAscensionClientConfig(AscensionClientConfigSource source);
void AppendAscensionClientConfigList(std::string_view list, std::vector<std::pair<std::string, bool>>& out);
void AppendAscensionClientConfigList(std::string_view list, std::vector<std::pair<std::string, int32>>& out);
AscensionClientConfig CollectAscensionClientConfig();
WorldPacket BuildAscensionCoAConfig();
void SendAscensionCoAConfig(WorldSession* session);

#endif
