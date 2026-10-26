/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAProbeRelay.h"
#include <gtest/gtest.h>

using namespace CoAProbeRelay;

namespace
{
ReplyChunk Chunk(std::string const& req, uint32 index, uint32 total, std::string const& data)
{
    return ReplyChunk{req, index, total, data};
}
}

TEST(ProbeRelay, RequestMessageBuildsPrefixedQuery)
{
    EXPECT_EQ(RequestMessage("r1", "spell 501281"), std::optional<std::string>("CoaProbe\tQ:r1:spell 501281"));
    EXPECT_EQ(RequestMessage("r1", "ping"), std::optional<std::string>("CoaProbe\tQ:r1:ping"));
}

TEST(ProbeRelay, RequestMessageRejectsWriteCommands)
{
    for (std::string_view line :
             {"eval 1", "pksend 1", "pkwatch 1", "evwatch X", "evunwatch X", "pkunwatch 1", "", " ping"})
        EXPECT_FALSE(RequestMessage("r1", line).has_value()) << line;
}

TEST(ProbeRelay, RequestMessageRejectsControlCharacters)
{
    EXPECT_FALSE(RequestMessage("r1", "spell 1\t2").has_value());
    EXPECT_FALSE(RequestMessage("r1", "spell 1\n2").has_value());
    EXPECT_FALSE(RequestMessage("r1", std::string_view("spell 1\0" "2", 9)).has_value());
}

TEST(ProbeRelay, RequestMessageRejectsInvalidRequestIds)
{
    EXPECT_FALSE(RequestMessage("", "ping").has_value());
    EXPECT_FALSE(RequestMessage(std::string(17, 'a'), "ping").has_value());
    EXPECT_FALSE(RequestMessage("a:b", "ping").has_value());
    EXPECT_TRUE(RequestMessage(std::string(16, 'a'), "ping").has_value());
}

TEST(ProbeRelay, RequestMessageEnforces255Bytes)
{
    std::string const head = "CoaProbe\tQ:r1:spell ";
    std::string const fits = "spell " + std::string(MaxAddonMessage - head.size(), 'x');
    std::optional<std::string> const message = RequestMessage("r1", fits);
    ASSERT_TRUE(message.has_value());
    EXPECT_EQ(message->size(), 255u);
    EXPECT_FALSE(RequestMessage("r1", fits + "x").has_value());
}

TEST(ProbeRelay, ParseReplyChunkReadsHeader)
{
    std::optional<ReplyChunk> const chunk = ParseReplyChunk("CoaProbe\tR:r1:2:3:abc:def");
    ASSERT_TRUE(chunk.has_value());
    EXPECT_EQ(chunk->req, "r1");
    EXPECT_EQ(chunk->index, 2u);
    EXPECT_EQ(chunk->total, 3u);
    EXPECT_EQ(chunk->data, "abc:def");
}

TEST(ProbeRelay, ParseReplyChunkAcceptsEmptyData)
{
    std::optional<ReplyChunk> const chunk = ParseReplyChunk("CoaProbe\tR:r1:1:1:");
    ASSERT_TRUE(chunk.has_value());
    EXPECT_EQ(chunk->data, "");
}

TEST(ProbeRelay, ParseReplyChunkRejectsMalformed)
{
    for (std::string_view message : {"Other\tR:r1:1:1:x", "CoaProbe\tQ:r1:1:1:x", "CoaProbe\tR:r1:0:1:x",
             "CoaProbe\tR:r1:3:2:x", "CoaProbe\tR:r1:1:65:x", "CoaProbe\tR:r1:a:2:x", "CoaProbe\tR:r1:1:b:x",
             "CoaProbe\tR:r1:1:1", "CoaProbe\tR:r1:1", "CoaProbe\tR::1:1:x", "CoaProbe R:r1:1:1:x",
             "CoaProbe\tR:r1:-1:1:x", "CoaProbe\tR:r1:0001:1:x"})
        EXPECT_FALSE(ParseReplyChunk(message).has_value()) << message;
    EXPECT_TRUE(ParseReplyChunk("CoaProbe\tR:r1:64:64:x").has_value());
}

TEST(ProbeRelay, BookAssemblesOutOfOrderChunks)
{
    ReplyBook book;
    book.Arm(1, "a", 0);
    EXPECT_TRUE(book.Accept(1, Chunk("a", 3, 3, "ghi"), 10));
    EXPECT_TRUE(book.Accept(1, Chunk("a", 1, 3, "abc"), 20));
    ReplyStatus pending = book.Status(1, "a", 25);
    EXPECT_EQ(pending.state, ReplyState::Pending);
    EXPECT_EQ(pending.received, 2u);
    EXPECT_EQ(pending.total, 3u);
    EXPECT_TRUE(book.Accept(1, Chunk("a", 2, 3, "def"), 30));
    ReplyStatus complete = book.Status(1, "a", 40);
    EXPECT_EQ(complete.state, ReplyState::Complete);
    EXPECT_EQ(complete.body, "abcdefghi");
}

TEST(ProbeRelay, BookReportsArmedRequestWithoutChunksAsPending)
{
    ReplyBook book;
    book.Arm(1, "a", 0);
    ReplyStatus status = book.Status(1, "a", 1);
    EXPECT_EQ(status.state, ReplyState::Pending);
    EXPECT_EQ(status.received, 0u);
    EXPECT_EQ(status.total, 0u);
}

TEST(ProbeRelay, BookIgnoresUnarmedRequests)
{
    ReplyBook book;
    EXPECT_FALSE(book.Accept(1, Chunk("a", 1, 1, "x"), 0));
    EXPECT_EQ(book.Status(1, "a", 0).state, ReplyState::Unknown);
    book.Arm(1, "a", 0);
    EXPECT_FALSE(book.Accept(2, Chunk("a", 1, 1, "x"), 0));
    EXPECT_FALSE(book.Accept(1, Chunk("b", 1, 1, "x"), 0));
}

TEST(ProbeRelay, BookKeepsConcurrentRequestsApart)
{
    ReplyBook book;
    book.Arm(1, "a", 0);
    book.Arm(1, "b", 0);
    book.Arm(2, "a", 0);
    book.Arm(2, "b", 0);
    EXPECT_TRUE(book.Accept(1, Chunk("a", 1, 2, "1a1"), 1));
    EXPECT_TRUE(book.Accept(2, Chunk("b", 1, 2, "2b1"), 1));
    EXPECT_TRUE(book.Accept(2, Chunk("a", 2, 2, "2a2"), 1));
    EXPECT_TRUE(book.Accept(1, Chunk("b", 2, 2, "1b2"), 1));
    EXPECT_TRUE(book.Accept(1, Chunk("b", 1, 2, "1b1"), 1));
    EXPECT_TRUE(book.Accept(2, Chunk("a", 1, 2, "2a1"), 1));
    EXPECT_TRUE(book.Accept(1, Chunk("a", 2, 2, "1a2"), 1));
    EXPECT_TRUE(book.Accept(2, Chunk("b", 2, 2, "2b2"), 1));
    EXPECT_EQ(book.Status(1, "a", 2).body, "1a11a2");
    EXPECT_EQ(book.Status(1, "b", 2).body, "1b11b2");
    EXPECT_EQ(book.Status(2, "a", 2).body, "2a12a2");
    EXPECT_EQ(book.Status(2, "b", 2).body, "2b12b2");
}

TEST(ProbeRelay, BookExpiresStaleReplies)
{
    ReplyBook book;
    book.Arm(1, "a", 0);
    EXPECT_EQ(book.Status(1, "a", ReplyLifetimeMs).state, ReplyState::Pending);
    EXPECT_EQ(book.Status(1, "a", ReplyLifetimeMs + 1).state, ReplyState::Unknown);
}

TEST(ProbeRelay, BookExpiryIsWrapSafe)
{
    ReplyBook book;
    uint32 const nearWrap = 0xFFFFFFFFu - 10;
    book.Arm(1, "a", nearWrap);
    EXPECT_EQ(book.Status(1, "a", 100).state, ReplyState::Pending);
}

TEST(ProbeRelay, BookRejectsChangedTotal)
{
    ReplyBook book;
    book.Arm(1, "a", 0);
    EXPECT_TRUE(book.Accept(1, Chunk("a", 1, 2, "x"), 0));
    EXPECT_FALSE(book.Accept(1, Chunk("a", 2, 3, "y"), 0));
    ReplyStatus status = book.Status(1, "a", 0);
    EXPECT_EQ(status.state, ReplyState::Pending);
    EXPECT_EQ(status.total, 2u);
}

TEST(ProbeRelay, BookIgnoresDuplicateChunks)
{
    ReplyBook book;
    book.Arm(1, "a", 0);
    EXPECT_TRUE(book.Accept(1, Chunk("a", 1, 2, "x"), 0));
    EXPECT_FALSE(book.Accept(1, Chunk("a", 1, 2, "z"), 0));
    ReplyStatus status = book.Status(1, "a", 0);
    EXPECT_EQ(status.state, ReplyState::Pending);
    EXPECT_EQ(status.received, 1u);
}

TEST(ProbeRelay, BookDropsOldestBeyondSixteen)
{
    ReplyBook book;
    for (uint32 i = 0; i < MaxPendingPerPlayer; ++i)
        book.Arm(1, "r" + std::to_string(i), i);
    book.Arm(2, "other", MaxPendingPerPlayer);
    book.Arm(1, "newest", 100);
    EXPECT_EQ(book.Status(1, "r0", 101).state, ReplyState::Unknown);
    EXPECT_EQ(book.Status(1, "r1", 101).state, ReplyState::Pending);
    EXPECT_EQ(book.Status(1, "newest", 101).state, ReplyState::Pending);
    EXPECT_EQ(book.Status(2, "other", 101).state, ReplyState::Pending);
}

TEST(ProbeRelay, BookForgetsAPlayer)
{
    ReplyBook book;
    book.Arm(1, "a", 0);
    book.Arm(2, "a", 0);
    book.Forget(1);
    EXPECT_EQ(book.Status(1, "a", 0).state, ReplyState::Unknown);
    EXPECT_EQ(book.Status(2, "a", 0).state, ReplyState::Pending);
}

TEST(ProbeRelay, LabAccountPrefixIsCaseInsensitive)
{
    EXPECT_TRUE(IsLabAccount("coalab1", "COALAB"));
    EXPECT_TRUE(IsLabAccount("COALAB", "COALAB"));
    EXPECT_TRUE(IsLabAccount("COALAB1", "coalab"));
    EXPECT_FALSE(IsLabAccount("PLAYER", "COALAB"));
    EXPECT_FALSE(IsLabAccount("COA", "COALAB"));
    EXPECT_FALSE(IsLabAccount("COALAB1", ""));
}

TEST(ProbeRelay, ReadOnlyCommandsAreExactNames)
{
    for (std::string_view command : {"ping", "spell", "item", "auras", "spellbook", "known", "log", "state", "ca",
             "frame", "errors"})
        EXPECT_TRUE(IsReadOnlyCommand(command)) << command;
    for (std::string_view command : {"eval", "pksend", "pkwatch", "Ping", "pings", ""})
        EXPECT_FALSE(IsReadOnlyCommand(command)) << command;
}
