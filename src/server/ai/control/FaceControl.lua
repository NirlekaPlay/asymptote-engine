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
	-- Lip sync mouth shapes / variants
	MOUTH_TEETH_FROWN = 9806566055,
	MOUTH_OPEN_FROWN = 9806566637,
	MOUTH_LEFT_TEETH_FROWN = 13736431749,
	MOUTH_LEFT_OPEN_FROWN = 9806561846,
	MOUTH_OPEN_O = 13670499760
}

local FACE_ALIAS_ASSET_ID = {
	Neutral = {
		EyeRight = DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_NEUTRAL,
		EyeLeft  = DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_NEUTRAL,
		EyebrowRight = DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_RIGHT_NEUTRAL,
		EyebrowLeft  = DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_LEFT_NEUTRAL,
		MouthBase = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_NEUTRAL
	},
	Shocked = {
		EyeRight = DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_RAISED,
		EyeLeft  = DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_RAISED,
		Eyes = DEFAULT_FACE_PACK_ASSET_IDS.EYES_SHOCKED,
		EyebrowRight = nil,
		EyebrowLeft  = nil,
		MouthBase = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_FROWN
	},
	Angry = {
		EyebrowLeft = DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_LEFT_FURROW,
		EyebrowRight = DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_RIGHT_FURROW,
		EyeLeft = DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_NEUTRAL,
		EyeRight = DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_NEUTRAL,
		MouthBase = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_FROWN_2
	},
	Unconscious = {
		EyebrowLeft = DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_LEFT_NEUTRAL,
		EyebrowRight = DEFAULT_FACE_PACK_ASSET_IDS.EYEBROW_RIGHT_NEUTRAL,
		EyeLeft = DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_CLOSED,
		EyeRight = DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_CLOSED,
		MouthBase = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_FROWN
	},
	None = {}
}

local LIPSYNC_ASSET_MAP = {
	["A"] = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_OPEN_FROWN,
	["E"] = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_TEETH_FROWN,
	["O"] = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_OPEN_O,
	["M"] = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_CLOSED_NEUTRAL,
	["L"] = DEFAULT_FACE_PACK_ASSET_IDS.MOUTH_LEFT_OPEN_FROWN
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
	currentFaceAlias: string,
	decals: { [string]: Decal }, -- keyed by region: "EyeRight", "Mouth", etc
}, FaceControl))

type EyesAlias = "Open"
	| "Closed"

type FaceAlias = "Neutral"
	| "Shocked"
	| "Angry"
	| "Unconscious"
	| "None"

type Phoneme = "A"
	| "E"
	| "O"
	| "M"
	| "L"

function FaceControl.new(character: Model): FaceControl
	local self = {}
	self.head = character:FindFirstChild("Head") :: BasePart
	self.currentFaceAlias = "None"
	self.decals = {}

	local faceDecals = self.head:FindFirstChild("Face Decals")
	if not faceDecals then
		FaceControl.createHdifyFaceDecals(self.head)
		for _, child in ipairs(self.head:GetChildren()) do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	else
		for _, child in ipairs(faceDecals:GetChildren()) do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	end

	return setmetatable(self, FaceControl)
end

function FaceControl._ensureDecal(self: FaceControl, regionName: string): Decal
	local dec = self.decals[regionName]
	if dec and dec.Parent and dec:IsDescendantOf(self.head) then
		return dec
	end

	local faceDecals = self.head:FindFirstChild("Face Decals")
	assert(faceDecals, "Face Decals container missing on head")

	local newDecal = Instance.new("Decal")
	newDecal.Name = regionName
	newDecal.Face = Enum.NormalId.Front
	newDecal.Parent = faceDecals
	self.decals[regionName] = newDecal
	return newDecal
end

function FaceControl._setRegionTexture(self: FaceControl, regionName: string, assetId: number?)
	if assetId == nil then
		-- If nil requested, remove decal if present
		if self.decals[regionName] then
			self.decals[regionName]:Destroy()
			self.decals[regionName] = nil
		end
		return
	end

	local decal = self:_ensureDecal(regionName)
	decal.TextureContent = Content.fromAssetId(assetId)
end

function FaceControl.setFace(self: FaceControl, faceAlias: FaceAlias): ()
	if self.currentFaceAlias == faceAlias then
		return
	end

	local aliasMap = FACE_ALIAS_ASSET_ID[faceAlias] or {} :: any
	for regionName, assetId in pairs(aliasMap) do
		-- Region name "MouthBase" is stored as "Mouth" in decals for consistency.
		local decalRegion = (regionName == "MouthBase") and "Mouth" or regionName
		self:_setRegionTexture(decalRegion, assetId)
	end

	for prevRegionName, _ in pairs(self.decals) do
		local aliasKey = (prevRegionName == "Mouth") and "MouthBase" or prevRegionName
		if aliasMap[aliasKey] == nil then
			self:_setRegionTexture(prevRegionName, nil)
		end
	end

	self.currentFaceAlias = faceAlias
end

function FaceControl.setEyesAlias(self: FaceControl, eyesAlias: EyesAlias): ()
	if eyesAlias == "Open" then
		self:resetEyesToExpression()
	elseif eyesAlias == "Closed" then
		self:_setRegionTexture("EyeLeft", DEFAULT_FACE_PACK_ASSET_IDS.EYE_LEFT_CLOSED)
		self:_setRegionTexture("EyeRight", DEFAULT_FACE_PACK_ASSET_IDS.EYE_RIGHT_CLOSED)
	end
end

function FaceControl.setMouth(self: FaceControl, assetId: number?): ()
	self:_setRegionTexture("Mouth", assetId)
end

function FaceControl.setMouthPhoneme(self: FaceControl, phonemeKey: Phoneme): ()
	local assetId = LIPSYNC_ASSET_MAP[phonemeKey]
	if assetId then
		self:setMouth(assetId)
	else
		self:resetMouthToExpression()
	end
end

function FaceControl.resetEyesToExpression(self: FaceControl): ()
	local aliasMap = FACE_ALIAS_ASSET_ID[self.currentFaceAlias :: any] or {} :: any
	local eyeLeft = aliasMap.EyeLeft
	local eyeRight = aliasMap.EyeRight
	if eyeLeft and eyeRight then
		self:_setRegionTexture("EyeLeft", eyeLeft)
		self:_setRegionTexture("EyeRight", eyeRight)
	end
end

function FaceControl.resetMouthToExpression(self: FaceControl): ()
	local aliasMap = FACE_ALIAS_ASSET_ID[self.currentFaceAlias :: any] or {} :: any
	local mouthBase = aliasMap.MouthBase
	if mouthBase then
		self:setMouth(mouthBase)
	else
		self:setMouth(nil)
	end
end

function FaceControl.createDecal(self: FaceControl, assetId: number): Decal
	local faceDecals = self.head:FindFirstChild("Face Decals")
	assert(faceDecals, "Face Decals container missing on head")
	local newDecal = Instance.new("Decal")
	newDecal.TextureContent = Content.fromAssetId(assetId)
	newDecal.Face = Enum.NormalId.Front
	newDecal.Parent = faceDecals
	return newDecal
end

function FaceControl.createHdifyFaceDecals(head: BasePart): BasePart
	-- this mimics the HDify plugin to make faces on R6 not look like utter shit
	local part = Instance.new("Part")
	part.Name = "Face Decals"
	part.Color = head.Color
	part.Size = Vector3.new(2, 1, 1)
	part.CFrame = CFrame.new(-7, 4.5, -8.5)
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
