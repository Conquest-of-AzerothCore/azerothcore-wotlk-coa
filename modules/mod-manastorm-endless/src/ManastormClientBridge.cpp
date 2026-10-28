#include "ManastormClientBridge.h"

#include "DatabaseEnv.h"
#include "AscensionCoAConfig.h"
#include "Group.h"
#include "GroupScript.h"
#include "Log.h"
#include "ManastormModuleConfig.h"
#include "ManastormClientUIFixes.h"
#include "ManastormNativeProtocol.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ServerScript.h"
#include "SpellMgr.h"
#include "World.h"
#include "ManastormMgr.h"
#include "ManastormProgression.h"
#include "ManastormRewards.h"
#include "ManastormRun.h"
#include "WorldPacket.h"
#include "WorldSession.h"

// Transport serializers and validated gadget ranks from the native donor.
// No donor Scene catalogue, run service, rewards or progression are used.
#include "AscensionManastormProtocol.h"
#include "AscensionManastormGadgets.h"

#include <algorithm>
#include <array>
#include <string>

namespace
{
    constexpr char const* LOG_FILTER = "module.manastorm.endless.native";
    using Slots = std::array<uint32, 4>;

    bool NativeEnabled()
    {
        return ManastormModuleConfig::Enabled() && ManastormModuleConfig::IsNativeClientMode();
    }

    void SendCStringResult(Player* player, uint16 opcode, char const* value)
    {
        if (!player || !player->GetSession())
            return;
        WorldPacket packet(opcode, 64);
        packet << value;
        player->SendDirectMessage(&packet);
    }

    // Native 0x65F carries eight completed-depth vectors:
    // Normal Solo/Duo/Trio/Group, then Endgame Solo/Duo/Trio/Group.
    bool LoadProgress(Player* player, Ascension::Manastorm::Progress& progress)
    {
        ManastormCompletedDepthLists completed;
        std::string error;

        if (!ManastormProgression::LoadCompletedDepthLists(
            player->GetGUID().GetCounter(),
            completed,
            error))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Cannot load native progression for {}: {}",
                player->GetGUID().ToString(),
                error);

            return false;
        }

        for (std::size_t index = 0;
            index < completed.size();
            ++index)
        {
            progress[index] =
                completed[index];
        }

        return true;
    }

    bool LoadSlots(Player* player, Slots& slots)
    {
        // Reuse the already installed native loadout storage and prepared
        // statements. This is equipment selection, never a progression source.
        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_MANASTORM_LOADOUT);
        statement->SetData(0, player->GetGUID().GetCounter());
        PreparedQueryResult result = CharacterDatabase.Query(statement);
        if (!result)
        {
            LOG_ERROR(LOG_FILTER, "Cannot load Manastorm slots for {}", player->GetGUID().ToString());
            return false;
        }
        do
        {
            Field* fields = result->Fetch();
            uint8 const slot = fields[0].Get<uint8>();
            if (slot < slots.size())
                slots[slot] = fields[1].Get<uint32>();
        } while (result->NextRow());
        return true;
    }

    Ascension::Manastorm::Gadget const* FindGadget(uint32 spell)
    {
        for (auto const& gadget : Ascension::Manastorm::Gadgets)
            if (gadget.spell == spell)
                return &gadget;
        return nullptr;
    }

    char const* ValidateSlot(Player* player, Slots const& slots, uint32 slot, uint32 spell)
    {
        if (slot >= slots.size())
            return "SET_MANASTORM_LOADOUT_OUT_OF_RANGE";
        if (ManastormMgr::Instance().GetRunFor(player))
            return "SET_MANASTORM_LOADOUT_ACTIVE_MANASTORM";
        auto const* gadget = FindGadget(spell);
        if (!gadget || gadget->passive || !sSpellMgr->GetSpellInfo(spell))
            return "SET_MANASTORM_LOADOUT_BAD_SPELL";
        if (!player->HasSpell(spell))
            return "SET_MANASTORM_LOADOUT_NOT_KNOWN";
        for (auto const& other : Ascension::Manastorm::Gadgets)
            // Passive upgrades modify the active gadget; they do not replace its loadout slot.
            if (!other.passive && other.family == gadget->family &&
                other.rank > gadget->rank && player->HasSpell(other.spell))
                return "SET_MANASTORM_LOADOUT_BAD_RANK";
        if (slots[slot] == spell)
            return "SET_MANASTORM_LOADOUT_ALREADY_SET";
        for (std::size_t index = 0; index < slots.size(); ++index)
            if (index != slot)
                if (auto const* other = FindGadget(slots[index]))
                    if (other->family == gadget->family)
                        return "SET_MANASTORM_LOADOUT_ALREADY_SET";
        return nullptr;
    }

    void PrimePotentialRewardItems(Player* player)
    {
        if (!player ||
            !player->GetSession())
        {
            return;
        }

        //
        // The original Manastorm queue hardcodes these item IDs in XML.
        //
        // Its ItemIconTemplate path immediately calls Item:CreateFromID()
        // followed by GetIcon()/GetQuality(), but it does not register an
        // async item-load callback. On a clean client cache those lookups can
        // therefore be empty when the queue first opens.
        //
        // Reuse AzerothCore's normal item-query response serializer to warm
        // the client cache. This changes no client files and no DBCs.
        //
        static constexpr std::array<uint32, 7>
            potentialRewardItems =
            {
                97884,
                1297307,
                1297308,
                1278049,
                1278048,
                97886,
                97885
            };

        WorldSession* session =
            player->GetSession();

        for (uint32 itemEntry :
            potentialRewardItems)
        {
            if (!sObjectMgr->GetItemTemplate(
                    itemEntry))
            {
                LOG_ERROR(
                    LOG_FILTER,
                    "Cannot prime native Manastorm Potential Reward item {}: "
                    "item_template is missing.",
                    itemEntry);

                continue;
            }

            WorldPacket query;
            query << itemEntry;

            session->
                HandleItemQuerySingleOpcode(
                    query);
        }
    }

    char const* ValidateEnter(Player* player, uint32 depth)
    {
        if (!depth)
            return "ENTER_MANASTORM_BAD_LEVEL";
        if (ManastormMgr::Instance().GetRunFor(player))
            return "ENTER_MANASTORM_ALREADY_ACTIVE";
        Group* group = player->GetGroup();
        if (group && !group->IsLeader(player->GetGUID()))
            return "ENTER_MANASTORM_NOT_GROUP_LEADER";
        if (group && group->GetMembersCount() > ManastormLimits::MaxMembers)
            return "ENTER_MANASTORM_BAD_GROUP_SIZE";

        uint32 const endgameLevel =
            std::max(
                60u,
                sWorld->getIntConfig(
                    CONFIG_MAX_PLAYER_LEVEL));

        bool runEndgame =
            player->GetLevel() >=
                endgameLevel;

        if (group)
        {
            for (auto const& memberSlot :
                group->GetMemberSlots())
            {
                if (Player* member =
                    ObjectAccessor::FindConnectedPlayer(
                        memberSlot.guid))
                {
                    runEndgame =
                        runEndgame ||
                        member->GetLevel() >=
                            endgameLevel;
                }
            }
        }

        auto check = [player, depth, group, runEndgame](Player* member) -> char const*
        {
            if (!member || !member->IsInWorld() || !member->FindMap() || !member->IsAlive()
                || member->IsBeingTeleported())
                return "ENTER_MANASTORM_UNKNOWN";
            bool const other = member != player;
            if (other && ManastormMgr::Instance().GetRunFor(member))
                return "ENTER_MANASTORM_BAD_GROUP_SIZE";
            if (member->GetLevel() < 10)
                return other ? "ENTER_MANASTORM_GROUP_TOO_LOW_PLAYER_LEVEL" : "ENTER_MANASTORM_TOO_LOW_PLAYER_LEVEL";
            if (member->IsInFlight())
                return other ? "ENTER_MANASTORM_GROUP_ON_FLIGHT_PATH" : "ENTER_MANASTORM_ON_FLIGHT_PATH";
            if (member->InBattleground() || member->InArena())
                return other ? "ENTER_MANASTORM_GROUP_IN_BATTLEGROUND_OR_ARENA" : "ENTER_MANASTORM_IN_BATTLEGROUND_OR_ARENA";
            if (member->duel)
                return other ? "ENTER_MANASTORM_GROUP_DUELING" : "ENTER_MANASTORM_DUELING";
            if (member->IsInCombat())
                return "ENTER_MANASTORM_UNKNOWN";
            if (member->HasAura(93310))
                return other ? "ENTER_MANASTORM_GROUP_COOLDOWN" : "ENTER_MANASTORM_COOLDOWN";
            if (!sScriptMgr->OnPlayerCanEnterManastorm(member))
                return other ? "ENTER_MANASTORM_GROUP_NO_MANASTORM_CHALLENGE" : "ENTER_MANASTORM_NO_MANASTORM_CHALLENGE";
            ManastormProgressionSnapshot snapshot;
            std::string error;
            auto const mode =
                ManastormModeForMemberCount(
                    group
                    ? group->GetMembersCount()
                    : 1);

            if (!ManastormProgression::LoadSnapshot(
                member->GetGUID().GetCounter(),
                mode,
                runEndgame,
                snapshot,
                error))
            {
                return "ENTER_MANASTORM_UNKNOWN";
            }
            if (!ManastormProgression::IsDepthEnterable(snapshot, depth))
                return "ENTER_MANASTORM_TOO_LOW_COMPLETED_LEVEL";
            return nullptr;
        };
        if (char const* error = check(player))
            return error;
        if (group)
            for (auto const& member : group->GetMemberSlots())
                if (member.guid != player->GetGUID())
                    if (char const* error = check(ObjectAccessor::FindConnectedPlayer(member.guid)))
                        return error;
        return nullptr;
    }
}

ManastormClientBridge& ManastormClientBridge::Instance()
{
    static ManastormClientBridge instance;
    return instance;
}

void ManastormClientBridge::SendEnterResult(Player* player, char const* result) const
{
    SendCStringResult(player, ManastormNativeOpcode::EnterResult, result);
}

void ManastormClientBridge::SendLeaveResult(Player* player, char const* result) const
{
    SendCStringResult(player, ManastormNativeOpcode::LeaveResult, result);
}

void ManastormClientBridge::SendLoadoutResult(Player* player, uint32 slot, char const* result) const
{
    WorldPacket packet(ManastormNativeOpcode::SetLoadoutResult, 64);
    packet << slot << result;
    player->SendDirectMessage(&packet);
}

void ManastormClientBridge::SendChaoticLink(Player* player, uint32 stacks) const
{
    WorldPacket packet(ManastormNativeOpcode::ChaoticLink, 4);
    packet << stacks;
    player->SendDirectMessage(&packet);
}

void ManastormClientBridge::SendFailed(Player* player) const
{
    WorldPacket packet(ManastormNativeOpcode::Failed, 0);
    player->SendDirectMessage(&packet);
}

void ManastormClientBridge::SendState(Player* player, ManastormRun const* run) const
{
    if (!player ||
        !player->GetSession() ||
        !NativeEnabled())
    {
        return;
    }

    bool const active =
        run &&
        run->GetState() !=
            ManastormRunState::Failed &&
        run->GetState() !=
            ManastormRunState::Finished;

    if (run &&
        run->GetState() ==
            ManastormRunState::Failed)
    {
        SendFailed(player);
    }

    uint32 guaranteedCaches = 0;
    float cacheChancePct = 0.0f;
    uint32 cacheItem = 0;

    if (active)
    {
        ManastormRewardStateSnapshot rewardState;
        std::string rewardError;

        if (ManastormRewards::Instance()
            .LoadState(
                player->GetGUID().GetCounter(),
                run->GetMode(),
                run->IsEndgame(),
                rewardState,
                rewardError))
        {
            guaranteedCaches =
                run->GetBonusCacheCount();

            cacheChancePct =
                float(
                    rewardState.CacheChancePct);
        }
        else
        {
            LOG_ERROR(
                LOG_FILTER,
                "Cannot load native Manastorm reward state for {}: {}",
                player->GetGUID().ToString(),
                rewardError);
        }

        if (!ManastormRewards::Instance()
            .ResolveCacheItemEntry(
                run->IsEndgame(),
                run->GetDepth(),
                uint32(
                    player->GetLevel()),
                cacheItem,
                player->GetGUID().GetCounter(),
                uint8(run->GetMode())))
        {
            LOG_ERROR(
                LOG_FILTER,
                "Cannot resolve native Manastorm cache item for {}: "
                "track={} depth={} level={}.",
                player->GetGUID().ToString(),
                run->IsEndgame()
                    ? uint32(
                        ManastormTrackBits::Endgame)
                    : uint32(
                        ManastormTrackBits::Normal),
                run->GetDepth(),
                uint32(
                    player->GetLevel()));
        }
    }

    WorldPacket packet(
        ManastormNativeOpcode::ActiveState,
        48);

    Ascension::Manastorm::WriteActive(
        packet,
        active
            ? run->GetDepth()
            : 0,
        active
            ? run->GetSegment().SegmentId
            : 0,
        active
            ? uint8(
                uint8(run->GetMode()) -
                1 +
                (run->IsEndgame()
                    ? 4
                    : 0))
            : 0,
        guaranteedCaches,
        cacheChancePct,
        cacheItem);

    player->SendDirectMessage(
        &packet);
    ManastormClientUIFixes::SendObjectiveHighlight(player);

    SendChaoticLink(
        player,
        active &&
            run->GetState() !=
                ManastormRunState::StageComplete
            ? run->GetChaoticLinkStacks()
            : 0);

    //
    // Exact Extensions.dll 0x06AD layout:
    //
    //   u64 context
    //   u32 count
    //
    //   repeat:
    //     u32 itemID
    //     u8  action
    //     u32 lockEndTimestamp
    //     u32 secondsRemaining
    //     u32 earnedQuantity
    //     u32 maxQuantity
    //     u32 remainingQuantity
    //     u32 windowStart
    //     u32 windowEnd
    //
    // Sending all seven native Potential Reward identities also causes the
    // native MANASTORM_REWARD_VISIBILITY_UPDATED path to refresh the queue.
    //
    bool endgameRewards = active ? run->IsEndgame() :
        player->GetLevel() >= std::max(60u, sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));
    if (!active)
        if (Group* group = player->GetGroup())
            for (auto const& slot : group->GetMemberSlots())
                if (Player* member = ObjectAccessor::FindConnectedPlayer(slot.guid))
                    endgameRewards = endgameRewards ||
                        member->GetLevel() >= std::max(60u, sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL));

    std::vector<ManastormRewardVisibilityRecord> const
        records =
            ManastormRewards::Instance()
                .BuildVisibilityRecords(player->GetGUID().GetCounter(), endgameRewards, guaranteedCaches);

    WorldPacket visibility(
        ManastormNativeOpcode::RewardVisibility,
        12 +
            records.size() * 33);

    visibility <<
        uint64(
            active
            ? run->GetSegment().SegmentId
            : 0);

    visibility <<
        uint32(
            records.size());

    for (ManastormRewardVisibilityRecord const& record :
        records)
    {
        visibility <<
            record.ItemEntry;
        visibility <<
            record.Action;
        visibility <<
            record.LockEndTimestamp;
        visibility <<
            record.SecondsRemaining;
        visibility <<
            record.EarnedQuantity;
        visibility <<
            record.MaxQuantity;
        visibility <<
            record.RemainingQuantity;
        visibility <<
            record.WindowStart;
        visibility <<
            record.WindowEnd;
    }

    player->SendDirectMessage(
        &visibility);
}

void ManastormClientBridge::SendProgression(Player* player) const
{
    if (!player || !player->GetSession() || !NativeEnabled())
        return;
    Ascension::Manastorm::Progress progress;
    if (!LoadProgress(player, progress))
        return;
    WorldPacket packet(ManastormNativeOpcode::ProgressUpdate, 104);
    packet << player->GetGUID().GetRawValue();
    Ascension::Manastorm::WriteProgress(packet, progress);
    if (Group* group = player->GetGroup())
        group->BroadcastPacket(&packet, false);
    else
        player->SendDirectMessage(&packet);
}

void ManastormClientBridge::SendGroupProgression(Group* group) const
{
    if (!group || !NativeEnabled())
        return;
    for (auto const& member : group->GetMemberSlots())
        if (Player* player = ObjectAccessor::FindConnectedPlayer(member.guid))
            SendProgression(player);
}

void ManastormClientBridge::SendLoadout(Player* player) const
{
    if (!player || !player->GetSession() || !NativeEnabled())
        return;
    Slots slots{};
    if (!LoadSlots(player, slots))
        return;
    WorldPacket packet(ManastormNativeOpcode::FullLoadout, 20);
    packet << uint32(slots.size());
    for (uint32 spell : slots)
        packet << spell;
    player->SendDirectMessage(&packet);
    // Full snapshot has no refresh event; proven per-slot updates refresh an
    // already-open original loadout UI after reconnect/synchronization.
    for (uint32 slot = 0; slot < slots.size(); ++slot)
    {
        WorldPacket update(ManastormNativeOpcode::LoadoutUpdate, 8);
        update << slot << slots[slot];
        player->SendDirectMessage(&update);
    }
}

void ManastormClientBridge::SendConfig(Player* player) const
{
    if (!player || !player->GetSession() || !ManastormModuleConfig::IsNativeClientMode())
        return;
    WorldSession* session = player->GetSession();
    SendAscensionCoAConfig(session);
}

void ManastormClientBridge::Login(Player* player) const
{
    SendConfig(player);

    if (!player ||
        !player->GetSession() ||
        !NativeEnabled())
    {
        return;
    }

    //
    // Prime the seven XML-hardcoded Potential Reward items before the
    // load-on-demand Manastorm queue is opened.
    //
    PrimePotentialRewardItems(
        player);

    Ascension::Manastorm::Progress progress;
    if (LoadProgress(player, progress))
    {
        WorldPacket packet(ManastormNativeOpcode::CompletedDepths, 96);
        Ascension::Manastorm::WriteProgress(packet, progress);
        player->SendDirectMessage(&packet);
    }
    SendLoadout(player);
    if (player->GetGroup())
        SendGroupProgression(player->GetGroup());
    else
        SendProgression(player);
    auto const* run = ManastormMgr::Instance().GetRunFor(player);
    SendState(player, run);
    if (run && run->GetState() == ManastormRunState::StageComplete && !player->IsBeingTeleported())
        SendStageCompleted(player, run->GetDepth());
}

void ManastormClientBridge::SendStageCompleted(Player* player, uint32 depth) const
{
    if (!player || !player->GetSession() || !NativeEnabled())
        return;
    WorldPacket packet(ManastormNativeOpcode::LevelCompleted, 4);
    packet << depth;
    player->SendDirectMessage(&packet);
}

void ManastormClientBridge::BroadcastStageCompleted(ManastormRun const& run) const
{
    if (!NativeEnabled())
        return;
    for (auto guid : run.GetMembers())
        if (Player* member = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)))
        {
            SendStageCompleted(member, run.GetDepth());
            SendProgression(member);
        }
}

bool ManastormClientBridge::HandleIncoming(WorldSession* session, WorldPacket const& packet)
{
    if (!session || !ManastormNativeOpcode::IsClientRequest(uint16(packet.GetOpcode())))
        return false;
    Player* player = session->GetPlayer();
    if (!player || !player->IsInWorld() || !player->FindMap())
        return true;
    if (!NativeEnabled())
    {
        player->SendSystemMessage("Native Manastorm requires Manastorm.Enable=1 and Manastorm.ClientMode=2 (restart required).");
        if (packet.GetOpcode() == ManastormNativeOpcode::Enter)
            SendEnterResult(player, ManastormNativeResult::EnterUnknown);
        else if (packet.GetOpcode() == ManastormNativeOpcode::Leave)
            SendLeaveResult(player, ManastormNativeResult::LeaveNotActive);
        return true;
    }
    LOG_DEBUG(LOG_FILTER, "Shared Manastorm received opcode {} from {}", packet.GetOpcode(), player->GetGUID().ToString());
    uint16 const opcode = uint16(packet.GetOpcode());
    std::size_t const expected = opcode == ManastormNativeOpcode::Enter ? 4
        : opcode == ManastormNativeOpcode::SetLoadoutSlot ? 8 : 0;
    if (packet.size() != expected)
    {
        LOG_WARN(LOG_FILTER, "Malformed native request {} ({} bytes) from {}", opcode,
            packet.size(), player->GetGUID().ToString());
        return true;
    }
    auto& mgr = ManastormMgr::Instance();
    if (opcode == ManastormNativeOpcode::Enter)
    {
        uint32 const depth = packet.read<uint32>(0);
        if (char const* result = ValidateEnter(player, depth))
        {
            SendEnterResult(player, result);
            return true;
        }
        std::string error;
        if (ManastormRun* run = mgr.StartRun(player, depth, error, false))
        {
            for (auto guid : run->GetMembers())
                if (Player* member = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(guid)))
                {
                    SendEnterResult(member, ManastormNativeResult::EnterOk);
                    SendState(member, run);
                    SendProgression(member);
                }
        }
        else
        {
            LOG_WARN(LOG_FILTER, "Native Enter({}) rejected for {}: {}", depth, player->GetGUID().ToString(), error);
            SendEnterResult(player, ManastormNativeResult::EnterUnknown);
            SendState(player, nullptr);
        }
        return true;
    }
    if (opcode == ManastormNativeOpcode::Leave)
    {
        if (!mgr.GetRunFor(player))
        {
            SendLeaveResult(player, ManastormNativeResult::LeaveNotActive);
            SendState(player, nullptr);
            return true;
        }
        if (player->IsBeingTeleported() || player->HasAura(93304))
        {
            SendLeaveResult(player, "LEAVE_MANASTORM_TRANSITION");
            return true;
        }
        std::string error;
        bool const stopped = mgr.StopRun(player, error);
        SendLeaveResult(player, stopped ? ManastormNativeResult::LeaveOk : ManastormNativeResult::LeaveUnknown);
        if (stopped)
            SendState(player, nullptr);
        return true;
    }
    uint32 const slot = packet.read<uint32>(0);
    uint32 const spell = packet.read<uint32>(4);
    Slots slots{};
    char const* result = "SET_MANASTORM_LOADOUT_UNKNOWN";
    if (LoadSlots(player, slots))
    {
        result = ValidateSlot(player, slots, slot, spell);
        if (!result)
        {
            auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_REP_MANASTORM_LOADOUT);
            statement->SetData(0, player->GetGUID().GetCounter());
            statement->SetData(1, uint8(slot));
            statement->SetData(2, spell);
            auto transaction = CharacterDatabase.BeginTransaction();
            transaction->Append(statement);
            // Acknowledge only a durable write; requests are handled serially
            // on the world thread, with no raw Player captured by DB callbacks.
            result = CharacterDatabase.AsyncCommitTransaction(transaction).m_future.get()
                ? "SET_MANASTORM_LOADOUT_OK" : "SET_MANASTORM_LOADOUT_UNKNOWN";
        }
    }
    SendLoadoutResult(player, slot, result);
    if (std::string_view(result) == "SET_MANASTORM_LOADOUT_OK")
    {
        WorldPacket update(ManastormNativeOpcode::LoadoutUpdate, 8);
        update << slot << spell;
        player->SendDirectMessage(&update);
    }
    return true;
}

namespace
{
    class manastorm_native_packet_script : public ServerScript
    {
    public:
        manastorm_native_packet_script()
            : ServerScript("manastorm_native_packet_script", {SERVERHOOK_CAN_PACKET_RECEIVE}) { }

        bool CanPacketReceive(WorldSession* session, WorldPacket const& packet) override
        {
            return !ManastormClientBridge::Instance().HandleIncoming(session, packet);
        }
    };

    class manastorm_native_group_script : public GroupScript
    {
    public:
        manastorm_native_group_script()
            : GroupScript("manastorm_native_group_script", {GROUPHOOK_ON_ADD_MEMBER}) { }

        void OnAddMember(Group* group, ObjectGuid /*guid*/) override
        {
            ManastormClientBridge::Instance().SendGroupProgression(group);
        }
    };
}

void AddSC_manastorm_native_bridge()
{
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        if (!ManastormModuleConfig::IsNativeClientMode())
            return;

        config.Integers.emplace_back("CONFIG_MANASTORM_LOADOUTS_MAX", 4);
        config.Booleans.emplace_back("CONFIG_MANASTORM_ENABLED", NativeEnabled());
        config.Booleans.emplace_back("CONFIG_MANASTORM_END_GAME_ENABLED", NativeEnabled());
        config.Booleans.emplace_back("CONFIG_MANASTORM_LOADOUTS_ENABLED", NativeEnabled());
    });
    new manastorm_native_packet_script();
    new manastorm_native_group_script();
}
