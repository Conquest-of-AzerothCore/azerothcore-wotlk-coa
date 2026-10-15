/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Chat.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Group.h"
#include "Item.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "StringFormat.h"
#include <algorithm>
#include <mutex>
#include <vector>

namespace
{
struct ZoneScrollEntry
{
    uint32 ItemEntry;
    uint32 SpellId;
    char const* Name;
};

constexpr ZoneScrollEntry kZoneScrolls[] = {
    { 696661, 993961, "Golganneth" },
    { 696662, 993943, "Norgannon" },
    { 696663, 993955, "Khaz'goroth" },
    { 696664, 993959, "Aggramar" },
    { 696665, 993957, "Eonar" },
    { 1179240, 91770, "Steadfast" },
    { 1179261, 91796, "Featherfall" },
    { 1179266, 91803, "Ghost Runner" },
    { 1179269, 91814, "Crafting Speed" },
};

uint32 SpellForItem(uint32 itemEntry)
{
    for (ZoneScrollEntry const& entry : kZoneScrolls)
        if (entry.ItemEntry == itemEntry)
            return entry.SpellId;
    return 0;
}

constexpr char const* ANNOUNCE_TAG_COLOR = "ffa54a";

std::string ItemIcon(ItemTemplate const* proto)
{
    ItemDisplayInfoEntry const* display = sItemDisplayInfoStore.LookupEntry(proto->DisplayInfoID);
    if (!display || !display->inventoryIcon || !*display->inventoryIcon)
        return "";
    return Acore::StringFormat("|TInterface\\Icons\\{}:20:20|t ", display->inventoryIcon);
}

std::string ZoneBlessingAnnouncement(Player const* player, ItemTemplate const* proto, SpellInfo const* spellInfo)
{
    std::string icon = ItemIcon(proto);
    return Acore::StringFormat(
        "{}|cff{}[Keeper's Scroll]|r {}{} used their |c{:08x}|Hitem:{}:0:0:0:0:0:0:0:0:0|h[{}]|h|r "
        "to buff the zone with |cff71d5ff|Hspell:{}|h[{}]|h|r!",
        icon, ANNOUNCE_TAG_COLOR, icon, player->GetName(), ItemQualityColors[proto->Quality], proto->ItemId,
        proto->Name1, spellInfo->Id, spellInfo->SpellName[LOCALE_enUS]);
}

struct ZoneBlessing
{
    uint32 ZoneId;
    uint32 InstanceId;
    uint32 SpellId;
    ObjectGuid Caster;
    TeamId CasterTeam;
    time_t ExpireAt;
};

std::mutex g_zoneScrollLock;
std::vector<ZoneBlessing> g_zoneBlessings;

bool SharesBlessing(Player const* player, ZoneBlessing const& blessing)
{
    if (player->GetTeamId() == blessing.CasterTeam || player->GetGUID() == blessing.Caster)
        return true;
    Group const* group = player->GetGroup();
    return group && group->IsMember(blessing.Caster);
}

time_t BlessingExpiry(Player const* player, uint32 zoneId, uint32 spellId)
{
    time_t expiry = 0;
    std::lock_guard<std::mutex> lock(g_zoneScrollLock);
    for (ZoneBlessing const& blessing : g_zoneBlessings)
        if (blessing.ZoneId == zoneId && blessing.InstanceId == player->GetInstanceId() &&
            blessing.SpellId == spellId && blessing.ExpireAt > expiry && SharesBlessing(player, blessing))
            expiry = blessing.ExpireAt;
    return expiry;
}

void ApplyZoneScrollAura(Player* player, uint32 spellId, int32 remainingMs)
{
    if (remainingMs <= 0)
        return;

    if (!player->HasAura(spellId))
        player->CastSpell(player, spellId, true);

    if (Aura* aura = player->GetAura(spellId))
    {
        aura->SetMaxDuration(remainingMs);
        aura->SetDuration(remainingMs);
    }
}

constexpr uint32 SPELL_KEEPERS_SCROLL_GHOST_RUNNER = 91803;
constexpr uint32 SPELL_GHOST_RUNNER_SPEED = 92417;

void SyncGhostRunner(Player* player)
{
    bool const wanted = player->HasPlayerFlag(PLAYER_FLAGS_GHOST) && player->HasAura(SPELL_KEEPERS_SCROLL_GHOST_RUNNER);
    if (wanted && !player->HasAura(SPELL_GHOST_RUNNER_SPEED))
        player->CastSpell(player, SPELL_GHOST_RUNNER_SPEED, true);
    else if (!wanted && player->HasAura(SPELL_GHOST_RUNNER_SPEED))
        player->RemoveAurasDueToSpell(SPELL_GHOST_RUNNER_SPEED);
}

void SyncZoneBlessings(Player* player, uint32 zoneId)
{
    time_t now = GameTime::GetGameTime().count();
    for (ZoneScrollEntry const& entry : kZoneScrolls)
    {
        time_t expiry = BlessingExpiry(player, zoneId, entry.SpellId);
        if (expiry > now)
            ApplyZoneScrollAura(player, entry.SpellId, int32((expiry - now) * 1000));
        else if (player->HasAura(entry.SpellId))
            player->RemoveAurasDueToSpell(entry.SpellId);
    }

    SyncGhostRunner(player);
}

void SaveBlessing(ZoneBlessing const& blessing)
{
    CharacterDatabase.Execute("REPLACE INTO coa_keepers_scroll_blessing (zone, instance, spell, caster, team, expire_at) "
        "VALUES ({}, {}, {}, {}, {}, {})", blessing.ZoneId, blessing.InstanceId, blessing.SpellId,
        blessing.Caster.GetCounter(), uint32(blessing.CasterTeam), uint32(blessing.ExpireAt));
}

void LoadBlessings()
{
    time_t now = GameTime::GetGameTime().count();
    CharacterDatabase.DirectExecute("DELETE FROM coa_keepers_scroll_blessing WHERE expire_at <= {}", uint32(now));
    QueryResult result = CharacterDatabase.Query(
        "SELECT zone, instance, spell, caster, team, expire_at FROM coa_keepers_scroll_blessing");
    if (!result)
        return;

    std::lock_guard<std::mutex> lock(g_zoneScrollLock);
    do
    {
        Field* fields = result->Fetch();
        g_zoneBlessings.push_back({fields[0].Get<uint32>(), fields[1].Get<uint32>(), fields[2].Get<uint32>(),
            ObjectGuid::Create<HighGuid::Player>(fields[3].Get<uint32>()), TeamId(fields[4].Get<uint8>()),
            time_t(fields[5].Get<uint32>())});
    } while (result->NextRow());
}

std::vector<ObjectGuid> g_pendingGroupSyncs;

void QueueGroupSync(Group const* group, ObjectGuid changedMember = ObjectGuid::Empty)
{
    std::lock_guard<std::mutex> lock(g_zoneScrollLock);
    for (Group::MemberSlot const& slot : group->GetMemberSlots())
        g_pendingGroupSyncs.push_back(slot.guid);
    if (changedMember)
        g_pendingGroupSyncs.push_back(changedMember);
}

class ascension_keepers_scroll_zone_buff_spell : public AllSpellScript
{
public:
    ascension_keepers_scroll_zone_buff_spell()
        : AllSpellScript("ascension_keepers_scroll_zone_buff_spell", {ALLSPELLHOOK_ON_BEFORE_EFFECTS}) { }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* spellInfo) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        Item* item = spell->m_CastItem;
        if (!player || !item || SpellForItem(item->GetEntry()) != spellInfo->Id)
            return;

        int32 durationMs = spellInfo->GetMaxDuration();
        if (durationMs <= 0)
            return;

        ZoneBlessing blessing{player->GetZoneId(), player->GetInstanceId(), spellInfo->Id, player->GetGUID(),
            player->GetTeamId(), GameTime::GetGameTime().count() + durationMs / 1000};
        {
            std::lock_guard<std::mutex> lock(g_zoneScrollLock);
            g_zoneBlessings.push_back(blessing);
        }
        SaveBlessing(blessing);

        std::string announcement = ZoneBlessingAnnouncement(player, item->GetTemplate(), spellInfo);
        for (MapReference const& ref : player->GetMap()->GetPlayers())
        {
            Player* recipient = ref.GetSource();
            if (!recipient->IsInWorld() || recipient->GetZoneId() != blessing.ZoneId ||
                !SharesBlessing(recipient, blessing))
                continue;

            if (recipient != player)
            {
                ApplyZoneScrollAura(recipient, spellInfo->Id, durationMs);
                SyncGhostRunner(recipient);
            }
            ChatHandler(recipient->GetSession()).SendSysMessage(announcement);
        }
    }
};

class ascension_keepers_scroll_zone_buff_player : public PlayerScript
{
public:
    ascension_keepers_scroll_zone_buff_player()
        : PlayerScript("ascension_keepers_scroll_zone_buff_player",
            {PLAYERHOOK_ON_UPDATE_ZONE, PLAYERHOOK_CAN_CAST_ITEM_USE_SPELL, PLAYERHOOK_ON_PLAYER_RELEASED_GHOST,
             PLAYERHOOK_ON_PLAYER_RESURRECT}) { }

    void OnPlayerReleasedGhost(Player* player) override
    {
        SyncGhostRunner(player);
    }

    void OnPlayerResurrect(Player* player, float, bool&) override
    {
        SyncGhostRunner(player);
    }

    bool OnPlayerCanCastItemUseSpell(Player* player, Item* item, SpellCastTargets const&,
        uint8 castCount, uint32) override
    {
        uint32 spellId = SpellForItem(item->GetEntry());
        if (!spellId)
            return true;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellId);
        if (!spellInfo || BlessingExpiry(player, player->GetZoneId(), spellId) <= GameTime::GetGameTime().count())
            return true;

        Spell::SendCastResult(player, spellInfo, castCount, SPELL_FAILED_AURA_BOUNCED);
        ChatHandler(player->GetSession()).PSendSysMessage(
            "{} is already active in this zone.", spellInfo->SpellName[LOCALE_enUS]);
        return false;
    }

    void OnPlayerUpdateZone(Player* player, uint32 newZone, uint32) override
    {
        SyncZoneBlessings(player, newZone);
    }
};

class ascension_keepers_scroll_zone_buff_group : public GroupScript
{
public:
    ascension_keepers_scroll_zone_buff_group()
        : GroupScript("ascension_keepers_scroll_zone_buff_group",
            {GROUPHOOK_ON_ADD_MEMBER, GROUPHOOK_ON_REMOVE_MEMBER, GROUPHOOK_ON_DISBAND}) { }

    void OnAddMember(Group* group, ObjectGuid) override
    {
        QueueGroupSync(group);
    }

    void OnRemoveMember(Group* group, ObjectGuid guid, RemoveMethod, ObjectGuid, char const*) override
    {
        QueueGroupSync(group, guid);
    }

    void OnDisband(Group* group) override
    {
        QueueGroupSync(group);
    }
};

class ascension_keepers_scroll_zone_buff_world : public WorldScript
{
public:
    ascension_keepers_scroll_zone_buff_world()
        : WorldScript("ascension_keepers_scroll_zone_buff_world", {WORLDHOOK_ON_STARTUP, WORLDHOOK_ON_UPDATE}) { }

    void OnStartup() override
    {
        LoadBlessings();
    }

    void OnUpdate(uint32 diff) override
    {
        SyncPendingGroups();

        _timer += diff;
        if (_timer < EXPIRE_CHECK_INTERVAL_MS)
            return;
        _timer = 0;

        time_t now = GameTime::GetGameTime().count();
        std::vector<ZoneBlessing> expired;

        {
            std::lock_guard<std::mutex> lock(g_zoneScrollLock);
            auto isExpired = [now](ZoneBlessing const& blessing) { return blessing.ExpireAt <= now; };
            std::copy_if(g_zoneBlessings.begin(), g_zoneBlessings.end(), std::back_inserter(expired), isExpired);
            std::erase_if(g_zoneBlessings, isExpired);
        }

        if (!expired.empty())
            CharacterDatabase.Execute("DELETE FROM coa_keepers_scroll_blessing WHERE expire_at <= {}", uint32(now));

        for (ZoneBlessing const& blessing : expired)
        {
            sMapMgr->DoForAllMaps([&blessing, now](Map* map)
            {
                if (map->GetInstanceId() != blessing.InstanceId)
                    return;

                for (MapReference const& ref : map->GetPlayers())
                {
                    Player* player = ref.GetSource();
                    if (!player->IsInWorld() || player->GetZoneId() != blessing.ZoneId ||
                        BlessingExpiry(player, blessing.ZoneId, blessing.SpellId) > now)
                        continue;

                    player->RemoveAurasDueToSpell(blessing.SpellId);
                    SyncGhostRunner(player);
                }
            });
        }
    }

private:
    static void SyncPendingGroups()
    {
        std::vector<ObjectGuid> pending;
        {
            std::lock_guard<std::mutex> lock(g_zoneScrollLock);
            pending.swap(g_pendingGroupSyncs);
        }

        for (ObjectGuid guid : pending)
            if (Player* player = ObjectAccessor::FindPlayer(guid))
                SyncZoneBlessings(player, player->GetZoneId());
    }

    uint32 _timer = 0;
    static constexpr uint32 EXPIRE_CHECK_INTERVAL_MS = 10000;
};
}

void AddSC_AscensionKeepersScrollZoneBuff()
{
    new ascension_keepers_scroll_zone_buff_spell();
    new ascension_keepers_scroll_zone_buff_player();
    new ascension_keepers_scroll_zone_buff_group();
    new ascension_keepers_scroll_zone_buff_world();
}
