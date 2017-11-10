local DUDUGLOW = CreateFrame("frame")
DUDUGLOW:RegisterEvent("CHAT_MSG_LOOT")
DUDUGLOW:RegisterEvent("ADDON_LOADED")
DUDUGLOW:RegisterEvent("PLAYER_ENTERING_WORLD")
SLASH_DUDUGLOW1 = "/duduglow"

function SlashCmdList.DUDUGLOW(msg)
	local args = {}
	args[1], args[2] = string.match(msg, "(%a+)%s*(%d+%.?%d?)")
	args[2] = tonumber(args[2])
	
	if ( args[1] == "glowtime" and type(args[2]) == "number" ) then
		print("glowtime set to "..args[2])
		DUDUGLOW.glowTime = args[2]
		DUDUGLOW_SAVED_VARS.glowTime = args[2]
	elseif ( args[1] == "throttle" and type(args[2]) == "number" ) then
		print("throttle set to", args[2], "("..1/args[2].."fps)")
		DUDUGLOW.throttle = args[2]
		DUDUGLOW_SAVED_VARS.throttle = args[2]
	else
		print("Option with current value:")
		print("how long the glow lingers: /duduglow glowtime", DUDUGLOW.glowTime)
		print("cap update interval: /duduglow throttle", DUDUGLOW.throttle)
	end
end

local function Init(self)
	DUDUGLOW_SAVED_VARS = DUDUGLOW_SAVED_VARS or { glowTime = 5 , throttle = 0.1 }
	self.itemIds = {}
	self.glowTime = DUDUGLOW_SAVED_VARS.glowTime
	self.throttle = DUDUGLOW_SAVED_VARS.throttle
	self.lastUpdate = 0
	self.elapsed = 0
end

local function GetItemId(itemLink)
	if itemLink then
		return select(3, strfind(itemLink, "(%d+):"))
	end
end

local function AddItemId(self, lootstring)
--~ 	local lootstring = ...
    local formatted = lootstring:lower():gsub("%s+", "")
    local itemId = GetItemId(lootstring)
	local validStrings = { "youreceive", "youcreate" }
	
	for i = 1, #validStrings do
		if ( strfind(formatted, validStrings[i]) ) then
			self.itemIds[itemId] = GetTime() + self.glowTime
		end
	end
end

local function GarbageCollection(self) --item isnt set to glow anymore so remove it
	for k, v in pairs(self.itemIds) do
		if GetTime() > v then
			self.itemIds[k] = nil
		end
	end
end

local function GetInventoryCapacity()
	local count = 16
	
	for bag = 1, NUM_BAG_SLOTS do
		count = count + GetContainerNumSlots(bag)
	end
	
	return count
end

local function UpdateInventory(self, itemButton, itemLink)
	itemLink = itemLink or itemButton.item
	local itemId = GetItemId(itemLink)
	
	if ( self.itemIds[itemId] and GetTime() <= self.itemIds[itemId] ) then
		ActionButton_ShowOverlayGlow(itemButton)
	else
		ActionButton_HideOverlayGlow(itemButton)
	end
end

local function BagnonInventory(self) --maps bagnon inventory slots to containerframe
	local count = GetInventoryCapacity()
	local numBagnonCount = 36
	local remainder = math.fmod(count, numBagnonCount)
	local numContainerFrame = floor(count/numBagnonCount)
	
	for f = 1, numContainerFrame do 
		for i = 1, numBagnonCount do
			local itemButton = _G["ContainerFrame"..f.."Item"..i]
			
			UpdateInventory(self, itemButton)
		end
	end
	if remainder > 0 then
		local lastContainer = numContainerFrame + 1
		
		for i = 1, remainder do
			local itemButton = _G["ContainerFrame"..lastContainer.."Item"..i]
			
			UpdateInventory(self, itemButton)
		end
	end
end

local function DefaultInventory(self) --maps inventory slots to containerframe
	for bag = 0, NUM_BAG_SLOTS do
		local bagOffset = bag + 1
		
		for slot = 1, GetContainerNumSlots(bag) do
			local slotNumber = GetContainerNumSlots(bag) - slot + 1
			local itemButton = _G["ContainerFrame"..bagOffset.."Item"..slotNumber]
			local itemLink = GetContainerItemLink(bag, slot)
			
			UpdateInventory(self, itemButton, itemLink)
		end
	end
end

local function OnUpdate(self, elasped) 
	self.lastUpdate = self.lastUpdate + elasped
	if ( self.lastUpdate < self.throttle ) then
		return
	end
	self.elapsed = self.elapsed + self.lastUpdate
	self.lastUpdate = 0
	
	if BagnonFrameinventory then
		BagnonInventory(self)
	else
		DefaultInventory(self)
	end
	GarbageCollection(self)
end

DUDUGLOW:SetScript("OnEvent", function(self, event, arg1)
	if ( event == "CHAT_MSG_LOOT" ) then
		AddItemId(self, arg1)
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		DUDUGLOW:SetScript("OnUpdate", OnUpdate)
	elseif ( event == "ADDON_LOADED" and arg1 == "DUDUGLOW" ) then
		Init(self)
		print("DUDUGLOW loaded: /duduglow for options")
	end
end)
