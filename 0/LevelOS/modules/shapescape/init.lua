-- shapescape

-- somehow you need to detect whether the inputted argument is the path from require or a path from shell to execute a .scape file
-- i guess the best way to do that is to just check if the file extension is .scape
-- lol yea

-- also if the file extension IS .scape, that means the API path is actually shell.getRunningProgram()

local tArgs = {...}
local shapescape = {utils={},slide={},scape={},generic={}}

local scapeRef = {}
local slideRef = {}

local corFilterCache = {}

local doExecute
	
if type(tArgs[1]) == "string" and string.find(tArgs[1],"%.%w+$") and string.sub(tArgs[1],string.find(tArgs[1],"%.%w+$")) == ".scape" then
	-- execute file
	-- somehow
	doExecute = tArgs[1]
	shapescape.path = shell.getRunningProgram()
else
	shapescape.path = tArgs[2] or tArgs[1]
end

if shapescape.path then
	shapescape.path = "/"..fs.getDir(shapescape.path)
end

do -- imports
	local function doImport(t,k)
		local n
		for k,v in pairs(shapescape) do
			if v == t then
				n = k
				break
			end
		end
		if not n then
			error("Module not found",2)
		end
		shapescape[n] = require("/"..fs.combine(shapescape.path,n))
		if shapescape[n].init then
			shapescape[n].init(shapescape)
		end
		for k,v in pairs(shapescape[n]) do
			t[k] = v
		end
		return shapescape[n][k]
	end

	local function getFileType(filename)
		if string.find(filename,"%.%w+$") == nil then
			return ""
		else
			return string.sub(filename,string.find(filename,"%.%w+$"))
		end
	end



	local function getFileName(filename,ext)
		local f = filename
		if string.find(filename," ") then
			f = string.sub(filename,1,({string.find(filename," ")})[1]-1)
		end
		f = fs.getName(f)
		if not ext or getFileType(f) == ".llnk" then
			f = string.sub(f,1,string.len(f)-string.len(getFileType(f)))
		end
		return string.gsub(f,"_"," ")
	end

	local ls = fs.list(shapescape.path)
	for i,f in ipairs(ls) do
		if f ~= "init.lua" then
			local n = getFileName(f)
			shapescape[n] = {import=function() doImport(shapescape[n]) end}
			setmetatable(shapescape[n],{__index=doImport})
		end
	end
end



-- [[ UTILITIES API ]]
local utils = shapescape.utils
utils.wordwrap = function(txt,tWidth)
	local lines = {}
	for line in txt:gmatch("([^\n]*)\n?") do
		table.insert(lines,"")
		for word in line:gmatch("%S*%s?") do
			local width
			if type(tWidth) == "table" then
				if not tWidth[#lines] then
					lines[#lines] = nil
					return lines
				else
					width = tWidth[#lines]
				end
			else
				width = tWidth
			end
			if #lines[#lines]+#word > width and #(lines[#lines]:gsub(" ","")) > 0 then
				lines[#lines+1] = ""
			end
			if #lines[#lines]+#word > width then
				local tWord = word
				while #lines[#lines]+#tWord > width do
					lines[#lines] = tWord:sub(1,width)
					table.insert(lines,"")
					tWord = tWord:sub(width+1)
				end
				lines[#lines] = tWord
			else
				lines[#lines] = lines[#lines]..word
			end
		end
	end
	if lines[#lines] == "" then
		lines[#lines] = nil
	end
	if txt:sub(#txt) == "\n" then
		table.insert(lines,"")
	end
	while type(tWidth) == "table" and #lines > #tWidth do
		lines[#lines] = nil
	end
	return lines
end

local animationTbl = {}
utils.renderImage = function(spr,x,y,format,transparency)
	local format
	local img = spr
	local cterm = term.current()
	if not format then
		if type(spr) == "string" then
			format = "nfp"
		elseif type(spr) == "table" then
			format = "bImg"
			if type(spr[1][1]) == "table" then
				if #spr == 1 or not spr.animated then
					spr = spr[1]
				else
					if not animationTbl[spr] then
						animationTbl[spr] = {cFrame=0,oTime=os.epoch("utc")/1000}
					else
						local cFrame = animationTbl[spr].cFrame+0.0001
						local dur = spr[math.ceil(cFrame)].duration or spr.secondsPerFrame or 0.05
						local oTime = animationTbl[spr].oTime
						local cTime = os.epoch("utc")/1000
						local delta = (cTime-oTime)
						animationTbl[spr].cFrame = (cFrame + delta/dur) % #spr
						animationTbl[spr].oTime = cTime
					end
					spr = spr[math.ceil(animationTbl[spr].cFrame+0.0001)]
				end
			end
		end
	end
	if format == "bImg" or format == "lImg" then
		if not spr[1] or not spr[1][1] or type(spr[1][1]) ~= "string" then
			error("Unrecognized format",2)
		end
		local sW,sH = #spr[1][1],#spr
		local w,h = term.getSize()
		for l=1,#spr do
			--[[if not y then
				term.setCursorPos(math.ceil(w/2)-math.floor(sW/2),(math.ceil(h/2)-math.floor(sH/2)+(l-1)))
			else
				term.setCursorPos(x,y+(l-1))
			end]]
			local line
			if y then
				line = y+(l-1)
			end
			local cX,cY = x or math.ceil(w/2)-math.floor(sW/2), line or (math.ceil(h/2)-math.floor(sH/2)+(l-1))
			term.setCursorPos(cX,cY)
			local bl = {}
			bl[1] = spr[l][1]
			if transparency then
				bl[2] = spr[l][2]
				bl[3] = spr[l][3]
				-- thing
				local line
				if cY >= 1 and cY <= h then
					line = {cterm.getLine(cY)}
					for t=1,3 do
						line[t] = line[t]:sub(cX,cX+(#spr[l][1]-1))
					end
				else
					line = {string.rep("f",#spr[l][1])}
					line[2] = line[1]
					line[3] = line[2]
				end
				if #line[2] < #spr[l][1] then
					line[1] = line[1]..string.rep(" ",#spr[l][1]-#line[1])
					line[2] = line[2]..string.rep("f",#spr[l][1]-#line[2])
					line[3] = line[3]..string.rep("f",#spr[l][1]-#line[3])
				end
				local start,final = 0,0
				while true do
					start,final = bl[2]:gsub(" ","T"):find("T")
					if start then
						bl[2] = bl[2]:sub(1,start-1)..line[3]:sub(start,final)..bl[2]:sub(final+1,#bl[2])
					else
						break
					end
				end
				while true do
					start,final = bl[3]:gsub(" ","T"):find("T")
					if start then
						if bl[1]:sub(start,final) == " " or bl[1]:sub(start,final) == "\128" then
							bl[1] = bl[1]:sub(1,start-1)..line[1]:sub(start,final)..bl[1]:sub(final+1,#bl[1])
							bl[2] = bl[2]:sub(1,start-1)..line[2]:sub(start,final)..bl[2]:sub(final+1,#bl[2])
						end
						bl[3] = bl[3]:sub(1,start-1)..line[3]:sub(start,final)..bl[3]:sub(final+1,#bl[3])
					else
						break
					end
				end
			else
				bl[2] = string.gsub(spr[l][2]:gsub(" ","T"),"T",utils.toBlit(term.getBackgroundColor()))
				bl[3] = string.gsub(spr[l][3]:gsub(" ","T"),"T",utils.toBlit(term.getBackgroundColor()))
			end
			term.blit(unpack(bl))
		end
	elseif format == "nfp" or format == "nfg" then
		local b,e = string.find(spr,"\n")
		local sW,sH
		local w,h = term.getSize()
		local lines,sW = getLines(spr)
		sH = #lines
		for l=1,sH do
			local line
			if y then
				line = y+(l-1)
			end
			term.setCursorPos(x or math.ceil(w/2)-math.floor(sW/2), line or math.ceil(h/2)-math.floor(sH/2)+(l-1))
			for lX=1,sW do
				local ch = lines[l]:sub(lX,lX)
				if ch ~= " " and ch ~= "" then
					term.blit(" ","f",ch)
				else
					local cx,cy = term.getCursorPos()
					term.setCursorPos(cx+1,cy)
				end
			end
		end
	end
end

utils.instantiate = function(orig)
	local function deepCopy(o, seen) -- so that "seen" doesn't appear in autocomplete
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

local to_colors, to_blit = {}, {}
for i = 1, 16 do
	to_blit[2^(i-1)] = ("0123456789abcdef"):sub(i, i)
	to_colors[("0123456789abcdef"):sub(i, i)] = 2^(i-1)
end

utils.toColor = function(theblit)
	return to_colors[theblit] or nil
end

utils.toBlit = function(thecolor)
	return to_blit[thecolor] or nil
end

utils.fread = function(filepath)
	local fread = fs.open(filepath,"r")
	local thing = fread.readAll()
	fread.close()
	return thing
end

utils.locateEntry = function(tbl,value)
	for k,v in pairs(tbl) do
		if v == value then
			return k
		end
	end
end

utils.genStatelessIterator = function(...)
	local tbls = {...}
	local function iter(tbl)
		local temp = {}
		for i=#tbls,1 do
			for k,v in pairs(tbls[i]) do
				temp[k] = v
			end
		end
		return next,temp
	end
	return iter
end

-- [[ LOCAL API ]]
shapescape.debug = {scapeRef=scapeRef,slideRef=slideRef}
if not lOS.pDebug then
	lOS.pDebug = {}
end
if not lOS.pDebug.scapes then
	lOS.pDebug.scapes = {}
end
shapescape.debug.scapes = lOS.pDebug.scapes
local dLocal = shapescape.debug

local function runListener(listeners,scape)
	for k=#listeners,1,-1 do
		local func = listeners[k]
		local ok,err = pcall(func,unpack(scape.args))
		if not ok then
			if not scape.blacklist then
				scape.blacklist = {}
			end
			if scape.blacklist[func] then
				table.remove(listeners,k)
			else
				scape.blacklist[func] = true
				scape:warn(err)
			end
		end
	end
end
dLocal.runListener = runListener

local pointerCache = {}
dLocal.pointerCache = {}
local function runPointer(pointerValue,scape,self)
	local pointer = self.pointers[pointerValue]
	local ret
	if type(pointer) == "string" or pointer.type == "formula" then
		local formula
		if type(pointer) == "string" then
			formula = pointer
		else
			formula = pointer.content
		end
		local env = {
			self = self,
			-- load shapescape api or something too
			math = math,
		}
		env.width,env.height = scape.slides[scape.currentSlide]:getSize()
		setmetatable(env,{__index=scape.variables})
		local id = self.name or self.id
		local func,err = load("return "..formula,"@"..id.."."..pointerValue, nil, env)
		if not func then
			func,err = load(formula,"@"..id.."."..pointerValue, nil, env)
		end
		if not func then
			scape:warn(err)
		else
			local ok,output = pcall(func)
			if ok then
				if pointerValue == "text" and type(output) == "string" then
					output = {content=output, color=self.textColor or colors.white}
				elseif (pointerValue == "fill" or pointerValue == "border") and type(output) == "number" then
					output = {color=output}
				end
				ret = output
			else
				scape:warn(output)
				ret = 0
			end
		end
	elseif pointer.type == "variable" then
		-- parse dots
		ret = scape.variables[pointer.content]
	end
	if not pointerCache[self] then
		pointerCache[self] = {}
	end
	if pointerCache[self][pointerValue] ~= ret then
		pointerCache[self][pointerValue] = ret
		self:markAsChanged()
	end
	return ret
end
dLocal.runPointer = runPointer

local function deleted(t,k)
	if k == "deleted" or k == "destroyed" then
		return t
	else
		error("This object no longer exists.",2)
	end
end
dLocal.deleted = deleted

local function captureCursor()
	local cursor = {}
	cursor.x,cursor.y = term.getCursorPos()
	cursor.color = term.getTextColor()
	cursor.blink = term.getCursorBlink()
	return cursor
end

local function restoreCursor(cursor)
	term.setCursorPos(cursor.x,cursor.y)
	term.setTextColor(cursor.color)
	term.setCursorBlink(cursor.blink)
end

local function resumeCoroutines(self,...)
	local ev = {...}
	local scape = self:getScape()
	for i=#self.coroutines,1,-1 do
		local cor = self.coroutines[i]
		if coroutine.status(cor) == "dead" then
			table.remove(self.coroutines,i)
		elseif not (corFilterCache[cor] and ev[1] ~= corFilterCache[cor]) then
			local oterm = term.current()
			if self.window then
				term.redirect(self.window)
			end
			local ok, filter = coroutine.resume(cor,...)
			if not ok then
				scape:warn(filter)
				table.remove(self.coroutines,i)
			else
				corFilterCache[cor] = filter
			end
			term.redirect(oterm)
		end
	end
end
dLocal.resumeCoroutines = resumeCoroutines

local function fixChildren(o)
	for i,obj in ipairs(o.children) do
		scapeRef[obj] = scapeRef[o]
		slideRef[obj] = slideRef[o]
		if obj.children then
			fixChildren(obj)
		end
	end
end

local changeCache = {}
local renderCache = {}
dLocal.renderCache = renderCache
dLocal.changeCache = changeCache

-- [[ GENERIC API ]]
local generic = shapescape.generic

generic.getAbsolutePosition = function(self,includePadding)
	local x1,y1,x2,y2 = self.x1,self.y1,self.x2,self.y2
	local o = self
	while o.parent do
		--local p = o.parent.padding or 0
		--local pL,pR,pT,pB = (o.parent.paddingLeft or p), (o.parent.paddingRight or p), (o.parent.paddingTop or p), (o.parent.paddingBottom or p)
		local off = 0
		if o.parent.border then
			off = 1
		end
		x1 = x1+o.parent.x1-1+off
		x2 = x2+o.parent.x1-1+off
		y1 = y1+o.parent.y1-1+off
		y2 = y2+o.parent.y1-1+off
		o = o.parent
	end
	if includePadding then
		local p = self.padding or 0
		local pL,pR,pT,pB = (self.paddingLeft or p), (self.paddingRight or p), (self.paddingTop or p), (self.paddingBottom or p)
		x1, y1, x2, y2 = x1-pL, y1-pT, x2+pR, y2+pB
	end
	return x1,y1,x2,y2
end

generic.render = function(self, baseX, baseY, full)
	
	-- for variable parameters use custom objects using metamethods; indexing self with that field would return the value of the variable it refers to
	-- the metamethods would be applied on the parent of the parameter and be defined during object initialization
	
	local oCursor = captureCursor()

	baseX = baseX or 1
	baseY = baseY or 1
	
	local off = 0
	if self.border then
		off = 1
	end

	local p = self.padding or 0
	local pL,pR,pT,pB = (self.paddingLeft or p), (self.paddingRight or p), (self.paddingTop or p), (self.paddingBottom or p)
	
	local x1, y1, x2, y2 = self.x1+baseX-1-pL, self.y1+baseY-1-pT, self.x2+baseX-1+pR, self.y2+baseY-1+pB
	
	if self.type == "circle" then
		-- different rendering
		
	elseif self.border or self.fill or self.text then -- literally all other rendering
	
		
		local mode = "fill"
		if not self.fill then
			mode = "transparent"
		end
		-- no lUtils allowed
		-- center, top, bottom, left, right, corTL, corTR, corBL, corBR
		local p
		local t = " "
		local fg = " "
		local bg = " "
		if self.border and self.border.color then
			fg = utils.toBlit(self.border.color)
		elseif self.fill and self.fill.color and self.fill.color ~= 0 then
			fg = utils.toBlit(self.fill.color)
		end
		if self.fill and self.fill.color and self.fill.color ~= 0 and not (self.window and self.active) then
			bg = utils.toBlit(self.fill.color)
		end
		--print("fg="..fg.."\nbg="..bg)
		--os.sleep(0.5)
		local pc = {" ",bg,bg}
		if self.border then
			local weight = self.border.weight or 1
			local dist = self.border.padding or 2
			local ctbl = {
				[1] = { -- weight
					[0] = { -- distance
						top = {"\143",t,fg},
						bottom = {"\131",fg,t},
						left = {"\149",t,fg},
						right = {"\149",fg,t},
						corTL = {"\159",t,fg},
						corTR = {"\144",fg,t},
						corBL = {"\130",fg,t},
						corBR = {"\129",fg,t},
					},
					[1] = {
						top = {"\140",fg,bg},
						bottom = {"\140",fg,bg},
						left = {"\149",fg,bg},
						right = {"\149",bg,fg},
						corTL = {"\156",fg,bg},
						corTR = {"\147",bg,fg},
						corBL = {"\141",fg,bg},
						corBR = {"\142",fg,bg},
					},
					[2] = {
						top = {"\131",fg,bg},
						bottom = {"\143",bg,fg},
						left = {"\149",fg,bg},
						right = {"\149",bg,fg},
						corTL = {"\151",fg,bg},
						corTR = {"\148",bg,fg},
						corBL = {"\138",bg,fg},
						corBR = {"\133",bg,fg},
					}, --maybe make more efficient in future using the strings "bg" and "fg" so grid doesn't have to regenerate on color change
				}
			}
			p = utils.instantiate(ctbl[weight][dist])
			p.center = pc
			
		else
			p = {center=pc, top=pc, bottom=pc, left=pc, right=pc, corTL=pc, corTR=pc, corBL=pc, corBR=pc}
		end
		local txt
		local lines = {}
		local txtlines = {}
		if self.text and self.text.color and self.text.content then
			txt = self.text.content or self.textContent
			-- if self.fill.image or self.fill.pattern then replace center lines with that etc etc
			
			-- add handling for blit lines
			txtlines = utils.wordwrap(txt, (x2-pR-off)-(x1+pL+off)+1)
		end
		
		
		--_G.debuglines = {}
		local winW,winH
		if self.window then
			winW,winH = self.window.getSize()
		end
		for y=y1,y2 do
			local winLine
			local absY = y-y1+1 - off-pT
			if self.window then
				if absY < 1 then
					winLine = {self.window.getLine(1)}
				elseif absY <= winH then
					winLine = {self.window.getLine(absY)}
				else
					winLine = {self.window.getLine(winH)}
				end
			end
			local txtline = txtlines[y-y1+1-pT-off]
			term.setCursorPos(x1,y)
			local line = {{},{},{}}
			--table.insert(debuglines,line)
			local function addPix(pix,amount)
				amount = amount or 1
				for i=1,amount do
					table.insert(line[1],pix[1])
					table.insert(line[2],pix[2])
					table.insert(line[3],pix[3])
				end
			end
			if not self.border then
				addPix(p.center,x2-x1+1)
			elseif y == y1 then
				addPix(p.corTL)
				addPix(p.top,x2-x1-1)
				addPix(p.corTR)
			elseif y == y2 then
				addPix(p.corBL)
				addPix(p.bottom,x2-x1-1)
				addPix(p.corBR)
			else
				addPix(p.left)
				addPix(p.center,x2-x1-1)
				addPix(p.right)
			end
			local wLine
			if self.window then
				wLine = {
					string.rep(" ",off+pL)..winLine[1]..string.rep(" ",off+pR),
					string.rep(winLine[2]:sub(1,1),off+pL)..winLine[2]..string.rep(winLine[2]:sub(winW,winW),off+pR),
					string.rep(winLine[3]:sub(1,1),off+pL)..winLine[3]..string.rep(winLine[3]:sub(winW,winW),off+pR),
				}
			elseif full then
				local tw,th = term.getSize()
				if y >= 1 and y <= th then
					wLine = {term.current().getLine(y)}
				else
					wLine = {"","",""}
				end
			end
			--_G.mydebugwline = wLine
			if wLine then
				for c=1,#line[1] do
					local p = c+x1-1
					if self.window then
						p = c
					end
					local c1,c2,c3 = wLine[1]:sub(p,p),wLine[2]:sub(p,p),wLine[3]:sub(p,p)
					if c1 == "" then c1 = " " end
					if c2 == "" then c2 = "f" end
					if c3 == "" then c3 = "f" end
					if line[2][c] == " " and line[3][c] == " " then
						line[1][c] = c1
						line[2][c] = c2
						line[3][c] = c3
					elseif line[2][c] == " " then
						line[2][c] = c3
					elseif line[3][c] == " " then
						line[3][c] = c3
					end
				end
			end
			for l=1,3 do
				line[l] = table.concat(line[l])
			end
			if txtline then
				line[1] = line[1]:sub(1,off+pL)..txtline..line[1]:sub(off+pL+#txtline+1)
				--[[for s=off+pL+1,off+pL+#txtline do
					local c = s-(off+pL)
					line[1][s] = txtline:sub(c,c)]]
					
				line[2] = line[2]:sub(1,off+pL)..string.rep(utils.toBlit(self.text.color or self.textColor),#txtline)..line[2]:sub(off+pL+#txtline+1)
			end
			if full then
				term.blit(unpack(line))
			else
				table.insert(lines,line)
			end
		end
		if not full then
			renderCache[self] = lines
		end
		--[[if self.fill and self.fill.image then -- temporary, make it stretch n shit and put it in the line fill
			if self.fill.color then
				term.setBackgroundColor(self.fill.color)
			end
			utils.renderImage(self.fill.image,x1+pL+off,y1+pT+off,nil,(not self.fill.color))
		end]]
		
		
	end
	if self.window and self.window.getCursorBlink() then
		local x,y = self:getAbsolutePosition()
		local col = self.window.getTextColor()
		local cX,cY = self.window.getCursorPos()
		term.setCursorPos(x+cX+off-1,y+cY+off-1)
		term.setCursorBlink(true)
		term.setTextColor(col)
	else
		restoreCursor(oCursor)
	end
	if self.children then
		-- add base coords AND self coords (u become new parent but m aybe u already have parent)
		for k,v in ipairs(self.children) do
			if generic.isVisible(v) then
				generic.render(v,x1+pL+off, y1+pT+off, full) --x1 and y1 are already base plus self stoopid
			end
		end
	end
end

generic.update = function(self, ...)
	if not self.active then
		if not scapeRef[slideRef[self]] then
			error("No scape attached",2)
		end
		self:initialize()
	end
	if self.window then
		local sw,sh = self:getSize()
		local ww,wh = self.window.getSize()
		if sw ~= ww or sh ~= wh then
			self:resize(sw,sh)
		end
	end
	local fEv = "self.mouse"
	if not self:getScape() then
		fEv = "mouse"
	end
	local e = {...}
	local runCor = true
	local runChildren = true
	if e[1]:find(fEv) == 1 then
		--e[3] = e[3]-self.x1+1
		--e[4] = e[4]-self.y1+1
		-- completely wrong, get absolute position
		if e[3] and e[4] then
			local x1,y1,x2,y2 = self:getAbsolutePosition()
			local off = 0
			if self.border then
				off = 1
			end
			e[3] = e[3]-(x1+off)+1
			e[4] = e[4]-(y1+off)+1 -- test
		end
		local cE = table.pack(table.unpack(e))
		cE[1] = cE[1]:gsub("self.","")
		if self.coroutines then
			resumeCoroutines(self,unpack(cE))
		end
		runCor = false
		runChildren = false
	elseif e[1]:find("mouse") == 1 then
		runCor = false
	end
	local oterm = term.current()
	if self.window then
		term.redirect(self.window)
	end
	--[=[if self.eventListeners[e[1]] then
		runListener(self.eventListeners[e[1]],self:getScape())
	end]=]
	local sTbl = {}
	for i=1,#e do
		sTbl[i] = tostring(e[i])
		local l = table.concat(sTbl,".",1,i)
		if self.eventListeners[l] then
			runListener(self.eventListeners[l],self:getScape())
		end
	end
	if self.coroutines and runCor then
		resumeCoroutines(self,unpack(e))
	end
	if not self.destroyed then
		if self.children and runChildren then
			for i,child in ipairs(self.children) do
				child:update(...)
			end
		end
	end
	term.redirect(oterm)
end

local privRef = {}

generic.initialize = function(self) -- provide the scape table to it for variables
	local slide = slideRef[self]
	local scape = scapeRef[slide]
	if not scape then
		error("No scape attached",2)
	end
	-- NOTE: CLASSES MUST NOT BE INITIALIZED, ONLY THEIR INSTANCES
	-- except they should, just using custom class initialize
	-- oh yeah i didnt make classes yet hm
	-- figure out how to handle variables
	-- maybe a table in an object with names of properties with variable values and then this table isn't looked at until initialize is ran and the properties are replaced with custom variable shit stuff
	-- load the scripts into functions
	-- etc
	-- do everything that would make it not serializable
	
	-- add scape log to log errors and shit and warnings
	-- generate env
	if not self.parent or not self.parent.env then
		self.env = {
			shell = scape.env.shell,
			multishell = scape.env.multishell,
			package = scape.env.package,
			require = scape.env.require,
			LevelOS = scape.env.LevelOS,
			shapescape = scape.env.shapescape, --no. add as __index.
			_SCAPE = scape,
			_SLIDE = slide,
		}
	else
		self.env = {}
		for k,v in pairs(self.parent.env) do
			self.env[k] = v
		end
	end
	-- make local sahpesacpe api
	self.env._ENV = self.env
	self.env.self = self
	setmetatable(self.env,{__index=scape.variables,__newindex=scape.variables}) -- scape.variables index is _G
	if self.type == "window" then
		local p = self.padding or 0
		local pL,pR,pT,pB = (self.paddingLeft or p), (self.paddingRight or p), (self.paddingTop or p), (self.paddingBottom or p)
		local off = 0
		if self.border then
			off = 1
		end
		local w,h = (self.x2-off)-(self.x1+off)+1, (self.y2-off)-(self.y1+off)+1
		self.window = window.create(term.current(),self.x1+off,self.y1+off,w,h,false)
		if self.fill and self.fill.color then
			self.window.setBackgroundColor(self.fill.color)
			self.window.clear()
			self.window.setCursorPos(1,1)
		end
		if self.textColor then
			self.window.setTextColor(self.textColor)
		end
	end

	for i,e in pairs(self.eventListeners) do
		if type(e) ~= "table" then
			e = {e}
		end
		local newE = {}
		for k,v in ipairs(e) do
			local asset
			if type(v) == "number" then
				asset = scape:getAssetByID(v)
			elseif type(v) == "string" then
				asset = scape:getAssetByName(v)
			else
				asset = v
			end
			id, name = asset.id, asset.name
			if asset then
				local func,err = load(asset.content,"@"..(asset.name or asset.id),nil,self.env)
				if not func then
					scape:warn(err)
				else
					table.insert(newE,func)
				end
				-- put erorr if not loaded correctly idk
			end
		end
		self.eventListeners[i] = newE
	end
	-- generate coroutines, run once with scape.args
	
	for k,v in pairs(self.pointers) do
		self[k] = nil
	end
	local oldindex = getmetatable(self).__index
	local private = {}
	privRef[self] = private
	for k,v in pairs(self) do
		private[k] = v
		self[k] = nil
	end
	local mt = {
		__index=function(tbl,k)
			if private[k] then
				return private[k]
			elseif self.pointers[k] then
				return runPointer(k,scape,self)
			elseif k == "width" then
				return self.x2-self.x1+1
			elseif k == "height" then
				return self.y2-self.y1+1
			elseif k == "x" then
				return self.x1
			elseif k == "y" then
				return self.y1
			else
				return oldindex[k]
			end
		end,
		__newindex=function(tbl,k,v)
			if tbl[k] ~= v then
				if k == "width" then
					self:resize(v,self.height)
				elseif k == "height" then
					self:resize(self.width,v)
				elseif k == "x" then
					self:move(v,self.y1)
				elseif k == "y" then
					self:move(self.x1,v)
				elseif k == "x1" then
					self:reposition(v)
				elseif k == "y1" then
					self:reposition(self.x1,v)
				elseif k == "x2" then
					self:reposition(self.x1,self.y1,v,self.y2)
				elseif k == "y2" then
					self:reposition(self.x1,self.y1,self.x2,v)
				else
					private[k] = v
					self:markAsChanged()
				end
			end
		end
	}
	if self.type == "group" then
		mt.__pairs = utils.genStatelessIterator(private, group, generic)
	else
		mt.__pairs = utils.genStatelessIterator(private, generic)
	end
	setmetatable(self, mt)
	self.active = true

	if self.children then
		for k,v in ipairs(self.children) do
			if v.name then
				if not self[v.name] then
					self[v.name] = v
				end
				if not self.env[v.name] then
					self.env[v.name] = v
				end
			end
			v:initialize()
		end
	end

	if self.coroutines then
		local args = scape.args or {}
		for k=#self.coroutines,1,-1 do
			local v = self.coroutines[k]
			local asset = scape.assets[v]
			if asset then
				local func,err = load(asset.content,"@"..(asset.name or asset.id),nil,self.env)
				if not func then
					scape:warn(err)
					table.remove(self.coroutines,k)
				else
					self.coroutines[k] = coroutine.create(func)
				end
			end
		end
		resumeCoroutines(self,unpack(args))
	end

	if self.eventListeners["initialize"] then
		runListener(self.eventListeners["initialize"],scape)
	end

	return true
end

generic.reposition = function(self,x1,y1,x2,y2)
	-- take care of aligning n shit idk
	x1,y1,x2,y2 = x1 or self.x1, y1 or self.y1, x2 or self.x2, y2 or self.y2
	if self.active then
		if not self.pointers.x1 then
			privRef[self].x1 = x1
		end
		if not self.pointers.y1 then
			privRef[self].y1 = y1
		end
		if not self.pointers.x2 then
			privRef[self].x2 = x2
		end
		if not self.pointers.y2 then
			privRef[self].y2 = y2
		end
		--self:markAsChanged()
		renderCache[self:getSlide()] = nil
	else
		self.x1,self.y1,self.x2,self.y2 = x1,y1,x2,y2
	end

	if self.window then-- position dont matter shit, just size (window is invisible) thats wrong motherfucker it absolutely does
		local p = self.padding or 0
		local pL,pR,pT,pB = (self.paddingLeft or p), (self.paddingRight or p), (self.paddingTop or p), (self.paddingBottom or p)
		local off = 0
		if self.border then
			off = 1
		end
		local w,h = (self.x2-off)-(self.x1+off)+1, (self.y2-off)-(self.y1+off)+1
		local x,y = self:getAbsolutePosition()
		self.window.reposition(x+off,y+off,w,h)
	end
end

generic.move = function(self,x,y)
	x = x or self.x1
	y = y or self.y1
	local offX,offY = x-self.x1,y-self.y1
	self:reposition(x,y,self.x2+offX,self.y2+offY)
end

generic.resize = function(self,width,height)
	self:reposition(self.x1,self.y1,((width and (self.x1+width-1)) or self.x2),((height and (self.y1+height-1)) or self.y2))
end

generic.duplicate = function(self,properties)
	if self.active then
		error("Cannot duplicate active objects",2)
	end
	return self:getSlide():addObject(utils.instantiate(self))
end

generic.destroy = function(self,full)
	if full == nil then
		full = true
	end
	if self.parent then
		for k,v in pairs(self.parent.children) do
			if v == self then
				table.remove(self.parent.children,k)
				break
			end
		end
		for k,v in pairs(self.parent) do
			if v == self then
				self.parent[k] = nil
			end
		end
		local sl = self:getSlide()
	elseif not self.isClass then
		local sl = self:getSlide()
		for k,v in pairs(sl.objects) do
			if v == self then
				table.remove(sl.objects,k)
			end
		end
		for id,obj in ipairs(sl.objects) do
			obj.id = id -- so ID is not static hm
			-- then again it doesn't really need to be because string IDs *are* static
		end
	end
	if full then
		for k,v in pairs(self) do
			self[k] = nil
		end
		setmetatable(self,{__index=deleted,__newindex=deleted})
	end
	if slideRef[self] then
		renderCache[slideRef[self]] = nil
		slideRef[self] = nil
	end
end

generic.markAsChanged = function(self)
	local slide = self:getSlide()
	if not slide then
		return false
	else
		if not changeCache[slide] then
			changeCache[slide] = {}
		end
		if changeCache[self] then
			for k,v in pairs(changeCache[self]) do
				if k ~= "old" and self[k] ~= v then
					changeCache[slide][self] = 2
					break
				end
			end
		end
		local x1,y1,x2,y2 = self:getAbsolutePosition(true)
		changeCache[self] = {x1=x1,y1=y1,x2=x2,y2=y2,old=changeCache[self]}
		changeCache[slide][self] = changeCache[slide][self] or 1
		if self.children then
			for k,v in pairs(self.children) do
				v:markAsChanged()
			end
		end
	end
end

generic.getSize = function(self)
	return self.x2-self.x1+1,self.y2-self.y1+1
end

generic.getPosition = function(self)
	return self.x1,self.y1
end

generic.getBackgroundColor = function(self)
	if not self.fill then
		return 0
	else
		return self.fill.color or 0
	end
end

generic.getBorderColor = function(self)
	if not self.border then
		return 0
	else
		return self.border.color or 0
	end
end

generic.getTextColor = function(self)
	if not self.text then
		return 0
	else
		return self.text.color or 0
	end
end

generic.getText = function(self)
	if not self.text then
		return nil
	else
		return self.text.content
	end
end

generic.setBackgroundColor = function(self,color)
	if color == nil or color == 0 then
		self.fill = nil
	else
		if not self.fill then self.fill = {} end
		self.fill.color = color
	end
	self:markAsChanged()
end

generic.setTextColor = function(self,color)
	if not self.text then self.text = {content=""} end
	self.text.color = color
	self:markAsChanged()
end

generic.setText = function(self,content,color)
	if not self.text then self.text = {} end
	self.text.color = color or self.text.color or self.txtcolor or self.textColor or colors.black
	self.text.content = content
	self:markAsChanged()
end

generic.setBorderColor = function(self,color)
	if color == nil or color == 0 then
		self.border = nil
	else
		if not self.border then self.border = {weight=1,padding=2} end
		self.border.color = color
	end
	self:markAsChanged()
end

generic.setPointer = function(self, key, value)
	if not self.pointers then self.pointers = {} end
	if self.active then
		privRef[self][key] = nil
	end
	self.pointers[key] = value
end

generic.removePointer = function(self, key)
	if self.active then
		self[key] = self[key]
	end
	self.pointers[key] = nil
end

generic.addListener = function(self, sEvent, sAsset)
	local scape = scapeRef[self]
	if not self.eventListeners then
		self.eventListeners = {}
	end
	if sEvent == "coroutine" then
		if not self.coroutines then
			self.coroutines = {}
		end
	elseif not self.eventListeners[sEvent] then
		self.eventListeners[sEvent] = {}
	end
	if self.active and (type(sAsset) == "string" or type(sAsset) == "number") and scape then
		local asset
		if type(sAsset) == "string" then
			asset = scape:getAssetByName(sAsset)
		else
			asset = scape:getAssetByID(sAsset)
		end
		if asset then
			local func,err = load(asset.content,"@"..(asset.name or asset.id),nil,self.env)
			if not func then
				scape:warn(err)
			elseif sEvent == "coroutine" then
				local args = scape.args or {}
				local k = #self.coroutines+1
				self.coroutines[k] = coroutine.create(func)
				local oterm = term.current()
				if self.window then
					term.redirect(self.window)
				end
				local ok,filter = coroutine.resume(self.coroutines[k],unpack(args))
				if not ok then
					scape:warn(filter)
					table.remove(self.coroutines,k)
				else
					corFilterCache[self.coroutines[k]] = filter
				end
				term.redirect(oterm)
			else
				table.insert(self.eventListeners[sEvent],func)
			end
		end
	elseif self.active and sEvent == "coroutine" then
		local func = sAsset
		local args = scape.args or {}
		local k = #self.coroutines+1
		self.coroutines[k] = coroutine.create(func)
		local oterm = term.current()
		if self.window then
			term.redirect(self.window)
		end
		local ok,filter = coroutine.resume(self.coroutines[k],unpack(args))
		if not ok then
			scape:warn(filter)
			table.remove(self.coroutines,k)
		else
			corFilterCache[self.coroutines[k]] = filter
		end
		term.redirect(oterm)
	elseif sEvent == "coroutine" then
		table.insert(self.coroutines,sAsset)
	else
		table.insert(self.eventListeners[sEvent],sAsset)
	end
end

generic.getSlide = function(self)
	return slideRef[self]
end

generic.getScape = function(self)
	return scapeRef[self]
end

generic.isInside = function(self,x,y)
	local x1,y1,x2,y2 = self:getAbsolutePosition(true)

	if x >= x1 and y >= y1 and x <= x2 and y <= y2 then
		return true
	end
end

generic.arrange = function(self,newPositionID)
	local slide = self:getSlide()
	if not slide then
		error("No slide attached to object",2)
	end
	local parent = slide.objects
	if self.parent then
		parent = self.parent.children
	end
	if newPositionID < 0 then
		newPositionID = #parent+newPositionID+2
	end
	newPositionID = math.min(#parent+1,newPositionID)
	table.remove(parent,self.id)
	table.insert(parent,newPositionID,self)
	for id,iObj in ipairs(parent) do
		iObj.id = id
	end
end

generic.moveToFront = function(self)
	self:arrange(-1)
end

generic.moveToBack = function(self)
	self:arrange(1)
end

generic.moveForward = function(self)
	self:arrange(self.id+1)
end

generic.moveBackward = function(self)
	self:arrange(math.max(1,self.id-1))
end

-- [[ GROUP API ]]
shapescape.group = {}
local group = shapescape.group
setmetatable(group, {__index=generic})

group.resetSize = function(self)
	local off = 0
	if self.border then
		off = 1
	end
	local baseX,baseY = self.x1+off,self.y1+off
	self.x1 = self.children[1].x1+baseX-1-off
	self.y1 = self.children[1].y1+baseY-1-off
	self.x2 = self.children[1].x2+baseX-1+off
	self.y2 = self.children[1].y2+baseY-1+off
	for i=2,#self.children do
		local o = self.children[i]
		self.x1 = math.min(self.x1,o.x1+baseX-1-off)
		self.y1 = math.min(self.y1,o.y1+baseY-1-off)
		self.x2 = math.max(self.x2,o.x2+baseX-1+off)
		self.y2 = math.max(self.y2,o.y2+baseY-1+off)
	end
	local nBaseX,nBaseY = self.x1+off,self.y1+off
	local offX,offY = nBaseX-baseX,nBaseY-baseY
	for i=1,#self.children do
		self.children[i]:move(self.children[i].x1-offX,self.children[i].y1-offY)
	end
end

group.addObject = function(self,obj)
	local off = 0
	if self.border then
		off = 1
	end
	local xOff,yOff,_,_ = self:getAbsolutePosition()
	xOff = xOff+off-1
	yOff = yOff+off-1
	obj.x1,obj.y1,obj.x2,obj.y2 = obj.x1-xOff,obj.y1-yOff,obj.x2-xOff,obj.y2-yOff
	obj.parent = self
	shapescape.loadObject(obj)
	scapeRef[obj] = scapeRef[self]
	slideRef[obj] = slideRef[self]
	if obj.children then
		fixChildren(obj)
	end
	table.insert(self.children,obj)
	obj.id = #self.children
	self:resetSize()
	if self.active then
		obj:initialize()
	end
	self:resetSize()
	local sl = self:getSlide()
	if sl then
		renderCache[sl] = nil
	end
end

local invisibleObjects = {}
generic.setVisible = function(self,visibility)
	if not visibility then
		invisibleObjects[self] = true
	else
		invisibleObjects[self] = false
	end
end

generic.isVisible = function(self)
	return not invisibleObjects[self]
end

-- [[ SLIDE API ]]
local slide = shapescape.slide

slide.initialize = function(self)
	self:setVisible(true)
	local scape = scapeRef[self]
	self.window = window.create(term.current(), 1, 1, self.width, self.height, self:isVisible())
	self:render(true)
	for i=1,#self.objects do
		local obj = self.objects[i]
		obj:initialize(scape)
		if obj.name and not scape.variables[obj.name] then
			scape.variables[obj.name] = obj
		end
	end
	self.active = true
end

slide.getScape = function(self)
	return scapeRef[self]
end

slide.getSize = function(self)
	return self.width,self.height
end

slide.resize = function(self, width, height)
	self.width, self.height = width, height
	if self.window then
		local x,y = self.window.getPosition()
		self.window.reposition(x,y,width,height)
	end
end

slide.loadObject = function(self,obj)
	shapescape.loadObject(obj)
	scapeRef[obj] = scapeRef[self]
	slideRef[obj] = self
	if obj.children then
		fixChildren(obj)
	end
	renderCache[self] = nil
	return obj
end

slide.addObject = function(self,obj)
	obj.id = #self.objects+1
	table.insert(self.objects,obj)
	return self:loadObject(obj)
end

slide.createObject = function(self,oType,x1,y1,x2,y2,properties)
	return self:addObject(shapescape.createObject(oType,x1,y1,x2,y2,properties))
end

slide.createRectangle = function(self,x1,y1,x2,y2,fill,border,properties)
	return self:addObject(shapescape.createRectangle(x1,y1,x2,y2,fill,border,properties))
end

slide.createWindow = function(self,x1,y1,x2,y2,fill,textColor,border,properties)
	return self:addObject(shapescape.createWindow(x1,y1,x2,y2,fill,textColor,border,properties))
end

slide.createGroup = function(self,objects,properties)
	return self:addObject(shapescape.createGroup(objects,properties))
end

slide.isVisible = function(self)
	return self.visible
end

slide.setVisible = function(self,visibility)
	self.visible = not not visibility
	if self.window then
		self.window.setVisible(self.visible)
	end
end

slide.getBackgroundColor = function(self)
	if not self.background then
		return 0
	else
		return self.background.color or 0
	end
end

slide.setBackgroundColor = function(self,color)
	if not self.background then self.background = {} end
	self.background.color = color
end

slide.genCache = function(self,objs,doDebug)
	if not objs then
		renderCache[self] = {}
		objs = self.objects
	end
	local c = renderCache[self]
	for i=1,#objs do
		local o = objs[i]
		if o:isVisible() then
			local x1,y1,x2,y2 = o:getAbsolutePosition(true)
			for x=x1,x2 do
				if not c[x] then
					c[x] = {}
				end
				local cx = c[x]
				for y=y1,y2 do
					if not cx[y] then
						cx[y] = {o}
					else
						table.insert(cx[y],1,o)
					end
				end
			end
			if doDebug then
				o:render(1,1,true)
				os.sleep(1)
				term.clear()
				os.sleep(1)
			end
			if o.children then
				self:genCache(o.children, doDebug)
			end
		end
	end
end

slide.render = function(self,full)
	local oterm = term.current()
	if self.window then
		term.redirect(self.window)
	end
	local function get(pix,x,y)
		local fgn = 1
		local o = pix[fgn]
		local ox,oy = o:getAbsolutePosition(true)
		local fgp = renderCache[o] and renderCache[o][y-oy+1] and renderCache[o][y-oy+1][2]:sub(x-ox+1,x-ox+1) or " "
		while fgp == " " do
			fgn = fgn+1
			if fgn > #pix then
				fgp = utils.toBlit(term.getBackgroundColor())
				break
			end
			local o = pix[fgn]
			ox,oy = o:getAbsolutePosition(true)
			fgp = renderCache[o] and renderCache[o][y-oy+1] and renderCache[o][y-oy+1][2]:sub(x-ox+1,x-ox+1) or " "
		end
		local bgn = 1
		local o = pix[bgn]
		local ox,oy = o:getAbsolutePosition(true)
		local bgp = renderCache[o] and renderCache[o][y-oy+1] and renderCache[o][y-oy+1][3]:sub(x-ox+1,x-ox+1) or " "
		while bgp == " " do
			bgn = bgn+1
			if bgn > #pix then
				bgp = utils.toBlit(term.getTextColor())
				break
			end
			local o = pix[bgn]
			ox,oy = o:getAbsolutePosition(true)
			bgp = renderCache[o] and renderCache[o][y-oy+1] and renderCache[o][y-oy+1][3]:sub(x-ox+1,x-ox+1) or " "
		end
		local txtn = math.min(fgn,bgn)
		if txtn > #pix then
			txtp = " "
		else
			local o = pix[txtn]
			local ox,oy = o:getAbsolutePosition(true)
			txtp = renderCache[pix[txtn]] and renderCache[pix[txtn]][y-oy+1][1]:sub(x-ox+1,x-ox+1) or " "
		end
		if #txtp ~= #fgp or #txtp ~= #bgp or #fgp ~= #bgp then
			_G.x,_G.y,_G.txtp,_G.fgp,_G.bgp,_G.pix = x,y,txtp,fgp,bgp,pix
			error("wtf")
		end
		--table.insert(debuglogshit,{txtp=txtp,fgp=fgp,bgp=bgp,pix=pix,x=x,y=y})
		return txtp,fgp,bgp
	end
	if self.background then
		if self.background.color then
			term.setBackgroundColor(self.background.color)
		elseif self.background.image then
			-- idk
		end
	end
	local bg = utils.toBlit(term.getBackgroundColor())
	if full or not renderCache[self] then
		term.clear()
		for i,o in ipairs(self.objects) do
			if not renderCache[o] then
				o:render()
			end
		end
		if not renderCache[self] then
			self:genCache()
		end
		
		local w,h = self:getSize()
		local c = renderCache[self]

		_G.debugLines = {}
		for y=1,h do
			term.setCursorPos(1,y)
			local line = {{},{},{}}
			for x=1,w do
				if c[x] and c[x][y] then
					local cxy = c[x][y]
					l1,l2,l3 = get(cxy,x,y)
					_G.debugPix = {l1,l2,l3}
					table.insert(line[1],l1)
					table.insert(line[2],l2)
					table.insert(line[3],l3)
					--table.insert(debuglogshit,{l1,l2,l3})
				else
					table.insert(line[1]," ")
					table.insert(line[2],bg)
					table.insert(line[3],bg)
					--table.insert(debuglogshit,{" ",bg,bg})
				end
			end
			-- THIS LINE INTERRUPTS YOU MOTHERFUCKER WORK PLEASE
			_G.moredebugshit = {line[1],line[2],line[3]}
			table.insert(debugLines,{table.concat(line[1]),table.concat(line[2]),table.concat(line[3])})
			term.blit(table.concat(line[1]),table.concat(line[2]),table.concat(line[3]))
		end
	elseif changeCache[self] then
		--[[for k,v in pairs(changeCache[self]) do
			if v == 2 then
				renderCache[self] = nil
				self:genCache()
				self:render(true)
				break
			end
		end]]
		if self.debugMode and not self.i then
			self.i = 0
		end
		local c = renderCache[self]
		_G.debugRenderList = {}
		if not changeCache.previous then
			changeCache.previous = {}
		end
		for o,t in pairs(changeCache[self]) do
			if not o.destroyed then
				o:render()
				table.insert(debugRenderList,o)
				local x1,y1,x2,y2 = o:getAbsolutePosition(true)
				local cur = {x1=x1,y1=y1,x2=x2,y2=y2}
				local changePos = false
				if changeCache.previous[o] then
					local p = changeCache.previous[o]
					for k,v in pairs(p) do
						if v ~= cur[k] then
							-- render previous position
							changePos = true
							for y=p.y1,p.y2 do
								local line = {{},{},{}}
								for x=p.x1,p.x2 do
									if c[x] and c[x][y] then
										local cxy = c[x][y]
										table.remove(cxy,utils.locateEntry(cxy,o))
										if #cxy == 0 then
											c[x][y] = nil
										end
									end
									if c[x] and c[x][y] then
										if self.debugMode then
											term.setCursorPos(x,y)
											term.setBackgroundColor(2^self.i)
											term.write(" ")
										else
											local cxy = c[x][y]
											l1,l2,l3 = get(cxy,x,y)
											_G.debugPix = {l1,l2,l3}
											table.insert(line[1],l1)
											table.insert(line[2],l2)
											table.insert(line[3],l3)
										end
									else
										if self.debugMode then
											term.setCursorPos(x,y)
											term.setBackgroundColor(2^self.i)
											term.setTextColor(2^((self.i+1)%16))
											term.write("0")
										else
											table.insert(line[1]," ")
											table.insert(line[2],bg)
											table.insert(line[3],bg)
										end
									end
								end
								if not self.debugMode then
									term.setCursorPos(p.x1,y)
									term.blit(table.concat(line[1]),table.concat(line[2]),table.concat(line[3]))
								end
							end
							break
						end
					end
				end
				changeCache.previous[o] = cur
				for y=y1,y2 do
					local line = {{},{},{}}
					for x=x1,x2 do
						if changePos then
							if not c[x] then
								c[x] = {}
							end
							if not c[x][y] then
								c[x][y] = {}
							end
							local cxy = c[x][y]
							table.insert(cxy,o)
							-- compare equal parent levels but FUCK how do I do that
							-- OH I KNOW
							-- if parent and parent does NOT equal go up a level
							-- if not parent or parent equals then bigger ID wins
							-- wait fuck im dumb, what if b IS the parent
							local function isOnTop(a, b)
								if a.parent == b.parent then
									return a.id > b.id
								elseif a.parent == b then
									return true
								elseif a == b.parent then
									return false
								else
									if a.parent then
										if b.parent then
											local r = isOnTop(a.parent, b.parent)
											if r ~= nil then
												return r
											end
										end
										local r = isOnTop(a.parent, b)
										if r ~= nil then
											return r
										end
									end
									if b.parent then
										local r = isOnTop(a, b.parent)
										if r ~= nil then
											return r
										end
									end
								end
							end
							table.sort(cxy,function(a,b) return isOnTop(a,b) end) -- bruh
						end
						if c[x] and c[x][y] then
							if self.debugMode then
								term.setCursorPos(x,y)
								term.setBackgroundColor(2^self.i)
								term.write(" ")
							else
								local cxy = c[x][y]
								l1,l2,l3 = get(cxy,x,y)
								_G.debugPix = {l1,l2,l3,cxy=cxy}
								table.insert(line[1],l1)
								table.insert(line[2],l2)
								table.insert(line[3],l3)
							end
						else
							if self.debugMode then
								term.setCursorPos(x,y)
								term.setBackgroundColor(2^self.i)
								term.setTextColor(2^((self.i+1)%16))
								term.write("0")
							else
								table.insert(line[1]," ")
								table.insert(line[2],bg)
								table.insert(line[3],bg)
							end
						end
					end
					if not self.debugMode then
						term.setCursorPos(x1,y)
						term.blit(table.concat(line[1]),table.concat(line[2]),table.concat(line[3]))
					end
				end
			end
		end
		if self.debugMode and #debugRenderList > 0 then
			self.i = (self.i+1)%16
		end
		changeCache[self] = {}
	end
	term.redirect(oterm)
end

slide.destroy = function(self)
	local scape = self:getScape()
	for k,v in pairs(scape.slides) do
		if v == self then
			table.remove(scape.slides,k)
		end
	end
	for k,v in ipairs(scape.slides) do
		v.id = k
	end
	for k,v in pairs(self) do
		self[k] = nil
	end
	setmetatable(self,{__index=deleted,__newindex=deleted})
end


-- [[ SCAPE API ]]
local scape = shapescape.scape

scape.initialize = function(self,env,args)
	table.insert(shapescape.debug.scapes,self)
	self.env = env or _ENV
	self.env.shapescape = {
		getEvent = function()
			return unpack(self.event)
		end,
		getSlide = function()
			return self.slides[self.currentSlide]
		end,
		setSlide = function(slideID)
			-- if string search actually not necessary
			if self.slides[slideID] then
				self.currentSlide = self.slides[slideID].id
				os.pullEvent()
			end
		end,
		getSlides = function()
			return self.slides
		end,
		getScape = function()
			return self
		end,
		exit = function(...)
			self.returnValues = table.pack(...)
			self.status = "dead"
		end,
	}
	for k,v in pairs(shapescape) do
		self.env.shapescape[k] = v
	end
	if not self.variables then
		self.variables = {}
	end
	setmetatable(self.variables,{__index=_G})
	self.status = "running"
	self.log = {}
	self.args = args or {}
	self.currentSlide = 1
	self.active = true
	--_G.debugSelf = self
	for s=1,#self.slides do
		-- dont initialize slides until update
		local sl = self.slides[s]
		if sl.name and not self.slides[sl.name] then
			self.slides[sl.name] = sl
		end
	end
	for c=1,#self.classes do
		self.classes[c]:initialize()
	end
end

scape.loadSlide = function(self,tSlide)
	local w,h = term.getSize()
	width = tSlide.width or w
	height = tSlide.height or h
	setmetatable(tSlide,{__index=slide})
	scapeRef[tSlide] = self
	for o=1,#tSlide.objects do
		local obj = tSlide.objects[o]
		tSlide:loadObject(obj)
	end
	return tSlide
end

scape.newSlide = function(self,width,height,backgroundColor)
	local w,h = term.getSize()
	width = width or w
	height = height or h
	local sl = {width=width,height=height,visible=true,objects={},id=#self.slides+1}
	if backgroundColor then
		sl.background = {color=backgroundColor}
	end
	--sl.window = window.create(term.current(),1,1,width,height,false)
	table.insert(self.slides,sl)
	return self:loadSlide(sl)
end

scape.removeSlide = function(self, slide)
	if type(slide) ~= "table" then
		for k,v in pairs(self.slides) do
			if k == slide then
				slide = v
				break
			end
		end
		if type(slide) ~= "table" then
			return false
		end
	end
	for k,v in pairs(self.slides) do
		if v == slide then
			table.remove(self.slides,k)
		end
	end
	return true
end

scape.setSlide = function(self,nSlide)
	if type(nSlide) == "table" and nSlide.id then
		self.currentSlide = nSlide.id
	elseif type(nSlide) == "number" then
		self.currentSlide = nSlide
	else
		error("bad argument #2 to 'scape.setSlide' (expected slide, got "..type(nSlide)..")",2)
	end
end

scape.update = function(self, ...)
	-- i dont feel like this anymore
	-- maybe instead of just mouse_click, make it self.mouse_click or <name>.mouse_click
	-- and then mouse_click will execute on every mouse click, no matter where was clicked
	local e = table.pack(...)
	self.event = e
	local s = self.slides[self.currentSlide] -- idiot
	if not s.active then
		s:initialize()
	end
	for o=#s.objects,1,-1 do
		if not s.objects[o].active then
			s.objects[o]:initialize()
		end
		s.objects[o]:update(...)
	end
	local secEvent
	-- NOTE: transparent objects with children let mouse clicks through when click doesn't collide with any child
	local function checkCollisions(objs,prefix)
		local clickedObj
		for o=#objs,1,-1 do
			if objs[o]:isVisible() and objs[o]:isInside(e[3],e[4]) then
				if objs[o].children then
					local pre
					if objs[o].name and prefix then
						pre = prefix..objs[o].name.."."
					end
					clickedObj = checkCollisions(objs[o].children,pre)
				end
				if not (objs[o].children and objs[o]:getBackgroundColor() == 0 and not clickedObj) then -- only passes through if a child wasn't clicked
					local newEvent = utils.instantiate(e)
					newEvent[1] = "self."..e[1]
					objs[o]:update(unpack(newEvent)) -- will NOT update parent, meaning parent should NEVER pass self.mouse events to children
					if not clickedObj then
						clickedObj = objs[o]
						if objs[o].name and prefix then
							secEvent = utils.instantiate(e)
							secEvent[1] = (prefix or "")..objs[o].name.."."..e[1]
						end
					end
					return clickedObj
				end
			end
		end
	end

	if e[1]:find("mouse") == 1 and e[3] and e[4] then
		checkCollisions(s.objects,"")
	end
	if secEvent then
		for o=1,#s.objects do
			s.objects[o]:update(unpack(secEvent))
		end
	end
end

scape.render = function(self)
	term.setCursorBlink(false)
	self.slides[self.currentSlide]:render()
	if self.log then
		local cursor = captureCursor()
		local warns = {}
		for l=#self.log,1,-1 do
			local entry = self.log[l]
			if os.epoch("utc") <= entry.time+5000 then
				table.insert(warns,entry)
			else
				break
			end
		end
		local warnCols = {
			["WARNING"] = colors.orange,
			["ERROR"] = colors.red,
			["MSG"] = colors.lime,
		}
		local y = 2
		local w,h = term.getSize()
		for i,warn in ipairs(warns) do
			term.setCursorPos(2,y)
			local prefix = "["..warn.type.."] "
			local lines = utils.wordwrap(prefix..tostring(warn.text),w-4)
			width = 0
			for l=1,#lines do
				width = math.max(width,#lines[l]+2)
			end
			term.setBackgroundColor(colors.gray)
			term.write(string.rep(" ",width))
			term.setCursorPos(2,y)
			term.setTextColor(warnCols[warn.type])
			term.write("\149")
			term.setTextColor(colors.white)
			term.write(prefix)
			term.setTextColor(warnCols[warn.type])
			term.write(lines[1]:sub(#prefix+1).." ")
			y = y+1
			for l=2,#lines do
				term.setCursorPos(2,y)
				term.write("\149"..lines[l]..string.rep(" ",width-#lines[l]-3))
				y = y+1
			end
			y = y+1
		end
		restoreCursor(cursor)
	end
end

scape.run = function(self,...)
	local w,h = term.getSize()
	for s=1,#self.slides do
		self.slides[s]:resize(w,h)
	end
	if not self.active then
		self:initialize(_ENV, table.pack(...))
	end
	self:render()
	while self.status ~= "dead" do
		local e = table.pack(os.pullEvent())
		if e[1] == "term_resize" then
			local w,h = term.getSize()
			for s=1,#self.slides do
				self.slides[s]:resize(w,h)
			end
		end
		self:update(table.unpack(e,1,e.n))
		self:render()
	end
	return unpack(self.returnValues or {})
end

scape.createSlide = function(self,objects,width,height)
	sl = self:newSlide(width,height)
	for o=1,#objects do
		local obj = objects[o]
		sl:createObject(obj.type,obj.x1,obj.y1,obj.x2,obj.y2,obj)
	end
end

scape.addScript = function(self, sCode, sName)
	self.assets[self.lastAssetID+1] = {content=sCode,name=sName,id=self.lastAssetID+1}
	self.lastAssetID = self.lastAssetID+1
end

scape.getAssetByName = function(self, sName)
	for k,v in pairs(self.assets) do
		if v.name == sName then
			return v
		end
	end
end

scape.getAssetByID = function(self, nID)
	return self.assets[nID]
end

scape.getAPI = function(self)
	return shapescape
end

scape.message = function(self,message,type)
	type = type or "MSG"
	local types = {["MSG"]=true,["WARNING"]=true,["ERROR"]=true}
	if not types[type] then
		error("Invalid type '"..type.."'",2)
	end
	for e=#self.log,1,-1 do
		if os.epoch("utc") > self.log[e].time+5000 then
			break
		elseif self.log[e].text == message and self.log[e].type == type then
			table.remove(self.log,e)
		end
	end
	table.insert(self.log,{time=os.epoch("local"),text=message,type=type})
end

scape.warn = function(self,warning)
	self:message(warning,"WARNING")
end

-- [[ GLOBAL API ]]
shapescape.loadScape = function(tScape)
	local sc
	if type(tScape) == "table" then
		sc = tScape
	elseif type(tScape) == "string" and fs.exists(tScape) then
		local content = utils.fread(tScape)
		sc = textutils.unserialize(content)
	end
	setmetatable(sc,{__index=scape})
	for s=1,#sc.slides do
		sc:loadSlide(sc.slides[s])
	end
	local function classChildren(obj)
		for i,o in ipairs(obj.children) do
			scapeRef[o] = scapeRef[obj]
			if o.children then
				classChildren(o)
			end
		end
	end
	if not sc.classes then
		if sc.templates then
			sc.classes = sc.templates
			sc.templates = nil
		else
			sc.classes = {}
		end
	end
	for c=1,#sc.classes do
		scapeRef[sc.classes[c]] = sc
		if sc.classes[c].children then
			classChildren(sc.classes[c])
		end
		shapescape.class.load(sc.classes[c])
	end
	return sc
end

shapescape.createScape = function(slides,assets,classes)
	local sc = {slides=slides or {},assets=assets or {},classes=classes or {},variables={}} -- maybe width/height or something idk
	-- ooh metatables
	sc.lastAssetID = 0
	for k,v in pairs(sc.assets) do
		sc.lastAssetID = math.max(sc.lastAssetID,v.id+1)
	end
	return shapescape.loadScape(sc)
end

shapescape.loadObject = function(obj)
	if type(obj.fill) == "number" then
		if obj.fill == 0 then
			obj.fill = nil
		else
			obj.fill = {color=obj.fill}
		end
	end
	if type(obj.border) == "number" then
		if obj.border == 0 then
			obj.border = nil
		else
			obj.border = {color=obj.border,weight=1,padding=2}
		end
	end
	if type(obj.text) == "number" then
		if obj.text == 0 then
			obj.text = nil
		else
			obj.text = {color=obj.text,content=""}
		end
	elseif type(obj.text) == "string" then
		obj.text = {color=obj.txtcolor or obj.textColor or colors.black,content=obj.text}
	end
	if not obj.eventListeners then
		obj.eventListeners = {}
	end
	if not obj.pointers then
		obj.pointers = {}
	end
	if obj.type == "group" then
		setmetatable(obj,{__index=group})
	else
		setmetatable(obj,{__index=generic})
	end
	if obj.children then
		for i,child in ipairs(obj.children) do
			shapescape.loadObject(child)
			child.parent = obj
			child.id = i
		end
	end
	local x1,y1,x2,y2 = obj:getAbsolutePosition()
	changeCache[obj] = {x1=x1,y1=y1,x2=x2,y2=y2}
	return obj
end

shapescape.createObject = function(oType,x1,y1,x2,y2,properties)
	properties = properties or {}
	local obj = {x1=x1,y1=y1,x2=x2,y2=y2,type=oType}
	for k,v in pairs(properties) do
		obj[k] = v
	end
	return shapescape.loadObject(obj)
end

shapescape.createRectangle = function(x1,y1,x2,y2,fill,border,properties)
	properties = properties or {}
	properties.fill = fill
	properties.border = border
	return shapescape.createObject("rect",x1,y1,x2,y2,properties)
end

shapescape.createWindow = function(x1,y1,x2,y2,fill,textColor,border,properties)
	properties = properties or {}
	properties.fill = fill
	properties.border = border
	properties.textColor = textColor
	return shapescape.createObject("window",x1,y1,x2,y2,properties)
end

shapescape.createGroup = function(objects,properties)
	properties = properties or {}
	properties.children = objects
	if not objects or not objects[1] then return end
	local x1,y1,x2,y2 = objects[1].x1,objects[1].y1,objects[1].x2,objects[1].y2
	for i=2,#objects do
		--print(x1,y1,x2,y2)
		local o = objects[i]
		x1 = math.min(x1,o.x1)
		y1 = math.min(y1,o.y1)
		x2 = math.max(x2,o.x2)
		y2 = math.max(y2,o.y2)
		--print("after object: "..o.x1..","..o.y1..","..o.x2..","..o.y2..":",x1,y1,x2,y2)
		--os.sleep(0.5)
	end
	--os.sleep(2)
	local obj = shapescape.createObject("group",x1,y1,x2,y2,properties)
	setmetatable(obj,{__index=group})
	for i,o in ipairs(objects) do
		o.x1,o.y1,o.x2,o.y2 = o.x1-x1+1,o.y1-y1+1,o.x2-x1+1,o.y2-y1+1
		o.parent = obj
		o.id = i
	end
	return obj
end

--return {utils=utils,generic=generic,scape=scape,createObject=createObject,createRectangle=createRectangle,createGroup=createGroup}
return shapescape