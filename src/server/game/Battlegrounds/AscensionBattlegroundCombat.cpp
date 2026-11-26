/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattlegroundCombat.h"
#include "AscensionBattlegroundBrackets.h"
#include "AscensionBattlegroundBracketsPolicy.h"
#include "Battleground.h"
#include "Map.h"
#include "Player.h"
#include "SpellInfo.h"
#include "Unit.h"

namespace
{
    bool ShouldScale(Unit const* source, Unit const* target, SpellInfo const* spell, bool healing, bool absorb)
    {
        if (!source || !target || AscensionBattlegroundCombat::SharedTopLevel(source, target) == 0)
            return false;

        if (source->IsHostileTo(target) == healing)
            return false;

        if (spell)
        {
            if (spell->HasAura(SPELL_AURA_PERIODIC_DAMAGE_PERCENT))
                return false;

            if (spell->AscensionInheritsResolvedAmount)
                return false;

            uint8 const channel = absorb ? BG_CATCH_UP_SKIP_ABSORB
                : (healing ? BG_CATCH_UP_SKIP_HEAL : BG_CATCH_UP_SKIP_DAMAGE);
            if ((spell->AscensionBattlegroundCatchUpSkip & channel) != 0)
                return false;

            if (healing && (spell->HasEffect(SPELL_EFFECT_HEALTH_LEECH) || spell->HasAura(SPELL_AURA_PERIODIC_LEECH)))
                return false;

            if (healing && (spell->HasEffect(SPELL_EFFECT_HEAL_PCT) || spell->HasEffect(SPELL_EFFECT_HEAL_MAX_HEALTH) ||
                spell->HasAura(SPELL_AURA_OBS_MOD_HEALTH)))
                return false;
        }

        return true;
    }
}

namespace AscensionBattlegroundCombat
{
    uint8 SharedTopLevel(Unit const* self, Unit const* other)
    {
        if (!self || !other || !self->IsControlledByPlayer() || !other->IsControlledByPlayer())
            return 0;

        Map const* map = self->FindMap();
        if (!map || !map->IsBattleground() || other->FindMap() != map)
            return 0;

        Player const* selfPlayer = self->GetCharmerOrOwnerPlayerOrPlayerItself();
        Player const* otherPlayer = other->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!selfPlayer || !otherPlayer)
            return 0;

        Battleground const* battleground = selfPlayer->GetBattleground();
        if (!battleground || battleground->isArena() || battleground != otherPlayer->GetBattleground() ||
            battleground->GetMapId() != map->GetId())
            return 0;

        return static_cast<uint8>(
            AscensionBattlegroundBrackets::WidenedMaxLevel(battleground->GetMapId(), battleground->GetBracketId()));
    }

    uint8 StealthDetectionLevel(Unit const* detector, Unit const* stealthed)
    {
        return SharedTopLevel(detector, stealthed) ? stealthed->GetLevel() : 0;
    }

    float OutputRatio(Unit const* unit)
    {
        if (!unit)
            return 1.0f;

        if (float const ratio = unit->GetBattlegroundOutputRatio(); ratio > 1.0f)
            return ratio;

        Unit const* owner = unit->GetCharmerOrOwner();
        return owner ? owner->GetBattlegroundOutputRatio() : 1.0f;
    }

    uint32 ScaledOutput(Unit const* source, Unit const* target, uint32 amount, SpellInfo const* spell, bool healing,
        bool absorb)
    {
        if (amount == 0 || !ShouldScale(source, target, spell, healing, absorb))
            return amount;

        return AscensionBattlegroundBracketsPolicy::ScaleAmount(amount, OutputRatio(source));
    }

    float UnscaledFactor(Unit const* source, Unit const* target, SpellInfo const* spell, bool healing, bool absorb)
    {
        if (!ShouldScale(source, target, spell, healing, absorb))
            return 1.0f;

        float const ratio = OutputRatio(source);
        return ratio > 1.0f ? (1.0f / ratio) : 1.0f;
    }

    float UnitUnscaledFactor(Unit const* unit)
    {
        float const ratio = OutputRatio(unit);
        return ratio > 1.0f ? (1.0f / ratio) : 1.0f;
    }
}
