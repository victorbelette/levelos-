local assets = {
  [ "bgwindow.lua" ] = {
    id = 8,
    content = "local sl = shapescape.getSlides()\
local win = sl[1].win\
\
local function draw()\
	local w,h = term.getSize()\
	for y=1,h do\
		term.setCursorPos(1,y)\
		term.blit(win.getLine(y))\
	end\
end\
\
draw()\
\
while true do\
	local e = {os.pullEvent()}\
	draw()\
end",
    name = "bgwindow.lua",
  },
  [ "cancel.lua" ] = {
    id = 16,
    content = "shapescape.exit()",
    name = "cancel.lua",
  },
  [ "viewlist.lua" ] = {
    id = 21,
    content = "local e = {shapescape.getEvent()}\
local sl = shapescape.getSlides()\
local scolor = colors.lightGray\
if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) then\
	self.ocolor = self.txtcolor\
	self.txtcolor = scolor\
elseif e[1] == \"mouse_up\" then\
	if self.txtcolor == scolor and lUtils.isInside(e[3],e[4],self) then\
		sl.rMode = 1\
		sl.config.modes[sl.folder] = nil\
		sl.saveConfig()\
		os.queueEvent(\"explorer_reload\")\
	end\
	if self.ocolor then\
		self.txtcolor = self.ocolor\
		self.ocolor = nil\
	end\
end\
if sl.rMode == 1 then\
	self.color = colors.lightGray\
else\
	self.color = 0\
end",
    name = "viewlist.lua",
  },
  [ "sidedragthingy.lua" ] = {
    id = 4,
    content = "local drag = false\
local s = shapescape.getSlide()\
local sl = shapescape.getSlides()\
while not sl.config do os.pullEvent() end\
s.sidebar.x2 = sl.config.sidebar.width\
self.x1 = s.sidebar.x2-1\
self.x2 = self.x1+2\
s.main.x1 = self.x2+1\
while true do\
	local e = {os.pullEvent()}\
	if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) then\
		drag = true\
	elseif e[1] == \"mouse_drag\" and drag then\
		self.x1,self.x2 = e[3]-2,e[3]\
		s.sidebar.x2 = self.x2-1\
		s.main.x1 = self.x2+1\
	elseif e[1] == \"mouse_up\" and drag then\
		sl.config.sidebar.width = s.sidebar.x2\
		sl.saveConfig()\
		drag = false\
	end\
end",
    name = "sidedragthingy.lua",
  },
  [ "bottombar.lua" ] = {
    id = 11,
    content = "local sl = shapescape.getSlides()\
local str = {}\
if sl.files then\
	if #sl.files == 1 then\
		table.insert(str,\"1 item | \")\
	else\
		table.insert(str,#sl.files)\
		table.insert(str,\" items | \")\
	end\
end\
if sl.selected then\
	local size = 0\
	local count = 0\
	for k,v in pairs(sl.selected) do\
		if size and not v.isDir then\
			size = size+v.size\
		else\
			size = nil\
		end\
		count = count+1\
	end\
	if count > 0 then\
		if count == 1 then\
			table.insert(str,\"1 item selected\")\
		else\
			table.insert(str,count)\
			table.insert(str,\" items selected\")\
		end\
		if size then\
			table.insert(str,string.format(\" %.1f kB\",math.floor(size/100+0.5)/10))\
		end\
		table.insert(str,\" | \")\
	end\
end\
self.txt = table.concat(str)",
    name = "bottombar.lua",
  },
  [ "hPrevious.lua" ] = {
    id = 5,
    content = "local sl = shapescape.getSlides()\
local e = {shapescape.getEvent()}\
if not sl.history then return end\
if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) and #sl.history > 1 then\
	self.txtcolor = colors.blue\
elseif e[1] == \"mouse_up\" and #sl.history > 1 then\
	self.txtcolor = colors.white\
	if lUtils.isInside(e[3],e[4],self) then\
		sl.folder = sl.history[#sl.history-1]\
		table.insert(sl.rhistory,sl.history[#sl.history])\
		sl.history[#sl.history] = nil\
		sl.ofolder = sl.folder\
	end\
elseif e[1] == \"mouse_move\" and #sl.history > 1 then\
	if e[3] and e[4] and lUtils.isInside(e[3],e[4],self) then\
		self.txtcolor = colors.lightBlue\
	else\
		self.txtcolor = colors.white\
	end\
end\
if self.txtcolor ~= colors.blue and self.txtcolor ~= colors.lightBlue then\
	if #sl.history <= 1 then\
		self.txtcolor = colors.gray\
	else\
		self.txtcolor = colors.white\
	end\
end",
    name = "hPrevious.lua",
  },
  [ "searchrender.lua" ] = {
    id = 3,
    content = "local x,y = term.getCursorPos()\
term.setBackgroundColor(colors.black)\
term.setTextColor(colors.gray)\
lUtils.border(self.x1-1,self.y1-1,self.x2+1,self.y2+1,nil,2)\
if self.txt == \"\" then\
	term.setCursorPos(self.x1,self.y1)\
	term.setTextColor(colors.gray)\
	term.write(\"Search...\")\
end\
term.setCursorPos(x,y)\
term.setTextColor(colors.white)",
    name = "searchrender.lua",
  },
  [ "hList.lua" ] = {
    id = 12,
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
local e = {shapescape.getEvent()}\
if not sl.history then return end\
if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) and (#sl.history > 1 or #sl.rhistory > 0) then\
	self.txtcolor = colors.blue\
elseif e[1] == \"mouse_up\" and (#sl.history > 1 or #sl.rhistory > 0) then\
	self.txtcolor = colors.white\
	if lUtils.isInside(e[3],e[4],self) then\
		--[[sl.folder = sl.history[#sl.history-1]\
		table.insert(sl.rhistory,sl.history[#sl.history])\
		sl.history[#sl.history] = nil\
		sl.ofolder = sl.folder]]\
		local opt = {}\
		local function jump(obj)\
			local to = obj.id\
			sl.rhistory = {}\
			sl.history = {}\
			for t=1,#opt do\
				if t < to then\
					table.insert(sl.rhistory,opt[t].file)\
				elseif t >= to then\
					table.insert(sl.history,1,opt[t].file)\
				end\
			end\
			sl.folder = obj.file\
			sl.ofolder = obj.file\
		end\
		for i=1,#sl.rhistory do\
			table.insert(opt,{txt=\"  \"..sl.getName(sl.rhistory[i]),file=sl.rhistory[i],action=jump})\
		end\
		table.insert(opt,{txt=\"\\7 \"..sl.getName(sl.history[#sl.history]),file=sl.history[#sl.history],action=jump})\
		for i=#sl.history-1,1,-1 do\
			table.insert(opt,{txt=\"  \"..sl.getName(sl.history[i]),file=sl.history[i],action=jump})\
		end\
		for i=1,#opt do\
			opt[i].id = i\
		end\
		lOS.contextmenu(2,self.y2+2,0,opt,{fg=colors.white,bg=colors.gray,txt=colors.white,divider=colors.gray,selected=colors.lightGray},true)\
	end\
elseif e[1] == \"mouse_move\" and (#sl.history > 1 or #sl.rhistory > 0) then\
	if e[3] and e[4] and lUtils.isInside(e[3],e[4],self) then\
		self.txtcolor = colors.lightBlue\
	else\
		self.txtcolor = colors.white\
	end\
end\
if self.txtcolor ~= colors.blue and self.txtcolor ~= colors.lightBlue then\
	if #sl.history <= 1 and #sl.rhistory <= 0 then\
		self.txtcolor = colors.gray\
	else\
		self.txtcolor = colors.white\
	end\
end",
    name = "hList.lua",
  },
  [ "owtxt.lua" ] = {
    id = 10,
    content = "local sl = shapescape.getSlides()\
local file = sl.OWfile\
if file and file.type then\
	self.txt = \"Always use this app for .\"..file.type..\" files\"\
end",
    name = "owtxt.lua",
  },
  [ "viewicons.lua" ] = {
    id = 22,
    content = "local e = {shapescape.getEvent()}\
local sl = shapescape.getSlides()\
local scolor = colors.lightGray\
if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) then\
	self.ocolor = self.txtcolor\
	self.txtcolor = scolor\
elseif e[1] == \"mouse_up\" then\
	if self.txtcolor == scolor and lUtils.isInside(e[3],e[4],self) then\
		sl.rMode = 2\
		sl.config.modes[sl.folder] = 2\
		sl.saveConfig()\
		os.queueEvent(\"explorer_reload\")\
	end\
	if self.ocolor then\
		self.txtcolor = self.ocolor\
		self.ocolor = nil\
	end\
end\
if sl.rMode == 2 then\
	self.color = colors.lightGray\
else\
	self.color = 0\
end",
    name = "viewicons.lua",
  },
  [ "select.lua" ] = {
    id = 15,
    content = "local sl = shapescape.getSlides()\
sl.fpathbox.state = true\
os.queueEvent(\"key\",keys.enter)",
    name = "select.lua",
  },
  [ "dropdown.lua" ] = {
    id = 13,
    content = "self.txt = \"\"\
local sl = shapescape.getSlides()\
if sl.dropdown then\
	lOS.contextmenu(unpack(sl.dropdown))\
	sl.dropdown = nil\
end",
    name = "dropdown.lua",
  },
  [ "owok.lua" ] = {
    id = 19,
    content = "local s = shapescape.getSlide()\
local sl = shapescape.getSlides()\
local e = {shapescape.getEvent()}\
if s.selected then\
	if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) then\
		self.isSel = true\
	elseif e[1] == \"mouse_up\" then\
		if lUtils.isInside(e[3],e[4],self) and self.isSel then\
			self.isSel = false\
			-- run the thang\
			sl.OWprogram = s.selected\
			fTypes = lUtils.asset.load(\"LevelOS/data/formats.lconf\")\
			local t = sl.OWfile.type\
			local p = sl.OWprogram.path\
			if s.checkbox.isOn then\
				local deskIcons = lUtils.asset.load(\"LevelOS/assets/Desktop_Icons.limg\")\
				if not fTypes[t] then\
					fTypes[t] = {name=t:upper()..\"-File\",program=p,contextMenu={{\"Open\"},{p}},openWith={p},icon=deskIcons[4]}\
				else\
					fTypes[t].program = p\
					if fTypes[t].openWith and not sl.locateEntry(fTypes[t].openWith,p) then\
						table.insert(fTypes[t].openWith,1,p)\
					end\
				end\
				lUtils.asset.save(fTypes,\"LevelOS/data/formats.lconf\",false)\
				sl.fullReload = true\
			else\
				if fTypes[t] and fTypes[t].openWith and not sl.locateEntry(fTypes[t].openWith,p) then\
					table.insert(fTypes[t].openWith,p)\
					lUtils.asset.save(fTypes,\"LevelOS/data/formats.lconf\",false)\
					sl.fullReload = true\
				end\
			end\
			s.reset = true\
			sl.OWfile = nil\
			shapescape.setSlide(1)\
		end\
		self.isSel = false\
	end\
	if self.isSel then\
		self.color = colors.black\
	else\
		self.color = colors.gray\
	end\
	self.txtcolor = colors.white\
else\
	self.color = colors.lightGray\
	self.txtcolor = colors.gray\
end",
    name = "owok.lua",
  },
  [ "folderUp.lua" ] = {
    id = 7,
    content = "local sl = shapescape.getSlides()\
local e = {shapescape.getEvent()}\
if not sl.folder then return end\
local cPath = sl.split_path(sl.folder)\
if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) and #cPath > 0 then\
	self.txtcolor = colors.blue\
elseif e[1] == \"mouse_up\" and #cPath > 0 then\
	self.txtcolor = colors.white\
	if lUtils.isInside(e[3],e[4],self) then\
		sl.folder = fs.getDir(sl.folder)\
	end\
elseif e[1] == \"mouse_move\" and #cPath > 0 then\
	if e[3] and e[4] and lUtils.isInside(e[3],e[4],self) then\
		self.txtcolor = colors.lightBlue\
	else\
		self.txtcolor = colors.white\
	end\
end\
if self.txtcolor ~= colors.blue and self.txtcolor ~= colors.lightBlue then\
	if #cPath <= 0 then\
		self.txtcolor = colors.gray\
	else\
		self.txtcolor = colors.white\
	end\
end",
    name = "folderUp.lua",
  },
  [ "filepathbox.lua" ] = {
    id = 14,
    content = "local sl = shapescape.getSlides()\
sl.fpathbox = self\
while true do\
	local e = {os.pullEvent()}\
	if e[1] == \"key\" and e[2] == keys.enter and self.state then\
		local rtbl = {}\
		if self.changed then\
			if not self.txt:find('\"') then\
				table.insert(rtbl,fs.combine(sl.folder,self.txt))\
			else\
				for pth in str:gmatch('\"([^\"]*)\"') do\
					table.insert(rtbl,fs.combine(sl.folder,pth))\
				end\
			end\
		else\
			for k,v in pairs(sl.ret) do\
				table.insert(rtbl,(k))\
			end\
		end\
		shapescape.exit(rtbl)\
	end\
end",
    name = "filepathbox.lua",
  },
  [ "owlist.lua" ] = {
    id = 17,
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
local programs = {}\
local porder = {}\
local dIcons = lUtils.asset.load(\"LevelOS/assets/Desktop_Icons.limg\")\
local function findPrograms(pth)\
	local list = fs.list(pth)\
	local foundProgram = false\
	local folders = {}\
	if pth ~= \"Program_Files\" and fs.exists(fs.combine(pth,\"main.lua\")) then\
		foundProgram = true\
	else\
		for f=1,#list do\
			local pr = fs.combine(pth,list[f])\
			if fs.isDir(pr) then\
				table.insert(folders,pr)\
			elseif lUtils.getFileType(pr) == \".lua\" or lUtils.getFileType(pr) == \"\" then\
				if pth ~= \"Program_Files\" then\
					foundProgram = true\
					break\
				else\
					local p = {path=pr,name=sl.getName(pr)}\
					local ext = lUtils.getFileType(pr)\
					p.name = p.name:sub(1,#p.name-#ext)\
					p.icon = dIcons[3]\
					programs[p.path] = p\
				end\
			end\
		end\
	end\
	if foundProgram then\
		local p = {path=pth,name=sl.getName(pth)}\
		if fs.exists(fs.combine(pth,\"icon.limg\")) then\
			p.icon = lUtils.asset.load(fs.combine(pth,\"icon.limg\"))[1]\
		end\
		programs[p.path] = p\
	else\
		for t=1,#folders do\
			findPrograms(folders[t])\
		end\
	end\
end\
local scrollY\
local mSelect\
local selected\
local function generate()\
	programs = {} -- add lua option with lua icon and stuff\
	programs[\"Lua\"] = {name=\"Lua\",path=\"Lua\"}\
	programs[\"rom/programs/edit.lua\"] = {name=\"Edit\",path=\"rom/programs/edit.lua\"} -- add icon here too wait i dont even have one so make one ig\
	local p = {name=\"Paint\",path=\"rom/programs/fun/advanced/paint.lua\"}\
	programs[p.path] = p\
	programs[\"LevelOS/notepad.lua\"] = {name=\"Notepad\",path=\"LevelOS/notepad.lua\",icon={{\"\\159\\159 \",\"   \",\"77 \"},{\"\\157\\141\\149\",\"888\",\"77 \"},{\"\\136\\140\\149\",\"778\",\"88 \"}}}\
	findPrograms(\"Program_Files\")\
	porder = {}\
	for k,v in pairs(programs) do\
		table.insert(porder,k)\
	end\
	table.sort(porder,function(a,b) return programs[a].name:lower() < programs[b].name:lower() end)\
	scrollY = 0\
	mSelect = nil\
	selected = nil\
end\
local function render()\
	-- idk\
	term.setBackgroundColor(colors.white)\
	term.clear()\
	local y = 1-scrollY\
	local w,h = term.getSize()\
	for k,v in ipairs(porder) do\
		local p = programs[v]\
		if selected == p then\
			term.setBackgroundColor(colors.gray)\
			term.setTextColor(colors.white)\
		elseif mSelect == p then\
			term.setBackgroundColor(colors.lightGray)\
			term.setTextColor(colors.black)\
		else\
			term.setBackgroundColor(colors.white)\
			term.setTextColor(colors.black)\
		end\
		lOS.boxClear(1,y,w,y+2)\
		if p.icon then\
			lUtils.renderImg(p.icon,2,y)\
		else\
			lUtils.renderImg(dIcons[3],2,y)\
		end\
		term.setCursorPos(6,y+1)\
		term.write(p.name)\
		y = y+3\
	end\
end\
generate()\
render()\
while true do\
	local e = {os.pullEvent()}\
	if s.reset and sl.OWfile then\
		s.reset = false\
		generate()\
	end\
	local w,h = term.getSize()\
	if e[1] == \"mouse_move\" or e[1] == \"mouse_click\" then\
		mSelect = nil\
	end\
	if e[1]:find(\"mouse\") and e[3] and e[4] and lUtils.isInside(e[3],e[4],{x1=1,y1=1,x2=w,y2=h}) then\
		if e[1] == \"mouse_up\" then\
			selected = nil\
		end\
		if e[1] == \"mouse_scroll\" then\
			-- stuff\
			if (e[2] == -1 and scrollY > 0) or (e[2] == 1 and scrollY < (#porder*3-h)) then\
				scrollY = scrollY+e[2]\
			end\
			render()\
		elseif e[1] == \"mouse_click\" or e[1] == \"mouse_move\" or e[1] == \"mouse_up\" then\
			local y = math.ceil((e[4]+scrollY)/3)\
			if porder[y] then\
				local p = programs[porder[y]]\
				if e[1] == \"mouse_up\" and mSelect == p then\
					selected = p\
				elseif e[1] == \"mouse_click\" or e[1] == \"mouse_move\" then\
					mSelect = p\
				end\
				render()\
			end\
		end\
	end\
	if e[1] == \"mouse_up\" then\
		mSelect = nil\
	end\
	s.selected = selected\
end",
    name = "owlist.lua",
  },
  [ "owcheckbox.lua" ] = {
    id = 18,
    content = "local e = {shapescape.getEvent()}\
local s = shapescape.getSlide()\
s.checkbox = self\
if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) then\
	self.isSel = true\
elseif e[1] == \"mouse_up\" then\
	if lUtils.isInside(e[3],e[4],self) and self.isSel then\
		self.isOn = not self.isOn\
	end\
	self.isSel = false\
end\
if self.isSel then\
	self.color = colors.black\
elseif self.isOn then\
	self.color = colors.green\
	self.border.color = colors.gray\
else\
	self.color = colors.white\
	self.border.color = colors.lightGray\
end",
    name = "owcheckbox.lua",
  },
  [ "openwithwhite.lua" ] = {
    id = 9,
    content = "local clickoutside = false\
local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
while true do\
	local e = {os.pullEvent()}\
	if e[1] == \"mouse_click\" then\
		if lUtils.isInside(e[3],e[4],self) then\
			clickoutside = false\
		else\
			clickoutside = true\
		end\
	elseif e[1] == \"mouse_up\" then\
		if clickoutside and not lUtils.isInside(e[3],e[4],self) then\
			clickoutside = false\
			s.reset = true\
			sl.OWfile = nil\
			shapescape.setSlide(1)\
		end\
	end\
end",
    name = "openwithwhite.lua",
  },
  [ "hNext.lua" ] = {
    id = 6,
    content = "local sl = shapescape.getSlides()\
local e = {shapescape.getEvent()}\
if not sl.history then return end\
if e[1] == \"mouse_click\" and lUtils.isInside(e[3],e[4],self) and #sl.rhistory > 0 then\
	self.txtcolor = colors.blue\
elseif e[1] == \"mouse_up\" and #sl.rhistory > 0 then\
	self.txtcolor = colors.white\
	if lUtils.isInside(e[3],e[4],self) then\
		sl.folder = sl.rhistory[#sl.rhistory]\
		sl.rhistory[#sl.rhistory] = nil\
		sl.ofolder = sl.folder\
		table.insert(sl.history,sl.folder)\
	end\
elseif e[1] == \"mouse_move\" and #sl.rhistory > 0 then\
	if e[3] and e[4] and lUtils.isInside(e[3],e[4],self) then\
		self.txtcolor = colors.lightBlue\
	else\
		self.txtcolor = colors.white\
	end\
end\
if self.txtcolor ~= colors.blue and self.txtcolor ~= colors.lightBlue then\
	if #sl.rhistory <= 0 then\
		self.txtcolor = colors.gray\
	else\
		self.txtcolor = colors.white\
	end\
end",
    name = "hNext.lua",
  },
  [ "tree.lua" ] = {
    id = 1,
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
s.sidebar = self\
local objs = {}\
local tree = {\"Quick access\",\"LevelCloud\",\"This PC\",\"Local disk\",path=\"\"}\
local function genTree(tEntry)\
	local list = fs.list(tEntry.path)\
	for i,f in ipairs(tEntry) do\
		tEntry[i] = nil\
	end\
	for f=1,#list do\
		if fs.isDir(fs.combine(tEntry.path,list[f])) then\
			tEntry[#tEntry+1] = list[f]\
		end\
	end\
end\
tree[\"Quick access\"] = {\
	path=\"Quick access\",\
	nopath=true,\
	open=true,\
}\
local function reloadQuickAccess()\
	if not sl.config.quickaccess then sl.config.quickaccess = {} return end\
	local l = sl.config.quickaccess\
	for t=#tree[\"Quick access\"],1,-1 do\
		tree[\"Quick access\"][\"Quick access/\"..tree[\"Quick access\"][t]] = nil\
		table.remove(tree[\"Quick access\"],t)\
	end\
	for t=1,#l do\
		local n = sl.getName(l[t])\
		tree[\"Quick access\"][#tree[\"Quick access\"]+1] = n\
		tree[\"Quick access\"][\"Quick access/\"..n] = {\
			path = l[t],\
			open = false,\
		}\
	end\
end\
reloadQuickAccess()\
sl.reloadQuickAccess = reloadQuickAccess\
--[[tree[\"Quick access\"][\"Quick access/LevelOS\"] = {\
	path=\"User/Cloud/Public/LevelOS\",\
	open=false,\
}]]\
if fs.exists(\"User/Cloud\") then\
	tree[\"LevelCloud\"] = {\
		path=\"User/Cloud\",\
		open=false,\
		auto=true,\
	}\
end\
tree[\"This PC\"] = {\
	path=\"User\",\
	open=true,\
	\"Desktop\",\
	\"Documents\",\
	\"Downloads\",\
	\"Games\",\
	\"Images\",\
	\"Music\",\
	\"Scripts\",\
}\
--[[for t=#tree[\"This PC\"]-2,1,-1 do\
	if not fs.exists(fs.combine(tree[\"This PC\"].path,tree[\"This PC\"][t])) then\
		table.remove(tree[\"This PC\"],t)\
	end\
end]]\
tree[\"Local disk\"] = {\
	path=\"\",\
	open=false,\
	auto=true,\
}\
for k=#sl.disks,1,-1 do\
	local v = sl.disks[k]\
	local dPath = v.getMountPath()\
	local dName = sl.getName(dPath)\
	tree[\"This PC\"][#tree[\"This PC\"]+1] = dName\
	tree[\"This PC\"][\"User/\"..dName] = {path=dPath,open=false,auto=true}\
	genTree(tree[\"This PC\"][\"User/\"..dName])\
end\
table.insert(tree,\"rom\")\
tree[\"rom\"] = {\
	path=\"rom\",\
	open=false,\
}\
if tree[\"LevelCloud\"] then\
	genTree(tree[\"LevelCloud\"])\
end\
genTree(tree[\"Local disk\"])\
genTree(tree[\"rom\"])\
--local cList = fs.list(dir)\
local x,y = 0,1\
local symbols = {\
	[\"Quick access\"]   = {symbol=\"*\",color=colors.blue},\
	[\"User/Cloud\"]     = {symbol=\"\",color=colors.blue},\
	[\"\"]               = {symbol=\"\",color=colors.lightGray},\
	[\"rom\"]            = {symbol=\"\",color=colors.red},\
	[\"User\"]           = {symbol=\"\",color=colors.lightBlue},\
	[\"User/Desktop\"]   = {symbol=\"\",color=colors.lightBlue},\
	[\"User/Documents\"] = {symbol=\"\",color=colors.lightGray},\
	[\"User/Downloads\"] = {symbol=\"\",color=colors.blue},\
	[\"User/Images\"]    = {symbol=\"\",color=colors.lightBlue},\
	[\"User/Scripts\"]   = {symbol=\"\",color=colors.cyan},\
	[\"User/Games\"]     = {symbol=\"\",color=colors.lightGray},\
	[\"User/Music\"]     = {symbol=\"\",color=colors.blue},\
}\
sl.symbols = symbols\
local selected1\
local selected2\
local scrollY = 0\
local hadselected = false\
local function updateTree(tree)\
	for i=#tree,1,-1 do\
		local f = tree[i]\
		local file = fs.combine(tree.path,f)\
		if not fs.exists(file) then\
			tree[file] = nil\
		end\
		tree[i] = nil\
	end\
	local ls = fs.list(tree.path)\
	for f=1,#ls do\
		local file = fs.combine(tree.path,ls[f])\
		if fs.isDir(file) then\
			tree[#tree+1] = ls[f]\
			if tree[file] and tree.auto then\
				updateTree(tree[file])\
			end\
		end\
	end\
end\
local function updateFullTree()\
	for k,v in ipairs(tree) do\
		if tree[v] and tree[v].auto then\
			updateTree(tree[v])\
		end\
	end\
end\
sl.updateFullTree = updateFullTree\
local function renderTree(tree)\
	x = x+1\
	for i,f in ipairs(tree) do\
		local file = fs.combine(tree.path,f)\
		if not tree[file] then\
			if not fs.exists(file) then\
				--error(\"No tree[\"..file..\"]!\")\
			else\
				tree[file] = {path=file,open=false,auto=true}\
				genTree(tree[file])\
			end\
		end\
		local t = tree[file]\
		if t and (fs.exists(t.path) or t.nopath) then\
			t.x,t.y = x,y\
			objs[#objs+1] = t\
			term.setCursorPos(x,y)\
			local selected\
			if sl.folder and not hadselected then\
				selected = ((t.open and t.path == sl.folder) or (not t.open and string.find(sl.folder..\"/\",t.path..\"/\",nil,true) == 1))\
			end\
			if selected then\
				term.setBackgroundColor(colors.gray)\
				hadselected = true\
			else\
				term.setBackgroundColor(colors.black)\
			end\
			term.clearLine()\
			term.setCursorPos(x,y)\
			y = y+1\
			if t.open then\
				if selected2 == t then\
					term.setTextColor(colors.blue)\
				elseif selected then\
					term.setTextColor(colors.white)\
				else\
					term.setTextColor(colors.lightGray)\
				end\
				term.write(\" \")\
			elseif #t > 0 then\
				if selected2 == t then\
					term.setTextColor(colors.blue)\
				elseif selected then\
					term.setTextColor(colors.lightGray)\
				else\
					term.setTextColor(colors.gray)\
				end\
				term.write(\" \")\
			else\
				term.write(\"  \")\
			end\
			if symbols[t.path] then\
				term.setTextColor(symbols[t.path].color)\
				term.write(symbols[t.path].symbol..\" \")\
			elseif sl.disks[t.path] then\
				term.setTextColor(colors.blue)\
				term.write(\" \")\
			else\
				term.setTextColor(colors.yellow)\
				term.write(\" \")\
			end\
			if selected1 == t then\
				term.setTextColor(colors.lightGray)\
			elseif fs.isReadOnly(t.path) then\
				term.setTextColor(colors.lightGray)\
			else\
				term.setTextColor(colors.white)\
			end\
			term.write(sl.getName(t.path))\
			if t.open then\
				renderTree(t)\
			end\
			if x == 1 then\
				y = y+1\
			end\
		end\
	end\
	x = x-1\
end\
local function render()\
	objs = {}\
	hadselected = false\
	term.setBackgroundColor(colors.black)\
	term.clear()\
	x,y = 0,1+scrollY\
	renderTree(tree)\
end\
render()\
local ofolder\
while true do\
	local e = {os.pullEvent()}\
	local w,h = term.getSize()\
	if e[1] == \"mouse_scroll\" and lUtils.isInside(e[3]+self.x1-1,e[4]+self.y1-1,self) then\
		if (e[2] == -1 and scrollY < 0) or (e[2] == 1 and y > h) then\
			scrollY = scrollY-e[2]\
			render()\
		end\
	elseif e[1]:find(\"mouse\") then\
		if e[1] == \"mouse_move\" or e[1] == \"mouse_click\" or e[1] == \"mouse_up\" then selected1 = nil selected2 = nil end\
		if e[3] and e[4] and lUtils.isInside(e[3]+self.x1-1,e[4]+self.y1-1,self) then\
			for k,v in pairs(objs) do\
				if e[4] == v.y then\
					if e[3] == v.x and #v > 0 then\
						if e[1] == \"mouse_move\" or e[1] == \"mouse_click\" then\
							selected2 = v\
						elseif e[1] == \"mouse_up\" then\
							v.open = not v.open\
						end\
					else\
						if e[1] == \"mouse_move\" or e[1] == \"mouse_click\" then\
							selected1 = v\
						elseif e[1] == \"mouse_up\" and not v.nopath then\
							if e[2] == 1 then\
								sl.folder = v.path\
								os.queueEvent(\"explorer_change_folder\")\
							elseif e[2] == 2 then\
								sl.cMenu(v.path,e[3],e[4])\
							end\
						end\
					end\
					break\
				end\
			end\
		end\
		render()\
	elseif ofolder ~= sl.folder then\
		ofolder = sl.folder\
		render()\
	end\
end",
    name = "tree.lua",
  },
  [ "mainscreen.lua" ] = {
    id = 0,
    content = "if not blittle then\
	os.loadAPI(\"blittle\")\
end\
local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
local imgcache\
local nimgcache\
local shortcache\
s.main = self\
if not lOS.fCut then\
	lOS.fCut = {}\
end\
if not lOS.fClipboard then\
	lOS.fClipboard = {}\
end\
local tW,tH = lOS.wAll.getSize()\
if tW > 85+12 and tH > 33+12 and LevelOS and LevelOS.self and LevelOS.self.window then\
	LevelOS.setWin(85,33)\
	os.queueEvent(\"term_resize\")\
	os.queueEvent(\"term_resize\")\
end\
local tArgs = {...}\
local cSlide = sl.cSlide\
if tArgs[2] then\
	if tArgs[2] == \"SelFile\" and cSlide ~= 3 then\
		sl.ret = {}\
		shapescape.setSlide(3)\
	elseif tArgs[2] == \"SelFolder\" and cSlide ~= 4 then\
		sl.ret = {}\
		shapescape.setSlide(4)\
	elseif tArgs[2] == \"SelSave\" and cSlide ~= 5 then\
		sl.ret = {}\
		shapescape.setSlide(5)\
	end\
end\
local deskIcons = lUtils.asset.load(\"LevelOS/assets/Desktop_Icons.limg\")\
\
local config\
if fs.exists(\"LevelOS/data/explorer.lconf\") then\
	config = lUtils.asset.load(\"LevelOS/data/explorer.lconf\")\
end\
local function saveConfig()\
	lUtils.asset.save(config,\"LevelOS/data/explorer.lconf\")\
end\
\
local fTypes = lUtils.asset.load(\"LevelOS/data/formats.lconf\")\
sl.saveConfig = saveConfig\
if not config then\
	config = {\
		_VERSION=\"1.0\",\
		tabs = {\
			{\"Name\",w=18,on=true},\
			{\"Status\",w=8,on=false},\
			{\"Type\",w=10,on=true},\
			{\"Size\",w=9,on=true},\
			{\"Date Modified\",w=16,on=true},\
			{\"Date Created\",w=16,on=false},\
		},\
		modes = {[\"User/Cloud/Images\"]=2,[\"User/Images\"]=2},\
		sidebar = {width=13}\
	}\
	saveConfig()\
end\
\
sl.config = config\
\
if tArgs[1] and fs.exists(tArgs[1]) then\
	sl.folder = tArgs[1]\
else\
	sl.folder = \"\"\
end\
\
local function uFP(filepath2) -- unique filepath\
	if fs.exists(filepath2) == true then\
		t = 1\
		while fs.exists(string.sub(filepath2,1,string.len(filepath2)-string.len(lUtils.getFileType(filepath2)))..\"_(\"..t..\")\"..lUtils.getFileType(filepath2)) == true do\
			t = t+1\
		end\
		filepath2 = string.sub(filepath2,1,string.len(filepath2)-string.len(lUtils.getFileType(filepath2)))..\"_(\"..t..\")\"..lUtils.getFileType(filepath2)\
	end\
	return filepath2\
end\
sl.uFP = uFP\
\
local disks = {peripheral.find(\"drive\",function(name,object) return object.hasData() end)}\
for t=1,#disks do\
	disks[disks[t].getMountPath()] = disks[t]\
end\
sl.disks = disks\
\
local function getName(path)\
	local isDisk = false\
	if sl.disks[path] and sl.disks[path].getDiskLabel() then\
		str = sl.disks[path].getDiskLabel()..\" (\"..string.gsub(path,\"_\",\" \")..\")\"\
		isDisk = true\
	elseif path == \"\" then\
		str = \"Local disk\"\
	else\
		str = string.gsub(fs.getName(path),\"_\",\" \")\
		if lUtils.getFileType(str) == \".llnk\" then\
			str = str:sub(1,#str-5)\
		end\
	end\
	return str,isDisk\
end\
sl.getName = getName\
\
local files -- includes all entries from fs.attributes\
local scrollY = 0\
\
function locateEntry(tTable,tEntry)\
	if type(tTable) ~= \"table\" then\
		error(\"Invalid input #1\",2)\
	end\
    for t=1,#tTable do\
        if tTable[t] == tEntry then\
            return true,t\
        end\
    end\
    return false,0\
end\
sl.locateEntry = locateEntry\
\
local function openWith(file)\
	-- open with GUI\
	--[[term.setBackgroundColor(colors.white)\
	local w,h = term.getSize()\
	lOS.boxClear(]]\
	sl.OWfile = file\
	shapescape.setSlide(2)\
	coroutine.yield()\
	return sl.OWprogram\
end\
sl.openWith = openWith\
\
local function getIcon(path)\
	if sl.symbols and sl.symbols[path] then\
		--term.setTextColor(sl.symbols[file.path].color)\
		--term.write(sl.symbols[file.path].symbol)\
		return {sl.symbols[path].symbol,lUtils.toBlit(sl.symbols[path].color)}\
	else\
		if fs.isDir(path) then\
			if sl.disks[path] then\
				return {\"\",lUtils.toBlit(colors.blue)}\
			else\
				return {\"\",lUtils.toBlit(colors.yellow)}\
			end\
		else\
			return {\"\",lUtils.toBlit(colors.white)}\
		end\
		--term.write(\"\")\
	end\
end\
sl.getIcon = getIcon\
\
local NAME = {name=\"Name\",width=18}\
sl.NAME = NAME\
function NAME.render(file)\
	local path = file.path\
	if shortcache[file.path] then\
		path = shortcache[file.path][1]\
	end\
	local isCut = locateEntry(lOS.fCut,file.path)\
	if not isCut then\
		if sl.symbols and sl.symbols[path] then\
			term.setTextColor(sl.symbols[path].color)\
			term.write(sl.symbols[path].symbol)\
		else\
			if fs.isDir(path) then\
				if disks[path] then\
					term.setTextColor(colors.blue)\
					term.write(\"\")\
				else\
					term.setTextColor(colors.yellow)\
					term.write(\"\")\
				end\
			else\
				term.setTextColor(colors.white)\
				term.write(\"\")\
			end\
		end\
		if fs.isReadOnly(file.path) then\
			term.setTextColor(colors.lightGray)\
		else\
			term.setTextColor(colors.white)\
		end\
	else\
		term.setTextColor(colors.lightGray)\
		term.write(\" \")\
	end\
	local str = \" \"..sl.getName(file.path)\
	if #str >= NAME.width-1 then\
		str = str:sub(1,NAME.width-4)..\"..\"\
	end\
	local x,y = term.getCursorPos()\
	term.write(str)\
	if sl.search then\
		local b,e = sl.getName(file.path):lower():find(sl.search:lower(),nil,true)\
		if b < NAME.width-2 then\
			if e >= NAME.width-2 then\
				e = NAME.width-3\
			end\
			local nx,ny = term.getCursorPos()\
			local bg = term.getBackgroundColor()\
			term.setCursorPos(x+b,y)\
			term.setBackgroundColor(colors.orange)\
			term.write(str:sub(b+1,e+1))\
			term.setBackgroundColor(bg)\
			term.setCursorPos(nx,ny)\
		end\
	end\
	term.setTextColor(colors.white)\
end\
\
local TYPE = {name=\"Type\",width=10}\
function TYPE.func(file)\
	if fs.isDir(file.path) then\
		if disks[file.path] then\
			return \"Disk\"\
		else\
			return \"Folder\"\
		end\
	elseif fTypes[file.type] then\
		return fTypes[file.type].name\
	else\
		return file.type:upper()..\"-file\"\
	end\
end\
\
local SIZE = {name=\"Size\",width=9}\
function SIZE.func(file)\
	if not fs.isDir(file.path) then\
		return string.format(\"%.1f kB\",math.floor(file.size/100+0.5)/10)\
	else\
		return \"\"\
	end\
end\
\
local MODIFIED = {name=\"Date Modified\",width=16}\
function MODIFIED.func(file)\
	if not file.modification then return \"\" end\
	local t = file.modification\
	return os.date(\"%d-%m-%y %H:%M\",t/1000)\
end\
\
local CREATED = {name=\"Date Created\",width=16}\
function CREATED.func(file)\
	if not file.created then return \"\" end\
	local t = file.created\
	return os.date(\"%d-%m-%y %H:%M\",t/1000)\
end\
\
local STATUS = {name=\"Status\",width=8}\
function STATUS.render(file)\
	-- nothing yet, cloud doesn't support this yet\
	-- IF timestamp of file is HIGHER than cloud reported timestamp, file is NOT SYNCED YET\
	-- IF timestamp of file is LOWER than cloud reported timestamp or file only exists in CLOUD TABLE, file is AVAILABLE ONLINE\
	-- IF timestamp of file is EQUAL to cloud reported timestamp, file is AVAILABLE COMPLETELY\
	if lOS.cloud.lastSync and lOS.cloud.files[file.path] then\
		if lOS.cloud.conflicts[file.path] then\
			term.setTextColor(colors.red)\
			term.write(\"×\")\
		elseif file.modification > lOS.cloud.lastSync then\
			term.setTextColor(colors.blue)\
			term.write(\"\\24\")\
		else\
			term.setTextColor(colors.lime)\
			term.write(\"\\7\")\
		end\
	end\
	term.setTextColor(colors.white)\
end\
local tabRef = {}\
local aTabs = {NAME,TYPE,SIZE,MODIFIED,CREATED,STATUS}\
for k,v in ipairs(config.tabs) do\
	for i,t in pairs(aTabs) do\
		if v[1] == t.name then\
			t.id = k\
			t.width = v.w\
			tabRef[k] = t\
			table.remove(aTabs,i)\
			break\
		end\
	end\
end\
aTabs = nil\
local tabs = {NAME,TYPE,SIZE,MODIFIED}\
sl.rMode = 1\
local selected = {}\
sl.selected = selected\
local mSelected = nil\
local renamebox\
local function render()\
	shortcache = lOS.explorer.shortcache\
	imgcache = lOS.explorer.imgcache\
	nimgcache = lOS.explorer.nimgcache\
	local oterm = term.current()\
	if oterm ~= self.window then\
		term.redirect(self.window)\
	end\
	if not files then return end\
	local w,h = term.getSize()\
	if sl.rMode == 1 then\
		while #files+scrollY <= h-3 and scrollY < 0 do\
			scrollY = scrollY+1\
		end\
		term.setBackgroundColor(colors.black)\
		term.clear()\
		tabs[1].x = 2\
		term.setBackgroundColor(colors.black)\
		term.setTextColor(colors.lightGray)\
		for i=1,#tabs do\
			term.setCursorPos(tabs[i].x,1)\
			term.write(tabs[i].name..string.rep(\" \",tabs[i].width-#tabs[i].name-1)..\"\\149\")\
			if tabs[i+1] then\
				tabs[i+1].x = tabs[i].x+tabs[i].width\
			end\
		end\
		term.setTextColor(colors.white)\
		for i=1,math.min(#files+scrollY,h-2) do\
			local file = files[i-scrollY]\
			file.x1 = tabs[1].x\
			file.y1 = i+1+1\
			file.y2 = file.y1\
			file.x2 = tabs[#tabs].x+tabs[#tabs].width-1\
			local fc = fs.combine\
			local rPath = file.path\
			local isShort = false\
			if shortcache[file.path] then\
				isShort = true\
				rPath = shortcache[file.path][1]\
			elseif file.type == \"llnk\" then\
				local info = lUtils.asset.load(file.path)\
				if info and type(info[1]) == \"string\" then\
					isShort = true\
					rPath = info[1] -- if linked to folder, assume user wants to go to folder, if linked to main.lua it links to program (do context menu shizz)\
					imgcache[file.path] = info.icon\
					shortcache[file.path] = info\
				end\
			end\
			if selected[file.path] then\
				term.setBackgroundColor(colors.gray)\
				term.setCursorPos(file.x1,file.y1)\
				term.write(string.rep(\" \",file.x2-(file.x1-1)))\
			elseif mSelected and lUtils.isInside(mSelected[1],mSelected[2],file) then\
				term.setBackgroundColor(colors.pink)\
				term.setCursorPos(file.x1,file.y1)\
				term.write(string.rep(\" \",file.x2-(file.x1-1)))\
			end\
			for t=1,#tabs do\
				term.setCursorPos(tabs[t].x,i+1+1)\
				if tabs[t].render then\
					tabs[t].render(file)\
				elseif tabs[t].func then\
					local str = tabs[t].func(file)\
					if str and #str >= tabs[t].width then\
						str = str:sub(1,tabs[t].width-3)..\"..\"\
					end\
					term.write(tostring(str))\
				end\
			end\
			if renamebox and sl.renaming == file.path then\
				renamebox.render()\
			end\
			term.setBackgroundColor(colors.black)\
		end\
	elseif sl.rMode == 2 then\
		term.setBackgroundColor(colors.black)\
		term.clear()\
		local fx,fy = 2,1+scrollY\
		local fw,fh = 7,5\
		for i=1,#files do\
			local file = files[i]\
			if selected[file.path] then\
				term.setBackgroundColor(colors.gray)\
			elseif mSelected and file.x1 and lUtils.isInside(mSelected[1],mSelected[2],file) then\
				term.setBackgroundColor(colors.pink)\
			else\
				term.setBackgroundColor(colors.black)\
			end\
			lineH = lOS.explorer.drawIcon(file.path,fx,fy,false,false,4,{\"\\24\",\"3\",\"0\"})-4\
			fh = math.max(lineH+4,fh)\
			file.x1,file.y1 = fx,fy\
			file.x2,file.y2 = fx+7-1,fy+5-1+lineH-1\
			fx = fx+fw+1\
			if fx+fw > w then\
				fx = 2\
				fy = fy+fh\
				fh = 5\
			end\
		end\
	end\
	if oterm ~= self.window then\
		term.redirect(oterm)\
	end\
end\
\
local function genFile(f)\
	local file = {path=f,name=fs.getName(f),type=lUtils.getFileType(f):sub(2),readOnly=fs.isReadOnly(f),isDir=fs.isDir(f)}\
	if not ((file.isDir and file.readOnly) or sl.disks[file.path]) then\
		local a = fs.attributes(f)\
		for k,v in pairs(a) do\
			file[k] = v\
		end\
	end\
	return file\
end\
sl.genFile = genFile\
\
local function updateFiles()\
	while not fs.exists(sl.folder) do\
		sl.folder = fs.getDir(sl.folder)\
	end\
	local inCloud = sl.folder:find(\"User/Cloud\",nil,true) == 1\
	tabs = {}\
	for t=1,#tabRef do\
		if (tabRef[t] == STATUS and inCloud) or config.tabs[tabRef[t].id].on then\
			table.insert(tabs,tabRef[t])\
		end\
	end\
	if config.modes[sl.folder] then\
		sl.rMode = config.modes[sl.folder]\
	else\
		sl.rMode = 1\
	end\
	if LevelOS.self and LevelOS.self.window then\
		if sl.search then\
			LevelOS.setTitle(sl.search..\" - Search Results in \"..sl.getName(sl.folder))\
			LevelOS.self.window.icon = {\"\",lUtils.toBlit(colors.lightBlue)}\
		else\
			LevelOS.setTitle(sl.getName(sl.folder))\
			LevelOS.self.window.icon = sl.getIcon(sl.folder)\
		end\
	end\
	local fi = fs.list(sl.folder)\
	table.sort(fi,function(a,b) return a:lower() < b:lower() end)\
	local folders = {}\
	local nonfolders = {}\
	for t=1,#fi do\
		local f = fs.combine(sl.folder,fi[t])\
		local file = genFile(f)\
		if not (sl.search and not file.name:lower():find(sl.search:lower(),nil,true)) then\
			if file.isDir then\
				table.insert(folders,file)\
			else\
				table.insert(nonfolders,file)\
			end\
		end\
	end\
	files = folders\
	for k,v in ipairs(nonfolders) do\
		table.insert(files,v)\
	end\
	sl.files = files\
	sl.updateFullTree()\
end\
while not sl.symbols do\
	os.sleep(0.1)\
end\
updateFiles()\
render()\
sl.ofolder = sl.folder\
local ofolder = sl.folder\
sl.history = {sl.folder}\
sl.rhistory = {}\
local mousemove = false\
local tID = os.startTimer(10)\
local timerTimeout = os.epoch(\"utc\")+15000\
local function count(tbl)\
	local c = 0\
	for k,v in pairs(tbl) do\
		c = c+1\
	end\
	return c\
end\
local contextcache = {}\
--[[if not fs.isDir(file) and b[2] == 1 and fTypes[f.type] and fTypes[f.type].c then\
	local found,num = locateEntry(fTypes[f.type].c[1],b[3])\
	local p = fTypes[f.type].c[2][num]\
	if p == \"Lua\" then\
		lOS.execute(f.path)\
	else\
		lOS.execute(p..\" \"..f.path)\
	end\
elseif b[3] == \"Open\" and fs.isDir(file) then\
	selected = {}\
	sl.folder = f.path\
	updateFiles()\
	scrollY = 0\
elseif b[3] == \"Delete\" then\
	for k,v in pairs(selected) do\
		fs.delete(k)\
	end\
	selected = {}\
	updateFiles()\
	scrollY = 0\
end]]\
local function cMenu(f, x, y)\
	local options = lOS.explorer.genContextMenu(f,s,sl,selected,updateFiles,render,LevelOS,false)\
	local output = {lOS.contextmenu(x,y,30,options,nil,true)}\
	renamebox = sl.renamebox\
	return unpack(output)\
end\
sl.cMenu = cMenu\
local function updateReturn()\
	local tbl = {}\
	for k,v in pairs(sl.ret) do\
		if not selected[k] then\
			sl.ret[k] = nil\
		else\
			table.insert(tbl,k)\
		end\
	end\
	if #tbl > 1 then\
		sl.fpathbox.txt = \"\"\
		for t=1,#tbl do\
			sl.fpathbox.txt = sl.fpathbox.txt..'\"'..fs.getName(tbl[t])..'\" '\
		end\
		sl.fpathbox.changed = false\
	elseif #tbl == 1 then\
		sl.fpathbox.txt = fs.getName(tbl[1])\
		sl.fpathbox.changed = false\
	else\
		sl.fpathbox.changed = true\
	end\
end\
\
local function fPaste(obj)\
	local tFolder = sl.folder\
	for c=1,#lOS.fClipboard do\
		if fs.exists(lOS.fClipboard[c]) == true then\
			fs.copy(lOS.fClipboard[c],uFP(fs.combine(tFolder,fs.getName(lOS.fClipboard[c]))))\
		end\
		if locateEntry(lOS.fCut,lOS.fClipboard[c]) == true then\
			fs.delete(lOS.fClipboard[c])\
			table.remove(lOS.fCut,({locateEntry(lOS.fCut,lOS.fClipboard[c])})[2])\
		end\
	end\
	lOS.fClipboard = {}\
	lOS.fCut = {}\
	updateFiles()\
end\
\
local function fRename(obj)\
	lOS.explorer.fRename(obj,s,sl,render,LevelOS)\
	renamebox = sl.renamebox\
end\
\
local function fOpenWith(obj)\
	if LevelOS and LevelOS.self and LevelOS.self.window then\
		LevelOS.self.window.events = nil\
	end\
	LevelOS.overlay = nil\
	lOS.noEvents = false\
	local p = sl.openWith(obj.file)\
	if p then\
		p = p.path\
		local f = obj.file\
		if p == \"Lua\" then\
			lOS.execute(f.path)\
		else\
			lOS.execute(p..\" \"..f.path)\
		end\
	end\
end\
\
local function fNew(obj)\
	local pth = uFP(fs.combine(sl.folder,\"New_\"..obj.txt:gsub(\" \",\"_\")..\".\"..obj.format))\
	lUtils.fwrite(pth,obj.preset)\
	term.redirect(self.window)\
	updateFiles()\
	render()\
	fRename(pth)\
	-- rename\
end\
\
local function fNewFolder(obj)\
	local pth = uFP(fs.combine(sl.folder,\"New_Folder\"))\
	fs.makeDir(pth)\
	term.redirect(self.window)\
	updateFiles()\
	render()\
	fRename(pth)\
	-- rename\
end\
\
local dragmenu\
while true do\
	local w,h = term.getSize()\
	local sObj = {x1=1,y1=1,x2=w,y2=h}\
	local e = {os.pullEvent()}\
	if sl.fullReload then\
		os.queueEvent(\"explorer_full_reload\")\
		sl.fullReload = false\
	elseif sl.reload then\
		os.queueEvent(\"explorer_reload\")\
		sl.reload = false\
	end\
	if e[1] == \"explorer_full_reload\" then\
		term.setBackgroundColor(colors.black)\
		term.clear()\
		fTypes = lUtils.asset.load(\"LevelOS/data/formats.lconf\")\
		contextcache = {}\
		imgcache = {}\
		nimgcache = {}\
		shortcache = {}\
		updateFiles()\
		os.sleep(0.2)\
		render()\
	end\
	if dragmenu and (e[1] == \"mouse_drag\" or e[1] == \"mouse_up\") then\
		--dragmenu.x = e[3]-dragmenu.width+1\
		dragmenu.width = e[3]-dragmenu.x+1\
		if e[1] == \"mouse_up\" then\
			config.tabs[dragmenu.id].w = dragmenu.width\
			saveConfig()\
			dragmenu = nil\
		end\
		render()\
	elseif renamebox then\
		if e[1] == \"char\" and e[2] == \" \" then\
			e[2] = \"_\"\
		end\
		if e[1] == \"key\" and e[2] == keys.enter then\
			renamebox.state = false\
			--sl.renaming = nil\
		else\
			renamebox.update(unpack(e))\
			if sl.rMode == 1 then\
				renamebox.x2 = math.min(math.max(NAME.width,#renamebox.txt+5),w)\
			end\
			render()\
			renamebox.render()\
		end\
		if not renamebox.state then\
			local pth = fs.combine(sl.ofolder,renamebox.txt)\
			if renamebox.isShortcut then\
				pth = pth..\".llnk\"\
			end\
			if pth == sl.renaming or fs.combine(pth,\"\") == sl.ofolder then\
				-- nothing\
			elseif fs.exists(pth) then\
				local newPth = uFP(pth)\
				local r = {lUtils.popup(\"Rename File\",\"Do you want to rename \\\"\"..fs.getName(sl.renaming):gsub(\"_\",\" \")..\"\\\" to \\\"\"..fs.getName(newPth):gsub(\"_\",\" \")..\"\\\"?\\n\\nThere is already a file with the same name in this location.\",41,11,{\"Yes\",\"No\"})}\
				if r[1] and r[3] == \"Yes\" then\
					fs.move(sl.renaming,newPth)\
				end\
			else\
				fs.move(sl.renaming,pth)\
			end\
			renamebox = nil\
			sl.renamebox = nil\
			sl.renaming = nil\
			term.setCursorBlink(false)\
			s.win.setPaletteColor(colors.pink,unpack(sl.opink))\
			updateFiles()\
			render()\
		end\
	else\
		if e[1] == \"mouse_move\" or e[1] == \"mouse_up\" or e[1] == \"mouse_click\" then\
			mSelected = nil\
		end\
		if sl.ofolder ~= sl.folder then\
			scrollY = 0\
			sl.ofolder = sl.folder\
			ofolder = sl.folder\
			table.insert(sl.history,sl.folder)\
			sl.rhistory = {}\
			sl.search = nil\
			updateFiles()\
			render()\
		elseif ofolder ~= sl.folder then\
			ofolder = sl.folder\
			sl.search = nil\
			updateFiles()\
			render()\
		elseif (e[1] == \"timer\" and tID == e[2]) or os.epoch(\"utc\") > timerTimeout then\
			if not (e[1] == \"timer\" and tID == e[2]) then\
				_G.expLog = \"Timer timed out at \"..os.date()\
			end\
			updateFiles()\
			render()\
			tID = os.startTimer(4)\
			timerTimeout = os.epoch(\"utc\")+15000\
		end\
		if e[1] == \"mouse_scroll\" and lUtils.isInside(e[3],e[4],sObj) then\
			if sl.rMode == 1 and ((e[2] > 0 and #files+scrollY > h-2) or (e[2] < 0 and scrollY < 0)) then\
				scrollY = scrollY-e[2]\
			elseif sl.rMode == 2 and ((e[2] > 0 and files[#files].y2+1 > h) or (e[2] < 0 and scrollY < 0)) then\
				scrollY = scrollY-e[2]\
			end\
			render()\
		elseif (e[1] == \"mouse_click\" or e[1] == \"mouse_up\" or e[1] == \"mouse_move\" or e[1] == \"mouse_drag\") and e[3] and e[4] and lUtils.isInside(e[3],e[4],sObj) then\
			if e[1] == \"mouse_move\" then\
				if not mousemove then\
					shapescape.getSlide().win.setPaletteColor(colors.pink,0.15,0.15,0.15)\
					mousemove = true\
				end\
				mSelected = {e[3],e[4]}\
				render()\
			elseif not (sl.rMode == 1 and e[4] <= 1) then\
				local clickedfile = false\
				if not (sl.rMode == 1 and e[4] == 2) then\
					for i,f in ipairs(files) do\
						if f.x1 and lUtils.isInside(e[3],e[4],f) then\
							clickedfile = true\
							if e[1] == \"mouse_drag\" and e[2] == 2 then\
								selected[f.path] = f\
								if sl.ret then\
									if (f.isDir and tArgs[2] == \"SelFolder\") or (tArgs[2] == \"SelFile\" and not f.isDir) then\
										sl.ret[f.path] = f\
										updateReturn()\
									end\
								end\
							elseif e[1] == \"mouse_click\" then\
								if e[2] == 1 then\
									if lUtils.isHolding(keys.leftShift) then\
										local startSel = math.huge\
										local endSel = -1\
										for i1,f1 in ipairs(files) do\
											if selected[f1.path] then\
												if i1 < startSel then\
													startSel = i1\
												end\
												if i1 > endSel then\
													endSel = i1\
												end\
											end\
										end\
										if i > startSel and i > endSel then\
											if startSel < 0 then\
												startSel = i\
											end\
											endSel = i\
										elseif i >= startSel and i < endSel then\
											if startSel < 0 then\
												startSel = i\
											end\
											endSel = i\
										elseif i < startSel then\
											startSel,endSel = i,startSel\
										end\
										selected = {}\
										for i1=startSel,endSel do\
											selected[files[i1].path] = files[i1]\
											if (files[i1].isDir and tArgs[2] == \"SelFolder\") or (tArgs[2] == \"SelFile\" and not files[i1].isDir) then\
												sl.ret[files[i1].path] = files[i1]\
												updateReturn()\
											end\
										end\
									elseif lUtils.isHolding(keys.leftCtrl) then\
										if selected[f.path] then\
											selected[f.path] = nil\
											if sl.ret then\
												if count(sl.ret) > 1 then\
													sl.ret[f.path] = nil\
													updateReturn()\
												end\
											end\
										else\
											selected[f.path] = f\
											if (f.isDir and tArgs[2] == \"SelFolder\") or (tArgs[2] == \"SelFile\" and not f.isDir) then\
												sl.ret[f.path] = f\
												updateReturn()\
											end\
										end\
									elseif selected[f.path] and count(selected) == 1 and selected[f.path].lastClick and selected[f.path].lastClick > os.epoch(\"utc\")-1000 then\
										local nf = f\
										local cmd = nf.path\
										local invalidShort = false\
										if shortcache[f.path] then\
											local rPath = shortcache[f.path][1]\
											f.sPath = rPath\
											f.sName = fs.getName(rPath)\
											if not fs.exists(rPath) then\
												invalidShort = true\
											else\
												nf = genFile(shortcache[f.path][1])\
											end\
											local args = shortcache[f.path].args\
											if args and #args > 0 then\
												cmd = cmd..\" \"..table.concat(args, \" \")\
											end\
										end\
										if invalidShort then\
											lOS.explorer.fInvShort({file=f},updateFiles,render)\
										else\
											if nf.isDir then\
												selected = {}\
												sl.folder = nf.path\
												updateFiles()\
												scrollY = 0\
												break\
											elseif (tArgs[2] == \"SelFile\") then\
												sl.ret = {[f.path]=f}\
												updateReturn()\
												shapescape.exit({f.path})\
											elseif shortcache[f.path] and shortcache[f.path].program then -- if needs to be executed with special program\
												local p = shortcache[f.path].program\
												if p == \"Lua\" then\
													lOS.execute(cmd)\
												else\
													lOS.execute(p..\" \"..cmd)\
												end\
											elseif fTypes[nf.type] and fTypes[nf.type].program then\
												local p = fTypes[nf.type].program\
												if p == \"Lua\" then\
													lOS.execute(f.path)\
												else\
													lOS.execute(p..\" \"..nf.path)\
												end\
											elseif nf.type == \"\" then\
												lOS.execute(f.path)\
											else\
												fOpenWith({file=nf})\
												-- open with prompt\
											end\
										end\
									else\
										selected = {[f.path]=f}\
										if (f.isDir and tArgs[2] == \"SelFolder\") or (tArgs[2] == \"SelFile\" and not f.isDir) then\
											sl.ret = {[f.path] = f}\
											updateReturn()\
										end\
										f.lastClick = os.epoch(\"utc\")\
									end\
								elseif e[2] == 2 then\
									if count(selected) > 0 and not selected[f.path] then\
										selected = {[f.path]=f}\
										if (f.isDir and tArgs[2] == \"SelFolder\") or (tArgs[2] == \"SelFile\" and not f.isDir) then\
											sl.ret = {[f.path] = f}\
											updateReturn()\
										end\
									end\
								end\
							elseif e[1] == \"mouse_up\" then\
								if e[2] == 2 then\
									if count(selected) > 0 then\
										cMenu(f,e[3],e[4])\
									else\
										clickedfile = false\
									end\
								end\
							end\
							break\
						end\
					end\
				end\
				if not clickedfile then\
					selected = {}\
					if e[1] == \"mouse_up\" and e[2] == 2 then\
						cMenu(nil, e[3], e[4])\
					end\
				end\
				render()\
			elseif sl.rMode == 1 and e[4] == 1 then\
				if e[1] == \"mouse_click\" and e[2] == 1 then\
					for k,v in ipairs(tabs) do\
						if e[3] == v.x+v.width-1 then\
							dragmenu = v\
						end\
					end\
				elseif e[1] == \"mouse_up\" and e[2] == 2 then\
					local opt = {}\
					for t=1,#config.tabs do\
						local o = {}\
						if config.tabs[t].on then\
							o.txt = {\" \\7  \"..config.tabs[t][1],\"\",\"888\"}\
						else\
							o.txt = \"    \"..config.tabs[t][1]\
						end\
						o.action = function() config.tabs[t].on = not config.tabs[t].on saveConfig() sl.reload = true os.queueEvent(\"explorer_reload\") os.queueEvent(\"explorer_reload\") end\
						table.insert(opt,o)\
					end\
					lOS.contextmenu(e[3],e[4],20,opt)\
				end\
			end\
		elseif e[1] == \"term_resize\" or e[1] == \"explorer_reload\" then\
			updateFiles()\
			render()\
			saveConfig()\
		end\
	end\
	sl.selected = selected\
end",
    name = "mainscreen.lua",
  },
  [ "topbar.lua" ] = {
    id = 2,
    content = "local sl = shapescape.getSlides()\
local function split(str, pat)\
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0\
	local fpat = \"(.-)\" .. pat\
	local last_end = 1\
	local s, e, cap = str:find(fpat, 1)\
	while s do\
		if s ~= 1 or cap ~= \"\" then\
			table.insert(t,cap)\
		end\
		last_end = e+1\
		s, e, cap = str:find(fpat, last_end)\
	end\
	if last_end <= #str then\
		cap = str:sub(last_end)\
		table.insert(t, cap)\
	end\
	return t\
end\
local function split_path(str)\
	return split(str,'[\\\\/]+')\
end\
sl.split_path = split_path\
local robjs = {}\
local function render()\
	local w,h = term.getSize()\
	term.setBackgroundColor(colors.black)\
	term.setTextColor(colors.gray)\
	lUtils.border(1,1,w,h,\"fill\",2)\
	robjs = {w=1}\
	local olist = {}\
	local cPath = split_path(sl.folder)\
	table.insert(cPath,1,\"\")\
	local isDisk\
	local isRom\
	local ico = sl.getIcon(sl.folder)\
	if sl.search then\
		local str = \"Search Results in \"..sl.getName(sl.folder)\
		if robjs.w+#str+3 > w-2 then\
			robjs[1] = {\" \\171 \"}\
		else\
			table.insert(robjs,{\" > \"})\
			table.insert(robjs,{str})\
			robjs.w = robjs.w+#str+3\
			ico = {\"\",lUtils.toBlit(colors.lightBlue)}\
		end\
	else\
		for i=#cPath,1,-1 do\
			local str\
			if i == 2 and sl.disks[cPath[2]] and sl.disks[cPath[i]].getDiskLabel() then\
				str = string.gsub(cPath[2],\"_\",\" \")..\" (\"..sl.disks[cPath[2]].getDiskLabel()..\")\"\
				isDisk = true\
			elseif i == 1 then\
				str = \"Local disk\"\
			else\
				str = string.gsub(cPath[i],\"_\",\" \")\
			end\
			if i == 2 and str == \"rom\" then\
				isRom = true\
			end\
			if robjs.w+#str+3 > w-2 then\
				for t=1,i do\
					olist[t] = cPath[t]\
				end\
				if olist[2] and (sl.disks[olist[2]] or olist[2] == \"rom\") then\
					table.remove(olist,1)\
				end\
				robjs[1] = {\" \\171 \",list=olist}\
				break\
			else\
				table.insert(robjs,1,{str,path=fs.combine(table.unpack(cPath,1,i))})\
				table.insert(robjs,1,{\" > \"})\
				robjs.w = robjs.w+#str+3\
			end\
			if isDisk or isRom then\
				break\
			end\
		end\
	end\
	term.setCursorPos(2,2)\
	term.blit(ico[1],ico[2],lUtils.toBlit(term.getBackgroundColor()))\
	robjs[1].x = 3\
	term.setTextColor(colors.lightGray)\
	term.write(robjs[1][1])\
	\
	for i=2,#robjs do\
		robjs[i].x = robjs[i-1].x+#robjs[i-1][1]\
		if robjs[i][1] == \" > \" then\
			term.setTextColor(colors.lightGray)\
		else\
			term.setTextColor(colors.white)\
		end\
		term.write(robjs[i][1])\
	end\
end\
\
render()\
os.sleep(0.5)\
render()\
local ofolder = sl.folder\
local function gotofolder(obj)\
	sl.folder = obj.path\
	os.queueEvent(\"explorer_update\")\
	os.queueEvent(\"explorer_update\")\
end\
local getIcon = sl.getIcon\
local ow,oh = term.getSize()\
local osearch = sl.search\
while true do\
	local e = {os.pullEvent()}\
	local w,h = term.getSize()\
	if e[1] == \"term_resize\" or ofolder ~= sl.folder or ow ~= w or oh ~= h or osearch ~= sl.search then\
		ow,oh = w,h\
		ofolder = sl.folder\
		osearch = sl.search\
		render()\
	elseif e[1]:find(\"mouse\") and e[3] and e[4] and e[4] == 2 and e[3] > 1 and e[3] < w then\
		render()\
		local cObj = false\
		for k,v in ipairs(robjs) do\
			if e[3] >= v.x and e[3] <= v.x+(#v[1]-1) then\
				cObj = true\
				local int = 1\
				local a = v\
				if a[1] == \" > \" and k > 1 then\
					int = 2\
					a = robjs[k-1]\
					k = k-1\
				end\
				if e[1] == \"mouse_click\" then\
					term.setBackgroundColor(colors.gray)\
					term.setCursorPos(a.x,2)\
					term.setTextColor(colors.white)\
					term.write(a[1])\
					if robjs[k+1] and k > 1 then\
						term.setTextColor(colors.lightGray)\
						term.write(\" > \")\
					end\
				elseif e[1] == \"mouse_up\" then\
					if k == 1 and a.list then\
						-- idk\
						if a.list then\
							--sl.dropdown = {self.x1+a.x-3,self.y2,0,a.list}\
							local opt = {}\
							for f=#a.list,1,-1 do\
								local pth = fs.combine(unpack(a.list,1,f))\
								local ico = getIcon(pth)\
								table.insert(opt,{txt={ico[1]..\" \"..sl.getName(a.list[f]),ico[2]},path=pth,action=gotofolder})\
							end\
							sl.dropdown = {self.x1+a.x-3,self.y2,0,opt,{bg=colors.white,fg=colors.lightGray,txt=colors.black}}\
						end\
					elseif int == 1 and a.path then\
						sl.folder = a.path\
						os.queueEvent(\"explorer_change_folder\")\
					elseif a.path then\
						term.setCursorPos(a.x,2)\
						term.setBackgroundColor(colors.gray)\
						term.setTextColor(colors.white)\
						term.write(a[1])\
						term.setTextColor(colors.lightGray)\
						term.write(\" \\31 \")\
						os.sleep(0)\
						local opt = {}\
						local ls = fs.list(a.path)\
						for f=1,#ls do\
							local pth = fs.combine(a.path,ls[f])\
							if fs.isDir(pth) then\
								local ico = getIcon(pth)\
								table.insert(opt,{txt={ico[1]..\" \"..ls[f],ico[2]},path=pth,action=gotofolder})\
								if robjs[k+2] and robjs[k+2][1] == ls[f] then\
									opt[#opt].color = colors.black\
									--table.insert(opt,{txt=\"\\7 \"..ls[f],path=fs.combine(a.path,ls[f]),color=colors.black,action=gotofolder})\
								--else\
									--table.insert(opt,{txt=\"  \"..ls[f],path=fs.combine(a.path,ls[f]),action=gotofolder})\
								end\
							end\
						end\
						sl.dropdown = {self.x1+a.x+#a[1]-3,self.y2,0,opt,{bg=colors.white,fg=colors.lightGray,txt=colors.gray}}\
						render()\
						--os.pullEvent()\
						-- dropdown menu\
					end\
				end\
			end\
		end\
		if not cObj then\
			if e[1] == \"mouse_up\" then\
				local w,h = term.getSize()\
				term.setBackgroundColor(colors.black)\
				term.setTextColor(colors.gray)\
				lUtils.border(1,1,w,h,\"fill\",2)\
				local ico = sl.getIcon(sl.folder)\
				term.setCursorPos(2,2)\
				term.blit(ico[1],ico[2],lUtils.toBlit(term.getBackgroundColor()))\
				term.setTextColor(colors.white)\
				local ibox = lUtils.input(4,2,w-1,2,{text=sl.folder,overflowY=\"none\",overflowX=\"scroll\",selectColor=colors.blue})\
				ibox.state = true\
				--ibox.txt = sl.folder\
				ibox.select = {1,#ibox.txt}\
				ibox.cursor.a = #ibox.txt+1\
				ibox.cursor.x = #ibox.txt+1\
				ibox.update(\"timer\")\
				ibox.render()\
				while ibox.state do\
					local e = {os.pullEvent()}\
					if e[1] == \"char\" and e[2] == \" \" then\
						e[2] = \"_\"\
					end\
					if e[1] == \"key\" and e[2] == keys.enter then\
						break\
					else\
						ibox.update(unpack(e))\
						ibox.render()\
					end\
				end\
				term.setCursorBlink(false)\
				if fs.exists(ibox.txt) then\
					sl.folder = fs.combine(ibox.txt,\"\")\
				end\
				render()\
			end\
		end\
	end\
end",
    name = "topbar.lua",
  },
  [ "searchupdate.lua" ] = {
    id = 20,
    content = "local sl = shapescape.getSlides()\
while true do\
	local e = {os.pullEvent()}\
	if self.state and e[1] == \"key\" and e[2] == keys.enter then\
		self.state = false\
		if #self.txt >= 1 then\
			sl.search = self.txt\
			os.queueEvent(\"explorer_reload\")\
		end\
	end\
end",
    name = "searchupdate.lua",
  },
}

local nAssets = {}
for key,value in pairs(assets) do nAssets[key] = value nAssets[assets[key].id] = assets[key] end
assets = nAssets
nAssets = nil

local slides = {
  {
    y = 22,
    x = 65,
    h = 19,
    w = 51,
    objs = {
      {
        type = "rect",
        x2 = 14,
        y2 = 19,
        y1 = 3,
        x1 = 12,
        color = 32768,
        oy2 = 0,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 4,
          },
        },
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        border = {
          color = 128,
          type = 1,
        },
      },
      {
        type = "rect",
        color = 32768,
        y2 = 3,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        x2 = 51,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 1,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        y1 = 1,
      },
      {
        txt = " ",
        type = "text",
        color = 0,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        x2 = 2,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 5,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        x1 = 1,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "",
        type = "text",
        x2 = 5,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        color = 0,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 6,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        x1 = 4,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "",
        type = "text",
        color = 0,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        x2 = 6,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 12,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        x1 = 6,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "",
        type = "text",
        color = 0,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        x2 = 8,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 7,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        x1 = 8,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        x2 = 51,
        y2 = 19,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 1,
        oy1 = 0,
        txt = " ?? items |",
        type = "text",
        oy2 = 0,
        txtcolor = 1,
        ox2 = 0,
        color = 128,
        y1 = 19,
        input = false,
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 11,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
      },
      {
        lines = {
          "",
        },
        color = 32768,
        y2 = 2,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 34,
        scr = 0,
        history = {},
        ox1 = 17,
        changed = false,
        x2 = 49,
        txt = "",
        type = "input",
        blit = {},
        txtcolor = 1,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = 3,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 20,
          },
        },
        rhistory = {},
        ox2 = 2,
        state = false,
        dLines = {
          "",
        },
        opt = {
          overflowX = "scroll",
          overflowY = "none",
          cursorColor = 256,
          indentChar = " ",
          tabSize = 4,
          minWidth = 16,
          overflow = "scroll",
          minHeight = 1,
        },
        cursor = {
          y = 1,
          x = 1,
          a = 1,
        },
        scrollX = 0,
        ref = {
          1,
          1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        y1 = 2,
      },
      {
        type = "window",
        color = 32768,
        y2 = 18,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 0,
          },
          update = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        oy2 = 1,
        x2 = 51,
        border = {
          color = 0,
          type = 1,
        },
        input = false,
        x1 = 15,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        y1 = 4,
      },
      {
        type = "window",
        color = 128,
        y2 = 18,
        oy2 = 1,
        x1 = 1,
        x2 = 13,
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        input = false,
        y1 = 4,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        type = "window",
        color = 256,
        y2 = 3,
        y1 = 1,
        ox2 = 20,
        x2 = 31,
        x1 = 10,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 2,
          },
          update = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "dropdown",
        type = "text",
        color = 0,
        y2 = 1,
        border = {
          color = 0,
          type = 1,
        },
        txtcolor = 1,
        x2 = 8,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 13,
          },
        },
        x1 = 1,
        y1 = 1,
      },
      {
        x2 = 48,
        y2 = 19,
        x1 = 48,
        ox1 = 3,
        oy1 = 0,
        txt = "=",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 21,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 3,
        y1 = 19,
        border = {
          color = 0,
          type = 1,
        },
        color = 0,
        input = false,
        txtcolor = 1,
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap bottom",
        },
        oy2 = 0,
      },
      {
        x2 = 50,
        y2 = 19,
        x1 = 50,
        ox1 = 1,
        oy1 = 0,
        txt = "",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 22,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        y1 = 19,
        border = {
          color = 0,
          type = 1,
        },
        color = 0,
        input = false,
        txtcolor = 8,
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap bottom",
        },
        oy2 = 0,
      },
    },
    c = 1,
  },
  {
    y = 22,
    x = 65,
    h = 19,
    w = 51,
    objs = {
      {
        type = "window",
        color = 32768,
        y2 = 19,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 8,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        x1 = 1,
        x2 = 51,
        ox2 = 0,
        oy2 = 0,
        border = {
          color = 0,
          type = 1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        y1 = 1,
      },
      {
        type = "rect",
        oy2 = -9,
        color = 1,
        y2 = 19,
        border = {
          color = 0,
          type = 1,
        },
        ox2 = -12,
        x2 = 38,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 9,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        x1 = 14,
        ox1 = 12,
        oy1 = 9,
        snap = {
          Top = "Snap center",
          Right = "Snap center",
          Left = "Snap center",
          Bottom = "Snap center",
        },
        y1 = 1,
      },
      {
        x2 = 37,
        y2 = 3,
        x1 = 15,
        ox1 = 11,
        oy1 = 8,
        txt = "How do you want to open this file?",
        type = "text",
        oy2 = 7,
        txtcolor = 32768,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        border = {
          color = 0,
          type = 1,
        },
        color = 0,
        input = false,
        y1 = 2,
        snap = {
          Top = "Snap center",
          Right = "Snap center",
          Left = "Snap center",
          Bottom = "Snap center",
        },
        ox2 = -11,
      },
      {
        type = "window",
        oy2 = -2,
        color = 1,
        y2 = 12,
        y1 = 4,
        ox2 = -12,
        x2 = 38,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 17,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        x1 = 14,
        ox1 = 12,
        oy1 = 6,
        snap = {
          Top = "Snap center",
          Right = "Snap center",
          Left = "Snap center",
          Bottom = "Snap center",
        },
        border = {
          color = 256,
          type = 1,
        },
      },
      {
        color = 0,
        y2 = 16,
        x1 = 19,
        ox1 = 7,
        oy1 = -4,
        txt = "Always use this app for ??? files",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 10,
          },
        },
        txtcolor = 32768,
        oy2 = -6,
        y1 = 14,
        x2 = 37,
        input = false,
        ox2 = -11,
        snap = {
          Top = "Snap center",
          Right = "Snap center",
          Left = "Snap center",
          Bottom = "Snap center",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 256,
        y2 = 18,
        x1 = 28,
        ox1 = -2,
        oy1 = -6,
        txt = "   OK",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 19,
          },
        },
        ox2 = -11,
        txtcolor = 32768,
        y1 = 16,
        x2 = 37,
        input = false,
        oy2 = -8,
        snap = {
          Top = "Snap center",
          Right = "Snap center",
          Left = "Snap center",
          Bottom = "Snap center",
        },
        border = {
          color = 1,
          type = 1,
        },
      },
      {
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 18,
          },
        },
        x2 = 17,
        y2 = 15,
        y1 = 14,
        ox2 = 9,
        color = 0,
        oy2 = -5,
        x1 = 15,
        ox1 = 11,
        oy1 = -4,
        snap = {
          Top = "Snap center",
          Right = "Snap center",
          Left = "Snap center",
          Bottom = "Snap center",
        },
        border = {
          color = 256,
          type = 1,
        },
      },
    },
    c = 2,
  },
  {
    y = 21,
    x = 65,
    h = 19,
    w = 51,
    objs = {
      {
        type = "rect",
        x2 = 14,
        y2 = 15,
        border = {
          color = 128,
          type = 1,
        },
        x1 = 12,
        color = 32768,
        oy2 = 4,
        y1 = 3,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 4,
          },
          update = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
      },
      {
        type = "rect",
        color = 32768,
        y2 = 3,
        y1 = 1,
        x1 = 1,
        x2 = 51,
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = " ",
        type = "text",
        color = 0,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        x2 = 2,
        input = false,
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 5,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        x1 = 1,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "",
        type = "text",
        x2 = 5,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        color = 0,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 6,
          },
        },
        x1 = 4,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "",
        type = "text",
        color = 0,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        x2 = 6,
        input = false,
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 12,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        x1 = 6,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "",
        type = "text",
        color = 0,
        y2 = 2,
        y1 = 2,
        txtcolor = 128,
        x2 = 8,
        input = false,
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 7,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        x1 = 8,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        lines = {
          "",
        },
        color = 32768,
        y2 = 2,
        y1 = 2,
        x1 = 34,
        scrollX = 0,
        cursor = {
          y = 1,
          x = 1,
          a = 1,
        },
        ox1 = 17,
        x2 = 49,
        txt = "",
        opt = {
          overflowX = "scroll",
          overflowY = "none",
          cursorColor = 256,
          indentChar = " ",
          tabSize = 4,
          minWidth = 16,
          overflow = "scroll",
          minHeight = 1,
        },
        ox2 = 2,
        state = false,
        history = {},
        event = {
          render = {
            [ 2 ] = 3,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        rhistory = {},
        txtcolor = 1,
        blit = {},
        dLines = {
          "",
        },
        type = "input",
        scr = 0,
        changed = false,
        ref = {
          1,
          1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        type = "window",
        color = 32768,
        y2 = 14,
        oy2 = 5,
        x1 = 15,
        border = {
          color = 0,
          type = 1,
        },
        x2 = 51,
        ox2 = 0,
        input = false,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 0,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        y1 = 4,
      },
      {
        type = "window",
        x2 = 13,
        y2 = 14,
        y1 = 4,
        x1 = 1,
        color = 128,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        input = false,
        oy2 = 5,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        type = "window",
        x2 = 31,
        y2 = 3,
        y1 = 1,
        x1 = 10,
        color = 256,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 2,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        input = false,
        ox2 = 20,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        txt = "dropdown",
        type = "text",
        color = 0,
        y2 = 1,
        border = {
          color = 0,
          type = 1,
        },
        txtcolor = 1,
        x2 = 8,
        input = false,
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 13,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        x1 = 1,
        y1 = 1,
      },
      {
        type = "rect",
        color = 128,
        y2 = 19,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 1,
        y1 = 15,
        x2 = 51,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        oy1 = 4,
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        oy2 = 0,
      },
      {
        color = 32768,
        y2 = 18,
        x1 = 43,
        ox1 = 8,
        oy1 = 1,
        txt = " Cancel",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = 16,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        txtcolor = 1,
        border = {
          color = 0,
          type = 1,
        },
        x2 = 50,
        input = false,
        y1 = 18,
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap bottom",
        },
        oy2 = 1,
      },
      {
        x2 = 41,
        y2 = 18,
        x1 = 34,
        ox1 = 17,
        oy1 = 1,
        txt = " Select",
        type = "text",
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = 15,
          },
        },
        txtcolor = 1,
        y1 = 18,
        border = {
          color = 0,
          type = 1,
        },
        color = 32768,
        input = false,
        ox2 = 10,
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap bottom",
        },
        oy2 = 1,
      },
      {
        color = 0,
        y2 = 16,
        x1 = 4,
        oy1 = 3,
        txt = "File Name:",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        oy2 = 3,
        border = {
          color = 0,
          type = 1,
        },
        input = false,
        x2 = 13,
        snap = {
          Top = "Snap bottom",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        y1 = 16,
      },
      {
        lines = {
          "",
        },
        x2 = 32,
        y2 = 16,
        cursor = {
          y = 1,
          x = 1,
          a = 1,
        },
        x1 = 15,
        state = false,
        scr = 0,
        changed = false,
        oy1 = 3,
        txtcolor = 1,
        txt = "",
        opt = {
          overflowX = "scroll",
          overflowY = "none",
          cursorColor = 1,
          indentChar = " ",
          tabSize = 4,
          minWidth = 9,
          overflow = "scroll",
          minHeight = 1,
        },
        oy2 = 3,
        history = {},
        scrollX = 0,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 14,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        rhistory = {},
        ox2 = 19,
        blit = {},
        dLines = {
          "",
        },
        border = {
          color = 0,
          type = 1,
        },
        type = "input",
        color = 32768,
        ref = {
          1,
          1,
        },
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        y1 = 16,
      },
      {
        color = 32768,
        y2 = 16,
        x1 = 34,
        ox1 = 17,
        oy1 = 3,
        txt = "All files (*.*) ",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        txtcolor = 1,
        border = {
          color = 0,
          type = 1,
        },
        x2 = 50,
        input = false,
        y1 = 16,
        snap = {
          Top = "Snap bottom",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap bottom",
        },
        oy2 = 3,
      },
    },
    c = 3,
  },
}

for s=1,#slides do
	local slide = slides[s]
	for o=1,#slide.objs do
		local obj = slide.objs[o]
		for key,value in pairs(obj.event) do
			if assets[ value[2] ] then
				lUtils.shapescape.addScript(obj,value[2],key,assets,LevelOS,slides)
			else
				obj.event[key] = {function() end,-1}
			end
		end
	end
end

	local tArgs = {...}
if tArgs[1] and tArgs[1] == "load" then
	return {assets=assets,slides=slides}
end


return lUtils.shapescape.run(slides,...)