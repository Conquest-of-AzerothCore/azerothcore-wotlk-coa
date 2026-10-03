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

#include "RASession.h"
#include "AccountMgr.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "Duration.h"
#include "Log.h"
#include "MotdMgr.h"
#include "QueryResult.h"
#include "SRP6.h"
#include "Util.h"
#include "World.h"
#include <boost/asio/buffer.hpp>
#include <boost/asio/read_until.hpp>
#include <boost/asio/post.hpp>
#include <boost/asio/write.hpp>

using boost::asio::ip::tcp;

void RASession::Start()
{
    _negotiationTimer.expires_after(1s);
    _negotiationTimer.async_wait([self = shared_from_this()](boost::system::error_code error)
    {
        if (error)
            return;

        auto const available = self->_socket.available(error);
        if (error)
        {
            self->Close();
            return;
        }

        if (available > 0)
        {
            char buffer[1024];
            self->_socket.read_some(boost::asio::buffer(buffer, std::min<std::size_t>(available, sizeof(buffer))), error);
            if (error)
            {
                self->Close();
                return;
            }
            self->Send(std::string("\xff\xf0", 2), [self]() { self->ReadUsername(); });
        }
        else
            self->ReadUsername();
    });
}

void RASession::ReadUsername()
{
    Send("Authentication Required\r\nUsername: ", [self = shared_from_this()]()
    {
        self->ReadString([self](std::string username)
        {
            self->_username = std::move(username);
            LOG_INFO("commands.ra", "Accepting RA connection from user {} (IP: {})", self->_username, self->GetRemoteIpAddress());
            self->Send("Password: ", [self]()
            {
                self->ReadString([self](std::string password)
                {
                    if (!self->CheckAccessLevel(self->_username) || !self->CheckPassword(self->_username, password))
                    {
                        self->Send("Authentication failed\r\n", [self]() { self->Close(); });
                        return;
                    }
                    LOG_INFO("commands.ra", "User {} (IP: {}) authenticated correctly to RA", self->_username, self->GetRemoteIpAddress());
                    self->Send(std::string(sMotdMgr->GetMotd(DEFAULT_LOCALE)) + "\r\n", [self]() { self->ReadCommand(); });
                });
            });
        });
    });
}

void RASession::ReadCommand()
{
    Send("AC>", [self = shared_from_this()]()
    {
        self->ReadString([self](std::string command) { self->ProcessCommand(std::move(command)); });
    });
}

void RASession::Close()
{
    boost::system::error_code error;
    _socket.close(error);
}

void RASession::Send(std::string data, std::function<void()> next)
{
    auto bytes = std::make_shared<std::string>(std::move(data));
    boost::asio::async_write(_socket, boost::asio::buffer(*bytes),
        [self = shared_from_this(), bytes, next = std::move(next)](boost::system::error_code error, std::size_t)
    {
        if (error)
            self->Close();
        else if (next)
            next();
    });
}

void RASession::ReadString(std::function<void(std::string)> next)
{
    boost::asio::async_read_until(_socket, _readBuffer, "\r\n",
        [self = shared_from_this(), next = std::move(next)](boost::system::error_code error, std::size_t)
    {
        if (error)
        {
            self->Close();
            return;
        }
        std::string line;
        std::istream input(&self->_readBuffer);
        std::getline(input, line);
        if (!line.empty() && line.back() == '\r')
            line.pop_back();
        if (line.empty())
            self->Close();
        else
            next(std::move(line));
    });
}

bool RASession::CheckAccessLevel(std::string const& user)
{
    std::string safeUser = user;

    Utf8ToUpperOnlyLatin(safeUser);

    auto* stmt = LoginDatabase.GetPreparedStatement(LOGIN_SEL_ACCOUNT_ACCESS);
    stmt->SetData(0, safeUser);

    PreparedQueryResult result = LoginDatabase.Query(stmt);
    if (!result)
    {
        LOG_INFO("commands.ra", "User {} does not exist in database", user);
        return false;
    }

    Field* fields = result->Fetch();

    if (fields[1].Get<uint8>() < sConfigMgr->GetOption<int32>("Ra.MinLevel", 3))
    {
        LOG_INFO("commands.ra", "User {} has no privilege to login", user);
        return false;
    }
    else if (fields[2].Get<int32>() != -1)
    {
        LOG_INFO("commands.ra", "User {} has to be assigned on all realms (with RealmID = '-1')", user);
        return false;
    }

    return true;
}

bool RASession::CheckPassword(std::string const& user, std::string const& pass)
{
    std::string safe_user = user;
    std::transform(safe_user.begin(), safe_user.end(), safe_user.begin(), ::toupper);
    Utf8ToUpperOnlyLatin(safe_user);

    std::string safe_pass = pass;
    Utf8ToUpperOnlyLatin(safe_pass);
    std::transform(safe_pass.begin(), safe_pass.end(), safe_pass.begin(), ::toupper);

    auto* stmt = LoginDatabase.GetPreparedStatement(LOGIN_SEL_CHECK_PASSWORD_BY_NAME);

    stmt->SetData(0, safe_user);

    if (PreparedQueryResult result = LoginDatabase.Query(stmt))
    {
        Acore::Crypto::SRP6::Salt salt = (*result)[0].Get<Binary, Acore::Crypto::SRP6::SALT_LENGTH>();
        Acore::Crypto::SRP6::Verifier verifier = (*result)[1].Get<Binary, Acore::Crypto::SRP6::VERIFIER_LENGTH>();

        if (Acore::Crypto::SRP6::CheckLogin(safe_user, safe_pass, salt, verifier))
            return true;
    }

    LOG_INFO("commands.ra", "Wrong password for user: {}", user);
    return false;
}

void RASession::ProcessCommand(std::string command)
{
    LOG_INFO("commands.ra", "Received command: {}", command);
    if (command == "quit" || command == "exit" || command == "logout")
    {
        Send("Bye\r\n", [self = shared_from_this()]() { self->Close(); });
        return;
    }

    auto state = std::make_shared<CommandState>();
    state->session = shared_from_this();
    _negotiationTimer.expires_at(std::chrono::steady_clock::time_point::max());
    _negotiationTimer.async_wait([self = shared_from_this()](boost::system::error_code) { });
    auto* holder = new CliCommandHolder(state.get(), command.c_str(), &RASession::CommandPrint, &RASession::CommandFinished);
    holder->m_callbackLifetime = std::move(state);
    sWorld->QueueCliCommand(holder);
}

void RASession::CommandPrint(void* callbackArg, std::string_view text)
{
    auto* state = static_cast<CommandState*>(callbackArg);
    constexpr std::size_t maxOutput = 1024 * 1024;
    if (state->output.size() < maxOutput)
        state->output.append(text.substr(0, maxOutput - state->output.size()));
}

void RASession::CommandFinished(void* callbackArg, bool /*success*/)
{
    auto* state = static_cast<CommandState*>(callbackArg);
    auto self = state->session.lock();
    if (!self)
        return;
    auto output = std::move(state->output);
    boost::asio::post(self->_socket.get_executor(), [self, output = std::move(output)]() mutable
    {
        self->_negotiationTimer.cancel();
        self->Send(std::move(output), [self]() { self->ReadCommand(); });
    });
}
