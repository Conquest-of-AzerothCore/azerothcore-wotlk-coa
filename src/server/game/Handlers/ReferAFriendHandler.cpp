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

#include "Chat.h"
#include "Config.h"
#include "CryptoRandom.h"
#include "DatabaseEnv.h"
#include "Item.h"
#include "Mail.h"
#include "Realm.h"
#include "StringConvert.h"
#include "StringFormat.h"
#include "Tokenize.h"
#include "World.h"
#include <algorithm>
#include <memory>
#include <optional>
#include <unordered_map>
#include <vector>
#include "GameTime.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "Player.h"
#include "PlayerSettings.h"
#include "ScriptMgr.h"
#include "SocialMgr.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"

namespace
{
    constexpr uint32 RecruitAFriendMenu = 0x524146;
    constexpr uint32 AcceptRecruitment = 1;
    constexpr uint32 DeclineRecruitment = 2;
    constexpr time_t ProposalLifetime = 60;

    uint8 GrantLevelError(Player* donor, Player* target)
    {
        if (!target || target == donor)
            return ERR_REFER_A_FRIEND_NO_TARGET;
        if (PlayerSettingVector const* prestige = target->FindPlayerSettings("core.coa_prestige");
            prestige && prestige->size() > 1 && (*prestige)[1].value != 0)
            return ERR_REFER_A_FRIEND_NOT_NOW;
        if (!donor->GetGrantableLevels())
            return ERR_REFER_A_FRIEND_INSUFFICIENT_GRANTABLE_LEVELS;
        if (donor->GetSession()->GetAccountId() == target->GetSession()->GetAccountId() ||
            (donor->GetSession()->GetRecruiterId() != target->GetSession()->GetAccountId() &&
                target->GetSession()->GetRecruiterId() != donor->GetSession()->GetAccountId()))
            return ERR_REFER_A_FRIEND_NOT_REFERRED_BY;
        if (donor->GetTeamId() != target->GetTeamId())
            return ERR_REFER_A_FRIEND_DIFFERENT_FACTION;
        if (target->GetLevel() >= donor->GetLevel())
            return ERR_REFER_A_FRIEND_TARGET_TOO_HIGH;
        if (target->GetLevel() >= sWorld->getIntConfig(CONFIG_MAX_RECRUIT_A_FRIEND_BONUS_PLAYER_LEVEL) ||
            target->GetLevel() >= target->GetUInt32Value(PLAYER_FIELD_MAX_LEVEL))
            return ERR_REFER_A_FRIEND_GRANT_LEVEL_MAX_I;
        if (!donor->GetGroup() || donor->GetGroup() != target->GetGroup())
            return ERR_REFER_A_FRIEND_NOT_IN_GROUP;
        if (!donor->IsInMap(target) || !donor->IsAtRecruitAFriendDistance(target))
            return ERR_REFER_A_FRIEND_TOO_FAR;
        if (!donor->IsAlive() || !target->IsAlive() || donor->IsInCombat() || target->IsInCombat() ||
            donor->IsBeingTeleported() || target->IsBeingTeleported() || donor->IsInFlight() || target->IsInFlight())
            return ERR_REFER_A_FRIEND_NOT_NOW;
        if (uint8 cap = sScriptMgr->GetMaxAllowedLevel(target))
            if (target->GetLevel() >= cap)
                return ERR_REFER_A_FRIEND_NOT_NOW;
        return ERR_REFER_A_FRIEND_NONE;
    }

    void SendGrantError(WorldSession* session, uint8 error, Player const* target)
    {
        WorldPacket data(SMSG_REFER_A_FRIEND_FAILURE, 24);
        data << uint32(error);
        if (error == ERR_REFER_A_FRIEND_NOT_IN_GROUP && target)
            data << target->GetName();
        session->SendPacket(&data);
    }
}

void WorldSession::HandleGrantLevel(WorldPacket& recvData)
{
    ObjectGuid guid;
    recvData >> guid.ReadAsPacked();
    Player* target = ObjectAccessor::GetPlayer(*_player, guid);
    if (uint8 error = GrantLevelError(_player, target))
    {
        SendGrantError(this, error, target);
        return;
    }

    WorldSession* recipient = target->GetSession();
    if (recipient->_rafGrantExpiry > GameTime::GetGameTime().count())
    {
        SendGrantError(this, ERR_REFER_A_FRIEND_NOT_NOW, target);
        return;
    }
    recipient->_rafGrantFrom = _player->GetGUID();
    recipient->_rafGrantRecipient = target->GetGUID();
    recipient->_rafGrantLevel = target->GetLevel();
    recipient->_rafGrantDonorLevel = _player->GetLevel();
    recipient->_rafGrantExpiry = GameTime::GetGameTime().count() + ProposalLifetime;
    WorldPacket data(SMSG_PROPOSE_LEVEL_GRANT, 8);
    data << _player->GetPackGUID();
    target->SendDirectMessage(&data);
}

void WorldSession::HandleAcceptGrantLevel(WorldPacket& recvData)
{
    ObjectGuid guid;
    recvData >> guid.ReadAsPacked();
    if (guid != _rafGrantFrom || _rafGrantRecipient != _player->GetGUID())
        return;

    time_t const expiry = _rafGrantExpiry;
    _rafGrantExpiry = 0;
    _rafGrantFrom.Clear();
    _rafGrantRecipient.Clear();
    if (expiry <= GameTime::GetGameTime().count())
        return;

    Player* donor = ObjectAccessor::GetPlayer(*_player, guid);
    if (!donor || donor->GetLevel() != _rafGrantDonorLevel || _player->GetLevel() != _rafGrantLevel)
        return;
    if (uint8 error = GrantLevelError(donor, _player))
    {
        SendGrantError(donor->GetSession(), error, _player);
        return;
    }

    uint8 const nextLevel = _player->GetLevel() + 1;
    _player->GiveLevel(nextLevel);
    if (_player->GetLevel() != nextLevel)
    {
        SendGrantError(donor->GetSession(), ERR_REFER_A_FRIEND_NOT_NOW, _player);
        return;
    }

    donor->SetGrantableLevels(donor->GetGrantableLevels() - 1);
    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    _player->SaveToDB(trans, false, false);
    donor->SaveToDB(trans, false, false);
    CharacterDatabase.CommitTransaction(trans);
}

void WorldSession::ClearRecruitAFriendRequests()
{
    _rafGrantFrom.Clear();
    _rafGrantRecipient.Clear();
    _rafGrantExpiry = 0;
    _rafInviter.Clear();
    _rafInviteExpiry = 0;
    _rafRewardsNextUpdate = 0;
    _rafSummoner.Clear();
}

void WorldSession::RefreshRecruitAFriendFlags()
{
    if (!_player || !_player->IsInWorld())
        return;
    if (isRecruiter || recruiterId)
        _player->SetDynamicFlag(UNIT_DYNFLAG_REFER_A_FRIEND);
    _player->SetRestBonus(_player->GetRestBonus());
    _player->SetGrantableLevels(_player->GetGrantableLevels());
    _player->GetSocial()->SendSocialList(_player, SOCIAL_FLAG_FRIEND);
}

bool WorldSession::InviteRecruitAFriend(Player* target)
{
    ChatHandler chat(this);
    auto reject = [&chat](char const* message)
    {
        chat.SendSysMessage(message);
        return false;
    };
    time_t const now = GameTime::GetGameTime().count();
    if (!_player)
        return reject("Recruit-A-Friend requires a character logged into the world.");
    if (!target)
        return reject("That character is not online on this realm. Use .raf <CharacterName>.");
    if (target == _player || target->GetSession()->GetAccountId() == GetAccountId())
        return reject("You cannot recruit yourself or another character on your own account.");

    WorldSession* recipient = target->GetSession();
    if (recipient->recruiterId == GetAccountId())
        return reject("That account is already recruited by you. The link is permanent; use .raf status to view your recruits.");
    if (recipient->recruiterId)
        return reject("That account already has another recruiter. Existing recruitment links cannot be changed.");
    if (recruiterId == recipient->GetAccountId())
        return reject("That account is your recruiter. Recruiting them would create a recruitment cycle.");
    if (target->GetTeamId() != _player->GetTeamId())
        return reject("You can only recruit a character of the same faction.");
    if (!_player->IsAlive() || !target->IsAlive())
        return reject("Both characters must be alive before you can send a recruitment invitation.");
    if (_player->IsInCombat() || target->IsInCombat())
        return reject("Both characters must leave combat before you can send a recruitment invitation.");
    if (_player->IsBeingTeleported() || target->IsBeingTeleported())
        return reject("Wait for both characters to finish teleporting before inviting again.");
    if (recipient->_rafInviteExpiry > now)
    {
        if (recipient->_rafInviter == _player->GetGUID())
            return reject("You already invited that character. They must accept or decline; invitations expire after 60 seconds.");
        return reject("That character already has a pending recruitment invitation. Try again after it is answered or expires.");
    }
    if (_rafInviteCooldown > now)
    {
        chat.PSendSysMessage("Please wait {} seconds before sending another recruitment invitation.",
            uint32(_rafInviteCooldown - now));
        return false;
    }
    _rafInviteCooldown = now + 10;
    recipient->_rafInviter = _player->GetGUID();
    recipient->_rafInviteExpiry = now + ProposalLifetime;
    target->PlayerTalkClass->ClearMenus();
    GossipMenu& menu = target->PlayerTalkClass->GetGossipMenu();
    menu.SetMenuId(RecruitAFriendMenu);
    menu.AddMenuItem(-1, GOSSIP_ICON_CHAT, "Accept permanent recruitment", 0, AcceptRecruitment, "", 0);
    menu.AddMenuItem(-1, GOSSIP_ICON_CHAT, "Decline", 0, DeclineRecruitment, "", 0);
    target->PlayerTalkClass->SendDynamicGossipMenu(_player->GetName() +
        " invites you to Recruit-A-Friend. Accepting permanently links your account to theirs. This link does not expire.",
        target->GetGUID());
    ChatHandler(this).SendSysMessage("Recruitment invitation sent. The other player must accept.");
    return true;
}

bool WorldSession::HandleRecruitAFriendInviteResponse(uint32 menuId, uint32 action)
{
    if (menuId != RecruitAFriendMenu)
        return false;
    ObjectGuid const inviterGuid = _rafInviter;
    time_t const expiry = _rafInviteExpiry;
    _rafInviter.Clear();
    _rafInviteExpiry = 0;
    _player->PlayerTalkClass->SendCloseGossip();
    if (expiry <= GameTime::GetGameTime().count() || inviterGuid.IsEmpty())
        return true;
    Player* inviter = ObjectAccessor::FindPlayer(inviterGuid);
    if (!inviter)
        return true;
    if (action == DeclineRecruitment)
    {
        ChatHandler(inviter->GetSession()).SendSysMessage("Recruitment invitation declined.");
        return true;
    }
    if (action != AcceptRecruitment || recruiterId ||
        GetAccountId() == inviter->GetSession()->GetAccountId() ||
        inviter->GetTeamId() != _player->GetTeamId() || !_player->IsAlive() || !inviter->IsAlive() ||
        _player->IsInCombat() || inviter->IsInCombat())
        return true;

    uint32 const inviterAccount = inviter->GetSession()->GetAccountId();
    auto* stmt = LoginDatabase.GetPreparedStatement(LOGIN_UPD_RAF_RECRUITER);
    stmt->SetData(0, inviterAccount);
    stmt->SetData(1, GetAccountId());
    stmt->SetData(2, inviterAccount);
    stmt->SetData(3, GetAccountId());
    LoginDatabaseTransaction trans = LoginDatabase.BeginTransaction();
    trans->Append(LoginDatabase.GetPreparedStatement(LOGIN_INS_RAF_LINK_LOCK));
    trans->Append(LoginDatabase.GetPreparedStatement(LOGIN_UPD_RAF_LINK_LOCK));
    trans->Append(stmt);
    auto* registration = LoginDatabase.GetPreparedStatement(LOGIN_INS_RAF_ACCOUNT);
    registration->SetData(0, GetAccountId());
    trans->Append(registration);
    AddTransactionCallback(LoginDatabase.AsyncCommitTransaction(trans)).AfterComplete([this, inviterAccount](bool success)
    {
        if (!success)
        {
            ChatHandler(this).SendSysMessage("Recruitment could not be saved. No link was confirmed; please try again.");
            if (WorldSession* recruiter = sWorldSessionMgr->FindSession(inviterAccount))
                ChatHandler(recruiter).SendSysMessage("Recruitment could not be saved. No link was confirmed; please try again.");
            return;
        }
        auto* status = LoginDatabase.GetPreparedStatement(LOGIN_SEL_RAF_STATUS);
        status->SetData(0, GetAccountId());
        GetQueryProcessor().AddCallback(LoginDatabase.AsyncQuery(status).WithPreparedCallback(
            [this, inviterAccount](PreparedQueryResult result)
            {
                if (!result || result->Fetch()[0].Get<uint32>() != inviterAccount)
                {
                    ChatHandler(this).SendSysMessage("Recruitment was not accepted because an account is already linked or would create a recruitment cycle.");
                    if (WorldSession* recruiter = sWorldSessionMgr->FindSession(inviterAccount))
                        ChatHandler(recruiter).SendSysMessage("Recruitment was not accepted because an account is already linked or would create a recruitment cycle.");
                    return;
                }
                recruiterId = inviterAccount;
                UpdateRecruitAFriendRewards(true);
                RefreshRecruitAFriendFlags();
                ChatHandler(this).SendSysMessage("Your account is now permanently recruited. Recruit-A-Friend is active.");
                if (WorldSession* recruiter = sWorldSessionMgr->FindSession(inviterAccount))
                {
                    recruiter->isRecruiter = true;
                    recruiter->RefreshRecruitAFriendFlags();
                    ChatHandler(recruiter).SendSysMessage("Recruitment accepted and permanently saved.");
                }
            }));
    });
    return true;
}

SpellCastResult WorldSession::CheckRecruitAFriendSummon(Player const* target) const
{
    if (!_player || !target || target == _player || !_player->IsInWorld() || !target->IsInWorld() ||
        target->GetSession()->GetAccountId() == GetAccountId())
        return SPELL_FAILED_BAD_TARGETS;
    if (target->GetSession()->GetRecruiterId() != GetAccountId() && recruiterId != target->GetSession()->GetAccountId())
        return SPELL_FAILED_BAD_TARGETS;
    if (target->GetTeamId() != _player->GetTeamId())
        return SPELL_FAILED_BAD_TARGETS;
    if (target->GetLevel() >= sWorld->getIntConfig(CONFIG_MAX_RECRUIT_A_FRIEND_BONUS_PLAYER_LEVEL))
        return SPELL_FAILED_HIGHLEVEL;
    if (!_player->IsAlive() || !target->IsAlive() || _player->IsInCombat() || target->IsInCombat() ||
        _player->IsBeingTeleported() || target->IsBeingTeleported() || _player->IsInFlight() || target->IsInFlight() ||
        _player->GetVehicle() || target->GetVehicle())
        return SPELL_FAILED_NOT_HERE;
    Map const* casterMap = _player->FindMap();
    Map const* targetMap = target->FindMap();
    if (!casterMap || !targetMap || casterMap->Instanceable() || targetMap->Instanceable() ||
        _player->GetInstanceId() || target->GetInstanceId())
        return SPELL_FAILED_NOT_HERE;
    return SPELL_CAST_OK;
}

bool WorldSession::ValidateRecruitAFriendSummon(ObjectGuid guid, bool agree)
{
    if (_rafSummoner.IsEmpty())
        return true;
    if (guid != _rafSummoner)
        return false;
    if (_player->GetSummonExpireTimer() <= GameTime::GetGameTime().count())
    {
        _rafSummoner.Clear();
        return false;
    }
    if (agree)
    {
        Player* summoner = ObjectAccessor::FindPlayer(guid);
        if (!summoner || summoner->GetSession()->CheckRecruitAFriendSummon(_player) != SPELL_CAST_OK)
        {
            _rafSummoner.Clear();
            _player->SummonIfPossible(false, guid);
            return false;
        }
    }
    _rafSummoner.Clear();
    return true;
}

namespace
{
    uint8 RecruitRewardRealmMask()
    {
        std::string const modes = sConfigMgr->GetOption<std::string>("CoAChallenges.GameModes.Realm", "");
        for (std::string_view mode : Acore::Tokenize(modes, ',', false))
            if (Acore::String::Trim(std::string(mode)) == "WildCard")
                return 8;
        std::string const model = sConfigMgr->GetOption<std::string>("CoA.ClassModel", "coa");
        if (model == "coa")
            return 1;
        if (model == "hero")
            return 2;
        if (model == "wcr")
            return 4;
        return 0;
    }

    bool ValidRecruitReward(uint32 itemId, uint32 quantity)
    {
        ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
        return item && quantity && item->GetMaxStackSize() &&
            (item->MaxCount <= 0 || quantity <= uint32(item->MaxCount)) &&
            (uint64(quantity) + item->GetMaxStackSize() - 1) / item->GetMaxStackSize() <= 1000;
    }
}

void WorldSession::UpdateRecruitAFriendRewards(bool force)
{
    if (!_player || !_player->IsInWorld())
        return;
    time_t const now = GameTime::GetGameTime().count();
    if (!force && now < _rafRewardsNextUpdate)
        return;
    _rafRewardsNextUpdate = now + 60;
    if (recruiterId)
    {
        if (!_rafRewardSession)
            Acore::Crypto::GetRandomBytes(reinterpret_cast<uint8*>(&_rafRewardSession), sizeof(_rafRewardSession));
        auto* registration = LoginDatabase.GetPreparedStatement(LOGIN_INS_RAF_ACCOUNT);
        registration->SetData(0, GetAccountId());
        auto* baseline = LoginDatabase.GetPreparedStatement(LOGIN_INS_RAF_PROGRESS);
        baseline->SetData(0, GetAccountId());
        baseline->SetData(1, realm.Id.Realm);
        baseline->SetData(2, _player->GetGUID().GetCounter());
        baseline->SetData(3, _player->GetTotalPlayedTime());
        baseline->SetData(4, _player->GetTotalPlayedTime());
        baseline->SetData(5, _rafRewardSession);
        auto* progress = LoginDatabase.GetPreparedStatement(LOGIN_UPD_RAF_PROGRESS);
        progress->SetData(0, _rafRewardSession);
        progress->SetData(1, _player->GetTotalPlayedTime());
        progress->SetData(2, _rafRewardSession);
        progress->SetData(3, _player->GetTotalPlayedTime());
        progress->SetData(4, _player->GetTotalPlayedTime());
        progress->SetData(5, _rafRewardSession);
        progress->SetData(6, GetAccountId());
        progress->SetData(7, realm.Id.Realm);
        progress->SetData(8, _player->GetGUID().GetCounter());
        auto* validate = LoginDatabase.GetPreparedStatement(LOGIN_UPD_RAF_VALIDATION);
        validate->SetData(0, GetAccountId());
        auto trans = LoginDatabase.BeginTransaction();
        trans->Append(registration);
        trans->Append(baseline);
        trans->Append(progress);
        trans->Append(validate);
        LoginDatabase.DirectCommitTransaction(trans);
    }
    UpdateRecruitMilestoneRewards();
    RecoverRecruitAFriendRewards();
    RecoverRecruitAFriendRewards(true);
}

void WorldSession::UpdateRecruitMilestoneRewards()
{
    if (!_player || !recruiterId)
        return;

    uint32 reachedLevel = _player->GetLevel();
    if (PlayerSettingVector const* settings = _player->FindPlayerSettings("core.coa_prestige");
        settings && !settings->empty() && settings->front().value > 0)
        reachedLevel = std::max(reachedLevel, std::min<uint32>(60,
            sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL)));

    auto* query = WorldDatabase.GetPreparedStatement(WORLD_SEL_RAF_RECRUIT_MILESTONES);
    PreparedQueryResult rewards = WorldDatabase.Query(query);
    if (!rewards)
        return;

    uint8 const realmMask = RecruitRewardRealmMask();
    do
    {
        Field* fields = rewards->Fetch();
        uint32 const rewardId = fields[0].Get<uint32>();
        uint32 const requiredLevel = fields[1].Get<uint32>();
        uint8 const mask = fields[2].Get<uint8>();
        uint32 const itemId = fields[3].Get<uint32>();
        uint32 const quantity = fields[4].Get<uint32>();
        if (!rewardId || !requiredLevel || reachedLevel < requiredLevel || !(mask & realmMask) ||
            (mask & ~15) || !ValidRecruitReward(itemId, quantity))
            continue;

        auto* claim = LoginDatabase.GetPreparedStatement(LOGIN_INS_RAF_RECRUIT_CLAIM);
        claim->SetData(0, GetAccountId());
        claim->SetData(1, rewardId);
        claim->SetData(2, realm.Id.Realm);
        claim->SetData(3, _player->GetGUID().GetCounter());
        claim->SetData(4, itemId);
        claim->SetData(5, quantity);
        claim->SetData(6, GetAccountId());
        LoginDatabase.DirectExecute(claim);
    } while (rewards->NextRow());
}

void WorldSession::RecoverRecruitAFriendRewards(bool recruit)
{
    auto* claims = LoginDatabase.GetPreparedStatement(
        recruit ? LOGIN_SEL_RAF_RECRUIT_CLAIMS : LOGIN_SEL_RAF_CLAIMS);
    claims->SetData(0, GetAccountId());
    PreparedQueryResult rows = LoginDatabase.Query(claims);
    if (!rows)
        return;
    do
    {
        Field* fields = rows->Fetch();
        if (fields[2].Get<uint32>() != realm.Id.Realm || !fields[6].IsNull())
            continue;
        uint64 const claimId = fields[0].Get<uint64>();
        ObjectGuid::LowType const guid = fields[3].Get<uint32>();
        uint32 const itemId = fields[4].Get<uint32>();
        uint32 const quantity = fields[5].Get<uint32>();
        auto receiptQuery = [claimId, recruit]()
        {
            auto* stmt = CharacterDatabase.GetPreparedStatement(
                recruit ? CHAR_SEL_RAF_RECRUIT_DELIVERY : CHAR_SEL_RAF_DELIVERY);
            stmt->SetData(0, claimId);
            return CharacterDatabase.Query(stmt);
        };
        PreparedQueryResult receipt = receiptQuery();
        if (!receipt)
        {
            if (!ValidRecruitReward(itemId, quantity))
                continue;
            auto* ownerQuery = CharacterDatabase.GetPreparedStatement(CHAR_SEL_RAF_RECIPIENT);
            ownerQuery->SetData(0, guid);
            PreparedQueryResult owner = CharacterDatabase.Query(ownerQuery);
            if (!owner || owner->Fetch()[0].Get<uint32>() != GetAccountId())
                continue;
            ItemTemplate const* itemTemplate = sObjectMgr->GetItemTemplate(itemId);
            auto trans = CharacterDatabase.BeginTransaction();
            std::vector<std::unique_ptr<MailDraft>> drafts;
            std::vector<StagedMail> staged;
            uint32 remaining = quantity;
            bool valid = true;
            while (remaining && valid)
            {
                auto draft = std::make_unique<MailDraft>("Recruit-A-Friend reward",
                    recruit ? "Welcome! Your recruit milestone reward is enclosed. Each milestone is rewarded once per account on this realm." :
                    "Thank you for recruiting your friends! Your account-wide reward is enclosed.");
                for (uint32 slot = 0; remaining && slot < MAX_MAIL_ITEMS; ++slot)
                {
                    uint32 const count = std::min(remaining, itemTemplate->GetMaxStackSize());
                    Item* item = Item::CreateItem(itemId, count, nullptr);
                    if (!item)
                    {
                        valid = false;
                        break;
                    }
                    item->SaveToDB(trans);
                    draft->AddItem(item);
                    remaining -= count;
                }
                auto mail = valid ? draft->StageMailTo(trans, guid,
                    MailSender(MAIL_NORMAL, 0, MAIL_STATIONERY_GM)) : std::nullopt;
                if (!mail)
                    valid = false;
                else
                    staged.push_back(*mail);
                drafts.push_back(std::move(draft));
            }
            if (!valid)
            {
                for (auto const& draft : drafts)
                    draft->DiscardItems();
                continue;
            }
            auto* marker = CharacterDatabase.GetPreparedStatement(
                recruit ? CHAR_INS_RAF_RECRUIT_DELIVERY : CHAR_INS_RAF_DELIVERY);
            marker->SetData(0, claimId);
            marker->SetData(1, GetAccountId());
            marker->SetData(2, guid);
            marker->SetData(3, staged.front().mailId);
            trans->Append(marker);
            CharacterDatabase.DirectCommitTransaction(trans);
            receipt = receiptQuery();
            bool const committed = receipt && receipt->Fetch()[0].Get<uint32>() == staged.front().mailId;
            for (std::size_t index = 0; index < drafts.size(); ++index)
            {
                if (committed)
                    drafts[index]->PublishStagedMail(staged[index], ObjectAccessor::FindPlayerByLowGUID(guid));
                else
                    drafts[index]->DiscardItems();
            }
        }
        if (receipt)
        {
            auto* delivered = LoginDatabase.GetPreparedStatement(
                recruit ? LOGIN_UPD_RAF_RECRUIT_CLAIM_DELIVERED : LOGIN_UPD_RAF_CLAIM_DELIVERED);
            delivered->SetData(0, claimId);
            LoginDatabase.DirectExecute(delivered);
        }
    } while (rows->NextRow());
}

bool WorldSession::HandleRecruitAFriendRewardsCommand(std::string const& command)
{
    if (!_player || !_player->IsInWorld())
        return false;
    ChatHandler chat(this);
    UpdateRecruitAFriendRewards(true);
    if (command == "status")
    {
        auto* stmt = LoginDatabase.GetPreparedStatement(LOGIN_SEL_RAF_RECRUITS);
        stmt->SetData(0, GetAccountId());
        PreparedQueryResult result = LoginDatabase.Query(stmt);
        uint32 total = 0;
        uint32 validated = 0;
        if (result)
        {
            do
            {
                Field* fields = result->Fetch();
                ++total;
                bool const valid = !fields[1].IsNull();
                validated += valid;
                chat.PSendSysMessage("Recruit {}: {} ({}/7200 seconds on their best single character).",
                    fields[0].Get<uint32>(), valid ? "validated" : "pending", fields[2].Get<uint64>());
            } while (result->NextRow());
        }
        chat.PSendSysMessage("Direct recruits: {} total, {} validated, {} pending. Progress updates every minute.",
            total, validated, total - validated);
        return true;
    }
    if (recruiterId && command == "rewards")
    {
        auto* milestonesQuery = WorldDatabase.GetPreparedStatement(WORLD_SEL_RAF_RECRUIT_MILESTONES);
        if (PreparedQueryResult milestones = WorldDatabase.Query(milestonesQuery))
        {
            uint8 const mode = RecruitRewardRealmMask();
            do
            {
                Field* fields = milestones->Fetch();
                uint8 const mask = fields[2].Get<uint8>();
                uint32 const itemId = fields[3].Get<uint32>();
                uint32 const quantity = fields[4].Get<uint32>();
                if (!(mask & mode) || (mask & ~15) || !ValidRecruitReward(itemId, quantity))
                    continue;
                ItemTemplate const* item = sObjectMgr->GetItemTemplate(itemId);
                if (item)
                    chat.PSendSysMessage("Recruit bonus at level {}: {} x{}. Mailed automatically once per account on this realm.",
                        fields[1].Get<uint32>(), item->Name1, quantity);
            } while (milestones->NextRow());
        }
    }
    auto* countQuery = LoginDatabase.GetPreparedStatement(LOGIN_SEL_RAF_VALID_COUNT);
    countQuery->SetData(0, GetAccountId());
    PreparedQueryResult countResult = LoginDatabase.Query(countQuery);
    if (!countResult)
    {
        chat.SendSysMessage("Recruitment eligibility could not be checked. Please try again.");
        return true;
    }
    uint32 const count = countResult->Fetch()[0].Get<uint32>();
    auto* claimQuery = LoginDatabase.GetPreparedStatement(LOGIN_SEL_RAF_CLAIMS);
    claimQuery->SetData(0, GetAccountId());
    PreparedQueryResult claims = LoginDatabase.Query(claimQuery);
    std::unordered_map<uint32, bool> claimed;
    if (claims)
    {
        do
        {
            Field* fields = claims->Fetch();
            claimed.emplace(fields[1].Get<uint32>(), !fields[6].IsNull());
        } while (claims->NextRow());
    }
    uint32 requested = 0;
    if (command != "rewards")
    {
        auto id = command.rfind("claim ", 0) == 0 ? Acore::StringTo<uint32>(command.substr(6)) : std::nullopt;
        if (!id || !*id)
        {
            chat.SendSysMessage("Usage: .raf claim <reward_id>");
            return true;
        }
        requested = *id;
        if (auto existing = claimed.find(requested); existing != claimed.end())
        {
            chat.SendSysMessage(existing->second ? "This reward has already been mailed to your account." :
                "This reward is reserved for delivery to the original character and realm; recovery runs there on login.");
            return true;
        }
    }
    auto* rewardsQuery = WorldDatabase.GetPreparedStatement(WORLD_SEL_RAF_REWARDS);
    PreparedQueryResult rewards = WorldDatabase.Query(rewardsQuery);
    bool listed = false;
    uint8 const realmMask = RecruitRewardRealmMask();
    if (rewards)
    {
        do
        {
            Field* fields = rewards->Fetch();
            uint32 const id = fields[0].Get<uint32>();
            uint32 const needed = fields[1].Get<uint32>();
            uint8 const mask = fields[2].Get<uint8>();
            uint32 const itemId = fields[3].Get<uint32>();
            uint32 const quantity = fields[4].Get<uint32>();
            if (!(mask & realmMask) || (mask & ~15) || (requested && requested != id))
                continue;
            bool const valid = ValidRecruitReward(itemId, quantity);
            if (!requested)
            {
                auto existing = claimed.find(id);
                char const* state = existing != claimed.end() ? (existing->second ? "claimed" : "delivery pending") :
                    !valid ? "invalid configuration" : count >= needed ? "available" : "locked";
                chat.PSendSysMessage("Reward {}: item {} x{}, needs {} direct recruits - {}.",
                    id, itemId, quantity, needed, state);
                listed = true;
                continue;
            }
            if (!valid || count < needed)
            {
                chat.SendSysMessage("This reward is locked or its item configuration is invalid.");
                return true;
            }
            auto* reserve = LoginDatabase.GetPreparedStatement(LOGIN_INS_RAF_CLAIM);
            reserve->SetData(0, GetAccountId());
            reserve->SetData(1, id);
            reserve->SetData(2, realm.Id.Realm);
            reserve->SetData(3, _player->GetGUID().GetCounter());
            reserve->SetData(4, itemId);
            reserve->SetData(5, quantity);
            reserve->SetData(6, GetAccountId());
            reserve->SetData(7, needed);
            LoginDatabase.DirectExecute(reserve);
            RecoverRecruitAFriendRewards();
            chat.SendSysMessage("Claim processed. Use .raf rewards to check delivery status; delivered items are in your mailbox.");
            return true;
        } while (rewards->NextRow());
    }
    if (!listed)
        chat.SendSysMessage(requested ? "No enabled reward with that ID is available on this realm." :
            "No enabled rewards are configured for this realm.");
    return true;
}
