local tArgs = {...}
if not tArgs then return end
local sID = #lOS.notifWins+1
lOS.notifWins[sID] = LevelOS.self.window
local function count(tbl)
	local c = 0
	for k,v in pairs(tbl) do
		c = c+1
	end
	return c
end
local nAmount = count(lOS.notifWins)
term.setBackgroundColor(colors.gray)
term.clear()
local x,y = 2,2
local icon
if type(tArgs[3]) == "string" and fs.exists(tArgs[3]) and lOS.getIcon then
	icon = lOS.getIcon(tArgs[3])
end
if icon then
	lUtils.renderImg(icon,x,y)
	x = x+4
end
if type(tArgs[1]) == "string" then
	term.setCursorPos(x,y)
	term.setTextColor(colors.white)
	local w,h = term.getSize()
	local nw = w-x
	local txt = lUtils.wordwrap(tArgs[1],nw-1)
	if y+#txt > h then
		local dif = y+#txt-h
		local wX,wY = LevelOS.self.window.win.getPosition()
		wY = wY-dif
		h = h+dif
		LevelOS.self.window.win.reposition(wX,wY,w,h)
	end
	for t=1,#txt do
		term.setCursorPos(x,y)
		term.write(txt[t])
		y = y+1
	end
end
if type(tArgs[2]) == "string" then
	term.setCursorPos(x,y)
	term.setTextColor(colors.lightGray)
	local w,h = term.getSize()
	local nw = w-x
	local txt = lUtils.wordwrap(tArgs[2],nw)
	if y+#txt > h then
		local dif = y+#txt-h
		local wX,wY = LevelOS.self.window.win.getPosition()
		wY = wY-dif
		h = h+dif
		LevelOS.self.window.win.reposition(wX,wY,w,h)
	end
	for t=1,#txt do
		term.setCursorPos(x,y)
		term.write(txt[t])
		y = y+1
	end
end
local w,h = term.getSize()
term.setCursorPos(w-1,2)
term.setTextColor(colors.lightGray)
term.write("×")
local timer = 3
if type(tArgs[4]) == "string" and tonumber(tArgs[4]) then
	timer = tonumber(tArgs[4])
end
local tID = os.startTimer(timer)
local tID2
local sel = false
while true do
	local e = {os.pullEvent()}
	if e[1] == "timer" and e[2] == tID then
		break
	elseif e[1]:find("mouse") and e[3] and e[4] then
		if e[3] == w-1 and e[4] == 2 then
			if e[1] == "mouse_hover" then
				term.setCursorPos(w-1,2)
				term.setTextColor(colors.white)
				term.write("×")
				sel = true
			elseif e[1] == "mouse_click" then
				term.setCursorPos(w-1,2)
				term.setTextColor(colors.red)
				term.write("×")
				sel = true
			elseif e[1] == "mouse_up" and sel then
				break
			end
		end
		if e[1] == "mouse_up" and sel then
			term.setCursorPos(w-1,2)
			term.setTextColor(colors.lightGray)
			term.write("×")
			sel = false
		end
	end
	--if count(lOS.notifWins) ~= nAmount then
		nAmount = count(lOS.notifWins)
		local tW,tH = lOS.wAll.getSize()
		local w,h = term.getSize()
		local newY = tH-h-lOS.tbSize
		local x,y = LevelOS.self.window.win.getPosition()
		for k,v in pairs(lOS.notifWins) do
			--if v ~= LevelOS.self.window then
				local tx,ty = v.win.getPosition()
				if ty-h-1 <= newY and ty > y then -- use actual height
					newY = ty-h-1
				end
			--end
		end
		if newY > y then
			if not tID2 then
				tID2 = os.startTimer(0.3)
			elseif tID2 and e[1] == "timer" and e[2] == tID2 then
				LevelOS.self.window.win.reposition(x,newY)
				tID2 = nil
			end
		end
	--end
end
lOS.notifWins[sID] = nil