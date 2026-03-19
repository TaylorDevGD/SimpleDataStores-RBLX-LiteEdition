-- ?? General Information ??

-- HOW TO SET UP:
-- Add values into HiddenPlayerData which will be stored and saved in the player
-- Add values into PublicPlayerData which will be stored in a folder called 'leaderstats' and saved in the player

-- HiddenPlayerData can also have folders which will save the contents of what is put inside that folder when the player is playing
-- You can change what propreties are saved in folders by going to settings -> CustomTablePropertiesSave, adding an instence and naming it the property you want to always save

-- You can save the player backpack by going to Settings -> CanSaveBackpack and enabling. This will also require you having a duplicate of the tools in Settings -> CanSaveBackpack -> SaveableTools and named exactly the same
-- EnableEconomyTracking allows all player int and number stats to be put into a graph

-- All of this and more that can be done using SimpleDataStores. Thanks for using!
-- Run into a problem? View the documentation for detailed reporting on functionality and possible errors with solutions.

----------------------------------------------------
--  VERSION INFOMATION
-- You are currently running Version 7.0
-- If you run into a bug, please report it to the Dev-Forums and when updated feel free to download the newer version.

----------------------------------------------------
-- REQUIRED VARIABLES
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("AnalyticsService")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local ReflectService = game:GetService("ReflectionService")

local DataStore = nil
local SetupFunction = nil
local GetData = ""
local SetData = ""
local GetDataVariables = {}
local SetDataVariables = {}

local CustomDataModuleInfo = nil
local CustomDataStoreFunction = nil
local PlayerDataStore = nil
local CustomDataModuleSettingRef = script.Settings.CustomDataModule

local playerTools = {}
local playerGameSystemsSaveSlots = {}
local playerSavesLocationReferences = {}

local AbortPlayerSaveData = {}

----------------------------------------------------
-- SETTINGS REFERENCES
local CanSaveBackpack = script.Settings.CanSaveBackpack
local CanSaveBackpackAllowed = CanSaveBackpack.Value
local CanSaveBackpackOnDeath = CollectionService:HasTag(CanSaveBackpack, "SDS_NoDeathSaving")
local CanSaveBackpackOnRejoin = CollectionService:HasTag(CanSaveBackpack, "SDS_NoRejoinSaving")
local SaveableToolsInfo = CanSaveBackpack.SaveableTools:GetChildren()
local AutoDetectTools = CanSaveBackpack.AutoDetectTools.Value

local RetrySave = script.Settings.DataLossPreventions.Retry_Data_Save.Value
local maxRetries = script.Settings.DataLossPreventions.Retry_Data_Save.Max_Retries.Value
local BreakPerRetry = script.Settings.DataLossPreventions.Retry_Data_Save.Duration_Per_Retry.Value

local OutdatedVersionPrevention = script.Settings.DataLossPreventions.Outdated_Version_Prevention.Value
local AutoSaveDuration = script.Settings.DataLossPreventions.Auto_Save_Duration.Value

local AutoTablePropretiesSave = script.Settings.AutoTablePropretiesSave.Value

local DataStoreName = script.Settings.DataStoreName.Value

local DataStorePrefix = script.Settings.DataSaveSlotPrefix.Value

local EnableEconomyTrackingAllowed = script.Settings.EnableEconomyTracking.Value

local OutputDebuggingAllowed = script.Settings.OutputDebugging.Value

local SaveInStudioAllowed = script.Settings.SaveInStudio.Value

local CustomTablePropertiesSaveNames = script.Settings.CustomTablePropertiesSave:GetChildren()

----------------------------------------------------

local function OutputDebuggingLog(message, tableinfo, systemError)
	if OutputDebuggingAllowed and tableinfo ~= nil then
		warn(message)
		warn(tableinfo)
	elseif OutputDebuggingAllowed and systemError == true then
		warn(message)
	elseif OutputDebuggingAllowed then
		print(message)
	end
end

if script.Parent ~= game.ServerScriptService then
	OutputDebuggingLog("SimpleDataStores was moved from "..script.Parent.Name.." to ServerScriptService. " .."If you have scripts referencing this script remember it's now in ServerScriptService. (LINES: 8-13)", nil, true)
	script.Parent = game.ServerScriptService
end

local function DefaultSetup()
	GetData = "GetAsync"
	SetData = "UpdateAsync"
	DataStore = DataStoreService:GetDataStore(DataStoreName)
	GetDataVariables = { "UserID" }
	SetDataVariables = { "UserID", "playerStats" }
end

local function splitVars(input)
	if not input then return {} end
	if type(input) == "table" then return input end
	local t = {}
	for s in string.gmatch(input, "[^,]+") do
		s = s:gsub("^%s+","") :gsub("%s+$", "")
		table.insert(t, s)
	end
	return t
end

local function buildArgs(mapping, varList)
	local args = {}
	local vars = splitVars(varList)
	for _, name in ipairs(vars) do
		table.insert(args, mapping[name])
	end
	return args
end

local function callDataStore(funcRef, dsObject, ...)
	local args = { ... }
	if type(funcRef) == "string" then
		if dsObject and dsObject[funcRef] then
			return dsObject[funcRef](dsObject, table.unpack(args))
		else
			error("DataStore method '"..tostring(funcRef).."' not available")
		end
	elseif type(funcRef) == "function" then
		return funcRef(dsObject, table.unpack(args))
	else
		error("Invalid DataStore function reference: "..tostring(funcRef))
	end
end

local CanCustomDataModule = CustomDataModuleSettingRef.EnableCustomDataModule.Value
if not CanCustomDataModule then
	DefaultSetup()
else
	if CustomDataModuleSettingRef.DataModule.ClassName ~= "ModuleScript" then
		OutputDebuggingLog("CustomDataModule Failed Setup: ModuleScript not found. Using default setup.", nil, true)
		DefaultSetup()
	else

		local ds = require(CustomDataModuleSettingRef.DataModule)
		if ds then
			DataStore = ds
			GetData = CustomDataModuleSettingRef.RetrievingDataSets.GetDataFunction.Value
			SetData = CustomDataModuleSettingRef.SavingDataSets.SetDataFunction.Value
			GetDataVariables = splitVars(CustomDataModuleSettingRef.RetrievingDataSets.GetDataVariables.Value)
			SetDataVariables = splitVars(CustomDataModuleSettingRef.SavingDataSets.SetDataVariables.Value)
		else
			OutputDebuggingLog("CustomDataModule Failed Setup: require() failed. Using default setup.", nil, true)
			DefaultSetup()
		end
	end
end

local function hasTag(instance, tag)
	return CollectionService:HasTag(instance, tag) or instance:GetAttribute(tag)
end

if AutoDetectTools then
	for _, v in pairs(game:GetDescendants()) do
		if v:IsA("Tool") and v:GetAttribute("ignore") ~= true then
			OutputDebuggingLog(v.Name .. " was automatically added to SaveableTools because CanSaveBackpack and AutoDetectTools were enabled")
			local ok, clone = pcall(function() return v:Clone() end)
			if ok and clone then
				clone.Parent = script.Settings.CanSaveBackpack.SaveableTools
			end
		end
	end
end

local function serializeAdditionals(fontFace)
	if not fontFace then return nil end
	return {
		Family = fontFace.Family,
		Weight = fontFace.Weight and fontFace.Weight.Name or nil,
		Style = fontFace.Style and fontFace.Style.Name or nil,
	}
end

local function deserializeAdditionals(data)
	if not data then return nil end
	local fontFace = Font.new(data.Family)
	if data.Weight then
		fontFace.Weight = Enum.FontWeight[data.Weight]
	end
	if data.Style then
		fontFace.Style = Enum.FontStyle[data.Style]
	end
	return fontFace
end

local READONLY_PROPERTIES = {
	AbsoluteRotation = true,
	AbsolutePosition = true,
	AbsoluteSize = true,
	TextFits = true,
	ContentText = true,
	LocalizedText = true,
	OpenTypeFeaturesError = true,
	className = true,
}

local function serializeDefined(propertyList, instance)
	local writable = {}

	for _, propertyInfo in ipairs(propertyList) do
		local propName = propertyInfo.Name

		local success, value = pcall(function()
			return instance[propName]
		end)

		if success and value ~= nil then
			local t = typeof(value)

			if t == "Vector3" then
				writable[propName] = { value.X, value.Y, value.Z }

			elseif t == "Color3" then
				writable[propName] = { value.R, value.G, value.B }

			elseif t == "ColorSequence" then
				local keypoints = {}
				for _, kp in ipairs(value.Keypoints) do
					table.insert(keypoints, {
						Time = kp.Time,
						Color = { kp.Value.R, kp.Value.G, kp.Value.B }
					})
				end
				writable[propName] = keypoints

			elseif t == "UDim2" then
				writable[propName] = {
					ScaleX = value.X.Scale,
					OffsetX = value.X.Offset,
					ScaleY = value.Y.Scale,
					OffsetY = value.Y.Offset,
				}

			elseif t == "string" or t == "number" or t == "boolean" then
				writable[propName] = value

			elseif t == "table" then
				writable[propName] = value
			end
		end
	end

	if instance:IsA("TextLabel") or instance:IsA("TextBox") or instance:IsA("TextButton") then
		writable.FontFace = serializeAdditionals(instance.FontFace)
	end

	for name, v in pairs(instance:GetAttributes()) do
		local t = typeof(v)
		if t == "string" or t == "number" or t == "boolean" then
			writable[name] = v
		end
	end

	writable.Children = {}

	for _, child in ipairs(instance:GetChildren()) do
		local childProps

		if script.Settings.AutoTablePropretiesSave.Value then
			childProps = ReflectService:GetPropertiesOfClass(child.ClassName, READONLY_PROPERTIES)
		else
			childProps = script.Settings.CustomTablePropertiesSave:GetChildren()
		end

		local serializedChild = serializeDefined(childProps, child)

		local childEntry = {
			ClassName = child.ClassName,
			Name = child.Name,
		}

		for k, v in pairs(serializedChild) do
			childEntry[k] = v
		end

		table.insert(writable.Children, childEntry)
	end

	return writable
end


local function serializeInstance(instance)
	local propertyList

	if script.Settings.AutoTablePropretiesSave.Value then
		propertyList = ReflectService:GetPropertiesOfClass(instance.ClassName, READONLY_PROPERTIES)
	else
		propertyList = script.Settings.CustomTablePropertiesSave:GetChildren()
	end

	local data = serializeDefined(propertyList, instance)

	data.ClassName = instance.ClassName
	data.Name = instance.Name

	return data
end

local function toColor3(tbl)
	return Color3.new(tbl[1], tbl[2], tbl[3])
end

local function toVector3(tbl)
	return Vector3.new(tbl[1], tbl[2], tbl[3])
end

local function toUDim2(tbl)
	return UDim2.new(tbl.ScaleX, tbl.OffsetX, tbl.ScaleY, tbl.OffsetY)
end

local function toColorSequence(tbl)
	local keypoints = {}
	for _, kp in ipairs(tbl) do
		table.insert(keypoints, ColorSequenceKeypoint.new(
			kp.Time,
			Color3.new(kp.Color[1], kp.Color[2], kp.Color[3])
			))
	end
	return ColorSequence.new(keypoints)
end


local function deserializeInstance(parentInstance, data)
	data = data or {}

	for _, childData in ipairs(data.Children or {}) do

		local childInstance = Instance.new(childData.ClassName)
		childInstance.Name = childData.Name or "Unnamed"
		childInstance.Parent = parentInstance

		for prop, propValue in pairs(childData) do

			if prop ~= "Children" and prop ~= "ClassName" and prop ~= "Name" then

				if READONLY_PROPERTIES[prop] then
					continue
				end

				local success, err = pcall(function()
					local expected = typeof(childInstance[prop])

					if expected == "Color3" then
						childInstance[prop] = toColor3(propValue)

					elseif expected == "Vector3" then
						childInstance[prop] = toVector3(propValue)

					elseif expected == "UDim2" then
						childInstance[prop] = toUDim2(propValue)

					elseif expected == "ColorSequence" then
						childInstance[prop] = toColorSequence(propValue)

					elseif expected == "string" or expected == "boolean" or expected == "number" then
						childInstance[prop] = propValue
					elseif prop == "FontFace" then
						childInstance[prop] = deserializeAdditionals(propValue)

					else
						childInstance[prop] = propValue
					end
				end)

				if not success then
					warn("Failed to set property", prop, "on", childInstance.Name, ":", err)
				end
			end
		end

		deserializeInstance(childInstance, childData)
	end
end

local function LogEconomy(player, v, savedStats, leaving)
	if savedStats and EnableEconomyTrackingAllowed and leaving and (v:IsA("IntValue") or v:IsA("NumberValue")) then
		AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType.Source, v.Name, savedStats[v.Name] or 0, v.Value, Enum.AnalyticsEconomyTransactionType.Gameplay.Name)
	end
end

local function updatePlayerTools(player)
	local backpackItems = {}
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(backpackItems, item.Name)
				OutputDebuggingLog("Updated tool in Backpack: " .. item.Name .. " for " .. player.Name)
			end
		end
	end

	local character = player.Character
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(backpackItems, item.Name)
				OutputDebuggingLog("Updated equipped tool in Character: " .. item.Name .. " for " .. player.Name)
			end
		end
	end

	playerTools[player.UserId] = backpackItems
	OutputDebuggingLog("Updated tools for " .. player.Name .. ": " .. table.concat(backpackItems, ", "))
end

local function getPlayerTools(player)
	local tools = playerTools[player.UserId] or {}
	OutputDebuggingLog("Retrieved tools for " .. player.Name .. ": " .. table.concat(tools, ", "))
	return tools
end

local function findInstanceByNameInGame(name, ignoreParent)
	for _, inst in ipairs(game:GetDescendants()) do
		if inst.Name == name and inst ~= ignoreParent then
			return inst
		end
	end
	return nil
end

local function findInstanceFromFullName(fullName)
	if not fullName then return nil end

	local segments = {}
	if string.split then
		segments = string.split(fullName, ".")
	else
		for s in string.gmatch(fullName, "[^%.]+") do
			table.insert(segments, s)
		end
	end

	local current = game
	for _, name in ipairs(segments) do
		if not current then
			return nil
		end

		local child = current:FindFirstChild(name)
		if not child then
			return nil
		end
		current = child
	end
	return current
end

local function WorldSpaceLocator(player, templateInstance, playerClone)
	local userIdKey = tostring(player.UserId)
	local entryName = templateInstance.Name

	local function setMappingFromInstance(source)
		if not playerSavesLocationReferences[userIdKey] then
			playerSavesLocationReferences[userIdKey] = {}
		end

		if source and source:IsDescendantOf(game) then
			playerSavesLocationReferences[userIdKey][entryName] = source
		else
			playerSavesLocationReferences[userIdKey][entryName] = nil
		end
	end

	local source = findInstanceByNameInGame(templateInstance.Name, templateInstance)
	if not source then
		source = templateInstance
	end

	setMappingFromInstance(source)

	local function onAncestryChanged()
		if source and source.Parent then
			setMappingFromInstance(source)
		else
			local replacement = findInstanceByNameInGame(templateInstance.Name, templateInstance)
			if replacement then
				source = replacement
				setMappingFromInstance(source)
				replacement.AncestryChanged:Connect(onAncestryChanged)
			else
				playerSavesLocationReferences[userIdKey][entryName] = nil
			end
		end
	end

	if source and source:IsA("Instance") then
		source.AncestryChanged:Connect(onAncestryChanged)
	end

	templateInstance.AncestryChanged:Connect(function()
		local replacement = findInstanceByNameInGame(templateInstance.Name, templateInstance)
		if replacement then
			source = replacement
			setMappingFromInstance(source)
			replacement.AncestryChanged:Connect(onAncestryChanged)
		else
			setMappingFromInstance(templateInstance)
		end
	end)
end


local function savePlayerStats(player, leaving)
	if not AbortPlayerSaveData[player.UserId] then
		local playerstats = PlayerDataStore or {}

		local mapping = {
			player = player,
			UserID = tostring(player.UserId),
			DataStore = DataStore,
			GetData = GetData,
			SetData = SetData,
			backpackonly = false,
		}

		local GETactualArgs = buildArgs(mapping, GetDataVariables)

		local success, savedStats = pcall(function()
			return callDataStore(GetData, DataStore, table.unpack(GETactualArgs))
		end)

		if not success then
			warn("Failed to save data for player " .. player.Name .. ": ", tostring(savedStats) .. " (Error 2)")
			return nil
		end

		OutputDebuggingLog("Previous saved stats for player: ".. player.Name, savedStats)
		OutputDebuggingLog("Newly saving stats for player: " .. player.Name)

		local CombinedDatas = {}

		for _, child in ipairs(player:GetChildren()) do
			table.insert(CombinedDatas, child)
		end

		local refs = playerSavesLocationReferences[tostring(player.UserId)]
		if refs then
			for _, ref in pairs(refs) do
				table.insert(CombinedDatas, ref)
			end
		end

		for _, v in ipairs(CombinedDatas) do
			if not v then
				OutputDebuggingLog("Skipping missing reference during SAVE: " .. tostring(v), nil, true)
				continue
			end

			if v:IsA("Backpack") and CanSaveBackpackAllowed then
				if (leaving and not hasTag(v, "NoRejoinSaving")) or (not leaving and not hasTag(v, "NoDeathSaving")) then
					local tools = getPlayerTools(player)
					playerstats["Backpack"] = tools
					OutputDebuggingLog("Saving Backpack tools: ", tools)
				end
			elseif v:IsA("ValueBase") then
				if script.HiddenPlayerData:FindFirstChild(v.Name) then
					print("FOUND: "..v.name.. " in "..v.Parent.Name)
					if (leaving and not hasTag(v, "NoRejoinSaving")) or (not leaving and not hasTag(v, "NoDeathSaving")) then
						playerstats[v.Name] = v.Value
					end
					LogEconomy(player, v, savedStats, leaving)
				end
			elseif v:IsA("Folder") and v.Name ~= "leaderstats" then
				if (leaving and not hasTag(v, "NoRejoinSaving")) or (not leaving and not hasTag(v, "NoDeathSaving")) then
					local serializedData = serializeInstance(v)
					playerstats[v.Name] = serializedData
				end
			end
		end

		if script.Settings.DataLossPreventions.Outdated_Version_Prevention.Value then
			playerstats["LatestPlaceVersionID"] = game.PlaceVersion
			playerstats["LatestPlaceID"] = game.PlaceId 
		end

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			for _, v in ipairs(leaderstats:GetChildren()) do
				if v:IsA("ValueBase") then
					if script.PublicPlayerData:FindFirstChild(v.Name) then
						if (leaving and not hasTag(v, "NoRejoinSaving")) or (not leaving and not hasTag(v, "NoDeathSaving")) then
							playerstats[v.Name] = v.Value
						end
						LogEconomy(player, v, savedStats, leaving)
					end
				end
			end
		end

		local setMapping = {
			player = player,
			UserID = tostring(player.UserId),
			playerStats = playerstats,
			leaving = leaving,
			DataStore = DataStore,
			GetData = GetData,
			SetData = SetData,
			GetDefaultStats = savedStats,
		}

		local SETactualArgs = buildArgs(setMapping, SetDataVariables)

		local SaveSize = HttpService:JSONEncode(playerstats)

		OutputDebuggingLog(player.UserId.." Save Size is "..#SaveSize)

		if not leaving then
			local prevPlayerData = playerGameSystemsSaveSlots[tostring(player.UserId)]
			if prevPlayerData and #SaveSize > 4000000 then
				warn("[INTERNAL SYSTEM SAVE ERROR] Failed to save data for player " .. player.Name .. " :  data size limit surpassed. "..#SaveSize.."/4000000 (Error 1)")
			else
				if type(savedStats) ~= "table" then
					savedStats = {}
				end
				playerGameSystemsSaveSlots[tostring(player.UserId)] = playerstats
				OutputDebuggingLog("[INTERNAL SYSTEM SAVE] Saved stats for player:".. player.UserId, playerstats)
			end
		else
			local SavedSuccessfully, err = pcall(function()
				if SetData == "UpdateAsync" then
					callDataStore("UpdateAsync", DataStore, tostring(player.UserId), function(oldData)
						oldData = type(oldData) == "table" and oldData or {}
						return playerstats
					end)
				else
					callDataStore(SetData, DataStore, tostring(player.UserId), playerstats)
				end
			end)

			if not SavedSuccessfully then
				warn("[KEY PROBLEMS] Failed to save data for player " .. player.Name .. ": " .. tostring(err) .. " (Error 1)")
				if #SaveSize > 4000000 then
					warn("[PLAYER DATA SAVE DIAGNOSTIC] player ".. player.Name .." has gone over the file size limit. "..#SaveSize.."/4000000")
				elseif RetrySave then
					local attempts = 0
					while not SavedSuccessfully and attempts < maxRetries do
						attempts += 1
						SavedSuccessfully, err = pcall(function()
							if SetData == "UpdateAsync" then
								callDataStore("UpdateAsync", DataStore, tostring(player.UserId), function(oldData)
									oldData = type(oldData) == "table" and oldData or {}
									return playerstats
								end)
							else
								callDataStore(SetData, DataStore, tostring(player.UserId), playerstats)
							end
						end)

						warn("[DATA FAIL SAFE]: Attempting to save player data again for user @"..player.Name)
						task.wait(BreakPerRetry)
					end
					if attempts ~= maxRetries then
						OutputDebuggingLog("[KEY SENT AFTER REATTEMPTS]: Player data was saved after needing to go to re-trys")
					else
						warn("[PLAYER DATA SAVE RETRY FAILED]: Here is the diagnostic: ".. err)
					end
				else
					warn("[PLAYER DATA SAVE DIAGNOSTIC] Unable to diagnose root case of error internally. ERROR: ".. err)
				end
			else
				OutputDebuggingLog("[KEY SENT] Saved stats for player:".. player.UserId, playerstats)
			end
		end
	else
		OutputDebuggingLog("Data saving was aborted due to wrong place version")
		AbortPlayerSaveData[player.UserId] = nil
	end
end

local function retrievePlayerStats(player, backpackonly, presetdata, playerJustJoined, playerRespawned)
	local mapping = {
		player = player,
		UserID = tostring(player.UserId),
		DataStore = DataStore,
		GetData = GetData,
		SetData = SetData,
		backpackonly = backpackonly
	}

	local RETactualArgs = buildArgs(mapping, GetDataVariables)

	local success, savedStats = pcall(function()
		if not playerJustJoined and presetdata == nil then
			return playerGameSystemsSaveSlots[tostring(player.UserId)]
		elseif presetdata then
			return presetdata
		elseif playerJustJoined then
			return callDataStore(GetData, DataStore, table.unpack(RETactualArgs))
		end
	end)

	if not success then
		warn("Failed to retrieve data for player " .. player.Name .. ": ", tostring(savedStats) .. " (Error 2)")
		return nil
	end

	OutputDebuggingLog("Retrieved stats for player:".. player.UserId, savedStats)

	if savedStats then
		if savedStats["LatestPlaceVersionID"] and savedStats["LatestPlaceVersionID"] > game.PlaceVersion and savedStats["LatestPlaceID"] == game.PlaceId and OutdatedVersionPrevention then
			OutputDebuggingLog("PLAYER DATA WAS SAVED IN A NEWER THAN CURRENT VERSION!! Prevented with Outdated_Version_Prevention. CurrentVersion: "..game.PlaceVersion.." : SaveVersion: "..savedStats["LatestPlaceVersionID"])
			AbortPlayerSaveData[player.UserId] = true
			player:Kick(script.Settings.DataLossPreventions.Outdated_Version_Prevention.ErrorMessage.Value)
		end

		playerGameSystemsSaveSlots[tostring(player.UserId)] = savedStats

		if not backpackonly then
			local refs = playerSavesLocationReferences[tostring(player.UserId)]
			if refs then
				for _, v in pairs(refs) do

					if not v then
						OutputDebuggingLog("Skipping missing reference during LOAD: " .. tostring(v), nil, true)
						continue
					end

					if v:IsA("ValueBase") then
						local playerStat = player:FindFirstChild(v.Name)
						local defaultValue = v.Value
						local savedValue = savedStats[v.Name]

						if playerStat then
							if not playerRespawned then
								if savedValue ~= nil then
									playerStat.Value = savedValue
								end

							elseif playerRespawned then
								if hasTag(v, "NoDeathSave") then
									if savedValue ~= nil then
										playerStat.Value = savedValue
									end
								else
									playerStat.Value = defaultValue
								end
							end
						end

					elseif v:IsA("Folder") then
						local folderInstance = player:FindFirstChild(v.Name)
						if folderInstance and savedStats[v.Name] ~= nil and not playerRespawned then
							for _, child in ipairs(folderInstance:GetChildren()) do 
								child:Destroy() 
							end
							deserializeInstance(folderInstance, savedStats[v.Name])

						elseif folderInstance and savedStats[v.Name] ~= nil and playerRespawned and hasTag(v, "NoDeathSave") then
							for _, child in ipairs(folderInstance:GetChildren()) do 
								child:Destroy() 
							end
							deserializeInstance(folderInstance, savedStats[v.Name])

						elseif playerRespawned and hasTag(v, "NoDeathSave") then
							for _, child in ipairs(folderInstance:GetChildren()) do 
								child:Destroy() 
							end

							for _, child in ipairs(v:GetChildren()) do
								child:Clone().Parent = folderInstance
							end
						end

					end
				end

				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					for _, v in ipairs(script.PublicPlayerData:GetChildren()) do
						local stat = leaderstats:FindFirstChild(v.Name)
						local defaultValue = v.Value
						local savedValue = savedStats[v.Name]

						if stat then
							if not playerRespawned then
								if savedValue ~= nil then
									stat.Value = savedValue
								end

							elseif playerRespawned then
								if hasTag(v, "NoDeathSave") then
									if savedValue ~= nil then
										stat.Value = savedValue
									end
								else
									stat.Value = defaultValue
								end
							end
						end
					end
				end
			end

			if CanSaveBackpackAllowed and (not backpackonly and CanSaveBackpack:GetAttribute("SaveOnDeath") == true) then
				local backpack = player:FindFirstChild("Backpack")
				local matchingFolder = script.Settings.CanSaveBackpack:FindFirstChild("SaveableTools")

				if backpack and matchingFolder and savedStats["Backpack"] then
					if #savedStats["Backpack"] > 0 then
						for _, itemName in ipairs(savedStats["Backpack"]) do
							local matchingItem = matchingFolder:FindFirstChild(itemName)
							if matchingItem then
								local clone = matchingItem:Clone()
								clone.Parent = backpack
								OutputDebuggingLog("Restored tool: " .. itemName .. " to " .. player.Name .. "'s Backpack")
							else
								OutputDebuggingLog(itemName .. " was unretrievable. Please put a copy of the tool in the SaveableTools folder.")
							end
						end
					else
						OutputDebuggingLog("User " .. player.Name .. " had no saved tools in Backpack!")
					end
				else
					OutputDebuggingLog("Backpack or SaveableTools folder not found for player: " .. player.Name)
				end
			end
			return true
		end

		return false
	end
end


local function AutoSaveControl()
	if AutoSaveDuration >= 30 and game.Players.MaxPlayers < 50 then
		while task.wait(script.Settings.DataLossPreventions.Auto_Save_Duration) do
			for _, player in ipairs(Players:GetPlayers()) do
				if playerGameSystemsSaveSlots[tostring(player.UserId)] then
					savePlayerStats(player, true)
				else
					OutputDebuggingLog("Player "..player.Name.." attempted to auto save but failed. Player has no save slot", nil, true)
				end
			end
		end
	elseif game.Players.MaxPlayers < 50 then
		warn("AutoSave is not allowed for game with over 50 player's due to Roblox limitations. AutoSave has been aborted!")
	else
		OutputDebuggingLog("Auto Save Duration is less than 30 seconds. Auto saving is disabled.", nil, false)
	end
end

Players.PlayerAdded:Connect(function(player)
	playerTools[player.UserId] = {}
	playerGameSystemsSaveSlots[tostring(player.UserId)] = {}
	playerSavesLocationReferences[tostring(player.UserId)] = {}

	for _, v in ipairs(script.HiddenPlayerData:GetChildren()) do
		local datasetup = v:Clone()
		datasetup.Parent = player

		if hasTag(v, "SDS_SaveOnWorldSpaceRelocation") then
			task.spawn(function() WorldSpaceLocator(player, v, datasetup) end)
		else
			playerSavesLocationReferences[tostring(player.UserId)][datasetup.Name] = datasetup
		end

		if v:IsA("ValueBase") then
			datasetup.Value = v.Value
		elseif not v:IsA("Folder") then
			OutputDebuggingLog("Attempted to use type ".. v.ClassName .." for HiddenPlayerData but type is not supported. Affected instence name: ".. v.Name)
		end
	end

	if #script.PublicPlayerData:GetChildren() > 0 then
		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
		for _, v in ipairs(script.PublicPlayerData:GetChildren()) do
			local datasetup = v:Clone()
			datasetup.Parent = leaderstats
			datasetup.Value = v.Value
		end
	end

	OutputDebuggingLog("DataStores player values were set up as expected")

	retrievePlayerStats(player, false, nil, true)

	if script.Settings:FindFirstChild("SaveInStudio") and not script.Settings.SaveInStudio.Value then
		OutputDebuggingLog("SaveInStudio is not turned on. Data can only save in the main game unless this feature is enabled!")
	end

	local function onCharacterAdded(character)
		updatePlayerTools(player)

		local function ToolCheck(child)
			if child:IsA("Tool") then
				updatePlayerTools(player)
			end
		end

		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			backpack.ChildAdded:Connect(ToolCheck)
			backpack.ChildRemoved:Connect(ToolCheck)
		end

		character.ChildAdded:Connect(ToolCheck)
		character.ChildRemoved:Connect(ToolCheck)

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if SaveInStudioAllowed == false and game:GetService("RunService"):IsStudio() then
					OutputDebuggingLog("Data not saved on death: SaveInStudio is disabled in Studio.")
					return
				end
				OutputDebuggingLog("Player " .. player.Name .. " died, saving stats...")
				savePlayerStats(player, false)
				task.wait(Players.RespawnTime + 0.5)
				retrievePlayerStats(player, true, nil, false, true)
			end)
		end
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then onCharacterAdded(player.Character) end
end)

local taskCoro = coroutine.create(AutoSaveControl)
local success, result = coroutine.resume(taskCoro)

Players.PlayerRemoving:Connect(function(player)
	if SaveInStudioAllowed == false and game:GetService("RunService"):IsStudio() then
		warn("Data failed to save: SaveInStudio is disabled which prevented saving while you playtest in Roblox Studio. Saving WILL work in production game. (Error 3)")
	else
		OutputDebuggingLog("Player " .. player.Name .. " is leaving, saving data...")
		savePlayerStats(player, true)
	end
	playerTools[player.UserId] = nil
	playerGameSystemsSaveSlots[tostring(player.UserId)] = nil
	playerSavesLocationReferences[tostring(player.UserId)] = nil
end)
