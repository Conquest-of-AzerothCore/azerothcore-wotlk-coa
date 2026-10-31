/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "WorldBaseline.h"
#include "CryptoHash.h"
#include "DBUpdater.h"
#include "StringFormat.h"
#include "Util.h"
#include <algorithm>
#include <array>
#include <boost/bind/placeholders.hpp>
#include <boost/property_tree/json_parser.hpp>
#include <boost/property_tree/ptree.hpp>
#include <fstream>
#include <map>
#include <set>
#include <zlib.h>

namespace
{
    constexpr uint32 EndOfCentralDirectorySignature = 0x06054b50;
    constexpr uint32 CentralDirectorySignature = 0x02014b50;
    constexpr uint32 LocalHeaderSignature = 0x04034b50;
    constexpr uint32 Zip64Marker = 0xFFFFFFFF;
    constexpr uint16 StoredMethod = 0;
    constexpr uint16 DeflateMethod = 8;
    constexpr std::size_t ChunkSize = 1 << 18;

    struct Member
    {
        uint16 method = 0;
        uint32 compressedSize = 0;
        uint32 size = 0;
        uint32 localHeaderOffset = 0;
    };

    [[noreturn]] void Fail(std::string const& message)
    {
        throw UpdateException("World baseline: " + message);
    }

    uint16 ReadUInt16(uint8 const* data)
    {
        return uint16(data[0] | (data[1] << 8));
    }

    uint32 ReadUInt32(uint8 const* data)
    {
        return uint32(data[0]) | (uint32(data[1]) << 8) | (uint32(data[2]) << 16) | (uint32(data[3]) << 24);
    }

    void ReadAt(std::ifstream& stream, uint64 offset, uint8* buffer, std::size_t length)
    {
        stream.clear();
        stream.seekg(std::streamoff(offset));
        if (!stream.read(reinterpret_cast<char*>(buffer), std::streamsize(length)))
            Fail("archive is truncated");
    }

    bool IsTableName(std::string const& name)
    {
        return !name.empty() && std::all_of(name.begin(), name.end(), [](char c)
        {
            return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
        });
    }

    std::string Lowercase(std::string value)
    {
        std::transform(value.begin(), value.end(), value.begin(),
            [](unsigned char c) { return char(std::tolower(c)); });
        return value;
    }

    std::string FileSha256(std::filesystem::path const& path)
    {
        std::ifstream stream(path, std::ios::binary);
        if (!stream)
            Fail(Acore::StringFormat("cannot open archive \"{}\"", path.generic_string()));

        Acore::Crypto::SHA256 hash;
        std::vector<char> buffer(ChunkSize);
        while (stream.read(buffer.data(), std::streamsize(buffer.size())) || stream.gcount() > 0)
            hash.UpdateData(reinterpret_cast<uint8 const*>(buffer.data()), std::size_t(stream.gcount()));
        hash.Finalize();
        return Lowercase(ByteArrayToHexStr(hash.GetDigest()));
    }

    std::map<std::string, Member> ReadCentralDirectory(std::ifstream& stream)
    {
        stream.seekg(0, std::ios::end);
        uint64 const archiveSize = uint64(stream.tellg());
        std::size_t const tailSize = std::size_t(std::min<uint64>(archiveSize, 22 + 0xFFFF));
        std::vector<uint8> tail(tailSize);
        ReadAt(stream, archiveSize - tailSize, tail.data(), tailSize);

        std::size_t end = tailSize;
        for (std::size_t i = tailSize >= 22 ? tailSize - 22 + 1 : 0; i-- > 0;)
        {
            if (ReadUInt32(&tail[i]) == EndOfCentralDirectorySignature)
            {
                end = i;
                break;
            }
        }

        if (end == tailSize)
            Fail("archive has no zip directory");

        uint16 const entries = ReadUInt16(&tail[end + 10]);
        uint32 const directorySize = ReadUInt32(&tail[end + 12]);
        uint32 const directoryOffset = ReadUInt32(&tail[end + 16]);
        if (entries == 0xFFFF || directoryOffset == Zip64Marker
            || uint64(directoryOffset) + directorySize > archiveSize)
            Fail("archive directory is unsupported or damaged");

        std::vector<uint8> directory(directorySize);
        ReadAt(stream, directoryOffset, directory.data(), directorySize);

        std::map<std::string, Member> members;
        std::size_t position = 0;
        for (uint16 index = 0; index < entries; ++index)
        {
            if (position + 46 > directory.size() || ReadUInt32(&directory[position]) != CentralDirectorySignature)
                Fail("archive directory is damaged");

            uint8 const* header = &directory[position];
            uint16 const flags = ReadUInt16(header + 8);
            Member member;
            member.method = ReadUInt16(header + 10);
            member.compressedSize = ReadUInt32(header + 20);
            member.size = ReadUInt32(header + 24);
            member.localHeaderOffset = ReadUInt32(header + 42);
            uint16 const nameLength = ReadUInt16(header + 28);
            std::size_t const next = position + 46 + nameLength + ReadUInt16(header + 30) + ReadUInt16(header + 32);
            if (next > directory.size())
                Fail("archive directory is damaged");

            std::string const name(reinterpret_cast<char const*>(header + 46), nameLength);
            if ((flags & 1) || member.compressedSize == Zip64Marker || member.size == Zip64Marker
                || member.localHeaderOffset == Zip64Marker
                || (member.method != StoredMethod && member.method != DeflateMethod))
                Fail(Acore::StringFormat("archive member \"{}\" uses an unsupported zip feature", name));

            if (!members.emplace(name, member).second)
                Fail(Acore::StringFormat("archive member \"{}\" is duplicated", name));

            position = next;
        }

        return members;
    }

    std::string ExtractMember(std::ifstream& archive, std::string const& name, Member const& member,
        std::filesystem::path const& target)
    {
        std::array<uint8, 30> localHeader;
        ReadAt(archive, member.localHeaderOffset, localHeader.data(), localHeader.size());
        if (ReadUInt32(localHeader.data()) != LocalHeaderSignature)
            Fail(Acore::StringFormat("archive member \"{}\" is damaged", name));

        archive.clear();
        archive.seekg(std::streamoff(uint64(member.localHeaderOffset) + localHeader.size()
            + ReadUInt16(&localHeader[26]) + ReadUInt16(&localHeader[28])));

        std::ofstream output(target, std::ios::binary | std::ios::trunc);
        if (!output)
            Fail(Acore::StringFormat("cannot write \"{}\"", target.generic_string()));

        Acore::Crypto::SHA256 hash;
        uint64 written = 0;
        auto const emit = [&](uint8 const* data, std::size_t length)
        {
            hash.UpdateData(data, length);
            output.write(reinterpret_cast<char const*>(data), std::streamsize(length));
            written += length;
        };

        std::vector<uint8> input(ChunkSize);
        std::vector<uint8> inflated(ChunkSize);
        uint64 remaining = member.compressedSize;
        auto const readChunk = [&]() -> std::size_t
        {
            std::size_t const length = std::size_t(std::min<uint64>(remaining, input.size()));
            if (!archive.read(reinterpret_cast<char*>(input.data()), std::streamsize(length)))
                Fail(Acore::StringFormat("archive member \"{}\" is truncated", name));
            remaining -= length;
            return length;
        };

        if (member.method == StoredMethod)
        {
            while (remaining > 0)
            {
                std::size_t const length = readChunk();
                emit(input.data(), length);
            }
        }
        else
        {
            z_stream inflater{};
            if (inflateInit2(&inflater, -MAX_WBITS) != Z_OK)
                Fail("cannot initialize zlib");

            int status = Z_OK;
            while (status != Z_STREAM_END)
            {
                if (inflater.avail_in == 0 && remaining > 0)
                {
                    inflater.avail_in = uInt(readChunk());
                    inflater.next_in = input.data();
                }

                inflater.avail_out = uInt(inflated.size());
                inflater.next_out = inflated.data();
                status = inflate(&inflater, Z_NO_FLUSH);
                if (status != Z_OK && status != Z_STREAM_END)
                    break;

                emit(inflated.data(), inflated.size() - inflater.avail_out);
            }

            inflateEnd(&inflater);
            if (status != Z_STREAM_END)
                Fail(Acore::StringFormat("archive member \"{}\" cannot be decompressed", name));
        }

        output.close();
        if (!output || written != member.size)
            Fail(Acore::StringFormat("archive member \"{}\" has the wrong size", name));

        hash.Finalize();
        return Lowercase(ByteArrayToHexStr(hash.GetDigest()));
    }
}

std::vector<std::filesystem::path> WorldBaseline::Extract(std::filesystem::path const& manifest,
    std::filesystem::path const& directory)
{
    boost::property_tree::ptree tree;
    try
    {
        boost::property_tree::read_json(manifest.string(), tree);
    }
    catch (boost::property_tree::json_parser_error const& error)
    {
        Fail(Acore::StringFormat("cannot read \"{}\": {}", manifest.generic_string(), error.what()));
    }

    std::string const archiveName = tree.get<std::string>("archive", "");
    if (tree.get<int>("format", 0) != 1 || archiveName.empty()
        || std::filesystem::path(archiveName).filename().string() != archiveName)
        Fail(Acore::StringFormat("\"{}\" is not a supported baseline manifest", manifest.generic_string()));

    std::filesystem::path const archivePath = manifest.parent_path() / archiveName;
    if (FileSha256(archivePath) != Lowercase(tree.get<std::string>("sha256", "")))
        Fail(Acore::StringFormat("checksum mismatch for \"{}\"", archivePath.generic_string()));

    std::ifstream archive(archivePath, std::ios::binary);
    std::map<std::string, Member> const members = ReadCentralDirectory(archive);

    std::set<std::string> metadata;
    if (auto const metadataTables = tree.get_child_optional("metadataTables"))
        for (auto const& [key, value] : *metadataTables)
            metadata.insert(value.get_value<std::string>());

    std::vector<std::pair<std::string, std::string>> tables;
    if (auto const tableTree = tree.get_child_optional("tables"))
        for (auto const& [table, contract] : *tableTree)
            tables.emplace_back(table, Lowercase(contract.get<std::string>("sqlSha256", "")));

    if (tables.empty() || tables.size() != members.size())
        Fail("archive members do not match the manifest tables");

    std::sort(tables.begin(), tables.end(), [&metadata](auto const& left, auto const& right)
    {
        bool const leftMetadata = metadata.contains(left.first);
        bool const rightMetadata = metadata.contains(right.first);
        return leftMetadata != rightMetadata ? rightMetadata : left.first < right.first;
    });

    std::filesystem::create_directories(directory);
    std::vector<std::filesystem::path> files;
    for (auto const& [table, sqlSha256] : tables)
    {
        auto const member = members.find(table + ".sql");
        if (!IsTableName(table) || member == members.end())
            Fail(Acore::StringFormat("manifest table \"{}\" has no archive member", table));

        std::filesystem::path const target = directory / (table + ".sql");
        if (ExtractMember(archive, member->first, member->second, target) != sqlSha256)
            Fail(Acore::StringFormat("checksum mismatch for table \"{}\"", table));

        files.push_back(target);
    }

    return files;
}
