/*
 * Infernal Strike, the on-use of Infused, Infernos of Elemental Fury (998102-998105)
 * and Infernos, the Ignited (18129, 218129, 318129, 1318129).
 *
 * 909834-909837 (Normal/Heroic/Mythic/Ascended) are a lone SPELL_EFFECT_DUMMY on the
 * caster; Ascension did the work server-side with helper spells that exist in our
 * Spell.dbc but had nothing chaining them. Rebuilt from that data plus a player's
 * account of the live ability ("7 tiles in a straight line, anything hit gets a ~30 s
 * dot, big targets hit by several tiles get a bigger stack") - a smaller version of
 * Basalthane's Inferno Trail:
 *
 *  - After the 2 s cast, 909843 roots the caster for 2 s while 7 tiles run forward.
 *  - Each tile plays the Line visual (909844-909847, 3 yd radius) and every enemy
 *    inside it gets one stack of Infernal Strike Burn (909842, 125 Fire/s, 30 s,
 *    up to 100 stacks): one stack per tile, so a normal unit gets 1 and a large
 *    target covering several tiles stacks up (at most 7).
 *  - The first tile that reaches an enemy also deals the tier's weapon hit
 *    (909838-909841, 100% weapon damage) - once per enemy, not once per tile.
 */

#include "../../coa/AscensionClientSpellPatches.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "Unit.h"

#include <algorithm>
#include <cmath>
#include <list>
#include <memory>
#include <unordered_set>

namespace
{
    constexpr uint32 ITEM_INFUSED_INFERNOS_NORMAL = 998102;
    constexpr uint32 ITEM_INFUSED_INFERNOS_ASCENDED = 998105;

    constexpr uint32 SPELL_INFERNAL_STRIKE_NORMAL = 909834;
    constexpr uint32 SPELL_INFERNAL_STRIKE_DAMAGE_NORMAL = 909838;
    constexpr uint32 SPELL_INFERNAL_STRIKE_BURN = 909842;
    constexpr uint32 SPELL_INFERNAL_STRIKE_ROOT = 909843;
    constexpr uint32 SPELL_INFERNAL_STRIKE_LINE_NORMAL = 909844;

    constexpr int INFERNAL_STRIKE_TILES = 7;
    constexpr float INFERNAL_STRIKE_TILE_RADIUS = 3.0f;
    constexpr float INFERNAL_STRIKE_TILE_STEP = 3.5f;
    constexpr uint32 INFERNAL_STRIKE_TILE_INTERVAL_MS = 250;

    uint32 TierOffset(uint32 strikeSpellId)
    {
        return strikeSpellId - SPELL_INFERNAL_STRIKE_NORMAL;
    }

    float GroundZ(Unit const* caster, float x, float y, float fallbackZ)
    {
        float z = caster->GetMap()->GetHeight(x, y, fallbackZ + 5.0f, true);
        return z > INVALID_HEIGHT ? z : fallbackZ;
    }

    // Tiles split the line into back-to-back segments, so a normal-sized unit stands in
    // exactly one of them; only the part of a target's size above the default reach
    // stretches it across neighbouring tiles, which is what lets big targets stack higher.
    bool IsInTile(Unit const* enemy, float x, float y, float dirX, float dirY)
    {
        float const extra = std::max(0.0f, enemy->GetCombatReach() - DEFAULT_COMBAT_REACH);
        float const dx = enemy->GetPositionX() - x;
        float const dy = enemy->GetPositionY() - y;
        float const along = dx * dirX + dy * dirY;
        float const across = -dx * dirY + dy * dirX;
        float const halfStep = INFERNAL_STRIKE_TILE_STEP / 2.0f;
        return along > -halfStep - extra && along <= halfStep + extra
            && std::fabs(across) <= INFERNAL_STRIKE_TILE_RADIUS + extra;
    }

    void StrikeTile(Unit* caster, uint32 tier, float x, float y, float z, float dirX, float dirY,
        std::unordered_set<ObjectGuid>& struck)
    {
        if (SpellInfo const* line = sSpellMgr->GetSpellInfo(SPELL_INFERNAL_STRIKE_LINE_NORMAL + tier))
        {
            SpellCastTargets targets;
            targets.SetDst(x, y, z, caster->GetOrientation());
            caster->CastSpell(targets, line, nullptr, TRIGGERED_FULL_MASK);
        }

        std::list<Unit*> enemies;
        float const searchRange = caster->GetDistance2d(x, y) + INFERNAL_STRIKE_TILE_STEP + 30.0f;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(caster, caster, searchRange);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(caster, enemies, check);
        Cell::VisitObjects(caster, searcher, searchRange);

        for (Unit* enemy : enemies)
        {
            if (!enemy->IsAlive() || !caster->IsValidAttackTarget(enemy))
                continue;

            if (!IsInTile(enemy, x, y, dirX, dirY))
                continue;

            if (struck.insert(enemy->GetGUID()).second)
                caster->CastSpell(enemy, SPELL_INFERNAL_STRIKE_DAMAGE_NORMAL + tier, true);
            caster->CastSpell(enemy, SPELL_INFERNAL_STRIKE_BURN, true);
        }
    }
}

class spell_infernos_infernal_strike : public SpellScript
{
    PrepareSpellScript(spell_infernos_infernal_strike);

    bool Validate(SpellInfo const* spellInfo) override
    {
        uint32 const tier = TierOffset(spellInfo->Id);
        return ValidateSpellInfo({ SPELL_INFERNAL_STRIKE_DAMAGE_NORMAL + tier, SPELL_INFERNAL_STRIKE_LINE_NORMAL + tier,
            SPELL_INFERNAL_STRIKE_BURN, SPELL_INFERNAL_STRIKE_ROOT });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;

        caster->CastSpell(caster, SPELL_INFERNAL_STRIKE_ROOT, true);

        uint32 const tier = TierOffset(GetSpellInfo()->Id);
        float const originX = caster->GetPositionX();
        float const originY = caster->GetPositionY();
        float const originZ = caster->GetPositionZ();
        float const dirX = std::cos(caster->GetOrientation());
        float const dirY = std::sin(caster->GetOrientation());
        ObjectGuid const casterGuid = caster->GetGUID();
        auto struck = std::make_shared<std::unordered_set<ObjectGuid>>();

        for (int tile = 0; tile < INFERNAL_STRIKE_TILES; ++tile)
        {
            float const distance = INFERNAL_STRIKE_TILE_STEP * (tile + 1);
            float const x = originX + dirX * distance;
            float const y = originY + dirY * distance;
            float const z = GroundZ(caster, x, y, originZ);
            caster->m_Events.AddEventAtOffset([casterGuid, tier, x, y, z, dirX, dirY, struck, caster]()
            {
                if (caster->GetGUID() == casterGuid && caster->IsInWorld())
                    StrikeTile(caster, tier, x, y, z, dirX, dirY, *struck);
            }, Milliseconds(INFERNAL_STRIKE_TILE_INTERVAL_MS * tile));
        }
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_infernos_infernal_strike::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void AddSC_spell_infernos_items()
{
    // The Infused axes are missing from the live client's Item.dbc; their item_dbc rows only
    // reach the client once the item ids are registered for streaming.
    for (uint32 itemId = ITEM_INFUSED_INFERNOS_NORMAL; itemId <= ITEM_INFUSED_INFERNOS_ASCENDED; ++itemId)
        Ascension::ClientItemPatches::Instance().Register(itemId);
    RegisterSpellScript(spell_infernos_infernal_strike);
}
