/*
 * Magmadar with Ascension's kit.
 *
 * The body never casts in the 42-log corpus (issue #5120): only two head
 * creatures do, "Magmadar's Right Head" and "Magmadar's Left Head"
 * (80642/80643, exiles-kit; not statically spawned anywhere in the export,
 * so this script summons them on engage, the same way Garr summons
 * Firesworn). Their kit is Enrage (2105307, self haste), Lava Burst
 * (2105355/57-59, single-target Fire hit whose real damage lives in
 * coa_spell_damage_info per rev_20260930_83), Scorching Breath (2105360-65,
 * a ticking hit on the current target, SpellDifficulty group 2099) and Lava
 * Bomb (2105366-70, a dummy that plants a persistent ground-fire patch on a
 * random target, SpellDifficulty group 2100 - the "fire puddle" the body's
 * own vanilla Lava Bomb only approximates).
 *
 * The body itself keeps its stock Frenzy/Lava Bomb timers (vanilla ids)
 * unchanged - no log ever caught them being wrong, and #5120 only says the
 * body never casts its *own* kit (Fierce Blow, Bellowing Roar, Ancient
 * Despair/Hysteria/Dread/Fury), which stays unused here for the same reason
 * Ragnaros's unmatched kit entries stay unused: no log evidence to place
 * them on a timer.
 *
 * Panic is the one body cast the corpus does measure (research-H3.md): the
 * body's real fear is Ascension's own Panic (2105309, self+area
 * SPELL_AURA_MOD_FEAR, SpellDifficultyId 0 - one id for every difficulty),
 * not the vanilla donor id (19408) this script ran before. 157-196 aura
 * applications across the 54-log corpus, caster GUID matching Magmadar's
 * body, repeat interval a flat ~40s (40.0/40.1/40.2/39.8/39.9/40.0/40.1/
 * 40.0/40.1s between nine consecutive casts) with no measured first-cast
 * offset, so only the repeat is corpus-driven below.
 *
 * The heads share Magmadar's own health pool (MC_PV video: both heads always read the same
 * figure as the body, "PV = Magmadar") - a head takes damage like any other creature, but its
 * DamageTaken hook redirects that damage onto the body and zeroes it locally, so a head never
 * dies on its own; it also mirrors the body's current health every tick for display. Killing
 * the body despawns both heads through BossAI's own summons list. See npc_magmadar_head_coa
 * below. Their per-head cast cadence and the periodic Core Hound reinforcements (entry 11671,
 * already in this instance as trash) are not in any log or export; every timer below is
 * designed, not measured, and marked as such.
 */

#include "CreatureScript.h"
#include "InstanceScript.h"
#include "ObjectAccessor.h"
#include "ScriptedCreature.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "../../../src/server/scripts/EasternKingdoms/BlackrockMountain/MoltenCore/molten_core.h"

#include <algorithm>

namespace
{
    enum MagmadarCoaTexts
    {
        EMOTE_FRENZY_COA                = 0,
    };

    enum MagmadarCoaSpells
    {
        // Body - stock, unchanged (measured: never seen casting anything else)
        SPELL_FRENZY_COA                = 19451,
        SPELL_PANIC_COA                 = 2105309, // measured (research-H3.md); vanilla donor was 19408
        SPELL_LAVA_BOMB_MELEE_COA       = 19411,
        SPELL_LAVA_BOMB_RANGED_COA      = 20474,

        // Heads
        SPELL_HEAD_ENRAGE               = 2105307,
        SPELL_HEAD_LAVA_BURST           = 2105357, // coa_spell_damage_info: 2105351-54
        SPELL_HEAD_SCORCHING_BREATH     = 2105360,
        SPELL_HEAD_LAVA_BOMB            = 2105366,
    };

    enum MagmadarCoaCreatures
    {
        NPC_MAGMADAR_HEAD_RIGHT           = 80642,
        NPC_MAGMADAR_HEAD_LEFT            = 80643,
        NPC_MC_CORE_HOUND_COA             = 11671,
    };

    enum MagmadarCoaEvents
    {
        EVENT_FRENZY_COA = 1,
        EVENT_PANIC_COA,
        EVENT_LAVA_BOMB_MELEE_COA,
        EVENT_LAVA_BOMB_RANGED_COA,
        EVENT_CORE_HOUND_SPAWN_COA,
    };

    enum MagmadarHeadEvents
    {
        EVENT_HEAD_ENRAGE = 1,
        EVENT_HEAD_LAVA_BURST,
        EVENT_HEAD_SCORCHING_BREATH,
        EVENT_HEAD_LAVA_BOMB,
    };

    constexpr float MELEE_TARGET_LOOKUP_DIST = 10.0f;
    constexpr float HEAD_OFFSET_DIST = 3.0f;
    constexpr float HEAD_OFFSET_ANGLE = 0.55f;

    struct npc_magmadar_head_coa;

    struct boss_magmadar_coa : public BossAI
    {
        boss_magmadar_coa(Creature* creature) : BossAI(creature, DATA_MAGMADAR) { }

        // Heads are summoned here, not at engage, so they stand next to the body before the pull
        // (player report). _Reset() already despawns any previous summons (including a wipe's),
        // so this both prevents duplicates and respawns a fresh pair after every evade.
        void Reset() override
        {
            _Reset();
            SummonHeads();
        }

        void SummonHeads()
        {
            if (Creature* head = DoSummon(NPC_MAGMADAR_HEAD_RIGHT, me->GetNearPosition(HEAD_OFFSET_DIST, -HEAD_OFFSET_ANGLE),
                                           0, TEMPSUMMON_MANUAL_DESPAWN))
                SetHeadPassive(head);
            if (Creature* head = DoSummon(NPC_MAGMADAR_HEAD_LEFT, me->GetNearPosition(HEAD_OFFSET_DIST, HEAD_OFFSET_ANGLE),
                                           0, TEMPSUMMON_MANUAL_DESPAWN))
                SetHeadPassive(head);
        }

        static void SetHeadPassive(Creature* head)
        {
            head->SetReactState(REACT_PASSIVE);
            head->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        }

        void JustEngagedWith(Unit* /*who*/) override
        {
            _JustEngagedWith();
            events.ScheduleEvent(EVENT_FRENZY_COA, 8500ms);
            events.ScheduleEvent(EVENT_PANIC_COA, 9500ms);
            events.ScheduleEvent(EVENT_LAVA_BOMB_MELEE_COA, 12s);
            events.ScheduleEvent(EVENT_LAVA_BOMB_RANGED_COA, 15s);
            // Designed: no log measures the heads or the hound adds, only
            // that #5120 says the heads exist and cast, and the player
            // report asks for periodic Core Hound reinforcements.
            events.ScheduleEvent(EVENT_CORE_HOUND_SPAWN_COA, 45s);

            ActivateHeads();
        }

        void ActivateHeads();

        void ExecuteEvent(uint32 eventId) override
        {
            switch (eventId)
            {
                case EVENT_FRENZY_COA:
                {
                    Talk(EMOTE_FRENZY_COA);
                    DoCastSelf(SPELL_FRENZY_COA);
                    events.Repeat(15s, 20s);
                    break;
                }
                case EVENT_PANIC_COA:
                {
                    DoCastVictim(SPELL_PANIC_COA);
                    events.Repeat(40s); // measured (research-H3.md): flat ~40s, no jitter
                    break;
                }
                case EVENT_LAVA_BOMB_MELEE_COA:
                {
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, MELEE_TARGET_LOOKUP_DIST, true))
                        DoCast(target, SPELL_LAVA_BOMB_MELEE_COA);

                    events.Repeat(12s, 15s);
                    break;
                }
                case EVENT_LAVA_BOMB_RANGED_COA:
                {
                    std::list<Unit*> targets;
                    SelectTargetList(targets, 1, SelectTargetMethod::Random, 1, [this](Unit* target)
                    {
                        return target && target->IsPlayer() && target->GetDistance(me) > MELEE_TARGET_LOOKUP_DIST
                               && target->GetDistance(me) < 100.0f;
                    });

                    if (!targets.empty())
                        DoCast(targets.front(), SPELL_LAVA_BOMB_RANGED_COA);
                    events.Repeat(12s, 15s);
                    break;
                }
                case EVENT_CORE_HOUND_SPAWN_COA:
                {
                    // Designed: 2 hounds, no confirmed count or cadence.
                    for (uint8 i = 0; i < 2; ++i)
                        DoSummon(NPC_MC_CORE_HOUND_COA, me->GetRandomNearPosition(8.0f), 0, TEMPSUMMON_CORPSE_TIMED_DESPAWN);
                    events.Repeat(50s);
                    break;
                }
            }
        }
    };

    struct npc_magmadar_head_coa : public ScriptedAI
    {
        npc_magmadar_head_coa(Creature* creature) : ScriptedAI(creature) { }

        // Video evidence (MC_PV): the heads' displayed health always reads the same figure as
        // Magmadar's own ("PV = Magmadar" on both heads, every reading). A single shared pool
        // is modelled by redirecting whatever a head takes into the body (DamageTaken below,
        // same pattern as npc_heart_of_hakkar_coa) and zeroing the head's own damage, so the
        // heads never die on their own; they still mirror the body's current health every tick
        // (below) instead of splitting the flex total into three independent pools.
        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask /*school*/) override
        {
            uint32 const dealt = damage;
            damage = 0;
            if (!dealt || !attacker)
                return;

            InstanceScript* instance = me->GetInstanceScript();
            Creature* body = instance ? ObjectAccessor::GetCreature(*me, instance->GetGuidData(DATA_MAGMADAR)) : nullptr;
            if (!body || body == me || !body->IsAlive())
                return;

            Unit::DealDamage(attacker, body, dealt, nullptr, type, SPELL_SCHOOL_MASK_NORMAL, nullptr, false);
        }

        // Called by the body's own JustEngagedWith once Magmadar is pulled: the head stands
        // passive/unselectable since SummonHeads(), so it never engages on its own.
        void Activate()
        {
            me->SetReactState(REACT_AGGRESSIVE);
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);

            // Summoned in Reset(), before Magmadar ever engages, so BossAI::JustSummoned's own
            // "if (me->IsEngaged()) DoZoneInCombat(summon)" branch never ran for these heads the
            // way it did when they were summoned from JustEngagedWith; do it explicitly here so
            // UpdateVictim() succeeds and the schedule below actually runs.
            DoZoneInCombat();

            // Designed cadence: staggered by head so both do not sync casts.
            bool const isRightHead = me->GetEntry() % 100000 == NPC_MAGMADAR_HEAD_RIGHT;
            events.ScheduleEvent(EVENT_HEAD_ENRAGE, 25s);
            events.ScheduleEvent(EVENT_HEAD_LAVA_BURST, isRightHead ? 4s : 7s);
            events.ScheduleEvent(EVENT_HEAD_SCORCHING_BREATH, isRightHead ? 9s : 13s);
            events.ScheduleEvent(EVENT_HEAD_LAVA_BOMB, isRightHead ? 6s : 11s);
        }

        void ExecuteEvent(uint32 eventId)
        {
            switch (eventId)
            {
                case EVENT_HEAD_ENRAGE:
                    DoCastSelf(SPELL_HEAD_ENRAGE, true);
                    events.Repeat(25s);
                    break;
                case EVENT_HEAD_LAVA_BURST:
                    DoCastVictim(SPELL_HEAD_LAVA_BURST);
                    events.Repeat(10s, 13s);
                    break;
                case EVENT_HEAD_SCORCHING_BREATH:
                    DoCastVictim(SPELL_HEAD_SCORCHING_BREATH);
                    events.Repeat(16s, 20s);
                    break;
                case EVENT_HEAD_LAVA_BOMB:
                    if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, 100.0f, true))
                        DoCast(target, SPELL_HEAD_LAVA_BOMB);
                    events.Repeat(14s, 18s);
                    break;
            }
        }

        void UpdateAI(uint32 diff) override
        {
            if (InstanceScript* instance = me->GetInstanceScript())
                if (Creature* body = ObjectAccessor::GetCreature(*me, instance->GetGuidData(DATA_MAGMADAR)))
                    if (body->IsAlive() && me->IsAlive())
                        me->SetHealth(std::min(body->GetHealth(), me->GetMaxHealth()));

            if (!UpdateVictim())
                return;

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
                ExecuteEvent(eventId);
        }

    private:
        EventMap events;
    };

    void boss_magmadar_coa::ActivateHeads()
    {
        for (ObjectGuid const& guid : summons)
            if (Creature* summon = ObjectAccessor::GetCreature(*me, guid))
                if (npc_magmadar_head_coa* headAI = dynamic_cast<npc_magmadar_head_coa*>(summon->AI()))
                    headAI->Activate();
    }
}

// 2105361 Scorching Breath - Hidden - Hit Dummy
class spell_magmadar_head_scorching_breath_tick : public SpellScript
{
    PrepareSpellScript(spell_magmadar_head_scorching_breath_tick);

    enum
    {
        SPELL_HEAD_SCORCHING_BREATH_DAMAGE = 2105362, // SpellDifficulty group 2099
    };

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        if (Unit* caster = GetCaster())
            if (Unit* target = GetHitUnit())
                caster->CastSpell(target, SPELL_HEAD_SCORCHING_BREATH_DAMAGE, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_magmadar_head_scorching_breath_tick::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

// 2105366 Lava Bomb (heads)
class spell_magmadar_head_lava_bomb : public SpellScript
{
    PrepareSpellScript(spell_magmadar_head_lava_bomb);

    enum
    {
        SPELL_HEAD_LAVA_BOMB_EFFECT = 2105367, // SpellDifficulty group 2100, persistent ground fire
    };

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ SPELL_HEAD_LAVA_BOMB_EFFECT });
    }

    void HandleDummy(SpellEffIndex /*effIndex*/)
    {
        // Unlike the body's own vanilla Lava Bomb (a GO trap spell, where the vanilla script's
        // target->CastSpell(target, ...) idiom is harmless), this follow-up is a
        // SPELL_EFFECT_PERSISTENT_AREA_AURA at TARGET_UNIT_DEST_AREA_ENEMY: Spell::EffectPersistentAA
        // and Spell::SelectImplicitAreaTargets both key the "enemy" search and the DynamicObject's
        // owner off m_caster, not the original caster. Casting it as the hit player (target->CastSpell)
        // makes the ground fire search for the *player's* enemies, i.e. hostile NPCs, so it never
        // finds any raid member and the puddle silently applies to nobody. Casting it as the head
        // (same as spell_magmadar_head_scorching_breath_tick's caster->CastSpell) keeps the area
        // search hostile to players, while GetExplicitTargetMask() still anchors the destination on
        // the hit target's own position (InitExplicitTargets falls back to the unit target for
        // TARGET_FLAG_DEST_LOCATION).
        if (Unit* caster = GetCaster())
            if (Unit* target = GetHitUnit())
                caster->CastSpell(target, SPELL_HEAD_LAVA_BOMB_EFFECT, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_magmadar_head_lava_bomb::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

void AddCoaMagmadarScripts()
{
    RegisterMoltenCoreCreatureAI(boss_magmadar_coa);
    RegisterMoltenCoreCreatureAI(npc_magmadar_head_coa);

    RegisterSpellScript(spell_magmadar_head_scorching_breath_tick);
    RegisterSpellScript(spell_magmadar_head_lava_bomb);
}
