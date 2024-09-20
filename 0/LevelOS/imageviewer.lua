local format

local function getLines(str)
    local lines = {}
    local w = 0
    for potato in str:gmatch("[^\n]+") do
        table.insert(lines,potato)
        if #potato > w then
            w = #potato
        end
    end
    return lines,w
end

--[[local function render(spr)
    term.setBackgroundColor(colors.black)
    term.clear()
    if format == "lImg" then
        local sW,sH = #spr[1][1],#spr
        local w,h = term.getSize()
        for l=1,#spr do
            term.setCursorPos(math.ceil(w/2)-math.floor(sW/2),math.ceil(h/2)-math.floor(sH/2)+(l-1))
            local bl = {}
            bl[1] = spr[l][1]
            bl[2] = string.gsub(spr[l][2],"T",lUtils.toBlit(term.getBackgroundColor()))
            bl[3] = string.gsub(spr[l][3],"T",lUtils.toBlit(term.getBackgroundColor()))
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
end]]
local render = lUtils.renderImg

local tArgs = {...}
local filepath
if tArgs[1] ~= nil and fs.exists(tArgs[1]) then
    filepath = tArgs[1]
end
while not filepath do
    filepath = lUtils.explorer("User","SelFile false")
end

local sprite = {}
local ext = lUtils.getFileType(filepath)
if ext == ".nfp" then
    format = "nfp"
    sprite[1] = lUtils.fread(filepath)
elseif ext == ".nfg" then
    format = "nfg"
    sprite = lUtils.asset.load(filepath)
elseif ext == ".limg" or ext == ".bimg" then
    format = "lImg"
    sprite = lUtils.asset.load(filepath)
else
    lUtils.popup("Error","This file type is not supported!",22,9,{"OK"})
    return
end

local tID = os.startTimer(0.5)
render(sprite[1])
local spr = 1
while true do
    local e = {os.pullEvent()}
    if #sprite > 1 and e[1] == "timer" and e[2] == tID then
        tID = os.startTimer(0.1)
        spr = spr+1
        if spr > #sprite then
            spr = 1
        end
        term.clear()
        render(sprite[spr])
    elseif e[1] == "term_resize" then
    	term.clear()
        render(sprite[spr])
    end
end