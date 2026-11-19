#ifndef COA_BATTLEGROUND_REWARDS_POLICY_H
#define COA_BATTLEGROUND_REWARDS_POLICY_H

#include <array>
#include <cstdint>

namespace CoABattlegroundRewardsPolicy
{
    struct RewardBand
    {
        uint8_t minLevel;
        uint8_t maxLevel;
        uint32_t winQuest;
        uint32_t lossQuest;
    };

    inline constexpr std::array<RewardBand, 6> RewardBands = { {
        { 10, 20, 90001, 90008 },
        { 21, 30, 90002, 90009 },
        { 31, 40, 90003, 90010 },
        { 41, 50, 90004, 90011 },
        { 51, 59, 90005, 90012 },
        { 60, 60, 190005, 190012 },
    } };

    constexpr uint32_t RewardQuestFor(uint8_t level, bool won)
    {
        for (RewardBand const& band : RewardBands)
            if (level >= band.minLevel && level <= band.maxLevel)
                return won ? band.winQuest : band.lossQuest;
        return 0;
    }

    inline constexpr uint8_t FirstWinOfDayLevel = 60;
    inline constexpr uint32_t FirstWinOfDayBonusArenaPoints = 300;

    constexpr uint32_t FirstWinOfDayBonusFor(uint8_t level, bool won, bool firstWinToday)
    {
        return won && firstWinToday && level == FirstWinOfDayLevel ? FirstWinOfDayBonusArenaPoints : 0;
    }
}

#endif
