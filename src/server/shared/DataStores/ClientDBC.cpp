/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "ClientDBC.h"
#include "Log.h"
#include <fstream>
#include <iterator>

namespace
{
constexpr std::size_t HeaderSize = 20;

uint32 ReadHeaderField(std::vector<uint8> const& data, std::size_t offset)
{
    uint32 value;
    std::memcpy(&value, data.data() + offset, sizeof(value));
    EndianConvert(value);
    return value;
}
}

std::string_view ClientDBC::Record::GetStringAt(uint32 byteOffset) const
{
    uint32 offset = GetUInt32At(byteOffset);
    if (offset >= _file._stringSize)
        return {};

    std::size_t const stringStart = HeaderSize + std::size_t(_file._recordCount) * _file._recordSize;
    std::string_view const strings(reinterpret_cast<char const*>(_file._data.data() + stringStart), _file._stringSize);
    std::size_t const end = strings.find('\0', offset);
    return strings.substr(offset, end == std::string_view::npos ? std::string_view::npos : end - offset);
}

bool ClientDBC::Load(std::string const& path, uint32 minimumDWords)
{
    _data.clear();
    _recordCount = _recordSize = _stringSize = 0;

    std::ifstream file(path, std::ios::binary);
    if (!file)
    {
        LOG_ERROR("dbc", "Unable to open client DBC {}", path);
        return false;
    }

    std::vector<uint8> data((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
    if (data.size() < HeaderSize || std::memcmp(data.data(), "WDBC", 4) != 0)
    {
        LOG_ERROR("dbc", "{} is not a WDBC file", path);
        return false;
    }

    uint32 recordCount = ReadHeaderField(data, 4);
    uint32 recordSize = ReadHeaderField(data, 12);
    uint32 stringSize = ReadHeaderField(data, 16);
    if (HeaderSize + uint64(recordCount) * recordSize + stringSize != data.size())
    {
        LOG_ERROR("dbc", "{}: header does not match the file size", path);
        return false;
    }

    if (recordCount && recordSize < uint64(minimumDWords) * sizeof(uint32))
    {
        LOG_ERROR("dbc", "{}: records are {} bytes, {} DWORDs are required", path, recordSize, minimumDWords);
        return false;
    }

    _data = std::move(data);
    _recordCount = recordCount;
    _recordSize = recordSize;
    _stringSize = stringSize;
    return true;
}

ClientDBC::Record ClientDBC::GetRecord(uint32 row) const
{
    ASSERT(row < _recordCount, "Client DBC row {} of {}", row, _recordCount);
    return Record(*this, _data.data() + HeaderSize + std::size_t(row) * _recordSize);
}
