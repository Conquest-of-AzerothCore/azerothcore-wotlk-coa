import csv
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
method = runpy.run_path(str(HERE.parent / "client_compat/run.py"))["method"]
SATCHEL = 800901


def snapshot_row(entry):
    archive = zipfile.ZipFile(sorted((ROOT / "data/coa-world").glob("coa-world-*.zip"))[-1])

    def table(name):
        return archive.read(next(p for p in archive.namelist() if p.rsplit("/", 1)[-1] == name + ".sql")).decode()

    data = table("item_template")
    columns = re.findall(r"^  `([^`]+)`", data, re.M)
    match = re.search(r"\(" + str(entry) + ",", data)
    end = min(p for p in (data.find("),(", match.start()), data.find(");", match.start())) if p >= 0)
    values = next(csv.reader([data[match.start() + 1:end]], quotechar="'", escapechar="\\"))
    loot = re.findall(r"\(" + str(entry) + r",\d+,", table("item_loot_template"))
    return dict(zip(columns, values)), loot


def check_snapshot():
    row, loot = snapshot_row(SATCHEL)
    assert row["name"] == "Boss Blitz Gold Satchel (500)" and row["description"] == "Contains 500 gold."
    assert int(row["Flags"]) & 4 and not loot
    assert (row["minMoneyLoot"], row["maxMoneyLoot"], row["spellid_1"]) == ("0", "0", "0")


def check_payout():
    source = (ROOT / "src/server/coa/AscensionGoldSatchels.cpp").read_text(encoding="utf-8")
    loader = (ROOT / "src/server/coa/CoAScriptLoader.cpp").read_text(encoding="utf-8")
    assert loader.count("AddSC_AscensionGoldSatchels();") == 2
    assert "PLAYERHOOK_ON_BEFORE_OPEN_ITEM" in source
    code = "#include <array>\n#include <cassert>\n#include <cstdint>\n#include <vector>\n"
    code += r'''
using uint8=std::uint8_t;using uint32=std::uint32_t;using int32=std::int32_t;
constexpr uint32 GOLD=10000, MAX_MONEY_AMOUNT=0x7FFFFFFF-1;
enum InventoryResult {EQUIP_ERR_NONE=0,EQUIP_ERR_TOO_MUCH_GOLD=1};
enum Opcodes {SMSG_LOOT_MONEY_NOTIFY=0x163};
struct WorldPacket
{
    uint32 opcode;std::vector<uint32> fields;
    WorldPacket(Opcodes op,uint32):opcode(op){}
    WorldPacket& operator<<(uint32 value){fields.push_back(value);return *this;}
    WorldPacket& operator<<(uint8 value){fields.push_back(value);return *this;}
};
struct Item {uint32 entry;uint32 count=1;uint32 GetEntry()const{return entry;}};
struct Player
{
    uint32 money=0;std::vector<InventoryResult> errors;std::vector<WorldPacket> packets;
    void SendEquipError(InventoryResult error,Item*,Item*){errors.push_back(error);}
    bool ModifyMoney(int32 amount)
    {
        if (money>=uint32(MAX_MONEY_AMOUNT-amount)){errors.push_back(EQUIP_ERR_TOO_MUCH_GOLD);return false;}
        money+=uint32(amount);return true;
    }
    void DestroyItemCount(Item* item,uint32& count,bool){item->count-=count;}
    void SendDirectMessage(WorldPacket const* packet){packets.push_back(*packet);}
};
'''
    code += source[source.index("struct GoldSatchel"):source.index("class ascension_gold_satchel_open")]
    code += "struct OpenHook {" + method(source, "bool OnPlayerBeforeOpenItem(").replace(" override", "") + "};\n"
    code += r'''
int main()
{
    OpenHook open;
    {
        Player p;p.money=123;Item satchel{800901};
        assert(!open.OnPlayerBeforeOpenItem(&p,&satchel));
        assert(p.money==123+500*GOLD && satchel.count==0);
        assert(p.packets.size()==1 && p.packets[0].opcode==SMSG_LOOT_MONEY_NOTIFY);
        assert(p.packets[0].fields==std::vector<uint32>({500*GOLD,1}));
        assert(p.errors==std::vector<InventoryResult>({EQUIP_ERR_NONE}));
    }
    {
        Player p;p.money=MAX_MONEY_AMOUNT-100*GOLD;Item satchel{800901};
        assert(!open.OnPlayerBeforeOpenItem(&p,&satchel));
        assert(p.money==MAX_MONEY_AMOUNT-100*GOLD && satchel.count==1 && p.packets.empty());
        assert(p.errors==std::vector<InventoryResult>({EQUIP_ERR_NONE,EQUIP_ERR_TOO_MUCH_GOLD}));
    }
    for (uint32 entry : {800902u,1u})
    {
        Player p;Item other{entry};
        assert(open.OnPlayerBeforeOpenItem(&p,&other));
        assert(!p.money && other.count==1 && p.errors.empty() && p.packets.empty());
    }
    Player p;assert(open.OnPlayerBeforeOpenItem(&p,nullptr));
}
'''
    compiler = shutil.which(os.environ.get("CXX", "g++"))
    assert compiler, "Set CXX to a C++17 compiler."
    with tempfile.TemporaryDirectory(prefix="coa-gold-satchel-") as directory:
        out = Path(directory)
        cpp, exe = out / "satchel.cpp", out / "satchel.exe"
        cpp.write_text(code, encoding="utf-8")
        subprocess.run([compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror", str(cpp), "-o", str(exe)],
                       cwd=out, check=True)
        subprocess.run([str(exe)], cwd=out, check=True)


def main():
    check_snapshot()
    check_payout()
    print("PASS: satchel 800901 opens for exactly 500 gold, is consumed, stays at the gold cap, leaves other "
          "items alone")


if __name__ == "__main__":
    main()
