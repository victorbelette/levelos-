local input = {}

local shapescape
local utils

input.init = function(api)
	shapescape = api
	utils = api.utils
end

local function isInside(x,y,object)
	local function n(var)
		return type(var) == "number"
	end
	local x1,y1,x2,y2
	if n(object.x1) and n(object.y1) and n(object.x2) and n(object.y2) then
		x1,y1,x2,y2 = object.x1,object.y1,object.x2,object.y2
	elseif n(object.x) and n(object.y) then
		x1,y1 = object.x,object.y
		if n(object.w) and n(object.h) then
			x2,y2 = x1+(object.w-1),y1+(object.h-1)
		else
			x2,y2 = x1,y1
		end
	else
		error("Invalid input: "..textutils.serialize(object,{compact=true}),2)
	end
	if x2 < x1 then
		x1,x2 = x2,x1
	end
	if y2 < y1 then
		y1,y2 = y2,y1
	end
	if x >= x1 and y >= y1 and x <= x2 and y <= y2 then
		return true
	else
		return false
	end
end

local function getLines(str)
	local lines = {}
	local w = 0
	for potato in str:gmatch("([^\n]*)\n?") do
		table.insert(lines,potato)
		if #potato > w then
			w = #potato
		end
	end
	return lines,w
end

local function cRestore(restore)
	if not restore then
		return {bg=term.getBackgroundColor(),fg=term.getTextColor(),cursor={term.getCursorPos()}}
	else
		term.setBackgroundColor(restore.bg)
		term.setTextColor(restore.fg)
		term.setCursorPos(unpack(restore.cursor))
	end
end

function input.box(x1,y1,x2,y2,tOptions,sReplaceChar,tShape)
	local holdTbl = {}
	local isHolding
	if lUtils then
		isHolding = lUtils.isHolding
	else
		isHolding = function(key)
			if type(key) == "string" then
				key = keys[key]
			end
			return not not holdTbl
		end
	end
	local oCursorA
	local s
	if not tShape then
		s = {x1=x1,y1=y1,x2=x2,y2=y2,cursor={x=1,y=1,a=1},scr=0,ref={}}
	else
		s = tShape
		s.cursor={x=1,y=1,a=1}
		s.scr=0
		s.ref={}
	end
	s.history = {}
	s.rhistory = {}
	s.changed = false
	local opt = {}
	if tOptions then
		opt = tOptions
	elseif s.opt then
		opt = s.opt
	else
		opt = {}
	end
	if not opt.overflow and not opt.overflowX and not opt.overflowY then
		opt.overflow = "scroll"
		opt.overflowX = "scroll"
		opt.overflowY = "none"
	end
	opt["overflow"] = opt.overflow or "scroll" -- none, stretch, scroll or wrap
	opt["overflowX"] = opt.overflowX or opt.overflow
	opt["overflowY"] = opt.overflowY or opt.overflow
	if opt.overflowY == "wrap" then
		opt.overflowY = "none"
	end
	opt["cursorColor"] = opt.cursorColor or s.txtcolor or term.getTextColor()
	opt["replaceChar"] = sReplaceChar or opt.replaceChar

	opt["minWidth"] = opt.minWidth or s.x2-(s.x1-1)
	opt["minHeight"] = opt.minHeight or s.y2-(s.y1-1)

	opt["tabSize"] = opt.tabSize or 4
	opt["indentChar"] = opt.indentChar or " "

	if opt.overflowX == "scroll" then
		s.scrollX = 0
	end

	if opt.overflowY == "scroll" then
		s.scrollY = 0
	end

	--[[opt["maxWidth"] = opt.maxWidth
	opt["maxHeight"] = opt.maxHeight]]

	s.opt = opt

	s.color = s.color or opt.backgroundColor or term.getBackgroundColor()
	s.txtcolor = s.txtcolor or opt.textColor or term.getTextColor()
	
	local txtcolor = s.txtcolor
	s.txt = opt.text or ""
	--s.lines = {s.txt}
	s.lines = {} -- real text input, for example password if censored
	s.dLines = {} -- rendered text input, buncha asterisks if censored, spaces instead of tab
	s.blit = {} -- foreground and background colors
	s.state = false
	local ref = s.ref
	local syntaxes = {
		["lua"] = {
			lexer="lex",
			whitespace=colors.white,
			comment=colors.green,
			string=colors.red,
			escape=colors.orange,
			keyword=colors.yellow,
			value=colors.yellow,
			ident=colors.white,
			number=colors.purple,
			symbol=colors.orange,
			operator=colors.yellow,
			unidentified=colors.white,
		},
		["lua-light"] = {
			lexer="lex",
			whitespace=colors.black,
			comment=colors.lightGray,
			string=colors.red,
			escape=colors.orange,
			keyword=colors.blue,
			value=colors.purple,
			ident=colors.black,
			number=colors.lightBlue,
			symbol=colors.orange,
			operator=colors.gray,
			unidentified=colors.black,
		}
	}
	local syntax
	local uservars = {}
	local scope = 0
	local function lineLn(line)
		local findTab = line:find("\t")
		local offset = 0
		local t = s.opt.tabSize
		while findTab do
			local l = t-(findTab+offset-1)%t
			offset = offset+(l-1)
			findTab = line:find("\t",findTab+1)
		end
		return #line+offset
	end
	local function fillTable(tTable,tbl,prefix)
		--local type = rtype
		local docs = s.opt.complete.docs
		while tTable do
			for k,v in pairs(tTable) do
				if type(k) == "string" and not tbl[k] then
					if type(v) == "table" then
						tbl[k] = {type="table",data={},name=prefix..k}
						if docs and docs[tbl[k].name] then
							tbl[k].docs = docs[tbl[k].name]
						end
						--[[scope = scope+1
						fillTable(v,tbl[k].data,prefix..k..".")
						scope = scope-1]]
					elseif type(v) == "string" or type(v) == "number" or type(v) == "boolean" then
						tbl[k] = {type=type(v),data=v,name=prefix..k}
						if docs and docs[tbl[k].name] then
							tbl[k].docs = docs[tbl[k].name]
						end
					elseif type(v) == "function" then
						local obj = {type="function",data=v,name=prefix..k}
						local args = {}
						if rtype(v) == "table" then
							local mt = getmetatable(v)
							if rtype(mt) == "table" and rtype(mt._call) == "function" then
								v = mt._call
							end
						end
						if rtype(v) == "function" then
							local info = debug.getinfo(v)
							for t=1,info.nparams do
								table.insert(args,debug.getlocal(v,t))
							end
							if info.isvararg then
								table.insert(args,"...")
							end
							obj.args = args
							obj.source = info.short_src
						end
						if not obj.args then obj.args = {} end
						if not obj.source then obj.source = "" end
						if docs and docs[obj.name] then
							obj.docs = docs[obj.name]
						end
						tbl[k] = obj
					end
				end
			end
			local tMetatable = getmetatable(tTable)
			if tMetatable and type(tMetatable.__index) == "table" then
				tTable = tMetatable.__index
			else
				tTable = nil
			end
		end
	end
	local keywords = {"and", "break", "do", "else", "elseif", "end", "for", "function", "if", "in", "local", "not", "or", "repeat", "return", "then", "until", "while"}
	local function complete(sTxt)
		local docs = s.opt.complete.docs
		if not sTxt then return {} end
		local sSearchText
		local fComplete = false
		local sSearchText = sTxt:match("^[a-zA-Z0-9_%.:]+")
		if not sSearchText then return end
		if #sSearchText < #sTxt then
			fComplete = true
		end
		s.opt.complete.selected = nil
		local env = s.opt.complete.env
		fillTable(env,uservars,"")
		local nStart = 1
		local nDot = string.find(sSearchText, ".", nStart, true)
		local tTable = uservars
		while nDot do
			local sPart = string.sub(sSearchText, nStart, nDot - 1)
			if not tTable[sPart] then return {} end
			local value = tTable[sPart].data
			if type(value) == "table" then
				tTable = value
				if type(env[sPart]) == "table" then
					fillTable(env[sPart],tTable,"")
					env = env[sPart]
				end
				nStart = nDot + 1
				nDot = string.find(sSearchText, ".", nStart, true)
			else
				return {}
			end
		end
		local nColon = string.find(sSearchText, ":", nStart, true)
		if nColon then
			local sPart = string.sub(sSearchText, nStart, nColon - 1)
			if not tTable[sPart] then return {} end
			local value = tTable[sPart].data
			if type(value) == "table" then
				tTable = value
				if type(env[sPart]) == "table" then
					fillTable(env[sPart],tTable,"")
					env = env[sPart]
				end
				nStart = nColon + 1
			else
				return {}
			end
		end

		local sPart = string.sub(sSearchText, nStart)
		local prefix = string.sub(sSearchText, 1, nStart-1)
		local nPartLength = #sPart

		local tResults = {}
		local tStrings = {}
		local tSorted = {}
		local tSeen = {}
		if fComplete then
			tResults.length = #sTxt
		else
			tResults.length = nPartLength
		end
		for k,v in pairs(tTable) do
			if not tSeen[k] and type(k) == "string" and not (nColon and v.type ~= "function") then
				if (string.find(k, sPart, 1, true) == 1 and not fComplete) or (fComplete and k == sPart) then
					if string.match(k, "^[%a_][%a%d_]*$") then
						local sResult = string.sub(k, nPartLength + 1)
						local display = k
						local index = sSearchText..sResult
						if v.type == "function" then
							local vArgs = utils.instantiate(v.args)
							if nColon then
								table.remove(vArgs,1)
							end
							if fComplete then
								display = index.."("..table.concat(vArgs,",")..")"
							else
								display = k.."("..table.concat(vArgs,",")..")"
							end
							sResult = sResult.."("
						end
						tStrings[sResult] = {src=(v.source or ""),complete=sResult,type=v.type,display=display}
						if fComplete and v.type ~= "function" then return nil end
						if docs[index] then
							local d = docs[index]
							if fComplete then
								tStrings[sResult].display = d.name:gsub("^_G%.","")
								tStrings[sResult].description = d.summary
							else
								tStrings[sResult].display = d.name:gsub("^_G%.",""):gsub("^"..prefix,"")
							end
						end
						table.insert(tSorted,sResult)
						--tResults[#tResults].id = #tResults
					end
				end
			end
			tSeen[k] = true
		end
		table.sort(tSorted)
		for t=1,#tSorted do
			tResults[t] = tStrings[tSorted[t]]
			tResults[t].id = t
		end
		--table.sort(tResults)
		return tResults
	end
	local function renderComplete(list) -- make option to use overay like s.opt.complete.overlay = true
		local c = s.opt.complete
		local LevelOS = c.LevelOS
		c.reverse = false
		if not c.selected and not list[1].description then
			c.selected = list[1]
		end
		local a = 0
		if s.border and s.border.color ~= 0 then
			a = 1
		end
		local scrollX = s.scrollX or 0
		local scrollY = s.scrollY or 0
		local x,y = s.x1+(s.cursor.x-1)+a-scrollX,s.y1+(s.cursor.y-1)+a-scrollY
		x = x-list.length-4
		y = y+1
		local width = 10
		local height = #list
		for t=1,#list do
			width = math.max(#list[t].display+#list[t].src+5,width)
			if list[t].description then
				list[t].lines = utils.wordwrap(list[t].description,width-4)
				height = height+#list[t].lines
			end
		end
		if c.overlay and LevelOS then
			--local wX,wY = LevelOS.self.window.win.getPosition()
			local wX,wY = lUtils.getWindowPos(term.current())
			local w,h = lOS.oldterm.getSize()
			x = x+wX-1
			y = y+wY-1
			if x < 1 then
				x = 1
			end
			if y+(height-1) > h and y-1-height >= 1 then
				y = y-2
				c.reverse = true
			end
			if x+(width-1) > w then
				x = w-width+1
			end
		else
			if x < s.x1 then
				x = s.x1
			end
			if y+(height-1) > s.y2 and y-1-height >= s.y1 then
				c.reverse = true
				y = y-2
			end
			if x+(width-1) > s.x2 then
				x = s.x2-width+1
			end
		end
		local offset = 1
		if c.reverse then
			offset = -1
		end
		local x2 = x+(width-1)
		abbrevs = {table={"tbl",colors.lime},number={"num",colors.yellow},boolean={"bln",colors.yellow},["function"]={"fnc",colors.cyan},keyword={"   ",colors.orange},["nil"]={"nil",colors.red},unknown={"???",colors.pink},string={"str",colors.yellow}}
		local function theRender()
			if not s.opt.complete.colors then
				s.opt.complete.colors = {}
			end
			local col = s.opt.complete.colors
			col.selectedbg = col.selectedbg or colors.lightBlue -- green
			col.backgroundColor = col.backgroundColor or colors.gray -- magenta
			col.txtcolor = col.txtcolor or colors.white -- white
			col.typebg = col.typebg or colors.black -- light gray
			col.selectedtypebg = col.selectedtypebg or colors.blue -- green
			col.sourcetxtcolor = col.sourcetxtcolor or colors.lightGray -- pink
			local cY = y
			for t=1,#list do
				if c.selected == list[t] then
					term.setBackgroundColor(col.selectedtypebg)
				else
					term.setBackgroundColor(col.typebg)
				end
				local a = abbrevs[list[t].type] or abbrevs["unknown"]
				term.setTextColor(a[2])
				term.setCursorPos(x,cY)
				term.write(a[1])
				if c.selected == list[t] then
					term.setBackgroundColor(col.selectedbg)
				else
					term.setBackgroundColor(col.backgroundColor)
				end
				term.setTextColor(col.txtcolor)
				term.write(" "..list[t].display..string.rep(" ",width-#list[t].display-4-#list[t].src))
				term.setCursorPos(x2-(#list[t].src-1),cY)
				term.setTextColor(col.sourcetxtcolor)
				term.write(list[t].src)
				cY = cY+offset
				if list[t].lines then
					for i,l in ipairs(list[t].lines) do
						term.setCursorPos(x,cY)
						term.setTextColor(col.sourcetxtcolor)
						term.write("    "..l..string.rep(" ",width-#l-4))
						cY = cY+offset
					end
				end
			end
		end
		local x1,y1,x2,y2
		if c.overlay and LevelOS then
			LevelOS.overlay = theRender
			local wX,wY = LevelOS.self.window.win.getPosition()
			x1 = x-wX+1
			x2 = x1+width-1
			y1 = y-wY+1
			y2 = y1+((#list-1)*offset)
		else
			x1 = x
			y1 = y
			y2 = y1+((#list-1)*offset)
			theRender()
		end
		list.x1 = x1
		list.y1 = math.min(y1,y2)
		list.y2 = math.max(y1,y2)
		list.x2 = x2
	end
	local function replaceText(txt,pos1,pos2,replace)
		return txt:sub(1,pos1-1)..replace..txt:sub(pos2+1,#txt)
	end
	local function genLines(t)
		local syn = s.opt.syntax
		if type(syn) == "string" and syntaxes[syn] then
			syntax = syntaxes[syn]
			syntax.type = syn
		elseif type(syn) == "table" and syn.lexer and type(syn.lexer) == "function" then
			syntax = syn
		elseif type(syn) == "table" and syntaxes[syn.type] then
			syntax = syntaxes[syn.type]
			for k,v in pairs(syn) do
				syntax[k] = v
			end
		elseif type(syn) == "table" and syn.lexer and ((type(syn.lexer) == "string" and fs.exists(syn.lexer)) or type(syn.lexer) == "function") then
			syntax = syn
		else
			syntax = nil
		end
		local blit = {}
		if s.opt.complete and syntax then
			uservars = {}
			for k=1,#keywords do
				uservars[keywords[k]] = {type="keyword"}
			end
			uservars["true"] = {type="boolean"}
			uservars["false"] = {type="boolean"}
			uservars["nil"] = {type="nil"}
			_G.debuguservars = uservars
			--[[scope = 0
			local tTable = s.opt.complete.env
			fillTable(tTable,uservars,"")]]
		end
		if syntax and ((type(syntax.lexer) == "string" and fs.exists(syntax.lexer)) or type(syntax.lexer) == "function") then
			if type(syntax.lexer) ~= "function" then
				syntax.lexer = dofile(syntax.lexer)
			end
			local lex = syntax.lexer
			local sublines = lex(t)
			local line = 1
			local l = 0
			local ref = 0
			--for li in t:gmatch("([^\n]*)\n?") do -- this aint workin and dont forget to add newlines to the blit lines
			blit[1] = ""
			blit[2] = ""
			_G.debugsublines = sublines
			for l=1,#sublines do
				local elements = sublines[l]
				for t=1,#elements do
					local col = utils.toBlit(syntax[elements[t].type] or s.txtcolor)
					blit[1] = blit[1]..elements[t].data
					blit[2] = blit[2]..string.rep(col,#elements[t].data)
					if s.opt.complete and #s.txt < 40000 and syntax.type:find("^lua") then
						if elements[t].type == "nfunction" then
							local el = t+1
							local args = {}
							while true do
								local e = elements[el]
								if not e then
									break
								elseif e.type == "function" or e.type == "whitespace" or e.data == "(" or e.data == "," or e.data == "=" then
									el = el+1
								elseif e.type == "arg" or e.data == "..." then
									table.insert(args,e.data)
									el = el+1
								else
									break
								end
							end
							local parent = {data=uservars}
							local el = t-1
							local children = {}
							while true do
								local e = elements[el]
								if not e then
									break
								elseif e.data == "." then
									el = el-1
								elseif e.type == "ident" then
									table.insert(children,1,e.data)
									el = el-1
								else
									break
								end
							end
							for t=1,#children do
								if parent.data[children[t]] then
									local child = parent.data[children[t]]
									if type(child.data) ~= "table" then child.data = {} child.type = "table" end
									parent = child
								else
									parent.data[children[t]] = {data={},type="table",source="Ln "..l}
									parent = parent.data[children[t]]
								end
							end
							parent.data[elements[t].data] = {args=args,type="function",source="Ln "..l}
						elseif elements[t].type == "ident" then
							local el = t+1
							local foundEquals = false
							local foundValue = false
							local naming = true
							local prefix = ""
							local parent = {data=uservars}
							local children = {elements[t].data}
							while true do
								local e = elements[el]
								if not e then
									break
								elseif e.data == "." and naming then
									el = el+1
								elseif e.type == "whitespace" or (e.data == "=" and not foundEquals) then
									naming = false
									el = el+1
									if e.data == "=" then
										local stop = false
										for c=1,#children-1 do
											local child = parent.data[children[c]]
											if not child then parent.data[children[c]] = {data={},type="table",source="Ln "..l} child = parent.data[children[c]] end
											if type(child.data) ~= "table" then child.data = {} child.type = "table" end
											parent = child
											prefix = prefix..children[c].."."
										end
										if stop then break end
										foundEquals = true
									end
								elseif e.type == "ident" then
									el = el+1
									if naming then
										table.insert(children,e.data)
									else
										-- idk do later
										foundValue = true
										-- add table support
										if uservars[e.data] then
										end
									end
								elseif foundEquals and (e.type == "string" or e.type == "number" or (e.type == "operator" and e.data == "-") or e.type == "value" or (e.type == "symbol" and e.data:sub(1,1) == "{") or e.type == "function") then
									local vType = e.type
									if e.type == "operator" then
										vType = "number"
									elseif e.type == "value" then
										if e.data == "nil" then
											vType = "nil"
										elseif e.data == "true" or e.data == "false" then
											vType = "boolean"
										else
											vType = "unknown"
										end
									elseif e.type == "symbol" then
										vType = "table"
									elseif e.type == "function" then
										vType = "unknown"
									end
									local obj = {name=prefix..children[#children],type=vType,source="Ln "..l}
									if vType == "table" then
										obj.data = {}
									end
									parent.data[children[#children]] = obj
									break
								else
									break
								end
							end
						end
					end
				end
				if l < #sublines then
					blit[1] = blit[1].."\n"
					blit[2] = blit[2].."\n"
				end
			end
			_G.debugBlit2 = {blit[1],blit[2]}
		end
		-- check for transparency for third blit line
		for a=1,#s.lines do
			s.lines[a] = nil
			s.dLines[a] = nil
			s.blit[a] = nil
			ref[a] = nil
		end
		s.lines[1] = ""
		s.dLines[1] = ""
		local width = s.x2-(s.x1-1)
		local height = s.y2-(s.y1-1)
		if s.border and s.border.color ~= 0 then
			width = width-2
			height = height-2
		end
		local c = 1
		local l = s.lines
		local dl = s.dLines
		local pl = 0
		if opt.overflowX == "scroll" then
			--local b,e = t:find()
			l[1] = ""
			dl[1] = ""
			while true do
				-- line
				local b,e = t:find("[^\n]*\n?")
				if not b or e == 0 then break end
				local line = t:sub(b,e)
				l[c] = line
				if #blit > 0 then
					dl[c] = line
					local findTab = dl[c]:find("\t")
					local blit2 = blit[2]
					if not s.opt.tabSize then
						s.opt.tabSize = 4
					end
					local t = s.opt.tabSize
					while findTab do
						local l = t-(findTab-1)%t
						dl[c] = replaceText(dl[c],findTab,findTab,string.sub(s.opt.indentChar..string.rep(" ",t-#s.opt.indentChar),t-l+1,t))
						char = utils.toBlit(syntax.whitespace)
						blit2 = replaceText(blit2,findTab,findTab,string.rep(char,l))
						findTab = dl[c]:find("\t")
					end
					local tabArea = string.rep(" ",t)
					local findSpace,findSpace2 = dl[c]:find(tabArea)
					while findSpace do
						dl[c] = replaceText(dl[c],findSpace,findSpace2,s.opt.indentChar..string.rep(" ",t-#s.opt.indentChar))
						findSpace,findSpace2 = dl[c]:find(tabArea,findSpace2+1)
					end
					dl[c] = dl[c]:sub(1+s.scrollX,width+s.scrollX)
					s.blit[c] = {dl[c],blit2:sub(b+s.scrollX,b+s.scrollX+(#dl[c]-1)),string.rep(utils.toBlit(s.color),#dl[c])}
					blit[1] = blit[1]:sub(e+1,#blit[1])
					blit[2] = blit[2]:sub(e+1,#blit[2])
				else
					dl[c] = line:sub(1+s.scrollX,width+s.scrollX)
					s.blit[c] = {dl[c],string.rep(utils.toBlit(s.txtcolor),#dl[c]),string.rep(utils.toBlit(s.color),#dl[c])}
				end
				if line:sub(#line) == "\n" then
					if c+1 > height then
						if opt.overflowY == "stretch" then
							s.y2 = s.y2+1
						elseif opt.overflowY == "none" then
							return false
						end
					end
					l[c+1] = ""
					dl[c+1] = ""
				end
				t = t:sub(e+1,#t)
				c = c+1
			end
		else
			while true do
				local b,e = t:find("%S*%s?")
				if not b or e < 1 then break end
				local w = e-(b-1)
				c = #l
				if not dl[c] then dl[c] = l[c] end
				if string.find(t:sub(b,e),"\n",nil,true) then
					if (opt.overflowY == "stretch" or opt.overflowY == "scroll") or c+1 <= height then
						if opt.overflowY == "stretch" and c+1 > height then
							s.y2 = s.y2+1
						end
						b2,e2 = t:sub(b,e):find("\n",nil,true)
						e = e2
						l[c+1] = ""
						dl[c+1] = ""
					else
						return false
					end
				end
				local of = opt.overflowX
				local tW,tH = term.getSize()
				if opt.overflowX == "stretch" then
					if #dl[c]+w > tW and #dl[c]+w > width then
						of = "wrap"
					end
				end
				if #dl[c]+w > width then
					if opt.overflowX == "wrap" then
						if (opt.overflowY == "stretch" or opt.overflowY == "scroll") or c+1 <= height then
							if opt.overflowY == "stretch" and c+1 > height then
								s.y2 = s.y2+1
							end
							if not dl[c]:find("%S") then
								e = width-#l[c]
								l[c] = l[c]..t:sub(b,e)
								l[c+1] = ""
							else
								--l[c+1] = t:sub(b,e)
								e = b-1
								l[c+1] = ""
							end
						else
							-- oh no, stop typing
							return false
						end
					elseif opt.overflowX == "stretch" then
						s.x2 = s.x2+1
						l[c] = l[c]..t:sub(b,e)
						dl[c] = dl[c]..t:sub(b,e):gsub("\9","    ")
					elseif opt.overflowX == "none" then
						return false
					end
				else
					l[c] = l[c]..t:sub(b,e)
					dl[c] = dl[c]..t:sub(b,e):gsub("\9","    ")
				end
				t = t:sub(e+1,#t)
			end
		end
		return true
	end
	genLines(s.txt)
	local function genText()
		local txt = ""
		ref[1] = 1
		for l=1,#s.lines do
			txt = txt..s.lines[l]
			ref[l+1] = ref[l]+#s.lines[l]
			if s.select and s.select[1] < ref[l+1] and s.select[2] >= ref[l] and s.blit and s.blit[l] then
				local line = s.lines[l]
				local c = utils.toBlit(s.opt.selectColor or colors.blue)
				local sel1 = s.select[1]-ref[l]
				local sel2 = s.select[2]-ref[l]+2
				local findTab = s.lines[l]:find("\t")
				local off1 = 0
				local off2 = 0
				local offT = 0
				while findTab do
					line = replaceText(line,findTab,findTab," ")
					local t = s.opt.tabSize
					local a = t-(findTab+offT-1)%t
					if sel1 >= findTab then
						off1 = off1+a-1
					end
					if sel2 > findTab then
						off2 = off2+a-1
					end
					if findTab > sel1 and findTab < sel2 then
						s.blit[l][1] = replaceText(s.blit[l][1],offT+findTab,offT+findTab+(a-1),string.sub(string.rep("\140",t-1).."\132",t-a+1,t))
					end
					offT = offT+a-1
					findTab = line:find("\t")
				end
				sel1 = sel1+off1-s.scrollX
				sel2 = sel2+off2-s.scrollX
				local pos1 = math.max(0,sel1)
				local pos2 = math.min(#s.blit[l][1]+1,sel2)
				s.blit[l][3] = s.blit[l][3]:sub(1,pos1)..string.rep(c,pos2-(pos1+1))..s.blit[l][3]:sub(pos2,#s.blit[l][1])
				if s.opt.selectTxtColor then
					local c2 = utils.toBlit(s.opt.selectTxtColor)
					s.blit[l][2] = s.blit[l][2]:sub(1,pos1)..string.rep(c2,pos2-(pos1+1))..s.blit[l][2]:sub(pos2,#s.blit[l][1])
				end
				s.blit[l][1] = s.blit[l][1]:sub(1,pos1)..s.blit[l][1]:sub(pos1+1,pos2-1):gsub(" ","\183")..s.blit[l][1]:sub(pos2,#s.blit[l][1])
			end
		end
		return txt
	end
	genText()
	local function calcCursor()
		local width = s.x2-(s.x1-1)
		local height = s.y2-(s.y1-1)
		if s.border and s.border.color ~= 0 then
			width = width-2
			height = height-2
		end
		for r=1,#s.lines do
			if ref[r+1] > s.cursor.a or r == #s.lines then
				s.cursor.y = r
				s.cursor.x = s.cursor.a-(ref[r]-1)
				local _,tabs = s.txt:sub(ref[r],s.cursor.a-1):gsub("\9","")
				s.cursor.x = s.cursor.x+((s.opt.tabSize-1)*tabs)
				break
			end
		end
		if opt.overflowX == "scroll" then
			if s.cursor.x < (1+s.scrollX) then
				s.scrollX = s.cursor.x-1
			elseif s.cursor.x > (width+s.scrollX) then
				s.scrollX = s.cursor.x-width
			end
			if s.scrollX > 0 and lineLn(s.lines[s.cursor.y]) < width then
				s.scrollX = 0
			end
		end
		if opt.overflowY == "scroll" then
			if s.cursor.y < (1+s.scrollY) then
				s.scrollY = s.cursor.y-1
			elseif s.cursor.y > (height+s.scrollY) then
				s.scrollY = s.cursor.y-height
			end
		end
	end
	local function rCalcCursor()
		local x = s.cursor.x
		local tx = 0
		local offset = 0
		local line = s.lines[s.cursor.y]
		if s.cursor.y == #s.lines then
			line = line.."\n"
		end
		for w in line:gmatch(".") do
			tx = tx+1
			if w == "\t" then
				local l = s.opt.tabSize-(tx-1)%s.opt.tabSize
				tx = tx+l-1
				offset = offset+l-1
			end
			if tx >= x then
				x = tx-offset
				break
			end
		end
		s.cursor.a = ref[s.cursor.y]+(x-1)
	end
	--s.rCalcCursor = rCalcCursor
	local oTxt = ""
	local function rAll(nTxt)
		if nTxt then
			if not genLines(nTxt) then
				genLines(s.txt)
				s.cursor.a = oCursorA
			else
				s.txt = nTxt
			end
		else
			genLines(s.txt)
		end
		genText()
		calcCursor()
		genLines(s.txt)
		genText()
		oTxt = s.txt
		if s.opt.complete then
			s.opt.complete.list = nil
		end
	end
	local uTimer
	local function addUndo(event)
		if #s.history == 0 then
			table.insert(s.history,{txt=s.txt,changed=true,cursor=s.cursor.a})
		end
		if event == "paste" then
			table.insert(s.history,{txt=s.txt,changed=true,cursor=s.cursor.a,description="Paste"})
		elseif event == "key" or event == "char" then
			--if s.history[#s.history] and s.history[#s.history].time and s.history[#s.history].time > os.epoch("utc")-250
			if uTimer then os.cancelTimer(uTimer) end
			uTimer = os.startTimer(0.3)
		elseif event == "timer" then
			table.insert(s.history,{txt=s.txt,changed=s.changed,cursor=s.cursor.a,description="Insert Characters"})
		end
		while #s.history > 80 do
			table.remove(s.history,1)
		end
	end
	local function undo()
		if s.history[#s.history-1] then
			local h = s.history[#s.history-1]
			s.changed = h.changed
			s.cursor.a = h.cursor
			rAll(h.txt)
			table.insert(s.rhistory,s.history[#s.history])
			table.remove(s.history,#s.history)
		end
	end
	local function redo()
		if s.rhistory[#s.rhistory] then
			local h = s.history
			local r = s.rhistory[#s.rhistory]
			s.changed = r.changed
			s.cursor.a = r.cursor
			rAll(r.txt)
			table.insert(s.history,r)
			table.remove(s.rhistory,#s.rhistory)
		end
	end
	local function addText(txt)
		local a = 0
		if s.border and s.border.color ~= 0 then
			a = 1
		end
		local ttxt = txt
		if txt:find("\n") then
			if s.opt.overflowY == "none" and s.cursor.y >= s.y2-s.y1+1-a*2 then
				return false
			else
				ttxt = txt:match("(.-)\n")
			end
		end
		if s.opt.overflowX == "none" and lineLn(s.lines[s.cursor.y]..ttxt) > s.x2-s.x1+1-a*2 then
			return false
		end
		local pos1,pos2
		if s.select then
			pos1 = s.select[1]-1
			pos2 = s.select[2]+1
		else
			pos1 = s.cursor.a-1
			pos2 = s.cursor.a
		end
		s.changed = true
		s.txt = s.txt:sub(1,pos1)..txt..s.txt:sub(pos2,#s.txt)
		s.cursor.a = pos1+#txt+1
		s.select = nil
		rAll()
	end
	local function update(...) -- maybe make it so that click already selects and then the key char etc operations always sub based on select so no if statement needed
		opt = s.opt
		if not opt.tabSize then
			opt.tabSize = 4
		end
		oCursorA = s.cursor.a
		local e = table.pack(...)
		if not lUtils then
			if e[1] == "key" then
				holdTbl[e[2]] = true
			elseif e[1] == "key_up" then
				holdTbl[e[2]] = nil
			end
		end
		if s.opt.complete and s.opt.complete.LevelOS and s.opt.complete.LevelOS.self.window.events == "all" and e[1]:find("mouse") and type(e[3]) == "number" and type(e[4]) == "number" then
			local wX,wY = s.opt.complete.LevelOS.self.window.win.getPosition()
			e[3] = e[3]-(wX-1)
			e[4] = e[4]-(wY-1)
		end
		if e[1] == "mouse_click" and s.opt.complete and s.opt.complete.list and #s.opt.complete.list > 0 and not isInside(e[3],e[4],s.opt.complete.list) then
			s.opt.complete.list = nil
			rAll()
		end
		if e[1] == "timer" and e[2] == uTimer then
			addUndo(e[1])
		end
		if not s.state then
			if e[1] == "mouse_click" and e[3] >= s.x1 and e[4] >= s.y1 and e[3] <= s.x2 and e[4] <= s.y2 then
				s.state = true
			elseif e[1] == "term_resize" then
				rAll()
			elseif s.txt ~= oTxt then
				rAll()
			end
		else
			if e[1] == "mouse_click" then
				if (e[3] < s.x1 or e[3] > s.x2 or e[4] < s.y1 or e[4] > s.y2) and not (s.opt.complete and s.opt.complete.list and #s.opt.complete.list > 0 and isInside(e[3],e[4],s.opt.complete.list)) then -- add support for autocomplete click
					term.setCursorBlink(false)
					s.state = false
				end
			end
			if s.txt ~= oTxt then
				rAll()
			end
			if e[1] == "char" then
				if #s.history == 0 then
					table.insert(s.history,{txt=s.txt,changed=false,cursor=s.cursor.a})
				end
				--[[s.changed = true
				s.cursor.a = s.cursor.a+1
				rAll(s.txt:sub(1,s.cursor.a-2)..e[2]..s.txt:sub(s.cursor.a-1,#s.txt))]]
				addText(e[2])
				addUndo(e[1])
				if s.opt.complete then
					s.opt.complete.complete = complete
					s.opt.complete.render = renderComplete
					s.opt.complete.list = complete(string.match(s.txt:sub(1,s.cursor.a-1), "[a-zA-Z0-9_%.:]+$"))
				end
			elseif e[1] == "key" then
				local dirs = {
					[keys.left] = true,
					[keys.right] = true,
					[keys.up] = true,
					[keys.down] = true,
					[keys["end"]] = true,
					[keys.home] = true,
				}
				local deletes = {
					[keys.delete] = true,
					[keys.backspace] = true,
				}
				if isHolding(keys.leftCtrl) and dirs[e[2]] then -- e fuck implement ur own isholdign
					-- nothing
				elseif s.select and dirs[e[2]] then
					s.select = nil
					rAll()
				elseif s.select and deletes[e[2]] then
					addText("")
				elseif e[2] == keys.left and s.cursor.a > 1 then
					s.cursor.a = s.cursor.a-1
					--calcCursor()
					rAll()
				elseif e[2] == keys.right and s.cursor.a <= #s.txt then
					s.cursor.a = s.cursor.a+1
					--calcCursor()
					rAll()
				elseif e[2] == keys.up then
					local c = s.opt.complete
					if c and c.list and #c.list > 0 and c.selected then
						local offset = 1
						if c.reverse then
							offset = -1
						end
						local sID = c.selected.id-offset
						if sID < 1 then
							sID = #c.list
						elseif sID > #c.list then
							sID = 0
						end
						c.selected = c.list[sID]
					elseif s.cursor.y > 1 then
						s.cursor.y = s.cursor.y-1
						if opt.overflowX == "scroll" then
							li = s.lines
						else
							li = s.dLines
						end
						local ln = lineLn(li[s.cursor.y])
						if s.cursor.x > ln then
							s.cursor.x = ln
							if s.cursor.y == #s.lines then
								s.cursor.x = s.cursor.x+1
							end
						end
						rCalcCursor()
						rAll()
					end
				elseif e[2] == keys.down then
					local c = s.opt.complete
					if c and c.list and #c.list > 0 and c.selected then
						local offset = 1
						if c.reverse then
							offset = -1
						end
						local sID = c.selected.id+offset
						if sID < 1 then
							sID = #c.list
						elseif sID > #c.list then
							sID = 0
						end
						c.selected = c.list[sID]
					elseif s.cursor.y < #s.lines then
						s.cursor.y = s.cursor.y+1
						if opt.overflowX == "scroll" then
							li = s.lines
						else
							li = s.dLines
						end
						local ln = lineLn(li[s.cursor.y])
						if s.cursor.x > ln then
							s.cursor.x = ln
							if s.cursor.y == #s.lines then
								s.cursor.x = s.cursor.x+1
							end
						end
						rCalcCursor()
						rAll()
					end
				elseif e[2] == keys.pageUp then
					local h = s.y2-(s.y1-1)
					s.cursor.y = math.max(s.cursor.y-h,1)
					if opt.overflowX == "scroll" then
						li = s.lines
					else
						li = s.dLines
					end
					local ln = lineLn(li[s.cursor.y])
					if s.cursor.x > ln then
						s.cursor.x = ln
						if s.cursor.y == #s.lines then
							s.cursor.x = s.cursor.x+1
						end
					end
					rCalcCursor()
					rAll()
				elseif e[2] == keys.pageDown then
					local h = s.y2-(s.y1-1)
					s.cursor.y = math.min(s.cursor.y+h,#s.lines)
					if opt.overflowX == "scroll" then
						li = s.lines
					else
						li = s.dLines
					end
					local ln = lineLn(li[s.cursor.y])
					if s.cursor.x > ln then
						s.cursor.x = ln
						if s.cursor.y == #s.lines then
							s.cursor.x = s.cursor.x+1
						end
					end
					rCalcCursor()
					rAll()
				elseif e[2] == keys["end"] then
					if isHolding(keys.leftCtrl) then
						s.cursor.a = #s.txt+1
					else
						if opt.overflowX == "scroll" then
							local ln = lineLn(s.lines[s.cursor.y])

							s.cursor.x = ln
						else
							s.cursor.x = #s.dLines[s.cursor.y]
						end
						if s.cursor.y == #s.lines then
							s.cursor.x = s.cursor.x+1
						end
						rCalcCursor()
					end
					rAll()
				elseif e[2] == keys.home then
					if isHolding(keys.leftCtrl) then
						s.cursor.a = 1
					else
						local wp = (s.lines[s.cursor.y]:match("^[\t ]+") or ""):gsub("\t",string.rep(" ",s.opt.tabSize)) -- always beginning of string so always 4 per tab
						if s.cursor.x == 1+#wp then
							s.cursor.x = 1
						else
							s.cursor.x = 1+#wp
						end
						rCalcCursor()
					end
					rAll()
				elseif e[2] == keys.backspace and s.cursor.a > 1 then
					s.changed = true
					s.txt = s.txt:sub(1,s.cursor.a-2)..s.txt:sub(s.cursor.a,#s.txt)
					s.cursor.a = s.cursor.a-1
					rAll()
					addUndo(e[1])
				elseif e[2] == keys.delete and s.cursor.a <= #s.txt then
					s.changed = true
					s.txt = s.txt:sub(1,s.cursor.a-1)..s.txt:sub(s.cursor.a+1,#s.txt)
					rAll()
					addUndo(e[1])
				elseif e[2] == keys.enter then
					local wp = s.lines[s.cursor.y]:match("^[\t ]+") or ""
					addText("\n"..wp)
					addUndo(e[1])
				elseif (isHolding(keys.leftCtrl) and (e[2] == keys.leftBracket or e[2] == keys.rightBracket)) or (s.select and e[2] == keys.tab) then
					local sLine = s.cursor.y
					local eLine = s.cursor.y
					if s.select then
						for l=1,#s.lines do
							local encountered = false
							if (s.select[1] >= s.ref[l] and s.select[1] < s.ref[l+1]) then -- if begin of select is in line
								sLine = math.min(sLine,l)
							end
							if (s.select[2] >= s.ref[l] and s.select[2] < s.ref[l+1]) then -- if end of select is in line
								eLine = math.max(eLine,l)
								encountered = true
							elseif encountered then -- if it already encountered the select and is no longer in selected area it doesnt need to search any further
								break
							end
						end
					end
					for l=sLine,eLine do
						if e[2] == keys.rightBracket or e[2] == keys.tab then
							s.lines[l] = "\t"..s.lines[l]
							if s.select then
								if s.select[1] >= s.ref[l] then
									s.select[1] = s.select[1]+1
								end
								if s.select[2] >= s.ref[l] then
									s.select[2] = s.select[2]+1
								end
							end
							if s.cursor.a >= s.ref[l] then
								s.cursor.a = s.cursor.a+1
							end
							calcCursor()
						elseif e[2] == keys.leftBracket then
							if s.lines[l]:find("^\t") then
								s.lines[l] = s.lines[l]:gsub("^\t","")
								if s.select then
									if s.select[1] > s.ref[l] then
										s.select[1] = s.select[1]-1
									end
									if s.select[2] > s.ref[l] then
										s.select[2] = s.select[2]-1
									end
								end
								if s.cursor.a > s.ref[l] then
									s.cursor.a = s.cursor.a-1
								end
							elseif s.lines[l]:find("^    ") then
								s.lines[l] = s.lines[l]:gsub("^    ","")
								if s.select then
									if s.select[1] > s.ref[l] then
										s.select[1] = math.max(s.select[1]-4,s.ref[l])
									end
									if s.select[2] > s.ref[l] then
										s.select[2] = math.max(s.select[2]-4,s.ref[l])
									end
								end
								if s.cursor.a > s.ref[l] then
									s.cursor.a = math.max(s.cursor.a-4,s.ref[l])
								end
							end
						end
						s.txt = genText()
						rAll()
					end
				elseif e[2] == keys.tab then
					local c = s.opt.complete
					if c and c.list and #c.list > 0 and c.selected then
						addText(c.selected.complete)
						addUndo("char")
					else
						addText("\t")
						addUndo(e[1])
					end
				elseif isHolding(keys.leftCtrl) then
					if e[2] == keys.z then
						undo()
					elseif e[2] == keys.y then
						redo()
					elseif e[2] == keys.a then
						s.select = {1,#s.txt}
						s.cursor.a = #s.txt+1
						rAll()
					elseif (e[2] == keys.c or e[2] == keys.x) and ccemux and s.select then
						local txt = s.txt:sub(s.select[1],s.select[2])
						ccemux.setClipboard(txt)
						lOS.clipboard = txt
						if e[2] == keys.x then
							addText("")
							addUndo(e[1])
						end
					end
				end
			elseif e[1] == "paste" then
				if s.opt.complete then
					s.opt.complete.list = nil
				end
				if #s.history == 0 then
					table.insert(s.history,{txt=s.txt,changed=false,cursor=s.cursor.a})
				end
				local txt = e[2]
				if lOS.clipboard then
					local nline = lOS.clipboard:find("(.)\n") or #lOS.clipboard
					local checkCB = lOS.clipboard:sub(1,nline):gsub("\t","")
					if txt == checkCB then
						txt = lOS.clipboard
					end
				end
				addText(txt)
				addUndo(e[1])
			elseif s.opt.complete and s.opt.complete.list and #s.opt.complete.list > 0 and s.opt.complete.selected and (e[1] == "mouse_click" or e[1] == "mouse_scroll" or e[1] == "mouse_up") and isInside(e[3],e[4],s.opt.complete.list) then
				local c = s.opt.complete
				--local x,y = e[3]-(s.x1-1),e[4]-(s.y1-1)
				local el = e[4]-(s.opt.complete.list.y1-1)
				if e[1] == "mouse_click" then
					c.selected = c.list[el]
				elseif e[1] == "mouse_up" and c.selected.id == el then
					s.changed = true
					s.txt = s.txt:sub(1,s.cursor.a-1)..c.selected.complete..s.txt:sub(s.cursor.a,#s.txt)
					s.cursor.a = s.cursor.a+#c.selected.complete
					rAll()
					addUndo("char")
				end
			elseif e[1] == "mouse_click" or e[1] == "mouse_scroll" then
				s.select = nil
				if e[3] >= s.x1 and e[4] >= s.y1 and e[3] <= s.x2 and e[4] <= s.y2 then
					if e[1] == "mouse_click" then
						local scrollX = s.scrollX or 0
						local scrollY = s.scrollY or 0
						local x,y = e[3]-(s.x1-1)+scrollX,e[4]-(s.y1-1)-s.scr+scrollY
						if not s.lines[y] then
							y = #s.lines
						end
						if x > #s.dLines[y] then
							if opt.overflowX == "scroll" then
								x = lineLn(s.lines[y])
							else
								x = #s.dLines[y]
							end
							if y == #s.lines then
								x = x+1
							end
						end
						s.cursor.x,s.cursor.y = x,y
						rCalcCursor()
						rAll()
					elseif opt.overflowY == "scroll" and e[1] == "mouse_scroll" then
						local width = s.x2-(s.x1-1)
						local height = s.y2-(s.y1-1)
						if s.border and s.border.color ~= 0 then
							width = width-2
							height = height-2
						end
						if s.scrollY+e[2] >= 0 and s.scrollY+e[2] <= #s.lines-height then
							s.scrollY = s.scrollY+e[2]
						end
					end
				end
			elseif e[1] == "mouse_drag" then
				local pos1
				if s.select then
					pos1 = s.select[1]
				else
					pos1 = s.cursor.a
					s.select = {pos1,pos1}
				end
				local scrollX = s.scrollX or 0
				local scrollY = s.scrollY or 0
				local x,y = e[3]-(s.x1-1)+scrollX,e[4]-(s.y1-1)-s.scr+scrollY
				if not s.lines[y] then
					y = #s.lines
				end
				if x > #s.dLines[y] then
					if opt.overflowX == "scroll" then
						x = lineLn(s.lines[y])
					else
						x = #s.dLines[y]
					end
					if y == #s.lines then
						x = x+1
					end
				end
				s.cursor.x,s.cursor.y = x,y
				rCalcCursor()
				local pos2 = s.cursor.a
				if s.select then
					if pos2 < s.select[1] and not s.select.reversed then
						s.select.reversed = true
						s.select[2] = s.select[1]-1
					elseif pos2 > s.select[2] and s.select.reversed then
						s.select.reversed = false
						s.select[1] = s.select[2]+1
					end
					if s.select.reversed then
						s.select[1] = pos2
					else
						s.select[2] = pos2-1
					end
				end
				rAll()
			elseif e[1] == "term_resize" then
				rAll()
			end
		end
		local lChar = s.txt:sub(s.cursor.a-1,s.cursor.a-1)
		if s.opt.complete and (e[1] == "key" or e[1] == "char") and (lChar == "(" or lChar == ",") then
			s.opt.complete.list = complete(string.match(s.txt:sub(1,s.cursor.a-1), "[a-zA-Z0-9_%.:%(]+[^%)%(]*$"))
		end
	end
	local function render()
		if s.color == 0 then s.color = colors.white end
		local restore = cRestore()
		term.setBackgroundColor(s.color or term.getBackgroundColor())
		local a = 0
		if s.border and s.border.color ~= 0 then
			a = 1
		end
		lOS.boxClear(s.x1+a,s.y1+a,s.x2-a,s.y2-a)
		local scrollX = s.scrollX or 0
		local scrollY = s.scrollY or 0

		for y=s.y1+a,s.y2-a do
			local l = y-(s.y1-1+a)+s.scr + scrollY
			if s.lines[l] then
				term.setCursorPos(s.x1+a,y)
				term.setBackgroundColor(s.color or term.getBackgroundColor())
				term.setTextColor(s.txtcolor or txtcolor)
				local line
				if s.blit[l] then
					line = s.blit[l][1]
				else
					line = s.dLines[l]
				end
				if type(opt.replaceChar) == "string" and #opt.replaceChar > 0 then
					local pattern = "."
					for t=1,#opt.replaceChar-1 do
						pattern = pattern..".?"
					end
					local nLine = line:gsub(pattern,opt.replaceChar)
					line = nLine:sub(1,#line)
				end
				if s.blit[l] then
					--s.blit[l][3] = string.rep(lUtils.toBlit(s.color or term.getBackgroundColor()),#s.blit[l][1])
					term.blit(line,s.blit[l][2],s.blit[l][3])
				else
					term.write(line)
				end
			end
		end
		if s.opt.complete and s.opt.complete.list and #s.opt.complete.list > 0 then
			if s.opt.complete.overlay and s.opt.complete.LevelOS then
				s.opt.complete.LevelOS.self.window.events = "all"
				lOS.noEvents = 2
			end
			lOS.noEvents = 2
			local ok,err = pcall(renderComplete,s.opt.complete.list)
			if not ok then
				_G.theterribleerrorrighthere = err
			end
		elseif s.opt.complete and s.opt.complete.LevelOS and s.opt.complete.LevelOS.self.window.events == "all" then
			if s.opt.complete.overlay then
				s.opt.complete.LevelOS.self.window.events = nil
				lOS.noEvents = false
			end
			s.opt.complete.LevelOS.overlay = nil
		end
		if s.state then
			local x,y = s.x1+(s.cursor.x-1)+a-scrollX,s.y1+(s.cursor.y-1)+a-scrollY
			if isInside(x,y,s) then
				term.setTextColor(opt.cursorColor or txtcolor)
				term.setCursorPos(x,y)
				term.setCursorBlink(true)
			else
				term.setCursorBlink(false)
			end
		else
			cRestore(restore)
		end
	end
	if not tShape then
		s.update = update
		s.render = render
	else
		s.fUpdate = update
		s.fRender = render
	end
	return s
end

function input.read(_sReplaceChar)
	local x1,y1 = term.getCursorPos()
	local x2,_ = term.getSize()
	local box = input.box(x1,y1,x2,y1,{overflowX="scroll",overflowY="none",replaceChar=_sReplaceChar})
	box.state = true
	while true do
		local e = {os.pullEvent()}
		if e[1] == "key" and e[2] == keys.enter then
			box.state = false
			print("")
			return box.txt
		else
			box.update(unpack(e))
			box.state = true
			box.render()
		end
	end
end

return input