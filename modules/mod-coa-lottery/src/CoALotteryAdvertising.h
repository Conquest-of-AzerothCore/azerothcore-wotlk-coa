#ifndef COA_LOTTERY_ADVERTISING_H
#define COA_LOTTERY_ADVERTISING_H

#include <algorithm>
#include <array>
#include <cstdint>
#include <string>
#include <string_view>

namespace CoALottery
{
    constexpr uint32_t GallywixMap = 0;
    constexpr float GallywixX = -8787.7705f;
    constexpr float GallywixY = 640.43396f;
    constexpr float GallywixZ = 96.12781f;
    constexpr float GoldilocksX = -8788.967f;
    constexpr float GoldilocksY = 643.0418f;
    constexpr float GoldilocksZ = 94.944855f;

    struct LotteryLocation
    {
        uint32_t map;
        float gallywixX, gallywixY, gallywixZ;
        float goldilocksX, goldilocksY, goldilocksZ;
        float orientation;
    };

    constexpr LotteryLocation StormwindLotteryLocation =
        { GallywixMap, GallywixX, GallywixY, GallywixZ, GoldilocksX, GoldilocksY, GoldilocksZ, 3.14159265f };
    constexpr LotteryLocation OrgrimmarLotteryLocation =
        { 1, 1621.1122f, -4419.4966f, 14.876221f, 1623.0135f, -4417.805f, 14.7874975f, 4.71238898f };

    inline float GoldilocksScale(uint32_t duration, uint64_t remaining)
    {
        if (!duration)
            return 0.5f;
        return 1.5f - float(std::min<uint64_t>(remaining, duration)) / float(duration);
    }

    constexpr auto AdvertisementLines = std::to_array<std::string_view>({
        "{city}! Gallywix's lottery jackpot is up to {pot}! Goldilocks has your ticket to the big time!",
        "{player}, you look like someone with expensive tastes! Ten gold for a ticket. Give Goldilocks a visit!",
        "Only {time} until the draw! Stop counting your coppers and start dreaming about {pot}!",
        "Tired of splitting loot with four other cheapskates? The winning ticket takes the entire pot!",
        "The jackpot is {pot}, pal! That's a lot of repairs, mounts, and other questionable financial decisions!",
        "Time is money, and you've got {time} left! Get your golden tickets from Goldilocks!",
        "Rigged?! No, but of course I've got a feeeew house tickets... Same odds as yours... Read the rules!",
        "{player}, your next big adventure could start at the mailbox! Winners get their gold mailed straight to them and I pay for postage out of sheer generosity!",
        "The draw is in {time}! Buy more tickets for more chances. No guarantees and certainly no refunds!",
        "Gallywix's lottery! {pot} in the pot! Goldilocks sells the tickets whilst I provide the entrepreneurial genius!",
        "Someone wins? We mail the prize! I win on a house ticket? The pot gets destroyed! Nobody can say I hid the rules!",
        "{player}, got ten gold and a dream? Talk to Goldilocks!",
        "{time} left, {pot} at stake! Remember: a golden ticket buys a chance, not a guarantee!",
        "It's demotions for everyone if the Sharks beat the Buccaneers or if this lottery does not reach gold cap!",
        "Thank you for your hard work and dedication in fighting Azeroth's inflation. Unpaid overtime is approved for all!",
        "Is that you, {player}? Have you signed up for this week's raffle?",
        "You're all lazy! Get back to work. Especially you, {player}!",
        "What's this I hear about a party? I wasn't invited!",
        "All hail the greatest trade prince on Azeroth... me!"
    });

    inline std::string AdvertisementTime(uint64_t remaining)
    {
        uint64_t amount;
        std::string unit;
        if (remaining > 86400)
        {
            amount = remaining / 86400;
            unit = "day";
        }
        else if (remaining > 3600)
        {
            amount = remaining / 3600;
            unit = "hour";
        }
        else
        {
            amount = remaining ? std::max<uint64_t>(1, remaining / 60) : 0;
            unit = "minute";
        }
        return std::to_string(amount) + " " + unit + (amount == 1 ? "" : "s");
    }

    inline std::string BuildAdvertisement(uint32_t index, uint32_t copper, uint64_t remaining,
        std::string_view playerName, std::string_view cityName = "Stormwind")
    {
        std::string message(AdvertisementLines[index % AdvertisementLines.size()]);
        std::string pot = std::to_string(copper / 10000) + " gold";
        std::string time = AdvertisementTime(remaining);
        auto replace = [&message](std::string_view token, std::string_view value)
        {
            size_t position = 0;
            while ((position = message.find(token, position)) != std::string::npos)
            {
                message.replace(position, token.size(), value);
                position += value.size();
            }
        };
        replace("{city}", cityName);
        replace("{pot}", pot);
        replace("{time}", time);
        replace("{player}", playerName.empty() ? std::string_view("You there") : playerName);
        return message;
    }
}

#endif
