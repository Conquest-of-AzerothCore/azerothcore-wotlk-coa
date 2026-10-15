/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Battlefield.h"
#include "BattlefieldMgr.h"
#include "DBCStores.h"
#include "Map.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include "World.h"
#include <array>
#include <optional>

namespace
{
enum ClosestResurrection : uint32
{
    SPELL_RESURRECT_CLOSEST_TOWN = 84423,
    SPELL_RESURRECT_CLOSEST_CITY = 84433,
    CITY_MIN_LEVEL = 10
};

constexpr float RESURRECT_RESTORE_PERCENT = 0.5f;

struct Destination
{
    uint32 map;
    float x;
    float y;
    float z;
    float orientation;
};

struct Capital
{
    TeamId team;
    Destination destination;
};

constexpr std::array<Capital, 8> Capitals =
{{
    { TEAM_ALLIANCE, { 0, -8833.38f, 628.628f, 94.0066f, 1.06535f } },
    { TEAM_ALLIANCE, { 0, -4918.88f, -940.406f, 501.564f, 5.42347f } },
    { TEAM_ALLIANCE, { 1, 9949.56f, 2284.21f, 1341.4f, 1.59587f } },
    { TEAM_ALLIANCE, { 530, -3965.7f, -11653.6f, -138.844f, 0.852154f } },
    { TEAM_HORDE, { 1, 1629.85f, -4373.64f, 31.5573f, 3.69762f } },
    { TEAM_HORDE, { 1, -1277.37f, 124.804f, 131.287f, 5.22274f } },
    { TEAM_HORDE, { 0, 1584.14f, 240.308f, -52.1534f, 0.041793f } },
    { TEAM_HORDE, { 530, 9487.69f, -7279.2f, 14.2866f, 6.16478f } }
}};

bool CanResurrectHere(Player* player)
{
    if (player->GetMap()->Instanceable())
        return false;

    Battlefield* battlefield = sBattlefieldMgr->GetBattlefieldToZoneId(player->GetZoneId());
    return !battlefield || !battlefield->IsWarTime();
}

std::optional<Destination> FindClosestTown(Player* player)
{
    uint32 node = sObjectMgr->GetNearestTaxiNode(player->GetPositionX(), player->GetPositionY(),
        player->GetPositionZ(), player->GetMapId(), player->GetTeamId());
    TaxiNodesEntry const* entry = node ? sTaxiNodesStore.LookupEntry(node) : nullptr;
    if (!entry)
        return std::nullopt;

    return Destination{ entry->map_id, entry->x, entry->y, entry->z, player->GetOrientation() };
}

std::optional<Destination> FindClosestCity(Player* player)
{
    Capital const* closest = nullptr;
    float closestDistance = 0.0f;
    Capital const* fallback = nullptr;
    for (Capital const& capital : Capitals)
    {
        if (capital.team != player->GetTeamId())
            continue;

        if (!fallback)
            fallback = &capital;

        if (capital.destination.map != player->GetMapId())
            continue;

        float const distance = player->GetExactDist2dSq(capital.destination.x, capital.destination.y);
        if (!closest || distance < closestDistance)
        {
            closest = &capital;
            closestDistance = distance;
        }
    }

    if (Capital const* capital = closest ? closest : fallback)
        return capital->destination;

    return std::nullopt;
}

class spell_ascension_closest_resurrection : public SpellScript
{
    PrepareSpellScript(spell_ascension_closest_resurrection);

    bool Load() override { return GetCaster()->ToPlayer() != nullptr; }

    std::optional<Destination> FindDestination(Player* player)
    {
        return GetSpellInfo()->Id == SPELL_RESURRECT_CLOSEST_CITY ? FindClosestCity(player) : FindClosestTown(player);
    }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        if (player->IsAlive())
            return SPELL_FAILED_TARGET_NOT_DEAD;

        if (GetSpellInfo()->Id == SPELL_RESURRECT_CLOSEST_CITY && player->GetLevel() < CITY_MIN_LEVEL)
            return SPELL_FAILED_LEVEL_REQUIREMENT;

        if (!CanResurrectHere(player) || !FindDestination(player))
            return SPELL_FAILED_NOT_HERE;

        return SPELL_CAST_OK;
    }

    void Resurrect(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        std::optional<Destination> destination = FindDestination(player);
        if (player->IsAlive() || !destination)
            return;

        player->ResurrectPlayer(RESURRECT_RESTORE_PERCENT, true);

        if (!player->IsAlive())
            return;

        float const durabilityLoss = sWorld->getRate(RATE_DURABILITY_LOSS_ON_SPIRIT_RESURRECT) / 100.0f;
        if (durabilityLoss)
            player->DurabilityLossAll(durabilityLoss, true);

        player->SpawnCorpseBones();
        player->TeleportTo(destination->map, destination->x, destination->y, destination->z,
            destination->orientation, TELE_TO_SPELL);
        sScriptMgr->OnPlayerCoAProgress(player, CoAProgressEvent::ClosestResurrection, GetSpellInfo()->Id);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_closest_resurrection::CheckCast);
        OnEffectHit += SpellEffectFn(spell_ascension_closest_resurrection::Resurrect, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class closest_resurrection_player_spells : public PlayerScript
{
public:
    closest_resurrection_player_spells() : PlayerScript("closest_resurrection_player_spells", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        for (uint32 spellId : { SPELL_RESURRECT_CLOSEST_TOWN, SPELL_RESURRECT_CLOSEST_CITY })
            if (!player->HasSpell(spellId))
                player->learnSpell(spellId, false);
    }
};
}

void AddSC_AscensionClosestResurrection()
{
    RegisterSpellScript(spell_ascension_closest_resurrection);
    new closest_resurrection_player_spells();
}
