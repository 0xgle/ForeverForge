local ADDON, F = ...
_G.ForeverCore = F
F.name, F.version, F.apiVersion = ADDON, "1.0.0-rc1", 1
F.modules, F.pending, F.errors = {}, {}, {}
F.media = "Interface\\AddOns\\ForeverCore\\Media\\"
F.A = {}
local names = {"GetNumAddOns", "GetAddOnInfo", "GetAddOnMetadata", "IsAddOnLoaded", "IsAddOnLoadOnDemand", "GetAddOnDependencies", "EnableAddOn", "DisableAddOn", "LoadAddOn"}
for _, name in ipairs(names) do F.A[name] = C_AddOns and C_AddOns[name] or _G[name] end
function F.A.Enabled(name)
    if C_AddOns and C_AddOns.GetAddOnEnableState then
        return (C_AddOns.GetAddOnEnableState(name, UnitName("player")) or 0) > 0
    end
    return (GetAddOnEnableState(UnitName("player"), name) or 0) > 0
end
function F:Print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff60dcccForeverCore|r  " .. tostring(msg)) end
end
function F:Copy(t)
    if type(t) ~= "table" then return t end
    local out = {}; for k,v in pairs(t) do out[k] = self:Copy(v) end; return out
end
function F:InitDB()
    ForeverCoreDB = type(ForeverCoreDB) == "table" and ForeverCoreDB or {}
    self.db = ForeverCoreDB
    for _,key in ipairs({"profiles", "favorites", "settings", "history"}) do
        if type(self.db[key]) ~= "table" then self.db[key] = {} end
    end
    self.db.schema = 1
    local s = self.db.settings
    s.scale = math.max(.65, math.min(1.25, tonumber(s.scale) or 1))
    s.minimapAngle = tonumber(s.minimapAngle) or 220
    if s.minimap == nil then s.minimap = true end
    ForeverCoreCharDB = type(ForeverCoreCharDB) == "table" and ForeverCoreCharDB or {}
    self.char = ForeverCoreCharDB
end
function F:Guard()
    if InCombatLockdown() then self:Print("This action is available after combat."); return false end
    return true
end
function F:Record(message)
    table.insert(self.db.history, 1, date("%H:%M") .. "  " .. message)
    while #self.db.history > 30 do table.remove(self.db.history) end
end
function F:SafeCall(label, fn, ...)
    local ok, result = pcall(fn, ...)
    if not ok then
        table.insert(self.errors, 1, label .. ": " .. tostring(result))
        while #self.errors > 15 do table.remove(self.errors) end
        self:Print(label .. " failed. See Diagnostics.")
    end
    return ok, result
end
-- Stable public registration API. Call with colon syntax. Callbacks receive no arguments.
function F:RegisterModule(id, spec)
    assert(type(id) == "string" and type(spec) == "table", "ForeverCore: invalid module")
    assert(type(spec.title) == "string", "ForeverCore: module title required")
    self.modules[id] = spec
    if self.db then self:Refresh() end
end
function F:Refresh()
    if self.frame and self.frame:IsShown() then self:Render() end
end
function F:Reload()
    if not self:Guard() then return end
    if next(self.pending) then self:Print("Apply or discard the staged changes first."); return end
    ReloadUI()
end
