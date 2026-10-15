/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "CellImpl.h"
#include "EventMap.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <cmath>
#include <map>
#include <memory>

namespace
{
constexpr uint32 DrumBuffRefreshBelowMs = 15000;
constexpr uint32 DrumBuffRefreshCooldownMs = 1000;

struct DrumPlacement
{
    std::map<ObjectGuid, uint32> nextRefreshMs;
};

struct go_ascension_guardian_drum : GameObjectAI
{
    explicit go_ascension_guardian_drum(GameObject* object) : GameObjectAI(object)
    {
        events.ScheduleEvent(1, Milliseconds(250));
    }

    std::shared_ptr<DrumPlacement> placement;
    EventMap events;

    void UpdateAI(uint32 diff) override
    {
        events.Update(diff);
        if (!events.ExecuteEvent())
            return;
        Unit* owner = me->GetOwner();
        if (!placement || !owner || !owner->IsAlive() || !owner->IsInWorld() || owner->GetMap() != me->GetMap())
        {
            me->Delete();
            return;
        }
        SpellInfo const* buff = sSpellMgr->GetSpellInfo(570759);
        float range = buff->Effects[EFFECT_0].CalcRadius(owner);
        if (range <= 0.0f)
            range = 20.0f;
        std::list<Unit*> players;
        Acore::AnyUnitInObjectRangeCheck check(me, range);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> searcher(me, players, check);
        Cell::VisitObjects(me, searcher, range);
        uint32 now = uint32(GameTime::GetGameTimeMS().count());
        for (Unit* player : players)
        {
            if (!player->IsAlive() || !player->IsControlledByPlayer() || !owner->IsFriendlyTo(player))
                continue;
            auto scheduled = placement->nextRefreshMs.find(player->GetGUID());
            if (scheduled != placement->nextRefreshMs.end() && scheduled->second > now)
                continue;
            Aura const* aura = player->GetAura(570759, owner->GetGUID());
            if (aura && aura->GetDuration() > int32(DrumBuffRefreshBelowMs))
                continue;
            if (owner->CastSpell(player, 570759, true) == SPELL_CAST_OK)
                placement->nextRefreshMs[player->GetGUID()] = now + DrumBuffRefreshCooldownMs;
        }
        events.ScheduleEvent(1, Milliseconds(250));
    }
};

class spell_ascension_guardian_drums : public SpellScript
{
    PrepareSpellScript(spell_ascension_guardian_drums);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_GUARDIAN;
    }

    void Skip(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
    }

    void Summon()
    {
        Unit* caster = GetCaster();
        auto placement = std::make_shared<DrumPlacement>();
        std::list<GameObject*> previous;
        caster->GetGameObjectListWithEntryInGrid(previous, 9000117, 200.0f);
        std::vector<GameObject*> created;
        for (uint32 i = 0; i < 3; ++i)
        {
            float angle = caster->GetOrientation() + float(i) * float(2.0 * M_PI / 3.0);
            float x, y, z;
            caster->GetClosePoint(x, y, z, DEFAULT_WORLD_OBJECT_SIZE, 3.0f, angle - caster->GetOrientation());
            if (GameObject* object = caster->SummonGameObject(9000117, x, y, z, angle,
                0, 0, std::sin(angle / 2), std::cos(angle / 2), uint32(GetSpellInfo()->GetDuration() / 1000)))
            {
                object->SetSpellId(803683);
                if (auto* ai = dynamic_cast<go_ascension_guardian_drum*>(object->AI()))
                {
                    ai->placement = placement;
                    created.push_back(object);
                }
                else
                    object->Delete();
            }
        }
        if (created.size() == 3)
            for (GameObject* object : previous)
                if (object->GetOwnerGUID() == caster->GetGUID())
                    object->Delete();
        if (created.size() != 3)
            for (GameObject* object : created)
                object->Delete();
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_guardian_drums::Skip, EFFECT_ALL, SPELL_EFFECT_TRANS_DOOR);
        AfterCast += SpellCastFn(spell_ascension_guardian_drums::Summon);
    }
};
}

void AddAscensionGuardianDrumScripts()
{
    RegisterGameObjectAI(go_ascension_guardian_drum);
    RegisterSpellScript(spell_ascension_guardian_drums);
}
