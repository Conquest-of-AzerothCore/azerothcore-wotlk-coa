#include "Battle.h"
#include "Describe.h"
#include "LuaNumber.h"
#include "Rules.h"
#include <algorithm>
#include <cmath>
#include <map>
#include <set>

namespace CoAPetBattles::Engine
{
    namespace
    {
        std::string Lower(std::string text)
        {
            for (char& c : text)
                if (c >= 'A' && c <= 'Z')
                    c = static_cast<char>(c - 'A' + 'a');
            return text;
        }

        template<typename Visit>
        void ForAbilities(Pet const& pet, Visit visit)
        {
            for (std::optional<PetAbility> const& ability : pet.abil)
            {
                if (!ability)
                    return;
                if (visit(*ability))
                    return;
            }
        }

        std::set<uint16_t> const DisplayDamage = { 24, 222, 96, 62, 65, 54, 52, 172, 178 };
        std::set<uint16_t> const HostileFx = { 24, 222, 54, 52, 172, 178 };
        std::map<std::string, std::string> const LockTexts = {
            { "Asleep", " is asleep and loses its turn!" },
            { "Polymorphed", " has been turned into a frog and cannot act!" },
            { "Stunned", " is stunned and loses its turn!" },
            { "Hibernation", " is hibernating and cannot act!" },
            { "Napping", " is napping and cannot act!" },
            { "Emerald Dream", " is dreaming and cannot act!" },
            { "Repairing", " is repairing and cannot act!" },
        };
    }

    States const* Battle::WeatherStates() const
    {
        if (!resolving || !weather)
            return nullptr;
        return catalog->StatesOf(weather->id);
    }

    bool Has(States const& states, std::string const& key)
    {
        return states.count(key) != 0;
    }

    double Get(States const& states, std::string const& key)
    {
        auto const found = states.find(key);
        return found == states.end() ? 0.0 : found->second;
    }

    double Mod(Battle const* battle, Pet const& pet, std::string const& state)
    {
        double total = 0;
        for (Aura const& aura : pet.auras)
            total += Get(aura.states, state);
        States const* weather = battle ? battle->WeatherStates() : nullptr;
        if (weather && Has(*weather, state) && state.rfind("Mechanic_Is", 0) == 0 && pet.family != "Elemental")
            total += weather->at(state);
        return total;
    }

    std::string EffFam(Pet const& pet)
    {
        for (Aura const& aura : pet.auras)
            if (Has(aura.states, "Special_TypeOverride"))
                return FamilyAt(aura.states.at("Special_TypeOverride")).value_or(pet.family);
        return pet.family;
    }

    void SyncMax(Pet& pet)
    {
        double bonus = 0;
        for (Aura const& aura : pet.auras)
            if (Has(aura.states, "maxHealthBonus"))
                bonus += std::floor(aura.states.at("maxHealthBonus") / 100 * pet.level);
        pet.max = pet.baseMax + bonus;
        if (pet.hp > pet.max)
            pet.hp = pet.max;
    }

    bool HasState(Battle const* battle, Pet const& pet, double stateId)
    {
        Catalog const& catalog = *battle->catalog;
        std::string const* name = catalog.StateName(stateId);
        return name && Mod(battle, pet, *name) != 0;
    }

    bool Beneficial(States const& states)
    {
        static std::set<std::string> const positive = { "Stat_Dodge", "untargettable", "Mod_HealingDealtPercent",
            "Mod_MaxHealthPercent", "Mod_SpeedPercent", "Mod_DamageDealtPercent", "Mod_HealingTakenPercent",
            "Stat_Accuracy" };
        static std::set<std::string> const negative = { "Mod_DamageTakenPercent", "Add_FlatDamageTaken" };
        static std::set<std::string> const harmful = { "Mechanic_IsStunned", "Mechanic_IsPoisoned", "Mechanic_IsBurning",
            "Mechanic_IsBleeding", "Mechanic_IsWebbed", "Mechanic_IsBlind", "Mechanic_IsChilled" };
        double score = 0;
        for (auto const& [key, value] : states)
        {
            if (positive.count(key))
                score += value > 0 ? 1 : -1;
            else if (negative.count(key))
                score += value < 0 ? 1 : -1;
            else if (harmful.count(key))
                score -= 1;
        }
        return score >= 0;
    }

    bool CantAct(Battle const* battle, Pet const& pet)
    {
        return pet.hp > 0 && (Mod(battle, pet, "Mechanic_IsStunned") > 0 || Mod(battle, pet, "turnLock") > 0);
    }

    bool Locked(Battle const* battle, Pet const& pet, std::string const& state)
    {
        return Mod(battle, pet, state) > 0;
    }

    double Speed(Battle const* battle, Pet const& pet)
    {
        double speed = pet.speed * (1 + Mod(battle, pet, "Mod_SpeedPercent") / 100);
        if (pet.family == "Flying" && pet.hp > pet.max * 0.5)
            speed = speed * 1.5;
        return speed;
    }

    bool Ready(Pet const& pet, int32_t slot)
    {
        PetAbility const* ability = pet.Ability(slot);
        return ability && !ability->turns.empty() && pet.cd[static_cast<size_t>(slot) - 1] == 0;
    }

    std::string AuraName(Catalog const& catalog, uint32_t id)
    {
        if (id == 340)
            return "Burrowed";
        if (id == 311)
            return "Dodge";
        if (AbilityDef const* ability = catalog.Ability(id))
            return ability->name;
        return "Effect " + LuaNumber(static_cast<double>(id));
    }

    std::optional<double> AuraTrigger(Catalog const& catalog, uint32_t id)
    {
        AbilityDef const* ability = catalog.Ability(id);
        if (!ability || ability->turns.empty() || ability->turns.front().event == 255)
            return std::nullopt;
        Turn const& turn = ability->turns.front();
        for (Fx const& fx : turn.fx)
            if (fx.prop == 49)
                return turn.event;
        return std::nullopt;
    }

    bool DisplayHostile(Catalog const& catalog, uint32_t id)
    {
        AbilityDef const* ability = catalog.Ability(id);
        if (!ability || id == 1086)
            return false;
        for (Turn const& turn : ability->turns)
            for (Fx const& fx : turn.fx)
                if (DisplayDamage.count(fx.prop))
                    return true;
        return false;
    }

    bool AuraGood(Catalog const& catalog, uint32_t id, States const& states, Pet const* holder, Pet const* src)
    {
        if (src && src != holder && (Has(states, "turnLock") || Has(states, "swapOutLock") ||
            (Has(states, "Stat_Accuracy") && states.at("Stat_Accuracy") < 0)))
            return false;
        if (src == holder && Has(states, "Special_BlockedAttackCount"))
            return true;
        return Beneficial(states) && !(src && src != holder && DisplayHostile(catalog, id));
    }

    std::string AuraNameFor(Catalog const& catalog, uint32_t id, Pet const* src)
    {
        std::optional<std::string> found;
        if (src)
            ForAbilities(*src, [&](PetAbility const& ability)
            {
                AbilityDef const* retail = catalog.Ability(ability.id);
                if (retail && ability.name != retail->name)
                    for (Turn const& turn : retail->turns)
                        for (Fx const& fx : turn.fx)
                            if (fx.aura == id)
                            {
                                found = ability.name;
                                return true;
                            }
                return false;
            });
        return found ? *found : AuraName(catalog, id);
    }

    std::vector<Turn> const& MainTurns(AbilityDef const* ability)
    {
        static std::vector<Turn> const none;
        return ability ? ability->main : none;
    }

    bool AuraHostile(Catalog const& catalog, uint32_t id)
    {
        AbilityDef const* ability = catalog.Ability(id);
        if (!ability)
            return false;
        for (Turn const& turn : MainTurns(ability))
            for (Fx const& fx : turn.fx)
                if (HostileFx.count(fx.prop))
                    return true;
        return false;
    }

    void ApplyAura(Battle& battle, std::vector<Event>& events, Side side, int32_t index, uint32_t id, double duration,
        bool skipTick, std::optional<double> maxStacks, Pet* source)
    {
        Catalog const& catalog = *battle.catalog;
        Pet& pet = battle.At(side, index);
        AbilityDef const* ability = catalog.Ability(id);
        if (ability && MainTurns(ability).size() > 1)
            duration = std::max(duration, static_cast<double>(MainTurns(ability).size()));
        static States const empty;
        States const* found = catalog.StatesOf(id);
        States const& states = found ? *found : empty;
        if (pet.family == "Critter" && source && source != &pet &&
            (Has(states, "Mechanic_IsStunned") || Has(states, "swapOutLock")))
            return;
        bool const lingering = AuraHostile(catalog, id) || Has(states, "Mechanic_IsBleeding") ||
            Has(states, "Mechanic_IsBurning") || Has(states, "Mechanic_IsPoisoned");
        if (pet.family == "Aquatic" && duration > 1 && lingering)
            duration = duration - 1;
        if (States const* weather = battle.WeatherStates())
            if (Has(*weather, "Weather_Rain") && duration > 1 && lingering)
                duration = duration - 1;
        if (Has(states, "Mechanic_IsBomb"))
        {
            battle.bomb[static_cast<size_t>(side)] = Bomb { id, std::max(duration, 1.0), source,
                source ? std::optional<double>(source->power) : std::nullopt };
            Event event { "debuff", {} };
            event.fields["side"] = SideName(side);
            event.fields["idx"] = static_cast<double>(index);
            event.fields["what"] = Lower(AuraNameFor(catalog, id, source));
            event.fields["turns"] = duration;
            events.push_back(event);
            return;
        }
        double count = 0;
        for (Aura& aura : pet.auras)
            if (aura.id == id)
            {
                ++count;
                aura.left = duration;
                aura.perm = duration >= 90;
                aura.skip = skipTick ? std::optional<double>(battle.round) : std::nullopt;
            }
        double const limit = maxStacks && *maxStacks > 0 ? *maxStacks : 1;
        if (count < limit)
        {
            Aura aura;
            aura.id = id;
            aura.left = duration;
            aura.perm = duration >= 90;
            aura.states = states;
            aura.skip = skipTick ? std::optional<double>(battle.round) : std::nullopt;
            aura.on = AuraTrigger(catalog, id);
            if (source)
                aura.pwr = source->power;
            if (ability && ability->family >= 0)
                aura.fam = FamilyAt(ability->family + 1);
            if (!aura.fam && source)
                aura.fam = source->useFam ? *source->useFam : source->family;
            aura.src = source;
            if (Has(states, "Special_BlockedAttackCount"))
                aura.charges = states.at("Special_BlockedAttackCount");
            pet.auras.push_back(aura);
        }
        SyncMax(pet);
        std::string const kind = AuraGood(catalog, id, states, &pet, source) ? "buff" : "debuff";
        std::string const what = Lower(AuraNameFor(catalog, id, source));
        for (Event const& event : events)
            if (event.kind == kind && event.Text("side") == SideName(side) && event.Has("idx") &&
                event.Number("idx") == index && event.Has("what") && event.Text("what") == what)
                return;
        Event event { kind, {} };
        event.fields["side"] = SideName(side);
        event.fields["idx"] = static_cast<double>(index);
        event.fields["what"] = what;
        event.fields["turns"] = duration;
        events.push_back(event);
    }

    void RemoveAura(Pet& pet, uint32_t id)
    {
        pet.auras.erase(std::remove_if(pet.auras.begin(), pet.auras.end(), [id](Aura const& a) { return a.id == id; }),
            pet.auras.end());
    }

    void ConsumeAuras(Pet& pet, double event)
    {
        pet.auras.erase(std::remove_if(pet.auras.begin(), pet.auras.end(),
            [event](Aura const& a) { return a.on && *a.on == event; }), pet.auras.end());
    }

    std::vector<StatusEntry> StatusList(Catalog const& catalog, Pet const& pet)
    {
        std::vector<StatusEntry> list;
        std::map<uint32_t, size_t> seen;
        for (Aura const& aura : pet.auras)
        {
            if (AuraName(catalog, aura.id).find("Server Only") != std::string::npos)
                continue;
            auto const previous = seen.find(aura.id);
            if (previous != seen.end())
            {
                StatusEntry& entry = list[previous->second];
                entry.stacks += 1;
                if (!aura.perm && aura.left < 90)
                    entry.turns = std::max(entry.turns, aura.left);
                continue;
            }
            bool const good = AuraGood(catalog, aura.id, aura.states, &pet, aura.src);
            StatusEntry entry;
            entry.aid = aura.id;
            entry.label = AuraNameFor(catalog, aura.id, aura.src);
            entry.icon = good ? "Spell_Holy_PowerWordShield" : "Spell_Shadow_CurseOfTounges";
            entry.turns = (aura.perm || aura.left >= 90) ? 0 : aura.left;
            entry.bad = !good;
            entry.power = aura.pwr.value_or(pet.power);
            entry.src = aura.src;
            States const& s = aura.states;
            if (Has(s, "untargettable"))
                entry.icon = "Ability_Stealth";
            else if (Has(s, "Stat_Dodge"))
                entry.icon = "Ability_Rogue_Feint";
            else if (Has(s, "Mod_SpeedPercent"))
                entry.icon = "Ability_Rogue_Sprint";
            else if (Has(s, "Mechanic_IsStunned"))
                entry.icon = "Spell_Frost_Stun";
            else if (Has(s, "Mechanic_IsBleeding"))
                entry.icon = "Ability_Rogue_Rupture";
            else if (Has(s, "Mechanic_IsPoisoned"))
                entry.icon = "Ability_Rogue_DualWeild";
            else if (Has(s, "Mod_DamageTakenPercent") && s.at("Mod_DamageTakenPercent") < 0)
                entry.icon = "Ability_Defend";
            seen[aura.id] = list.size();
            list.push_back(entry);
        }
        return list;
    }

    std::string StatusTip(Catalog const& catalog, StatusEntry const& entry)
    {
        std::string const name = AuraNameFor(catalog, entry.aid, entry.src);
        std::optional<std::string> tip;
        if (name != AuraName(catalog, entry.aid) && entry.src)
            ForAbilities(*entry.src, [&](PetAbility const& ability)
            {
                if (ability.name == name && !ability.text.empty())
                {
                    tip = Describe(catalog, { ability.text, &ability.turns, ability.family, std::nullopt },
                        entry.power);
                    return true;
                }
                return false;
            });
        return tip ? *tip : AuraTip(catalog, entry.aid, entry.power);
    }

    std::string StatusString(Catalog const& catalog, Pet const& pet, std::map<std::string, std::string>* tips)
    {
        std::string text;
        for (StatusEntry const& entry : StatusList(catalog, pet))
        {
            if (tips)
                (*tips)[entry.label] = StatusTip(catalog, entry);
            text += (text.empty() ? "" : ";") + entry.label + "~" + entry.icon + "~" + LuaNumber(entry.turns) + "~" +
                LuaNumber(entry.stacks) + "~" + (entry.bad ? "1" : "0");
        }
        return text;
    }

    std::string TagText(Catalog const& catalog, Pet const& pet)
    {
        std::string text;
        bool first = true;
        for (StatusEntry const& entry : StatusList(catalog, pet))
        {
            text += (first ? "" : "  ") + entry.label + (entry.stacks > 1 ? " x" + LuaNumber(entry.stacks) : "");
            first = false;
        }
        return text;
    }

    std::optional<std::string> LockLabel(Catalog const& catalog, Pet const& pet)
    {
        for (Aura const& aura : pet.auras)
            if (Has(aura.states, "Mechanic_IsStunned") || Has(aura.states, "turnLock"))
                return AuraNameFor(catalog, aura.id, aura.src);
        return std::nullopt;
    }

    std::string LockText(Event const& event)
    {
        if (event.Flag("pass"))
            return " has nothing ready and passes the turn!";
        if (event.Has("label"))
        {
            std::string const label = event.Text("label");
            if (auto found = LockTexts.find(label); found != LockTexts.end())
                return found->second;
            return " is " + Lower(label) + " and cannot act!";
        }
        if (auto found = LockTexts.find(""); found != LockTexts.end())
            return found->second;
        return event.Flag("self") ? " cannot act!" : " is stunned and loses its turn!";
    }
}
