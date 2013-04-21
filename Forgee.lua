--[[
Forgee library BETA 2013.02.28
To use these functions paste: dofile("Forgee.lua")
at the top of your script.

Forum thread: http://forums.xenobot.net/showthread.php?2392-Lua-functions-by-Forgee
Facebook: http://facebook.com/forgee.xenobot
]]

----------------------------------------------------------------------------
------------------------------ Self Class ----------------------------------
----------------------------------------------------------------------------
if Forgee then
	return print("Forgee's lib is already loaded. Use dofile() correctly!")
end

Forgee = {}

-- getMonstersAround(4, "Frost Dragon", "Frost Dragon Hatchling")
function getMonstersAround(radius, ...)
	local t = {...}
	local monsters = {}
	local targets = Self.GetTargets(radius)
	if #t > 0 then
		for i = 1, #targets do
			local creature = targets[i] -- Let's find us a creature
			if table.contains(t, creature:Name()) then
				table.insert(monsters, creature)
			end
		end
		return monsters
	else
		return targets
	end
end

-- getPlayersAround(7, "DarkstaR", "Syntax")
-- getPlayersAround({7, true}) - also gets players from floors above and below, replaces xrayPlayersAround(7).
function getPlayersAround(radius, ...)
	local t = {...}
	local players = {}
	if type(radius) == "table" then
		range, multiFloor = radius[1], radius[2]
	else
		range, multiFloor = radius, false
	end
	local spectators = Self.GetSpectators()
	for i = 1, #spectators do
		local creature = spectators[i]
		if creature:isPlayer() and creature:DistanceFromSelf() <= range then
			if not table.contains(t, creature:Name()) then
				table.insert(players, creature)
			end
		end
	end
	return players
end

--[[
Usage:
We can find all info the bot can get about a creature.
If you enter names after the radius it will work as a "whitelist".

players = getPlayersAround(8, "DarkstaR", "Syntax")
if #players > 0 then
	for i = #players do
		creature = players[i]
		if creature:HealthPercent() < 60 then
			~do something
		end
	end
end
]]

-- Compatibility
function xrayPlayersAround(radius)
	return getPlayersAround({radius, true})
end

-- Count monsters around. monstersAround(5, "Frost Dragon") will count only Frost Dragons within a 5 sqm radius.
-- You can now use the optional multiFloor argument by passing radius as a table. monstersAround({5, true}, "Frost Dragon")
function monstersAround(radius, ...)
	if getMonstersAround(radius, ...) then
		return #getMonstersAround(radius, ...)
	else
		return 0
	end
end
-- Count players around. Listed names are excluded from the count.
function playersAround(radius, ...)
	if getPlayersAround(radius, ...) then
		return #getPlayersAround(radius, ...)
	else
		return 0
	end
end

--[ Container functions ]--
--[[
Since we now can close a container instead of using hotkeys, cascaded backpacks no longer has to be the same colour. Yay!
You can close specific backpacks by entering the index, id or name of backpacks to close.
]]
function closeBackpacks(...)
	local backpacks = {...}
	local indexes = Container.GetIndexes()
	if #backpacks > 0 then
		for i = #backpacks, 1, -1 do
			if type(backpacks[i]) == "table" then
				if type(backpacks[i][1]) == "string" then
					tmpBP = Container.GetByName(backpacks[i][1])
				elseif backpacks[i][1] < 18 then
					tmpBP = Container.GetFromIndex(backpacks[i][1])
				else
					tmpBP = Container.GetByID(backpacks[i][1])
				end
			elseif type(backpacks[i]) == "string" then
				tmpBP = Container.GetByName(backpacks[i])
			elseif backpacks[i] < 18 then
				tmpBP = Container.GetFromIndex(backpacks[i])
			else
				tmpBP = Container.GetByID(backpacks[i])
			end
			tmpBP:Close()
			wait(200, 500)
		end
	else
		Self.CloseContainers()
	end
end

--[[
openBackpacks() -- Will open the bp in your backpack slot.
openBackpacks({9602, 0}) -- Will open an orange bp (9602) inside a your main (first open) backpack.
openBackpacks(9602, {8860, 1}) -- Will first open an orage bp inside the first container/main bp if open. If Main bp is not open it will open that first. Then opens a Brocade Backpack in the second open container ().
]]
function openBackpacks(...)
	local backpacks = {...} -- List of backpacks to open.
    local open = Container.GetIndexes() -- List of already open backpacks.
    local main = Container.GetFirst() -- First open container is assumed to be main backpack (will be 0 if no container is open).
    local toOpen = #backpacks -- Number of backpacks we need to open (used to check success).
	local bps = {} -- A place to store the backpacks to open by container:UseItem(), if any. Why not always use :OpenChildren()? This way I can open bps by their relative position instead of id, so you don't have to worry about colours anymore.
    if main:ID() == 0 then -- If no backpack is open, we need to open main.
		if backpacks[1] ~= Self.Backpack().id then
			toOpen = toOpen + 1
		end
		repeat -- Open main backpack.
			wait(400, 900)
		until Self.OpenMainBackpack():ID() > 0
		main = Container.GetFirst()
    end
	if #backpacks > 0 then
		for i = 1, #backpacks do
			if type(backpacks[i]) == "table" then
				bp, minimize = backpacks[i][1], backpacks[i][2]
			else
				bp, minimize = backpacks[i], false
			end
		end
		if type(bp) == "number" then
			if bp <= 20 then
				openByIndex(main, unpack(backpacks))
			else
				main:OpenChildren(unpack(backpacks))
			end
		else
			main:OpenChildren(unpack(backpacks))
		end	
	end
	wait(400)
	if #open + toOpen == #Container.GetIndexes() then
		return true
	end
	return false	
end

function openByIndex(parent, ...)
	local bps = {}
	-- Look for containers in main backpack.
	for i = 0, parent:ItemCount() do
		local thing = parent:GetItemData(i)
		if Item.isContainer(thing.id) then
			table.insert(bps, i)
		end
	end

	for index, bp in pairs({...}) do
		if type(bp) == "table" then
			spot, minimize = bps[bp[1]], bp[2]
		else
			spot, minimize = bps[bp], false
		end
		parent:UseItem(spot)
		if minimize then
			wait(700, 1500)
			Container.GetLast():Minimize()
		end
		wait(500, 1500)
	end
end

--[[
Returns a table containing the ids of opened backpacks in order.
open = getOpenBackpacks()
open[1] -> first backpack
open[2] -> second backpack, etc.
]]
function getOpenBackpacks()
	local indexes = Container.GetIndexes() -- Find index for all open backpacks
	local open = {} -- Create a place to store our open backpacks
	for i = 1, #indexes do -- Search all open backpacks
		tmpBP = Container.GetFromIndex(indexes[i])
		table.insert(open, tmpBP:ID()) -- Store this backpack
	end
	return open -- Return found backpacks
end

--[[
resetBackpacks(reset)
If reset is specified it will reset the number of backpacks specified. resetBackpacks(1) will reset the last opened backpack, resetBackpacks(2) the last 2 etc.
Empty argument resets all open backpacks.
Checks if all backpacks were reopened correctly. If not it will start over up to 3 times. If it failed after 3 tries it returns false (true if it succeeds).
]]
function resetBackpacks(reset, minimize)
    Walker.Stop()
    local open = {} -- Create a table to hold backpack list
    local indexes = Container.GetIndexes() -- Get indexes of open backpacks.
    if reset then
		if type(reset) == "boolean" then
			minimize = reset
			for i = 1, #indexes do
				table.insert(open, indexes[i])
			end
		elseif reset > 0 and reset < #indexes then
			for i = (#indexes-reset)+1, #indexes do
				table.insert(open, indexes[i])
            end
        else
			for i = 2, #indexes do -- If 'reset' is above the number of open backpacks we should reset all.
				table.insert(open, indexes[i])
			end
        end
    else
        for i = 2, #indexes do -- If 'reset' is nil (empty argument) we should reset all backpacks.
			table.insert(open, indexes[i])
		end
    end
    local tries = 3 -- Give the script 3 tries to achieve a successful reset.
	local close = open
	if minimize then
		for i = 1, #open do
			open[i] = {open[i], true}
		end
	end	
		
    repeat
        if reset then
			if type(reset) == "number" then
				if reset > 0 and reset < #indexes then
					closeBackpacks(unpack(close)) -- Close selected backpacks
				else
					Self.CloseContainers() -- Close all backpacks.
				end
			elseif type(reset) == "boolean" then
				Self.CloseContainers() -- Close all backpacks.
			end
        else
            Self.CloseContainers() -- Close all backpacks
        end
        wait(600, 800) -- Wait a little while		
        local reopen = openBackpacks(unpack(open)) -- I store the return from openBackpacks, true if successfull, false otherwise
        if tries == 0 then -- Check how many tries the function has left
            print("BackpackReset failed!") -- Tell the user that reset has failed
            return false
        end
        tries = tries - 1 -- One try has been spent
		wait(100,200)
    until reopen -- If reopen is true it means all backpacks were opened successfully and function is done
    Walker.Start()
    return true
end

function sellItemsDownTo(item, count)
	return Self.ShopSellItem(Self.ShopGetItemSaleCount(item) - count)
end

----------------------------------------------------
-----------[ Working with ground items ]------------
----------------------------------------------------

-- openDoor(direction[, key])
-- also accepts position as a table, openDoor({x, y, z}) or as normal x, y, z
function openDoor(x, y, z, keyid)
	if not x then -- assumes doorpos is 1sqm ahead in the direction the char is facing
		pos = Self.LookPos(1)
	elseif type(x) == "table" then
		pos = {x = x[1], x = x[2], z = x[3]}
		keyid = y
	elseif x < 50 then
		pos = getPositionFromDirection(Self.Position(), x, 1)
		keyid = y
	else
		pos = {x = x, y = y, z = z}
	end
	local door = Map.GetTopUseItem(pos.x, pos.y, pos.z)
	if table.contains(CLOSED_DOORS, door.id) then -- door is closed
		local tries = 0
		if keyid then
			local spot = getSpotByID(keyid)
			if spot then
				repeat
					if tries >= 3 then
						print("OpenDoor: Failed to open door!")
						return false
					end
					Container:UseItemWithGround(spot, pos.x, pos.y, pos.z)
					wait(500, 800)
					door = Map.GetTopUseItem(pos.x, pos.y, pos.z)
					tries = tries + 1
				until table.contains(OPENED_DOORS, door.id)
			else
				print("OpenDoor: Could not find key %s.", keyid)
				return false
			end
		else
			repeat
				if tries >= 3 then
					print("OpenDoor: Failed to open door!  Is it locked?")
					return false
				end
				Self.UseItemFromGround(pos.x, pos.y, pos.z)
				wait(500, 800)
				door = Map.GetTopUseItem(pos.x, pos.y, pos.z)
				tries = tries + 1
			until table.contains(OPENED_DOORS, door.id)
		end
	end
	return true
end

-- Same usage as openDoor
function closeDoor(x, y, z, keyid)
	if not x then -- assumes doorpos is 1sqm ahead in the direction the char is facing
		pos = Self.LookPos(1)
	elseif type(x) == "table" then
		pos = {x = x[1], x = x[2], z = x[3]}
		keyid = y
	elseif x < 50 then
		pos = getPositionFromDirection(Self.Position(), x, 1)
		keyid = y
	else
		pos = {x = x, y = y, z = z}
	end
	local door = Map.GetTopUseItem(pos.x, pos.y, pos.z)
	if table.contains(OPENED_DOORS, door.id) then -- door is open
		if keyid then
			spot = getSpotByID(keyid)
			repeat
				Container:UseItemWithGround(spot, pos.x, pos.y, pos.z)
				wait(500, 800)
				door = Map.GetTopUseItem(pos.x, pos.y, pos.z)
			until table.contains(CLOSED_DOORS, door.id)
		else
			repeat
				Self.UseItemFromGround(pos.x, pos.y, pos.z)
				wait(500, 800)
				door = Map.GetTopUseItem(pos.x, pos.y, pos.z)
			until table.contains(CLOSED_DOORS, door.id)
		end
	end
	return true
end

function skinCreature(tool, range, ...)
	if type(tool) == "string" then
		tool = Item.GetID(tool)
	end
	if Self.ItemCount(tool) == 0 then
		print("Could not find %s in any open container.", Item.GetName(tool))
		return false
	end
	local bodies = {...}
	for i = 1, #bodies do
		local pos = findUseItem(bodies[i])
		if pos ~= 0 then 
			if Self.DistanceFromPosition(pos.x, pos.y, pos.z) <= range then
				Walker.Stop()
				setLooterEnabled(false)
				while getDistanceBetween(Self.Position(), pos) > 1 do
					Self.UseItemWithGround(tool, pos.x, pos.y, pos.z)
					wait(1500, 2500)
				end
				Walker.Start()
				setLooterEnabled(true)
				return 1
			end
		end
	end
	return 0
end

Forgee.Skin = function (range, ...)
	return skinCreature(5908, range, ...)
end

Forgee.Stake = function (range, ...)
	return skinCreature(5942, range, ...)
end

Forgee.Fish = function (range, ...)
	return skinCreature(3483, range, ...)
end

Forgee.AutoFish = function (miss)
	local function findWater()
		local FISH_POS = {}
		local EMPTY_POS = {}
		local WATER_FISH = {4597, 4598, 4599, 4601, 4602}
		local WATER_EMPTY = {4603, 4604, 4605, 4606, 4607, 4608, 4609, 4610, 4611, 4612, 4613}
		for x = -7, 7 do
			for y = -5, 5 do
				tile = Map.GetTopUseItem(Self.Position().x + x, Self.Position().y + y, Self.Position().z)
				if table.contains(WATER_FISH, tile.id) then
					table.insert(FISH_POS, {x = Self.Position().x + x, y = Self.Position().y + y, z = Self.Position().z})
				elseif table.contains(WATER_EMPTY, tile.id) then
					table.insert(EMPTY_POS, {x = Self.Position().x + x, y = Self.Position().y + y, z = Self.Position().z})
				end
			end
		end
		return FISH_POS, EMPTY_POS
	end
	
	if Self.ItemCount(3492) > 0 then
		local oldCount = Self.ItemCount(3492)
		if not pos or pos.x ~= Self.Position().x or pos.y ~= Self.Position().y then
			fish, empty = findWater()
			pos = Self.Position()
		end
		if miss and type(miss) ~= 'boolean' then
			print("AutoFish: Invalid agument. Valid arguments are 'true' or 'false'.")
			return false
		end
		if miss then
			for i = 1, #empty do
				table.insert(fish, empty[i])
			end
		end
		if #fish > 0 then
			local spot = math.random(1, #fish)
			local tile = Map.GetTopUseItem(fish[spot].x, fish[spot].y, fish[spot].z)
			Self.UseItemWithGround(Item.GetID("Fishing rod"), fish[spot].x, fish[spot].y, fish[spot].z)
			sleep(500)
			if Self.ItemCount(3492) < oldCount then
				result = 2
			else
				result = 1
			end
		end
		wait(500, 800)
	end
	return result or 0
end

-- Move items from a specified square to under yourself until an accepted id is visible.
-- untrash(x, y, acceptedid[, ...])
function untrash(x, y, ...)
	local ACCEPTED_IDS = {...}
	while not table.contains(ACCEPTED_IDS, Map.GetTopMoveItem(x, y, Self.Position().z).id) do
		Map.MoveItem(x, y, Self.Position().x, Self.Position().y)
		wait(400, 600)
	end
	return 1
end

-- Move items from depot until the depot is visible. (You have to be facing the depot.)
-- Forgee.ReachDepot does this automatically, if needed.
function untrashDepot()
	return untrash(Self.LookPos().x, Self.LookPos().y, 3497, 3498, 3499, 3500)
end

-- Find a free depot and walk there. Built in untrasher.
Forgee.ReachDepot = function (tries)
	local tries = tries or 3
	Walker.Stop()
	local DepotIDs = {3497, 3498, 3499, 3500}
	local DepotPos = {}
	for i = 1, #DepotIDs do
		local dps = getUseItems(DepotIDs[i])
		for j = 1, #dps do
			table.insert(DepotPos, dps[j])
		end
	end
	local function gotoDepot()
		local pos = Self.Position()
		print("Depots found: " .. tostring(#DepotPos))
		for i = 1, #DepotPos do
			location = DepotPos[i]
			Self.UseItemFromGround(location.x, location.y, location.z)
			wait(1000, 2000)
			if Self.DistanceFromPosition(pos.x, pos.y, pos.z) >= 1 then
				wait(5000, 6000)
				if Self.DistanceFromPosition(location.x, location.y, location.z) == 1 then
					untrashDepot()
					Walker.Start()
					return true
				end
			else
				print("Something is blocking the path. Trying next depot.")
			end
		end
		return false
	end
	
	repeat
		reachedDP = gotoDepot()
		if reachedDP then
			return true
		end
		tries = tries - 1
		sleep(100)
		print("Attempt to reach depot was unsuccessfull. " .. tries .. " tries left.")
	until tries <= 0

	return false
end

findUseItem = function (id)
	if type(id) == "string" then
		id = Item.GetID(id)
	end
	local pos = Self.Position()
	for x = -7, 7 do
		for y = -5, 5 do
			if Map.GetTopUseItem(pos.x + x, pos.y + y, pos.z).id == id then
				itemPos = {x = pos.x + x, y = pos.y + y, z = pos.z}
				return itemPos
			end
		end
	end
	return 0
end

findMoveItem = function (id)
	if type(id) == "string" then
		id = Item.GetID(id)
	end
	local pos = Self.Position()
	for x = -7, 7 do
		for y = -5, 5 do
			if Map.GetTopMoveItem(pos.x + x, pos.y + y, pos.z).id == id then
				itemPos = {x = pos.x + x, y = pos.y + y, z = pos.z}
				return itemPos
			end
		end
	end
	return 0
end

getUseItems = function (id)
    if type(id) == "string" then
        id = Item.GetID(id)
    end
    local pos = Self.Position()
	local store = {}
    for x = -7, 7 do
        for y = -5, 5 do
            if Map.GetTopUseItem(pos.x + x, pos.y + y, pos.z).id == id then
                itemPos = {x = pos.x + x, y = pos.y + y, z = pos.z}
				table.insert(store, itemPos)
            end
        end
    end
    return store
end

getMoveItems = function (id)
    if type(id) == "string" then
        id = Item.GetID(id)
    end
    local pos = Self.Position()
	local store = {}
    for x = -7, 7 do
        for y = -5, 5 do
            if Map.GetTopMoveItem(pos.x + x, pos.y + y, pos.z).id == id then
                itemPos = {x = pos.x + x, y = pos.y + y, z = pos.z}
				table.insert(store, itemPos)
            end
        end
    end
    return store
end

----------------------------------------------------
-------------------[ Item Tools ]-------------------
----------------------------------------------------

-- getSpotByID(id[, container]) Container name/index is optional.
function getSpotByID(id, container)
	if container then
		if type(container) == "string" then
			cont = Container.GetByName(container)
		elseif type(container) == "number" then
			cont = Container.GetFromIndex(container)
		end
	else
		cont = Container.GetFirst()
	end
	while cont:isOpen() do
		for spot = 0, cont:ItemCount() do
			item = cont:GetItemData(spot)
			if item.id == id then
				return spot, cont
			end
		end
		if container then
			--print("GetSpotByID: Item of id " .. id .. " could not be found in " .. cont:Name() .. ".")
			return false
		else
			cont = cont:GetNext()
		end
	end
	--print("GetSpotByID: Item of id " .. id .. " could not be found in any open container.")
	return false
end


-------------------------------------------------------------
-----------------------[ War tools ]-------------------------
-------------------------------------------------------------
-- [NOT TESTED] --
function warEnemies(range)
	p = getPlayersAround(range)
	enemies = {}
	for i = 1, #p do
		if p[i]:isWarEnemy() then
			table.insert(enemies, p[i])
		end
	end
	return #enemies
end

function warAllies(range)
	p = getPlayersAround(range)
	allies = {}
	for i = 1, #p do
		if p[i]:isWarAlly() then
			table.insert(allies, p[i])
		end
	end
	return #allies
end

function getWarAllies(range)
	p = getPlayersAround(range)
	allies = {}
	for i = 1, #p do
		if p[i]:isWarAlly() then
			table.insert(allies, p[i])
		end
	end
	if #allies > 0 then
		return allies
	else
		return false
	end
end

function getWarEnemies(range)
	p = getPlayersAround(range)
	enemies = {}
	for i = 1, #p do
		local player = p[i]
		if player:isWarEnemy() then
			table.insert(enemies, player)
		end
	end
	if #enemies > 0 then
		return enemies
	else
		return false
	end
end

-- [Naming redundancies] --
Forgee.GetMonstersAround = getMonstersAround
Forgee.MonstersAround = monstersAround
Forgee.GetPlayersAround = getPlayersAround
Forgee.PlayersAround = playersAround
Forgee.BuyItemsUpTo = Self.ShopBuyItemsUpTo
Self.BuyItemsUpTo = Self.ShopBuyItemsUpTo
Forgee.SellItemsDownTo = sellItemsDownTo
Forgee.GetSpotByID = getSpotByID

Forgee.CloseBackpacks = closeBackpacks
Forgee.OpenBackpacks = openBackpacks
Forgee.ResetBackpacks = resetBackpacks
Forgee.GetOpenBackpacks = getOpenBackpacks

Forgee.OpenDoor = openDoor
Forgee.CloseDoor = closeDoor

Forgee.WarEnemies = warEnemies
Forgee.WarAllies = warAllies
Forgee.GetWarEnemies = getWarEnemies
Forgee.GetWarAllies = getWarAllies