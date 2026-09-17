local ADDON,FG=...
function FG:InitIntegrations() end

function FG:AddTomTomWaypoint(mapID,x,y,title)
 if not _G.TomTom or not TomTom.AddWaypoint then self:Print("TomTom is not loaded."); return end
 TomTom:AddWaypoint(mapID,x,y,{title=title or "ForeverGather",persistent=false,minimap=true,world=true}); self:Print("TomTom waypoint added.")
end
function FG:WaypointNextRoute()
 local p=self:GetNextRoutePoint(); local mapID=self:GetPos()
 if p and mapID then self:AddTomTomWaypoint(mapID,p.x,p.y,"ForeverGather: "..(p.name or "route stop")) else self:Print("No active route stop in this zone.") end
end
