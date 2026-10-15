#include <array>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <initializer_list>
#include <unordered_map>
#include <unordered_set>
#include <vector>

using uint8 = std::uint8_t;
using uint16 = std::uint16_t;
using uint32 = std::uint32_t;
using int32 = std::int32_t;

#define LOG_ERROR(...) ((void)0)
#define LOG_DEBUG(...) ((void)0)

// ACTUAL_FLAG96
// ACTUAL_SPELL_MOD_OPS
// ACTUAL_SPELL_MOD_TYPE

enum Opcodes : uint16
{
    SMSG_SET_FLAT_SPELL_MODIFIER = 0x266,
    SMSG_SET_PCT_SPELL_MODIFIER = 0x267
};

struct Aura
{
};

// ACTUAL_SPELL_MODIFIER
// ACTUAL_SPELL_MOD_CONTAINER

class WorldPacket
{
public:
    WorldPacket(uint16 opcode, std::size_t) : Opcode(opcode) { }

    template<class T>
    WorldPacket& operator<<(T value)
    {
        auto const* bytes = reinterpret_cast<uint8 const*>(&value);
        Bytes.insert(Bytes.end(), bytes, bytes + sizeof(T));
        return *this;
    }

    uint16 Opcode;
    std::vector<uint8> Bytes;
};

struct SpellInfo
{
    uint32 Id;
    uint32 SpellFamilyName;
};

class SpellMgr
{
public:
    SpellInfo const* GetSpellInfo(uint32 id) const
    {
        auto const found = Spells.find(id);
        return found == Spells.end() ? nullptr : &found->second;
    }

    std::unordered_map<uint32, SpellInfo> Spells;
};

SpellMgr spellMgr;
#define sSpellMgr (&spellMgr)

std::vector<WorldPacket> sent;

class Player;

class WorldSession
{
public:
    bool IsAscensionCompatEnabled() const { return AscensionClient; }
    void SendPacket(WorldPacket const* packet) { sent.push_back(*packet); }
    void ResendSpellMods(Player* pCurrChar);

    bool AscensionClient = false;
};

class Player
{
public:
    WorldSession* GetSession() const { return Session; }
    void SendDirectMessage(WorldPacket const* packet) const { sent.push_back(*packet); }
    SpellModContainer const& GetSpellModList(uint32 op) const { return m_spellMods[op]; }
    void AddSpellMod(SpellModifier* mod, bool apply);
    bool UsesAscensionSpellModifierLayout() const;
    uint32 GetClientSpellModCount() const;
    void SendSpellModifier(uint16 opcode, uint8 eff, uint8 op, int32 value, uint32 spellFamily) const;

    WorldSession* Session = nullptr;
    std::array<SpellModContainer, MAX_SPELLMOD> m_spellMods;
};

// ACTUAL_ADD_SPELL_MOD

void WorldSession::ResendSpellMods(Player* pCurrChar)
{
// ACTUAL_LOGIN_RESEND
}

namespace
{
constexpr uint32 SUMMONING_ADEPT = 92123;
constexpr uint8 NECROMANCER_FAMILY = 29;
constexpr uint8 LIFE_FORCE_MASK_BIT = 49;
constexpr uint8 MAX_AURA_STACKS_OP = 31;
constexpr uint8 COST_REFUND_OP = 30;

int failures = 0;

void Check(bool condition, char const* description)
{
    std::printf("%s: %s\n", condition ? "PASS" : "FAIL", description);
    failures += !condition;
}

SpellModifier* LifeForceCapacity(SpellModOp op)
{
    auto* mod = new SpellModifier();
    mod->op = op;
    mod->type = SPELLMOD_FLAT;
    mod->value = 1;
    mod->mask = flag96(0, 0x20000, 0);
    mod->spellId = SUMMONING_ADEPT;
    return mod;
}

bool Sent(uint16 opcode, std::initializer_list<uint8> bytes)
{
    for (WorldPacket const& packet : sent)
        if (packet.Opcode == opcode && packet.Bytes == std::vector<uint8>(bytes))
            return true;
    return false;
}

bool SentStockOp(uint8 op)
{
    for (WorldPacket const& packet : sent)
        if (packet.Bytes.size() == 6 && packet.Bytes[1] == op)
            return true;
    return false;
}

void AscensionClientReceivesMaxAuraStacks()
{
    WorldSession session;
    session.AscensionClient = true;
    Player player;
    player.Session = &session;
    sent.clear();
    player.AddSpellMod(LifeForceCapacity(SPELLMOD_MAX_AURA_STACKS), true);
    Check(Sent(SMSG_SET_FLAT_SPELL_MODIFIER,
               {0, LIFE_FORCE_MASK_BIT, MAX_AURA_STACKS_OP, 1, 0, 0, 0, NECROMANCER_FAMILY, 0, 0, 0}),
          "an Ascension client is sent the max aura stacks modifier when it is applied");

    SpellModifier* mod = *player.m_spellMods[SPELLMOD_MAX_AURA_STACKS].begin();
    sent.clear();
    player.AddSpellMod(mod, false);
    Check(Sent(SMSG_SET_FLAT_SPELL_MODIFIER,
               {0, LIFE_FORCE_MASK_BIT, MAX_AURA_STACKS_OP, 0, 0, 0, 0, NECROMANCER_FAMILY, 0, 0, 0}),
          "an Ascension client is sent the cleared max aura stacks modifier when it is removed");
}

void StockClientIsNotSentMaxAuraStacks()
{
    WorldSession session;
    Player player;
    player.Session = &session;
    sent.clear();
    player.AddSpellMod(LifeForceCapacity(SPELLMOD_MAX_AURA_STACKS), true);
    Check(sent.empty(), "a stock client is not sent the max aura stacks modifier");

    sent.clear();
    player.AddSpellMod(LifeForceCapacity(SPELLMOD_SPELL_COST_REFUND_ON_FAIL), true);
    Check(Sent(SMSG_SET_FLAT_SPELL_MODIFIER, {LIFE_FORCE_MASK_BIT, COST_REFUND_OP, 1, 0, 0, 0}),
          "a stock client is still sent the highest native modifier");
}

void LoginResendsMaxAuraStacks(bool ascensionClient)
{
    WorldSession session;
    session.AscensionClient = ascensionClient;
    Player player;
    player.Session = &session;
    player.m_spellMods[SPELLMOD_MAX_AURA_STACKS].insert(LifeForceCapacity(SPELLMOD_MAX_AURA_STACKS));
    sent.clear();
    session.ResendSpellMods(&player);
    if (ascensionClient)
        Check(Sent(SMSG_SET_FLAT_SPELL_MODIFIER,
                   {0, LIFE_FORCE_MASK_BIT, MAX_AURA_STACKS_OP, 1, 0, 0, 0, NECROMANCER_FAMILY, 0, 0, 0}),
              "logging in resends the max aura stacks modifier to an Ascension client");
    else
        Check(!SentStockOp(MAX_AURA_STACKS_OP),
              "logging in does not resend the max aura stacks modifier to a stock client");
}
}

int main()
{
    spellMgr.Spells[SUMMONING_ADEPT] = {SUMMONING_ADEPT, NECROMANCER_FAMILY};
    AscensionClientReceivesMaxAuraStacks();
    StockClientIsNotSentMaxAuraStacks();
    LoginResendsMaxAuraStacks(true);
    LoginResendsMaxAuraStacks(false);
    std::printf("%d failure(s)\n", failures);
    return failures ? 1 : 0;
}
