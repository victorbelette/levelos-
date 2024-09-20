
local bg = term.getBackgroundColor()
local fg = term.getTextColor()

if fs.exists("bigfont") then
    os.loadAPI("bigfont")
end

local register = false

local rememberme = false

local w,h = term.getSize()

local userbox = lUtils.makeEditBox("username",w,1)
local pwbox = lUtils.makeEditBox("password",w,1)
local pwconfirm = lUtils.makeEditBox("pwconfirm",w,1)


if fs.exists("LevelOS/data/account.txt") then
    userbox.lines[1] = lUtils.fread("LevelOS/data/account.txt")
end

if fs.exists("LevelOS/data/account2.txt") then
    --pwbox.lines[1] = lUtils.fread("LevelOS/data/account2.txt")
    token = lUtils.fread("LevelOS/data/account2.txt")
    --rememberme = true
    local res = http.post("https://www.old.leveloper.cc/auth.php","username="..userbox.lines[1].."&token="..token)
    local str = res.readAll()
    if str:find("Welcome") then
        local userID = res.getResponseHeaders()["Set-Cookie"]
        return userID,userbox.lines[1]
    end
end

local trysub = false

local continue = true

local boxes = {}

local e = {}

local webresponse

local userID = ""

local pause = false

local function submit()
    trysub = true
    continue = true
    os.sleep(0.5)
    if continue == true then
        saveuser = fs.open("LevelOS/data/account.txt","w")
        saveuser.write(userbox.lines[1])
        saveuser.close()
        if rememberme then
        	--lUtils.fwrite("LevelOS/data/account2.txt",pwbox.lines[1])
        else
            fs.delete("LevelOS/data/account2.txt")
        end
        if register then
            response = {http.post("https://www.old.leveloper.cc/register.php","username="..userbox.lines[1].."&password="..pwbox.lines[1])}
            local webres = response[1].readAll()
            if webres == "200" then
             local xtra = ""
             if rememberme then
                 xtra = "&rememberme=true"
             end
            	response2 = {http.post("https://www.old.leveloper.cc/auth.php","username="..userbox.lines[1].."&password="..pwbox.lines[1]..xtra)}
            	userID = response2[1].getResponseHeaders()["Set-Cookie"]
            	webresponse = webres
             if rememberme then
                 token = lUtils.getField(response2[1].readAll(),"token")
                 lUtils.fwrite("LevelOS/data/account2.txt",token)
             end
            end
        else
            local xtra = ""
            if rememberme then
                xtra = "&rememberme=true"
            end
            response = {http.post("https://www.old.leveloper.cc/auth.php","username="..userbox.lines[1].."&password="..pwbox.lines[1]..xtra)}
            webresponse = response[1].readAll()
           	userID = response[1].getResponseHeaders()["Set-Cookie"]
            if rememberme then
                token = lUtils.getField(webresponse,"token")
                lUtils.fwrite("LevelOS/data/account2.txt",token)
            end
        end
        --print("username="..userbox.lines[1].."&password="..pwbox.lines[1])
        -- check if things are present communicate with PHP
    end
end

local regsel = false

local function draw()
    boxes = {}
    local cY = 1
    local w,h = term.getSize()
    term.setBackgroundColor(colors.white)
    term.clear()
    term.setBackgroundColor(colors.white)
    if h < 19 then
        -- absolutely fkin nothin
    elseif h < 25 or w < 26 or not bigfont then
        for t=0,2 do
            term.setCursorPos(1,cY+t)
            term.clearLine()
        end
        term.setCursorPos(2,cY+2)
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.lightGray)
        term.write(string.rep("\143",w-2))
        term.setTextColor(colors.blue)
        term.setBackgroundColor(colors.white)
        cY = cY+1
        term.setCursorPos(1,cY)
        if register then
            lUtils.centerText("Register")
        else
            lUtils.centerText("Log in")
        end
        cY = cY+2
    else
        if h < 50 or w < 90 then
            for t=0,4 do
                term.setCursorPos(1,cY+t)
                term.clearLine()
            end
            term.setCursorPos(2,cY+4)
        else
            for t=0,10 do
                term.setCursorPos(1,cY+t)
                term.clearLine()
            end
            term.setCursorPos(2,cY+10)
        end
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.lightGray)
        term.write(string.rep("\143",w-2))
        term.setTextColor(colors.blue)
        term.setBackgroundColor(colors.white)
        cY = cY+1
        local size = 1
        --cY = cY+4
        if h >= 50 and w >= 90 then
            size = 2
            cY = cY+10
        else
            cY = cY+4
        end
        if register then
            bigfont.writeOn(term.current(),size,"Register",nil,2)
        else
            bigfont.writeOn(term.current(),size,"Log in",nil,2)
        end
    end
    term.setBackgroundColor(colors.white)
    for y=cY,h do
        term.setCursorPos(1,y)
        term.clearLine()
    end
    cY = cY+1
    term.setTextColor(colors.lightGray)
    local offset = math.ceil(w/30)
    local spacing = 0
    if h > 50 then
        spacing = 5
    elseif h > 45 then
        spacing = 4
    elseif h > 40 then
        spacing = 3
    elseif h > 35 then
        spacing = 2
    elseif h > 30 then
        spacing = 1
    end
    cY = cY+spacing
    if (register and trysub and userbox.lines[1] and userbox.lines[1] ~= "" and string.len(userbox.lines[1]) >= 3 and #userbox.lines[1] <= 15 and not string.find(userbox.lines[1],"[^a-zA-Z0-9]")) then -- also check for special characters
        term.setTextColor(colors.lime)
    elseif register and trysub then
        term.setTextColor(colors.red)
        term.setCursorPos(1,cY+3)
        if #userbox.lines[1] < 3 or #userbox.lines[1] > 15 then
            lUtils.centerText("Username must be between 3-15 characters.")
        else
            lUtils.centerText("Username can not contain special characters.")
        end
        continue = false
    else
        term.setTextColor(colors.lightGray)
    end
    lUtils.border(1+offset,cY,w-offset,cY+2)
    userbox.x = 2+offset
    userbox.y = cY+1
    userbox.width = ((w-offset)-1)-(1+offset)
    boxes[#boxes+1] = {x1=1+offset,y1=cY,x2=w-offset,y2=cY+2,func=function() lUtils.drawEditBox(userbox,nil,nil,nil,nil,nil,nil,true,false) end}
    cY = cY+1
    term.setCursorPos(2+offset,cY)
    if userbox.lines[1] and userbox.lines[1] ~= "" then
        term.setTextColor(colors.gray)
        term.write(string.sub(userbox.lines[1],1,userbox.width))
    else
        term.write("Username")
    end
    cY = cY+3+spacing
    if (register and trysub and pwbox.lines[1] and pwbox.lines[1] ~= "" and string.len(pwbox.lines[1]) >= 5) then
        term.setTextColor(colors.lime)
    elseif register and trysub then
        term.setTextColor(colors.red)
        continue = false
    else
        term.setTextColor(colors.lightGray)
    end
    lUtils.border(1+offset,cY,w-offset,cY+2)
    pwbox.x = 2+offset
    pwbox.y = cY+1
    pwbox.width = ((w-offset)-1)-(1+offset)
    boxes[#boxes+1] = {x1=1+offset,y1=cY,x2=w-offset,y2=cY+2,func=function() lUtils.drawEditBox(pwbox,nil,nil,nil,nil,nil,nil,true,false,"*") end}
    cY = cY+1
    term.setCursorPos(2+offset,cY)
    if pwbox.lines[1] and pwbox.lines[1] ~= "" then
        term.setTextColor(colors.gray)
        term.write(string.rep("*",string.len(string.sub(pwbox.lines[1],1,pwbox.width))))
    else
        term.write("Password")
    end
    if register then
        cY = cY+3+spacing
        if (register and trysub and pwconfirm.lines[1] and pwconfirm.lines[1] ~= "" and string.len(pwconfirm.lines[1]) > 3 and pwconfirm.lines[1] == pwbox.lines[1]) then
            term.setTextColor(colors.lime)
        elseif register and trysub then
            term.setTextColor(colors.red)
            if spacing > 0 then
                term.setCursorPos(1,cY+3)
                lUtils.centerText("Passwords don't match.")
            end
            continue = false
        else
            term.setTextColor(colors.lightGray)
        end
        lUtils.border(1+offset,cY,w-offset,cY+2)
        pwconfirm.x = 2+offset
        pwconfirm.y = cY+1
        pwconfirm.width = ((w-offset)-1)-(1+offset)
        boxes[#boxes+1] = {x1=1+offset,y1=cY,x2=w-offset,y2=cY+2,func=function() lUtils.drawEditBox(pwconfirm,nil,nil,nil,nil,nil,nil,true,false,"*") end}
        cY = cY+1
        term.setCursorPos(2+offset,cY)
        if pwconfirm.lines[1] and pwconfirm.lines[1] ~= "" then
            term.setTextColor(colors.gray)
            term.write(string.rep("*",string.len(string.sub(pwconfirm.lines[1],1,pwconfirm.width))))
        else
            term.write("Confirm Password")
        end
    end
    cY = cY+3+spacing
    term.setTextColor(colors.white)
    if e[1] == "mouse_click" and e[3] >= 1+(offset+2) and e[4] >= cY and e[3] <= w-(offset+2) and e[4] <= cY+2 then
        regsel = true
    elseif e[1] == "mouse_up" then
        regsel = false
    end
    if regsel or trysub then
        term.setBackgroundColor(colors.lightBlue)
    else
        term.setBackgroundColor(colors.blue)
    end
    lUtils.border(1+(offset+2),cY,w-(offset+2),cY+2,"fill")
    boxes[#boxes+1] = {x1=1+(offset+2),y1=cY,x2=w-(offset+2),y2=cY+2,func=submit}
    cY = cY+1
    term.setCursorPos(1,cY)
    if register then
        lUtils.centerText("Register")
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.lightBlue)
        term.setCursorPos(1,cY-2)
        local w,h = term.getSize()
        if w < string.len("Already have an account? Log in.") then
            lUtils.centerText("Log in")
        else
        	lUtils.centerText("Already have an account? Log in.")
        end
        boxes[#boxes+1] = {x1=math.ceil(w/2)-16,x2=math.ceil(w/2)+16,y1=cY-2,y2=cY-2,func=function() register = false end}
    else
        lUtils.centerText("Log in")
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.lightBlue)
        term.setCursorPos(1,cY+2)
        local w,h = term.getSize()
        if w < string.len("Don't have an account yet? Register.") then
            lUtils.centerText("Register")
        else
        	lUtils.centerText("Don't have an account yet? Register.")
        end
        boxes[#boxes+1] = {x1=math.ceil(w/2)-18,x2=math.ceil(w/2)+18,y1=cY+2,y2=cY+2,func=function() register = true end}
    end
    cY = cY+4
    local bl = {
      {
        "",
        "00f",
        "ff0",
      },
      {
        " ",
        "0ff",
        "f00",
      },
      {
        "",
        "fff",
        "000",
      },
    }
    if rememberme then
        bl[2][1] = "x"
    end
    local txt = "    Auto-login" -- 4 spaces for the box
    local rX = math.ceil(w/2)-math.floor(#txt/2)
    term.setCursorPos(rX,cY)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.gray)
    term.write(txt)
    for b=1,#bl do
        term.setCursorPos(rX,(cY-2)+b)
        term.blit(unpack(bl[b]))
    end
    table.insert(boxes,{x1=rX,y1=cY,x2=rX+2,y2=cY,func=function() local f = function() rememberme = not rememberme end pause = true f() pause = false end})
end
local function textboxes()
    while true do
        local e = {os.pullEvent()} 
        term.setCursorPos(1,1)
        term.setBackgroundColor(colors.white)
        term.setTextColor(colors.black)
        --term.write(table.concat(e,", "))
        if e[1] == "mouse_up" and e[2] == 1 then
            for b=1,#boxes do
                local box = boxes[b]
                if e[3] >= box.x1 and e[4] >= box.y1 and e[3] <= box.x2 and e[4] <= box.y2 then
                    trysub = false
                    box.func()
                    os.startTimer(0.1)
                end
            end
        end
    end
end
local txtbox = coroutine.create(textboxes)
if rememberme then submit() end
draw()
while true do
    e = {os.pullEvent()}
    local w,h = term.getSize()
    local pW,pH
    if w < 29 then
        pW = 19
        pH = 15
    else
        pW = 29
        pH = 9
    end
    if not webresponse then
        if not pause then
        	draw()
        end
        coroutine.resume(txtbox,table.unpack(e))
        while pause do
            local e = {os.pullEvent()}
            coroutine.resume(txtbox,table.unpack(e))
        end
    else
        if (register and webresponse ~= "200") or (not register and not string.find(webresponse,"Welcome")) then
            lUtils.popup("LevelOS",lUtils.getField(webresponse,"msg"),pW,pH,{"OK"})
            term.setTextColor(fg)
            term.setBackgroundColor(bg)
            if rememberme then
                rememberme = false
                fs.delete("LevelOS/data/account2.txt")
            end
            return false
        elseif register then
            lUtils.popup("LevelOS","You have successfully registered! You are now logged in.",pW,pH,{"OK"})
            term.setTextColor(fg)
            term.setBackgroundColor(bg)
            return userID,userbox.lines[1]
        else
            term.setTextColor(fg)
            term.setBackgroundColor(bg)
            return userID,userbox.lines[1]
        end
    end
end