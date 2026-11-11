/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionFlightMasters.h"
#include "DBCStores.h"
#include "GossipDef.h"
#include "Item.h"
#include "ItemScript.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "SpellScript.h"
#include "StringFormat.h"
#include "WorldSession.h"
#include <algorithm>
#include <cmath>
#include <string>
#include <vector>

namespace
{
enum SchmorgusBoard
{
    SPELL_WELL_FED_SPELL_POWER  = 966453,
    SPELL_WELL_FED_ATTACK_POWER = 966454,
};

enum FlightMastersWhistle : uint32
{
    SpellFlightMastersWhistleTeleport = 2485,
    SenderFlightMastersWhistle = 10,
    NpcTextFlightMastersWhistle = 9990158,
    WhistleChoices = 3,
};

constexpr char const* WhistleDestinationKey = "ascension_flight_masters_whistle_destination";

struct WhistleDestination final : DataMap::Base
{
    uint32 Node = 0;
};

std::vector<uint32> NearestFlightMasters(Player const* player)
{
    if (player->GetMap()->Instanceable())
        return {};
    return AscensionFlightMasters::NearestNodes(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(),
        player->GetMapId(), player->GetTeamId(), WhistleChoices);
}

std::string FlightMasterChoice(Player const* player, TaxiNodesEntry const* node)
{
    LocaleConstant const locale = player->GetSession()->GetSessionDbcLocale();
    std::string zone = node->name[locale];
    uint32 const zoneId = player->GetMap()->GetZoneId(PHASEMASK_NORMAL, node->x, node->y, node->z);
    if (AreaTableEntry const* area = sAreaTableStore.LookupEntry(zoneId))
        zone = area->area_name[locale];
    std::string master = "Flight Master";
    if (CreatureTemplate const* creature = sObjectMgr->GetCreatureTemplate(AscensionFlightMasters::MasterEntry(node->ID)))
        master = creature->Name;
    return Acore::StringFormat("{} ({} - {} units away)", zone, master,
        uint32(std::lround(player->GetExactDist(node->x, node->y, node->z))));
}

class spell_ascension_flight_masters_whistle : public SpellScript
{
    PrepareSpellScript(spell_ascension_flight_masters_whistle);

    SpellCastResult Check()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || NearestFlightMasters(player).empty())
            return SPELL_FAILED_NOT_HERE;
        return SPELL_CAST_OK;
    }

    void OfferFlightMasters()
    {
        Player* player = GetCaster()->ToPlayer();
        Item* whistle = GetCastItem();
        if (!player || !whistle)
            return;
        player->RemoveSpellCooldown(GetSpellInfo()->Id, true);
        ClearGossipMenuFor(player);
        for (uint32 node : NearestFlightMasters(player))
            if (TaxiNodesEntry const* entry = sTaxiNodesStore.LookupEntry(node))
                AddGossipItemFor(player, GOSSIP_ICON_TAXI, FlightMasterChoice(player, entry), SenderFlightMastersWhistle,
                    node);
        SendGossipMenuFor(player, NpcTextFlightMastersWhistle, whistle->GetGUID());
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_flight_masters_whistle::Check);
        AfterCast += SpellCastFn(spell_ascension_flight_masters_whistle::OfferFlightMasters);
    }
};

class spell_ascension_flight_masters_whistle_teleport : public SpellScript
{
    PrepareSpellScript(spell_ascension_flight_masters_whistle_teleport);

    TaxiNodesEntry const* ChosenFlightMaster()
    {
        Player* player = GetCaster()->ToPlayer();
        WhistleDestination const* destination =
            player ? player->CustomData.Get<WhistleDestination>(WhistleDestinationKey) : nullptr;
        if (!destination)
            return nullptr;
        std::vector<uint32> const nearest = NearestFlightMasters(player);
        if (std::find(nearest.begin(), nearest.end(), destination->Node) == nearest.end())
            return nullptr;
        return sTaxiNodesStore.LookupEntry(destination->Node);
    }

    SpellCastResult Check()
    {
        return ChosenFlightMaster() ? SPELL_CAST_OK : SPELL_FAILED_NOT_HERE;
    }

    void FlyToChosenFlightMaster(SpellDestination& destination)
    {
        if (TaxiNodesEntry const* node = ChosenFlightMaster())
            destination.Relocate({ node->x, node->y, node->z, GetCaster()->GetOrientation() });
    }

    void ForgetChoice()
    {
        if (Player* player = GetCaster()->ToPlayer())
            player->CustomData.Erase(WhistleDestinationKey);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_flight_masters_whistle_teleport::Check);
        OnDestinationTargetSelect += SpellDestinationTargetSelectFn(
            spell_ascension_flight_masters_whistle_teleport::FlyToChosenFlightMaster, EFFECT_0, TARGET_DEST_DB);
        AfterCast += SpellCastFn(spell_ascension_flight_masters_whistle_teleport::ForgetChoice);
    }
};

class item_ascension_flight_masters_whistle : public ItemScript
{
public:
    item_ascension_flight_masters_whistle() : ItemScript("item_ascension_flight_masters_whistle") { }

    void OnGossipSelect(Player* player, Item* whistle, uint32 sender, uint32 action) override
    {
        CloseGossipMenuFor(player);
        ClearGossipMenuFor(player);
        if (sender != SenderFlightMastersWhistle)
            return;
        std::vector<uint32> const nearest = NearestFlightMasters(player);
        if (std::find(nearest.begin(), nearest.end(), action) == nearest.end())
            return;
        player->CustomData.GetDefault<WhistleDestination>(WhistleDestinationKey)->Node = action;
        player->CastSpell(player, SpellFlightMastersWhistleTeleport, TRIGGERED_NONE, whistle);
    }
};

class spell_ascension_schmorgus_well_fed : public SpellScript
{
    PrepareSpellScript(spell_ascension_schmorgus_well_fed);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ SPELL_WELL_FED_SPELL_POWER, SPELL_WELL_FED_ATTACK_POWER });
    }

    void Feed(SpellEffIndex)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        float attackPower = std::max(target->GetTotalAttackPowerValue(BASE_ATTACK),
            target->GetTotalAttackPowerValue(RANGED_ATTACK));
        float spellPower = float(std::max(target->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SPELL),
            target->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_SPELL)));
        target->CastSpell(target, spellPower > attackPower ? SPELL_WELL_FED_SPELL_POWER : SPELL_WELL_FED_ATTACK_POWER,
            true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_schmorgus_well_fed::Feed, EFFECT_1, SPELL_EFFECT_DUMMY);
    }
};
}

void AddSC_AscensionConvenienceItems()
{
    RegisterSpellScript(spell_ascension_flight_masters_whistle);
    RegisterSpellScript(spell_ascension_flight_masters_whistle_teleport);
    new item_ascension_flight_masters_whistle();
    RegisterSpellScript(spell_ascension_schmorgus_well_fed);
}
