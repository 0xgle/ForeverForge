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

-- Premium toolbar controls used in the ForeverBags header.
-- These are intentionally separate from category/view buttons so the top bar
-- can feel integrated with the vault artwork instead of looking like flat
-- black default UI rectangles.
function M:EnsureToolbarSkin(frame)
    if frame.fbToolbarSkin or not frame.SetBackdrop then return end
    frame.fbToolbarSkin = true

    frame:SetBackdrop({
        bgFile="Interface\\Buttons\\WHITE8x8",
        edgeFile="Interface\\Buttons\\WHITE8x8",
        edgeSize=1,
    })

    local texture = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    texture:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    texture:SetTexture(self:Texture("vault_panel"))
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.fbToolbarTexture = texture

    local wash = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    wash:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    wash:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    wash:SetColorTexture(0.055, 0.105, 0.11, 0.28)
    frame.fbToolbarWash = wash

    local sheen = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    sheen:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    sheen:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    sheen:SetHeight(12)
    sheen:SetColorTexture(0.22, 0.31, 0.31, 0.09)
    frame.fbToolbarSheen = sheen

    local topLine = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    topLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
    topLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    topLine:SetHeight(1)
    topLine:SetColorTexture(0.72, 0.58, 0.31, 0.42)
    frame.fbToolbarTopLine = topLine

    local bottomLine = frame:CreateTexture(nil, "ARTWORK", nil, 1)
    bottomLine:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
    bottomLine:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    bottomLine:SetHeight(1)
    bottomLine:SetColorTexture(0.10, 0.38, 0.42, 0.42)
    frame.fbToolbarBottomLine = bottomLine
end

function M:SetToolbarBackdrop(frame, active, kind)
    if not frame or not frame.SetBackdrop then return end
    self:EnsureToolbarSkin(frame)
    frame.fbToolbarActive = active and true or false
    local hovered = frame.fbToolbarHovered

    if active then
        frame:SetBackdropColor(0.075, 0.115, 0.12, 0.97)
        frame:SetBackdropBorderColor(0.76, 0.63, 0.36, 0.98)
        frame.fbToolbarTexture:SetVertexColor(0.78, 0.93, 0.94, 1)
        frame.fbToolbarTexture:SetAlpha(0.80)
        frame.fbToolbarWash:SetColorTexture(0.055, 0.17, 0.18, 0.34)
        frame.fbToolbarTopLine:SetColorTexture(0.96, 0.76, 0.38, 0.78)
        frame.fbToolbarBottomLine:SetColorTexture(0.13, 0.58, 0.62, 0.62)
    elseif hovered then
        frame:SetBackdropColor(0.067, 0.098, 0.102, 0.96)
        if kind == "danger" then
            frame:SetBackdropBorderColor(0.74, 0.31, 0.20, 0.98)
            frame.fbToolbarTopLine:SetColorTexture(0.90, 0.43, 0.25, 0.74)
        else
            frame:SetBackdropBorderColor(0.61, 0.51, 0.31, 0.98)
            frame.fbToolbarTopLine:SetColorTexture(0.83, 0.66, 0.34, 0.64)
        end
        frame.fbToolbarTexture:SetVertexColor(0.72, 0.86, 0.88, 1)
        frame.fbToolbarTexture:SetAlpha(0.76)
        frame.fbToolbarWash:SetColorTexture(0.06, 0.14, 0.15, 0.30)
        frame.fbToolbarBottomLine:SetColorTexture(0.12, 0.48, 0.52, 0.55)
    else
        frame:SetBackdropColor(0.052, 0.074, 0.078, 0.95)
        frame:SetBackdropBorderColor(0.33, 0.31, 0.24, 0.88)
        frame.fbToolbarTexture:SetVertexColor(0.64, 0.78, 0.80, 1)
        frame.fbToolbarTexture:SetAlpha(0.68)
        frame.fbToolbarWash:SetColorTexture(0.045, 0.10, 0.11, 0.26)
        frame.fbToolbarTopLine:SetColorTexture(0.66, 0.54, 0.31, 0.38)
        frame.fbToolbarBottomLine:SetColorTexture(0.10, 0.36, 0.40, 0.38)
    end

    frame.fbToolbarSheen:SetAlpha((active or hovered) and 1 or 0.72)
    if frame.text then
        if active or hovered then
            frame.text:SetTextColor(0.92, 0.86, 0.70)
        else
            frame.text:SetTextColor(0.79, 0.82, 0.80)
        end
    end
end

function M:SkinToolbarButton(frame, kind)
    if not frame then return end
    frame.fbToolbarKind = kind
    self:EnsureToolbarSkin(frame)
    if not frame.fbToolbarHooks then
        frame.fbToolbarHooks = true
        frame:HookScript("OnEnter", function(self)
            self.fbToolbarHovered = true
            M:SetToolbarBackdrop(self, self.fbToolbarActive, self.fbToolbarKind)
        end)
        frame:HookScript("OnLeave", function(self)
            self.fbToolbarHovered = false
            M:SetToolbarBackdrop(self, self.fbToolbarActive, self.fbToolbarKind)
        end)
    end
    self:SetToolbarBackdrop(frame, false, kind)
end

function M:SkinToolbarField(frame)
    if not frame then return end
    self:EnsureToolbarSkin(frame)
    if not frame.fbToolbarHooks then
        frame.fbToolbarHooks = true
        frame:HookScript("OnEnter", function(self)
            self.fbToolbarHovered = true
            M:SetToolbarBackdrop(self, self:HasFocus(), "field")
        end)
        frame:HookScript("OnLeave", function(self)
            self.fbToolbarHovered = false
            M:SetToolbarBackdrop(self, self:HasFocus(), "field")
        end)
    end
    self:SetToolbarBackdrop(frame, false, "field")
end

