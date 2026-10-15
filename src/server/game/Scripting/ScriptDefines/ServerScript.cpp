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

#include "IoContext.h"
#include "Log.h"
#include "Opcodes.h"
#include "ScriptMgr.h"
#include "ScriptMgrMacros.h"
#include "ServerScript.h"
#include "WorldPacket.h"
#include "WorldSession.h"

void ScriptMgr::OnNetworkStart(Acore::Asio::IoContext& ioContext)
{
    CALL_ENABLED_HOOKS(ServerScript, SERVERHOOK_ON_NETWORK_START, script->OnNetworkStart(ioContext));
}

void ScriptMgr::OnNetworkStop()
{
    CALL_ENABLED_HOOKS(ServerScript, SERVERHOOK_ON_NETWORK_STOP, script->OnNetworkStop());
}

void ScriptMgr::OnSocketOpen(std::shared_ptr<WorldSocket> const& socket)
{
    ASSERT(socket);

    CALL_ENABLED_HOOKS(ServerScript, SERVERHOOK_ON_SOCKET_OPEN, script->OnSocketOpen(socket));
}

void ScriptMgr::OnSocketClose(std::shared_ptr<WorldSocket> const& socket)
{
    ASSERT(socket);

    CALL_ENABLED_HOOKS(ServerScript, SERVERHOOK_ON_SOCKET_CLOSE, script->OnSocketClose(socket));
}

void ScriptMgr::OnPacketReceived(WorldSession* session, WorldPacket const& packet)
{
    WorldPacket copy(packet);
    ExecuteScript<ServerScript>([&](ServerScript* script)
    {
        script->OnPacketReceived(session, copy);
    });
}

bool ScriptMgr::CanPacketSend(WorldSession* session, WorldPacket const& packet)
{
    ASSERT(session);

    if (ScriptRegistry<ServerScript>::ScriptPointerList.empty())
        return true;

    CALL_ENABLED_BOOLEAN_HOOKS(ServerScript, SERVERHOOK_CAN_PACKET_SEND, !script->CanPacketSend(session, packet));
}

bool ScriptMgr::CanPacketReceive(WorldSession* session, WorldPacket const& packet)
{
    if (ScriptRegistry<ServerScript>::ScriptPointerList.empty())
        return true;

    CALL_ENABLED_BOOLEAN_HOOKS(ServerScript, SERVERHOOK_CAN_PACKET_RECEIVE, !script->CanPacketReceive(session, packet));
}

bool ScriptMgr::CanPacketReceiveEarly(WorldSession* session, WorldPacket const& packet)
{
    ASSERT(session);

    if (ScriptRegistry<ServerScript>::ScriptPointerList.empty())
        return true;

    // Runs on the socket thread, where an escaping exception terminates the worldserver.
    try
    {
        CALL_ENABLED_BOOLEAN_HOOKS(ServerScript, SERVERHOOK_CAN_PACKET_RECEIVE_EARLY,
            !script->CanPacketReceiveEarly(session, packet));
    }
    catch (ByteBufferException const&)
    {
        LOG_ERROR("network", "Dropped malformed {} ({} bytes) from account {}",
            GetOpcodeNameForLogging(static_cast<Opcodes>(packet.GetOpcode())), packet.size(),
            session->GetAccountId());
        return false;
    }
}

ServerScript::ServerScript(char const* name, std::vector<uint16> enabledHooks)
    : ScriptObject(name, SERVERHOOK_END)
{
    // If empty - enable all available hooks.
    if (enabledHooks.empty())
        for (uint16 i = 0; i < SERVERHOOK_END; ++i)
            enabledHooks.emplace_back(i);

    ScriptRegistry<ServerScript>::AddScript(this, std::move(enabledHooks));
}

template class AC_GAME_API ScriptRegistry<ServerScript>;
