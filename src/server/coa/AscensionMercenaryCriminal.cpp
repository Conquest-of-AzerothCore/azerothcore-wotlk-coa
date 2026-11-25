/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionMercenary.h"
#include "DataMap.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include <unordered_set>

namespace
{
constexpr uint32 SPELL_CRIMINAL = 9930873;
constexpr int32 CRIMINAL_HIT_DURATION = 2 * MINUTE * IN_MILLISECONDS;
constexpr int32 CRIMINAL_KILL_DURATION = 8 * MINUTE * IN_MILLISECONDS;
constexpr char const* AggressionKey = "ascension_mercenary_criminal_aggression";

struct Aggression final : DataMap::Base
{
    std::unordered_set<ObjectGuid> Victims;
};

Player* MercenaryStriking(Unit* attacker, Unit* victim, Player*& innocent)
{
    Player* mercenary = attacker ? attacker->GetCharmerOrOwnerPlayerOrPlayerItself() : nullptr;
    innocent = victim ? victim->ToPlayer() : nullptr;
    if (!mercenary || !innocent || mercenary == innocent || !AscensionMercenary::Active(mercenary) ||
        AscensionMercenary::Active(innocent) || mercenary->GetTeamId() != innocent->GetTeamId())
        return nullptr;
    return mercenary;
}

void MarkCriminal(Player* player, int32 duration)
{
    Aura* aura = player->GetAura(SPELL_CRIMINAL);
    if (!aura)
    {
        player->CastSpell(player, SPELL_CRIMINAL, true);
        aura = player->GetAura(SPELL_CRIMINAL);
        if (!aura)
            return;
    }
    else if (aura->GetDuration() >= duration)
        return;

    aura->SetMaxDuration(duration);
    aura->SetDuration(duration);
}

void StrikeInnocent(Unit* attacker, Unit* victim)
{
    Player* innocent = nullptr;
    Player* mercenary = MercenaryStriking(attacker, victim, innocent);
    if (!mercenary || AscensionMercenary::StruckFirst(innocent, mercenary))
        return;

    mercenary->CustomData.GetDefault<Aggression>(AggressionKey)->Victims.insert(innocent->GetGUID());
    MarkCriminal(mercenary, CRIMINAL_HIT_DURATION);
}

void KillInnocent(Unit* killer, Unit* victim)
{
    Player* innocent = nullptr;
    Player* mercenary = MercenaryStriking(killer, victim, innocent);
    if (!mercenary)
        return;

    Aggression* state = mercenary->CustomData.Get<Aggression>(AggressionKey);
    if (state && state->Victims.erase(innocent->GetGUID()))
        MarkCriminal(mercenary, CRIMINAL_KILL_DURATION);
}

void ForgetAggressionOnceOutOfCombat(Player* player)
{
    if (!player->CustomData.Get<Aggression>(AggressionKey))
        return;

    ObjectGuid const guid = player->GetGUID();
    player->m_Events.AddEventAtOffset([guid]()
    {
        Player* player = ObjectAccessor::FindPlayer(guid);
        if (!player || player->IsInCombat())
            return;
        if (Aggression* state = player->CustomData.Get<Aggression>(AggressionKey))
            state->Victims.clear();
    }, 0ms);
}

class ascension_mercenary_criminal_acts : public UnitScript
{
public:
    ascension_mercenary_criminal_acts()
        : UnitScript("ascension_mercenary_criminal_acts", true,
                     {UNITHOOK_ON_DAMAGE, UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_UNIT_DEATH,
                      UNITHOOK_ON_UNIT_EXIT_COMBAT}) { }

    void OnDamage(Unit* attacker, Unit* victim, uint32&) override { StrikeInnocent(attacker, victim); }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Unit* caster = aura->GetCaster();
        if (caster != unit && !aura->GetSpellInfo()->IsPositive())
            StrikeInnocent(caster, unit);
    }

    void OnUnitDeath(Unit* unit, Unit* killer) override { KillInnocent(killer, unit); }

    void OnUnitExitCombat(Unit* unit) override
    {
        if (Player* player = unit->ToPlayer())
            ForgetAggressionOnceOutOfCombat(player);
    }
};
}

void AddSC_AscensionMercenaryCriminal()
{
    new ascension_mercenary_criminal_acts();
}
