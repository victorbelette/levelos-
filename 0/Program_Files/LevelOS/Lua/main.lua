local tArgs = {...}
if type(tArgs[1]) == "string" and fs.exists(tArgs[1]) then
	lOS.execute(table.concat(tArgs," "))
	return
end
if LevelOS then LevelOS.self.window.icon = {"\3","b"} end
local lex = "LevelOS/modules/lex.lua"
local docs = "Program_Files/Slime_Text/highlight/lua/docs.json"
local docstable
if not fs.exists(lex) then
	-- oh no
end
if not fs.exists(docs) then
	local webres = http.get("http://tweaked.cc/index.json")
	if webres then
		docstable = textutils.unserializeJSON(webres.readAll())
	end
	--[[if webres then
		lUtils.fwrite(docs,webres.readAll())
	end]]
end
if fs.exists(docs) then
	docstable = textutils.unserializeJSON(lUtils.fread(docs))
end
local pretty = require "cc.pretty"

local tCommandHistory = {}
local hCur = 0
local bRunning = true
local tEnv = {
    ["exit"] = setmetatable({}, {
        __tostring = function() return "Call exit() to exit." end,
        __call = function() bRunning = false end,
        __type = "function",
    }),
    ["_echo"] = function(...)
        return ...
    end,
}
setmetatable(tEnv, { __index = _ENV })
term.setTextColor(colors.yellow)
print("LevelOS interactive Lua prompt.\nCall exit() to exit.")
term.setTextColor(colors.white)
while bRunning do
	hCur = #tCommandHistory+1
	write("lua> ")
	local w,h = term.getSize()
	local x,y = term.getCursorPos()
	local self = lUtils.input(x,y,w,y)
	self.opt.cursorColor = colors.white
	self.opt.overflowY = "scroll"
	self.scrollY = 0
	self.opt.syntax = {
		type="lua",
		keyword=colors.yellow,
		comment=colors.green,
		string=colors.red,
		number=colors.purple,
		symbol=colors.white, 
		operator=colors.lightGray,
		value=colors.purple,
		ident=colors.white,
		["function"]=colors.cyan,
		nfunction=colors.lime,
		arg=colors.orange,
		lexer=lex,
		whitespace=colors.lightGray,
	}
	self.opt.complete = {
		docs = docstable,
		env = tEnv,
		overlay = true,
		LevelOS = LevelOS,
	}
	self.opt.selectColor=colors.gray
	self.opt.overflowY="stretch"
	self.opt.overflowX="scroll"
	_G.debugeditor = self
	while true do
		tCommandHistory[hCur] = self.txt
		self.state = true
		local doUpdate = true
		local e = {os.pullEvent()}
		if e[1] == "term_resize" then
			local w,h = term.getSize()
			self.x2 = w
		elseif e[1] == "key" and (e[2] == keys.up or e[2] == keys.down) and not self.opt.complete.list then
			doUpdate = false
			local o = 1
			if e[2] == keys.up then
				o = -1
			end
			if tCommandHistory[hCur+o] then
				hCur = hCur+o
				self.txt = tCommandHistory[hCur]
				self.cursor.x = #self.txt+1
				self.cursor.a = #self.txt+1
			end
			self.update("term_resize")
		elseif e[1] == "key" and e[2] == keys.enter and not lUtils.isHolding(keys.leftShift) then
			if hCur < #tCommandHistory then
				hCur = #tCommandHistory
				tCommandHistory[hCur] = self.txt
			end
			doUpdate = false
			term.setCursorBlink(false)
			LevelOS.overlay = nil
			print("")
			local s = self.txt
			local nForcePrint = 0
			local func, e = load(s, "=lua", "t", tEnv)
			local func2 = load("return _echo(" .. s .. ");", "=lua", "t", tEnv)
			if not func then
				if func2 then
					func = func2
					e = nil
					nForcePrint = 1
				end
			else
				if func2 then
					func = func2
				end
			end
			
			if func then
				local tResults = table.pack(pcall(func))
				if tResults[1] then
					local n = 1
					while n < tResults.n or n <= nForcePrint do
						local value = tResults[n + 1]
						local ok, serialised = pcall(pretty.pretty, value, {
							function_args = settings.get("lua.function_args"),
							function_source = settings.get("lua.function_source"),
						})
						if ok then
							pretty.print(serialised)
						else
							print(tostring(value))
						end
						n = n + 1	
					end
				else
					printError(tResults[2])
				end
			else
				printError(e)
			end
			break
		elseif e[1] == "key" or e[1] == "char" or e[1] == "paste" then
			if hCur < #tCommandHistory then
				hCur = #tCommandHistory
				tCommandHistory[hCur] = self.txt
			end
		end
		if doUpdate then
			self.update(unpack(e))
		end
		local w,h = term.getSize()
		while self.y2 > h do
			if self.y1 > 1 then
				term.scroll(1)
				self.y2 = self.y2-1
				self.y1 = self.y1-1
			else
				self.y1 = 1
				self.y2 = h
				self.opt.overflowY = "scroll"
			end
		end
		self.render()
	end
end