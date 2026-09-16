local ADDON, FG = ...
_G.ForeverGather = FG

FG.VERSION = "2.2.0-classic-era"
FG.SCHEMA = 7
FG.MEDIA = "Interface\\AddOns\\ForeverGather\\Media\\"
FG.C = {
 bg={0.024,0.067,0.086,0.985}, panel={0.031,0.106,0.125,0.985}, panel2={0.043,0.145,0.173,0.985},
 gold={0.949,0.776,0.427,1}, cyan={0.212,0.835,0.859,1}, text={0.863,0.906,0.910,1}, muted={0.471,0.592,0.616,1},
 green={0.314,0.902,0.659,1}, red={0.92,0.35,0.31,1}, border={0.482,0.341,0.133,1}, orange={0.95,0.56,0.24,1}
}
FG.KINDS = {
 mining={label="Mining", pin=FG.MEDIA.."Pin_Mining.tga", fallback="Interface\\Icons\\Trade_Mining"},
 herbalism={label="Herbalism", pin=FG.MEDIA.."Pin_Herb.tga", fallback="Interface\\Icons\\Trade_Herbalism"},
 skinning={label="Skinning", pin=FG.MEDIA.."Pin_Skin.tga", fallback="Interface\\Icons\\INV_Misc_Pelt_Wolf_01"},
}

FG.defaults = {
 profile={
  enabled=true, showMinimap=true, showWorldMap=true, showMining=true, showHerbs=true, showSkinning=true,
  showSkinHeat=true, minimapRange=1000, pinScale=0.68, pinAlpha=0.74, maxMinimapPins=48,
  fadeVisited=true, fadeVisitedSeconds=90, hideUnusable=false, toasts=true, autoSession=true,
  showRoute=true, routeThickness=1.20, routeCluster=18, routeLoop=true, routeMaxStops=110,
  routePreferConfirmed=true, autoAdvanceRoute=true, routeArrivalDistance=18,
  showHud=false, hudRange=320, hudRotate=false, hudScale=1.0,
  showFieldBar=true, focusKind="", focusResource="", minimapButton=true, minimapButtonAngle=225,
  diagnostics=false,
 },
 nodes={}, nextID=1,
 stats={mining=0,herbalism=0,skinning=0,sessions=0,imports=0},
 analytics={resources={},zones={},loot={}},
 session={mining=0,herbalism=0,skinning=0,started=0,last=nil,archived=false,loot={},zones={}},
 sessionHistory={},
 route=nil,
 meta={schema=7,firstRun=true,created=0,lastVersion="",lastLogin=0},
}

local function deepMerge(src,dst)
 dst = type(dst)=="table" and dst or {}
 for k,v in pairs(src) do
  if type(v)=="table" then dst[k]=deepMerge(v,dst[k]) elseif dst[k]==nil then dst[k]=v end
 end
 return dst
end

local function countTable(t)
 local n=0; if type(t)~="table" then return 0 end
 for _ in pairs(t) do n=n+1 end
 return n
end

function FG:Print(msg) print("|cffe1b457ForeverGather|r |cff3acdd5»|r "..tostring(msg)) end
function FG:Debug(msg) if self.db and self.db.profile.diagnostics then self:Print("|cff7fdde2DEBUG|r "..tostring(msg)) end end
function FG:Now() return time() end
function FG:GetPos()
 if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return end
 local mapID=C_Map.GetBestMapForUnit("player"); if not mapID then return end
 local pos=C_Map.GetPlayerMapPosition(mapID,"player"); if not pos then return end
 local x,y=pos:GetXY(); if not x or not y or x<=0 or y<=0 or x>=1 or y>=1 then return end
 return mapID,x,y
end
function FG:WorldPos(mapID,x,y)
 if not C_Map or not C_Map.GetWorldPosFromMapPos or not CreateVector2D then return end
 local instance,p=C_Map.GetWorldPosFromMapPos(mapID,CreateVector2D(x,y))
 if p then
  -- C_Map vectors use the opposite axis order from UnitPosition/world-map math.
  -- HereBeDragons uses this same swap: worldX = vector.y, worldY = vector.x.
  return instance,p.y,p.x
 end
end
function FG:GetPlayerWorldPos()
 if not UnitPosition then return end
 local worldY,worldX,_z,instanceID=UnitPosition("player")
 if not worldX or not worldY then return end
 return instanceID,worldX,worldY
end
function FG:Distance(mapID,x1,y1,x2,y2)
 local c1,a,b=self:WorldPos(mapID,x1,y1); local c2,c,d=self:WorldPos(mapID,x2,y2)
 if c1 and c1==c2 and a and b and c and d then local dx,dy=a-c,b-d; return math.sqrt(dx*dx+dy*dy) end
 local dx,dy=(x1-x2)*1000,(y1-y2)*1000; return math.sqrt(dx*dx+dy*dy)
end
function FG:SafeName(s)
 s=tostring(s or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("^%s+",""):gsub("%s+$","")
 return s~="" and s or "Unknown"
end
function FG:KindShown(kind)
 local p=self.db.profile
 return (kind=="mining" and p.showMining) or (kind=="herbalism" and p.showHerbs) or (kind=="skinning" and p.showSkinning)
end
function FG:MatchesFocus(kind,name)
 local p=self.db.profile
 if p.focusKind and p.focusKind~="" and p.focusKind~=kind then return false end
 if p.focusResource and p.focusResource~="" then
  return string.find(string.lower(name or ""),string.lower(p.focusResource),1,true)~=nil
 end
 return true
end
function FG:ShouldShow(kind,r)
 if not self:KindShown(kind) or not self:MatchesFocus(kind,r.name) then return false end
 if self.db.profile.hideUnusable and self.IsUsable and not self:IsUsable(kind,r.name) then return false end
 return true
end
function FG:GetKindTable(mapID,kind,create)
 if create then
  self.db.nodes[mapID]=self.db.nodes[mapID] or {}; self.db.nodes[mapID][kind]=self.db.nodes[mapID][kind] or {}
 end
 return self.db.nodes[mapID] and self.db.nodes[mapID][kind]
end

function FG:InvalidateCaches(mapID,kind)
 self.visibleCache=self.visibleCache or {}
 if mapID then self.visibleCache[mapID]=nil else self.visibleCache={} end
 self.spatial=self.spatial or {}
 if mapID and kind and self.spatial[mapID] then self.spatial[mapID][kind]=nil
 elseif mapID then self.spatial[mapID]=nil
 else self.spatial={} end
 self.dataRevision=(self.dataRevision or 0)+1
end
function FG:SpatialKey(x,y)
 return math.floor((x or 0)*50)..":"..math.floor((y or 0)*50)
end
function FG:BuildSpatial(mapID,kind)
 self.spatial=self.spatial or {}; self.spatial[mapID]=self.spatial[mapID] or {}
 local idx={cells={}}
 local b=self:GetKindTable(mapID,kind,false) or {}
 for _,r in pairs(b) do
  local key=self:SpatialKey(r.x,r.y); idx.cells[key]=idx.cells[key] or {}; idx.cells[key][#idx.cells[key]+1]=r
 end
 self.spatial[mapID][kind]=idx
 return idx
end
function FG:GetSpatial(mapID,kind)
 self.spatial=self.spatial or {}; self.spatial[mapID]=self.spatial[mapID] or {}
 return self.spatial[mapID][kind] or self:BuildSpatial(mapID,kind)
end
function FG:FindNearby(mapID,kind,name,x,y)
 local b=self:GetKindTable(mapID,kind,false); if not b then return end
 local radius=(kind=="skinning") and 18 or 12
 local idx=self:GetSpatial(mapID,kind); local cx,cy=math.floor(x*50),math.floor(y*50)
 local best,bestd
 for gx=cx-1,cx+1 do for gy=cy-1,cy+1 do
  local cell=idx.cells[gx..":"..gy]
  if cell then for _,r in ipairs(cell) do
   local compatible=(r.name==name) or (r.source=="GatherMate2" and string.find(r.name or "","Imported",1,true)) or name=="Unknown" or r.name=="Unknown"
   if compatible then
    local d=self:Distance(mapID,x,y,r.x,r.y)
    if d<=radius and (not bestd or d<bestd) then best,bestd=r,d end
   end
  end end
 end end
 return best,bestd
end

function FG:AddObservation(kind,name,mapID,x,y,source,opts)
 opts=opts or {}
 if not self.KINDS[kind] or not self.db then return end
 if not mapID then mapID,x,y=self:GetPos() end; if not mapID or not x or not y then return end
 name=self:SafeName(name)
 local b=self:GetKindTable(mapID,kind,true); local r=self:FindNearby(mapID,kind,name,x,y)
 if r and opts.noIncrementIfExisting then return r,false end
 local now=self:Now(); local isNew=false
 if not r then
  local id=self.db.nextID or 1; self.db.nextID=id+1; isNew=true
  r={id=id,x=x,y=y,name=name,count=0,hits=0,first=now,last=0,source=source or "learned",respawnCount=0,respawnSum=0,respawnMin=nil,respawnMax=nil,loot={},npcID=opts.npcID,guid=opts.guid}
  b[id]=r
 else
  local total=math.max(r.count or 0,1); r.x=((r.x or x)*total+x)/(total+1); r.y=((r.y or y)*total+y)/(total+1)
  if (r.name=="Unknown" or r.source=="GatherMate2") and name~="Unknown" then r.name=name end
  r.npcID=r.npcID or opts.npcID; r.guid=r.guid or opts.guid
 end
 if r.last and r.last>0 then
  local dt=now-r.last
  if dt>=300 and dt<=14400 then
   r.respawnCount=(r.respawnCount or 0)+1; r.respawnSum=(r.respawnSum or 0)+dt
   r.respawnMin=not r.respawnMin and dt or math.min(r.respawnMin,dt); r.respawnMax=not r.respawnMax and dt or math.max(r.respawnMax,dt)
  end
 end
 r.count=(r.count or 0)+1; r.hits=(r.hits or 0)+1; r.last=now
 if source and source~="GatherMate2" then r.source=source end
 self:InvalidateCaches(mapID,kind)
 if not opts.noStats then
  self.db.stats[kind]=(self.db.stats[kind] or 0)+1
  local s=self.db.session; s[kind]=(s[kind] or 0)+1; s.archived=false
  s.zones=s.zones or {}; s.zones[mapID]=(s.zones[mapID] or 0)+1
  s.last={kind=kind,name=r.name,mapID=mapID,x=x,y=y,at=now,id=r.id}
  if self.RecordAnalytics then self:RecordAnalytics(kind,r.name,mapID) end
 end
 self.visited=self.visited or {}; self.visited[r.id]=nil
 if self.RefreshPins then self:RefreshPins() end; if self.UIRefresh then self:UIRefresh() end
 if not opts.quiet and self.db.profile.toasts and self.Toast then self:Toast(kind,r.name,r,isNew) end
 return r,isNew
end

function FG:DeleteRecord(mapID,kind,id)
 local b=self:GetKindTable(mapID,kind,false); if not b or not b[id] then return false end
 b[id]=nil; self:InvalidateCaches(mapID,kind); if self.RefreshPins then self:RefreshPins() end; return true
end
function FG:Count(kind,mapID)
 local n=0
 for mid,ks in pairs(self.db.nodes or {}) do if not mapID or mid==mapID then
  for k,b in pairs(ks) do if not kind or kind==k then n=n+countTable(b) end end
 end end
 return n
end
function FG:Confidence(r)
 local c=r.count or 1; local imported=r.source=="GatherMate2"
 if imported and c<=1 then return .24,"IMPORTED" end
 if c>=10 then return 1,"MASTERED" elseif c>=6 then return .88,"VERY HIGH" elseif c>=3 then return .72,"HIGH" elseif c>=2 then return .58,"CONFIRMED" else return .42,"LEARNED" end
end
function FG:RespawnText(r)
 if not r.respawnCount or r.respawnCount<2 then return "Learning" end
 local avg=(r.respawnSum or 0)/r.respawnCount
 local lo=(r.respawnMin or avg)/60; local hi=(r.respawnMax or avg)/60
 if r.respawnCount>=4 then return string.format("~%d min  [%d–%d]",math.floor(avg/60+.5),math.floor(lo+.5),math.floor(hi+.5)) end
 return string.format("~%d min (%d samples)",math.floor(avg/60+.5),r.respawnCount)
end
function FG:SessionElapsed()
 local started=(self.db.session and self.db.session.started) or self:Now(); if started<=0 then started=self:Now() end
 return math.max(1,self:Now()-started)
end
function FG:GetSessionTotal(s) s=s or self.db.session; return (s.mining or 0)+(s.herbalism or 0)+(s.skinning or 0) end
function FG:ArchiveSession(reason)
 local s=self.db.session; if not s or s.archived or self:GetSessionTotal(s)<=0 then return end
 local copy={started=s.started,ended=self:Now(),mining=s.mining or 0,herbalism=s.herbalism or 0,skinning=s.skinning or 0,loot=s.loot or {},zones=s.zones or {},reason=reason or "ended"}
 self.db.sessionHistory=self.db.sessionHistory or {}; table.insert(self.db.sessionHistory,1,copy)
 while #self.db.sessionHistory>25 do table.remove(self.db.sessionHistory) end
 s.archived=true
end
function FG:ResetSession(archive)
 if archive~=false then self:ArchiveSession("reset") end
 self.db.session={mining=0,herbalism=0,skinning=0,started=self:Now(),last=nil,archived=false,loot={},zones={}}
 self.db.stats.sessions=(self.db.stats.sessions or 0)+1
 if self.UIRefresh then self:UIRefresh() end; if self.UpdateFieldBar then self:UpdateFieldBar() end
end
function FG:SetFocus(kind,resource)
 self.db.profile.focusKind=kind or ""; self.db.profile.focusResource=self:SafeName(resource or "")
 if self.db.profile.focusResource=="Unknown" then self.db.profile.focusResource="" end
 self:InvalidateCaches(); if self.RefreshPins then self:RefreshPins() end; if self.UpdateHUD then self:UpdateHUD(true) end; if self.UIRefresh then self:UIRefresh() end
end
function FG:ClearFocus()
 self.db.profile.focusKind=""; self.db.profile.focusResource=""; self:InvalidateCaches(); if self.RefreshPins then self:RefreshPins() end; if self.UpdateHUD then self:UpdateHUD(true) end; if self.UIRefresh then self:UIRefresh() end
end
function FG:GetZoneName(mapID)
 local info=C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID); return info and info.name or tostring(mapID or "Unknown")
end
function FG:GetHealthReport()
 local report={nodes=0,invalid=0,maps=0,mining=0,herbalism=0,skinning=0}
 for mapID,ks in pairs(self.db.nodes or {}) do
  report.maps=report.maps+1
  for kind,b in pairs(ks) do for _,r in pairs(b) do
   report.nodes=report.nodes+1; report[kind]=(report[kind] or 0)+1
   if type(mapID)~="number" or not r.x or not r.y or r.x<=0 or r.x>=1 or r.y<=0 or r.y>=1 then report.invalid=report.invalid+1 end
  end end
 end
 return report
end
function FG:PruneInvalid()
 local removed=0
 for mapID,ks in pairs(self.db.nodes or {}) do for kind,b in pairs(ks) do for id,r in pairs(b) do
  if type(mapID)~="number" or not r.x or not r.y or r.x<=0 or r.x>=1 or r.y<=0 or r.y>=1 then b[id]=nil; removed=removed+1 end
 end end end
 if removed>0 then self:InvalidateCaches(); if self.RefreshPins then self:RefreshPins() end end
 return removed
end

function FG:Migrate()
 self.db.meta=self.db.meta or {}; local old=self.db.meta.schema or 0
 local nextID=1
 for mapID,ks in pairs(self.db.nodes or {}) do
  if type(ks)=="table" then for kind,b in pairs(ks) do if type(b)=="table" then
   local normalized={}
   for key,r in pairs(b) do if type(r)=="table" and r.x and r.y then
    r.id=r.id or (type(key)=="number" and key) or nextID; nextID=math.max(nextID,r.id+1); r.loot=r.loot or {}; r.count=r.count or 1; r.hits=r.hits or r.count
    r.respawnCount=r.respawnCount or 0; r.respawnSum=r.respawnSum or 0; r.source=r.source or "learned"; normalized[r.id]=r
   end end
   self.db.nodes[mapID][kind]=normalized
  end end end
 end
 self.db.nextID=math.max(self.db.nextID or 1,nextID); self.db.meta.schema=FG.SCHEMA; self.db.meta.created=self.db.meta.created or self:Now(); self.db.meta.lastVersion=FG.VERSION
 self.db.sessionHistory=self.db.sessionHistory or {}; self.db.analytics.loot=self.db.analytics.loot or {}
 if old<7 then self:Print("Database upgraded to schema "..FG.SCHEMA..".") end
end

SLASH_FOREVERGATHER1="/fg"; SLASH_FOREVERGATHER2="/forevergather"
SlashCmdList.FOREVERGATHER=function(msg)
 local raw=(msg or ""):match("^%s*(.-)%s*$"); local lower=string.lower(raw)
 if lower=="reset" then FG:ResetSession(); FG:Print("Session reset.")
 elseif lower=="refresh" then FG:InvalidateCaches(); FG:RefreshPins(); FG:Print("Pins refreshed.")
 elseif lower=="hud" or lower=="bar" then FG:ToggleFieldBar()
 elseif lower=="bar" then if FG.ToggleFieldBar then FG:ToggleFieldBar() end
 elseif lower=="route" then FG:BuildRoute()
 elseif lower=="route clear" then FG:ClearRoute()
 elseif lower=="route next" then FG:WaypointNextRoute()
 elseif lower=="import gathermate" then FG:ImportGatherMate2()
 elseif lower=="focus clear" then FG:ClearFocus(); FG:Print("Focus cleared.")
 elseif string.sub(lower,1,6)=="focus " then FG.db.profile.focusResource=raw:sub(7); FG:InvalidateCaches(); FG:RefreshPins(); FG:Print("Focus: "..FG.db.profile.focusResource)
 elseif lower=="diag" then if FG.ShowDiagnostics then FG:ShowDiagnostics() end
 elseif lower=="export" then if FG.ShowExport then FG:ShowExport() end
 elseif lower=="prune" then FG:Print("Data Doctor removed "..FG:PruneInvalid().." invalid records.")
 elseif lower=="test mine" then FG:AddObservation("mining","Test Copper Vein")
 elseif lower=="test herb" then FG:AddObservation("herbalism","Test Peacebloom")
 elseif lower=="test skin" then FG:AddObservation("skinning","Test Wolf")
 elseif lower=="help" then FG:Print("/fg • bar • route • route clear • route next • focus <name> • focus clear • reset • import gathermate • diag • export • prune • test mine/herb/skin")
 else FG:ToggleUI() end
end

local E=CreateFrame("Frame")
E:RegisterEvent("ADDON_LOADED"); E:RegisterEvent("PLAYER_ENTERING_WORLD"); E:RegisterEvent("ZONE_CHANGED_NEW_AREA"); E:RegisterEvent("PLAYER_LOGOUT"); E:RegisterEvent("SKILL_LINES_CHANGED")
E:SetScript("OnEvent",function(_,ev,arg)
 if ev=="ADDON_LOADED" and arg==ADDON then
  ForeverGatherDB=deepMerge(FG.defaults,ForeverGatherDB or {}); FG.db=ForeverGatherDB; FG:Migrate(); FG.visited={}; FG.visibleCache={}; FG.spatial={}; FG.dataRevision=1
  FG.db.meta.visualMapVersion=FG.db.meta.visualMapVersion or 0
  if FG.db.meta.visualMapVersion<1 then
   -- RC8 map-first visual migration: learned markers become small hollow rings so Blizzard's live tracking dot stays visible.
   FG.db.profile.pinScale=.78; FG.db.profile.pinAlpha=.78; FG.db.profile.routeThickness=1.25
   FG.db.meta.visualMapVersion=1
  end
  FG.db.meta.lastLogin=FG:Now()
  if FG.db.profile.autoSession or not FG.db.session.started or FG.db.session.started==0 then FG:ResetSession(true) end
  C_Timer.After(.20,function()
   if FG.InitAnalytics then FG:InitAnalytics() end; if FG.InitTracker then FG:InitTracker() end; if FG.InitRoutes then FG:InitRoutes() end; if FG.InitIntegrations then FG:InitIntegrations() end
   if FG.InitMap then FG:InitMap() end; if FG.InitHUD then FG:InitHUD() end; if FG.InitUI then FG:InitUI() end; if FG.InitDataIO then FG:InitDataIO() end
   if FG.RefreshPins then FG:RefreshPins() end
  end)
 elseif ev=="PLAYER_LOGOUT" and FG.db then
  FG:ArchiveSession("logout")
 elseif ev=="SKILL_LINES_CHANGED" and FG.db then
  if FG.InvalidateProfessionCache then FG:InvalidateProfessionCache() end; FG:InvalidateCaches(); if FG.RefreshPins then FG:RefreshPins() end
 elseif (ev=="PLAYER_ENTERING_WORLD" or ev=="ZONE_CHANGED_NEW_AREA") and FG.db then
  FG.visited={}; FG:InvalidateCaches(); C_Timer.After(.45,function() if FG.RefreshPins then FG:RefreshPins() end; if FG.UpdateHUD then FG:UpdateHUD(true) end; if FG.UpdateFieldBar then FG:UpdateFieldBar() end end)
 end
end)
