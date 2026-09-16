local ADDON_NAME, FB = ...
_G.ForeverBags = FB
FB.name = ADDON_NAME
FB.version = "0.9.0-beta1"
FB.modules = FB.modules or {}
FB.callbacks = FB.callbacks or {}
FB.state = FB.state or { bankOpen = false, merchantOpen = false, lastLootSource = nil, lastLootAt = 0 }

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55d6ffForeverBags|r: " .. tostring(err))
    end
end

function FB:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55d6ffForeverBags|r " .. tostring(msg))
    end
end

function FB:On(event, callback)
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], callback)
end

function FB:Fire(event, ...)
    local list = self.callbacks[event]
    if not list then return end
    for i = 1, #list do SafeCall(list[i], ...) end
end

function FB:Debounce(key, delay, fn)
    self._debounce = self._debounce or {}
    local token = (self._debounce[key] or 0) + 1
    self._debounce[key] = token
    C_Timer.After(delay or 0, function()
        if self._debounce[key] == token then SafeCall(fn) end
    end)
end

function FB:FormatMoney(copper)
    copper = math.max(0, tonumber(copper) or 0)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then return string.format("%dg %02ds %02dc", g, s, c) end
    if s > 0 then return string.format("%ds %02dc", s, c) end
    return string.format("%dc", c)
end

function FB:CharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "Unknown"
    return name .. " - " .. realm
end

function FB:Now()
    return (GetServerTime and GetServerTime()) or time()
end

function FB:ItemKey(itemID)
    return tostring(tonumber(itemID) or itemID or "0")
end

function FB:ShallowCopy(src)
    local out = {}
    if src then for k, v in pairs(src) do out[k] = v end end
    return out
end

FB.eventFrame = CreateFrame("Frame")
local events = {
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE_DELAYED",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "PLAYERBANKSLOTS_CHANGED",
    "PLAYERREAGENTBANKSLOTS_CHANGED", "MERCHANT_SHOW", "MERCHANT_CLOSED",
    "GET_ITEM_INFO_RECEIVED", "PLAYER_MONEY", "LOOT_OPENED", "LOOT_CLOSED",
    "PLAYER_LOGOUT", "ITEM_LOCK_CHANGED"
}
for i = 1, #events do pcall(FB.eventFrame.RegisterEvent, FB.eventFrame, events[i]) end

FB.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == ADDON_NAME then
        FB:Fire("BOOT")
    elseif event == "PLAYER_LOGIN" then
        FB:Fire("LOGIN")
    elseif event == "PLAYER_ENTERING_WORLD" then
        FB:Fire("WORLD")
    elseif event == "BANKFRAME_OPENED" then
        FB.state.bankOpen = true
        FB:Fire("BANK_OPEN")
    elseif event == "BANKFRAME_CLOSED" then
        FB.state.bankOpen = false
        FB:Fire("BANK_CLOSE")
    elseif event == "MERCHANT_SHOW" then
        FB.state.merchantOpen = true
        FB:Fire("MERCHANT_OPEN")
    elseif event == "MERCHANT_CLOSED" then
        FB.state.merchantOpen = false
        FB:Fire("MERCHANT_CLOSE")
    elseif event == "LOOT_OPENED" then
        local target = UnitName("target")
        FB.state.lastLootSource = target or (GetZoneText and GetZoneText()) or nil
        FB.state.lastLootAt = FB:Now()
    elseif event == "LOOT_CLOSED" then
        -- Keep the source briefly so BAG_UPDATE_DELAYED can associate newly-seen items.
    end
    FB:Fire(event, ...)
end)
