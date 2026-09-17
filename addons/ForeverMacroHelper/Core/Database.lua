local _, FMH = ...
local DEFAULTS = {
    version = 1,
    settings = {
        scale = 1.0,
        minimap = true,
        minimapAngle = 225,
        currentClassOnly = true,
        showGeneral = true,
        mode = "ALL",
        category = "ALL",
        search = "",
    },
    favorites = {},
    installed = {},
    windowPoint = nil,
}
local function Merge(dst, src)
    for k,v in pairs(src) do
        if type(v)=="table" then if type(dst[k])~="table" then dst[k]={} end; Merge(dst[k],v)
        elseif dst[k]==nil then dst[k]=v end
    end
end
function FMH:InitDB()
    if type(ForeverMacroHelperDB)~="table" then ForeverMacroHelperDB={} end
    Merge(ForeverMacroHelperDB, DEFAULTS)
    self.db=ForeverMacroHelperDB; self.settings=self.db.settings
end
function FMH:IsFavorite(id) return self.db and self.db.favorites[id] == true end
function FMH:ToggleFavorite(id)
    if not id then return end
    self.db.favorites[id] = not self.db.favorites[id] or nil
    self:Fire("FILTER_CHANGED")
end
FMH:On("BOOT", function() FMH:InitDB() end)
