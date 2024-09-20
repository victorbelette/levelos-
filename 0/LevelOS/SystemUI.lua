LevelOS.self.window.events = "all"
local w,h = lOS.wAll.getSize()
local timeObj = {x=w-13,w=8}
local function round(n)
	return math.floor(n + 0.5)
end
local oclickmenu = lUtils.clickmenu
lUtils.oclickmenu = oclickmenu
local opopup = lUtils.popup
local oinputbox = lUtils.inputbox
local events = {}
local doLog = false
local subprocesses = {}
local theOverlayFunction

local oshutdown = os.shutdown
local oreboot = os.reboot
local function shutdownscreen(reboot)
	local bgcolor = colors.cyan
	local txtcolor = colors.white
	local txtcolor2 = colors.gray
	local txtcolor3 = colors.lightGray
	local button1 = colors.lightBlue -- fill
	local button2 = colors.cyan -- border
	local button3 = colors.white -- text

	lOS.focusWin = lOS.wins[0]
	local nEvents = lOS.noEvents
	lOS.noEvents = true
	local img = lUtils.asset.load("LevelOS/assets/loading.limg")
	local iw,ih = #img[1][1][1],#img[1]
	local frame = 1
	local action = 1
	local programs = {}
	local objs = {}
	local sel
	local function genPrograms()
		programs = {}
		for i,process in ipairs(lOS.processes) do
			if (process.env and process.env.LevelOS and type(process.env.LevelOS.close) == "function") or process.winMode ~= "background" then
				table.insert(programs,process) -- ha potato
			end
		end
	end
	local function drawObj(obj)
		term.setTextColor(obj.border)
		term.setBackgroundColor(obj.color)
		lUtils.border(obj.x1, obj.y1, obj.x2, obj.y2, "fill")
		term.setCursorPos(obj.x1+1,obj.y1+1)
		term.setTextColor(button3)
		term.write(obj.txt)
	end
	local function overlayFunc()
		term.setCursorBlink(false)
		term.setBackgroundColor(bgcolor)
		term.clear()
		local w,h = term.getSize()
		lUtils.renderImg(img[frame],nil,math.ceil(h/2)-2)
		term.setCursorPos(1,math.ceil(h/2)+2)
		term.setTextColor(txtcolor)
		if reboot then
			lUtils.centerText("Restarting")
		else
			lUtils.centerText("Shutting down")
		end
	end
	LevelOS.overlay = overlayFunc
	local oTime = os.epoch("utc")
	lOS.save()
	local render
	local e
	local closewin
	while true do
		local tID = os.startTimer(0.1)
		while true do
			e = {os.pullEventRaw()}
			LevelOS.overlay = overlayFunc
			if os.epoch("utc") > oTime+250 and action == 1 then
				action = 2
				genPrograms()
				if #programs == 0 then
					if reboot then
						oreboot()
					else
						oshutdown()
					end
				else
					closewin = window.create(lOS.wAll,2,2,51-2,19-2,false)
					function render()
						objs = {}
						local list = {}
						for i,p in ipairs(lOS.processes) do
							if p.winMode ~= "background" or (p.env and p.env.LevelOS and type(p.env.LevelOS.close) == "function") then
								table.insert(list,p)
							end
						end
						local cTerm = term.current()
						local tW,tH = lOS.wAll.getSize()
						local cW,cH = 51,#list*3+10
						local big = false
						local spacing = 3
						local offset = 0
						if tH >= 30 and tW >= 100 then
							big = true
							cW = 74
							offset = 5
						end
						if tH >= 30 then
							spacing = 4
							cH = #list*4+10+offset
						end
						closewin.reposition(math.floor(tW/2-cW/2)+1,math.floor(tH/2-cH/2)+1,cW,cH)
						term.redirect(closewin)
						term.setBackgroundColor(bgcolor)
						term.setTextColor(txtcolor)
						term.clear()
						local w,h = term.getSize()
						term.setCursorPos(1,1)
						local word = " apps"
						if #list == 1 then
							word = " app"
						end
						local act = "shutting down"
						if reboot then
							act = "restarting"
						end
						if big then
							bigfont.bigPrint("Closing "..#list..word.." and")
							bigfont.bigPrint(act)
						else
							print("Closing "..#list..word.." and "..act)
							term.setTextColor(txtcolor2) -- gray
						end
						print("To go back and save your work, click Cancel and finish what you need to.")
						for i,p in ipairs(list) do
							local path = p.path
							if fs.isDir(path) and fs.exists(fs.combine(path,"main.lua")) then
								path = fs.combine(path,"main.lua")
							end
							lOS.explorer.drawIcon(path,1,i*spacing+1+offset,true,true)
							term.setTextColor(txtcolor)
							term.setCursorPos(7,i*spacing+3+offset)
							print(p.title or lOS.explorer.getName(p.path))
							if p.env and p.env.LevelOS and type(p.env.LevelOS.close) == "function" then
								term.setCursorPos(7,i*spacing+4+offset)
								term.setTextColor(txtcolor3) -- light gray
								if reboot then
									print("This app is preventing you from restarting.")
								else
									print("This app is preventing shutdown.")
								end
							end
						end
						local txt = " Shut down anyway "
						if reboot then
							txt = " Restart anyway "
						end
						local obj1 = {x1=1, y1=#list*spacing+8+offset, x2=#txt+2, y2=#list*spacing+10+offset, id="shutdown", color=button1, border=button2, txt=txt}
						if sel == 1 then
							obj1.color = button2
							obj1.border = button1
						end
						table.insert(objs,obj1)
						drawObj(obj1)
						local txt2 = "   Cancel   "
						local obj2 = {x1=#txt+3, y1=#list*spacing+8+offset, x2=#txt+2+#txt2+2, y2=#list*spacing+10+offset, id="cancel", color=button1, border=button2, txt=txt2}
						if sel == 2 then
							obj2.color = button2
							obj2.border = button1
						end
						table.insert(objs,obj2)
						drawObj(obj2)
						term.redirect(cTerm)
					end
					local ok,err = pcall(render)
					if not ok then
						lOS.bsod(err)
						os.sleep(10)
					end
					function overlayFunc()
						term.setCursorBlink(false)
						term.setBackgroundColor(bgcolor)
						term.clear()

						closewin.setVisible(true)
						closewin.setVisible(false)
					end
					LevelOS.overlay = overlayFunc
				end
			elseif os.epoch("utc") > oTime+2250 and action == 2 then
				action = 3
				for i=#lOS.processes,3,-1 do
					local process = lOS.processes[i]
					if (process.env and process.env.LevelOS and type(process.env.LevelOS.close) == "function") or process.winMode ~= "background" then
						os.queueEvent("process_close",i,tostring(lOS.processes[i]))
					end
				end
				genPrograms()
				render()
			elseif action == 3 then
				local ocount = #programs
				genPrograms()
				if #programs == 0 then
					if reboot then
						oreboot()
					else
						oshutdown()
					end
				end
				if ocount ~= #programs then
					render()
				end
			end
			if e[1] == "key" and e[2] == keys.t and lUtils.isHolding(keys.leftCtrl) then
				term.setBackgroundColor(colors.black)
				LevelOS.overlay = theOverlayFunction
				lOS.noEvents = nil
				return
			elseif e[1] == "mouse_click" or e[1] == "mouse_up" then
				local wx,wy = closewin.getPosition()
				for i,o in ipairs(objs) do
					if lUtils.isInside(e[3]-(wx-1),e[4]-(wy-1),o) then
						if e[1] == "mouse_click" then
							sel = i
							render()
						elseif e[1] == "mouse_up" and sel == i then
							if o.id == "cancel" then
								LevelOS.overlay = theOverlayFunction
								lOS.noEvents = nil
								LevelOS.events = oEvents
								return
							elseif o.id == "shutdown" then
								if reboot then
									oreboot()
								else
									oshutdown()
								end
							end
						end
					end
				end
				if e[1] == "mouse_up" and sel then
					sel = nil
					render()
				end
			elseif e[1] == "timer" and e[2] == tID then
				break
			end
		end
		frame = frame%#img+1
	end
end

function os.shutdown()
	table.insert(subprocesses,coroutine.create(shutdownscreen))
	coroutine.resume(subprocesses[#subprocesses])
end

function os.reboot()
	table.insert(subprocesses,coroutine.create(shutdownscreen))
	coroutine.resume(subprocesses[#subprocesses],true)
end

local tbIcoAssets = lUtils.asset.load("LevelOS/assets/Compact_Icons.limg")

local tbIco = {

	["LevelOS/explorer.lua"] = {
		tbIcoAssets[1],
		{"\143","4","7"},
	},

	["LevelOS/LevelCloud.lua"] = {
		tbIcoAssets[2],
	},

	["LevelOS/Pigeon.lua"] = {
		tbIcoAssets[3],
		{"\29","b","7"},
	},

	["Program_Files/Shapescape"] = {
		tbIcoAssets[4],
		{"\7","e","7"},
	},

	["rom/programs/shell.lua"] = {
		tbIcoAssets[5],
	},

	["rom/programs/lua.lua"] = {
		tbIcoAssets[6],
	},

	["LevelOS/notepad.lua"] = {
		tbIcoAssets[7],
		{"\143","0","7"},
	},

	["*"] = {
		tbIcoAssets[8],
	},

	["LevelOS/paint.lua"] = {
		tbIcoAssets[9],
		{"\1","1","7"},
	},

}

local pHistory = {}

local function logEvents()
	while true do
		local e = {os.pullEventRaw()}
		if doLog and (e[1]:find("window") or e[1]:find("process")) then
			table.insert(events,e)
		end
		for p=#subprocesses,1,-1 do
			coroutine.resume(subprocesses[p],unpack(e))
			if coroutine.status(subprocesses[p]) == "dead" then
				table.remove(subprocesses,p)
			end
		end
	end
end


local function runOverlay(func,grayOut,system)
	local levOS
	if system then
		levOS = lOS.sysUI.env.LevelOS
	else
		levOS = lOS.wins[lOS.cWin].env.LevelOS
	end
	local oterm = term.current()
	local w,h = lOS.wAll.getSize()
	local win = window.create(oterm,1,1,w,h,false)
	local cor = coroutine.create(func)
	lOS.noEvents = true
	if grayOut then
		os.sleep(0)
	end
	for y=1,h do
		win.setCursorPos(1,y)
		win.blit(lOS.wAll.getLine(y))
	end
	local oldOverlay = levOS.overlay
	function levOS.overlay()
		for y=1,h do
			term.setCursorPos(1,y)
			term.blit(win.getLine(y))
			term.setCursorPos(1,1)
			term.setBackgroundColor(colors.white)
			term.setTextColor(colors.red)
		end
		oldOverlay()
	end
	term.redirect(win)
	local pEvent
	if system or lOS.wins[lOS.cWin].events == "all" then
		pEvent = os.pullEventRaw
	else
		pEvent = levOS.pullEvent
	end
	coroutine.resume(cor)
	while true do
		local e = {pEvent()}
		term.redirect(win)
		coroutine.resume(cor,unpack(e))
		term.redirect(oterm)
		if coroutine.status(cor) == "dead" then
			lOS.noEvents = false
			break
		end
	end
	term.redirect(oterm)
	levOS.overlay = oldOverlay
end

function runLevelOSclose(process)
	if process.env and process.env.LevelOS and type(process.env.LevelOS.close) == "function" then
		local func = process.env.LevelOS.close
		local oEnv = getfenv(func)
		local nEnv = {}
		for k,v in pairs(oEnv) do
			nEnv[k] = v
		end
		setmetatable(nEnv,getmetatable(oEnv))
		local cor = process[1]
		nEnv.abort = function()
			process[1] = cor
			process.env.LevelOS.close = func
			os.sleep(0)
		end
		setfenv(func,nEnv)
		process[1] = coroutine.create(func)
		process.env.LevelOS.close = nil
	end
end

function lUtils.clickmenu(...)
	if not lOS.cWin or not lOS.wins[lOS.cWin] or not lOS.wins[lOS.cWin].win then
		return oclickmenu(...)
	end
	local output
	local x,y = lOS.wins[lOS.cWin].win.getPosition()
	if term.current() ~= lOS.wins[lOS.cWin].win then
		local x1,y1 = term.current().getPosition()
		x = x+x1-1
		y = y+y1-1
	end
	local input = table.pack(...)
	input[1],input[2] = input[1]+(x-1),input[2]+(y-1)
	os.sleep(0)
	runOverlay(function() output = table.pack(oclickmenu(table.unpack(input,1,input.n))) end)
	return table.unpack(output,1,output.n)
end

function lOS.contextmenu(x,y,width,options,colorScheme,dividers) -- no bad change whole thing i need to put render function in LevelOS.overlay n shit
	lOS.noEvents = 2
	local oterm = term.current()
	--[[local tx,ty = lOS.wins[lOS.cWin].win.getPosition()
	if term.current() ~= lOS.wins[lOS.cWin].win then
		local tx1,ty1 = term.current().getPosition()
		tx = tx+tx1-1
		ty = ty+ty1-1
	end]]
	local tx,ty = lUtils.getWindowPos(oterm)
	term.redirect(lOS.wAll)
	local menu = lUtils.contextmenu(x+tx-1,y+ty-1,width,options,colorScheme,dividers)
	lOS.debugMenu = menu
	term.redirect(oterm)
	levOS = lOS.wins[lOS.cWin].env.LevelOS
	local oldOverlay = levOS.overlay
	function levOS.overlay()
		menu.render()
		oldOverlay()
	end
	local clicked
	while menu.status ~= "dead" do
		local e = {levOS.pullEvent()}
		term.redirect(lOS.wAll)
		clicked = menu.update(unpack(e))
		term.redirect(oterm)
	end
	lOS.noEvents = false
	levOS.overlay = oldOverlay
	os.sleep(0)
	return clicked
end
local function animation(v,x,y,w,h,gx,gy,gw,gh,dur)
	local dur = dur or 8
	if lOS.settings.animations == false then
		dur = 0
	end
	local minWin
	local oterm = term.current()
	if v.winMode == "windowed" then
		local wx,wy = v.win.getPosition()
		local ww,wh = v.win.getSize()
		minWin = window.create(term.current(),wx-1,wy-1,ww+2,wh+2,false)
		term.redirect(minWin)
		term.setBackgroundColor(colors.gray)
		term.setCursorPos(1,1)
		term.clearLine()
		term.setCursorPos(1,wh+2)
		term.clearLine()
		for t=1,wh do
			term.setCursorPos(1,t+1)
			term.write(" ")
			term.blit(v.win.getLine(t))
			term.write(" ")
		end
		term.redirect(oterm)
	else
		minWin = v.win
	end
	local width,height = term.getSize()
	--lOS.noEvents = true
	local oldOverlay = LevelOS.overlay
	local lilwin
	function LevelOS.overlay()
		if lilwin then
			lilwin.render(lilwin.x,lilwin.y)
		end
		oldOverlay()
	end
	for t=1,dur do
		local nx,ny = round(x+(gx-(x))*(t/dur)),round(y+(gy-(y))*(t/dur))
		local nw,nh = round(w+(gw-(w))*(t/dur)),round(h+(gh-(h))*(t/dur))
		lilwin = lUtils.littlewin(minWin,nw,nh)
		lilwin.x,lilwin.y = nx,ny
		os.sleep(0.05)
	end
	LevelOS.overlay = oldOverlay
	--lOS.noEvents = false
end

local imgcache = {}
local nimgcache = {}
local function UI()

	local function startMenu()
		local width,height = lOS.wAll.getSize()
		height = height-lOS.tbSize
		while true do
			local opt = {{"Task Manager"},{"Settings","Search","Execute"},"Shut Down Options >"}
			if fs.exists("LevelOS/Global_Login.lua") then
				if not lOS.userID then
					table.insert(opt[1],1,"Log in")
				else
					table.insert(opt[1],1,"Log out")
				end
			end
			a = {oclickmenu(2,height,21,opt,nil,{Settings=true})}
			if a[1] == false then
				break
			else
				if a[3] == "Task Manager" then
					if not fs.exists("LevelOS/Task_Manager.lua") then
						local f = hpost("https://old.leveloper.cc/sGet.php","path="..textutils.urlEncode("LevelOS/Task_Manager.lua").."&code="..textutils.urlEncode("lSlb8kZq")).readAll()
						fwrite("LevelOS/Task_Manager.lua",f)
					end
					lOS.execute("LevelOS/Task_Manager.lua")
					break
				elseif a[3] == "Log in" then
					lOS.execute("LevelOS/Global_Login.lua")
					break
				elseif a[3] == "Log out" then
					lUtils.logout()
					break
				elseif a[3] == "Execute" then
					-- code
					b = {lUtils.inputbox("Execute","Enter the path of the program you want to run:",27,10,{"  OK  ","Cancel"})}
					if b[1] ~= nil and b[1] ~= "" and b[3] == 1 then
						local path = string.sub(b[1],string.find(b[1],"%S+"))
						-- virusscan
						if fs.exists(path) == false then
							lUtils.popup("Error!","File does not exist.",21,8,{"OK"})
						else
							--lOS.oWins[#lOS.oWins+1] = {window.create(oldterm,1,2,w,h-3),coroutine.create(function() if shell.run(b[1]) == false then curterm = term.current() term.redirect(oldterm) lUtils.popup(fs.getName(path),fs.getName(path).." has stopped working.",25,9,{"OK"}) term.redirect(curterm) end end),fullscreen=false,minimized=false,filepath=path,icon={string.sub(fs.getName(path),1,3),string.sub(fs.getName(path),4,6)},ran=false}
						    --_G.cWin = #lOS.oWins
							lOS.execute(b[1])
						end
					end
					break
				elseif a[3] == "Search" then
					-- run search
					break
				elseif a[3] == "Settings" then
					lUtils.openWin("Settings","LevelOS/settings.lua",2,2,49,17,true)
					break
				elseif a[3] == "Shut Down Options >" then
					b = {oclickmenu(22,height,20,{{"Shut Down","Reboot"}})}
					if b[1] == true then
						if b[3] == "Shut Down" or b[3] == "Reboot" then
							--[[lOS.focusWin = lOS.wins[0]
							local te = lOS.focusWin.win
							local te2 = lOS.focusWin.owin
							allcolors = {}
						    for t=0,15,1 do
						        allcolors[#allcolors+1] = {te.getPaletteColor(2^t)}
						    end
					        for t=1,0,-0.1 do
					            for c=0,15,1 do
					                te.setPaletteColor(2^c,allcolors[c+1][1]*t,allcolors[c+1][2]*t,allcolors[c+1][3]*t)
					                te2.setPaletteColor(2^c,allcolors[c+1][1]*t,allcolors[c+1][2]*t,allcolors[c+1][3]*t)
					            end
						        os.sleep(0.05)
						    end
							lOS.save()]]
							if b[3] == "Shut Down" then
								table.insert(subprocesses,coroutine.create(shutdownscreen))
								coroutine.resume(subprocesses[#subprocesses])
								break
								--os.shutdown()
							elseif b[3] == "Reboot" then
								table.insert(subprocesses,coroutine.create(shutdownscreen))
								coroutine.resume(subprocesses[#subprocesses],true)
								break
							end
						end
					else
						break
					end
				else
					break
				end
			end
		end
		lOS.noEvents = false
	end

	local tbApps = {}
	local tbPos = {}
	_G.lOS.sysDebug = {tbApps=tbApps,tbPos=tbPos}
	local icoSel
	local previewWin
	local function drawTaskbar()
		local w,h = term.getSize()
		timeObj.x = w-13
		term.setBackgroundColor(colors.gray)
		term.setCursorPos(1,h)
		term.clearLine()
		if icoSel ~= 0 then
			term.setTextColor(colors.white)
		else
			term.setTextColor(colors.lightGray)
		end
		tbApps = {}
		tbPos = {}
		lOS.sysDebug.tbApps,lOS.sysDebug.tbPos = tbApps,tbPos
		local appLookup = {}
		for i,p in ipairs(lOS.processes) do
			if p.win and p.winMode ~= "widget" and p.winMode ~= "background" then
				if not appLookup[p.path] then
					local newLookup = {p}
					table.insert(tbApps,newLookup)
					appLookup[p.path] = newLookup
				else
					table.insert(appLookup[p.path],p)
				end
			end
		end
		if not lOS.settings then lOS.settings = {} end
	    if lOS.settings.timeOffset == nil then lOS.settings.timeOffset = 0 end
	    if lOS.settings.rTime == nil then lOS.settings.rTime = false end
	    local t = os.date("*t",os.epoch("utc")/1000+lOS.settings.timeOffset*3600)
	    local function tz(n)
	    	return string.rep("0",2-string.len(n))..n
		end
	    local dateTxt = t.day.."-"..t.month.."-"..(t.year-2000)
	    local lTime
	    if lOS.settings.rTime then
	        lTime = tz(t.hour)..":"..tz(t.min)
	    else
	        local nTime = (os.time()+lOS.settings.timeOffset)%24
	    	local nHour = math.floor(nTime)
	    	local nMinute = math.floor((nTime - nHour) * 60)
	        lTime = tz(nHour)..":"..tz(nMinute)
	    end
		if lOS.tbSize > 1 then
			term.setCursorPos(1,h-1)
			term.clearLine()
			term.setCursorPos(1,h-1)
			term.write("\144")
			term.setCursorPos(1,h)
			term.write("\141")
			for i,w in ipairs(tbApps) do
				local top
				for t=1,#w do
					if w[t] == lOS.focusWin then
						top = t
						break
					end
				end
				local bg,txt
				if top then
					bg = colors.lightGray
				else
					bg = colors.gray
				end
				if icoSel == i then
					txt = colors.lightGray
				else
					txt = colors.white
				end
				--[[for y=h-(lOS.tbSize-1),h do
					term.setBackgroundColor(bg)
					term.setTextColor(colors.gray)
					term.setCursorPos(i*4-1,y)
					term.write("\149")
					term.setBackgroundColor(colors.gray)
					term.setTextColor(bg)
					term.setCursorPos(i*4+3,y)
					term.write("\149")
				end]]
				if lOS.settings.taskbarIcons == false then
					term.setBackgroundColor(bg)
					term.setTextColor(txt)
					term.setCursorPos(i*4,h-1)
					local title = lUtils.getFileName(program)
	    			title = title:sub(1,1):upper()..title:sub(2)
					local t1,t2 = title:sub(1,3),title:sub(4,6)
					t1 = t1..string.rep(" ",3-#t1)
					t2 = t2..string.rep(" ",3-#t2)
					term.write(t1)
					term.setCursorPos(i*4,h)
					term.write(t2)
				else
					term.setBackgroundColor(bg)
					local ico
					local dPath = w[1].path
					if fs.getName(dPath) == "main.lua" then
						dPath = fs.getDir(dPath)
					end
					if imgcache[dPath] then
						ico = {imgcache[dPath]}
					elseif not nimgcache[dPath] and fs.isDir(dPath) and (fs.exists(fs.combine(dPath,"taskbar.limg")) or fs.exists(fs.combine(dPath,"taskbar.bimg"))) then
						local img
						if fs.exists(fs.combine(dPath,"taskbar.limg")) then
							img = lUtils.asset.load(fs.combine(dPath,"taskbar.limg"))
						else
							img = lUtils.asset.load(fs.combine(dPath,"taskbar.bimg"))
						end
						img = img[1]
						local iw = #img[1][1]
						local ih = #img
						if iw <= 3 and ih <= 2 then
							if not imgcache[dPath] then
								imgcache[dPath] = img
							end
							ico = {img}
						else
							nimgcache[dPath] = true
							ico = tbIco["*"]
						end
					elseif tbIco[dPath] then
						ico = tbIco[dPath]
					else
						ico = tbIco["*"]
					end
					if not ico.inactive then
						ico.inactive = lUtils.instantiate(ico[1])
						for l,line in ipairs(ico.inactive) do
							line[2] = line[2]:gsub("0","8")
							line[3] = line[3]:gsub("0","8")
						end
					end
					if icoSel == i then
						ico = ico.inactive
					else
						ico = ico[1]
					end
					-- sync pls
					lUtils.renderImg(ico,i*4,h-1)
				end
				tbPos[w] = { x1=i*4, y1=h-1, x2=i*4+2, y2=h }
				for t=1,#w do
					tbPos[w[t]] = tbPos[w]
				end
			end
			term.setTextColor(colors.white)
			if icoSel == -1 then
				term.setBackgroundColor(colors.lightGray)
				term.setCursorPos(timeObj.x,h)
				term.write(string.rep(" ",8))
			else
				term.setBackgroundColor(colors.gray)
			end
			term.setCursorPos((timeObj.x+(timeObj.w-1))-(#dateTxt-1),h)
			term.write(dateTxt)
		else
			term.setCursorPos(1,h)
			term.write("L")
			for i,w in ipairs(tbApps) do
				local top
				for t=1,#w do
					if w[t] == lOS.focusWin then
						top = t
						break
					end
				end
				local bg,txt
				if top then
					bg = colors.lightGray
				else
					bg = colors.gray
				end
				if icoSel == i then
					txt = colors.lightGray
				else
					txt = colors.white
				end
				--[[for y=h-(lOS.tbSize-1),h do
					term.setBackgroundColor(bg)
					term.setTextColor(colors.gray)
					term.setCursorPos(i*4-1,y)
					term.write("\149")
					term.setBackgroundColor(colors.gray)
					term.setTextColor(bg)
					term.setCursorPos(i*4+3,y)
					term.write("\149")
				end]]
				term.setBackgroundColor(bg)
				term.setTextColor(txt)
				term.setCursorPos(i*4,h)
				local t1 = w[1].title:sub(1,3)
				t1 = t1..string.rep(" ",3-#t1)
				term.setCursorPos(i*4,h)
				term.write(t1)
				tbPos[w] = { x1=i*4, y1=h, x2=i*4+2, y2=h } -- x1, y1, x2, y2
				for t=1,#w do
					tbPos[w[t]] = tbPos[w]
				end
			end
		end
		term.setTextColor(colors.white)
		if icoSel == -1 then
			term.setBackgroundColor(colors.lightGray)
			term.setCursorPos(timeObj.x,h-(lOS.tbSize-1))
			term.write(string.rep(" ",8))
		else
			term.setBackgroundColor(colors.gray)
		end
		term.setCursorPos(timeObj.x+2,h-(lOS.tbSize-1))
		term.write(lTime)

		-- notifications button
		term.setCursorPos(timeObj.x+timeObj.w+1,h-(lOS.tbSize-1))
		local fg = colors.white
		local bg
		if icoSel == -2 then
			bg = colors.lightGray
		else
			bg = colors.gray
		end
		fg,bg = lUtils.toBlit(fg),lUtils.toBlit(bg)
		--[[if #lOS.notifications > 0 then
			term.blit("\151\131\148",bg..bg..fg,fg..fg..bg)
			term.setCursorPos(timeObj.x+timeObj.w+1,h-(lOS.tbSize-2))
			term.blit("\130\135\129",fg..fg..fg,bg..bg..bg)]]
		if #lOS.notifications == 0 then
			fg = lUtils.toBlit(colors.lightGray)
			--[[term.blit("\151\140\148",bg..fg..fg,fg..bg..bg)
			term.setCursorPos(timeObj.x+timeObj.w+1,h-(lOS.tbSize-2))
			term.blit("\130\134\129",fg..fg..fg,bg..bg..bg)]]
		end
		if lOS.tbSize > 1 then
			term.blit("\151\131\148",bg..bg..fg,fg..fg..bg)
			term.setCursorPos(timeObj.x+timeObj.w+1,h-(lOS.tbSize-2))
			term.blit("\130\135\129",fg..fg..fg,bg..bg..bg)
		else
			term.write("msg")
		end
		-- draw uh mminimize button on task bar
		term.setBackgroundColor(colors.gray)
		term.setTextColor(colors.lightGray)
		for y=h-(lOS.tbSize-1),h do
			term.setCursorPos(w,y)
			term.write("\149")
		end
	end
	local function genTabMenu()
		local tabMenu = {}
		local w,h = lOS.wAll.getSize()
		local maxW,maxH = w-(math.floor(w/8))-math.floor(math.floor(w/8)),h-(math.floor(h/8))-math.floor(math.floor(h/8))
		local minX,minY = math.floor(w/8),math.floor(h/8)
		while minY+(maxH-1) >= h-lOS.tbSize do
			maxH = maxH-1
		end
		local maxRows = 4
		local rowH = math.floor((maxH-1)/maxRows-2)
		local minRowH = 5
		if h <= 21 then
			minRowH = 4
		end
		while rowH < minRowH do
		    maxRows = maxRows-1
		    rowH = math.floor((maxH-1)/maxRows-2)
		end
		--#pHistory
		tabMenu[1] = {w=3}
		tabMenu.a = {}
		for i=1,#pHistory do
		    local p = pHistory[i]
		    if p.winMode ~= "background" then
		        local wW,wH = p.win.getSize()
		        local pH = rowH
		        local pW = round(wW/(wH/rowH))
		        local lilWin = lUtils.littlewin(p.win,pW,pH)
		        lilWin.proc = p
		        lilWin.w,lilWin.h = pW,pH
		        if tabMenu[#tabMenu].w+pW+1 <= maxW then
		            table.insert(tabMenu[#tabMenu],lilWin)
		            tabMenu[#tabMenu].w = tabMenu[#tabMenu].w+pW+1
		        else
		        	table.insert(tabMenu,{lilWin,w=2+pW})
		        end
		        lilWin.row = #tabMenu
		        table.insert(tabMenu.a,lilWin)
		    end
		end
		local rows = math.min(#tabMenu,maxRows)
		tabMenu.h = 1+rows*(rowH+2)
		tabMenu.w = 0
		local cenX,cenY = math.ceil(w/2),math.ceil(h/2)
		tabMenu.y = cenY-(math.floor(tabMenu.h/2))
		for i,row in ipairs(tabMenu) do
			tabMenu.w = math.max(row.w,tabMenu.w)
			local cX = cenX-math.floor(row.w/2)
			row.x = cX
			row.y = tabMenu.y+2+(i-1)*(rowH+2)
			cX = cX+2
			for p,win in ipairs(row) do
				win.x = cX
				win.y = row.y
				cX = cX+win.w+1
			end
		end
		tabMenu.x = cenX-(math.floor(tabMenu.w/2))
		function tabMenu.render(fromRow)
			local fromRow = fromRow or 1
			term.setBackgroundColor(colors.gray)
			lOS.boxClear(tabMenu.x,tabMenu.y,tabMenu.x+(tabMenu.w-1),tabMenu.y+(tabMenu.h-1))
			local rows = math.min(#tabMenu,maxRows)
			local toRow = math.min(fromRow+(maxRows-1),rows)
			local offset = (fromRow-1)*(rowH+2)
			local count = 1
			for r=1,fromRow-1 do
				count = count+#tabMenu[r]
			end
			local startedTimer
			for r=fromRow,toRow do
				local row = tabMenu[r]
				for p,win in ipairs(row) do
					if tabMenu.clickSel and tabMenu.clickSel == win then
						if not win.small then
							win.small = lUtils.littlewin(win.proc.win,win.w-2,win.h-2)
						end
						win.small.render(win.x+1,win.y+1-offset,true)
						term.setBackgroundColor(colors.gray)
						term.setTextColor(colors.white)
						lUtils.border(win.x,win.y,win.x+(win.w-1),win.y+(win.h-1),nil,1)
					else
						win.render(win.x,win.y-offset,true)
					end
					term.setBackgroundColor(colors.gray)
					local of = 0
					term.setCursorPos(win.x,win.y-1)
					if win.proc.icon then
						term.blit(win.proc.icon[1],(win.proc.icon[2] or lUtils.toBlit(term.getBackgroundColor())),(win.proc.icon[3] or lUtils.toBlit(term.getBackgroundColor())))
						term.write(" ")
						of = 2
					end
					term.setTextColor(colors.white)
					local t = win.proc.title
					if #t >= win.w-1-of then
						t = t:sub(1,win.w-3-of)..".."
					end
					term.write(t)
					term.setCursorPos(win.x+win.w-2,win.y-1)
					local c = "7"
					if win.closeSel then
						c = "e"
					end
					term.blit("\149×","70",c..c)
					if tabMenu.sel and tabMenu.sel == count then
						lUtils.border(win.x-1,win.y-2,win.x+win.w,win.y+win.h,nil,2)
					end
					count = count+1
					if win.nX then
						if win.x < win.nX then
							win.x = win.x+1
						elseif win.x > win.nX then
							win.x = win.x-1
						else
							win.nX = nil
						end
						if not startedTimer then
							startedTimer = os.startTimer(0.05)
						end
					end
				end
			end
		end
		return tabMenu
	end
		    
	--[[local function drawTabMenu()		
		term.setBackgroundColor(colors.gray)
		--lOS.boxClear(math.floor(w/8),math.floor(h/8),w-(math.floor(w/8)-1),h-(math.floor(h/8)-1))

	end]]

	lOS.tbSize = 2 -- check config if disabled, usually
	local function lMenu()
		function theOverlayFunction()
			if previewWin then
				for i,win in ipairs(previewWin) do
					local bg = colors.lightGray
					local tcol
					if previewWin.sel and previewWin.sel == win then
						tcol = colors.white
					else
						tcol = colors.gray
					end
					if tbApps[icoSel][i] == lOS.focusWin then
						bg = colors.gray
						if previewWin.sel and previewWin.sel == win then
							tcol = colors.lightGray
						else
							tcol = colors.white
						end
					end
					win.render(win.x,win.y,true)
					term.setTextColor(bg)
					lUtils.border(win.x,win.y-1,win.x+(win.w-1),win.y+(win.h-1),"transparent")
					term.setTextColor(tcol)
					term.setBackgroundColor(bg)
					term.setCursorPos(win.x,win.y-1)
					local txt = tbApps[icoSel][i].title:sub(1,win.w-2)
					term.write(" "..txt..string.rep(" ",win.w-1-#txt))
					local w,h = lOS.wAll.getSize()
					if win.y+(win.h-1) > h-(lOS.tbSize) then
						win.y = win.y-1
						os.startTimer(0.05)
					end
				end
			end
			if lOS.tbSize and lOS.tbSize > 0 then
				local ok, err = pcall(drawTaskbar)
				if not ok then
					term.setCursorPos(1,1)
					term.setBackgroundColor(colors.white)
					term.setTextColor(colors.red)
					term.write(err)
				end
			end

			-- DEBUG
			--[[term.setBackgroundColor(colors.white)
			term.setTextColor(colors.red)
			term.setCursorPos(1,1)
			print(textutils.serialize(events))]]
		end
		LevelOS.overlay = theOverlayFunction
		while true do
		    local w,h = lOS.wAll.getSize()
		    doLog = false
		    local hurry = false
		    if #events > 0 then
		    	e = events[1]
		    	--[[doLog = true
		    	os.sleep(2)]]
		    	table.remove(events,1)
		    	hurry = true
		    else
		    	e = {os.pullEventRaw()}
		    end

		    --[[ MANAGE NOTIFICATIONS ]]

		    if #lOS.notifications > 0 then
	            --[[timer = timer+0.1
	            if timer >= 2 then
	                table.remove(lOS.notifications,1)
	                timer = 0
	            end]]
	        end

		    --[[ END OF MANAGE NOTIFICATIONS ]]

		    if #lOS.wins >= 1 then
			    local topwin = lOS.focusWin
			    if topwin ~= pHistory[1] and topwin ~= lOS.wins[0] then
			    	for t=1,#pHistory do
			    		if pHistory[t] == topwin then
			    			table.remove(pHistory,t)
			    			break
			    		end
			    	end
			    	table.insert(pHistory,1,topwin)
			    end
			end
			for t=#pHistory,1,-1 do
				if coroutine.status(pHistory[t][1]) == "dead" or pHistory[t].winMode == "background" then
					table.remove(pHistory,t)
				end
			end

		    if e[1] == "window_open" then
		    	if tostring(lOS.processes[e[2]]) ~= e[3] then
		    		for t=1,#lOS.processes do
		    			if tostring(lOS.processes[t]) == e[3] then
		    				e[2] = t
		    				break
		    			end
		    		end
		    	end
		    elseif e[1]:find("window_") then
		    	local wins = lOS.wins
		    	if e[1] == "window_focus" then
		    		wins = lOS.processes
		    	end
		    	if tostring(wins[e[2]]) ~= e[3] then
		    		for t=1,#wins do
		    			if tostring(wins[t]) == e[3] then
		    				e[2] = t
		    				break
		    			end
		    		end
		    	end
		    end

		    doLog = true
		    if e[1]:find("mouse") and type(e[3]) == "number" and e[4] >= h-(lOS.tbSize-1) then
		    	local foundwidget = false
		    	if e[1] ~= "mouse_scroll" and e[1] ~= "mouse_move" then
		    		for t=#lOS.wins,1,-1 do
						if lOS.wins[t].winMode == "widget" then
							if not lOS.sysUIlog then
								lOS.sysUIlog = {}
							end
							table.insert(lOS.sysUIlog,"Closed win "..t.." due to event "..table.concat(e,",")..".")
							os.queueEvent("window_close",t,tostring(lOS.wins[t]),"some mouse shit")
							foundwidget = true
						end
					end
				end
				if foundwidget then
					-- nothing
			    elseif e[3] <= 2 then
			    	if e[1] == "mouse_click" then
			    		icoSel = 0
			    	elseif e[1] == "mouse_up" then
			        	local oterm = term.current()
						local win = window.create(term.current(),1,1,w,h,false)
						local cor = coroutine.create(startMenu)
						lOS.noEvents = true
						os.sleep(0)
						for y=1,h do
							win.setCursorPos(1,y)
							win.blit(lOS.wAll.getLine(y))
						end
						local oldOverlay = LevelOS.overlay
						function LevelOS.overlay()
							for y=1,h do
								term.setCursorPos(1,y)
								term.blit(win.getLine(y))
								term.setCursorPos(1,1)
								term.setBackgroundColor(colors.white)
								term.setTextColor(colors.red)
							end
							oldOverlay()
						end
						term.redirect(win)
						coroutine.resume(cor)
						while true do
							local e = {os.pullEventRaw()}
							term.redirect(win)
							coroutine.resume(cor,unpack(e))
							term.redirect(oterm)
							if lOS.noEvents == false then
								break
							end
						end
						term.redirect(oterm)
						LevelOS.overlay = oldOverlay
					end
				-- elseif widget area
				elseif e[3] >= timeObj.x and e[4] <= h and e[4] >= h-1 then
					if e[3] <= timeObj.x+(timeObj.w-1) then
						if e[1] == "mouse_click" then
							icoSel = -1
						elseif e[1] == "mouse_up" then
							lOS.execute("LevelOS/Clock.lua")
						end
					elseif e[3] <= w-2 then
						if e[1] == "mouse_click" then
							icoSel = -2
						elseif e[1] == "mouse_up" then
							--lOS.execute("LevelOS/Clock.lua")
						end
					else
						for t=#lOS.wins,1,-1 do
							if lOS.wins[t].winMode == "widget" then
								if not lOS.sysUIlog then
									lOS.sysUIlog = {}
								end
								table.insert(lOS.sysUIlog,"Closed win "..t.." due to event "..table.concat(e,",")..".")
								os.queueEvent("window_close",t,tostring(lOS.wins[t]),"some timeobj thing idk")
							else
								os.queueEvent("window_minimize",t,tostring(lOS.wins[t]),true)
							end
						end
					end
				else
					for i,v in ipairs(tbApps) do
						if not tbPos[v] then
							_G.lOS.sysDebug.error = "tbPos["..tostring(v).." (tbApps["..i.."])] not found."
							_G.lOS.curApps = {}
							_G.lOS.curPos = {}
							for a,b in ipairs(tbApps) do
								_G.lOS.curApps[a] = {b,tostring(b)}
							end
							for c,d in pairs(tbPos) do
								_G.lOS.curPos[c] = d
							end
							lOS.sysDebug.str = tostring(v).." vs "..tostring(tbApps[i])
							lOS.sysDebug.theProblem = {v,tbApps[i],tostring(v),tostring(tbApps[i])}
							_G.lOS.theError = lOS.sysDebug.error
							error(lOS.sysDebug.error,0)
						end
						if lUtils.isInside(e[3],e[4],tbPos[v]) then
							if e[1] == "mouse_click" or e[1] == "mouse_drag" or e[1] == "mouse_hover" or (previewWin and e[1] == "mouse_move" and type(e[3]) == "number") then
								icoSel = i
								if ((e[2] == 1 and #v > 1) or e[1] ~= "mouse_click") then
									local cX
									local pW = {}
									_G.debugPreviewWin = pW
									for p,app in ipairs(v) do
										local w,h = app.win.getSize()
										local nH = 7
										local nW = round(w/(h/nH))
										local x,y
										y = tbPos[v].y1-nH
										if not cX then
											x = (tbPos[v].x1+1)-(math.floor(nW/2))
											if x < 2 then
												x = 2
											elseif x+(nW-1) > ({lOS.wAll.getSize()})[1] then
												x = ({lOS.wAll.getSize()})[1]-(nW-1)
											end
										else
											x = cX
										end
										cX = x+nW
										pW[p] = lUtils.littlewin(app.win, nW, nH)
										local offset = 0
										if not previewWin then
											offset = 4
										end
										pW[p].x,pW[p].y = x,y+offset
										pW[p].w,pW[p].h = nW,nH
									end
									previewWin = pW
								end
							elseif e[1] == "mouse_up" and icoSel == i and e[2] == 2 then
								previewWin = nil
								local opt = {}
								local dis = {}
								local h = 1
								if v[1].path then
									local t
									if fs.getName(v[1].path) == "main.lua" then
										t = lUtils.getFileName(fs.getDir(v[1].path))
									else
										t = lUtils.getFileName(v[1].path)
									end
									t = t:sub(1,1):upper()..t:sub(2)
									table.insert(opt," \4 "..t)
									h = h+2

									-- (un)pin to/from taskbar
									table.insert(opt," \25 Pin to taskbar")
									dis[opt[#opt]] = true
									h = h+2
								end

								if #v == 1 then
									table.insert(opt," × Close")
								else
									table.insert(opt," × Close all")
								end
								h = h+2

								local tW,tH = lOS.wAll.getSize()
								local w,h = 21,7
								local x,y = tbPos[v].x1-9,tH-(lOS.tbSize)-(h-1)
								if x < 2 then
									x = 2
								elseif x+(w-1) > tW then
									x = tW
								end
								local function rWin()
									term.setBackgroundColor(colors.gray)
									term.setTextColor(colors.lightGray)
									lUtils.border(x,y,x+(w-1),y+(h-1),"fill")
									for t=1,#opt do
										if dis[opt[t]] then
											term.setTextColor(colors.lightGray)
										else
											term.setTextColor(colors.white)
										end
										term.setCursorPos(x+1,y+(t*2)-1)
										term.write(opt[t]..string.rep(" ",(w-2)-#opt[t]))
										if t < #opt then
											term.setCursorPos(x+1,y+(t*2))
											term.write(" ",w-2)
										end
									end
								end
								y = y+3
								local oOverlay = LevelOS.overlay
								function LevelOS.overlay()
									rWin()
									oOverlay()
								end
								for t=1,3 do
									os.sleep(0.05)
									y = y-1
								end
								os.sleep(0)
								function LevelOS.overlay()
									term.setBackgroundColor(colors.gray)
									term.setTextColor(colors.lightGray)
									lUtils.border(x,y,x+(w-1),y+(h-1))
								end
								local a
								runOverlay(function() a = {lUtils.oclickmenu(x,y,w,opt,nil,dis,{bg=colors.gray,fg=colors.gray,txt=colors.white})} end,false,true)
								if a[1] then
									if a[3] == opt[1] and v[1].path then
										lOS.execute(v[1].path)
									elseif (a[3] == opt[1] and not v[1].path) or (v[1].path and a[3] == opt[3]) then
										for t=#lOS.wins,1,-1 do
											if (lOS.wins[t] == v[1] and not v[1].path) or (v[1].path and v[1].path == lOS.wins[t].path) then
												if not lOS.sysUIlog then
													lOS.sysUIlog = {}
												end
												table.insert(lOS.sysUIlog,"Closed win "..t.." through taskbar menu.")
												os.queueEvent("window_close",t,tostring(lOS.wins[t]))
											end
										end
										for t=1,#v do
											if v[t].minimized then
												for p=1,#lOS.processes do
													if lOS.processes[p] == v[t] then
														table.remove(lOS.processes,p)
														break
													end
												end
												for p=1,#pHistory do
													if pHistory[p] == v[t] then
														table.remove(pHistory,p)
														break
													end
												end
											end
										end
									elseif v[1].path and a[3] == opt[2] then
										-- nothing
									end
								end
								LevelOS.overlay = oOverlay
							elseif e[1] == "mouse_up" and icoSel == i and e[2] == 1 then
								if #v == 1 then
									previewWin = nil
									local v = v[1]
									if v == lOS.focusWin then
										--[[local dur = 5
										local x,y = v.win.getPosition()
										local w,h = v.win.getSize()
										local gx,gy = tbPos[v].x1,tbPos[v].y1
										local gw,gh = 3,2
										for t=#lOS.wins,1,-1 do
											if lOS.wins[t] == lOS.focusWin then
												table.remove(lOS.wins,t)
												lOS.focusWin = lOS.wins[t-1]
												break
											end
										end
										animation(v,x,y,w,h,gx,gy,gw,gh,dur)
										v.minimized = true]]
										local id
										for k1,v1 in pairs(lOS.wins) do
											if v1 == v then
												id = k1
												break
											end
										end
										os.queueEvent("window_minimize",id,tostring(v))
									--[[elseif not potato then
										lOS.sysDebug.v = v]]
									else
										local id
										for k1,v1 in pairs(lOS.processes) do
											if v1 == v then
												id = k1
												break
											end
										end
										os.queueEvent("window_focus",id,tostring(v))
									end
								else
									-- choose from previews
									lOS.noEvents = true
									local pW = previewWin
									while true do
										local e = {os.pullEventRaw()}
										if e[1] == "mouse_up" or e[1] == "mouse_drag" or e[1] == "mouse_click" then
											local terminate = true
											for i,win in ipairs(pW) do
												local lWin = tbApps[icoSel][i]
												local focusWin
												for t=1,#lOS.wins do
													if lOS.wins[t] == lWin then
														focusWin = t
														break
													end
												end
												local fID
												for t=#lOS.wins,0,-1 do
													if lOS.wins[t] == lOS.focusWin then
														fID = t
													end
												end
												if e[3] >= win.x and e[4] >= win.y and e[3] <= win.x+(win.w-1) and e[4] <= win.y+(win.h-1) then
													terminate = false
													if e[2] == 2 and e[1] == "mouse_up" then
														local dis = {}
														if not (lWin.snap or lWin.minimized) then
															dis["=  Restore"] = true
														end
														if lWin.snap and lWin.snap.x and lWin.snap.y then
															dis["+  Maximize"] = true
														end
														if lWin.minimized then
															dis["-  Minimize"] = true
														end
														lOS.cWin = 0
														local a
														local oOverlay = LevelOS.overlay
														LevelOS.overlay = nil
														runOverlay(function() a = {lUtils.oclickmenu(e[3],e[4],19,{"=  Restore",{"-  Minimize","+  Maximize"},"×  Close   Ctrl+W"},nil,dis)} end,false,true)
														LevelOS.overlay = oOverlay
														if a[1] then
															if a[3] == "=  Restore" then
																if lWin.minimized then
																	local dur = 5
																	local x,y = tbPos[lWin].x1,tbPos[lWin].y1
																	local w,h = 3,2
																	local gx,gy = lWin.win.getPosition()
																	local gw,gh = lWin.win.getSize()
																	animation(lWin,x,y,w,h,gx,gy,gw,gh,dur)
																	lWin.minimized = nil
																	table.insert(lOS.wins,lWin)
																	lOS.focusWin = lWin
																elseif lWin.snap then
																	--os.queueEvent("timer",9999999)
																	os.queueEvent("window_reposition",focusWin,tostring(lWin),lWin.snap.oPos[1],lWin.snap.oPos[2],unpack(lWin.snap.oSize))
                                    								lWin.snap = nil
                                    							end
                                    						elseif a[3] == "-  Minimize" then
                                    							--os.queueEvent("timer",9999999)
                                    							os.queueEvent("window_minimize",focusWin,tostring(lWin))
                                    						elseif a[3] == "+  Maximize" then
                                    							os.queueEvent("timer",9999999)
                                    							local totalW,totalH = lOS.wAll.getSize()
                                    							lWin.snap = {x=true,y=true,oPos={lWin.win.getPosition()},oSize={lWin.win.getSize()}}
							                                    os.queueEvent("window_reposition",focusWin,tostring(lWin),1,2,totalW,totalH-1)
							                                elseif a[3] == "×  Close   Ctrl+W" then
								                                if lWin.env and lWin.env.LevelOS and type(lWin.env.LevelOS.close) == "function" then
								                                	if lWin.minimized then
																		local dur = 5
																		local x,y = tbPos[lWin].x1,tbPos[lWin].y1
																		local w,h = 3,2
																		local gx,gy = lWin.win.getPosition()
																		local gw,gh = lWin.win.getSize()
																		animation(lWin,x,y,w,h,gx,gy,gw,gh,dur)
																		lWin.minimized = nil
																		table.insert(lOS.wins,lWin)
																		lOS.focusWin = lWin
																	end
								                                    --lWin[1] = coroutine.create(lWin.env.LevelOS.close)
								                                    --lWin.env.LevelOS.close = nil
								                                    runLevelOSclose(lWin)
								                                else
								                                    if focusWin then
								                                    	--os.queueEvent("timer",9999999)
								                                    	--[[if not lOS.sysUIlog then
																			lOS.sysUIlog = {}
																		end
																		table.insert(lOS.sysUIlog,"Closed win "..focusWin.." through taskbar submenu.")]]
								                                    	os.queueEvent("window_close",focusWin,tostring(lWin))
								                                    else
								                                    	for t=1,#lOS.processes do
								                                    		if lOS.processes[t] == lWin then
								                                    			table.remove(lOS.processes,t)
								                                    			break
								                                    		end
								                                    	end
								                                    	for t=1,#pHistory do
																			if pHistory[t] == lWin then
																				table.remove(pHistory,t)
																				break
																			end
																		end
								                                    end
								                                end
                                    						end
														end
														previewWin = nil
														lOS.noEvents = false
														break
													elseif e[2] == 1 and e[1] == "mouse_up" then
														-- switch
														if not (focusWin and focusWin == fID) then
															local v = lWin
															if v.minimized then
																local dur = 5
																local x,y = tbPos[v].x1,tbPos[v].y1
																local w,h = 3,2
																local gx,gy = v.win.getPosition()
																local gw,gh = v.win.getSize()
																animation(v,x,y,w,h,gx,gy,gw,gh,dur)
																v.minimized = nil
															else
																for i=1,#lOS.wins do
																	if lOS.wins[i] == v then
																		table.remove(lOS.wins,i)
																		break
																	end
																end
															end
															table.insert(lOS.wins,v)
															lOS.focusWin = v
														end
														previewWin = nil
														lOS.noEvents = false
														break
													else
														pW.sel = win
													end
												end
											end
											if terminate or not previewWin then
												icoSel = nil
												previewWin = nil
												lOS.noEvents = false
												break
											end
										end
										if e[1] == "mouse_up" and previewWin then
											previewWin.sel = nil
										end
									end
								end
							end
							break
						end
					end
				end
			elseif e[1] == "window_open" then
				local v = lOS.processes[e[2]]
				if v and tostring(v) == e[3] then
					local dur = 2
					local gx,gy = v.win.getPosition()
					local gw,gh = v.win.getSize()
					local x,y = gx+4,gy+2
					local w,h = gw-8,gh-4
					local tW,tH = lOS.wAll.getSize()
					if (v.winMode == "widget" or v.winMode == "borderless") then
						dur = 4
						if gy > 2 and gy+(gh-1) == tH-lOS.tbSize then
							x,y = gx,tH-lOS.tbSize
							w,h = gw,gh
						elseif gx+(gw-1) == tW then
							x,y = tW,gy
							w,h = gw,gh
						end
					end
					animation(v,x,y,w,h,gx,gy,gw,gh,dur)
					table.insert(lOS.wins,v)
					if e[4] ~= false then
						lOS.focusWin = v
					end
				end
			elseif e[1] == "window_focus" and lOS.processes[e[2]] and tostring(lOS.processes[e[2]]) == e[3] then
				local v = lOS.processes[e[2]]
				if v.minimized then
					local dur = 5
					local x,y = tbPos[v].x1,tbPos[v].y1
					local w,h = 3,2
					local gx,gy = v.win.getPosition()
					local gw,gh = v.win.getSize()
					animation(v,x,y,w,h,gx,gy,gw,gh,dur)
					v.minimized = nil
				else
					for i=1,#lOS.wins do
						if lOS.wins[i] == v then
							table.remove(lOS.wins,i)
							break
						end
					end
				end
				table.insert(lOS.wins,v)
				lOS.focusWin = v
			elseif e[1] == "window_minimize" and lOS.wins[e[2]] and tostring(lOS.wins[e[2]]) == e[3] then
				local v = lOS.wins[e[2]]
				local dur = 5
				if hurry or #events > 0 or e[4] then
					dur = 3
				end
				local x,y = v.win.getPosition()
				local w,h = v.win.getSize()
				local gx,gy = tbPos[v].x1,tbPos[v].y1
				local gw,gh = 3,2
				table.remove(lOS.wins,e[2])
				if lOS.focusWin == v then
					lOS.focusWin = lOS.wins[e[2]-1]
				end
				animation(v,x,y,w,h,gx,gy,gw,gh,dur)
				v.minimized = true
			elseif e[1] == "window_reposition" and lOS.wins[e[2]] and tostring(lOS.wins[e[2]]) == e[3] then
				local win = lOS.wins[e[2]]
				local x,y = win.win.getPosition()
				local w,h = win.win.getSize()
				local _,focusWin,pointer,gx,gy,gw,gh = unpack(e)
				local dur = 2
				table.remove(lOS.wins,e[2])
				animation(win,x,y,w,h,gx,gy,gw,gh,dur)
				table.insert(lOS.wins,win)
				win.win.reposition(gx,gy,gw,gh)
				os.queueEvent("term_resize")
			elseif (e[1] == "window_close" and tostring(lOS.wins[e[2]]) == e[3]) or (e[1] == "process_close" and tostring(lOS.processes[e[2]]) == e[3]) --[[or (e[1] == "key_up" and lUtils.isHolding(keys.leftCtrl) and e[2] == keys.w and #lOS.wins > 0 and lOS.focusWin and lOS.focusWin ~= lOS.wins[0] and not lOS.focusWin.noShortcuts)]] then
				local focusWin
				if e[1] == "window_close" then
					focusWin = e[2]
				elseif e[1] == "process_close" then
					for i,lwin in pairs(lOS.wins) do
						if lOS.wins[i] == lOS.processes[e[2]] then
							focusWin = i
							e[1] = "window_close"
							e[2] = focusWin
							break
						end
					end
				else
					for t=#lOS.wins,1,-1 do
						if lOS.wins[t] == lOS.focusWin then
							focusWin = t
							break
						end
					end
				end
				local win
				if focusWin then
					win = lOS.wins[focusWin]
				elseif e[1] == "process_close" then
					win = lOS.processes[e[2]]
				end
                if win.env and win.env.LevelOS and type(win.env.LevelOS.close) == "function" then
                    --[[win[1] = coroutine.create(win.env.LevelOS.close)
                    win.env.LevelOS.close = nil]]
                    runLevelOSclose(win)
                elseif e[1] == "process_close" then
                	table.remove(lOS.processes,e[2])
                elseif e[1] == "window_close" then
                    win.closing = true
					local x,y = win.win.getPosition()
					local w,h = win.win.getSize()
					local gx,gy = x+4,y+2
					local gw,gh = w-8,h-4
					local tW,tH = lOS.wAll.getSize()
					local dur = 2
					if (win.winMode == "widget" or win.winMode == "borderless") then
						dur = 4
						if y > 2 and y+(h-1) == tH-lOS.tbSize then
							gx,gy = x,tH-lOS.tbSize
							gw,gh = w,h
						elseif x+(w-1) == tW then
							gx,gy = tW,y
							gw,gh = w,h
						end
					end
					if lOS.wins[focusWin].winMode ~= "background" then
						local proc = lOS.processes
						for i=1,#proc do
		                    if lOS.wins[focusWin] == proc[i] then
	                        	table.remove(proc,i)
	                    	end
	                	end
	                end
	                table.remove(lOS.wins,focusWin)
	                if lOS.focusWin == win then
	                	lOS.focusWin = lOS.wins[focusWin-1] -- good
	                end
					animation(win,x,y,w,h,gx,gy,gw,gh,dur)
					for t=1,#pHistory do
						if pHistory[t] == win then
							table.remove(pHistory,t)
							break
						end
					end
				end
			elseif e[1] == "key" then
				if e[2] == keys.f5 and #lOS.wins > 0 then
					if lOS.focusWin.winMode == "fullscreen" and lOS.focusWin.fullscreen then
						local proc = lOS.focusWin
						proc.winMode = "windowed"
						proc.win.reposition(proc.fullscreen.pos[1],proc.fullscreen.pos[2],proc.fullscreen.size[1],proc.fullscreen.size[2],lOS.wAll)
						proc.win.setVisible(false)
						proc.fullscreen = nil
					else
						local proc = lOS.focusWin
						proc.winMode = "fullscreen"
					end
				elseif e[2] == keys.tab and lUtils.isHolding(keys.leftCtrl) and #pHistory > 0 then
					if lOS.focusWin.winMode == "fullscreen" then
						local win = lOS.focusWin
						for t=#lOS.wins,1,-1 do
							if lOS.wins[t] == lOS.focusWin then
								table.remove(lOS.wins,t)
								break
							end
						end
						win.minimized = true
					end
					local oOverlay = LevelOS.overlay
					local tabMenu = genTabMenu()
					lOS.sysDebug.tabMenu = tabMenu
					tabMenu.sel = math.min(#pHistory,2)
					function LevelOS.overlay()
						oOverlay()
						tabMenu.render()
					end
					lOS.noEvents = true
					while true do
						if tabMenu.sel and not tabMenu.a[tabMenu.sel] then
							if #tabMenu.a < 1 then
								LevelOS.overlay = oOverlay
								break
							else
								while tabMenu.sel > #tabMenu.a do
									tabMenu.sel = tabMenu.sel-1
								end
							end
						end
						local e = {os.pullEventRaw()}
						lOS.noEvents = true
						if (e[1] == "key_up" and e[2] == keys.leftCtrl) or e[1] == "tabMenu_close" then
							LevelOS.overlay = oOverlay
							if tabMenu.sel then
								local proc = tabMenu.a[tabMenu.sel].proc
								if proc.minimized then
									for t=1,#lOS.processes do
										if lOS.processes[t] == proc then
											local dur = 5
											local x,y = tbPos[proc].x1,tbPos[proc].y1
											local w,h = 3,2
											local gx,gy = proc.win.getPosition()
											local gw,gh = proc.win.getSize()
											animation(proc,x,y,w,h,gx,gy,gw,gh,dur)
											proc.minimized = nil
											table.insert(lOS.wins,proc)
											lOS.focusWin = proc
											break
										end
									end
								else
									for t=1,#lOS.wins do
										if lOS.wins[t] == proc then
											table.remove(lOS.wins,t)
											break
										end
									end
									table.insert(lOS.wins,proc)
									lOS.focusWin = proc
								end
							end
							break
						elseif e[1] == "key" and e[2] == keys.tab or e[2] == keys.right then
							tabMenu.sel = tabMenu.sel+1
							if tabMenu.sel > #tabMenu.a then
								tabMenu.sel = 1
							end
						elseif e[1] == "key" and e[2] == keys.left then
							tabMenu.sel = tabMenu.sel-1
							if tabMenu.sel < 1 then
								tabMenu.sel = #tabMenu.a
							end
						elseif e[1]:find("mouse") and e[2] == 1 and type(e[3]) == "number" then
							if e[3] >= tabMenu.x and e[4] >= tabMenu.y and e[3] <= tabMenu.x+(tabMenu.w-1) and e[4] <= tabMenu.y+(tabMenu.h-1) then
								tabMenu.closing = nil
								for i,win in ipairs(tabMenu.a) do
									if e[3] >= win.x and e[4] >= win.y and e[3] <= win.x+(win.w-1) and e[4] <= win.y+(win.h-1) then
										if e[1] == "mouse_click" or e[1] == "mouse_drag" then
											tabMenu.clickSel = win
										elseif e[1] == "mouse_up" then
											tabMenu.sel = i
											os.queueEvent("tabMenu_close")
										end
									elseif e[3] == win.x+(win.w-1) and e[4] == win.y-1 then
										if e[1] == "mouse_click" then
											win.closeSel = true
										elseif e[1] == "mouse_up" and win.closeSel then
											local lWin = win.proc
											local focusWin
											for t=1,#lOS.wins do
												if lOS.wins[t] == lWin then
													focusWin = t
												end
											end
											if lWin.env and lWin.env.LevelOS and type(lWin.env.LevelOS.close) == "function" then
			                                	if lWin.minimized then
													local dur = 5
													local x,y = tbPos[lWin].x1,tbPos[lWin].y1
													local w,h = 3,2
													local gx,gy = lWin.win.getPosition()
													local gw,gh = lWin.win.getSize()
													animation(lWin,x,y,w,h,gx,gy,gw,gh,dur)
													lWin.minimized = nil
													table.insert(lOS.wins,lWin)
													lOS.focusWin = lWin
												end
			                                    --[[lWin[1] = coroutine.create(lWin.env.LevelOS.close)
			                                    lWin.env.LevelOS.close = nil]]
			                                    runLevelOSclose(lWin)
			                                else
			                                    if focusWin then
			                                    	--os.queueEvent("timer",9999999)
			                                    	--os.queueEvent("window_close",focusWin,tostring(lWin))
													local win = lWin
													local x,y = win.win.getPosition()
													local w,h = win.win.getSize()
													local gx,gy = x+4,y+2
													local gw,gh = w-8,h-4
													local tW,tH = lOS.wAll.getSize()
													local dur = 2
													if (win.winMode == "widget" or win.winMode == "borderless") and y > 2 and y+(h-1) == tH-lOS.tbSize then
														dur = 4
														gx,gy = x,tH-lOS.tbSize
														gw,gh = w,h
													end
													if lOS.wins[focusWin].winMode ~= "background" then
														local proc = lOS.processes
														for i=1,#proc do
										                    if lOS.wins[focusWin] == proc[i] then
									                        	table.remove(proc,i)
									                    	end
									                	end
									                end
									                table.remove(lOS.wins,focusWin)
													animation(win,x,y,w,h,gx,gy,gw,gh,dur)
													for t=1,#pHistory do
														if pHistory[t] == win then
															table.remove(pHistory,t)
															break
														end
													end
			                                    else
			                                    	for t=1,#lOS.processes do
			                                    		if lOS.processes[t] == lWin then
			                                    			table.remove(lOS.processes,t)
			                                    			break
			                                    		end
			                                    	end
			                                    	for t=1,#pHistory do
														if pHistory[t] == lWin then
															table.remove(pHistory,t)
															break
														end
													end
			                                    end
			                                end
			                                --[[LevelOS.overlay = oOverlay
			                                break]]
			                                table.remove(tabMenu.a,i)
			                                local row = tabMenu[win.row]
			                                for t=1,#row do
			                                	if win == row[t] then
			                                		table.remove(row,t)
			                                		break
			                                	end
			                                end
											if #row > 0 then
				                                row.w = 3
				                                for i,win in ipairs(row) do
				                                	row.w = row.w+win.w+1
				                                end
				                                local w,h = lOS.wAll.getSize()
				                                local cenX,cenY = math.ceil(w/2),math.ceil(h/2)
												local cX = cenX-math.floor(row.w/2)
												--row.x = cX
												cX = cX+2
												for p,win in ipairs(row) do
													win.nX = cX
													cX = cX+win.w+1
												end
											else
												local sel = tabMenu.sel
												tabMenu = genTabMenu()
												tabMenu.sel = sel
											end
			                                break
			                            end
			                        else
			                        	win.closeSel = nil
			                        end
			                    end
			                else
			                	if e[1] == "mouse_click" then
			                		tabMenu.closing = true
			                	elseif e[1] == "mouse_up" and tabMenu.closing then
			                		LevelOS.overlay = oOverlay
			                		break
			                	end
			                end
		                    if e[1] == "mouse_up" then
		                    	tabMenu.clickSel = nil
		                    end
						end
					end
					lOS.noEvents = false
				end
	    	end
		    if e[1] == "mouse_up" then
		    	previewWin = nil
		    	icoSel = nil
		    end
		end
	end
	local function internet()
		while true do
			lOS.checkinternet()
			os.sleep(30)
		end
	end
	local function fade()
		local native = {}
		local col = colors.black
		if lOS.isCyan then
			col = colors.cyan
		end
		for c=0,15,1 do
			native[2^c] = {--[[lOS.wins[0].win.getPaletteColor(2^c)]]term.nativePaletteColor(col)}
		end
		for p,process in pairs(lOS.processes) do
			for c=0,15,1 do
				process.win.setPaletteColor(2^c,unpack(native[2^c]))
				if process.owin then
					process.owin.setPaletteColor(2^c,unpack(native[2^c]))
				end
			end
		end
		local prog = 1
		local dur = 5
	    local function col(c,d)
	        local n = native[c]
	        local cur = {lOS.wins[0].win.getPaletteColor(c)}
	        local rgb = {}
	        for t=1,3 do
	            local st = (d[t]-n[t])/dur
	            --rgb[t] = cur[t]+st
	            rgb[t] = n[t]+st*prog
	        end
	        return rgb[1],rgb[2],rgb[3]
	    end
	    for t=1,dur do
	    	prog = t
	    	for p,process in pairs(lOS.processes) do
		        for c=0,15,1 do
		            if t < dur then
		                process.win.setPaletteColor(2^c,col(2^c,{term.nativePaletteColor(2^c)}))
		                if process.owin then
		                	process.owin.setPaletteColor(2^c,col(2^c,{term.nativePaletteColor(2^c)}))
		                end
		            else
		                process.win.setPaletteColor(2^c,term.nativePaletteColor(2^c))
		                if process.owin then
		                	process.owin.setPaletteColor(2^c,term.nativePaletteColor(2^c))
		                end
		            end
		        end
		    end
	        os.sleep(0.05)
	    end
	end
	parallel.waitForAny(logEvents,lMenu,function() if lOS.isCyan then fade() end lOS.fadeComplete = true while true do pcall(internet) end end)
end
local ok,err = pcall(UI)
if not ok then
	lOS.systemUIerror = err
	lOS.bsod(err)
else
	lOS.systemUIerror = "Unknown error: "..tostring(err)
end
lOS.noEvents = false