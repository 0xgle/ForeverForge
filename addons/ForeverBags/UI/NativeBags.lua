local _, FB = ...

FB.NativeBags = FB.NativeBags or {}
local N = FB.NativeBags

-- Mature bag replacements such as Bagnon integrate with the bag API itself.
-- On Classic Era the backpack button and the default bag key both eventually
-- call these global bag functions, so wrapping them is more reliable than
-- placing an invisible overlay over one specific Blizzard button.
local PLAYER_BAG_MAX = tonumber(NUM_BAG_SLOTS) or 4
local originals = N.originals or {}
local wrappers = N.wrappers or {}
N.originals = originals
N.wrappers = wrappers

local function Enabled()
    return not FB.settings or FB.settings.nativeBagIntegration ~= false
end

local function IsPlayerBag(id)
    id = tonumber(id)
    return id ~= nil and id >= 0 and id <= PLAYER_BAG_MAX
end

local function GetFrame()
    return FB:BuildMainFrame()
end

local function SetBagButtonState(open)
    open = open and true or false
    local backpack = _G.MainMenuBarBackpackButton or _G.BagBarBackpackButton or _G.BackpackButton
    if backpack and backpack.SetChecked then pcall(backpack.SetChecked, backpack, open) end

    -- Classic Era still exposes the equipped bag buttons under these names.
    -- Keep their checked state in sync with the combined ForeverBags window.
    for i = 0, PLAYER_BAG_MAX - 1 do
        local button = _G["CharacterBag" .. i .. "Slot"]
        if button and button.SetChecked then pcall(button.SetChecked, button, open) end
    end
end

local function ShowInventory()
    FB.currentView = "bags"
    FB.currentCategory = FB.currentCategory or "all"
    local f = GetFrame()
    if not f:IsShown() then f:Show() end
    FB:Refresh()
    SetBagButtonState(true)
end

local function HideInventory()
    if FB.frame and FB.frame:IsShown() then FB.frame:Hide() end
    SetBagButtonState(false)
end

local function ToggleInventory()
    local f = GetFrame()
    if f:IsShown() then HideInventory() else ShowInventory() end
end

local function CallOriginal(name, ...)
    local fn = originals[name]
    if type(fn) == "function" then return fn(...) end
end

local function Install(name, handler)
    if wrappers[name] and _G[name] == wrappers[name] then return true end
    local current = _G[name]
    if type(current) ~= "function" then return false end

    -- Capture the function that existed when we installed. If another bag addon
    -- is present and native integration is disabled, control is returned to it.
    originals[name] = current
    local wrapped = function(...)
        if Enabled() then
            return handler(...)
        end
        return CallOriginal(name, ...)
    end
    wrappers[name] = wrapped
    _G[name] = wrapped
    return true
end

function N:InstallBagAPIHooks()
    -- Backpack / all-bag entry points used by keybindings and Blizzard buttons.
    Install("ToggleBackpack", function() ToggleInventory() end)
    Install("OpenBackpack", function() ShowInventory() end)
    Install("CloseBackpack", function() HideInventory() end)
    Install("ToggleAllBags", function() ToggleInventory() end)
    Install("OpenAllBags", function() ShowInventory() end)
    Install("CloseAllBags", function() HideInventory() end)

    -- Individual equipped bag buttons. Bank/non-player bag IDs are left to the
    -- original Blizzard implementation.
    Install("ToggleBag", function(id, ...)
        if IsPlayerBag(id) then return ToggleInventory() end
        return CallOriginal("ToggleBag", id, ...)
    end)
    Install("OpenBag", function(id, ...)
        if IsPlayerBag(id) then return ShowInventory() end
        return CallOriginal("OpenBag", id, ...)
    end)
    Install("CloseBag", function(id, ...)
        if IsPlayerBag(id) then return HideInventory() end
        return CallOriginal("CloseBag", id, ...)
    end)
end

function N:HookMainFrame()
    local f = FB.frame
    if not f or self.frameHooked then return end
    self.frameHooked = true
    f:HookScript("OnShow", function() SetBagButtonState(true) end)
    f:HookScript("OnHide", function() SetBagButtonState(false) end)
end

function N:Refresh()
    self:InstallBagAPIHooks()
    self:HookMainFrame()
    if FB.frame then SetBagButtonState(FB.frame:IsShown()) end
end

FB:On("LOGIN", function()
    -- Main.lua builds the frame earlier in the LOGIN callback order.
    N:Refresh()
end)

FB:On("WORLD", function()
    -- Some Classic UI modules load/rebind their globals while entering world.
    -- Re-check once the world is ready; Install() is idempotent.
    C_Timer.After(0, function() N:Refresh() end)
end)

FB:On("SETTINGS_CHANGED", function()
    N:Refresh()
end)
