local _, FB = ...

local DEFAULTS = {
    version = 1,
    settings = {
        scale = 1.0,
        columns = 10,
        iconSize = 42,
        sectioned = true,
        sort = "slot",
        minimap = true,
        minimapAngle = 220,
        showEmptySlots = true,
        recentSeconds = 600,
    },
    characters = {},
    discoveries = {},
    favorites = {},
    tags = {},
}

local function MergeDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            MergeDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function FB:InitDB()
    if type(ForeverBagsDB) ~= "table" then ForeverBagsDB = {} end
    MergeDefaults(ForeverBagsDB, DEFAULTS)
    self.db = ForeverBagsDB
    self.settings = self.db.settings
    local key = self:CharacterKey()
    self.db.characters[key] = self.db.characters[key] or { inventory = {}, bank = {}, money = 0, class = select(2, UnitClass("player")), lastSeen = 0 }
    self.char = self.db.characters[key]
    self.char.lastSeen = self:Now()
    self.char.class = select(2, UnitClass("player"))
end

function FB:IsFavorite(itemID)
    return self.db and self.db.favorites[self:ItemKey(itemID)] == true
end

function FB:ToggleFavorite(itemID)
    if not itemID then return end
    local k = self:ItemKey(itemID)
    self.db.favorites[k] = not self.db.favorites[k] or nil
    self:Fire("FILTER_CHANGED")
end

function FB:GetTag(itemID)
    return self.db and self.db.tags[self:ItemKey(itemID)] or nil
end

function FB:CycleTag(itemID)
    if not itemID then return nil end
    local k = self:ItemKey(itemID)
    local current = self.db.tags[k]
    local nextTag = current == nil and "keep" or current == "keep" and "sell" or current == "sell" and "bank" or nil
    self.db.tags[k] = nextTag
    self:Fire("FILTER_CHANGED")
    return nextTag
end

FB:On("BOOT", function() FB:InitDB() end)
