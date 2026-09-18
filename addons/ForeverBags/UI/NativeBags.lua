local _, FB = ...

FB.NativeBags = FB.NativeBags or {}
local N = FB.NativeBags

N.hooked = N.hooked or false
N.containerHooks = N.containerHooks or false
N.hiddenParent = N.hiddenParent or nil

local function Enabled()
    return not FB.settings or FB.settings.nativeBagIntegration ~= false
end

local function ToggleForeverBags()
    if not Enabled() then return end
    FB:Debounce("native-bag-toggle", 0, function()
        if not Enabled() then return end
        FB.currentView = "bags"
        FB.currentCategory = FB.currentCategory or "all"
        FB:Toggle()
    end)
end

local function IsNestedToggle()
    -- ToggleAllBags/ToggleBackpack/ToggleBag can call one another. Rather than
    -- duplicating Blizzard's call graph, collapse all hooks into one zero-delay
    -- toggle with FB:Debounce. This helper remains for future branch quirks.
    return false
end

local function HookGlobal(name)
    if type(_G[name]) ~= "function" then return end
    hooksecurefunc(name, function()
        if not IsNestedToggle() then ToggleForeverBags() end
    end)
end

local function EnsureHiddenParent()
    if N.hiddenParent then return N.hiddenParent end
    local parent = ContainerFrameContainer or UIParent
    local hidden = CreateFrame("Frame", "ForeverBagsHiddenContainerParent", parent)
    hidden:SetAllPoints(parent)
    hidden:Hide()
    N.hiddenParent = hidden
    return hidden
end

local function ShouldOwnBag(bag)
    return Enabled() and FB.API and FB.API:IsPlayerContainer(bag)
end

local function HookContainerFrames()
    if N.containerHooks then return end
    N.containerHooks = true

    local hidden = EnsureHiddenParent()
    local normalParent = ContainerFrameContainer or UIParent
    local count = tonumber(NUM_CONTAINER_FRAMES) or 13

    for i = 1, count do
        local frame = _G["ContainerFrame" .. i]
        if frame and frame.SetID then
            hooksecurefunc(frame, "SetID", function(self, bag)
                if InCombatLockdown and InCombatLockdown() then return end
                if ShouldOwnBag(tonumber(bag)) then
                    if self:GetParent() ~= hidden then self:SetParent(hidden) end
                elseif self:GetParent() == hidden then
                    self:SetParent(normalParent)
                end
            end)
        end
    end
end

function N:ApplyContainerOwnership()
    if not self.containerHooks then return end
    if InCombatLockdown and InCombatLockdown() then return end

    local hidden = EnsureHiddenParent()
    local normalParent = ContainerFrameContainer or UIParent
    local count = tonumber(NUM_CONTAINER_FRAMES) or 13

    for i = 1, count do
        local frame = _G["ContainerFrame" .. i]
        if frame then
            local bag = frame:GetID()
            if ShouldOwnBag(tonumber(bag)) then
                if frame:GetParent() ~= hidden then frame:SetParent(hidden) end
            elseif frame:GetParent() == hidden then
                frame:SetParent(normalParent)
            end
        end
    end
end

function N:Install()
    if self.hooked then
        self:ApplyContainerOwnership()
        return
    end
    self.hooked = true

    -- These are post-hooks only; Blizzard keeps ownership of its protected code.
    HookGlobal("ToggleAllBags")
    HookGlobal("ToggleBackpack")
    HookGlobal("ToggleBag")

    HookContainerFrames()
    self:ApplyContainerOwnership()
end

FB:On("LOGIN", function()
    N:Install()
end)

FB:On("WORLD", function()
    C_Timer.After(0, function()
        N:Install()
        N:ApplyContainerOwnership()
    end)
end)

FB:On("SETTINGS_CHANGED", function()
    N:ApplyContainerOwnership()
end)

FB:On("PLAYER_REGEN_ENABLED", function()
    N:ApplyContainerOwnership()
end)
