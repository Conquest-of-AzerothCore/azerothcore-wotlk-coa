/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "BossControlTargeting.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "ThreatManager.h"

namespace
{
    // Hex of Jammal'an is a dummy timer; its removal casts the transform and the charm on the same player.
    constexpr uint32 SPELL_HEX_OF_JAMMAL_AN_TIMER = 12479;

    // Zevrim Thornhoof's Sacrifice (and its Ascension kit version) teleports, stuns and drains its target.
    constexpr uint32 SPELL_ZEVRIM_SACRIFICE = 22651;
    constexpr uint32 SPELL_ZEVRIM_SACRIFICE_ASCENSION = 2100215;

    // Darkmaster Gandling's Shadow Portal sends its target into one of his locked rooms.
    constexpr uint32 SPELL_GANDLING_SHADOW_PORTAL = 17950;

    // Shade of Eranikus' Deep Slumber stuns rather than applying the sleep mechanic.
    constexpr uint32 SPELL_ERANIKUS_DEEP_SLUMBER = 12890;

    // Lady Illucia Barov's Ascension kit Fear follows the same rule as her Dominate Mind.
    constexpr uint32 SPELL_ILLUCIA_FEAR_ASCENSION = 2100063;

    // Doctor Theolen Krastinov's Ghoulish Potion picks a damage dealer, but its splash still reaches anyone near them.
    constexpr uint32 SPELL_KRASTINOV_GHOULISH_POTION = 92624;

    // On Ascension, Archmage Arugal's curses still take tanks and healers.
    constexpr uint32 NPC_ARCHMAGE_ARUGAL = 4275;
}

bool BossControl::IsControlSpell(SpellInfo const* spellInfo)
{
    if (!spellInfo)
        return false;

    switch (spellInfo->Id)
    {
        case SPELL_HEX_OF_JAMMAL_AN_TIMER:
        case SPELL_ZEVRIM_SACRIFICE:
        case SPELL_ZEVRIM_SACRIFICE_ASCENSION:
        case SPELL_GANDLING_SHADOW_PORTAL:
        case SPELL_ERANIKUS_DEEP_SLUMBER:
        case SPELL_ILLUCIA_FEAR_ASCENSION:
            return true;
        default:
            break;
    }

    if (spellInfo->GetAllEffectsMechanicMask() & (1ULL << MECHANIC_SLEEP))
        return true;

    return spellInfo->HasAura(SPELL_AURA_MOD_CHARM) || spellInfo->HasAura(SPELL_AURA_MOD_POSSESS) ||
        spellInfo->HasAura(SPELL_AURA_AOE_CHARM);
}

bool BossControl::Applies(Unit const* caster, SpellInfo const* spellInfo)
{
    Creature const* boss = caster ? caster->ToCreature() : nullptr;
    if (!boss || !boss->IsDungeonBoss() || boss->GetEntry() == NPC_ARCHMAGE_ARUGAL)
        return false;

    Map const* map = caster->FindMap();
    MapEntry const* entry = map ? map->GetEntry() : nullptr;
    if (!entry || !entry->IsNonRaidDungeon() || entry->Expansion() != 0)
        return false;

    return IsControlSpell(spellInfo);
}

bool BossControl::IsProtectedTarget(Unit const* target)
{
    Player const* player = target ? target->ToPlayer() : nullptr;
    return player && sScriptMgr->OnPlayerHoldsTankOrHealerRole(player);
}

namespace
{
    bool HasAnotherEngagedPlayer(Unit const* caster, Unit const* target)
    {
        for (ThreatReference const* ref : caster->GetThreatMgr().GetUnsortedThreatList())
            if (!ref->IsOffline() && ref->GetVictim() != target && ref->GetVictim()->IsPlayer())
                return true;

        return false;
    }

    bool HasEngagedUnprotectedPlayer(Unit const* caster)
    {
        for (ThreatReference const* ref : caster->GetThreatMgr().GetUnsortedThreatList())
            if (!ref->IsOffline() && ref->GetVictim()->IsPlayer() &&
                !BossControl::IsProtectedTarget(ref->GetVictim()))
                return true;

        return false;
    }
}

bool BossControl::Forbids(Unit const* caster, Unit const* target, SpellInfo const* spellInfo)
{
    if (!target || !Applies(caster, spellInfo))
        return false;

    if (IsProtectedTarget(target))
        return true;

    return spellInfo->Id == SPELL_HEX_OF_JAMMAL_AN_TIMER && !HasAnotherEngagedPlayer(caster, target);
}

bool BossControl::ForbidsCast(Unit const* caster, Unit const* explicitTarget, SpellInfo const* spellInfo)
{
    if (!Applies(caster, spellInfo))
        return false;

    if (explicitTarget && explicitTarget != caster)
        return Forbids(caster, explicitTarget, spellInfo);

    return !HasEngagedUnprotectedPlayer(caster);
}

bool BossControl::SparesAreaTargets(SpellInfo const* spellInfo)
{
    return spellInfo && spellInfo->Id != SPELL_KRASTINOV_GHOULISH_POTION;
}
