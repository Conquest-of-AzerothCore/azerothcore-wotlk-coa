#include "ManastormPotionClient.h"

#include "ClientDBC.h"
#include "Log.h"
#include "ManastormDefines.h"
#include "ManastormModuleConfig.h"
#include "Player.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <algorithm>
#include <filesystem>
#include <string>

namespace
{
    constexpr uint32 CHARGE_SYSTEM_SPELL = 992090;
    // Verified native handlers: 0x0570 -> two DWORDs; 0x0571 -> three DWORDs.
    constexpr uint16 PATCH_CHARGE_LINK = 0x0570;
    constexpr uint16 PATCH_CHARGE_CATEGORY = 0x0571;
    constexpr uint16 SET_SPELL_CHARGES = 0x09C5;
    uint32 categoryId = 0;
    uint32 originalPotionCategory = 0;
    uint32 originalRecoveryMs = 0;
    bool ready = false;

    bool CanSend(Player const* player)
    {
        return ready && ManastormModuleConfig::IsNativeClientMode() && player &&
            player->GetSession() && !player->GetSession()->IsBot();
    }

    void SendDefinitions(Player const* player, uint32 potionCategory, uint32 recoveryMs)
    {
        WorldPacket category(PATCH_CHARGE_CATEGORY, 12);
        category << categoryId << uint32(ManastormBaseline::PotionMaxCharges) << recoveryMs;
        player->SendDirectMessage(&category);

        WorldPacket link(PATCH_CHARGE_LINK, 8);
        link << uint32(ManastormBaseline::SpellPotion) << potionCategory;
        player->SendDirectMessage(&link);
    }

    void SendState(Player const* player, uint32 missing, uint32 remainingMs)
    {
        WorldPacket packet(SET_SPELL_CHARGES, 12);
        packet << categoryId << remainingMs << missing;
        player->SendDirectMessage(&packet);
    }
}

void ManastormPotionClient::Load()
{
    if (ready || !ManastormModuleConfig::Enabled() || !ManastormModuleConfig::IsNativeClientMode())
        return;

    ClientDBC links;
    ClientDBC categories;
    std::filesystem::path const directory = std::filesystem::path(sWorld->GetDataPath()) / "dbc";
    if (!links.Load((directory / "SpellCharges.dbc").string(), 2) ||
        !categories.Load((directory / "SpellChargesCategory.dbc").string(), 3))
        return;

    for (uint32 index = 0; index < links.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = links.GetRecord(index);
        if (record.GetUInt32(0) == CHARGE_SYSTEM_SPELL)
            categoryId = record.GetUInt32(1);
        else if (record.GetUInt32(0) == ManastormBaseline::SpellPotion)
            originalPotionCategory = record.GetUInt32(1);
    }

    if (!categoryId || (originalPotionCategory && originalPotionCategory != categoryId))
    {
        LOG_ERROR("module.manastorm.endless", "Potion display disabled: incompatible native charge links.");
        return;
    }

    // Never change a recharge category shared with another ability.
    for (uint32 index = 0; index < links.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = links.GetRecord(index);
        uint32 const spell = record.GetUInt32(0);
        if (record.GetUInt32(1) == categoryId && spell != CHARGE_SYSTEM_SPELL &&
            spell != ManastormBaseline::SpellPotion)
        {
            LOG_ERROR("module.manastorm.endless", "Potion display disabled: category {} also belongs to spell {}.",
                categoryId, spell);
            return;
        }
    }

    for (uint32 index = 0; index < categories.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = categories.GetRecord(index);
        if (record.GetUInt32(0) != categoryId)
            continue;

        if (record.GetUInt32(1) != ManastormBaseline::PotionMaxCharges ||
            !record.GetUInt32(2) || record.GetUInt32(2) > 86400000)
        {
            LOG_ERROR("module.manastorm.endless", "Potion display disabled: incompatible native charge category.");
            return;
        }

        originalRecoveryMs = record.GetUInt32(2);
        ready = true;
        return;
    }

    LOG_ERROR("module.manastorm.endless", "Potion display disabled: native charge category {} is absent.", categoryId);
}

void ManastormPotionClient::Send(Player const* player, uint8 charges, uint32 remainingMs)
{
    if (!CanSend(player))
        return;

    // Patch only the session's native display records. Do not activate the core's separate charge pool.
    SendDefinitions(player, categoryId, ManastormBaseline::PotionRechargeMs);
    uint32 const missing = ManastormBaseline::PotionMaxCharges -
        std::min<uint32>(charges, ManastormBaseline::PotionMaxCharges);
    SendState(player, missing, missing ? std::max<uint32>(remainingMs, 1) : ManastormBaseline::PotionRechargeMs);
}

void ManastormPotionClient::Reset(Player const* player)
{
    if (!CanSend(player))
        return;

    SendState(player, 0, originalRecoveryMs);
    // Category zero restores "no charge category" when the baseline spell had no shipped link.
    SendDefinitions(player, originalPotionCategory, originalRecoveryMs);
}
