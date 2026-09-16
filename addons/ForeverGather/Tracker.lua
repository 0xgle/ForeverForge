local ADDON,FG=...
local pending,lastRecord=nil,nil
local SPELL_IDS={[2575]="mining",[2366]="herbalism",[8613]="skinning"}
local SPELL_NAMES={ ["Mining"]="mining",["Herb Gathering"]="herbalism",["Herbalism"]="herbalism",["Skinning"]="skinning" }
local diag={sent=0,stopped=0,succeeded=0,failed=0,lootOpened=0,recorded=0,lastEvent="none",lastSpell="none",lastTarget="none"}
local function spellName(id)
 if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
 return GetSpellInfo and GetSpellInfo(id)
end
local function kindForSpell(id) return SPELL_IDS[id] or SPELL_NAMES[spellName(id)] end
local function tooltipName()
 local fs=_G.GameTooltipTextLeft1; local t=fs and fs:GetText(); if t and t~="" then return t end
end
local function validName(v) return type(v)=="string" and v~="" and v~="Unknown" end
local function bestTarget(sent,kind)
 if validName(sent) then return sent end
 local mouse=UnitName and UnitName("mouseover"); local target=UnitName and UnitName("target"); local tip=tooltipName()
 if kind=="skinning" then return mouse or target or tip end
 return tip or sent or mouse or target
end
local function getTargetGUID(name)
 if UnitGUID and UnitName then
  if UnitName("mouseover")==name then return UnitGUID("mouseover") end
  if UnitName("target")==name then return UnitGUID("target") end
 end
end
local function npcIDFromGUID(guid)
 if not guid then return end
 local a,b,c,d,e,f,g=strsplit("-",guid)
 if a=="Creature" or a=="Vehicle" then return tonumber(f) end
end
local function clearPending(reason)
 if reason then FG:Debug("Tracker cleared: "..reason) end
 pending=nil
end
local function scanLoot(record)
 if not record or not GetNumLootItems then return end
 local n=GetNumLootItems() or 0
 for slot=1,n do
  local link=GetLootSlotLink and GetLootSlotLink(slot)
  if link then
   local _,_,qty=GetLootSlotInfo(slot); FG:AttachLoot(record,link,tonumber(qty) or 1)
  end
 end
end
local function finalize()
 if not pending or pending.finalized or not pending.lootOpened then return end
 if not (pending.stopped or pending.succeeded) then return end
 if GetTime()-pending.at>12 then clearPending("expired before finalize"); return end
 pending.finalized=true
 local name=FG:SafeName(pending.name)
 if name=="Unknown" and pending.kind=="skinning" and pending.npcID then name="Creature #"..pending.npcID end
 local r=FG:AddObservation(pending.kind,name,pending.mapID,pending.x,pending.y,"gather",{npcID=pending.npcID,guid=pending.targetGUID})
 if r then
  diag.recorded=diag.recorded+1; lastRecord={record=r,at=GetTime()}; scanLoot(r); C_Timer.After(0,function() scanLoot(r) end)
 end
 clearPending("recorded")
end
function FG:GetTrackerDiagnostics() return diag,pending end
function FG:InitTracker()
 if self.tracker then return end
 local f=CreateFrame("Frame"); self.tracker=f
 f:RegisterEvent("UNIT_SPELLCAST_SENT"); f:RegisterEvent("UNIT_SPELLCAST_STOP"); f:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
 f:RegisterEvent("UNIT_SPELLCAST_FAILED"); f:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED"); f:RegisterEvent("LOOT_OPENED"); f:RegisterEvent("LOOT_CLOSED"); f:RegisterEvent("CHAT_MSG_LOOT")
 f:SetScript("OnEvent",function(_,ev,...)
  diag.lastEvent=ev
  if ev=="UNIT_SPELLCAST_SENT" then
   local unit,target,castGUID,spellID=...; if unit~="player" then return end
   local kind=kindForSpell(spellID); if not kind then return end
   local mapID,x,y=FG:GetPos(); if not mapID then return end
   local name=FG:SafeName(bestTarget(target,kind)); local guid=getTargetGUID(name)
   pending={kind=kind,name=name,mapID=mapID,x=x,y=y,guid=castGUID,spellID=spellID,at=GetTime(),targetGUID=guid,npcID=npcIDFromGUID(guid),stopped=false,succeeded=false,lootOpened=false}
   diag.sent=diag.sent+1; diag.lastSpell=spellName(spellID) or tostring(spellID); diag.lastTarget=name
  elseif ev=="UNIT_SPELLCAST_FAILED" or ev=="UNIT_SPELLCAST_INTERRUPTED" then
   local unit,castGUID=...; if unit=="player" and pending and (not castGUID or castGUID==pending.guid) then diag.failed=diag.failed+1; clearPending(ev) end
  elseif ev=="UNIT_SPELLCAST_SUCCEEDED" then
   local unit,castGUID,spellID=...; if unit=="player" and pending and (not castGUID or castGUID==pending.guid or spellID==pending.spellID) then pending.succeeded=true; diag.succeeded=diag.succeeded+1; finalize() end
  elseif ev=="UNIT_SPELLCAST_STOP" then
   local unit,castGUID=...; if unit=="player" and pending and (not castGUID or castGUID==pending.guid) then pending.stopped=true; pending.stopAt=GetTime(); diag.stopped=diag.stopped+1; finalize() end
  elseif ev=="LOOT_OPENED" then
   if pending and GetTime()-pending.at<12 then pending.lootOpened=true; pending.lootAt=GetTime(); diag.lootOpened=diag.lootOpened+1; finalize() end
  elseif ev=="LOOT_CLOSED" then
   if pending and GetTime()-pending.at>12 then clearPending("loot closed timeout") end
  elseif ev=="CHAT_MSG_LOOT" then
   local msg=...; if lastRecord and GetTime()-lastRecord.at<4 and type(msg)=="string" then
    local link=string.match(msg,"(|c%x+|Hitem:.-|h%[.-%]|h|r)") or string.match(msg,"(|Hitem:.-|h%[.-%]|h)")
    if link then local qty=tonumber(string.match(msg,"x(%d+)%s*$")) or 1; FG:AttachLoot(lastRecord.record,link,qty) end
   end
  end
 end)
 self.pendingWatch=C_Timer.NewTicker(1,function() if pending and GetTime()-pending.at>13 then clearPending("watchdog") end end)
end
