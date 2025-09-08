--!strict

export type TagType<T> = {
	tagName: string,
	predicate: (Instance) -> boolean
}

local function register(tagName: string, predicate: (Instance) -> boolean): TagType<any>
	return {
		tagName = tagName,
		predicate = predicate
	}
end

return {
	NPC_GUARD = register("Guard", function(inst)
		return inst:IsA("Model")
	end) :: TagType<Model>,

	NPC_DETECTION_DUMMY = register("DetectionDummy", function(inst)
		return inst:IsA("Model")
	end) :: TagType<Model>,

	GUARD_POST = register("Post", function(inst)
		return inst:IsA("BasePart")
	end) :: TagType<BasePart>
}