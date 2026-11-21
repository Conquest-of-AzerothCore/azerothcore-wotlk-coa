#include "Chat.h"
#include "ObjectGuid.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "WorldPacket.h"
#include "WorldSession.h"

namespace
{
constexpr uint32 NPC_WISDOMBALL_QUESTGIVER = 9417001;
constexpr uint32 NPC_WISDOMBALL_CRYSTAL    = 9417042;
constexpr char const* KHADGAR_NAME         = "Khadgar";

constexpr std::size_t SENDER_GUID_POS      = 5;
constexpr std::size_t MIN_MONSTER_CHAT     = 21;

bool IsKhadgarOrb(ObjectGuid guid)
{
    return guid.IsCreature() && (guid.GetEntry() == NPC_WISDOMBALL_QUESTGIVER || guid.GetEntry() == NPC_WISDOMBALL_CRYSTAL);
}

bool IsSpokenLine(uint8 chatType)
{
    return chatType == CHAT_MSG_MONSTER_SAY || chatType == CHAT_MSG_MONSTER_YELL || chatType == CHAT_MSG_MONSTER_WHISPER;
}
}

class wisdomball_khadgar_voice : public ServerScript
{
public:
    wisdomball_khadgar_voice() : ServerScript("wisdomball_khadgar_voice", { SERVERHOOK_CAN_PACKET_SEND }) { }

    bool CanPacketSend(WorldSession* session, WorldPacket const& packet) override
    {
        if (!session || packet.GetOpcode() != SMSG_MESSAGECHAT || packet.size() < MIN_MONSTER_CHAT)
            return true;

        if (!IsSpokenLine(packet.read<uint8>(0)) || !IsKhadgarOrb(ObjectGuid(packet.read<uint64>(SENDER_GUID_POS))))
            return true;

        try
        {
            WorldPacket in(packet);
            in.rpos(0);

            uint8 chatType = 0;
            int32 language = 0;
            ObjectGuid sender;
            uint32 flags = 0;
            uint32 nameLength = 0;
            std::string name;
            in >> chatType >> language >> sender >> flags >> nameLength >> name;
            if (name == KHADGAR_NAME)
                return true;

            ObjectGuid receiver;
            in >> receiver;
            std::string receiverName;
            if (receiver && !receiver.IsPlayer() && !receiver.IsPet())
            {
                uint32 receiverNameLength = 0;
                in >> receiverNameLength >> receiverName;
            }

            uint32 messageLength = 0;
            std::string message;
            uint8 chatTag = 0;
            in >> messageLength >> message >> chatTag;

            WorldPacket out;
            ChatHandler::BuildChatPacket(out, ChatMsg(chatType), Language(language), sender, receiver, message, chatTag,
                                         KHADGAR_NAME, receiverName);
            session->SendPacket(&out);
            return false;
        }
        catch (ByteBufferException const&)
        {
            return true;
        }
    }
};

void AddSC_wisdomball_khadgar_voice()
{
    new wisdomball_khadgar_voice();
}
