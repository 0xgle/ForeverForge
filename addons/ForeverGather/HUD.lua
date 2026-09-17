local ADDON,FG=...
local T,C=FG.Theme,FG.C
function FG:InitHUD()self:InitFieldBar()end
function FG:ToggleHUD(force)self:ToggleFieldBar(force)end
function FG:UpdateHUD()self:UpdateFieldBar()end
function FG:InitFieldBar()
 if self.fieldBar then return end
 local f=CreateFrame('Frame','ForeverGatherFieldBar',UIParent,'BackdropTemplate');self.fieldBar=f
 f:SetSize(342,172);f:SetPoint('RIGHT',UIParent,'RIGHT',-36,80);f:SetFrameStrata('MEDIUM');T.Skin(f,C.bg)
 f.material=T.Art(f,'Material',1,1,340,170,'BACKGROUND');f.material:SetAlpha(.35)
 local art=T.Art(f,'Header',1,1,340,48,'BACKGROUND');art:SetTexCoord(0,1,.30,.75)
 T.Art(f,'Emblem',10,7,34)
 f.zone=T.Text(f,'EXPEDITION',52,7,218,20,13,C.gold)
 T.Text(f,'by 0xgle',52,27,155,14,9,C.muted)
 local drag=CreateFrame('Frame',nil,f);drag:SetPoint('TOPLEFT');drag:SetSize(270,48);T.Movable(f,'expeditionHUDPosition',drag)
 T.Button(f,'-',278,10,24,26,function()FG.db.profile.hudCollapsed=not FG.db.profile.hudCollapsed;FG:UpdateFieldBar()end)
 T.Button(f,'x',308,10,24,26,function()FG:ToggleFieldBar(false)end)
 f.body=CreateFrame('Frame',nil,f);f.body:SetAllPoints()
 f.icon=T.Art(f.body,'Icon_Route',12,61,48)
 f.name=T.Text(f.body,'Ready to explore',72,58,186,22,13,C.text)
 f.distance=T.Text(f.body,'',262,59,68,21,13,C.gold);f.distance:SetJustifyH('RIGHT')
 f.detail=T.Text(f.body,'Gather to discover locations',72,82,258,18,10,C.muted)
 T.Rule(f.body,12,117,318)
 f.stats=T.Text(f.body,'',12,126,196,20,11,C.cyan)
 T.Button(f,'Open',222,126,51,30,function()FG:ToggleUI()end)
 T.Button(f,'Next',279,126,51,30,function()FG:AdvanceRoute()end)
 T.Fit(f,342,172,self.db.profile.expeditionHUDScale or 1)
 f:SetShown(self.db.profile.showFieldBar);self:UpdateFieldBar()
end
function FG:ToggleFieldBar(force)
 if force==nil then force=not self.db.profile.showFieldBar end
 self.db.profile.showFieldBar=force
 if self.fieldBar then self.fieldBar:SetShown(force);self:UpdateFieldBar()end
end
function FG:UpdateFieldBar(nearby)
 local f=self.fieldBar;if not f or not self.db.profile.showFieldBar then return end
 if type(nearby)=='number' then self.hudNearby=nearby end
 local collapsed=self.db.profile.hudCollapsed;f:SetHeight(collapsed and 48 or 172);f.material:SetHeight(collapsed and 46 or 170);f.body:SetShown(not collapsed)
 f.zone:SetText(self:GetZoneName(C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit('player')))
 local p,d,i=self:GetNextRoutePoint();local r=self.db.route
 if p then
  f.icon:SetTexture(self:IconFor(p.kind));f.name:SetText(p.name or 'Route stop');f.distance:SetText(string.format('%.0f yd',d or 0))
  f.detail:SetText(string.format('Stop %d / %d  •  %.1f, %.1f',i,#r.points,p.x*100,p.y*100))
 elseif r and r.finished then
  f.name:SetText('Route complete');f.distance:SetText('');f.detail:SetText('Open Expedition to build another');f.icon:SetTexture(self:IconFor())
 elseif r then
  f.name:SetText('Route in another zone');f.distance:SetText('');f.detail:SetText(self:GetZoneName(r.mapID));f.icon:SetTexture(self:IconFor())
 else
  f.name:SetText('Ready to explore');f.distance:SetText('');f.detail:SetText('Gather to discover locations');f.icon:SetTexture(self:IconFor())
 end
 f.stats:SetText(string.format('%d gathers   •   %.0f /h',self:GetSessionTotal(),self:GetSessionRate()))
end
