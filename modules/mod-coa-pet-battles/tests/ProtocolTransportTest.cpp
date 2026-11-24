#include "Protocol/AddonMessage.h"
#include "Protocol/WireText.h"
#include <gtest/gtest.h>
#include <string>

using namespace CoAPetBattles::Protocol;

TEST(CoAPetBattlesProtocol, ParsesUpstreamWireFormat)
{
    std::optional<AddonMessage> const command = ParseAddonMessage("pbt|cmd|A1");
    ASSERT_TRUE(command.has_value());
    EXPECT_EQ(command->module, "pbt");
    EXPECT_EQ(command->action, "cmd");
    EXPECT_EQ(command->payload, "A1");

    std::optional<AddonMessage> const quit = ParseAddonMessage("pbt|quit");
    ASSERT_TRUE(quit.has_value());
    EXPECT_EQ(quit->action, "quit");
    EXPECT_EQ(quit->payload, "");

    std::optional<AddonMessage> const hello = ParseAddonMessage("core|hello|");
    ASSERT_TRUE(hello.has_value());
    EXPECT_EQ(hello->payload, "");

    std::optional<AddonMessage> const piped = ParseAddonMessage("pbj|setteam|1,2|3");
    ASSERT_TRUE(piped.has_value());
    EXPECT_EQ(piped->payload, "1,2|3");

    EXPECT_FALSE(ParseAddonMessage("a b|x|y").has_value());
    EXPECT_FALSE(ParseAddonMessage("pbt").has_value());
    EXPECT_FALSE(ParseAddonMessage("|cmd|A1").has_value());
    EXPECT_TRUE(ParseAddonMessage("pbt|cmd|" + std::string(247, 'x')).has_value());
    EXPECT_FALSE(ParseAddonMessage("pbt|cmd|" + std::string(248, 'x')).has_value());
}

TEST(CoAPetBattlesProtocol, RefusesOverlongSends)
{
    std::optional<std::string> const text = FormatAddonMessage("pbt", "msg", "hello");
    ASSERT_TRUE(text.has_value());
    EXPECT_EQ(*text, "pbt|msg|hello");
    EXPECT_TRUE(FormatAddonMessage("pbt", "msg", std::string(232, 'x')).has_value());
    EXPECT_FALSE(FormatAddonMessage("pbt", "msg", std::string(233, 'x')).has_value());
}

TEST(CoAPetBattlesProtocol, ChunksNumberEveryPart)
{
    EXPECT_EQ(Chunks({ "a", "b", "c" }), (std::vector<std::string> { "1/3;a", "2/3;b", "3/3;c" }));
    EXPECT_TRUE(Chunks({}).empty());
}

TEST(CoAPetBattlesProtocol, LongStatusListsSplitLikeUpstream)
{
    std::string text;
    std::vector<std::string> items;
    for (int i = 0; i < 7; ++i)
        items.push_back("Very Long Status Name Number " + std::to_string(i) + "~Spell_Holy_PowerWordShield~" +
            std::to_string(i) + "~1~" + std::to_string(i % 2));
    for (std::string const& item : items)
        text += (text.empty() ? "" : ";") + item;
    EXPECT_EQ(SplitStatusList(text), (std::vector<std::string> { items[0] + ";" + items[1] + ";",
        items[2] + ";" + items[3] + ";", items[4] + ";" + items[5] + ";", items[6] + ";" }));
    EXPECT_EQ(SplitStatusList(""), (std::vector<std::string> { "" }));
    EXPECT_EQ(SplitStatusList("A~i~1~1~0"), (std::vector<std::string> { "A~i~1~1~0;" }));
}

TEST(CoAPetBattlesProtocol, CapCutsAtSentencesLikeUpstream)
{
    EXPECT_EQ(Cap("Hits #the| target;", 40), "Hits  the  target ");
    EXPECT_EQ(Cap("First sentence here. Second sentence is long.", 30), "First sentence here.");
    EXPECT_EQ(Cap("A. Then a very long second sentence goes on", 30), "A. Then a very long second ...");
}

TEST(CoAPetBattlesProtocol, HelloRemembersAddons)
{
    AddonPeers peers;
    EXPECT_FALSE(peers.Has(7, "wotlk_petbattle"));
    peers.Hello(7, "AcoreLib wotlk_petbattle,wotlk_pets");
    EXPECT_TRUE(peers.Has(7, "wotlk_petbattle"));
    EXPECT_TRUE(peers.Has(7, "wotlk_pets"));
    EXPECT_TRUE(peers.Has(7, "AcoreLib"));
    EXPECT_FALSE(peers.Has(7, "wotlk_garrison"));
    EXPECT_FALSE(peers.Has(8, "wotlk_pets"));
    peers.Hello(7, "wotlk_pets");
    EXPECT_FALSE(peers.Has(7, "wotlk_petbattle"));
    peers.Forget(7);
    EXPECT_FALSE(peers.Has(7, "wotlk_pets"));
}
