#include "Packets.h"
#include "CreatureData.h"
#include "GameTime.h"
#include "Opcodes.h"
#include "Player.h"
#include "SpellAuraDefines.h"
#include "SpellDefines.h"
#include "Unit.h"
#include "WorldPacket.h"
#include "WorldSession.h"

namespace CoAPetBattles::Present
{
    namespace
    {
        constexpr uint8_t VisualAuraSlot = 63;
        constexpr uint32_t CastPending = 0x00000001;
        constexpr uint32_t CastTrajectory = 0x00000002;
        constexpr uint32_t CastGo = 0x00000100;
        constexpr uint32_t CastNoCooldown = 0x00040000;
        constexpr uint32_t TargetUnit = 0x00000002;
        constexpr uint8_t AuraEffect0 = 0x01;
        constexpr uint8_t AuraCaster = 0x08;
        constexpr uint8_t AuraPositive = 0x10;
    }

    void SendVisualCast(Unit* caster, Unit* target, uint32_t spell)
    {
        if (!caster || !target || !spell)
            return;
        WorldPacket start(SMSG_SPELL_START, 8 + 8 + 4 + 4 + 4 + 4 + 8);
        start << caster->GetPackGUID();
        start << caster->GetPackGUID();
        start << uint8(0);
        start << uint32(spell);
        start << uint32(CastPending | CastTrajectory);
        start << int32(0);
        start << uint32(TargetUnit);
        start << target->GetPackGUID();
        caster->SendMessageToSet(&start, true);

        WorldPacket go(SMSG_SPELL_GO, 8 + 8 + 4 + 4 + 4 + 1 + 8 + 1 + 4 + 8);
        go << caster->GetPackGUID();
        go << caster->GetPackGUID();
        go << uint8(0);
        go << uint32(spell);
        go << uint32(CastPending | CastGo | CastNoCooldown);
        go << uint32(GameTime::GetGameTimeMS().count());
        go << uint8(1);
        go << target->GetGUID();
        go << uint8(0);
        go << uint32(TargetUnit);
        go << target->GetPackGUID();
        caster->SendMessageToSet(&go, true);
    }

    void SendVisualAura(Unit* target, uint32_t spell, bool on)
    {
        if (!target || !spell)
            return;
        WorldPacket data(SMSG_AURA_UPDATE, 8 + 1 + 4 + 3);
        data << target->GetPackGUID();
        data << uint8(VisualAuraSlot);
        if (!on)
            data << uint32(0);
        else
        {
            data << uint32(spell);
            data << uint8(AuraEffect0 | AuraCaster | AuraPositive);
            data << uint8(target->GetLevel());
            data << uint8(0);
        }
        target->SendMessageToSet(&data, true);
    }

    void SendCreatureRecord(Player* player, CreatureTemplate const& creature, uint32_t entry, uint32_t display)
    {
        if (!player || !player->GetSession())
            return;
        WorldPacket data(SMSG_CREATURE_QUERY_RESPONSE, 160);
        data << uint32(entry);
        data << creature.Name;
        data << uint8(0) << uint8(0) << uint8(0);
        data << creature.SubName;
        data << creature.IconName;
        data << uint32(creature.type_flags);
        data << uint32(creature.type);
        data << uint32(creature.family);
        data << uint32(creature.rank);
        data << uint32(creature.KillCredit[0]);
        data << uint32(creature.KillCredit[1]);
        for (uint32_t index = 0; index < 4; ++index)
        {
            if (display)
                data << uint32(index == 0 ? display : 0);
            else
            {
                CreatureModel const* model = creature.GetModelByIdx(index);
                data << uint32(model ? model->CreatureDisplayID : 0);
            }
        }
        data << float(creature.ModHealth);
        data << float(creature.ModMana);
        data << uint8(creature.RacialLeader);
        data << uint32(creature.movementId);
        player->GetSession()->SendPacket(&data);
    }
}
