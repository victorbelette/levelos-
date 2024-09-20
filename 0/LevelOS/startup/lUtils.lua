-- LevelOS Utils

if not unpack then
	_G.unpack = table.unpack
end

local write = term.write

if _G.lUtils == nil then
	_G.lUtils = {}
end


if _G.lOS == nil then
	_G.lOS = {}
end

function lUtils.RGBToGrayscale( r, g, b )
	local gr = (r + g + b) / 3
	return gr,gr,gr
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

function lUtils.wordwrap(txt,width)
	if not txt then
		error("No text given",2)
	end
	local lines = {}
	for line in txt:gmatch("([^\n]*)\n?") do
		table.insert(lines,"")
		for word in line:gmatch("%S*%s?") do
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
	return lines
end

function lUtils.input(x1,y1,x2,y2,tOptions,sReplaceChar,tShape)
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
		local rtype = rtype
		if not rtype then
			rtype = type
		end
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
					elseif type(v) == "string" or type(v) == "number" or type(v) == "boolean" or type(v) == "nil" then
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
							local vArgs = lUtils.instantiate(v.args)
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
				list[t].lines = lUtils.wordwrap(list[t].description,width-4)
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
		abbrevs = {table={"tbl",colors.lime},number={"num",colors.purple},boolean={"bln",colors.purple},["function"]={"fnc",colors.cyan},keyword={"   ",colors.orange},["nil"]={"nil",colors.red},unknown={"???",colors.pink},string={"str",colors.yellow}}
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
			x2 = x1+width-1
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
			blit[3] = ""
			_G.debugsublines = sublines
			for l=1,#sublines do
				local elements = sublines[l]
				for t=1,#elements do
					local col
					local col2 = lUtils.toBlit(s.color)
					if type(syntax[elements[t].type]) == "table" then
						col, col2 = lUtils.toBlit(syntax[elements[t].type][1] or s.txtcolor), lUtils.toBlit(syntax[elements[t].type][2] or s.color)
					else
						col = lUtils.toBlit(syntax[elements[t].type] or s.txtcolor)
					end
					blit[1] = blit[1]..elements[t].data
					blit[2] = blit[2]..string.rep(col,#elements[t].data)
					blit[3] = blit[3]..string.rep(col2,#elements[t].data)
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
					blit[3] = blit[3].."\n"
				end
			end
			_G.debugBlit2 = {blit[1],blit[2],blit[3]}
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
					local blit3 = blit[3]
					if not s.opt.tabSize then
						s.opt.tabSize = 4
					end
					local t = s.opt.tabSize
					while findTab do
						local l = t-(findTab-1)%t
						dl[c] = replaceText(dl[c],findTab,findTab,string.sub(s.opt.indentChar..string.rep(" ",t-#s.opt.indentChar),t-l+1,t))
						local col, col2
						if type(syntax.whitespace) == "table" then
							col = lUtils.toBlit(syntax.whitespace[1] or s.txtcolor)
							col2 = lUtils.toBlit(syntax.whitespace[2] or s.color)
						else
							col = lUtils.toBlit(syntax.whitespace or s.txtcolor)
							col2 = lUtils.toBlit(s.color)
						end
						blit2 = replaceText(blit2,findTab,findTab,string.rep(col,l))
						blit3 = replaceText(blit3,findTab,findTab,string.rep(col2,l))
						findTab = dl[c]:find("\t")
					end
					local tabArea = string.rep(" ",t)
					local findSpace,findSpace2 = dl[c]:find(tabArea)
					while findSpace do
						dl[c] = replaceText(dl[c],findSpace,findSpace2,s.opt.indentChar..string.rep(" ",t-#s.opt.indentChar))
						findSpace,findSpace2 = dl[c]:find(tabArea,findSpace2+1)
					end
					dl[c] = dl[c]:sub(1+s.scrollX,width+s.scrollX)
					s.blit[c] = {dl[c],blit2:sub(b+s.scrollX,b+s.scrollX+(#dl[c]-1)),blit3:sub(b+s.scrollX,b+s.scrollX+(#dl[c]-1))}
					blit[1] = blit[1]:sub(e+1,#blit[1])
					blit[2] = blit[2]:sub(e+1,#blit[2])
					blit[3] = blit[3]:sub(e+1,#blit[3])
				else
					dl[c] = line:sub(1+s.scrollX,width+s.scrollX)
					s.blit[c] = {dl[c],string.rep(lUtils.toBlit(s.txtcolor),#dl[c]),string.rep(lUtils.toBlit(s.color),#dl[c])}
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
				local c = lUtils.toBlit(s.opt.selectColor or colors.blue)
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
					local c2 = lUtils.toBlit(s.opt.selectTxtColor)
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
		if s.opt.complete and s.opt.complete.LevelOS and s.opt.complete.LevelOS.self.window.events == "all" and e[1]:find("mouse") and type(e[3]) == "number" and type(e[4]) == "number" then
			local wX,wY = s.opt.complete.LevelOS.self.window.win.getPosition()
			e[3] = e[3]-(wX-1)
			e[4] = e[4]-(wY-1)
		end
		if e[1] == "mouse_click" and s.opt.complete and s.opt.complete.list and #s.opt.complete.list > 0 and not lUtils.isInside(e[3],e[4],s.opt.complete.list) then
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
				if (e[3] < s.x1 or e[3] > s.x2 or e[4] < s.y1 or e[4] > s.y2) and not (s.opt.complete and s.opt.complete.list and #s.opt.complete.list > 0 and lUtils.isInside(e[3],e[4],s.opt.complete.list)) then -- add support for autocomplete click
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
				if lUtils.isHolding(keys.leftCtrl) and dirs[e[2]] then
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
					if lUtils.isHolding(keys.leftCtrl) then
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
					if lUtils.isHolding(keys.leftCtrl) then
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
				elseif (lUtils.isHolding(keys.leftCtrl) and (e[2] == keys.leftBracket or e[2] == keys.rightBracket)) or (s.select and e[2] == keys.tab) then
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
				elseif lUtils.isHolding(keys.leftCtrl) then
					if e[2] == keys.z then
						undo()
					elseif e[2] == keys.y then
						redo()
					elseif e[2] == keys.a then
						s.select = {1,#s.txt}
						s.cursor.a = #s.txt+1
						rAll()
					elseif (e[2] == keys.c or e[2] == keys.x) and s.select then
						local txt = s.txt:sub(s.select[1],s.select[2])
						if ccemux then
							ccemux.setClipboard(txt)
							lOS.clipboard = txt
						else
							s.clipboard = txt
						end
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
				if s.clipboard then
					txt = s.clipboard
				elseif lOS.clipboard then
					local nline = lOS.clipboard:find("(.)\n") or #lOS.clipboard
					local checkCB = lOS.clipboard:sub(1,nline):gsub("\t","")
					if txt == checkCB then
						txt = lOS.clipboard
					end
				end
				addText(txt)
				addUndo(e[1])
			elseif s.opt.complete and s.opt.complete.list and #s.opt.complete.list > 0 and s.opt.complete.selected and (e[1] == "mouse_click" or e[1] == "mouse_scroll" or e[1] == "mouse_up") and lUtils.isInside(e[3],e[4],s.opt.complete.list) then
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
						if x > #s.dLines[y]+scrollX then
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
				if x > #s.dLines[y]+scrollX then
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
			if lUtils.isInside(x,y,s) then
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

function lUtils.read(_sReplaceChar)
	local x1,y1 = term.getCursorPos()
	local x2,_ = term.getSize()
	local box = lUtils.input(x1,y1,x2,y1,{overflowX="scroll",overflowY="none",replaceChar=_sReplaceChar})
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

local animationTbl = {}
lUtils.debugAnimationTbl = animationTbl
function lUtils.renderImg(spr,x,y,format,transparency)
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
				bl[2] = string.gsub(spr[l][2]:gsub(" ","T"),"T",lUtils.toBlit(term.getBackgroundColor()))
				bl[3] = string.gsub(spr[l][3]:gsub(" ","T"),"T",lUtils.toBlit(term.getBackgroundColor()))
			end
			if #bl[1] ~= #bl[2] or #bl[2] ~= #bl[3] then
				_G.debugblitthingy = bl
				if #bl[2] > #bl[1] then
					bl[2] = bl[2]:sub(1, #bl[1])
				elseif #bl[2] < #bl[1] then
					bl[2] = bl[2]..string.rep(lUtils.toBlit(term.getBackgroundColor()), #bl[1]-#bl[2])
				end
				if #bl[3] > #bl[2] then
					bl[3] = bl[3]:sub(1, #bl[2])
				elseif #bl[3] < #bl[2] then
					bl[3] = bl[3]..string.rep(lUtils.toBlit(term.getBackgroundColor()), #bl[2]-#bl[3])
				end
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


function lUtils.getDrawingCharacter(...)
	local e=0
	local arg = {...}
	for t=1,5 do
		if arg[t] then
			e=e+2^(t-1)
		end
	end
	return {char = string.char(arg[6] and 159-e or 128+e), inverted = not not arg[6]}
end

lUtils.asset = {}
function lUtils.asset.load(filename)
	if filename and type(filename) == "string" and fs.exists(filename) and not fs.isDir(filename) then
		local ft = lUtils.getFileType(filename)
		if ft == ".limg" or ft == ".bimg" or ft == ".lconf" then
			local contents = lUtils.fread(filename, true)
			local decodedText = ""
			for _, codepoint in utf8.codes(contents) do
				decodedText = decodedText .. string.char(codepoint)
			end
			local data = textutils.unserialize(decodedText)
			local oterm = term.current()
			local trashwin = window.create(term.current(), 1, 1, 51, 19, false)
			term.redirect(trashwin)
			local ok, _ = pcall(lUtils.renderImg, data)
			term.redirect(oterm)
			if ((ft == ".limg" or ft == ".bimg") and not ok) then
				return textutils.unserialize(contents)
			else
				return data
			end
		end
		return textutils.unserialize(lUtils.fread(filename))
	else
		return false
	end
end


function lUtils.asset.save(asset,filename,compact)
	if compact == nil then compact = true end
	if type(asset) == "table" and not fs.isDir(filename) then
		local ok,output = pcall(textutils.serialize,asset,{compact=compact})
		if not ok then
			error(output,2)
		end
		return lUtils.fwrite(filename,output)
	else
		return false
	end
end


function lUtils.HSVToRGB( hue, saturation, value )
	-- Returns the RGB equivalent of the given HSV-defined color
	-- (adapted from some code found around the web)

	-- If it's achromatic, just return the value
	hue = hue%360
	if saturation == 0 then
		return value,value,value
	end

	-- Get the hue sector
	local hue_sector = math.floor( hue / 60 )
	local hue_sector_offset = ( hue / 60 ) - hue_sector

	local p = value * ( 1 - saturation )
	local q = value * ( 1 - saturation * hue_sector_offset )
	local t = value * ( 1 - saturation * ( 1 - hue_sector_offset ) )

	if hue_sector == 0 then
		return value, t, p
	elseif hue_sector == 1 then
		return q, value, p
	elseif hue_sector == 2 then
		return p, value, t
	elseif hue_sector == 3 then
		return p, q, value
	elseif hue_sector == 4 then
		return t, p, value
	elseif hue_sector == 5 then
		return value, p, q
	end
end


function lUtils.RGBToHSV( red, green, blue )

	local hue, saturation, value

	local min_value = math.min( red, green, blue )
	local max_value = math.max( red, green, blue )

	value = max_value

	local value_delta = max_value - min_value

	-- If the color is not black
	if max_value ~= 0 then
		saturation = value_delta / max_value

	-- If the color is purely black
	else
		saturation = 0
		hue = -1
		return hue, saturation, value
	end

	if red == max_value then
		hue = ( green - blue ) / value_delta
	elseif green == max_value then
		hue = 2 + ( blue - red ) / value_delta
	else
		hue = 4 + ( red - green ) / value_delta
	end

	hue = hue * 60
	if hue < 0 then
		hue = hue + 360
	end

	return hue, saturation, value
end


lUtils.graphics = {}
local g = lUtils.graphics
function g.button(txt,x1,y1,x2,y2,func,border,fg1,bg1,fg2,bg2,bcolor)
	if not y2 then
		return nil
	end
	if not bg1 then
		bg1 = colors.black
	end
	if not fg1 then
		fg1 = colors.white
	end
	if not bcolor then
		bcolor = colors.gray
	end
	if not fg2 then
		fg2 = fg1
	end
	if not bg2 then
		bg2 = colors.gray
	end
	if not border then
		border = true
	end
	local btn = {txt=txt,x1=x1,y1=y1,x2=x2,y2=y2,func=func,border=border,selected=false,colors={bg1=bg1,fg1=fg1,bg2=bg2,fg2=fg2,border=bcolor}}
	function btn.render(...)
		local e = {...}
		local selected = false
		--term.setTextColor(colors.fg1)
		--term.setBackgroundColor(colors.bg1)
		local abc = {}
		if e[1] == "mouse_click" or e[1] == "mouse_up" then
			if e[3] >= btn.x1 and e[4] >= btn.y1 and e[3] <= btn.x2 and e[4] <= btn.y2 then
				if e[1] == "mouse_click" then
					btn.selected = true
				elseif e[1] == "mouse_up" then
					if not btn.func then
						abc[1] = true
					else
						abc = {btn.func()}
					end
				end
			end
		end
		if e[1] == "mouse_up" then
			btn.selected = false
		end
		if btn.selected then
			term.setBackgroundColor(btn.colors.bg2)
		else
			term.setBackgroundColor(btn.colors.bg1)
		end
		term.setTextColor(btn.colors.border)
		if btn.border == true then
			lUtils.border(btn.x1,btn.y1,btn.x2,btn.y2)
		else
			lOS.boxClear(btn.x1,btn.y1,btn.x2,btn.y2)
		end
		if btn.selected then
			term.setTextColor(btn.colors.fg2)
		else
			term.setTextColor(btn.colors.fg1)
		end
		lUtils.textbox(btn.txt,btn.x1+1,btn.y1+1,btn.x2-1,btn.y2-1)
		return unpack(abc)
	end
	return btn
end


function lOS.boxClear(tx1,ty1,tx2,ty2)
	local x1,y1,x2,y2 = tx1,ty1,tx2,ty2
	if x1 > x2 then
		x2,x1 = x1,x2
	end
	if y1 > y2 then
		y2,y1 = y1,y2
	end
	clearline = ""
	for t=x1,x2 do
		clearline = clearline.." "
	end
	for l=y1,y2 do
		term.setCursorPos(x1,l)
		term.write(clearline)
	end
end


local function run2( _tEnv, _sPath, ... )
	local tArgs = table.pack( ... )
	local tEnv = _tEnv
	setmetatable( tEnv, { __index = _G } )
	local fnFile,err
	if fs.exists("window") then
		fnFile, err = loadfile( _sPath, tEnv )
	else
		fnFile, err = loadfile( _sPath, nil, tEnv )
	end
	if fnFile then
		local returned = {pcall( function()
			return table.unpack({fnFile( table.unpack( tArgs, 1, tArgs.n ) )})
		end )}
		local ok, err = returned[1],returned[2]
		table.remove(returned,1)
		if not ok then
			table.remove(returned,1)
			if err and err ~= "" then
				--printError( err )
			end
			return false,err,table.unpack(returned)
		end
		return true,table.unpack(returned)
	end
	if err and err ~= "" then
		--printError( err )
	end
	return false,err
end



local function createShellEnv( sDir , tWindow , sPath)
	local tEnv = {}
	tEnv[ "shell" ] = lUtils.instantiate(shell)
	if sPath then
		tEnv.shell.getRunningProgram = function() return sPath end
	end
	tEnv[ "multishell" ] = multishell

	local package = {}
	package.loaded = {
		_G = _G,
		bit32 = bit32,
		coroutine = coroutine,
		math = math,
		package = package,
		string = string,
		table = table,
	}
	package.path = "?;?.lua;?/init.lua;/rom/modules/main/?;/rom/modules/main/?.lua;/rom/modules/main/?/init.lua;/LevelOS/modules/?.lua;/LevelOS/modules/?/init.lua"
	if turtle then
		package.path = package.path..";/rom/modules/turtle/?;/rom/modules/turtle/?.lua;/rom/modules/turtle/?/init.lua"
	elseif command then
		package.path = package.path..";/rom/modules/command/?;/rom/modules/command/?.lua;/rom/modules/command/?/init.lua"
	end
	package.config = "/\n;\n?\n!\n-"
	package.preload = {}
	package.loaders = {
		function( name )
			if package.preload[name] then
				return package.preload[name]
			else
				return nil, "no field package.preload['" .. name .. "']"
			end
		end,
		function( name )
			local fname = string.gsub(name, "%.", "/")
			local sError = ""
			for pattern in string.gmatch(package.path, "[^;]+") do
				local sPath = string.gsub(pattern, "%?", fname)
				if sPath:sub(1,1) ~= "/" then
					sPath = fs.combine(sDir, sPath)
				end
				if fs.exists(sPath) and not fs.isDir(sPath) then
					local fnFile, sError = loadfile( sPath, tEnv )
					if fnFile then
						return fnFile, sPath
					else
						return nil, sError
					end
				else
					if #sError > 0 then
						sError = sError .. "\n"
					end
					sError = sError .. "no file '" .. sPath .. "'"
				end
			end
			return nil, sError
		end
	}

	local sentinel = {}
	local function require( name )
		if type( name ) ~= "string" then
			error( "bad argument #1 (expected string, got " .. type( name ) .. ")", 2 )
		end
		if package.loaded[name] == sentinel then
			error("Loop detected requiring '" .. name .. "'", 0)
		end
		if package.loaded[name] then
			return package.loaded[name]
		end

		local sError = "Error loading module '" .. name .. "':"
		for n,searcher in ipairs(package.loaders) do
			local loader, err = searcher(name)
			if loader then
				package.loaded[name] = sentinel
				local result = loader( err )
				if result ~= nil then
					package.loaded[name] = result
					return result
				else
					package.loaded[name] = true
					return true
				end
			else
				sError = sError .. "\n" .. err
			end
		end
		error(sError, 2)
	end

	tEnv["package"] = package
	tEnv["require"] = require

	tEnv["LevelOS"] = {self={window=tWindow}}

	local lAPI = tEnv["LevelOS"]
	--local s = tEnv["shell"]
	--local ms = tEnv["multishell"]
	--TEMP DISABLED
	local s = {}
	local ms = {}

	
	
	if not lOS.oldterm then
		lOS.oldterm = oldterm
		if not oldterm then
			lOS.oldterm = term.native() -- DANGEROUS
		end
	end
	local w,h = lOS.oldterm.getSize()
	if tWindow ~= nil and lOS.wins ~= nil then
		local win = tWindow
		local function setWin( x, y, width, height, mode )
			local x,y,width,height,mode = x, y, width, height, mode
			if type(x) == "string" then
				mode = x
				x,y = win.win.getPosition()
				width,height = win.win.getSize()
			elseif type(width) ~= "number" then
				width,height,mode = x,y,width
				x,y = win.win.getPosition()
			end
			win.win.reposition(x,y,width,height)
			os.queueEvent("term_resize")
			if mode then
				if mode ~= "background" and win.winMode == "background" then
					local pID
					for p=1,#lOS.processes do
						if lOS.processes[p] == win then
							pID = p
							break
						end
					end
					if pID then
						os.queueEvent("window_open",pID,tostring(win))
					end
				elseif mode == "background" and win.winMode ~= "background" then
					local wID
					for i=1,#lOS.wins do
						if lOS.wins[i] == win then
							wID = i
							break
						end
					end
					if wID then
						os.queueEvent("window_close",wID,tostring(win))
					end
				end
				win.winMode = mode
			end
		end
		local function pullEvent()
			win.events = "all"
			local e = {os.pullEventRaw()}
			win.events = "default"
			return table.unpack(e)
		end
		local function setTitle(title)
			if type(title) == "string" and title ~= "" then
				win.title = title
				return true
			else
				return false
			end
		end
		local function maximize()
			if win.win ~= nil then
				local w,h = lOS.wAll.getSize()
				local off = 0
				if win.winMode == "windowed" then
					off = 1
				end
				win.snap = {x=true,y=true,oPos={win.win.getPosition()},oSize={win.win.getSize()}}
				win.win.reposition(1,1+off,w,h-lOS.tbSize-off)
				return true
			end
			return false
		end
		local function minimize()
			os.queueEvent("window_minimize",lOS.cWin,tostring(tWindow))
		end
		local function focus()
			for k,v in pairs(lOS.processes) do
				if v == win then
					os.queueEvent("window_focus",k,tostring(v))
					break
				end
			end
		end
		lAPI.pullEvent = pullEvent
		lAPI.setWin = setWin
		lAPI.setTitle = setTitle
		lAPI.maximize = maximize
		lAPI.minimize = minimize
		lAPI.focus = focus
		tWindow.env = tEnv
		local srun = tEnv.shell.run
		
		function ms.launch(env, path, ...)
			local args = {...}
			local function func(win)
				local oEnv = createShellEnv(fs.getDir(path),win)
				env["LevelOS"] = oEnv["LevelOS"]
				return run2(env, path, table.unpack(args))
			end
			lOS.newWin(func,path)
		end

		function ms.getCount()
			return #lOS.wins
		end

		function ms.setTitle(n, title)
			lOS.wins[n].title = title
		end

		function ms.setFocus(n)
			if n >= 1 and n <= #lOS.wins then
				local w = lOS.wins[n]
				table.remove(lOS.wins,n)
				table.insert(lOS.wins,w)
				return true
			else
				return false
			end
		end

		function ms.getTitle(n)
			if n >= 1 and n <= #lOS.wins then
				return lOS.wins[n].title
			end
		end

		function s.execute(command, ...)

			local sPath = s.resolveProgram(command)
			if sPath ~= nil then
				local sTitle = lUtils.getFileName(sPath)
				sTitle = (sTitle:gsub("^%l", string.upper))
				lAPI.setTitle(sTitle)

				local sDir = fs.getDir(sPath)
				local env = createShellEnv(sDir,lAPI.self.window)
				env.arg = { [0] = command, ... }
				local result = run2(env, sPath, ...)

				return result
			else
				printError("No such program")
				return false
			end
		end
		
		--function tEnv.shell.run(...)
			--if ({...})[2] and fs.exists(({...})[2]) then
				--setTitle(lUtils.getFileName(({...})[1]).." - "..lUtils.getFileName(({...})[2]))
			--else
				--setTitle(lUtils.getFileName(({...})[1]))
			--end
			--srun(...)
		--end

		-- do the above once we port everything to lOS.run
		
	end

	return tEnv
end


lOS.createShellEnv = createShellEnv




lUtils.shapescape = {}

if true then
	local shape = lUtils.shapescape

	function shape.createRectangle(x1,y1,x2,y2,fillColor,borderColor)
		local sCol = {fillColor or term.getBackgroundColor(),borderColor or 0}
		local tObj = {event={mouse_click={function() end,-1},mouse_up={function() end,-1},focus={function() end,-1},update={function() end,-1},render={function() end,-1},Coroutine={function() end,-1}},type="rect",color=sCol[1],border={type=1,color=sCol[2]},x1=x1,y1=y1,x2=x2,y2=y2}
		--slide.objs[#slide.objs+1] = tObj
		local w,h = term.getSize()
		lUtils.shapescape.renderSlide({win=window.create(term.current(),1,1,w,h,false),objs={tObj}})
		return tObj
	end


	function shape.createText(txt,x1,y1,x2,y2,fillColor,borderColor,textColor)
		local tObj = shape.createRectangle(x1,y1,x2,y2,fillColor or 0,borderColor or 0)
		tObj.type = "text"
		tObj.txtcolor = textColor or term.getTextColor()
		tObj.txt = txt
		return tObj
	end


	function shape.createWindow(x1,y1,x2,y2)
		local tObj = shape.createRectangle(x1,y1,x2,y2)
		tObj.type = "window"
		tObj.color = colors.black
		tObj.border.color = 0
		tObj.render = nil
		tObj.update = nil
		local w,h = term.getSize()
		lUtils.shapescape.renderSlide({win=window.create(term.current(),1,1,w,h,false),objs={tObj}})
		return tObj
	end

	function shape.createInputbox(x1,y1,x2,y2,fillColor,borderColor,textColor)
		local tObj = shape.createText("",x1,y1,x2,y2,fillColor,0,textColor)
		tObj.type = "input"
		return tObj
	end
end


local align = {}
function align.left(slide,offset)
	local w,h = term.getSize()
	return offset
end
function align.right(slide,offset)
	local w,h = term.getSize()
	return w-offset
end
function align.top(slide,offset)
	local w,h = term.getSize()
	return offset
end
function align.bottom(slide,offset)
	local w,h = term.getSize()
	return h-offset
end
function align.center(slide,offset,vert)
	local w,h = term.getSize()
	if vert then
		return math.ceil(h/2)-offset
	else
		return math.ceil(w/2)-offset
	end
end


local generic = {}

function generic.align(obj)
	--if obj.ox1 == nil or obj.oy1 == nil then
		--obj.ox1,obj.oy1,obj.ox2,obj.oy2 = obj.x1,obj.y1,obj.x2,obj.y2
	--end
	local w,h = term.getSize()
	if obj.snap.Left == "Snap right" then
		if not obj.ox1 then
			obj.ox1 = w-obj.x1
		end
		obj.x1 = align.right(slide,obj.ox1)
	elseif obj.snap.Left == "Snap center" then
		if not obj.ox1 then
			obj.ox1 = math.ceil(w/2)-obj.x1
		end
		obj.x1 = align.center(slide,obj.ox1)
	else
		obj.ox1 = nil
	end
	if obj.snap.Right == "Snap right" then
		if not obj.ox2 then
			obj.ox2 = w-obj.x2
		end
		obj.x2 = align.right(slide,obj.ox2)
	elseif obj.snap.Right == "Snap center" then
		if not obj.ox2 then
			obj.ox2 = math.ceil(w/2)-obj.x2
		end
		obj.x2 = align.center(slide,obj.ox2)
	else
		obj.ox2 = nil
	end
	if obj.snap.Top == "Snap bottom" then
		if not obj.oy1 then
			obj.oy1 = h-obj.y1
		end
		obj.y1 = align.bottom(slide,obj.oy1)
	elseif obj.snap.Top == "Snap center" then
		if not obj.oy1 then
			obj.oy1 = math.ceil(h/2)-obj.y1
		end
		obj.y1 = align.center(slide,obj.oy1,true)
	else
		obj.oy1 = nil
	end
	if obj.snap.Bottom == "Snap bottom" then
		if not obj.oy2 then
			obj.oy2 = h-obj.y2
		end
		obj.y2 = align.bottom(slide,obj.oy2)
	elseif obj.snap.Bottom == "Snap center" then
		if not obj.oy2 then
			obj.oy2 = math.ceil(h/2)-obj.y2
		end
		obj.y2 = align.center(slide,obj.oy2,true)
	else
		obj.oy2 = nil
	end
end


function lUtils.shapescape.addScript(tShp,id,ev,assets,LevelOS,slides)
	if not tShp.event then
		tShp.event = {}
	end
	
	-- run script with environment
	local function getEnv(tShape)
		local tempWin
		if LevelOS then
			tempWin = LevelOS.self.window
		end
		local tEnv = createShellEnv("",tempWin)
		if LevelOS then
			tEnv.LevelOS = LevelOS
		end
		setmetatable(tEnv,{__index=_G})
		tEnv.self = tShape
		return tEnv
	end
	local function getSlide()
		return slides[slides.cSlide]
	end
	local function getSlides()
		return slides
	end
	local function setSlide(n)
		if slides[n] then
			slides.cSlide = n
			os.queueEvent("shapescape_change_slide")
			os.pullEvent()
			return true
		else
			return false
		end
	end
	local function exit(...)
		slides.stop = true
		slides["return"] = {...}
	end
	local getEvent = function() return end
	local tEnv = getEnv(tShp)
	tEnv.shapescape = {getEvent=getEvent,getSlide=getSlide,getSlides=getSlides,setSlide=setSlide,exit=exit}
	tShp.tEnv = tEnv
	local sFunc,err = load(assets[id].content,"@"..assets[id].name,"bt",tEnv)
	if not sFunc then
		function sFunc() printError(err) end
	end
	if ev == "Coroutine" and tShp.type == "window" then
		tShp.event[ev] = {function(tShape,e,...) tShape.tEnv.shapescape.getEvent = function() return unpack(e) end local ok,err = pcall(sFunc,...) if not ok then print(err) end end,id}
	else
		tShp.event[ev] = {function(tShape,e,...) tShape.tEnv.shapescape.getEvent = function() return unpack(e) end local ok,err = pcall(sFunc,...) if not ok then lUtils.popup("Error",err,31,11,{"OK"}) end end,id}
	end
end

function lUtils.shapescape.renderSlide(slide,static,args)
	local oterm = term.current()
	term.redirect(slide.win)
	term.setBackgroundColor(colors.white)
	term.clear()
	local cursor
	for o=1,#slide.objs do
		--[[if slide.objs[o].snap then
			generic.align(slide.objs[o])
		end]]
		if slide.objs[o].type == "rect" or slide.objs[o].type == "text" or slide.objs[o].type == "window" or slide.objs[o].type == "input" then
			local s = slide.objs[o]
			if not slide.objs[o].render then
				local self = slide.objs[o]
				if slide.objs[o].type == "window" then
					if not static then
						function self.render()
							local restore = cRestore()
							if self.snap then
								generic.align(self)
							end
							if self.color ~= 0 then
								if not self.window then
									self.window = window.create(term.current(),self.x1,self.y1,(self.x2-self.x1)+1,(self.y2-self.y1)+1,false)
								end
								local x,y = self.window.getPosition()
								local w,h = self.window.getSize()
								if x ~= self.x1 or y ~= self.y1 or w ~= (self.x2-self.x1)+1 or h ~= (self.y2-self.y1)+1 then
									self.window.reposition(self.x1,self.y1,(self.x2-self.x1)+1,(self.y2-self.y1)+1)
								end
								for l=1,(self.y2-self.y1)+1 do
									term.setCursorPos(self.x1,self.y1+(l-1))
									term.blit(self.window.getLine(l))
								end
							end
							cRestore(restore)
						end
					else
						local lines
						local function genLines()
							lines = {}
							--[[local fg = lUtils.toBlit(self.color or colors.white)
							local bg = lUtils.toBlit(self.color or colors.white)]]
							local fg,bg
							if self.color ~= colors.black then
								fg = lUtils.toBlit(self.color)
								bg = lUtils.toBlit(self.border.color ~= nil and self.border.color or colors.black)
								if bg == nil then
									bg = lUtils.toBlit(colors.black)
								end
							else
								fg = lUtils.toBlit(self.color)
								bg = lUtils.toBlit(self.border.color ~= nil and self.border.color or colors.white)
								if bg == nil then
									bg = lUtils.toBlit(colors.white)
								end
							end
							for y=self.y1,self.y2 do
								lines[#lines+1] = {"","",""}
								for x=self.x1,self.x2 do
									lines[#lines][1] = lines[#lines][1]..string.char(math.random(129,159))
									if math.random(1,2) == 2 then
										lines[#lines][2] = lines[#lines][2]..bg
										lines[#lines][3] = lines[#lines][3]..fg
									else
										lines[#lines][2] = lines[#lines][2]..fg
										lines[#lines][3] = lines[#lines][3]..bg
									end
								end
							end
						end
						genLines()
						local x1,y1,x2,y2 = self.x1,self.y1,self.x2,self.y2
						local c1,c2 = self.color,self.border.color
						function self.render()
							if self.snap then
								generic.align(self)
							end
							if x1 ~= self.x1 or y1 ~= self.y1 or x2 ~= self.x2 or y2 ~= self.y2 or c1 ~= self.color or c2 ~= self.border.color then
								x1,y1,x2,y2 = self.x1,self.y1,self.x2,self.y2
								c1,c2 = self.color,self.border.color
								genLines()
							end
							for l=1,#lines do
								term.setCursorPos(self.x1,self.y1+(l-1))
								term.blit(unpack(lines[l]))
							end
						end
					end
				else
					function self.render()
						local restore = cRestore()
						if self.snap then
							generic.align(self)
						end
						if self.color ~= 0 then
							term.setBackgroundColor(self.color)
							--term.setCursorPos(self.x1,self.y1)
							for y=self.y1,self.y2 do
								term.setCursorPos(self.x1,y)
								term.write(string.rep(" ",self.x2-(self.x1-1)))
							end
							--lOS.boxClear(self.x1,self.y1,self.x2,self.y2)
						end
						if self.border and self.border.color ~= 0 then
							term.setTextColor(self.border.color)
							lUtils.border(self.x1,self.y1,self.x2,self.y2,"transparent")
						end
						if self.image then
							if self.border and self.border.color ~= 0 then
								lUtils.renderImg(self.image,self.x1+1,self.y1+1,nil,true)
							else
								lUtils.renderImg(self.image,self.x1,self.y1,nil,true)
							end
						end
						if self.type == "input" then
							-- gen shape and make it provide shape
							if not self.fRender then
								lUtils.input(self.x1,self.y1,self.x2,self.y2,nil,nil,self)
							end
							self.fRender()
						elseif self.txt then
							if self.color == 0 then
								term.setBackgroundColor(colors.white)
							else
								term.setBackgroundColor(self.color)
							end
							term.setTextColor(self.txtcolor)
							term.setCursorPos(1,1)
							if self.border and self.border.color ~= 0 and self.y2 >= self.y1+2 then
								lUtils.textbox(self.txt,self.x1+1,self.y1+1,self.x2-1,self.y2-1,true)
							else
								if static and self.txt == "" and not self.input then
									lUtils.textbox("...",self.x1,self.y1,self.x2,self.y2,true)
								else
									lUtils.textbox(self.txt,self.x1,self.y1,self.x2,self.y2,true)
								end
							end
						end
						if not self.state then
							cRestore(restore)
						end
					end
				end
			end
			s.render()
			if not static and s.event and s.event.render and s.event.render[1] then
				s.event.render[1](s,nil,args)
			end
			if not slide.objs[o].update then
				local self = slide.objs[o]
				function self.update(args,...)
					-- continue this
					local e = {...}
					if e[1] == "mouse_click" or e[1] == "mouse_up" then
						if e[3] >= self.x1 and e[4] >= self.y1 and e[3] <= self.x2 and e[4] <= self.y2 then
							if self.event[e[1]] and self.event[e[1]][1] then
								self.event[e[1]][1](self,e,table.unpack(args))
							end
						end
						if e[1] == "mouse_up" and self.selected then
							self.selected = false
						end
					end
					if self.event.update then
						-- dt when i can
						self.event.update[1](self,e,table.pack(args))
					end
					if not self.coroutine and self.event.Coroutine[2] >= 0 then
						self.coroutine = coroutine.create(function() self.event.Coroutine[1](self,{},table.unpack(args)) end)
					end
					if self.coroutine then
						local oterm = term.current()
						if self.window then
							if self.snap then
								generic.align(self)
							end
							local x,y = self.window.getPosition()
							local w,h = self.window.getSize()
							if x ~= self.x1 or y ~= self.y1 or w ~= (self.x2-self.x1)+1 or h ~= (self.y2-self.y1)+1 then
								self.window.reposition(self.x1,self.y1,(self.x2-self.x1)+1,(self.y2-self.y1)+1)
							end
							term.redirect(self.window)
							if string.find(e[1],"mouse") and e[3] and e[4] and not (self.tEnv and self.tEnv.LevelOS and self.tEnv.LevelOS.self and self.tEnv.LevelOS.self.window and self.tEnv.LevelOS.self.window.events == "all") then
								e[3] = e[3]-(self.x1-1)
								e[4] = e[4]-(self.y1-1)
							end
						end
						coroutine.resume(self.coroutine,unpack(e))
						-- if blink was enabled set cursor back to this window after everything blablabla
						term.redirect(oterm)

					end
					if self.type == "input" then
						if not self.fUpdate then
							lUtils.input(self.x1,self.y1,self.x2,self.y2,nil,nil,nil,self)
						end
						self.fUpdate(...)
					end
				end
			end
		elseif slide.objs[o].type == "triangle" then

		end
		if not slide.objs[o].remove then
			local self = slide.objs[o]
			local sl = slide
			slide.objs[o].remove = function()
				for s=1,#sl.objs do
					if sl.objs[s] == self then
						sl.objs[s] = nil
						return true
					end
				end
			end
		end
	end
	term.redirect(oterm)
end

function lUtils.shapescape.run(slides,...)
	local args = table.pack(...)
	local oterm = term.current()
	if not slides.cSlide then
		slides.cSlide = 1
	end
	term.setBackgroundColor(colors.white)
	local cTerm = term.current()
	local sWin = window.create(cTerm,1,1,term.getSize())
	sWin.setVisible(false)
	--sWin.setVisible(false)
	sWin.setBackgroundColor(colors.white)
	sWin.setTextColor(colors.black)
	sWin.clear()
	slides[slides.cSlide].win = sWin
	--lUtils.shapescape.renderSlide(slides[slides.cSlide])
	local started = 0
	os.queueEvent("term_resize")
	while not slides.stop do
		local cursor
		local s = slides[slides.cSlide]
		local e
		if started < 2 then
			e = {"shapescape_start"}
			started = started+1
		else
			e = {os.pullEvent()}
		end
		sWin.reposition(1,1,term.getSize())
		local cSlide = slides.cSlide
		local oterm = term.current()
		local function ssUpdateFunc()
			for t=1,#s.objs do
				local o = s.objs[t]
				if o and o.update then
					local ok,err = pcall(function() o.update(args,unpack(e)) end)
					if not ok then
						error(err,0)
					end
					if o.window and o.window.getCursorBlink() == true then
						cursor = {pos={o.window.getCursorPos()},color=o.window.getTextColor()}
						cursor.pos[1] = o.x1+(cursor.pos[1]-1)
						cursor.pos[2] = o.y1+(cursor.pos[2]-1)
					end
				end
			end
		end
		local ssUpdate = coroutine.create(ssUpdateFunc)
		term.redirect(sWin)
		local ok,err = coroutine.resume(ssUpdate)
		if not ok then
			error(err,0)
		end
		while coroutine.status(ssUpdate) ~= "dead" do
			term.redirect(oterm)
			sWin.setVisible(true)
			sWin.setVisible(false)
			local e = {os.pullEvent()}
			term.redirect(sWin)
			coroutine.resume(ssUpdate,table.unpack(e))
		end
		if cSlide ~= slides.cSlide then
			-- fuck you bitchass cunt
			if not slides[slides.cSlide].win then
				local w,h = term.getSize()
				slides[slides.cSlide].win = window.create(cTerm,1,1,w,h,false)
			end
			sWin = slides[slides.cSlide].win
			term.redirect(sWin)
			lUtils.shapescape.renderSlide(slides[slides.cSlide])
		end
		term.setCursorBlink(false)
		lUtils.shapescape.renderSlide(s)
		if cursor then
			term.setCursorPos(unpack(cursor.pos))
			term.setTextColor(cursor.color)
			term.setCursorBlink(true)
		end
		-- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa it doesnt WORK
		term.redirect(oterm)
		sWin.setVisible(true)
		sWin.setVisible(false)
-- invis rendering during update broke eberythinf so now its notv invis
		--for t=1,({sWin.getSize()})[2] do
			--term.setCursorPos(1,t)
			--term.blit(sWin.getLine(t))
		--end
	end
	if not LevelOS then
		term.setBackgroundColor(colors.black)
		term.setTextColor(colors.white)
		term.clear()
		term.setCursorPos(1,1)
	end
	return unpack(slides["return"])
end
		

function lUtils.getArgs(fn)
	local args = {}
	local info = debug.getinfo(fn)
	for i=1, info.nparams do
		args[i] = debug.getlocal(fn,i) or "?"
	end
	if info.vararg then
		args[#args + 1] = "..."
	end
	return args
end


function lUtils.randStr(keyLength,num,symb)
	local upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local lowerCase = "abcdefghijklmnopqrstuvwxyz"
	local numbers = "0123456789"
	local symbols = "!@#$%&()*+-,./\\:;<=>?^[]{}"
	
	local characterSet = upperCase .. lowerCase
	if num then
		characterSet = characterSet..numbers
	end
	if symb then
		characterSet = characterSet..symbols
	end
	
	local output = ""
	
	for i = 1, keyLength do
		local rand = math.random(#characterSet)
		output = output .. string.sub(characterSet, rand, rand)
	end
	return output
end


function lUtils.logout()
	lOS.userID = nil
	lOS.username = nil
	if fs.exists("LevelOS/data/account2.txt") then
		fs.delete("LevelOS/data/account2.txt")
	end
	lOS.notification("You are now logged out of Leveloper Services.")
end

function lUtils.login(username,password,isToken,rememberme)
	local res,err
	local xtra = ""
	if isToken then
		res,err = http.post("https://os.leveloper.cc/auth.php","username="..textutils.urlEncode(username).."&token="..textutils.urlEncode(password))
	else
		if rememberme then
			xtra = "&rememberme=true"
		end
		res,err = http.post("https://os.leveloper.cc/auth.php","username="..textutils.urlEncode(username).."&password="..textutils.urlEncode(password)..xtra)
	end
	if res then
		local str = res.readAll()
		local oldstr = str
		str = lUtils.getField(str,"msg")
		if str:find("Welcome") then
			lUtils.fwrite("LevelOS/data/account.txt",username)
			if rememberme then
				local token = lUtils.getField(oldstr,"token")
				lUtils.fwrite("LevelOS/data/account2.txt",token)
			end
			local userID = res.getResponseHeaders()["Set-Cookie"]
			return userID,str
		else
			return nil,str
		end
	else
		return nil,err
	end
end


function lUtils.getField(thing,fieldname)
	if string.find(thing,"<"..fieldname..">",1,true) ~= nil and string.find(thing,"</"..fieldname..">",1,true) ~= nil then
		begin = nil
		ending = nil
		trash,begin = string.find(thing,"<"..fieldname..">",1,true)
		ending,ending2 = string.find(thing,"</"..fieldname..">",begin+1,true)
		if begin ~= nil and ending ~= nil then
			return string.sub(thing,begin+1,ending-1),string.sub(thing,1,trash-1)..string.sub(thing,ending2+1,string.len(thing))
		end
	end
	return nil,thing
end


function lUtils.compare(a, b)
  for k,v in pairs(a) do 
	if (type(v) == "table" and type(b[k]) == "table" and not lUtils.compare(b[k], v)) or b[k] ~= v then return false end 
  end
  for k,v in pairs(b) do 
	if (type(v) == "table" and type(a[k]) == "table" and not lUtils.compare(a[k], v)) or a[k] ~= v then return false end 
  end
  return true
end


function lUtils.centerText(text)
	local x,y = term.getSize()
	local x2,y2 = term.getCursorPos()
	term.setCursorPos(math.floor(x / 2 - text:len() / 2) + 1, y2)
	term.write(text)
end



function lUtils.outline(x1,y1,x2,y2)
	local c1 = term.getTextColor()
	local c2 = term.getBackgroundColor()
	term.setCursorPos(x1,y1)
	term.setBackgroundColor(c1)
	term.setTextColor(c2)
	local a
	for a=x1,x2 do
		term.write("\143")
	end
	for a=y1,y2 do
		term.setCursorPos(x1,y1-1+a)
		term.write("\149")
	end
	term.setBackgroundColor(c2)
	term.setTextColor(c1)
	for a=y1,y2 do
		term.setCursorPos(x2,y1-1+a)
		term.write("\149")
	end
	term.setCursorPos(x1,y2)
	for a=x1,x2 do
		term.write("\131")
	end
end



function lUtils.border(x1,y1,x2,y2,mode,layer)
	term.setCursorPos(x1,y1)
	local l = layer or 3
	local w,h = x2-(x1-1),y2-(y1-1)
	local bg,fg = term.getBackgroundColor(),term.getTextColor()
	local inved = false
	local function inv()
		if not inved then
			term.setBackgroundColor(fg)
			term.setTextColor(bg)
			inved = true
		else
			term.setBackgroundColor(bg)
			term.setTextColor(fg)
			inved = false
		end
	end
	local function setBG()
		if mode and mode == "transparent" then
			if not inved then
				term.setBackgroundColor(lUtils.toColor(({lUtils.getPixel(term.current(),term.getCursorPos())})[3]))
			else
				term.setTextColor(lUtils.toColor(({lUtils.getPixel(term.current(),term.getCursorPos())})[3]))
			end
		end
	end
	--[[local function setFG()
		if mode and mode == "transparent" then
			term.setTextColor(lUtils.toColor(({lUtils.getPixel(term.current(),term.getCursorPos())})[3]))
		end
	end]]
	if l == 1 then
		inv()
		setBG()
	else
		setBG()
	end
	if l == 2 then
		term.write("\156")
	elseif l == 3 then
	   term.write("\151")
	elseif l == 1 then
		term.write("\159")
	end
	if mode and mode == "transparent" then
		for x=1,w-2 do
			if l == 3 then
				setBG()
				term.write("\131")
			elseif l == 2 then
				setBG()
				term.write("\140")
			elseif l == 1 then
				setBG()
				term.write("\143")
			end
		end
	else
		if l == 3 then
			term.write(string.rep("\131",w-2))
		elseif l == 2 then
			term.write(string.rep("\140",w-2))
		elseif l == 1 then
			term.write(string.rep("\143",w-2))
		end
	end
	inv()
	if l == 1 then
		setBG()
	else
		setBG()
	end
	if l == 2 then
		term.write("\147")
	elseif l == 3 then
	   term.write("\148")
	elseif l == 1 then
		term.write("\144")
	end
	for y=y1+1,y2-1 do
		term.setCursorPos(x2,y)
		setBG()
		term.write("\149")
		inv()
		term.setCursorPos(x1,y)
		setBG()
		term.write("\149")
		if mode and mode == "fill" then
			term.write(string.rep(" ",w-2))
		end
		inv()
	end
	term.setCursorPos(x1,y2)
	if l == 3 then
	   setBG()
	   term.write("\138")
	elseif l == 2 then
		inv()
		setBG()
		term.write("\141")
	elseif l == 1 then
		setBG()
		term.write("\130")
	end
	if mode and mode == "transparent" then
		for x=1,w-2 do
			if l == 3 then
				setBG()
				term.write("\143")
			elseif l == 2 then
				setBG()
				term.write("\140")
			elseif l == 1 then
				setBG()
				term.write("\131")
			end
		end
	else
		if l == 3 then
			term.write(string.rep("\143",w-2))
		elseif l == 2 then
			term.write(string.rep("\140",w-2))
		elseif l == 1 then
			term.write(string.rep("\131",w-2))
		end
	end
	if l == 3 then
		setBG()
		term.write("\133")
		inv()
	elseif l == 2 then
		setBG()
		term.write("\142")
	elseif l == 1 then
		setBG()
		term.write("\129")
	end
end


function lUtils.spairs(t, order)
	-- collect the keys
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end

	-- if order function given, sort by it by passing the table and keys a, b,
	-- otherwise just sort the keys 
	if order then
		table.sort(keys, function(a,b) return order(t, a, b) end)
	else
		table.sort(keys)
	end

	-- return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end


function lUtils.splitStr(str,pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
	  if s ~= 1 or cap ~= "" then
		 table.insert(t,cap)
	  end
	  last_end = e+1
	  s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
	  cap = str:sub(last_end)
	  table.insert(t, cap)
   end
   return t
end



function lUtils.explorer(path,mode)
	if path == nil or path == "" then
		path = "/"
	end
	local title = "Explorer"
	if mode == "SelFile" then
		title = "Select File"
	elseif mode == "SelFolder" then
		title = "Select Folder"
	end
	local w,h = term.getSize()
	local eW,eH = math.ceil(math.min(w*0.75,w-3)),math.ceil(math.min(h*0.75,h-1))
	local a = {lUtils.openWin(title,"Program_Files/LevelOS/Explorer/main.lua "..path.." "..mode,math.ceil(w/2-eW/2),math.ceil(h/2-eH/2),eW,eH,true,false)}
	if a[1] == false then return false end
	table.remove(a,1)
	if type(a[1]) == "table" then
		a = a[1]
	end
	return table.unpack(a)
end



local to_colors, to_blit = {}, {}
for i = 1, 16 do
	to_blit[2^(i-1)] = ("0123456789abcdef"):sub(i, i)
	to_colors[("0123456789abcdef"):sub(i, i)] = 2^(i-1)
end



function lUtils.toColor(theblit)
	return to_colors[theblit] or nil
end



function lUtils.toBlit(thecolor)
	return to_blit[thecolor] or nil
end



function lUtils.instantiate(orig)
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



local function tokenise( ... )
	local sLine = table.concat( { ... }, " " )
	local tWords = {}
	local bQuoted = false
	for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
		if bQuoted then
			table.insert( tWords, match )
		else
			for m in string.gmatch( match, "[^ \t]+" ) do
				table.insert( tWords, m )
			end
		end
		bQuoted = not bQuoted
	end
	return tWords
end





to_colors, to_blit = {}, {}
for i = 1, 16 do
	to_blit[2^(i-1)] = ("0123456789abcdef"):sub(i, i)
	to_colors[("0123456789abcdef"):sub(i, i)] = 2^(i-1)
end


function lOS.eventdelay()
	local oldtime = os.time()
	local timer = os.startTimer(0)
	while true do
		event,id = os.pullEvent("timer")
		if id == timer then
			local newtime = os.time()
			return (newtime-oldtime)*50000
		end
	end
end



function lUtils.getFileType(filename)
	if string.find(filename,"%.%w+$") == nil then
		return ""
	else
		return string.sub(filename,string.find(filename,"%.%w+$"))
	end
end



function lUtils.getFileName(filename,ext)
	local f = filename
	if string.find(filename," ") then
		f = string.sub(filename,1,({string.find(filename," ")})[1]-1)
	end
	f = fs.getName(f)
	if not ext or lUtils.getFileType(f) == ".llnk" then
		f = string.sub(f,1,string.len(f)-string.len(lUtils.getFileType(f)))
	end
	return string.gsub(f,"_"," ")
end



function lUtils.getFilePath(filename)
	local f = filename
	if string.find(filename," ") then
		f = string.sub(filename,1,({string.find(filename," ")})[1]-1)
	end
	return f
end

local strength

function lOS.checkinternet()
	strenth = 0
	local oldtime = os.time()
	a = http.get("https://os.leveloper.cc/ping.php")
	if a == nil or a == false then
		strength = 0
	else
		newtime = os.time()
		if newtime-oldtime < 0.005 then
			strength = 3
		elseif newtime-oldtime < 0.01 then
			strength = 2
		elseif newtime-oldtime >= 0.01 then
			strength = 1
		end
		return strength,newtime-oldtime
	end
	return 0,0
end

function lOS.getInternet()
	return strength or 0
end

function lOS.run( _sCommand, ... )
	local sPath = shell.resolveProgram( _sCommand )
	if sPath ~= nil then
		local tWindow = {}
		local tArgs = {...}
		--term.write(textutils.serialize(tArgs))
		if type(tArgs[1]) == "table" then
			tWindow = tArgs[1]
			table.remove(tArgs,1)
		else
			tWindow = nil
		end
		-- set window title
		local sDir = fs.getDir( sPath )
		local result = {run2( createShellEnv( sDir, tWindow, sPath ), sPath, table.unpack(tArgs) )}
		return table.unpack(result)
	else
		return false,"No such program"
	end
end

function lOS.newWin(func,rPath)
	-- fuck me
end


function lOS.searchfor(arg,path)
	local files = fs.list(path)
	local folders = {}
	local result = {}
	local p = ""
	if path ~= "" then
		p = path.."/"
	else
		p = ""
	end
	for t=1,#files do
		if fs.isDir(p..files[t]) then
			folders[#folders+1] = p..files[t]
		elseif string.find(string.lower(files[t]),string.lower(arg)) then
			result[#result+1] = p..files[t]
		end
	end
	for t=1,#folders do
		local a = lOS.searchfor(arg,folders[t])
		for b=1,#a do
			result[#result+1] = a[b]
		end
	end
	return result
end



function lOS.search(keyword,x,y,w,h,searchfile,animation)
	local lines = {}
	local slp = function() os.sleep(0) end
	for t=1,h do
		lines[t] = {"","",""}
	end
	lines[h] = {"\138","0","8"}
	lines[h-1] = {"\149","8","0"}
	lines[h-2] = {"\151","8","0"}
	lines[1] = {"\151","8","7"}
	lines[2] = {"\149","8","7"}
	for t=1,w-2 do
		if t < math.floor(w/2) then
			lines[1][1] = lines[1][1].."\131"
			lines[1][2] = lines[1][2].."8"
			lines[1][3] = lines[1][3].."7"
			lines[2][1] = lines[2][1].." "
			lines[2][2] = lines[2][2].."0"
			lines[2][3] = lines[2][3].."7"
		else
			lines[1][1] = lines[1][1].."\131"
			lines[1][2] = lines[1][2].."8"
			lines[1][3] = lines[1][3].."0"
			lines[2][1] = lines[2][1].." "
			lines[2][2] = lines[2][2].."0"
			lines[2][3] = lines[2][3].."0"
		end
		lines[h][1] = lines[h][1].."\143"
		lines[h][2] = lines[h][2].."0"
		lines[h][3] = lines[h][3].."8"
		lines[h-1][1] = lines[h-1][1].." "
		lines[h-1][2] = lines[h-1][2].."f"
		lines[h-1][3] = lines[h-1][3].."0"
		lines[h-2][1] = lines[h-2][1].."\131"
		lines[h-2][2] = lines[h-2][2].."8"
		lines[h-2][3] = lines[h-2][3].."0"
	end
	lines[1][1] = lines[1][1].."\148"
	lines[1][2] = lines[1][2].."0"
	lines[1][3] = lines[1][3].."8"
	lines[2][1] = lines[2][1].."\149"
	lines[2][2] = lines[2][2].."0"
	lines[2][3] = lines[2][3].."8"
	lines[h][1] = lines[h][1].."\133"
	lines[h][2] = lines[h][2].."0"
	lines[h][3] = lines[h][3].."8"
	lines[h-1][1] = lines[h-1][1].."\149"
	lines[h-1][2] = lines[h-1][2].."0"
	lines[h-1][3] = lines[h-1][3].."8"
	lines[h-2][1] = lines[h-2][1].."\148"
	lines[h-2][2] = lines[h-2][2].."0"
	lines[h-2][3] = lines[h-2][3].."8"
	term.setCursorPos(x,y+(h-1))
	term.blit(table.unpack(lines[h]))
	term.setCursorPos(x,y+(h-1)-1)
	term.blit(table.unpack(lines[h-2]))
	slp()
	term.setCursorPos(x,y+(h-1)-1)
	term.blit(table.unpack(lines[h-1]))
	term.setCursorPos(x,y+(h-1)-2)
	term.blit(table.unpack(lines[h-2]))
	slp()
	for t=4,h,3 do
		term.setCursorPos(x,y+(h-1)-(t-1))
		term.blit(table.unpack(lines[1]))
		for a=1,t-4 do
			term.setCursorPos(x,y+(h-1)-(t-1)+(a))
			term.blit(table.unpack(lines[2]))
		end
		slp()
	end
	term.setCursorPos(x,y)
	term.blit(table.unpack(lines[1]))
	for a=1,h-4 do
		term.setCursorPos(x,y+a)
		term.blit(table.unpack(lines[2]))
	end
	search = lUtils.makeEditBox("Search",w-3,1)
	search.lines = {""}
	local function searchy()
		while true do
			lUtils.drawEditBox(search,x+2,y+(h-2),0,0,string.len(search.lines[1])+1,1,true,false)
		end
	end
	local scrl = -1
	local sel = 1
	local btns = {}
	local function rendersearch()
		for a=1,h-4 do
			term.setCursorPos(x,y+a)
			term.blit(table.unpack(lines[2]))
		end
		local ox,oy = term.getCursorPos()
		local txtcolor = term.getTextColor()
		term.setCursorPos(x+(w/2),y+1)
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
--      write("lastkey = "..lastkey.." and os.time() = "..os.time())
		-- selected box
		term.setBackgroundColor(colors.white)
		lOS.boxClear(x+math.ceil(w/2),y+1,x+(w-2),y+(h-4))
		if result[sel] ~= nil then
			local tPath = ""
			if string.gsub(result[sel],fs.getName(result[sel]),"") ~= "" then
				tPath = string.gsub(result[sel],fs.getName(result[sel]),"")
			else
				tPath = "root"
			end
			term.setCursorPos(x+(w/2)+1,y+2)
			local ay = y+2
			local ax = x+(math.floor(w/2))+6
			local aw = (math.ceil(w/2-1)-6)
			term.setTextColor(colors.lightGray)
			write("Name")
			term.setTextColor(colors.black)
			for t=1,math.ceil(string.len(fs.getName(result[sel]))/aw) do
				term.setCursorPos(ax,ay)
				write(string.sub(fs.getName(result[sel]),1+((t-1)*aw),t*aw))
				ay = ay+1
			end
			term.setCursorPos(x+(w/2)+1,ay)
			term.setTextColor(colors.lightGray)
			write("Path")
			term.setTextColor(colors.black)
			for t=1,math.ceil(string.len(tPath)/aw) do
				term.setCursorPos(ax,ay)
				write(string.sub(tPath,1+((t-1)*aw),t*aw))
				ay = ay+1
			end
	if fs.exists(result[sel].."updater") then
		term.setTextColor(colors.gray)
		term.setCursorPos(x+(w/2)+1,ay)
		term.write("(Auto updates)")
		ay = ay+1
	end
	ay = ay+1
	local aline = ""
	for t=ax-5,x+(w-2) do
		aline = aline.." "
	end
	function filetype(filename)
		if string.find(filename,"%.%w+$") == nil then
			return ""
		else
			return string.sub(filename,string.find(filename,"%.%w+$"))
		end
	end
	if ay+1 <= y+(h-4) then
		if filetype(fs.getName(result[sel])) == ".lua" then
			btns = {}
			btns[1] = {" Execute",ax-5,ay}
			btns[2] = {" Edit",ax-5,ay+2}
			btns[3] = {" Create Shortcut",ax-5,ay+4}
		elseif filetype(fs.getName(result[sel])) == ".txt" then
			btns = {}
			btns[1] = {" Edit",ax-5,ay}
			btns[2] = {" Create Shortcut",ax-5,ay+2}
		else
			btns = {}
			btns[1] = {" Execute",ax-5,ay}
			btns[2] = {" Edit",ax-5,ay+2}
			btns[3] = {" Create Shortcut",ax-5,ay+4}
		end
	end
	for t=1,#btns do
		if t==1 then
			term.setCursorPos(ax-5,btns[t][3]-1)
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.white)
			term.write(string.gsub(aline,"%s","\143"))
		end
		term.setCursorPos(btns[t][2],btns[t][3])
		term.setTextColor(colors.black)
		term.write(btns[t][1]..string.sub(aline,string.len(btns[t][1])+1,string.len(aline)))
		if t < #btns then
			term.setCursorPos(ax-5,btns[t][3]+1)
			term.setTextColor(colors.white)
			term.write(string.gsub(aline,"%s","\140"))
		else
			term.setCursorPos(ax-5,btns[t][3]+1)
			term.setTextColor(colors.lightGray)
			term.setBackgroundColor(colors.white)
			term.write(string.gsub(aline,"%s","\131"))
		end
	end
		end
		for t=1,#result do
			if result[t] ~= nil then
				if sel == t then
					term.setBackgroundColor(colors.lightGray)
				else
					term.setBackgroundColor(colors.gray)
				end
				if fs.exists(result[t].."updater") ~= nil then
					for i=1,#result do
						if result[i] ~= nil and result[i] == result[t].."updater" then
							table.remove(result,i)
						end
					end
				end
				if y+((t-1)*2)-scrl > y and y+((t-1)*2)-scrl <= y+(h-4) then
					term.setCursorPos(x,y+((t-1)*2)-scrl)
					term.setTextColor(colors.lightGray)
					term.write("\149")
					for i=1,(w/2)-2 do
						write(" ")
					end
					term.setCursorPos(x+1,y+((t-1)*2)-scrl)
					term.setTextColor(colors.white)
					if string.len(fs.getName(result[t])) > (w/2)-2 then
						term.write(string.sub(fs.getName(result[t]),1,(w/2)-5).."...")
					else
						term.write(fs.getName(result[t]))
					end
				end
				if 1+y+((t-1)*2)-scrl > y and 1+y+((t-1)*2)-scrl <= y+(h-4) then
					term.setCursorPos(x,1+y+((t-1)*2)-scrl)
					term.setTextColor(colors.lightGray)
					term.write("\149")
					for i=1,(w/2)-2 do
						write(" ")
					end
					term.setCursorPos(x+1,1+y+((t-1)*2)-scrl)
					if sel == t then
						term.setTextColor(colors.gray)
					end
					if string.gsub(result[t],fs.getName(result[t]),"") ~= "" then
						if string.len(string.gsub(result[t],fs.getName(result[t]),"")) > (w/2)-2 then
							term.write(string.sub(string.gsub(result[t],fs.getName(result[t]),""),1,(w/2)-5).."...")
						else
							term.write(string.gsub(result[t],fs.getName(result[t]),""))
						end
					else
						term.write("root")
					end
				end
			end
		end
		term.setCursorPos(ox,oy)
		term.setTextColor(txtcolor)
	end
	lastkey = os.time()
	lastsearch = ""
	result = {}
	term.setBackgroundColor(colors.white)
--	lOS.boxClear(x+math.ceil(w/2),y+1,x+(w-2),y+(h-2))
	local function regevents()
		local atimer = os.startTimer(0.5)
		while true do
			local a = {os.pullEvent()}
			if a[1] == "mouse_click" then
				if a[3] < x or a[3] > x+(w-1) or a[4] < y then -- maybe check underneath search box too but i dont think thats necessary for now
					return false,""
				else
					for t=1,#btns do
						if a[4] == btns[t][3] and a[3] >= btns[t][2] and result[sel] ~= nil then
							if string.gsub(btns[t][1],"%s","") == "Edit" and fs.exists(result[sel].."updater") == true then
								result[sel] = result[sel].."updater"
							end
							return true,result[sel],string.gsub(btns[t][1],"%s","")
						end
					end
				end
			elseif a[1] == "key" then
				lastkey = os.time()
				if a[2] == keys.enter and search.lines[1] ~= "" and result[sel] ~= nil then
					return true,result[sel],"Execute"
				elseif a[2] == keys.down then
					if result[sel+1] ~= nil then
						sel = sel+1
						while y+((sel-1)*2)-scrl <= y do
							scrl = scrl-1
						end
						while 1+y+((sel-1)*2)-scrl > y+(h-4) do
							scrl = scrl+1
						end
						rendersearch()
					end
				elseif a[2] == keys.up then
					if sel > 1 then
						sel = sel-1
						while y+((sel-1)*2)-scrl <= y do
							scrl = scrl-1
						end
						while 1+y+((sel-1)*2)-scrl > y+(h-4) do
							scrl = scrl+1
						end
						rendersearch()
					end
				end
			elseif a[1] == "timer" and a[2] == atimer then
				atimer = os.startTimer(0.5)
				if os.time() > lastkey+0.01 and search.lines[1] ~= lastsearch then
					lastkey = os.time()
					lastsearch = search.lines[1]
					result = lOS.searchfor(search.lines[1],"")
					sel = 1
					rendersearch()
				end
			elseif a[1] == "mouse_scroll" and a[3] >= x and a[3] <= x+((w/2)-1) and a[4] >= y and a[4] <= y+(h-4) then
				if scrl+a[2] >= -1 then
					scrl = scrl+a[2]
					rendersearch()
				end
			end
		end
	end
	i = {}
	parallel.waitForAny(searchy,function() i={regevents()} end)
	term.setCursorBlink(false)
	return table.unpack(i)
end



function lUtils.littlewin(oriwin,w,h)
	local oW,oH = oriwin.getSize()
	local oldwin = {lines={}}
	for y=1,oH do
		oldwin.lines[y] = {oriwin.getLine(y)}
	end
	local newwin = {lines={}}
	local ystep = oH/h
	local xstep = oW/w
	for y=1,h do
		local xstart = math.floor(xstep/2)
		if xstart < 1 then
			xstart = 1
		end
		local ystart = math.floor(ystep/2)
		if ystart < 1 then
			ystart = 1
		end
		local curLine = math.floor(ystart+ystep*(y-1))
		if curLine > oH or curLine <= 0 then
			curLine = 1
		end
		local templine = {oriwin.getLine(curLine)}
		newwin.lines[y] = {"","",""}
		for x=1,w do
			newwin.lines[y][1] = newwin.lines[y][1]..string.sub(templine[1],math.floor(xstart+xstep*(x-1)+0.5),math.floor(xstart+xstep*(x-1)+0.5))
			newwin.lines[y][2] = newwin.lines[y][2]..string.sub(templine[2],math.floor(xstart+xstep*(x-1)+0.5),math.floor(xstart+xstep*(x-1)+0.5))
			newwin.lines[y][3] = newwin.lines[y][3]..string.sub(templine[3],math.floor(xstart+xstep*(x-1)+0.5),math.floor(xstart+xstep*(x-1)+0.5))
		end
	end
	function newwin.render(x,y,noLetters)
		for l=1,#newwin.lines do
			term.setCursorPos(x,y+(l-1))
			if noLetters then
				newwin.lines[l][1] = newwin.lines[l][1]:gsub("[^\127-\160 ]",".")
			end
			term.blit(table.unpack(newwin.lines[l]))
		end
	end
	return newwin
end



function lUtils.fread(filepath, binary)
	local mode = binary and "rb" or "r"
	local fread = fs.open(filepath,mode)
	local thing = fread.readAll()
	fread.close()
	return thing
end

function lUtils.fwrite(filepath,content, binary)
	local mode = binary and "wb" or "w"
	local fwrite = fs.open(filepath,mode)
	fwrite.write(content)
	fwrite.close()
	return true
end



wPattern = "%S+"
function lUtils.makeEditBox(filepath,width,height,sTable)
	if filepath == nil then
		return false
	end
	if width == nil then
		width = getWidth()
	end
	if height == nil then
		height = getHeight()
	end
	if sTable == nil then
		--sTable = {background={colors.white},text={colors.black},keywords={colors.yellow},notes={colors.green},strings={colors.red},menu={colors.yellow,colors.lightGray}}
		sTable = {background={colors.white},text={colors.black},cursor={colors.red}}
	end
	lines = {""}
	return {width=width,height=height,sTable=sTable,lines=lines,filepath=filepath,changed=false}
end



function lUtils.drawEditBox(box,expos,eypos,spx,spy,cpx,cpy,active,enterkey,rChar,changesAllowed)
	if changesAllowed == nil then
		changesAllowed = true
	end
	-- term.setCursorPos(expos,eypos)
	-- print(tostring(changesAllowed))
	-- os.sleep(1)
	if enterkey == nil then
		enterkey = true
	end
	if spx == nil then
		spx = 0
	end
	if spy == nil then
		spy = 0
	end
	if cpx == nil then
		cpx = 1
	end
	if cpy == nil then
		cpy = 1
	end
	if expos == nil then
		expos = box.x
	else
		box.x = expos
	end
	if eypos == nil then
		eypos = box.y
	else
		box.y = eypos
	end
	-- As these abbrevs are pretty unclear, I will now specify them respectively.
	-- editorboxtable,editorxposition,editoryposition,scrollpositionx,scrollpositiony,usercursorpositionx,usercurserpositiony
	local keywords = {["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,["end"]=true,["false"]=true,["for"]=true,["function"]=true,["if"]=true,["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,["until"]=true,["while"]=true}
	if box.width == nil or box.height == nil or box.sTable == nil or box.lines == nil or box.filepath == nil then
		return false
	end
	if active == nil then
		active = true
	end
	if active == false then
		if box.sTable.background == nil then
			term.setBackgroundColor(colors.black)
		else
			term.setBackgroundColor(box.sTable.background[1])
		end
		lOS.boxClear(expos,eypos,expos+(box.width-1),eypos+(box.height-1))
		ypos = eypos
		for l=1+spy,box.height+spy do
			if box.lines[l] ~= nil then
				if rChar ~= nil then
					term.setTextColor(colors.lightGray)
					term.setCursorPos(expos,ypos)
					for rc=1,string.len(string.sub(box.lines[l],1+spx,box.width+spx)) do
						write(rChar)
					end
				else
					term.setTextColor(colors.lightGray)
					term.setCursorPos(expos,ypos)
					write(string.sub(box.lines[l],1+spx,box.width+spx))
				end
			end
			ypos = ypos+1
		end
		return box,spx,spy,cpx,cpy,false,{}
	end
	while true do
		expos,eypos = box.x,box.y
		if box.sTable.background == nil then
			term.setBackgroundColor(colors.black)
		else
			term.setBackgroundColor(box.sTable.background[1])
		end
		lOS.boxClear(expos,eypos,expos+(box.width-1),eypos+(box.height-1))
		ypos = eypos
		for l=1+spy,box.height+spy do
			instring = false
			innote = false
			if box.lines[l] ~= nil then
				if box.sTable.text == nil then
					term.setTextColor(colors.white)
				else
					term.setTextColor(box.sTable.text[1])
				end
				term.setCursorPos(expos,ypos)
				if rChar ~= nil then
					for rc=1,string.len(string.sub(box.lines[l],1+spx,box.width+spx)) do
						write(rChar)
					end
				else
					wordcount = 1
					if string.find(string.sub(box.lines[l],1+spx,box.width+spx),"%s+") ~= nil then
						if string.find(string.sub(box.lines[l],1+spx,box.width+spx),"%s+") == 1 then
							write(string.match(string.sub(box.lines[l],1+spx,box.width+spx),"%s+"))
						end
					end
					for word in string.gmatch(string.sub(box.lines[l],1+spx,box.width+spx),wPattern) do
						somearg = string.find(word,"--",nil,true)
						if tonumber(somearg) ~= nil and instring == false then
							innote = true
						end
						somearg = nil
						if innote == true and box.sTable.notes ~= nil then
							term.setTextColor(box.sTable.notes[1])
						elseif keywords[word] ~= nil and box.sTable.keywords ~= nil then
							term.setTextColor(box.sTable.keywords[1])
						elseif tonumber(word) ~= nil and box.sTable.numbers ~= nil then
							term.setTextColor(box.sTable.numbers[1])
						else
							term.setTextColor(box.sTable.text[1])
						end
						if wordcount == 1 then
							write(word)
						else
							write(" "..word)
						end
						wordcount = wordcount+1
					end
				end
			end
			ypos = ypos+1
		end
		if cpy > spy and cpy <= spy+(box.height) and cpx > spx and cpx <= spx+(box.width) then
			if box.sTable.cursor ~= nil then
				term.setTextColor(box.sTable.cursor[1])
			else
				term.setTextColor(colors.black)
			end
			term.setCursorPos(cpx-spx-1+expos,cpy-spy-1+eypos)
			term.setCursorBlink(true)
		end
		while cpx > string.len(box.lines[cpy])+1 do
			cpx = cpx-1
		end
		while cpx > spx+(box.width) do
			spx = spx+1
		end
		while cpx <= spx do
			spx = spx-1
		end
		event,button,x,y = os.pullEvent()
		term.setCursorBlink(false)
		if (event == "mouse_click" and (x < expos or x > expos+box.width-1 or y < eypos or y > eypos+box.height-1)) or (event == "key" and button == keys.enter and enterkey == false) then
			if box.sTable.background == nil then
				term.setBackgroundColor(colors.black)
			else
				term.setBackgroundColor(box.sTable.background[1])
			end
			lOS.boxClear(expos,eypos,expos+(box.width-1),eypos+(box.height-1))
			ypos = eypos
			for l=1+spy,box.height+spy do
				if box.lines[l] ~= nil then
					if rChar ~= nil then
						for rc=1,string.len(string.sub(box.lines[l],1+spx,box.width+spx)) do
							write(rChar)
						end
					else
						term.setTextColor(colors.lightGray)
						term.setCursorPos(expos,ypos)
						write(string.sub(box.lines[l],1+spx,box.width+spx))
					end
				end
				ypos = ypos+1
			end
			return box,spx,spy,cpx,cpy,false,{event,button,x,y}
		elseif event == "mouse_scroll" and enterkey == true then
			if button == -1 and spy > 0 then
				spy = spy-1
			elseif button == 1 then
				spy = spy+1
			end
		elseif event == "key" then
			if button == keys.right and cpx < string.len(box.lines[cpy])+1 then
				cpx = cpx+1
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height do
					spy = spy+1
				end
			elseif button == keys.left and cpx > 1 then
				cpx = cpx-1
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height do
					spy = spy+1
				end
			elseif button == keys.down and cpy < #box.lines then
				cpy = cpy+1
				while cpy > spy + (box.height) do
					spy = spy+1
				end
				while cpy <= spy do
					spy = spy-1
				end
			elseif button == keys.up and cpy > 1 then
				cpy = cpy-1
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height do
					spy = spy+1
				end
			elseif button == keys.home then
				cpx = 1
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height do
					spy = spy+1
				end
			elseif button == keys["end"] then
				cpx = string.len(box.lines[cpy])+1
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height do
					spy = spy+1
				end
			elseif button == keys.tab and changesAllowed == true then
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height do
					spy = spy+1
				end
				if box.changed == false then
					box.changed = true
				end
				box.lines[cpy] = string.sub(box.lines[cpy],1,cpx-1).."  "..string.sub(box.lines[cpy],cpx,string.len(box.lines[cpy]))
				cpx = cpx+2
			elseif button == keys.backspace and changesAllowed == true then
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height do
					spy = spy+1
				end
				if box.changed == false then
					box.changed = true
				end
				if cpx == 1 then
					if cpy > 1 then
						cpx = string.len(box.lines[cpy-1])+1
						box.lines[cpy-1] = box.lines[cpy-1]..box.lines[cpy]
						table.remove(box.lines,cpy)
						cpy = cpy-1
					end
				else
					box.lines[cpy] = string.sub(box.lines[cpy],1,cpx-2)..string.sub(box.lines[cpy],cpx,string.len(box.lines[cpy]))
					cpx = cpx-1
				end
			elseif button == keys.enter and enterkey ~= false and changesAllowed == true then
				while cpy <= spy do
					spy = spy-1
				end
				while cpy > spy+box.height-1 do
					spy = spy+1
				end
				if box.changed == false then
					box.changed = true
				end
				table.insert(box.lines,cpy+1,string.sub(box.lines[cpy],cpx,string.len(box.lines[cpy])))
				box.lines[cpy] = string.sub(box.lines[cpy],1,cpx-1)
				cpy = cpy+1
				cpx = 1
			end
		elseif event == "char" and changesAllowed == true then
			while cpy <= spy do
				spy = spy-1
			end
			while cpy > spy+box.height do
				spy = spy+1
			end
			if box.changed == false then
				box.changed = true
			end
			box.lines[cpy] = string.sub(box.lines[cpy],1,cpx-1)..button..string.sub(box.lines[cpy],cpx,string.len(box.lines[cpy]))
			cpx = cpx+1
	elseif event == "paste" and changesAllowed == true then
		while cpy <= spy do
				spy = spy-1
			end
			while cpy > spy+box.height do
				spy = spy+1
			end
			if box.changed == false then
				box.changed = true
			end
			box.lines[cpy] = string.sub(box.lines[cpy],1,cpx-1)..button..string.sub(box.lines[cpy],cpx,string.len(box.lines[cpy]))
			cpx = cpx+string.len(button)
		elseif event == "mouse_click" and y <= eypos+box.height-1 then
			cpx = x - expos + spx+1
			cpy = y - eypos + spy+1
			if cpy > #box.lines then
				cpy = #box.lines
			end
		end
	end
end


function lUtils.textbox(txt,x1,y1,x2,y2,trans,syntax,overflowX,overflowY,scrollX,scrollY,align)
	--[[term.setCursorPos(1,1)
	local bbox = lUtils.makeBox(txt,x1,y1,x2,y2,{background={term.getBackgroundColor()},text={term.getTextColor()},name={colors.cyan},code={colors.red,colors.lightGray},notification={colors.green},title={colors.orange,align="center"}})
	_G.bbox = bbox
	lUtils.printBox(bbox,0,true,trans)]]
	local al = align or "left"
	local oX = overflowX or "wrap"
	local oY = overflowY or "none"
	local w,h = x2-(x1-1),y2-(y1-1)
	local lines
	local blit = {}
	if trans then
		for y=y1,y2 do
			local bl = term.getLine(y)
			table.insert(blit,{"","",bl[3]:sub(x1,x2)})
		end
	else
		local col = lUtils.toBlit(term.getBackgroundColor())
		for y=y1,y2 do
			table.insert(blit,{"","",string.rep(col,w)})
		end
	end
	if oX == "wrap" then
		lines = lUtils.wordwrap(txt,w)
	else
		lines = {}
		for line in txt:gmatch("([^\n]*)\n?") do
			table.insert(lines,line)
		end
		if txt:sub(#txt) == "\n" then
			table.insert(lines,"")
		end
	end
	local tLines = {{lines[1],ref=1}}
	for t=2,#lines do
		tLines[t] = {lines[t],ref=tLines[t-1].ref+#tLines[t-1][1]}
	end
	local syntaxes = {
		["lua"] = {
			whitespace=colors.white,
			comment=colors.green,
			string=colors.red,
			escape=colors.orange,
			keyword=colors.yellow,
			value=colors.yellow,
			ident=colors.cyan,
			number=colors.purple,
			symbol=colors.orange,
			operator=colors.yellow,
			unidentified=colors.white,
		}
	}
	local sType
	if type(syntax) == "string" then
		sType = syntax
		syntax = {type=sType}
	elseif type(syntax) == "table" then
		sType = syntax.type
	end
	if sType and syntaxes[sType] then
		if sType == "lua" and fs.exists("lex") then
			local lex = dofile("lex")
			local elements = lex.lex(txt)
			local line = 1
			for t=1,#elements do
				while tLines[line+1] and elements[t].posFirst >= tLines[line+1].ref do
					line = line+1
				end
				--term.setCursorPos(x+elements[t].posFirst-tLines[line].ref)
				--elements[t].data = elements[t].data:gsub("\t","    ")
				local col = lUtils.toBlit(syntaxes[sType][elements[t].type] or colors.white)
				blit[line][1] = blit[line][1]..elements[t].data
				blit[line][2] = blit[line][2]..string.rep(col,#elements[t].data)
			end
		end
	end
	_G.debugBlit = blit
	for t=1,#blit do
		local x
		local line = lines[t]
		if align == "center" then
			x = (x1+math.ceil(w/2)-1)-(math.ceil(#blit[t][1]/2)-1)
		elseif align == "right" then
			x = x2-(#blit[t][1]-1)
		else
			x = x1
		end
		if #blit[t][3] > #blit[t][1] then
			blit[t][3] = blit[t][3]:sub(x1-(x-1),x1-(x-1)+(#blit[t][1]-1))
		end
		term.setCursorPos(x,y1+(t-1))
		term.blit(unpack(blit[t]))
	end
end

function lUtils.textbox(txt,x1,y1,x2,y2,trans)
	term.setCursorPos(1,1)
	local bbox = lUtils.makeBox(txt,x1,y1,x2,y2,{background={term.getBackgroundColor()},text={term.getTextColor()},name={colors.cyan},code={colors.red,colors.lightGray},notification={colors.green},title={colors.orange,align="center"}})
	_G.bbox = bbox
	lUtils.printBox(bbox,0,true,trans)
end

function lUtils.makeBox(boxTxt,x1,y1,x2,y2,sTable,buttons)
	-- boxTxt = {{{"Introduction",type="title"}},{{"Welcome to ",type="text"},{"LuaCraft",type="name"},{"!",type="text"}}}
	paragraphs = {}
	if boxTxt == nil then
		return false
	end
	if x1 == nil then
		x1 = 1
	end
	if y1 == nil then
		y1 = 1
	end
	if x2 == nil then
		x2 = getWidth()
	end
	if y2 == nil then
		y2 = getHeight()
	end
	if sTable == nil then
		sTable = {background={colors.white},text={colors.black},name={colors.cyan},code={colors.red,colors.lightGray},notification={colors.green},title={colors.orange,align="center"}}
	end
	if _G.type(boxTxt) == "string" then
		while true do
			par1,par2 = string.find(boxTxt,"\n")
			if par2 ~= nil then
				paragraphs[#paragraphs+1] = {{string.sub(boxTxt,1,par1-1),type="text"}}
				if string.len(boxTxt) > par2 then
					boxTxt = string.sub(boxTxt,par2+1,string.len(boxTxt))
				else
					boxTxt = ""
					break
				end
			else
				paragraphs[#paragraphs+1] = {{boxTxt,type="text"}}
				break
			end
		end
	elseif _G.type(boxTxt) == "table" then
		paragraphs = boxTxt
	end
	lines = {{{},tt=""}}
	cline = 1
	for p=1,#paragraphs do
		for t=1,#paragraphs[p] do
			-- paragraphs[1] = {{"Introduction",type="title"}}
			-- paragraphs[1][1] = {"Introduction",type="title"}
			lines[cline][1][#lines[cline][1]+1] = {"",type=paragraphs[p][t].type}
			for word in string.gmatch(paragraphs[p][t][1],"%S+") do
--				write(word)
				if string.len(lines[cline].tt) == 0 then
					if string.len(lines[cline].tt..word) > x2-(x1-1) then
						-- This means a single word takes up MORE than an ENTIRE line. I'll have to write some proper code for that later.
					end
					-- First word in the line, so obviously no space before the word.
					-- wow old me is so stupid I completely forgot about indentation
					-- HAHAHA dumbass old me messed the fuck up
					local indent = ""
					if string.sub(paragraphs[p][t][1],1,1) == " " then
						indent = string.gmatch(paragraphs[p][t][1],"%s+")()
					end
					lines[cline][1][#lines[cline][1]][1] = lines[cline][1][#lines[cline][1]][1]..indent..word
					lines[cline].tt = lines[cline].tt..indent..word
				else
					if string.len(lines[cline].tt.." "..word) > x2-(x1-1) then
						cline = cline+1
						lines[cline] = {{},tt=""}
						lines[cline][1][#lines[cline][1]+1] = {"",type=paragraphs[p][t].type}
						lines[cline][1][#lines[cline][1]][1] = lines[cline][1][#lines[cline][1]][1]..word
						lines[cline].tt = lines[cline].tt..word
					else
						lines[cline][1][#lines[cline][1]][1] = lines[cline][1][#lines[cline][1]][1].." "..word
						lines[cline].tt = lines[cline].tt.." "..word
					end
				end
			end
			print("")
		end
		cline = cline+1
		lines[cline] = {{},tt=""}
	end
	if buttons == nil then
		buttons = {}
	end
	return {x1=x1,y1=y1,x2=x2,y2=y2,sTable=sTable,lines=lines,buttons=buttons}
end

function lUtils.transWrite(txt,autoTextColor)
	local txtcolor = term.getTextColor()
	local dark = {colors.blue,colors.red,colors.purple,colors.green,colors.black,colors.gray,colors.brown,colors.cyan,colors.magenta}
	local light = {colors.white,colors.orange,colors.lightBlue}
	for k,v in ipairs(dark) do
		dark[v] = true
	end
	for k,v in ipairs(light) do
		light[v] = true
	end
	for t=1,string.len(txt) do
		local col = lUtils.toColor(({lUtils.getPixel(term.current(),term.getCursorPos())})[3])
		term.setBackgroundColor(col)
		if autoTextColor then
			if dark[col] and not light[col] then
				term.setTextColor(colors.white)
			else
				term.setTextColor(colors.black)
			end
		end
		term.write(string.sub(txt,t,t))
	end
	term.setTextColor(txtcolor)
end

function lUtils.printBox(box,scrollpos,simple,trans)
	if type(box) ~= "table" then
		error("Invalid argument #1: Expected table",2)
	end
	someabsolutelyrandomthing = true
	while someabsolutelyrandomthing == true do
		term.setTextColor(colors.black)
		if box.x1 == nil or box.y1 == nil or box.x2 == nil or box.y2 == nil or box.sTable == nil or box.lines == nil then
			return false,"Invalid Box."
		end
		if box.sTable.background ~= nil then
			term.setBackgroundColor(box.sTable.background[1])
		else
			term.setBackgroundColor(colors.white)
		end
		if not trans then
			lOS.boxClear(box.x1,box.y1,box.x2,box.y2)
		end
		ypos = box.y1
		for l=1+scrollpos,box.y2-(box.y1-1)+scrollpos do
			if box.lines[l] ~= nil then
				term.setCursorPos(box.x1,ypos)
				for p=1,#box.lines[l][1] do
					if box.sTable[box.lines[l][1][p].type] ~= nil then
						term.setTextColor(box.sTable[box.lines[l][1][p].type][1])
						if box.sTable[box.lines[l][1][p].type][2] ~= nil then
							term.setBackgroundColor(box.sTable[box.lines[l][1][p].type][2])
						end
						if box.sTable[box.lines[l][1][p].type].align ~= nil then
							if box.sTable[box.lines[l][1][p].type].align == "center" then
								cposx,cposy=term.getCursorPos()
								term.setCursorPos(box.x1+math.floor((box.x2-(box.x1-1))/2)-math.floor(string.len(box.lines[l][1][p][1])/2),cposy)
							end
						end
						lUtils.transWrite(box.lines[l][1][p][1])
					end
				end
			end
			ypos = ypos+1
		end
		if box.buttons ~= nil then
			for b=1,#box.buttons do
				if box.buttons[b].type == "button" or box.buttons[b].type == "editor" then
					term.setBackgroundColor(box.buttons[b].bg)
					term.setTextColor(box.buttons[b].txt)
					for t=1,box.buttons[b].y2-(box.buttons[b].y1-1) do
						blankline = ""
						for bl=1,box.buttons[b].x2-(box.buttons[b].x1-1) do
							blankline = blankline.." "
						end
						if box.buttons[b].y1+t-1 >= 1+scrollpos and box.buttons[b].y1+t-1 <= box.y2-(box.y1-1)+scrollpos then
							term.setCursorPos(box.buttons[b].x1+box.x1-1,(box.buttons[b].y1+t-2)+box.y1-scrollpos)
							term.write(blankline)
							term.setCursorPos(box.buttons[b].x1+box.x1-1,(box.buttons[b].y1+t-2)+box.y1-scrollpos)
							if box.buttons[b].text[t] ~= nil then
								term.write(box.buttons[b].text[t])
							end
						end
					end
				end
				if box.buttons[b].type == "editor" then
					if box.buttons[b].y1 >= 1+scrollpos and box.buttons[b].y2 <= box.y2-(box.y1-1)+scrollpos then
						if drawEditBox ~= nil and box.buttons[b].quit == false then
							term.setCursorPos(1,1)
							term.write(box.buttons[b].spx..","..box.buttons[b].spy.." | "..box.buttons[b].cpx..","..box.buttons[b].cpy)
							drawEditBox(box.buttons[b].box,box.buttons[b].x1+box.x1-1,(box.buttons[b].y1-1)+box.y1-scrollpos,box.buttons[b].spx,box.buttons[b].spy,box.buttons[b].cpx,box.buttons[b].cpy,false)
						end
					end
				end
			end
		end
		if simple == true then
			someabsolutelyrandomthing = false
		else
		event,button,x,y = os.pullEvent()
		if event == "mouse_click" and (x < box.x1 or x > box.x2 or y < box.y1 or y > box.y2) then
			term.setBackgroundColor(colors.white)
			ypos = box.y1
			for l=1+scrollpos,box.y2-(box.y1-1)+scrollpos do
				if box.lines[l] ~= nil then
					term.setCursorPos(box.x1,ypos)
					for p=1,#box.lines[l][1] do
						if box.sTable[box.lines[l][1][p].type] ~= nil then
							term.setTextColor(colors.lightGray)
							if box.sTable[box.lines[l][1][p].type][2] ~= nil then
								term.setBackgroundColor(box.sTable[box.lines[l][1][p].type][2])
							end
							if box.sTable[box.lines[l][1][p].type].align ~= nil then
								if box.sTable[box.lines[l][1][p].type].align == "center" then
									cposx,cposy=term.getCursorPos()
									term.setCursorPos(box.x1+math.floor((box.x2-(box.x1-1))/2)-math.floor(string.len(box.lines[l][1][p][1])/2),cposy)
								end
							end
							term.write(box.lines[l][1][p][1])
						end
					end
				end
				ypos = ypos+1
			end
			if box.buttons ~= nil then
				for b=1,#box.buttons do
					term.setBackgroundColor(box.buttons[b].bg)
					term.setTextColor(colors.lightGray)
					for t=1,box.buttons[b].y2-(box.buttons[b].y1-1) do
						blankline = ""
						for bl=1,box.buttons[b].x2-(box.buttons[b].x1-1) do
							blankline = blankline.." "
						end
						if box.buttons[b].y1+t-1 >= 1+scrollpos and box.buttons[b].y1+t-1 <= box.y2-(box.y1-1)+scrollpos then
							term.setCursorPos(box.buttons[b].x1+box.x1-1,(box.buttons[b].y1+t-2)+box.y1-scrollpos)
							term.write(blankline)
							term.setCursorPos(box.buttons[b].x1+box.x1-1,(box.buttons[b].y1+t-2)+box.y1-scrollpos)
							if box.buttons[b].text[t] ~= nil then
								term.write(box.buttons[b].text[t])
							end
						end
					end
				end
			end
			return scrollpos
		elseif event == "mouse_click" then
			for b=1,#box.buttons do
				-- box.buttons[b].x1+box.x1-1,(box.buttons[b].y1+t-2)+box.y1-scrollpos
				if x >= box.buttons[b].x1+box.x1-1 and x <= box.buttons[b].x2+box.x1-1 and y >= (box.buttons[b].y1-1)+box.y1-scrollpos and y <= (box.buttons[b].y2-1)+box.y1-scrollpos then
					newbox,newbutton,newscrollpos = box.buttons[b].func(box,box.buttons[b],scrollpos)
					if newbox ~= nil then
						box = newbox
					end
					if newbutton ~= nil then
						box.buttons[b] = newbutton
					end
					if newscrollpos ~= nil then
						scrollpos = newscrollpos
					end
				end
			end
		elseif event == "mouse_scroll" then
			if button == -1 and scrollpos > 0 then
				scrollpos = scrollpos-1
			elseif button == 1 then
				scrollpos = scrollpos+1
			end
		end
		end
	end
end

function lUtils.getPixel(win,x,y)
	local w,h = win.getSize()
	if x < 1 or x > w or y < 1 or y > h then
	return "0","0","0"
	else
		theline = {win.getLine(y)}
		return string.sub(theline[1],x,x),string.sub(theline[2],x,x),string.sub(theline[3],x,x)
   end
end

local function setParent(win)
	if not win.reposition then return false end
	local varName,value = debug.getupvalue(win.reposition,5)
	local i = 1
	while varName and varName ~= "parent" do
		varName,value = debug.getupvalue(win.reposition,i)
		i = i+1
	end
	if varName == "parent" then
		win.parent = value
		if win.parent.reposition and not win.parent.parent then
			setParent(win.parent)
		end
	end
end

function lUtils.getWindowPos(win)
	setParent(win)
	local tWin = win
	local x,y = tWin.getPosition()
	while tWin.parent and tWin.parent.getPosition do
		tWin = tWin.parent
		local ox,oy = tWin.getPosition()
		x,y = x+ox-1,y+oy-1
	end
	return x,y
end

function lUtils.openWin(title,filepath,x,y,width,height,canresize,canmaximize)
	if canmaximize == nil then
		canmaximize = true
	end
	to_colors, to_blit = {}, {}
	for i = 1, 16 do
		to_blit[2^(i-1)] = ("0123456789abcdef"):sub(i, i)
		to_colors[("0123456789abcdef"):sub(i, i)] = 2^(i-1)
	end
	local OGterm = term.current()
	local OGwin = {lines={}}
	local OGtxt = term.getTextColor()
	local OGbg = term.getBackgroundColor()
	local w,h = term.getSize()
	for t=1,h do
		OGwin.lines[t] = {OGterm.getLine(t)}
	end
	local function getPixel(win,x,y)
		theline = {win.getLine(y)}
		return string.sub(theline[1],x,x),string.sub(theline[2],x,x),string.sub(theline[3],x,x)
	end
	function OGwin.render()
		for l=1,#OGwin.lines do
			term.setCursorPos(1,l)
			term.blit(table.unpack(OGwin.lines[l]))
		end
	end
	local progWin = window.create(term.current(),x+1,y+1,width-2,height-2)
	dragging = false
	dragX = false
	dragY = false
	dragSide = 1
	local function redrawbox()
		term.setBackgroundColor(colors.gray)
		term.setCursorPos(x,y)
		for t=1,width-6 do
			term.write(" ")
		end
		term.setTextColor(colors.white)
		if canmaximize == false then
			term.write("    × ")
		else
			term.write(" +  × ")
		end
		term.setCursorPos(x+1,y)
		term.write(title)
		term.setTextColor(colors.gray)
		for i=1,height-2 do
			term.setCursorPos(x,y+i)
			term.blit(string.char(149),to_blit[colors.gray],({getPixel(progWin,1,i)})[3])
			term.blit(progWin.getLine(i))
			term.blit(string.char(149),({getPixel(progWin,width-2,i)})[3],to_blit[colors.gray])
		end
		local bottomline = {string.char(138),({getPixel(progWin,1,height-2)})[3],to_blit[colors.gray]}
		for i=1,width-2 do
			bottomline[1] = bottomline[1]..string.char(143)
			bottomline[2] = bottomline[2]..({getPixel(progWin,i,height-2)})[3]
			bottomline[3] = bottomline[3]..to_blit[colors.gray]
		end
		bottomline[1] = bottomline[1]..string.char(133)
		bottomline[2] = bottomline[2]..({getPixel(progWin,width-2,height-2)})[3]
		bottomline[3] = bottomline[3]..to_blit[colors.gray]
		term.setCursorPos(x,y+(height-1))
		term.blit(table.unpack(bottomline))
	end
	local endresult = {}
	local function regevents()
		local progCor
		if type(filepath) == "string" then
			local tPath = filepath
			local rPath = string.sub(filepath,string.find(filepath,"%S+"))
			local b,e = string.find(filepath,"%S+")
			local tPath = string.sub(filepath,e+2,string.len(filepath))
			local thingy = {}
			for i in string.gmatch(tPath,"%S+") do
				if i ~= nil and i ~= "" then
					thingy[#thingy+1] = i
				end
			end
			progCor = coroutine.create(function() endresult = {lOS.run(rPath,table.unpack(thingy))} end)
		elseif type(filepath) == "function" then
			progCor = coroutine.create(function() endresult = {filepath()} end)
		else
			error("Invalid filepath",3)
		end
		local stop = false
		e = {}
		while stop == false do
			if coroutine.status(progCor) == "dead" then return end
			term.redirect(progWin)
			progWin.redraw()
			progWin.restoreCursor()
			if (e[1] == "mouse_click" or e[1] == "mouse_drag" or e[1] == "mouse_up" or e[1] == "mouse_scroll" or e[1] == "mouse_move") and lOS.wins[lOS.cWin].events ~= "all" then
				e[3] = e[3]-x
				e[4] = e[4]-y
				if e[3] >= 1 and e[3] <= width-2 and e[4] >= 1 and e[4] <= height-2 then
					coroutine.resume(progCor,table.unpack(e))
				end
			else
				coroutine.resume(progCor,table.unpack(e))
			end
			term.redirect(OGterm)
			redrawbox()
			term.setTextColor(progWin.getTextColor())
			term.setCursorPos(({progWin.getPosition()})[1]+({progWin.getCursorPos()})[1]-1,({progWin.getPosition()})[2]+({progWin.getCursorPos()})[2]-1)
			term.setCursorBlink(progWin.getCursorBlink())
			e = {os.pullEvent()}
			if e[1] == "mouse_drag" then
				if dragX == true then
					if dragSide == 1 then
						width = OGw+(DRx-e[3])
						x = OGx-(DRx-e[3])
					else
						width = OGw-(DRx-e[3])
					end
				end
				if dragY == true then
					height = OGh-(DRy-e[4])
				end
				progWin.reposition(x+1,y+1,width-2,height-2)
				progWin.setVisible(false)
				term.redirect(progWin)
				progWin.redraw()
				progWin.restoreCursor()
				coroutine.resume(progCor,"term_resize")
				term.redirect(OGterm)
				progWin.setVisible(true)
				OGwin.render()
				redrawbox()
			end
			if e[1] == "mouse_drag" and dragging == true then
				x = OGx-(DRx-e[3])
				y = OGy-(DRy-e[4])
				progWin.reposition(x+1,y+1)
				progWin.setVisible(false)
				term.redirect(progWin)
				progWin.redraw()
				progWin.restoreCursor()
				coroutine.resume(progCor,"term_resize")
				term.redirect(OGterm)
				progWin.setVisible(true)
				OGwin.render()
				redrawbox()
			elseif e[1] == "mouse_click" or e[1] == "mouse_up" then
				if e[1] == "mouse_up" then
					dragging = false
					dragX = false
					dragY = false
					OGx,OGy = x,y
					OGw,OGh = width,height
					DRx,DRy = nil,nil
				end
				if e[4] == y and e[3] >= x+(width-3) and e[3] <= x+(width-1) then
					if e[1] == "mouse_click" then
						term.setTextColor(colors.white)
						term.setBackgroundColor(colors.red)
						term.setCursorPos(x+(width-3),y)
						term.write(" × ")
					elseif e[1] == "mouse_up" then
						stop = true
						return false
					end
				elseif e[4] == y and e[3] >= x+(width-6) and e[3] <= x+(width-4) and canmaximize ~= false then
					if e[1] == "mouse_click" then
						term.setTextColor(colors.white)
						term.setBackgroundColor(colors.lightGray)
						term.setCursorPos(x+(width-6),y)
						term.write(" + ")
					elseif e[1] == "mouse_up" then
						--lOS.oWins[#lOS.oWins+1] = {window.create(oldterm,1,2,({oldterm.getSize()})[1],({oldterm.getSize()})[2]-3),progCor,fullscreen=false,minimized=false,filepath="'..rPath..'",icon={string.sub(fs.getName(rPath),1,3),string.sub(fs.getName(rPath),4,6)},ran=false}
						--os.startTimer(0.1)
						--return true
					end
				elseif e[4] == y and e[1] == "mouse_click" then
					dragging = true
					DRx,DRy = e[3],e[4]
					OGx,OGy = x,y
				end
				if e[4] > y and e[4] <= y+(height-1) and (e[3] == x or e[3] == x+(width-1)) and e[1] == "mouse_click" and canresize then
					DRx = e[3]
					OGw = width
					OGx = x
					dragX = true
					if e[3] == x then
						dragSide = 1
					else
						dragSide = 2
					end
				end
				if e[4] == y+(height-1) and e[3] >= x and e[3] <= x+(width-1) and e[1] == "mouse_click" and canresize then
					dragY = true
					DRy = e[4]
					OGh = height
				end
			end
		end
	end
	regevents()
	OGwin.render()
	term.setBackgroundColor(OGbg)
	term.setTextColor(OGtxt)
	return table.unpack(endresult)
end



function lUtils.popup(title,msg,width,height,buttons,redrawscreen,colorScheme)
	colorScheme = colorScheme or {}
	local tbtxt = colorScheme.topbarText or colors.white
	local tbtxt2 = colorScheme.topbarTextHighlight or colors.black
	local tbbg = colorScheme.topbarFill or colors.gray
	local tbbg2 = colorScheme.topbarFillHighlight or colors.white
	local txtcol = colorScheme.text or colors.blue
	local bg = colorScheme.fill or colors.white
	local fg = colorScheme.border or colors.lightGray
	local btnbg = colorScheme.buttonFill or colors.white
	local btnbg2 = colorScheme.buttonFillHighlight or colors.lightBlue
	local btntxt = colorScheme.buttonText or colors.black
	local btntxt2 = colorScheme.buttonTextHighlight or colors.white

	buttons = buttons or {"Continue"}

	local oblink = term.getCursorBlink()
	term.setCursorBlink(false)
	if msg == nil then
		error("No text given",2)
	end
	local OGterm = term.current()
	local OGwin = {lines={}}
	local w,h = term.getSize()
	for t=1,h do
		OGwin.lines[t] = {OGterm.getLine(t)}
	end
	function OGwin.render()
		for l=1,#OGwin.lines do
			term.setCursorPos(1,l)
			term.blit(table.unpack(OGwin.lines[l]))
		end
	end
	local dragging = false
	--[[if width == nil or height == nil then
		width = 21
		height = 7
	end]]
	if not height and not width then
		width = 21
	end

	if height and not width then
		width = 21
		local lines = lUtils.wordwrap(msg, width-2)
		while #lines > height-6 do
			width = width+2
			lines = lUtils.wordwrap(msg, width-2)
		end
	elseif width and not height then
		local lines = lUtils.wordwrap(msg, width-2)
		height = #lines+6
	end

	if height < 6 then height = 6 end
	local popupline = string.rep(" ",width)

	local lines = lUtils.wordwrap(msg, width-2)

	local write = term.write
	local function redrawbox()
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
		term.setBackgroundColor(tbbg)
		term.setTextColor(tbtxt)
		write(popupline)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
		write(" "..title)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
		write(" × ")
		-- The line below is unreadable now but it just makes the text box for the popup message and then prints it
		term.setBackgroundColor(bg)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+1,math.ceil(h/2)-math.floor(height/2)+1)
		term.write(string.rep(" ", width-2))
		term.setTextColor(txtcol)
		for y=1, height-4 do
			local line = ""
			if lines[y] then
				line = lines[y]
			end
			line = line..string.rep(" ", width-2 - #line)
			term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+1,math.ceil(h/2)-math.floor(height/2)+1+y)
			term.write(line)
		end

		for t=1,height-4 do
			term.setBackgroundColor(bg)
			term.setTextColor(fg)
			term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+t)
			write(string.char(149))
			term.setBackgroundColor(fg)
			term.setTextColor(bg)
			term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-1,math.ceil(h/2)-math.floor(height/2)+t)
			write(string.char(149))
		end
		term.setBackgroundColor(fg)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-2)
		write(popupline)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-1)
		write(popupline)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1)
		write(popupline)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-1)
		write(popupline)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-1)
		term.setTextColor(btntxt)
		for b=1,#buttons do
			term.setBackgroundColor(fg)
			write(" ")
			term.setBackgroundColor(btnbg)
			write(" "..buttons[b].." ")
		end
	end
	redrawbox()
	while true do
		event,button,x,y = os.pullEvent()
		if event == "mouse_drag" and dragging == true then
			w = OGw-(OGx-x)*2
			h = OGh-(OGy-y)*2
			OGwin.render()
			redrawbox()
		elseif event == "mouse_click" or event == "mouse_up" then
			if event == "mouse_up" and dragging == true then
				dragging = false
			end
			if y == math.ceil(h/2)-math.floor(height/2)+height-2 then
				curX = math.ceil(w/2)-math.floor(width/2)
				for b=1,#buttons do
					if x >= curX+1 and x <= curX+string.len(" "..buttons[b].." ") then
						if event == "mouse_up" or event == "monitor_touch" then
							if redrawscreen ~= nil and redrawscreen == true then
								OGwin.render()
							end
							term.setCursorBlink(oblink)
							return true,b,buttons[b]
						elseif event == "mouse_click" then
							term.setCursorPos(curX+1,math.ceil(h/2)-math.floor(height/2)+height-2)
							term.setBackgroundColor(btnbg2)
							term.setTextColor(btntxt2)
							write(" "..buttons[b].." ")
						end
					end
					curX = curX+string.len(" "..buttons[b].." ")+1
				end
			elseif y == math.ceil(h/2)-math.floor(height/2) and x >= math.ceil(w/2)-math.floor(width/2)+width-3 and x <= math.ceil(w/2)-math.floor(width/2)+width-1 then
				if event == "mouse_click" then
					term.setTextColor(colors.white)
					term.setBackgroundColor(colors.red)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
					write(" × ")
				elseif event == "mouse_up" then
					if redrawscreen ~= nil and redrawscreen == true then
						OGwin.render()
					end
					term.setCursorBlink(oblink)
					return false,0,""
				end
			elseif y == math.ceil(h/2)-math.floor(height/2) and event == "mouse_click" then
				dragging = true
				OGx,OGy = x,y
				OGw = w
				OGh = h
			end
			if (x < math.ceil(w/2)-math.floor(width/2) or x > math.ceil(w/2)-math.floor(width/2)+width-1 or y < math.ceil(h/2)-math.floor(height/2) or y > math.ceil(h/2)-math.floor(height/2)+height-1) and event == "mouse_click" then
				for t=1,5 do
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					term.setBackgroundColor(tbbg2)
					term.setTextColor(tbtxt2)
					write(popupline)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					write(" "..title)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
					write(" × ")
					os.sleep(0.1)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					term.setBackgroundColor(tbbg)
					term.setTextColor(tbtxt)
					write(popupline)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					write(" "..title)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
					write(" × ")
					os.sleep(0.1)
				end
			end
		end
	end
end

function lUtils.inputbox(title,msg,width,height,buttons)
	local OGterm = term.current()
	local OGwin = {lines={}}
	local w,h = term.getSize()
	for t=1,h do
		OGwin.lines[t] = {OGterm.getLine(t)}
	end
	function OGwin.render()
		for l=1,#OGwin.lines do
			term.setCursorPos(1,l)
			term.blit(table.unpack(OGwin.lines[l]))
		end
	end
	dragging = false
	local input = lUtils.makeEditBox("input",width-4,1)
	if width == nil or height == nil then
		width = 21
		height = 7
	end
	if height < 6 then height = 6 end
	popupline = ""
	for pl=1,width do
		popupline = popupline.." "
	end
	local function redrawbox()
	ocursorx,ocursory = term.getCursorPos()
	otext = term.getTextColor()
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
	term.setBackgroundColor(colors.gray)
	term.setTextColor(colors.white)
	write(popupline)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
	write(" "..title)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
	write(" × ")
	-- The line below is unreadable now but it just makes the text box for the popup message and then prints it
	term.setBackgroundColor(colors.white)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+1,math.ceil(h/2)-math.floor(height/2)+1)
	term.write(string.sub(popupline,2,string.len(popupline)-1))
	term.setTextColor(colors.black)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+1)
	lUtils.printBox(lUtils.makeBox(msg,(math.ceil(w/2)-math.floor(width/2))+1,math.ceil(h/2)-math.floor(height/2)+2,(math.ceil(w/2)-math.floor(width/2)+width-1)-1,math.ceil(h/2)-math.floor(height/2)+height-1-3-3,{background={colors.white},text={colors.blue}}),0,true)
	for t=1,height-4 do
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.lightGray)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+t)
		write(string.char(149))
		term.setBackgroundColor(colors.lightGray)
		term.setTextColor(colors.white)
		term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-1,math.ceil(h/2)-math.floor(height/2)+t)
		write(string.char(149))
	end
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+1,math.ceil(h/2)-math.floor(height/2)+height-1-3-2)
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.white)
	write("\159")
	for t=1,width-4 do
		write("\143")
	end
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.lightGray)
	write("\144")
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+1,math.ceil(h/2)-math.floor(height/2)+height-1-3-1)
	term.setBackgroundColor(colors.lightGray)
	term.setTextColor(colors.white)
	write("\149")
	term.setTextColor(colors.lightGray)
	term.setBackgroundColor(colors.white)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+1+width-3,math.ceil(h/2)-math.floor(height/2)+height-1-3-1)
	write("\149")
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+1,math.ceil(h/2)-math.floor(height/2)+height-1-3)
	write("\130")
	for t=1,width-4 do
		write("\131")
	end
	write("\129")
	term.setBackgroundColor(colors.lightGray)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-2)
	write(popupline)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-1)
	write(popupline)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1)
	write(popupline)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-1)
	write(popupline)
	term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2)+height-1-1)
	term.setTextColor(colors.black)
	for b=1,#buttons do
		term.setBackgroundColor(colors.lightGray)
		write(" ")
		term.setBackgroundColor(colors.white)
		write(" "..buttons[b].." ")
	end
	term.setTextColor(otext)
	term.setCursorPos(ocursorx,ocursory)
	end
	redrawbox()
	local function regevents()
	while true do
		event,button,x,y = os.pullEvent()
		if event == "mouse_drag" and dragging == true then
			w = OGw-(OGx-x)*2
			h = OGh-(OGy-y)*2
			OGwin.render()
			redrawbox()
		elseif event == "mouse_click" or event == "mouse_up" then
			if event == "mouse_up" and dragging == true then
				dragging = false
			end
			if y == math.ceil(h/2)-math.floor(height/2)+height-2 then
				curX = math.ceil(w/2)-math.floor(width/2)
				for b=1,#buttons do
					if x >= curX+1 and x <= curX+string.len(" "..buttons[b].." ") then
						if event == "mouse_up" or event == "monitor_touch" then
							return true,b,buttons[b]
						elseif event == "mouse_click" then
							ocursorx,ocursory = term.getCursorPos()
							otext = term.getTextColor()
							term.setCursorPos(curX+1,math.ceil(h/2)-math.floor(height/2)+height-2)
							term.setBackgroundColor(colors.lightBlue)
							term.setTextColor(colors.black)
							write(" "..buttons[b].." ")
							term.setCursorPos(ocursorx,ocursory)
							term.setTextColor(otext)
						end
					end
					curX = curX+string.len(" "..buttons[b].." ")+1
				end
			elseif y == math.ceil(h/2)-math.floor(height/2) and x >= math.ceil(w/2)-math.floor(width/2)+width-3 and x <= math.ceil(w/2)-math.floor(width/2)+width-1 then
				if event == "mouse_click" then
					term.setTextColor(colors.white)
					term.setBackgroundColor(colors.red)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
					write(" × ")
				elseif event == "mouse_up" then
					return false,0,""
				end
			elseif y == math.ceil(h/2)-math.floor(height/2) then
				dragging = true
				OGx,OGy = x,y
				OGw = w
				OGh = h
			else
				redrawbox()
			end
			if (x < math.ceil(w/2)-math.floor(width/2) or x > math.ceil(w/2)-math.floor(width/2)+width-1 or y < math.ceil(h/2)-math.floor(height/2) or y > math.ceil(h/2)-math.floor(height/2)+height-1) and event == "mouse_click" then
				for t=1,5 do
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					term.setBackgroundColor(colors.white)
					term.setTextColor(colors.black)
					write(popupline)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					write(" "..title)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
					write(" × ")
					os.sleep(0.1)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					term.setBackgroundColor(colors.gray)
					term.setTextColor(colors.white)
					write(popupline)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2),math.ceil(h/2)-math.floor(height/2))
					write(" "..title)
					term.setCursorPos(math.ceil(w/2)-math.floor(width/2)+width-3,math.ceil(h/2)-math.floor(height/2))
					write(" × ")
					os.sleep(0.1)
				end
			end
		end
	end
	end
	function readbox()
		c = {"mouse_click",1,math.ceil(w/2)-math.floor(width/2)+2,math.ceil(h/2)-math.floor(height/2)+height-1-3-1}
		while true do
			if c[1] == "mouse_click" and c[3] >= math.ceil(w/2)-math.floor(width/2)+2 and c[3] <= math.ceil(w/2)-math.floor(width/2)+2+(input.width-1) and c[4] == math.ceil(h/2)-math.floor(height/2)+height-1-3-1 then
				if input.lines[1] ~= nil then
					lUtils.drawEditBox(input,math.ceil(w/2)-math.floor(width/2)+2,math.ceil(h/2)-math.floor(height/2)+height-1-3-1,0,0,string.len(input.lines[1])+1,1,true,false)
				else
					lUtils.drawEditBox(input,math.ceil(w/2)-math.floor(width/2)+2,math.ceil(h/2)-math.floor(height/2)+height-1-3-1,0,0,1,1,true,false)
				end
			end
			c = {os.pullEvent("mouse_click")}
		end
	end
	local returnthis = {}
	parallel.waitForAny(readbox,function() returnthis = {regevents()} end)
	term.setCursorBlink(false)
	return input.lines[1],table.unpack(returnthis)
end

function lUtils.createButton(x,y,w,h,lines,func,colrs)
	local btn = {x1=x,y1=y,x2=x+(w-1),y2=y+(h-1),func=func,colors=colrs,selected=false}
	if not btn.colors then
		btn.colors = {}
	end
	local c = btn.colors
	if not c.txt then
		c.txt = colors.white
	end
	if not c.fg then
		c.fg = c.bg or colors.lightGray
	end
	if not c.bg then
		c.bg = colors.gray
	end
	if not c.clicked then
		c.clicked = {}
	end
	local cc = c.clicked
	if not cc.fg then
		cc.fg = cc.bg or colors.lightGray
	end
	if not cc.bg then
		cc.bg = c.bg2 or colors.lightGray
	end
	if not cc.txt then
		cc.txt = c.txt2 or colors.white
	end
	function btn.render()
		local ofg,obg = term.getTextColor(),term.getBackgroundColor()
		if btn.selected then
			term.setBackgroundColor(btn.colors.clicked.bg)
			term.setTextColor(btn.colors.clicked.fg)
		else
			term.setBackgroundColor(btn.colors.bg)
			term.setTextColor(btn.colors.fg)
		end
		lUtils.border(btn.x1,btn.y1,btn.x2,btn.y2,"fill")
		if type(lines) == "string" then
			if btn.selected then
				term.setTextColor(btn.colors.clicked.txt)
			else
				term.setTextColor(btn.colors.txt)
			end
			if btn.y1 == btn.y2 then
				term.setCursorPos(btn.x1,btn.y1)
			else
				term.setCursorPos(btn.x1+1,btn.y1+1)
			end
			term.write(lines)
		end
		term.setTextColor(ofg)
		term.setBackgroundColor(obg)
	end
	function btn.update(...)
		local e = {...}
		if (e[1] == "mouse_click" or e[1] == "mouse_up") and e[2] == 1 then
			if e[3] >= btn.x1 and e[4] >= btn.y1 and e[3] <= btn.x2 and e[4] <= btn.y2 then
				if e[1] == "mouse_click" then
					btn.selected = true
					btn.render()
				elseif e[1] == "mouse_up" and btn.selected then
					btn.selected = false
					btn.render()
					return btn.func()
				end
			end
		end
		if e[1] == "mouse_up" then
			btn.selected = false
		end
	end
	return btn
end
function lUtils.createCanvas(x,y,w,h)
	cvs = {}
	if not (x or y) then
		cvs.x1,cvs.y1 = 1,1
	else
		cvs.x1,cvs.y1 = x,y
	end
	if not (w or h) then
		cvs.x2,cvs.y2 = term.getSize()
	else
		cvs.x2,cvs.y2 = x+(w-1),y+(h-1)
	end
	cvs.objs = {}
	function cvs.clear()
		cvs.objs = {}
	end
	function cvs.update(...)
		for o=1,#cvs.objs do
			cvs.objs[o].update(...)
		end
	end
	function cvs.render()
		for o=1,#cvs.objs do
			cvs.objs[o].render()
		end
	end
	function cvs.createButton(...)
		local b = lUtils.createButton(...)
		if b then
			cvs.objs[#cvs.objs+1] = b
			return b
		else
			return false
		end
	end
	return cvs
end
function lUtils.contextmenu(x,y,width,options,colorScheme,dividers)
	-- elements are either string OR table, table contains txt and optionally: disabled (bool), action (function or table (for nested context menu)), color (number)
	local mColors = colorScheme or {}
	mColors.fg = mColors.fg or colors.lightGray
	mColors.bg = mColors.bg or colors.gray
	mColors.txt = mColors.txt or colors.white
	mColors.disabled = mColors.disabled or colors.lightGray
	mColors.divider = mColors.divider or mColors.fg
	mColors.selected = mColors.selected or mColors.select or mColors.fg
	local w = 0
	if not width then
		width = "auto"
	end
	if type(width) == "number" then
		w = width
	end
	local function genContextMenu(opt,x,y,w)
		local h = 2
		local objects = {}
		local cY = 1
		local function addObject(obj,parent)
			obj.y = cY
			obj.parent = opt
			obj.parentObj = parent
			table.insert(objects,obj)
			cY = cY+1
			h = h+1
			if not obj.action then obj.action = "output" end
			if obj.txt then
				local nW
				if type(obj.txt) == "table" then
					nW = #obj.txt[1]+2
				else
					nW = #obj.txt+2
				end
				if type(obj.action) == "table" then
					nW = nW+2
				end
				if nW > w then
					w = nW
				end
			end
		end
		local acceptable = {["string"]=true,["table"]=true}
		local lID = 1
		for i,o in ipairs(opt) do
			if i > 1 and dividers then
				addObject({action="divider"})
			end
			if type(o) == "string" then
				addObject({action="output",txt=o,id=lID})
				lID = lID+1
			elseif type(o) == "table" and acceptable[type(o.txt)] then
				addObject(o)
				o.id = lID
				lID = lID+1
			elseif type(o) == "table" then
				for k,v in ipairs(o) do
					local lID2 = 1
					if type(v) == "string" then
						addObject({action="output",txt=v,id=lID2},o)
						lID2 = lID2+1
					elseif type(v) == "table" and acceptable[type(v.txt)] then
						addObject(v,o)
						v.id = lID2
						lID2 = lID2+1
					end
				end
				o.id = lID
				lID = lID+1
				o.parent = opt
			end
		end
		objects.x,objects.y,objects.w,objects.h = x,y,w,h
		objects.x1,objects.y1 = x,y
		objects.x2,objects.y2 = x+w-1,y+h-1
		objects.rObjs = {}
		objects.scroll = 0
		return objects
	end
	local objects,h
	objects = genContextMenu(options,x,y,w)
	objects.status = "idle"
	local function positionMenu(menu)
		local tW,tH = term.getSize()
		if menu.y+menu.h-1 > tH then
			if menu.y-menu.h+1 >= 1 then
				menu.y = menu.y-menu.h+1
			elseif menu.h <= tH then
				while menu.y+menu.h-1 > tH do
					menu.y = menu.y-1
				end
			else
				menu.y = 1
			end
		end
		-- repeat for X axis
		if menu.x+menu.w-1 > tW then
			if menu.x-menu.w+1 >= 1 then
				menu.x = menu.x-menu.w+1
			elseif menu.w <= tW then
				while menu.x+menu.w-1 > tW do
					menu.x = menu.x-1
				end
			else
				menu.x = 1
				-- turn on scroll
			end
		end
	end
	positionMenu(objects)
	local menus = {objects}
	local function renderMenu(menu)
		local tW,tH = term.getSize()
		while menu.y+menu.h-1 > tH do
			menu.h = menu.h-1
		end
		menu.x1,menu.y1 = menu.x,menu.y
		menu.x2,menu.y2 = menu.x+menu.w-1,menu.y+menu.h-1
		menu.bg = menu.bg or mColors.bg
		menu.fg = menu.fg or mColors.fg
		menu.txt = menu.txt or mColors.txt
		menu.divider = menu.divider or mColors.divider
		menu.disabled = menu.disabled or mColors.disabled
		menu.selColor = menu.selColor or mColors.selected
		dividerline = string.rep("\140",menu.w-2)
		term.setBackgroundColor(menu.bg)
		term.setTextColor(menu.fg)
		lUtils.border(menu.x,menu.y,menu.x+menu.w-1,menu.y+menu.h-1,"fill")
		for k=1+menu.scroll,(menu.h-2)+menu.scroll do
			local v = menu[k]
			term.setCursorPos(menu.x+1,menu.y+v.y-menu.scroll)
			if menu.scroll > 0 and k == 1+menu.scroll then
				term.setBackgroundColor(menu.bg)
				term.setTextColor(menu.txt)
				term.setCursorPos(menu.x+math.ceil(menu.w/2)-1,menu.y+1)
				term.write("\30")
			elseif k == (menu.h-2)+menu.scroll and k < #menu then
				term.setBackgroundColor(menu.bg)
				term.setTextColor(menu.txt)
				term.setCursorPos(menu.x+math.ceil(menu.w/2)-1,menu.y2-1)
				term.write("\31")
			else
				if menu.selected == v then
					term.setBackgroundColor(menu.selColor)
				else
					term.setBackgroundColor(v.bg or menu.bg)
				end
				if v.action == "divider" then
					term.setTextColor(menu.divider)
					term.write(dividerline)
				else
					if v.disabled then
						term.setTextColor(v.color or menu.disabled)
					else
						term.setTextColor(v.color or menu.txt)
					end
					if type(v.txt) == "table" then
						if not v.txt[2] then v.txt[2] = "" end
						if not v.txt[3] then v.txt[3] = "" end
						local bl = {
							v.txt[1]..string.rep(" ",(menu.w-2)-#v.txt[1]),
							v.txt[2]..string.rep(lUtils.toBlit(term.getTextColor()),(menu.w-2)-#v.txt[2]),
							v.txt[3]..string.rep(lUtils.toBlit(term.getBackgroundColor()),(menu.w-2)-#v.txt[3]),
						}
						term.blit(unpack(bl))
					else
						term.write(v.txt..string.rep(" ",(menu.w-2)-#v.txt))
					end
					if type(v.action) == "table" then
						term.setCursorPos(menu.x+menu.w-2,menu.y+v.y-menu.scroll)
						term.write(">")
					end
				end
			end
		end
	end
	function objects.render()
		for m=1,#menus do
			renderMenu(menus[m])
		end
	end
	function objects.update(...)
		if objects.status == "dead" then return false end
		objects.status = "running"
		local e = {...}
		if e[1]:find("mouse") and e[3] and e[4] then
			for m=#menus,1,-1 do
				local menu = menus[m]
				local oselected = menu.selected
				if e[1] == "mouse_click" or e[1] == "mouse_move" then
					menu.selected = nil
				end
				if not lUtils.isInside(e[3],e[4],menu) then
					if e[1] == "mouse_click" then
						table.remove(menus,m)
						if m == 1 then
							objects.status = "dead"
							return
						end
					end
				else
					if e[1] == "mouse_scroll" then
						if e[2] == -1 and menu.scroll > 0 then
							menu.scroll = menu.scroll-1
						elseif e[2] == 1 and (menu.h-2)+menu.scroll < #menu then
							menu.scroll = menu.scroll+1
						end
					elseif e[3] > menu.x and e[3] < menu.x+menu.w-1 then
						if e[4] == menu.y+1 and menu.scroll > 0 then
							if e[1] == "mouse_click" then
								menu.scroll = menu.scroll-1
							end
						elseif e[4] == menu.y2-1 and (menu.h-2)+menu.scroll < #menu then
							if e[1] == "mouse_click" then
								menu.scroll = menu.scroll+1
							end
						else
							for i=1+menu.scroll,(menu.h-2)+menu.scroll do
								local o = menu[i]
								if e[4] == o.y+menu.y-menu.scroll then
									if o.action == "divider" or o.disabled then
										break
									end
									-- check action
									if e[1] == "mouse_up" and menu.selected == o then
										if type(o.action) == "function" then
											o.action(o)
											objects.clicked = o
											objects.status = "dead"
											return o
										elseif type(o.action) == "table" then
											local submenu = genContextMenu(o.action,menu.x+menu.w-1,menu.y+o.y-menu.scroll-1,o.action.w or 0)
											o.action.parent = o
											local tW,tH = term.getSize()
											if submenu.y+submenu.h-1 > tH and (submenu.y+2)-submenu.h+1 >= 1 then
												submenu.y = (submenu.y+2)-submenu.h+1
											else
												positionMenu(submenu)
											end
											table.insert(menus,submenu)
										elseif type(o.action) == "string" then
											-- idk what to return
											objects.clicked = o
											objects.status = "dead"
											return o
										end
									elseif e[1] == "mouse_up" then
										menu.selected = nil
									elseif e[1] == "mouse_click" or e[1] == "mouse_move" then
										menu.selected = o
										if e[1] == "mouse_click" then
											if menu.oselected == menu.selected then
												menu.selected = nil
												menu.oselected = nil
											else
												menu.oselected = o
											end
										end
									end
									break
								end
							end
						end
					end
					break
				end
			end
		end
		objects.status = "idle"
	end
	function objects.run()
		objects.render()
		while objects.status ~= "dead" do
			objects.update(os.pullEvent())
			objects.render()
		end
		return objects.clicked
	end
	return objects
end

function lUtils.clickmenu(x,y,w,options,redrawscreen,disabled,preferredColors)
	local function disable(opt)
		if opt.txt and disabled[opt.txt] then
			opt.disabled = true
		end
		for o=1,#opt do
			if type(opt[o]) == "table" then
				disable(opt[o])
			elseif type(opt[o]) == "string" and disabled[opt[o]] then
				opt[o] = {txt=opt[o],action="output",disabled=true}
			end
		end
	end
	if disabled then
		disable(options)
	end
	local menu = lUtils.contextmenu(x,y,w,options,preferredColors,true)
	local clicked = menu.run()
	if not clicked then
		return false,0
	else
		if clicked.parentObj then
			return true,clicked.parentObj.id,clicked.txt,clicked.id
		else
			return true,clicked.id,clicked.txt
		end
	end
end

function lUtils.isInside(x,y,object)
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