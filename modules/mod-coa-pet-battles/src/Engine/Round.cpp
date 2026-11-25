#include "Round.h"
#include "Describe.h"
#include "Rules.h"
#include <algorithm>
#include <cmath>
#include <set>

namespace CoAPetBattles::Engine
{
    namespace
    {
        std::set<uint16_t> const DamageProps = { 24, 222, 96, 62 };
        std::set<uint16_t> const ApplyProps = { 50, 52, 178 };
        std::set<uint16_t> const InertProps = { 158, 177, 85, 229, 116, 28, 170, 31, 157, 156, 136, 159, 79, 194, 135,
            137, 107 };

        double LuaRound(double x) { return std::floor(x + 0.5); }
        double Bonus(std::optional<double> power) { return 1 + power.value_or(0) / 20; }
        bool IsDamage(uint16_t prop) { return DamageProps.count(prop) != 0; }

        std::string Lower(std::string text)
        {
            for (char& c : text)
                if (c >= 'A' && c <= 'Z')
                    c = static_cast<char>(c - 'A' + 'a');
            return text;
        }

        Event MakeEvent(std::string kind)
        {
            return Event { std::move(kind), {} };
        }

        void SetNumber(Event& e, std::string const& key, double value) { e.fields[key] = value; }
        void SetText(Event& e, std::string const& key, std::string const& value) { e.fields[key] = value; }
        void SetFlag(Event& e, std::string const& key, bool value) { e.fields[key] = value; }
        void SetSide(Event& e, std::string const& key, Side side) { e.fields[key] = SideName(side); }

        Catalog const& Cat(Battle const& b) { return *b.catalog; }

        double Alive(Battle const& b, Side s)
        {
            double n = 0;
            for (Pet const& p : b.Team(s))
                if (p.hp > 0)
                    ++n;
            return n;
        }

        std::optional<int32_t> NextAlive(Battle const& b, Side s)
        {
            std::vector<Pet> const& team = b.Team(s);
            for (size_t i = 0; i < team.size(); ++i)
                if (team[i].hp > 0)
                    return static_cast<int32_t>(i + 1);
            return std::nullopt;
        }

        double MagicCap(Pet const& p, double d)
        {
            if (p.family == "Magic" && d > std::floor(p.max * 0.35))
                return std::floor(p.max * 0.35);
            return d;
        }

        void Detonate(Battle& b, std::vector<Event>& ev, Side s);

        std::optional<double> CommandNumber(std::string const& command)
        {
            return LuaToNumber(command.size() > 1 ? command.substr(1) : std::string());
        }

        int32_t CommandSlot(std::string const& command)
        {
            std::optional<double> const number = CommandNumber(command);
            if (!number)
                return 1;
            if (*number >= 1 && *number <= 3 && *number == std::floor(*number))
                return static_cast<int32_t>(*number);
            return 0;
        }

        std::optional<int32_t> TeamIndex(Battle const& b, Side side, std::string const& command)
        {
            std::optional<double> const number = CommandNumber(command);
            if (!number || *number != std::floor(*number) || *number < 1 ||
                *number > static_cast<double>(b.Team(side).size()))
                return std::nullopt;
            return static_cast<int32_t>(*number);
        }

        void FixLastHp(std::vector<Event>& ev, Side s, int32_t idx, double hp)
        {
            if (ev.empty())
                return;
            Event& last = ev.back();
            bool const hit = last.kind == "dmg" && last.Text("tside") == SideName(s) && last.Has("tidx") &&
                last.Number("tidx") == idx;
            bool const dot = last.kind == "dot" && last.Text("side") == SideName(s) && last.Has("idx") &&
                last.Number("idx") == idx;
            if (hit || dot)
                last.fields["hp"] = hp;
        }

        void ReviveEvent(std::vector<Event>& ev, Side s, int32_t idx, Pet const& p)
        {
            Event e = MakeEvent("heal");
            SetSide(e, "side", s);
            SetNumber(e, "idx", idx);
            SetNumber(e, "amt", p.hp);
            SetNumber(e, "hp", p.hp);
            SetNumber(e, "max", p.max);
            SetFlag(e, "quick", true);
            SetFlag(e, "revive", true);
            ev.push_back(e);
        }

        void Faint(Battle& b, std::vector<Event>& ev, Side s, int32_t idx, bool final = false)
        {
            Pet& p = b.At(s, idx);
            p.hp = 0;
            if (!final)
            {
                for (size_t ai = p.auras.size(); ai >= 1; --ai)
                {
                    if (ai > p.auras.size())
                        continue;
                    AbilityDef const* aab = Cat(b).Ability(p.auras[ai - 1].id);
                    if (aab)
                        for (Turn const& pt : aab->turns)
                        {
                            if (pt.event != 7)
                                continue;
                            for (Fx const& rf : pt.fx)
                            {
                                if (rf.prop != 111 || p.hp != 0)
                                    continue;
                                if (ai <= p.auras.size())
                                    p.auras.erase(p.auras.begin() + static_cast<std::ptrdiff_t>(ai - 1));
                                p.hp = std::max(1.0, std::floor(p.max * rf.p[0] / 100));
                                p.channel.reset();
                                FixLastHp(ev, s, idx, p.hp);
                                ReviveEvent(ev, s, idx, p);
                                for (Fx const& rf2 : pt.fx)
                                    if (rf2.prop == 26 && rf2.aura != 0)
                                        ApplyAura(b, ev, s, idx, rf2.aura, 99, true, std::nullopt, nullptr);
                            }
                        }
                    if (p.hp > 0)
                        return;
                }
            }
            if (!final && !p.revived && (p.family == "Undead" || p.family == "Mechanical"))
            {
                p.revived = true;
                if (p.family == "Undead")
                {
                    p.hp = 1;
                    p.undeadLeft = 2;
                }
                else
                    p.hp = std::max(1.0, std::floor(p.max * 0.2));
                p.auras.Replace();
                p.channel.reset();
                FixLastHp(ev, s, idx, p.hp);
                ReviveEvent(ev, s, idx, p);
                return;
            }
            p.auras.Replace();
            p.channel.reset();
            p.undeadLeft.reset();
            Event e = MakeEvent("faint");
            SetSide(e, "side", s);
            SetNumber(e, "idx", idx);
            ev.push_back(e);
        }

        double DoHeal(Battle& b, std::vector<Event>& ev, Side s, int32_t i, double amount,
            std::optional<bool> quick = std::nullopt)
        {
            if (i < 1 || static_cast<size_t>(i) > b.Team(s).size())
                return 0;
            Pet& q = b.At(s, i);
            if (q.hp <= 0)
                return 0;
            double const amt = std::min(amount, q.max - q.hp);
            if (amt <= 0)
                return 0;
            q.hp = q.hp + amt;
            Event e = MakeEvent("heal");
            SetSide(e, "side", s);
            SetNumber(e, "idx", i);
            SetNumber(e, "amt", amt);
            SetNumber(e, "hp", q.hp);
            SetNumber(e, "max", q.max);
            if (quick)
                SetFlag(e, "quick", *quick);
            ev.push_back(e);
            return amt;
        }

        double Flat(Battle const& b, Pet const& tgt)
        {
            double t = 0;
            for (Aura const& a : tgt.auras)
                if (Has(a.states, "Add_FlatDamageTaken"))
                    t = t + a.states.at("Add_FlatDamageTaken") * (1 + a.pwr.value_or(0) / 20);
            States const* w = b.WeatherStates();
            if (w && Has(*w, "Add_FlatDamageTaken") && tgt.family != "Elemental")
                t = t + w->at("Add_FlatDamageTaken");
            return LuaRound(t);
        }

        double WeatherBoost(Battle const& b, std::string const& fam, Pet const& pet)
        {
            States const* w = b.WeatherStates();
            if (pet.family == "Elemental")
                return 0;
            if (w && Has(*w, "Mod_PetTypeDamageDealtPercent") &&
                FamilyAt(Get(*w, "Mod_PetType_ID")).value_or("") == fam && !fam.empty())
                return w->at("Mod_PetTypeDamageDealtPercent");
            return 0;
        }

        double WeatherBonus(Battle const& b, Pet const& pet, Pet const& tgt)
        {
            if (!(b.resolving && b.weather) || pet.family == "Elemental")
                return 0;
            AbilityDef const* wab = Cat(b).Ability(b.weather->id);
            if (!wab)
                return 0;
            for (Turn const& pt : wab->turns)
                if (pt.event == 2)
                    for (Fx const& f : pt.fx)
                        if (f.prop == 169)
                            return Damage(f.p[0], pet.power, FamilyAt(wab->family + 1).value_or("Mechanical"),
                                EffFam(tgt), 0, 0);
            return 0;
        }

        double Dmg(Battle const& b, Pet const& pet, Pet const& tgt, double points)
        {
            std::string const fam = pet.useFam ? *pet.useFam : pet.family;
            double dealt = Mod(&b, pet, "Mod_DamageDealtPercent") + WeatherBoost(b, fam, pet);
            if (pet.family == "Beast" && pet.hp < pet.max * 0.5)
                dealt += 25;
            if (pet.family == "Dragonkin" && pet.dragonRound && b.resolving && *pet.dragonRound == b.round)
                dealt += 50;
            return std::max(1.0, Damage(points, pet.power, fam, EffFam(tgt), dealt,
                Mod(&b, tgt, "Mod_DamageTakenPercent")) + Flat(b, tgt) + WeatherBonus(b, pet, tgt));
        }

        void DodgeEvent(std::vector<Event>& ev, Side o, int32_t oi, Side s, std::optional<std::string> text,
            bool more, Pet const& tgt)
        {
            Event e = MakeEvent("dodge");
            SetSide(e, "side", o);
            SetNumber(e, "idx", oi);
            SetSide(e, "from", s);
            if (text)
                SetText(e, "text", *text);
            SetFlag(e, "more", more);
            SetNumber(e, "hp", tgt.hp);
            SetNumber(e, "max", tgt.max);
            ev.push_back(e);
        }

        void ReflectEvent(std::vector<Event>& ev, Side o, int32_t oi, Side s, int32_t si, double dmg, Pet const& pet)
        {
            Event e = MakeEvent("dmg");
            SetSide(e, "side", o);
            SetNumber(e, "idx", oi);
            SetSide(e, "tside", s);
            SetNumber(e, "tidx", si);
            SetNumber(e, "dmg", dmg);
            SetNumber(e, "hp", pet.hp);
            SetNumber(e, "max", pet.max);
            SetFlag(e, "reflect", true);
            SetFlag(e, "more", false);
            SetNumber(e, "counter", 1);
            ev.push_back(e);
        }

        bool Hit(Battle& b, std::vector<Event>& ev, Side s, Pet& pet, double points, double accuracy,
            std::optional<double> slot, bool more, std::optional<double> raw = std::nullopt)
        {
            Side const o = Other(s);
            int32_t const oi = b.Active(o);
            Pet& tgt = b.At(o, oi);
            if (pet.hp <= 0 || tgt.hp <= 0)
                return false;
            if (tgt.undeadLeft && *tgt.undeadLeft == 2)
                return false;
            if (Mod(&b, tgt, "untargettable") > 0)
            {
                DodgeEvent(ev, o, oi, s, std::string("Burrowed!"), more, tgt);
                return false;
            }
            for (size_t i = 0; i < tgt.auras.size(); ++i)
            {
                Aura& a = tgt.auras[i];
                if (a.charges && *a.charges > 0)
                {
                    a.charges = *a.charges - 1;
                    if (*a.charges <= 0)
                        tgt.auras.erase(tgt.auras.begin() + static_cast<std::ptrdiff_t>(i));
                    DodgeEvent(ev, o, oi, s, std::string("Blocked!"), more, tgt);
                    return false;
                }
            }
            if (b.wall && b.wall->charges > 0)
            {
                b.wall->charges -= 1;
                if (b.wall->charges <= 0)
                    b.wall.reset();
                DodgeEvent(ev, o, oi, s, std::string("Blocked!"), more, tgt);
                return false;
            }
            double const dodge = std::min(100.0, Mod(&b, tgt, "Stat_Dodge"));
            if (dodge > 0 && b.rng->Roll(1, 100) <= dodge)
            {
                DodgeEvent(ev, o, oi, s, std::nullopt, more, tgt);
                return false;
            }
            States const* ws = b.WeatherStates();
            if (ws && Has(*ws, "Stat_Accuracy") && accuracy <= 100 && pet.family != "Elemental")
                accuracy = accuracy + ws->at("Stat_Accuracy");
            double const auraAcc = Mod(&b, pet, "Stat_Accuracy");
            if (auraAcc != 0 && accuracy <= 100)
                accuracy = std::max(0.0, accuracy + auraAcc);
            if (accuracy < 100 && b.rng->Roll(1, 100) > accuracy)
            {
                DodgeEvent(ev, o, oi, s, std::string("Miss!"), more, tgt);
                return false;
            }
            double dmg = raw ? *raw : Dmg(b, pet, tgt, points);
            bool crit = false;
            if (!raw)
                crit = b.rng->Roll(1, 100) <= 5 + Mod(&b, pet, "Stat_CritChance");
            if (crit)
                dmg = dmg * 2;
            dmg = MagicCap(tgt, dmg);
            if (Mod(&b, tgt, "unkillable") > 0 && tgt.hp - dmg < 1)
                dmg = std::max(0.0, tgt.hp - 1);
            double const hpBefore = tgt.hp;
            tgt.hp = std::max(0.0, tgt.hp - dmg);
            tgt.lastTaken = dmg;
            if (pet.family == "Dragonkin" && hpBefore >= tgt.max * 0.5 && tgt.hp < tgt.max * 0.5 && tgt.hp > 0)
                pet.dragonRound = b.round + 1;
            Event e = MakeEvent("dmg");
            SetSide(e, "side", s);
            SetNumber(e, "idx", b.Active(s));
            SetSide(e, "tside", o);
            SetNumber(e, "tidx", oi);
            SetNumber(e, "dmg", dmg);
            SetFlag(e, "crit", crit);
            SetNumber(e, "hp", tgt.hp);
            SetNumber(e, "max", tgt.max);
            if (slot)
                SetNumber(e, "slot", *slot);
            SetFlag(e, "more", more);
            SetNumber(e, "counter", Matchup(pet.useFam ? *pet.useFam : pet.family, EffFam(tgt)));
            ev.push_back(e);
            if (pet.family == "Humanoid" && dmg > 0 && pet.hp > 0)
                DoHeal(b, ev, s, b.Active(s), std::floor(pet.max * 0.04), true);
            {
                auto table = tgt.auras.Share();
                for (size_t i = 0; i < table->size(); ++i)
                {
                    Aura const a = (*table)[i];
                    AbilityDef const* aab = Cat(b).Ability(a.id);
                    if (!aab)
                        continue;
                    for (Turn const& pt : aab->turns)
                    {
                        if (pt.event != 1)
                            continue;
                        for (Fx const& rf : pt.fx)
                        {
                            if (rf.prop == 204 && pet.hp > 0 && dmg > 0)
                            {
                                double const rd = std::floor(dmg * rf.p[0] / 100);
                                if (rd > 0)
                                {
                                    pet.hp = std::max(0.0, pet.hp - rd);
                                    ReflectEvent(ev, o, oi, s, b.Active(s), rd, pet);
                                    if (pet.hp <= 0)
                                        Faint(b, ev, s, b.Active(s));
                                }
                            }
                            if (rf.prop == 179 && pet.hp > 0)
                            {
                                double const rd = MagicCap(pet, Damage(rf.p[0], a.pwr.value_or(tgt.power),
                                    a.fam ? *a.fam : tgt.family, pet.family, 0, Mod(&b, pet, "Mod_DamageTakenPercent")));
                                pet.hp = std::max(0.0, pet.hp - rd);
                                ReflectEvent(ev, o, oi, s, b.Active(s), rd, pet);
                                if (pet.hp <= 0)
                                    Faint(b, ev, s, b.Active(s));
                            }
                        }
                    }
                }
            }
            {
                auto table = pet.auras.Share();
                for (size_t i = 0; i < table->size(); ++i)
                {
                    Aura const a = (*table)[i];
                    AbilityDef const* aab = Cat(b).Ability(a.id);
                    if (!aab)
                        continue;
                    for (Turn const& pt : aab->turns)
                    {
                        if (pt.event != 2)
                            continue;
                        for (Fx const& rf : pt.fx)
                            if (rf.prop == 24 && pet.hp > 0)
                            {
                                double const rd = MagicCap(pet, Damage(rf.p[0], a.pwr.value_or(pet.power),
                                    a.fam ? *a.fam : pet.family, EffFam(pet), 0, Mod(&b, pet, "Mod_DamageTakenPercent")));
                                pet.hp = std::max(0.0, pet.hp - rd);
                                ReflectEvent(ev, o, oi, s, b.Active(s), rd, pet);
                                if (pet.hp <= 0)
                                    Faint(b, ev, s, b.Active(s));
                            }
                    }
                }
            }
            {
                auto table = tgt.auras.Share();
                for (size_t i = 0; i < table->size(); ++i)
                {
                    Aura const a = (*table)[i];
                    AbilityDef const* aab = Cat(b).Ability(a.id);
                    if (!aab)
                        continue;
                    for (Turn const& pt : aab->turns)
                        if (pt.event == 1)
                            for (Fx const& rf : pt.fx)
                                if (rf.prop == 23 && pet.hp > 0)
                                    DoHeal(b, ev, s, b.Active(s), Heal(rf.p[0], a.pwr.value_or(tgt.power)));
                }
            }
            ConsumeAuras(pet, 2);
            ConsumeAuras(tgt, 1);
            if (tgt.hp <= 0)
                Faint(b, ev, o, oi);
            return true;
        }

        struct Context
        {
            Battle& b;
            std::vector<Event>& ev;
            Side s;
            int32_t idx;
            Side o;
            Pet& pet;
            Pet& tgt;
            PetAbility const& ab;
            Turn const& turn;
            double turnNo;
            int32_t slot;
            bool actedFirst;
            bool actedSecond;
            bool missStun;
            double hits;
            double hp0;
            double done = 0;
            double healed = 0;
            bool landed = false;
            std::optional<double> runK;
            std::set<double> cstate;
            double h29 = 0;
            double h100 = 0;
            bool weatherSeen = false;
        };

        enum class Flow
        {
            Next,
            Stop,
        };

        bool ChanceRoll(Battle& b, double chance)
        {
            return chance >= 100 || b.rng->Roll(1, 100) <= chance;
        }

        bool Targetable(Context& X)
        {
            return X.tgt.hp > 0 && Mod(&X.b, X.tgt, "untargettable") == 0;
        }

        Flow FX00(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            if (p[1] >= 200 && IsDamage(f.prop) && X.done > 0)
            {
                double const selfDmg = std::max(1.0, Damage(p[0], X.pet.power, X.pet.family, X.pet.family, 0, 0));
                X.pet.hp = std::max(1.0, X.pet.hp - selfDmg);
                Event e = MakeEvent("dmg");
                SetSide(e, "side", X.s);
                SetNumber(e, "idx", X.idx);
                SetSide(e, "tside", X.s);
                SetNumber(e, "tidx", X.idx);
                SetNumber(e, "dmg", selfDmg);
                SetNumber(e, "hp", X.pet.hp);
                SetNumber(e, "max", X.pet.max);
                SetNumber(e, "slot", X.slot);
                SetFlag(e, "more", false);
                SetFlag(e, "recoil", true);
                SetNumber(e, "counter", 1);
                X.ev.push_back(e);
                return Flow::Next;
            }
            X.done = X.done + 1;
            double const acc = (f.prop == 96 && HasState(&X.b, X.tgt, p[3])) ? 100 : p[1];
            X.landed = Hit(X.b, X.ev, X.s, X.pet, p[0], acc, X.slot, X.done < X.hits) || X.landed;
            if (X.landed && X.tgt.hp <= 0)
                return Flow::Stop;
            return Flow::Next;
        }

        Flow FX01(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            X.done = X.done + 1;
            double const uses = X.pet.ramp.count(X.ab.id) ? X.pet.ramp[X.ab.id] : 0;
            double const pts = std::min(p[3], p[0] + p[2] * uses);
            if (X.turnNo == 1 && !X.ab.turns.empty())
                X.pet.ramp[X.ab.id] = uses + 1;
            X.landed = Hit(X.b, X.ev, X.s, X.pet, pts, p[1], X.slot, X.done < X.hits) || X.landed;
            return Flow::Next;
        }

        Flow FX02(Context& X, Fx const& f)
        {
            if (X.pet.lastTaken > 0 && X.tgt.hp > 0)
                Hit(X.b, X.ev, X.s, X.pet, f.p[0], f.p[1], X.slot, false);
            return Flow::Next;
        }

        Flow FX03(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            X.done = X.done + 1;
            Side const o2 = Other(X.s);
            std::vector<int32_t> alive;
            for (size_t i = 0; i < X.b.Team(o2).size(); ++i)
                if (X.b.Team(o2)[i].hp > 0)
                    alive.push_back(static_cast<int32_t>(i + 1));
            double total = Dmg(X.b, X.pet, X.tgt, p[0]);
            if (p[2] > 0 && p[3] > 0)
            {
                States const* w = X.b.WeatherStates();
                if (w && Has(*w, "Weather_Rain"))
                    total = std::floor(total * (1 + p[2] / 100) + 0.5);
            }
            double share = std::max(1.0, std::floor(total / static_cast<double>(alive.size()) + 0.5));
            for (size_t k = 0; k < alive.size(); ++k)
            {
                int32_t const i = alive[k];
                Pet& q = X.b.At(o2, i);
                if (i == X.b.Active(o2))
                    X.landed = Hit(X.b, X.ev, X.s, X.pet, 0, 100, X.slot, X.done < X.hits || k + 1 < alive.size(),
                        share) || X.landed;
                else
                {
                    share = MagicCap(q, share);
                    q.hp = std::max(0.0, q.hp - share);
                    Event e = MakeEvent("dmg");
                    SetSide(e, "side", X.s);
                    SetNumber(e, "idx", X.idx);
                    SetSide(e, "tside", o2);
                    SetNumber(e, "tidx", i);
                    SetNumber(e, "dmg", share);
                    SetNumber(e, "hp", q.hp);
                    SetNumber(e, "max", q.max);
                    SetNumber(e, "slot", X.slot);
                    SetFlag(e, "bench", true);
                    SetFlag(e, "more", true);
                    X.ev.push_back(e);
                    if (q.hp <= 0)
                    {
                        Faint(X.b, X.ev, o2, i);
                        SetFlag(X.ev.back(), "bench", true);
                    }
                }
            }
            return Flow::Next;
        }

        Flow FX04(Context& X, Fx const& f)
        {
            double const got = X.hp0 - X.tgt.hp;
            if (got > 0)
                DoHeal(X.b, X.ev, X.s, X.idx, std::floor(got * f.p[0] / 100));
            return Flow::Next;
        }

        Flow FX05(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            if (X.actedFirst && Targetable(X) && ChanceRoll(X.b, p[1]))
                ApplyAura(X.b, X.ev, X.o, X.b.Active(X.o), f.aura, std::max(1.0, p[2]), false, std::nullopt, &X.pet);
            return Flow::Next;
        }

        Flow FX06(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            X.done = X.done + 1;
            double pts = p[0];
            if (HasState(&X.b, X.tgt, p[3]))
                pts = pts + p[2];
            X.landed = Hit(X.b, X.ev, X.s, X.pet, pts, p[1], X.slot, X.done < X.hits) || X.landed;
            return X.landed && X.tgt.hp <= 0 ? Flow::Stop : Flow::Next;
        }

        Flow FX07(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            X.done = X.done + 1;
            double pts = p[0];
            if (X.tgt.hp < X.tgt.max * 0.25)
                pts = pts * (100 + p[2]) / 100;
            X.landed = Hit(X.b, X.ev, X.s, X.pet, pts, p[1], X.slot, X.done < X.hits) || X.landed;
            return X.landed && X.tgt.hp <= 0 ? Flow::Stop : Flow::Next;
        }

        Flow FX08(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            X.done = X.done + 1;
            X.landed = Hit(X.b, X.ev, X.s, X.pet, 0, p[1], X.slot, false, std::floor(X.pet.max * p[0] / 100)) ||
                X.landed;
            if (X.pet.hp > 0)
            {
                X.pet.hp = 0;
                Faint(X.b, X.ev, X.s, X.idx, true);
            }
            return Flow::Next;
        }

        Flow FX09(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            X.done = X.done + 1;
            double const dmg = Dmg(X.b, X.pet, X.tgt, p[0]);
            X.landed = Hit(X.b, X.ev, X.s, X.pet, 0, p[1], X.slot, X.done < X.hits,
                std::max(0.0, std::min(dmg, X.tgt.hp - 1))) || X.landed;
            return Flow::Next;
        }

        void WeatherEvent(Battle& b, std::vector<Event>& ev, uint32_t id)
        {
            Event e = MakeEvent("weather");
            SetNumber(e, "id", id);
            SetNumber(e, "turns", b.weather->left);
            SetText(e, "name", AuraName(Cat(b), id));
            ev.push_back(e);
        }

        Flow FX10(Context& X, Fx const& f)
        {
            X.weatherSeen = true;
            X.b.weather = Weather { f.aura, std::max(1.0, f.p[2]) };
            WeatherEvent(X.b, X.ev, f.aura);
            return Flow::Next;
        }

        Flow FX11(Context& X, Fx const&)
        {
            if (X.tgt.hp > 0 && X.pet.hp > 0 && Mod(&X.b, X.tgt, "untargettable") == 0)
            {
                double const avg = std::floor((X.pet.hp + X.tgt.hp) / 2);
                if (X.tgt.hp > avg)
                {
                    DoHeal(X.b, X.ev, X.s, X.idx, avg - X.pet.hp);
                    Hit(X.b, X.ev, X.s, X.pet, 0, 100, X.slot, false, std::min(X.tgt.hp - avg, X.tgt.hp - 1));
                }
                else if (X.pet.hp > avg)
                {
                    double const loss = std::min(X.pet.hp - avg, X.pet.hp - 1);
                    X.pet.hp = X.pet.hp - loss;
                    Event e = MakeEvent("dmg");
                    SetSide(e, "side", X.s);
                    SetNumber(e, "idx", X.idx);
                    SetSide(e, "tside", X.s);
                    SetNumber(e, "tidx", X.idx);
                    SetNumber(e, "dmg", loss);
                    SetNumber(e, "hp", X.pet.hp);
                    SetNumber(e, "max", X.pet.max);
                    SetNumber(e, "slot", X.slot);
                    SetFlag(e, "more", false);
                    SetFlag(e, "recoil", true);
                    SetNumber(e, "counter", 1);
                    X.ev.push_back(e);
                    DoHeal(X.b, X.ev, X.o, X.b.Active(X.o), avg - X.tgt.hp);
                }
            }
            return Flow::Next;
        }

        Flow FX12(Context& X, Fx const& f)
        {
            bool const onTarget = f.prop == 77;
            Pet& holder = onTarget ? X.tgt : X.pet;
            Side const hs = onTarget ? X.o : X.s;
            int32_t const hi = onTarget ? X.b.Active(X.o) : X.idx;
            bool have = false;
            for (Aura const& a : holder.auras)
                if (a.id == f.aura)
                    have = true;
            if (have)
            {
                RemoveAura(holder, f.aura);
                X.done = X.done + 1;
                X.landed = Hit(X.b, X.ev, X.s, X.pet, f.p[0], f.p[1], X.slot, false) || X.landed;
            }
            else if (f.prop == 75 || Targetable(X))
                ApplyAura(X.b, X.ev, hs, hi, f.aura, f.prop == 75 ? 99 : 2, true, std::nullopt, &X.pet);
            return Flow::Next;
        }

        Flow FX13(Context& X, Fx const& f)
        {
            if (Targetable(X) && ChanceRoll(X.b, f.p[1]))
                ApplyAura(X.b, X.ev, X.o, X.b.Active(X.o), f.aura, std::max(1.0, f.p[2]), true, std::nullopt, &X.pet);
            return Flow::Next;
        }

        Flow FX14(Context& X, Fx const& f)
        {
            DoHeal(X.b, X.ev, X.s, X.idx, std::floor(X.pet.max * f.p[0] / 100));
            return Flow::Next;
        }

        Flow FX15(Context& X, Fx const& f)
        {
            X.h100 = X.h100 + 1;
            std::optional<std::string> const want = FamilyAt(f.p[3]);
            double k = 0;
            std::vector<Pet>& team = X.b.Team(X.s);
            for (size_t i = 0; i < team.size(); ++i)
            {
                Pet& q = team[i];
                if (static_cast<int32_t>(i + 1) != X.idx && q.hp > 0 && (!want || q.family == *want))
                {
                    k = k + 1;
                    if (k == X.h100)
                    {
                        DoHeal(X.b, X.ev, X.s, static_cast<int32_t>(i + 1), Heal(f.p[0], X.pet.power), true);
                        break;
                    }
                }
            }
            return Flow::Next;
        }

        Flow FX16(Context& X, Fx const& f)
        {
            States const* st = Cat(X.b).StatesOf(f.aura);
            double const charges = st && Has(*st, "Special_BlockedAttackCount") ? st->at("Special_BlockedAttackCount") : 2;
            X.b.wall = Wall { f.aura, charges, X.s };
            Event e = MakeEvent("buff");
            SetSide(e, "side", X.s);
            SetNumber(e, "idx", X.idx);
            SetText(e, "what", Lower(AuraName(Cat(X.b), f.aura)));
            SetNumber(e, "turns", charges);
            X.ev.push_back(e);
            return Flow::Next;
        }

        Flow FX17(Context& X, Fx const& f)
        {
            if (X.pet.lastTaken > 0)
                DoHeal(X.b, X.ev, X.s, X.idx, std::floor(X.pet.lastTaken * f.p[0] / 100), true);
            return Flow::Next;
        }

        Flow FX18(Context& X, Fx const& f)
        {
            X.done = X.done + 1;
            if (X.pet.lastTaken > 0)
                X.landed = Hit(X.b, X.ev, X.s, X.pet, 0, 100, X.slot, X.done < X.hits,
                    std::floor(X.pet.lastTaken * f.p[0] / 100)) || X.landed;
            return Flow::Next;
        }

        Flow FX19(Context& X, Fx const& f)
        {
            if (f.p[4] == 0 || HasState(&X.b, X.tgt, f.p[4]))
                X.cstate.insert(f.p[0]);
            return Flow::Next;
        }

        Flow FX20(Context& X, Fx const& f)
        {
            if (!X.cstate.count(f.p[2]))
                return Flow::Next;
            X.h29 = X.h29 + 1;
            Side const o2 = Other(X.s);
            double k = 0;
            std::vector<Pet>& team = X.b.Team(o2);
            for (size_t i = 0; i < team.size(); ++i)
            {
                Pet& q = team[i];
                int32_t const index = static_cast<int32_t>(i + 1);
                if (q.hp > 0 && index != X.b.Active(o2))
                {
                    k = k + 1;
                    if (k == X.h29)
                    {
                        double const d = MagicCap(q, Dmg(X.b, X.pet, q, f.p[0]));
                        q.hp = std::max(0.0, q.hp - d);
                        Event e = MakeEvent("dmg");
                        SetSide(e, "side", X.s);
                        SetNumber(e, "idx", X.idx);
                        SetSide(e, "tside", o2);
                        SetNumber(e, "tidx", index);
                        SetNumber(e, "dmg", d);
                        SetNumber(e, "hp", q.hp);
                        SetNumber(e, "max", q.max);
                        SetNumber(e, "slot", X.slot);
                        SetFlag(e, "bench", true);
                        SetFlag(e, "more", true);
                        X.ev.push_back(e);
                        if (q.hp <= 0)
                        {
                            Faint(X.b, X.ev, o2, index);
                            SetFlag(X.ev.back(), "bench", true);
                        }
                    }
                }
            }
            return Flow::Next;
        }

        Flow FX21(Context& X, Fx const& f)
        {
            if (HasState(&X.b, X.tgt, f.p[3]) && X.tgt.hp > 0)
                Hit(X.b, X.ev, X.s, X.pet, f.p[0], f.p[1], X.slot, false);
            return Flow::Next;
        }

        Flow FX22(Context& X, Fx const& f)
        {
            X.healed = X.healed + 1;
            double const amount = f.p[0] > 0 ? Heal(f.p[0], X.pet.power) : 0;
            double heals = 0;
            for (Fx const& g : X.turn.fx)
                if (g.prop == 23)
                    ++heals;
            if (heals > 1)
            {
                double k = 0;
                std::vector<Pet>& team = X.b.Team(X.s);
                for (size_t i = 0; i < team.size(); ++i)
                    if (team[i].hp > 0)
                    {
                        k = k + 1;
                        if (k == X.healed)
                        {
                            if (amount > 0)
                                DoHeal(X.b, X.ev, X.s, static_cast<int32_t>(i + 1), amount, X.healed > 1);
                            break;
                        }
                    }
            }
            else if (amount > 0)
                DoHeal(X.b, X.ev, X.s, X.idx, amount);
            return Flow::Next;
        }

        Flow FX23(Context& X, Fx const& f)
        {
            if (f.p[3] != 0)
            {
                if (HasState(&X.b, X.tgt, f.p[3]))
                    DoHeal(X.b, X.ev, X.s, X.idx, Heal(f.p[0], X.pet.power));
            }
            else if (X.tgt.hp <= 0)
                DoHeal(X.b, X.ev, X.s, X.idx, Heal(f.p[0], X.pet.power));
            return Flow::Next;
        }

        Flow FX24(Context& X, Fx const& f)
        {
            if (!X.landed)
                ApplyAura(X.b, X.ev, X.s, X.idx, f.aura, std::max(1.0, f.p[2]), true, std::nullopt, &X.pet);
            return Flow::Next;
        }

        bool AuraIsSelf(Catalog const& catalog, uint16_t prop, uint32_t aura)
        {
            static States const empty;
            States const* found = catalog.StatesOf(aura);
            States const& states = found ? *found : empty;
            if (prop == 63 || prop == 26)
                return true;
            if (prop == 54 || prop == 172 || prop == 52 || prop == 178)
                return false;
            return Beneficial(states) && !Has(states, "Mechanic_IsBomb") && !(prop == 50 && AuraHostile(catalog, aura));
        }

        Flow FX25(Context& X, Fx const& f)
        {
            auto const& p = f.p;
            static States const empty;
            States const* found = Cat(X.b).StatesOf(f.aura);
            States const& states = found ? *found : empty;
            bool const selfAura = AuraIsSelf(Cat(X.b), f.prop, f.aura);
            double chance = p[1];
            double dur = p[2];
            std::optional<double> stacks = f.prop == 50 ? std::optional<double>(p[3]) : std::nullopt;
            if (f.prop == 172)
            {
                chance = (p[3] != 0 && HasState(&X.b, X.tgt, p[3])) ? 100 : p[5];
                dur = std::max(1.0, p[2]);
            }
            Side const target = selfAura ? X.s : X.o;
            bool const ok = target == X.s || Targetable(X);
            if (ok && ChanceRoll(X.b, chance))
            {
                std::optional<double> const trigger = AuraTrigger(Cat(X.b), f.aura);
                bool const skip = X.actedSecond || Has(states, "Mod_SpeedPercent") || (trigger && *trigger == 2) ||
                    (target == X.s && Get(states, "Mod_DamageDealtPercent") > 0);
                ApplyAura(X.b, X.ev, target, X.b.Active(target), f.aura, dur < 0 ? 99 : std::max(1.0, dur), skip,
                    stacks, &X.pet);
            }
            return Flow::Next;
        }

        Flow FX26(Context& X, Fx const&)
        {
            for (Pet const& q : X.b.Team(X.s))
                if (&q != &X.pet && q.hp <= 0 && !q.corpseUsed)
                    return Flow::Next;
            return Flow::Stop;
        }

        Flow FX27(Context& X, Fx const& f)
        {
            for (Pet& q : X.b.Team(X.s))
                if (&q != &X.pet && q.hp <= 0 && !q.corpseUsed)
                {
                    q.corpseUsed = true;
                    DoHeal(X.b, X.ev, X.s, X.idx, std::floor(X.pet.max * f.p[0] / 100));
                    break;
                }
            return Flow::Next;
        }

        Flow FX28(Context&, Fx const&)
        {
            return Flow::Next;
        }

        Flow FX29(Context& X, Fx const& f)
        {
            X.runK = X.runK.value_or(0) + 1;
            double k2 = 0;
            std::vector<Pet>& team = X.b.Team(X.s);
            for (size_t i = 0; i < team.size(); ++i)
            {
                Pet& q = team[i];
                if (&q != &X.pet && q.hp > 0)
                {
                    k2 = k2 + 1;
                    if (k2 == *X.runK)
                    {
                        if (q.family == "Critter")
                            ApplyAura(X.b, X.ev, X.s, static_cast<int32_t>(i + 1), f.aura, f.p[2] > 0 ? f.p[2] : 1,
                                false, std::nullopt, &X.pet);
                        break;
                    }
                }
            }
            return Flow::Next;
        }

        void PermanentBuff(Context& X, Fx const& f, States states, std::optional<double> hot,
            std::optional<std::string> fam)
        {
            Aura aura;
            aura.id = f.aura;
            aura.left = 99;
            aura.perm = true;
            aura.states = std::move(states);
            aura.pwr = X.pet.power;
            aura.src = &X.pet;
            aura.hot = hot;
            aura.fam = std::move(fam);
            X.pet.auras.push_back(aura);
            Event e = MakeEvent("buff");
            SetSide(e, "side", X.s);
            SetNumber(e, "idx", X.idx);
            SetText(e, "what", Lower(AuraName(Cat(X.b), f.aura)));
            SetNumber(e, "turns", 99);
            X.ev.push_back(e);
        }

        std::optional<size_t> LastAura(Pet const& pet, uint32_t id)
        {
            std::optional<size_t> found;
            for (size_t i = 0; i < pet.auras.size(); ++i)
                if (pet.auras[i].id == id)
                    found = i;
            return found;
        }

        Flow FX30(Context& X, Fx const& f)
        {
            if (std::optional<size_t> has = LastAura(X.pet, f.aura))
                X.pet.auras.erase(X.pet.auras.begin() + static_cast<std::ptrdiff_t>(*has));
            else
            {
                States const* st = Cat(X.b).StatesOf(f.aura);
                PermanentBuff(X, f, st ? *st : States { { "swapOutLock", 1 } }, f.p[0], std::nullopt);
            }
            return Flow::Next;
        }

        Flow FX31(Context& X, Fx const& f)
        {
            if (std::optional<size_t> has = LastAura(X.pet, f.aura))
            {
                X.pet.auras.erase(X.pet.auras.begin() + static_cast<std::ptrdiff_t>(*has));
                X.done = X.done + 1;
                X.landed = Hit(X.b, X.ev, X.s, X.pet, f.p[0], f.p[1], X.slot, false) || X.landed;
            }
            else
            {
                States const* st = Cat(X.b).StatesOf(f.aura);
                PermanentBuff(X, f, st ? *st : States { { "Mod_DamageDealtPercent", 10 } }, std::nullopt,
                    X.pet.useFam ? *X.pet.useFam : X.pet.family);
            }
            return Flow::Next;
        }

        Flow FX32(Context& X, Fx const& f)
        {
            double n = 0;
            for (Aura const& a : X.pet.auras)
                if (a.id == 831)
                    ++n;
            if (n < 8)
            {
                Aura aura;
                aura.id = 831;
                aura.left = 99;
                aura.perm = true;
                aura.states = { { "Mod_SpeedPercent", f.p[0] } };
                aura.pwr = X.pet.power;
                aura.src = &X.pet;
                X.pet.auras.push_back(aura);
                Event e = MakeEvent("buff");
                SetSide(e, "side", X.s);
                SetNumber(e, "idx", X.idx);
                SetText(e, "what", "speed boost");
                SetNumber(e, "turns", 99);
                X.ev.push_back(e);
            }
            return Flow::Next;
        }

        Flow FX33(Context& X, Fx const&)
        {
            X.b.meteor = Meteor { 15, X.s };
            return Flow::Next;
        }

        Flow FX34(Context& X, Fx const& f)
        {
            std::string const* wn = Cat(X.b).StateName(f.p[3]);
            States const* w = X.b.WeatherStates();
            if (wn && w && Has(*w, *wn) && X.tgt.hp > 0)
                Hit(X.b, X.ev, X.s, X.pet, f.p[0], f.p[1], X.slot, false);
            return Flow::Next;
        }

        Flow FX35(Context& X, Fx const& f)
        {
            std::optional<uint32_t> mainAura;
            for (Fx const& g : X.turn.fx)
                if (g.prop == 26 && g.aura != 0)
                    mainAura = g.aura;
            bool active = false;
            for (Aura const& a : X.pet.auras)
                if (mainAura && a.id == *mainAura)
                    active = true;
            if (active)
                ApplyAura(X.b, X.ev, X.s, X.idx, f.aura, std::max(1.0, f.p[2]), true, std::nullopt, &X.pet);
            return Flow::Next;
        }

        Flow FX36(Context& X, Fx const&)
        {
            for (std::vector<Pet>& team : X.b.pets)
                for (Pet& q : team)
                    q.auras.erase(std::remove_if(q.auras.begin(), q.auras.end(),
                        [](Aura const& a) { return Has(a.states, "Mechanic_IsObject"); }), q.auras.end());
            return Flow::Next;
        }

        Flow FX37(Context& X, Fx const& f)
        {
            RemoveAura(X.pet, f.aura);
            return Flow::Next;
        }

        Flow FX38(Context& X, Fx const&)
        {
            X.pet.auras.Replace();
            SyncMax(X.pet);
            return Flow::Next;
        }

        void SwapEvent(std::vector<Event>& ev, Side side, int32_t from, int32_t to, bool free,
            std::optional<bool> forced)
        {
            Event e = MakeEvent("swap");
            SetSide(e, "side", side);
            SetNumber(e, "from", from);
            SetNumber(e, "idx", to);
            SetFlag(e, "free", free);
            if (forced)
                SetFlag(e, "forced", *forced);
            ev.push_back(e);
        }

        Flow FX145(Context& X, Fx const& f)
        {
            bool enemy = false;
            for (Fx const& g : X.turn.fx)
            {
                if (&g == &f)
                    break;
                if (g.prop == 158)
                    enemy = true;
            }
            Side const side = enemy ? Other(X.s) : X.s;
            std::vector<int32_t> cand;
            std::vector<Pet>& team = X.b.Team(side);
            for (size_t i = 0; i < team.size(); ++i)
                if (team[i].hp > 0 && static_cast<int32_t>(i + 1) != X.b.Active(side))
                    cand.push_back(static_cast<int32_t>(i + 1));
            LuaSort(cand, [&team](int32_t x, int32_t y)
            {
                double const hx = team[static_cast<size_t>(x) - 1].hp;
                double const hy = team[static_cast<size_t>(y) - 1].hp;
                if (hx != hy)
                    return hx > hy;
                return x < y;
            });
            bool const ok = enemy ? (X.landed && X.tgt.hp > 0 && Mod(&X.b, X.tgt, "swapOutLock") == 0) :
                (X.pet.hp > 0 && Mod(&X.b, X.pet, "swapOutLock") == 0);
            if (ok && !cand.empty())
            {
                int32_t const from = X.b.Active(side);
                X.b.At(side, from).channel.reset();
                X.b.Active(side) = cand.front();
                SwapEvent(X.ev, side, from, X.b.Active(side), true, true);
                Detonate(X.b, X.ev, side);
            }
            return Flow::Next;
        }

        Flow FX39(Context& X, Fx const& f)
        {
            Side const o2 = Other(X.s);
            std::vector<int32_t> cand;
            std::vector<Pet>& team = X.b.Team(o2);
            for (size_t i = 0; i < team.size(); ++i)
                if (team[i].hp > 0 && static_cast<int32_t>(i + 1) != X.b.Active(o2))
                    cand.push_back(static_cast<int32_t>(i + 1));
            if (f.prop == 139 && !cand.empty())
            {
                LuaSort(cand, [&team](int32_t x, int32_t y)
                {
                    return team[static_cast<size_t>(x) - 1].hp < team[static_cast<size_t>(y) - 1].hp;
                });
                cand = { cand.front() };
            }
            if (X.landed && X.tgt.hp > 0 && !cand.empty() && Mod(&X.b, X.tgt, "swapOutLock") == 0)
            {
                int32_t const from = X.b.Active(o2);
                X.b.At(o2, from).channel.reset();
                int32_t const pick = f.prop == 139 ? 1 : X.b.rng->Roll(1, static_cast<int32_t>(cand.size()));
                X.b.Active(o2) = cand[static_cast<size_t>(pick) - 1];
                SwapEvent(X.ev, o2, from, X.b.Active(o2), true, true);
                Detonate(X.b, X.ev, o2);
            }
            return Flow::Next;
        }

        Flow FX40(Context& X, Fx const& f)
        {
            ++X.b.unknown[f.prop];
            return Flow::Next;
        }

        using Handler = Flow (*)(Context&, Fx const&);
        using Matcher = bool (*)(Context const&, Fx const&);

        struct Effect
        {
            Matcher match;
            Handler handle;
        };

        template<uint16_t... Props>
        bool PropIs(Context const&, Fx const& f)
        {
            return ((f.prop == Props) || ...);
        }

        std::array<Effect, 42> const Effects = { {
            { [](Context const& X, Fx const& f)
                { return IsDamage(f.prop) || (f.prop == 384 && X.actedFirst) || (f.prop == 385 && X.actedSecond); },
                FX00 },
            { PropIs<27>, FX01 }, { PropIs<59>, FX02 }, { PropIs<141>, FX03 }, { PropIs<32>, FX04 },
            { PropIs<131>, FX05 }, { PropIs<226>, FX06 }, { PropIs<66>, FX07 }, { PropIs<68>, FX08 },
            { PropIs<149>, FX09 }, { PropIs<80>, FX10 }, { PropIs<67>, FX11 }, { PropIs<77, 75>, FX12 },
            { PropIs<168>, FX13 }, { PropIs<53>, FX14 }, { PropIs<100>, FX15 }, { PropIs<150>, FX16 },
            { PropIs<44>, FX17 }, { PropIs<197>, FX18 }, { PropIs<138>, FX19 },
            { [](Context const&, Fx const& f) { return f.prop == 29 && f.p[2] > 0; }, FX20 },
            { PropIs<29>, FX21 }, { PropIs<23>, FX22 }, { PropIs<104>, FX23 },
            { [](Context const& X, Fx const& f) { return f.prop == 52 && X.missStun; }, FX24 },
            { [](Context const&, Fx const& f)
                { return f.prop == 26 || f.prop == 63 || ApplyProps.count(f.prop) || f.prop == 54 || f.prop == 172; },
                FX25 },
            { PropIs<144>, FX26 }, { PropIs<61>, FX27 }, { PropIs<22>, FX28 }, { PropIs<223>, FX29 },
            { PropIs<78>, FX30 }, { PropIs<76>, FX31 },
            { [](Context const& X, Fx const& f) { return f.prop == 79 && !X.ab.priority; }, FX32 },
            { PropIs<159>, FX33 }, { PropIs<170>, FX34 }, { PropIs<137>, FX35 },
            { [](Context const&, Fx const& f) { return f.prop == 85 && f.p[0] == 69; }, FX36 },
            { PropIs<49>, FX37 },
            { [](Context const&, Fx const& f) { return f.prop == 31 && f.p[0] == 141 && f.p[1] == 1; }, FX38 },
            { PropIs<107, 139>, FX39 }, { PropIs<145>, FX145 },
            { [](Context const&, Fx const& f)
                { return !(InertProps.count(f.prop) || IsDamage(f.prop) || f.prop == 384 || f.prop == 385); },
                FX40 },
        } };

        void RunEffects(Context& X, std::vector<Fx> const& list)
        {
            for (Fx const& f : list)
                for (Effect const& effect : Effects)
                    if (effect.match(X, f))
                    {
                        if (effect.handle(X, f) == Flow::Stop)
                            return;
                        break;
                    }
        }

        void Snap(Battle& b, std::vector<Event>& ev, size_t from)
        {
            Catalog const& catalog = Cat(b);
            std::string const tagP = TagText(catalog, b.Current(Side::P));
            std::string const tagE = TagText(catalog, b.Current(Side::E));
            std::string const statP = StatusString(catalog, b.Current(Side::P), &b.tips);
            std::string const statE = StatusString(catalog, b.Current(Side::E), &b.tips);
            for (size_t i = from; i < ev.size(); ++i)
            {
                ev[i].fields["tags.P"] = tagP;
                ev[i].fields["tags.E"] = tagE;
                ev[i].fields["stat.P"] = statP;
                ev[i].fields["stat.E"] = statE;
            }
        }

        void Act(Battle& b, std::vector<Event>& ev, Side s, std::optional<std::string> const& cmd,
            std::map<Pet const*, int32_t>& used)
        {
            int32_t const idx = b.Active(s);
            Side const o = Other(s);
            Pet& pet = b.At(s, idx);
            Pet& tgt = b.Current(o);
            if (pet.hp <= 0 || tgt.hp <= 0)
                return;
            Catalog const& catalog = Cat(b);
            if (Mod(&b, pet, "Mechanic_IsStunned") > 0)
            {
                Event e = MakeEvent("stunned");
                SetSide(e, "side", s);
                SetNumber(e, "idx", idx);
                if (std::optional<std::string> label = LockLabel(catalog, pet))
                    SetText(e, "label", *label);
                ev.push_back(e);
                return;
            }
            if (Mod(&b, pet, "turnLock") > 0)
            {
                Event e = MakeEvent("stunned");
                SetSide(e, "side", s);
                SetNumber(e, "idx", idx);
                SetFlag(e, "self", true);
                if (std::optional<std::string> label = LockLabel(catalog, pet))
                    SetText(e, "label", *label);
                ev.push_back(e);
                return;
            }
            int32_t slot = 1;
            double turnNo = 1;
            if (pet.channel)
            {
                slot = pet.channel->slot;
                turnNo = pet.channel->turn;
            }
            else
            {
                slot = CommandSlot(cmd ? *cmd : "A1");
                if (!Ready(pet, slot))
                    slot = 1;
                if (!Ready(pet, slot))
                {
                    Event e = MakeEvent("stunned");
                    SetSide(e, "side", s);
                    SetNumber(e, "idx", idx);
                    SetFlag(e, "self", true);
                    SetFlag(e, "pass", true);
                    ev.push_back(e);
                    return;
                }
                pet.cd[static_cast<size_t>(slot) - 1] = pet.Ability(slot)->cooldown;
                used[&pet] = slot;
                for (size_t i = pet.auras.size(); i >= 1; --i)
                {
                    if (i > pet.auras.size())
                        continue;
                    Aura const a = pet.auras[i - 1];
                    AbilityDef const* ab9 = (a.on && *a.on == 9) ? catalog.Ability(a.id) : nullptr;
                    if (!ab9)
                        continue;
                    for (Turn const& t9 : ab9->turns)
                        for (Fx const& f9 : t9.fx)
                            if (f9.prop == 129)
                            {
                                double& cd = pet.cd[static_cast<size_t>(slot) - 1];
                                cd = std::max(cd, f9.p[0]);
                                if (i <= pet.auras.size())
                                    pet.auras.erase(pet.auras.begin() + static_cast<std::ptrdiff_t>(i - 1));
                            }
                }
            }
            PetAbility const& ab = *pet.Ability(slot);
            if (ab.family >= 0)
                pet.useFam = FamilyAt(ab.family + 1);
            else
                pet.useFam.reset();
            Turn const& turn = ab.turns[static_cast<size_t>(turnNo) - 1];
            bool const actedFirst = !b.acted[static_cast<size_t>(o)];
            bool const actedSecond = !actedFirst;
            b.acted[static_cast<size_t>(s)] = true;
            if (static_cast<double>(ab.turns.size()) > turnNo)
                pet.channel = Channel { slot, turnNo + 1 };
            else
                pet.channel.reset();
            bool missStun = false;
            for (Fx const& f : turn.fx)
                if (f.prop == 194)
                    missStun = true;
            double hits = 0;
            for (Fx const& f : turn.fx)
                if (IsDamage(f.prop) || f.prop == 197 || f.prop == 66 || f.prop == 226 || f.prop == 68 ||
                    f.prop == 149 || (f.prop == 384 && actedFirst) || (f.prop == 385 && actedSecond))
                    ++hits;
            Event act = MakeEvent("act");
            SetSide(act, "side", s);
            SetNumber(act, "idx", idx);
            SetNumber(act, "slot", slot);
            SetNumber(act, "ab", ab.id);
            SetText(act, "name", ab.name);
            SetFlag(act, "dmg", hits > 0);
            if (ab.vis)
                SetNumber(act, "vis", *ab.vis);
            if (ab.ranged)
                SetFlag(act, "ranged", true);
            if (ab.vmode)
                SetText(act, "vm", *ab.vmode);
            if (ab.vpre)
                SetNumber(act, "vpre", *ab.vpre);
            if (ab.vhop)
                SetFlag(act, "vhop", true);
            if (ab.vdmg)
                SetFlag(act, "vdmg", true);
            ev.push_back(act);
            Context X { b, ev, s, idx, o, pet, tgt, ab, turn, turnNo, slot, actedFirst, actedSecond, missStun, hits,
                tgt.hp };
            RunEffects(X, turn.fx);
            for (Turn const& pt : ab.procs)
                for (Fx const& f : pt.fx)
                    if ((f.prop == 145 || f.prop == 107) && turnNo == 1)
                    {
                        Aura aura;
                        aura.id = 1124;
                        aura.left = 1;
                        aura.states = { { "untargettable", 1 } };
                        aura.pwr = pet.power;
                        aura.src = &pet;
                        pet.auras.push_back(aura);
                        pet.portalSwap = f.prop == 145 ? PortalSwap::Healthiest : PortalSwap::Random;
                    }
            if (X.landed)
                for (Turn const& pt : ab.procs)
                    if (pt.event == 2)
                        RunEffects(X, pt.fx);
            if (!X.weatherSeen)
                for (Fx const& f : turn.fx)
                    if (f.prop == 80)
                    {
                        b.weather = Weather { f.aura, std::max(1.0, f.p[2]) };
                        WeatherEvent(b, ev, f.aura);
                    }
            pet.useFam.reset();
        }

        bool ContainsText(std::string const& text, char const* needle)
        {
            return text.find(needle) != std::string::npos;
        }

        void Periodic(Battle& b, std::vector<Event>& ev, Side s)
        {
            int32_t const idx = b.Active(s);
            Pet& p = b.At(s, idx);
            if (p.hp <= 0)
                return;
            Catalog const& catalog = Cat(b);
            double dmg = 0;
            double stacks = 0;
            double heal = 0;
            auto table = p.auras.Share();
            for (size_t ai = 0; ai < table->size(); ++ai)
            {
                AbilityDef const* ab = catalog.Ability((*table)[ai].id);
                (*table)[ai].ticks = (*table)[ai].ticks + 1;
                Aura const a = (*table)[ai];
                if (a.hot)
                    heal = heal + Heal(*a.hot, a.pwr.value_or(p.power));
                std::vector<Turn> const& mt = MainTurns(ab);
                double const count = static_cast<double>(mt.size());
                Turn const* t = nullptr;
                if (ab && !mt.empty())
                {
                    double const pick = std::min(a.ticks, count);
                    if (pick >= 1)
                        t = &mt[static_cast<size_t>(pick) - 1];
                }
                if (ab && count > 1 && a.ticks >= count)
                    (*table)[ai].left = 0;
                if (!t || (a.ticks > count && count > 1))
                    continue;
                bool drains = false;
                for (Fx const& f : t->fx)
                    if (IsDamage(f.prop) || f.prop == 65)
                        drains = true;
                double auraDmg = 0;
                std::optional<double> leechPct;
                std::optional<double> teamK;
                for (Fx const& f : t->fx)
                {
                    if (IsDamage(f.prop) && a.src == &p)
                    {
                        size_t const before = ev.size();
                        p.useFam = a.fam;
                        Hit(b, ev, s, p, f.p[0], f.p[1], 1, false);
                        p.useFam.reset();
                        for (size_t k = before; k < ev.size(); ++k)
                            SetFlag(ev[k], "auraHit", true);
                    }
                    else if (f.prop == 32)
                        leechPct = f.p[0];
                    else if (IsDamage(f.prop) || f.prop == 65)
                    {
                        double pts = f.p[0];
                        double const acc = f.prop == 65 ? 100 : f.p[1];
                        bool const pctOfMax = f.prop == 62 && ab && (ContainsText(ab->text, "% of the target's health") ||
                            ContainsText(ab->text, "% health each round"));
                        if (f.prop == 65)
                        {
                            States const* w = b.WeatherStates();
                            std::string const* wn = catalog.StateName(f.p[3]);
                            if (w && wn && Has(*w, *wn))
                                pts = pts + f.p[2];
                        }
                        if (acc >= 100 || b.rng->Roll(1, 100) <= acc)
                        {
                            double d = Damage(pts, a.pwr.value_or(p.power), a.fam ? *a.fam : p.family, EffFam(p), 0,
                                Mod(&b, p, "Mod_DamageTakenPercent"));
                            if (pctOfMax)
                                d = std::max(1.0, std::floor(p.max * f.p[0] / 100));
                            bool const teamAura = ab && (ContainsText(ab->text, "your team") ||
                                ContainsText(ab->text, "enemy team"));
                            if (teamAura)
                            {
                                teamK = teamK.value_or(0) + 1;
                                double n = 0;
                                std::optional<int32_t> target;
                                std::vector<Pet>& team = b.Team(s);
                                for (size_t i2 = 0; i2 < team.size(); ++i2)
                                    if (team[i2].hp > 0)
                                    {
                                        n = n + 1;
                                        if (n == *teamK)
                                            target = static_cast<int32_t>(i2 + 1);
                                    }
                                if (target && *target != idx)
                                {
                                    Pet& q = b.At(s, *target);
                                    d = MagicCap(q, d);
                                    q.hp = std::max(0.0, q.hp - d);
                                    Side const os = Other(s);
                                    Event e = MakeEvent("dmg");
                                    SetSide(e, "side", os);
                                    SetNumber(e, "idx", b.Active(os));
                                    SetSide(e, "tside", s);
                                    SetNumber(e, "tidx", *target);
                                    SetNumber(e, "dmg", d);
                                    SetNumber(e, "hp", q.hp);
                                    SetNumber(e, "max", q.max);
                                    SetFlag(e, "bench", true);
                                    SetFlag(e, "more", true);
                                    ev.push_back(e);
                                    if (q.hp <= 0)
                                    {
                                        Faint(b, ev, s, *target);
                                        SetFlag(ev.back(), "bench", true);
                                    }
                                }
                                else if (target && *target == idx)
                                {
                                    dmg = dmg + d;
                                    auraDmg = auraDmg + d;
                                    stacks = stacks + 1;
                                }
                            }
                            else
                            {
                                dmg = dmg + d;
                                auraDmg = auraDmg + d;
                                stacks = stacks + 1;
                            }
                        }
                    }
                    else if (f.prop == 23)
                    {
                        if (drains && a.src && a.src != &p)
                        {
                            for (Side sd : { Side::P, Side::E })
                            {
                                std::vector<Pet>& team = b.Team(sd);
                                for (size_t i2 = 0; i2 < team.size(); ++i2)
                                    if (&team[i2] == a.src)
                                        DoHeal(b, ev, sd, static_cast<int32_t>(i2 + 1),
                                            Heal(f.p[0], a.pwr.value_or(team[i2].power)));
                            }
                        }
                        else
                            heal = heal + Heal(f.p[0], a.pwr.value_or(p.power));
                    }
                    else if (f.prop == 171)
                    {
                        States const* w = b.WeatherStates();
                        std::string const* sn = catalog.StateName(f.p[2]);
                        if (w && sn && Has(*w, *sn))
                            heal = heal + Heal(f.p[0], a.pwr.value_or(p.power));
                    }
                    else if (f.prop == 53)
                        heal = heal + std::floor(p.max * f.p[0] / 100);
                    else if ((f.prop == 54 || f.prop == 178 || f.prop == 52) && f.aura != 0)
                        ApplyAura(b, ev, s, idx, f.aura, std::max(1.0, f.p[2]), false, std::nullopt, a.src);
                }
                if (leechPct && auraDmg > 0 && a.src && a.src != &p)
                    for (Side sd : { Side::P, Side::E })
                    {
                        std::vector<Pet>& team = b.Team(sd);
                        for (size_t i2 = 0; i2 < team.size(); ++i2)
                            if (&team[i2] == a.src)
                                DoHeal(b, ev, sd, static_cast<int32_t>(i2 + 1),
                                    std::floor(std::min(auraDmg, p.hp) * *leechPct / 100));
                    }
            }
            if (dmg > 0)
            {
                dmg = MagicCap(p, dmg);
                if (Mod(&b, p, "unkillable") > 0 && p.hp - dmg < 1)
                    dmg = std::max(0.0, p.hp - 1);
                p.hp = std::max(0.0, p.hp - dmg);
                p.lastTaken = dmg;
                Event e = MakeEvent("dot");
                SetSide(e, "side", s);
                SetNumber(e, "idx", idx);
                SetNumber(e, "dmg", dmg);
                SetNumber(e, "stacks", stacks);
                SetNumber(e, "hp", p.hp);
                SetNumber(e, "max", p.max);
                ev.push_back(e);
                if (p.hp <= 0)
                {
                    Faint(b, ev, s, idx);
                    return;
                }
            }
            if (heal > 0)
                DoHeal(b, ev, s, idx, heal);
        }

        void EndOfRound(Battle& b, std::vector<Event>& ev, std::map<Pet const*, int32_t> const& used)
        {
            for (Side sd : { Side::P, Side::E })
            {
                std::optional<Bomb>& bm = b.bomb[static_cast<size_t>(sd)];
                if (bm)
                {
                    bm->left = bm->left - 1;
                    if (bm->left <= 0)
                        bm.reset();
                }
            }
            for (Side sd : { Side::P, Side::E })
            {
                Pet& cur = b.Current(sd);
                if (cur.portalSwap == PortalSwap::None)
                    continue;
                PortalSwap const mode = cur.portalSwap;
                cur.portalSwap = PortalSwap::None;
                Pet const* best = nullptr;
                std::optional<int32_t> bi;
                std::vector<int32_t> cand;
                std::vector<Pet>& team = b.Team(sd);
                for (size_t i2 = 0; i2 < team.size(); ++i2)
                {
                    int32_t const index = static_cast<int32_t>(i2 + 1);
                    Pet const& q = team[i2];
                    if (index != b.Active(sd) && q.hp > 0)
                    {
                        cand.push_back(index);
                        if (!best || q.hp > best->hp)
                        {
                            best = &q;
                            bi = index;
                        }
                    }
                }
                if (mode == PortalSwap::Random && !cand.empty())
                    bi = cand[static_cast<size_t>(b.rng->Roll(1, static_cast<int32_t>(cand.size()))) - 1];
                if (bi && cur.hp > 0)
                {
                    cur.auras.erase(std::remove_if(cur.auras.begin(), cur.auras.end(),
                        [](Aura const& a) { return a.id == 1124; }), cur.auras.end());
                    int32_t const from = b.Active(sd);
                    cur.channel.reset();
                    b.Active(sd) = *bi;
                    SwapEvent(ev, sd, from, *bi, true, true);
                    Detonate(b, ev, sd);
                }
            }
            if (b.meteor)
            {
                b.meteor->left = b.meteor->left - 1;
                if (b.meteor->left <= 0)
                {
                    b.meteor.reset();
                    for (Side sd : { Side::P, Side::E })
                    {
                        Pet& q = b.Current(sd);
                        bool const roach = q.name.find("Cockroach") != std::string::npos ||
                            q.name.find("Beetle") != std::string::npos;
                        if (q.hp > 0 && Mod(&b, q, "unkillable") == 0 && !roach)
                        {
                            q.hp = 0;
                            Faint(b, ev, sd, b.Active(sd), true);
                        }
                    }
                }
            }
            if (b.weather)
            {
                b.weather->left = b.weather->left - 1;
                if (b.weather->left <= 0)
                {
                    b.weather.reset();
                    Event e = MakeEvent("weather");
                    SetNumber(e, "id", 0);
                    SetNumber(e, "turns", 0);
                    SetText(e, "name", "");
                    ev.push_back(e);
                }
            }
            for (Side s : { Side::P, Side::E })
            {
                Periodic(b, ev, s);
                std::vector<Pet>& team = b.Team(s);
                for (size_t qi = 0; qi < team.size(); ++qi)
                {
                    Pet& q = team[qi];
                    int32_t const index = static_cast<int32_t>(qi + 1);
                    if (q.undeadLeft && q.hp > 0)
                    {
                        q.undeadLeft = *q.undeadLeft - 1;
                        if (*q.undeadLeft <= 0)
                        {
                            q.undeadLeft.reset();
                            q.hp = 0;
                            Faint(b, ev, s, index, true);
                            if (index != b.Active(s))
                                SetFlag(ev.back(), "bench", true);
                        }
                    }
                }
                Pet& p = b.Current(s);
                if (p.hp > 0)
                {
                    for (size_t i = p.auras.size(); i >= 1; --i)
                    {
                        Aura& a = p.auras[i - 1];
                        if (!(a.skip && *a.skip == b.round) && !a.perm)
                            a.left = a.left - 1;
                        if (a.left <= 0)
                            p.auras.erase(p.auras.begin() + static_cast<std::ptrdiff_t>(i - 1));
                    }
                    SyncMax(p);
                }
                for (Pet& q : team)
                    SyncMax(q);
                for (Pet& q : team)
                {
                    auto const found = used.find(&q);
                    for (int32_t sl = 1; sl <= 3; ++sl)
                    {
                        double& cd = q.cd[static_cast<size_t>(sl) - 1];
                        if (cd > 0 && !(found != used.end() && found->second == sl))
                            cd = cd - 1;
                    }
                }
            }
        }

        void Detonate(Battle& b, std::vector<Event>& ev, Side s)
        {
            std::optional<Bomb>& slot = b.bomb[static_cast<size_t>(s)];
            if (!slot)
                return;
            Bomb const bomb = *slot;
            slot.reset();
            Pet& q = b.Current(s);
            AbilityDef const* ab = Cat(b).Ability(bomb.id);
            if (q.hp <= 0 || !ab)
                return;
            std::optional<double> base;
            for (Turn const& t : ab->turns)
                for (Fx const& f : t.fx)
                    if (!base && f.prop == 24)
                        base = f.p[0];
            if (!base)
                return;
            std::optional<std::string> fam;
            if (ab->family >= 0)
                fam = FamilyAt(ab->family + 1);
            if (!fam && bomb.src)
                fam = bomb.src->family;
            double d = std::max(1.0, std::floor(LuaRound(*base * Bonus(bomb.pwr)) * (fam ? Matchup(*fam, q.family) : 1)));
            d = MagicCap(q, d);
            q.hp = std::max(0.0, q.hp - d);
            q.lastTaken = d;
            Side const o = Other(s);
            Event e = MakeEvent("dmg");
            SetSide(e, "side", o);
            SetNumber(e, "idx", b.Active(o));
            SetSide(e, "tside", s);
            SetNumber(e, "tidx", b.Active(s));
            SetNumber(e, "dmg", d);
            SetNumber(e, "hp", q.hp);
            SetNumber(e, "max", q.max);
            SetFlag(e, "reflect", true);
            ev.push_back(e);
            if (q.hp <= 0)
                Faint(b, ev, s, b.Active(s));
        }

        bool Priority(Pet const& pet, std::optional<std::string> const& cmd)
        {
            if (!cmd || cmd->empty() || (*cmd)[0] != 'A')
                return false;
            PetAbility const* ab = nullptr;
            if (pet.channel)
                ab = pet.Ability(pet.channel->slot);
            else
            {
                ab = pet.Ability(CommandSlot(*cmd));
            }
            return ab && ab->priority && !pet.channel;
        }

        void EndEvent(std::vector<Event>& ev, std::string const& result)
        {
            Event e = MakeEvent("end");
            SetText(e, "result", result);
            ev.push_back(e);
        }

        RoundResult RoundImpl(Battle& b, std::string const& commandP, std::string const& commandE)
        {
            RoundResult result;
            std::vector<Event>& ev = result.events;
            std::map<Pet const*, int32_t> used;
            std::optional<int32_t> swapTo;
            if (!commandP.empty() && commandP[0] == 'S')
            {
                swapTo = TeamIndex(b, Side::P, commandP);
                if (!swapTo)
                {
                    result.status = "invalid";
                    return result;
                }
            }
            b.round = b.round + 1;
            b.acted = { false, false };
            std::optional<std::string> cmdP = commandP;
            std::optional<std::string> const cmdE = commandE;
            bool const forcedSwap = b.Current(Side::P).hp <= 0;
            if (!commandP.empty() && commandP[0] == 'S')
            {
                int32_t const to = *swapTo;
                int32_t const from = b.Active(Side::P);
                b.At(Side::P, from).channel.reset();
                b.Active(Side::P) = to;
                SwapEvent(ev, Side::P, from, to, forcedSwap, std::nullopt);
                Detonate(b, ev, Side::P);
                if (b.Current(Side::P).hp <= 0)
                {
                    if (Alive(b, Side::P) == 0)
                    {
                        EndEvent(ev, "loss");
                        result.status = "loss";
                        return result;
                    }
                    result.status = "force";
                    return result;
                }
                if (forcedSwap)
                {
                    ev.push_back(MakeEvent("turn"));
                    result.status = "turn";
                    return result;
                }
                cmdP.reset();
            }
            std::optional<std::vector<Side>> order;
            if (cmdP && *cmdP == "T")
            {
                if (CanTrap(b))
                {
                    Pet& e = b.Current(Side::E);
                    Event trap = MakeEvent("trap");
                    SetSide(trap, "side", Side::E);
                    SetNumber(trap, "idx", b.Active(Side::E));
                    ev.push_back(trap);
                    e.hp = 0;
                    e.captured = true;
                    e.auras.Replace();
                    e.channel.reset();
                    b.captured.push_back(b.Active(Side::E));
                    cmdP.reset();
                    order = std::vector<Side> {};
                }
                else
                    cmdP = "A1";
            }
            Pet const& pe = b.Current(Side::P);
            Pet const& ee = b.Current(Side::E);
            if (order)
            {
            }
            else if (cmdP)
            {
                bool const pp = Priority(pe, cmdP);
                bool const ep = Priority(ee, cmdE);
                bool const playerFirst = (pp && !ep) || (pp == ep && Speed(&b, pe) >= Speed(&b, ee));
                order = playerFirst ? std::vector<Side> { Side::P, Side::E } : std::vector<Side> { Side::E, Side::P };
            }
            else
                order = std::vector<Side> { Side::E };
            for (Side s : *order)
            {
                size_t const from = ev.size();
                Act(b, ev, s, s == Side::P ? cmdP : cmdE, used);
                Snap(b, ev, from);
            }
            size_t const from = ev.size();
            EndOfRound(b, ev, used);
            Snap(b, ev, from);
            if (b.Current(Side::E).hp <= 0)
            {
                std::optional<int32_t> nx = NextAlive(b, Side::E);
                if (nx)
                {
                    b.Active(Side::E) = *nx;
                    Event spawn = MakeEvent("spawn");
                    SetSide(spawn, "side", Side::E);
                    SetNumber(spawn, "idx", *nx);
                    ev.push_back(spawn);
                    Detonate(b, ev, Side::E);
                    while (b.Current(Side::E).hp <= 0)
                    {
                        std::optional<int32_t> n2 = NextAlive(b, Side::E);
                        if (!n2)
                            break;
                        b.Active(Side::E) = *n2;
                        Event again = MakeEvent("spawn");
                        SetSide(again, "side", Side::E);
                        SetNumber(again, "idx", *n2);
                        ev.push_back(again);
                    }
                    if (b.Current(Side::E).hp <= 0)
                    {
                        EndEvent(ev, "win");
                        result.status = "win";
                        return result;
                    }
                }
                else
                {
                    EndEvent(ev, "win");
                    result.status = "win";
                    return result;
                }
            }
            if (b.Current(Side::P).hp <= 0)
            {
                if (Alive(b, Side::P) == 0)
                {
                    EndEvent(ev, "loss");
                    result.status = "loss";
                    return result;
                }
                result.status = "force";
                return result;
            }
            result.status = "turn";
            return result;
        }
    }

    void LuaSort(std::vector<int32_t>& a, std::function<bool(int32_t, int32_t)> const& less)
    {
        auto at = [&a](int32_t i) -> int32_t& { return a[static_cast<size_t>(i) - 1]; };
        std::function<void(int32_t, int32_t)> aux = [&](int32_t l, int32_t u)
        {
            while (l < u)
            {
                if (less(at(u), at(l)))
                    std::swap(at(l), at(u));
                if (u - l == 1)
                    break;
                int32_t i = (l + u) / 2;
                if (less(at(i), at(l)))
                    std::swap(at(i), at(l));
                else if (less(at(u), at(i)))
                    std::swap(at(i), at(u));
                if (u - l == 2)
                    break;
                int32_t const pivot = at(i);
                std::swap(at(i), at(u - 1));
                i = l;
                int32_t j = u - 1;
                for (;;)
                {
                    while (less(at(++i), pivot))
                    {
                    }
                    while (less(pivot, at(--j)))
                    {
                    }
                    if (j < i)
                        break;
                    std::swap(at(i), at(j));
                }
                std::swap(at(u - 1), at(i));
                if (i - l < u - i)
                {
                    j = l;
                    i = i - 1;
                    l = i + 2;
                }
                else
                {
                    j = i + 1;
                    i = u;
                    u = j - 2;
                }
                aux(j, i);
            }
        };
        aux(1, static_cast<int32_t>(a.size()));
    }

    RoundResult Round(Battle& battle, std::string const& commandP, std::string const& commandE)
    {
        battle.resolving = true;
        RoundResult result = RoundImpl(battle, commandP, commandE);
        battle.resolving = false;
        return result;
    }

    std::string AI(Battle& battle, Side side)
    {
        Pet const& pet = battle.Current(side);
        if (pet.channel)
            return "A" + std::to_string(pet.channel->slot);
        bool hurt = false;
        for (Pet const& q : battle.Team(side))
            if (q.hp > 0 && q.hp < q.max)
                hurt = true;
        std::vector<int32_t> ready;
        for (int32_t sl = 1; sl <= 3; ++sl)
        {
            if (!Ready(pet, sl))
                continue;
            Turn const& turn = pet.Ability(sl)->turns.front();
            bool healOnly = true;
            bool buffActive = false;
            for (Fx const& f : turn.fx)
            {
                if (IsDamage(f.prop) || f.prop == 384 || f.prop == 385 || f.prop == 29 || f.prop == 197 ||
                    f.prop == 66 || f.prop == 226 || f.prop == 68 || f.prop == 149 || f.prop == 44 || f.prop == 141 ||
                    f.prop == 27 || f.prop == 59 || f.prop == 131 || ApplyProps.count(f.prop) || f.prop == 54 ||
                    f.prop == 172)
                    healOnly = false;
                if ((f.prop == 26 || f.prop == 63) && f.aura != 0)
                    for (Aura const& a : pet.auras)
                        if (a.id == f.aura)
                            buffActive = true;
            }
            bool const useless = (healOnly && !hurt && !turn.fx.empty() && turn.fx.front().prop != 49) || buffActive;
            if (!useless)
                ready.push_back(sl);
        }
        if (ready.empty())
            return "A1";
        return "A" + std::to_string(ready[static_cast<size_t>(battle.rng->Roll(1, static_cast<int32_t>(ready.size()))) - 1]);
    }

    bool CanTrap(Battle const& battle)
    {
        Pet const& e = battle.Current(Side::E);
        return e.hp > 0 && e.hp <= e.max * battle.catalog->Config().captureHealth && !e.noTrap;
    }

    void Finish(Battle& battle)
    {
        for (std::vector<Pet>& team : battle.pets)
            for (Pet& q : team)
            {
                q.auras.Replace();
                q.channel.reset();
                q.undeadLeft.reset();
                SyncMax(q);
            }
    }

    std::map<uint16_t, int32_t> const& UnknownEffects(Battle const& battle)
    {
        return battle.unknown;
    }
}
