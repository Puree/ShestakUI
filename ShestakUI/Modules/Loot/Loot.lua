local T, C, L = unpack(select(2, ...))
if not C.loot.lootframe == true then return end

----------------------------------------------------------------------------------------
--	Loot frame(Butsu by Haste)
----------------------------------------------------------------------------------------
local _NAME, _NS = ...
local Butsu = CreateFrame("Button", _NAME)
local db = C.font
local lb = CreateFrame("Button", "ButsuAdv", Butsu, "UIPanelScrollDownButtonTemplate")		
local LDD = CreateFrame("Frame", "ButsuLDD", Butsu, "UIDropDownMenuTemplate")
Butsu:Hide()

Butsu:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)

function Butsu:LOOT_OPENED(event, autoloot)
	self:Show()
	lb:Show()
	
	if(not self:IsShown()) then
		CloseLoot(not autoLoot)
	end

	if(IsFishingLoot()) then
		self.title:SetText(L_LOOT_FISH)
	elseif(not UnitIsFriend("player", "target") and UnitIsDead"target") then
		self.title:SetText(UnitName"target")
	else
		self.title:SetText(LOOT)
	end

	-- Blizzard uses strings here
	if(GetCVar("lootUnderMouse") == "1") then
		local x, y = GetCursorPosition()
		x = x / self:GetEffectiveScale()
		y = y / self:GetEffectiveScale()

		self:ClearAllPoints()
		self:Point("TOPLEFT", nil, "BOTTOMLEFT", x - 40, y + 20)
		self:GetCenter()
		self:Raise()
	end

	local m = 0
	local items = GetNumLootItems()
	if(items > 0) then
		for i=1, items do
			local slot = _NS.slots[i] or _NS.CreateSlot(i)
			local texture, item, quantity, quality, locked = GetLootSlotInfo(i)
			local color = ITEM_QUALITY_COLORS[quality]

			if(LootSlotIsCoin(i)) then
				item = item:gsub("\n", ", ")
			end

			if quantity and (quantity > 1) then
				slot.count:SetText(quantity)
				slot.count:Show()
			else
				slot.count:Hide()
			end
			
			if color then
				slot.iconFrame:SetBackdropBorderColor(color.r, color.g, color.b)
				slot:SetBackdropBorderColor(color.r, color.g, color.b)
				slot.drop:SetVertexColor(color.r, color.g, color.b)
			end
			slot.drop:Show()

			slot.quality = quality
			slot.name:SetText(item)
			if color then
				slot.name:SetTextColor(color.r, color.g, color.b)
			end
			slot.icon:SetTexture(texture)

			if quality then
				m = math.max(m, quality)
			end

			slot:Enable()
			slot:Show()
		end
	else
		local slot = _NS.slots[1] or _NS.CreateSlot(1)
		local color = ITEM_QUALITY_COLORS[0]

		slot.name:SetText(EMPTY)
		slot.name:SetTextColor(color.r, color.g, color.b)
		slot.icon:SetTexture[[Interface\Icons\INV_Misc_Herb_AncientLichen]]

		slot.count:Hide()
		slot.drop:Hide()
		slot:Disable()
		slot:Show()
	end
	self:AnchorSlots()

	local color = ITEM_QUALITY_COLORS[m]
	self:SetBackdropBorderColor(color.r, color.g, color.b, 0.8)
	
	local close = CreateFrame("Button", nil, Butsu, "UIPanelCloseButton")
	close:Width(25)
	close:Height(25)
	close:Point("TOPRIGHT", 0, 1)
	close:SetScript("OnClick", function(self) self:GetParent():Hide() end)
	
	self:Width(C.loot.width)
	self.title:Width(C.loot.width - 45)
	self.title:Height(C.font.loot_font_size)
end
Butsu:RegisterEvent"LOOT_OPENED"

function Butsu:LOOT_SLOT_CLEARED(event, slot)
	if(not self:IsShown()) then return end

	_NS.slots[slot]:Hide()
	self:AnchorSlots()
end
Butsu:RegisterEvent"LOOT_SLOT_CLEARED"

function Butsu:LOOT_CLOSED()
	StaticPopup_Hide"LOOT_BIND"
	self:Hide()
	lb:Hide()

	for _, v in pairs(_NS.slots) do
		v:Hide()
	end
end
Butsu:RegisterEvent"LOOT_CLOSED"

function Butsu:OPEN_MASTER_LOOT_LIST()
	ToggleDropDownMenu(1, nil, GroupLootDropDown, LootFrame.selectedLootButton, 0, 0)
end
Butsu:RegisterEvent"OPEN_MASTER_LOOT_LIST"

function Butsu:UPDATE_MASTER_LOOT_LIST()
	UIDropDownMenu_Refresh(GroupLootDropDown)
end
Butsu:RegisterEvent"UPDATE_MASTER_LOOT_LIST"

do
	local title = Butsu:CreateFontString(nil, "OVERLAY")
	title:SetFont(C.font.loot_font, C.font.loot_font_size, C.font.loot_font_style);
	title:SetShadowOffset(C.font.loot_font_shadow and 1 or 0, C.font.loot_font_shadow and -1 or 0)
	title:SetJustifyH("LEFT")
	title:Point("TOPLEFT", Butsu, "TOPLEFT", 8, -7)
	Butsu.title = title
end

Butsu:SetScript("OnMouseDown", function(self)
	if(IsAltKeyDown()) then
		self:StartMoving()
	end
end)

Butsu:SetScript("OnMouseUp", function(self)
	self:StopMovingOrSizing()
end)

Butsu:SetScript("OnHide", function(self)
	StaticPopup_Hide"CONFIRM_LOOT_DISTRIBUTION"
	CloseLoot()
end)

Butsu:SetMovable(true)
Butsu:RegisterForClicks("anyup")

Butsu:SetParent(UIParent)
Butsu:SetUserPlaced(true)
Butsu:Point(unpack(C.position.loot))
Butsu:SetTemplate("Transparent")

Butsu:SetClampedToScreen(true)
Butsu:SetClampRectInsets(0, 0, 14, 0)
Butsu:SetHitRectInsets(0, 0, -14, 0)
Butsu:SetFrameStrata("HIGH")
Butsu:SetToplevel(true)

----------------------------------------------------------------------------------------
--	Announce loot(lcLoot by RustamIrzaev)
----------------------------------------------------------------------------------------
local function OnLinkClick(self)
    ToggleDropDownMenu(1, nil, LDD, lb, 0, 0)
end

local function LDD_OnClick(self)
    local val = self.value
	Announce(val)
end

function Announce(chn)
    local nums = GetNumLootItems()
    if(nums == 0) then return end
    if UnitIsPlayer("target") or not UnitExists("target") then -- Chests are hard to identify!
		SendChatMessage(L_LOOT_CHEST..":", chn)
	else
		SendChatMessage(L_LOOT_MONSTER.."'"..UnitName("target").."':", chn)
	end
    for i = 1, GetNumLootItems() do
        if(LootSlotIsItem(i)) then
            local link = GetLootSlotLink(i)
            local messlink = "- %s"
            SendChatMessage(format(messlink, link), chn)
        end
    end
end

local function LDD_Initialize()  
    local info = {}
    
    info.text = L_LOOT_ANNOUNCE
    info.notCheckable = true
    info.isTitle = true
    UIDropDownMenu_AddButton(info)
    
    info = {}
    info.text = L_LOOT_TO_RAID
    info.value = "raid"
    info.notCheckable = 1
    info.func = LDD_OnClick
    UIDropDownMenu_AddButton(info)
    
    info = {}
    info.text = L_LOOT_TO_GUILD
    info.value = "guild"
    info.notCheckable = 1
    info.func = LDD_OnClick
    UIDropDownMenu_AddButton(info)
	
	info = {}
    info.text = L_LOOT_TO_PARTY
    info.value = "party"
    info.notCheckable = 1
    info.func = LDD_OnClick
    UIDropDownMenu_AddButton(info)

    info = {}
    info.text = L_LOOT_TO_SAY
    info.value = "say"
    info.notCheckable = 1
    info.func = LDD_OnClick
    UIDropDownMenu_AddButton(info)
    
    info = nil
end

lb:Width(15)
lb:Height(13)
lb:ClearAllPoints()
lb:Point("BOTTOMRIGHT", Butsu, "TOPRIGHT", -21, -18)
lb:SetFrameStrata("TOOLTIP")
lb:RegisterForClicks("RightButtonUp", "LeftButtonUp")
lb:SetScript("OnClick", OnLinkClick)
lb:Hide()
UIDropDownMenu_Initialize(LDD, LDD_Initialize, "MENU")

do
	local slots = {}
	_NS.slots = slots

	local OnEnter = function(self)
		local slot = self:GetID()
		if(LootSlotIsItem(slot)) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetLootItem(slot)
			CursorUpdate(self)
		end

		self.drop:Show()
		self.drop:SetVertexColor(1, 1, 0)
	end

	local OnLeave = function(self)
		local color = ITEM_QUALITY_COLORS[self.quality]
		if color then
			self.drop:SetVertexColor(color.r, color.g, color.b)
		end
		
		GameTooltip:Hide()
		ResetCursor()
	end

	local OnClick = function(self)
		if(IsModifiedClick()) then
			HandleModifiedItemClick(GetLootSlotLink(self:GetID()))
		else
			StaticPopup_Hide"CONFIRM_LOOT_DISTRIBUTION"

			LootFrame.selectedLootButton = self
			LootFrame.selectedSlot = self:GetID()
			LootFrame.selectedQuality = self.quality
			LootFrame.selectedItemName = self.name:GetText()

			LootSlot(self:GetID())
		end
	end

	local OnUpdate = function(self)
		if(GameTooltip:IsOwned(self)) then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetLootItem(self:GetID())
			CursorOnUpdate(self)
		end
	end

	function _NS.CreateSlot(id)
		local frame = CreateFrame("Button", "ButsuSlot"..id, Butsu)
		frame:Height(math.max(C.font.loot_font_size, C.loot.icon_size))
		frame:SetID(id)

		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		frame:SetScript("OnEnter", OnEnter)
		frame:SetScript("OnLeave", OnLeave)
		frame:SetScript("OnClick", OnClick)
		frame:SetScript("OnUpdate", OnUpdate)

		local iconFrame = CreateFrame("Frame", nil, frame)
		iconFrame:Height(C.loot.icon_size)
		iconFrame:Width(C.loot.icon_size)
		iconFrame:SetTemplate("Default")
		iconFrame:Point("LEFT", frame)
		frame.iconFrame = iconFrame

		local icon = iconFrame:CreateTexture(nil, "ARTWORK")
		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		icon:Point("TOPLEFT", 2, -2)
		icon:Point("BOTTOMRIGHT", -2, 2)
		frame.icon = icon

		local count = iconFrame:CreateFontString(nil, "OVERLAY")
		count:SetJustifyH("RIGHT")
		count:Point("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 1, 1)
		count:SetFont(C.font.loot_font, C.font.loot_font_size, C.font.loot_font_style);
		count:SetShadowOffset(C.font.loot_font_shadow and 1 or 0, C.font.loot_font_shadow and -1 or 0)
		count:SetText(1)
		frame.count = count

		local name = frame:CreateFontString(nil, "OVERLAY")
		name:SetJustifyH("LEFT")
		name:Point("LEFT", icon, "RIGHT", 5, 0)
		name:SetNonSpaceWrap(true)
		name:SetFont(C.font.loot_font, C.font.loot_font_size, C.font.loot_font_style);
		name:SetShadowOffset(C.font.loot_font_shadow and 1 or 0, C.font.loot_font_shadow and -1 or 0)
		name:Width(C.loot.width - C.loot.icon_size - 20)
		name:Height(C.font.loot_font_size)
		frame.name = name

		local drop = frame:CreateTexture(nil, "ARTWORK")
		drop:SetTexture(C.media.blank)
		drop:Point("TOPLEFT", 2, -2)
		drop:Point("BOTTOMRIGHT", -2, 2)
		drop:SetAlpha(0.5)
		frame.drop = drop

		frame:SetTemplate("Default")
		
		slots[id] = frame
		return frame
	end

	function Butsu:AnchorSlots()
		local frameSize = math.max(C.loot.icon_size, C.loot.icon_size)
		local shownSlots = 0

		local prevShown
		for i = 1, #slots do
			local frame = slots[i]
			if(frame:IsShown()) then
				frame:ClearAllPoints()
				frame:Point("LEFT", 8, 0)
				frame:Point("RIGHT", -8, 0)
				if(not prevShown) then
					frame:Point("TOPLEFT", self, 8, -25)
				else
					frame:Point("TOP", prevShown, "BOTTOM", 0, -3)
				end

				frame:Height(frameSize)
				shownSlots = shownSlots + 1
				prevShown = frame
			end
		end

		self:Height((shownSlots * (frameSize + 3)) + 30)
	end
end

-- Kill the default loot frame
LootFrame:UnregisterAllEvents()

-- Escape the dungeon
table.insert(UISpecialFrames, "Butsu")

----------------------------------------------------------------------------------------
--	MasterLoot by Ammo
----------------------------------------------------------------------------------------
local hexColors = {}
for k, v in pairs(RAID_CLASS_COLORS) do
	hexColors[k] = string.format("|cff%02x%02x%02x", v.r * 255, v.g * 255, v.b * 255)
end
hexColors["UNKNOWN"] = string.format("|cff%02x%02x%02x", 0.6*255, 0.6*255, 0.6*255)

local playerName = UnitName("player")
local unknownColor = { r = .6, g = .6, b = .6 }
local classesInRaid = {}
local randoms = {}
local function CandidateUnitClass(candidate)
	local class, fileName = UnitClass(candidate)
	if class then
		return class, fileName
	end
	return L_LOOT_UNKNOWN, "UNKNOWN"
end

local function init()
	local candidate, color
	local info = UIDropDownMenu_CreateInfo()
	
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		-- raid class menu
		for i = 1, 40 do
			candidate = GetMasterLootCandidate(i)
			if candidate then
				local class = select(2, CandidateUnitClass(candidate))
				if class == UIDROPDOWNMENU_MENU_VALUE then -- we check for not class adding everyone that left the raid to every menu to prevent not being able to loot to them
					-- Add candidate button
					info.text = candidate -- coloredNames[candidate]
					info.colorCode = hexColors[class] or hexColors["UNKOWN"]
					info.textHeight = 12
					info.value = i
					info.notCheckable = 1
					info.disabled = nil
					info.func = GroupLootDropDown_GiveLoot
					UIDropDownMenu_AddButton(info,UIDROPDOWNMENU_MENU_LEVEL)
				end
			end
		end
		return
	end

	info.isTitle = 1
	info.text = GIVE_LOOT
	info.textHeight = 12
	info.notCheckable = 1
	info.disabled = nil
	info.notClickable = nil
	UIDropDownMenu_AddButton(info)
	
	if ( GetNumRaidMembers() > 0 ) then
		-- In a raid

		for k, v in pairs(classesInRaid) do
			classesInRaid[k] = nil
		end
		for i = 1, 40 do
			candidate = GetMasterLootCandidate(i)
			if candidate then
				local cname, class = CandidateUnitClass(candidate)
				classesInRaid[class] = cname
			end		
		end

		for k, v in pairs(classesInRaid) do
			info.isTitle = nil
			info.text = v -- classColors[k]..v.."|r"
			info.colorCode = hexColors[k] or hexColors["UNKOWN"]
			info.textHeight = 12
			info.hasArrow = 1
			info.notCheckable = 1
			info.value = k
			info.func = nil
			info.disabled = nil
			UIDropDownMenu_AddButton(info)
		end
	else
		-- In a party
		for i=1, MAX_PARTY_MEMBERS+1, 1 do
			candidate = GetMasterLootCandidate(i)
			if candidate then
				-- Add candidate button
				info.text = candidate -- coloredNames[candidate]
				info.colorCode = hexColors[select(2,CandidateUnitClass(candidate))] or hexColors["UNKOWN"]
				info.textHeight = 12
				info.value = i
				info.notCheckable = 1
				info.hasArrow = nil
				info.isTitle = nil
				info.disabled = nil
				info.func = GroupLootDropDown_GiveLoot
				UIDropDownMenu_AddButton(info)
			end
		end
	end
	
	for k, v in pairs(randoms) do randoms[k] = nil end
	for i = 1, 40 do
		candidate = GetMasterLootCandidate(i)
		if candidate then
			table.insert(randoms, i)
		end
	end
	if #randoms > 0 then
		info.colorCode = "|cffffffff"
		info.isTitle = nil
		info.textHeight = 12
		info.value = randoms[math.random(1, #randoms)]
		info.notCheckable = 1
		info.text = L_LOOT_RANDOM
		info.func = GroupLootDropDown_GiveLoot
		info.icon = nil
		UIDropDownMenu_AddButton(info)
	end
	for i = 1, 40 do
		candidate = GetMasterLootCandidate(i)
		if candidate and candidate == playerName then
			info.colorCode = hexColors[select(2,CandidateUnitClass(candidate))] or hexColors["UNKOWN"]
			info.isTitle = nil
			info.textHeight = 12
			info.value = i
			info.notCheckable = 1
			info.text = L_LOOT_SELF
			info.func = GroupLootDropDown_GiveLoot
			info.icon = nil
			UIDropDownMenu_AddButton(info)
		end
	end
end

UIDropDownMenu_Initialize(GroupLootDropDown, init, "MENU")