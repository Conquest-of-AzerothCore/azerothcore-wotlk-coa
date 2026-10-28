/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "LocalLevelScaling.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellDefines.h"
#include "SpellMgr.h"

namespace
{
constexpr uint32 TITAN_SCROLL_EONAR_BUFF = 993957;
constexpr uint32 TITAN_SCROLL_EONAR_BLESSING = 993963;
constexpr uint8 TITAN_SCROLL_EONAR_PROC_CHANCE = 10;

// Matches the buff's own native tooltip: "granting 5% of creature health as
// health and mana periodically" -- a flat percentage per tick, not scaled by
// stacks (the buff doesn't stack; native StackAmount is 1). Eonar's Blessing
// (993963) ticks 5 times over its 5000ms duration (1000ms EffectAmplitude),
// so this delivers 25% of the killed creature's max health in total.
constexpr uint32 TITAN_SCROLL_EONAR_HEAL_PERCENT = 5;

class titan_scroll_eonar_kill : public PlayerScript
{
public:
    titan_scroll_eonar_kill() : PlayerScript("titan_scroll_eonar_kill",
        {PLAYERHOOK_ON_CREATURE_KILL}) { }

    void OnPlayerCreatureKill(Player* killer, Creature* killed) override
    {
        Aura* buff = killer->GetAura(TITAN_SCROLL_EONAR_BUFF);
        if (!buff)
            return;

        // Nothing for what the player made themselves, and nothing for the
        // harmless (matches mod-ethereal-bazaar's identical kill-hook guard).
        if (killed->IsSummon() || killed->IsCritter() || killed->IsTotem())
            return;

        AreaTableEntry const* zone = sAreaTableStore.LookupEntry(killer->GetZoneId());
        if (zone && (zone->flags & AREA_FLAG_CAPITAL))
            return;

        if (!roll_chance_i(TITAN_SCROLL_EONAR_PROC_CHANCE))
            return;

        SpellInfo const* blessing = sSpellMgr->GetSpellInfo(TITAN_SCROLL_EONAR_BLESSING);
        if (!blessing)
            return;

        // The tooltip's "creature health" is the health bar the killer was shown, which level
        // scaling lifts per character above the creature's own.
        uint32 maxHealth = LocalLevelScaling::ViewMaxHealthFor(killer, killed);
        if (!maxHealth)
            maxHealth = killed->GetMaxHealth();

        uint32 healPerTick = maxHealth * TITAN_SCROLL_EONAR_HEAL_PERCENT / 100;

        SpellCastTargets targets;
        targets.SetDst(killed->GetPosition());

        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, static_cast<int32>(healPerTick));
        values.AddSpellMod(SPELLVALUE_BASE_POINT1, static_cast<int32>(healPerTick));

        killer->CastSpell(targets, blessing, &values, TRIGGERED_FULL_MASK);
    }
};
}

void AddSC_titan_scroll_eonar_kill()
{
    new titan_scroll_eonar_kill();
}
