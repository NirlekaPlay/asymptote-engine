return function(entity: Instance): Vector3?
	if entity:IsA("Player") then
		local playerChar = entity.Character
		if not playerChar then
			return nil
		end

		local humanoidRootPart = playerChar:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
			return nil
		end

		return humanoidRootPart.Position
	elseif entity:IsA("BasePart") then
		return entity.Position
	elseif entity:IsA("Model") then
		local primaryPart = entity.PrimaryPart
		return primaryPart.Position
	end

	return nil
end
