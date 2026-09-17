local ADDON,FG=...
function FG:InitRoutes() end
function FG:ClusterRecords(records,mapID,radius)
 local clusters={}; radius=radius or 18
 for _,r in ipairs(records) do
  local best,bestd
  for _,c in ipairs(clusters) do
   local d=self:Distance(mapID,r.x,r.y,c.x,c.y)
   if d<=radius and (not bestd or d<bestd) then best,bestd=c,d end
  end
  local cf=self:Confidence(r)
  if best then
   local n=best.n+1; best.x=(best.x*best.n+r.x)/n; best.y=(best.y*best.n+r.y)/n; best.n=n
   best.weight=best.weight+(r.count or 1); best.confidence=math.max(best.confidence or 0,cf); if best.name~=r.name then best.name="Mixed nodes" end
  else clusters[#clusters+1]={x=r.x,y=r.y,n=1,weight=r.count or 1,confidence=cf,name=r.name,kind=r.kind,id=r.id} end
 end
 return clusters
end
local function reverseRange(t,i,k) while i<k do t[i],t[k]=t[k],t[i]; i=i+1; k=k-1 end end
function FG:TwoOpt(route,mapID,passes)
 passes=passes or 2; local n=#route; if n<4 then return route end
 for _=1,passes do
  local improved=false
  for i=2,n-2 do for k=i+1,math.min(n-1,i+16) do
   local a,b,c,d=route[i-1],route[i],route[k],route[k+1]
   local old=self:Distance(mapID,a.x,a.y,b.x,b.y)+self:Distance(mapID,c.x,c.y,d.x,d.y)
   local new=self:Distance(mapID,a.x,a.y,c.x,c.y)+self:Distance(mapID,b.x,b.y,d.x,d.y)
   if new+1<old then reverseRange(route,i,k); improved=true end
  end end
  if not improved then break end
 end
 return route
end
function FG:BuildRoute(kind,resource)
 local mapID,px,py=self:GetPos(); if not mapID then self:Print("No map position available."); return end
 kind=kind or (self.db.profile.focusKind~="" and self.db.profile.focusKind or nil)
 resource=resource or (self.db.profile.focusResource~="" and self.db.profile.focusResource or nil)
 local records={}
 for k,b in pairs(self.db.nodes[mapID] or {}) do if not kind or kind==k then for _,r in pairs(b) do
  local cf=self:Confidence(r)
  if self:KindShown(k) and (not resource or string.find(string.lower(r.name or ""),string.lower(resource),1,true)) and (not self.db.profile.routePreferConfirmed or cf>=.40) then
   local c={}; for a,v in pairs(r) do c[a]=v end; c.kind=k; records[#records+1]=c
  end
 end end end
 if #records<2 then self:Print("Need at least 2 matching learned locations in this zone."); return end
 local points=self:ClusterRecords(records,mapID,self.db.profile.routeCluster or 18)
 local maxStops=self.db.profile.routeMaxStops or 110
 if #points>maxStops then table.sort(points,function(a,b) return (a.weight or 1)*(a.confidence or .4)>(b.weight or 1)*(b.confidence or .4) end); while #points>maxStops do table.remove(points) end end
 local route,used={},{}; local cur={x=px,y=py}
 for _=1,#points do
  local bi,bs=nil,nil
  for i,p in ipairs(points) do if not used[i] then
   local d=self:Distance(mapID,cur.x,cur.y,p.x,p.y); local bonus=1+math.min(1.5,(p.weight or 1)*.06)+(p.confidence or .4)*.35
   local score=d/bonus; if not bs or score<bs then bi,bs=i,score end
  end end
  if not bi then break end; used[bi]=true; route[#route+1]=points[bi]; cur=points[bi]
 end
 route=self:TwoOpt(route,mapID,2)
 local dist=0; for i=2,#route do dist=dist+self:Distance(mapID,route[i-1].x,route[i-1].y,route[i].x,route[i].y) end
 if self.db.profile.routeLoop and #route>2 then dist=dist+self:Distance(mapID,route[#route].x,route[#route].y,route[1].x,route[1].y) end
 self.db.route={mapID=mapID,kind=kind or "mixed",resource=resource or "All visible",points=route,created=self:Now(),distance=dist,current=1,completed=0,loop=self.db.profile.routeLoop}
 self.routeRevision=(self.routeRevision or 0)+1
 if self.RefreshPins then self:RefreshPins() end; if self.UpdateHUD then self:UpdateHUD(true) end; if self.UIRefresh then self:UIRefresh() end
 self:Print(string.format("Smart Route built: %d stops, ~%.0f yd%s.",#route,dist,self.db.profile.routeLoop and " loop" or ""))
end
function FG:ClearRoute()
 self.db.route=nil; self.routeRevision=(self.routeRevision or 0)+1
 if self.RefreshPins then self:RefreshPins() end; if self.UpdateHUD then self:UpdateHUD(true) end; if self.UIRefresh then self:UIRefresh() end; self:Print("Route cleared.")
end
function FG:GetNextRoutePoint()
 local r=self.db.route; local mapID,px,py=self:GetPos(); if not r or r.finished or r.mapID~=mapID or not r.points or #r.points==0 then return end
 local idx=math.max(1,math.min(r.current or 1,#r.points)); local p=r.points[idx]; local d=self:Distance(mapID,px,py,p.x,p.y)
 return p,d,idx
end
function FG:AdvanceRoute(automatic)
 local r=self.db.route
 if not r or r.finished or not r.points or #r.points==0 then return end
 r.completed=(r.completed or 0)+1
 local idx=math.max(1,math.min(r.current or 1,#r.points))
 if idx>=#r.points then
  if r.loop and #r.points>1 then r.current=1 else r.finished=true end
 else r.current=idx+1 end
 r.arrivalLatch=automatic and true or nil
 self.routeRevision=(self.routeRevision or 0)+1
 if not automatic then
  if self.RefreshPins then self:RefreshPins() end
  if self.UIRefresh then self:UIRefresh() end
  if self.UpdateFieldBar then self:UpdateFieldBar() end
 end
end
function FG:UpdateRouteProgress()
 local r=self.db.route;if not r or r.finished or not self.db.profile.autoAdvanceRoute then return end
 local p,d=self:GetNextRoutePoint();if not p or not d then return end
 local threshold=self.db.profile.routeArrivalDistance or 18
 -- Require leaving the arrival radius before counting another overlapping stop.
 if d>threshold then r.arrivalLatch=nil end
 if d<=threshold and not r.arrivalLatch then self:AdvanceRoute(true) end
end
