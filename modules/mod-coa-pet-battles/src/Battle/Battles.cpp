#include "Battles.h"
#include "Engine/LuaNumber.h"
#include "Engine/PetFactory.h"
#include "Engine/Round.h"
#include "Protocol/JournalMessages.h"
#include "Protocol/WireText.h"
#include <algorithm>
#include <cmath>

namespace CoAPetBattles::Battle
{
    namespace
    {
        constexpr uint32_t IdleTimeoutSeconds = 300;
        constexpr uint32_t PreviewBase = 9100000;
        constexpr uint32_t SpawnEffect = 52096;
        constexpr uint32_t PoofEffect = 12244;
        constexpr uint32_t LevelUpEffect = 47292;
        constexpr uint32_t UtilityGlow = 60957;
        constexpr uint32_t CrateObject = 193761;
        constexpr uint32_t Wound = 33;
        constexpr uint32_t Death = 34;
        constexpr uint32_t Hop = 4;
        constexpr uint64_t AuraMs = 2400;
        constexpr size_t MaxEnemies = 3;

        std::string TypeIcon(std::string const& family, std::string const& fallback)
        {
            static std::map<std::string, std::string> const icons = {
                { "Humanoid", "INV_Misc_Head_Human_01" }, { "Dragonkin", "INV_Misc_Head_Dragon_01" },
                { "Flying", "Ability_Druid_FlightForm" }, { "Undead", "Spell_Shadow_AnimateDead" },
                { "Critter", "INV_Egg_01" }, { "Magic", "Spell_Arcane_Arcane01" },
                { "Elemental", "Spell_Nature_EarthElemental_Totem" }, { "Mechanical", "INV_Gizmo_01" },
                { "Aquatic", "Ability_Druid_AquaticForm" }, { "Beast", "Ability_Racial_BearForm" } };
            auto const found = icons.find(family);
            return found == icons.end() ? fallback : found->second;
        }

        std::string N(double value)
        {
            return Engine::LuaNumber(value);
        }

        bool Digits(std::string const& text)
        {
            return !text.empty() && std::all_of(text.begin(), text.end(), [](char c) { return c >= '0' && c <= '9'; });
        }

        std::vector<std::string> Split(std::string const& text, char separator)
        {
            std::vector<std::string> parts;
            size_t start = 0;
            while (true)
            {
                size_t const at = text.find(separator, start);
                parts.push_back(text.substr(start, at == std::string::npos ? std::string::npos : at - start));
                if (at == std::string::npos)
                    return parts;
                start = at + 1;
            }
        }
    }

    class Session : public std::enable_shared_from_this<Session>
    {
    public:
        Session(Battles& battles, uint64_t character, std::vector<Engine::Pet> mine, std::vector<Engine::Pet> theirs,
            double enemyLevel)
            : _battles(battles), _world(battles.GetWorld()), _catalogHold(battles.GetCatalog()),
              _catalog(*_catalogHold),
              _character(character), _eng(*_catalogHold, std::move(mine), std::move(theirs), battles.GetRng()),
              _enemyLevel(enemyLevel)
        {
        }

        Engine::Battle& Eng() { return _eng; }
        bool Over() const { return _over; }
        bool Waiting() const { return _waiting; }
        uint32_t LastAct() const { return _lastAct; }

        void Send(std::string_view action, std::string const& payload)
        {
            if (_world.Online(_character))
                _world.Send(_character, "pbt", action, payload);
        }

        void Direct(std::string_view module, std::string_view action, std::string const& payload)
        {
            if (_world.Online(_character))
                _world.Send(_character, module, action, payload);
        }

        bool Present(Side side) const
        {
            return _handles[Index(side)] != 0 && _world.Online(_character);
        }

        bool HoldsStandIns() const
        {
            return _handles[0] != 0 || _handles[1] != 0;
        }

        void Show(CueKind kind, Side side, uint32_t value = 0, Side target = Side::P, bool ranged = false,
            bool heal = false)
        {
            if (!Present(side))
                return;
            Cue cue;
            cue.kind = kind;
            cue.side = side;
            cue.target = target;
            cue.value = value;
            cue.ranged = ranged;
            cue.heal = heal;
            cue.character = _character;
            if (kind == CueKind::Health)
                _health[Index(side)] = value;
            uint64_t const other = kind == CueKind::Cast ? _handles[Index(target)] : 0;
            _world.Show(_handles[Index(side)], other, cue);
        }

        void FaceAll()
        {
            for (Side side : { Side::P, Side::E })
                Show(CueKind::Face, side);
        }

        void Back(Side side)
        {
            if (!_lunged[Index(side)])
                return;
            _lunged[Index(side)] = false;
            bool const hop = _hop[Index(side)];
            _hop[Index(side)] = false;
            Show(hop ? CueKind::Jump : CueKind::Back, side);
            std::shared_ptr<Session> self = shared_from_this();
            _battles.GetScheduler().After(hop ? 900 : 450, [self, side] { self->Show(CueKind::Face, side); });
        }

        void ShowCrateGone()
        {
            if (!_world.Online(_character))
                return;
            Cue cue;
            cue.kind = CueKind::Uncrate;
            cue.side = Side::E;
            cue.value = CrateObject;
            cue.character = _character;
            _world.Show(_handles[Index(Side::E)], 0, cue);
        }

        void SpawnPet(Side side, int32_t index)
        {
            if (_over)
                return;
            Engine::Pet& pet = _eng.At(side, index);
            std::optional<Spawned> const spawned = _world.Spawn(_character, side, pet.species, pet.display);
            if (!spawned)
                return;
            if (_handles[Index(side)])
                _world.Despawn(_handles[Index(side)]);
            _handles[Index(side)] = spawned->handle;
            _spawnOrder[Index(side)] = ++_spawns;
            std::optional<uint32_t> const worn = spawned->display;
            uint32_t display = pet.display;
            if (!display && *worn)
            {
                pet.display = *worn;
                display = *worn;
                if (side == Side::P)
                    if (Store::Journal* journal = _world.JournalOf(_character))
                    {
                        if (journal->SetDisplayOnce(pet.ownedPetId, *worn))
                            _world.Prime(_character, pet.species, pet.species, *worn);
                        _world.Flush(*journal);
                    }
            }
            else if (!display)
                display = *worn;
            _world.Scale(spawned->handle, _battles.GetScale().ScaleOf(pet.species, display));
            Show(CueKind::Health, side, 1000);
            Show(CueKind::Effect, side, SpawnEffect);
        }

        void Despawn(Side side, bool effect = false)
        {
            if (effect)
                Show(CueKind::Effect, side, PoofEffect);
            if (_handles[Index(side)])
                _world.Despawn(_handles[Index(side)]);
            _handles[Index(side)] = 0;
        }

        void DespawnInOrder()
        {
            std::vector<Side> sides = { Side::P, Side::E };
            std::sort(sides.begin(), sides.end(), [this](Side a, Side b)
            {
                return _spawnOrder[Index(a)] < _spawnOrder[Index(b)];
            });
            for (Side side : sides)
                Despawn(side);
        }

        void SendAbilities()
        {
            Engine::Pet const& pet = _eng.Current(Side::P);
            for (int32_t slot = 1; slot <= 3; ++slot)
            {
                Engine::PetAbility const* ability = pet.Ability(slot);
                if (!ability)
                    break;
                std::string const name = Protocol::Cap(ability->name, 30);
                std::string const cooldown = N(ability->cooldown);
                int64_t const room = std::min<int64_t>(170, 240 - static_cast<int64_t>(
                    ("pbt|abil|" + std::to_string(slot) + "|").size() + ability->icon.size() + name.size() +
                    cooldown.size() + 4));
                Send("abil", std::to_string(slot) + "|" + ability->icon + "#" + name + "#" +
                    Protocol::Cap(ability->tip, room) + "#" + cooldown);
            }
        }

        void SendInfo()
        {
            for (Side side : { Side::P, Side::E })
            {
                Engine::FamilyMatchups const info = Engine::FamilyInfo(_eng.Current(side).family);
                Send("info", Engine::SideName(side) + "|" + info.name + "|" + info.strong + "|" + info.weak + "|" +
                    info.hurtBy + "|" + info.resists);
            }
            Engine::Pet const& enemy = _eng.Current(Side::E);
            for (int32_t slot = 1; slot <= 3; ++slot)
                if (Engine::PetAbility const* ability = enemy.Ability(slot))
                    Send("eabil", std::to_string(slot) + "|" + ability->icon + "#" + Protocol::Cap(ability->name, 30) +
                        "#" + Protocol::Cap(ability->tip, 150) + "#" + N(ability->cooldown) + "#" +
                        N(enemy.cd[static_cast<size_t>(slot) - 1]));
        }

        void SendPet(Side side, int32_t index)
        {
            Engine::Pet const& pet = _eng.At(side, index);
            uint32_t const entry = pet.display ? PreviewBase + pet.display : pet.species;
            double const scale = _battles.GetScale().ScaleOf(pet.species, pet.display);
            if (pet.display && _world.Online(_character))
                _world.Prime(_character, entry, pet.species, pet.display);
            Send("st", Engine::SideName(side) + "," + std::to_string(index) + "," + Protocol::Integer(pet.level) + "," +
                Protocol::Integer(pet.hp) + "," + Protocol::Integer(pet.max) + "," + TypeIcon(pet.family, pet.icon) +
                "," + Protocol::Integer(pet.quality) + "," + std::to_string(entry) + "," +
                Protocol::Integer(std::floor(scale * 100 + 0.5)) + "," + pet.name);
        }

        void SendTags(Side side, std::optional<std::string> const& stat)
        {
            std::string const text = stat ? *stat : Engine::StatusString(_catalog, _eng.Current(side), &_eng.tips);
            std::vector<std::string> const parts = Protocol::SplitStatusList(text);
            for (size_t i = 0; i < parts.size(); ++i)
                Send(i == 0 ? "tag" : "tag2", Engine::SideName(side) + "|" + parts[i]);
            for (std::string const& item : Split(text, ';'))
            {
                std::vector<std::string> const fields = Split(item, '~');
                if (fields.size() < 5 || fields[0].empty() || fields[1].empty() || !Digits(fields[2]) ||
                    !Digits(fields[3]) || fields[4].empty() || fields[4][0] < '0' || fields[4][0] > '9')
                    continue;
                auto const tip = _eng.tips.find(fields[0]);
                if (tip == _eng.tips.end() || tip->second.empty() || _tipSent[fields[0]] == tip->second)
                    continue;
                _tipSent[fields[0]] = tip->second;
                Send("stip", Protocol::Cap(fields[0], 30) + "#" + Protocol::Cap(tip->second, 190));
            }
        }

        void SendTags(Side side, Engine::Event const& event)
        {
            std::string const key = side == Side::P ? "stat.P" : "stat.E";
            SendTags(side, event.Has(key) ? std::optional<std::string>(event.Text(key)) : std::nullopt);
        }

        void SendTurn(bool force)
        {
            FaceAll();
            {
                std::shared_ptr<Session> self = shared_from_this();
                _battles.GetScheduler().After(500, [self]
                {
                    if (!self->_over)
                        self->FaceAll();
                });
            }
            Engine::Pet const& pet = _eng.Current(Side::P);
            _waiting = true;
            _lastAct = _world.UnixNow();
            SendInfo();
            if (!force && pet.hp > 0 && (pet.channel || Engine::CantAct(nullptr, pet)))
            {
                if (pet.channel && !Engine::CantAct(nullptr, pet))
                {
                    Engine::PetAbility const* ability = pet.Ability(pet.channel->slot);
                    std::string const text = (ability ? ability->name : std::string()) + ": round " +
                        N(pet.channel->turn) + " of " + std::to_string(ability ? ability->turns.size() : 0);
                    Send("turn", "lock;0,0,0;0;" + Protocol::Cap(text, 40));
                }
                else
                {
                    std::optional<std::string> const label = Engine::LockLabel(_catalog, pet);
                    Send("turn", "stun;0,0,0;0;" + (label ? *label : std::string("Stunned")));
                }
                _waiting = false;
                std::shared_ptr<Session> self = shared_from_this();
                _battles.GetScheduler().After(1500, [self]
                {
                    if (self->_over || self->_waiting)
                        return;
                    self->_lastAct = self->_world.UnixNow();
                    std::string const enemy = Engine::AI(self->_eng, Side::E);
                    self->PlayRound(Engine::Round(self->_eng, "A1", enemy));
                });
                return;
            }
            bool const trap = !force && Engine::CanTrap(_eng);
            _turn = std::string(force ? "force" : "go") + ";" + N(pet.cd[0]) + "," + N(pet.cd[1]) + "," +
                N(pet.cd[2]) + ";" + (trap ? "1" : "0");
            Send("turn", _turn);
        }

        void PlayRound(Engine::RoundResult result)
        {
            auto events = std::make_shared<std::vector<Engine::Event>>(std::move(result.events));
            Play(events, 0, result.status);
        }

        void Next(std::shared_ptr<std::vector<Engine::Event>> const& events, size_t index, std::string const& status,
            uint64_t ms)
        {
            std::shared_ptr<Session> self = shared_from_this();
            _battles.GetScheduler().After(ms, [self, events, index, status] { self->Play(events, index, status); });
        }

        uint64_t Support(Engine::Event const& event, std::string const& mode)
        {
            Side const side = SideOf(event, "side");
            Side const other = Engine::Other(side);
            uint32_t const spell = static_cast<uint32_t>(event.Number("vis"));
            if (mode == "aura")
            {
                Show(CueKind::Aura, side, spell);
                uint64_t const handle = _handles[Index(side)];
                std::shared_ptr<Session> self = shared_from_this();
                _battles.GetScheduler().After(AuraMs, [self, side, spell, handle]
                {
                    if (self->_handles[Index(side)] == handle)
                        self->Show(CueKind::Unaura, side, spell);
                });
                return 1500;
            }
            if (mode == "target")
            {
                if (!Present(other))
                    return 600;
                Show(CueKind::Cast, side, spell, other, true);
                Show(CueKind::Health, other, _health[Index(other)]);
                return 1300;
            }
            Show(CueKind::Cast, side, spell, side, false, true);
            return 1500;
        }

        static Side SideOf(Engine::Event const& event, std::string const& key)
        {
            return event.Text(key) == "E" ? Side::E : Side::P;
        }

        std::string HealthLine(Engine::Event const& event, std::string const& sideKey, std::string const& indexKey)
        {
            return event.Text(sideKey) + "," + N(event.Number(indexKey)) + "," + N(event.Number("hp")) + "," +
                N(event.Number("max"));
        }

        void Capture(int32_t index)
        {
            Engine::Pet const& pet = _eng.At(Side::E, index);
            Store::Journal* journal = _world.JournalOf(_character);
            if (!journal)
                return;
            uint8_t const level = static_cast<uint8_t>(std::min<double>(pet.level, _catalog.Config().maxLevel));
            uint8_t const quality = static_cast<uint8_t>(pet.quality);
            std::array<uint8_t, 3> picks {};
            for (uint8_t& pick : picks)
                pick = static_cast<uint8_t>(_battles.GetRng().Roll(1, 2));
            Store::OwnedPet const* stored = journal->Capture(pet.species, level, picks, quality, pet.display, pet.breed);
            if (!stored)
            {
                Direct("pbt", "msg", "Your journal could not record the captured pet.");
                return;
            }
            if (pet.display && (_battles.UsesOwnedIds(_character) || journal->PetIdForSpecies(pet.species) == stored->id))
                _world.Prime(_character, pet.species, pet.species, pet.display);
            _world.Flush(*journal);
            _battles.SendJournalPet(_character, *journal, *stored, _world.UnixNow());
            Direct("pbt", "msg", "You captured " + pet.name + "!");
            Direct("pbt", "got", std::to_string(quality) + "," + pet.name);
        }

        void Play(std::shared_ptr<std::vector<Engine::Event>> const& events, size_t index, std::string const& status)
        {
            if (_over)
                return;
            if (!_world.Online(_character) || !_world.Alive(_character) || _world.Away(_character))
            {
                Send("msg", "The battle ended due to interruption.");
                End("interrupted", false);
                return;
            }
            if (index >= events->size())
            {
                SendTags(Side::P, std::nullopt);
                SendTags(Side::E, std::nullopt);
                if (status == "force")
                    SendTurn(true);
                else if (status == "turn")
                    SendTurn(false);
                return;
            }
            Engine::Event const& e = (*events)[index];
            auto next = [&](uint64_t ms) { Next(events, index + 1, status, ms); };
            std::string const& kind = e.kind;
            if (kind == "act")
            {
                Side const side = SideOf(e, "side");
                Send("act", e.Text("side") + "," + N(e.Number("idx")) + "," + e.Text("name"));
                if (side == Side::P)
                    _acted[static_cast<size_t>(e.Number("idx"))] = true;
                std::string const mode = e.Has("vm") ? e.Text("vm") : (e.Flag("ranged") ? "ranged" : "melee");
                bool const hitMode = mode == "melee" || mode == "ranged";
                _vis = hitMode && e.Has("vis") ? std::optional<double>(e.Number("vis")) : std::nullopt;
                _ranged = mode == "ranged";
                _hop[Index(side)] = e.Flag("vhop");
                bool const support = e.Has("vis") && (mode == "self" || mode == "target" || mode == "aura");
                bool const attack = e.Flag("dmg") || _vis.has_value();
                if (e.Has("vpre"))
                    Show(CueKind::Cast, side, static_cast<uint32_t>(e.Number("vpre")), side, false, true);
                if (support && Present(side))
                    next(Support(e, mode) + (e.Flag("dmg") ? 300 : 0));
                else if (attack && _vis && _ranged)
                    next(500);
                else if (attack)
                {
                    if (Present(Engine::Other(side)))
                        Show(CueKind::Lunge, side);
                    _lunged[Index(side)] = true;
                    uint32_t const swing = Engine::FamilyInfo(_eng.At(side,
                        static_cast<int32_t>(e.Number("idx"))).family).name == "Humanoid" ? 26 : 35;
                    std::shared_ptr<Session> self = shared_from_this();
                    _battles.GetScheduler().After(650, [self, side, swing]
                    {
                        self->Show(CueKind::Emote, side, swing);
                    });
                    next(1000);
                }
                else
                {
                    Show(CueKind::Effect, side, UtilityGlow);
                    next(900);
                }
            }
            else if (kind == "trap")
            {
                int32_t const enemy = static_cast<int32_t>(e.Number("idx"));
                Send("msg", _eng.At(Side::E, enemy).name + " is being captured...");
                bool const crate = Present(Side::E);
                if (crate)
                    Show(CueKind::Crate, Side::E, CrateObject);
                std::shared_ptr<Session> self = shared_from_this();
                _battles.GetScheduler().After(2200, [self, enemy, crate]
                {
                    if (crate)
                        self->ShowCrateGone();
                    self->Despawn(Side::E, true);
                    if (self->_world.Online(self->_character))
                        self->Capture(enemy);
                    self->Send("fnt", "E," + std::to_string(enemy));
                });
                next(2800);
            }
            else if (kind == "dmg" && (e.Flag("recoil") || e.Flag("reflect")))
            {
                Show(CueKind::Emote, SideOf(e, "tside"), Wound);
                Send("hp", HealthLine(e, "tside", "tidx") + ",-" + N(e.Number("dmg")));
                next(700);
            }
            else if (kind == "dmg" && e.Flag("bench"))
            {
                Send("hp", HealthLine(e, "tside", "tidx") + ",-" + N(e.Number("dmg")));
                next(250);
            }
            else if (kind == "faint" && e.Flag("bench"))
            {
                Send("fnt", e.Text("side") + "," + N(e.Number("idx")));
                next(500);
            }
            else if (kind == "dmg")
            {
                Side const side = SideOf(e, "side");
                Side const target = SideOf(e, "tside");
                Show(CueKind::Emote, target, Wound);
                if (_vis && Present(target) && Present(side))
                {
                    Show(CueKind::Cast, side, static_cast<uint32_t>(*_vis), target, _ranged);
                    double const ratio = e.Number("hp") / std::max(1.0, e.Number("max")) * 1000 + 0.5;
                    Show(CueKind::Health, target, static_cast<uint32_t>(std::floor(ratio)));
                }
                Send("hp", HealthLine(e, "tside", "tidx") + ",-" + N(e.Number("dmg")) + (e.Flag("crit") ? "!" : ""));
                if (!e.Flag("more"))
                {
                    std::shared_ptr<Session> self = shared_from_this();
                    _battles.GetScheduler().After(600, [self, side] { self->Back(side); });
                }
                next(e.Flag("more") ? (_vis ? 1000 : 650) : 1000);
            }
            else if (kind == "dodge")
            {
                if (!e.Has("text") || e.Text("text") != "Burrowed!")
                    Show(CueKind::Emote, SideOf(e, "side"), Hop);
                Send("hp", HealthLine(e, "side", "idx") + "," + (e.Has("text") ? e.Text("text") : std::string("Dodge!")));
                if (!e.Flag("more"))
                {
                    Side const from = SideOf(e, "from");
                    std::shared_ptr<Session> self = shared_from_this();
                    _battles.GetScheduler().After(500, [self, from] { self->Back(from); });
                }
                next(e.Flag("more") ? 650 : 1000);
            }
            else if (kind == "buff" || kind == "debuff")
            {
                SendTags(Side::P, e);
                SendTags(Side::E, e);
                next(700);
            }
            else if (kind == "heal")
            {
                Send("hp", HealthLine(e, "side", "idx") + ",+" + N(e.Number("amt")));
                next(e.Flag("quick") ? 450 : 1000);
            }
            else if (kind == "stunned")
            {
                Send("msg", _eng.At(SideOf(e, "side"), static_cast<int32_t>(e.Number("idx"))).name + Engine::LockText(e));
                SendTags(Side::P, e);
                SendTags(Side::E, e);
                next(1300);
            }
            else if (kind == "dot")
            {
                Show(CueKind::Emote, SideOf(e, "side"), Wound);
                Send("hp", HealthLine(e, "side", "idx") + ",-" + N(e.Number("dmg")));
                SendTags(Side::P, e);
                SendTags(Side::E, e);
                next(1000);
            }
            else if (kind == "faint")
            {
                Side const side = SideOf(e, "side");
                std::string const payload = e.Text("side") + "," + N(e.Number("idx"));
                Show(CueKind::Emote, side, Death);
                Back(Engine::Other(side));
                std::shared_ptr<Session> self = shared_from_this();
                _battles.GetScheduler().After(1000, [self, side, payload]
                {
                    self->Despawn(side, true);
                    self->Send("fnt", payload);
                });
                next(1700);
            }
            else if (kind == "swap")
            {
                Side const side = e.Has("side") ? SideOf(e, "side") : Side::P;
                int32_t const index = static_cast<int32_t>(e.Number("idx"));
                std::string const& name = _eng.At(side, index).name;
                Send("msg", (side == Side::P && !e.Flag("forced")) ? "Go, " + name + "!" : name + " is forced into battle!");
                Despawn(side, true);
                std::shared_ptr<Session> self = shared_from_this();
                _battles.GetScheduler().After(700, [self, side, index]
                {
                    self->SpawnPet(side, index);
                    self->Send("in", Engine::SideName(side) + "," + std::to_string(index));
                    if (side == Side::P)
                        self->SendAbilities();
                    self->SendTags(side, std::nullopt);
                });
                next(1600);
            }
            else if (kind == "weather")
            {
                Send("weather", N(e.Number("id")) + "|" + N(e.Number("turns")) + "|" + e.Text("name"));
                next(e.Number("id") != 0 ? 500 : 100);
            }
            else if (kind == "spawn")
            {
                Side const side = SideOf(e, "side");
                int32_t const index = static_cast<int32_t>(e.Number("idx"));
                SpawnPet(side, index);
                Send("in", e.Text("side") + "," + std::to_string(index));
                SendTags(side, std::nullopt);
                next(1400);
            }
            else if (kind == "end")
                End(e.Text("result"), false);
            else
                next(0);
        }

        void End(std::string const& result, bool forfeit)
        {
            if (_over)
                return;
            _over = true;
            _world.Suppress(_character, false);
            Engine::Finish(_eng);
            Store::Journal* journal = _world.JournalOf(_character);
            if (journal)
            {
                uint32_t const now = _world.UnixNow();
                for (Engine::Pet const& pet : _eng.Team(Side::P))
                    journal->SetHealth(pet.ownedPetId, static_cast<uint32_t>((!forfeit && pet.hp > 0) ? pet.hp : 1), now);
                _world.Flush(*journal);
                for (Engine::Pet const& pet : _eng.Team(Side::P))
                    if (Store::OwnedPet const* stored = journal->Pet(pet.ownedPetId))
                        _battles.SendJournalPet(_character, *journal, *stored, now);
            }
            Send("end", result);
            _battles.Unregister(_character, this);
            bool const win = result == "win";
            std::shared_ptr<Session> self = shared_from_this();
            _battles.GetScheduler().After(win ? 600 : 1200, [self, win]
            {
                if (!win)
                    self->Despawn(Side::P, true);
                self->Despawn(Side::E, true);
                bool leveled = false;
                if (win && self->_world.Online(self->_character) && self->_eng.captured.empty())
                    leveled = self->GrantExperience();
                if (leveled)
                    self->Show(CueKind::Effect, Side::P, LevelUpEffect);
                self->Direct("pbt", "done", "");
                if (win)
                    self->_battles.GetScheduler().After(leveled ? 2600 : 500, [self]
                    {
                        self->Despawn(Side::P, true);
                    });
            });
        }

        bool GrantExperience()
        {
            Store::Journal* journal = _world.JournalOf(_character);
            if (!journal)
                return false;
            bool leveled = false;
            uint32_t const now = _world.UnixNow();
            uint8_t const maxLevel = _catalog.Config().maxLevel;
            std::vector<Engine::Pet> const& team = _eng.Team(Side::P);
            for (size_t i = 0; i < team.size(); ++i)
            {
                if (!_acted[i + 1])
                    continue;
                Store::OwnedPet const* before = journal->Pet(team[i].ownedPetId);
                bool const below = before && before->level < maxLevel;
                std::optional<Store::XpGain> const gain =
                    journal->GrantXp(team[i].ownedPetId, static_cast<uint8_t>(_enemyLevel), now);
                if (!gain)
                    continue;
                if (below)
                {
                    _world.Flush(*journal);
                    _battles.SendJournalPet(_character, *journal, *journal->Pet(team[i].ownedPetId), now);
                }
                Direct("pbt", "xp", team[i].name + "," + std::to_string(gain->gained) + "," +
                    std::to_string(gain->level) + "," + std::to_string(gain->levelsGained));
                if (gain->levelsGained > 0)
                    leveled = true;
            }
            return leveled;
        }

        std::optional<std::string> Legal(std::string const& command) const
        {
            Engine::Pet const& pet = _eng.Current(Side::P);
            if (command.empty())
                return std::nullopt;
            char const kind = command[0];
            std::optional<double> const number = Protocol::LuaNumberOf(command.substr(1));
            bool const integral = number && *number == std::floor(*number);
            if (kind == 'A' && integral && *number >= 1 && *number <= 3 &&
                Engine::Ready(pet, static_cast<int32_t>(*number)) && pet.hp > 0)
                return command;
            if (kind == 'S' && integral && *number >= 1 && *number <= static_cast<double>(_eng.Team(Side::P).size()))
            {
                int32_t const target = static_cast<int32_t>(*number);
                if (_eng.At(Side::P, target).hp > 0 && target != _eng.Active(Side::P) &&
                    !(pet.hp > 0 && Engine::Locked(nullptr, pet, "swapOutLock")))
                    return command;
            }
            if (kind == 'T' && pet.hp > 0 && Engine::CanTrap(_eng))
                return std::string("T");
            return std::nullopt;
        }

        void Command(std::string const& payload)
        {
            if (_over || !_waiting)
                return;
            std::optional<std::string> const command = Legal(payload);
            if (!command)
            {
                _world.Refused(_character, payload);
                if (!_turn.empty())
                    Send("turn", _turn);
                return;
            }
            _waiting = false;
            std::string const enemy = Engine::AI(_eng, Side::E);
            PlayRound(Engine::Round(_eng, *command, enemy));
        }

        void Begin(Store::Journal* journal)
        {
            Send("begin", "");
            for (Side side : { Side::P, Side::E })
                for (size_t i = 1; i <= _eng.Team(side).size(); ++i)
                    SendPet(side, static_cast<int32_t>(i));
            for (size_t i = 0; i < _eng.Team(Side::E).size(); ++i)
            {
                Engine::Pet const& enemy = _eng.Team(Side::E)[i];
                uint8_t const quality = static_cast<uint8_t>(enemy.quality);
                uint8_t const level = static_cast<uint8_t>(enemy.level);
                Store::OwnedPet const* owned = journal ? journal->PetOfSpecies(enemy.species) : nullptr;
                uint8_t status = 0;
                if (owned)
                    status = quality > owned->quality || (quality == owned->quality && level > owned->level) ? 1 : 2;
                else if (journal && journal->Owns(enemy.species))
                    status = 2;
                Send("own", std::to_string(i + 1) + "," + std::to_string(status) + "," +
                    std::to_string(owned ? owned->quality : 0) + "," + std::to_string(owned ? owned->level : 0));
                if (_battles.UsesOwnedIds(_character))
                    Send("breed2", std::to_string(i + 1) + "," + std::to_string(enemy.breed) + "," +
                        N(std::floor(enemy.power + 0.5)) + "," + N(std::floor(enemy.speed + 0.5)));
            }
            SendAbilities();
            std::shared_ptr<Session> self = shared_from_this();
            Scheduler& scheduler = _battles.GetScheduler();
            scheduler.After(300, [self] { self->SpawnPet(Side::P, 1); self->Send("in", "P,1"); });
            scheduler.After(1300, [self] { self->SpawnPet(Side::E, 1); self->Send("in", "E,1"); });
            scheduler.After(2600, [self]
            {
                self->SendTags(Side::P, std::nullopt);
                self->SendTags(Side::E, std::nullopt);
                self->SendTurn(false);
            });
        }

        void Abandon(bool notify, bool effect = false)
        {
            if (notify && !_over)
                Send("end", "interrupted");
            _over = true;
            Despawn(Side::P, effect);
            Despawn(Side::E, effect);
        }

    private:
        static size_t Index(Side side) { return side == Side::P ? 0 : 1; }

        Battles& _battles;
        World& _world;
        std::shared_ptr<Engine::Catalog const> _catalogHold;
        Engine::Catalog const& _catalog;
        uint64_t _character;
        Engine::Battle _eng;
        double _enemyLevel;
        bool _over = false;
        bool _waiting = false;
        std::string _turn;
        uint32_t _lastAct = 0;
        std::array<uint64_t, 2> _handles { 0, 0 };
        std::array<uint64_t, 2> _spawnOrder { 0, 0 };
        uint64_t _spawns = 0;
        std::array<bool, 8> _acted {};
        std::optional<double> _vis;
        bool _ranged = false;
        std::array<bool, 2> _lunged { false, false };
        std::array<bool, 2> _hop { false, false };
        std::array<uint32_t, 2> _health { 1000, 1000 };
        std::map<std::string, std::string> _tipSent;
    };

    Battles::Battles(std::shared_ptr<Engine::Catalog const> catalog, DataSet const& data, ModelInfoLookup modelInfo,
        World& world, Scheduler& scheduler, Engine::Rng& rng)
        : _catalog(std::move(catalog)), _scale(data, std::move(modelInfo)), _world(world), _scheduler(scheduler), _rng(rng)
    {
    }

    Battles::~Battles() = default;

    bool Battles::InBattle(uint64_t character) const
    {
        return _sessions.count(character) != 0;
    }

    void Battles::Unregister(uint64_t character, Session const* session)
    {
        auto const found = _sessions.find(character);
        if (found == _sessions.end() || found->second.get() != session)
            return;
        if (found->second->HoldsStandIns())
            _lingering.emplace(character, found->second);
        _sessions.erase(found);
    }

    void Battles::ClearLingering(uint64_t character)
    {
        auto [first, last] = _lingering.equal_range(character);
        for (auto it = first; it != last; ++it)
            if (std::shared_ptr<Session> session = it->second.lock())
                session->DespawnInOrder();
        _lingering.erase(character);
    }

    void Battles::SendJournalPet(uint64_t character, Store::Journal const& journal, Store::OwnedPet const& pet,
        uint32_t now)
    {
        bool const ownedIds = UsesOwnedIds(character);
        if (ownedIds || journal.PetIdForSpecies(pet.species) == pet.id)
            _world.Send(character, "pbj", ownedIds ? "pet2" : "pet",
                Protocol::PetMessage(*_catalog, journal, pet, now, ownedIds));
    }

    void Battles::NotifyRelease(uint32_t account, uint32_t petId)
    {
        for (uint64_t character : _ownedIdClients)
        {
            if (!_world.Online(character) || _world.Account(character) != account)
                continue;
            if (Store::Journal const* journal = _world.JournalOf(character))
                for (uint8_t team = 1; team <= Store::TeamCount; ++team)
                    _world.Send(character, "pbj", "team2", Protocol::TeamMessage(*journal, team, true));
            _world.Send(character, "pbj", "removed2", std::to_string(petId));
        }
        _world.DismissReleasedFollowers(account, petId);
    }

    void Battles::FedRefresh(uint64_t character, uint32_t petId, uint32_t remaining, uint64_t stepMs)
    {
        _scheduler.After(stepMs, [this, character, petId, remaining, stepMs]
        {
            if (_world.Online(character))
                if (Store::Journal* journal = _world.JournalOf(character))
                    if (Store::OwnedPet const* pet = journal->Pet(petId))
                        SendJournalPet(character, *journal, *pet, _world.UnixNow());
            if (remaining > 1)
                FedRefresh(character, petId, remaining - 1, stepMs);
        });
    }

    uint32_t Battles::Clean(uint64_t character)
    {
        auto const found = _sessions.find(character);
        if (found != _sessions.end())
        {
            std::shared_ptr<Session> const session = found->second;
            _sessions.erase(found);
            session->Abandon(false, true);
        }
        _world.Suppress(character, false);
        _world.Send(character, "pbt", "end", "interrupted");
        uint32_t const removed = _world.SweepStandIns(character, 200);
        _world.Send(character, "pbt", "msg", "Removed " + std::to_string(removed) + " leftover pets nearby.");
        return removed;
    }

    void Battles::UseCatalog(std::shared_ptr<Engine::Catalog const> catalog)
    {
        _catalog = std::move(catalog);
    }

    void Battles::Abandon(uint64_t character)
    {
        auto const found = _sessions.find(character);
        if (found != _sessions.end())
        {
            std::shared_ptr<Session> const session = found->second;
            _sessions.erase(found);
            session->Abandon(true);
        }
        ClearLingering(character);
    }

    bool Battles::OtherCharacterFighting(uint64_t character) const
    {
        uint32_t const account = _world.Account(character);
        for (auto const& [other, session] : _sessions)
            if (other != character && !session->Over() && _world.Online(other) && _world.Account(other) == account)
                return true;
        return false;
    }

    bool Battles::Start(uint64_t character, std::optional<std::vector<EnemySpec>> enemies)
    {
        auto const old = _sessions.find(character);
        if (old != _sessions.end())
        {
            std::shared_ptr<Session> const previous = old->second;
            _sessions.erase(old);
            previous->Abandon(false, true);
        }
        if (_world.InCombat(character) || !_world.Alive(character))
        {
            _world.Send(character, "pbt", "msg", "You cannot battle right now.");
            return false;
        }
        _world.SyncCompanions(character);
        Store::Journal* journal = _world.JournalOf(character);
        std::vector<Engine::Pet> mine;
        if (journal)
        {
            uint8_t const active = journal->ActiveTeam();
            auto const& before = journal->TeamAt(active).slots;
            bool const hadTeam = std::any_of(before.begin(), before.end(),
                [journal](uint32_t petId) { return journal->Pet(petId) != nullptr; });
            std::array<uint32_t, 3> const slots = journal->BattleTeam(UsesOwnedIds(character));
            if (!hadTeam && !journal->Pets().empty())
            {
                _world.Flush(*journal);
                bool const ownedIds = UsesOwnedIds(character);
                _world.Send(character, "pbj", ownedIds ? "team2" : "team",
                    Protocol::TeamMessage(*journal, active, ownedIds));
                _world.Send(character, "pbt", "msg",
                    "No team was set up: using your highest level pets. Change it in /pets > Teams.");
            }
            uint32_t const now = _world.UnixNow();
            for (uint32_t petId : slots)
            {
                Store::OwnedPet const* pet = journal->Pet(petId);
                if (!pet)
                    continue;
                Engine::Pet built = Engine::NewPet(*_catalog, pet->species, pet->level,
                    std::array<int32_t, 3> { pet->picks[0], pet->picks[1], pet->picks[2] }, _rng, pet->quality,
                    static_cast<double>(journal->CurrentHealth(*pet, now)), pet->breed);
                built.display = pet->display;
                built.ownedPetId = pet->id;
                mine.push_back(std::move(built));
            }
        }
        if (mine.empty())
        {
            _world.Send(character, "pbt", "msg", "You have no pets yet. Open /pets.");
            return false;
        }
        double sum = 0;
        for (Engine::Pet const& pet : mine)
            sum += pet.level;
        double level = std::max(1.0, std::floor(sum / static_cast<double>(mine.size()) + 0.5));
        std::vector<Engine::Pet> theirs;
        if (enemies)
        {
            level = enemies->front().level;
            for (EnemySpec const& enemy : *enemies)
            {
                theirs.push_back(Engine::NewPet(*_catalog, enemy.species, enemy.level, std::nullopt, _rng,
                    enemy.quality, std::nullopt, enemy.breed));
                if (enemy.display)
                    theirs.back().display = enemy.display;
            }
        }
        else
        {
            std::vector<uint32_t> const pool = _catalog->SpeciesIds();
            for (size_t i = 0; i < MaxEnemies; ++i)
            {
                uint32_t const species = pool[static_cast<size_t>(_rng.Roll(1, static_cast<int32_t>(pool.size()))) - 1];
                double const quality = Engine::RollQuality(*_catalog, _rng);
                theirs.push_back(Engine::NewPet(*_catalog, species, level, std::nullopt, _rng, quality, std::nullopt));
            }
        }
        auto session = std::make_shared<Session>(*this, character, std::move(mine), std::move(theirs), level);
        for (Side side : { Side::P, Side::E })
            for (Engine::Pet& pet : session->Eng().Team(side))
            {
                if (pet.display)
                    continue;
                std::vector<uint32_t> const displays = _world.Displays(pet.species);
                if (displays.empty())
                    continue;
                pet.display = displays[static_cast<size_t>(_rng.Roll(1, static_cast<int32_t>(displays.size()))) - 1];
                if (side == Side::P && journal)
                {
                    if (journal->SetDisplayOnce(pet.ownedPetId, pet.display))
                        _world.Prime(character, pet.species, pet.species, pet.display);
                    _world.Flush(*journal);
                }
            }
        _world.MarkOrigin(character);
        _world.Suppress(character, true);
        _sessions[character] = session;
        session->Begin(journal);
        return true;
    }

    void Battles::Command(uint64_t character, std::string const& payload)
    {
        auto const found = _sessions.find(character);
        if (found != _sessions.end())
            found->second->Command(payload);
    }

    void Battles::Quit(uint64_t character)
    {
        auto const found = _sessions.find(character);
        if (found == _sessions.end() || found->second->Over())
            return;
        std::shared_ptr<Session> const session = found->second;
        session->Send("msg", "You forfeited the battle: your pets are knocked out.");
        session->End("loss", true);
    }

    void Battles::Logout(uint64_t character)
    {
        _ownedIdClients.erase(character);
        auto const found = _sessions.find(character);
        if (found != _sessions.end())
        {
            std::shared_ptr<Session> const session = found->second;
            Quit(character);
            session->DespawnInOrder();
            Unregister(character, session.get());
        }
        ClearLingering(character);
    }

    void Battles::Watchdog()
    {
        for (auto it = _lingering.begin(); it != _lingering.end();)
        {
            std::shared_ptr<Session> const session = it->second.lock();
            it = (!session || !session->HoldsStandIns()) ? _lingering.erase(it) : std::next(it);
        }
        uint32_t const now = _world.UnixNow();
        std::vector<std::shared_ptr<Session>> sessions;
        for (auto const& [character, session] : _sessions)
            sessions.push_back(session);
        for (std::shared_ptr<Session> const& session : sessions)
        {
            if (session->Over())
                continue;
            uint64_t character = 0;
            for (auto const& [key, value] : _sessions)
                if (value == session)
                    character = key;
            if (!_world.Online(character) || !_world.Alive(character) || _world.Away(character))
            {
                session->Send("msg", "The battle ended due to interruption.");
                session->End("interrupted", false);
            }
            else if (session->Waiting() && session->LastAct() && now - session->LastAct() > IdleTimeoutSeconds)
            {
                session->Send("msg", "The battle timed out.");
                session->End("interrupted", false);
            }
        }
    }

    void Battles::EndAll()
    {
        std::map<uint64_t, std::shared_ptr<Session>> sessions;
        sessions.swap(_sessions);
        for (auto const& [character, session] : sessions)
            session->Abandon(true);
        std::vector<uint64_t> characters;
        for (auto const& [character, session] : _lingering)
            characters.push_back(character);
        for (uint64_t character : characters)
            ClearLingering(character);
    }

    void Battles::Message(uint64_t character, std::string const& module, std::string const& action,
        std::string const& payload)
    {
        if (module == "pbt")
        {
            if (action == "start")
            {
                if (_world.Gm(character))
                    Challenge(character, payload);
            }
            else if (action == "cmd")
                Command(character, payload);
            else if (action == "quit")
                Quit(character);
            else if (action == "clean")
                Clean(character);
            return;
        }
        if (module != "pbj")
            return;
        Store::Journal* journal = _world.JournalOf(character);
        if (!journal)
            return;
        bool const ownedIds = action.ends_with('2');
        if (ownedIds)
            _ownedIdClients.insert(character);
        if (action == "hello2")
            return;
        Protocol::JournalReply reply;
        reply.ownedIds = ownedIds;
        reply.now = _world.UnixNow();
        reply.send = [this, character](std::string_view replyModule, std::string_view replyAction,
            std::string const& replyPayload) { _world.Send(character, replyModule, replyAction, replyPayload); };
        reply.syncCompanions = [this, character] { _world.SyncCompanions(character); };
        reply.foodLevel = [this](uint32_t item) { return _world.FoodLevel(item); };
        reply.hasItem = [this, character](uint32_t item) { return _world.HasItem(character, item); };
        reply.takeItem = [this, character](uint32_t item) { _world.TakeItem(character, item); };
        reply.inBattle = [this, character] { return InBattle(character); };
        reply.releaseBlocked = [this, character] { return InBattle(character) || OtherCharacterFighting(character); };
        reply.released = [this, character, journal](uint32_t petId)
        {
            uint32_t const account = journal->Account();
            _world.FlushRelease(*journal, [this, character, account, petId](bool success)
            {
                if (success)
                    NotifyRelease(account, petId);
                else if (_world.Online(character))
                    _world.Send(character, "pbj", "releaseerror2", "The release could not be saved. Reopen the journal.");
            });
        };
        reply.fedRefresh = [this, character](uint32_t petId, uint32_t steps, uint64_t stepMs)
        {
            FedRefresh(character, petId, steps, stepMs);
        };
        reply.summon = [this, character](uint32_t petId) { _world.Summon(character, petId); };
        reply.dismiss = [this, character] { _world.Dismiss(character); };
        reply.follower = [this, character, ownedIds]
        {
            return ownedIds ? _world.FollowerId(character) : _world.Follower(character);
        };
        reply.prime = [this, character] { return _world.PrimeAll(character); };
        Protocol::HandleJournalMessage(*_catalog, *journal, ownedIds ? action.substr(0, action.size() - 1) : action,
            payload, reply);
        _world.Flush(*journal);
    }

    bool Battles::Challenge(uint64_t character, std::string const& payload)
    {
        if (OtherCharacterFighting(character))
        {
            _world.Send(character, "pbt", "msg", "Another character of your account is in a pet battle.");
            return false;
        }
        std::vector<EnemySpec> list;
        size_t at = 0;
        while (at < payload.size())
        {
            if (payload[at] < '0' || payload[at] > '9')
            {
                ++at;
                continue;
            }
            size_t end = at;
            while (end < payload.size() && payload[end] >= '0' && payload[end] <= '9')
                ++end;
            std::string const id = payload.substr(at, end - at);
            if (end < payload.size() && payload[end] == '@')
                ++end;
            size_t levelEnd = end;
            while (levelEnd < payload.size() && payload[levelEnd] >= '0' && payload[levelEnd] <= '9')
                ++levelEnd;
            std::string const levelText = payload.substr(end, levelEnd - end);
            at = levelEnd;
            std::optional<double> const species = Protocol::LuaNumberOf(id);
            if (!species || !_catalog->Species(static_cast<uint32_t>(*species)) || list.size() >= MaxEnemies)
                continue;
            std::optional<double> const wanted = Protocol::LuaNumberOf(levelText);
            double const level = std::max(1.0, std::min<double>(_catalog->Config().maxLevel, wanted ? *wanted : 5));
            list.push_back({ static_cast<uint32_t>(*species), level, Engine::RollQuality(*_catalog, _rng) });
        }
        return Start(character, list.empty() ? std::nullopt : std::optional<std::vector<EnemySpec>>(list));
    }
}
