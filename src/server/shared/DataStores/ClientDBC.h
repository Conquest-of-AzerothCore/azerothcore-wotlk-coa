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

#ifndef CLIENT_DBC_H
#define CLIENT_DBC_H

#include "Define.h"
#include "Errors.h"
#include "Utilities/ByteConverter.h"
#include <cstring>
#include <string>
#include <string_view>
#include <vector>

/// Read access to a client DBC the core keeps no store for.
/// Custom client tables do not follow the core's field formats: a header's field count can disagree with its
/// record size, and byte fields sit between DWORD fields. Records are therefore read by DWORD index or byte
/// offset, and the caller names the positions it uses.
class ClientDBC
{
public:
    class Record
    {
    public:
        [[nodiscard]] uint32 GetUInt32(uint32 dword) const { return Read<uint32>(dword * sizeof(uint32)); }
        [[nodiscard]] int32 GetInt32(uint32 dword) const { return Read<int32>(dword * sizeof(uint32)); }
        [[nodiscard]] float GetFloat(uint32 dword) const { return Read<float>(dword * sizeof(uint32)); }
        [[nodiscard]] uint8 GetUInt8(uint32 byteOffset) const { return Read<uint8>(byteOffset); }
        [[nodiscard]] uint32 GetUInt32At(uint32 byteOffset) const { return Read<uint32>(byteOffset); }
        /// Empty when the offset points outside the string block.
        [[nodiscard]] std::string_view GetString(uint32 dword) const { return GetStringAt(dword * sizeof(uint32)); }
        [[nodiscard]] std::string_view GetStringAt(uint32 byteOffset) const;

    private:
        friend class ClientDBC;
        Record(ClientDBC const& file, uint8 const* data) : _file(file), _data(data) { }

        template<class T>
        [[nodiscard]] T Read(uint32 offset) const
        {
            ASSERT(offset + sizeof(T) <= _file._recordSize, "Client DBC read at byte {} of a {} byte record",
                offset, _file._recordSize);
            T value;
            std::memcpy(&value, _data + offset, sizeof(T));
            EndianConvert(value);
            return value;
        }

        ClientDBC const& _file;
        uint8 const* _data;
    };

    /// Reads a WDBC file whose records hold at least `minimumDWords` DWORDs. Logs and returns false otherwise.
    bool Load(std::string const& path, uint32 minimumDWords);

    [[nodiscard]] uint32 GetRecordCount() const { return _recordCount; }
    [[nodiscard]] uint32 GetRecordSize() const { return _recordSize; }
    [[nodiscard]] Record GetRecord(uint32 row) const;

private:
    std::vector<uint8> _data;
    uint32 _recordCount = 0;
    uint32 _recordSize = 0;
    uint32 _stringSize = 0;
};

#endif
