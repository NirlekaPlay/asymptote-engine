--!strict

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local USE_THIS_INSTEAD = "https://webhook.lewisakura.moe/api/webhooks/1473266327396286506/uetjMY9PzC_6SehGmBJ5jeyr4z5crZXNKi9PR4iPZuM-IcXwph6U_Dy58rVP0XN2O658"

if not USE_THIS_INSTEAD and RunService:IsStudio() then
	return
end

if ServerScriptService:GetAttribute("LogJoins") ~= true then
	return
end

print("Fetching webhook secret...")
local success, webhookSecret = pcall(function()
	if USE_THIS_INSTEAD then
		return ({} :: any) :: Secret
	end
	return HttpService:GetSecret("DiscordWebhook")
end)

if not success then
	warn("Critical Error: Could not fetch Secret for Webhook:", webhookSecret)
	return
end

local MAX_RETRIES = 3
local INITIAL_WAIT = 5 -- seconds

local function sendToDiscord(player: Player, status: string)
	print("Sending...")
	local givenAvatarUrl = "https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg"
	local success, avatarResult = pcall(function()
		return HttpService:GetAsync(`https://thumbnails.roproxy.com/v1/users/avatar-headshot?userIds={player.UserId}&size=420x420&format=Png`, false)
	end)

	if success and avatarResult then
		givenAvatarUrl = HttpService:JSONDecode(avatarResult).data[1].imageUrl
	end

	print(success, avatarResult)
	print(givenAvatarUrl)

	local data = {
		["embeds"] = {{
			["title"] = "Player " .. status,
			["description"] = "**" .. player.Name .. "** has " .. status:lower() .. " the server.",
			["color"] = (status == "Joined") and 65280 or 16711680,
			["thumbnail"] = { ["url"] = givenAvatarUrl },
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
			["footer"] = { ["text"] = "Roblox Version: " .. game.PlaceVersion .. " Identifier: " .. game.ReplicatedStorage.Version.Value .. "Job id: " .. game.JobId },
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
				HttpService:PostAsync(if USE_THIS_INSTEAD then USE_THIS_INSTEAD else webhookSecret, payload)
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