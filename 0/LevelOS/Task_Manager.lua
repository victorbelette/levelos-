local scroll = 0
local procs = lOS.processes
local sel = {}
local pSel = {}
local expanded = {}
local cEnd = false
local scrollable = false
local display = 1
local function percentage(part,full)
	if display == 1 then
		local f = math.min(math.ceil((part/full)*1000)/10,100)
		return f.."%"
	else
		return math.floor(part+0.5).." ms"
	end
end
function _G.invWrite(txt)
	local fg = lUtils.toBlit(term.getTextColor()):rep(#txt)
	local bg = lUtils.toBlit(term.getBackgroundColor()):rep(#txt)
	term.blit(txt,bg,fg)
end

local function drawProcs(x1,y1,x2,y2,e)
	if e[1] == "mouse_scroll" then
		if scroll+e[2] >= 0 and (e[2] <= -1 or scrollable) then
			scroll = scroll+e[2]
		end
	end
	term.setBackgroundColor(colors.yellow)
	term.setTextColor(colors.lightGray)
	--lOS.boxClear(x2-9,y1,x2,y2-2)
	for y=y1,y2-2 do
		term.setBackgroundColor(colors.white)
		term.setCursorPos(x2-10,y)
		invWrite("\149")
		term.setBackgroundColor(colors.yellow)
		term.write(string.rep(" ",10))
		term.setBackgroundColor(colors.white)
		term.write("\149")
	end
	scrollable = false
	cY = y1-scroll
	local pr = {}
	local bg = {}

	y2 = y2-2

	for p=1,#procs do
		if procs[p].path then
			if procs[p].win and procs[p].winMode ~= "background" then
				if not pr[procs[p].path] then
					if expanded[procs[p].path] == nil then
						expanded[procs[p].path] = false
					end
					pr[#pr+1] = {expanded=expanded[procs[p].path],path=procs[p].path,pr={procs[p]},yieldTime=procs[p].yieldTime}
					pr[procs[p].path] = pr[#pr]
				else
					for t=1,#pr do
						if pr[t].path == procs[p].path then
							pr[t].pr[#pr[t].pr+1] = procs[p]
							if procs[p].yieldTime then
								pr[t].yieldTime = pr[t].yieldTime+procs[p].yieldTime
							end
						end
					end
				end
			else
				bg[#bg+1] = procs[p]
			end
		end
	end
	local clickmenu = {}
	-- TEMP

	if type(pSel) == "table" then
		sel = pSel
	elseif type(pSel) == "number" then
		sel = pr[pSel]
	else
		sel = {}
	end
	--if pr[2] then
		--pr[2].expanded = true
	--end
	if cY+1 >= y1 and cY+1 <= y2 then
		term.setTextColor(colors.blue)
		term.setBackgroundColor(colors.white)
		term.setCursorPos(x1,cY+1)
		term.write("Programs ("..#pr..")")
	end
	cY = cY+2
	local previousColor1
	local previousColor2
	for p=1,#pr+1 do
		local fg1
		local bg1
		local fg2
		local bg2
		
		local WARN = colors.yellow
		if p <= #pr and pr[p].yieldTime then
			local f = pr[p].yieldTime/lOS.yieldTime
			if f > 0.7 then
				WARN = colors.red
			elseif f > 0.4 then
				WARN = colors.orange
			end
		end
		fg1 = previousColor1 or colors.white
		fg2 = previousColor2 or colors.yellow
		if p > #pr or sel ~= pr[p] then
			bg1 = colors.white
			bg2 = WARN
		else
			bg1 = colors.lightBlue
			bg2 = colors.cyan
		end
		previousColor1 = bg1
		previousColor2 = bg2
		if cY >= y1 and cY <= y2 then
			term.setTextColor(fg1)
			term.setBackgroundColor(bg1)
			term.setCursorPos(x1,cY)
			term.write(string.rep("\131",x2-(x1-1)-11))
			
			term.setTextColor(colors.lightGray)
			term.setBackgroundColor(colors.white)
			invWrite("\149")
			term.setBackgroundColor(bg1)
			term.setTextColor(fg2)
			term.setBackgroundColor(bg2)
			term.write(string.rep("\131",10))
		end
		term.setTextColor(fg1)
		term.setBackgroundColor(bg1)
		if p > #pr then
			break
		end
		cY = cY+1
		if cY >= y1 and cY <= y2 then
			--term.setTextColor(colors.black)
			clickmenu[cY] = p
			term.setCursorPos(x1,cY)
			term.write(string.rep(" ",x2-(x1-1)-11))
			term.setTextColor(colors.lightGray)
			term.setBackgroundColor(colors.white)
			invWrite("\149")
			term.setBackgroundColor(bg2)
			term.write(string.rep(" ",10))
			term.setCursorPos(x1+1,cY)
			term.setBackgroundColor(bg1)
			if not pr[p].expanded then
				term.setTextColor(colors.lightGray)
				term.write("\16 ")
			else
				term.setTextColor(colors.gray)
				term.write("\31 ")
			end
			term.setTextColor(colors.black)
			local path = pr[p].path
			if fs.getName(path) == "main.lua" then
				path = fs.getDir(path)
			end
			local t = lUtils.getFileName(path)
			t = t:sub(1,1):upper()..t:sub(2)
			term.write(t.." ("..#pr[p].pr..")")
			local txt
			if pr[p].yieldTime then
				txt = percentage(pr[p].yieldTime,lOS.yieldTime)
			else
				txt = "???"
			end
			term.setCursorPos(x2-#txt,cY)
			term.setBackgroundColor(bg2)
			term.write(txt)
		end
		cY = cY+1
		if pr[p].expanded then
			for t=1,#pr[p].pr do
				if cY >= y1 and cY <= y2 then
					clickmenu[cY] = pr[p].pr[t]
					local bg3
					local bg4
					if sel == pr[p].pr[t] or sel == pr[p] then
						bg3 = colors.lightBlue
						bg4 = colors.cyan
					else
						bg3 = colors.white
						bg4 = WARN
					end
					term.setBackgroundColor(bg3)
					if not (sel == pr[p]) then
						term.setCursorPos(x1+3,cY)
						term.write(string.rep(" ",(x2)-(x1+2)-11))
					else
						term.setCursorPos(x1,cY)
						term.write(string.rep(" ",x2-(x1-1)-11))
					end
					term.setTextColor(colors.lightGray)
					term.setBackgroundColor(colors.white)
					invWrite("\149")
					term.setBackgroundColor(bg4)
					term.write(string.rep(" ",10))
					term.setBackgroundColor(bg3)
					term.setTextColor(colors.black)
					term.setCursorPos(x1+4,cY)
					term.write(pr[p].pr[t].title)
					local txt
					if pr[p].pr[t].yieldTime then
						txt = percentage(pr[p].pr[t].yieldTime,lOS.yieldTime)
					else
						txt = "???"
					end
					term.setCursorPos(x2-#txt,cY)
					term.setBackgroundColor(bg4)
					term.write(txt)
				end
				cY = cY+1
			end
		end
	end
	-- draw bg processes (no extended)
	if cY+1 >= y1 and cY+1 <= y2 then
		term.setTextColor(colors.blue)
		term.setBackgroundColor(colors.white)
		term.setCursorPos(x1,cY+1)
		term.write("Background Processes ("..#bg..")")
	end
	cY = cY+2
	local previousColor1
	local previousColor2
	for p=1,#bg+1 do
		local fg1
		local bg1
		local fg2
		local bg2
		
		local WARN = colors.yellow
		if p <= #bg and bg[p].yieldTime then
			local f = bg[p].yieldTime/lOS.yieldTime
			if f > 0.7 then
				WARN = colors.red
			elseif f > 0.4 then
				WARN = colors.orange
			end
		end
		fg1 = previousColor1 or colors.white
		fg2 = previousColor2 or colors.yellow
		if p > #bg or sel ~= bg[p] then
			bg1 = colors.white
			bg2 = WARN
		else
			bg1 = colors.lightBlue
			bg2 = colors.cyan
		end
		previousColor1 = bg1
		previousColor2 = bg2
		if cY >= y1 and cY <= y2 then
			term.setTextColor(fg1)
			term.setBackgroundColor(bg1)
			term.setCursorPos(x1,cY)
			term.write(string.rep("\131",x2-(x1-1)-11))
			
			term.setTextColor(colors.lightGray)
			term.setBackgroundColor(colors.white)
			invWrite("\149")
			term.setBackgroundColor(bg1)
			term.setTextColor(fg2)
			term.setBackgroundColor(bg2)
			term.write(string.rep("\131",10))
		end
		term.setTextColor(fg1)
		term.setBackgroundColor(bg1)
		if p > #bg then
			break
		end
		cY = cY+1
		if cY >= y1 and cY <= y2 then
			--term.setTextColor(colors.black)
			clickmenu[cY] = bg[p]
			term.setCursorPos(x1,cY)
			term.write(string.rep(" ",x2-(x1-1)-11))
			term.setTextColor(colors.lightGray)
			term.setBackgroundColor(colors.white)
			invWrite("\149")
			term.setBackgroundColor(bg2)
			term.write(string.rep(" ",10))
			term.setCursorPos(x1+1,cY)
			term.setBackgroundColor(bg1)
			if sel ~= bg[p] then
				term.setBackgroundColor(colors.white)
			else
				term.setBackgroundColor(colors.lightBlue)
			end
			term.write("  ")
			term.setTextColor(colors.black)
			local t = ""
			if bg[p].title then
				t = bg[p].title
			else
				t = bg[p].path
			end
			term.write(t)
			local txt
			if bg[p].yieldTime then
				txt = percentage(bg[p].yieldTime,lOS.yieldTime)
			else
				txt = "???"
			end
			term.setCursorPos(x2-#txt,cY)
			term.setBackgroundColor(bg2)
			term.write(txt)
		end
		cY = cY+1
	end
	if cY > y2 then
		scrollable = true
	end
	term.setCursorPos(1,y2+1)
	term.setBackgroundColor(colors.white)
	term.setTextColor(colors.gray)
	local w,h = term.getSize()
	term.write(string.rep("\131",w))
	--term.setCursorPos(x1,y2+2)
	local txt = "End Task"
	term.setCursorPos(x2-(string.len(txt)),y2+2)
	if sel.path then
		if not cEnd then
			term.setTextColor(colors.blue)
		else
			term.setTextColor(colors.lightBlue)
		end
	else
		term.setTextColor(colors.lightGray)
	end
	term.write(txt)

	if e[1] == "mouse_click" then
		if e[3] >= x1 and e[3] <= x2 and e[4] >= y1 and e[4] <= y2 then
			sel = {}
			pSel = {}
		end
		if sel.path and e[4] == y2+2 and e[3] >= x2-string.len(txt) and e[3] <= x2-1 then
			term.setCursorPos(x2-(string.len(txt)),y2+2)
			term.setTextColor(colors.lightBlue)
			term.write(txt)
			cEnd = true
		end
		if clickmenu[e[4]] then
			pSel = clickmenu[e[4]]
			if type(pSel) == "number" and e[3] == x1+1 then
				if expanded[pr[pSel].path] == false then
					expanded[pr[pSel].path] = true
				else
					expanded[pr[pSel].path] = false
				end
			end
		end
	elseif e[1] == "mouse_up" then
		cEnd = false
		if sel.path and e[4] == y2+2 and e[3] >= x2-string.len(txt) and e[3] <= x2-1 then
			local t = 1
			while true do
				if lOS.processes[t] == nil then break end
				if type(sel[1]) == "thread" then
					if lOS.processes[t] == sel then
						for i=1,#lOS.wins do
							if lOS.wins[i] == lOS.processes[t] then
								table.remove(lOS.wins,i)
							end
						end
						table.remove(lOS.processes,t)
						break
					else
						t = t+1
					end
				else
					if lOS.processes[t].path == sel.path then
						for i=1,#lOS.wins do
							if lOS.wins[i] == lOS.processes[t] then
								table.remove(lOS.wins,i)
							end
						end
						table.remove(lOS.processes,t)
					else
						t = t+1
					end
				end
			end
			sel = {}
			pSel = {}
		end
	end
end
-- sel wont work since pr gets regenerated every time
-- it will work for subprocesses tho
local w,h = term.getSize()
term.setBackgroundColor(colors.white)
term.clear()
while true do
	e = {os.pullEvent()}
	term.setBackgroundColor(colors.white)
	term.clear()
	local w,h = term.getSize()
	term.setCursorPos(2,3)
	term.setTextColor(colors.blue)
	term.write("Name")
	term.setCursorPos(w-6,3)
	term.write("Yield")
	term.setTextColor(colors.black)
	local txt
	if lOS.yieldTime then
		txt = math.ceil(lOS.yieldTime).." ms"
	else
		txt = "???"
	end
	term.setCursorPos((w-1)-#txt,2)
	term.write(txt)
	term.setCursorPos(1,4)
	term.setTextColor(colors.lightGray)
	term.setBackgroundColor(colors.white)
	term.write(string.rep("\131",w))
	for y=1,3 do
		term.setCursorPos(w-11,y)
		invWrite("\149")
		term.setCursorPos(w,y)
		term.write("\149")
	end
	term.setCursorPos(w-11,4)
	invWrite("\148")
	term.setBackgroundColor(colors.yellow)
	term.write(string.rep("\131",10))
	term.setBackgroundColor(colors.white)
	term.setCursorPos(w,4)
	term.write("\151")
	drawProcs(2,5,w-1,h,e)
	if e[1] == "key_up" and e[2] == keys.t and lUtils.isHolding(keys.leftShift) then
		term.setBackgroundColor(colors.black)
		term.clear()
		term.setCursorPos(1,1)
		term.setTextColor(colors.red)
		print("Terminated")
		return
	elseif e[1] == "mouse_click" and e[2] == 2 and lUtils.isInside(e[3],e[4],{x1=w-10,y1=1,x2=w-1,y2=4}) then
		if display == 1 then
			lOS.contextmenu(e[3],e[4],0,{{txt="Switch to ms",action=function() display = 2 end}})
		else
			lOS.contextmenu(e[3],e[4],0,{{txt="Switch to %",action=function() display = 1 end}})
		end
	end
end