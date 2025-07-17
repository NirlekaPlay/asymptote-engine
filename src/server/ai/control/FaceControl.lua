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
		9806562460,
		13873040061,
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
	return setmetatable({
		head = character:FindFirstChild("Head") :: BasePart,
		currentFaceAlias = "None",
		currentFaceDecals = {}
	}, FaceControl)
end

function FaceControl.setFace(self: FaceControl, faceAlias: FaceAlias): ()
	-- TODO: Automatically remove the default smiley face from the rig if present
	-- If you do not do this, the mf is gonna have some pennywise face shit
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
	newDecal.Parent = self.head

	return newDecal
end

return FaceControl