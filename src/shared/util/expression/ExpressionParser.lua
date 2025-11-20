--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StringReader = require(ReplicatedStorage.shared.commands.StringReader)
local ExpressionContext = require(ReplicatedStorage.shared.util.expression.ExpressionContext)

local Parser = {}
Parser.__index = Parser

export type ASTNode = {
	kind: string,
	[string]: any
}

export type Parser = typeof(setmetatable({} :: {
	reader: StringReader.StringReader
}, Parser))

local FIRST_TERNARY_OPERATOR = "?"
local SECOND_TERNARY_OPERATOR = ":"
local NOT_OPERATOR = "!"
local OR_OPERATOR = "||"
local AND_OPERATOR = "&&"
local EQUALITY_OPERATOR = "=="
local LESS_THAN_OPERATOR = "<"
local MORE_THAN_OPERATOR = ">"
local LESS_THAN_OET_OPERATOR = ">="
local MORE_THAN_OET_OPERATOR = "<="
local ADDITION_OPERATOR = "+"
local SUBTRACTION_OR_NEGATE_OPERATOR = "-"
local MULTIPLICATION_OPERATOR = "*"
local DIVISION_OPERATOR = "/"

local GROUP_OPENING_CHAR = "("
local GROUP_CLOSING_CHAR = ")"
local STRING_INTERP_OPENING_CHAR = "{"
local STRING_INTERP_CLOSING_CHAR = "}"

local STRING_CHARS = {
	["'"] = true,
	['"'] = true
}

local OPERATOR_PRECEDENCES = {
	[FIRST_TERNARY_OPERATOR] = 10,
	[OR_OPERATOR] = 20,
	[AND_OPERATOR] = 30,
	[EQUALITY_OPERATOR] = 40,
	[LESS_THAN_OPERATOR] = 50, [MORE_THAN_OPERATOR] = 50,
	[LESS_THAN_OET_OPERATOR] = 50, [MORE_THAN_OET_OPERATOR] = 50,
	[ADDITION_OPERATOR] = 60, [SUBTRACTION_OR_NEGATE_OPERATOR] = 60,
	[MULTIPLICATION_OPERATOR] = 70, [DIVISION_OPERATOR] = 70,
	["prefix"] = 80, -- Unary operators !, -
}

local function isDigit(char: string): boolean
	return char >= "0" and char <= "9"
end

local function isAlpha(char: string): boolean
	return (char >= "a" and char <= "z") or (char >= "A" and char <= "Z") or char == "_"
end

local function isAlphaNumeric(char: string): boolean
	return isAlpha(char) or isDigit(char)
end

function Parser.new(reader: StringReader.StringReader)
	local self = setmetatable({
		reader = reader
	}, Parser)
	return self
end

function Parser.fromString(str: string): Parser
	return Parser.new(StringReader.fromString(str))
end

--

function Parser.parseAndEvalute(input: string, context: ExpressionContext.ExpressionContext): any
	return Parser.evaluate(Parser.fromString(input):parse(), context)
end

function Parser.evaluate(node: ASTNode, context: ExpressionContext.ExpressionContext): any
	if node.kind == "Literal" then
		return node.value
		
	elseif node.kind == "Variable" then
		return context:getVariable(node.name)
	elseif node.kind == "StringInterpolation" then
		local result = ""
		for _, part in ipairs(node.parts) do
			result = result .. tostring(Parser.evaluate(part, context))
		end
		return result
	elseif node.kind == "Unary" then
		local val = Parser.evaluate(node.operand, context)
		if node.operator == NOT_OPERATOR then
			return not val
		elseif node.operator == SUBTRACTION_OR_NEGATE_OPERATOR then
			return -val
		end
	elseif node.kind == "Binary" then
		local left = Parser.evaluate(node.left, context)
		local right = Parser.evaluate(node.right, context)
		
		local op = node.operator
		if op == EQUALITY_OPERATOR then return left == right end
		if op == AND_OPERATOR then return left and right end
		if op == OR_OPERATOR then return left or right end
		if op == LESS_THAN_OPERATOR then return left < right end
		if op == MORE_THAN_OPERATOR then return left > right end
		if op == LESS_THAN_OET_OPERATOR then return left <= right end
		if op == MORE_THAN_OET_OPERATOR then return left >= right end
		if op == ADDITION_OPERATOR then return left + right end
		if op == SUBTRACTION_OR_NEGATE_OPERATOR then return left - right end
		if op == MULTIPLICATION_OPERATOR then return left * right end
		if op == DIVISION_OPERATOR then return left / right end
		
	elseif node.kind == "Ternary" then
		local condition = Parser.evaluate(node.condition, context)
		if condition then
			return Parser.evaluate(node.trueExpression, context)
		else
			return Parser.evaluate(node.falseExpression, context)
		end
	end
	
	error("Unknown AST node kind: " .. tostring(node.kind))
end

function Parser.parse(self: Parser): ASTNode
	local result = self:parseExpression(0)
	
	self.reader:skipWhitespace()
	if self.reader:canRead() then
		error("Unexpected character at end of expression: " .. self.reader:peek())
	end
	
	return result
end

function Parser.parseExpression(self: Parser, minPrecedence: number): ASTNode
	self.reader:skipWhitespace()
	
	-- 1. Handle Prefix (Nud)
	local left: ASTNode = self:parsePrefix()
	
	-- 2. Handle Infix (Led)
	while true do
		self.reader:skipWhitespace()
		if not self.reader:canRead() then break end
		
		local op = self:peekOperator()
		if not op then break end
		
		-- Determine precedence
		local opPrecedence = OPERATOR_PRECEDENCES[op] or 0
		
		-- If the next operator binds less tightly than the current context, stop.
		if opPrecedence <= minPrecedence then break end
		
		-- Consume the operator
		self:consumeOperator(op)
		
		if op == FIRST_TERNARY_OPERATOR then
			-- Ternary Special Case
			local trueBranch = self:parseExpression(0)
			
			self.reader:skipWhitespace()
			if self.reader:peek() ~= SECOND_TERNARY_OPERATOR then
				error(`Expected '{SECOND_TERNARY_OPERATOR}' in ternary operator`)
			end
			self.reader:read() -- consume SECOND_TERNARY_OPERATOR
			
			local falseBranch = self:parseExpression(opPrecedence - 1) -- Right associative
			
			left = {
				kind = "Ternary",
				condition = left,
				trueExpression = trueBranch,
				falseExpression = falseBranch
			}
		else
			-- Standard Binary Operator
			local right = self:parseExpression(opPrecedence)
			left = {
				kind = "Binary",
				operator = op,
				left = left,
				right = right
			}
		end
	end
	
	return left
end

function Parser.parsePrefix(self: Parser): ASTNode
	local char = self.reader:peek()
	
	-- Parentheses
	if char == GROUP_OPENING_CHAR then
		self.reader:read() -- consume GROUP_OPENING_CHAR
		local expr = self:parseExpression(0)
		self.reader:skipWhitespace()
		if self.reader:peek() ~= GROUP_CLOSING_CHAR then
			error(`Expected '{GROUP_CLOSING_CHAR}'`)
		end
		self.reader:read() -- consume GROUP_CLOSING_CHAR
		return expr
	end
	
	-- Unary Operators (!, -)
	if char == NOT_OPERATOR or char == SUBTRACTION_OR_NEGATE_OPERATOR then
		self.reader:read()
		local operand = self:parseExpression(OPERATOR_PRECEDENCES["prefix"])
		return {
			kind = "Unary",
			operator = char,
			operand = operand
		}
	end
	
	-- Strings
	if STRING_CHARS[char] then
		return self:parseString()
	end
	
	-- Numbers
	if isDigit(char) then
		return self:parseNumber()
	end
	
	-- Identifiers (Variables/Context lookup)
	if isAlpha(char) then
		return self:parseIdentifier()
	end
	
	error("Unexpected token: " .. char)
end

--

function Parser.parseNumber(self: Parser): ASTNode
	local startPos = self.reader:getCursorPos()
	while self.reader:canRead() and (isDigit(self.reader:peek()) or self.reader:peek() == ".") do
		self.reader:read()
	end
	
	local numStr = table.concat(self.reader:getEncompassingChars(startPos, self.reader:getCursorPos()))
	local num = tonumber(numStr)
	
	if not num then error("Invalid number format: " .. numStr) end
	
	return {
		kind = "Literal",
		value = num
	}
end

function Parser.parseIdentifier(self: Parser): ASTNode
	local startPos = self.reader:getCursorPos()
	while self.reader:canRead() and isAlphaNumeric(self.reader:peek()) do
		self.reader:read()
	end
	
	local name = table.concat(self.reader:getEncompassingChars(startPos, self.reader:getCursorPos()))
	
	-- Check for boolean literals
	if name == "true" then return { kind = "Literal", value = true } end
	if name == "false" then return { kind = "Literal", value = false } end
	
	return {
		kind = "Variable",
		name = name
	}
end

function Parser.parseString(self: Parser): ASTNode
	local quote = self.reader:read() -- consume opening quote
	local parts: { any } = {}
	local currentString = ""
	
	while self.reader:canRead() do
		local char = self.reader:read()
		
		if char == quote then
			-- End of string
			if #currentString > 0 then
				table.insert(parts, { kind = "Literal", value = currentString })
			end
			return {
				kind = "StringInterpolation",
				parts = parts
			}
		elseif char == STRING_INTERP_OPENING_CHAR then
			-- Start Interpolation
			-- Flush current string buffer
			if #currentString > 0 then
				table.insert(parts, { kind = "Literal", value = currentString })
				currentString = ""
			end
			
			-- Parse the inner expression
			local expr = self:parseExpression(0)
			table.insert(parts, expr)
			
			-- Expect closing brace
			if self.reader:peek() == STRING_INTERP_CLOSING_CHAR then
				self.reader:read()
			else
				error(`Expected '{STRING_INTERP_CLOSING_CHAR}' closing string interpolation`)
			end
		else
			currentString = currentString .. char
		end
	end
	
	error("Unterminated string literal")
end

function Parser.peekOperator(self: Parser): string?
	local c1 = self.reader:peek()
	local c2 = self.reader:peekOffset(1)
	
	-- Two-character operators
	if c2 then
		local twoChars = c1 .. c2
		if twoChars == EQUALITY_OPERATOR or twoChars == AND_OPERATOR or twoChars == OR_OPERATOR or 
			twoChars == LESS_THAN_OET_OPERATOR or twoChars == MORE_THAN_OET_OPERATOR then
			return twoChars
		end
	end
	
	-- Single-character operators
	if c1 == ADDITION_OPERATOR or c1 == SUBTRACTION_OR_NEGATE_OPERATOR or
		c1 == MULTIPLICATION_OPERATOR or c1 == DIVISION_OPERATOR or 
		c1 == LESS_THAN_OPERATOR or c1 == MORE_THAN_OPERATOR or
		c1 == FIRST_TERNARY_OPERATOR then
		return c1
	end
	
	return nil
end

function Parser.consumeOperator(self: Parser, op: string)
	for i = 1, #op do
		self.reader:read()
	end
end

--

return Parser