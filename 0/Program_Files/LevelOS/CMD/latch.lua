local tokens = {
	whitespace = {
		["\t"] = true,
		[" "] = true,
		["\n"] = true,
		[","] = true,
	},

	line = {
		["\n"] = true,
		[","] = true,
	},

	label = {
		[":"] = true,
	},

	indexVar = {
		["%"] = true,
	},

	operator = {},
	op = {
		add = {
			["+"] = true,
		},
		subtract = {
			["-"] = true,
		},
		multiply = {
			["*"] = true,
		},
		modulo = {
			["%"] = true,
		},
		power = {
			["^"] = true,
		},
		divide = {
			["/"] = true,
		},
	},

	assign = {
		["="] = true,
	},

	comparison = {},
	comp = {
		equals =  {
			["=="] = true,
		},
		notEquals = {
			["~="] = true,
		},
		bigger = {
			[">"] = true,
		},
		biggerOrEquals = {
			[">="] = true,
		},
		smaller = {
			["<"] = true,
		},
		smallerOrEquals = {
			["<="] = true,
		},
	},

	logic = {},
	logicAnd = {
		["and"] = true,
		["&&"] = true,
	},
	logicOr = {
		["or"] = true,
		["||"] = true,
	},
	logicNot = {
		["not"] = true,
		["!"] = true,
	},

	keyword = {},
	ifStatement = {
		["if"] = true,
	},
	whileStatement = {
		["while"] = true,
	},
	forStatement = {
		["for"] = true,
	},
	elseStatement = {
		["else"] = true,
	},
	localStatement = {
		["local"] = true,
	},
	eof = {
		["end"] = true,
		["exit"] = true,
	},

	boolean = {},
	boolTrue = {
		["true"] = true,
	},
	boolFalse = {
		["false"] = true,
	},

	ident = {
		["_"] = true,
	},
	digits = {
	},

	string = {
		["\""] = true,
		["'"] = true,
	},

	symbol = {
		["("] = true,
		[")"] = true,
	},

	escape = {
		["\\"] = true,
	}
}

for c=("a"):byte(), ("z"):byte() do
	tokens.ident[string.char(c)] = true
	tokens.ident[string.char(c):upper()] = true
end

for c=("0"):byte(), ("9"):byte() do
	tokens.ident[string.char(c)] = true
	tokens.digits[string.char(c)] = true
end

local function addTo(root, ...)
	if not root then error("invalid argument #1: expected table, got nil",2) end
	local tbls = {...}
	for i,t in ipairs(tbls) do
		for k,v in pairs(t) do
			root[k] = v
		end
	end
end

for k,v in pairs(tokens.comp) do
	addTo(tokens.comparison, v)
end

for k,v in pairs(tokens.op) do
	addTo(tokens.operator, v)
end

addTo(tokens.logic, tokens.logicAnd, tokens.logicOr, tokens.logicNot)

addTo(tokens.keyword, tokens.logic, tokens.ifStatement, tokens.whileStatement, tokens.forStatement, tokens.elseStatement, tokens.localStatement, tokens.eof)

addTo(tokens.boolean, tokens.boolTrue, tokens.boolFalse)

local statementValues = {
	["string"] = true,
	["number"] = true,
	["variable"] = true,
	["arg"] = true,
	["value"] = true,
}

local validVarTypes = {
	["function"] = true,
	["arg"] = true,
	["variable"] = true,
	["escape"] = true,
}

local function lex(text)
	local char = 1
	local function get(p)
		local tPos = p or char
		return text:sub(tPos,tPos)
	end
	local beginline = true
	local inStatement = false
	local isLabel = false
	local data = {{}}
	local line = data[1]
	local posOffset = 0
	
	local function newline()
		posOffset = char
		table.insert(data,{})
		line = data[#data]
	end
	
	local function addData(txt,type)
		if not txt then error("no txt",2) end
		if line[#line] and line[#line].type == type then
			line[#line].data = line[#line].data..txt
			line[#line].posLast = line[#line].posLast+#txt
		else
			table.insert(line,{data=txt,posFirst=(char-posOffset),posLast=(char-posOffset)+(#txt-1),type=type})
		end
	end
	
	local function readWhitespace(acceptNewline)
		local txt = get()
		local oldchar = char
		while tokens.whitespace[txt] and (acceptNewline or not tokens.line[txt]) do
			char = char + 1
			addData(txt,"whitespace")
			isLabel = false
			txt = get()
		end
		if oldchar == char then
			return false
		else
			return true
		end
	end
	
	while char <= #text do
		local txt = get()
		if tokens.whitespace[txt] and not tokens.line[txt] then
			addData(txt,"whitespace")
			isLabel = false

		elseif tokens.escape[txt] then
			addData(txt..text:sub(char+1,char+1),"escape")
			char = char+1
			if tokens.whitespace[get(char+1)] then
				isLabel = false
				beginline = false
			end

		elseif tokens.string[txt] then
			local bchar = txt
			local echar = bchar
			local stype = "string"
			if isLabel then
				stype = "label"
			elseif beginline then
				stype = "function"
			end
			isLabel = false
			beginline = false
			addData(txt,stype)
			char = char+1
			while char <= #text do
				local c = text:sub(char,char)
				if tokens.escape[c] then
					addData(c..get(char+1),"escape")
					char = char+1
					if tokens.digits[get()] then
						char = char+1
						for i=1,2 do
							if tokens.digits[get()] then
								addData(get(),"escape")
								char = char+1
							else
								break
							end
						end
					else
						char = char+1
					end
				elseif tokens.indexVar[c] then
					local b2,e2 = text:find("^%%[A-Za-z0-9_]+%%", char)
					if b2 then
						addData(text:sub(b2,e2), "variable")
						char = e2
					else
						local b3,e3 = text:find("^%%[0-9]+", char)
						if not b3 then
							b3,e3 = text:find("^%%~[0-9]+", char)
						end
						if b3 then
							addData(text:sub(b3,e3), "arg")
							char = e3
						else
							addData(c, stype)
						end
					end
					char = char+1
				elseif c == echar then
					addData(c, stype)
					break
				else
					if c == "\n" then
						newline()
					else
						addData(c, stype)
					end
					char = char+1
				end
			end

		elseif tokens.indexVar[txt] then
			if inStatement == 1 and line[#line] and line[#line].type == "whitespace" and line[#line-1] and statementValues[line[#line-1].type] then
				inStatement = false
				beginline = true
			end
			local b2,e2 = text:find("^%%[A-Za-z0-9_]+%%", char)
			if b2 then
				if isLabel and beginline then
					addData(text:sub(b2,e2), "unidentified")
				else
					addData(text:sub(b2,e2), "variable")
				end
				char = e2
			else
				local b3,e3 = text:find("^%%[0-9]+", char)
				if not b3 then
					b3,e3 = text:find("^%%~[0-9]+", char)
				end
				if b3 then
					if isLabel and beginline then
						addData(text:sub(b3,e3), "unidentified")
					else
						addData(text:sub(b3,e3), "arg")
					end
					char = e3
				elseif isLabel then
					addData(txt, "label")
				elseif beginline then
					addData(txt, "function")
				elseif not inStatement then
					addData(txt, "string")
				elseif tokens.operator[txt] then
					addData(txt, "operator")
				else
					addData(txt, "unidentified")
				end
			end
			if tokens.whitespace[get(char+1)] then
				beginline = false
			end

		elseif tokens.ident[txt] or (not inStatement and not (tokens.line[txt] or tokens.label[txt] or tokens.assign[txt] or tokens.symbol[txt])) then
			local b,e
			if inStatement then
				b,e = text:find("^[A-Za-z0-9_.]+", char)
			else
				b,e = char,char+1
				local c = get(e)
				while e <= #text and not (tokens.line[c] or tokens.label[c] or tokens.assign[c] or tokens.indexVar[c] or tokens.whitespace[c] or tokens.symbol[c] or tokens.escape[c]) do
					e = e + 1
					c = get(e)
				end
				e = e - 1
			end
			local token = text:sub(b,e)
			local ltoken = token:lower()
			local statementValue = false
			if inStatement then
				if line[#line] and line[#line].type == "whitespace" and line[#line-1] and statementValues[line[#line-1].type] then
					if inStatement == 1 then
						inStatement = 0
						beginline = true
					end
					statementValue = true
				end
			end
			char = e
			if isLabel then
				addData(token, "label")
				if tokens.whitespace[get(char+1)] then
					isLabel = false
					beginline = false
				end

			elseif tokens.localStatement[ltoken] and not inStatement then
				if not beginline then
					addData(token, "string")
				else
					addData(token, "keyword")
				end
				
			elseif tokens.eof[ltoken] and (inStatement == 0 or not inStatement) then
				addData(token, "keyword")
				
			elseif (tokens.ifStatement[ltoken] or tokens.whileStatement[ltoken]) and (inStatement == 0 or not inStatement) then
				addData(token, "keyword")
				inStatement = 1

			elseif (tokens.elseStatement[ltoken] or tokens.eof[ltoken]) and (inStatement == 0 or not inStatement) then
				addData(token, "keyword")

			elseif (tokens.logicAnd[ltoken] or tokens.logicOr[ltoken]) and statementValue then
				addData(token, "logic")
				if inStatement == 0 then
					inStatement = 1
				end

			elseif tokens.logicNot[ltoken] and inStatement and not statementValue then
				addData(token, "logic")
				if inStatement == 0 then
					inStatement = 1
				end

			elseif tokens.forStatement[ltoken] and (inStatement == 0 or not inStatement) then
				-- other handling
			
			elseif tokens.boolean[ltoken] and inStatement and not statementValue then
				addData(token, "value")

			elseif beginline and (inStatement == 0 or not inStatement) then
				addData(token, "function")
				if tokens.whitespace[get(char+1)] then
					beginline = false
				end
				
			elseif tonumber(token) then
				addData(token, "number")
				if tokens.whitespace[get(char+1)] then
					beginline = false
				end
				
			else
				addData(token, "string")
				
			end
			if inStatement == 0 then
				inStatement = false
			end

		elseif tokens.label[txt] then
			if char+1 > #text or tokens.whitespace[get(char+1)] then
				addData(txt, "string")
			else
				addData(txt, "label")
				isLabel = true
			end

		elseif tokens.line[txt] then
			beginline = true
			inStatement = false
			if txt ~= "\n" then
				addData(txt, "symbol")
			end

		elseif tokens.symbol[txt] then
			addData(txt, "symbol")

		elseif txt:find("%p") then
			local b,e = text:find("^%p+", char)
			local token = text:sub(b,e)
			char = e
			if inStatement then
				if tokens.operator[token] then
					addData(token, "operator")
				elseif tokens.comparison[token] then
					addData(token, "comparison")
				elseif tokens.logic[token] then
					addData(token, "logic")
				else
					addData(token, "string")
				end
			else
				if tokens.assign[token] then
					local v = line[#line]
					if v and v.type == "whitespace" then
						v = line[#line-1]
					end
					if v and (validVarTypes[v.type]) then
						local it = #line-1
						while v and (validVarTypes[v.type]) do
							if v.type == "function" then
								v.type = "variable"
							end
							it = it-1
							v = line[it]
						end
						addData(token, "assign")
						inStatement = true
					elseif beginline then
						addData(token, "unidentified")
					else
						addData(token, "string")
					end
				elseif beginline then
					addData(token, "unidentified")
				else
					addData(token, "string")
				end
			end

		elseif txt ~= "\n" then
			addData(txt, "unidentified")
		end
		if txt == "\n" then
			newline()
		end
		char = char+1
	end
	return data
end

local function parse(data, filename)
	filename = filename or "latch"
	if type(data) == "string" then
		data = lex(data)
	end

	local function err(lineNum, txt, txtafter)
		local err = filename..": "..txt.." on line "..lineNum
		if txtafter then
			err = err.." ("..txtafter..")"
		end
		error(err, 0)
	end

	local function unexpectedToken(line, token, ...)
		_G.debugtoken = token
		local exp = {...}
		local expstr
		if #exp > 0 then
			expstr = "expected "..table.concat(exp, ", ")
		end
		err(line, "unexpected token '"..tostring(token.data).."' ("..tostring(token.type)..")", expstr)
	end

	local function locateEntry(tbl, value)
		for k,v in pairs(tbl) do
			if v == value then
				return true
			end
		end
		return false
	end

	local function parseToken(line, i, allowed, stopAt)
		local token = line[i]
		local data = {}

		stopAt = stopAt or {"whitespace"}

		while true do
			if locateEntry(allowed, token.type) then
				if token.type == "number" then
					table.insert(data, {type="number", data=token.data})
				elseif token.type == "operator" then
					table.insert(data, {type="operator", data=token.data})
				elseif token.type == "variable" and token.data:sub(1,1) == "%" then
					table.insert(data, {type="variable", data=token.data:sub(2,#token.data-1)})
				elseif token.type == "variable" then
					table.insert(data, {type="string", data=token.data})
				elseif token.type == "arg" then
					table.insert(data, {type="argument", data=token.data:sub(2)})
				elseif token.type == "label" then
					if tokens.string[token.data:sub(2,2)] then
						table.insert(data, {type="label", data=token.data:sub(2):gsub(token.data:sub(2,2),"")})
					else
						table.insert(data, {type="label", data=token.data:sub(2)})
					end
				elseif tokens.string[token.data:sub(1,1)] then
					table.insert(data, {type="string", data=token.data:gsub(token.data:sub(1,1),"")})
				else
					table.insert(data, {type="string", data=token.data})
				end
			elseif locateEntry(stopAt, token.type) then
				i = i - 1
				break
			else
				local expected = {}
				addTo(expected, stopAt)
				addTo(expected, allowed)
				unexpectedToken(ln, token, unpack(expected))
			end
			i = i + 1
			token = line[i]
			if not token then break end
		end

		return data, i
	end

	local function parseExpression(line, i, whitespaceConcat) -- this is all wrong FUCK, value (x+5) > comparison (x+5 == 8) > expression(x+5 == 8 and %potato%)
		-- expression structure
		local token = line[i]
		local conditions = {
			{
				{} -- current condition (value)
				-- more AND conditions
			}
			-- more OR conditions
		}
		local condition = conditions[1][1]
		local isValid = false
		while true do
			token = line[i]
			if not token then break end
			if token.type == "whitespace" then -- optional token
			elseif token.type == "logic" and tokens.logicNot[token.data] then -- optional token
				table.insert(condition, token)
				isValid = false
			elseif statementValues[token.type] then -- REQUIRED token, expression is invalid without it
				table.insert(condition, token)
				isValid = true
				i = i + 1
				token = line[i]
				if not token then break end
				if token.type == "whitespace" then
					i = i + 1
					token = line[i]
				end
				if not token then break end
				if token.type == "logic" and tokens.logicAnd[token.data] then
					condition = {}
					table.insert(conditions[#conditions], condition)
					isValid = false
				elseif token.type == "logic" and tokens.logicOr[token.data] then
					condition = {}
					table.insert(conditions, {})
					table.insert(conditions[#conditions], condition)
					isValid = false
				elseif token.type == "operator" then
					table.insert(condition, token)
				elseif whitespaceConcat then
					i = i - 1
				else
					i = i - 1
					break -- end of statement
				end
			else
				unexpectedToken(i, token, "expression")
			end
			i = i + 1
		end
		if not isValid then
			err(i, "invalid statement")
		else
			return conditions, i
		end
	end


	local program = {
		arguments = {},
		env = {},
		commands = {},
		labels = {},
		code = {},
	}
	local scope = program.code
	for ln,line in ipairs(data) do
		local token
		local i = 1
		local beginline = true
		local function nextToken(includeWhitespace)
			if line[i+1] and (includeWhitespace or line[i+1].type ~= "whitespace") then
				return line[i+1]
			elseif line[i+2] then
				return line[i+2]
			end
		end
		local function nextTokenType(includeWhitespace)
			local nt = nextToken(includeWhitespace)
			if nt then
				return nt.type
			end
		end
		while i <= #line do
			token = line[i]
			if beginline then
				if token.type == "function" or token.type == "variable" or token.type == "arg" then
					local data
					data, i = parseToken(line, i, {"function", "variable", "arg", "escape"}, {"whitespace", "symbol", "assign"})
					local l
					if nextTokenType() == "assign" then
						l = {type="assign", data=data, value={}}
						while nextTokenType() == "assign" do
							i = i + 1
						end
						i = i + 1
						l.value, i = parseExpression(line, i, true)
					else
						l = {type="command", data=data, line=ln, params={}}
						beginline = false
					end
					table.insert(scope, l)

				elseif token.type == "label" then
					program.labels[token.data] = {scope=scope, commandNum=#scope+1}

				elseif token.type ~= "whitespace" then
					--unexpectedToken(ln, token, "whitespace", "function", "variable", "arg")
				end

			else
				if token.type == "label" then
					if scope[#scope].type == "command" then
						local data
						data, i = parseToken(line, i, {"label", "variable", "arg", "escape"}, {"whitespace", "symbol"})
						table.insert(scope[#scope].params, data)
					else
						unexpectedToken(ln, token)
					end

				elseif token.type == "string" or token.type == "number" then
					if scope[#scope].type == "command" then
						local data
						data, i = parseToken(line, i, {"string", "number", "variable", "arg", "escape"}, {"whitespace", "symbol"})
						table.insert(scope[#scope].params, data)
					end

				elseif token.type ~= "whitespace" then

				end
			end
			i = i + 1
		end
	end
	return program
end

return {lex=lex,parse=parse}