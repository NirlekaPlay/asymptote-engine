--!nonstrict

local Players = game:GetService("Players")

--[=[
	@class EntitySelectorParser

	A Minecraft-style entity selector parser and resolver for Roblox.
	
	## Supported Selectors
	 * `@a`  - All players
	 * `@p`  - Nearest player (excluding source)
	 * `@s`  - Self (source player)
	 * `@r`  - Random player
	 * `@e`  - All entities (players + NPCs with Humanoids)
	 * `@m`  - All NPCs (entities with Humanoids, excluding players)

	## Parameter Syntax

	`@selector[param=value,param2=value2]`

	Example: `@e[type=!player,distance=..50,limit=3]`
	
	 * `distance=X`     - Exact distance
	 * `distance=..X`   - Less than or equal to X
	 * `distance=X..`   - Greater than or equal to X  
	 * `distance=X..Y`  - Between X and Y (inclusive)
	
	 * `name=PlayerName`    - Entity with exact name
	 * `name=!PlayerName`   - Entity NOT with this name
	 * `name="Name Here"`   - Quoted names with spaces
	
	 * `type=player`    - Players only
	 * `type=npc`       - NPCs/mobs only  
	 * `type=!player`   - Exclude players
	
	 * `team=TeamName`  - Players on specific team
	 * `team=!TeamName` - Players NOT on this team
	
	 * `limit=N`        - Maximum number of results

	## Negation Syntax
	
	Use `=!` (not `!=`) - this follows Minecraft's convention.<p>
	Examples: `type=!player, name=!Noob123, team=!Red`

	## Example commands
	
	 * `/kill @e[type=!player,distance=..50]`        - Kill all non-players within 50 units
	 * `/tp @p[team=Blue] @s`                        - Teleport nearest Blue team player to self
	 * `/give @a[level=10..,limit=5] sword`          - Give sword to first 5 players with level 10+
	
	*NOTE: Distance calculations require HumanoidRootPart or PrimaryPart*
]=]
local EntitySelectorParser = {}

local function parseParameters(paramString: string)
	local params = {}
	if not paramString or paramString == "" then return params end
	
	-- Remove brackets
	paramString = paramString:gsub("^%[", ""):gsub("%]$", "")
	
	-- Split by commas (but not inside quotes)
	local current = ""
	local inQuotes = false
	local quoteChar = nil
	
	for i = 1, #paramString do
		local char = paramString:sub(i, i)
		
		if not inQuotes and (char == '"' or char == "'") then
			inQuotes = true
			quoteChar = char
			current = current .. char
		elseif inQuotes and char == quoteChar then
			inQuotes = false
			quoteChar = nil
			current = current .. char
		elseif not inQuotes and char == "," then
			-- Process current parameter
			local key, value = current:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
			if key and value then
				-- Remove quotes from value if present
				value = value:gsub('^"(.-)"$', '%1'):gsub("^'(.-)'$", '%1')
				params[key] = value
			end
			current = ""
		else
			current = current .. char
		end
	end
	
	-- Process final parameter
	if current ~= "" then
		local key, value = current:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
		if key and value then
			value = value:gsub('^"(.-)"$', '%1'):gsub("^'(.-)'$", '%1')
			params[key] = value
		end
	end
	
	return params
end

function EntitySelectorParser.parse(input: string): (any, number)
	if not input or input == "" then
		return nil, 0
	end
	
	-- Check if it starts with @ (selector indicator)
	if input:sub(1, 1) ~= "@" then
		return nil, 0
	end
	
	-- Parse the selector pattern: @<type>[parameters]
	local consumed = 0
	local selectorType = ""
	local parameters = ""
	
	-- Parse selector type (@a, @p, @e, etc.)
	local typeMatch = input:match("^@([apesr])")
	if not typeMatch then
		return nil, 0
	end
	
	selectorType = "@" .. typeMatch
	consumed = 2 -- @ + type character
	
	-- Check for parameters
	if consumed < #input and input:sub(consumed + 1, consumed + 1) == "[" then
		-- Find matching closing bracket
		local bracketDepth = 0
		local paramStart = consumed + 1
		local paramEnd = paramStart
		local inQuotes = false
		local quoteChar = nil
		
		for i = paramStart, #input do
			local char = input:sub(i, i)
			
			if not inQuotes and (char == '"' or char == "'") then
				inQuotes = true
				quoteChar = char
			elseif inQuotes and char == quoteChar then
				-- Check if it's escaped
				if i > 1 and input:sub(i - 1, i - 1) ~= "\\" then
					inQuotes = false
					quoteChar = nil
				end
			elseif not inQuotes then
				if char == "[" then
					bracketDepth = bracketDepth + 1
				elseif char == "]" then
					bracketDepth = bracketDepth - 1
					if bracketDepth == 0 then
						paramEnd = i
						break
					end
				end
			end
		end
		
		if bracketDepth == 0 then
			parameters = input:sub(paramStart, paramEnd)
			consumed = paramEnd
		else
			-- Unmatched brackets - invalid selector
			return nil, 0
		end
	end
	
	-- Parse parameters
	local parsedParams = parseParameters(parameters)
	
	-- Create selector data structure
	local selectorData = {
		type = "selector",
		selector = selectorType,
		parameters = parsedParams,
		raw = input:sub(1, consumed)
	}
	
	return selectorData, consumed
end

local function getDistance(pos1: Vector3, pos2: Vector3)
	return (pos1 - pos2).Magnitude
end

local function getPosition(target: Instance): Vector3?
	if target:IsA("Player") then
		local character = target.Character
		if not character then
			return nil
		end
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
			return humanoidRootPart.Position
		end
	elseif target:IsA("Model") and target.PrimaryPart then
		return (target.PrimaryPart :: BasePart).Position
	elseif target:IsA("BasePart") then
		return target.Position
	end
	return nil
end

local function applyFilters(entities, params, source)
	local filtered = {}
	local sourcePos = getPosition(source)
	
	for _, entity in ipairs(entities) do
		local include = true
		local entityPos = getPosition(entity)
		
		-- Distance filter
		if params.distance and sourcePos and entityPos then
			local dist = getDistance(sourcePos, entityPos)
			local distanceCondition = params.distance
			
			-- Handle range notation (..10, 5.., 5..10)
			if distanceCondition:match("^%.%.") then
				-- ..10 (less than or equal to 10)
				local maxDist = tonumber(distanceCondition:match("^%.%.(.+)"))
				if maxDist and dist > maxDist then include = false end
			elseif distanceCondition:match("%.%.$") then
				-- 5.. (greater than or equal to 5)
				local minDist = tonumber(distanceCondition:match("(.+)%.%.$"))
				if minDist and dist < minDist then include = false end
			elseif distanceCondition:match("%.%.") then
				-- 5..10 (between 5 and 10)
				local minDist, maxDist = distanceCondition:match("(.+)%.%.(.+)")
				minDist, maxDist = tonumber(minDist), tonumber(maxDist)
				if minDist and maxDist and (dist < minDist or dist > maxDist) then
					include = false
				end
			else
				-- Exact distance
				local exactDist = tonumber(distanceCondition)
				if exactDist and math.abs(dist - exactDist) > 0.1 then
					include = false
				end
			end
		end
		
		-- Name filter
		if params.name then
			local targetName = params.name
			local negate = targetName:sub(1, 1) == "!"
			if negate then targetName = targetName:sub(2) end
			
			local entityName = entity.Name
			if entity:IsA("Player") then
				entityName = entity.Name
			end
			
			local nameMatch = entityName == targetName
			if negate then nameMatch = not nameMatch end
			if not nameMatch then include = false end
		end
		
		-- Type filter (for entities)
		if params.type then
			local targetType = params.type
			local negate = targetType:sub(1, 1) == "!"
			if negate then targetType = targetType:sub(2) end
			
			local entityType = entity.ClassName
			if entity:IsA("Player") then
				entityType = "player"
			elseif entity:FindFirstChildOfClass("Humanoid") then
				entityType = "npc"
			end
			
			local typeMatch = entityType:lower() == targetType:lower()
			if negate then typeMatch = not typeMatch end
			if not typeMatch then include = false end
		end
		
		-- Team filter (for players)
		if params.team and entity:IsA("Player") then
			local targetTeam = params.team
			local negate = targetTeam:sub(1, 1) == "!"
			if negate then targetTeam = targetTeam:sub(2) end
			
			local playerTeam = entity.Team and entity.Team.Name or ""
			local teamMatch = playerTeam == targetTeam
			if negate then teamMatch = not teamMatch end
			if not teamMatch then include = false end
		end
		
		-- Limit filter - handled after all other filtering
		if include then
			table.insert(filtered, entity)
		end
	end
	
	-- Apply limit after all filtering
	if params.limit then
		local limit = tonumber(params.limit)
		if limit and #filtered > limit then
			local limited = {}
			for i = 1, limit do
				table.insert(limited, filtered[i])
			end
			filtered = limited
		end
	end
	
	return filtered
end

local function sortByDistance(entities, source)
	local sourcePos = getPosition(source)
	if not sourcePos then return entities end
	
	table.sort(entities, function(a, b)
		local posA, posB = getPosition(a), getPosition(b)
		if not posA then return false end
		if not posB then return true end
		return getDistance(sourcePos, posA) < getDistance(sourcePos, posB)
	end)
	
	return entities
end

function EntitySelectorParser.resolvePlayerSelector(selectorData, source)
	if type(selectorData) == "table" and selectorData.type == "selector" then
		local baseSelector = selectorData.selector
		local params = selectorData.parameters or {}
		local entities = {}
		
		-- Get base entity set
		if baseSelector == "@a" then
			entities = Players:GetPlayers() -- All players
		elseif baseSelector == "@p" then
			entities = Players:GetPlayers() -- Will be sorted by distance
			-- Remove source player for nearest calculation
			for i = #entities, 1, -1 do
				if entities[i] == source then
					table.remove(entities, i)
					break
				end
			end
			entities = sortByDistance(entities, source)
		elseif baseSelector == "@s" then
			entities = {source} -- Self
		elseif baseSelector == "@r" then
			entities = Players:GetPlayers() -- Will pick random after filtering
		elseif baseSelector == "@e" then
			-- All entities (players + mobs)
			entities = {}
			for _, player in pairs(Players:GetPlayers()) do
				table.insert(entities, player)
			end
			for _, inst in pairs(workspace:GetChildren()) do
				if inst:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(inst) then
					table.insert(entities, inst)
				end
			end
		elseif baseSelector == "@m" then
			-- Only mobs (non-player entities with humanoids)
			entities = {}
			for _, inst in pairs(workspace:GetChildren()) do
				if inst:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(inst) then
					table.insert(entities, inst)
				end
			end
		end
		
		-- Apply filters
		entities = applyFilters(entities, params, source)
		
		-- Handle special selector behaviors after filtering
		if baseSelector == "@p" and #entities > 0 then
			-- Nearest player - return only the first one
			return {entities[1]}
		elseif baseSelector == "@r" and #entities > 0 then
			-- Random player - pick one randomly
			return {entities[math.random(#entities)]}
		end
		
		return entities
	else
		-- Regular player object
		return {selectorData}
	end
	
	return {}
end

return EntitySelectorParser