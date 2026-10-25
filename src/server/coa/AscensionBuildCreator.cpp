/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBuildCreatorRules.h"
#include "AscensionCompatOpcodes.h"
#include "AscensionFreepick.h"
#include "AscensionMysticEnchant.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "SpellMgr.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <atomic>
#include <deque>
#include <map>
#include <mutex>
#include <unordered_map>
#include <unordered_set>

namespace AscensionBuildCreator
{
namespace
{
constexpr uint16 CMSG_ACTIVATE_BUILD = 0x05C2;
constexpr uint16 SMSG_ACTIVATE_BUILD_RESULT = 0x05C3;
constexpr uint16 CMSG_DEACTIVATE_BUILD = 0x05C4;
constexpr uint16 SMSG_DEACTIVATE_BUILD_RESULT = 0x05C5;
constexpr uint16 CMSG_CREATE_BUILD = 0x0626;
constexpr uint16 SMSG_CREATE_BUILD_RESULT = 0x0627;
constexpr uint16 CMSG_SAVE_BUILD = 0x0628;
constexpr uint16 SMSG_SAVE_BUILD_RESULT = 0x0629;
constexpr uint16 CMSG_RATE_BUILD = 0x062A;
constexpr uint16 SMSG_RATE_BUILD_RESULT = 0x062B;
constexpr uint16 CMSG_DELETE_BUILD = 0x062C;
constexpr uint16 SMSG_DELETE_BUILD_RESULT = 0x062D;
constexpr uint16 CMSG_REQUEST_BUILD_DATAS = 0x062E;
constexpr uint16 SMSG_REQUEST_BUILD_DATAS_RESULT = 0x062F;
constexpr uint16 CMSG_REQUEST_BUILD_DATA = 0x0630;
constexpr uint16 SMSG_REQUEST_BUILD_DATA_RESULT = 0x0631;
constexpr uint16 SMSG_OWNED_BUILDS = 0x0634;
constexpr uint16 SMSG_ACTIVE_BUILD = 0x0632;
constexpr uint16 SMSG_ACTIVE_BUILDS = 0x0633;
constexpr uint16 SMSG_UPVOTED_BUILDS = 0x0635;

constexpr std::array<uint16, 8> CLIENT_OPCODES = { CMSG_ACTIVATE_BUILD, CMSG_DEACTIVATE_BUILD, CMSG_CREATE_BUILD,
    CMSG_SAVE_BUILD, CMSG_RATE_BUILD, CMSG_DELETE_BUILD, CMSG_REQUEST_BUILD_DATAS, CMSG_REQUEST_BUILD_DATA };
constexpr std::size_t MAX_QUEUED_REQUESTS = 16;

std::mutex CatalogLock;
std::map<uint32, Build> Builds;
std::unordered_map<std::string, uint32> Entries;
std::unordered_map<uint32, std::unordered_set<uint32>> Votes;
uint32 NextEntry = 1;

std::mutex ActiveLock;
std::unordered_map<ObjectGuid, ActiveBuilds> Active;
std::unordered_set<ObjectGuid> DeferredAutoLearn;
std::atomic<bool> AnyDeferred = false;

std::mutex PendingLock;
std::unordered_map<WorldSession const*, std::deque<WorldPacket>> PendingRequests;
std::atomic<bool> AnyPending = false;

Build* Find(std::string const& id)
{
    auto const itr = Entries.find(id);
    return itr == Entries.end() ? nullptr : &Builds.at(itr->second);
}

void LoadCatalog()
{
    std::lock_guard<std::mutex> lock(CatalogLock);
    Builds.clear();
    Entries.clear();
    Votes.clear();
    NextEntry = 1;

    if (PreparedQueryResult result = CharacterDatabase.Query(
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_BUILD_CREATOR_BUILDS)))
    {
        do
        {
            Field* fields = result->Fetch();
            Build& build = Builds[fields[0].Get<uint32>()];
            build.Id = fields[1].Get<std::string>();
            build.LevelingId = fields[2].Get<std::string>();
            build.PveId = fields[3].Get<std::string>();
            build.PvpId = fields[4].Get<std::string>();
            build.Class = fields[5].Get<uint8>();
            build.OwnerAccount = fields[6].Get<uint32>();
            build.Author = fields[7].Get<std::string>();
            build.Name = fields[8].Get<std::string>();
            build.Subtext = fields[9].Get<std::string>();
            build.Description = fields[10].Get<std::string>();
            build.Icon = fields[11].Get<std::string>();
            build.Upvotes = fields[12].Get<uint32>();
            build.Created = fields[13].Get<uint64>();
            build.Updated = fields[14].Get<uint64>();
            build.Category = fields[15].Get<uint8>();
            build.Roles = fields[16].Get<uint8>();
            build.PrimaryStat = fields[17].Get<uint8>();
            build.NeedsRepairs = fields[18].Get<uint8>();
            build.Flags = fields[19].Get<uint32>();
            build.Difficulty = fields[20].Get<uint8>();
        } while (result->NextRow());
    }

    if (PreparedQueryResult result = CharacterDatabase.Query(
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_BUILD_CREATOR_SPELLS)))
    {
        do
        {
            Field* fields = result->Fetch();
            auto const build = Builds.find(fields[0].Get<uint32>());
            if (build == Builds.end())
                continue;
            Spell& spell = build->second.Spells.emplace_back();
            spell.SpellId = fields[1].Get<uint32>();
            spell.Level = fields[2].Get<uint8>();
            spell.Core = fields[3].Get<uint8>();
            spell.Optimal = fields[4].Get<uint8>();
            spell.Empowering = fields[5].Get<uint8>();
            spell.Synergistic = fields[6].Get<uint8>();
            spell.Flags = fields[7].Get<uint32>();
            spell.Comment = fields[8].Get<std::string>();
        } while (result->NextRow());
    }

    if (PreparedQueryResult result = CharacterDatabase.Query(
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_BUILD_CREATOR_ENCHANTS)))
    {
        do
        {
            Field* fields = result->Fetch();
            auto const build = Builds.find(fields[0].Get<uint32>());
            if (build == Builds.end())
                continue;
            Enchant& enchant = build->second.Enchants.emplace_back();
            enchant.EnchantId = fields[1].Get<uint32>();
            enchant.Stacks = fields[2].Get<uint32>();
            enchant.Level = fields[3].Get<uint8>();
            enchant.Flags = fields[4].Get<uint32>();
            enchant.Comment = fields[5].Get<std::string>();
        } while (result->NextRow());
    }

    if (PreparedQueryResult result = CharacterDatabase.Query(
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_BUILD_CREATOR_ITEM_TYPES)))
    {
        do
        {
            Field* fields = result->Fetch();
            auto const build = Builds.find(fields[0].Get<uint32>());
            if (build == Builds.end())
                continue;
            std::vector<ItemType>& types = fields[1].Get<uint8>() ? build->second.Armor : build->second.Weapons;
            types.push_back({ fields[2].Get<uint8>(), fields[3].Get<std::string>() });
        } while (result->NextRow());
    }

    if (PreparedQueryResult result = CharacterDatabase.Query(
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_BUILD_CREATOR_VOTES)))
    {
        do
        {
            Field* fields = result->Fetch();
            Votes[fields[0].Get<uint32>()].insert(fields[1].Get<uint32>());
        } while (result->NextRow());
    }

    for (auto const& [entry, build] : Builds)
    {
        Entries[build.Id] = entry;
        NextEntry = std::max(NextEntry, entry + 1);
    }
    LOG_INFO("server.loading", ">> Loaded {} Hero Architect builds", Builds.size());
}

void Persist(uint32 entry, Build const& build)
{
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    CharacterDatabasePreparedStatement* statement =
        CharacterDatabase.GetPreparedStatement(CHAR_REP_COA_BUILD_CREATOR_BUILD);
    statement->SetData(0, entry);
    statement->SetData(1, build.Id);
    statement->SetData(2, build.LevelingId);
    statement->SetData(3, build.PveId);
    statement->SetData(4, build.PvpId);
    statement->SetData(5, uint8(build.Class));
    statement->SetData(6, build.OwnerAccount);
    statement->SetData(7, build.Author);
    statement->SetData(8, build.Name);
    statement->SetData(9, build.Subtext);
    statement->SetData(10, build.Description);
    statement->SetData(11, build.Icon);
    statement->SetData(12, build.Upvotes);
    statement->SetData(13, build.Created);
    statement->SetData(14, build.Updated);
    statement->SetData(15, uint8(build.Category));
    statement->SetData(16, uint8(build.Roles));
    statement->SetData(17, uint8(build.PrimaryStat));
    statement->SetData(18, build.NeedsRepairs);
    statement->SetData(19, build.Flags);
    statement->SetData(20, uint8(build.Difficulty));
    transaction->Append(statement);

    for (CharacterDatabaseStatements remove : { CHAR_DEL_COA_BUILD_CREATOR_SPELLS, CHAR_DEL_COA_BUILD_CREATOR_ENCHANTS,
        CHAR_DEL_COA_BUILD_CREATOR_ITEM_TYPES })
    {
        statement = CharacterDatabase.GetPreparedStatement(remove);
        statement->SetData(0, entry);
        transaction->Append(statement);
    }

    for (std::size_t slot = 0; slot < build.Spells.size(); ++slot)
    {
        Spell const& spell = build.Spells[slot];
        statement = CharacterDatabase.GetPreparedStatement(CHAR_INS_COA_BUILD_CREATOR_SPELL);
        statement->SetData(0, entry);
        statement->SetData(1, uint16(slot));
        statement->SetData(2, spell.SpellId);
        statement->SetData(3, uint8(spell.Level));
        statement->SetData(4, spell.Core);
        statement->SetData(5, spell.Optimal);
        statement->SetData(6, spell.Empowering);
        statement->SetData(7, spell.Synergistic);
        statement->SetData(8, spell.Flags);
        statement->SetData(9, spell.Comment);
        transaction->Append(statement);
    }

    for (std::size_t slot = 0; slot < build.Enchants.size(); ++slot)
    {
        Enchant const& enchant = build.Enchants[slot];
        statement = CharacterDatabase.GetPreparedStatement(CHAR_INS_COA_BUILD_CREATOR_ENCHANT);
        statement->SetData(0, entry);
        statement->SetData(1, uint16(slot));
        statement->SetData(2, enchant.EnchantId);
        statement->SetData(3, enchant.Stacks);
        statement->SetData(4, uint8(enchant.Level));
        statement->SetData(5, enchant.Flags);
        statement->SetData(6, enchant.Comment);
        transaction->Append(statement);
    }

    for (uint8 armor = 0; armor < 2; ++armor)
    {
        std::vector<ItemType> const& types = armor ? build.Armor : build.Weapons;
        for (std::size_t slot = 0; slot < types.size(); ++slot)
        {
            statement = CharacterDatabase.GetPreparedStatement(CHAR_INS_COA_BUILD_CREATOR_ITEM_TYPE);
            statement->SetData(0, entry);
            statement->SetData(1, armor);
            statement->SetData(2, uint8(slot));
            statement->SetData(3, uint8(types[slot].Type));
            statement->SetData(4, types[slot].Comment);
            transaction->Append(statement);
        }
    }
    CharacterDatabase.CommitTransaction(transaction);
}

void Erase(uint32 entry)
{
    CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
    for (CharacterDatabaseStatements remove : { CHAR_DEL_COA_BUILD_CREATOR_BUILD, CHAR_DEL_COA_BUILD_CREATOR_SPELLS,
        CHAR_DEL_COA_BUILD_CREATOR_ENCHANTS, CHAR_DEL_COA_BUILD_CREATOR_ITEM_TYPES, CHAR_DEL_COA_BUILD_CREATOR_VOTES })
    {
        CharacterDatabasePreparedStatement* statement = CharacterDatabase.GetPreparedStatement(remove);
        statement->SetData(0, entry);
        transaction->Append(statement);
    }
    CharacterDatabase.CommitTransaction(transaction);
}

Publisher Describe(Player const* player)
{
    Publisher publisher;
    publisher.Account = player->GetSession()->GetAccountId();
    publisher.Class = player->getClass();
    publisher.Gm = player->GetSession()->GetSecurity() > SEC_PLAYER;
    publisher.MaxLevel = sWorld->getIntConfig(CONFIG_MAX_PLAYER_LEVEL);
    return publisher;
}

bool KnownSpell(uint32 spell)
{
    return sSpellMgr->GetSpellInfo(spell) != nullptr;
}

std::string NewId()
{
    std::string id;
    do
        id = FormatId({ rand32(), rand32(), rand32(), rand32() });
    while (Entries.contains(id));
    return id;
}

void Send(Player* player, WorldPacket const& packet)
{
    player->GetSession()->SendPacket(&packet);
}

void SendText(Player* player, uint16 opcode, char const* text)
{
    WorldPacket packet(opcode, 40);
    packet << text;
    Send(player, packet);
}

void SendIds(Player* player, uint16 opcode, std::vector<std::string> const& ids)
{
    WorldPacket packet(opcode, 4 + ids.size() * (ID_LENGTH + 1));
    packet << uint32(ids.size());
    for (std::string const& id : ids)
        packet << id;
    Send(player, packet);
}

void SendAccountLists(Player* player)
{
    uint32 const account = player->GetSession()->GetAccountId();
    std::vector<std::string> owned;
    std::vector<std::string> upvoted;
    {
        std::lock_guard<std::mutex> lock(CatalogLock);
        for (auto const& [entry, build] : Builds)
        {
            if (build.OwnerAccount == account)
                owned.push_back(build.Id);
            auto const voters = Votes.find(entry);
            if (voters != Votes.end() && voters->second.contains(account))
                upvoted.push_back(build.Id);
        }
    }
    SendIds(player, SMSG_OWNED_BUILDS, owned);
    SendIds(player, SMSG_UPVOTED_BUILDS, upvoted);
}

void SendActiveBuilds(Player* player, ActiveBuilds const& active)
{
    WorldPacket packet(SMSG_ACTIVE_BUILDS, 4 + active.size() * (ID_LENGTH + 3));
    packet << uint32(active.size());
    for (ActiveBuild const& build : active)
        WriteActiveBuild(packet, build);
    Send(player, packet);
}

void SendActiveBuild(Player* player, uint32 spec, ActiveBuild const& active)
{
    WorldPacket packet(SMSG_ACTIVE_BUILD, 4 + ID_LENGTH + 3);
    packet << spec;
    WriteActiveBuild(packet, active);
    Send(player, packet);
}

void LoadActiveBuilds(Player* player)
{
    CharacterDatabasePreparedStatement* statement =
        CharacterDatabase.GetPreparedStatement(CHAR_SEL_COA_BUILD_CREATOR_ACTIVE);
    statement->SetData(0, player->GetGUID().GetCounter());
    WorldSession* session = player->GetSession();
    ObjectGuid const guid = player->GetGUID();
    session->GetQueryProcessor().AddCallback(CharacterDatabase.AsyncQuery(statement)
        .WithPreparedCallback([session, guid](PreparedQueryResult result)
        {
            Player* owner = session->GetPlayer();
            if (!owner || owner->GetGUID() != guid)
                return;
            ActiveBuilds active;
            if (result)
            {
                do
                {
                    Field* fields = result->Fetch();
                    uint8 const spec = fields[0].Get<uint8>();
                    if (spec >= active.size())
                        continue;
                    active[spec].Id = fields[1].Get<std::string>();
                    active[spec].Flags = { fields[2].Get<uint8>(), fields[3].Get<uint8>() };
                } while (result->NextRow());
            }
            {
                std::lock_guard<std::mutex> lock(ActiveLock);
                Active[guid] = active;
            }
            SendActiveBuilds(owner, active);
        }));
}

void StoreActiveBuild(Player* player, uint32 spec, ActiveBuild const& active)
{
    CharacterDatabasePreparedStatement* statement = nullptr;
    if (active.Id.empty())
    {
        statement = CharacterDatabase.GetPreparedStatement(CHAR_DEL_COA_BUILD_CREATOR_ACTIVE);
        statement->SetData(0, player->GetGUID().GetCounter());
        statement->SetData(1, uint8(spec));
    }
    else
    {
        statement = CharacterDatabase.GetPreparedStatement(CHAR_REP_COA_BUILD_CREATOR_ACTIVE);
        statement->SetData(0, player->GetGUID().GetCounter());
        statement->SetData(1, uint8(spec));
        statement->SetData(2, active.Id);
        statement->SetData(3, active.Flags[0]);
        statement->SetData(4, active.Flags[1]);
    }
    CharacterDatabase.Execute(statement);
}

void AutoLearn(Player* player, ActiveBuild const& active)
{
    if (!active.Flags[0] || !AscensionFreepick::HasFreepickBuild(player))
        return;
    std::vector<AscensionFreepick::GuideSpell> spells;
    std::vector<AscensionMysticEnchant::GuideEnchant> enchants;
    uint32 primaryStat = 0;
    {
        std::lock_guard<std::mutex> lock(CatalogLock);
        Build const* build = Find(active.Id);
        if (!build)
            return;
        for (Spell const& spell : build->Spells)
            spells.push_back({ spell.SpellId, spell.Level });
        for (Enchant const& enchant : build->Enchants)
            enchants.push_back({ enchant.EnchantId, enchant.Stacks, enchant.Level });
        primaryStat = build->PrimaryStat;
    }
    AscensionFreepick::UploadResult const result = AscensionFreepick::ApplyGuide(player, spells, primaryStat);
    if (std::string_view(result.Result) == AscensionFreepick::UPDATE_RESULTS[AscensionFreepick::UPDATE_NOT_TRAVERSIBLE] &&
        (player->IsInCombat() || !player->IsAlive()))
    {
        std::lock_guard<std::mutex> lock(ActiveLock);
        DeferredAutoLearn.insert(player->GetGUID());
        AnyDeferred = true;
    }
    bool const enchanted = AscensionMysticEnchant::ApplyGuide(player, enchants);
    LOG_INFO("coa", "Hero Architect auto-learn of {} for {} at level {}: {} {} entry {} rank {}, enchants {}", active.Id,
        player->GetName(), player->GetLevel(), result.Result, result.Learn, result.EntryId, result.Rank,
        enchanted ? "changed" : "unchanged");
}

ActiveBuild CurrentActiveBuild(Player const* player)
{
    std::lock_guard<std::mutex> lock(ActiveLock);
    auto const itr = Active.find(player->GetGUID());
    return itr == Active.end() ? ActiveBuild() : itr->second[AscensionFreepick::ActiveSpecialization(player)];
}

void HandleActivate(Player* player, WorldPacket& packet)
{
    std::string id;
    uint8 first = 0;
    uint8 second = 0;
    packet >> id >> first >> second;
    uint32 const spec = AscensionFreepick::ActiveSpecialization(player);
    ActiveBuild const next = { id, { first, second } };
    uint32 result = ACTIVATE_FAILED;
    uint32 progress = 0;
    {
        std::lock_guard<std::mutex> activeLock(ActiveLock);
        ActiveBuild& current = Active[player->GetGUID()][spec];
        {
            std::lock_guard<std::mutex> catalogLock(CatalogLock);
            Build const* build = Find(id);
            result = Activate(build, player->getClass(), current.Id);
            progress = ActivationProgress(build);
        }
        if (result == ACTIVATE_OK)
            current = next;
    }
    if (result == ACTIVATE_OK)
    {
        StoreActiveBuild(player, spec, next);
        SendActiveBuild(player, spec, next);
        AutoLearn(player, next);
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::BuildActivated, progress);
    }
    SendText(player, SMSG_ACTIVATE_BUILD_RESULT, ACTIVATE_RESULTS[result]);
}

void HandleDeactivate(Player* player, WorldPacket& packet)
{
    std::string id;
    packet >> id;
    uint32 const spec = AscensionFreepick::ActiveSpecialization(player);
    bool exists = false;
    {
        std::lock_guard<std::mutex> lock(CatalogLock);
        exists = Find(id) != nullptr;
    }
    uint32 result = DEACTIVATE_FAILED;
    {
        std::lock_guard<std::mutex> lock(ActiveLock);
        ActiveBuild& current = Active[player->GetGUID()][spec];
        result = Deactivate(exists, id, current.Id);
        if (result == DEACTIVATE_OK)
            current = {};
    }
    if (result == DEACTIVATE_OK)
    {
        StoreActiveBuild(player, spec, {});
        SendActiveBuild(player, spec, {});
    }
    SendText(player, SMSG_DEACTIVATE_BUILD_RESULT, DEACTIVATE_RESULTS[result]);
}

void HandleQueryCategory(Player* player, WorldPacket& packet)
{
    std::string name;
    packet >> name;
    std::optional<uint32> const category = CategoryIndex(name);
    sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::ArchitectOpened, category.value_or(0));
    std::vector<ByteBuffer> entries;
    {
        std::lock_guard<std::mutex> lock(CatalogLock);
        if (category)
            for (auto const& [entry, build] : Builds)
                if (InCategory(build, *category))
                    WriteBuild(entries.emplace_back(), build);
    }

    std::vector<std::size_t> sizes;
    for (ByteBuffer const& data : entries)
        sizes.push_back(data.size());
    std::vector<std::pair<std::size_t, std::size_t>> const pages = Pages(sizes, PAGE_BYTES);
    for (std::size_t page = 0; page < pages.size(); ++page)
    {
        auto const [first, last] = pages[page];
        WorldPacket response(SMSG_REQUEST_BUILD_DATAS_RESULT, PAGE_BYTES + 16);
        response << "" << uint32(page) << uint32(pages.size()) << uint32(last - first);
        for (std::size_t index = first; index < last; ++index)
            response.append(entries[index]);
        Send(player, response);
    }
}

void HandleQueryBuild(Player* player, WorldPacket& packet)
{
    std::string id;
    packet >> id;
    WorldPacket response(SMSG_REQUEST_BUILD_DATA_RESULT, 1024);
    response << "";
    std::lock_guard<std::mutex> lock(CatalogLock);
    if (Build const* build = Find(id))
        WriteBuild(response, *build);
    else
    {
        Build missing;
        missing.Id = id;
        WriteBuild(response, missing);
    }
    Send(player, response);
}

void HandleCreate(Player* player, WorldPacket& packet)
{
    std::optional<Build> const submitted = ReadBuild(packet);
    Publisher const publisher = Describe(player);
    uint32 const result = submitted ? ValidateContent(*submitted, publisher, KnownSpell) : uint32(PUBLISH_UNKNOWN);
    WorldPacket response(SMSG_CREATE_BUILD_RESULT, 1024);
    response << PUBLISH_RESULTS[result];
    if (result == PUBLISH_OK)
    {
        uint64 const now = GameTime::GetGameTime().count();
        Build build;
        build.Class = publisher.Class;
        build.OwnerAccount = publisher.Account;
        build.Author = player->GetName();
        build.Created = now;
        Publish(build, *submitted, publisher, now);
        uint32 entry = 0;
        {
            std::lock_guard<std::mutex> lock(CatalogLock);
            build.Id = NewId();
            entry = NextEntry++;
            Builds[entry] = build;
            Entries[build.Id] = entry;
        }
        Persist(entry, build);
        WriteBuild(response, build);
    }
    Send(player, response);
}

void HandleSave(Player* player, WorldPacket& packet)
{
    std::optional<Build> const submitted = ReadBuild(packet);
    Publisher const publisher = Describe(player);
    WorldPacket response(SMSG_SAVE_BUILD_RESULT, 1024);
    if (!submitted)
    {
        response << PUBLISH_RESULTS[PUBLISH_UNKNOWN] << "";
        Send(player, response);
        return;
    }

    std::lock_guard<std::mutex> lock(CatalogLock);
    Build* existing = Find(submitted->Id);
    uint32 result = ValidateEdit(existing, publisher);
    if (result == PUBLISH_OK)
        result = ValidateContent(*submitted, publisher, KnownSpell);
    response << PUBLISH_RESULTS[result];
    if (result != PUBLISH_OK)
        response << submitted->Id;
    else
    {
        Publish(*existing, *submitted, publisher, GameTime::GetGameTime().count());
        Persist(Entries.at(existing->Id), *existing);
        WriteBuild(response, *existing);
    }
    Send(player, response);
}

void HandleRate(Player* player, WorldPacket& packet)
{
    std::string id;
    uint8 up = 0;
    packet >> id >> up;
    uint32 const account = player->GetSession()->GetAccountId();
    uint32 result = RATE_NOT_FOUND;
    {
        std::lock_guard<std::mutex> lock(CatalogLock);
        Build* build = Find(id);
        uint32 const entry = build ? Entries.at(id) : 0;
        std::unordered_set<uint32>& voters = Votes[entry];
        result = Rate(build != nullptr, voters.contains(account), up != 0);
        if (result == RATE_OK)
        {
            CharacterDatabasePreparedStatement* statement = CharacterDatabase.GetPreparedStatement(
                up ? CHAR_INS_COA_BUILD_CREATOR_VOTE : CHAR_DEL_COA_BUILD_CREATOR_VOTE);
            statement->SetData(0, entry);
            statement->SetData(1, account);
            CharacterDatabase.Execute(statement);
            if (up)
            {
                voters.insert(account);
                ++build->Upvotes;
            }
            else
            {
                voters.erase(account);
                build->Upvotes -= build->Upvotes ? 1 : 0;
            }
            statement = CharacterDatabase.GetPreparedStatement(CHAR_UPD_COA_BUILD_CREATOR_UPVOTES);
            statement->SetData(0, build->Upvotes);
            statement->SetData(1, entry);
            CharacterDatabase.Execute(statement);
        }
        if (!build)
            Votes.erase(entry);
    }
    SendText(player, SMSG_RATE_BUILD_RESULT, RATE_RESULTS[result]);
}

void HandleDelete(Player* player, WorldPacket& packet)
{
    std::string id;
    packet >> id;
    Publisher const publisher = Describe(player);
    uint32 result = DELETE_NOT_FOUND;
    {
        std::lock_guard<std::mutex> lock(CatalogLock);
        result = Delete(Find(id), publisher.Account, publisher.Gm);
        if (result == DELETE_OK)
        {
            uint32 const entry = Entries.at(id);
            Builds.erase(entry);
            Entries.erase(id);
            Votes.erase(entry);
            Erase(entry);
        }
    }
    SendText(player, SMSG_DELETE_BUILD_RESULT, DELETE_RESULTS[result]);
}

void Handle(Player* player, WorldPacket& packet)
{
    packet.rpos(0);
    switch (packet.GetOpcode())
    {
        case CMSG_ACTIVATE_BUILD: HandleActivate(player, packet); break;
        case CMSG_DEACTIVATE_BUILD: HandleDeactivate(player, packet); break;
        case CMSG_REQUEST_BUILD_DATAS: HandleQueryCategory(player, packet); break;
        case CMSG_REQUEST_BUILD_DATA: HandleQueryBuild(player, packet); break;
        case CMSG_CREATE_BUILD: HandleCreate(player, packet); break;
        case CMSG_SAVE_BUILD: HandleSave(player, packet); break;
        case CMSG_RATE_BUILD: HandleRate(player, packet); break;
        case CMSG_DELETE_BUILD: HandleDelete(player, packet); break;
        default: break;
    }
}

bool QueueRequest(WorldSession* session, WorldPacket const& packet)
{
    if (!session)
        return true;
    std::lock_guard<std::mutex> lock(PendingLock);
    std::deque<WorldPacket>& queue = PendingRequests[session];
    if (queue.size() < MAX_QUEUED_REQUESTS)
        queue.push_back(packet);
    AnyPending = true;
    return true;
}

class AscensionBuildCreatorPlayer final : public PlayerScript
{
public:
    AscensionBuildCreatorPlayer() : PlayerScript("AscensionBuildCreatorPlayer", { PLAYERHOOK_ON_LOGIN,
        PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_DELETE_FROM_DB, PLAYERHOOK_ON_LEVEL_CHANGED }) { }

    void OnPlayerLevelChanged(Player* player, uint8 oldLevel) override
    {
        if (player->GetLevel() > oldLevel)
            AutoLearn(player, CurrentActiveBuild(player));
    }

    void OnPlayerLogin(Player* player) override
    {
        SendAccountLists(player);
        LoadActiveBuilds(player);
    }

    void OnPlayerDeleteFromDB(CharacterDatabaseTransaction transaction, uint32 guid) override
    {
        CharacterDatabasePreparedStatement* statement =
            CharacterDatabase.GetPreparedStatement(CHAR_DEL_COA_BUILD_CREATOR_ACTIVE_ALL);
        statement->SetData(0, guid);
        transaction->Append(statement);
    }

    void OnPlayerLogout(Player* player) override
    {
        {
            std::lock_guard<std::mutex> lock(ActiveLock);
            Active.erase(player->GetGUID());
            DeferredAutoLearn.erase(player->GetGUID());
            AnyDeferred = !DeferredAutoLearn.empty();
        }
        std::lock_guard<std::mutex> lock(PendingLock);
        PendingRequests.erase(player->GetSession());
        AnyPending = !PendingRequests.empty();
    }

    void OnPlayerUpdate(Player* player, uint32) override
    {
        if (AnyDeferred && !player->IsInCombat() && player->IsAlive())
        {
            bool deferred = false;
            {
                std::lock_guard<std::mutex> lock(ActiveLock);
                deferred = DeferredAutoLearn.erase(player->GetGUID()) != 0;
                AnyDeferred = !DeferredAutoLearn.empty();
            }
            if (deferred)
                AutoLearn(player, CurrentActiveBuild(player));
        }
        if (!AnyPending)
            return;
        std::deque<WorldPacket> requests;
        {
            std::lock_guard<std::mutex> lock(PendingLock);
            auto itr = PendingRequests.find(player->GetSession());
            if (itr == PendingRequests.end())
                return;
            requests = std::move(itr->second);
            PendingRequests.erase(itr);
            AnyPending = !PendingRequests.empty();
        }
        for (WorldPacket& packet : requests)
        {
            try
            {
                Handle(player, packet);
            }
            catch (ByteBufferException const&)
            {
                LOG_INFO("coa", "Dropped a malformed build creator request 0x{:04X} from {}", packet.GetOpcode(),
                    player->GetName());
            }
        }
    }
};

class AscensionBuildCreatorWorld final : public WorldScript
{
public:
    AscensionBuildCreatorWorld() : WorldScript("AscensionBuildCreatorWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        LoadCatalog();
    }
};
}
}

void AddAscensionBuildCreatorScripts()
{
    for (uint16 opcode : AscensionBuildCreator::CLIENT_OPCODES)
        AscensionCompatOpcodes::Claim(opcode, &AscensionBuildCreator::QueueRequest);
    new AscensionBuildCreator::AscensionBuildCreatorPlayer();
    new AscensionBuildCreator::AscensionBuildCreatorWorld();
}
