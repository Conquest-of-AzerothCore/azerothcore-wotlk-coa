/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Creature.h"
#include "Map.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include <cmath>
#include "MotionMaster.h"
#include "Opcodes.h"
#include "WorldPacket.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellScript.h"
#include "Log.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Player.h"
#include "UnitScript.h"
#include <memory>

namespace
{
    class spell_coa_torrent_spin : public AuraScript
    {
        PrepareAuraScript(spell_coa_torrent_spin);

        ReactStates _react = REACT_AGGRESSIVE;
        float _start = 0.0f;
        uint32 _ticks = 0;

        void Start(AuraEffect const*, AuraEffectHandleModes)
        {
            Creature* boss = GetTarget()->ToCreature();
            if (!boss)
                return;
            _react = boss->GetReactState();
            _start = boss->GetOrientation();
            _ticks = 0;
            boss->SetReactState(REACT_PASSIVE);
            boss->AttackStop();
            boss->SetTarget();
            boss->SetUnitFlag(UNIT_FLAG_PACIFIED);
            boss->GetMotionMaster()->Clear();
            boss->StopMoving();
            boss->RemoveUnitMovementFlag(MOVEMENTFLAG_MASK_MOVING);
            boss->SetGuidValue(UNIT_FIELD_CHANNEL_OBJECT, ObjectGuid::Empty);
        }

        static void SendFacing(Creature* boss)
        {
            WorldPacket data(MSG_MOVE_SET_FACING, 64);
            data << boss->GetPackGUID();
            boss->BuildMovementPacket(&data);
            boss->SendMessageToSet(&data, false);
        }

        void Turn(AuraEffect const* effect)
        {
            Creature* boss = GetTarget()->ToCreature();
            if (!boss || !GetMaxDuration())
                return;
            ++_ticks;
            float turned = float(_ticks * effect->GetAmplitude()) / float(GetMaxDuration()) * float(2 * M_PI);
            float angle = Position::NormalizeOrientation(_start - turned);
            boss->RemoveUnitMovementFlag(MOVEMENTFLAG_MASK_MOVING);
            boss->SetOrientation(angle);
            SendFacing(boss);
        }

        void Stop(AuraEffect const*, AuraEffectHandleModes)
        {
            Creature* boss = GetTarget()->ToCreature();
            if (!boss || !boss->IsAlive())
                return;
            boss->RemoveUnitFlag(UNIT_FLAG_PACIFIED);
            boss->SetReactState(_react);
            boss->GetMotionMaster()->Clear();
            if (Unit* victim = boss->SelectVictim())
                boss->AI()->AttackStart(victim);
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_coa_torrent_spin::Start, EFFECT_1,
                SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_coa_torrent_spin::Turn, EFFECT_1,
                SPELL_AURA_PERIODIC_TRIGGER_SPELL);
            AfterEffectRemove += AuraEffectRemoveFn(spell_coa_torrent_spin::Stop, EFFECT_1,
                SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        }
    };

    class spell_coa_bouncing_saw_blade : public SpellScript
    {
        PrepareSpellScript(spell_coa_bouncing_saw_blade);

        void Limit(std::list<WorldObject*>& targets)
        {
            size_t const count = GetCaster()->GetMap()->GetDifficulty() >= DUNGEON_DIFFICULTY_EPIC ? 3 : 1;
            if (targets.size() > count)
                targets.resize(count);
        }

        void Register() override
        {
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_bouncing_saw_blade::Limit, EFFECT_ALL,
                TARGET_UNIT_TARGET_ENEMY);
        }
    };

    class spell_coa_massive_fire_nova : public SpellScript
    {
        PrepareSpellScript(spell_coa_massive_fire_nova);

        static constexpr uint32 EarthPillar = 663030;
        static constexpr uint32 NovaLanded = 1;

        void Cover(std::list<WorldObject*>& targets)
        {
            Unit* boss = GetCaster();
            std::list<Creature*> pillars;
            boss->GetCreatureListWithEntryInGrid(pillars, EarthPillar, 80.0f);
            pillars.remove_if([](Creature* pillar) { return !pillar->IsAlive(); });
            if (pillars.empty())
                return;
            targets.remove_if([boss, &pillars](WorldObject* target)
            {
                float const dx = target->GetPositionX() - boss->GetPositionX();
                float const dy = target->GetPositionY() - boss->GetPositionY();
                float const length = std::sqrt(dx * dx + dy * dy);
                if (length < 0.1f)
                    return false;
                for (Creature* pillar : pillars)
                {
                    float const px = pillar->GetPositionX() - boss->GetPositionX();
                    float const py = pillar->GetPositionY() - boss->GetPositionY();
                    float const along = (px * dx + py * dy) / length;
                    if (along <= 0.0f || along >= length)
                        continue;
                    if (std::abs(px * dy - py * dx) / length <= 2.5f)
                        return true;
                }
                return false;
            });
        }

        void Crumble()
        {
            std::list<Creature*> pillars;
            GetCaster()->GetCreatureListWithEntryInGrid(pillars, EarthPillar, 80.0f);
            for (Creature* pillar : pillars)
                if (pillar->IsAlive() && pillar->IsAIEnabled)
                    pillar->AI()->SetData(NovaLanded, NovaLanded);
        }

        void Register() override
        {
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_coa_massive_fire_nova::Cover, EFFECT_0,
                TARGET_UNIT_SRC_AREA_ENEMY);
            AfterCast += SpellCastFn(spell_coa_massive_fire_nova::Crumble);
        }
    };

    class spell_coa_fixed_facing_channel : public AuraScript
    {
        PrepareAuraScript(spell_coa_fixed_facing_channel);

        ReactStates _react = REACT_AGGRESSIVE;

        void Start(AuraEffect const*, AuraEffectHandleModes)
        {
            Creature* boss = GetTarget()->ToCreature();
            if (!boss)
                return;
            _react = boss->GetReactState();
            boss->SetReactState(REACT_PASSIVE);
            boss->AttackStop();
            boss->SetTarget();
            boss->SetUnitFlag(UNIT_FLAG_PACIFIED);
            boss->GetMotionMaster()->Clear();
            boss->StopMoving();
            boss->SetGuidValue(UNIT_FIELD_CHANNEL_OBJECT, ObjectGuid::Empty);
        }

        void Stop(AuraEffect const*, AuraEffectHandleModes)
        {
            Creature* boss = GetTarget()->ToCreature();
            if (!boss || !boss->IsAlive())
                return;
            boss->RemoveUnitFlag(UNIT_FLAG_PACIFIED);
            boss->SetReactState(_react);
            boss->GetMotionMaster()->Clear();
            if (Unit* victim = boss->SelectVictim())
                boss->AI()->AttackStart(victim);
        }

        void Register() override
        {
            AfterEffectApply += AuraEffectApplyFn(spell_coa_fixed_facing_channel::Start, EFFECT_0,
                SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
            AfterEffectRemove += AuraEffectRemoveFn(spell_coa_fixed_facing_channel::Stop, EFFECT_0,
                SPELL_AURA_PERIODIC_TRIGGER_SPELL, AURA_EFFECT_HANDLE_REAL);
        }
    };

    class OverrunTrampleEvent : public BasicEvent
    {
    public:
        OverrunTrampleEvent(Creature* owner, std::shared_ptr<GuidSet> hit) : _owner(owner), _hit(std::move(hit)) { }

        static constexpr uint32 SpellOverrunTrample = 2102625;
        static constexpr uint32 SpellDustTrail = 2132349;

        bool Execute(uint64, uint32) override
        {
            if (!_owner->IsAlive())
                return true;
            std::list<Player*> players;
            _owner->CastSpell(_owner, SpellDustTrail, true);
            Acore::AnyPlayerInObjectRangeCheck check(_owner, 4.0f, true, true);
            Acore::PlayerListSearcher<Acore::AnyPlayerInObjectRangeCheck> searcher(_owner, players, check);
            Cell::VisitObjects(_owner, searcher, 4.0f);
            Map const* map = _owner->GetMap();
            uint32 const damage = map->GetDifficulty() == DUNGEON_DIFFICULTY_NORMAL ? 400
                : map->GetDifficulty() == DUNGEON_DIFFICULTY_HEROIC ? 1350 : 1750;
            for (Player* player : players)
            {
                if (!player->IsAlive() || player->IsGameMaster() || !_hit->insert(player->GetGUID()).second)
                    continue;
                SpellNonMeleeDamage log(_owner, player, sSpellMgr->GetSpellInfo(SpellOverrunTrample), SPELL_SCHOOL_MASK_NORMAL);
                log.damage = damage;
                Unit::DealDamageMods(player, log.damage, &log.absorb);
                _owner->SendSpellNonMeleeDamageLog(&log);
                _owner->DealSpellDamage(&log, true);
                player->KnockbackFrom(_owner->GetPositionX(), _owner->GetPositionY(), 12.0f, 7.0f);
                LOG_INFO("coa.bossprobe", "spelldmg map={} entry={} name=\"{}\" spell={} value={} target={}", map->GetId(),
                    _owner->GetEntry(), _owner->GetName(), SpellOverrunTrample, log.damage, player->GetName());
            }
            return true;
        }

    private:
        Creature* _owner;
        std::shared_ptr<GuidSet> _hit;
    };

    class spell_coa_skum_overrun : public SpellScript
    {
        PrepareSpellScript(spell_coa_skum_overrun);

        void Run()
        {
            Creature* skum = GetCaster()->ToCreature();
            if (!skum)
                return;
            skum->SetControlled(false, UNIT_STATE_ROOT);
            Position dest = skum->GetPosition();
            skum->MovePositionToFirstCollision(dest, 25.0f, 0.0f);
            skum->GetMotionMaster()->MoveCharge(dest.GetPositionX(), dest.GetPositionY(), dest.GetPositionZ(), 22.0f);
            auto hit = std::make_shared<GuidSet>();
            for (uint32 i = 0; i < 12; ++i)
                skum->m_Events.AddEventAtOffset(new OverrunTrampleEvent(skum, hit), Milliseconds(100 + i * 150));
            skum->m_Events.AddEventAtOffset([skum]()
            {
                if (!skum->IsAlive())
                    return;
                skum->SetReactState(REACT_AGGRESSIVE);
                if (Unit* victim = skum->SelectVictim())
                    skum->AI()->AttackStart(victim);
            }, 2s);
        }

        void Register() override
        {
            AfterCast += SpellCastFn(spell_coa_skum_overrun::Run);
        }
    };

    class spell_coa_divine_retribution : public AuraScript
    {
        PrepareAuraScript(spell_coa_divine_retribution);

        static constexpr uint32 SpellRelease = 570147;

        void Release(AuraEffect const* aurEff, AuraEffectHandleModes)
        {
            AuraRemoveMode mode = GetTargetApplication()->GetRemoveMode();
            if (mode != AURA_REMOVE_BY_EXPIRE && mode != AURA_REMOVE_BY_ENEMY_SPELL)
                return;
            Unit* caster = GetCaster();
            Unit* target = GetTarget();
            int32 stored = aurEff->GetAmount();
            if (!caster || !target || stored <= 0 || !caster->IsCreature() || caster->IsControlledByPlayer())
                return;
            CustomSpellValues values;
            values.AddSpellMod(SPELLVALUE_BASE_POINT0, stored);
            caster->CastCustomSpell(sSpellMgr->GetSpellInfo(SpellRelease), values, target, TRIGGERED_FULL_MASK);
        }

        void Register() override
        {
            AfterEffectRemove += AuraEffectRemoveFn(spell_coa_divine_retribution::Release, EFFECT_2, SPELL_AURA_DUMMY,
                AURA_EFFECT_HANDLE_REAL);
        }
    };

    class CoADivineRetributionStore final : public UnitScript
    {
    public:
        CoADivineRetributionStore() : UnitScript("CoADivineRetributionStore", true, { UNITHOOK_ON_DAMAGE }) { }

        static constexpr uint32 SpellDivineRetribution = 680624;

        void OnDamage(Unit* attacker, Unit* victim, uint32& damage) override
        {
            if (!attacker || !victim || !damage || !attacker->IsCreature() || attacker->IsControlledByPlayer()
                || !victim->HasAura(SpellDivineRetribution))
                return;
            if (Aura* aura = victim->GetAura(SpellDivineRetribution, attacker->GetGUID()))
                if (AuraEffect* store = aura->GetEffect(EFFECT_2))
                    store->ChangeAmount(store->GetAmount() + int32(damage / 4), false);
        }
    };

    class CoARattlegoreBoneCrush final : public UnitScript
    {
    public:
        CoARattlegoreBoneCrush() : UnitScript("CoARattlegoreBoneCrush", true, { UNITHOOK_MODIFY_MELEE_DAMAGE }) { }

        static constexpr uint32 Rattlegore = 11622;
        static constexpr uint32 SpellBoneCrush = 40412;

        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
        {
            if (!attacker || !target || !damage || attacker->GetEntry() != Rattlegore || !attacker->IsCreature())
                return;
            Map const* map = attacker->GetMap();
            if (!map || !map->IsNonRaidDungeon() || map->GetDifficulty() == DUNGEON_DIFFICULTY_NORMAL)
                return;
            if (Aura* aura = attacker->AddAura(SpellBoneCrush, target))
            {
                aura->SetMaxDuration(5000);
                aura->SetDuration(5000);
            }
        }
    };

    class CoATargorrBerserkerLeapMarker final : public AllSpellScript
    {
    public:
        CoATargorrBerserkerLeapMarker()
            : AllSpellScript("CoATargorrBerserkerLeapMarker", { ALLSPELLHOOK_ON_PREPARE }) { }

        static constexpr uint32 SpellBerserkerLeap = 2102736;
        static constexpr uint32 SpellBerserkerLeapDestArea = 2102735;

        void OnSpellPrepare(Spell* spell, Unit* caster, SpellInfo const* info) override
        {
            if (info->Id != SpellBerserkerLeap || spell->IsTriggered() || spell->getState() != SPELL_STATE_PREPARING
                || !spell->m_targets.HasDst())
                return;
            Position const* landing = spell->m_targets.GetDstPos();
            caster->CastSpell(landing->GetPositionX(), landing->GetPositionY(), landing->GetPositionZ(),
                SpellBerserkerLeapDestArea, true);
        }
    };

    enum MothersMilk
    {
        SPELL_MOTHERS_MILK_DEBUFF = 2102217,
        SPELL_MOTHERS_MILK_BLOODSTREAM = 2102216,
        SPELL_WEBPLOSION = 2102218,
    };

    class spell_coa_mothers_milk_spray : public SpellScript
    {
        PrepareSpellScript(spell_coa_mothers_milk_spray);

        void Apply()
        {
            if (Unit* target = GetHitUnit())
                GetCaster()->CastSpell(target, SPELL_MOTHERS_MILK_DEBUFF, true);
        }

        void Register() override
        {
            AfterHit += SpellHitFn(spell_coa_mothers_milk_spray::Apply);
        }
    };

    class spell_coa_mothers_milk_debuff : public AuraScript
    {
        PrepareAuraScript(spell_coa_mothers_milk_debuff);

        void Webplosion(AuraEffect const* aurEff)
        {
            if (Unit* target = GetTarget())
                target->CastSpell(target, SPELL_WEBPLOSION, true, nullptr, aurEff, GetCasterGUID());
        }

        void Expired(AuraEffect const*, AuraEffectHandleModes)
        {
            if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
                GetTarget()->CastSpell(GetTarget(), SPELL_MOTHERS_MILK_BLOODSTREAM, true);
        }

        void Register() override
        {
            OnEffectPeriodic += AuraEffectPeriodicFn(spell_coa_mothers_milk_debuff::Webplosion, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
            AfterEffectRemove += AuraEffectRemoveFn(spell_coa_mothers_milk_debuff::Expired, EFFECT_0, SPELL_AURA_PERIODIC_DUMMY,
                AURA_EFFECT_HANDLE_REAL);
        }
    };
}

void AddSC_CoADungeonBossSpells()
{
    RegisterSpellScript(spell_coa_massive_fire_nova);
    RegisterSpellScript(spell_coa_torrent_spin);
    RegisterSpellScript(spell_coa_bouncing_saw_blade);
    RegisterSpellScript(spell_coa_skum_overrun);
    RegisterSpellScript(spell_coa_divine_retribution);
    new CoADivineRetributionStore();
    RegisterSpellScript(spell_coa_fixed_facing_channel);
    new CoARattlegoreBoneCrush();
    new CoATargorrBerserkerLeapMarker();
    RegisterSpellScript(spell_coa_mothers_milk_spray);
    RegisterSpellScript(spell_coa_mothers_milk_debuff);
}
