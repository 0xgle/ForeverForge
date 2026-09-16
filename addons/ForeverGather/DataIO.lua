local ADDON,FG=...
local function skin(frame,bg,border)
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1});frame:SetBackdropColor(unpack(bg));frame:SetBackdropBorderColor(unpack(border))
end
local function button(parent,text,w,h)
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b:SetSize(w or 120,h or 28);skin(b,FG.C.panel2,FG.C.border);local t=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");t:SetPoint("CENTER");t:SetText(text);b.txt=t;b:SetScript("OnEnter",function()b:SetBackdropBorderColor(unpack(FG.C.cyan))end);b:SetScript("OnLeave",function()b:SetBackdropBorderColor(unpack(FG.C.border))end);return b
end
function FG:InitDataIO() end
function FG:BuildZoneExport(mapID)
 mapID=mapID or C_Map.GetBestMapForUnit("player"); if not mapID then return "ForeverGather export: no map" end
 local lines={"FOREVERGATHER|1|"..FG.VERSION,"MAP|"..mapID.."|"..self:GetZoneName(mapID)}
 for kind,b in pairs(self.db.nodes[mapID] or {}) do for _,r in pairs(b) do
  local name=(r.name or "Unknown"):gsub("[|\n\r]"," ")
  lines[#lines+1]=table.concat({"N",kind,math.floor(r.x*100000+.5),math.floor(r.y*100000+.5),r.count or 1,r.source or "learned",r.npcID or 0,name},"|")
 end end
 return table.concat(lines,"\n")
end
function FG:ShowExport()
 if not self.exportFrame then
  local f=CreateFrame("Frame","ForeverGatherExport",UIParent,"BackdropTemplate");f:SetSize(620,440);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");skin(f,self.C.bg,self.C.gold);self.exportFrame=f
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");t:SetPoint("TOPLEFT",18,-16);t:SetText("FOREVER GATHER // ZONE EXPORT");t:SetTextColor(unpack(self.C.gold))
  local sub=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");sub:SetPoint("TOPLEFT",18,-41);sub:SetText("Portable plain-text backup of the currently selected zone. Ctrl+C to copy.");sub:SetTextColor(unpack(self.C.muted))
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",18,-70);scroll:SetPoint("BOTTOMRIGHT",-38,56)
  local e=CreateFrame("EditBox",nil,scroll);e:SetMultiLine(true);e:SetAutoFocus(false);e:SetFontObject("ChatFontNormal");e:SetWidth(545);e:SetTextInsets(6,6,6,6);scroll:SetScrollChild(e);f.edit=e
  local close=button(f,"CLOSE",100,30);close:SetPoint("BOTTOMRIGHT",-18,16);close:SetScript("OnClick",function()f:Hide()end)
  local select=button(f,"SELECT ALL",110,30);select:SetPoint("RIGHT",close,"LEFT",-8,0);select:SetScript("OnClick",function()e:SetFocus();e:HighlightText()end)
 end
 self.exportFrame.edit:SetText(self:BuildZoneExport());self.exportFrame.edit:SetCursorPosition(0);self.exportFrame:Show()
end
function FG:ShowDiagnostics()
 if not self.diagFrame then
  local f=CreateFrame("Frame","ForeverGatherDiagnostics",UIParent,"BackdropTemplate");f:SetSize(590,470);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");skin(f,self.C.bg,self.C.gold);self.diagFrame=f
  local t=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");t:SetPoint("TOPLEFT",18,-16);t:SetText("FOREVER GATHER // SYSTEM DIAGNOSTICS");t:SetTextColor(unpack(self.C.gold))
  local body=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");body:SetPoint("TOPLEFT",20,-56);body:SetPoint("BOTTOMRIGHT",-20,64);body:SetJustifyH("LEFT");body:SetJustifyV("TOP");f.body=body
  local prune=button(f,"RUN DATA DOCTOR",150,30);prune:SetPoint("BOTTOMLEFT",18,16);prune:SetScript("OnClick",function()local n=FG:PruneInvalid();FG:Print("Data Doctor removed "..n.." invalid records.");FG:ShowDiagnostics()end)
  local close=button(f,"CLOSE",100,30);close:SetPoint("BOTTOMRIGHT",-18,16);close:SetScript("OnClick",function()f:Hide()end)
 end
 local h=self:GetHealthReport();local d,p=self:GetTrackerDiagnostics();local mapID=self:GetPos();local miniRadius=(C_Minimap and C_Minimap.GetViewRadius and C_Minimap.GetViewRadius()) or 0
 local route=self.db.route;local rtxt=route and string.format("%d stops, current %d, %.0f yd",#(route.points or {}),route.current or 1,route.distance or 0) or "inactive"
 local lines={
  "|cffe1b457Build|r  "..self.VERSION.."    Schema "..self.SCHEMA,
  "|cffe1b457Zone|r  "..self:GetZoneName(mapID).." (mapID "..tostring(mapID)..")",
  "|cffe1b457Database|r  "..h.nodes.." nodes across "..h.maps.." maps   Invalid: "..h.invalid,
  string.format("Mining %d   Herbalism %d   Skinning %d",h.mining,h.herbalism,h.skinning),
  "",
  "|cff3acdd5Tracker event counters|r",
  string.format("Sent %d   Stop %d   Success %d   Failed %d   LootOpened %d   Recorded %d",d.sent,d.stopped,d.succeeded,d.failed,d.lootOpened,d.recorded),
  "Last event: "..tostring(d.lastEvent).."   Spell: "..tostring(d.lastSpell).."   Target: "..tostring(d.lastTarget),
  "Pending gather: "..(p and (p.kind.." / "..p.name) or "none"),
  "",
  "|cff3acdd5Profession/API state|r",
  "Mining skill: "..tostring(self:GetProfessionSkill("mining") or "not detected").."   Herbalism: "..tostring(self:GetProfessionSkill("herbalism") or "not detected").."   Skinning: "..tostring(self:GetProfessionSkill("skinning") or "not detected"),
  "C_Map: "..tostring(C_Map~=nil).."   C_Minimap: "..tostring(C_Minimap~=nil).."   View radius: "..string.format("%.0f",miniRadius or 0).." yd",
  "TomTom: "..tostring(_G.TomTom~=nil).."   GatherMate2 DB: "..tostring(_G.GatherMate2MineDB~=nil or _G.GatherMate2HerbDB~=nil),
  "",
  "|cff3acdd5Runtime|r",
  "Smart Route: "..rtxt,
  string.format("Current session: %d gathers / %.1f per hour",self:GetSessionTotal(),self:GetSessionRate()),
  "Data revision: "..tostring(self.dataRevision or 0).."   Route revision: "..tostring(self.routeRevision or 0),
  "",
  "If real gathering does not record, screenshot this panel after one Mining/Herbalism/Skinning attempt."
 }
 self.diagFrame.body:SetText(table.concat(lines,"\n"));self.diagFrame:Show()
end
