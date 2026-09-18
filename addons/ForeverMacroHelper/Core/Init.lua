local ADDON_NAME, FMH = ...
_G.ForeverMacroHelper = FMH
FMH.name = ADDON_NAME
FMH.version = "0.2.0-beta2"
FMH.author = "0xgle"
FMH.copyright = "© 2026 0xgle. All rights reserved."
FMH.isClassicEra = WOW_PROJECT_CLASSIC and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC or false
FMH.callbacks = FMH.callbacks or {}
FMH.state = FMH.state or { inCombat = false }

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok and DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55d6ffForeverMacroHelper|r: " .. tostring(err))
    end
end

function FMH:Print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff55d6ffForeverMacroHelper|r " .. tostring(msg)) end
end

function FMH:On(event, fn)
    self.callbacks[event] = self.callbacks[event] or {}
    table.insert(self.callbacks[event], fn)
end

function FMH:Fire(event, ...)
    local list = self.callbacks[event]
    if not list then return end
    for i=1,#list do SafeCall(list[i], ...) end
end

function FMH:CharacterKey()
    return (UnitName("player") or "Unknown") .. " - " .. (GetRealmName() or "Unknown")
end

function FMH:PlayerClass()
    return select(2, UnitClass("player")) or "UNKNOWN"
end

function FMH:CanModifyMacros()
    if InCombatLockdown and InCombatLockdown() then return false end
    return not self.state.inCombat
end

function FMH:Normalize(s)
    s = tostring(s or ""):lower()
    s = s:gsub("[%c%p]", " ")
    return s:gsub("%s+", " ")
end

FMH.eventFrame = CreateFrame("Frame")
for _,ev in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","UPDATE_MACROS"}) do
    FMH.eventFrame:RegisterEvent(ev)
end
FMH.eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" and ... == ADDON_NAME then FMH:Fire("BOOT")
    elseif event == "PLAYER_LOGIN" then FMH:Fire("LOGIN")
    elseif event == "PLAYER_REGEN_DISABLED" then FMH.state.inCombat = true; FMH:Fire("COMBAT_CHANGED", true)
    elseif event == "PLAYER_REGEN_ENABLED" then FMH.state.inCombat = false; FMH:Fire("COMBAT_CHANGED", false)
    elseif event == "UPDATE_MACROS" then FMH:Fire("MACROS_CHANGED") end
end)
