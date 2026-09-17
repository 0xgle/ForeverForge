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
    frame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    frame:SetBackdropColor(0.025,0.038,0.046,alpha or 0.97)
    frame:SetBackdropBorderColor(0.28,0.27,0.22,0.8)
end

function M:SetButtonBackdrop(frame, active)
    if not frame.SetBackdrop then return end
    frame.fbActive = active
    if not frame.fbStyled then
        frame.fbStyled = true
        frame.fbAccent = frame:CreateTexture(nil, "ARTWORK")
        frame.fbAccent:SetColorTexture(0.72,0.61,0.38,1)
        frame.fbAccent:SetPoint("TOPLEFT",1,-5)
        frame.fbAccent:SetPoint("BOTTOMLEFT",1,5)
        frame.fbAccent:SetWidth(2)
        frame:HookScript("OnEnter", function(self)
            self.fbHovered = true; M:SetButtonBackdrop(self, self.fbActive)
        end)
        frame:HookScript("OnLeave", function(self)
            self.fbHovered = false; M:SetButtonBackdrop(self, self.fbActive)
        end)
    end
    frame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    if active then
        frame:SetBackdropColor(0.065,0.15,0.17,0.96); frame:SetBackdropBorderColor(0.42,0.51,0.46,0.9)
    elseif frame.fbHovered then
        frame:SetBackdropColor(0.075,0.105,0.115,0.96); frame:SetBackdropBorderColor(0.55,0.47,0.31,0.95)
    else
        frame:SetBackdropColor(0.04,0.055,0.063,0.9); frame:SetBackdropBorderColor(0.25,0.28,0.28,0.75)
    end
    frame.fbAccent:SetShown(active and true or false)
    if frame.text then frame.text:SetTextColor(active and 0.96 or 0.79, active and 0.87 or 0.81, active and 0.65 or 0.79) end
end

function M:ApplyWindowArt(frame)
    if frame.fbWindowArt then return end
    frame:SetBackdropColor(0.015,0.025,0.03,1)
    frame:SetBackdropBorderColor(0,0,0,0)
    local art = frame:CreateTexture(nil,"BACKGROUND",nil,1)
    art:SetAllPoints(); art:SetTexture(self:Texture("vault_panel"))
    frame.fbWindowArt = art
end
