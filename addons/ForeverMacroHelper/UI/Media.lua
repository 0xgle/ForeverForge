local _, FMH = ...
FMH.Media = FMH.Media or {}
local M = FMH.Media
M.base = "Interface\\AddOns\\ForeverMacroHelper\\Media\\"
M.icons = M.base .. "Icons\\"
M.textures = M.base .. "Textures\\"
function M:Icon(name) return self.icons .. name .. ".tga" end
function M:Texture(name) return self.textures .. name .. ".tga" end
function M:SetBackdrop(frame, alpha)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({bgFile=self:Texture("obsidian"),edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    frame:SetBackdropColor(0.035,0.055,0.072,alpha or 0.98)
    frame:SetBackdropBorderColor(0.50,0.37,0.16,1)
end
function M:SetPanel(frame, alpha)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    frame:SetBackdropColor(0.025,0.04,0.055,alpha or 0.88)
    frame:SetBackdropBorderColor(0.18,0.27,0.31,0.95)
end
function M:SetButton(frame, active, danger)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Buttons\\WHITE8x8",edgeSize=1})
    if danger then frame:SetBackdropColor(0.25,0.055,0.045,0.95); frame:SetBackdropBorderColor(0.85,0.22,0.16,1)
    elseif active then frame:SetBackdropColor(0.025,0.25,0.32,0.98); frame:SetBackdropBorderColor(0.18,0.82,1,1)
    else frame:SetBackdropColor(0.035,0.055,0.072,0.96); frame:SetBackdropBorderColor(0.36,0.30,0.20,0.95) end
end
