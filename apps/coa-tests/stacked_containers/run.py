CLI_DESCRIPTION = """Exercise the native item loot-release branch without a server build."""

import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from source_paths import git_source  # noqa: E402


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]


def main():
    parser = argparse.ArgumentParser(description=CLI_DESCRIPTION)
    parser.add_argument("--source-ref", help="Read the loot-release branch from a local Git ref.")
    args = parser.parse_args()
    path = "src/server/game/Handlers/LootHandler.cpp"
    source = (git_source(["git", "show", f"{args.source_ref}:{path}"], cwd=ROOT).decode()
              if args.source_ref else ROOT.joinpath(path).read_text(encoding="utf-8"))
    release = method(source, "void WorldSession::DoLootRelease(")
    code = r"""
#include <algorithm>
#include <cassert>
#include <cstdint>
using uint32=std::uint32_t;
constexpr uint32 ITEM_FLAG_HAS_LOOT=4, ITEM_FLAG_IS_PROSPECTABLE=0x40000, ITEM_FLAG_IS_MILLABLE=0x20000000;
struct Guid { bool IsItem() const { return true; } };
struct Loot
{
    bool empty=false;
    bool isLooted() const { return empty; }
    void clear() { empty=true; }
};
struct ItemTemplate
{
    uint32 Flags=ITEM_FLAG_HAS_LOOT;
    bool HasFlag(uint32 flag) const { return (Flags&flag)!=0; }
};
struct Item
{
    Loot loot;
    ItemTemplate proto;
    uint32 count=20;
    bool m_lootGenerated=true;
    ItemTemplate const* GetTemplate() const { return &proto; }
    uint32 GetCount() const { return count; }
    Guid GetGUID() const { return {}; }
    uint32 GetBagSlot() const { return 0; }
    uint32 GetSlot() const { return 7; }
};
struct Storage
{
    bool stored=true;
    void RemoveStoredLoot(Guid) { stored=false; }
} storage;
Storage* sLootItemStorage=&storage;
struct Player
{
    Item item;
    bool changed=false;
    Item* GetItemByGuid(Guid) { return item.count ? &item : nullptr; }
    void DestroyItem(uint32 bag,uint32 slot,bool update)
    {
        assert(bag==0 && slot==7 && update);
        item.count=0; changed=true; storage.stored=false;
    }
    void DestroyItemCount(Item* target,uint32& count,bool update)
    {
        assert(target==&item && update);
        uint32 removed=std::min(count,item.count);
        item.count-=removed; count-=removed; changed=true;
    }
};
void Release(Player* player)
{
    Guid lguid;
    Loot* loot=nullptr;
    if (false) {}
"""
    code += method(release, "else if (lguid.IsItem())")
    code += r"""
    (void)loot;
}
int main()
{
    Player player;
    Release(&player); // Closing an unfinished cache retains its existing loot.
    assert(player.item.count==20 && player.item.m_lootGenerated && storage.stored && !player.changed);
    for (uint32 remaining=20; remaining>0; --remaining)
    {
        player.item.loot.empty=true; // This cache's reward has been collected.
        Release(&player);
        assert(player.item.count==remaining-1 && player.changed && !storage.stored);
        if (remaining>1)
        {
            assert(!player.item.m_lootGenerated);
            // The next open can generate and persist a fresh loot roll.
            player.item.m_lootGenerated=storage.stored=true;
            player.item.loot.empty=false;
        }
    }
    Release(&player); // Missing/consumed inventory GUID is harmless.
    for (uint32 flag : {ITEM_FLAG_IS_PROSPECTABLE,ITEM_FLAG_IS_MILLABLE})
    {
        Player materials;
        materials.item.proto.Flags=flag;
        Release(&materials);
        assert(materials.item.count==15 && !materials.item.m_lootGenerated && materials.item.loot.empty);
    }
    Player disenchant;
    disenchant.item.proto.Flags=0;
    disenchant.item.count=1;
    Release(&disenchant);
    assert(disenchant.item.count==0);
}
"""
    compiler = shutil.which(os.environ.get("CXX", "g++"))
    if not compiler:
        raise RuntimeError("Set CXX to a C++17 compiler.")
    with tempfile.TemporaryDirectory(prefix="coa-stacked-containers-") as directory:
        out = Path(directory)
        cpp, executable = out / "cases.cpp", out / "cases.exe"
        cpp.write_text(code, encoding="utf-8")
        subprocess.run([compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(executable)],
                       cwd=out, check=True, timeout=60)
        subprocess.run([str(executable)], cwd=out, check=True, timeout=15)
    print("PASS: twenty individual cache opens, unfinished loot, storage reset, prospecting, milling, disenchanting")


if __name__ == "__main__":
    main()
