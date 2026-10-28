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

#ifndef __RASESSION_H__
#define __RASESSION_H__

#include "Socket.h"
#include <boost/asio/streambuf.hpp>
#include <boost/asio/steady_timer.hpp>
#include <functional>

const std::size_t bufferSize = 4096;

class RASession : public std::enable_shared_from_this<RASession>
{
public:
    RASession(IoContextTcpSocket&& socket) :
        _socket(std::move(socket)), _negotiationTimer(_socket.get_executor()), _readBuffer(131072) { }

    void Start();

    const std::string GetRemoteIpAddress() const { return _socket.remote_endpoint().address().to_string(); }
    unsigned short GetRemotePort() const { return _socket.remote_endpoint().port(); }

private:
    struct CommandState
    {
        std::weak_ptr<RASession> session;
        std::string output;
    };

    void Send(std::string data, std::function<void()> next = {});
    void ReadString(std::function<void(std::string)> next);
    void ReadUsername();
    void ReadCommand();
    void Close();
    bool CheckAccessLevel(std::string const& user);
    bool CheckPassword(std::string const& user, std::string const& pass);
    void ProcessCommand(std::string command);

    static void CommandPrint(void* callbackArg, std::string_view text);
    static void CommandFinished(void* callbackArg, bool);

    IoContextTcpSocket _socket;
    boost::asio::steady_timer _negotiationTimer;
    boost::asio::streambuf _readBuffer;
    std::string _username;
};

#endif
