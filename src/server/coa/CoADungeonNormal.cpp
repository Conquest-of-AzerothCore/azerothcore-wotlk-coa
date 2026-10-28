/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoADungeonNormal.h"
#include "Config.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "Log.h"
#include "Map.h"
#include "QueryResult.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "UnitScript.h"
#include "WorldScript.h"
#include <algorithm>
#include <unordered_map>

extern uint32 (*CoADungeonKitRepeatHook)(WorldObject const* source, uint32 eventId, uint32 repeat);

namespace
{
    struct NormalSpell
    {
        uint32 normalSpell = 0;
        float high = 1.0f;
    };

    constexpr uint32 KitFirstEventId = 9000;
    constexpr uint8 NormalRankMaxCasterLevel = 49;

    bool Enabled = true;
    float RepeatFactor = 1.1f;
    float AreaCapPct = 25.0f;
    float TargetCapPct = 40.0f;
    std::unordered_map<uint32, NormalSpell> Spells;

    Creature const* NormalDungeonCreature(WorldObject const* object)
    {
        Creature const* creature = object ? object->ToCreature() : nullptr;
        if (!Enabled || !creature || creature->IsCharmedOwnedByPlayerOrPlayer())
            return nullptr;
        Map const* map = creature->FindMap();
        if (!map || !map->IsNonRaidDungeon() || map->GetDifficulty() != DUNGEON_DIFFICULTY_NORMAL)
            return nullptr;
        return creature;
    }

    float DieAverage(SpellEffectInfo const& effect)
    {
        if (effect.DieSides == 0)
            return 0.0f;
        if (effect.DieSides == 1)
            return 1.0f;
        return (1.0f + float(effect.DieSides)) / 2.0f;
    }

    float CastValue(SpellInfo const* spellInfo, SpellEffectInfo const& effect, int32 level)
    {
        float value = float(effect.BasePoints) + DieAverage(effect);
        if (effect.RealPointsPerLevel == 0.0f)
            return value;
        if (level > int32(spellInfo->MaxLevel) && spellInfo->MaxLevel > 0)
            level = int32(spellInfo->MaxLevel);
        else if (level < int32(spellInfo->BaseLevel))
            level = int32(spellInfo->BaseLevel);
        level -= int32(std::max(spellInfo->BaseLevel, spellInfo->SpellLevel));
        return value + float(int32(level * effect.RealPointsPerLevel));
    }

    float NormalRankValue(SpellInfo const* spellInfo, SpellEffectInfo const& effect, int32 level)
    {
        return float(effect.BasePoints) + DieAverage(effect)
            + effect.RealPointsPerLevel * float(std::max<int32>(0, level - int32(spellInfo->SpellLevel)));
    }

    bool IsDirect(SpellEffectInfo const& effect)
    {
        return effect.Effect == SPELL_EFFECT_SCHOOL_DAMAGE || effect.Effect == SPELL_EFFECT_HEALTH_LEECH;
    }

    bool IsPeriodic(SpellEffectInfo const& effect)
    {
        return effect.Effect == SPELL_EFFECT_APPLY_AURA && effect.Amplitude > 0
            && (effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE || effect.ApplyAuraName == SPELL_AURA_PERIODIC_LEECH);
    }

    template <typename Value>
    float Damage(SpellInfo const* spellInfo, bool periodic, int32 level, Value value)
    {
        float total = 0.0f;
        for (SpellEffectInfo const& effect : spellInfo->GetEffects())
        {
            if (periodic ? IsPeriodic(effect) : IsDirect(effect))
            {
                float const amount = value(spellInfo, effect, level);
                total += periodic ? amount * 1000.0f / float(effect.Amplitude) : amount;
            }
        }
        return total;
    }

    float Factor(Creature const* caster, SpellInfo const* spellInfo, bool periodic)
    {
        auto itr = Spells.find(spellInfo->Id);
        if (itr == Spells.end())
            return 1.0f;
        NormalSpell const& row = itr->second;
        if (!row.normalSpell || caster->GetLevel() > NormalRankMaxCasterLevel)
            return row.high;
        if (row.normalSpell == spellInfo->Id)
            return 1.0f;
        SpellInfo const* normalInfo = sSpellMgr->GetSpellInfo(row.normalSpell);
        if (!normalInfo)
            return row.high;
        int32 const level = int32(caster->GetLevel());
        float const current = Damage(spellInfo, periodic, level, CastValue);
        float const normal = Damage(normalInfo, periodic, level, NormalRankValue);
        return current > 0.0f && normal > 0.0f ? normal / current : row.high;
    }

    template <typename T>
    void Tune(Unit const* target, Unit const* attacker, T& damage, SpellInfo const* spellInfo, bool periodic)
    {
        if (damage <= 0 || !spellInfo || !CoADungeonNormal::TunesSpell(attacker, spellInfo))
            return;
        float value = float(damage) * Factor(attacker->ToCreature(), spellInfo, periodic);
        if (target && target->GetCharmerOrOwnerPlayerOrPlayerItself())
        {
            float const capPct = spellInfo->IsAffectingArea() ? AreaCapPct : TargetCapPct;
            if (capPct > 0.0f)
                value = std::min(value, float(target->GetMaxHealth()) * capPct / 100.0f);
        }
        damage = T(std::max(1.0f, value));
    }

    uint32 SmartKitRepeat(WorldObject const* source, uint32 eventId, uint32 repeat)
    {
        return eventId >= KitFirstEventId ? CoADungeonNormal::KitRepeat(source, repeat) : repeat;
    }
}

bool CoADungeonNormal::TunesSpell(Unit const* attacker, SpellInfo const* spellInfo)
{
    return spellInfo && Spells.count(spellInfo->Id) && NormalDungeonCreature(attacker);
}

uint32 CoADungeonNormal::KitRepeat(WorldObject const* source, uint32 repeat)
{
    if (!repeat || RepeatFactor == 1.0f || !NormalDungeonCreature(source))
        return repeat;
    return uint32(float(repeat) * RepeatFactor + 0.5f);
}

class CoADungeonNormalWorld final : public WorldScript
{
public:
    CoADungeonNormalWorld() : WorldScript("CoADungeonNormalWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool) override
    {
        Enabled = sConfigMgr->GetOption<bool>("CoA.DungeonNormal.Enable", true);
        RepeatFactor = std::max(0.1f, sConfigMgr->GetOption<float>("CoA.DungeonNormal.RepeatFactor", 1.1f));
        AreaCapPct = sConfigMgr->GetOption<float>("CoA.DungeonNormal.AreaHitCapPct", 25.0f);
        TargetCapPct = sConfigMgr->GetOption<float>("CoA.DungeonNormal.TargetHitCapPct", 40.0f);
        CoADungeonKitRepeatHook = &SmartKitRepeat;
    }

    void OnStartup() override
    {
        Spells.clear();
        if (QueryResult result = WorldDatabase.Query("SELECT spell_id, normal_spell_id, high FROM coa_dungeon_normal_spell_damage"))
        {
            do
            {
                Field* fields = result->Fetch();
                NormalSpell& row = Spells[fields[0].Get<uint32>()];
                row.normalSpell = fields[1].Get<uint32>();
                row.high = fields[2].Get<float>();
            } while (result->NextRow());
        }
        LOG_INFO("server.loading", ">> Loaded {} CoA Normal dungeon kit spells", Spells.size());
    }
};

class CoADungeonNormalDamage final : public UnitScript
{
public:
    CoADungeonNormalDamage() : UnitScript("CoADungeonNormalDamage", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK }) { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        Tune(target, attacker, damage, spellInfo, false);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        Tune(target, attacker, damage, spellInfo, true);
    }
};

void AddSC_CoADungeonNormal()
{
    new CoADungeonNormalWorld();
    new CoADungeonNormalDamage();
}
