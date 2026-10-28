#include <cassert>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <map>
#include <memory>
#include <mutex>
#include <thread>
#include <string>
#include <type_traits>
#include <variant>
#include <vector>
using uint8=uint8_t; using uint16=uint16_t; using uint32=uint32_t;
enum class HighGuid { Player };
struct ObjectGuid
{
    uint32 value=0;
    template<HighGuid> static ObjectGuid Create(uint32 n) { return {n}; }
    uint32 GetCounter() const { return value; }
    explicit operator bool() const { return value != 0; }
    auto operator<=>(ObjectGuid const&) const=default;
    static ObjectGuid const Empty;
};
ObjectGuid const ObjectGuid::Empty{};
constexpr uint8 SOCIAL_FLAG_FRIEND=1, SOCIAL_FLAG_IGNORED=2;
constexpr uint8 FRIEND_STATUS_OFFLINE=0, FRIEND_STATUS_ONLINE=1, FRIEND_STATUS_AFK=2, FRIEND_STATUS_DND=4;
constexpr uint8 FRIEND_STATUS_RAF=8;
using FriendStatus=uint8;
enum FriendsResult { FRIEND_ADDED_OFFLINE, FRIEND_ADDED_ONLINE, FRIEND_OFFLINE, FRIEND_ONLINE };
constexpr uint32 SMSG_FRIEND_STATUS=0x68, SOCIAL_FLAG_ALL=7;
constexpr uint32 SOCIALMGR_FRIEND_LIMIT=50, SOCIALMGR_IGNORE_LIMIT=50, SMSG_CONTACT_LIST=0x67;
struct FriendInfo { uint8 Status=0, Flags=0; uint32 Area=0; uint8 Level=0,Class=0; std::string Note; };
struct WorldPacket
{
    uint16 opcode; std::vector<uint8> bytes;
    WorldPacket(uint16 op, size_t):opcode(op) {}
    uint16 GetOpcode() const { return opcode; }
    template<class T> WorldPacket& operator<<(T v)
    {
        if constexpr(std::is_same_v<T,ObjectGuid>) { *this << uint64_t(v.value); }
        else if constexpr(std::is_same_v<T,std::string>) { append(v.data(),v.size()); bytes.push_back(0); }
        else { for (size_t i=0;i<sizeof(T);++i) bytes.push_back(uint8(uint64_t(v)>>(8*i))); }
        return *this;
    }
    void append(char const* p,size_t n) { bytes.insert(bytes.end(),p,p+n); }
    template<class T> void put(size_t pos,T v) { for (size_t i=0;i<sizeof(T);++i) bytes.at(pos+i)=uint8(uint64_t(v)>>(8*i)); }
    size_t wpos() const { return bytes.size(); }
};
struct Character { ObjectGuid Guid; uint32 AccountId; std::string Name; };
struct Cache
{
    std::map<ObjectGuid,Character> chars;
    uint32 GetCharacterAccountIdByGuid(ObjectGuid g) { auto p=chars.find(g);return p==chars.end()?0:p->second.AccountId; }
    Character const* GetCharacterCacheByGuid(ObjectGuid g) { auto p=chars.find(g);return p==chars.end()?nullptr:&p->second; }
} cache;
auto* sCharacterCache=&cache;
enum Statement { CHAR_SEL_ACCOUNT_FRIENDS,CHAR_INS_ACCOUNT_FRIEND,CHAR_DEL_ACCOUNT_FRIEND,
CHAR_UPD_ACCOUNT_FRIEND_NOTE,CHAR_SEL_FRIEND_FALLBACK, CHAR_SEL_ACCOUNT_FRIEND_MIGRATION, CHAR_INS_ACCOUNT_FRIEND_MIGRATION, CHAR_SEL_ACCOUNT_FRIEND_LEGACY };
using Value=std::variant<uint32,std::string>;
struct Field { Value value; template<class T> T Get() const { return std::get<T>(value); } };
struct Result
{
    std::vector<std::vector<Field>> rows; size_t index=0;
    Field* Fetch() { return rows.at(index).data(); }
    bool NextRow() { return ++index<rows.size(); }
};
struct Prepared
{
    Statement id; std::map<int,Value> args;
    template<class T> void SetData(int n,T value) { args[n]=value; }
    uint32 U(int n) const { return std::get<uint32>(args.at(n)); }
    std::string V(int n) const { return std::get<std::string>(args.at(n)); }
};
struct Record { uint32 guid;std::string name,note; };
struct Transaction
{
    std::vector<std::unique_ptr<Prepared>> statements;
    void Append(Prepared* p) { statements.emplace_back(p); }
};
struct Database
{
    std::map<std::pair<uint32,uint32>,Record> rows; bool readFail=false,writeFail=false;
    int reads=0,writes=0;
    std::map<uint32, bool> migrated;
    std::map<uint32, std::vector<std::vector<Field>>> legacy;
    std::shared_ptr<Transaction> BeginTransaction() { return std::make_shared<Transaction>(); }
    void DirectCommitTransaction(std::shared_ptr<Transaction> const& t)
    {
        if (writeFail) return;
        for (auto& p : t->statements)
            if (p->id == CHAR_INS_ACCOUNT_FRIEND_MIGRATION) migrated[p->U(0)] = true;
            else DirectExecute(p.release());
    }
    Prepared* GetPreparedStatement(Statement id) { return new Prepared{id,{}}; }
    std::shared_ptr<Result> Query(Prepared* raw)
    {
        std::unique_ptr<Prepared> p(raw);++reads;if (readFail)return {};
        auto result=std::make_shared<Result>();
        if (p->id==CHAR_SEL_ACCOUNT_FRIEND_MIGRATION)
            result->rows.push_back({{uint32(migrated[p->U(0)])}});
        else if (p->id==CHAR_SEL_ACCOUNT_FRIEND_LEGACY)
        {
            result->rows=legacy[p->U(0)];
            result->rows.push_back({{uint32(0)},{uint32(0)},{std::string()},{std::string()}});
        }
        else if (p->id==CHAR_SEL_ACCOUNT_FRIENDS)
        {
            for (auto const& [key,r]:rows) if (key.first==p->U(0))
                result->rows.push_back({{key.second},{r.guid},{r.name},{r.note}});
            result->rows.push_back({{uint32(0)},{uint32(0)},{std::string()},{std::string()}});
        }
        else if (p->id==CHAR_SEL_FRIEND_FALLBACK)
        {
            for (auto const& [guid,c]:cache.chars) if (c.AccountId==p->U(0))
            { result->rows.push_back({{guid.value}});break; }
        }
        else assert(false);
        return result->rows.empty()?nullptr:result;
    }
    void DirectExecute(Prepared* raw)
    {
        std::unique_ptr<Prepared> p(raw);++writes;if (writeFail)return;
        if (p->id==CHAR_INS_ACCOUNT_FRIEND)
            rows.emplace(std::pair{p->U(0),p->U(1)},Record{p->U(2),p->V(3),p->V(4)});
        else if (p->id==CHAR_DEL_ACCOUNT_FRIEND) rows.erase({p->U(0),p->U(1)});
        else if (p->id==CHAR_UPD_ACCOUNT_FRIEND_NOTE)
        { auto q=rows.find({p->U(1),p->U(2)});if (q!=rows.end())q->second.note=p->V(0); }
        else assert(false);
    }
} CharacterDatabase;
void utf8truncate(std::string& s,size_t n) { if (s.size()>n)s.resize(n); }
#define LOG_ERROR(...) ((void)0)
#define LOG_DEBUG(...) ((void)0)
struct Player;
struct PlayerSocial;
using TeamId=int;using AccountTypes=int;
constexpr int CONFIG_GM_LEVEL_IN_WHO_LIST=0;
namespace rbac { constexpr int RBAC_PERM_WHO_SEE_ALL_SEC_LEVELS=1,RBAC_PERM_TWO_SIDE_WHO_LIST=2; }
struct WorldSession
{
    uint32 account;Player* player=nullptr;bool gm=false,allSecurity=false,crossFaction=true;int security=0;
    uint32 GetAccountId()const{return account;}
    uint32 GetRecruiterId()const{return 0;}
    Player* GetPlayer()const{return player;}
    bool IsGMAccount()const{return gm;}
    int GetSecurity()const{return security;}
    bool HasPermission(int p)const{return p==1?allSecurity:crossFaction;}
};
struct Player
{
    ObjectGuid guid; WorldSession* session; bool inWorld=true,visible=true;
    std::vector<WorldPacket> sent;
    PlayerSocial* social=nullptr;int team=0;bool afk=false,dnd=false;
    ObjectGuid GetGUID()const{return guid;}
    WorldSession* GetSession()const{return session;}
    bool IsInWorld()const{return inWorld;}
    void SendDirectMessage(WorldPacket* p){sent.push_back(*p);}
    PlayerSocial* GetSocial()const{return social;}
    TeamId GetTeamId()const{return team;}
    bool IsVisibleGloballyFor(Player*)const{return visible;}
    bool isAFK()const{return afk;}
    bool isDND()const{return dnd;}
    uint32 GetZoneId()const{return 1;}
    uint8 GetLevel()const{return 70;}
    uint8 getClass()const{return 1;}
};
struct Sessions { std::map<uint32,WorldSession*> values;WorldSession* FindSession(uint32 n){auto p=values.find(n);return p==values.end()?nullptr:p->second;} } sessions;
auto* sWorldSessionMgr=&sessions;
enum Processing { PROCESS_INPLACE, PROCESS_THREADSAFE, PROCESS_THREADUNSAFE };
using OpcodeClient=uint16;
struct ClientOpcodeHandler { Processing ProcessingPlace; } contactHandler{PROCESS_THREADUNSAFE};
std::map<uint16, ClientOpcodeHandler*> opcodeTable{{0x66, &contactHandler}};
struct MapSessionFilter { WorldSession* m_pSession; bool Process(WorldPacket*); };
struct WorldSessionFilter { WorldSession* m_pSession; bool Process(WorldPacket*); };
struct SocialMgr
{
    std::map<ObjectGuid, PlayerSocial> m_socialMap;
    static void GetFriendInfo(Player*,ObjectGuid const&,FriendInfo&);
    void SendFriendStatus(Player*, FriendsResult, ObjectGuid const&, bool);
    void BroadcastToFriendListers(Player*, WorldPacket*) { assert(false); }
} socialMgr;
namespace ObjectAccessor
{
    Player* FindConnectedPlayer(ObjectGuid g)
    {
        auto* s=sessions.FindSession(cache.GetCharacterAccountIdByGuid(g));
        return s && s->player && s->player->guid==g?s->player:nullptr;
    }
    Player* FindPlayer(ObjectGuid g) { return FindConnectedPlayer(g); }
}
constexpr int CONFIG_ACCOUNT_WIDE_FRIENDS=1, CONFIG_ALLOW_TWO_SIDE_WHO_LIST=2;
struct World { bool enabled=true; bool getBoolConfig(int key)const{return key==CONFIG_ACCOUNT_WIDE_FRIENDS && enabled;} int getIntConfig(int)const{return 0;} } world;
auto* sWorld=&world;
auto* sSocialMgr=&socialMgr;
struct PlayerSocial
{
    ObjectGuid m_playerGUID;std::map<ObjectGuid,FriendInfo> m_playerSocialMap;
    ObjectGuid GetPlayerGUID()const{return m_playerGUID;}
    bool UsesAccountFriends()const;
    void ProjectAccountFriends(Player*,ObjectGuid excluded=ObjectGuid::Empty);
    void SendSocialList(Player*,uint32,ObjectGuid excluded=ObjectGuid::Empty);
    bool HasFriend(ObjectGuid const&)const;
    bool _checkContact(ObjectGuid g,uint8 flag)const { auto p=m_playerSocialMap.find(g);return p!=m_playerSocialMap.end()&&(p->second.Flags&flag); }
};
