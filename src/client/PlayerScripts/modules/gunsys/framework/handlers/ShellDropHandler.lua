--!strict

--[=[
	@class ShellDropHandler
]=]
local ShellDropHandler = {}

-- TODO: Add pooling system
-- TODO: Difference guns can have different shell sound, shell model,
-- shell fly time and fall speed, etc.

local SHELL_INST_NAME = "GunSysShell"
local SHELL_SIZE = Vector3.new(0.25, 0.1, 0.1)
local SHELL_COLOR = BrickColor.new("New Yeller")
local SHELL_MATERIAL = Enum.Material.Glass
local SHELL_FLY_TIME = 0.5
local SHELL_FALL_SPEED = 80
local SHELL_SOUND_ID = "rbxassetid://2712533735"

local activeShells: { [BasePart]: {
	time: number,
	currentshelly: number,
	currentshellx: number,
	ejectLook: Vector3,
	ejectRight: Vector3,
	playedSound: boolean
} } = {}

local function playShellSound(parent: Instance): ()
	local sound = Instance.new("Sound")
	sound.SoundId = SHELL_SOUND_ID
	sound.Volume = 0.7
	sound.PlaybackSpeed = 1 + math.random(-10,10) / 65
	sound.PlayOnRemove = true
	sound.Parent = parent
	sound:Destroy()
end

function ShellDropHandler.dropShell(boltCframe: CFrame): ()
	local shell = Instance.new("Part")
	shell.Name = SHELL_INST_NAME
	shell.Shape = Enum.PartType.Cylinder
	shell.Size = SHELL_SIZE
	shell.BrickColor = SHELL_COLOR
	shell.Material = SHELL_MATERIAL
	shell.Anchored = true
	shell.CanQuery = false
	shell.AudioCanCollide = false
	shell.CanCollide = false
	shell.CFrame = boltCframe * CFrame.new(0.1, 0, 0)
	shell.Parent = workspace

	activeShells[shell] = {
		time = 0,
		currentshelly = math.random(1, 10) / 5,
		currentshellx = math.random(8, 15),
		ejectLook = boltCframe.UpVector,
		ejectRight = boltCframe.RightVector,
		playedSound = false
	}
end

function ShellDropHandler.onReceiveDropShellCall(boltCframe: CFrame): ()
	ShellDropHandler.dropShell(boltCframe)
end

function ShellDropHandler.update(deltaTime: number): ()
	for shell, data in pairs(activeShells) do
		if not shell.Parent then
			activeShells[shell] = nil
			continue
		end

		data.time += deltaTime

		shell.CFrame = CFrame.new(shell.Position, shell.Position + data.ejectLook)
			* CFrame.new(0, data.currentshelly * deltaTime, -data.currentshellx * deltaTime)

		shell.CFrame = CFrame.new(shell.Position, shell.Position + data.ejectRight)
			* CFrame.Angles(0, math.pi / 2, 0)

		data.currentshelly -= deltaTime * SHELL_FALL_SPEED

		if data.time > SHELL_FLY_TIME / 2 and not data.playedSound then
			data.playedSound = true
			playShellSound(shell)
		end

		if data.time > SHELL_FLY_TIME then
			shell:Destroy()
			activeShells[shell] = nil
		end
	end
end

return ShellDropHandler