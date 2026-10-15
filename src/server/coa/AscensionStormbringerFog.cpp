/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "DynamicObject.h"
#include "Map.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellScript.h"
#include "Unit.h"
#include <map>
#include <mutex>

namespace
{
enum FogSpells : uint32
{
    SPELL_FOG = 806100
};

struct FogArea
{
    ObjectGuid area;
    uint32 map;
    uint32 instance;
};

std::mutex fogMutex;
std::map<ObjectGuid, FogArea> fogAreas;

void RememberFog(Unit* caster, DynamicObject* area)
{
    std::lock_guard<std::mutex> lock(fogMutex);
    fogAreas[caster->GetGUID()] = {area->GetGUID(), area->GetMapId(), area->GetInstanceId()};
}

bool CrossesFogEdge(Unit* caster, Unit* target)
{
    Map* map = caster->FindMap();
    if (!map || target->FindMap() != map)
        return false;
    std::lock_guard<std::mutex> lock(fogMutex);
    bool crossed = false;
    for (auto itr = fogAreas.begin(); itr != fogAreas.end() && !crossed;)
    {
        if (itr->second.map != map->GetId() || itr->second.instance != map->GetInstanceId())
        {
            ++itr;
            continue;
        }
        DynamicObject* area = map->GetDynamicObject(itr->second.area);
        if (!area || !area->IsInWorld())
        {
            itr = fogAreas.erase(itr);
            continue;
        }
        if (!area->InSamePhase(caster))
        {
            ++itr;
            continue;
        }
        float radius = area->GetRadius();
        crossed = (area->GetExactDist2d(caster) <= radius) != (area->GetExactDist2d(target) <= radius);
        ++itr;
    }
    return crossed;
}

class spell_ascension_stormbringer_fog : public SpellScript
{
    PrepareSpellScript(spell_ascension_stormbringer_fog);

    void Remember()
    {
        Unit* caster = GetCaster();
        if (!caster)
            return;
        if (DynamicObject* area = caster->GetDynObject(SPELL_FOG))
            RememberFog(caster, area);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_ascension_stormbringer_fog::Remember);
    }
};

class stormbringer_fog_targeting : public AllSpellScript
{
public:
    stormbringer_fog_targeting() : AllSpellScript("stormbringer_fog_targeting",
        {ALLSPELLHOOK_ON_SPELL_CHECK_CAST}) { }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        if (result != SPELL_CAST_OK || spell->IsTriggered())
            return;
        Unit* caster = spell->GetCaster();
        Unit* target = spell->m_targets.GetUnitTarget();
        if (!caster || !target || caster == target || !caster->IsValidAttackTarget(target))
            return;
        if (CrossesFogEdge(caster, target))
            result = SPELL_FAILED_LINE_OF_SIGHT;
    }
};
}

void AddSC_AscensionStormbringerFog()
{
    RegisterSpellScript(spell_ascension_stormbringer_fog);
    new stormbringer_fog_targeting();
}
