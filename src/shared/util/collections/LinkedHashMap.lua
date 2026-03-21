--!strict

--[=[
	@class LinkedHashMap

	A class that functions as a dictionary that maintains insertion order.
]=]
local LinkedHashMap = {}
LinkedHashMap.__index = LinkedHashMap

export type LinkedHashMap<K, V> = typeof(setmetatable({} :: {
	_map: { [K]: Node<K, V> },
	_head: Node<K, V>?,
	_tail: Node<K, V>,
	_size: number
}, LinkedHashMap))

type Node<K, V> = {
	key: K,
	value: V,
	prev: Node<K, V>,
	next: Node<K, V>?
}

function LinkedHashMap.new(): LinkedHashMap<any, any>
	return setmetatable({
		_map = {},          -- key -> node
		_head = nil :: any, -- oldest entry
		_tail = nil :: any, -- newest entry
		_size = 0,
	}, LinkedHashMap)
end

function LinkedHashMap.put<K, V>(self: LinkedHashMap<K, V>, key: K, value: V): ()
	local existing = self._map[key]
	if existing then
		existing.value = value
		return
	end

	local node: Node<K, V> = { key = key, value = value, prev = self._tail, next = nil }

	if self._tail then
		self._tail.next = node
	else
		self._head = node
	end

	self._tail = node
	self._map[key] = node
	self._size += 1
end

function LinkedHashMap.get<K, V>(self: LinkedHashMap<K, V>, key: K): V?
	local node = self._map[key]
	return node and node.value or nil
end

function LinkedHashMap.remove<K, V>(self: LinkedHashMap<K, V>, key: K): ()
	local node = self._map[key]
	if not node then
		return
	end

	if node.prev then
		node.prev.next = node.next
	else
		self._head = node.next
	end

	if node.next then
		node.next.prev = node.prev
	else
		self._tail = node.prev
	end

	self._map[key] = nil
	self._size -= 1
end

function LinkedHashMap.has<K, V>(self: LinkedHashMap<K, V>, key: K): boolean
	return self._map[key] ~= nil
end

function LinkedHashMap.forEach<K, V>(self: LinkedHashMap<K, V>, fn: (key: K, value: V) -> ()): ()
	-- snapshot the tail at iteration start
	-- anything added after this point wont be visited this iteration
	local stop = self._tail
	local node = self._head
	while node do
		local next = node.next
		fn(node.key, node.value)
		if node == stop then
			break
		end
		node = next
	end
end

function LinkedHashMap.keys<K, V>(self: LinkedHashMap<K, V>): () -> (K)
	local node = self._head
	return function()
		if node then
			local key = node.key
			node = node.next
			return key
		else
			return nil
		end
	end
end

function LinkedHashMap.size<K, V>(self: LinkedHashMap<K, V>): number
	return self._size
end

function LinkedHashMap.clear<K, V>(self: LinkedHashMap<K, V>): ()
	self._map = {}
	self._head = nil
	self._tail = nil :: any
	self._size = 0
end

return LinkedHashMap