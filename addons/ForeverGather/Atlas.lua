local ADDON,FG=...
local C=FG.C

local FONT_TITLE="Fonts\\MORPHEUS.TTF"
local FONT_UI="Fonts\\ARIALN.TTF"

local function setFont(obj,size,color,title)
 local ok=obj:SetFont(title and FONT_TITLE or FONT_UI,size,title and "" or "")
 if not ok then obj:SetFontObject(title and _G.GameFontNormalLarge or _G.GameFontHighlightSmall) end
 if color then obj:SetTextColor(unpack(color)) end
end
local function fs(p,text,size,color,title)
 local x=p:CreateFontString(nil,"OVERLAY");setFont(x,size or 12,color or C.text,title);x:SetText(text or "");return x
end
local function skin(f,bg,border)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 f:SetBackdropColor(unpack(bg));f:SetBackdropBorderColor(unpack(border))
end
local function flatButton(parent,text,w,h)
 local b=CreateFrame("Button",nil,parent,"BackdropTemplate")
 b:SetSize(w,h)
 skin(b,{.008,.043,.050,.96},{.12,.34,.36,.56})
 local t=fs(b,text,11,C.text);t:SetPoint("CENTER");b.label=t
 b:SetScript("OnEnter",function(self)self:SetBackdropBorderColor(C.gold[1],C.gold[2],C.gold[3],.82);self.label:SetTextColor(unpack(C.gold))end)
 b:SetScript("OnLeave",function(self)if self.Refresh then self:Refresh() else self:SetBackdropBorderColor(.12,.34,.36,.56);self.label:SetTextColor(unpack(C.text))end end)
 return b
end
local function iconPath(kind)
 if kind=="herbalism" then return FG.MEDIA.."Icon_Herb.tga" end
 if kind=="skinning" then return FG.MEDIA.."Icon_Skin.tga" end
 return FG.MEDIA.."Icon_Mining.tga"
end
local function countTable(t)
 local n=0;if type(t)~="table" then return 0 end;for _ in pairs(t)do n=n+1 end;return n
end
local function sumObservations(bucket)
 local n=0
 if type(bucket)=="table" then for _,r in pairs(bucket) do n=n+(r.count or 1) end end
 return n
end

function FG:GetKnownMaps()
 local out={}
 for mapID,ks in pairs(self.db.nodes or {}) do
  if type(mapID)=="number" and type(ks)=="table" then
   local mining=countTable(ks.mining);local herbalism=countTable(ks.herbalism);local skinning=countTable(ks.skinning)
   local total=mining+herbalism+skinning
   if total>0 then out[#out+1]={mapID=mapID,name=self:GetZoneName(mapID),total=total,mining=mining,herbalism=herbalism,skinning=skinning} end
  end
 end
 table.sort(out,function(a,b)return string.lower(a.name or "")<string.lower(b.name or "") end)
 return out
end

function FG:GetResourceCatalog(kind)
 local byName={}
 for mapID,ks in pairs(self.db.nodes or {}) do
  local b=ks and ks[kind]
  if b then for _,r in pairs(b) do
   local name=self:SafeName(r.name);local key=string.lower(name);local e=byName[key]
   if not e then e={name=name,kind=kind,nodes=0,observations=0,maps={}};byName[key]=e end
   e.nodes=e.nodes+1;e.observations=e.observations+(r.count or 1);e.maps[mapID]=(e.maps[mapID] or 0)+1
  end end
 end
 local out={}
 for _,e in pairs(byName) do e.mapCount=countTable(e.maps);out[#out+1]=e end
 table.sort(out,function(a,b)return string.lower(a.name)<string.lower(b.name) end)
 return out
end

function FG:GetResourcesOnMap(mapID)
 local out={}
 for kind,b in pairs(self.db.nodes[mapID] or {}) do
  local byName={}
  for _,r in pairs(b) do
   local name=self:SafeName(r.name);local key=string.lower(name);local e=byName[key]
   if not e then e={name=name,kind=kind,nodes=0,observations=0};byName[key]=e end
   e.nodes=e.nodes+1;e.observations=e.observations+(r.count or 1)
  end
  for _,e in pairs(byName) do out[#out+1]=e end
 end
 table.sort(out,function(a,b)if a.kind~=b.kind then return a.kind<b.kind end;return string.lower(a.name)<string.lower(b.name) end)
 return out
end

function FG:GetMapsForResource(kind,name)
 local out={};local needle=string.lower(name or "")
 for mapID,ks in pairs(self.db.nodes or {}) do
  local nodes=0;local obs=0
  for _,r in pairs((ks and ks[kind]) or {}) do if string.lower(r.name or "")==needle then nodes=nodes+1;obs=obs+(r.count or 1) end end
  if nodes>0 then out[#out+1]={mapID=mapID,name=self:GetZoneName(mapID),nodes=nodes,observations=obs} end
 end
 table.sort(out,function(a,b)return string.lower(a.name)<string.lower(b.name) end)
 return out
end

function FG:GetMapObservationTotal(mapID)
 local ks=self.db.nodes[mapID] or {}
 return sumObservations(ks.mining)+sumObservations(ks.herbalism)+sumObservations(ks.skinning)
end

