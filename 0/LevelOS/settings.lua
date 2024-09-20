--ccvs = mwm.newCvs() -- config canvas aka settings canvas
btns = {}
function _G.btn(x,y,width,lines)
    btns[#btns+1] = {}
    thebtn = btns[#btns]
	thebtn.x = x
	thebtn.y = y
	thebtn.w = width
	thebtn.h = #lines+2
    function thebtn.render(px,py)
		if px == nil then
			px,py = thebtn.x,thebtn.y
		end
        thebtn.blit = {{"\151",tostring(lUtils.toBlit(colors.gray)),tostring(lUtils.toBlit(term.getBackgroundColor()))}}
        for t=1,thebtn.w-2 do
            thebtn.blit[1][1] = thebtn.blit[1][1].."\131"
            thebtn.blit[1][2] = thebtn.blit[1][2]..lUtils.toBlit(colors.gray)
            thebtn.blit[1][3] = thebtn.blit[1][3]..lUtils.toBlit(term.getBackgroundColor())
        end
        thebtn.blit[1][1] = thebtn.blit[1][1].."\148"
        thebtn.blit[1][2] = thebtn.blit[1][2]..lUtils.toBlit(term.getBackgroundColor())
        thebtn.blit[1][3] = thebtn.blit[1][3]..lUtils.toBlit(colors.gray)
        for t=1,#lines do
            thebtn.blit[t+1] = {"\149",tostring(lUtils.toBlit(colors.gray)),tostring(lUtils.toBlit(term.getBackgroundColor()))}
            for w=1,width-2 do
                thebtn.blit[t+1][1] = thebtn.blit[t+1][1].." "
                if t == 1 then
                    thebtn.blit[t+1][2] = thebtn.blit[t+1][2]..lUtils.toBlit(term.getTextColor())
                else
                    thebtn.blit[t+1][2] = thebtn.blit[t+1][2]..lUtils.toBlit(colors.lightGray)
                end
                thebtn.blit[t+1][3] = thebtn.blit[t+1][3]..lUtils.toBlit(term.getBackgroundColor())
            end
            local thetxt = ""
            if string.len(lines[t]) > thebtn.w-2 then
                thetxt = string.sub(lines[t],thebtn.w-2)
            else
                thetxt = lines[t]
            end
            thebtn.blit[t+1][1] = "\149"..thetxt..string.sub(thebtn.blit[t+1][1],2+string.len(thetxt),string.len(thebtn.blit[t+1][1]))
            thebtn.blit[t+1][1] = thebtn.blit[t+1][1].."\149"
            thebtn.blit[t+1][2] = thebtn.blit[t+1][2]..tostring(lUtils.toBlit(term.getBackgroundColor()))
            thebtn.blit[t+1][3] = thebtn.blit[t+1][3]..lUtils.toBlit(colors.gray)
        end
        thebtn.blit[#thebtn.blit+1] = {"\138",tostring(lUtils.toBlit(term.getBackgroundColor())),tostring(lUtils.toBlit(colors.gray))}
        local tempblit = thebtn.blit[#thebtn.blit]
        for t=1,thebtn.w-2 do
            tempblit[1] = tempblit[1].."\143"
            tempblit[2] = tempblit[2]..lUtils.toBlit(term.getBackgroundColor())
            tempblit[3] = tempblit[3]..lUtils.toBlit(colors.gray)
        end
        tempblit[1] = tempblit[1].."\133"
        tempblit[2] = tempblit[2]..lUtils.toBlit(term.getBackgroundColor())
        tempblit[3] = tempblit[3]..lUtils.toBlit(colors.gray)
        for t=1,#thebtn.blit do
            term.setCursorPos(px,py+(t-1))
            term.blit(table.unpack(thebtn.blit[t]))
        end
    end
    return thebtn
end
lSettings = {{"Peripherals","Monitors, Speakers,","Printers"},{"Personal Settings","Background, Welcome","Screen"},{"E","Fookin nonsense","aha"},{"Hello","How are you","Mr Valentine"},{"Hey","I am good thank",":)"}}
btnW = 21
btnH = 5
scrl = 0
function setrender(scr) -- settings render, scroll (Y)
    if scr == nil then
        scr = 0
    end
    term.setBackgroundColor(colors.black)
    term.clear()
    local w,h = term.getSize()
    term.setCursorPos(math.ceil(w/2)-math.floor(string.len("Settings")/2),2-scr)
    term.setTextColor(colors.white)
    term.write("Settings")
    local cX = math.ceil(w/2)+1
    local cY = 4
    while cX-(btnW+1) > 1 do
        cX = cX-(btnW+1)
    end
    local OGcX = cX
    btns = {}
    for t=1,#lSettings do
        --term.setCursorPos(cX,cY-scr)
        btn(cX,cY-scr,btnW,lSettings[t]).render()
        if cX+(btnW*2+2) <= w then
            cX = cX+(btnW+1)
        else
            cX = OGcX
            cY = cY+btnH+1
        end
    end
end
setrender()
local aw,ah = term.getSize()
local ow,oh = aw,ah
while true do
    e = {os.pullEvent()}
	if e[1] == "mouse_scroll" then
		scrl = scrl+e[2]
		setrender(scrl)
	elseif e[1] == "mouse_click" then
		for t=1,#btns do
			if e[3] >= btns[t].x and e[4] >= btns[t].y and e[3] <= btns[t].x+(btns[t].w-1) and e[4] <= btns[t].y+(btns[t].h-1) then
				term.setCursorPos(1,1)
				print("Yey")
				term.setBackgroundColor(colors.gray)
				btns[t].render(btns[t].x,btns[t].y)
			end
		end
	elseif e[1] == "mouse_up" then
		term.setBackgroundColor(colors.black)
		setrender(scrl)
	end
    aw,ah = term.getSize()
    if aw ~= ow or ah ~= oh then
        setrender(scrl)
        ow,oh = aw,ah
    end
end
os.sleep(3)