/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoABossProbe.h"
#include "AllSpellScript.h"
#include "Config.h"
#include "Creature.h"
#include "Log.h"
#include "Map.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "Timer.h"
#include "UnitScript.h"
#include "WorldScript.h"

namespace
{
    bool Enabled = false;

    Creature const* DungeonCreature(Unit const* unit)
    {
        if (!Enabled || !unit)
            return nullptr;
        Creature const* creature = unit->ToCreature();
        if (!creature || creature->IsPet() || creature->IsGuardian() || creature->GetCharmerOrOwnerPlayerOrPlayerItself())
            return nullptr;
        Map const* map = creature->GetMap();
        return map && map->IsDungeon() ? creature : nullptr;
    }

    void Write(char const* kind, Creature const* creature, uint32 spell, int64 value, Unit const* target)
    {
        LOG_INFO("coa.bossprobe", "{} {} map={} diff={} entry={} tpl={} name=\"{}\" spell={} value={} hp={:.0f} target={}",
            getMSTime(), kind, creature->GetMapId(), uint32(creature->GetMap()->GetDifficulty()), creature->GetEntry(),
            creature->GetCreatureTemplate()->Entry, creature->GetName(), spell, value, creature->GetHealthPct(),
            target ? target->GetName() : "-");
    }
}

extern void (*CoABossProbeSmartCastHook)(Creature* creature, uint32 spellId, int32 result, char const* stage);

void CoABossProbeSmartCast(Creature* creature, uint32 spellId, int32 result, char const* stage)
{
    if (Creature const* probed = DungeonCreature(creature))
        Write(stage, probed, spellId, result, creature->GetVictim());
}

class CoABossProbeWorld final : public WorldScript
{
public:
    CoABossProbeWorld() : WorldScript("CoABossProbeWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

    void OnAfterConfigLoad(bool) override
    {
        Enabled = sConfigMgr->GetOption<bool>("CoA.BossProbe.Enable", false);
    }
};

class CoABossProbeSpells final : public AllSpellScript
{
public:
    CoABossProbeSpells() : AllSpellScript("CoABossProbeSpells", { ALLSPELLHOOK_ON_CAST }) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (Creature const* creature = DungeonCreature(caster); creature && info)
            Write("cast", creature, info->Id, spell && spell->IsTriggered() ? 1 : 0, spell ? spell->m_targets.GetUnitTarget() : nullptr);
    }
};

class CoABossProbeDamage final : public UnitScript
{
public:
    CoABossProbeDamage() : UnitScript("CoABossProbeDamage", true, { UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN }) { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        if (Creature const* creature = DungeonCreature(attacker))
            Write("melee", creature, 0, damage, target);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (Creature const* creature = DungeonCreature(attacker))
            Write("spelldmg", creature, spellInfo ? spellInfo->Id : 0, damage, target);
    }
};

void AddSC_CoABossProbe()
{
    CoABossProbeSmartCastHook = &CoABossProbeSmartCast;
    new CoABossProbeWorld();
    new CoABossProbeSpells();
    new CoABossProbeDamage();
}
