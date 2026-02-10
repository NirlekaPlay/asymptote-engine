--!strict

local MSG_TEMP_SERVER = "This is a temporary lobby. Teleporting back in a moment."
local MSG_TELEPORTING = "Rebooting servers for update. Please wait..."

--[=[
	@class SoftShutdown
]=]
local SoftShutdown = {}

--[=[
	Use this to soft shutdown a reserved server or a private server.
	Since these don't use Roblox's general servers, you can just teleport them to a new place.
]=]
function SoftShutdown.softShutdownCurrentPrivateServer(): ()

end

--

function SoftShutdown._createMessage(msg: string): ()
	local m = Instance.new("Message")
	m.Text = msg
	m.Parent = workspace
end

return SoftShutdown