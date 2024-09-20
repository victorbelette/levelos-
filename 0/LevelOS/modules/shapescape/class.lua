local class = {}

local tAPI = {} -- local class API for objects

local shapescape

class.init = function(api)
	shapescape = api
	setmetatable(tAPI, {__index=api.group})
	api.generic.convertToClass = class.convertToClass
end

tAPI.initialize = function(obj)

	local scape = obj:getScape()
	local publicProperties = obj.publicProperties or {}
	setmetatable(obj, {__index=tAPI})
	obj.isClass = true
	local str = ""
	
	for k,v in pairs(publicProperties) do
		if v == "" then
			table.remove(publicProperties,k)
		end
	end

	if not shapescape.utils.locateEntry(publicProperties, "properties") then
		table.insert(publicProperties,"properties")
	end
	
	for i,p in ipairs(publicProperties) do
		if p == "width" then
			str = str.."instance:resize(width or instance.width)\n"
		elseif p == "height" then
			str = str.."instance:resize(nil, height or instance.height)\n"
		elseif p == "x" then
			str = str.."instance:move(x or instance.x)\n" -- "or instance.x1" is already done by API when provided with nil value
		elseif p == "y" then
			str = str.."instance:move(nil, y or instance.y)\n"
		else
			str = str.."instance."..p.." = "..p.." or instance."..p.."\n"
		end
	end

	table.insert(publicProperties,1,"self")
	
	local fStr = [[
return function(]]..table.concat(publicProperties,",")..[[)
	local instance = shapescape.utils.instantiate(self)
	if instance.name then
		instance.class = instance.name
		instance.name = nil
	end
	]]..str..[[
	for k,v in pairs(properties or {}) do
		instance[k] = v
	end
	instance.isClass = nil
	return instance
end]]

	local func,err = load(fStr,"@instantiate",nil,{shapescape=shapescape,pairs=pairs})
	if func then
		obj.instantiate = func()
	else
		_G.debugstr = fStr
		error(err,0)
	end
	if obj.name then
		scape.variables[obj.name] = obj
	end
end

tAPI.instantiateTo = function(self, target, ...)
	if not self.instantiate then
		self:initialize()
	end
	return target:addObject(self:instantiate(...))
end

class.convertToClass = function(self, publicProperties, posProperties)
	publicProperties = publicProperties or {}
	if self.active then
		error("Cannot convert active objects",2)
	end
	local sl = self:getSlide()
	if sl then
		-- remove obj from slide
		self:destroy(false)
	end
	setmetatable(self, {__index=tAPI})
	self.isClass = true
	self.publicProperties = publicProperties
	local coords = {}
	if posProperties == 1 or posProperties == nil then -- if posProperties is false then no position
		coords = {"x1","y1","x2","y2"}
	elseif posProperties == 2 then
		coords = {"x","y","width","height"}
	elseif posProperties == 3 then
		coords = {"x","y"}
	elseif posProperties == 4 then
		coords = {"width","height"}
	end
	for i,c in ipairs(coords) do
		if not shapescape.utils.locateEntry(publicProperties, c) then
			table.insert(publicProperties, i, c)
		end
	end
	table.insert(self:getScape().classes,self)
	if self:getScape().active then
		self:initialize()
	end
end

tAPI.convertToObject = function(self,slide)
	self.publicProperties = nil
	self.isClass = nil
	for k,v in ipairs(self:getScape().classes) do
		if v == self then
			table.remove(self:getScape().classes,k)
		end
	end
	slide:addObject(self)
end

tAPI.destroy = function(self)
	-- remove from classes
	for k,v in ipairs(scape.classes) do
		if v == self then
			table.remove(scape.classes,k)
		end
	end
	shapescape.generic.destroy(self)
end

class.load = function(classObj)
	setmetatable(classObj, {__index=tAPI})
	if classObj.children then
		for i,child in ipairs(classObj.children) do
			shapescape.loadObject(child)
			child.parent = classObj
			child.id = i
		end
	end
end

return class