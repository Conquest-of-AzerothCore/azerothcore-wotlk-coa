local directory = assert(arg[1], "chunk directory")
local TOKEN = "MANASTORM_UI_FIXES"
local failures = 0

local function check(condition, message)
    if not condition then
        failures = failures + 1
        io.stderr:write("FAIL: " .. message .. "\n")
    end
end

local function recorder(log, name, result)
    return function(...)
        table.insert(log, name)
        return result
    end
end

local function newEnvironment(addonLoaded)
    local log = {}
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.log = log
    env.manastorm = { inRun = false, levels = nil, available = {}, unavailable = {} }

    env.C_TrackerHeader = { Show = recorder(log, "banner") }
    env.SHOW_LFD_LEVEL = 10
    env.UNIT_LEVEL_TEMPLATE = "Level %d"
    env.CANNOT_ENTER_MANASTORM = "Cannot enter"
    env.ENTER_MANASTORM_SOLO = "Enter"
    env.Enum = { ItemQuality = { Poor = 0, Epic = 4 } }
    env.QUICKSLOT_QUALITY_BORDER_ATLAS = { [0] = "poor-border", [4] = "epic-border" }
    env.ScrollListMixin = { UpdateType = { Always = 1 } }
    env.tContains = function(list, item)
        for _, value in ipairs(list) do
            if value == item then
                return true
            end
        end
        return false
    end
    env.HideUIPanel = recorder(log, "hide panel")
    env.AscensionPVEFrame = { IsVisible = function() return false end }
    env.AscensionLFGFrame = { ShowFrame = recorder(log, "show group finder") }
    env.C_Player = { GetLevel = function() return 5 end }
    env.C_Manastorm = {
        IsInManastorm = function() return env.manastorm.inRun end,
        CanEnter = function() return false end,
        GetEnterableLevels = function() return env.manastorm.levels end,
        GetAvailableLoadoutSpells = function() return env.manastorm.available, env.manastorm.unavailable end,
        Enter = recorder(log, "enter"),
    }
    env.ManastormUtil = {
        GetManastormType = function() return "SOLO" end,
        GetRewardVisibilityContext = function() return "context" end,
    }
    env.ToggleLFDParentFrame = recorder(log, "stock keybind")

    local frames = {}
    env.CreateFrame = function()
        local frame = { events = {} }
        function frame:RegisterEvent(event) self.events[event] = true end
        function frame:UnregisterEvent(event) self.events[event] = nil end
        function frame:SetScript(_, handler) self.onEvent = handler end
        table.insert(frames, frame)
        return frame
    end
    env.frames = frames
    env.IsAddOnLoaded = function(name) return addonLoaded and name == "Ascension_Manastorm" end

    local function text()
        return {
            value = nil,
            SetText = function(self, value) self.value = value end,
            SetFormattedText = function(self, pattern, ...) self.value = pattern:format(...) end,
        }
    end

    env.ManastormQueueMixin = {
        RefreshAvailableLevels = recorder(log, "stock refresh"),
        SelectHighestLevel = recorder(log, "stock select"),
        HideLevelSelect = recorder(log, "stock hide select"),
        EnterQueue = recorder(log, "stock enter queue"),
        UpdateQueueButton = recorder(log, "stock queue button"),
        UpdateRewards = recorder(log, "update rewards"),
    }
    local queue = {
        IsVisible = function() return true end,
        RightPanel = {
            LevelSelect = {
                Hide = recorder(log, "hide level select"),
                ScrollList = {
                    RefreshScrollFrame = recorder(log, "refresh list"),
                    SetSelectedIndex = recorder(log, "select index"),
                },
            },
            LevelDropDown = { Text = text() },
            EnterButton = {
                SetText = function(self, value) self.label = value end,
                Disable = function(self) self.enabled = false end,
                SetEnabled = function(self, value) self.enabled = value end,
                enabled = true,
            },
        },
    }
    for name, fn in pairs(env.ManastormQueueMixin) do
        queue[name] = fn
    end
    env.ManastormQueueFrame = queue
    env.ManastormQueueFrameRewardDiv = { divider = true }

    env.ItemIconTemplateMixin = { SetItem = function(self) self.item = nil end }
    env.ManastormPotentialRewardMixin = { SetItem = recorder(log, "stock set item") }
    for index = 1, 3 do
        env["ManastormQueueFrameReward" .. index] = {
            SetItem = env.ManastormPotentialRewardMixin.SetItem,
            SetBorderAtlas = function(self, atlas) self.border = atlas end,
            SetOverlayAtlas = function(self, atlas) self.overlay = atlas end,
            UpdateRewardVisibility = recorder(log, "reward visibility"),
        }
    end

    env.ManastormLoadoutFlyoutMixin = { RefreshSpells = recorder(log, "stock refresh spells") }
    env.ManastormLoadoutFlyoutFrame = {
        RefreshSpells = env.ManastormLoadoutFlyoutMixin.RefreshSpells,
        buttonPool = { ReleaseAll = recorder(log, "release buttons") },
        Hide = recorder(log, "hide flyout"),
    }
    return env
end

local function logged(env, name)
    for _, entry in ipairs(env.log) do
        if entry == name then
            return true
        end
    end
    return false
end

local function run(mask, addonLoaded)
    local path = string.format("%s/chunk-%02d.lua", directory, mask)
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a")
    file:close()

    local env = newEnvironment(addonLoaded)
    local stock = {
        keybind = env.ToggleLFDParentFrame,
        select = env.ManastormQueueMixin.SelectHighestLevel,
        refreshSpells = env.ManastormLoadoutFlyoutMixin.RefreshSpells,
    }
    local compiled, err = loadstring(source)
    check(compiled ~= nil, string.format("mask %d compiles inside the client's formatter signature: %s", mask, tostring(err)))
    if not compiled then
        return
    end
    setfenv(compiled, env)
    local before, middle, after = compiled()
    check(type(before) == "function" and type(after) == "function",
        string.format("mask %d keeps the formatter returning functions", mask))

    if not addonLoaded and mask >= 2 then
        local loader = env.frames[#env.frames]
        check(loader and loader.events.ADDON_LOADED, string.format("mask %d waits for the addon", mask))
        check(env.ManastormQueueFrame.RewardDiv == nil, "nothing is patched before the addon loads")
        loader.onEvent(loader, "ADDON_LOADED", "SomeOtherAddon")
        check(loader.events.ADDON_LOADED, "other addons do not trigger the fixes")
        loader.onEvent(loader, "ADDON_LOADED", "Ascension_Manastorm")
        check(not loader.events.ADDON_LOADED, "the loader unregisters once applied")
    end

    env.C_TrackerHeader:Show("ChallengeCriteriaSuccess", "Partner Up!", "Done: " .. TOKEN)
    check(not logged(env, "banner"), string.format("mask %d hides its trigger banner", mask))
    env.C_TrackerHeader:Show("ChallengeCriteriaSuccess", "Partner Up!", "Kill 10 boars")
    check(logged(env, "banner"), string.format("mask %d leaves real banners alone", mask))

    env.manastorm.inRun = true
    env.ToggleLFDParentFrame()
    if mask % 2 == 1 then
        check(logged(env, "show group finder"), "fix 1 opens the group finder inside a run")
        check(not logged(env, "stock keybind"), "fix 1 replaces the keybind handler")
    else
        check(env.ToggleLFDParentFrame == stock.keybind, string.format("mask %d keeps the stock keybind", mask))
    end
    env.manastorm.inRun = false

    local queue = env.ManastormQueueFrame
    if math.floor(mask / 2) % 2 == 1 then
        check(queue.RewardDiv == env.ManastormQueueFrameRewardDiv, "fix 2 sets the reward divider key")
        check(logged(env, "update rewards"), "fix 2 re-anchors a visible queue panel")
    else
        check(queue.RewardDiv == nil, string.format("mask %d leaves the reward divider key unset", mask))
    end

    if math.floor(mask / 4) % 2 == 1 then
        env.manastorm.levels = nil
        queue:SelectHighestLevel()
        check(queue.selectedLevel == nil, "fix 4 tolerates a nil level list")
        check(queue.RightPanel.EnterButton.enabled == false, "fix 4 disables Enter with no level")
        check(queue.RightPanel.LevelDropDown.Text.value == "", "fix 4 blanks the level dropdown")
        queue:HideLevelSelect()
        check(queue.RightPanel.LevelDropDown.Text.value == "", "fix 4 never formats a nil level")
        queue:EnterQueue()
        check(not logged(env, "stock enter queue"), "fix 4 never enters without a level")

        env.manastorm.levels = { 12, 10 }
        queue:RefreshAvailableLevels()
        check(queue.selectedLevel == 12, "fix 4 selects the highest enterable level")
        check(queue.RightPanel.LevelDropDown.Text.value == "Level 12", "fix 4 shows the selected level")
        queue:EnterQueue()
        check(logged(env, "stock enter queue"), "fix 4 keeps the stock enter path with a level")
        queue:UpdateQueueButton()
        check(logged(env, "stock queue button"), "fix 4 keeps the stock queue button with a level")

        local reward = env.ManastormQueueFrameReward2
        reward:SetItem(12345, 1)
        check(reward.itemID == 12345 and reward.border == "poor-border" and reward.overlay == "poor-border",
            "fix 4 borders an uncached reward as poor quality")
        check(env.ManastormPotentialRewardMixin.SetItem == reward.SetItem, "fix 4 patches the mixin and live buttons")
    else
        check(env.ManastormQueueMixin.SelectHighestLevel == stock.select, string.format("mask %d keeps the stock queue", mask))
    end

    local flyout = env.ManastormLoadoutFlyoutFrame
    if math.floor(mask / 8) % 2 == 1 then
        flyout:RefreshSpells()
        check(logged(env, "hide flyout") and not logged(env, "stock refresh spells"), "fix 8 hides an empty flyout")
        env.manastorm.available = { 1001 }
        flyout:RefreshSpells()
        check(logged(env, "stock refresh spells"), "fix 8 keeps the stock grid when spells exist")
    else
        check(env.ManastormLoadoutFlyoutMixin.RefreshSpells == stock.refreshSpells,
            string.format("mask %d keeps the stock flyout", mask))
    end
end

for mask = 0, 15 do
    run(mask, true)
    run(mask, false)
end

do
    local file = assert(io.open(directory .. "/fel-window-chunk.lua", "rb"))
    local source = file:read("*a")
    file:close()
    local compiled, err = loadstring(source)
    check(compiled ~= nil, "the Fel Commutation window compiles inside the shared formatter: " .. tostring(err))
    if compiled then
        local log = {}
        local env = setmetatable({}, { __index = _G })
        env._G = env
        env.C_TrackerHeader = { Show = recorder(log, "banner") }
        setfenv(compiled, env)
        pcall(compiled)
        check(env.AscensionClientLuaTokens and env.AscensionClientLuaTokens.FEL_COMMUTATION_WINDOW,
            "the Fel Commutation token is registered with the banner filter")
        env.C_TrackerHeader:Show("ChallengeCriteriaSuccess", "Partner Up!", "Done: FEL_COMMUTATION_WINDOW")
        check(#log == 0, "the Fel Commutation trigger banner is hidden")
    end
end

if failures > 0 then
    os.exit(1)
end
print("manastorm_ui_fixes lua: OK")
