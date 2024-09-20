if LevelOS and LevelOS.self and LevelOS.self.window then
	LevelOS.self.window.winMode = "widget"
end
local oldlog = lUtils.asset.load("LevelOS/data/nativelog.lconf") or {}
local newlog = lUtils.asset.load("LevelOS/data/changelog.lconf")
if newlog then
	fs.delete("LevelOS/data/nativelog.lconf")
	fs.move("LevelOS/data/changelog.lconf","LevelOS/data/nativelog.lconf")
elseif oldlog then
	newlog = oldlog
end
local run = false
for c=1,#newlog do
	if not oldlog[c] then
		newlog[c].new = true
		run = true
	end
end
local txt = term.setTextColor
local bg = term.setBackgroundColor
local function clr()
	local w,h = term.getSize()
	local x,y = term.getCursorPos()
	term.setCursorPos(19,y)
	term.write(string.rep(" ",w-21))
	term.setCursorPos(x,y)
end
local function wr(text,color,mX,mY) --max x and y
	if color then
		txt(color)
	end
	local x,y = term.getCursorPos()
	local cX = x
	local cY = y
	for word in text:gmatch("%S+") do
		--[[if cX ~= x then
			word = " "..word
		end]]
		if cX+#word <= mX then
			term.write(word.." ")
			cX = cX+#word+1
		elseif cY < mY then
			cX = x
			cY = cY+1
			term.setCursorPos(cX,cY)
			clr()
			term.write(word.." ")
			cX = cX+#word+1
		else
			return (cY-y)+1
		end
	end
	return (cY-y)+1
end
local function rm() -- reached max
	local x,y = term.getCursorPos()
	local w,h = term.getSize()
	if y >= h then
		return true
	else
		return false
	end
end
function render(s)
	local function cp(x,y)
		term.setCursorPos(x,y+s)
	end
	bg(colors.cyan)
	term.clear()
	txt(colors.cyan)
	bg(colors.white)
	local w,h = term.getSize()
	for t=0,h-s do
		cp(14,4+t)
		term.write("\149")
	end
	-- write with window height as max Y and width-4 as max X
	local cY = 1
	for k=#newlog,1,-1 do
		local v = newlog[k]
		cY = cY+2
		
		-- the date
		cp(2,cY+1)
		bg(colors.cyan)
		txt(colors.white)
		term.write(v.date)
		cp(13,cY)
		
		-- cyan = 9, white = 0, lime=5
		-- the dot
		if k == #newlog then -- to check if its on top (for the line)
			term.blit("\159\143\143","999","000")
		else
			term.blit("\159\133\143","999","000")
		end
		cp(13,cY+1)
		if v.major then -- if major version make orange dot
			term.blit("\149 \149","911","010")
		else
			term.blit("\149 \149","955","050")
		end
		cp(13,cY+2)
		term.blit("\130\148\131","090","909")
		
		-- the actual box
		bg(colors.white)
		txt(colors.cyan)
		cp(19,cY)
		clr()
		--term.write("\151\129")
		term.write("\129")
		cp(w-3,cY)
		term.write("\130")
		--term.blit("\148","0","9")
		--[[cY = cY+1
		cp(19,cY)
		clr()]]
		cY = cY+1
		cp(18,cY)
		clr()
		term.write("\145 ")
		term.write("v"..v.version)
		if v.new then
			txt(colors.orange)
			term.write(" New!")
		end
		cY = cY+1
		cp(19,cY)
		clr()
		cY = cY+1
		cp(20,cY)
		clr()
		if v.description then
			cY = cY-1
			cp(21,cY)
			bg(colors.white)
			txt(colors.black)
			cY = cY+wr(v.description,nil,w-4,h)
			cp(20,cY)
			clr()
			cY = cY+1
			cp(20,cY)
			clr()
		end
		if v.added and #v.added > 0 then
			bg(colors.lime)
			txt(colors.white)
			term.write(" NEW ")
			cY = cY+1
			bg(colors.white)
			cp(19,cY)
			clr()
			cY = cY+1
			txt(colors.black)
			for t=1,#v.added do
				cp(21,cY)
				clr()
				term.write("\7 ")
				cY = cY+wr(v.added[t],nil,w-4,h)
			end
			cp(20,cY)
			clr()
		end
		if v.fixed and #v.fixed > 0 then
			if v.added and #v.added > 0 then
				cY = cY+1
				cp(20,cY)
				clr()
			end
			bg(colors.lightBlue)
			txt(colors.white)
			term.write(" FIXED ")
			cY = cY+1
			bg(colors.white)
			cp(19,cY)
			clr()
			cY = cY+1
			txt(colors.black)
			for t=1,#v.fixed do
				cp(21,cY)
				clr()
				term.write("\7 ")
				cY = cY+wr(v.fixed[t],nil,w-4,h)
			end
		end
		bg(colors.white)
		txt(colors.cyan)
		cp(19,cY)
		clr()
		cY = cY+1
		cp(19,cY)
		clr()
		term.write("\144")
		cp(w-3,cY)
		term.blit("\159","0","9")
		if rm() then break end
	end
	term.setCursorPos(1,1)
	bg(colors.cyan)
	txt(colors.white)
	term.clearLine()
	term.setCursorPos(2,1)
	term.write("Changelog")
	term.setCursorPos(w-2,1)
	term.write("×")
end
render(0)
local scroll = 0
while true do
	local e = {os.pullEvent()}
	local w,h = term.getSize()
	if e[1] == "term_resize" then
		render(scroll)
	elseif e[1] == "mouse_scroll" and scroll-e[2] <= 0 then
		scroll = scroll-e[2]
		render(scroll)
	elseif e[1] == "mouse_up" and e[3] == w-2 and e[4] == 1 then
		return
	end
end