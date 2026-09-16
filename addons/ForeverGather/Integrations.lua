local ADDON,FG=...
function FG:InitIntegrations() end
local function decodeGM2(coord)
 if type(coord)~="number" then return end
 local x=math.floor(coord/1000000)/10000
 local y=math.floor((coord%1000000)/100)/10000
 if x>0 and x<1 and y>0 and y<1 then return x,y end
end
local function gm2Name(kind,nodeID)
 local gm=_G.GatherMate2
 if gm and gm.GetNameForNode then
  local gmKind=kind=="mining" and "Mining" or "Herb Gathering"
  local ok,name=pcall(gm.GetNameForNode,gm,gmKind,nodeID); if ok and name then return name end
 end
 return "Imported "..(kind=="mining" and "mine" or "herb").." #"..tostring(nodeID)
end
function FG:ImportGatherMate2()
 local src={mining=_G.GatherMate2MineDB,herbalism=_G.GatherMate2HerbDB}; local added,merged=0,0
 for kind,db in pairs(src) do if type(db)=="table" then for mapID,entries in pairs(db) do
  if type(mapID)=="number" and type(entries)=="table" then for coord,nodeID in pairs(entries) do
   local x,y=decodeGM2(coord); if x then
    local name=gm2Name(kind,nodeID); local r,isNew=self:AddObservation(kind,name,mapID,x,y,"GatherMate2",{noStats=true,quiet=true,noIncrementIfExisting=true})
    if r then if isNew then added=added+1 else merged=merged+1 end end
   end
  end end
 end end end
 self.db.stats.imports=(self.db.stats.imports or 0)+added; self:InvalidateCaches(); if self.RefreshPins then self:RefreshPins() end
 self:Print(string.format("GatherMate2 import: %d new locations (%d already known).",added,merged))
 return added
end
function FG:AddTomTomWaypoint(mapID,x,y,title)
 if not _G.TomTom or not TomTom.AddWaypoint then self:Print("TomTom is not loaded."); return end
 TomTom:AddWaypoint(mapID,x,y,{title=title or "ForeverGather",persistent=false,minimap=true,world=true}); self:Print("TomTom waypoint added.")
end
function FG:WaypointNextRoute()
 local p=self:GetNextRoutePoint(); local mapID=self:GetPos()
 if p and mapID then self:AddTomTomWaypoint(mapID,p.x,p.y,"ForeverGather: "..(p.name or "route stop")) else self:Print("No active route stop in this zone.") end
end
