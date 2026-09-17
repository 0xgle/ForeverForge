local ADDON,FG=...

local function skin(frame,bg,border)
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 frame:SetBackdropColor(unpack(bg));frame:SetBackdropBorderColor(unpack(border))
end
local function button(parent,text,w,h)
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate");b:SetSize(w or 120,h or 28);skin(b,FG.C.panel2,FG.C.border)
 local t=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");t:SetPoint("CENTER");t:SetText(text);b.txt=t
 b:SetScript("OnEnter",function()b:SetBackdropBorderColor(unpack(FG.C.cyan))end)
 b:SetScript("OnLeave",function()b:SetBackdropBorderColor(unpack(FG.C.border))end)
 return b
end
local function esc(s)
 s=tostring(s or "");s=s:gsub("%%","%%25"):gsub("|","%%7C"):gsub("\r","%%0D"):gsub("\n","%%0A");return s
end
local function unesc(s)
 s=tostring(s or "");s=s:gsub("%%0A","\n"):gsub("%%0D","\r"):gsub("%%7C","|"):gsub("%%25","%%");return s
end
local function fields(line)
 local out={};for v in (tostring(line or "").."|"):gmatch("(.-)|") do out[#out+1]=v end;return out
end
local function positiveMin(a,b)
 a=tonumber(a) or 0;b=tonumber(b) or 0
 if a<=0 then return b>0 and b or nil end;if b<=0 then return a end;return math.min(a,b)
end

function FG:InitDataIO() end

function FG:BuildExport(mapID)
 local scope=mapID and ("MAP:"..mapID) or "ALL"
 local lines={table.concat({"FGX","2",esc(self.VERSION),self:Now(),scope},"|")}
 local maps={}
 if mapID then maps[1]=mapID else for mid in pairs(self.db.nodes or {}) do if type(mid)=="number" then maps[#maps+1]=mid end end;table.sort(maps) end
 for _,mid in ipairs(maps) do
  lines[#lines+1]=table.concat({"M",mid,esc(self:GetZoneName(mid))},"|")
  local ks=self.db.nodes[mid] or {}
  for _,kind in ipairs({"mining","herbalism","skinning"}) do
   local ids={};for id in pairs(ks[kind] or {}) do ids[#ids+1]=id end;table.sort(ids)
   for _,id in ipairs(ids) do local r=ks[kind][id]
    lines[#lines+1]=table.concat({
     "N",kind,mid,math.floor((r.x or 0)*100000+.5),math.floor((r.y or 0)*100000+.5),
     r.count or 1,r.hits or r.count or 1,r.first or 0,r.last or 0,r.respawnCount or 0,r.respawnSum or 0,
     r.respawnMin or 0,r.respawnMax or 0,r.npcID or 0,esc(r.name or "Unknown")
    },"|")
   end
  end
 end
 return table.concat(lines,"\n")
end

function FG:MergeImportedRecord(rec)
 if not self.KINDS[rec.kind] or not rec.mapID or not rec.x or not rec.y or rec.x<=0 or rec.x>=1 or rec.y<=0 or rec.y>=1 then return false,"invalid" end
 local name=self:SafeName(rec.name);local b=self:GetKindTable(rec.mapID,rec.kind,true);local r=self:FindNearby(rec.mapID,rec.kind,name,rec.x,rec.y)
 local incoming=math.max(1,tonumber(rec.count) or 1)
 if not r then
  local id=self.db.nextID or 1;self.db.nextID=id+1
  r={id=id,x=rec.x,y=rec.y,name=name,count=incoming,hits=math.max(incoming,tonumber(rec.hits) or incoming),first=tonumber(rec.first) or 0,last=tonumber(rec.last) or 0,source="imported",respawnCount=tonumber(rec.respawnCount) or 0,respawnSum=tonumber(rec.respawnSum) or 0,respawnMin=positiveMin(0,rec.respawnMin),respawnMax=(tonumber(rec.respawnMax) or 0)>0 and tonumber(rec.respawnMax) or nil,loot={},npcID=(tonumber(rec.npcID) or 0)>0 and tonumber(rec.npcID) or nil}
  b[id]=r;if self.spatial and self.spatial[rec.mapID] then self.spatial[rec.mapID][rec.kind]=nil end;return true,"new"
 end
 local existing=math.max(1,r.count or 1);local weight=existing+incoming
 r.x=((r.x or rec.x)*existing+rec.x*incoming)/weight;r.y=((r.y or rec.y)*existing+rec.y*incoming)/weight
 if r.name=="Unknown" and name~="Unknown" then r.name=name end
 r.count=math.max(existing,incoming);r.hits=math.max(r.hits or existing,tonumber(rec.hits) or incoming)
 local rf=tonumber(r.first) or 0;local inf=tonumber(rec.first) or 0;if rf<=0 then r.first=inf elseif inf>0 then r.first=math.min(rf,inf) end
 r.last=math.max(tonumber(r.last) or 0,tonumber(rec.last) or 0)
 r.respawnCount=math.max(tonumber(r.respawnCount) or 0,tonumber(rec.respawnCount) or 0)
 r.respawnSum=math.max(tonumber(r.respawnSum) or 0,tonumber(rec.respawnSum) or 0)
 r.respawnMin=positiveMin(r.respawnMin,rec.respawnMin)
 r.respawnMax=math.max(tonumber(r.respawnMax) or 0,tonumber(rec.respawnMax) or 0);if r.respawnMax<=0 then r.respawnMax=nil end
 r.npcID=r.npcID or (((tonumber(rec.npcID) or 0)>0) and tonumber(rec.npcID) or nil)
 if self.spatial and self.spatial[rec.mapID] then self.spatial[rec.mapID][rec.kind]=nil end
 return true,"merged"
end

function FG:ImportText(text)
 text=tostring(text or "");local header=text:match("^([^\r\n]+)")
 local hf=fields(header);if hf[1]~="FGX" or tonumber(hf[2])~=2 then return nil,"Not a ForeverGather FGX v2 export." end
 local added,merged,invalid=0,0,0
 for line in text:gmatch("[^\r\n]+") do
  local f=fields(line)
  if f[1]=="N" then
   local rec={kind=f[2],mapID=tonumber(f[3]),x=(tonumber(f[4]) or 0)/100000,y=(tonumber(f[5]) or 0)/100000,count=tonumber(f[6]),hits=tonumber(f[7]),first=tonumber(f[8]),last=tonumber(f[9]),respawnCount=tonumber(f[10]),respawnSum=tonumber(f[11]),respawnMin=tonumber(f[12]),respawnMax=tonumber(f[13]),npcID=tonumber(f[14]),name=unesc(f[15])}
   local ok,state=self:MergeImportedRecord(rec);if ok then if state=="new" then added=added+1 else merged=merged+1 end else invalid=invalid+1 end
  end
 end
 self.db.stats.imports=(self.db.stats.imports or 0)+added;self:InvalidateCaches();if self.RefreshPins then self:RefreshPins() end;if self.UIRefresh then self:UIRefresh() end;if self.RefreshAtlas then self:RefreshAtlas(false) end
 return {added=added,merged=merged,invalid=invalid}
end

local function buildDataFrame(self)
 if self.dataFrame then return self.dataFrame end
 local f=CreateFrame("Frame","ForeverGatherDataExchange",UIParent,"BackdropTemplate");f:SetSize(670,500);f:SetPoint("CENTER");f:SetFrameStrata("FULLSCREEN_DIALOG");skin(f,self.C.bg,self.C.gold);self.dataFrame=f
 f.title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");f.title:SetPoint("TOPLEFT",18,-16);f.title:SetTextColor(unpack(self.C.gold))
 f.sub=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.sub:SetPoint("TOPLEFT",18,-43);f.sub:SetTextColor(unpack(self.C.muted));f.sub:SetWidth(620);f.sub:SetJustifyH("LEFT")
 local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",18,-78);scroll:SetPoint("BOTTOMRIGHT",-38,66)
 local e=CreateFrame("EditBox",nil,scroll);e:SetMultiLine(true);e:SetAutoFocus(false);e:SetFontObject("ChatFontNormal");e:SetWidth(595);e:SetTextInsets(6,6,6,6);scroll:SetScrollChild(e);f.edit=e
 f.status=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");f.status:SetPoint("BOTTOMLEFT",18,46);f.status:SetTextColor(unpack(self.C.cyan));f.status:SetWidth(400);f.status:SetJustifyH("LEFT")
 local close=button(f,"CLOSE",100,30);close:SetPoint("BOTTOMRIGHT",-18,12);close:SetScript("OnClick",function()f:Hide()end)
 local action=button(f,"IMPORT",110,30);action:SetPoint("RIGHT",close,"LEFT",-8,0);f.action=action
 local select=button(f,"SELECT ALL",110,30);select:SetPoint("RIGHT",action,"LEFT",-8,0);select:SetScript("OnClick",function()e:SetFocus();e:HighlightText()end);f.select=select
 return f
end

function FG:ShowExport(mapID)
 local f=buildDataFrame(self);f.mode="export";f.title:SetText("FOREVER GATHER // EXPORT");f.sub:SetText(mapID and ("Portable ForeverGather data for "..self:GetZoneName(mapID)..". Copy it anywhere and import it later.") or "Portable ForeverGather backup of every learned map and node. Copy it anywhere and import it later.")
 f.edit:SetText(self:BuildExport(mapID));f.edit:SetCursorPosition(0);f.edit:SetAutoFocus(false);f.status:SetText("FGX v2  •  "..(mapID and "single map" or "all maps"));f.action:Hide();f.select:Show();FG.Theme.Fit(f,670,500);f:SetClampedToScreen(true);f:Show()
end

function FG:ShowImport()
 local f=buildDataFrame(self);f.mode="import";f.title:SetText("FOREVER GATHER // IMPORT");f.sub:SetText("Paste a ForeverGather FGX v2 export below. Existing locations are merged; your learned data is never wiped.");f.edit:SetText("");f.edit:SetAutoFocus(true);f.status:SetText("Waiting for ForeverGather data…");f.select:Hide();f.action:Show();f.action:SetScript("OnClick",function()
  local result,err=FG:ImportText(f.edit:GetText());if not result then f.status:SetText("Import failed: "..tostring(err));return end
  f.status:SetText(string.format("Imported: %d new  •  %d merged  •  %d invalid",result.added,result.merged,result.invalid));FG:Print(string.format("Import complete: %d new locations, %d merged.",result.added,result.merged))
 end);FG.Theme.Fit(f,670,500);f:Show();f.edit:SetFocus()
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
  "TomTom: "..tostring(_G.TomTom~=nil).."   FGX import/export: ready",
  "",
  "|cff3acdd5Runtime|r",
  "Smart Route: "..rtxt,
  string.format("Current session: %d gathers / %.1f per hour",self:GetSessionTotal(),self:GetSessionRate()),
  "Data revision: "..tostring(self.dataRevision or 0).."   Route revision: "..tostring(self.routeRevision or 0),
  "",
  "If real gathering does not record, screenshot this panel after one Mining/Herbalism/Skinning attempt."
 }
 self.diagFrame.body:SetText(table.concat(lines,"\n"));FG.Theme.Fit(self.diagFrame,590,470);self.diagFrame:Show()
end
