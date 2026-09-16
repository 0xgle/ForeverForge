local _, FB = ...
FB.Media = FB.Media or {}
local M = FB.Media

M.base = "Interface\\AddOns\\ForeverBags\\Media\\"
M.icons = M.base .. "Icons\\"
M.textures = M.base .. "Textures\\"

M.iconFiles = {
    bag="bag", bank="bank", alts="alts", search="search", sort_up="sort_up", sort_down="sort_down",
    filter="filter", favorite="favorite", settings="settings", close="close", minimize="minimize", move="move",
    allitems="allitems", equipment="equipment", weapons="weapons", armor="armor", potion="potion", food="food",
    crafting="crafting", herbs="herbs", ore="ore", cloth="cloth", gems="gems", quest="quest", junk="junk",
    mail="mail", repair="repair", lock="lock", discovery="discovery", coins="coins", selected="selected",
    new="new", keep="keep", sell="sell", bank_badge="bank_badge", warning="warning", unknown="unknown", pinned="pinned",
}

function M:Icon(name)
    local file = self.iconFiles[name] or name
    return self.icons .. file .. ".tga"
end

function M:Texture(name)
    return self.textures .. name .. ".tga"
end

M.quality = {
    [0] = {0.45,0.45,0.45}, [1] = {0.88,0.88,0.88}, [2] = {0.15,0.95,0.25},
    [3] = {0.15,0.55,1.0}, [4] = {0.72,0.25,1.0}, [5] = {1.0,0.55,0.05}, [6] = {0.9,0.55,0.15},
}

function M:SetBackdrop(frame, alpha)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({ bgFile=self:Texture("obsidian"), edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    frame:SetBackdropColor(0.045,0.065,0.08,alpha or 0.97)
    frame:SetBackdropBorderColor(0.48,0.36,0.16,1)
end

function M:SetButtonBackdrop(frame, active)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    if active then
        frame:SetBackdropColor(0.03,0.26,0.34,0.95); frame:SetBackdropBorderColor(0.15,0.85,1,0.9)
    else
        frame:SetBackdropColor(0.04,0.055,0.07,0.95); frame:SetBackdropBorderColor(0.42,0.34,0.2,0.9)
    end
end
