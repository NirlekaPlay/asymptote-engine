--!nonstrict

for _, module in ipairs(script.Parent:GetDescendants()) do
	if module:IsA("ModuleScript") then
		require(module)
	end
end