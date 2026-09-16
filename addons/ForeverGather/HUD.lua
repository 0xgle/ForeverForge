local ADDON,FG=...

local function skin(frame,bg,border,edge)
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=edge or 1})
 frame:SetBackdropColor(unpack(bg))
 frame:SetBackdropBorderColor(unpack(border))
end

function FG:InitHUD()
 -- Radar HUD removed by design. We keep only the compact Field Bar and lightweight wrappers
 -- so older buttons/commands do not error out.
 self:InitFieldBar()
end

function FG:ToggleHUD(force)
 -- Redirect old HUD interactions to the compact Field Bar.
 if self.ToggleFieldBar then
  self:ToggleFieldBar(force)
  if force==false then
   self:Print("Radar HUD removed. Using Minimap + World Map + route lines instead.")
  end
 end
end

function FG:UpdateHUD()
 if self.UpdateFieldBar then self:UpdateFieldBar() end
end

function FG:InitFieldBar()
 if self.fieldBar then return end
 local f=CreateFrame("Frame","ForeverGatherFieldBar",UIParent,"BackdropTemplate")
 f:SetSize(540,38)
 f:SetPoint("BOTTOM",0,188)
 f:SetFrameStrata("MEDIUM")
 skin(f,{.008,.03,.038,.92},{.10,.34,.36,.52},1)
 f:EnableMouse(false)
 self.fieldBar=f

 local top=f:CreateTexture(nil,"ARTWORK")
 top:SetColorTexture(self.C.cyan[1],self.C.cyan[2],self.C.cyan[3],.20)
 top:SetPoint("TOPLEFT",1,-1)
 top:SetPoint("TOPRIGHT",-1,-1)
 top:SetHeight(1)

 local g=f:CreateTexture(nil,"ARTWORK")
 g:SetTexture(self.MEDIA.."FG_Logo.tga")
 g:SetSize(28,28)
 g:SetPoint("LEFT",7,0)

 local txtLine=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 txtLine:SetPoint("LEFT",42,0)
 txtLine:SetPoint("RIGHT",-10,0)
 txtLine:SetJustifyH("LEFT")
 txtLine:SetTextColor(unpack(self.C.text))
 f.txt=txtLine

 if not self.db.profile.showFieldBar then f:Hide() end
 self:UpdateFieldBar()
end

function FG:ToggleFieldBar(force)
 local show=force
 if show==nil then show=not self.db.profile.showFieldBar end
 self.db.profile.showFieldBar=show
 if self.fieldBar then
  if show then self.fieldBar:Show(); self:UpdateFieldBar() else self.fieldBar:Hide() end
 end
end

function FG:UpdateFieldBar(nearby)
 if not self.fieldBar or not self.db.profile.showFieldBar then return end
 local mapID=self:GetPos()
 local np,nd=self:GetNextRoutePoint()
 local nextText=np and string.format("Next %.0f yd",nd or 0) or "No route"
 local route=self.db.route
 local routeText=route and string.format("%d stops", #(route.points or {})) or "Route off"
 self.fieldBar.txt:SetText(string.format("|cffe1b457%s|r   |cff3acdd5•|r   %d nearby   |cff3acdd5•|r   %.1f/h   |cff3acdd5•|r   %s   |cff3acdd5•|r   %s",self:GetZoneName(mapID),nearby or 0,self:GetSessionRate(),routeText,nextText))
end
