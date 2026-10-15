"""Generate a focused C++ fixture from production validation/configuration code.
Usage: python audit_regressions.py path/to/output.cpp
Compile the generated file as C++20, then execute it. No database/server needed.
"""
from pathlib import Path
import re
import sys

module = Path(__file__).resolve().parents[1]
repo = module.parents[1]
compat = repo / "src/server/coa"
bridge = (module / "src/ManastormClientBridge.cpp").read_text(encoding="utf-8")
config = (module / "src/ManastormModuleConfig.cpp").read_text(encoding="utf-8")
donor = (compat / "AscensionManastorm.cpp").read_text(encoding="utf-8")
registration = donor[donor.index("void AddAscensionManastormItemScripts()") :]
assert re.findall(r"new\s+(\w+)\s*\(", registration) == ["item_ascension_manastorm_cache"]
assert "QueueAscensionManastormPacket" not in (compat / "AscensionCompat.cpp").read_text(encoding="utf-8")
assert "AddAscensionManastormScripts" not in (compat / "CoAScriptLoader.cpp").read_text(encoding="utf-8")

validation = bridge[bridge.index("    Ascension::Manastorm::Gadget const* FindGadget") :
                    bridge.index("    char const* ValidateEnter")]
configuration = config[config.index("namespace ManastormModuleConfig") :]
source = r"""
#include <array>
#include <cassert>
#include <cstdint>
#include <string_view>
#include <unordered_set>
#include <iostream>
using uint32 = std::uint32_t;
using Slots = std::array<uint32, 4>;
struct Player {
    std::unordered_set<uint32> learned;
    bool HasSpell(uint32 spell) const { return learned.contains(spell); }
};
struct ManastormMgr {
    bool active = false;
    static ManastormMgr& Instance() { static ManastormMgr mgr; return mgr; }
    bool GetRunFor(Player*) const { return active; }
};
struct SpellMgr { bool GetSpellInfo(uint32 spell) const { return spell != 0; } } spellMgr;
auto* sSpellMgr = &spellMgr;
enum class ManastormClientMode : uint32 { Reconstructed = 1, Ascension = 2 };
struct Config {
    bool enabled = true;
    uint32 mode = 2;
    template<class T> T GetOption(char const* key, T) const {
        return static_cast<T>(std::string_view(key) == "Manastorm.Enable" ? enabled : mode);
    }
} configMgr;
auto* sConfigMgr = &configMgr;
#define LOG_WARN(...) ((void)0)
#define LOG_ERROR(...) ((void)0)
#define LOG_INFO(...) ((void)0)
"""
source += '\n#include "' + (compat / "AscensionManastormGadgets.h").as_posix() + '"\n'
source += validation + configuration
source += r"""
struct WorldSession {};
struct WorldPacket {};
constexpr int SERVERHOOK_CAN_PACKET_RECEIVE = 0;
struct ServerScript {
    ServerScript(char const*, std::initializer_list<int>) {}
    virtual bool CanPacketReceive(WorldSession*, WorldPacket&) { return true; }
    virtual bool CanPacketReceive(WorldSession*, WorldPacket const&) { return true; }
};
struct ManastormClientBridge {
    int calls = 0;
    static ManastormClientBridge& Instance() { static ManastormClientBridge bridge; return bridge; }
    bool HandleIncoming(WorldSession*, WorldPacket const&) { ++calls; return true; }
};
"""
source += bridge[bridge.index("    class manastorm_native_packet_script") :
                 bridge.index("    class manastorm_native_group_script")]

source += r"""
int main() {
    manastorm_native_packet_script script;
    ServerScript& dispatch = script;
    WorldSession session;
    WorldPacket const packet;
    assert(!dispatch.CanPacketReceive(&session, packet));
    assert(ManastormClientBridge::Instance().calls == 1);
    Player player{{93431, 293437}};
    Slots slots{93431, 0, 0, 0};
    auto expect = [&](uint32 slot, uint32 spell, char const* error) {
        char const* result = ValidateSlot(&player, slots, slot, spell);
        assert(error ? result && std::string_view(result) == error : result == nullptr);
    };
    expect(0, 293437, nullptr); // Upgrade a rank in its own slot.
    expect(1, 293437, "SET_MANASTORM_LOADOUT_ALREADY_SET");
    expect(0, 93431, "SET_MANASTORM_LOADOUT_BAD_RANK");
    slots[0] = 293437;
    expect(0, 293437, "SET_MANASTORM_LOADOUT_ALREADY_SET");
    expect(4, 293437, "SET_MANASTORM_LOADOUT_OUT_OF_RANGE");
    expect(1, 0, "SET_MANASTORM_LOADOUT_BAD_SPELL");
    expect(1, 93433, "SET_MANASTORM_LOADOUT_NOT_KNOWN");
    expect(1, 93467, "SET_MANASTORM_LOADOUT_BAD_SPELL"); // Passive gadget.
    ManastormMgr::Instance().active = true;
    expect(0, 293437, "SET_MANASTORM_LOADOUT_ACTIVE_MANASTORM");
    using namespace ManastormModuleConfig;
    Load(false);
    assert(Enabled() && IsNativeClientMode());
    configMgr.mode = 2;
    Load(false);
    assert(Enabled() && IsNativeClientMode());
    configMgr.enabled = false;
    configMgr.mode = 1;
    Load(true);
    assert(Enabled() && IsNativeClientMode()); // Reload cannot strand a live run.
    Load(false);
    assert(!Enabled() && IsReconstructedClientMode());
    configMgr.enabled = true;
    configMgr.mode = 999;
    Load(false);
    assert(Enabled() && IsReconstructedClientMode());
    std::cout << "Ownership, loadout and configuration regressions passed\n";
}
"""
Path(sys.argv[1]).write_text(source, encoding="utf-8", newline="\n")
print("Ownership registration checks passed; generated", sys.argv[1])
