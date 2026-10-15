/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "CreatureScript.h"
#include "GameObjectAI.h"
#include "GameObjectScript.h"
#include "LootMgr.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "molten_core.h"

enum Texts
{
    SAY_AGGRO                               = 0,
    SAY_SPAWN                               = 1,
    SAY_SLAY                                = 2,
    SAY_DEFEAT                              = 3,
    SAY_SUMMON_MAJ                          = 4,
    SAY_ARRIVAL2_MAJ                        = 5,
    SAY_LAST_ADD                            = 6,

    SAY_DEFEAT_2                            = 7,
    SAY_DEFEAT_3                            = 8,

    // Ragnaros event
    // Majordomo
    SAY_RAG_SUM_1                           = 9,
    SAY_RAG_SUM_2                           = 10,
    SAY_DEATH                               = 11,

    // Ragnaros
    SAY_ARRIVAL1_RAG                        = 1,
    SAY_ARRIVAL3_RAG                        = 3,
};

enum Spells
{
    SPELL_MAGIC_REFLECTION                  = 20619,
    SPELL_DAMAGE_REFLECTION                 = 21075,
    SPELL_BLAST_WAVE                        = 20229,
    SPELL_AEGIS_OF_RAGNAROS                 = 20620,
    SPELL_TELEPORT_RANDOM                   = 20618,    // Teleport random target
    SPELL_TELEPORT_TARGET                   = 20534,    // Teleport Victim
    SPELL_ENCOURAGEMENT                     = 21086,
    SPELL_CHAMPION                          = 21090,    // Server side
    SPELL_IMMUNE_POLY                       = 21087,    // Server side
    SPELL_HATE_TO_ZERO                      = 20538,    // Threat reset after each teleport. Server side
    SPELL_SEPARATION_ANXIETY                = 21094,    // Majordomo's aura on his adds; one over 40 yd casts 21095
    SPELL_SEPARATION_ANXIETY_MINION         = 21095,

    // Outro & Ragnaros intro
    SPELL_TELEPORT_SELF                     = 19484,
    SPELL_SUMMON_RAGNAROS                   = 19774,
    SPELL_ELEMENTAL_FIRE                    = 19773,
    SPELL_RAGNA_EMERGE                      = 20568,
    SPELL_RAGNAROS_FADE                     = 21107,
    SPELL_RAGNAROS_SUBMERGE_EFFECT          = 21859,    // Applies pacify state and applies all schools immunity
};

enum Events
{
    EVENT_SHIELD_REFLECTION                 = 1,
    EVENT_TELEPORT_RANDOM,
    EVENT_TELEPORT_TARGET,
    EVENT_AEGIS_OF_RAGNAROS,
    EVENT_SACRIFICIAL_CHAINS,               // CoA addition (rev_20260930_97)

    EVENT_DEFEAT_OUTRO_1                    = 1,
    EVENT_DEFEAT_OUTRO_2,
    EVENT_DEFEAT_OUTRO_3,

    EVENT_RAGNAROS_SUMMON_1                 = 1,
    EVENT_RAGNAROS_SUMMON_2,
    EVENT_RAGNAROS_SUMMON_3,
    EVENT_RAGNAROS_SUMMON_4,
    EVENT_RAGNAROS_SUMMON_5,
    EVENT_RAGNAROS_SUMMON_6,
    EVENT_RAGNAROS_SUMMON_7,
    EVENT_RAGNAROS_EMERGE,
};

enum Misc
{
    MENU_ID_RAGNAROS_SUMMON                 = 4108,

    FACTION_MAJORDOMO_FRIENDLY              = 1080,
    SUMMON_GROUP_ADDS                       = 1,

    // CoA addition: the encounter completes once Majordomo himself drops to this health floor
    // after all 8 adds are dead, not the instant the last add dies (user's own CoA play memory).
    MAJORDOMO_DEFEAT_HEALTH_PCT             = 20,

    // Points
    POINT_RAGNAROS_SUMMON                   = 1,

    // Event phases
    PHASE_NONE                              = 1,
    PHASE_COMBAT                            = 2,
    PHASE_DEFEAT_OUTRO                      = 3,
    PHASE_RAGNAROS_SUMMONING                = 4,

    // CoA addition (rev_20260930_97): Sacrificial Chains, Majordomo's periodic hostage add
    // (mc-dataset.json: 92030 in 48/49 corpus Majordomo pulls, median first spawn +29s,
    // repeating on a median ~47-50s cycle across every sampled difficulty/player count).
    NPC_SACRIFICIAL_CHAINS_COA              = 92030,
};

Position const MajordomoRagnaros = { 848.933f, -812.875f, -229.601f, 4.046f };
// CoA correction: the user stood at the room's real center and read the point off `.gps`
// directly (floor Z -120.0913), replacing the earlier add-ring-centroid estimate.
Position const MajordomoSummonPos = { 742.1174f, -1181.1216f, -120.0913f, 5.7636776f };
Position const MajordomoMoveRagPos = { 830.9636f, -814.7055f, -228.9733f, 0.0f };   // Position used at Ragnaros summoning event
Position const RagnarosSummonPos = { 838.3082f, -831.4665f, -232.1853f, 2.199115f };

// CoA correction: the user stood at the Ragnaros lair entrance and read the point off `.gps`
// directly (floor Z -228.51599), replacing the earlier estimated midpoint.
Position const RagnarosLairEntranceCoa = { 814.8772f, -851.9799f, -228.51599f, 0.7247386f };

struct MajordomoAddData
{
    ObjectGuid guid;
    uint32 creatureEntry;
    Position spawnPos;

    MajordomoAddData() { }
    MajordomoAddData(ObjectGuid _guid, uint32 _creatureEntry, Position _spawnPos) : guid(_guid), creatureEntry(_creatureEntry), spawnPos(_spawnPos) { }
};

struct boss_majordomo : public BossAI
{
    boss_majordomo(Creature* creature) : BossAI(creature, DATA_MAJORDOMO_EXECUTUS) {}

    void JustDied(Unit* /*killer*/) override
    {
        Talk(SAY_DEATH);
        me->DespawnOrUnsummon(10s, 0s);
    }

    void JustSummoned(Creature* summon) override
    {
        if (summon->GetEntry() == NPC_RAGNAROS)
        {
            summon->CastSpell(summon, SPELL_RAGNAROS_FADE);
            summon->CastSpell(summon, SPELL_RAGNAROS_SUBMERGE_EFFECT, true);
            summon->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);
            summon->SetImmuneToAll(true);
            summon->SetReactState(REACT_PASSIVE);
        }
    }

    void InitializeAI() override
    {
        BossAI::InitializeAI();
        if (instance->GetBossState(DATA_MAJORDOMO_EXECUTUS) != DONE)
        {
            events.SetPhase(PHASE_COMBAT);

            std::list<TempSummon*> p_summons;
            me->SummonCreatureGroup(SUMMON_GROUP_ADDS, &p_summons);
            if (!p_summons.empty())
            {
                for (TempSummon const* summon : p_summons)
                {
                    if (summon)
                    {
                        static_minionsGUIDS.insert(summon->GetGUID());
                        majordomoSummonsData[summon->GetGUID().GetCounter()] = MajordomoAddData(summon->GetGUID(), summon->GetEntry(), summon->GetPosition());
                    }
                }
            }
        }
        else
        {
            events.SetPhase(PHASE_NONE);
            me->SetImmuneToAll(true);
            me->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            me->SetFaction(FACTION_MAJORDOMO_FRIENDLY);
        }
    }

    void Reset() override
    {
        me->ResetLootMode();
        events.Reset();
        scheduler.CancelAll();
        aliveMinionsGUIDS.clear();
        _allAddsDefeated = false;

        if (instance->GetBossState(DATA_MAJORDOMO_EXECUTUS) != DONE)
        {
            events.SetPhase(PHASE_COMBAT);
            instance->SetBossState(DATA_MAJORDOMO_EXECUTUS, NOT_STARTED);

            for (auto const& summon : majordomoSummonsData)
            {
                if (ObjectAccessor::GetCreature(*me, summon.second.guid))
                    continue;

                if (Creature* spawn = me->SummonCreature(summon.second.creatureEntry, summon.second.spawnPos))
                {
                    static_minionsGUIDS.erase(summon.second.guid); // Erase the guid from the previous, no longer existing, spawn.
                    static_minionsGUIDS.insert(spawn->GetGUID());
                    majordomoSummonsData.erase(summon.second.guid.GetCounter());
                    majordomoSummonsData[spawn->GetGUID().GetCounter()] = MajordomoAddData(spawn->GetGUID(), spawn->GetEntry(), spawn->GetPosition());
                }
            }

            me->RemoveNpcFlag(UNIT_NPC_FLAG_GOSSIP);
        }
        else
        {
            static_minionsGUIDS.clear();
            majordomoSummonsData.clear();
            summons.DespawnAll();
        }
    }

    bool CanAIAttack(Unit const* /*target*/) const override
    {
        return instance->GetBossState(DATA_MAJORDOMO_EXECUTUS) != DONE;
    }

    void KilledUnit(Unit* victim) override
    {
        Talk(SAY_SLAY, victim);
    }

    void JustEngagedWith(Unit* /*attacker*/) override
    {
        if (!events.IsInPhase(PHASE_COMBAT))
            return;

        _JustEngagedWith();
        DoCastAOE(SPELL_SEPARATION_ANXIETY);

        // The client's Separation Anxiety is a plain aura with no tick; Majordomo checks his adds every second.
        scheduler.CancelAll();
        scheduler.Schedule(1s, [this](TaskContext context)
        {
            for (ObjectGuid const& guid : aliveMinionsGUIDS)
                EnrageIfSeparated(ObjectAccessor::GetCreature(*me, guid));
            context.Repeat();
        });

        Talk(SAY_AGGRO);
        DoCastSelf(SPELL_AEGIS_OF_RAGNAROS, true);

        events.ScheduleEvent(EVENT_SHIELD_REFLECTION, 30s, PHASE_COMBAT, PHASE_COMBAT);
        events.ScheduleEvent(EVENT_TELEPORT_RANDOM, 25s, PHASE_COMBAT, PHASE_COMBAT);
        events.ScheduleEvent(EVENT_TELEPORT_TARGET, 15s, PHASE_COMBAT, PHASE_COMBAT);

        // CoA addition (rev_20260930_97): see NPC_SACRIFICIAL_CHAINS_COA above.
        events.ScheduleEvent(EVENT_SACRIFICIAL_CHAINS, 29s, PHASE_COMBAT, PHASE_COMBAT);

        aliveMinionsGUIDS.clear();
        aliveMinionsGUIDS = static_minionsGUIDS;
    }

    void SummonedCreatureDies(Creature* summon, Unit* /*killer*/) override
    {
        aliveMinionsGUIDS.erase(summon->GetGUID());
        if (summon->GetEntry() == NPC_FLAMEWAKER_HEALER || summon->GetEntry() == NPC_FLAMEWAKER_ELITE)
        {
            uint32 const remainingAdds = std::count_if(aliveMinionsGUIDS.begin(), aliveMinionsGUIDS.end(), [](ObjectGuid const& summonGuid)
            {
                return summonGuid.GetEntry() == NPC_FLAMEWAKER_HEALER || summonGuid.GetEntry() == NPC_FLAMEWAKER_ELITE;
            });

            // Last remaining add
            if (remainingAdds == 1)
            {
                Talk(SAY_LAST_ADD);
                DoCastAOE(SPELL_CHAMPION);
            }
            // 50% of adds
            else if (remainingAdds == 4)
            {
                DoCastAOE(SPELL_IMMUNE_POLY);
            }
            else if (!remainingAdds)
            {
                static_minionsGUIDS.clear();
                _allAddsDefeated = true;

                scheduler.Schedule(500ms, [this](TaskContext context)
                {
                    if (me->GetHealthPct() <= float(MAJORDOMO_DEFEAT_HEALTH_PCT))
                    {
                        CompleteEncounter();
                        return;
                    }
                    context.Repeat(500ms);
                });
                return;
            }
            DoCastAOE(SPELL_ENCOURAGEMENT);
        }
    }

    void CompleteEncounter()
    {
        instance->SetBossState(DATA_MAJORDOMO_EXECUTUS, DONE);
        events.CancelEventGroup(PHASE_COMBAT);
        me->GetMap()->UpdateEncounterState(ENCOUNTER_CREDIT_KILL_CREATURE, me->GetEntry(), me);
        me->SetImmuneToAll(true);
        me->SetFaction(FACTION_MAJORDOMO_FRIENDLY);
        EnterEvadeMode();
        Talk(SAY_DEFEAT);
    }

    void JustReachedHome() override
    {
        _JustReachedHome();
        if (instance->GetBossState(DATA_MAJORDOMO_EXECUTUS) == DONE)
        {
            events.Reset();
            events.SetPhase(PHASE_DEFEAT_OUTRO);
            events.ScheduleEvent(EVENT_DEFEAT_OUTRO_1, 7500ms, PHASE_DEFEAT_OUTRO, PHASE_DEFEAT_OUTRO);
        }
    }

    void DamageTaken(Unit* /*attacker*/, uint32& damage, DamageEffectType /*dmgType*/, SpellSchoolMask /*school*/) override
    {
        if (!events.IsInPhase(PHASE_COMBAT))
            return;

        if (!_allAddsDefeated)
        {
            if (me->GetHealth() <= damage)
                damage = 0;
            return;
        }

        // Solo phase (all adds dead): killable down to the floor, not immune outright - the
        // recurring health check in SummonedCreatureDies completes the encounter once he gets there.
        uint32 const floor = me->CountPctFromMaxHealth(MAJORDOMO_DEFEAT_HEALTH_PCT);
        if (me->GetHealth() <= floor + damage)
            damage = me->GetHealth() > floor ? me->GetHealth() - floor : 0;
    }

    void UpdateAI(uint32 diff) override
    {

        switch (events.GetPhaseMask())
        {
            case  (1 << (PHASE_COMBAT - 1)):
            {
                if (!UpdateVictim())
                    return;

                scheduler.Update(diff);
                events.Update(diff);

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                while (uint32 const eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_SHIELD_REFLECTION:
                        {
                            if (rand_chance() <= 50.f)
                            {
                                DoCastSelf(SPELL_MAGIC_REFLECTION);
                            }
                            else
                            {
                                DoCastSelf(SPELL_DAMAGE_REFLECTION);
                            }
                            events.Repeat(30s);
                            break;
                        }
                        case EVENT_TELEPORT_RANDOM:
                        {
                            if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 0.0f, true, false))
                            {
                                DoCastSelf(SPELL_HATE_TO_ZERO, true);
                                DoCast(target, SPELL_TELEPORT_RANDOM);
                            }

                            events.Repeat(30s);
                            break;
                        }
                        case EVENT_TELEPORT_TARGET:
                        {
                            DoCastSelf(SPELL_HATE_TO_ZERO, true);
                            DoCastAOE(SPELL_TELEPORT_TARGET);
                            events.Repeat(30s);
                            break;
                        }
                        case EVENT_SACRIFICIAL_CHAINS:
                        {
                            // Corrected (diag-G3.md "Ascension evidence" #2): the chain always
                            // spawns at the same fixed point, the burning ground in the middle
                            // of Majordomo's room (MajordomoSummonPos, his own battle position),
                            // not on a random raid member -- npc_sacrificial_chains_coa.cpp owns
                            // the add's own sacrifice/heal-to-full/Berserk/teleport-and-pacify
                            // behaviour.
                            me->SummonCreature(NPC_SACRIFICIAL_CHAINS_COA, MajordomoSummonPos, TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 5 * MINUTE * IN_MILLISECONDS);
                            events.Repeat(47s);
                            break;
                        }
                    }

                    if (me->HasUnitState(UNIT_STATE_CASTING))
                        return;
                }

                DoMeleeAttackIfReady();
                break;
            }
            case (1 << (PHASE_DEFEAT_OUTRO - 1)):
            {
                events.Update(diff);
                while (uint32 const eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_DEFEAT_OUTRO_1:
                        {
                            Talk(SAY_DEFEAT_2);
                            events.ScheduleEvent(EVENT_DEFEAT_OUTRO_2, 8s, PHASE_DEFEAT_OUTRO, PHASE_DEFEAT_OUTRO);
                            break;
                        }
                        case EVENT_DEFEAT_OUTRO_2:
                        {
                            Talk(SAY_DEFEAT_3);
                            events.ScheduleEvent(EVENT_DEFEAT_OUTRO_3, 21500ms, PHASE_DEFEAT_OUTRO, PHASE_DEFEAT_OUTRO);
                            break;
                        }
                        case EVENT_DEFEAT_OUTRO_3:
                        {
                            DoCastSelf(SPELL_TELEPORT_SELF);
                            break;
                        }
                    }
                }
                break;
            }
            case (1 << (PHASE_RAGNAROS_SUMMONING - 1)):
            {
                events.Update(diff);
                while (uint32 const eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_RAGNAROS_SUMMON_1:
                        {
                            if (GameObject* lavaSplash = ObjectAccessor::GetGameObject(*me, instance->GetGuidData(DATA_LAVA_SPLASH)))
                            {
                                lavaSplash->SetRespawnTime(900);
                                lavaSplash->Refresh();
                            }
                            if (GameObject* lavaSteam = ObjectAccessor::GetGameObject(*me, instance->GetGuidData(DATA_LAVA_STEAM)))
                            {
                                lavaSteam->SetRespawnTime(900);
                                lavaSteam->Refresh();
                            }
                            Talk(SAY_RAG_SUM_2);
                            // Next event will get triggered in MovementInform
                            me->SetWalk(true);
                            me->GetMotionMaster()->MovePoint(POINT_RAGNAROS_SUMMON, MajordomoMoveRagPos, FORCED_MOVEMENT_NONE, 0.f, true, false);
                            break;
                        }
                        case EVENT_RAGNAROS_SUMMON_2:
                        {
                            if (GameObject* lavaSteam = ObjectAccessor::GetGameObject(*me, instance->GetGuidData(DATA_LAVA_STEAM)))
                            {
                                me->SetFacingToObject(lavaSteam);
                            }

                            Talk(SAY_SUMMON_MAJ);
                            events.ScheduleEvent(EVENT_RAGNAROS_SUMMON_3, 16700ms, PHASE_RAGNAROS_SUMMONING, PHASE_RAGNAROS_SUMMONING);
                            events.ScheduleEvent(EVENT_RAGNAROS_EMERGE, 15s, PHASE_RAGNAROS_SUMMONING, PHASE_RAGNAROS_SUMMONING);
                            break;
                        }
                        case EVENT_RAGNAROS_SUMMON_3:
                        {
                            if (Creature* ragnaros = ObjectAccessor::GetCreature(*me, instance->GetGuidData(DATA_RAGNAROS)))
                            {
                                ragnaros->AI()->Talk(SAY_ARRIVAL1_RAG);
                            }
                            events.ScheduleEvent(EVENT_RAGNAROS_SUMMON_4, 11700ms, PHASE_RAGNAROS_SUMMONING, PHASE_RAGNAROS_SUMMONING);
                            break;
                        }
                        case EVENT_RAGNAROS_SUMMON_4:
                        {
                            Talk(SAY_ARRIVAL2_MAJ);
                            events.ScheduleEvent(EVENT_RAGNAROS_SUMMON_5, 8700ms, PHASE_RAGNAROS_SUMMONING, PHASE_RAGNAROS_SUMMONING);
                            break;
                        }
                        case EVENT_RAGNAROS_SUMMON_5:
                        {
                            if (Creature* ragnaros = ObjectAccessor::GetCreature(*me, instance->GetGuidData(DATA_RAGNAROS)))
                            {
                                ragnaros->AI()->Talk(SAY_ARRIVAL3_RAG);
                            }

                            events.ScheduleEvent(EVENT_RAGNAROS_SUMMON_6, 16500ms, PHASE_RAGNAROS_SUMMONING, PHASE_RAGNAROS_SUMMONING);
                            break;
                        }
                        case EVENT_RAGNAROS_SUMMON_6:
                        {
                            if (Creature* ragnaros = ObjectAccessor::GetCreature(*me, instance->GetGuidData(DATA_RAGNAROS)))
                            {
                                ragnaros->CastSpell(me, SPELL_ELEMENTAL_FIRE, true);
                                ragnaros->AI()->DoAction(ACTION_FINISH_RAGNAROS_INTRO);
                            }
                            break;
                        }
                        // Additional events
                        case EVENT_RAGNAROS_EMERGE:
                        {
                            if (Creature* ragnaros = ObjectAccessor::GetCreature(*me, instance->GetGuidData(DATA_RAGNAROS)))
                            {
                                ragnaros->RemoveAurasDueToSpell(SPELL_RAGNAROS_FADE);
                                ragnaros->CastSpell(ragnaros, SPELL_RAGNA_EMERGE);
                            }
                        }break;
                    }
                }
                break;
            }
        }
    }

    void MovementInform(uint32 type, uint32 pointId) override
    {
        if (type == POINT_MOTION_TYPE && pointId == POINT_RAGNAROS_SUMMON)
        {
            DoCastAOE(SPELL_SUMMON_RAGNAROS);
            events.ScheduleEvent(EVENT_RAGNAROS_SUMMON_2, 11500ms, PHASE_RAGNAROS_SUMMONING, PHASE_RAGNAROS_SUMMONING);
        }
    }

    void SpellHit(Unit* /*caster*/, SpellInfo const* spellInfo) override
    {
        if (events.IsInPhase(PHASE_DEFEAT_OUTRO) && spellInfo->Id == SPELL_TELEPORT_SELF)
        {
            me->SetNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            me->SetHomePosition(MajordomoRagnaros);
            me->NearTeleportTo(MajordomoRagnaros.GetPositionX(), MajordomoRagnaros.GetPositionY(), MajordomoRagnaros.GetPositionZ(), MajordomoRagnaros.GetOrientation());
            events.SetPhase(PHASE_NONE);
        }
    }

    void DoAction(int32 action) override
    {
        if (action == ACTION_START_RAGNAROS_INTRO && !events.IsInPhase(PHASE_RAGNAROS_SUMMONING))
        {
            events.SetPhase(PHASE_RAGNAROS_SUMMONING);
            events.ScheduleEvent(EVENT_RAGNAROS_SUMMON_1, 5s, PHASE_RAGNAROS_SUMMONING, PHASE_RAGNAROS_SUMMONING);
        }
    }

    void sGossipSelect(Player* player, uint32 menuId, uint32 /*gossipListId*/) override
    {
        if (menuId == MENU_ID_RAGNAROS_SUMMON)
        {
            CloseGossipMenuFor(player);
            me->RemoveNpcFlag(UNIT_NPC_FLAG_GOSSIP);
            Talk(SAY_RAG_SUM_1, player);
            DoAction(ACTION_START_RAGNAROS_INTRO);
        }
    }

private:
    void EnrageIfSeparated(Creature* add)
    {
        if (add && add->IsAlive() && add->HasAura(SPELL_SEPARATION_ANXIETY, me->GetGUID()) &&
            add->GetDistance(me) > 40.0f && !add->HasAura(SPELL_SEPARATION_ANXIETY_MINION))
            add->CastSpell(add, SPELL_SEPARATION_ANXIETY_MINION, true);
    }

    GuidSet static_minionsGUIDS;    // contained data should be changed on encounter completion
    GuidSet aliveMinionsGUIDS;      // used for calculations
    std::unordered_map<uint32, MajordomoAddData> majordomoSummonsData;

    // CoA addition: he no longer yields the instant his last add dies (user report, live CoA memory
    // of a real "fight him down" phase). Set once all 8 adds are dead; DamageTaken then clamps him
    // to MAJORDOMO_DEFEAT_HEALTH_PCT instead of 100%, and a recurring health check completes the
    // encounter once he actually reaches that floor.
    bool _allAddsDefeated = false;
};

// 20538 Hate to Zero (SERVERSIDE)
class spell_hate_to_zero : public SpellScript
{
    PrepareSpellScript(spell_hate_to_zero);

    bool Load() override
    {
        return GetCaster()->IsCreature();
    }

    void HandleHit(SpellEffIndex /*effIndex*/)
    {
        if (Unit* caster = GetCaster())
            if (Creature* creatureCaster = caster->ToCreature())
                creatureCaster->GetThreatMgr().ResetAllThreat();
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_hate_to_zero::HandleHit, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// 19774 Summon Ragnaros
class spell_summon_ragnaros : public SpellScript
{
    PrepareSpellScript(spell_summon_ragnaros);

    void HandleHit()
    {
        if (Unit* caster = GetCaster())
            caster->SummonCreature(NPC_RAGNAROS, RagnarosSummonPos, TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT, 2 * HOUR * IN_MILLISECONDS);
    }

    void Register() override
    {
        AfterCast += SpellCastFn(spell_summon_ragnaros::HandleHit);
    }
};

// CoA addition: once Majordomo turns friendly, instance_molten_core.cpp summons
// go_ragnaros_portal_coa (GO_RAGNAROS_PORTAL_COA); using it teleports a player straight to the
// Ragnaros lair entrance instead of requiring the gossip-triggered summon sequence.
struct go_ragnaros_portal_coa : public GameObjectAI
{
    go_ragnaros_portal_coa(GameObject* go) : GameObjectAI(go) { }

    bool GossipHello(Player* player, bool reportUse) override
    {
        if (reportUse || !player)
            return false;

        player->TeleportTo(me->GetMapId(), RagnarosLairEntranceCoa.GetPositionX(), RagnarosLairEntranceCoa.GetPositionY(),
                            RagnarosLairEntranceCoa.GetPositionZ(), RagnarosLairEntranceCoa.GetOrientation());
        return true;
    }
};

// CoA addition: GameObject::Use() has no GAMEOBJECT_TYPE_CHEST case at all (it falls to
// default:, spellId stays 0, nothing happens) - a type-3 chest is normally opened only via
// Spell::EffectOpenLock, reached by the client auto-casting the spell matching its lock's
// LockType.dbc entry. Cache of the Firelord's lock (57) resolves through LockType 5 ("Open"),
// which SkillByLockType maps to SKILL_NONE, so CanOpenLock always succeeds with no real skill
// or key - but nothing in this core ever drives that cast for a bare GAMEOBJECT_TYPE_CHEST
// (confirmed live: neither CMSG_LOOT, guarded to creature/vehicle GUIDs only in
// WorldSession::HandleLootOpcode, nor plain CMSG_GAMEOBJ_USE ever opened the loot window).
// GossipHello fires before Use()'s switch and short-circuits it on a true return (the same
// idiom go_ragnaros_portal_coa above already uses), so this calls SendLoot directly instead of
// waiting on the unreachable lock-spell path.
struct go_cache_of_the_firelord_coa : public GameObjectAI
{
    go_cache_of_the_firelord_coa(GameObject* go) : GameObjectAI(go) { }

    bool GossipHello(Player* player, bool reportUse) override
    {
        if (reportUse || !player)
            return false;

        player->SendLoot(me->GetGUID(), LOOT_CORPSE);
        return true;
    }
};

void AddSC_boss_majordomo()
{
    RegisterMoltenCoreCreatureAI(boss_majordomo);
    RegisterMoltenCoreGameObjectAI(go_ragnaros_portal_coa);
    RegisterMoltenCoreGameObjectAI(go_cache_of_the_firelord_coa);

    // Spells
    RegisterSpellScript(spell_hate_to_zero);
    RegisterSpellScript(spell_summon_ragnaros);
}
