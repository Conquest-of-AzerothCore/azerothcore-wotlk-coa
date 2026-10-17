#include "GrootCoinRules.h"
#include <gtest/gtest.h>

using namespace GrootCoin;

TEST(GrootCoinRules, AwardAmountsAreStrictPositiveDecimalsUpToTheMaximum)
{
    EXPECT_EQ(ParseAwardAmount("1", 25), 1u);
    EXPECT_EQ(ParseAwardAmount("25", 25), 25u);
    EXPECT_FALSE(ParseAwardAmount("26", 25));
    EXPECT_FALSE(ParseAwardAmount("0", 25));
    EXPECT_FALSE(ParseAwardAmount("-1", 25));
    EXPECT_FALSE(ParseAwardAmount("+3", 25));
    EXPECT_FALSE(ParseAwardAmount(" 3", 25));
    EXPECT_FALSE(ParseAwardAmount("3.0", 25));
    EXPECT_FALSE(ParseAwardAmount("0x5", 25));
    EXPECT_FALSE(ParseAwardAmount("", 25));
    EXPECT_FALSE(ParseAwardAmount("4294967296", UINT32_MAX));
    EXPECT_FALSE(ParseAwardAmount("99999999999", UINT32_MAX));
    EXPECT_FALSE(ParseAwardAmount("1001", 5000));
}

TEST(GrootCoinRules, IssuesAreCanonicalNumbersNotUrls)
{
    EXPECT_EQ(ParseIssueNumber("6696"), 6696u);
    EXPECT_FALSE(ParseIssueNumber("#6696"));
    EXPECT_FALSE(ParseIssueNumber("https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/6696"));
    EXPECT_FALSE(ParseIssueNumber("0"));
    EXPECT_FALSE(ParseIssueNumber("4294967296"));
}

TEST(GrootCoinRules, AuditTextIsRequiredBoundedAndPrintable)
{
    EXPECT_TRUE(IsValidAuditText("Reproduced the crash", REASON_MAX));
    EXPECT_FALSE(IsValidAuditText("", REASON_MAX));
    EXPECT_FALSE(IsValidAuditText("   ", REASON_MAX));
    EXPECT_FALSE(IsValidAuditText("line\nbreak", REASON_MAX));
    EXPECT_TRUE(IsValidAuditText(std::string(ATTRIBUTION_MAX, 'a'), ATTRIBUTION_MAX));
    EXPECT_FALSE(IsValidAuditText(std::string(ATTRIBUTION_MAX + 1, 'a'), ATTRIBUTION_MAX));
    EXPECT_TRUE(IsValidAuditText("'; DROP TABLE grootcoin_award; --", REASON_MAX));
}

TEST(GrootCoinRules, HistoryCountDefaultsAndCaps)
{
    EXPECT_EQ(ParseHistoryCount(""), HISTORY_DEFAULT);
    EXPECT_EQ(ParseHistoryCount("5"), 5u);
    EXPECT_EQ(ParseHistoryCount("1000"), HISTORY_MAX);
    EXPECT_FALSE(ParseHistoryCount("0"));
    EXPECT_FALSE(ParseHistoryCount("-5"));
    EXPECT_FALSE(ParseHistoryCount("ten"));
}

TEST(GrootCoinRules, PilotRatePaysExactBundles)
{
    constexpr uint32_t tokenStack = 5000000;
    EXPECT_EQ(TokensFor(1, DEFAULT_TOKENS_PER_COIN, tokenStack), 100u);
    EXPECT_EQ(TokensFor(5, DEFAULT_TOKENS_PER_COIN, tokenStack), 500u);
    EXPECT_EQ(TokensFor(10, DEFAULT_TOKENS_PER_COIN, tokenStack), 1000u);
    EXPECT_TRUE(IsExchangeBundle(1));
    EXPECT_TRUE(IsExchangeBundle(5));
    EXPECT_TRUE(IsExchangeBundle(10));
    EXPECT_FALSE(IsExchangeBundle(0));
    EXPECT_FALSE(IsExchangeBundle(2));
    EXPECT_FALSE(IsExchangeBundle(100));
}

TEST(GrootCoinRules, RatesThatOverflowOrExceedAStackAreRejected)
{
    EXPECT_FALSE(TokensFor(10, 0, 5000000));
    EXPECT_FALSE(TokensFor(0, 100, 5000000));
    EXPECT_FALSE(TokensFor(10, UINT32_MAX, 0));
    EXPECT_FALSE(TokensFor(10, 500001, 5000000));
    EXPECT_EQ(TokensFor(10, 500000, 5000000), 5000000u);
    EXPECT_TRUE(IsValidRate(100, 5000000));
    EXPECT_FALSE(IsValidRate(0, 5000000));
    EXPECT_FALSE(IsValidRate(600000, 5000000));
    EXPECT_FALSE(IsValidRate(UINT32_MAX / 5, 0));
}

TEST(GrootCoinRules, OperationIdsAreVersion4Uuids)
{
    std::array<uint8_t, 16> bytes{};
    bytes.fill(0xFF);
    std::string const id = FormatUuid(bytes);
    EXPECT_EQ(id, "ffffffff-ffff-4fff-bfff-ffffffffffff");
    EXPECT_TRUE(IsUuid(id));
    EXPECT_EQ(FormatUuid({}), "00000000-0000-4000-8000-000000000000");
    EXPECT_FALSE(IsUuid("FFFFFFFF-FFFF-4FFF-BFFF-FFFFFFFFFFFF"));
    EXPECT_FALSE(IsUuid("ffffffff-ffff-4fff-bfff-fffffffffff"));
    EXPECT_FALSE(IsUuid("ffffffffXffff-4fff-bfff-ffffffffffff"));
}

TEST(GrootCoinRules, CoinIdsAreDistinctFromTheBazaarToken)
{
    EXPECT_NE(COIN_ITEM, 975001u);
    EXPECT_EQ(COIN_ITEM, 910001u);
    EXPECT_EQ(COIN_DISPLAY, 990001u);
}

TEST(GrootCoinRules, ExternalSourcesAreNamedAndNeverGm)
{
    EXPECT_TRUE(IsValidExternalSource("website"));
    EXPECT_TRUE(IsValidExternalSource("github"));
    EXPECT_TRUE(IsValidExternalSource("bug-bot_2"));
    EXPECT_FALSE(IsValidExternalSource("gm"));
    EXPECT_TRUE(IsValidSource("gm"));
    EXPECT_FALSE(IsValidExternalSource(""));
    EXPECT_FALSE(IsValidExternalSource("Website"));
    EXPECT_FALSE(IsValidExternalSource("web site"));
    EXPECT_FALSE(IsValidExternalSource(std::string(SOURCE_MAX + 1, 'a')));
    EXPECT_TRUE(IsValidSourceRef("bug:1234"));
    EXPECT_TRUE(IsValidSourceRef("7447"));
    EXPECT_FALSE(IsValidSourceRef(""));
    EXPECT_FALSE(IsValidSourceRef(" 7447"));
    EXPECT_FALSE(IsValidSourceRef("74\n47"));
    EXPECT_FALSE(IsValidSourceRef(std::string(SOURCE_REF_MAX + 1, '1')));
}

TEST(GrootCoinRules, QueuedAwardsPassTheSameCapsAsTheCommand)
{
    EXPECT_EQ(CheckQueuedAward("website", "bug:1234", 42, 1, 25, "Confirmed bug #1234", 7), QueuedAwardCheck::Ok);
    EXPECT_EQ(CheckQueuedAward("gm", "bug:1234", 42, 1, 25, "r", 7), QueuedAwardCheck::InvalidSource);
    EXPECT_EQ(CheckQueuedAward("website", "", 42, 1, 25, "r", 7), QueuedAwardCheck::InvalidSourceRef);
    EXPECT_EQ(CheckQueuedAward("website", "x", 42, 0, 25, "r", 7), QueuedAwardCheck::InvalidAmount);
    EXPECT_EQ(CheckQueuedAward("website", "x", 42, 26, 25, "r", 7), QueuedAwardCheck::InvalidAmount);
    EXPECT_EQ(CheckQueuedAward("website", "x", 42, 1001, 5000, "r", 7), QueuedAwardCheck::InvalidAmount);
    EXPECT_EQ(CheckQueuedAward("website", "x", 42, 1, 25, "  ", 7), QueuedAwardCheck::InvalidReason);
    EXPECT_EQ(CheckQueuedAward("website", "x", 0, 1, 25, "r", 7), QueuedAwardCheck::InvalidCharacter);
    EXPECT_EQ(CheckQueuedAward("website", "x", 42, 1, 25, "r", 0), QueuedAwardCheck::NoRequester);
}

TEST(GrootCoinRules, StaffMayAwardTheirOwnAccount)
{
    // The checks never look at who owns the character: a requester awarding
    // a character on their own account passes like any other request.
    EXPECT_EQ(CheckQueuedAward("website", "bug:9", 42, 1, 25, "Own report", 7), QueuedAwardCheck::Ok);
    EXPECT_EQ(CheckQueuedAward("website", "bug:9", 7, 1, 25, "Own report", 7), QueuedAwardCheck::Ok);
}

TEST(GrootCoinRules, AReusedReferenceIsNeverPaidTwice)
{
    EXPECT_EQ(ClassifyExisting(false, 0, 0, 42, 1), ExistingAward::None);
    // The same request seen again (a retry after a restart) is reported as already paid.
    EXPECT_EQ(ClassifyExisting(true, 42, 1, 42, 1), ExistingAward::SameRequest);
    // A different character or amount under a used reference is a conflict; nothing is sent.
    EXPECT_EQ(ClassifyExisting(true, 42, 1, 43, 1), ExistingAward::Conflict);
    EXPECT_EQ(ClassifyExisting(true, 42, 1, 42, 2), ExistingAward::Conflict);
}

TEST(GrootCoinRules, TheQueueIsLeftAloneUnlessBothSwitchesAreOn)
{
    EXPECT_FALSE(ShouldPollQueue(false, false));
    EXPECT_FALSE(ShouldPollQueue(true, false));
    EXPECT_FALSE(ShouldPollQueue(false, true));
    EXPECT_TRUE(ShouldPollQueue(true, true));
    EXPECT_EQ(QueuePollSeconds(60), 60u);
    EXPECT_EQ(QueuePollSeconds(0), MIN_QUEUE_POLL_SECONDS);
}

TEST(GrootCoinRules, ExchangeAllTakesExactlyTheCarriedCoins)
{
    EXPECT_TRUE(IsExchangeAmount(1, 0));
    EXPECT_TRUE(IsExchangeAmount(5, 3));
    EXPECT_TRUE(IsExchangeAmount(10, 12));
    EXPECT_TRUE(IsExchangeAmount(7, 7));
    EXPECT_TRUE(IsExchangeAmount(1000, 1000));
    EXPECT_FALSE(IsExchangeAmount(7, 8));
    EXPECT_FALSE(IsExchangeAmount(0, 0));
    EXPECT_FALSE(IsExchangeAmount(3, 0));
    EXPECT_EQ(TokensFor(7, 100, 5000000), 700u);
}

TEST(GrootCoinRules, PopupOfferMustMatchCoinsAndRate)
{
    EXPECT_TRUE(MatchesOffer(3, 100, 300));
    EXPECT_TRUE(MatchesOffer(10, 100, 1000));
    EXPECT_FALSE(MatchesOffer(4, 100, 300));   // carried changed after the pop-up
    EXPECT_FALSE(MatchesOffer(3, 120, 300));   // rate changed after the pop-up
    EXPECT_FALSE(MatchesOffer(0, 100, 0));
    EXPECT_FALSE(MatchesOffer(3, 0, 0));
    EXPECT_FALSE(MatchesOffer(50000000, 100, 705032704u)); // no wrap-around
}

TEST(GrootCoinRules, ExchangeNeedsExactlyOneCharacterDatabaseWorker)
{
    EXPECT_TRUE(ExchangeSafeWithWorkers(1));
    EXPECT_FALSE(ExchangeSafeWithWorkers(0));
    EXPECT_FALSE(ExchangeSafeWithWorkers(2));
    EXPECT_FALSE(ExchangeSafeWithWorkers(16));
}

TEST(GrootCoinRules, DebitsUseSmallestStacksFirstAndNeverOverdraw)
{
    using V = std::vector<uint32_t>;
    EXPECT_EQ(PlanDebits(V{ 10, 3, 7 }, 5), (V{ 0, 3, 2 }));
    EXPECT_EQ(PlanDebits(V{ 10, 3, 7 }, 20), (V{ 10, 3, 7 }));
    EXPECT_EQ(PlanDebits(V{ 4, 4 }, 5), (V{ 4, 1 }));      // ties keep position order
    EXPECT_EQ(PlanDebits(V{ 1000 }, 1), (V{ 1 }));
    EXPECT_TRUE(PlanDebits(V{ 10, 3, 7 }, 21).empty());   // not enough: nothing is planned
    EXPECT_TRUE(PlanDebits(V{}, 1).empty());
    EXPECT_TRUE(PlanDebits(V{ 5 }, 0).empty());
}
