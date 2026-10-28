CLI_DESCRIPTION = """Exercise Bazaar Token purchases from the Vanity tab without building the server."""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
CONSTANTS = ("POINT_SPEND_REQUEST_SIZE", "VANITY_CURRENCY_DONATION_POINTS", "VANITY_CURRENCY_BAZAAR_TOKENS",
             "VANITY_BAZAAR_TOKEN_ITEM", "VANITY_FLAG_NOT_OFFERED", "REALM_TYPE_COUNT", "VANITY_CATEGORY_CONSUMABLE")


def constant(source, name):
    match = re.search(rf"^constexpr [^\n]*\b{name} = [^\n]*;$", source, re.M)
    if not match:
        raise ValueError(f"{name} is not defined")
    return match.group(0) + "\n"


def compile_and_run(code, prefix):
    compiler = shutil.which(os.environ.get("CXX", "g++"))
    if not compiler:
        raise RuntimeError("Set CXX to a C++20 compiler.")
    with tempfile.TemporaryDirectory(prefix=prefix) as directory:
        out = Path(directory)
        cpp, executable = out / "cases.cpp", out / "cases.exe"
        cpp.write_text(code, encoding="utf-8")
        subprocess.run([compiler, "-std=c++20", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)],
                       cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)


def check_patch_wire(source):
    code = r"""
#include <array>
#include <cassert>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>
using uint8=std::uint8_t; using uint16=std::uint16_t; using uint32=std::uint32_t;
struct Player {};
struct WorldPacket
{
    uint16 opcode; std::vector<uint8> bytes;
    WorldPacket(uint16 o, std::size_t) : opcode(o) {}
    WorldPacket& operator<<(uint32 v) { auto p=reinterpret_cast<uint8*>(&v); bytes.insert(bytes.end(), p, p+4); return *this; }
    WorldPacket& operator<<(std::string const& v) { bytes.insert(bytes.end(), v.begin(), v.end()); bytes.push_back(0); return *this; }
    WorldPacket& operator<<(char const* v) { return *this << std::string(v); }
};
WorldPacket sent(0, 0);
std::size_t SendRowPacket(Player*, WorldPacket const& packet) { sent=packet; return packet.bytes.size(); }
"""
    code += constant(source, "SMSG_PATCH_VANITY_COLLECTION")
    for name in ("VANITY_COLLECTION_DBC_FIELD_COUNT", "VANITY_COLLECTION_DESCRIPTION_FIELD",
                 "VANITY_COLLECTION_ADDITIONAL_TEXT_FIELD", "VANITY_COLLECTION_LEARNED_SPELL_FIELD"):
        match = re.search(rf"static constexpr uint32 {name} = \d+;", source)
        assert match, name
        code += match.group(0) + "\n"
    code += method(source, "struct VanityCollectionPatchRow {") + ";\n"
    code += method(source, "static std::size_t SendVanityCollectionRow(Player* player, VanityCollectionPatchRow const& row)")
    code += r"""
struct Reader
{
    std::vector<uint8> const& b; std::size_t pos=0;
    uint32 U32() { uint32 v; assert(pos+4<=b.size()); std::memcpy(&v, b.data()+pos, 4); pos+=4; return v; }
    std::string Str() { std::string s(reinterpret_cast<char const*>(b.data()+pos)); pos+=s.size()+1; assert(pos<=b.size()); return s; }
};
int main()
{
    VanityCollectionPatchRow row;
    for (uint32 i=0; i<VANITY_COLLECTION_DBC_FIELD_COUNT; ++i) row.Values[i]=1000+i;
    row.Artwork="art"; row.Description="desc"; row.AdditionalText="more";
    Player player;
    SendVanityCollectionRow(&player, row);
    assert(sent.opcode==0x573);
    // The client's 0x573 reader (FUN_101e55d0): u32 0..2, the artwork C string, u32 4..41, the description and
    // additional-text C strings, u32 learned spell, three more C strings it drops.
    Reader r{sent.bytes};
    for (uint32 i=0; i<3; ++i) assert(r.U32()==1000+i);
    assert(r.Str()=="art");
    for (uint32 i=4; i<42; ++i) assert(r.U32()==1000+i);
    assert(r.Str()=="desc" && r.Str()=="more");
    assert(r.U32()==1076);
    for (int i=0; i<3; ++i) assert(r.Str().empty());
    assert(r.pos==sent.bytes.size());
}
"""
    compile_and_run(code, "coa-vanity-patch-wire-")


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.parse_args()
    source = ROOT.joinpath("src/server/coa/AscensionCompat.cpp").read_text(encoding="utf-8")

    collect = method(source, "void CollectItem(Player *player, PlayerCollectionState &state, uint32 itemId,")
    assert "!IsConsumableVanityItem(_vanityItems.at(itemId))" in collect
    assert collect.count("SendVanityCollectionAdded(player, itemId);") == 2
    assert "IsConsumableVanityItem(itr->second)" in method(source, "void SendVanityCollection(Player *player,")
    added = method(source, "void SendVanityCollectionAdded(Player* player, uint32 itemId)")
    assert "SMSG_VANITY_COLLECTION_ADDED" in added and "CHAT_MSG_WHISPER, LANG_ADDON, player, player" in added
    assert constant(source, "VANITY_ITEM_LEARNED_EVENT").endswith('"ASCENSION_STORE_COLLECTION_ITEM_LEARNED";\n')
    assert "info.BazaarTokenCost = price->second.BazaarTokens;" in source
    assert "_rows.VanityCollections = LoadVanityCollectionPatchRows();" in source
    assert "bytes += SendVanityCollectionRow(player, row);" in source
    stream = method(source, "static std::vector<VanityCollectionPatchRow> LoadVanityCollectionPatchRows()")
    for field, column in (("DonationPoints", 4), ("SeasonalPoints", 5), ("BazaarTokens", 6)):
        assert f"row.Values[{column}] = price->second.{field};" in stream
    check_patch_wire(source)

    code = r"""
#include <algorithm>
#include <array>
#include <cassert>
#include <cstdint>
#include <cstring>
#include <map>
#include <memory>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <vector>
using uint8=std::uint8_t; using uint32=std::uint32_t; using uint64=std::uint64_t; using int32=std::int32_t;
#define LOG_DEBUG(...) do {} while (0)
#define LOG_INFO(...) do {} while (0)
namespace Acore
{
std::vector<std::string_view> Tokenize(std::string_view text, char separator, bool)
{
    std::vector<std::string_view> tokens;
    while (!text.empty())
    {
        std::size_t end = text.find(separator);
        if (end) tokens.push_back(text.substr(0, end));
        if (end == std::string_view::npos) break;
        text.remove_prefix(end + 1);
    }
    return tokens;
}
}
enum class AscensionCompatConfig { UNLOCK_ALL_VANITY, REALM_TYPE };
struct Config
{
    bool unlockAll=false; std::string realmType="live";
    template<class T> T GetConfigValue(AscensionCompatConfig key) const
    {
        if constexpr (std::is_same_v<T, bool>) { assert(key==AscensionCompatConfig::UNLOCK_ALL_VANITY); return unlockAll; }
        else { assert(key==AscensionCompatConfig::REALM_TYPE); return realmType; }
    }
} ascensionCompatConfig;
namespace AscensionCollectibles { constexpr std::array<uint32, 1> SigilVanityItems = { 600 }; }
struct WorldPacket
{
    std::vector<uint8> bytes; std::size_t cursor=0;
    template<class T> WorldPacket& operator<<(T v) { auto p=reinterpret_cast<uint8*>(&v); bytes.insert(bytes.end(), p, p+sizeof v); return *this; }
    template<class T> WorldPacket& operator>>(T& v) { assert(cursor+sizeof v<=bytes.size()); std::memcpy(&v, bytes.data()+cursor, sizeof v); cursor+=sizeof v; return *this; }
    std::size_t size() const { return bytes.size(); }
};
struct Session { std::vector<std::string> messages; uint32 GetAccountId() const { return 9; } };
struct ChatHandler
{
    Session* session;
    explicit ChatHandler(Session* s) : session(s) {}
    void SendSysMessage(std::string_view text) { session->messages.emplace_back(text); }
    template<class... Args> void PSendSysMessage(std::string_view text, Args...) { session->messages.emplace_back(text); }
};
enum InventoryResult { EQUIP_ERR_OK, EQUIP_ERR_INVENTORY_FULL };
using ItemPosCountVec=std::vector<int>;
constexpr uint8 NULL_BAG=0, NULL_SLOT=255;
struct Item { uint32 entry; bool bound=false; void SetBinding(bool value) { bound=value; } };
struct Player
{
    Session session; uint8 cls=10, race=1; bool full=false;
    std::map<uint32, uint32> bags; std::vector<Item> created; uint32 equipErrors=0, announced=0;
    Session* GetSession() { return &session; }
    uint8 getClass() const { return cls; }
    uint8 getRace() const { return race; }
    std::string GetName() const { return "Buyer"; }
    bool HasItemCount(uint32 item, uint32 count) const { auto itr=bags.find(item); return itr!=bags.end() && itr->second>=count; }
    void DestroyItemCount(uint32 item, uint32 count, bool) { assert(HasItemCount(item, count)); bags[item]-=count; }
    InventoryResult CanStoreNewItem(uint8 bag, uint8 slot, ItemPosCountVec&, uint32, uint32 count) const
    { assert(bag==NULL_BAG && slot==NULL_SLOT && count==1); return full ? EQUIP_ERR_INVENTORY_FULL : EQUIP_ERR_OK; }
    Item* StoreNewItem(ItemPosCountVec&, uint32 item, bool) { ++bags[item]; created.push_back({item}); return &created.back(); }
    void SendNewItem(Item*, uint32 count, bool, bool) { assert(count==1); ++announced; }
    void SendEquipError(InventoryResult result, void*, void*, uint32) { assert(result!=EQUIP_ERR_OK); ++equipErrors; }
};
struct Templates { std::unordered_set<uint32> known; Item const* GetItemTemplate(uint32 id) const { static Item row{}; return known.contains(id) ? &row : nullptr; } } templates;
auto sObjectMgr=&templates;
struct PlayerCollectionState { std::unordered_set<uint32> OwnedVanityItems; };
"""
    for name in CONSTANTS:
        code += constant(source, name)
    code += method(source, "struct VanityInfo {") + ";\n"
    code += method(source, "uint8 GetRealmTypeMask()") + "\n"
    code += r"""
struct Cosmetics
{
    std::unordered_map<uint32, VanityInfo> _vanityItems;
    std::shared_ptr<PlayerCollectionState> state=std::make_shared<PlayerCollectionState>();
    std::vector<std::pair<uint32, bool>> collected; std::vector<uint32> delivered; uint32 rejected=0;
    std::shared_ptr<PlayerCollectionState> GetState(Player*) { return state; }
    static bool IsWithheldVanityItem(uint32 itemId) { return itemId==700; }
    static bool IsBankVanityItem(uint32 itemId) { return itemId==800; }
    void RejectClientPacket(uint32 account, WorldPacket const&, std::string_view) { assert(account==9); ++rejected; }
    void DeliverVanityItem(Player*, uint32 itemId) { delivered.push_back(itemId); }
    void CollectItem(Player*, PlayerCollectionState& owner, uint32 itemId, bool notify, bool bound)
    { assert(&owner==state.get() && notify); collected.emplace_back(itemId, bound); }
"""
    for signature in ("void HandlePointSpendRequest(Player* player, WorldPacket& packet)",
                      "[[nodiscard]] static bool IsVanityItemOffered(Player* player, VanityInfo const& vanity)",
                      "void PurchaseVanityItemWithBazaarTokens(Player* player, uint32 itemId)",
                      "[[nodiscard]] static bool IsConsumableVanityItem(VanityInfo const& vanity)",
                      "void BuyConsumableVanityItem(Player* player, uint32 itemId, uint32 cost)"):
        code += method(source, signature) + "\n"
    code += r"""
};
constexpr uint32 TOKEN=VANITY_BAZAAR_TOKEN_ITEM, MOUNT=100, SCROLL=200, FREE=300, SEASONAL=400, ONLY_CLASS_9=500;
VanityInfo Row(uint32 cost, uint32 category=0, uint8 realms=1)
{
    VanityInfo info; info.BazaarTokenCost=cost; info.CategoryMask=category; info.RealmTypeMask=realms; return info;
}
WorldPacket Request(uint8 currency, uint32 item) { WorldPacket packet; packet << currency << item; return packet; }
struct Case
{
    Cosmetics cosmetics; Player player;
    Case()
    {
        cosmetics._vanityItems={{MOUNT, Row(35, 0x04000000)}, {SCROLL, Row(60, VANITY_CATEGORY_CONSUMABLE)}, {FREE, Row(0)},
            {SEASONAL, Row(10, 0, 2)}, {ONLY_CLASS_9, Row(10)}, {600, Row(10)}, {700, Row(10)}, {800, Row(10)}};
        cosmetics._vanityItems[ONLY_CLASS_9].ClassMask=uint64(1) << 8;
        templates.known={SCROLL};
        player.bags[TOKEN]=100;
    }
    void Buy(uint32 item, uint8 currency=VANITY_CURRENCY_BAZAAR_TOKENS)
    { WorldPacket packet=Request(currency, item); cosmetics.HandlePointSpendRequest(&player, packet); }
    uint32 Tokens() { return player.bags[TOKEN]; }
    std::string Said() { return player.session.messages.empty() ? "" : player.session.messages.back(); }
};
int main()
{
    { Case c; c.Buy(MOUNT); assert(c.Tokens()==65 && c.cosmetics.collected==(std::vector<std::pair<uint32, bool>>{{MOUNT, true}})); assert(c.Said().empty()); }
    { Case c; c.cosmetics.state->OwnedVanityItems.insert(MOUNT); c.Buy(MOUNT); assert(c.Tokens()==100 && c.cosmetics.collected.empty() && c.Said()=="You already own this item."); }
    { Case c; c.player.bags[TOKEN]=34; c.Buy(MOUNT); assert(c.Tokens()==34 && c.cosmetics.collected.empty() && c.Said()=="You do not have enough Bazaar Tokens."); }
    { Case c; c.Buy(FREE); assert(c.Tokens()==100 && c.Said()=="That item cannot be bought with Bazaar Tokens."); }
    for (uint32 item : {SEASONAL, ONLY_CLASS_9, 700u, 999u})
    { Case c; c.Buy(item); assert(c.Tokens()==100 && c.cosmetics.collected.empty() && c.Said()=="That item is not sold on this realm."); }
    { Case c; c.player.cls=9; c.Buy(ONLY_CLASS_9); assert(c.Tokens()==90); }
    { Case c; ascensionCompatConfig.realmType="live seasonal"; c.Buy(SEASONAL); ascensionCompatConfig.realmType="live"; assert(c.Tokens()==90); }
    { Case c; c.cosmetics._vanityItems[MOUNT].Flags=VANITY_FLAG_NOT_OFFERED; c.Buy(MOUNT); assert(c.Tokens()==100); }
    { Case c; c.cosmetics._vanityItems[MOUNT].RaceMask=2; c.Buy(MOUNT); assert(c.Tokens()==100); c.player.race=2; c.Buy(MOUNT); assert(c.Tokens()==65); }
    {
        Case c; ascensionCompatConfig.unlockAll=true;
        c.Buy(MOUNT); assert(c.Tokens()==100 && c.Said()=="You already own this item.");
        c.Buy(600); c.Buy(800); assert(c.Tokens()==80 && c.cosmetics.collected.size()==2);
        ascensionCompatConfig.unlockAll=false;
    }
    {
        Case c; c.cosmetics.state->OwnedVanityItems.insert(SCROLL);
        c.Buy(SCROLL); assert(c.player.bags[SCROLL]==1 && c.Tokens()==40 && c.player.announced==1 && c.player.created.back().bound);
        c.Buy(SCROLL); assert(c.player.bags[SCROLL]==1 && c.Tokens()==40 && c.Said()=="You do not have enough Bazaar Tokens.");
        assert(c.cosmetics.collected.empty());
    }
    { Case c; c.player.bags[TOKEN]=200; c.Buy(SCROLL); c.Buy(SCROLL); c.Buy(SCROLL); assert(c.player.bags[SCROLL]==3 && c.Tokens()==20 && c.cosmetics.collected.empty()); }
    { Case c; c.player.full=true; c.Buy(SCROLL); assert(c.Tokens()==100 && c.player.equipErrors==1 && !c.player.bags.contains(SCROLL)); }
    { Case c; templates.known.clear(); c.Buy(SCROLL); assert(c.Tokens()==100 && c.Said()=="Vanity item {} has no AzerothCore item template yet."); }
    { Case c; c.Buy(MOUNT, VANITY_CURRENCY_DONATION_POINTS); assert(c.cosmetics.delivered==std::vector<uint32>{MOUNT} && c.Tokens()==100); }
    { Case c; c.Buy(MOUNT, 1); assert(c.cosmetics.delivered.empty() && c.Tokens()==100 && c.Said().empty()); }
    { Case c; WorldPacket packet=Request(VANITY_CURRENCY_BAZAAR_TOKENS, MOUNT); packet << uint8(0); c.cosmetics.HandlePointSpendRequest(&c.player, packet); assert(c.cosmetics.rejected==1 && c.Tokens()==100); }
}
"""
    compile_and_run(code, "coa-vanity-purchase-")
    print("PASS: token purchases, ownership, price, offer gates, unlock-all, repeatable soulbound consumables, "
          "full bags, other currencies, malformed requests, the collection-added event and the price stream")


if __name__ == "__main__":
    main()
