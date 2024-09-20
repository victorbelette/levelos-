-- LevelOS

term.clear()
term.setCursorPos(1,1)

if not fs.exists("LevelOS") then
	shell.run("wget run http://install.leveloper.cc")
	return
end
for k,v in pairs(colors) do
	if type(v) == "number" then
		term.setPaletteColor(v,term.native().getPaletteColor(v))
	end
end

if lOS then
	error("LevelOS is already running, silly!")
end

_G.lOS = {}
lOS.path = shell.getRunningProgram()



local function encodeUTF8(asciiText)
    local utf8Text = ""
    
    for i=1, #asciiText, 32768 do
        utf8Text = utf8Text..utf8.char(string.byte(asciiText, i, math.min(i + 32767, #asciiText)))
    end
    
    return utf8Text
end

local function decodeUTF8(utf8Text)
    local asciiText = ""
    
    local ok, t = pcall(function() 
        return string.char(utf8.codepoint(utf8Text, 1, #utf8Text)) 
    end)
    
    if ok then
        asciiText = t
    else
        local ok2, err = pcall(function()
            for _, codepoint in utf8.codes(utf8Text) do
                if codepoint < 256 then
                    asciiText = asciiText .. string.char(codepoint)
                else
                    asciiText = asciiText .. "?"
                end
            end
        end)

        if not ok2 then
            _G.debugCurrentText = asciiText
            _G.debugTextInput = utf8Text

            error(err, 2)
        end
    end
    
    return asciiText
end


local function encodeAll(...)
    local tbl = table.pack(...)
    for k,v in pairs(tbl) do
        if type(v) == "string" and not utf8.len(v) then
            tbl[k] = encodeUTF8(v)
        end
    end
    
    return table.unpack(tbl, 1, tbl.n)
end
 
local function decodeAll(...)
    local tbl = table.pack(...)
    for k,v in pairs(tbl) do
        if type(v) == "string" then
            tbl[k] = decodeUTF8(v)
        end
    end
    
    return table.unpack(tbl, 1, tbl.n)
end

lOS.utf8 = {
	decode = decodeUTF8,
	encode = encodeUTF8,
	decodeAll = decodeAll,
	encodeAll = encodeAll,
}

local function extractVersion(str)
	local version = str:match("ComputerCraft (%d+%.%d+%.%d+)")
	return version
end

local function isVersionAbove(version1, version2)
	local function splitVersion(version)
		local parts = {}
		for part in version:gmatch("(%d+)") do
			table.insert(parts, tonumber(part))
		end
		return parts
	end

	local v1Parts = splitVersion(version1)
	local v2Parts = splitVersion(version2)

	for i = 1, math.max(#v1Parts, #v2Parts) do
		local v1 = v1Parts[i] or 0
		local v2 = v2Parts[i] or 0
		if v1 > v2 then
			return true
		elseif v1 < v2 then
			return false
		end
	end

	return true -- They are equal if all parts are equal
end

if isVersionAbove(extractVersion(_HOST), "1.109") then
    local fopen = fs.open
     
    function fs.open(path, mode)
        local f = fopen(path, mode)
        if not f then return nil end
        
        local customHandle = {}
        
        for k,v in pairs(f) do
            if mode:find("b") then
                customHandle[k] = function(...) return v(...) end
            else
                customHandle[k] = function(...) return decodeAll(v(encodeAll(...))) end
            end
        end
        
        return customHandle
    end
end


--enable mouse if no color
if not rtype then
	_G.rtype = type
	_G.type = function(obj)
		local mt = getmetatable(obj)
		if rtype(mt) == "table" and mt.__type then
			if rtype(mt.__type) == "string" then
				return mt.__type
			elseif rtype(mt.__type) == "function" then
				return mt.__type(obj)
			end
		else
			return rtype(obj)
		end
	end
end

function _G.pairs(t)
    local mt = getmetatable(t)
    if mt and type(mt.__pairs) == "function" then
        return mt.__pairs(t)
    else
        return next, t, nil
    end
end

if not hardreboot then
	_G.hardreboot = os.reboot
end

if fs.combine("a","b","c") == fs.combine("a","b") then
	local ocombine = fs.combine
	function fs.combine(path,...)
		local parts = {...}
		for p=1,#parts do
			path = ocombine(path,parts[p])
		end
		return path
	end
end

local w,h = term.getSize()
if h < 19 then return end
local newwin = false

local therealOGterm = term.current()
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

if fs.exists("AppData") == false then
	fs.makeDir("AppData")
end

if fs.exists("User") == false then
	fs.makeDir("User")
	fs.makeDir("User/Documents")
	fs.makeDir("User/Images")
	fs.makeDir("User/Scripts")
	fs.makeDir("User/Downloads")
end

if not fs.exists("bigfont") then
	shell.run("pastebin get 3LfWxRWh bigfont")
end

local to_colors, to_blit = {}, {}
for i = 1, 16 do
	to_blit[2^(i-1)] = ("0123456789abcdef"):sub(i, i)
	to_colors[("0123456789abcdef"):sub(i, i)] = 2^(i-1)
end
 
 
 
local function toColor(theblit)
	return to_colors[theblit] or nil
end
 
 
 
local function toBlit(thecolor)
	return to_blit[thecolor] or nil
end

local function render(spr,x,y)
	local format = "lImg"
	if format == "lImg" then
		local sW,sH = #spr[1][1],#spr
		local w,h = term.getSize()
		for l=1,#spr do
			if not y then
				term.setCursorPos(math.ceil(w/2)-math.floor(sW/2),(math.ceil(h/2)-math.floor(sH/2)+(l-1))+x)
			else
				term.setCursorPos(x,y+(l-1))
			end
			local bl = {}
			bl[1] = spr[l][1]
			bl[2] = string.gsub(spr[l][2],"T",toBlit(term.getBackgroundColor()))
			bl[3] = string.gsub(spr[l][3],"T",toBlit(term.getBackgroundColor()))
			term.blit(unpack(bl))
		end
	elseif format == "nfp" or format == "nfg" then
		local b,e = string.find(spr,"\n")
		local sW,sH
		local w,h = term.getSize()
		local lines,sW = getLines(spr)
		sH = #lines
		for l=1,sH do
			term.setCursorPos(math.ceil(w/2)-math.floor(sW/2),math.ceil(h/2)-math.floor(sH/2)+(l-1))
			term.blit(string.rep(" ",#lines[l]),lines[l],lines[l])
		end
	end
end


local function fread(file)
	local f = fs.open(file,"r")
	local o = f.readAll()
	f.close()
	return o
end

local function fwrite(file,content)
	local f = fs.open(file,"w")
	f.write(content)
	f.close()
	return true
end

local loadingico = textutils.unserialize(fread("LevelOS/assets/loading.limg"))


_G.bigfont = loadfile("bigfont",_ENV)()


local progress = 0

local function centerText(text,customY,customLen) -- i tried to put indentation but pastebin is being stupid for some reason
	local x,y = term.getSize()
	local x2,y2 = term.getCursorPos()
	if customY then y2 = customY end
	local len = customLen or text:len()
	term.setCursorPos((math.ceil(x / 2) - math.floor(len / 2)), y2)
	term.write(text)
	term.setCursorPos(x2,y2+1)
end

local doUpdate
local bootText = "Initializing"
local dots = 1
local frame = 1

local function bootscreen()
	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.cyan)
	term.clear()
	local w,h = term.getSize()
	if h > 19 then
		if fs.exists("LevelOS/assets/logo_christmas.limg") and os.date("%m") == "12" then
			render(textutils.unserialize(fread("LevelOS/assets/logo_christmas.limg"))[1],math.ceil(w/2)-4,h/2-8)
		elseif fs.exists("LevelOS/assets/logo_pride.limg") then
			render(textutils.unserialize(fread("LevelOS/assets/logo_pride.limg"))[1],math.ceil(w/2)-4,h/2-8)
		else
			bigfont.writeOn(term.current(),2,"L",nil,h/2-8)
		end
	else
		if fs.exists("LevelOS/assets/logo_christmas.limg") and os.date("%m") == "12" then
			render(textutils.unserialize(fread("LevelOS/assets/logo_christmas.limg"))[1],math.ceil(w/2)-4,h/2-5)
		elseif fs.exists("LevelOS/assets/logo_pride.limg") then
			render(textutils.unserialize(fread("LevelOS/assets/logo_pride.limg"))[1],math.ceil(w/2)-4,h/2-5)
		else
			bigfont.writeOn(term.current(),2,"L",nil,h/2-5)
		end
	end
	while true do
		if doUpdate then
			term.setBackgroundColor(colors.blue)
			term.setTextColor(colors.white)
			term.clear()
			local w,h = term.getSize()
			term.setCursorPos(1,math.ceil(h/2))
			centerText("Getting ready for updates")
			centerText("Do not turn off your computer")
			local init = false
			while true do
				render(loadingico[frame],-5)
				if progress > 0 then
					if not init then
						term.setBackgroundColor(colors.blue)
						term.setTextColor(colors.white)
						term.clear()
						render(loadingico[frame],-5)
						init = true
					end
					term.setCursorPos(1,math.ceil(h/2))
					centerText("Working on updates")
					centerText(math.floor(progress + 0.5).."% complete")
					centerText("Do not turn off your computer")
				end
				frame = frame+1
				if frame > #loadingico then
					frame = 1
				end
				os.sleep(0.1)
			end
		end
		if h > 19 then
			render(loadingico[frame],10)
			if bootText then
				centerText("          "..bootText..string.rep(".",dots).."          ",h/2+14,#("          "..bootText.."          "))
			end
		else
			render(loadingico[frame],7)
		end
		os.pullEvent()
	end
end

local function loadIco()
	while true do
		frame = frame+1
		if frame > #loadingico then
			frame = 1
		end
		dots = dots+0.5
		if dots > 3 then dots = 0 end
		os.sleep(0.1)
	end
end

local hpost = function(...)
	while true do
		local ret = table.pack(http.post(...))
		if not ret[1] then
			os.sleep(0.5)
		else
			badConn = false
			return table.unpack(ret, 1, ret.n)
		end
	end
end

local function getField(thing,fieldname)
	if string.find(thing,"<"..fieldname..">",1,true) ~= nil and string.find(thing,"</"..fieldname..">",1,true) ~= nil then
		local begin = nil
		local ending = nil
		local trash,begin = string.find(thing,"<"..fieldname..">",1,true)
		local ending,ending2 = string.find(thing,"</"..fieldname..">",begin+1,true)
		if begin ~= nil and ending ~= nil then
			return string.sub(thing,begin+1,ending-1),string.sub(thing,1,trash-1)..string.sub(thing,ending2+1,string.len(thing))
		end
	end
	return nil
end

local function download(pth)
	local f = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode(pth).."&code="..textutils.urlEncode("lSlb8kZq"),{Cookie=userID}).readAll()
	if f ~= "409" and f ~= "403" and f ~= "401" then
		if pth == "startup.lua" and f ~= fread(shell.getRunningProgram()) then
			fwrite(shell.getRunningProgram(),f)
			os.sleep(1)
			os.reboot()
		end
		if pth ~= "startup.lua" then
			fwrite(pth,f)
		end
		return true
	else
		return false
	end
end

local step = 0.05
local function update()
	bootText = "Connecting to server"
	os.sleep(step)
	local opost = http.post
	local ping = http.get("https://os.leveloper.cc/ping.php")
	if not ping then
		bootText = "Trying HTTP"
		os.sleep(step)
		local ping2 = http.get("http://os.leveloper.cc/ping.php")
		if not ping2 then
			bootText = "Starting in offline"
			os.sleep(step)
			-- no internet
			return
		end
		function http.post(...)
			local args = table.pack(...)
			local r = table.pack(opost(...))
			if not r[1] and string.find(args[1],"https://",nil,true) == 1 then
				args[1] = "http"..string.sub(args[1],6,#args[1])
				return opost(table.unpack(args))
			else
				return table.unpack(r)
			end
		end
		local oget = http.get
		function http.get(...)
			local args = table.pack(...)
			local r = table.pack(oget(...))
			if not r[1] and string.find(args[1],"https://",nil,true) == 1 then
				args[1] = "http"..string.sub(args[1],6,#args[1])
				return oget(table.unpack(args))
			else
				return table.unpack(r)
			end
		end
		hpost = http.post
	end

	bootText = "Checking client version"
	os.sleep(step)
	local servertimestamp
	local clienttimestamp
	if fs.exists("LevelOS/data/version.txt") then
		clienttimestamp = tonumber(fread("LevelOS/data/version.txt"))
	end
	if not clienttimestamp then
		clienttimestamp = 0
	end
	bootText = "Looking for updates"
	os.sleep(step)
	local response,err = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode("").."&code="..textutils.urlEncode("lSlb8kZq"))
	local res2,err2
	if fs.exists("LevelOS/startup/LevelCloud.lua") then
		res2,err2 = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode("").."&code="..textutils.urlEncode("Sm0f1bwQ"))
	end
	if res2 then
		bootText = "Updating LevelCloud"
		os.sleep(step)
		local f = res2.readAll()
		local sTS = tonumber((getField(f,"version"))) or math.huge
		local cTS = fs.attributes("LevelOS/startup/LevelCloud.lua").modification or fs.attributes("LevelOS/startup/LevelCloud.lua").modified or 0
		if sTS > cTS then
			local f = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode("LevelCloud.lua").."&code="..textutils.urlEncode("Sm0f1bwQ"))
			if f then
				fwrite("LevelOS/startup/LevelCloud.lua",f.readAll())
			end
		end
	end
	bootText = "Processing"
	os.sleep(step)
	if not response then
		-- could not connect
		--os.sleep(0.5)
		-- put "starting in offline mode"
		return
	end
	local f = response.readAll()
	servertimestamp = tonumber((getField(f,"version")))
	local tFiles = 0
	local pack = "Full"
	if fs.exists("LevelOS/data/settings.lconf") then
		local set = textutils.unserialize(fread("LevelOS/data/settings.lconf"))
		if set.package then
			pack = set.package
		end
	end

	local tree = {}
	local folders = {}
	local function searchFolder(folder)
		--print("Searching folder root/"..folder)
		local f = hpost("https://os.leveloper.cc/sGet.php","path="..textutils.urlEncode(folder).."&code="..textutils.urlEncode("lSlb8kZq")).readAll()
		--print(f)
		local f2 = f
		while true do
			local file = nil
			file,f = getField(f,"file")
			if not file then
				break
			else
				local name = getField(file,"name")
				local timestamp = getField(file,"timestamp")
				timestamp = tonumber(timestamp)
				if pack == "Full" or fs.exists(fs.combine(folder,name)) or folder == "LevelOS/assets" or fs.combine(folder,name) == "startup.lua" then
					tree[fs.combine(folder,name)] = {timestamp=timestamp}
					tFiles = tFiles+1
				end
				--print("Found "..fs.combine(folder,name))
			end
		end
		f = f2
		while true do
			local file = nil
			file,f = getField(f,"folder")
			if not file then
				break
			else
				local name = getField(file,"name")
				if not fs.exists(fs.combine(folder,name)) then
					fs.makeDir(fs.combine(folder,name))
				end
				folders[fs.combine(folder,name)] = ""
				searchFolder(fs.combine(folder,name))
			end
		end
		return true
	end
	if servertimestamp > clienttimestamp then
		doUpdate = true
		local deleteFiles = {
			"LevelOS/explorer.lua",
			"LevelOS/Pigeon.lua",
			"LevelOS/LevelCloud.lua",
			"LevelOS/notepad.lua",
			"LevelOS/Register.lua",
		}
		if fs.exists("LevelOS/data/nativelog.txt") then
			fs.move("LevelOS/data/nativelog.txt","LevelOS/data/nativelog.lconf")
		end
		for f=1,#deleteFiles do
			if fs.exists(deleteFiles[f]) then
				fs.delete(deleteFiles[f])
			end
		end
	else
		bootText = "Checking file integrity"
		os.sleep(step)
		local icheck = {
			--"startup.lua",
			"bigfont",
			"blittle",
			"LevelOS",
			"LevelOS/system.lua",
			"LevelOS/startup",
			"LevelOS/startup/lUtils.lua",
			"LevelOS/assets",
			"LevelOS/assets/Circle_Symbols.limg",
			"LevelOS/assets/circProgress.limg",
			"LevelOS/assets/Compact_Icons.limg",
			"LevelOS/assets/Desktop_Icons.limg",
			"LevelOS/assets/loading.limg",
			"LevelOS/assets/logo_pride.limg",
			"LevelOS/assets/QR_Code.limg",
			"LevelOS/assets/wifi.limg",
			"LevelOS/login.lua",
			"LevelOS/Changelog.lua",
			"LevelOS/lStore.lua",
			"LevelOS/SystemUI.lua",
			"LevelOS/Task_Manager.lua",
		}
		local aFiles = {} -- absent files
		for f=1,#icheck do
			if not fs.exists(icheck[f]) then
				table.insert(aFiles,icheck[f])
			end
		end
		if #aFiles > 0 then
			bootText = "Integrity compromised"
			os.sleep(0.5)
			bootText = "Restoring files"
			if not searchFolder("") then return false end

			for f=1,#aFiles do
				while not download(aFiles[f]) do
				end
			end
			bootText = "Restarting"
			os.sleep(1)
			os.reboot()
		end
	end
	
	if doUpdate then
		if not searchFolder("") then return false end

		if tree["startup.lua"] then
			download("startup.lua")
		end

		for k,v in pairs(tree) do
			if download(k,root,v.timestamp) == true then
				progress = progress+(100/tFiles)
			end
		end
		fwrite("LevelOS/data/version.txt",tostring(servertimestamp))
		os.sleep(1)
		os.reboot()
	end
	if not fs.exists("LevelOS/assets/wifi.limg") then
		folders["LevelOS/assets"] = ""
		if not searchFolder("LevelOS/assets") then return false end
		for k,v in pairs(tree) do
			if download(k) == true then
			end
		end
	end
	bootText = "Loading system"
	os.sleep(step)
end


parallel.waitForAny(update,bootscreen,loadIco)

local expect = require "cc.expect".expect

local function wrap(txt,width)
	local lines = {}
	for line in txt:gmatch("([^\n]*)\n?") do
		table.insert(lines,"")
		for word in line:gmatch("%S*%s?") do
			if #lines[#lines]+#word > width and #lines[#lines] > 0 then
				lines[#lines+1] = ""
			end
			if #lines[#lines]+#word > width then
				local tWord = word
				while #lines[#lines]+#tWord > width do
					print(tWord:sub(1,width))
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
	if txt:sub(#txt) == "\n" then
		table.insert(lines,"")
	end
	return lines
end

local function bPrint(txt)
	local x,y = term.getCursorPos()
	local w,h = term.getSize()

	local text = wrap(txt,w-(x-1))
	for t=1,#text do
		term.write(text[t])
		term.setCursorPos(x,y+t)
	end
end

local function wordwrap(str)
	local x,y = term.getCursorPos()
	local tW,tH = term.getSize()
	for w in str:gmatch("%S+") do
		local x1,y1 = term.getCursorPos()
		if x1+(#w*3) >= tW then
			bigfont.bigPrint(" ")
			local x2,y2 = term.getCursorPos()
			term.setCursorPos(x,y2)
		end
		bigfont.bigWrite(w.." ")
	end
end


if fs.exists("LevelOS/lStore.lua") then
	shell.setAlias("lStore","LevelOS/lStore.lua")

	local completion = require "cc.shell.completion"
	local function completelStorePut(shell, text, previous)
		if previous[2] == "put" then
			return fs.complete(text, "User/Cloud", true, false)
		end
	end

	shell.setCompletionFunction("LevelOS/lStore.lua", completion.build(
		{ completion.choice, { "put ", "get ", "run " } },
		completelStorePut
	))
end

if jit then
	shell.run("lStore get JITAlert LevelOS/startup/JITAlert2.lua")
	if fs.exists("LevelOS/startup/JITAlert2.lua") then
		if fs.exists("LevelOS/startup/JITAlert.lua") then
			fs.delete("LevelOS/startup/JITAlert.lua")
		end
		fs.move("LevelOS/startup/JITAlert2.lua","LevelOS/startup/JITAlert.lua")
	end
elseif fs.exists("LevelOS/startup/JITAlert.lua") then
	fs.delete("LevelOS/startup/JITAlert.lua")
end

local u

local u = {pcall(loadfile("LevelOS/system.lua",_ENV))}
_G.whatitreturn = u
local link
local copied = false
local crashwin
function bsodRender()
	term.redirect(therealOGterm)
	term.setPaletteColor(colors.blue,0,120/255,215/255)
	term.setPaletteColor(colors.white,1,1,1)
	term.setCursorPos(4,4)
	term.setBackgroundColor(colors.blue)
	term.clear()
	local w,h = term.getSize()
	if w > 140 then
		crashwin = window.create(therealOGterm,12,8,w/2+10,h-12)
		bigfont.writeOn(therealOGterm,3,"L",w-40,math.ceil(h/2)-10)
	else
		crashwin = window.create(therealOGterm,4,5,w-8,h-5)
	end
	term.redirect(crashwin)
	term.setBackgroundColor(colors.blue)
	term.clear()
	if w > 110 and h > 40 and fs.exists("LevelOS/assets/QR_Code.limg") then
		local qrcode = textutils.unserialize(fread("LevelOS/assets/QR_Code.limg"))
		bigfont.hugePrint(":(")
		wordwrap("Your PC ran into a problem and needs to restart. Please press space to continue.")
		print("\n\n\n\n\n\n")
		local x,y = term.getCursorPos()
		render(qrcode[1],x,y)
		term.setCursorPos(x+22,y)
		bPrint("For more information about this issue and possible fixes, visit ")
		local txt = "https://discord.gg/vBsjGqy99U"
		if copied then
			txt = txt.." (copied to clipboard!)"
		end
		local tx,ty = term.getCursorPos()
		local tw,th = term.getSize()
		if tx+(#txt-1) > tw then
			ty = ty+1
			tx = x+22
		end
		if ccemux and ccemux.setClipboard then
			link = {x=tx,y=ty,w=#txt,h=1,txt="https://discord.gg/vBsjGqy99U"}
			if copied then
				term.setTextColor(colors.cyan)
			else
				term.setTextColor(colors.lightBlue)
				term.setCursorPos(link.x,link.y+1)
				term.write(string.rep("\131",link.w))
			end
		end
		term.setCursorPos(tx,ty)
		term.write(txt)
		term.setTextColor(colors.white)
		term.setCursorPos(x+22,y+(#qrcode[1]-3))
		bPrint("If you contact support, give them this info:")
		term.setCursorPos(x+22,y+(#qrcode[1]-1))
		bPrint(u[2])
	else
		bigfont.bigPrint(":(")
		print("\nYour PC ran into a problem and needs to restart. Please press space to continue.")
		print("\nError:")
		print(u[2])
	end
end
bsodRender()
os.sleep(1)
while true do
	local e = {os.pullEventRaw()}
	if e[1] == "mouse_click" then
		local x,y = crashwin.getPosition()
		e[3] = e[3]-(x-1)
		e[4] = e[4]-(y-1)
	end
	if e[1] == "key" and e[2] == keys.space then
		hardreboot()
	elseif e[1] == "term_resize" then
		bsodRender()
	elseif link and e[1] == "mouse_click" and e[3] >= link.x and e[4] == link.y and e[3] <= link.x+(link.w-1) then
		ccemux.setClipboard(link.txt)
		copied = true
		bsodRender()
	elseif link and e[1] == "mouse_click" then
		--[[term.setCursorPos(1,1)
		print(textutils.serialize(link))
		print(textutils.serialize(e))]]
	elseif e[1] == "terminate" then
		term.redirect(therealOGterm)
		break
	end
end

-- TEMP FOR DEBUGGING
term.setBackgroundColor(colors.black) term.clear() term.setCursorPos(1,1)
shell.run("shell")