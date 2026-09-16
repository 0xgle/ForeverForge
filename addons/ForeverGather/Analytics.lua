local ADDON,FG=...
function FG:InitAnalytics() end
function FG:RecordAnalytics(kind,name,mapID)
 local a=self.db.analytics; a.resources=a.resources or {}; a.zones=a.zones or {}; a.loot=a.loot or {}
 a.resources[kind]=a.resources[kind] or {}; a.resources[kind][name]=(a.resources[kind][name] or 0)+1
 a.zones[mapID]=a.zones[mapID] or {mining=0,herbalism=0,skinning=0}; a.zones[mapID][kind]=(a.zones[mapID][kind] or 0)+1
end
function FG:GetTopResources(limit,kind)
 local out={}; limit=limit or 6
 for k,t in pairs(self.db.analytics.resources or {}) do if not kind or kind==k then for name,count in pairs(t) do out[#out+1]={kind=k,name=name,count=count} end end end
 table.sort(out,function(a,b)return a.count>b.count end)
 while #out>limit do table.remove(out) end
 return out
end
function FG:GetBestZone(kind)
 local bestMap,best=nil,0
 for mapID,z in pairs(self.db.analytics.zones or {}) do local n=z[kind] or 0; if n>best then best,bestMap=n,mapID end end
 return bestMap,best
end
function FG:AttachLoot(record,itemLink,qty)
 if not record or not itemLink then return end
 local itemID=tonumber(string.match(itemLink,"item:(%d+)")); if not itemID then return end
 qty=qty or 1; record.loot=record.loot or {}; local e=record.loot[itemID] or {count=0,link=itemLink}; e.count=e.count+qty; e.link=itemLink; record.loot[itemID]=e
 local a=self.db.analytics; a.loot=a.loot or {}; local ae=a.loot[itemID] or {count=0,link=itemLink}; ae.count=ae.count+qty; ae.link=itemLink; a.loot[itemID]=ae
 local s=self.db.session; s.loot=s.loot or {}; local se=s.loot[itemID] or {count=0,link=itemLink}; se.count=se.count+qty; se.link=itemLink; s.loot[itemID]=se
end
function FG:GetSessionRate()
 local total=self:GetSessionTotal(); return total/self:SessionElapsed()*3600
end
function FG:GetRecentSession(index) return self.db.sessionHistory and self.db.sessionHistory[index or 1] end
