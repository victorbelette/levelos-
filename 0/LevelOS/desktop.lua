local terminal = term.current()
local deskIcons = lUtils.asset.load("LevelOS/assets/Desktop_Icons.limg")
local desktop = {}
local idReference = {}
local fc = fs.combine

local function locateEntry(tTable,tEntry)
	if type(tTable) ~= "table" then
		error("Invalid input #1",2)
	end
    for t=1,#tTable do
        if tTable[t] == tEntry then
            return true,t
        end
    end
    return false,0
end

local fileTypes
if fs.exists("LevelOS/data/formats.lconf") then
	fileTypes = lUtils.asset.load("LevelOS/data/formats.lconf")
end

if not fileTypes then
	local copy = lUtils.instantiate
	fileTypes = {
		_VERSION="1.3",
		
		[""] = {
			name="File",
			program="Lua",
			contextMenu={
				{"Execute","Edit"},
				{"Lua","rom/programs/edit.lua"}
			},
			openWith={
				"Lua",
				"rom/programs/edit.lua"
			},
			icon=deskIcons[1]
		},
		
		lua = {
			name="Lua script",
			program="Lua",
			contextMenu={
				{"Execute","Edit"},
				{"Lua","rom/programs/edit.lua"}
			},
			openWith={
				"Lua",
				"rom/programs/edit.lua"
			},
			icon=deskIcons[2],
			emptyFilePreset=""
		},
		
		txt = {
			name="Text file",
			program="LevelOS/notepad.lua",
			contextMenu={
				{"Edit"},
				{"LevelOS/notepad.lua"}
			},
			openWith={
				"LevelOS/notepad.lua",
				"rom/programs/edit.lua"
			},
			icon=deskIcons[5],
			emptyFilePreset=""
		},
		
		lconf = {
			name="Config file",
			program="LevelOS/notepad.lua",
			contextMenu={
				{"Edit"},
				{"LevelOS/notepad.lua"}
			},
			openWith={
				"LevelOS/notepad.lua",
				"rom/programs/edit.lua"
			},
			icon=deskIcons[6],
			emptyFilePreset="{}"
		},

		sgui = {
			name="Shapescape GUI",
			program="Program_Files/Shapescape",
			contextMenu={
				{"Open","Execute"},
				{"Program_Files/Shapescape","Lua"}
			},
			openWith={
				"Lua",
				"Program_Files/Shapescape",
				"rom/programs/edit.lua"
			},
			icon=deskIcons[8],
			emptyFilePreset="return {assets={},slides={{contextMenu=1,objs={},w=51,h=19}}}"
		},

		sml = {
			name="SML Document",
			program="Program_Files/sml",
			contextMenu={
				{"Open","Edit"},
				{"Program_Files/sml","rom/programs/edit.lua"}
			},
			openWith={
				"Program_Files/sml",
				"rom/programs/edit.lua"
			},
			icon=deskIcons[9],
			emptyFilePreset=""
		},

		limg  = {
			name="Image",
			program="LevelOS/imageviewer.lua",
			contextMenu={
				{"View","Edit"},
				{"LevelOS/imageviewer.lua","rom/programs/edit.lua"}
			},
			openWith={
				"LevelOS/imageviewer.lua",
				"rom/programs/edit.lua"
			},
			icon=copy(deskIcons[10])
		},

		bimg  = {
			name="Image",
			program="LevelOS/imageviewer.lua",
			contextMenu={
				{"View","Edit"},
				{"LevelOS/imageviewer.lua","rom/programs/edit.lua"}
			},
			openWith={
				"LevelOS/imageviewer.lua",
				"rom/programs/edit.lua"
			},
			icon=copy(deskIcons[10])
		},

		nfp   = {
			name="NFP Image",
			program="LevelOS/imageviewer.lua",
			contextMenu={
				{"View","Edit"},
				{"LevelOS/imageviewer.lua","rom/programs/fun/advanced/paint.lua"}
			},
			openWith={
				"LevelOS/imageviewer.lua",
				"rom/programs/fun/advanced/paint.lua",
				"rom/programs/edit.lua"
			},
			icon=copy(deskIcons[10]),
			emptyFilePreset=""
		},

		nfg = {
			name="Animation",
			program="LevelOS/imageviewer.lua",
			contextMenu={
				{"View","Edit"},
				{"LevelOS/imageviewer.lua","rom/programs/edit.lua"}
			},
			openWith={
				"LevelOS/imageviewer.lua",
				"rom/programs/edit.lua"
			},
			icon=copy(deskIcons[10])
		},
	}

	lUtils.asset.save(lUtils.instantiate(fileTypes),"LevelOS/data/formats.lconf", false)

end

if fileTypes._VERSION == "1.0" then
	for k,v in pairs(fileTypes) do
		if type(v) == "table" then
			v.name = v.name or v.n
			v.n = nil
			v.program = v.program or v.p
			v.p = nil
			v.icon = v.icon or v.i
			v.i = nil
			v.contextMenu = v.contextMenu or v.c
			v.c = nil
			v.openWith = v.openWith or v.o
			v.o = nil
			v.emptyFilePreset = v.emptyFilePreset or v.e
		end
	end
	fileTypes._VERSION = "1.1"
	fileTypes["llnk"] = {name="Shortcut",program="Lua"}
	lUtils.asset.save(lUtils.instantiate(fileTypes),"LevelOS/data/formats.lconf")
end
if fileTypes._VERSION == "1.1" then
	for k,v in pairs(fileTypes) do
		if type(v) == "table" then
			v._VERSION = nil
		end
	end
	for k,v in pairs(fileTypes.nfp.openWith) do
		if v == "rom/programs/fun/paint.lua" then
			fileTypes.nfp.openWith[k] = "rom/programs/fun/advanced/paint.lua"
		end
	end
	fileTypes._VERSION = "1.2"
	lUtils.asset.save(lUtils.instantiate(fileTypes),"LevelOS/data/formats.lconf",false)
end
if fileTypes._VERSION == "1.2" then
	fileTypes.bimg = {
		name="Image",
		program="LevelOS/imageviewer.lua",
		contextMenu={
			{"View","Edit"},
			{"LevelOS/imageviewer.lua","rom/programs/edit.lua"}
		},
		openWith={
			"LevelOS/imageviewer.lua",
			"rom/programs/edit.lua"
		},
		icon=deskIcons[10]
	}
	fileTypes._VERSION = "1.3"
	lUtils.asset.save(lUtils.instantiate(fileTypes),"LevelOS/data/formats.lconf",false)
end
local dConfig
if not lOS.explorer then lOS.explorer = {} end
lOS.explorer.shortcache = {}
lOS.explorer.imgcache = {}
lOS.explorer.nimgcache = {}
lOS.explorer.desktopBackground = nil
lOS.fClipboard = {}

local disks = {}
lOS.explorer.disks = disks
local function reloadDisks()
	for k,v in pairs(disks) do
		disks[k] = nil
	end
	local ndisks = {peripheral.find("drive",function(name,object) return object.hasData() end)}
	for t=1,#ndisks do
		ndisks[ndisks[t].getMountPath()] = ndisks[t]
	end
	for k,v in pairs(ndisks) do
		disks[k] = v
	end
end
reloadDisks()

local function getName(path)
	local isDisk = false
	if disks[path] and disks[path].getDiskLabel() then
		str = disks[path].getDiskLabel().." ("..string.gsub(path,"_"," ")..")"
		isDisk = true
	elseif path == "" then
		str = "Local disk"
	else
		str = string.gsub(fs.getName(path),"_"," ")
		if lUtils.getFileType(str) == ".llnk" then
			str = str:sub(1,#str-5)
		end
	end
	return str,isDisk
end

lOS.explorer.getName = getName

local symbols = {
	["User/Cloud"]     = {symbol="",color=colors.blue},
	[""]               = {symbol="",color=colors.lightGray},
	["rom"]            = {symbol="",color=colors.red},
	["User"]           = {symbol="",color=colors.lightBlue},
	["User/Desktop"]   = {symbol="",color=colors.lightBlue},
	["User/Documents"] = {symbol="",color=colors.lightGray},
	["User/Downloads"] = {symbol="",color=colors.blue},
	["User/Images"]    = {symbol="",color=colors.lightBlue},
	["User/Scripts"]   = {symbol="",color=colors.cyan},
	["User/Games"]     = {symbol="",color=colors.lightGray},
	["User/Music"]     = {symbol="",color=colors.blue},
}

lOS.explorer.getIcon = function(path)
	local disks = {peripheral.find("drive",function(name,object) return object.hasData() end)}
	for t=1,#disks do
		disks[disks[t].getMountPath()] = disks[t]
	end
	if symbols[path] then
		return symbols[path].symbol, symbols[path].color
	elseif disks[path] then
		return "", colors.blue
	elseif fs.isDir(path) then
		return "\143", colors.yellow
	else
		return "\143", colors.white
	end
end

local function genFile(f)
	if not fs.exists(f) then
		error(f.." does not exist",2)
	end
	local file = {path=f,name=fs.getName(f),type=lUtils.getFileType(f):sub(2),readOnly=fs.isReadOnly(f),isDir=fs.isDir(f)}
	if not ((file.isDir and file.readOnly) or disks[file.path]) then
		local a = fs.attributes(f)
		for k,v in pairs(a) do
			file[k] = v
		end
	end
	return file
end

local function uFP(filepath2) -- unique filepath
	if fs.exists(filepath2) == true then
		t = 1
		while fs.exists(string.sub(filepath2,1,string.len(filepath2)-string.len(lUtils.getFileType(filepath2))).."_("..t..")"..lUtils.getFileType(filepath2)) == true do
			t = t+1
		end
		filepath2 = string.sub(filepath2,1,string.len(filepath2)-string.len(lUtils.getFileType(filepath2))).."_("..t..")"..lUtils.getFileType(filepath2)
	end
	return filepath2
end
lOS.explorer.uFP = uFP

function lOS.genIco(path)
	local name = getName(path)
	if fs.isDir(path) and fs.exists(fs.combine(path,"main.lua")) then
		path = fs.combine(path,"main.lua")
	end
	local pth = fs.combine("User/Desktop",name..".llnk")
	lUtils.asset.save({path},pth)
	os.queueEvent("explorer_reload")
end

local presetIcons = {
	["User"] = deskIcons[12],
	["User/Desktop"] = deskIcons[13],
	["User/Documents"] = deskIcons[14],
	["User/Downloads"] = deskIcons[15],
	["User/Games"] = deskIcons[16],
	["User/Images"] = deskIcons[17],
	["User/Music"] = deskIcons[18],
	["User/Scripts"] = deskIcons[19],
	["User/Cloud"] = deskIcons[20],
	["rom"] = deskIcons[21],
}
function lOS.explorer.drawIcon(path,fx,fy,onlyIcon,transparent,maxLines,shortcutIcon)
	--local file = {path=path,type=lUtils.getFileType(path):sub(2)}
	local ok,file = pcall(genFile,path)
	if not ok then
		lUtils.renderImg(deskIcons[11],fx+2,fy+1,nil,transparent)
		return
	end
	local bg = term.getBackgroundColor()
	local fg = term.getTextColor()
	local cTerm = term.current()
	local isCut = false
	if lOS.fCut then
		isCut = locateEntry(lOS.fCut,file.path)
	end
	local shortcache = lOS.explorer.shortcache
	local imgcache = lOS.explorer.imgcache
	local nimgcache = lOS.explorer.nimgcache
	local fc = fs.combine
	local rPath = path
	local rType = file.type
	local isShort = false
	local lines = lUtils.wordwrap(lUtils.getFileName(file.path),7)
	local lineH = math.min(#lines,4)
	local fw,fh = 7,5
	if #lines > lineH then
		lines[4] = lines[4]:sub(1,5)..".."
	end
	fh = math.max(4+lineH,fh)
	if not transparent then
		lOS.boxClear(fx,fy,fx+7-1,fy+5-1+lineH-1)
	end
	if shortcache[file.path] then
		isShort = true
		rPath = shortcache[file.path][1]
		rType = lUtils.getFileType(rPath):sub(2)
	elseif file.type == "llnk" then
		local info = lUtils.asset.load(file.path)
		if info and type(info[1]) == "string" then
			isShort = true
			rPath = info[1]
			if not fs.exists(rPath) then
				imgcache[file.path] = {}
				for i=0,15 do
					imgcache[file.path][i] = deskIcons[4]
				end
			else
				rType = lUtils.getFileType(info[1]):sub(2)
				imgcache[file.path] = {}
				for i=0,15 do
					imgcache[file.path][i] = info.icon
				end
			end
			shortcache[file.path] = info
		end
	end
	local pFolder = fs.getDir(rPath)
	if not isCut then
		if not fs.exists(rPath) then
			lUtils.renderImg(deskIcons[4],fx+2,fy+1,nil,transparent)
		elseif presetIcons[rPath] then
			lUtils.renderImg(presetIcons[rPath],fx+2,fy+1,nil,transparent)
		elseif imgcache[file.path] and imgcache[file.path][bg] then
			local win = imgcache[file.path][bg]
			if win.reposition then
				for t=1,3 do
					term.setCursorPos(fx+2,fy+t)
					term.blit(win.getLine(t))
				end
			else
				lUtils.renderImg(win,fx+2,fy+1,nil,transparent)
			end
		elseif fs.getName(rPath) == "main.lua" --[[and fs.exists(fc(pFolder,"icon.limg"))]] then
			if not nimgcache[file.path] and (fs.exists(fc(pFolder,"icon.limg")) or fs.exists(fc(pFolder,"icon.bimg"))) then
				local img
				if fs.exists(fc(pFolder,"icon.limg")) then
					img = lUtils.asset.load(fc(pFolder,"icon.limg"))
				else
					img = lUtils.asset.load(fc(pFolder,"icon.bimg"))
				end
				img = img[1]
				local iw = #img[1][1]
				local ih = #img
				if iw <= 3 and ih <= 3 then
					--[[local tWin = window.create(cTerm,fx+2,fy+1,iw,ih,true)
					term.redirect(tWin)
					lUtils.renderImg(img,1,1)
					term.redirect(cTerm)
					imgcache[file.path] = tWin]]
					if not imgcache[file.path] then
						imgcache[file.path] = {}
					end
					imgcache[file.path][bg] = img
					lUtils.renderImg(img,fx+2,fy+1,nil,transparent)
				else
					nimgcache[file.path] = true
				end
			else
				lUtils.renderImg(deskIcons[3],fx+2,fy+1,nil,transparent)
			end
		elseif fs.isDir(rPath) then
			if not nimgcache[file.path] and (fs.exists(fc(rPath,"icon.limg")) or fs.exists(fc(rPath,"icon.bimg"))) and fs.exists(fc(rPath,"main.lua")) then
				local img
				if fs.exists(fc(rPath,"icon.limg")) then
					img = lUtils.asset.load(fc(rPath,"icon.limg"))
				else
					img = lUtils.asset.load(fc(rPath,"icon.bimg"))
				end
				img = img[1]
				local iw = #img[1][1]
				local ih = #img
				if iw <= 3 and ih <= 3 then
					local tWin = window.create(cTerm,fx+2,fy+1,iw,ih,true)
					term.redirect(tWin)
					if transparent then
						for y=1,2 do
							local line = {cTerm.getLine(fy+y)}
							for t=1,3 do
								line[t] = line[t]:sub(fx+2,fx+4)
							end
							term.setCursorPos(1,y)
							term.blit(unpack(line))
						end
					else
						term.setBackgroundColor(bg)
						term.clear()
					end
					lUtils.renderImg(img,1,1,nil,transparent)
					term.setBackgroundColor(colors.yellow)
					term.setCursorPos(1,3)
					term.write("   ")
					term.redirect(cTerm)
					if not imgcache[file.path] then
						imgcache[file.path] = {}
					end
					imgcache[file.path][bg] = tWin
				else
					nimgcache[file.path] = true
				end
			else
				lUtils.renderImg(deskIcons[7],fx+2,fy+1,nil,transparent)
			end
		elseif ((rType == "limg" or file.type == "bimg") and lUtils.asset.load(rPath)) or rType == "nfp" then
			local iw,ih
			local img
			if rType == "nfp" then
				img = lUtils.fread(rPath)
				ih = 0
				iw = 0
				for line in img:gmatch("([^\n]*)\n?") do
					iw = math.max(iw,#line)
					ih = ih+1
				end
			else
				img = lUtils.asset.load(rPath)
				img = img[1]
				iw = #img[1][1]
				ih = #img
			end
			local tWin = window.create(cTerm,1,1,iw,ih,false)
			term.redirect(tWin)
			term.setBackgroundColor(bg)
			term.clear()
			lUtils.renderImg(img,1,1)
			term.redirect(cTerm)
			if not imgcache[file.path] then
				imgcache[file.path] = {}
			end
			if iw <= 3 and ih <= 3 then
				imgcache[file.path][bg] = img
				lUtils.renderImg(img,fx+2,fy+1,nil,transparent)
			else
				local lWin = lUtils.littlewin(tWin,6,math.floor(9*(ih/iw)+0.5))
				local fWin = window.create(cTerm,fx+2,fy+1,3,3,true)
				--_G.debuglwin[file.path] = {lWin=lWin,tWin=tWin,img=img}
				term.redirect(fWin)
				local win = blittle.createWindow(fWin,1,1,3,3,true)
				term.redirect(win)
				if transparent then
					for y=1,3 do
						local line = {cTerm.getLine(fy+y)}
						for t=1,3 do
							line[t] = line[t]:sub(fx+2,fx+4)
						end
						term.setCursorPos(1,y)
						term.blit(unpack(line))
					end
				else
					term.setBackgroundColor(bg)
					term.clear()
				end
				lWin.render(1,1)
				term.redirect(fWin)
				win.redraw()
				term.redirect(cTerm)
				fWin.redraw()
				imgcache[file.path][bg] = fWin
			end
		elseif fileTypes[rType] and fileTypes[rType].icon then
			lUtils.renderImg(fileTypes[rType].icon,fx+2,fy+1,nil,transparent)
		else
			lUtils.renderImg(deskIcons[4],fx+2,fy+1,nil,transparent)
		end
		if shortcutIcon then
			if isShort and not onlyIcon then
				term.setCursorPos(fx+2,fy+3)
				term.blit(unpack(shortcutIcon))
			elseif lOS.cloud and lOS.cloud.lastSync and lOS.cloud.files and lOS.cloud.files[file.path] then
				term.setCursorPos(fx+2,fy+3)
				local pix = {lUtils.getPixel(term.current(),fx+2,fy+3)}
				term.setBackgroundColor(lUtils.toColor(pix[3]))
				if lOS.cloud.conflicts[file.path] then
					term.setTextColor(colors.red)
					term.write("×")
				elseif file.modification > lOS.cloud.lastSync then
					term.setTextColor(colors.blue)
					term.write("\24")
				else
					term.setTextColor(colors.lime)
					term.write("\7")
				end
			end
		end
	end
	term.setBackgroundColor(bg)
	term.setTextColor(fg)
	if not onlyIcon then
		if maxLines then
			lineH = math.min(maxLines,lineH)
		end
		for l=1,lineH do
			local line = lines[l]:gsub("%s+$","")
			term.setCursorPos(fx+math.floor(fw/2-#line/2),fy+3+l)
			if transparent then
				lUtils.transWrite(line,(not dConfig.textColor))
			else
				term.write(line)
			end
		end
	end
	return fh
end

dConfig = {_VERSION=1,files={},sizes={},shortcutIcon=true,background={color=colors.white}}
if fs.exists("LevelOS/data/desktop.lconf") then
	dConfig = lUtils.asset.load("LevelOS/data/desktop.lconf")
end

if not dConfig._VERSION then
	-- backup n shit
	if fs.exists("LevelOS/data/olddesktop.lconf") then
		fs.delete("LevelOS/data/olddesktop.lconf")
	end
	fs.move("LevelOS/data/desktop.lconf","LevelOS/data/olddesktop.lconf")
	dConfig = {_VERSION=1,files={},sizes={},shortcutIcon=true,background={color=colors.white}}
end

lOS.explorer.desktopConfig = dConfig

function lOS.save()
	lUtils.asset.save(dConfig,"LevelOS/data/desktop.lconf")
	lUtils.fwrite("LevelOS/data/settings.lconf",textutils.serialize(lOS.settings))
	return true
end

if not fs.exists("User/Desktop") then
	fs.makeDir("User/Desktop")
	-- my PC
	lUtils.asset.save(
		{
			"Program_Files/LevelOS/Explorer/main.lua",
			icon = {
				{
					"",
					"ff ",
					"  f",
				},
				{
					"",
					"f f",
					" f ",
				},
				{
					"",
					"fff",
					"   ",
				}
			},
		},
		"User/Desktop/My_PC.llnk"
	)
	-- shell
	lUtils.asset.save(
		{
			"rom/programs/shell.lua",
			icon = {
				{
					"",
					"   ",
					"fff",
				},
				{
					"",
					"f44",
					"4ff",
				},
				{
					"",
					"fff",
					"   ",
				}
			},
		},
		"User/Desktop/Shell.llnk"
	)
	local function makeShortcuts(folder)
		local ls = fs.list(folder)
		for i,f in ipairs(ls) do
			local path = fc(folder,f)
			if fs.isDir(path) then
				if fs.exists(fc(path,"main.lua")) then
					lUtils.asset.save({fc(path,"main.lua")},fc("User/Desktop",fs.getName(f))..".llnk")
				else
					makeShortcuts(path)
				end
			end
		end
	end
	makeShortcuts("Program_Files")
end


-- dConfig should be loaded after this
local currentID = 1
if not dConfig.files then dConfig.files = {} end
for id,path in pairs(dConfig.files) do
	if id >= currentID then
		currentID = id+1
	end
	idReference[path] = id
end

local desktopMap = setmetatable({}, {
  __index = function(self, id)
    local default = {}
    self[id] = default
    return default
  end
})
_G.debugdesktopmap = desktopMap

local function clearDesktopMap()
	for k,v in pairs(desktopMap) do
		desktopMap[k] = nil
	end
end

local function getDesktopSize()
	local w,h = term.getSize()
	if lOS.tbSize then
		h = h - lOS.tbSize
	end
	local deskW,deskH = math.floor((w+1)/8),math.floor(h/5)
	return deskW,deskH
end

local currentSize
do
	local desktopWidth,desktopHeight = getDesktopSize()
	currentSize = desktopWidth..","..desktopHeight
end
if not dConfig.sizes[currentSize] then
	dConfig.sizes[currentSize] = {}
end

local function reloadDesktop()

	if not fs.exists("User/Desktop") then
		fs.makeDir("User/Desktop")
	end

	local desktopFiles = fs.list("User/Desktop")
	local changed = false
	for f=1,#desktopFiles do
		local name = desktopFiles[f]

		if not idReference[name] then
			idReference[name] = currentID
			dConfig.files[currentID] = name
			currentID = currentID+1
			changed = true
		end

	end
	
	if changed then
		lUtils.asset.save(dConfig,"LevelOS/data/desktop.lconf")
	end
	-- i only need to store position, but if i store them based on names everything gets messed up if a file gets renamed...
	-- iterate through IDs too to see if theres a file there that doesnt exist anymore wait nah just do in the thing actually wait hmm

end

reloadDesktop()

local function drawBackground(background)
	for i=0,15 do
		term.setPaletteColor(2^i,term.nativePaletteColor(2^i))
	end
	if not background then
		term.setBackgroundColor(colors.white)
		term.clear()
	elseif background.path and fs.exists(background.path) then
		local col = background.color or colors.white
		local tw,th = term.getSize()
		local rImg
		local img
		local w,h
		local t = lUtils.getFileType(background.path)
		if t == ".bimg" or t == ".limg" or t == ".nfg" then
			img = lUtils.asset.load(background.path)
			rImg = img[1]
			w = #rImg[1][1]
			h = #rImg
		elseif t == ".nfp" then
			rImg = lUtils.fread(background.path)
			h = 0
			w = 0
			local emptyLine = false
			for line in rImg:gmatch("([^\n]*)\n?") do
				w = math.max(w,#line)
				h = h+1
				if line == "" then
					emptyLine = true
				else
					emptyLine = false -- only if emptyLine is at end itll be true, very good
				end
			end
			if emptyLine then -- fking craftos pc man
				h = h-1
			end
		end
		if background.resize == "stretch" then
			local tWin = window.create(term.current(),1,1,w,h,false)
			local oterm = term.current()
			term.redirect(tWin)
			term.setBackgroundColor(col)
			term.clear()
			lUtils.renderImg(rImg,1,1)
			term.redirect(oterm)
			if h/w > th/tw then -- height should overflow, width equals screen width
				local iw,ih=tw,math.floor(tw*(h/w)+0.5)
				local lWin = lUtils.littlewin(tWin,iw,ih)
				lWin.render(1,math.floor(th/2-ih/2)+1)
			else
				local iw,ih=math.floor(th*(w/h)+0.5),th
				local lWin = lUtils.littlewin(tWin,iw,ih)
				lWin.render(math.floor(tw/2-iw/2)+1,1)
			end
		elseif background.resize == "center" then
			lUtils.renderImg(rImg,math.floor(tw/2-w/2)+1,math.floor(th/2-h/2)+1,nil,true)
		elseif background.resize == "repeat" or true then
			local rw,rh = math.ceil(tw/w),math.ceil(th/h)
			local frame = 1
			for ry=0,rh-1 do
				for rx=0,rw-1 do
					if img then
						lUtils.renderImg(img[frame],1+rx*w,1+ry*h,nil,true)
						frame = frame+1
						if frame > #img then
							frame = 1
						end
					else
						lUtils.renderImg(rImg,1+rx*w,1+ry*h,nil,true)
					end
				end
			end
		end
	elseif background.color then
		term.setBackgroundColor(background.color)
		term.clear()
	end
end
local selected = {}
local drag
local oldWidth,oldHeight = getDesktopSize()
local function render(dodebug)
	term.redirect(terminal)
	-- if not position gen position
	-- make order table with IDs, then sort that table and iterate through
	local dolog


	if lOS.explorer.desktopBackground then
		local dw,dh = lOS.explorer.desktopBackground.getSize()
		local tw,th = term.getSize()
		if dh ~= th-lOS.tbSize then
			lOS.explorer.desktopBackground = nil
		else
			lOS.explorer.desktopBackground.setVisible(true)
			lOS.explorer.desktopBackground.setVisible(false)
		end
	end
	if not lOS.explorer.desktopBackground then
		local col = dConfig.background.color or colors.white
		local tw,th = term.getSize()
		th = th-lOS.tbSize
		local cTerm = term.current()
		local bWin = window.create(term.current(),1,1,tw,th,true)
		term.redirect(bWin)
		term.setBackgroundColor(col)
		term.clear()
		if dConfig.background and dConfig.background[1] and type(dConfig.background[1]) == "table" then
			for t=1,#dConfig.background do
				drawBackground(dConfig.background[t])
			end
		else
			drawBackground(dConfig.background)
		end
		term.redirect(cTerm)
		lOS.explorer.desktopBackground = bWin
		lOS.explorer.desktopBackground.setVisible(false)
	end

	term.setTextColor(dConfig.textColor or colors.black)
	local newWidth,newHeight = getDesktopSize()
	if oldWidth ~= newWidth or oldHeight ~= newHeight then
		currentSize = newWidth..","..newHeight
		oldWidth = newWidth
		oldHeight = newHeight
		if not dConfig.sizes[currentSize] then
			dConfig.sizes[currentSize] = {}
		end
		clearDesktopMap()
	end
	local order = {}
	for path,id in pairs(idReference) do
		local absolutePath = fc("User/Desktop",path)
		if not fs.exists(absolutePath) then
			if dConfig.sizes[currentSize][id] then
				local self = dConfig.sizes[currentSize][id]
				if desktopMap[self.x] then
					desktopMap[self.x][self.y] = nil
				end
				dConfig.sizes[currentSize][id] = nil
			end
			idReference[path] = nil
			dConfig.files[id] = nil
		else
			table.insert(order,id)
		end
	end
	table.sort(order)
	local icons = dConfig.sizes[currentSize]
	for i=1,#order do
		local id = order[i]
		if not icons[id] then
			icons[id] = {}
		end
		if not icons[id].x or not icons[id].y then
			local x,y = 1,1
			local success = true
			while desktopMap[x][y] do
				y = y+1
				if y > newHeight then
					y = 1
					x = x+1
					if x > newWidth then
						success = false
						break
					end
				end
			end
			if success then
				icons[id].x,icons[id].y = x,y
				desktopMap[x][y] = id
			end
		end
		if icons[id].x and icons[id].y and not selected[id] then
			local x,y = icons[id].x,icons[id].y
			desktopMap[x][y] = id
			local path = fc("User/Desktop",dConfig.files[id])
			local maxLines = 1
			term.setBackgroundColor(colors.white)
			lOS.explorer.drawIcon(path,1+(x-1)*8,1+(y-1)*5,false,true,maxLines,{"\24","0","8"})
		end
		--os.sleep(0.5)
	end
	for id,v in pairs(selected) do
		if not icons[id] then
			selected[id] = nil
		else
			local x,y = icons[id].x,icons[id].y
			local path = fc("User/Desktop",dConfig.files[id])
			local maxLines = 4
			term.setBackgroundColor(colors.lightBlue)
			lOS.explorer.drawIcon(path,1+(x-1)*8,1+(y-1)*5,false,false,maxLines,{"\24","0","8"})
		end
	end
	if drag and drag.moved then
		lOS.explorer.drawIcon(fc("User/Desktop",dConfig.files[drag.id]),drag.x-drag.ox,drag.y-drag.oy,false,true,1,{"\24","0","8"})
	end
end


-- CONTEXT MENU FUNCTIONS

local fTypes = fileTypes
local function fExec(obj)
	local f = obj.file
	--[[local num = obj.num
	local p = fTypes[f.type].c[2][num]]
	local p = obj.p
	if p == "Lua" then
		lOS.execute(f.path)
	else
		lOS.execute(p.." "..f.path)
	end
end
lOS.explorer.fExec = fExec

local function fOpenWin(obj)
	local f = obj.file
	lOS.execute("Program_Files/LevelOS/Explorer "..f.path)
end
lOS.explorer.fOpenWin = fOpenWin

function lOS.explorer.fRename(obj,s,sl,render,LevelOS,isDesktop)
	if type(obj) == "string" then
		if isDesktop then
			for i,v in pairs(dConfig.sizes[currentSize]) do
				_G.debugcompare = {}
				if obj == fs.combine("User/Desktop",dConfig.files[i]) then
					local f = genFile(obj)
					local x,y = v.x,v.y
					f.x1,f.y1 = 1+(x-1)*8,1+(y-1)*5
					local lineH = math.min(#lUtils.wordwrap(lUtils.getFileName(f.path),7),4)
					f.x2,f.y2 = f.x1+6,f.y1+3+lineH
					obj = {file=f}
					break
				end
				table.insert(debugcompare,{obj,fs.combine("User/Desktop",dConfig.files[i])})
			end
			if type(obj) == "string" then
				error("not found")
			end
		else
			for k,v in ipairs(sl.files) do
				if v.path == obj then
					obj = {file=v}
					break
				end
			end
		end
	end
	LevelOS.overlay = nil
	local f = obj.file
	sl.renaming = f.path
	if isDesktop then
		term.setBackgroundColor(colors.white)
		term.setTextColor(colors.black)
	else
		term.setBackgroundColor(colors.pink)
		opink = {s.win.getPaletteColor(colors.pink)}
		sl.opink = opink
		s.win.setPaletteColor(colors.pink,0.15,0.15,0.15)
		term.setTextColor(colors.white)
	end
	local fname
	local isShortcut = false
	if lUtils.getFileType(f.path) == ".llnk" then
		fname = lUtils.getFileName(f.path,false)
		isShortcut = true
	else
		fname = lUtils.getFileName(f.path,true)
	end
	fname = fname:gsub(" ","_")
	local w,h = term.getSize()
	if sl.rMode == 1 then
		sl.renamebox = lUtils.input(sl.NAME.x+2,f.y2,sl.NAME.x+sl.NAME.width-2,f.y2,{overflowX="scroll",overflowY="none",text=fname,selectColor=colors.blue})
		sl.renamebox.x2 = math.min(math.max(sl.NAME.width,#sl.renamebox.txt+5),w)
	else
		sl.renamebox = lUtils.input(f.x1,f.y1+4,f.x2,f.y2,{overflowX="scroll",overflowY="none",text=fname,selectColor=colors.blue}) -- ah fuck ah FCK shit fuck
		if isDesktop then
			sl.renamebox.opt.selectTxtColor = colors.white
		end
		-- put renamebox in sl or something i guess FUCK why did i make it this way
	end
	local renamebox = sl.renamebox
	renamebox.isShortcut = isShortcut
	renamebox.scrollX = 0
	renamebox.state = true
	local ext = lUtils.getFileType(f.path)
	if ext == ".llnk" then
		ext = ""
	end
	renamebox.select = {1,#fname-#ext}
	renamebox.cursor.a = 1+#fname-#ext
	renamebox.cursor.x = renamebox.cursor.a
	renamebox.update("timer")
	local ok,err = pcall(function() render(true) end)
	if not ok then
		lOS.bsod(err)
	end
	renamebox.render()
	os.queueEvent("renamebox")
end

local function fInvShort(obj,updateFiles,render)
	local o = {lUtils.popup("Problem with shortcut","The item '"..obj.file.sName.."' that this shortcut refers to has been changed or moved, so this shortcut will no longer work properly.\n\nDo you want to delete this shortcut?",37,13,{"Yes","No"})}
	if o[1] and o[3] == "Yes" then
		fs.delete(obj.file.path)
		updateFiles()
	end
	term.setTextColor(colors.white)
	render()
end
lOS.explorer.fInvShort = fInvShort

local function genContextMenu(f,s,sl,selected,updateFiles,render,LevelOS,isDesktop)
	local shortcache = lOS.explorer.shortcache
	local winObj = term.current()

	local function fInvShortInternal(obj)
		term.redirect(winObj)
		LevelOS.overlay = nil
		lOS.noEvents = false
		LevelOS.self.window.events = nil
		fInvShort(obj,updateFiles,render)
		term.setTextColor(colors.white)
	end

	local function fDelete(obj)
		for k,v in pairs(selected) do
			fs.delete(k)
		end
		selected = {}
		updateFiles()
	end

	local function fOpen(obj)
		local f = obj.file
		selected = {}
		sl.folder = f.path
		updateFiles()
		scrollY = 0
	end

	local function fCut(obj)
		lOS.fClipboard = {}
		for k,v in pairs(selected) do
			table.insert(lOS.fClipboard,k)
		end
		lOS.fCut = lUtils.instantiate(lOS.fClipboard)
		selected = {}
	end

	local function fCopy(obj)
		lOS.fClipboard = {}
		lOS.fCut = {}
		for k,v in pairs(selected) do
			table.insert(lOS.fClipboard,k)
		end
	end

	local function fPaste(obj)
		local tFolder = sl.folder
		for c=1,#lOS.fClipboard do
			if fs.exists(lOS.fClipboard[c]) == true then
				fs.copy(lOS.fClipboard[c],uFP(fs.combine(tFolder,fs.getName(lOS.fClipboard[c]))))
			end
			if locateEntry(lOS.fCut,lOS.fClipboard[c]) == true then
				fs.delete(lOS.fClipboard[c])
				table.remove(lOS.fCut,({locateEntry(lOS.fCut,lOS.fClipboard[c])})[2])
			end
		end
		lOS.fClipboard = {}
		lOS.fCut = {}
		updateFiles()
	end

	local opink
	local function fRename(obj)
		lOS.explorer.fRename(obj,s,sl,render,LevelOS,isDesktop)
		if isDesktop then
			local renamebox = sl.renamebox
			term.redirect(terminal)
			render()
			renamebox.render()
			lOS.noEvents = false
			while true do
				local e = {os.pullEventRaw()}
				if e[1] == "char" and e[2] == " " then
					e[2] = "_"
				end
				if e[1] == "key" and e[2] == keys.enter then
					renamebox.state = false
					--sl.renaming = nil
				else
					renamebox.update(unpack(e))
					--render()
					renamebox.render()
				end
				if not renamebox.state then
					local pth = fs.combine("User/Desktop",renamebox.txt)
					if renamebox.isShortcut then
						pth = pth..".llnk"
					end
					if pth == sl.renaming or fs.combine(pth,"") == "User/Desktop" then
						-- nothing
					elseif fs.exists(pth) then
						local newPth = uFP(pth)
						local r = {lUtils.popup("Rename File","Do you want to rename \""..fs.getName(sl.renaming):gsub("_"," ").."\" to \""..fs.getName(newPth):gsub("_"," ").."\"?\n\nThere is already a file with the same name in this location.",41,11,{"Yes","No"})}
						if r[1] and r[3] == "Yes" then
							fs.move(sl.renaming,newPth)
						end
					else
						fs.move(sl.renaming,pth)
					end
					renamebox = nil
					sl.renamebox = nil
					sl.renaming = nil
					term.setCursorBlink(false)
					updateFiles()
					render()
					break
				end
			end
		end
	end

	local function fNew(obj)
		local pth = uFP(fs.combine(sl.folder,"New_"..obj.txt:gsub(" ","_").."."..obj.format))
		lUtils.fwrite(pth,obj.preset)
		term.redirect(winObj)
		updateFiles()
		render()
		fRename(pth)
		-- rename
	end

	local function fNewFolder(obj)
		local pth = uFP(fs.combine(sl.folder,"New_Folder"))
		fs.makeDir(pth)
		term.redirect(winObj)
		updateFiles()
		render()
		fRename(pth)
		-- rename
	end

	local function fOpenWith(obj)
		if LevelOS and LevelOS.self and LevelOS.self.window then
			LevelOS.self.window.events = nil
		end
		LevelOS.overlay = nil
		lOS.noEvents = false
		local p = sl.openWith(obj.file)
		if p then
			p = p.path
			local f = obj.file
			if p == "Lua" then
				lOS.execute(f.path)
			else
				lOS.execute(p.." "..f.path)
			end
		end
	end

	local function fPin(obj)
		table.insert(sl.config.quickaccess,obj.file.path)
		sl.saveConfig()
		sl.reloadQuickAccess()
	end

	local function fUnpin(obj)
		local s,i = locateEntry(sl.config.quickaccess,obj.file.path)
		if s then
			table.remove(sl.config.quickaccess,i)
			sl.saveConfig()
			sl.reloadQuickAccess()
		end
	end

	local function fShortcut(obj)
		local pth = uFP(fs.combine(obj.folder,obj.name:gsub(" ","_").."_-_Shortcut.llnk"))
		lUtils.asset.save({obj.file.path},pth)
		updateFiles()
		render()
	end

	local function fDesktopShortcut(obj)
		lOS.genIco(obj.file.path)
		--[[local pth = uFP(fs.combine(obj.folder,obj.name:gsub(" ","_")..".llnk"))
		lUtils.asset.save({obj.file.path},pth)
		os.queueEvent("explorer_reload")]]
	end

	local function fBackground(obj)
		lOS.explorer.desktopConfig.background = {path=obj.file.path,resize=obj.txt:lower()}
		os.queueEvent("explorer_reload")
	end

	local function fAddToBackground(obj)
		local dConfig = lOS.explorer.desktopConfig
		if not dConfig.background[1] then
			local obg = dConfig.background
			dConfig.background = {color=obg.color,obg}
		end
		table.insert(dConfig.background,{path=obj.file.path,resize=obj.txt:lower()})
		os.queueEvent("explorer_reload")
		lOS.explorer.desktopBackground = nil
	end

	local function fCopyPath(obj)
		ccemux.setClipboard(obj.file.path)
	end

	if isDesktop then
		fOpen = fOpenWin
	end

	local options
	if not f then
		local newfiles = {}
		for k,v in pairs(fTypes) do
			if type(v) == "table" and type(v.emptyFilePreset) == "string" then
				table.insert(newfiles,{txt=v.name,preset=v.emptyFilePreset,action=fNew,format=k})
			end
		end
		table.insert(newfiles,{txt="bImg Icon",preset='{{{"   ","   ","   "},{"   ","   ","   "},{"   ","   ","   "}}}',action=fNew,format="bimg"})
		local opt = {
			{{txt="Refresh",action=updateFiles}},
			{{txt="Paste",action=fPaste,disabled=(#lOS.fClipboard == 0 or fs.isReadOnly(sl.folder))}},
			{{txt="New",disabled=(fs.isReadOnly(sl.folder)),action={{txt="Folder",action=fNewFolder},newfiles}}} -- import from formats.lconf
		}
		if isDesktop then
			local txtcolors = {}
			for k,v in pairs(colors) do
				if type(v) == "number" then
					table.insert(txtcolors,k)
				end
			end
			table.sort(txtcolors)
			local txtcoloroptions = {}
			for c=1,#txtcolors do
				local col = colors[txtcolors[c]]
				local name = txtcolors[c]:sub(1,1):upper()..txtcolors[c]:sub(2)
				local b = lUtils.toBlit(col)
				if dConfig.textColor == col then
					table.insert(txtcoloroptions,{txt={" \7  "..name,nil,string.rep(b,3)}})
					if col == colors.white then
						txtcoloroptions[#txtcoloroptions].txt[2] = "fff"
					end
				else
					table.insert(txtcoloroptions,{txt={"    "..name,nil,string.rep(b,3)},action=function() dConfig.textColor = col updateFiles() render() end})
				end
			end
			if not dConfig.textColor then
				table.insert(txtcoloroptions,1,{txt=" \7  Automatic"})
			else
				table.insert(txtcoloroptions,1,{txt="    Automatic",action=function() dConfig.textColor = nil updateFiles() render() end})
			end
			table.insert(opt[1],1,{txt="View",action={
				{txt="Text color",action={txtcoloroptions}}
			}})
		end
		if ccemux then 
			table.insert(opt,{{txt="Open External Explorer",action=function() ccemux.openDataDir() end}})
		end
		options = opt
	else
		if type(f) == "string" then
			f = genFile(f)
		end
		local file = f.path
		local nf = f
		local invalidShort
		if shortcache[file] then
			f.sPath = shortcache[file][1]
			f.sName = fs.getName(f.sPath)
			if fs.exists(f.sPath) then
				nf = genFile(f.sPath)
			else
				invalidShort = true
			end
		end
		options = {
			{

			},
			{
				{txt="Cut",action=fCut},
				{txt="Copy",action=fCopy}
			},
			{
				{txt="Delete",action=fDelete},
				{txt="Rename",action=fRename,file=f,sl=sl}
			}
		}
		local createshortcut = {txt="Create shortcut",file=nf,folder=sl.folder,name=nf.name,action=fShortcut}
		local createshortcut2 = {txt="Create shortcut on desktop",file=nf,folder="User/Desktop",name=nf.name,action=fDesktopShortcut}
		if fs.getName(nf.path) == "main.lua" then
			createshortcut.name = fs.getName(fs.getDir(nf.path))
			createshortcut2.name = fs.getName(fs.getDir(nf.path))
		end
		if invalidShort then
			createshortcut.action = fInvShortInternal
			createshortcut2.action = fInvShortInternal
		end
		if not isDesktop then
			table.insert(options[3],1,createshortcut2)
			table.insert(options[3],1,createshortcut)
		end
		local disabled = {}
		if f.readOnly == true then
			disabled = {Edit=true,Cut=true,Delete=true,Rename=true}
		elseif disks[file] ~= nil then
			disabled = {Edit=true,Cut=true,Delete=true,Rename=true}
			disabled["Create Shortcut"] = true
		end
		local fc = fs.combine
		if ccemux then
			table.insert(options[3],{txt="Copy path",file=f,action=fCopyPath})
		end
		local fOpen = fOpen
		local fOpenWin = fOpenWin
		local fOpenWith = fOpenWith
		local fExec = fExec
		local fUnpin = fUnpin
		local fPin = fPin
		if invalidShort then
			fOpen = fInvShortInternal
			fOpenWin = fInvShortInternal
			fOpenWith = fInvShortInternal
			fExec = fInvShortInternal
			fUnpin = fInvShortInternal
			fPin = fInvShortInternal
		end
		if nf.isDir then
			local etxt = ""
			local isProgram = false
			if fs.exists(fc(nf.path,"main.lua")) then
				isProgram = true
				etxt = "folder "
			end
			options[1] = {{txt="Open "..etxt,action=fOpen,file=nf}}
			if not isDesktop then
				table.insert(options[1],{txt="Open "..etxt.."in new window",action=fOpenWin,file=nf})
			end
			if isProgram then
				table.insert(options[1],{txt="Execute",action=fExec,p="Lua",file=nf})
				createshortcut.action = {{txt="To program",file=genFile(fc(nf.path,"main.lua")),folder=sl.folder,name=nf.name,action=fShortcut},{txt="To folder",file=nf,folder=sl.folder,name=nf.name,action=fShortcut}}
			end
			if not isDesktop then
				if locateEntry(sl.config.quickaccess,nf.path) then
					table.insert(options[1],{txt="Unpin from Quick access",action=fUnpin,file=nf})
				else
					table.insert(options[1],{txt="Pin to Quick access",action=fPin,file=nf})
				end
			end
		elseif fTypes[nf.type] and fTypes[nf.type].contextMenu and not invalidShort then
			local tbl = {}
			for k,v in ipairs(fTypes[nf.type].contextMenu[1]) do
				table.insert(tbl,{txt=v,file=nf,p=fTypes[nf.type].contextMenu[2][k],action=fExec})
			end
			if nf.type == "bimg" or nf.type == "limg" or nf.type == "nfp" then
				table.insert(tbl,{txt="Set as desktop background",action={{{txt="Stretch",file=nf,action=fBackground},{txt="Repeat",file=nf,action=fBackground},{txt="Center",file=nf,action=fBackground}}}})
				table.insert(tbl,{txt="Add to desktop background",action={{{txt="Repeat",file=nf,action=fAddToBackground},{txt="Center",file=nf,action=fAddToBackground}}},disabled=(not lOS.explorer.desktopConfig.background)})
			end
			options[1] = tbl
		else
			options[1] = {{txt="Edit",action=fExec,p="rom/programs/edit.lua",file=nf}}
		end
		if shortcache[file] then
			if invalidShort then
				table.insert(options[1],2,{txt="Open file location",disabled=true})
			else
				table.insert(options[1],2,{txt="Open file location",action=fOpen,file=genFile(fs.getDir(nf.path))})
			end
		end
		local ow
		if fTypes[nf.type] and fTypes[nf.type].openWith and not nf.isDir then
			local owtbl = {}
			for k,v in ipairs(fTypes[nf.type].openWith) do
				table.insert(owtbl,{txt=lUtils.getFileName(v),file=nf,p=v,action=fExec})
			end
			ow = {txt="Open with",action={owtbl,{txt="Choose another app",action=fOpenWith,file=nf,disabled=isDesktop}}}
			if invalidShort then
				ow.disabled = true
			end
			table.insert(options[1],ow)
		end
		if nf.readOnly == true --[[and locateEntry(options[1],"Edit") == true]] then
			for k,v in ipairs(options[1]) do
				if type(v) == "table" and v.txt == "Edit" then
					v.txt = "View"
				end
			end
			--options[1][({locateEntry(options[1],"Edit")})[2]] = "View"
		end
		for _,cat in ipairs(options) do
			for k,v in ipairs(cat) do
				if type(v) == "string" and disabled[v] then
					cat[k] = {txt=v,disabled=true}
				elseif type(v) == "table" and disabled[v.txt] then
					v.disabled = true
				end
			end
		end
	end
	return options
end

lOS.explorer.genContextMenu = genContextMenu

local function cMenu(f, x, y)
	local sel = {}
	for k,v in pairs(selected) do
		local path = fc("User/Desktop",dConfig.files[k])
		sel[path] = true
	end
	local options = genContextMenu(f,{win=term.current()},{folder="User/Desktop"},sel,reloadDesktop,render,LevelOS,true)
	local output = {lOS.contextmenu(x,y,30,options,nil,true)}
	return unpack(output)
end

render()
os.sleep(0.05)
render()
local lastUpdate = os.epoch("utc")
local tID = os.startTimer(10)
while true do
	local e = {os.pullEvent()}
	if e[1] == "explorer_full_reload" then
		lOS.explorer.shortcache = {}
		lOS.explorer.imgcache = {}
		lOS.explorer.nimgcache = {}
		lOS.explorer.desktopBackground = nil
		reloadDesktop()
		render()
	elseif e[1] == "term_resize" or e[1] == "explorer_reload" then
		lOS.explorer.desktopBackground = nil
		reloadDesktop()
		render()
	elseif e[1]:find("mouse") and e[3] and e[4] then
		local x,y = math.ceil(e[3]/8),math.ceil(e[4]/5)
		if e[1] == "mouse_click" then
			lOS.focusWin = lOS.wins[0]
		end
		if e[1] == "mouse_drag" and drag then
			drag.x,drag.y = e[3],e[4]
			drag.moved = true
			render()
		elseif e[1] == "mouse_up" and drag then
			if not desktopMap[x][y] then
				desktopMap[x][y] = drag.id
				local icon = dConfig.sizes[currentSize][drag.id]
				desktopMap[icon.x][icon.y] = nil
				icon.x,icon.y = x,y
				lUtils.asset.save(dConfig,"LevelOS/data/desktop.lconf")
			end
			drag = nil
			render()
		elseif e[3]%8 ~= 0 and desktopMap[x][y] then
			if e[1] == "mouse_click" then
				local id = desktopMap[x][y]
				if selected[id] and os.epoch("utc") < selected[id]+500 and e[2] == 1 then
					local path = fc("User/Desktop",dConfig.files[id])
					local rPath = path
					local cmd = path
					local shortcache = lOS.explorer.shortcache
					local exec = false
					local invalidShort = false
					local f = genFile(path)
					if shortcache[path] then
						cmd = shortcache[path][1]
						rPath = cmd
						f.sName = rPath
						if not fs.exists(rPath) then
							invalidShort = true
						end
						if shortcache[path].args and #shortcache[path].args > 0 then
							cmd = cmd.." "..table.concat(shortcache[path].args)
						end
						if shortcache[path].program then
							if shortcache[path].program ~= "Lua" then
								cmd = shortcache[path].program.." "..cmd
							end
							exec = true
						end
					end
					if invalidShort then
						fInvShort({file=f},reloadDesktop,render)
					else
						local fType = lUtils.getFileType(rPath):sub(2)
						if exec then
							lOS.execute(cmd)
						elseif fs.isDir(rPath) then
							lOS.execute("Program_Files/LevelOS/Explorer "..cmd)
						elseif fileTypes[fType] and fileTypes[fType].program then
							local p = fileTypes[fType].program
							if p == "Lua" then
								lOS.execute(cmd)
							else
								lOS.execute(p.." "..cmd)
							end
						elseif fType == "" then
							lOS.execute(cmd)
						end
					end
					selected = {}
				else
					if not (lUtils.isHolding(keys.leftCtrl) or lUtils.isHolding(keys.leftShift)) then
						selected = {}
					end
					if e[2] == 1 then
						selected[id] = os.epoch("utc")
						drag = {id=id,ox=(e[3]-1)%8,oy=(e[4]-1)%5,x=e[3],y=e[4],moved=false}
					else
						selected[id] = 0
					end
				end
				render()
			elseif e[1] == "mouse_up" and e[2] == 2 then
				local id = desktopMap[x][y]
				local path = fc("User/Desktop",dConfig.files[id])
				--[[local rPath = path
				local cmd = path
				local shortcache = lOS.explorer.shortcache
				local exec = false]]
				local f = genFile(path)
				f.x1,f.y1 = 1+(x-1)*8,1+(y-1)*5
				local lineH = math.min(#lUtils.wordwrap(lUtils.getFileName(f.path),7),4)
				f.x2,f.y2 = f.x1+6,f.y1+3+lineH
				cMenu(f,e[3],e[4])
			end
		elseif e[1] == "mouse_click" and not (lUtils.isHolding(keys.leftCtrl) or lUtils.isHolding(keys.leftShift)) then
			selected = {}
			render()
			if e[2] == 2 then
				cMenu(nil, e[3], e[4])
			end
		end
	elseif (e[1] == "timer" and e[2] == tID) or os.epoch("utc")-10000 > lastUpdate then
		lastUpdate = os.epoch("utc")
		if not (e[1] == "timer" and e[2] == tID) then
			os.cancelTimer(tID)
		end
		tID = os.startTimer(10)
		reloadDesktop()
		render()
	end
	if e[1] == "mouse_up" then
		drag = nil
	end
end