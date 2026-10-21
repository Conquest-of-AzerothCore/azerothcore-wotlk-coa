/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "DBCStores.h"
#include "GameObject.h"
#include "GameObjectScript.h"
#include "GlobalScript.h"
#include "GossipDef.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "WorldSession.h"
#include <array>

namespace
{
enum TravelPermit : uint32
{
    ItemTravelPermit = 977028,
    SenderTravelPermit = 977028,
    MaxTravelLevel = 8
};

enum HomeboundPortal : uint32
{
    SpellHomeboundPortal = 93187,
    GameObjectHomeboundPortal = 80775
};

struct Destination
{
    char const* name;
    char const* icon;
    TeamId team;
    uint8 race;
    uint32 mapId;
    float x;
    float y;
    float z;
    float orientation;
};

constexpr uint32 ICON_SIZE = 40;

constexpr std::array<Destination, 6> Destinations =
{{
    {"Elwynn Forest", "Spell_Arcane_TeleportStormWind", TEAM_ALLIANCE, RACE_HUMAN, 0, -8949.95f, -132.493f, 83.5312f, 0.0f},
    {"Dun Morogh", "Spell_Arcane_TeleportIronForge", TEAM_ALLIANCE, RACE_DWARF, 0, -6240.32f, 331.033f, 382.758f, 6.17716f},
    {"Teldrassil", "Spell_Arcane_TeleportDarnassus", TEAM_ALLIANCE, RACE_NIGHTELF, 1, 10311.3f, 832.463f, 1326.41f, 5.69632f},
    {"Tirisfal Glades", "Spell_Arcane_TeleportUnderCity", TEAM_HORDE, RACE_UNDEAD_PLAYER, 0, 1676.71f, 1678.31f, 121.67f, 2.70526f},
    {"Durotar", "Spell_Arcane_TeleportOrgrimmar", TEAM_HORDE, RACE_ORC, 1, -618.518f, -4251.67f, 38.718f, 0.0f},
    {"Mulgore", "Spell_Arcane_TeleportThunderBluff", TEAM_HORDE, RACE_TAUREN, 1, -2917.58f, -257.98f, 52.9968f, 0.0f}
}};

SpellCastResult CheckTravel(Player const* player)
{
    if (!player || !player->IsAlive())
        return SPELL_FAILED_CASTER_DEAD;
    if (player->GetLevel() > MaxTravelLevel)
        return SPELL_FAILED_HIGHLEVEL;
    if (player->IsInCombat())
        return SPELL_FAILED_AFFECTING_COMBAT;
    return SPELL_CAST_OK;
}

bool IsOffered(Player const* player, Destination const& destination)
{
    MapEntry const* map = sMapStore.LookupEntry(destination.mapId);
    return destination.team == player->GetTeamId() && map && map->Expansion() <= player->GetSession()->Expansion() &&
        sObjectMgr->GetPlayerInfo(destination.race, player->getClass());
}

std::string OptionText(Destination const& destination)
{
    return Acore::StringFormat("|TInterface/ICONS/{}:{}:{}:-{}:0|t|r{}", destination.icon, ICON_SIZE, ICON_SIZE,
        ICON_SIZE / 2 + 2, destination.name);
}

class spell_ascension_travel_permit : public SpellScript
{
    PrepareSpellScript(spell_ascension_travel_permit);

    bool Load() override
    {
        return GetCaster()->ToPlayer() && GetCastItem() && GetCastItem()->GetEntry() == ItemTravelPermit;
    }

    SpellCastResult CheckCast()
    {
        return CheckTravel(GetCaster()->ToPlayer());
    }

    void OpenMenu()
    {
        Player* player = GetCaster()->ToPlayer();
        Item* item = GetCastItem();
        if (!item || CheckTravel(player) != SPELL_CAST_OK)
            return;
        ClearGossipMenuFor(player);
        for (uint32 i = 0; i < Destinations.size(); ++i)
            if (IsOffered(player, Destinations[i]))
                AddGossipItemFor(player, GOSSIP_ICON_TAXI, OptionText(Destinations[i]), SenderTravelPermit, i);
        SendGossipMenuFor(player, DEFAULT_GOSSIP_MESSAGE, item->GetGUID());
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_travel_permit::CheckCast);
        AfterCast += SpellCastFn(spell_ascension_travel_permit::OpenMenu);
    }
};

class spell_ascension_homebound_portal : public SpellScript
{
    PrepareSpellScript(spell_ascension_homebound_portal);

    void SendToOwnerHearth(SpellEffIndex)
    {
        Player* traveller = GetCaster()->ToPlayer();
        GameObject* portal = GetHitGObj();
        if (!traveller || !portal || portal->GetEntry() != GameObjectHomeboundPortal)
            return;
        Player* owner = ObjectAccessor::FindConnectedPlayer(portal->GetOwnerGUID());
        if (!owner)
            return;
        traveller->TeleportTo(owner->m_homebindMapId, owner->m_homebindX, owner->m_homebindY, owner->m_homebindZ,
            traveller->GetOrientation());
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_homebound_portal::SendToOwnerHearth, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class AscensionHomeboundPortalContract : public GlobalScript
{
public:
    AscensionHomeboundPortalContract()
        : GlobalScript("AscensionHomeboundPortalContract", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* spellInfo) override
    {
        if (spellInfo->Id == SpellHomeboundPortal)
            spellInfo->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_GAMEOBJECT_TARGET);
    }
};

class go_ascension_homebound_portal : public GameObjectScript
{
public:
    go_ascension_homebound_portal() : GameObjectScript("go_ascension_homebound_portal") { }

    bool OnGossipHello(Player* traveller, GameObject* portal) override
    {
        traveller->CastSpell(portal, SpellHomeboundPortal, false);
        return true;
    }
};

class item_ascension_travel_permit : public ItemScript
{
public:
    item_ascension_travel_permit() : ItemScript("item_ascension_travel_permit") { }

    void OnGossipSelect(Player* player, Item* item, uint32 sender, uint32 action) override
    {
        if (!player || !item || item->GetEntry() != ItemTravelPermit || sender != SenderTravelPermit)
            return;
        CloseGossipMenuFor(player);
        ClearGossipMenuFor(player);
        if (action >= Destinations.size() || CheckTravel(player) != SPELL_CAST_OK)
            return;
        Destination const& destination = Destinations[action];
        if (IsOffered(player, destination) &&
            player->TeleportTo(destination.mapId, destination.x, destination.y, destination.z, destination.orientation))
            player->DestroyItemCount(ItemTravelPermit, 1, true);
    }
};

class travel_permit_grant : public PlayerScript
{
public:
    travel_permit_grant() : PlayerScript("travel_permit_grant", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player* player) override
    {
        if (!player || player->GetLevel() > MaxTravelLevel || player->HasItemCount(ItemTravelPermit, 1, true))
            return;
        ItemPosCountVec destinations;
        if (player->CanStoreNewItem(NULL_BAG, NULL_SLOT, destinations, ItemTravelPermit, 1) != EQUIP_ERR_OK)
            return;
        player->StoreNewItem(destinations, ItemTravelPermit, true);
    }
};
}

void AddAscensionTravelPermitScripts()
{
    RegisterSpellScript(spell_ascension_travel_permit);
    RegisterSpellScript(spell_ascension_homebound_portal);
    new AscensionHomeboundPortalContract();
    new go_ascension_homebound_portal();
    new item_ascension_travel_permit();
    new travel_permit_grant();
}
