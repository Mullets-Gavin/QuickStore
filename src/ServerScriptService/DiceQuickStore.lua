--[[
	@Author: Gavin "Mullets" Rosenthal
	@Desc: A light weight varient of DiceDataStore for one purpose
--]]

--// logic
local QuickStore = {}
QuickStore.Default = {}
QuickStore.Cache = {}
QuickStore.Key = 'mulletmafiadev'
QuickStore.Queue = {}
QuickStore.Query = false
QuickStore.Types = {
	['Save'] = 0;
	['Load'] = 1;
}

--// services
local Services = setmetatable({}, {__index = function(cache, serviceName)
	cache[serviceName] = game:GetService(serviceName)
	return cache[serviceName]
end})

--// functions
local function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function RunQueue()
	if QuickStore.Query then
		repeat
			local tempQueue = {}
			for index = 1, #QuickStore.Queue do
				local selectQueue = QuickStore.Queue[index]
				if selectQueue then
					if selectQueue['Action'] == 0 then
						QuickStore:SaveData(selectQueue['DataFile'],selectQueue['ExtraFile'])
					elseif selectQueue['Action'] == 1 then
						QuickStore:LoadData(selectQueue['DataFile'])
					end
					for count,queue in ipairs(QuickStore.Queue) do
						if selectQueue ~= queue then
							table.insert(tempQueue,queue)
						end
					end
					QuickStore.Queue = tempQueue
				end
				wait(index)
			end
		until #QuickStore.Queue == 0
	end
end

function QuickStore:SetData(dataFile,extraFile)
	if type(dataFile) == 'table' then
		QuickStore.Default = dataFile
	elseif tostring(dataFile) then
		QuickStore.Key = dataFile
		if type(extraFile) == 'table' then
			QuickStore.Default = extraFile
		end
	end
end

function QuickStore:SaveData(dataFile,newData)
	if dataFile ~= nil and newData ~= nil then
		QuickStore.Cache[dataFile] = newData
	elseif dataFile ~= nil and not newData then
		QuickStore.Cache = newData
	end
	local Tries = 0
	local DataStoreKey
	repeat
		local success,err = pcall(function()
			DataStoreKey = Services['DataStoreService']:GetDataStore(QuickStore.Key..'_Data',QuickStore.Key)
		end)
		if not success then
			Tries = Tries + 1
			wait(Tries)
		end
	until success or Tries >= 5
	if DataStoreKey then
		Tries = 0
		repeat
			local success,err = pcall(function()
				DataStoreKey:UpdateAsync(QuickStore.Key,function()	
					return QuickStore.Cache
				end)
			end)
			if not success then
				Tries = Tries + 1
				wait(Tries)
			end
		until success or Tries >= 5
		if Tries < 5 then
			return true
		end
	end
	return false
end

function QuickStore:LoadData(dataFile)
	local TempCache = nil
	local Tries = 0
	local DataStoreKey
	repeat
		local success,err = pcall(function()
			DataStoreKey = Services['DataStoreService']:GetDataStore(QuickStore.Key..'_Data',QuickStore.Key)
		end)
		if not success then
			Tries = Tries + 1
			wait(Tries)
		end
	until success or Tries >= 5
	if DataStoreKey then
		Tries = 0
		repeat
			local success,err = pcall(function()
				TempCache = DataStoreKey:GetAsync(QuickStore.Key)
			end)
			if not success then
				Tries = Tries + 1
				wait(Tries)
			end
		until success or Tries >= 5
	end
	if not TempCache then
		TempCache = DeepCopy(QuickStore.Default)
	end
	QuickStore.Cache = TempCache
	if dataFile then
		if QuickStore.Cache[dataFile] then
			return QuickStore.Cache[dataFile]
		end
	else
		return QuickStore.Cache
	end
	return false
end

function QuickStore:QueueData(action,dataFile,extraFile)
	local createProfile = {
		['Action'] = action;
		['DataFile'] = dataFile;
		['ExtraFile'] = extraFile;
	}
	table.insert(QuickStore.Queue,createProfile)
	RunQueue()
end

return QuickStore