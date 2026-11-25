namespace
{
void AddBind(Player& player, uint32 map, Difficulty mode, uint32 instance)
{
    manager.saves.push_back(std::make_unique<InstanceSave>(InstanceSave{instance}));
    manager.binds[player.guid][mode][map] = {manager.saves.back().get()};
    CharacterDatabase.bindings.insert({player.guid.id, instance});
    ObjectAccessor::players[player.guid] = &player;
}

void Select(npc_coa_raid_reset& npc, Player& player, uint32 action)
{
    auto const found = std::find(player.talk.actions.begin(), player.talk.actions.end(), action);
    assert(found != player.talk.actions.end());
    npc.sGossipSelect(&player, 0, uint32(found - player.talk.actions.begin()));
}

void ResetWorld()
{
    manager = InstanceSaveMgr{};
    CharacterDatabase = Database{};
    ObjectAccessor::players.clear();
    config.gold = 10;
    raid_reset_config{}.OnStartup();
}

void PersonalReset()
{
    ResetWorld();
    Creature creature;
    npc_coa_raid_reset npc(&creature);
    Player player;
    AddBind(player, 409, Normal, 100);
    AddBind(player, 469, Ascended, 101);
    AddBind(player, 229, Normal, 102);
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    assert(player.money == 500000 && manager.binds[player.guid][Normal].contains(409));
    Select(npc, player, Confirm);
    assert(player.money == 400000 && CharacterDatabase.balances[1] == 400000);
    assert(!manager.binds[player.guid][Normal].contains(409));
    assert(!manager.binds[player.guid][Ascended].contains(469));
    assert(manager.binds[player.guid][Normal].contains(229));
    assert((CharacterDatabase.bindings == std::set<std::pair<uint32, uint32>>{{1, 102}}));
    assert(manager.calendarUpdates.size() == 2 && CharacterDatabase.commits == 1);
    for (auto const& save : manager.saves)
        assert(save->encounters == 3);
    player.talk.actions = {Confirm};
    Select(npc, player, Confirm);
    assert(player.money == 400000 && CharacterDatabase.commits == 1);
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    assert(player.money == 400000 && !npc.quotes.contains(player.guid));
    AddBind(player, 409, Normal, 200);
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    Select(npc, player, Confirm);
    assert(player.money == 300000 && CharacterDatabase.commits == 2);
}

void RaidReset()
{
    ResetWorld();
    Creature creature;
    npc_coa_raid_reset npc(&creature);
    Player leader;
    Group group;
    leader.group = &group;
    group.members.push_back({leader.guid});
    AddBind(leader, 409, Normal, 100);
    std::array<Player, 24> bots;
    for (uint32 i = 0; i < bots.size(); ++i)
    {
        Player& bot = bots[i];
        bot.guid.id = i + 2;
        bot.session.bot = true;
        bot.group = &group;
        group.members.push_back({bot.guid});
        AddBind(bot, 409, Normal, 100);
        AddBind(bot, 469, Heroic, 300 + i);
    }
    bots[0].session.bot = false;
    bots[1].map.instance = true;
    bots[2].combat = true;
    bots[3].teleport = true;
    bots[4].online = false;
    npc.sGossipHello(&leader);
    Select(npc, leader, Raid);
    assert(npc.quotes.at(leader.guid).plan.characters == 20);
    Select(npc, leader, Confirm);
    assert(leader.money == 400000 && CharacterDatabase.commits == 1);
    for (uint32 i = 0; i < bots.size(); ++i)
    {
        assert(bots[i].money == 500000);
        assert(manager.binds[bots[i].guid][Normal].contains(409) == (i < 5));
        assert(CharacterDatabase.bindings.contains({bots[i].guid.id, 100}) == (i < 5));
    }
    assert(manager.calendarUpdates.size() == 39);
}

void RejectedAndChangedQuotes()
{
    ResetWorld();
    Creature creature;
    npc_coa_raid_reset npc(&creature);
    Player player;
    AddBind(player, 409, Normal, 100);
    player.money = 99999;
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    Select(npc, player, Confirm);
    assert(player.money == 99999 && CharacterDatabase.commits == 0);
    player.money = 500000;
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    Select(npc, player, Cancel);
    assert(player.money == 500000 && CharacterDatabase.commits == 0 && npc.quotes.empty());
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    config.gold = 20;
    raid_reset_config{}.OnAfterConfigLoad(true);
    Select(npc, player, Confirm);
    assert(player.money == 500000 && CharacterDatabase.commits == 0);
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    AddBind(player, 469, Mythic, 200);
    Select(npc, player, Confirm);
    assert(player.money == 500000 && CharacterDatabase.commits == 0);
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    npc.quotes.at(player.guid).expires = std::chrono::steady_clock::time_point{};
    Select(npc, player, Confirm);
    assert(player.money == 500000 && CharacterDatabase.commits == 0);
    Group group;
    group.leader = player.guid;
    group.members.push_back({player.guid});
    player.group = &group;
    npc.sGossipHello(&player);
    Select(npc, player, Raid);
    group.leader = {90};
    Select(npc, player, Confirm);
    assert(player.money == 500000 && CharacterDatabase.commits == 0);
    npc.sGossipHello(&player);
    assert(std::find(player.talk.actions.begin(), player.talk.actions.end(), Raid) == player.talk.actions.end());
    player.combat = true;
    npc.sGossipHello(&player);
    assert(player.talk.actions.empty());
    player.combat = false;
    player.session.bot = true;
    npc.sGossipHello(&player);
    assert(player.talk.actions.empty());
}

void ConfiguredFee()
{
    ResetWorld();
    config.gold = 23;
    raid_reset_config{}.OnStartup();
    assert(resetCost == 230000);
    config.gold = 0;
    raid_reset_config{}.OnAfterConfigLoad(true);
    Creature creature;
    npc_coa_raid_reset npc(&creature);
    Player player;
    player.money = 0;
    AddBind(player, 409, Ascended, 100);
    npc.sGossipHello(&player);
    Select(npc, player, Personal);
    Select(npc, player, Confirm);
    assert(player.money == 0 && !manager.binds[player.guid][Ascended].contains(409));
    config.gold = INT64_MAX;
    raid_reset_config{}.OnAfterConfigLoad(true);
    assert(resetCost <= MAX_MONEY_AMOUNT);
}
}

int main()
{
    PersonalReset();
    RaidReset();
    RejectedAndChangedQuotes();
    ConfiguredFee();
    std::cout << "PASS: personal and flat-fee bot-raid resets, persistence, eligibility, replay rejection, "
        "quote invalidation, configurable fees, unlimited reuse and preserved instance progress\n";
}
