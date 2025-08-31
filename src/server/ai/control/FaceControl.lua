--!strict

local FACE_ALIAS_ASSET_ID = {
	Neutral = {
		13716114520,
		13873048302,
		9806565498,
		13873045657,
		13716112954
	},
	Shocked = {
		9806562460,
		13689111514,
		13873025400,
		13873026765
	},
	Angry = {
		13873040061,
		13716274037,
		9806560629,
		13873041494,
		13716272920
	},
	Unconscious = {
		13873048302,
		13716143698,
		9806562460,
		13873045657,
		13716145376
	}
}

--[=[
	@class FaceControl

	Controls the face decals of an Agent, allowing to change
	face expressions.
]=]
local FaceControl = {}
FaceControl.__index = FaceControl

export type FaceControl = typeof(setmetatable({} :: {
	head: BasePart,
	currentFaceAlias: FaceAlias,
	currentFaceDecals: { Decal }
}, FaceControl))

type FaceAlias = "Neutral"
	| "Shocked"
	| "Angry"
	| "Unconscious"
	| "None"

function FaceControl.new(character: Model): FaceControl
	local self = {}

	self.head = character:FindFirstChild("Head") :: BasePart
	self.currentFaceAlias = "None"
	self.currentFaceDecals = {}

	local faceDecals = self.head:FindFirstChild("Face Decals")
	if not faceDecals then
		FaceControl.createHdifyFaceDecals(self.head)
		for _, decal in ipairs(self.head:GetChildren()) do
			if decal:IsA("Decal") then
				decal:Destroy()
			end
		end
	elseif faceDecals ~= nil then
		for _, decal in ipairs(faceDecals:GetChildren()) do
			if decal:IsA("Decal") then
				decal:Destroy()
			end
		end
	end

	return setmetatable(self, FaceControl)
end

function FaceControl.setFace(self: FaceControl, faceAlias: FaceAlias): ()
	local isSame = self.currentFaceAlias == faceAlias -- fuck you typechecker
	if isSame then return end

	-- TODO: Make a more performant way by replacing the asset ids
	-- and name them
	for _, decal in ipairs(self.currentFaceDecals) do
		decal:Destroy()
	end
	table.clear(self.currentFaceDecals)

	for _, id in ipairs(FACE_ALIAS_ASSET_ID[faceAlias]) do
		local newDecal = self:createDecal(id :: number) -- how are you this fucking retarded
		table.insert(self.currentFaceDecals, newDecal)
	end

	self.currentFaceAlias = faceAlias
end

function FaceControl.createDecal(self: FaceControl, assetId: number): Decal
	local newDecal = Instance.new("Decal")
	newDecal.TextureContent = Content.fromAssetId(assetId)
	newDecal.Face = Enum.NormalId.Front
	newDecal.Parent = self.head:FindFirstChild("Face Decals") -- use the HDIfy plugin so it can have HD faces

	return newDecal
end

function FaceControl.createHdifyFaceDecals(head: BasePart): BasePart
	-- this mimics the HDify plugin to make faces on R6 not look like utter shit
	local part = Instance.new("Part")
	part.Name = "Face Decals"
	part.Color = head.Color
	part.Size = Vector3.new(2, 1, 1)
	part.CFrame = CFrame.new(-7, 4.5, -8.5)
	--part.Origin = CFrame.new(-7, 0, -8.5)
	part.PivotOffset = CFrame.new(0, -4.5, 0)

	local mesh = Instance.new("SpecialMesh")
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = part

	local weld = Instance.new("Weld")
	weld.Name = "HeadWeld"
	weld.Part0 = head
	weld.Part1 = part
	weld.Parent = part

	part.Parent = head

	return part
end

return FaceControl