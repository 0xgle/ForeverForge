local _, FMH = ...
local M={};FMH.Media=M
M.base='Interface\\AddOns\\ForeverMacroHelper\\Media\\'
function M:Icon(name) return self.base..'Icons\\'..name..'.tga' end
function M:Texture(name) return self.base..'Textures\\'..name..'.tga' end
function M:SetBackdrop(frame,alpha)
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
    frame:SetBackdropColor(0.02,0.03,0.04,alpha or 1);frame:SetBackdropBorderColor(0.46,0.35,0.18,1)
end
function M:SetPanel(frame,alpha)
    frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
    frame:SetBackdropColor(0.025,0.041,0.053,alpha or 0.95);frame:SetBackdropBorderColor(0.19,0.27,0.29,0.9)
end
function M:SetButton(frame,active,danger)
    if not frame._styled then
        frame:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
        frame._styled=true
    end
    if danger then frame:SetBackdropColor(0.24,0.07,0.055,1);frame:SetBackdropBorderColor(0.62,0.25,0.17,1)
    elseif active then frame:SetBackdropColor(0.04,0.19,0.22,1);frame:SetBackdropBorderColor(0.23,0.66,0.68,1)
    else frame:SetBackdropColor(0.04,0.065,0.078,0.97);frame:SetBackdropBorderColor(0.27,0.30,0.27,0.8) end
end
