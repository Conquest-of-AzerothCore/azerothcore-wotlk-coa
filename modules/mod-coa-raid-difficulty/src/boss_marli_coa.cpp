/*
 * High Priestess Mar'li with Ascension's spells.
 *
 * Kit: Ascension's block 2118100-2118151. Timings: a Bronzebeard kill on video,
 * see raid-difficulty-werkzeug/zg-video-zeitplan.json. Stock swaps between
 * troll and spider every minute; on Ascension she stays a troll until 50% and
 * a spider after (in the video from 49%, 230s in). The spider form's cycle
 * (Web Spray, Burrow, Poison Shock every 45s) and Fierce Blow follow the CoA
 * combat log of 2026-08-02; on Mythic and Ascended the cycle is 58s (the CoA
 * Mythic log of 2026-08-04: 58.5s; Bronzebeard Ascended, 2025-12-21: 56-58s).
 *
 *   Both forms
 *     Poison Bolt Volley first 12s, every 15s   everyone, stacking poison
 *     Hatch Eggs         first 17s, every 30s   the ten eggs nearest the players
 *                                               hatch 10s later, one spider each
 *                                               (a DBM bar in the live video of
 *                                               2026-08-04; count and delay:
 *                                               tester, live, 2026-11-04)
 *     Fierce Blow        tank, first 6.7-17.3s, then every 6-10s
 *
 *   Troll form
 *     Drain Life         first 6s,  every 10s   random player, interruptible
 *     Evolve             first 22s, every 60s   an egg swells and hatches a
 *                                               colossal spider 10s later;
 *                                               Mythic and Ascended only (tester,
 *                                               round 5)
 *
 *   At 50% she drains the Avatar of Shadra (see LoaAvatar), taking ~1% damage
 *   while it dies; then the Gift of the Blood God and her spider form.
 *
 *   Spider form, when the avatar dies
 *     Acid Spit          first 1s,  every 12s   on the tank, poison and -10% armour
 *     Web Spray          first 15s, every cycle everyone within 35 yards (the
 *                                               spell's own 20 widened: tester,
 *                                               2026-11-08) is slowed, then
 *                                               webbed; then she charges a
 *                                               caster, as in stock
 *     Burrow             first 20.5s, every cycle under ground for 3s, untargetable
 *                                               and hidden (the Hide Body display
 *                                               of Burrow's misc value 24417, as
 *                                               Kurinnaxx's Tunneling);
 *                                               she comes up where the player
 *                                               farthest from her stands (tester,
 *                                               2026-11-12) and stays on
 *                                               them for 8s, untauntable (tester,
 *                                               live, 2026-11-04); on Mythic and
 *                                               Ascended for 21s, through Poison
 *                                               Shock and about 15s of melee (the
 *                                               Mythic log: 12-19s on non-tanks)
 *     Poison Shock       1.8s after she comes up (both logs), Poison Nova,
 *                                               20 yards around her, less the
 *                                               farther away
 *     Infest             first 15s, every 60s   Ascended only: an egg hatches a
 *                                               festering spider that carries
 *                                               Putrid Cloud and leaves a
 *                                               Festering Cloud where it dies
 *                                               (the Ascended log of 2025-12-21)
 *     Furious Strikes    passive, her hits speed her up
 *
 * Decided here, not in the data:
 *   - Infest acts on an egg she hatches for it at once (live, its egg hatches
 *     about 15s later);
 *   - Evolve cannot target the egg object, so the egg takes Evolve's scale and
 *     the spawn it hatches 10s later takes Evolve itself (three times the size,
 *     twice the health) and never grows (live, 2026-08-04: the egg hatched
 *     10.2s after Evolve, a spider without Growth);
 *   - the festering spawn is a Spawn of Mar'li (15041), estimated: the live
 *     Festering Spawn of Mar'li has no creature data in any source;
 *   - Drain Life heals her for what each tick deals;
 *   - Poison Nova falls off evenly to nothing at 20 yards (the tooltip says
 *     reduced, not by how much);
 *   - her hunted player carries Menacing Gaze from the kit while she is fixed
 *     on them (no combat log shows it).
 */

#include "Containers.h"
#include "CreatureScript.h"
#include "GameObject.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "../../../src/server/scripts/EasternKingdoms/ZulGurub/zulgurub.h"
#include "zg_coa_common.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <list>
#include <vector>

using namespace coa_zg;

namespace
{
    enum Says
    {
        SAY_AGGRO        = 0,
        SAY_TRANSFORM    = 1,
        SAY_SPIDER_SPAWN = 2,
        SAY_DEATH        = 3
    };

    enum Spells
    {
        SPELL_THRASH              = 3391,
        SPELL_CHARGE              = 22911,

        INFO_DRAIN_LIFE           = 2118101,
        SPELL_DRAIN_LIFE          = 2118105,
        SPELL_DRAIN_LIFE_SPLASH   = 2118106,
        SPELL_DRAIN_LIFE_TICK     = 2118107,
        SPELL_DRAIN_LIFE_HEAL     = 2118108,
        SPELL_POISON_BOLT_VOLLEY  = 2118109,
        SPELL_POISON_BOLT_HIT     = 2118110,
        SPELL_HATCH_EGGS          = 2118115,
        SPELL_EVOLVE              = 2118116,
        SPELL_DRAIN_POWER         = 2118122,
        SPELL_ASPECT_OF_SHADRA    = 2118123,
        SPELL_GIFT_OF_THE_BLOOD_GOD = 2118124,
        SPELL_FURIOUS_STRIKES     = 2118125,
        SPELL_ACID_SPIT           = 2118127,
        SPELL_ACID_SPIT_DOT       = 2118128,
        SPELL_CORROSION           = 2118132,
        SPELL_WEB_SPRAY           = 2118133,
        SPELL_POISON_SHOCK        = 2118145,
        SPELL_POISON_SHOCK_HIT    = 2118146,
        SPELL_BURROW              = 2118140,
        SPELL_MENACING_GAZE       = 2118141,
        SPELL_POISON_NOVA         = 2118150,
        SPELL_INFEST              = 2118151,
        SPELL_PUTRID_CLOUD        = 2118170,
        SPELL_FESTERING_CLOUD     = 2118176,
    };

    enum Misc
    {
        GO_SPIDER_EGGS     = 179985,
        NPC_SPAWN_OF_MARLI = 15041,
        NPC_AVATAR_OF_SHADRA = 666990
    };

    enum Events
    {
        EVENT_THRASH = 1,
        EVENT_DRAIN_LIFE,
        EVENT_POISON_BOLT_VOLLEY,
        EVENT_HATCH_EGGS,
        EVENT_OPEN_EGGS,
        EVENT_EVOLVE,
        EVENT_HATCH_EVOLVED_EGG,
        EVENT_INFEST,
        EVENT_ACID_SPIT,
        EVENT_WEB_SPRAY,
        EVENT_CHARGE,
        EVENT_POISON_SHOCK,
        EVENT_BURROW,
        EVENT_EMERGE,
        EVENT_END_HUNT,
        EVENT_FIERCE_BLOW,
    };

    enum Phases
    {
        PHASE_TROLL  = 1,
        PHASE_SPIDER = 2
    };

    constexpr float VOLLEY_RANGE   = 200.0f;
    constexpr uint8 EGGS_PER_HATCH = 10;
    constexpr float NOVA_RANGE     = 20.0f;
    constexpr float WEB_SPRAY_RANGE = 35.0f;
    constexpr uint32 DISPLAY_HIDE_BODY = 22452;
    constexpr Milliseconds BURROW_LENGTH        = 3s;
    constexpr Milliseconds HUNT_LENGTH          = 8s;
    constexpr Milliseconds HUNT_LENGTH_MYTHIC   = 21s;
    constexpr Milliseconds SPIDER_CYCLE         = 45s;
    constexpr Milliseconds SPIDER_CYCLE_MYTHIC  = 58s;
    constexpr Milliseconds POISON_SHOCK_AFTER_EMERGE = 1800ms;
    constexpr Milliseconds HATCH_EVERY          = 30s;
    constexpr Milliseconds HATCH_DELAY          = 10s;
    constexpr float EGG_SEARCH_RANGE = 100.0f;
    constexpr float DRAIN_LIFE_RANGE = 100.0f;
    constexpr float DRAIN_LIFE_SPLASH_SHARE = 0.32f;
    constexpr uint8 MYTHIC_SPAWN_MODE = 2;
    constexpr uint8 INFEST_MIN_SPAWN_MODE = 3;
    constexpr float HUNT_THREAT    = 1000000.0f;

    struct boss_marli_coa : public BossAI
    {
        boss_marli_coa(Creature* creature) : BossAI(creature, DATA_MARLI) { }

        void Reset() override
        {
            me->RemoveAurasDueToSpell(SPELL_ASPECT_OF_SHADRA);
            me->RemoveAurasDueToSpell(SPELL_FURIOUS_STRIKES);
            me->RemoveAurasDueToSpell(SPELL_GIFT_OF_THE_BLOOD_GOD);
            _avatar.Restore(me);
            _spider = false;
            _festering.clear();
            _usedEggs.clear();
            _hatchingEggs.clear();
            ShrinkEvolvedEgg();
            EndDrainLifeSplash();
            EndHunt();
            Emerge();

            std::list<GameObject*> eggs;
            me->GetGameObjectListWithEntryInGrid(eggs, GO_SPIDER_EGGS, DEFAULT_VISIBILITY_INSTANCE);
            for (GameObject* egg : eggs)
            {
                egg->Respawn();
                egg->UpdateObjectVisibility();
            }
            BossAI::Reset();
        }

        void JustEngagedWith(Unit* who) override
        {
            BossAI::JustEngagedWith(who);
            Talk(SAY_AGGRO);
            _avatar.Restore(me);

            events.SetPhase(PHASE_TROLL);
            events.ScheduleEvent(EVENT_THRASH, 4s, 6s);
            events.ScheduleEvent(EVENT_DRAIN_LIFE, 6s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_POISON_BOLT_VOLLEY, 12s);
            events.ScheduleEvent(EVENT_HATCH_EGGS, 17s);
            if (MythicOrHigher())
                events.ScheduleEvent(EVENT_EVOLVE, 22s, 0, PHASE_TROLL);
            events.ScheduleEvent(EVENT_FIERCE_BLOW, FIERCE_BLOW_FIRST_MIN, FIERCE_BLOW_FIRST_MAX);
        }

        void JustDied(Unit* killer) override
        {
            ShrinkEvolvedEgg();
            EndDrainLifeSplash();
            EndHunt();
            BossAI::JustDied(killer);
            _avatar.Release(me);
            Talk(SAY_DEATH);
        }

        void DamageTaken(Unit* attacker, uint32& damage, DamageEffectType type, SpellSchoolMask school) override
        {
            BossAI::DamageTaken(attacker, damage, type, school);

            if (_spider || !me->HealthBelowPctDamaged(50, damage))
                return;

            _spider = true;
            if (!_avatar.Drain(me))
                TakeSpiderForm();
        }

        void TakeSpiderForm()
        {
            me->InterruptNonMeleeSpells(false);
            Talk(SAY_TRANSFORM);
            DoCastSelf(SPELL_GIFT_OF_THE_BLOOD_GOD, true);
            DoCastSelf(SPELL_ASPECT_OF_SHADRA, true);
            DoCastSelf(SPELL_FURIOUS_STRIKES, true);

            events.SetPhase(PHASE_SPIDER);
            events.ScheduleEvent(EVENT_ACID_SPIT, 1s, 0, PHASE_SPIDER);
            events.ScheduleEvent(EVENT_WEB_SPRAY, 15s, 0, PHASE_SPIDER);
            events.ScheduleEvent(EVENT_BURROW, 20500ms, 0, PHASE_SPIDER);
            if (me->GetMap()->GetSpawnMode() >= INFEST_MIN_SPAWN_MODE)
                events.ScheduleEvent(EVENT_INFEST, 15s, 0, PHASE_SPIDER);
        }

        bool MythicOrHigher() const
        {
            return me->GetMap()->GetSpawnMode() >= MYTHIC_SPAWN_MODE;
        }

        Milliseconds SpiderCycle() const
        {
            return MythicOrHigher() ? SPIDER_CYCLE_MYTHIC : SPIDER_CYCLE;
        }

        void OnSpellCast(SpellInfo const* spell) override
        {
            BossAI::OnSpellCast(spell);

            switch (spell->Id)
            {
                case SPELL_POISON_BOLT_VOLLEY:
                    for (Player* p : PlayersWithin(me, VOLLEY_RANGE))
                        me->CastSpell(p, SPELL_POISON_BOLT_HIT, true);
                    break;
                case SPELL_DRAIN_LIFE:
                    DrainLifeSplash();
                    break;
                case SPELL_HATCH_EGGS:
                    Talk(SAY_SPIDER_SPAWN);
                    ClaimEggsNearPlayers();
                    break;
                case SPELL_ACID_SPIT:
                    if (Unit* tank = me->GetVictim())
                    {
                        me->CastSpell(tank, SPELL_ACID_SPIT_DOT, true);
                        me->CastSpell(tank, SPELL_CORROSION, true);
                    }
                    break;
                case SPELL_POISON_SHOCK:
                {
                    int32 const full = Info(me, SPELL_POISON_SHOCK_HIT);
                    for (Player* p : PlayersWithin(me, NOVA_RANGE))
                        Hit(me, p, SPELL_POISON_NOVA, int32(full * (1.0f - me->GetDistance(p) / NOVA_RANGE)));
                    break;
                }
                case SPELL_WEB_SPRAY:
                    for (Player* p : PlayersWithin(me, WEB_SPRAY_RANGE))
                        if (!p->HasAura(SPELL_WEB_SPRAY, me->GetGUID()) && me->IsWithinLOSInMap(p))
                            me->AddAura(SPELL_WEB_SPRAY, p);
                    break;
                case SPELL_BURROW:
                    me->AttackStop();
                    me->SetReactState(REACT_PASSIVE);
                    me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
                    me->SetDisplayId(DISPLAY_HIDE_BODY);
                    events.ScheduleEvent(EVENT_EMERGE, BURROW_LENGTH, 0, PHASE_SPIDER);
                    break;
                default:
                    break;
            }
        }

        void SpellHitTarget(Unit* target, SpellInfo const* spell) override
        {
            switch (spell->Id)
            {
                case SPELL_EVOLVE:
                    target->SetMaxHealth(target->GetMaxHealth() * 2);
                    target->SetFullHealth();
                    break;
                case SPELL_INFEST:
                    _festering.insert(target->GetGUID());
                    target->CastSpell(target, SPELL_PUTRID_CLOUD, true);
                    break;
                // Drain Life heals her for what each tick deals.
                case SPELL_DRAIN_LIFE_TICK:
                {
                    int32 heal = Info(me, INFO_DRAIN_LIFE);
                    me->CastCustomSpell(me, SPELL_DRAIN_LIFE_HEAL, &heal, nullptr, nullptr, true);
                    break;
                }
                default:
                    break;
            }
        }

        // A festering spawn bursts into a Festering Cloud where it dies.
        void SummonedCreatureDies(Creature* summon, Unit* killer) override
        {
            BossAI::SummonedCreatureDies(summon, killer);
            if (!_festering.erase(summon->GetGUID()))
                return;
            me->CastSpell(summon->GetPositionX(), summon->GetPositionY(), summon->GetPositionZ(),
                SPELL_FESTERING_CLOUD, true);
        }

        void OnChannelFinished(SpellInfo const* spell) override
        {
            if (spell->Id == SPELL_DRAIN_LIFE)
                _drainSplashed.clear();
        }

        void DrainLifeSplash()
        {
            std::vector<Player*> raid = PlayersWithin(me, DRAIN_LIFE_RANGE);
            size_t const count = size_t(std::lround(raid.size() * DRAIN_LIFE_SPLASH_SHARE));
            std::erase_if(raid, [this](Player const* p) { return p->GetGUID() == _drainTarget; });
            Acore::Containers::RandomShuffle(raid);
            raid.resize(std::min(raid.size(), count));
            for (Player* p : raid)
            {
                me->CastCustomSpell(p, SPELL_DRAIN_LIFE_SPLASH, nullptr, &_drainTick, nullptr, true);
                _drainSplashed.push_back(p->GetGUID());
            }
        }

        bool DrainingLife() const
        {
            Spell const* channel = me->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
            return channel && channel->GetSpellInfo()->Id == SPELL_DRAIN_LIFE;
        }

        void EndDrainLifeSplash()
        {
            for (ObjectGuid const& guid : _drainSplashed)
                if (Player* p = ObjectAccessor::GetPlayer(*me, guid))
                    p->RemoveAurasDueToSpell(SPELL_DRAIN_LIFE_SPLASH, me->GetGUID());
            _drainSplashed.clear();
        }

        void KilledUnit(Unit* victim) override
        {
            if (victim->GetGUID() == _hunted)
            {
                events.CancelEvent(EVENT_END_HUNT);
                EndHunt();
            }
        }

        void Emerge()
        {
            me->RemoveAurasDueToSpell(SPELL_BURROW);
            if (me->GetDisplayId() == DISPLAY_HIDE_BODY)
                me->RestoreDisplayId();
            me->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_NON_ATTACKABLE);
            me->SetReactState(REACT_AGGRESSIVE);
        }

        void EmergeAtFarthest()
        {
            Unit* prey = SelectTarget(SelectTargetMethod::MaxDistance, 0, 0.0f, true);
            if (prey)
                me->NearTeleportTo(prey->GetPositionX(), prey->GetPositionY(), prey->GetPositionZ(),
                    me->GetAngle(prey));
            Emerge();
            if (prey)
                Hunt(prey);
        }

        void Hunt(Unit* prey)
        {
            _hunted = prey->GetGUID();
            _huntThreat = HighestThreat() * 2.0f + HUNT_THREAT;
            me->AddAura(SPELL_MENACING_GAZE, prey);
            me->GetThreatMgr().AddThreat(prey, _huntThreat, nullptr, true, true);
            me->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_ATTACK_ME, true);
            me->ApplySpellImmune(0, IMMUNITY_STATE, SPELL_AURA_MOD_TAUNT, true);
            AttackStart(prey);
            events.ScheduleEvent(EVENT_END_HUNT, MythicOrHigher() ? HUNT_LENGTH_MYTHIC : HUNT_LENGTH, 0, PHASE_SPIDER);
        }

        void EndHunt()
        {
            me->ApplySpellImmune(0, IMMUNITY_EFFECT, SPELL_EFFECT_ATTACK_ME, false);
            me->ApplySpellImmune(0, IMMUNITY_STATE, SPELL_AURA_MOD_TAUNT, false);
            if (Unit* prey = ObjectAccessor::GetUnit(*me, _hunted))
            {
                prey->RemoveAurasDueToSpell(SPELL_MENACING_GAZE, me->GetGUID());
                if (_huntThreat > 0.0f && me->GetThreatMgr().GetThreat(prey) >= _huntThreat)
                    me->GetThreatMgr().AddThreat(prey, -_huntThreat, nullptr, true, true);
            }
            _hunted.Clear();
            _huntThreat = 0.0f;
        }

        float HighestThreat() const
        {
            float highest = 0.0f;
            for (ThreatReference const* ref : me->GetThreatMgr().GetUnsortedThreatList())
                highest = std::max(highest, ref->GetThreat());
            return highest;
        }

        std::vector<GameObject*> FreeEggs()
        {
            std::list<GameObject*> eggs;
            me->GetGameObjectListWithEntryInGrid(eggs, GO_SPIDER_EGGS, EGG_SEARCH_RANGE);
            std::vector<GameObject*> free;
            for (GameObject* egg : eggs)
                if (egg->isSpawned() && !_usedEggs.count(egg->GetGUID()))
                    free.push_back(egg);
            return free;
        }

        // Hatch Eggs marks the eggs nearest the raid; each hatches one spider after HATCH_DELAY.
        void ClaimEggsNearPlayers()
        {
            std::vector<Player*> const players = PlayersWithin(me, EGG_SEARCH_RANGE);
            if (players.empty())
                return;

            auto distanceToRaid = [&players](GameObject const* egg)
            {
                float nearest = std::numeric_limits<float>::max();
                for (Player const* p : players)
                    nearest = std::min(nearest, egg->GetDistance(p));
                return nearest;
            };

            std::vector<GameObject*> eggs = FreeEggs();
            std::sort(eggs.begin(), eggs.end(), [&](GameObject const* a, GameObject const* b)
            {
                return distanceToRaid(a) < distanceToRaid(b);
            });
            if (eggs.size() > EGGS_PER_HATCH)
                eggs.resize(EGGS_PER_HATCH);
            if (eggs.empty())
                return;

            for (GameObject* egg : eggs)
            {
                _usedEggs.insert(egg->GetGUID());
                _hatchingEggs.push_back(egg->GetGUID());
            }
            events.ScheduleEvent(EVENT_OPEN_EGGS, HATCH_DELAY);
        }

        void OpenClaimedEggs()
        {
            for (ObjectGuid const& guid : _hatchingEggs)
                if (GameObject* egg = ObjectAccessor::GetGameObject(*me, guid))
                    if (egg->isSpawned())
                        HatchEgg(egg);
            _hatchingEggs.clear();
        }

        GameObject* ClaimNearestEgg()
        {
            GameObject* nearest = nullptr;
            for (GameObject* egg : FreeEggs())
                if (!nearest || me->GetDistance(egg) < me->GetDistance(nearest))
                    nearest = egg;
            if (nearest)
                _usedEggs.insert(nearest->GetGUID());
            return nearest;
        }

        Creature* HatchNearestEgg()
        {
            GameObject* egg = ClaimNearestEgg();
            return egg ? HatchEgg(egg) : nullptr;
        }

        void EvolveNearestEgg()
        {
            ShrinkEvolvedEgg();
            GameObject* egg = ClaimNearestEgg();
            if (!egg)
                return;

            _evolvedEgg = egg->GetGUID();
            _evolvedEggScale = egg->GetObjectScale();
            egg->SetObjectScale(_evolvedEggScale + CalculatePct(1.0f, Info(me, SPELL_EVOLVE, EFFECT_1)));
            events.ScheduleEvent(EVENT_HATCH_EVOLVED_EGG, HATCH_DELAY);
        }

        void HatchEvolvedEgg()
        {
            GameObject* egg = ShrinkEvolvedEgg();
            if (!egg || !egg->isSpawned())
                return;
            if (Creature* spawn = HatchEgg(egg))
                DoCast(spawn, SPELL_EVOLVE, true);
        }

        GameObject* ShrinkEvolvedEgg()
        {
            GameObject* egg = _evolvedEgg ? ObjectAccessor::GetGameObject(*me, _evolvedEgg) : nullptr;
            if (egg)
                egg->SetObjectScale(_evolvedEggScale);
            _evolvedEgg.Clear();
            return egg;
        }

        Creature* HatchEgg(GameObject* egg)
        {
            Creature* spawn = me->SummonCreature(NPC_SPAWN_OF_MARLI, egg->GetPosition(), TEMPSUMMON_CORPSE_TIMED_DESPAWN, 60000);
            egg->SetLootState(GO_JUST_DEACTIVATED);
            if (spawn)
                spawn->SetInCombatWithZone();
            return spawn;
        }

        void UpdateAI(uint32 diff) override
        {
            if (!UpdateVictim())
                return;

            if (!_drainSplashed.empty() && !DrainingLife())
                EndDrainLifeSplash();

            if (_avatar.Consumed(me))
                TakeSpiderForm();

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_THRASH:
                        DoCastVictim(SPELL_THRASH);
                        events.ScheduleEvent(EVENT_THRASH, 10s, 20s);
                        break;
                    case EVENT_DRAIN_LIFE:
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, DRAIN_LIFE_RANGE, true))
                        {
                            _drainTarget = target->GetGUID();
                            _drainTick = Info(me, INFO_DRAIN_LIFE);
                            me->CastCustomSpell(target, SPELL_DRAIN_LIFE, nullptr, &_drainTick, nullptr, false);
                        }
                        events.ScheduleEvent(EVENT_DRAIN_LIFE, 10s, 0, PHASE_TROLL);
                        break;
                    case EVENT_POISON_BOLT_VOLLEY:
                        DoCastSelf(SPELL_POISON_BOLT_VOLLEY);
                        events.ScheduleEvent(EVENT_POISON_BOLT_VOLLEY, 15s);
                        break;
                    case EVENT_HATCH_EGGS:
                        DoCastSelf(SPELL_HATCH_EGGS);
                        events.ScheduleEvent(EVENT_HATCH_EGGS, HATCH_EVERY);
                        break;
                    case EVENT_OPEN_EGGS:
                        OpenClaimedEggs();
                        break;
                    case EVENT_EVOLVE:
                        EvolveNearestEgg();
                        events.ScheduleEvent(EVENT_EVOLVE, 60s, 0, PHASE_TROLL);
                        break;
                    case EVENT_HATCH_EVOLVED_EGG:
                        HatchEvolvedEgg();
                        break;
                    case EVENT_INFEST:
                        if (Creature* spawn = HatchNearestEgg())
                            DoCast(spawn, SPELL_INFEST);
                        events.ScheduleEvent(EVENT_INFEST, 60s, 0, PHASE_SPIDER);
                        break;
                    case EVENT_ACID_SPIT:
                        DoCastVictim(SPELL_ACID_SPIT);
                        events.ScheduleEvent(EVENT_ACID_SPIT, 12s, 0, PHASE_SPIDER);
                        break;
                    case EVENT_WEB_SPRAY:
                        DoCastVictim(SPELL_WEB_SPRAY);
                        events.ScheduleEvent(EVENT_CHARGE, 5s, 0, PHASE_SPIDER);
                        events.ScheduleEvent(EVENT_WEB_SPRAY, SpiderCycle(), 0, PHASE_SPIDER);
                        break;
                    case EVENT_CHARGE:
                        // From stock: after the webs she goes for a caster out of reach.
                        if (Unit* target = SelectTarget(SelectTargetMethod::Random, 0, [this](Unit* u)
                            {
                                return u->IsPlayer() && u->getPowerType() == POWER_MANA && !me->IsWithinMeleeRange(u) && u != me->GetVictim();
                            }))
                        {
                            DoCast(target, SPELL_CHARGE);
                            AttackStart(target);
                        }
                        break;
                    case EVENT_POISON_SHOCK:
                        DoCastSelf(SPELL_POISON_SHOCK);
                        break;
                    case EVENT_BURROW:
                        DoCastSelf(SPELL_BURROW);
                        events.ScheduleEvent(EVENT_BURROW, SpiderCycle(), 0, PHASE_SPIDER);
                        break;
                    case EVENT_EMERGE:
                        EmergeAtFarthest();
                        events.ScheduleEvent(EVENT_POISON_SHOCK, POISON_SHOCK_AFTER_EMERGE, 0, PHASE_SPIDER);
                        break;
                    case EVENT_END_HUNT:
                        EndHunt();
                        break;
                }

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    break;
            }

            DoMeleeAttackIfReady();
        }

    private:
        bool _spider = false;
        LoaAvatar _avatar{ NPC_AVATAR_OF_SHADRA, SPELL_DRAIN_POWER };
        GuidSet _festering;
        GuidSet _usedEggs;
        GuidVector _hatchingEggs;
        ObjectGuid _evolvedEgg;
        float _evolvedEggScale = 1.0f;
        GuidVector _drainSplashed;
        ObjectGuid _drainTarget;
        int32 _drainTick = 0;
        ObjectGuid _hunted;
        float _huntThreat = 0.0f;
    };
}

void AddCoaMarliScripts()
{
    RegisterZulGurubCreatureAI(boss_marli_coa);
}
