#include "ManastormMobilityClient.h"

#include "ClientDBC.h"
#include "DBCStores.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Opcodes.h"
#include "ManastormMgr.h"
#include "ManastormModuleConfig.h"
#include "ManastormRun.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"

#include <array>
#include <chrono>
#include <filesystem>
#include <string>

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless";
    constexpr uint16 PATCH_SPELL_OPCODE = 0x092A;
    constexpr uint32 FIRST_MOBILITY_SPELL = 1300179;
    constexpr uint32 MOBILITY_SPELL_COUNT = 7;
    // Module-owned runtime records, absent from the supplied client DBC. Never overwrite an existing spell.
    constexpr uint32 FIRST_SUPPORT_SPELL = 1300400;
    constexpr uint32 CLIENT_FAMILY_WORD = 144;
    constexpr std::array<uint32, 36> FAMILIES = {
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38
    };
    constexpr std::array<uint32, 4> STRING_FIELDS = { 136, 170, 153, 187 };

    struct SpellRow
    {
        std::array<uint32, 170> Values{};
        std::array<std::string, 4> Strings;
    };

    std::array<SpellRow, MOBILITY_SPELL_COUNT> originalRows;
    std::array<SpellRow, FAMILIES.size()> supportRows;
    bool ready = false;

    void SendRow(Player* player, SpellRow const& row)
    {
        WorldPacket packet(PATCH_SPELL_OPCODE, 1024);
        for (uint32 value : row.Values)
            packet << value;

        // Native 0x092A uses name, description, rank, tooltip, each with a DWORD byte length.
        for (std::string const& text : row.Strings)
        {
            packet << uint32(text.size());
            if (!text.empty())
                packet.append(reinterpret_cast<uint8 const*>(text.data()), text.size());
        }
        player->SendDirectMessage(&packet);
    }

    bool IsNativePlayer(Player* player)
    {
        return ready && player && player->GetSession() && !player->GetSession()->IsBot();
    }

    bool IsOwnedStage(Player* player)
    {
        ManastormRun const* run = ManastormMgr::Instance().GetRunFor(player);
        Map const* map = player->FindMap();
        return run && map && map->IsScriptedPrivateInstance() &&
            player->GetMapId() == run->GetSegment().MapId && player->GetInstanceId() == run->GetInstanceId();
    }

    void RemoveSupport(Player* player)
    {
        for (std::size_t index = 0; index < FAMILIES.size(); ++index)
            player->RemoveAurasDueToSpell(FIRST_SUPPORT_SPELL + uint32(index));
    }
}

bool ManastormMobilityClient::IsMixture(uint32 spellId)
{
    return spellId >= FIRST_MOBILITY_SPELL && spellId < FIRST_MOBILITY_SPELL + MOBILITY_SPELL_COUNT;
}

void ManastormMobilityClient::Load()
{
    if (ready || !ManastormModuleConfig::Enabled() || !ManastormModuleConfig::IsNativeClientMode())
        return;

    ClientDBC dbc;
    std::string const path = (std::filesystem::path(sWorld->GetDataPath()) / "dbc" / "Spell.dbc").string();
    if (!dbc.Load(path, 234))
        return;

    // Preflight the entire range before registering any runtime record.
    for (std::size_t index = 0; index < FAMILIES.size(); ++index)
        if (sSpellMgr->GetSpellInfo(FIRST_SUPPORT_SPELL + uint32(index)))
        {
            LOG_ERROR(LOG_FILTER, "Mobility support disabled: runtime spell ID {} already exists.",
                FIRST_SUPPORT_SPELL + uint32(index));
            return;
        }

    std::array<bool, MOBILITY_SPELL_COUNT> found{};
    for (uint32 index = 0; index < dbc.GetRecordCount(); ++index)
    {
        ClientDBC::Record const record = dbc.GetRecord(index);
        uint32 const id = record.GetUInt32(0);
        if (id >= FIRST_SUPPORT_SPELL && id < FIRST_SUPPORT_SPELL + FAMILIES.size())
        {
            LOG_ERROR(LOG_FILTER, "Mobility support disabled: client spell ID {} already exists.", id);
            return;
        }
        if (!IsMixture(id))
            continue;

        std::size_t const rank = id - FIRST_MOBILITY_SPELL;
        SpellRow& row = originalRows[rank];
        uint32 word = 0;
        for (uint32 field = 0; field < 234;)
        {
            bool const localized = field == 136 || field == 153 || field == 170 || field == 187;
            row.Values[word++] = localized ? 0 : record.GetUInt32(field);
            field += localized ? 17 : 1;
        }
        for (std::size_t string = 0; string < STRING_FIELDS.size(); ++string)
            row.Strings[string] = std::string(record.GetString(STRING_FIELDS[string]));

        if (word != row.Values.size() || record.GetUInt32(95) != 313 ||
            record.GetUInt32(122) != 0xFFFFFFFF || record.GetUInt32(123) != 0xFFFFFFFF ||
            record.GetUInt32(124) != 0xFFFFFFFF)
        {
            LOG_ERROR(LOG_FILTER, "Mobility support disabled: unexpected DBC selectors for spell {}.", id);
            return;
        }
        found[rank] = true;
    }

    for (bool exists : found)
        if (!exists)
        {
            LOG_ERROR(LOG_FILTER, "Mobility support disabled: Spell.dbc is missing a Mobility rank.");
            return;
        }

    SpellEntry const* prototype = sSpellStore.LookupEntry(FIRST_MOBILITY_SPELL);
    if (!prototype || prototype->Effect[0] != SPELL_EFFECT_APPLY_AURA ||
        prototype->EffectApplyAuraName[0] != SPELL_AURA_313 ||
        prototype->EffectSpellClassMask[0] != flag96(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF))
    {
        LOG_ERROR(LOG_FILTER, "Mobility support disabled: server Mobility prototype does not match the client.");
        return;
    }

    for (std::size_t index = 0; index < FAMILIES.size(); ++index)
    {
        SpellEntry entry = *prototype;
        entry.Id = FIRST_SUPPORT_SPELL + uint32(index);
        entry.SpellFamilyName = FAMILIES[index];
        entry.Attributes |= SPELL_ATTR0_DO_NOT_DISPLAY | SPELL_ATTR0_NO_AURA_CANCEL;
        entry.Rank.fill("");
        // Client-only movement adapter: the server permission remains the real mixture's grace.
        entry.EffectApplyAuraName[0] = SPELL_AURA_DUMMY;
        // The real mixture owns expiration, interruption and death cleanup.
        entry.AuraInterruptFlags = 0;
        entry.ProcFlags = 0;
        entry.ProcCharges = 0;
        SpellInfo* info = sSpellMgr->RegisterRuntimeSpell(entry);
        if (!info)
            return;
        info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;

        SpellRow& row = supportRows[index];
        row = originalRows[0];
        row.Values[0] = entry.Id;
        row.Values[4] = entry.Attributes;
        row.Values[32] = entry.AuraInterruptFlags;
        row.Values[34] = entry.ProcFlags;
        row.Values[36] = entry.ProcCharges;
        row.Values[CLIENT_FAMILY_WORD] = entry.SpellFamilyName;
        row.Strings[2].clear();
    }

    ready = true;
    LOG_INFO(LOG_FILTER, "Native Mobility support ready for {} spell families, runtime IDs {}-{}.",
        FAMILIES.size(), FIRST_SUPPORT_SPELL, FIRST_SUPPORT_SPELL + uint32(FAMILIES.size()) - 1);
}

void ManastormMobilityClient::Sync(Player* player)
{
    if (!IsNativePlayer(player))
        return;

    // Reset the seven original records, including any previous family-38 test patch in client memory.
    for (SpellRow const& row : originalRows)
        SendRow(player, row);
    // All native sessions receive definitions so observers also recognize the supporting auras.
    for (SpellRow const& row : supportRows)
        SendRow(player, row);
    SyncAuras(player);
}

void ManastormMobilityClient::PrepareEntry(Player* player)
{
    if (!IsNativePlayer(player) || player->GetSession()->PlayerLoading() ||
        !player->IsInWorld() || !IsOwnedStage(player) || player->HasManastormMovementGrace())
        return;

    // Prime only unused client slots. Do not create server auras, replace buffs or grant server grace.
    std::array<uint8, FAMILIES.size()> slots{};
    std::size_t count = 0;
    Unit::VisibleAuraMap const* visible = player->GetVisibleAuras();
    for (uint16 slot = 0; slot < MAX_AURAS && count < slots.size(); ++slot)
        if (visible->find(uint8(slot)) == visible->end())
            slots[count++] = uint8(slot);

    if (count != slots.size())
        return;

    // OnPlayerEnterAll follows SendInitSelf, while world-transfer initialization is still in progress.
    // Stock SMSG_AURA_UPDATE is one entry per packet; use the core's normal flag and duration layout.
    for (std::size_t index = 0; index < slots.size(); ++index)
    {
        WorldPacket packet(SMSG_AURA_UPDATE, 32);
        packet << player->GetPackGUID();
        packet << slots[index] << uint32(FIRST_SUPPORT_SPELL + uint32(index));
        packet << uint8(AFLAG_EFF_INDEX_0 | AFLAG_CASTER | AFLAG_POSITIVE | AFLAG_DURATION);
        packet << uint8(player->GetLevel()) << uint8(1);
        // Short finite lifetime is also a fallback if the client misses a removal.
        packet << uint32(1) << uint32(1);
        player->SendDirectMessage(&packet);
    }
    for (uint8 slot : slots)
    {
        WorldPacket packet(SMSG_AURA_UPDATE, 16);
        packet << player->GetPackGUID() << slot << uint32(0);
        player->SendDirectMessage(&packet);
    }

    LOG_DEBUG("spells.scripts", "Mobility entry preparation: primed {} client aura records for {}.",
        slots.size(), player->GetGUID().ToString());
}

void ManastormMobilityClient::OnMixtureRemoved(Player* player)
{
    if (!IsNativePlayer(player))
        return;

    // Defer list mutation until the core finishes iterating aura removals.
    // Dummy server companions grant no movement permission during this cleanup interval.
    player->m_Events.AddEventAtOffset([guid = player->GetGUID()]()
    {
        if (Player* current = ObjectAccessor::FindPlayer(guid))
            SyncAuras(current);
    }, Milliseconds(1));
}

void ManastormMobilityClient::SyncAuras(Player* player)
{
    if (!IsNativePlayer(player))
        return;

    Aura const* source = nullptr;
    if (IsOwnedStage(player))
        for (uint32 id = FIRST_MOBILITY_SPELL; id < FIRST_MOBILITY_SPELL + MOBILITY_SPELL_COUNT; ++id)
            if (Aura const* aura = player->GetAura(id))
            {
                AuraApplication const* application = aura->GetApplicationOfTarget(player->GetGUID());
                if (!aura->IsRemoved() && application && !application->GetRemoveMode() &&
                    (aura->GetDuration() < 0 || aura->GetDuration() > 0) &&
                    (!source || aura->GetDuration() < 0 ||
                        (source->GetDuration() >= 0 && aura->GetDuration() > source->GetDuration())))
                    source = aura;
            }

    if (!source)
    {
        RemoveSupport(player);
        return;
    }

    auto const start = std::chrono::steady_clock::now();
    for (std::size_t index = 0; index < FAMILIES.size(); ++index)
    {
        uint32 const id = FIRST_SUPPORT_SPELL + uint32(index);
        Aura* support = player->GetAura(id);
        if (!support)
            support = player->AddAura(id, player);
        if (!support || support->IsRemoved())
            continue;

        support->SetMaxDuration(source->GetMaxDuration());
        support->SetDuration(source->GetDuration());
        support->SetNeedClientUpdateForTargets();
    }

    auto const elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::steady_clock::now() - start).count();
    LOG_DEBUG("spells.scripts", "Mobility server aura synchronization: {} families for {} in {} ms.",
        FAMILIES.size(), player->GetGUID().ToString(), elapsed);
}
