#ifndef COA_PET_BATTLE_FIXTURE_READER_H
#define COA_PET_BATTLE_FIXTURE_READER_H

#include "Engine/Rng.h"
#include "PetBattleData.h"
#include <array>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace CoAPetBattles::Fixtures
{
    struct TracePet
    {
        std::string side;
        int32_t index = 0;
        uint32_t species = 0;
        int32_t level = 0;
        int32_t quality = 0;
        std::optional<std::array<int32_t, 3>> picks;
        std::optional<double> hp;
        std::vector<std::string> built;
        std::vector<std::pair<int32_t, uint32_t>> library;
    };

    struct TraceTip
    {
        std::string side;
        int32_t index = 0;
        int32_t slot = 0;
        std::string text;
        bool excluded = false;
    };

    struct TraceKitTip
    {
        std::string side;
        int32_t index = 0;
        int32_t slot = 0;
        int32_t option = 0;
        std::string text;
        bool excluded = false;
    };

    struct TraceRound
    {
        std::string commandP;
        std::string commandE;
        std::vector<std::string> events;
        std::string status;
        std::vector<std::vector<std::string>> states;
    };

    struct TraceBattle
    {
        int32_t id = 0;
        std::vector<Engine::RecordedRoll> rolls;
        std::vector<TracePet> pets;
        std::vector<TraceTip> tips;
        std::vector<TraceKitTip> kitTips;
        std::vector<TraceRound> rounds;
        std::optional<std::pair<uint32_t, double>> weather;
    };

    std::vector<std::string> FixtureLines(std::string const& name);
    std::string DecodeField(std::string const& text);
    std::vector<std::string> SplitLine(std::string const& line);
    DataSet LoadData();
    std::vector<TraceBattle> LoadTraces();
}

#endif
