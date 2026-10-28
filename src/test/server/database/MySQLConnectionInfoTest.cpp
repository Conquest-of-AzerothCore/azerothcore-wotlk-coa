/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "MySQLConnection.h"
#include "gtest/gtest.h"

TEST(MySQLConnectionInfoTest, AcceptsOnlyTheMySQLTransactionIsolationLevels)
{
    for (std::string_view const level : { "READ-UNCOMMITTED", "READ-COMMITTED", "REPEATABLE-READ", "SERIALIZABLE" })
        EXPECT_TRUE(MySQLConnectionInfo::IsTransactionIsolationLevel(level)) << level;

    for (std::string_view const level : { "", "read-committed", "READ COMMITTED", "READ_COMMITTED", " READ-COMMITTED",
        "READ-COMMITTED ", "READ-COMMITTED'; DROP DATABASE acore_characters; --", "DEFAULT" })
        EXPECT_FALSE(MySQLConnectionInfo::IsTransactionIsolationLevel(level)) << level;
}

TEST(MySQLConnectionInfoTest, KeepsTheServerDefaultIsolationUnlessOneIsGiven)
{
    MySQLConnectionInfo const unchanged("127.0.0.1;3306;acore;secret;acore_characters");
    EXPECT_TRUE(unchanged.transactionIsolation.empty());
    EXPECT_EQ(unchanged.database, "acore_characters");
    EXPECT_TRUE(unchanged.ssl.empty());

    MySQLConnectionInfo const committed("127.0.0.1;3306;acore;secret;acore_characters;nossl", "READ-COMMITTED");
    EXPECT_EQ(committed.transactionIsolation, "READ-COMMITTED");
    EXPECT_EQ(committed.host, "127.0.0.1");
    EXPECT_EQ(committed.port_or_socket, "3306");
    EXPECT_EQ(committed.user, "acore");
    EXPECT_EQ(committed.database, "acore_characters");
    EXPECT_EQ(committed.ssl, "nossl");
}
