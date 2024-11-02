local _, class = UnitClass("player")
local charName = UnitName("player")
BB_OVER = BB_OVER or false
BB_LIST = BB_LIST or nil
local current = {}
local BB_wanted = {}
local queue = {}
local currentItem = nil
local timer = CreateFrame("Frame")
local animGroup = timer:CreateAnimationGroup()
local anim = animGroup:CreateAnimation("Animation")
anim:SetDuration(7)
animGroup:SetLooping("NONE")
local tt = CreateFrame("GameTooltip", "BuyBot_TT", nil, "GameTooltipTemplate")
tt:SetOwner(UIParent, "ANCHOR_NONE")

local function p(str)
	if (str) then
		prefix = "|cff0055FFBuyBot: |r"
		suffix = ""
		print(prefix..str..suffix)
	end
end

local function queryNext()
	if next(queue) then
		currentItem = tremove(queue, 1)
		if GetItemInfo(currentItem) then
			return queryNext()
		else
			tt:SetHyperlink("item:"..currentItem)
		end
	else
		currentItem = nil
	end
end

local function OnTooltipSetItem()
	if not currentItem then
		return
	end
	if GetItemInfo(currentItem) then
		if animGroup:IsPlaying() then
			animGroup:Stop()
		end
		queryNext()
	else
		animGroup:Play()
	end
end

local function queryItem(item)
	if GetItemInfo(item) then
		return
	end
	for _, v in ipairs(queue) do
		if item == v then
			return
		end
	end
	tinsert(queue, item)
	queryNext()
end

local function getAllItemInfo()
	for k, v in pairs(BB_wanted) do
		queryItem(k)
	end
end

local function buildList()
	if not BB_LIST then
		BB_LIST = {}
		BB_LIST["general"] = {}
		BB_LIST["classes"] = {}
		BB_LIST["characters"] = {}
	end
	if not BB_LIST["classes"][class] then
		BB_LIST["classes"][class] = {}
	end
	if not BB_LIST["characters"][charName] then
		BB_LIST["characters"][charName] = {}
	end
	BB_wanted = {}
	for k, v in pairs(BB_LIST["general"]) do
		BB_wanted[k] = v
	end
	for k, v in pairs(BB_LIST["classes"][class]) do
		BB_wanted[k] = v
	end
	for k, v in pairs(BB_LIST["characters"][charName]) do
		BB_wanted[k] = v
	end
end

local function getCurrentInfo()
	for k, v in pairs(BB_wanted) do
		current[k] = GetItemCount(k)
	end
end

local function buyAll()
	getCurrentInfo()
	local available = {}
	local currentNames = {}
	local wantedNames = {}
	for k, v in pairs(BB_wanted) do
		if GetItemInfo(k) then
			local name = GetItemInfo(k)
			wantedNames[name] = v
		else
			queryItem(k)
		end
	end
	for k, v in pairs(current) do
		if GetItemInfo(k) then
			local name = GetItemInfo(k)
			currentNames[name] = v
		else
			queryItem(k)
		end
	end
	for i = 1, GetMerchantNumItems(), 1 do
		name = GetMerchantItemInfo(i)
		if (name ~= nil and name ~= "") then
			available[name] = i
		end
	end
	for k, v in pairs(wantedNames) do
		if (available[k] and currentNames[k] < v) then
			_, _, _, quantity, numAvailable = GetMerchantItemInfo(available[k])
			if (numAvailable > 0 or numAvailable == -1) then
				diff = v - currentNames[k]
				if (BB_OVER) then
					num = math.ceil(diff / quantity)
				else
					num = math.floor(diff / quantity)
				end
				if (num > 0 and num >= numAvailable and numAvailable > 0) then
					p("Buying "..numAvailable.." * "..quantity.." "..k)
					BuyMerchantItem(available[k], numAvailable)
				elseif (num > 0 and (num < numAvailable or numAvailable < 0)) then
					p("Buying "..num.." * "..quantity.." "..k)
					BuyMerchantItem(available[k], num)
				end
			end
		end
	end
end

local function eventHandler(self, event, ...)
	if (event=="MERCHANT_SHOW") then
		buyAll()
	elseif (event=="MERCHANT_CLOSED") then
		current = {}
		available = {}
		diff = 0
		num = 0
	elseif (event=="PLAYER_ENTERING_WORLD") then
		buildList()
		getAllItemInfo()
	end
end

local function printMethod()
	if (BB_OVER) then
		p("Method is \"over\"")
	else
		p("Method is \"under\"")
	end
end

local function toggleMethod()
	BB_OVER = not BB_OVER
	printMethod()
end

local function printList(list, listName)
	p("List "..listName..":")
	for k, v in pairs(list) do
		local _, l = GetItemInfo(k)
		l = l or k
		p(v.." * "..l)
	end
	p("--------")
end

local function printAllLists()
	buildList()
	printList(BB_LIST["general"], "general")
	printList(BB_LIST["classes"][class], "classes->"..class)
	printList(BB_LIST["characters"][charName], "characters->"..charName)
end

local function clearList(list)
	local del = false
	if list == "general" or list == "all" then
		BB_LIST["general"] = {}
		del = true
	elseif list == "classes" or list == "class" then
		BB_LIST["classes"][class] = {}
		del = true
	elseif list == "characters" or list == "character" then
		BB_LIST["characters"][charName] = {}
		del = true
	end
	if del then
		buildList()
		p("Cleared list "..list)
	else
		p("Unknown list "..list)
	end
end

local function getItemID(str)
	if str:find("Hitem:") then
		_, _, str = str:find("Hitem:(%d+):")
	end
	return tonumber(str)
end

local function addToList(list, num, item)
	item = getItemID(item)
	if item then
		if list == "general" or list =="all" then
			tinsert(BB_LIST["general"], item, num)
		elseif list == "class" or list == "classes" then
			tinsert(BB_LIST["classes"][class], item, num)
		elseif list == "character" or list == "characters" then
			tinsert(BB_LIST["characters"][charName], item, num)
		end
		p("Adding "..num.." * "..item.." to list "..list)
	else
		p("Invalid item")
	end
	buildList()
	getAllItemInfo()
end

local function removeFromList(list, item)
	iItem = getItemID(item)
	if iItem then
		if list == "general" or list == "all" then
			BB_LIST["general"][iItem] = nil
		elseif list == "class" or list == "classes" then
			BB_LIST["classes"][class][iItem] = nil
		elseif list == "character" or list == "characters" then
			BB_LIST["characters"][charName][iItem] = nil
		end
		p("Removing "..iItem.." from list "..list)
	else
		p("Could not remove "..item.." from list "..list)
	end
	buildList()
end

local function cmd(txt)
	local cmd, a1, a2, a3, a4 = strsplit(" ", txt, 5)
	cmd = cmd or ""
	a1 = a1 or ""
	a2 = a2 or ""
	a3 = a3 or ""
	a4 = a4 or ""
	a5 = a5 or ""
	a6 = a6 or ""
	a7 = a7 or ""
	a8 = a8 or ""
	a9 = a9 or ""
	if cmd == "" then
		p("Commands:")
		p("/buybot method: Print current method")
		p("/buybot method toggle: Toggle method")
		p("/buybot method over: Set method to over")
		p("/buybot method under: Set method to under")
		p("/buybot list: Print current list")
		p("/buybot list add <list> <num> <item>: Add item to list (general, class or character)")
		p("/buybot list remove <list> <item>: Remove item from list (general, class or character)")
		p("/buybot list clear <list>: Clear list (general, class or characters)")
	else
		if cmd == "method" then
			if a1 == "" then
				printMethod()
			else
				if a1 == "toggle" then
					toggleMethod()
				elseif a1 == "over" then
					BB_OVER = true
					printMethod()
				elseif a1 == "under" then
					BB_OVER = false
					printMethod()
				else
					p("Unknown argument for command method")
				end
			end
		elseif cmd == "list" then
			if a1 == "" then
				printAllLists()
			elseif a1 == "clear" and a2 ~= "" then
				clearList(a2)
			elseif a2 ~= "" and a3 ~= "" then
				if (a2 == "general" or a2 == "class" or a2 == "classes" or a2 == "character" or a2 == "characters") and ((a1 == "add" and a4 ~= "") or (a1 == "remove" or a1 == "delete" or a1 == "del")) then
					if a1 == "add" then
						a3 = tonumber(a3)
						if a3 and a4 then
							addToList(a2, a3, a4)
						else
							p("Wrong argument for command list add")
						end
					elseif a1 == "remove" or a1 == "delete" or a1 == "del" then
						a3 = a3.." "..a4
						removeFromList(a2, a3)
					end
				else
					p("Unknown argument for command list")
				end
			else
				p("Missing argument for command list")
			end
		else
			p("Unknown command")
		end
	end
end

animGroup:SetScript("OnFinished", queryNext)
tt:SetScript("OnTooltipSetItem", OnTooltipSetItem)

local frame = CreateFrame("FRAME", "AutoBuy")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("MERCHANT_CLOSED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", eventHandler)
SLASH_BB1 = "/bb"
SLASH_BB2 = "/buybot"
SlashCmdList["BB"] = cmd
SLASH_BUY1 = "/buy"
SlashCmdList["BUY"] = buyCmd