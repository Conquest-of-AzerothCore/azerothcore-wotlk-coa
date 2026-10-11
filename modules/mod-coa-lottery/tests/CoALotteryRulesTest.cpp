#include "CoALotteryRules.h"
#include <gtest/gtest.h>
#include <map>

using namespace CoALottery;

TEST(CoALottery, PurchasesRequireFundsAndCannotOverflowThePot)
{
    EXPECT_FALSE(CanPurchase(TicketCost - 1, 0, 0, 1, 100));
    EXPECT_TRUE(CanPurchase(TicketCost, 0, 0, 1, 100));
    EXPECT_FALSE(CanPurchase(TicketCost, MaximumPot, 0, 1, 100));
    EXPECT_TRUE(CanPurchase(TicketCost, MaximumPot - TicketCost, 0, 1, 100));
    EXPECT_FALSE(CanPurchase(TicketCost, 0, MaximumTickets, 1, 0));
    EXPECT_FALSE(CanPurchase(UINT32_MAX, 0, 0, UINT32_MAX, 100));
    EXPECT_FALSE(CanPurchase(TicketCost, 0, 0, 1, 101));
    EXPECT_EQ(Contribution(10, 70), 700000u);
}

TEST(CoALottery, EachTicketHasExactlyOneWinningPosition)
{
    std::map<uint32_t, uint32_t> entries = {{ 10, 1 }, { 20, 10 }, { 30, 100 }};
    std::map<uint32_t, uint32_t> wins;
    for (uint32_t ticket = 0; ticket < 111; ++ticket)
        ++wins[SelectWinner(entries, ticket)];
    EXPECT_EQ(wins, entries);
    EXPECT_EQ(SelectWinner(entries, 111), 0u);
    EXPECT_EQ(SelectWinner(std::map<uint32_t, uint32_t>{}, 0), 0u);
}

TEST(CoALottery, BonusCsvRejectsInvalidEntriesAndKeepsTheLastValidPool)
{
    std::vector<uint32_t> items;
    ASSERT_TRUE(ParseBonusItems("97393, 98073,97393", items));
    EXPECT_EQ(items, (std::vector<uint32_t>{97393, 98073}));
    for (auto invalid : {"0", "-1", "97393,", "97393,,98073", "abc", "4294967296"})
    {
        EXPECT_FALSE(ParseBonusItems(invalid, items));
        EXPECT_EQ(items, (std::vector<uint32_t>{97393, 98073}));
    }
    EXPECT_TRUE(ParseBonusItems("", items));
    EXPECT_TRUE(items.empty());
}
