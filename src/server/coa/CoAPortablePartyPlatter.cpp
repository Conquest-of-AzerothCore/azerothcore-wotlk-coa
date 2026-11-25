#include "AscensionClientSpellPatches.h"
#include "Creature.h"
#include "PassiveAI.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include <array>

namespace
{
    constexpr uint32 PlatterItem = 9707200;
    constexpr std::array<uint32, 11> ClientSpells = {
        9978100, 9978101, 9978102, 9978103, 9978104, 9978105, 9978106, 9978107, 9978108, 9978109, 9978110};
    constexpr uint32 PlatterGossipText = 9990600;
    constexpr uint32 DessertsSpell = 9978101;
    constexpr uint32 SnowInAConeOption = 4;

    struct Treat
    {
        char const* Name;
        uint32 Spell;
    };

    constexpr std::array<Treat, 6> Treats = {{
        {"Slice of Cake", 9978102},
        {"Blubbery Muffin", 9978103},
        {"Rocks on the Rocks", 9978104},
        {"Sugarfree Firewater Sorbet", 9978105},
        {"Snow in a Cone", 9978107},
        {"Party Peripherals", 9978106},
    }};

    constexpr std::array<uint32, 4> Cones = {9978107, 9978108, 9978109, 9978110};

    uint32 TreatSpell(uint32 option)
    {
        if (option == SnowInAConeOption)
            return Cones[urand(0, Cones.size() - 1)];

        return Treats[option].Spell;
    }
}

class npc_coa_portable_party_platter_ai : public PassiveAI
{
public:
    explicit npc_coa_portable_party_platter_ai(Creature* creature) : PassiveAI(creature) { }

    void IsSummonedBy(WorldObject*) override
    {
        ServeDesserts();
    }

    void Reset() override
    {
        ServeDesserts();
    }

private:
    void ServeDesserts()
    {
        if (!me->HasAura(DessertsSpell))
            me->CastSpell(me, DessertsSpell, true);
    }
};

class npc_coa_portable_party_platter : public CreatureScript
{
public:
    npc_coa_portable_party_platter() : CreatureScript("npc_coa_portable_party_platter") { }

    CreatureAI* GetAI(Creature* creature) const override
    {
        return new npc_coa_portable_party_platter_ai(creature);
    }

    bool OnGossipHello(Player* player, Creature* creature) override
    {
        ClearGossipMenuFor(player);
        for (uint32 option = 0; option < Treats.size(); ++option)
            AddGossipItemFor(player, GOSSIP_ICON_CHAT, Treats[option].Name, GOSSIP_SENDER_MAIN, option);

        SendGossipMenuFor(player, PlatterGossipText, creature->GetGUID());
        return true;
    }

    bool OnGossipSelect(Player* player, Creature*, uint32 sender, uint32 action) override
    {
        CloseGossipMenuFor(player);
        if (sender != GOSSIP_SENDER_MAIN || action >= Treats.size())
            return true;

        player->CastSpell(player, TreatSpell(action), true);
        return true;
    }
};

void AddSC_CoAPortablePartyPlatter()
{
    for (uint32 spell : ClientSpells)
        Ascension::ClientSpellPatches::Instance().Register(spell);
    Ascension::ClientItemPatches::Instance().Register(PlatterItem);
    new npc_coa_portable_party_platter();
}
