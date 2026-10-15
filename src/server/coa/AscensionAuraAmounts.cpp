/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionAuraAmounts.h"
#include "Player.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "WorldPacket.h"

namespace
{
constexpr uint16 SMSG_ASCENSION_AURA_AMOUNT = 0x0673;
constexpr uint32 SPELL_BARBARIAN_DRUNKEN_FRENZY = 804771;
constexpr uint32 SPELL_BARBARIAN_TANKARD = 805813;

void AppendAuraAmounts(WorldPacket& data, AuraApplication const& application, bool remove)
{
    Aura const* aura = application.GetBase();
    data << int32(remove ? -1 : application.GetSlot());
    data << aura->GetCasterGUID() << uint32(aura->GetId());
    if (remove)
        return;

    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
    {
        uint8 sourceIndex = aura->GetId() == SPELL_BARBARIAN_DRUNKEN_FRENZY && index == 1 ? 0 : index;
        AuraEffect const* effect = aura->GetEffect(sourceIndex);
        int32 amount = effect && application.HasEffect(sourceIndex) && application.IsActive(sourceIndex)
            ? effect->GetAmount() : 0;
        if (aura->GetId() == SPELL_BARBARIAN_TANKARD && index == 0 && amount && aura->GetSpellInfo()->StackAmount)
            amount = 100 * aura->GetStackAmount() / aura->GetSpellInfo()->StackAmount;
        data << amount;
    }
}
}

void SendAscensionAuraAmounts(Unit* target, Player* receiver,
    AuraApplication const* application, bool remove)
{
    if (!target || (application && application->GetSlot() >= MAX_AURAS))
        return;

    if (!application)
    {
        for (auto const& [slot, visible] : *target->GetVisibleAuras())
        {
            (void)slot;
            SendAscensionAuraAmounts(target, receiver, visible, false);
        }
        return;
    }

    if (application && remove)
        for (auto const& [slot, visible] : *target->GetVisibleAuras())
        {
            (void)slot;
            if (visible != application && visible->GetBase()->GetId() == application->GetBase()->GetId() &&
                visible->GetBase()->GetCasterGUID() == application->GetBase()->GetCasterGUID())
            {
                application = visible;
                remove = false;
                break;
            }
        }

    WorldPacket data(SMSG_ASCENSION_AURA_AMOUNT);
    data << target->GetGUID();
    AppendAuraAmounts(data, *application, remove);

    if (receiver)
        receiver->SendDirectMessage(&data);
    else
        target->SendMessageToSet(&data, true);
}
