--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

if RunService:IsStudio() then
	return
end

if ServerScriptService:GetAttribute("LogJoins") ~= true then
	return
end

-- Fetch the secret once
local success, webhookSecret = pcall(function()
	return HttpService:GetSecret("DiscordWebhook")
end)

if not success then
	warn("Critical Error: Could not fetch Secret for Webhook:", webhookSecret)
	return
end

local MAX_RETRIES = 3
local INITIAL_WAIT = 5 -- seconds

local function sendToDiscord(player: Player, status: string)
	local avatarUrl, isReady = Players:GetUserThumbnailAsync(
		player.UserId, 
		Enum.ThumbnailType.HeadShot,
		Enum.ThumbnailSize.Size420x420
	)

	local data = {
		["embeds"] = {{
			["title"] = "Player " .. status,
			["description"] = "**" .. player.Name .. "** has " .. status:lower() .. " the server.",
			["color"] = (status == "Joined") and 65280 or 16711680,
			["thumbnail"] = { ["url"] = avatarUrl },
			["fields"] = {
				{
					["name"] = "User ID",
					["value"] = "["..player.UserId.."](https://www.roblox.com/users/"..player.UserId.."/profile)",
					["inline"] = true
				},
				{
					["name"] = "Account Age",
					["value"] = player.AccountAge .. " days",
					["inline"] = true
				}
			},
			["footer"] = { ["text"] = "JobId: " .. game.JobId },
			["timestamp"] = DateTime.now():ToIsoDate()
		}}
	}

	local payload = HttpService:JSONEncode(data)

	task.spawn(function()
		local attempt = 0
		local sent = false
		
		while attempt < MAX_RETRIES and not sent do
			attempt += 1
			local postSuccess, postError = pcall(function()
				HttpService:PostAsync(webhookSecret, payload)
			end)

			if postSuccess then
				sent = true
			else
				warn(string.format("Webhook attempt %d failed: %s", attempt, postError))
				if attempt < MAX_RETRIES then
					task.wait(INITIAL_WAIT * attempt)
				end
			end
		end

		if not sent then
			warn("Webhook failed after " .. MAX_RETRIES .. " attempts. Dropping request.")
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	sendToDiscord(player, "Joined")
end)

Players.PlayerRemoving:Connect(function(player)
	sendToDiscord(player, "Left")
end)