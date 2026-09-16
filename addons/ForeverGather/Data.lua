local ADDON,FG=...
FG.REQ={
 mining={ ["Copper Vein"]=1,["Tin Vein"]=65,["Silver Vein"]=75,["Iron Deposit"]=125,["Gold Vein"]=155,["Mithril Deposit"]=175,["Truesilver Deposit"]=230,["Small Thorium Vein"]=245,["Rich Thorium Vein"]=275 },
 herbalism={ ["Peacebloom"]=1,["Silverleaf"]=1,["Earthroot"]=15,["Mageroyal"]=50,["Briarthorn"]=70,["Stranglekelp"]=85,["Bruiseweed"]=100,["Wild Steelbloom"]=115,["Grave Moss"]=120,["Kingsblood"]=125,["Liferoot"]=150,["Fadeleaf"]=160,["Goldthorn"]=170,["Khadgar's Whisker"]=185,["Wintersbite"]=195,["Firebloom"]=205,["Purple Lotus"]=210,["Arthas' Tears"]=220,["Sungrass"]=230,["Blindweed"]=235,["Ghost Mushroom"]=245,["Gromsblood"]=250,["Golden Sansam"]=260,["Dreamfoil"]=270,["Mountain Silversage"]=280,["Plaguebloom"]=285,["Icecap"]=290,["Black Lotus"]=300 }
}
local SPELL={mining=2575,herbalism=2366,skinning=8613}
local profCache={}
local function spellName(id)
 if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
 return GetSpellInfo and GetSpellInfo(id)
end
function FG:InvalidateProfessionCache() profCache={} end
function FG:GetProfessionSkill(kind)
 if profCache[kind]~=nil then return profCache[kind] or nil end
 local wanted=spellName(SPELL[kind]); local english=self.KINDS[kind] and self.KINDS[kind].label
 if GetProfessions and GetProfessionInfo then
  local a,b,c,d,e=GetProfessions()
  local list={a,b,c,d,e}
  for i=1,5 do local idx=list[i]; if idx then
   local name,_,skill=GetProfessionInfo(idx)
   if name and (name==wanted or name==english or (kind=="herbalism" and name=="Herbalism")) then profCache[kind]=skill or false; return skill end
  end end
 end
 if GetNumSkillLines and GetSkillLineInfo then
  for i=1,GetNumSkillLines() do
   local name,isHeader,_,rank=GetSkillLineInfo(i)
   if not isHeader and name and (name==wanted or name==english or (kind=="herbalism" and name=="Herbalism")) then profCache[kind]=rank or false; return rank end
  end
 end
 profCache[kind]=false
end
function FG:HasProfession(kind) return self:GetProfessionSkill(kind)~=nil end
function FG:IsUsable(kind,name)
 local req=self.REQ[kind] and self.REQ[kind][name]; if not req then return true end
 local skill=self:GetProfessionSkill(kind); return not skill or skill>=req
end
function FG:GetRequiredSkill(kind,name) return self.REQ[kind] and self.REQ[kind][name] end
