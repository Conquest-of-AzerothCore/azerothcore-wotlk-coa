uint32 word(std::vector<uint8> const& b,size_t& i)
{
    assert(i+4<=b.size());uint32 n=0;for(int k=0;k<4;++k)n|=uint32(b[i++])<<(k*8);return n;
}
std::string string(std::vector<uint8> const& b,size_t& i)
{
    auto n=word(b,i);assert(n<=b.size()-i);std::string s(b.begin()+i,b.begin()+i+n);i+=n;return s;
}
int main()
{
    cache.chars={{{1},{{1},10,"Owner"}},{{2},{{2},10,"Owner Alt"}},
                 {{3},{{3},20,"Original Friend"}},{{4},{{4},20,"Current Friend"}},
                 {{5},{{5},30,"Unrelated"}}};
    WorldSession ownerSession{};ownerSession.account=10;
    WorldSession friendSession{};friendSession.account=20;
    Player owner{};owner.guid={1};owner.session=&ownerSession;
    Player other{};other.guid={4};other.session=&friendSession;
    ownerSession.player=&owner;friendSession.player=&other;sessions.values={{10,&ownerSession},{20,&friendSession}};
    WorldPacket contactRequest(0x66, 0);
    MapSessionFilter mapFilter{&ownerSession};
    WorldSessionFilter worldFilter{&ownerSession};
    assert(!mapFilter.Process(&contactRequest) && worldFilter.Process(&contactRequest));
    owner.inWorld=false;
    assert(!mapFilter.Process(&contactRequest) && worldFilter.Process(&contactRequest));
    owner.inWorld=true;
    PlayerSocial social{{1},{}},alt{{2},{}};
    owner.social=&social;
    world.enabled=false;
    assert(!social.HasFriend({3}) && AccountFriends::Loaded.empty());
    world.enabled=true;
    assert(!social.HasFriend({3}));
    assert(!AccountFriends::Add({1},{2}));
    assert(AccountFriends::Add({1},{3}));
    assert(social.HasFriend({4}) && alt.HasFriend({3}));
    assert(!AccountFriends::Has({3},{1}));
    social.m_playerSocialMap[{3}].Flags=SOCIAL_FLAG_FRIEND;
    social.m_playerSocialMap.clear();
    assert(AccountFriends::Add({2},{4}));
    assert(CharacterDatabase.rows.size()==1);
    assert(CharacterDatabase.rows.at({10,20}).name=="Original Friend");
    AccountFriends::SetNote({2},{4},"Independent friend note");
    social.m_playerSocialMap[{3}].Flags=SOCIAL_FLAG_IGNORED;
    social.SendSocialList(&owner,3);
    assert(social.m_playerSocialMap.size()==2);
    assert(social.m_playerSocialMap.at({3}).Flags==SOCIAL_FLAG_IGNORED);
    assert(social.m_playerSocialMap.at({4}).Flags==SOCIAL_FLAG_FRIEND);
    assert(social.m_playerSocialMap.at({4}).Note=="Independent friend note");
    auto const& metadata=owner.sent.back();assert(metadata.opcode==0x9c0);
    size_t pos=0;assert(word(metadata.bytes,pos)==1);
    assert(string(metadata.bytes,pos)=="Current Friend");
    assert(string(metadata.bytes,pos)=="Original Friend");assert(pos==metadata.bytes.size());
    social.SendSocialList(&owner,3);
    assert(social.m_playerSocialMap.size()==2);
    social.SendSocialList(&owner,3,{4});
    assert(!social.m_playerSocialMap.count({4}));
    assert(social.m_playerSocialMap.at({3}).Flags==3);
    other.guid={3};social.SendSocialList(&owner,3,{3});
    assert(social.m_playerSocialMap.at({3}).Status==FRIEND_STATUS_OFFLINE);
    other.guid={4};other.visible=false;social.SendSocialList(&owner,3);
    assert(!social.m_playerSocialMap.count({4}));
    other.visible=true;other.inWorld=false;social.SendSocialList(&owner,3);
    assert(!social.m_playerSocialMap.count({4}));
    other.inWorld=true;
    friendSession.gm=true;social.SendSocialList(&owner,3);assert(!social.m_playerSocialMap.count({4}));
    friendSession.gm=false;friendSession.security=1;
    social.SendSocialList(&owner,3);assert(!social.m_playerSocialMap.count({4}));
    friendSession.security=0;other.team=1;ownerSession.crossFaction=false;
    social.SendSocialList(&owner,3);assert(!social.m_playerSocialMap.count({4}));
    ownerSession.crossFaction=true;other.afk=true;
    social.SendSocialList(&owner,3);assert(social.m_playerSocialMap.at({4}).Status==FRIEND_STATUS_AFK);
    other.afk=false;other.dnd=true;
    social.SendSocialList(&owner,3);assert(social.m_playerSocialMap.at({4}).Status==FRIEND_STATUS_DND);
    other.dnd=false;
    cache.chars.at({4}).Name="Renamed Friend";
    social.SendSocialList(&owner,3);
    pos=0;auto const& renamed=owner.sent.back().bytes;
    assert(word(renamed,pos)==1 && string(renamed,pos)=="Renamed Friend");
    assert(string(renamed,pos)=="Original Friend");
    AccountFriends::Loaded.clear();assert(alt.HasFriend({4}));
    AccountFriends::Remove({2},{4});assert(!social.HasFriend({3}));
    social.SendSocialList(&owner,3);assert(social.m_playerSocialMap.size()==1);
    assert(social.m_playerSocialMap.at({3}).Flags==SOCIAL_FLAG_IGNORED);
    AccountFriends::Loaded.clear();assert(!alt.HasFriend({4}));
    CharacterDatabase.writeFail=true;assert(!AccountFriends::Add({1},{3}));
    CharacterDatabase.writeFail=false;CharacterDatabase.readFail=true;
    AccountFriends::Loaded.clear();assert(!AccountFriends::Add({1},{3}));
    CharacterDatabase.readFail=false;assert(AccountFriends::Add({1},{3}));
    cache.chars.erase({3});friendSession.player=nullptr;
    social.SendSocialList(&owner,3);assert(social.m_playerSocialMap.count({4}));
    cache.chars[{3}]={{3},30,"Reassigned"};
    social.SendSocialList(&owner,3);assert(!(social.m_playerSocialMap.at({3}).Flags&SOCIAL_FLAG_FRIEND));
    for(uint32 n=100;n<149;++n)
    { cache.chars[{n}]={{n},n,"Friend"};assert(AccountFriends::Add({1},{n})); }
    assert(!AccountFriends::Add({1},{5}));
    AccountFriends::Loaded.clear();
    CharacterDatabase.legacy[60]={{{uint32(20)},{uint32(4)},{std::string("Current Friend")},{std::string("note")}}};
    CharacterDatabase.writeFail=true;
    assert(!AccountFriends::Get(60));
    assert(!CharacterDatabase.migrated[60] && !CharacterDatabase.rows.count({60,20}));
    CharacterDatabase.writeFail=false;
    assert(AccountFriends::Get(60)->at(20).Note=="note");
    assert(CharacterDatabase.migrated[60]);
    CharacterDatabase.legacy[60].clear();AccountFriends::Loaded.clear();
    assert(AccountFriends::Get(60)->count(20));
    CharacterDatabase.legacy[70]={{{uint32(20)},{uint32(4)},{std::string("Current Friend")},{std::string("one")}},
        {{uint32(20)},{uint32(4)},{std::string("Current Friend")},{std::string("two")}}};
    assert(!AccountFriends::Get(70) && !CharacterDatabase.migrated[70]);
    for(uint32 n=100;n<151;++n)
        CharacterDatabase.legacy[80].push_back({{n},{n},{std::string("Friend")},{std::string()}});
    assert(!AccountFriends::Get(80) && !CharacterDatabase.migrated[80]);
    assert(AccountFriends::Get(90)->empty() && CharacterDatabase.migrated[90]);
    friendSession.player=&other;
    PlayerSocial otherSocial{{4},{}};
    other.social=&otherSocial;
    socialMgr.m_socialMap.emplace(ObjectGuid{1}, social);
    owner.social=&socialMgr.m_socialMap.at({1});
    owner.sent.clear();
    socialMgr.SendFriendStatus(&other, FRIEND_ONLINE, other.guid, true);
    assert(owner.sent.size()==3 && owner.sent.back().opcode==SMSG_FRIEND_STATUS);
    assert(owner.social->m_playerSocialMap.at({4}).Status==FRIEND_STATUS_ONLINE);
    owner.sent.clear();
    socialMgr.SendFriendStatus(&other, FRIEND_OFFLINE, other.guid, true);
    assert(owner.sent.size()==3 && owner.sent.back().opcode==SMSG_FRIEND_STATUS);
    assert(owner.social->m_playerSocialMap.at({4}).Status==FRIEND_STATUS_OFFLINE);
    other.visible=false;owner.sent.clear();
    socialMgr.SendFriendStatus(&other, FRIEND_ONLINE, other.guid, true);
    assert(owner.sent.size()==2 && owner.sent.back().opcode==0x9c0);
    owner.social=&social;
    for (uint32 i=1000;i<1008;++i)
        cache.chars[{i}]={{i},i,"Concurrent owner"};
    std::vector<std::thread> workers;
    for (uint32 i=1000;i<1008;++i)
        for (uint32 repeat=0;repeat<4;++repeat)
            workers.emplace_back([i] { assert(AccountFriends::Add({i},{4})); });
    for (auto& worker : workers)
        worker.join();
    for (uint32 i=1000;i<1008;++i)
        assert(AccountFriends::Get(i)->size()==1 && CharacterDatabase.rows.count({i,20}));
    workers.clear();owner.sent.clear();
    for (uint32 i=0;i<16;++i)
        workers.emplace_back([&] { social.SendSocialList(&owner, SOCIAL_FLAG_ALL); });
    for (auto& worker : workers)
        worker.join();
    assert(owner.sent.size()==32);
    world.enabled=false;
    assert(!alt.HasFriend({4}));
    std::cout<<"Native account identity, cold mode readiness, lifecycle, projection, notes, ignores, wire metadata, limits and DB failure checks passed\n";
}
