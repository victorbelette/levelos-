------------------------------------------------ LevelOOPer Library 2.2.6 ------------------------------------------------
function _G.pairs(t)
	local mt = getmetatable(t)
	if mt and type(mt.__pairs) == "function" then
		return mt.__pairs(t)
	else
		return next, t, nil
	end
end

local function fread(file)
	local f = fs.open(file,"r")
	local txt = f.readAll()
	f.close()
	return txt
end

local env = _ENV
local oop = {}

local classCache = {}
local privCache = {}
local publicCache = {}
local objectCache = {}

local dir = fs.getDir(({...})[1] or shell.getRunningProgram())

local function typeRestriction(index, sType, value)
	if not oop.isType(value, sType) then
		return false, "cannot convert "..sType.." '"..index.."' to '"..oop.type(value, true).."'"
	else
		return true
	end
end

local function getNumberType(number)
	if number%1 == 0 then
		return "int"
	else
		return "double"
	end
end

oop.setEnv = function(newEnv)
	env = newEnv
end

oop.setDir = function(newDir)
	oop.expect(1, newDir, "string")
	dir = newDir
end

oop.getDir = function()
	return dir
end

local default = {
	int = 0,
	double = 0,
	number = 0,
	string = "",
	["function"] = function() end,
	table = {},
	boolean = false,
}

local varTypes = {
	int = "int",
	double = "double",
	num = "number",
	str = "string",
	func = "function",
	tbl = "table",
	bool = "boolean",
}

local newVar = {
	var = function(name)
		local tbl = {name=name}
		setmetatable(tbl, {
			__call = function(self, value)
				self.value = value
				return self
			end
		})
		return tbl
	end,
	obj = function(class)
		oop.expect(1, class, "class")
		local var = {type=classCache[class].name}
		setmetatable(var, {
			__call = function(self, name)
				self.name = name
				setmetatable(var, {
					__call = function(self, value)
						local ok,err = typeRestriction(name, var.type, value)
						if not ok then
							error(err, 2)
						else
							self.value = value
							return self
						end
					end,
				})
				return self
			end,
		})
		return var
	end,
}

local const = function(name)
	if type(name) == "function" then
		return function(realname)
			local var = name(realname)
			var.const = true
			return var
		end
	elseif type(name) == "string" then
		local var = {name=name, const=true}
		setmetatable(var, {
			__call = function(self, value)
				self.value = value
				return self
			end,
		})
		return var
	end
end

for k,v in pairs(varTypes) do
	newVar[k] = function(name)
		local tbl = {name=name, type=varTypes[k]}
		setmetatable(tbl, {
			__call = function(self, value)
				local stat,err = typeRestriction(name, tbl.type, value)
				if not stat then
					error(err, 2)
				else
					self.value = value
					return self
				end
			end,
		})
		return tbl
	end
end

oop.injectEnv = function(env)
	env.oop = oop
	env.class = oop.class
	env.const = const
	env.import = oop.import
	env.type = oop.type
	env.getPublicObject = oop.getPublicObject
	for k,v in pairs(newVar) do
		env[k] = v
	end
end

local metamethods = {
	["__add"] = true,
	["__sub"] = true,
	["__mul"] = true,
	["__div"] = true,
	["__mod"] = true,
	["__pow"] = true,
	["__unm"] = true,
	["__concat"] = true,
	["__len"] = true,
	["__eq"] = true,
	["__lt"] = true,
	["__le"] = true,
	["__index"] = true,
	["__newindex"] = true,
	["__call"] = true,
	["__tostring"] = true,
	["__metatable"] = true,
	["__pairs"] = true,
	["__ipairs"] = true
}

local function sanitizeArgs(...)
	local args = table.pack(...)
	for k,v in pairs(args) do
		if publicCache[v] then
			args[k] = publicCache[v]
		end
	end
	return table.unpack(args, nil, args.n)
end

local function instantiate(orig)
	local function deepCopy(o, seen)
		seen = seen or {}
		if seen[o] then
			return seen[o]
		end
		local copy
		if type(o) == 'table' then
			copy = {}
			seen[o] = copy
			for k,v in pairs(o) do
				copy[deepCopy(k, seen)] = deepCopy(v, seen)
			end
			setmetatable(copy, deepCopy(getmetatable(o), seen))
		else
			copy = o
		end
		return copy
	end
	return deepCopy(orig)
end

local function makeClass(name, classTbl, inherit)
	local class = {
		static = {
		},
		private = {
		},
		public = {
		},
		properties = {
			static = {
			},
			private = {
			},
			public = {
			},
			types = {
			},
			consts = {
			},
		},
		metatable = {
			public = {
			},
			private = {
			},
		},
		name = name,
	}

	class.metatable.static = {
		__index = class.static,
		__newindex = function(tbl, k, v)
			if class.properties.static[k] then
				if class.properties.consts[k] then
					error("cannot modify const '"..tostring(k).."'", 2)
				elseif class.properties.types[k] then
					local stat,err = typeRestriction(k, class.properties.types[k], v)
					if not stat then
						error(err, 2)
					else
						class.static[k] = v
					end
				end
			elseif class.properties.private[k] then
				error("cannot modify private property '"..tostring(k).."' outside of class", 2)
			elseif class.properties.public[k] then
				error("cannot modify public property '"..tostring(k).."' outside of object", 2)
			end
		end,
		__call = function(self, ...)
			local privObj = {}
			local obj = {}

			privCache[obj] = privObj
			publicCache[privObj] = obj

			local properties = {}
			local privProperties = {}

			setmetatable(properties, {__index=class.public})
			setmetatable(privProperties, {
				__index=function(t, k)
					return properties[k] or class.private[k]
				end
			})

			local mt = {
				__index = function(t, k)
					local p = properties
					if t == privObj then
						p = privProperties
					end
					local v = p[k]
					if type(v) == "function" then
						local tEnv = {self=privObj}
						oop.injectEnv(tEnv)
						setmetatable(tEnv, {__index=env})
						setfenv(v, tEnv)
					end
					return v
				end
			}
			
			local inConstructor = false

			mt.__pairs = function(tbl)
				local loopThroughTables = {properties, class.public, class.static}
				if tbl == privObj then
					table.insert(loopThroughTables, 2, class.private)
				end
				local cls = class
				while cls.parent do -- this WONT WORK
					cls = cls.parent
					if tbl == privObj then
						table.insert(loopThroughTables, cls.private)
					end
					table.insert(loopThroughTables, cls.public)
					table.insert(loopThroughTables, cls.static)
				end
				
				local currentIndex = 1

				local had = {}
				
				local function customIterator(_, prevKey)
					local key, value
					
					while currentIndex <= #loopThroughTables do
						key, value = next(loopThroughTables[currentIndex], prevKey)
						while key ~= nil and had[key] do -- skip keys that were already found
							key, value = next(loopThroughTables[currentIndex], key)
						end
						
						if key ~= nil then
							had[key] = true
							return key, tbl[key]
						else
							prevKey = nil
							currentIndex = currentIndex + 1
						end
					end
					
					return nil
				end
				
				return customIterator, tbl, nil
			end
			
			mt.__newindex = function(tbl, k, v)
				if class.properties.consts[k] and not inConstructor then
					error("cannot modify const '"..tostring(k).."'", 2)
				end
				if tbl ~= privObj and class.properties.private[k] then
					error("cannot modify private property '"..tostring(k).."' outside of class", 2)
				end
				if class.properties.types[k] then
					local stat,err = typeRestriction(k, class.properties.types[k], v)
					if not stat then
						error(err, 2)
					end
				end
				if class.properties.static[k] then
					-- change in whole class
					class.static[k] = v
				elseif class.properties.private[k] then
					privProperties[k] = v
				else
					properties[k] = v
				end
			end

			local mt2 = {}

			for k,v in pairs(mt) do
				mt2[k] = v
			end

			for k,v in pairs(class.metatable.public) do
				mt[k] = function(...)
					local tEnv = {self=privObj}
					oop.injectEnv(tEnv)
					setmetatable(tEnv, {__index=env})
					setfenv(v, tEnv)
					return v(sanitizeArgs(...))
				end
			end

			for k,v in pairs(class.metatable.private) do
				mt2[k] = function(...)
					local tEnv = {self=privObj}
					oop.injectEnv(tEnv)
					setmetatable(tEnv, {__index=env})
					setfenv(v, tEnv)
					return v(sanitizeArgs(...))
				end
			end

			setmetatable(obj, mt)
			setmetatable(privObj, mt2)

			local constructors = {class.constructor}
			local cls = class
			while cls.parent do
				cls = cls.parent
				if cls.constructor then
					table.insert(constructors, 1, cls.constructor)
				end
			end
			for t=1,#constructors do
				inConstructor = true
				local tEnv = {self=privCache[obj] or obj}
				oop.injectEnv(tEnv)
				setmetatable(tEnv, {__index=env})
				setfenv(constructors[t], tEnv)
				local status,tObj = pcall(constructors[t],sanitizeArgs(...))
				if not status then
					error(tObj, 2)
				end
				if tObj == false then
					return false
				elseif tObj then
					obj = publicCache[tObj] or tObj
				end
				inConstructor = false
			end

			objectCache[obj] = class
			objectCache[privObj] = class

			for k,v in pairs(privObj) do
				if type(v) == "table" and v == class.private[k] then
					privObj[k] = instantiate(v)
				end
			end

			return obj
		end,
	}
	
	local iClass
	if inherit then
		iClass = classCache[inherit]
		class.parent = iClass
		setmetatable(class.static, {__index=iClass.static})
		setmetatable(class.public, {
			__index = function(tbl, key)
				if iClass.public[key] ~= nil then
					return iClass.public[key]
				else
					return class.static[key]
				end
			end,
		})
		
		setmetatable(class.private, {
			__index = function(tbl, key)
				if iClass.private[key] ~= nil then
					return iClass.private[key]
				else
					return class.public[key]
				end
			end,
		})
		
		for k,v in pairs(class.properties) do
			setmetatable(v, {__index=iClass.properties[k]})
		end
		
		setmetatable(class, {__index=iClass})
	else
		setmetatable(class.public, {__index=class.static})
		setmetatable(class.private, {__index=class.public})
	end
	
	loopThrough = {"static","private","public"}
	for i,l in ipairs(loopThrough) do
		if classTbl[l] then
			for k,v in pairs(classTbl[l]) do
				if type(k) == "number" then
					if type(v) == "table" and v.name then
						if v.const then
							class.properties.consts[v.name] = true
						end
						if v.type then
							class.properties.types[v.name] = v.type
						end
						if v.value or v.type then
							class[l][v.name] = v.value or default[v.type]
						end
						class.properties[l][v.name] = true -- now values can be generic typed starting with nil but still recognized
					elseif type(v) == "string" then
						class.properties[l][v] = true
					end
				elseif type(k) == "string" then
					if l == "public" and k == name then -- constructor
						if type(v) ~= "function" then
							error("invalid constructor: expected function, got "..type(v),2)
						end
						class.constructor = v
					elseif metamethods[k] then
						class.metatable[l][k] = v
					else
						class[l][k] = v
						class.properties[l][k] = true
					end
				end
			end
		end
	end

	local classObj = {}

	classCache[classObj] = class
	class.obj = classObj

	setmetatable(classObj, class.metatable.static)

	env[name] = classObj
end

function oop.class(name)
	return function(class)
		if classCache[class] then -- a class object was passed meaning we're gonna inherit
			return function(realclass)
				makeClass(name, realclass, class)
			end
		else
			makeClass(name, class)
		end
	end
end

local oType = type
function oop.type(value, numberType)
	if oType(value) == "table" then
		if objectCache[value] then
			return objectCache[value].name
		elseif classCache[value] then
			return "class"
		else
			return "table"
		end
	elseif numberType and oType(value) == "number" then
		return getNumberType(value)
	else
		return oType(value)
	end
end

function oop.getClassName(class)
	oop.expect(1, class, "class")
	return classCache[class].name
end

function oop.isType(value, ...)
	local types = {oop.type(value), oType(value), oop.type(value, true)}
	if types[1] ~= types[2] and types[3] ~= "class" then
		types[3] = "object"
	end
	local allowedTypes = {...}
	for i,t in ipairs(types) do
		for i=1, #allowedTypes do
			if allowedTypes[i] == t or (allowedTypes[i] == "double" and t == "number") then
				return true
			end
		end
	end
	return false
end

function oop.expect(index, value, ...)
	local level = 3
	local allowedTypes = {...}
	if type(allowedTypes[1]) == "number" then
		level = allowedTypes[1]
		table.remove(allowedTypes, 1)
	end
	if type(allowedTypes[1]) ~= "string" then
		error("bad argument #3: expected string", 2)
	end
	if oop.isType(value, ...) then
		return value
	end

	local expectlist
	local numbertype = false
	for t=1,#allowedTypes do
		if allowedTypes[t] == "int" then
			numbertype = true
		end
	end
	if #allowedTypes > 1 then
		local lastType = allowedTypes[#allowedTypes]
		allowedTypes[#allowedTypes] = nil
		expectlist = table.concat(allowedTypes, ", ").." or "..lastType
	else
		expectlist = allowedTypes[1]
	end
	local t = oop.type(value, numbertype)

	error("bad argument #"..index..": expected "..expectlist.." got "..t.." ("..tostring(value)..")", level)
end

function oop.getPublicObject(privateObject)
	return publicCache[privateObject] or privateObject
end

function oop.import(filepath)
	oop.expect(1, filepath, "string")

	local makePackage = require("cc.require")
	local tEnv = setmetatable({shell=shell, multishell=multishell},{__index=env})
	tEnv.require, tEnv.package = makePackage.make(tEnv, dir)
	tEnv.oop = oop

	oop.injectEnv(tEnv)

	local pathlog = filepath
	local filepath2 = filepath..".lua"
	pathlog = pathlog.."\n"..filepath2

	if filepath:sub(1,1) ~= "/" then
		pathlog = pathlog.."\n"..fs.combine(dir, filepath)
		pathlog = pathlog.."\n"..fs.combine(dir, filepath2)
		if fs.exists(fs.combine(dir, filepath)) then
			filepath = fs.combine(dir, filepath)
		elseif fs.exists(fs.combine(dir, filepath2)) then
			filepath = fs.combine(dir, filepath2)
		end
	end

	if fs.exists(filepath2) and not fs.exists(filepath) then
		filepath = filepath2
	end

	if not fs.exists(filepath) then
		error("Could not find file:"..pathlog,2)
	end

	local f = fread(filepath)

	local func, err = load(f, "@"..filepath, nil, tEnv)

	if not func then
		error(err, 2)
	else
		local ok,err = pcall(func)
		if not ok then
			error(err, 2)
		end
	end
end

return oop