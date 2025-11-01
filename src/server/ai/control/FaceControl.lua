--!strict

local DEFAULT_FACE_PACK_ASSET_IDS = {
	EYEBROW_RIGHT_NEUTRAL = 13873048302,
	EYEBROW_LEFT_NEUTRAL = 13873045657,
	EYEBROW_RIGHT_FURROW = 13873040061,
	EYEBROW_LEFT_FURROW = 13873041494,
	EYE_RIGHT_NEUTRAL = 13716114520,
	EYE_LEFT_NEUTRAL = 13716112954,
	EYE_RIGHT_RAISED = 13873025400,
	EYE_LEFT_RAISED = 13873026765,
	EYE_RIGHT_OPEN = 13716274037,
	EYE_LEFT_OPEN = 13716272920,
	EYE_RIGHT_CLOSED = 13716143698,
	EYE_LEFT_CLOSED = 13716145376,
	EYES_SHOCKED = 13689111514,
	MOUTH_CLOSED_NEUTRAL = 9806565498,
	MOUTH_CLOSED_FROWN = 9806562460,
	MOUTH_CLOSED_FROWN_2 = 9806560629,
	-- Lip sync stuff
	MOUTH_TEETH_FROWN = 9806566055,
	MOUTH_OPEN_FROWN = 9806566637,
	MOUTH_LEFT_TEETH_FROWN = 13736431749,
	MOUTH_LEFT_OPEN_FROWN = 9806561846,
	MOUTH_OPEN_O = 13670499760
}

local FACE_ALIAS_ASSET_ID = {
	Neutral = {
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_RIGHT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_LEFT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_NEUTRAL
	},
	Shocked = {
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_RAISED,
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_RAISED,
		DEFAULT_FACE_PACK_ASSET_IDS.EYES_SHOCKED,
		DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_FROWN
	},
	Angry = {
		DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_LEFT_FURROW,
		DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_RIGHT_FURROW,
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_FROWN_2
	},
	Unconscious = {
		DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_LEFT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_RIGHT_NEUTRAL,
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_CLOSED,
		DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_CLOSED,
		DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_FROWN,
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