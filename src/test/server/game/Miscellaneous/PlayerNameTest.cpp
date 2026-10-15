#include "ObjectMgr.h"
#include "SharedDefines.h"
#include "WorldMock.h"
#include "gtest/gtest.h"
#include <vector>

class PlayerNameTest : public ::testing::Test
{
protected:
    void SetUp() override
    {
        previousWorld = std::move(sWorld);
        auto* world = new ::testing::NiceMock<WorldMock>();
        ON_CALL(*world, getIntConfig(::testing::_)).WillByDefault(::testing::Return(0));
        ON_CALL(*world, getIntConfig(CONFIG_MIN_PLAYER_NAME)).WillByDefault(::testing::Return(2));
        sWorld.reset(world);
    }

    void TearDown() override
    {
        sWorld = std::move(previousWorld);
    }

    std::unique_ptr<IWorld> previousWorld;
};

TEST_F(PlayerNameTest, NormalizesEachWordAndKeepsSingleNames)
{
    for (auto const& [input, expected] : {
        std::pair{"aRTHAS", "Arthas"}, {"aRTHAS mENETHIL", "Arthas Menethil"},
        {"ИВАН ГРОМОВ", "Иван Громов"}})
    {
        std::string name(input);
        ASSERT_TRUE(normalizePlayerName(name));
        EXPECT_EQ(name, expected);
        EXPECT_EQ(ObjectMgr::CheckPlayerName(name, true), CHAR_NAME_SUCCESS);
    }
}

TEST_F(PlayerNameTest, RejectsMalformedSeparators)
{
    for (std::string name : {" Arthas", "Arthas ", "Arthas  Menethil", "Arthas Menethil Storm"})
    {
        EXPECT_FALSE(normalizePlayerName(name)) << name;
        EXPECT_EQ(ObjectMgr::CheckPlayerName(name, true), CHAR_NAME_INVALID_SPACE) << name;
    }
    for (std::string name : {"Arthas\tMenethil", "Arthas\nMenethil", "Arthas\xC2\xA0Menethil"})
        EXPECT_NE(ObjectMgr::CheckPlayerName(name, true), CHAR_NAME_SUCCESS) << name;
}

TEST_F(PlayerNameTest, ChecksEachWordLength)
{
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Abcdefghijkl Mnopqrstuvwx", true), CHAR_NAME_SUCCESS);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Abcdefghijklm", true), CHAR_NAME_TOO_LONG);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Arthas Abcdefghijklm", true), CHAR_NAME_TOO_LONG);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("A Menethil", true), CHAR_NAME_TOO_SHORT);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Arthas M", true), CHAR_NAME_TOO_SHORT);
}

TEST_F(PlayerNameTest, PreservesAlphabetAndRepeatedLetterRules)
{
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Arthas Иван", true), CHAR_NAME_MIXED_LANGUAGES);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Arthas Menethil2", true), CHAR_NAME_MIXED_LANGUAGES);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Arthas Meeenethil", true), CHAR_NAME_THREE_CONSECUTIVE);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Admingm Storm", true), CHAR_NAME_RESERVED);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Arthas Gm", true), CHAR_NAME_RESERVED);
}

TEST_F(PlayerNameTest, RespectsNativeByteCapacity)
{
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Абвгдежзийкл Мнопрстуфхц", true), CHAR_NAME_SUCCESS);
    EXPECT_EQ(ObjectMgr::CheckPlayerName("Абвгдежзийкл Мнопрстуфхцч", true), CHAR_NAME_TOO_LONG);
}

namespace
{
    PlayerNameByFirstName OnlineByFirstName(std::vector<std::string> online)
    {
        return [online = std::move(online)](std::string const& first)
        {
            std::string found;
            for (std::string const& name : online)
                if (name.starts_with(first + ' '))
                {
                    if (!found.empty())
                        return std::string();
                    found = name;
                }
            return found;
        };
    }
}

TEST_F(PlayerNameTest, JoinsOnlyQuotedNames)
{
    std::string name = "\"arthas";
    std::string_view rest = "menethil\" 80  extra";
    EXPECT_TRUE(joinQuotedPlayerName(name, rest));
    EXPECT_EQ(name, "arthas menethil");
    EXPECT_EQ(rest, "80  extra");

    name = "'Arthas";
    rest = "Menethil'";
    EXPECT_TRUE(joinQuotedPlayerName(name, rest));
    EXPECT_EQ(name, "Arthas Menethil");
    EXPECT_TRUE(rest.empty());

    name = "\"Jaina\"";
    rest = "hello";
    EXPECT_TRUE(joinQuotedPlayerName(name, rest));
    EXPECT_EQ(name, "Jaina");
    EXPECT_EQ(rest, "hello");

    for (auto const& [input, remainder] : {
        std::pair{"Arthas", "Menethil 80"}, {"\"Arthas", "Menethil 80"}, {"'Arthas", "Menethil\" 80"},
        {"\"Arthas", ""}, {"\"\"", "Menethil"}})
    {
        name = input;
        rest = remainder;
        EXPECT_FALSE(joinQuotedPlayerName(name, rest)) << input << ' ' << remainder;
        EXPECT_EQ(rest, remainder);
    }
}

TEST_F(PlayerNameTest, ResolvesQuotedWhisperToFullName)
{
    PlayerNameByFirstName const online = OnlineByFirstName({ "Arthas Menethil", "Arthas Storm" });

    std::string to = "\"Arthas";
    std::string msg = "Storm\" hello there";
    EXPECT_TRUE(resolveWhisperTarget(to, msg, online));
    EXPECT_EQ(to, "Arthas Storm");
    EXPECT_EQ(msg, "hello there");

    to = "\"Jaina\"";
    msg = "hi";
    EXPECT_TRUE(resolveWhisperTarget(to, msg, online));
    EXPECT_EQ(to, "Jaina");
    EXPECT_EQ(msg, "hi");
}

TEST_F(PlayerNameTest, KeepsUnquotedWhisperOnTheFirstWord)
{
    std::string to = "Arthas";
    std::string msg = "Menethil hello";
    EXPECT_FALSE(resolveWhisperTarget(to, msg, OnlineByFirstName({ "Arthas Menethil" })));
    EXPECT_EQ(to, "Arthas");
    EXPECT_EQ(msg, "Menethil hello");
}

TEST_F(PlayerNameTest, ResolvesStickyQuotedFirstNameOnlyWhenUnambiguous)
{
    std::string to = "\"uther";
    std::string msg = "hello";
    EXPECT_TRUE(resolveWhisperTarget(to, msg, OnlineByFirstName({ "Uther Light" })));
    EXPECT_EQ(to, "Uther Light");
    EXPECT_EQ(msg, "hello");

    to = "\"Arthas";
    EXPECT_FALSE(resolveWhisperTarget(to, msg, OnlineByFirstName({ "Arthas Menethil", "Arthas Storm" })));
    EXPECT_EQ(to, "\"Arthas");
}

TEST_F(PlayerNameTest, ValidatesBothDeclinedNameComponents)
{
    DeclinedName names;
    for (std::string& name : names.name)
        name = "Иван Громов";
    EXPECT_TRUE(ObjectMgr::CheckDeclinedNames(L"Иван Громов", names));

    names.name[1] = "Иван Другой";
    EXPECT_FALSE(ObjectMgr::CheckDeclinedNames(L"Иван Громов", names));
    names.name[1] = "Иван";
    EXPECT_FALSE(ObjectMgr::CheckDeclinedNames(L"Иван Громов", names));
}
