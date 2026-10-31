/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "WorldBaseline.h"
#include "CryptoHash.h"
#include "DBUpdater.h"
#include "Util.h"
#include "gtest/gtest.h"
#include <algorithm>
#include <fstream>
#include <map>
#include <sstream>
#include <zlib.h>

namespace
{
    struct ArchiveMember
    {
        std::string name;
        std::string content;
        bool deflate = false;
    };

    void PutUInt16(std::string& out, uint32 value)
    {
        out.push_back(char(value & 0xFF));
        out.push_back(char((value >> 8) & 0xFF));
    }

    void PutUInt32(std::string& out, uint32 value)
    {
        PutUInt16(out, value & 0xFFFF);
        PutUInt16(out, value >> 16);
    }

    std::string RawDeflate(std::string const& content)
    {
        z_stream deflater{};
        deflateInit2(&deflater, Z_BEST_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 8, Z_DEFAULT_STRATEGY);
        std::string out(deflateBound(&deflater, uLong(content.size())), '\0');
        deflater.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(content.data()));
        deflater.avail_in = uInt(content.size());
        deflater.next_out = reinterpret_cast<Bytef*>(out.data());
        deflater.avail_out = uInt(out.size());
        deflate(&deflater, Z_FINISH);
        out.resize(deflater.total_out);
        deflateEnd(&deflater);
        return out;
    }

    std::string Zip(std::vector<ArchiveMember> const& members)
    {
        std::string body;
        std::string directory;
        for (ArchiveMember const& member : members)
        {
            std::string const data = member.deflate ? RawDeflate(member.content) : member.content;
            uint32 const crc = uint32(crc32(0, reinterpret_cast<Bytef const*>(member.content.data()),
                uInt(member.content.size())));
            uint32 const offset = uint32(body.size());
            uint16 const method = member.deflate ? 8 : 0;

            PutUInt32(body, 0x04034b50);
            PutUInt16(body, 20);
            PutUInt16(body, 0);
            PutUInt16(body, method);
            PutUInt32(body, 0);
            PutUInt32(body, crc);
            PutUInt32(body, uint32(data.size()));
            PutUInt32(body, uint32(member.content.size()));
            PutUInt16(body, uint32(member.name.size()));
            PutUInt16(body, 0);
            body += member.name + data;

            PutUInt32(directory, 0x02014b50);
            PutUInt16(directory, 20);
            PutUInt16(directory, 20);
            PutUInt16(directory, 0);
            PutUInt16(directory, method);
            PutUInt32(directory, 0);
            PutUInt32(directory, crc);
            PutUInt32(directory, uint32(data.size()));
            PutUInt32(directory, uint32(member.content.size()));
            PutUInt16(directory, uint32(member.name.size()));
            PutUInt16(directory, 0);
            PutUInt16(directory, 0);
            PutUInt16(directory, 0);
            PutUInt16(directory, 0);
            PutUInt32(directory, 0);
            PutUInt32(directory, offset);
            directory += member.name;
        }

        std::string archive = body + directory;
        PutUInt32(archive, 0x06054b50);
        PutUInt16(archive, 0);
        PutUInt16(archive, 0);
        PutUInt16(archive, uint32(members.size()));
        PutUInt16(archive, uint32(members.size()));
        PutUInt32(archive, uint32(directory.size()));
        PutUInt32(archive, uint32(body.size()));
        PutUInt16(archive, 0);
        return archive;
    }

    std::string Sha256(std::string const& content)
    {
        return ByteArrayToHexStr(Acore::Crypto::SHA256::GetDigestOf(content));
    }

    std::string ReadFile(std::filesystem::path const& path)
    {
        std::ifstream stream(path, std::ios::binary);
        std::ostringstream content;
        content << stream.rdbuf();
        return content.str();
    }

    class WorldBaselineTest : public ::testing::Test
    {
    protected:
        void SetUp() override
        {
            _root = std::filesystem::temp_directory_path() / ("acore_world_baseline_test_"
                + std::string(::testing::UnitTest::GetInstance()->current_test_info()->name()));
            std::filesystem::remove_all(_root);
            std::filesystem::create_directories(_root);
        }

        void TearDown() override
        {
            std::filesystem::remove_all(_root);
        }

        std::filesystem::path WritePackage(std::vector<ArchiveMember> const& members,
            std::map<std::string, std::string> const& tables, std::string archiveSha256 = {})
        {
            std::string const archive = Zip(members);
            std::ofstream(_root / "world.zip", std::ios::binary) << archive;
            if (archiveSha256.empty())
                archiveSha256 = Sha256(archive);

            std::ostringstream manifest;
            manifest << R"({"format": 1, "archive": "world.zip", "sha256": ")" << archiveSha256
                << R"(", "metadataTables": ["updates", "version"], "tables": {)";
            bool first = true;
            for (auto const& [table, sqlSha256] : tables)
            {
                manifest << (first ? "" : ", ") << '"' << table << R"(": {"sqlSha256": ")" << sqlSha256 << R"("})";
                first = false;
            }
            manifest << "}}";

            std::filesystem::path const path = _root / "baseline.json";
            std::ofstream(path, std::ios::binary) << manifest.str();
            return path;
        }

        std::filesystem::path _root;
    };

    std::string const ItemTemplate = std::string(200000, 'i') + "INSERT INTO `item_template` VALUES (1);\n";
    std::string const Creature = "INSERT INTO `creature` VALUES (2);\n";
    std::string const Updates = "INSERT INTO `updates` VALUES ('2026_09_12_00.sql');\n";
    std::string const Version = "INSERT INTO `version` VALUES ('ACDB');\n";
}

TEST_F(WorldBaselineTest, ExtractsEveryTableWithMetadataLast)
{
    std::filesystem::path const manifest = WritePackage(
        { { "version.sql", Version }, { "updates.sql", Updates, true }, { "item_template.sql", ItemTemplate, true },
          { "creature.sql", Creature } },
        { { "creature", Sha256(Creature) }, { "item_template", Sha256(ItemTemplate) }, { "updates", Sha256(Updates) },
          { "version", Sha256(Version) } });

    std::vector<std::filesystem::path> const files = WorldBaseline::Extract(manifest, _root / "out");

    std::vector<std::string> names;
    for (std::filesystem::path const& file : files)
        names.push_back(file.filename().string());

    EXPECT_EQ(names, (std::vector<std::string>{ "creature.sql", "item_template.sql", "updates.sql", "version.sql" }));
    EXPECT_EQ(ReadFile(files[0]), Creature);
    EXPECT_EQ(ReadFile(files[1]), ItemTemplate);
    EXPECT_EQ(ReadFile(files[2]), Updates);
    EXPECT_EQ(ReadFile(files[3]), Version);
}

TEST_F(WorldBaselineTest, RejectsATableWhoseContentDoesNotMatchTheManifest)
{
    std::filesystem::path const manifest = WritePackage({ { "creature.sql", Creature, true } },
        { { "creature", Sha256(Version) } });

    EXPECT_THROW(WorldBaseline::Extract(manifest, _root / "out"), UpdateException);
}

TEST_F(WorldBaselineTest, RejectsAnArchiveWhoseChecksumDoesNotMatchTheManifest)
{
    std::filesystem::path const manifest = WritePackage({ { "creature.sql", Creature } },
        { { "creature", Sha256(Creature) } }, Sha256("another archive"));

    EXPECT_THROW(WorldBaseline::Extract(manifest, _root / "out"), UpdateException);
}

TEST_F(WorldBaselineTest, RejectsMembersThatDoNotMatchTheManifestTables)
{
    std::filesystem::path const extraMember = WritePackage({ { "creature.sql", Creature }, { "version.sql", Version } },
        { { "creature", Sha256(Creature) } });
    EXPECT_THROW(WorldBaseline::Extract(extraMember, _root / "out"), UpdateException);

    std::filesystem::path const renamedMember = WritePackage({ { "creature_old.sql", Creature } },
        { { "creature", Sha256(Creature) } });
    EXPECT_THROW(WorldBaseline::Extract(renamedMember, _root / "out"), UpdateException);
}
