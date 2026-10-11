/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWitchDoctorCompletion.h"
#include "Creature.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <algorithm>
#include <cmath>

namespace AscensionWitchDoctor
{
void PruneSummons(Player* player)
{
    auto& summons = State(player).summons;
    summons.erase(std::remove_if(summons.begin(), summons.end(),
                                 [player](ObjectGuid guid)
                                 {
                                     Creature* creature = ObjectAccessor::GetCreature(*player, guid);
                                     return !creature || !creature->IsAlive() ||
                                            creature->GetOwnerGUID() != player->GetGUID();
                                 }),
                  summons.end());
}
uint8 Slot(uint32 entry)
{
    switch (entry)
    {
        case NpcHealing:
        case NpcSerpent:
        case NpcStasis:
        case NpcSentry:
            return WardSlot;
        case NpcSpiritIdol:
        case NpcSerene:
        case NpcDark:
        case NpcSwift:
        case NpcCleanse:
        case NpcJungle:
        case NpcLink:
            return IdolSlot;
        case NpcShadow:
        case NpcHexing:
        case NpcCursed:
        case NpcGraven:
            return EffigySlot;
        case NpcMimic:
            return MimicSlot;
        case NpcGolem:
            return GolemSlot;
        case NpcCauldron:
            return CauldronSlot;
        case NpcBwonsamdi:
            return VoodooSlot;
        default:
            return NoSlot;
    }
}
bool HasSummon(Player* player, uint32 entry)
{
    if (!player || !player->IsInWorld())
        return false;
    for (ObjectGuid guid : State(player).summons)
        if (Creature* creature = ObjectAccessor::GetCreature(*player, guid))
            if (creature->GetEntry() == entry && creature->IsAlive() && creature->GetOwnerGUID() == player->GetGUID())
                return true;
    return false;
}
void HealThroughEffigies(Player* player, Unit* primary, uint32 healing)
{
    if (!player || !primary || !healing || !player->HasAura(JungleSecrets))
        return;
    SpellInfo const* info = sSpellMgr->GetSpellInfo(JungleSecretsHeal);
    if (!info)
        return;
    uint32 amount = uint32(uint64(healing) * std::clamp(Amount(JungleSecrets, EFFECT_0, player), 0, 100) / 100);
    float radius = info->Effects[EFFECT_0].CalcRadius(player);
    auto summons = State(player).summons;
    for (ObjectGuid guid : summons)
        if (Creature* effigy = ObjectAccessor::GetCreature(*player, guid))
            if (Slot(effigy->GetEntry()) == EffigySlot && effigy->IsAlive() &&
                effigy->GetOwnerGUID() == player->GetGUID() && player->IsInMap(effigy) && player->InSamePhase(effigy))
            {
                auto allies = Allies(player, effigy, radius);
                allies.remove(primary);
                if (!allies.empty())
                    Copy(player, allies.front(), JungleSecretsHeal, amount);
            }
}
void WardBuff(Player* player, uint32 spell)
{
    for (ObjectGuid guid : State(player).summons)
        if (Creature* ward = ObjectAccessor::GetCreature(*player, guid))
            if (ward->GetEntry() == NpcSerpent || ward->GetEntry() == NpcMassSerpent || ward->GetEntry() == NpcViper)
                Cast(player, ward, spell);
}
void ExplodeClones(Player* player)
{
    auto summons = State(player).summons;
    for (ObjectGuid guid : summons)
        if (Creature* clone = ObjectAccessor::GetCreature(*player, guid))
            if (clone->GetEntry() == NpcMarionette && clone->IsAIEnabled)
                clone->AI()->DoAction(ActionExplode);
}
void Mirror(Player* player, Unit* target, uint32 spell)
{
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    if (!(Family(info, 1, 32768 | 131072) || (player->HasAura(Shadowhunter) && (Family(info, 1, 4) || IsArrow(info))) ||
          (player->HasAura(Unleashed) && IsJuju(info))))
        return;
    for (ObjectGuid guid : State(player).summons)
        if (Creature* mimic = ObjectAccessor::GetCreature(*player, guid))
            if (mimic->GetEntry() == NpcMimic && mimic->IsAIEnabled && mimic->IsAlive() &&
                mimic->IsWithinDistInMap(target, 40.0f) && mimic->IsWithinLOSInMap(target))
            {
                mimic->AI()->SetData(DataSpell, spell);
                mimic->AI()->SetGUID(target->GetGUID(), DataTarget);
                mimic->AI()->DoAction(ActionMirror);
            }
}
void Summon(Player* player, uint32 spell, Unit* target, Position const& location)
{
    if (!player || !player->IsAlive() || !player->IsInWorld())
        return;
    SpellInfo const* info = sSpellMgr->GetSpellInfo(spell);
    if (!info)
        return;
    uint32 entry = 0;
    for (SpellEffectInfo const& effect : info->Effects)
        if (effect.Effect == SPELL_EFFECT_SUMMON)
            entry = effect.MiscValue;
    if (spell == FoolsPlay)
        entry = NpcFool;
    if (spell == Marionette)
        entry = NpcMarionette;
    if (!entry)
        return;
    uint32 count = spell == CallSseratus ? 4 + (player->HasAura(SerpentHandler) ? 2 : 0) : spell == Marionette ? 5 : 1;
    if (spell == Mimic)
        count = uint32(std::max(1, info->Effects[EFFECT_2].CalcValue(player)));
    int32 duration = spell == SpiritLink ? sSpellMgr->GetSpellInfo(LinkTimer)->GetDuration() : info->GetDuration();
    player->ApplySpellMod(spell, SPELLMOD_DURATION, duration);
    if (spell == Marionette)
        duration = 8500;
    uint8 slot = Slot(entry);
    PruneSummons(player);
    auto previous = State(player).summons;
    for (uint32 i = 0; i < count; ++i)
    {
        Position position = location;
        if (slot != NoSlot && spell != VoodooCauldron && spell != BigVoodoo)
            position = player->GetPosition();
        if (slot <= EffigySlot || count > 1)
            player->MovePositionToFirstCollision(position, count > 1 ? 2.5f : 1.5f,
                                                 float(i) * float(2 * M_PI) / count + slot * 0.8f);
        TempSummon* summon = player->SummonCreature(entry, position, TEMPSUMMON_TIMED_DESPAWN, std::max(1, duration));
        if (!summon)
            continue;
        summon->SetOwnerGUID(player->GetGUID());
        summon->AI()->SetData(DataSource, spell);
        if (target)
            summon->AI()->SetGUID(target->GetGUID(), DataTarget);
        if (slot != NoSlot)
            for (ObjectGuid guid : previous)
                if (Creature* old = ObjectAccessor::GetCreature(*player, guid))
                    if (old->GetOwnerGUID() == player->GetGUID() && Slot(old->GetEntry()) == slot)
                        old->DespawnOrUnsummon();
        if (slot == IdolSlot && player->HasAura(SpiritWarden))
            Cast(player, player, SpiritWardenBuff);
        if ((entry == NpcSerpent || entry == NpcMassSerpent || entry == NpcViper || entry == NpcSpirit) &&
            player->HasAura(TrueSpirit))
            Cast(player, player, TrueSpiritReady);
        if (entry == NpcGolem && player->HasAura(MaliciousGolems))
            Cast(player, player, GolemHaste);
    }
}
}

namespace
{
using namespace AscensionWitchDoctor;
constexpr uint32 NpcHauntVisage = 840000;
constexpr float HauntRunDistance = 25.0f;
class npc_ascension_witch_doctor : public ScriptedAI
{
  public:
    explicit npc_ascension_witch_doctor(Creature* creature) : ScriptedAI(creature) {}
    ObjectGuid _owner;
    ObjectGuid _target;
    uint32 _spell = 0;
    uint32 _source = 0;
    uint32 _timer = 1;
    uint32 _age = 0;
    uint32 _marionetteTicks = 0;
    bool _exploded = false;

    void IsSummonedBy(WorldObject* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (player && player->getClass() == CLASS_REAPER && me->GetEntry() == NpcHauntVisage)
        {
            _owner = player->GetGUID();
            me->SetOwnerGUID(_owner);
            me->SetCreatorGUID(_owner);
            me->SetFaction(player->GetFaction());
            me->SetLevel(player->GetLevel());
            player->CastSpell(me, CloneMe, true);
            me->SetReactState(REACT_PASSIVE);
            me->SetCombatMovement(false);
            RunAwayFrom(player);
            return;
        }
        if (!player || player->getClass() != CLASS_WITCH_DOCTOR)
            return;
        _owner = player->GetGUID();
        me->SetOwnerGUID(_owner);
        me->SetCreatorGUID(_owner);
        me->SetFaction(player->GetFaction());
        me->m_ControlledByPlayer = true;
        me->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
        me->SetByteValue(UNIT_FIELD_BYTES_2, 1, player->GetByteValue(UNIT_FIELD_BYTES_2, 1));
        me->SetLevel(player->GetLevel());
        me->SetMaxHealth(std::max(5u, uint32(player->GetLevel()) * 10));
        me->SetHealth(me->GetMaxHealth());
        me->SetReactState(REACT_PASSIVE);
        me->SetCombatMovement(false);
        if (me->GetEntry() == NpcCauldron)
            me->SetVisible(false);
        State(player).summons.push_back(me->GetGUID());
        if (me->GetEntry() == NpcMirage)
        {
            player->CastSpell(me, CloneMe, true);
            RunAwayFrom(player);
        }
        if (me->GetEntry() == NpcMarionette)
            player->CastSpell(me, CloneMe, true);
        if (me->GetEntry() == NpcGolem)
        {
            me->SetMaxHealth(std::max(100u, uint32(player->GetStat(STAT_INTELLECT) * 8)));
            me->SetHealth(me->GetMaxHealth());
        }
        if (me->GetEntry() == NpcMarionette)
            _timer = 2000;
        if (me->GetEntry() == NpcCleanse)
            _timer = 3000;
        if (me->GetEntry() == NpcSerpent || me->GetEntry() == NpcMassSerpent || me->GetEntry() == NpcViper)
            _timer = WardAttackInterval();
    }
    void RunAwayFrom(Player* player)
    {
        me->SetWalk(false);
        float angle = player->GetExactDist2d(me) > 0.5f ? player->GetAbsoluteAngle(me) : player->GetOrientation();
        me->GetMotionMaster()->MovePoint(1, me->GetNearPosition(HauntRunDistance,
            Position::NormalizeOrientation(angle - me->GetOrientation())), FORCED_MOVEMENT_RUN);
    }
    uint32 WardAttackInterval() const
    {
        int32 haste = me->GetTotalAuraModifier(SPELL_AURA_HASTE_SPELLS);
        return (me->GetEntry() == NpcViper ? 1000 : 2000) * 100 / std::max(1, 100 + haste);
    }
    void SetData(uint32 key, uint32 value) override
    {
        if (key == DataSpell)
            _spell = value;
        if (key == DataSource)
            _source = value;
    }
    uint32 GetData(uint32 key) const override
    {
        return key == DataSource ? _source : 0;
    }
    void SetGUID(ObjectGuid const& guid, int32 key) override
    {
        if (key != DataTarget)
            return;
        _target = guid;
        if (me->GetEntry() == NpcFool)
            if (Unit* target = ObjectAccessor::GetUnit(*me, guid))
            {
                me->SetDisplayId(target->GetDisplayId());
                me->SetReactState(REACT_AGGRESSIVE);
                me->SetFloatValue(UNIT_FIELD_MINDAMAGE, target->GetFloatValue(UNIT_FIELD_MINDAMAGE));
                me->SetFloatValue(UNIT_FIELD_MAXDAMAGE, target->GetFloatValue(UNIT_FIELD_MAXDAMAGE));
                me->SetCombatMovement(true);
                AttackStart(target);
                if (me->GetVictim() == target)
                    me->EngageWithTarget(target);
            }
    }
    ObjectGuid GetGUID(int32 key) const override { return key == DataTarget ? _target : _owner; }
    void DoAction(int32 action) override
    {
        if (action == ActionMirror)
        {
            if (me->GetEntry() == NpcMimic)
                if (Player* player = ObjectAccessor::GetPlayer(*me, _owner))
                {
                    me->SetFloatValue(UNIT_FIELD_MINRANGEDDAMAGE, player->GetFloatValue(UNIT_FIELD_MINRANGEDDAMAGE));
                    me->SetFloatValue(UNIT_FIELD_MAXRANGEDDAMAGE, player->GetFloatValue(UNIT_FIELD_MAXRANGEDDAMAGE));
                }
            if (Unit* target = ObjectAccessor::GetUnit(*me, _target))
                if (me->IsAlive() && me->IsWithinLOSInMap(target) && me->IsWithinDistInMap(target, 40.0f))
                    me->CastSpell(target, _spell, true, nullptr, nullptr,
                                  me->GetEntry() == NpcMimic ? _owner : ObjectGuid::Empty);
        }
        if (action == ActionExplode && !_exploded)
        {
            _exploded = true;
            me->CastSpell(me, MarionetteExplosion, true, nullptr, nullptr, _owner);
            me->DespawnOrUnsummon(1ms);
        }
    }
    void Field(Unit* target, uint32 spell)
    {
        me->CastSpell(target, spell, true, nullptr, nullptr, _owner);
        if (Aura* aura = target->GetAura(spell, _owner))
            aura->SetDuration(2200);
    }
    void Link(Player* player)
    {
        auto allies = Allies(player, me, 10.0f);
        allies.remove_if([](Unit* unit) { return !unit->IsPlayer(); });
        uint64 health = 0;
        uint64 maximum = 0;
        for (Unit* ally : allies)
        {
            health += ally->GetHealth();
            maximum += ally->GetMaxHealth();
        }
        if (!maximum)
            return;
        uint64 assigned = 0;
        for (Unit* ally : allies)
        {
            uint32 amount = uint32(std::max<uint64>(1, health * ally->GetMaxHealth() / maximum));
            ally->SetHealth(amount);
            assigned += amount;
        }
        for (Unit* ally : allies)
        {
            if (assigned < health && ally->GetHealth() < ally->GetMaxHealth())
            {
                uint32 delta = uint32(std::min<uint64>(health - assigned, ally->GetMaxHealth() - ally->GetHealth()));
                ally->SetHealth(ally->GetHealth() + delta);
                assigned += delta;
            }
            else if (assigned > health && ally->GetHealth() > 1)
            {
                uint32 delta = uint32(std::min<uint64>(assigned - health, ally->GetHealth() - 1));
                ally->SetHealth(ally->GetHealth() - delta);
                assigned -= delta;
            }
        }
    }
    Unit* Enemy(Player* player)
    {
        if (!player->IsInCombat())
            return nullptr;
        Unit* target = player->GetSelectedUnit();
        if (target && player->IsValidAttackTarget(target) && me->IsWithinDistInMap(target, 30.0f) &&
            me->IsWithinLOSInMap(target))
            return target;
        for (Unit* unit : Nearby(me, 30.0f))
            if (player->IsValidAttackTarget(unit) && player->IsInCombatWith(unit) && me->IsWithinLOSInMap(unit))
                return unit;
        return nullptr;
    }
    void UpdateAI(uint32 diff) override
    {
        Player* player = ObjectAccessor::GetPlayer(*me, _owner);
        if (!player || !player->IsAlive() || !player->IsInMap(me) || !player->InSamePhase(me))
        {
            me->DespawnOrUnsummon();
            return;
        }
        if (player->getClass() == CLASS_WITCH_DOCTOR)
            me->SetByteValue(UNIT_FIELD_BYTES_2, 1, player->GetByteValue(UNIT_FIELD_BYTES_2, 1));
        if (me->GetEntry() == NpcHauntVisage)
            return;
        _age += diff;
        if (me->GetEntry() == NpcFool)
        {
            Unit* target = ObjectAccessor::GetUnit(*me, _target);
            if (!target || !target->IsAlive())
            {
                me->DespawnOrUnsummon();
                return;
            }
            if (UpdateVictim())
                DoMeleeAttackIfReady();
        }
        if (_timer > diff)
        {
            _timer -= diff;
            return;
        }
        _timer = 1000;
        uint32 entry = me->GetEntry();
        if (entry == NpcSerpent || entry == NpcMassSerpent || entry == NpcViper)
        {
            if (Unit* target = Enemy(player))
            {
                me->CastSpell(target, SerpentAttackSpell, true, nullptr, nullptr, _owner);
                uint32 voodooFireRank = player->HasAura(VoodooFireTwo) ? VoodooFireTwo
                                       : player->HasAura(VoodooFireOne) ? VoodooFireOne
                                                                         : 0;
                float chance = voodooFireRank == VoodooFireTwo ? 40 : voodooFireRank == VoodooFireOne ? 20 : 0;
                if (voodooFireRank)
                    player->ApplySpellMod(voodooFireRank, SPELLMOD_CHANCE_OF_SUCCESS, chance);
                if (chance && roll_chance_f(chance))
                {
                    uint32 cap = 3;
                    for (Unit* enemy : Nearby(target, 10.0f))
                        if (player->IsValidAttackTarget(enemy))
                        {
                            me->CastSpell(enemy, VoodooFire, true, nullptr, nullptr, _owner);
                            if (!--cap)
                                break;
                        }
                }
                if (entry == NpcViper && roll_chance_f(sSpellMgr->GetSpellInfo(ViperProc)->ProcChance +
                                                       player->GetRatingBonusValue(CR_CRIT_RANGED)))
                    me->CastSpell(target, ViperFire, true, nullptr, nullptr, _owner);
            }
            _timer = WardAttackInterval();
        }
        if (entry == NpcHealing)
        {
            for (Unit* ally : Allies(player, me, 30.0f, 8))
                me->CastSpell(ally, WardHeal, true, nullptr, nullptr, _owner);
            _timer = 2500;
        }
        if (entry == NpcLink)
        {
            Link(player);
            _timer = 2000;
        }
        if (entry == NpcSpiritIdol)
        {
            for (Unit* ally : Allies(player, me, 30.0f))
                me->CastSpell(ally, SpiritManaTick, true, nullptr, nullptr, _owner);
            _timer = 3000;
        }
        if (entry == NpcCleanse)
        {
            for (Unit* ally : Allies(player, me, 30.0f))
                me->CastSpell(ally, Cleanse, true, nullptr, nullptr, _owner);
            _timer = 3000;
        }
        if (entry == NpcSerene || entry == NpcDark || entry == NpcJungle || entry == NpcSwift)
            for (Unit* ally : Allies(player, me, 30.0f))
                Field(ally, entry == NpcSerene   ? SereneField
                            : entry == NpcDark   ? DarkField
                            : entry == NpcJungle ? JungleFieldSpell
                                                 : SwiftField);
        if (entry == NpcSentry)
            for (Unit* enemy : Nearby(me, 30.0f))
                if (player->IsHostileTo(enemy) && me->IsWithinLOSInMap(enemy))
                    if (Aura* reveal = player->AddAura(SentryRevealSpell, enemy))
                        reveal->SetDuration(2200);
        if (entry == NpcShadow || entry == NpcGraven || entry == NpcCursed)
            for (Unit* enemy : Nearby(me, 10.0f))
                if (player->IsValidAttackTarget(enemy))
                {
                    Field(enemy, entry == NpcShadow   ? ShadowField
                                 : entry == NpcGraven ? GravenField
                                 : entry == NpcCursed ? CursedField
                                                      : SentryRevealSpell);
                    if (entry == NpcShadow)
                        Field(enemy, ShadowSlow);
                }
        if (entry == NpcStasis && _age >= 2000)
        {
            me->CastSpell(me, Stasis, true, nullptr, nullptr, _owner);
            me->DespawnOrUnsummon(1ms);
        }
        if (entry == NpcSpirit && player->IsWithinDistInMap(me, 2.0f))
        {
            GainSpirit(player);
            Cast(player, player, SpiritPickupBuff);
            me->DespawnOrUnsummon();
        }
        if (entry == NpcCauldron)
        {
            for (Unit* ally : Allies(player, me, 10.0f))
            {
                Field(ally, CauldronBuff);
                Copy(player, ally, LoaEchoHeal, Amount(VoodooCauldron, EFFECT_2, player));
            }
            _timer = 1500;
        }
        if (entry == NpcBwonsamdi)
        {
            if (player->IsWithinDistInMap(me, 10.0f))
            {
                Field(player, BigVoodooField);
                Cast(player, player, BigVoodooLock);
            }
            for (Unit* ally : Allies(player, me, 10.0f))
                if (ally != player)
                    Field(ally, VoodooProtectionSpell);
        }
        if (entry == NpcMarionette)
        {
            if (++_marionetteTicks <= 4 && (player->HasAura(Marionette) || _age >= 8000))
                Cast(player, player, MarionetteStacks);
            else
                me->DespawnOrUnsummon();
            _timer = 2000;
        }
    }
};

class spell_ascension_witch_doctor_summon : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_doctor_summon);
    bool _made = false;
    void Handle(SpellEffIndex index)
    {
        Player* player = Owner(GetCaster());
        if (!player || player != GetCaster())
            return;
        PreventHitDefaultEffect(index);
        if (_made)
            return;
        _made = true;
        if (GetSpell()->GetTriggeredByAuraSpellInfo() &&
            GetSpell()->GetTriggeredByAuraSpellInfo()->Id == CallSseratusChannel &&
            GetSpell()->GetTriggeredByAuraTickNumber() > 1)
            return;
        Position position = GetExplTargetDest() ? GetExplTargetDest()->GetPosition() : player->GetPosition();
        Unit* target = GetExplTargetUnit();
        if ((GetSpellInfo()->Id == WrathWard || GetSpellInfo()->Id == SerpentMass) && target)
            position = target->GetPosition();
        Summon(player, GetSpellInfo()->Id, target, position);
    }
    void Register() override
    {
        SpellInfo const* info = sSpellMgr->GetSpellInfo(m_scriptSpellId);
        if (info->HasEffect(SPELL_EFFECT_SUMMON))
        {
            OnEffectHit +=
                SpellEffectFn(spell_ascension_witch_doctor_summon::Handle, EFFECT_ALL, SPELL_EFFECT_SUMMON);
            OnEffectHitTarget +=
                SpellEffectFn(spell_ascension_witch_doctor_summon::Handle, EFFECT_ALL, SPELL_EFFECT_SUMMON);
        }
        if (info->HasEffect(SPELL_EFFECT_SCRIPT_EFFECT))
            OnEffectHitTarget +=
                SpellEffectFn(spell_ascension_witch_doctor_summon::Handle, EFFECT_ALL, SPELL_EFFECT_SCRIPT_EFFECT);
    }
};

class spell_ascension_witch_doctor_spiritual_recall : public SpellScript
{
    PrepareSpellScript(spell_ascension_witch_doctor_spiritual_recall);
    void Handle(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        Player* player = GetCaster() ? GetCaster()->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_WITCH_DOCTOR)
            return;
        int32 mana = 0;
        auto summons = State(player).summons;
        for (ObjectGuid guid : summons)
        {
            Creature* summon = ObjectAccessor::GetCreature(*player, guid);
            if (!summon || !summon->IsAlive() || summon->GetOwnerGUID() != player->GetGUID() ||
                Slot(summon->GetEntry()) > EffigySlot)
                continue;
            if (summon->IsAIEnabled)
                if (SpellInfo const* source = sSpellMgr->GetSpellInfo(summon->AI()->GetData(DataSource)))
                    mana += int32(source->ManaCost) +
                            int32(CalculatePct(player->GetCreateMana(), source->ManaCostPercentage));
            summon->DespawnOrUnsummon();
        }
        PruneSummons(player);
        ApplyPct(mana, GetEffectValue());
        if (mana > 0)
            player->EnergizeBySpell(player, GetSpellInfo()->Id, uint32(mana), POWER_MANA);
    }
    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_ascension_witch_doctor_spiritual_recall::Handle, EFFECT_0,
                                     SPELL_EFFECT_DESTROY_ALL_TOTEMS);
    }
};

bool CanMirrorSpell(SpellInfo const* info)
{
    if (!info || info->IsPositive() ||
        (!info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) && !info->HasEffect(SPELL_EFFECT_WEAPON_PERCENT_DAMAGE)))
        return false;
    auto scripts = sObjectMgr->GetSpellScriptsBounds(info->Id);
    if (scripts.first != scripts.second)
        return false;
    for (SpellEffectInfo const& effect : info->Effects)
        if (effect.IsEffect() && effect.Effect != SPELL_EFFECT_SCHOOL_DAMAGE &&
            effect.Effect != SPELL_EFFECT_WEAPON_PERCENT_DAMAGE && effect.Effect != SPELL_EFFECT_WEAPON_DAMAGE &&
            effect.Effect != SPELL_EFFECT_NORMALIZED_WEAPON_DMG)
            return false;
    return true;
}

class witch_doctor_summon_events : public AllSpellScript
{
  public:
    witch_doctor_summon_events() : AllSpellScript("witch_doctor_summon_events", {ALLSPELLHOOK_ON_CAST}) {}
    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (spell->IsTriggered() || info->IsPositive())
            return;
        Unit* target = spell->m_targets.GetUnitTarget();
        Player* player = Owner(target);
        if (player && target == player)
            for (ObjectGuid guid : State(player).summons)
                if (Creature* ward = ObjectAccessor::GetCreature(*player, guid))
                    if (ward->GetEntry() == NpcHexing && ward->IsAlive())
                    {
                        Cast(player, caster, Hexed);
                        ward->DespawnOrUnsummon();
                        break;
                    }
        if (!CanMirrorSpell(info))
            return;
        for (Unit* unit : Nearby(caster, 40.0f))
            if (Creature* clone = unit->ToCreature())
                if (clone->GetEntry() == NpcFool && clone->IsAIEnabled &&
                    clone->AI()->GetGUID(DataTarget) == caster->GetGUID())
                {
                    clone->AI()->SetData(DataSpell, info->Id);
                    clone->AI()->DoAction(ActionMirror);
                }
    }
};

class witch_doctor_magnet : public UnitScript
{
  public:
    witch_doctor_magnet() : UnitScript("witch_doctor_magnet", true, {UNITHOOK_SPELL_MAGNET_TARGET}) {}
    Unit* SpellMagnetTarget(Unit* attacker, Unit* victim, SpellInfo const* info) override
    {
        if (!attacker || !victim || !info || info->IsPositive())
            return nullptr;
        for (Unit* unit : Nearby(victim, 15.0f))
            if (unit->GetEntry() == NpcGolem)
                if (Player* player = Owner(unit); player && Friendly(player, victim) &&
                                                  attacker->IsValidAttackTarget(unit) && unit->IsWithinLOSInMap(victim))
                    return unit;
        return nullptr;
    }
};
}
void AddAscensionWitchDoctorSummonScripts()
{
    RegisterCreatureAI(npc_ascension_witch_doctor);
    RegisterSpellScript(spell_ascension_witch_doctor_summon);
    RegisterSpellScript(spell_ascension_witch_doctor_spiritual_recall);
    new witch_doctor_summon_events();
    new witch_doctor_magnet();
}
