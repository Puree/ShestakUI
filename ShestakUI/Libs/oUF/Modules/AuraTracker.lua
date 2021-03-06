local T, C, L = unpack(select(2, ...))
if C.unitframe.enable ~= true or C.unitframe.show_arena ~= true then return end
local _, ns = ...
local oUF = ns.oUF or oUF

if not oUF then return end

local function Update(object, event, unit)

	if object.unit ~= unit  then return end

	local auraList = T.ArenaControl()
	local priority = 0
	local auraName, auraIcon, auraExpTime
	local index = 1

	-- Buffs
	while ( true ) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitAura(unit, index, "HELPFUL")
		if ( not name ) then break end
		
		if ( auraList[name] and auraList[name] >= priority ) then
			priority = auraList[name]
			auraName = name
			auraIcon = icon
			auraExpTime = expirationTime
		end
		
		index = index+1
	end
	
	index = 1
	
	-- Debuffs 
	while ( true ) do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitAura(unit, index, "HARMFUL")
		if ( not name ) then break end
		
		if ( auraList[name] and auraList[name] >= priority ) then
			priority = auraList[name]
			auraName = name
			auraIcon = icon
			auraExpTime = expirationTime
		end
		
		index = index+1	
	end
	
	if ( auraName ) then -- If an aura is found, display it and set the time left!
		object.AuraTracker.icon:SetTexture(auraIcon)
		object.AuraTracker.timeleft = (auraExpTime-GetTime())
		object.AuraTracker.active = true
	elseif ( not auraName ) then -- No aura found and one is shown? Kill it since it's no longer active!
		object.AuraTracker.icon:SetTexture("")
		object.AuraTracker.text:SetText("")
		object.AuraTracker.active = false
	end
end

local function Enable(object)
	-- if we're not highlighting this unit return
	if not object.AuraTracker then return end

	-- make sure aura scanning is active for this object
	object:RegisterEvent("UNIT_AURA", Update)

	return true
end

local function Disable(object)
	if object.AuraTracker then
		object:UnregisterEvent("UNIT_AURA", Update)
	end
end

oUF:AddElement('AuraTracker', Update, Enable, Disable)