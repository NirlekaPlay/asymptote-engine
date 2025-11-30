--!strict

--[=[
	@class ExpressionEvaluationSorter
]=]
local ExpressionEvaluationSorter = {}

type Node = string

function ExpressionEvaluationSorter.kahnsTopologicalSort(
	nodes: {Node},
	adjacencyList: { [Node]: {Node} }
): {Node}
	local inDegree: { [Node]: number } = {}
	
	for _, node in nodes do
		inDegree[node] = 0
	end

	for u, neighbors in adjacencyList do
		for _, v in neighbors do
			if inDegree[v] ~= nil then
				inDegree[v] = inDegree[v] + 1
			end
		end
	end

	local queue: {Node} = {}
	local queueCount = 0
	
	for node, degree in inDegree do
		if degree == 0 then
			queueCount += 1
			queue[queueCount] = node
		end
	end

	local topologicalOrder: {Node} = {}
	local topologicalOrderCount = 0
	
	while queueCount > 0 do
		local u = table.remove(queue, 1) :: string
		queueCount -= 1
		topologicalOrderCount += 1
		topologicalOrder[topologicalOrderCount] = u

		local neighbors: {Node} = adjacencyList[u] or {}
		for _, v in neighbors do
			
			inDegree[v] = inDegree[v] - 1

			if inDegree[v] == 0 then
				queueCount += 1
				queue[queueCount] = v
			end
		end
	end

	if topologicalOrderCount == #nodes then
		return topologicalOrder
	else
		error("ERR_CIRCULAR_DEPENDENCY")
	end
end

return ExpressionEvaluationSorter