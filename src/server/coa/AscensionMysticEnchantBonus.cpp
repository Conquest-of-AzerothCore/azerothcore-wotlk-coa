/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Field.h"
#include "Log.h"
#include "Pet.h"
#include "Player.h"
#include "QueryResult.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "StringConvert.h"
#include "Tokenize.h"
#include "Unit.h"
#include "UnitScript.h"
#include "WorldScript.h"
#include <algorithm>
#include <mutex>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace
{
enum class BonusKind : uint8
{
    Damage,
    Healing,
    HealingTaken,
    Crit
};

struct BonusCondition
{
    enum class Kind : uint8
    {
        Health,
        TargetHealth,
        ManaPct,
        TargetMonster,
        OutOfCombat,
        TargetOutOfCombat,
        Knows,
        Pet,
        NoPet
    };

    Kind What = Kind::Health;
    std::string_view Op;
    int32 Value = 0;
    std::vector<uint32> Spells;
};

struct BonusRule
{
    uint32 Enchant = 0;
    uint8 Effect = 0;
    BonusKind Kind = BonusKind::Damage;
    std::unordered_set<uint32> Spells;
    uint32 SchoolMask = 0;
    bool UseMask = false;
    std::vector<uint32> SelfAura;
    std::vector<uint32> TargetAura;
    std::vector<uint32> CountAura;
    uint32 CountMechanic = 0;
    std::vector<BonusCondition> Conditions;
    int32 Amount = 0;
    float Multiplier = 1.0f;
};

std::vector<BonusRule> Rules;

constexpr Milliseconds SNAPSHOT_LIFETIME = 10s;
struct Snapshot
{
    uint32 Spell = 0;
    TimePoint Taken;
    std::vector<std::size_t> Rules;
};
std::unordered_map<ObjectGuid, Snapshot> Snapshots;
std::mutex SnapshotsLock;

std::string_view const OPS[] = {">=", "<=", "!=", ">", "<", "="};

bool Compare(int32 value, std::string_view op, int32 wanted)
{
    if (op == ">=") return value >= wanted;
    if (op == "<=") return value <= wanted;
    if (op == "!=") return value != wanted;
    if (op == ">") return value > wanted;
    if (op == "<") return value < wanted;
    return value == wanted;
}

std::vector<uint32> Ids(std::string_view text, char separator = ' ')
{
    std::vector<uint32> ids;
    for (std::string_view token : Acore::Tokenize(text, separator, false))
        if (Optional<uint32> id = Acore::StringTo<uint32>(token))
            ids.push_back(*id);
    return ids;
}

Optional<BonusCondition> ParseCondition(std::string_view text)
{
    BonusCondition condition;
    static std::unordered_map<std::string_view, BonusCondition::Kind> const FLAGS = {
        {"target_monster", BonusCondition::Kind::TargetMonster}, {"out_of_combat", BonusCondition::Kind::OutOfCombat},
        {"target_out_of_combat", BonusCondition::Kind::TargetOutOfCombat}, {"pet", BonusCondition::Kind::Pet},
        {"no_pet", BonusCondition::Kind::NoPet}};
    if (auto const flag = FLAGS.find(text); flag != FLAGS.end())
    {
        condition.What = flag->second;
        return condition;
    }
    if (text.starts_with("knows:"))
    {
        condition.What = BonusCondition::Kind::Knows;
        condition.Spells = Ids(text.substr(6), '|');
        if (condition.Spells.empty())
            return {};
        return condition;
    }
    static std::unordered_map<std::string_view, BonusCondition::Kind> const KINDS = {
        {"health", BonusCondition::Kind::Health}, {"target_health", BonusCondition::Kind::TargetHealth},
        {"mana_pct", BonusCondition::Kind::ManaPct}};
    for (std::string_view op : OPS)
    {
        std::size_t const at = text.find(op);
        if (at == std::string_view::npos)
            continue;
        auto const kind = KINDS.find(text.substr(0, at));
        Optional<int32> value = Acore::StringTo<int32>(text.substr(at + op.size()));
        if (kind == KINDS.end() || !value)
            return {};
        condition.What = kind->second;
        condition.Op = op;
        condition.Value = *value;
        return condition;
    }
    return {};
}

int32 HealthPct(Unit const* unit)
{
    return unit && unit->GetMaxHealth() ? int32(uint64(unit->GetHealth()) * 100 / unit->GetMaxHealth()) : 0;
}

bool Holds(BonusCondition const& condition, Unit const* owner, Unit const* target)
{
    switch (condition.What)
    {
        case BonusCondition::Kind::Health:
            return Compare(HealthPct(owner), condition.Op, condition.Value);
        case BonusCondition::Kind::TargetHealth:
            return target && Compare(HealthPct(target), condition.Op, condition.Value);
        case BonusCondition::Kind::ManaPct:
            return owner->GetMaxPower(POWER_MANA) &&
                Compare(int32(uint64(owner->GetPower(POWER_MANA)) * 100 / owner->GetMaxPower(POWER_MANA)),
                    condition.Op, condition.Value);
        case BonusCondition::Kind::TargetMonster:
            return target && target->IsCreature() && !target->IsControlledByPlayer();
        case BonusCondition::Kind::OutOfCombat:
            return !owner->IsInCombat();
        case BonusCondition::Kind::TargetOutOfCombat:
            return target && !target->IsInCombat();
        case BonusCondition::Kind::Pet:
        case BonusCondition::Kind::NoPet:
        {
            Player const* player = owner->ToPlayer();
            bool const out = player && player->GetPet() && player->GetPet()->IsAlive();
            return out == (condition.What == BonusCondition::Kind::Pet);
        }
        case BonusCondition::Kind::Knows:
        {
            Player const* player = owner->ToPlayer();
            return player && std::any_of(condition.Spells.begin(), condition.Spells.end(),
                [player](uint32 spell) { return player->HasSpell(spell); });
        }
    }
    return false;
}

bool HasAny(Unit const* unit, std::vector<uint32> const& auras, ObjectGuid caster = ObjectGuid::Empty)
{
    return unit && std::any_of(auras.begin(), auras.end(),
        [unit, caster](uint32 aura) { return unit->HasAura(aura, caster); });
}

uint32 Count(BonusRule const& rule, Unit const* owner, Unit const* target)
{
    if (!target)
        return 0;
    uint32 count = uint32(std::count_if(rule.CountAura.begin(), rule.CountAura.end(),
        [owner, target](uint32 aura) { return target->HasAura(aura, owner->GetGUID()); }));
    if (rule.CountMechanic)
        for (auto const& [id, application] : target->GetAppliedAuras())
        {
            Aura const* aura = application->GetBase();
            if (aura->GetCasterGUID() == owner->GetGUID() &&
                (aura->GetSpellInfo()->GetAllEffectsMechanicMask() & (1ULL << rule.CountMechanic)))
                ++count;
        }
    return count;
}

bool HeldAtCast(Unit const* owner, SpellInfo const* spellInfo, std::size_t rule)
{
    if (!spellInfo)
        return false;
    std::lock_guard<std::mutex> lock(SnapshotsLock);
    auto const itr = Snapshots.find(owner->GetGUID());
    return itr != Snapshots.end() && itr->second.Spell == spellInfo->Id &&
        GameTime::Now() - itr->second.Taken < SNAPSHOT_LIFETIME &&
        std::find(itr->second.Rules.begin(), itr->second.Rules.end(), rule) != itr->second.Rules.end();
}

float BonusPct(BonusKind kind, Unit const* owner, Unit const* target, SpellInfo const* spellInfo)
{
    if (!owner || !owner->IsPlayer())
        return 0.0f;
    float total = 0.0f;
    for (std::size_t index = 0; index < Rules.size(); ++index)
    {
        BonusRule const& rule = Rules[index];
        if (rule.Kind != kind)
            continue;
        AuraEffect const* effect = owner->GetAuraEffect(rule.Enchant, rule.Effect);
        if (!effect && !(rule.Amount && owner->HasAura(rule.Enchant)))
            continue;
        if (spellInfo)
        {
            if (!rule.Spells.empty() && !rule.Spells.contains(spellInfo->Id))
                continue;
            if (rule.SchoolMask && !(spellInfo->GetSchoolMask() & rule.SchoolMask))
                continue;
            if (rule.UseMask && !(effect && effect->IsAffectedOnSpell(spellInfo)))
                continue;
        }
        else if (!rule.Spells.empty() || rule.UseMask || (rule.SchoolMask && !(rule.SchoolMask & SPELL_SCHOOL_MASK_NORMAL)))
            continue;
        if (!rule.SelfAura.empty() && !HasAny(owner, rule.SelfAura) && !HeldAtCast(owner, spellInfo, index))
            continue;
        if (!rule.TargetAura.empty() && !HasAny(target, rule.TargetAura, owner->GetGUID()))
            continue;
        if (!std::all_of(rule.Conditions.begin(), rule.Conditions.end(),
            [owner, target](BonusCondition const& condition) { return Holds(condition, owner, target); }))
            continue;
        uint32 const count = rule.CountAura.empty() && !rule.CountMechanic ? 1 : Count(rule, owner, target);
        int32 const amount = rule.Amount ? rule.Amount : (effect ? effect->GetAmount() : 0);
        total += float(amount) * float(count) * rule.Multiplier;
    }
    return total;
}

template <class T>
void Scale(T& value, float pct)
{
    if (pct != 0.0f)
        value = T(std::max(0.0f, float(value) * (100.0f + pct) / 100.0f));
}

class AscensionMysticEnchantBonusUnit final : public UnitScript
{
public:
    AscensionMysticEnchantBonusUnit() : UnitScript("AscensionMysticEnchantBonusUnit", true,
        { UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_MELEE_DAMAGE,
          UNITHOOK_MODIFY_HEAL_RECEIVED }) { }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* spellInfo) override
    {
        if (damage > 0)
            Scale(damage, BonusPct(BonusKind::Damage, attacker, target, spellInfo));
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* spellInfo) override
    {
        if (spellInfo && (spellInfo->HasAura(SPELL_AURA_PERIODIC_HEAL) || spellInfo->HasAura(SPELL_AURA_OBS_MOD_HEALTH)))
            return;
        Scale(damage, BonusPct(BonusKind::Damage, attacker, target, spellInfo));
    }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        Scale(damage, BonusPct(BonusKind::Damage, attacker, target, nullptr));
    }

    void ModifyHealReceived(Unit* target, Unit* healer, uint32& heal, SpellInfo const* spellInfo) override
    {
        Scale(heal, BonusPct(BonusKind::Healing, healer, target, spellInfo) +
            BonusPct(BonusKind::HealingTaken, target, healer, spellInfo));
    }
};

class AscensionMysticEnchantBonusCrit final : public AllSpellScript
{
public:
    AscensionMysticEnchantBonusCrit() : AllSpellScript("AscensionMysticEnchantBonusCrit",
        { ALLSPELLHOOK_ON_CRIT_CHANCE, ALLSPELLHOOK_ON_PREPARE }) { }

    void OnSpellPrepare(Spell*, Unit* caster, SpellInfo const* spellInfo) override
    {
        if (!caster || !caster->IsPlayer())
            return;
        Snapshot snapshot{ spellInfo->Id, GameTime::Now(), {} };
        for (std::size_t index = 0; index < Rules.size(); ++index)
            if (!Rules[index].SelfAura.empty() && HasAny(caster, Rules[index].SelfAura) &&
                (Rules[index].Spells.empty() || Rules[index].Spells.contains(spellInfo->Id)))
                snapshot.Rules.push_back(index);
        std::lock_guard<std::mutex> lock(SnapshotsLock);
        if (snapshot.Rules.empty())
            Snapshots.erase(caster->GetGUID());
        else
            Snapshots[caster->GetGUID()] = std::move(snapshot);
    }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        chance += BonusPct(BonusKind::Crit, spell->GetCaster(), target, spell->GetSpellInfo());
    }
};

class AscensionMysticEnchantBonusWorld final : public WorldScript
{
public:
    AscensionMysticEnchantBonusWorld() : WorldScript("AscensionMysticEnchantBonusWorld", { WORLDHOOK_ON_STARTUP }) { }

    void OnStartup() override
    {
        static std::unordered_map<std::string_view, BonusKind> const KINDS = {
            {"damage", BonusKind::Damage}, {"healing", BonusKind::Healing}, {"healing_taken", BonusKind::HealingTaken},
            {"crit", BonusKind::Crit}};

        Rules.clear();
        QueryResult result = WorldDatabase.Query("SELECT enchant_spell, effect, kind, spells, school_mask, use_mask, "
            "self_aura, target_aura, count_aura, count_mechanic, conditions, amount, multiplier FROM coa_mystic_enchant_bonus");
        if (!result)
        {
            LOG_INFO("server.loading", ">> Loaded 0 Mystic Enchant bonus rules");
            return;
        }
        do
        {
            Field* fields = result->Fetch();
            BonusRule rule;
            rule.Enchant = fields[0].Get<uint32>();
            rule.Effect = fields[1].Get<uint8>();
            auto const kind = KINDS.find(fields[2].Get<std::string>());
            if (rule.Effect >= MAX_SPELL_EFFECTS || kind == KINDS.end())
            {
                LOG_ERROR("sql.sql", "coa_mystic_enchant_bonus: spell {} effect {} has an unknown kind or effect",
                    rule.Enchant, rule.Effect);
                continue;
            }
            rule.Kind = kind->second;
            for (uint32 id : Ids(fields[3].Get<std::string>()))
                rule.Spells.insert(id);
            rule.SchoolMask = fields[4].Get<uint32>();
            rule.UseMask = fields[5].Get<bool>();
            rule.SelfAura = Ids(fields[6].Get<std::string>());
            rule.TargetAura = Ids(fields[7].Get<std::string>());
            rule.CountAura = Ids(fields[8].Get<std::string>());
            rule.CountMechanic = fields[9].Get<uint32>();
            std::string const conditions = fields[10].Get<std::string>();
            bool valid = true;
            for (std::string_view token : Acore::Tokenize(conditions, ' ', false))
            {
                if (Optional<BonusCondition> condition = ParseCondition(token))
                    rule.Conditions.push_back(*condition);
                else
                    valid = false;
            }
            if (!valid)
            {
                LOG_ERROR("sql.sql", "coa_mystic_enchant_bonus: spell {} has an unknown condition '{}'", rule.Enchant,
                    conditions);
                continue;
            }
            rule.Amount = fields[11].Get<int32>();
            rule.Multiplier = fields[12].Get<float>();
            Rules.push_back(std::move(rule));
        } while (result->NextRow());
        LOG_INFO("server.loading", ">> Loaded {} Mystic Enchant bonus rules", Rules.size());
    }
};
}

void AddSC_AscensionMysticEnchantBonus()
{
    new AscensionMysticEnchantBonusUnit();
    new AscensionMysticEnchantBonusCrit();
    new AscensionMysticEnchantBonusWorld();
}
