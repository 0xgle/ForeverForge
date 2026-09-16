local _, FB = ...
FB.SettingsUI = FB.SettingsUI or {}
local S = FB.SettingsUI

local function MakePanel(parent)
    local f = CreateFrame("Frame", "ForeverBagsSettingsFrame", parent or UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(390, 360)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    FB.Media:SetBackdrop(f, 0.98)
    f:Hide()
    table.insert(UISpecialFrames, "ForeverBagsSettingsFrame")
    return f
end

local function MakeTextButton(parent, text, width)
    local b = CreateFrame("Button", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
    b:SetSize(width or 90, 28)
    FB.Media:SetButtonBackdrop(b, false)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("CENTER")
    b.text:SetText(text)
    b:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.15,0.85,1,1) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.42,0.34,0.2,0.9) end)
    return b
end

function S:Build()
    if self.frame then return self.frame end
    local f = MakePanel(UIParent)
    self.frame = f

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText(FB.L.SETTINGS or "Settings")
    title:SetTextColor(1,0.82,0.35)

    local close = MakeTextButton(f, "×", 32)
    close:SetPoint("TOPRIGHT", -12, -12)
    close:SetScript("OnClick", function() f:Hide() end)

    local function row(label, y, minusFn, plusFn, valueFn)
        local t = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        t:SetPoint("TOPLEFT", 22, y)
        t:SetText(label)
        local minus = MakeTextButton(f, "−", 34); minus:SetPoint("TOPRIGHT", -130, y+5)
        local value = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        value:SetPoint("TOPRIGHT", -80, y-3); value:SetWidth(44); value:SetJustifyH("CENTER")
        local plus = MakeTextButton(f, "+", 34); plus:SetPoint("TOPRIGHT", -25, y+5)
        local function refresh() value:SetText(valueFn()) end
        minus:SetScript("OnClick", function() minusFn(); refresh(); FB:Fire("SETTINGS_CHANGED") end)
        plus:SetScript("OnClick", function() plusFn(); refresh(); FB:Fire("SETTINGS_CHANGED") end)
        refresh()
    end

    row("UI scale", -72,
        function() FB.settings.scale = math.max(0.75, math.floor((FB.settings.scale - 0.05)*100+0.5)/100) end,
        function() FB.settings.scale = math.min(1.35, math.floor((FB.settings.scale + 0.05)*100+0.5)/100) end,
        function() return string.format("%.2f", FB.settings.scale) end)
    row("Columns", -116,
        function() FB.settings.columns = math.max(7, FB.settings.columns - 1) end,
        function() FB.settings.columns = math.min(16, FB.settings.columns + 1) end,
        function() return tostring(FB.settings.columns) end)
    row("Item size", -160,
        function() FB.settings.iconSize = math.max(34, FB.settings.iconSize - 2) end,
        function() FB.settings.iconSize = math.min(54, FB.settings.iconSize + 2) end,
        function() return tostring(FB.settings.iconSize) end)

    local section = MakeTextButton(f, "", 170)
    section:SetPoint("TOPLEFT", 22, -208)
    local function updateSection()
        section.text:SetText((FB.settings.sectioned and "✓ " or "") .. "Sectioned view")
    end
    section:SetScript("OnClick", function() FB.settings.sectioned = not FB.settings.sectioned; updateSection(); FB:Fire("SETTINGS_CHANGED") end)
    updateSection()

    local empty = MakeTextButton(f, "", 170)
    empty:SetPoint("TOPLEFT", 198, -208)
    local function updateEmpty()
        empty.text:SetText((FB.settings.showEmptySlots and "✓ " or "") .. "Show free slots")
    end
    empty:SetScript("OnClick", function() FB.settings.showEmptySlots = not FB.settings.showEmptySlots; updateEmpty(); FB:Fire("SETTINGS_CHANGED") end)
    updateEmpty()

    local reset = MakeTextButton(f, "Reset window", 140)
    reset:SetPoint("BOTTOMLEFT", 22, 22)
    reset:SetScript("OnClick", function()
        if FB.frame then
            FB.frame:ClearAllPoints(); FB.frame:SetPoint("CENTER")
            FB.settings.windowPoint = nil
        end
    end)

    local bind = MakeTextButton(f, "Bind B", 100)
    bind:SetPoint("BOTTOMRIGHT", -22, 22)
    bind:SetScript("OnClick", function()
        local ok = pcall(SetBinding, "B", "FOREVERBAGS_TOGGLE")
        if ok and SaveBindings and GetCurrentBindingSet then pcall(SaveBindings, GetCurrentBindingSet()) end
        FB:Print("B is now bound to ForeverBags. You can change it in Key Bindings > AddOns.")
    end)

    return f
end

function S:Toggle()
    local f = self:Build()
    if f:IsShown() then f:Hide() else f:Show() end
end
