local spawn = require(game.ServerStorage.spawn)

-- testing multi-return
spawn(function()
	return true, 5, {}
end):thenDo(print):join()

-- testing error handling
spawn(function()
	local x = {}
	local y = 5 / x
	print("this should not run.")
	print("if luau analysis was smart it should've figured that out")
	print("unless its been added in the future")
end):ifError(warn):join()

-- testing timeouts
--# i expect a single false in the output
spawn(task.wait, 3):timeout(1):thenDo(warn)
task.wait(3) -- lets see...

spawn(task.wait, 1):thenCall(print, "i love this world."):thenDo(function()
	return 10 + 8
end):timeout(3):thenDo(warn)
task.wait(3) -- lets see...

-- testing everything (expect timeouts because they just work)
spawn(function()
	-- pairs returns multiple values
	-- the iterative function, table, and initial key
	return pairs {5, 7, 2, "outlier", 4}
end)
	:thenDo(function(iterator, tbl, initKey)
		for k,v in iterator, tbl, initKey do
			print(k,v)
			print(`{k} / {v} is {k / v}`)
		end
	end)
	:thenDo(function()
		print("this code should not run")
	end)
	:ifError(function(err)
		warn("an error occurred:", err)
	end)
	:alwaysDo(function()
		print("do not say i am 7 in discord or someone might report you evn if youre joking")
	end)
	:join()

-- real world applications
-- data store ops
local DataStoreService = game:GetService("DataStoreService")
local PlayerData = DataStoreService:GetDataStore("PlayerData")

local cache = {}

local function playerJoined(plr)
	spawn(PlayerData.GetAsync, PlayerData --[[ self parameter ]], plr.UserId .. "-coins")
		:thenDo(function(coins)
			coins = coins or 100
			print(`{plr.Name} has {coins} coins`)
			cache[plr.UserId] = coins
		end)
		:ifError(function(err)
			warn(`Load failed for player {plr.UserId} ({plr.Name}): {err}`)
		end)
		:join() -- join is not required but it is in this case because this function will get invoked synchronously 
end

local function playerLeft(plr)
	spawn(PlayerData.SetAsync, PlayerData --[[ self parameter ]], plr.UserId .. "-coins", cache[plr.UserId])
		:thenCall(print, `{plr.Name}'s data was saved`)
		:ifError(function(err)
			warn(`Save failed for player {plr.UserId} ({plr.Name}): {err}`)
		end)
end

-- simulate join
-- giving enough data
playerJoined {
	Name = "ILuvUUWU_872",
	UserId = 5813613
}

playerJoined {
	Name = "ILuvOreosAndKetchup",
	UserId = 5113613
}

playerLeft {
	Name = "ILuvOreosAndKetchup",
	UserId = 5113613
}

-- player's data wasn't properly cached
-- this should cause an error
playerLeft {
	Name = "YouHateMeDontYou",
	UserId = 13613
}

-- getting data from a website
local HttpService = game:GetService("HttpService")
spawn(HttpService.GetAsync, HttpService, 'http://example.com')
	:thenDo(function(data)
		print("Data:", '...',data:sub(#data - 100, #data))
	end)
	:ifError(function(err)
		warn("Error while sending GET:", err)
	end)
	:alwaysDo(print, "Requested GET from http://example.com")

--# example.com does not accept POST requests
spawn(HttpService.PostAsync, HttpService, 'http://example.com', "hey")
	:thenDo(function(data)
		print("Response:", '...', data:sub(#data - 100, #data))
	end)
	:ifError(function(err)
		warn("Error while sending POST:", err)
	end)
	:alwaysDo(print, "POST'd to http://example.com")
