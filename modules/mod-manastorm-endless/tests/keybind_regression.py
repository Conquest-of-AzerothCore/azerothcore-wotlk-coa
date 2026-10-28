"""Generate a Lua test from the actual patched UIParent stored in the overlay."""
import importlib.util
from pathlib import Path
import sys
base = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('patch', base/'client/build_keybind_patch.py')
module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
api = module.ArchiveAPI(Path(sys.argv[1]))
data = api.read(base/'client/patch-ZZ.MPQ', module.UI_MEMBER).decode('utf-8')
function = data[data.index('function ToggleLFDParentFrame()'):data.index('function ToggleLFRParentFrame()')]

queue_source = module.load_queue_patch().decode('utf-8')
assert 'name="$parentRewardDiv" parentKey="RewardDiv"' in queue_source
assert 'name="$parentRewardDiv" file="Interface\\Common\\ui-tooltipdivider-transparent"' not in queue_source
test = r"""
local visible, level, active, eligible = false, 10, true, false
local shown, hidden, checks = 0, 0, 0
SHOW_LFD_LEVEL = 15
AscensionPVEFrame = {IsVisible = function() return visible end}
AscensionLFGFrame = {ShowFrame = function(self,name)
    assert(name == "AscensionPVEFrame"); shown = shown + 1
end}
function HideUIPanel(frame) assert(frame == AscensionLFGFrame); hidden = hidden + 1 end
C_Player = {GetLevel = function() return level end}
C_Manastorm = {IsInManastorm = function() return active end,
    CanEnter = function() checks = checks + 1; return eligible end}
""" + function + r"""
ToggleLFDParentFrame()
assert(shown == 1 and checks == 0) -- Active level-10 player can reopen despite CanEnter=false.
visible = true; ToggleLFDParentFrame(); assert(hidden == 1)
visible = false; active = false; ToggleLFDParentFrame(); assert(shown == 1)
eligible = true; ToggleLFDParentFrame(); assert(shown == 2)
eligible = false; level = 15; ToggleLFDParentFrame(); assert(shown == 3)
print("Active-run I-key reopening and existing toggle/admission behavior passed")
"""
Path(sys.argv[2]).write_text(test,encoding='utf-8')
