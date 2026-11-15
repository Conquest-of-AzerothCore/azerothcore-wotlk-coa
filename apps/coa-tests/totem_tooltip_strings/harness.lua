local chunkPath = assert(arg[1], "chunk path")
local failures = 0

local function check(condition, message)
    if not condition then
        failures = failures + 1
        io.stderr:write("FAIL: " .. message .. "\n")
    end
end

local STANDARD_SPELLS = { 500260, 500263, 500299, 500547, 706805, 800319, 803931, 803932, 803933, 803934,
                          803935, 803936, 803937, 803938 }

local function newClient(isGuardian)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.SPELL_TOTEMS = "Tools: "
    env.BINDING_NAME_MULTICASTACTIONBUTTON3 = "Water Totem"
    env.COA_TOTEM_IDOL = "Idol"
    env.COA_TOTEM_NAME_REMAP = { [507082] = env.COA_TOTEM_IDOL }
    for _, id in ipairs(STANDARD_SPELLS) do
        env.COA_TOTEM_NAME_REMAP[id] = env.STANDARD
    end

    local mods = {}
    function mods:CoATotemRename(left, right, spellID)
        local lineText = left:GetText()
        if lineText:sub(1, #env.SPELL_TOTEMS) == env.SPELL_TOTEMS then
            if isGuardian and lineText == env.SPELL_TOTEMS .. env.BINDING_NAME_MULTICASTACTIONBUTTON3 then
                left:SetText(env.STANDARD)
                return
            end
            local rename = spellID and env.COA_TOTEM_NAME_REMAP[spellID]
            if rename then
                left:SetText(rename)
            end
        end
    end
    function mods:EmbedSpell(left)
        local lineText = left:GetText()
        if lineText:find("%b@@") then
            left:SetText(lineText)
        end
    end
    env.ModTooltipSetSpell = mods
    return env
end

local function newLine(text)
    local line = { text = text }
    function line:GetText() return self.text end
    function line:SetText(value) self.text = value end
    return line
end

local function hover(env, spellID, text)
    local line = newLine(text)
    local ok, err = pcall(function()
        for _, name in ipairs({ "CoATotemRename", "EmbedSpell" }) do
            env.ModTooltipSetSpell[name](env.ModTooltipSetSpell, line, nil, spellID)
        end
    end)
    return ok, line.text, err
end

local function runChunk(env)
    local loaded = assert(loadfile(chunkPath))
    setfenv(loaded, env)
    loaded()
end

local before = newClient(true)
local okBefore = hover(before, 500260, "Tools: Water Totem")
check(not okBefore, "a Guardian hovering a standard raises the nil lineText error without the chunk")

local guardian = newClient(true)
runChunk(guardian)
check(guardian.STANDARD == "Standard", "STANDARD is defined")
for _, id in ipairs(STANDARD_SPELLS) do
    check(guardian.COA_TOTEM_NAME_REMAP[id] == "Standard", "standard " .. id .. " maps to STANDARD")
end
check(guardian.COA_TOTEM_NAME_REMAP[507082] == "Idol", "the idol rename is untouched")

local ok, text, err = hover(guardian, 500260, "Tools: Water Totem")
check(ok, "a Guardian's standard tooltip no longer errors: " .. tostring(err))
check(text == "Standard", "a Guardian's standard tool line reads Standard, got " .. tostring(text))
ok, text = hover(guardian, 507082, "Tools: Water Totem")
check(ok and text == "Standard", "a Guardian's water idol tool line follows the Guardian rename")

local other = newClient(false)
runChunk(other)
ok, text = hover(other, 507082, "Tools: Water Totem")
check(ok and text == "Idol", "another class keeps the idol rename, got " .. tostring(text))
ok, text = hover(other, 500260, "Tools: Water Totem")
check(ok and text == "Standard", "another class sees standards renamed, got " .. tostring(text))

local localized = newClient(true)
localized.STANDARD = "Estandarte"
runChunk(localized)
check(localized.STANDARD == "Estandarte", "a client that defines STANDARD keeps its value")
runChunk(localized)
check(localized.COA_TOTEM_NAME_REMAP[500260] == "Estandarte", "running the chunk again changes nothing")

local noRemap = newClient(true)
noRemap.COA_TOTEM_NAME_REMAP = nil
local okNoRemap = pcall(runChunk, noRemap)
check(okNoRemap and noRemap.STANDARD == "Standard", "the chunk runs on a client without the remap table")

if failures > 0 then
    os.exit(1)
end
print("totem tooltip strings: all checks passed")
