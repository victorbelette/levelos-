if lOS and lOS.started then
    error("LevelOS is already running, silly!")
end

changecolors = false
purecolors = false
local ranstartup = false
if purecolors == true then
    term.setPaletteColor(colors.white,1,1,1)
    term.setPaletteColor(colors.orange,1,0.5,0)
    -- magenta
    -- light blue
    term.setPaletteColor(colors.yellow,1,1,0)
    term.setPaletteColor(colors.lime,0,1,0)
    term.setPaletteColor(colors.pink,1,0.5,1)
    -- gray
    -- light gray
    term.setPaletteColor(colors.cyan,0,1,1)
    term.setPaletteColor(colors.purple,0.8,0,1)
    term.setPaletteColor(colors.blue,0,0,1)
    -- brown
    term.setPaletteColor(colors.green,0,0.6,0)
    term.setPaletteColor(colors.red,1,0,0)
    term.setPaletteColor(colors.black,0,0,0)
end
if changecolors == true then
    allcolors = {}
    for t=0,15,1 do
        allcolors[#allcolors+1] = {term.getPaletteColor(2^t)}
        term.setPaletteColor(2^t,0,0,0)
    end
end
if not lOS then
    _G.lOS = {}
end
lOS.started = false
if fs.exists("LevelOS/data/settings.lconf") then
    local f = fs.open("LevelOS/data/settings.lconf","r")
    local s = f.readAll()
    f.close()
    lOS.settings = textutils.unserialize(s)
else
    lOS.settings = {maxAll=false} -- load from file usually
end
lOS.tbSize = 0
lOS.lMenu = false
lOS.log = ""
lOS.doasearch = false
lOS.notifications = {}
if fs.exists("AppData") == false then
    fs.makeDir("AppData")
end

if fs.exists("AppData") and fs.exists("AppData/Shapescape") and fs.exists("AppData/Shapescape/temp") then
    local f = fs.list("AppData/Shapescape/temp")
    for t=1,#f do
        fs.delete(fs.combine("AppData/Shapescape/temp",f[t]))
    end
end
lOS.oldterm = term.current()
local oldterm = lOS.oldterm
local w,h = term.getSize()

local function log(txt)
    --lOS.log = lOS.log..txt.."\n"
end


local function fread(file)
    local f = fs.open(file,"r")
    local o = f.readAll()
    f.close()
    return o
end

lOS.processes = {}


lOS.noEvents = false


lOS.wins = {}

lOS.wAll = window.create(oldterm,1,1,w,h,false) -- window all (window object containing all window objects)
local wAll = lOS.wAll
lOS.depWin = window.create(wAll,1,1,w,h,false) -- window where windowless processes will draw objects to. (Does not get saved)

shell.run("LevelOS/startup/lUtils")
local function login()
    if fs.exists("LevelOS/data/account.txt") then
        while not lOS.userID do pcall(function() dofile("LevelOS/Login_screen.sgui") end) end
    elseif fs.exists("LevelOS/startup/LevelCloud.lua") then
        --while not lOS.userID do pcall(function() dofile("LevelOS/Global_Login.lua") end) end
        --while not lOS.userID do pcall(function() lOS.userID,lOS.username = dofile("LevelOS/login.lua") end) end
    end
end
local boterm = term.current()
local buffer = window.create(boterm,1,1,w,h,false)
local bufcor = coroutine.create(login)
if lOS.checkinternet() ~= 0 then
    os.startTimer(0)
    while coroutine.status(bufcor) ~= "dead" do
        local e = table.pack(os.pullEventRaw())
        term.redirect(buffer)
        coroutine.resume(bufcor, table.unpack(e, 1, e.n))
        term.redirect(boterm)
        buffer.setVisible(true)
        buffer.setVisible(false)
    end
end
term.redirect(boterm)
for c=0,15,1 do
    wAll.setPaletteColor(2^c,buffer.getPaletteColor(2^c))
end

os.startTimer(0)

local proc = lOS.processes
--proc[0] = {coroutine.create(function() shell.run("LevelOS/desktop.lua") end),title="Desktop",win=window.create(wAll,1,1,w,h,false),winMode="background"}
proc[0] = {title="Desktop",win=window.create(wAll,1,1,w,h,false),winMode="screen"}
proc[0][1] = coroutine.create(function() local ok,err = lOS.run("LevelOS/desktop.lua",proc[0]) if not ok then lOS.bsod(err) end end)
if fs.exists("LevelOS/data/changelog.lconf") then
    local w,h = term.getSize()
    local offset = 2
    local offsetY = 2
    if w > 60 then
        offset = 2+math.ceil((w-60)/3)
    end
    if h > 40 then
        offsetY = 2+math.ceil((h-40)/3)
    end
    proc[2] = {coroutine.create(function() shell.run("LevelOS/Changelog.lua") end),title="Changelog",win=window.create(wAll,1+offset,1+offsetY,w-(offset*2),(h-2)-(offsetY*2),false),winMode="widget"}
end

-- FOR DEBUGGING PURPOSES ONLY!!!!!
--proc[2] = {coroutine.create(function() shell.run("LevelOS/Task_Manager.lua") end),title="Task Manager",win=window.create(wAll,3,3,35,14,false),winMode="windowed"}
--proc[3] = {coroutine.create(function() shell.run("User/Scripts/log.lua") end),title="Log",win=window.create(wAll,5,5,35,14,false),winMode="windowed"}
--proc[3] = {coroutine.create(function() shell.run("rom/programs/shell.lua") end),title="Shell",win=window.create(wAll,7,7,35,14,false),winMode="windowed"}
--proc[4] = {coroutine.create(function() shell.run("rom/programs/shell.lua") end),win=window.create(wAll,1,1,51,17,false),winMode="borderless"}
--proc[4] = {coroutine.create(function() shell.run("rom/programs/shell.lua") end),title="Pastebin",win=window.create(wAll,9,9,35,14,false),winMode="borderless"}

_G.wButton = 0

lOS.wins[0] = proc[0]
lOS.focusWin = lOS.wins[0]
lOS.wins[1] = proc[2]
--lOS.wins[1] = proc[2]
--lOS.wins[2] = proc[3]
--lOS.wins[3] = proc[3]
--lOS.wins[4] = proc[4]
--table.insert(lOS.wins,1,proc[4])


--[[for t=1,#lOS.wins do
    if lOS.wins[t].snap == nil then
        lOS.wins[t].snap = "none"
    end
end]]



local lTime = 0

local sysErr
local sysEnabled = false

function lOS.bsod(msg)
    sysErr = msg
end

function lOS.sysUpdate(v)
    if v then
        sysEnabled = true
    else
        sysEnabled = false
    end
end

local sysTimer

local function system()
    local timer = 0
    lOS.sysUI = lOS.execute("LevelOS/SystemUI.lua","background")

    local response,err = http.post("https://old.leveloper.cc/sGet.php","path="..textutils.urlEncode("").."&name="..textutils.urlEncode("LevelOS_Beta_1251278571250123"),{Cookie=lOS.userID})
    if response then
        local f = response.readAll()
        local vtemp = lUtils.getField(f,"version")
        local servertimestamp = tonumber(vtemp)
        local clienttimestamp
        if fs.exists("LevelOS/data/version.txt") then
            clienttimestamp = tonumber(fread("LevelOS/data/version.txt"))
        end
        if not clienttimestamp then
            clienttimestamp = 0
        end
        if servertimestamp > clienttimestamp then
            if fs.exists("LevelOS/Beta_Updater.lua") then
                fs.delete("LevelOS/Beta_Updater.lua")
            end
            shell.run("lStore get Beta_Updater LevelOS/Beta_Updater.lua")
            os.sleep(1)
            if fs.exists("LevelOS/Beta_Updater.lua") then
                lOS.execute("LevelOS/Beta_Updater.lua")
            end
        end
    end

    --[[if not fs.exists("rom/apis/http/http.lua") then
        local function wrapRequest(_url, ...)
            local ok, err = http.request(...)
            if ok then
                while true do
                    local e = {os.pullEvent()}
                    if e[1] == "http_success" and e[2] == _url then
                        return e[3]
                    elseif event == "http_failure" and e[2] == _url then
                        return nil, e[3], e[4]
                    end
                end
            end
            return nil, err
        end

        function http.post(_url, _post, _headers, _binary)
            if type(_url) == "table" then
                return wrapRequest(_url.url, _url)
            else
                return wrapRequest(_url, _url, _post, _headers, _binary)
            end
        end

        function http.get(_url, _headers, _binary)
            if type(_url) == "table" then
                return wrapRequest(_url.url, _url)
            else
                return wrapRequest(_url, _url, nil, _headers, _binary)
            end
        end
    end]]

    while true do
        if ranstartup == false and lOS.fadeComplete then
            local sProgs = fs.list("LevelOS/startup")
            for t=1,#sProgs do
                if sProgs[t] ~= "lUtils.lua" and not string.find(sProgs[t],"updater") then
                    --print("Running "..sProgs[t].."...")
                    lOS.execute(fs.combine("LevelOS/startup",sProgs[t]),"background")
                end
            end
            ranstartup = true
        end
        if sysEnabled then
            local nsysTimer = os.startTimer(0.1)
            local ev = {}
            while ev[1] ~= "timer" or ev[2] ~= nsysTimer do
                ev = table.pack(os.pullEventRaw())
            end
            sysTimer = nsysTimer
            lTime = lTime+0.02
        else
            coroutine.yield()
        end
        if not lOS.sysUI.env then
            error("SystemUI: CRITICAL_PROCESS_DIED",0)
        end
        if sysErr then
            error(tostring(sysErr),0)
        end
    end
end



proc[1] = {coroutine.create(system),title="System",path="LevelOS/system.lua",win=window.create(wAll,1,1,51,19,false),winMode="background"}
lOS.system = proc[1]


local function getPixel(win,x,y)
    theline = {win.getLine(y)}
    return string.sub(theline[1],x,x),string.sub(theline[2],x,x),string.sub(theline[3],x,x)
end

local set = lOS.settings

local previewrect


--for p=0,#proc do
    --coroutine.resume(process[1])
--end

local cProc = 0

function lOS.execute(path,mode,wX,wY,wW,wH,focus)
    local aliases = {
        ["LevelOS/explorer.lua"] = "Program_Files/LevelOS/Explorer",
        ["LevelOS/LevelCloud.lua"] = "Program_Files/LevelOS/Cloud",
        ["LevelOS/notepad.lua"] = "Program_Files/LevelOS/Notepad",
        ["LevelOS/Pigeon.lua"] = "Program_Files/Pigeon",
    }
    _G.debugpath = path
    local tempargs
    if type(path) == "table" then
        tempargs = path
        path = tempargs[1]
        table.remove(tempargs,1)
    end

    local tPath = ""
    local rPath
    local args
    if not tempargs then
        rPath = string.sub(path,string.find(path,"%S+"))
        local b,e = string.find(path,"%S+")
        tPath = string.sub(path,e+2,string.len(path))
        args = {}
        for i in string.gmatch(tPath,"%S+") do
            if i ~= nil and i ~= "" then
                args[#args+1] = i
            end
        end
    else
        rPath = path
        args = tempargs
    end
    _G.debugargs = args
    if lUtils.getFileType(rPath) == ".llnk" then
        local link = lUtils.asset.load(rPath)
        if link[1] and fs.exists(link[1]) then
            local cmd = link[1]
            local args2 = link.args
            if args2 and #args > 0 then
                cmd = cmd.." "..table.concat(args2, " ")
            end
            if args and #args > 0 then
                cmd = cmd.." "..table.concat(args," ")
            end
            return lOS.execute(cmd,mode,wX,wY,wW,wH,focus)
        end
    end
    if aliases[rPath] then
        rPath = aliases[rPath]
    end
    if fs.isDir(rPath) then
        local files = fs.list(rPath)
        local runfile = false
        if fs.exists(fs.combine(rPath,"main.lua")) then
            runfile = true
            rPath = fs.combine(rPath,"main.lua")
        else
            for f=1,#files do
                local fP = fs.combine(rPath,files[f])
                if not fs.isDir(fP) then
                    if lUtils.getFileType(files[f]) == ".lua" then
                        rPath = fP
                        runfile = true
                        break
                    end
                end
            end
        end
        if not runfile then
            return false,"No lua file found in this folder."
        end
    end

    local w,h = oldterm.getSize()
    local thewin
    if mode == "maximized" then
        local tw,th = lOS.wAll.getSize()
        thewin = window.create(oldterm,1,2,tw,th-1-lOS.tbSize)
        mode = "windowed"
    elseif wX and wY and wW and wH then
        thewin = window.create(oldterm,wX,wY,wW,wH,false)
    elseif w <= 60 or h < 21 or (set.maxAll == true) then
        thewin = window.create(oldterm,1,2,w,h-3,false)
    else
        local x,y = 7,7
        local w,h = 51,19
        local tw,th = lOS.wAll.getSize()
        if lOS.tbSize then
            th = th-(lOS.tbSize-1)
        end
        for i,proc in ipairs(lOS.wins) do
            if proc.path == rPath then
                local nx,ny,nw,nh
                if not proc.snap then
                    nx,ny = proc.win.getPosition()
                    nw,nh = proc.win.getSize()
                else
                    nx,ny = unpack(proc.snap.oPos)
                    nw,nh = unpack(proc.snap.oSize)
                end
                w,h = nw,nh
                if nx+nw >= tw or ny+nh >= th then
                    x,y = 3,3
                else
                    x,y = nx+2,ny+1
                end
            end
        end
        thewin = window.create(oldterm,x,y,w,h,false)
    end
    local nPath = rPath
    if fs.getName(nPath) == "main.lua" then
        nPath = fs.getDir(nPath)
    end
    local t = lUtils.getFileName(nPath)
    t = t:sub(1,1):upper()..t:sub(2)
    local process = {title=t,win=thewin,winMode=mode or "windowed",path=rPath}
    local function func()
        local oWin = thewin
        local a = {lOS.run(rPath,process,table.unpack(args))}
        if a[1] == false then
            if process.winMode ~= "background" then
                term.redirect(oWin)
                local b = {lUtils.popup(fs.getName(rPath),fs.getName(rPath).." has stopped working.",29,9,{"OK","View Error"})}
                if b[3] == "View Error" then
                    lUtils.popup(fs.getName(rPath),a[2],31,nil,{"OK"})
                end
            else
                lOS.notification(fs.getName(rPath).." has stopped working.")
            end
        end
    end
    process[1] = coroutine.create(func)
    for i = 0, 15 do process.win.setPaletteColor(2^i, lOS.wins[0].win.getPaletteColor(2^i)) end
    table.insert(lOS.processes,process)
    local oterm = term.current()
    term.redirect(process.win)
    local oldcproc = cProc
    cProc = #lOS.processes
    process.id = cProc
    coroutine.resume(process[1])
    cProc = oldcproc
    term.redirect(oterm)
    if mode ~= "background" then
        os.queueEvent("window_open",#lOS.processes,tostring(process),focus)
    end
    return process
end

term.redirect(proc[0].win)
function lOS.getRunningProcess()
    return proc[cProc]
end
coroutine.resume(proc[0][1])
term.redirect(oldterm)

local oldwin = {}
local isFullscreen = false
local tbSize
lOS.nYieldTime = 0
lOS.eventsPassed = 0
local oYieldTime = os.epoch("utc")

local forceResumeID = 0
function lOS.queueForceResume()
    forceResumeID = forceResumeID + 1
    os.queueEvent("levelos_force_resume", forceResumeID)
    return forceResumeID
end

local function hook(event)
    local proc = lOS.getRunningProcess()
    if proc then
        local cStat = coroutine.status(proc[1])
        if cStat == "running" or cStat == "normal" then
            if os.epoch("utc") > proc.lastYield+1000 then
                if os.epoch("utc") > proc.lastYield+5000 then
                    proc.unresponsive = true
                end
                if not proc.eventQueue then
                    proc.eventQueue = {}
                end
                if not proc.systemYield then
                    proc.systemYield = lOS.queueForceResume()
                end
                proc.lastInterrupt = os.epoch("utc")
                while true do
                    local e = table.pack(coroutine.yield())
                    if e[1] == "levelos_force_resume" then
                        proc.systemYield = nil
                        proc.unresponsive = nil
                        break
                    else
                        table.insert(proc.eventQueue, e)
                    end
                end
            end
        end
    end
end

local requestCache
if fs.exists("rom/apis/http/http.lua") then
    local nativeHTTPRequest = http.request

    requestCache = {}
    lOS.requestCache = requestCache

    function http.request(_url, _post, _headers, _binary)
        local data
        if type(_url) == "table" then
            data = _url
        else
            data = {url=_url, body=_post, headers=_headers, binary=_binary}
        end
        local oldURL = data.url
        while requestCache[data.url] do
            if data.url:find("#", nil, true) then
                data.url = data.url.."0"
            else
                data.url = data.url.."#"
            end
        end
        requestCache[data.url] = {url=oldURL, binary=data.binary, process=lOS.getRunningProcess()}

        data.binary = true
        local ok, err = nativeHTTPRequest(data)
        if not ok then
            os.queueEvent("http_failure", data.url, err)
        end

        return ok, err
    end

    local restore = {
        checkURL = http.checkURL,
        websocket = http.websocket,
        websocketAsync = http.websocketAsync,
    }
    os.loadAPI("rom/apis/http/http.lua")
    for key, value in pairs(restore) do
        http[key] = value
    end
else
    
end

local function resumeProcess(process, e)
    if not (process.sFilter and process.sFilter ~= e[1]) then
        if process.eventQueue and not process.systemYield then
            local queue = process.eventQueue
            process.eventQueue = nil
            for i, event in ipairs(queue) do
                process.lastYield = os.epoch("utc")
                resumeProcess(process, event)
            end
        end

        if not process.systemYield then
            process.lastYield = os.epoch("utc")
        end

        local cSuccess,cFilter = coroutine.resume(process[1],table.unpack(e, 1, e.n))
        if cSuccess then
            process.sFilter = cFilter
        elseif process == lOS.system or process == lOS.systemUI then
            _G.theSystemError = cFilter
            error(cFilter,0)
        end
    end
end

local function increaseBrightness(colors, brightnessFactor)
    local brightenedColors = {}

    for _, color in ipairs(colors) do
        local brightenedColor = {
            math.min(color[1] + brightnessFactor, 1),
            math.min(color[2] + brightnessFactor, 1),
            math.min(color[3] + brightnessFactor, 1)
        }
        table.insert(brightenedColors, brightenedColor)
    end

    return brightenedColors
end

local function colorDistance(color1, color2)
    if type(color1) == "number" then
        color1 = {term.getPaletteColor(color1)}
    end
    if type(color2) == "number" then
        color2 = {term.getPaletteColor(color2)}
    end
    local rDiff = color1[1]+0.2 - color2[1]
    local gDiff = color1[2]+0.2 - color2[2]
    local bDiff = color1[3]+0.2 - color2[3]
    return (rDiff * rDiff + gDiff * gDiff + bDiff * bDiff) ^ 0.5
end

local function findClosestColor(targetColor, colorArray)
    local closestColor = nil
    local minDistance = math.huge

    for _, color in ipairs(colorArray) do
        local distance = colorDistance(targetColor, color)
        if distance < minDistance then
            minDistance = distance
            closestColor = color
        end
    end

    return closestColor
end

local function genGrayscale(win)
    local replace = {}
    local grays = {colors.black, colors.gray, colors.lightGray, colors.white}
    for i=0,15 do
        replace[lUtils.toBlit(2^i)] = lUtils.toBlit(findClosestColor(2^i, grays))
    end
    
    local lines = {}
    local w,h = win.getSize()
    for y=1,h do
        local line = {win.getLine(y)}
        for i=2,3 do
            line[i] = line[i]:gsub(".", function(str) return replace[str] end)
        end
        table.insert(lines, line)
    end
    return lines
end

_G.genGrayscale = genGrayscale

local function refreshProc(e)
    term.redirect(wAll)
    local w,h = term.getSize()
    --for i = 0, 15 do term.setPaletteColor(2^i, term.nativePaletteColor(2^i)) end
    local topwin
    local oTime = os.epoch("utc")
    local nTime = oTime
    for p=0,#proc do
        cProc = p
        local oProcTime = os.epoch("utc")
        if proc[p] == nil then break end
        proc[p].id = p
        local process = proc[p]
        if not process.hasHook then
            debug.sethook(process[1], hook, "", 50)
        end
        if process.win ~= nil then
            if not process.owin then
                process.owin = process.win
            end
            term.redirect(process.owin)
            if process.winMode == "fullscreen" and process.minimized then
                process.win.setVisible(false)
            end
        else
            term.redirect(lOS.depWin)
        end
        -- filter events
        local cWin
        lOS.cWin = nil
        local n = #lOS.wins
        while lOS.wins[n] ~= nil do
            if lOS.wins[n] == process then
                cWin = n
                lOS.cWin = cWin
                break
            else
                n = n-1
            end
        end
        local alreadydone = false
        if e[1] == "levelos_force_resume" then
            alreadydone = true
            --_G.debugforceresume = e
            if process.systemYield == e[2] then
                --_G.debugforceres = e
                local cSuccess, cFilter = coroutine.resume(process[1], table.unpack(e, 1, e.n))
                if cSuccess then
                    process.sFilter = cFilter
                elseif process == lOS.system or process == lOS.systemUI then
                    _G.theSystemError = cFilter
                    error(cFilter, 0)
                end
            end
        elseif (e[1] == "http_success" or e[1] == "http_failure") and requestCache then
            if not requestCache[e[2]] then
                lOS.notification("Error!", "Invalid request to "..e[2])
                break
            else
                --alreadydone = true
                break
            end
        elseif process == lOS.focusWin or not (e[1] == "key" or e[1] == "key_up" or e[1] == "char" or e[1] == "paste" or e[1] == "terminate" or e[1] == "term_resize" or (sysTimer and e[1] == "timer" and e[2] == sysTimer and process ~= lOS.system)) then
            local a = lUtils.instantiate(e)
            if string.find(a[1],"mouse") and ((a[1] ~= "mouse_up" and a[1] ~= "mouse_drag") or process == lOS.focusWin) and process.winMode ~= "background" and cWin and e[4] and e[4] < h-(lOS.tbSize-1) then
                local winX,winY = process.win.getPosition()
                local winW,winH = process.win.getSize()
                if (e[3] >= winX and e[4] >= winY and e[3] < winX+winW and e[4] < winY+winH) or (process.winMode == "windowed" and e[3] >= winX-1 and e[4] >= winY-1 and e[3] < winX+winW+1 and e[4] < winY+winH+1) then -- actually it does work
                    if topwin == nil then
                        topwin = process
                        if not (e[3] >= winX and e[4] >= winY and e[3] < winX+winW and e[4] < winY+winH) then
                            topwin = nil
                        end
                    else
                        for b=0,#lOS.wins do
                            if lOS.wins[b] == process then
                                break
                            elseif lOS.wins[b] == topwin then
                                topwin = process
                                if not (e[3] >= winX and e[4] >= winY and e[3] < winX+winW and e[4] < winY+winH) then
                                    --lOS.notification("Detected border press! Topwin canceled.")
                                    topwin = nil
                                end
                                break
                            end
                        end
                    end
                elseif process.winMode == "widget" and e[1] == "mouse_click" then
                    process[1] = coroutine.create(function() return end)
                end
            elseif not string.find(a[1],"mouse") and not (lOS.noEvents and process == lOS.focusWin and (e[1] == "key" or e[1] == "key_up" or e[1] == "char" or e[1] == "paste" or e[1] == "terminate" or e[1] == "term_resize")) then
                if not (process.events and process.events == "all") then
                    alreadydone = true
                    resumeProcess(process, e)
                end
            end
        end
        if e[1] ~= "levelos_force_resume" and process.events and process.events == "all" and not alreadydone then
            if not (process.sFilter and process.sFilter ~= e[1]) then
                resumeProcess(process, e)
            end
        end
        if process.win then
            process.owin = term.current()
        end
        local nProcTime = os.epoch("utc")
        if topwin ~= process then
            if not process.timeCounter then
                process.timeCounter = 0
            end
            process.timeCounter = process.timeCounter+(nProcTime-oProcTime)
            nTime = nTime+(nProcTime-oProcTime)
        end
    end
    if lOS.noEvents then
        topwin = nil
    end
    if requestCache and (e[1] == "http_success" or e[1] == "http_failure") and requestCache[e[2]] then
        local req = requestCache[e[2]]
        requestCache[e[2]] = nil
        local ev = table.pack(table.unpack(e, 1, e.n))
        ev[2] = req.url
        if e[1] == "http_success" and not req.binary then
            ev[3] = {}
            for k,v in pairs(e[3]) do
                ev[3][k] = function(...) return lOS.utf8.decodeAll(v(lOS.utf8.encodeAll(...))) end
            end
        end
        cProc = req.process.id
        local process = req.process
        local oterm = term.current()
        if process.win ~= nil then
            if not process.owin then
                process.owin = process.win
            end
            term.redirect(process.owin)
            if process.winMode == "fullscreen" and process.minimized then
                process.win.setVisible(false)
            end
        else
            term.redirect(lOS.depWin)
        end
        resumeProcess(process, ev)
        term.redirect(oterm)
        if not lOS.reqlog then lOS.reqlog = {} end
        req.event = ev
        table.insert(lOS.reqlog, req)
    elseif e[1] ~= "levelos_force_resume" and topwin ~= nil then
        term.redirect(topwin.owin)
        local winX,winY = topwin.win.getPosition()
        if topwin.owin ~= topwin.win and topwin.owin.getPosition then
            local winX2,winY2 = topwin.owin.getPosition()
            winX = winX+(winX2-1)
            winY = winY+(winY2-1)
        end
        local winW,winH = topwin.owin.getSize()
        local a = lUtils.instantiate(e)
        a[3] = a[3]-winX+1
        a[4] = a[4]-winY+1
        if not (topwin.events and topwin.events == "all") then
            if not (topwin.sFilter and topwin.sFilter ~= a[1] and topwin.sFilter ~= "terminate") then
                local cWin
                lOS.cWin = nil
                local n = #lOS.wins
                while lOS.wins[n] ~= nil do
                    if lOS.wins[n] == topwin then
                        cWin = n
                        lOS.cWin = cWin
                        break
                    else
                        n = n-1
                    end
                end
                local oProcTime = os.epoch("utc")
                cProc = topwin.id
                resumeProcess(topwin, a)
                topwin.owin = term.current()
                local nProcTime = os.epoch("utc")
                if not topwin.timeCounter then
                    topwin.timeCounter = 0
                end
                topwin.timeCounter = topwin.timeCounter+(nProcTime-oProcTime)
                nTime = nTime+(nProcTime-oProcTime)
            end
        end
        if topwin.title ~= nil then
            --lOS.notification("You clicked on process "..topwin.title)
        end
    end
    cProc = 0
    for w=0,#lOS.wins do
        while lOS.wins[w] ~= nil and lOS.wins[w].winMode == "background" do
            table.remove(lOS.wins,w)
        end
    end

    if lOS.focusWin and lOS.focusWin.winMode == "fullscreen" then
        local win = lOS.focusWin.win
        term.redirect(oldterm)
        local winW,winH = win.getSize()
        local winX,winY = win.getPosition()
        local totW,totH = oldterm.getSize()
        if not lOS.focusWin.fullscreen then
            lOS.focusWin.fullscreen = {pos={winX,winY},size={winW,winH}}
        end
        if winX ~= 1 or winY ~= 1 or winW ~= totW or winH ~= totH or isFullscreen == false then
            win.reposition(1,1,totW,totH,oldterm)
            win.setVisible(true)
            os.queueEvent("term_resize")
            if not isFullscreen then
                win.redraw()
                isFullscreen = true
                tbSize = lOS.tbSize
                lOS.tbSize = 0
            end
        end
    else
        if tbSize then
            lOS.tbSize = tbSize
            tbSize = nil
        end
        term.redirect(wAll)
        --[[local twrite = term.write
        local tblit = term.blit
        function term.write(...)
            if ({term.getCursorPos()})[2] <= ({term.getSize()})[2] then
                return twrite(...)
            end
        end
        function term.blit(...)
            if ({term.getCursorPos()})[2] <= ({term.getSize()})[2] then
                return tblit(...)
            end
        end]]
        for w=0,#lOS.wins do
            log("Processing window "..w)
            local winW,winH = lOS.wins[w].win.getSize()
            local winX,winY = lOS.wins[w].win.getPosition()
            if w == lOS.focusWin and previewrect ~= nil then
                term.setCursorPos(previewrect.x,previewrect.y)
                term.setTextColor(colors.lightBlue)
                for a=1,previewrect.w do
                    term.setBackgroundColor(lUtils.toColor(({getPixel(wAll,previewrect.x+(a-1),previewrect.y)})[3]))
                    term.write("\129")
                end
                for a=1,previewrect.h do
                    term.setBackgroundColor(lUtils.toColor(({getPixel(wAll,previewrect.x,previewrect.y+(a-1))})[3]))
                    term.setCursorPos(previewrect.x,previewrect.y+(a-1))
                    term.write("\132")
                    term.setBackgroundColor(lUtils.toColor(({getPixel(wAll,previewrect.x+(previewrect.w-1),previewrect.y+(a-1))})[3]))
                    term.setCursorPos(previewrect.x+(previewrect.w-1),previewrect.y+(a-1))
                    term.write("\136")
                end
                term.setCursorPos(previewrect.x,previewrect.y+(previewrect.h-1))
                for a=1,previewrect.w do
                    term.setBackgroundColor(lUtils.toColor(({getPixel(wAll,previewrect.x+(a-1),previewrect.y+(previewrect.h-1))})[3]))
                    term.write("\144")
                end
            end
            if lOS.wins[w].winMode == "fullscreen" and w ~= lOS.focusWin then
                -- minimize
                os.queueEvent("window_minimize",w,tostring(lOS.wins[w]))
            elseif lOS.wins[w].winMode == "screen" then
                for l=1,winH do
                    term.setCursorPos(1,l)
                    term.blit(lOS.wins[w].win.getLine(l))
                end
            elseif lOS.wins[w].winMode == "borderless" or lOS.wins[w].winMode == "widget" then
                --log("Drawing borderless window "..w.." from line "..(winY-winY+1).." to "..((winY+(winH-1))-winY+1))
                for l=winY,winY+(winH-1) do
                    term.setCursorPos(winX,l)
                    term.blit(lOS.wins[w].win.getLine(l-winY+1))
                end
            elseif lOS.wins[w].winMode == "windowed" then
                local width = winW+2
                local height = winH+2
                winX = winX-1
                winY = winY-1
                local bPos = 1
                --local w,h = wAll.getSize()
                local wW,wH = wAll.getSize()
                if (winX + (width-1)) > wW then
                --if lOS.wins[w].maximized == true then
                    bPos = 0
                end
                local wincolor = colors.lightGray
                if lOS.wins[w].winColor then
                    wincolor = lOS.wins[w].winColor
                elseif lOS.wins[w] == lOS.focusWin and not (lOS.noEvents and lOS.noEvents ~= 2) then
                    wincolor = colors.gray
                end
                term.setBackgroundColor(wincolor)
                term.setCursorPos(winX,winY)
                for t=1,width-(10-bPos) do
                    term.write(" ")
                end
                term.setTextColor(colors.white)
                if lOS.wins[w].resizable == nil then
                    lOS.wins[w].resizable = true
                end
                term.setTextColor(colors.white)
                if lOS.wins[w] == lOS.focusWin and not (lOS.noEvents and lOS.noEvents ~= 2) then
                    if wButton == 1 then
                        term.setBackgroundColor(colors.lightGray)
                    else
                        term.setBackgroundColor(wincolor)
                    end
                    term.write(" - ")
                    if wButton == 2 then
                        term.setBackgroundColor(colors.lightGray)
                    else
                        term.setBackgroundColor(wincolor)
                    end
                    if lOS.wins[w].resizable == false then
                        term.setTextColor(colors.lightGray)
                    else
                        term.setTextColor(colors.white)
                    end
                    term.write(" + ")
                    term.setTextColor(colors.white)
                    if wButton == 3 then
                        term.setBackgroundColor(colors.red)
                    else
                        term.setBackgroundColor(wincolor)
                    end
                    term.write(" × ")
                    term.setBackgroundColor(wincolor)
                else
                    term.setBackgroundColor(wincolor)
                    term.setTextColor(colors.gray)
                    term.write(" -  +  × ")
                end
                if bPos == 0 then
                    term.write(" ")
                end
                term.setCursorPos(winX+1,winY)
                if lOS.wins[w].icon ~= nil then
                    if type(lOS.wins[w].icon) == "table" then
                        term.blit(lOS.wins[w].icon[1],(lOS.wins[w].icon[2] or lUtils.toBlit(term.getBackgroundColor())),(lOS.wins[w].icon[3] or lUtils.toBlit(term.getBackgroundColor())))
                    elseif type(lOS.wins[w].icon) == "string" then
                        term.write(lOS.wins[w].icon)
                    end
                    term.write(" ")
                end
                if lOS.wins[w].title ~= nil then
                    term.write(lOS.wins[w].title)
                end
                if lOS.wins[w].unresponsive then
                    term.write(" (Not responding)")
                end
                term.setTextColor(wincolor)
                local progWin = lOS.wins[w].win

                local lines = {}
                if lOS.wins[w].unresponsive then
                    lines = genGrayscale(progWin)
                    _G.debuglines = lines
                else
                    for i=1,height-2 do
                        lines[i] = {progWin.getLine(i)}
                    end
                end

                local function pixel(x, y)
                    return lines[y][1]:sub(x,x), lines[y][2]:sub(x,x), lines[y][3]:sub(x,x)
                end


                for i=1,height-2 do
                    term.setCursorPos(winX,winY+i)
                    term.blit(string.char(149),lUtils.toBlit(wincolor),({pixel(1,i)})[3])
                    term.blit(table.unpack(lines[i]))
                    term.blit(string.char(149),({pixel(width-2,i)})[3],lUtils.toBlit(wincolor))
                end
                local bottomline = {string.char(138),({pixel(1,height-2)})[3],lUtils.toBlit(wincolor)}
                for i=1,width-2 do
                    bottomline[1] = bottomline[1]..string.char(143)
                    bottomline[2] = bottomline[2]..({pixel(i,height-2)})[3]
                    bottomline[3] = bottomline[3]..lUtils.toBlit(wincolor)
                end
                bottomline[1] = bottomline[1]..string.char(133)
                bottomline[2] = bottomline[2]..({pixel(width-2,height-2)})[3]
                bottomline[3] = bottomline[3]..lUtils.toBlit(wincolor)
                term.setCursorPos(winX,winY+(height-1))
                term.blit(table.unpack(bottomline))
            else
                log("Something went wrong with window "..w)
            end
        end
        for w=0,#proc do
            if proc[w].env ~= nil and proc[w].env.LevelOS ~= nil and proc[w].env.LevelOS.overlay ~= nil then
                coroutine.resume(coroutine.create(proc[w].env.LevelOS.overlay))
            end
        end
        local w,h = term.getSize()
        term.setCursorPos(1,1)
        --[[if #lOS.notifications > 0 then
            term.setBackgroundColor(colors.orange)
            term.setTextColor(colors.white)
            lUtils.textbox(lOS.notifications[1].txt,w-20,h-7,w,h-5)
        end]]
        term.redirect(oldterm)
        if lOS.focusWin then
            for i = 0, 15 do term.setPaletteColor(2^i, lOS.focusWin.win.getPaletteColor(2^i)) end
        end
        --local w,h = oldterm.getSize()
        --term.setBackgroundColor(colors.orange)
        --term.setTextColor(colors.white)
        --lOS.boxClear(w-20,h-7,w,h-5)
        --term.setCursorPos(w-19,h-6)
        --term.write(textutils.serialize(lOS.wins))
        --term.write("Yooo")
        --term.redirect(oldterm)
        for l=1,({wAll.getSize()})[2] do
            if isFullscreen or oldwin[l] == nil or lUtils.compare(oldwin[l],{wAll.getLine(l)}) == false then
                term.setCursorPos(1,l)
                oldwin[l] = {wAll.getLine(l)}
                term.blit(unpack(oldwin[l]))
            end
        end
        if isFullscreen then
            isFullscreen = false
        end
        --[[for t=1,h do
            oldwin[t] = {wAll.getLine(t)}
        end]]

        --term.setCursorPos(1,1)
        --term.setBackgroundColor(colors.black)
        --term.setTextColor(colors.white)
        --write(lOS.log)
        --[[taskbar(e)]]
        --for i = 0, 15 do term.setPaletteColor(2^i, term.nativePaletteColor(2^i)) end
    end
    lOS.nYieldTime = lOS.nYieldTime+(nTime-oTime)
    lOS.eventsPassed = lOS.eventsPassed+1
    if os.epoch("utc") >= oYieldTime+5000 then
        lOS.yieldTime = lOS.nYieldTime/lOS.eventsPassed
        for i,process in ipairs(lOS.processes) do
            if process.timeCounter then
                process.yieldTime = process.timeCounter/lOS.eventsPassed
                process.timeCounter = 0
            end
        end
        lOS.nYieldTime = 0
        lOS.eventsPassed = 0
        oYieldTime = os.epoch("utc")
    end
end

local holding = {}

if lUtils then
    lUtils.isHolding = nil
end

local function manage()
    if lUtils ~= nil and lUtils.isHolding == nil then
        function lUtils.isHolding(key)
            if type(key) == "string" then
                key = keys[key]
            end
            if holding[key] == nil or holding[key] == false then
                return false
            else
                return true
            end
        end
    end
    local dragging
    local dragon = false -- i can not come up with more variable names ffs
    local dragSide
    local dragX,dragY = false,false
    local DRx,DRy
    local OGw,OGh
    local OGx,OGy
    while true do
        if lOS.focusWin then
            local tempX,tempY = lOS.focusWin.win.getPosition()
            local tempW,tempH = lOS.focusWin.win.getSize()
            local tempX2,tempY2 = (tempX-1)+({lOS.focusWin.win.getCursorPos()})[1],(tempY-1)+({lOS.focusWin.win.getCursorPos()})[2]
            if tempY2 <= ({term.getSize()})[2] and tempX2 >= tempX and tempY2 >= tempY and tempX2 <= tempX+(tempW-1) and tempY2 <= tempY+(tempH-1) then
                lOS.focusWin.win.restoreCursor()
                term.setCursorBlink(lOS.focusWin.win.getCursorBlink())
                term.setCursorPos(tempX2,tempY2)
                term.setTextColor(lOS.focusWin.win.getTextColor())
            else
                term.setCursorBlink(false)
            end
        end
        for t=1,#lOS.processes do
            if coroutine.status(lOS.processes[t][1]) == "dead" then
                local win
                for n=1,#lOS.wins do
                    if lOS.wins[n] == lOS.processes[t] then
                        --table.remove(lOS.wins,n)
                        win = n
                        break
                    end
                end
                if win and not lOS.wins[win].isClosing then
                    if not lOS.sysUIlog then
                        lOS.sysUIlog = {}
                    end
                    table.insert(lOS.sysUIlog,"Closed win "..t.." because the process died.")
                    os.queueEvent("window_close",win,tostring(lOS.wins[win]),"system closed cuz ded")
                    lOS.wins[win].isClosing = true
                else
                    table.remove(lOS.processes,t)
                    break
                end
            end
        end
        if lOS.focusWin then
            for i = 0, 15 do term.setPaletteColor(2^i, lOS.focusWin.win.getPaletteColor(2^i)) end
        end
        local e = table.pack(os.pullEventRaw())

        local systemPresent = false
        local sysUIPresent = false
        for p=1,#lOS.processes do
            if lOS.processes[p] == lOS.system then
                systemPresent = true
            elseif lOS.processes[p] == lOS.sysUI then
                sysUIPresent = true
            end
        end
        if not systemPresent then
            error("CRITICAL_PROCESS_DIED",0)
        elseif lOS.sysUI and lOS.sysUI.env and not sysUIPresent then
            error("SystemUI: CRITICAL_PROCESS_DIED",0)
        end
        if e[1] == "term_resize" then
            local w1,h1 = term.getSize()
            local w2,h2 = lOS.wAll.getSize()
            if w1 ~= w2 or h1 ~= h2 then
                lOS.wAll.reposition(1,1,w1,h1)
                lOS.depWin.reposition(1,1,w1,h1)
                oldwin = {}
                local totalW,totalH = lOS.wAll.getSize()
                if lOS.tbSize then
                    totalH = totalH-lOS.tbSize
                end
                lOS.wins[0].win.reposition(1,1,w1,h1)
                for i,win in ipairs(lOS.wins) do
                    local oldX, oldY = win.win.getPosition()
                    local oldWidth, oldHeight = win.win.getSize()
                    local newX, newY
                    local newWidth, newHeight

                    if win.snap then
                        if win.snap.x then
                            newWidth = totalW
                        end

                        if win.snap.y then
                            if win.winMode == "windowed" then
                                newHeight = totalH-1
                            else
                                newHeight = totalH
                            end
                        end
                    end

                    local width, height = newWidth or oldWidth, newHeight or oldHeight

                    if oldX >= totalW or oldY >= totalH or oldX+width-1 <= 1 or oldY+height-1 <= 1 then
                        newX, newY = 4,4
                    end

                    win.win.reposition(newX or oldX, newY or oldY, width, height)
                end
            end
        end
    if e[1] == "paste" and e[2] == " " then
        e[2] = ""
    end
        if e[1] == "key" then
            holding[e[2]] = true
        elseif e[1] == "key_up" then
            holding[e[2]] = false
        end
        --for i = 0, 15 do term.setPaletteColor(2^i, term.nativePaletteColor(2^i)) end
        if e[1] == "mouse_move" then
            hX,hY = e[3],e[4]
        end
        local tempW,tempH = term.getSize()
        if string.find(e[1],"mouse") and (e[3] ~= nil and e[4] <= (tempH-lOS.tbSize)) and not lOS.noEvents then
            local focusWin = 0
            for t=1,#lOS.wins do
                local winX,winY = lOS.wins[t].win.getPosition()
                local winW,winH = lOS.wins[t].win.getSize()
                local w,h = wAll.getSize()
                if lOS.tbSize then
                    h = h-lOS.tbSize
                end
                if (e[3] >= winX and e[4] >= winY and e[3] < winX+winW and e[4] < winY+winH) or (lOS.wins[t].winMode == "windowed" and e[3] >= winX-1 and e[4] >= winY-1 and e[3] < winX+winW+1 and e[4] < winY+winH+1) then -- fixed
                    focusWin = t
                end
            end
            local bPos = 1
            local tempwin = lOS.wins[focusWin]
            local winX,winY = tempwin.win.getPosition()
            local winW,winH = tempwin.win.getSize()
            local totalW,totalH = lOS.wAll.getSize()
            if lOS.tbSize then
                totalH = totalH-lOS.tbSize
            end
            if winX+(winW-1) >= totalW --[[tempwin.maximized ~= nil and tempwin.maximized == true]] then
                bPos = 0
            end
            if e[1] == "mouse_click" and focusWin > 0 and (tempwin ~= lOS.focusWin) then
                table.remove(lOS.wins,focusWin)
                lOS.wins[#lOS.wins+1] = tempwin
                lOS.focusWin = tempwin
            end
            if e[1] == "mouse_drag" and dragging ~= nil then
                local winX,winY = dragging.win.getPosition()
                local winW,winH = dragging.win.getSize()
                if dragon == true then
                    if dragging.snap and (dragging.snap.x and dragging.snap.y) then
                        local rx = (DRx-(winX-1))/(winW-9)
                        winX = e[3]-math.ceil(rx*(dragging.snap.oSize[1]-9))
                        winW = dragging.snap.oSize[1]
                        winH = dragging.snap.oSize[2]
                        dragging.snap = nil
                        OGx,OGy = winX,winY
                    else
                        winX = OGx-(DRx-e[3])
                    end
                    if dragging.snap and dragging.snap.y then
                        if DRy-e[4] <= -2 then
                            winY = OGy-(DRy-e[4])
                            dragging.snap = nil
                            dragging.win.reposition(winX,winY,winW,h-7)
                        end
                    else
                        winY = OGy-(DRy-e[4])
                    end

                    local w,h = totalW,totalH

                    -- ALL THE RIGHT SIDE STUFF IS TEMP, TO SEE WHAT POSITION IT SHOULD BE ON. IT SHOULD BE RELATIVE TO THE SIZE OF A POTENTIAL LEFT SIDE SPLITSCREENED WINDOW

                    if e[3] == w and e[4] == 1 then
                        previewrect = {x=math.ceil(w/2)+1,y=2,w=math.floor(w/2)-1,h=math.floor((h)/2)-2}
                    elseif e[3] == w and e[4] == h then
                        previewrect = {x=math.ceil(w/2)+1,y=math.floor((h)/2)+2,w=math.floor(w/2)-1,h=math.floor((h)/2)-2}
                    elseif e[3] == w then
                        previewrect = {x=math.ceil(w/2)+1,y=2,w=math.floor(w/2)-1,h=h-2}


                    elseif e[3] == 1 and e[4] == 1 then
                        previewrect = {x=2,y=2,w=math.floor(w/2)-2,h=math.floor((h)/2)-2}
                    elseif e[3] == 1 and e[4] == h then
                        previewrect = {x=2,y=math.floor((h)/2)+2,w=math.floor(w/2)-2,h=math.floor((h)/2)-2}
                    elseif e[3] == 1 then
                        previewrect = {x=2,y=2,w=math.floor(w/2)-2,h=h-2}
                    elseif e[4] == 1 then
                        --previewrect = {x=2,y=2,w=w-2,h=h-4}
                    else
                        previewrect = nil
                    end
                end
                if dragX == true then
                    if dragSide == 1 then
                        if OGw+(DRx-e[3]) >= 10 then
                            winW = OGw+(DRx-e[3])
                            winX = OGx-(DRx-e[3])
                        end
                    else
                        if OGw-(DRx-e[3]) >= 10 then
                            winW = OGw-(DRx-e[3])
                        end
                    end
                end
                if dragY == true then
                    if OGh-(DRy-e[4]) >= 4 then
                        winH = OGh-(DRy-e[4])
                    end
                end
                local wW,wH = dragging.win.getSize()
                local resized = false
                if wW ~= winW or wH ~= winH then
                    resized = true
                end
                dragging.win.reposition(winX,winY,winW,winH)
                if resized then
                    os.queueEvent("term_resize")
                end
            end
            local winX,winY = tempwin.win.getPosition()
            local winW,winH = tempwin.win.getSize()
            if focusWin > 0 then
                if tempwin.winMode == "windowed" and (e[1] == "mouse_click" or e[1] == "mouse_up") then
                    if e[4] == winY-1 then
                        if e[3] <= bPos+winX+winW-1 and e[3] >= bPos+winX+winW-3 then
                            if e[1] == "mouse_click" then
                                wButton = 3
                            else
                                os.queueEvent("window_close",focusWin,tostring(tempwin),"system closed cuz button click")
                            end
                        elseif e[3] <= bPos+winX+winW-4 and e[3] >= bPos+winX+winW-6 then
                            if e[1] == "mouse_click" then
                                wButton = 2
                            elseif (tempwin.resizable == nil or tempwin.resizable == true) then
                                if tempwin.snap then
                                    --tempwin.win.reposition(tempwin.snap.oPos[1],tempwin.snap.oPos[2],unpack(tempwin.snap.oSize))
                                    os.queueEvent("window_reposition",focusWin,tostring(tempwin),tempwin.snap.oPos[1],tempwin.snap.oPos[2],unpack(tempwin.snap.oSize))
                                    tempwin.snap = nil
                                else
                                    tempwin.snap = {x=true,y=true,oPos={tempwin.win.getPosition()},oSize={tempwin.win.getSize()}}
                                    --tempwin.win.reposition(1,2,totalW,totalH-1)
                                    os.queueEvent("window_reposition",focusWin,tostring(tempwin),1,2,totalW,totalH-1)
                                end
                                --os.queueEvent("term_resize")
                            end
                        elseif e[3] <= bPos+winX+winW-7 and e[3] >= bPos+winX+winW-9 then
                            if e[1] == "mouse_click" then
                                wButton = 1
                            else
                                --oop im dumb

                                -- why tf would u do this
                                --[[local n=-1
                                while lOS.wins[n] ~= nil do
                                    n = n-1
                                end
                                lOS.wins[n] = tempwin]]
                                --lOS.wins[#lOS.wins] = nil
                                os.queueEvent("window_minimize",focusWin,tostring(tempwin))
                                -- plz work
                            end
                        elseif e[1] == "mouse_click" then
                            if tempwin.dragtimestamp and tempwin.dragtimestamp+500 > os.epoch("utc") then
                                if tempwin.snap then
                                    os.queueEvent("window_reposition",focusWin,tostring(tempwin),tempwin.snap.oPos[1],tempwin.snap.oPos[2],unpack(tempwin.snap.oSize))
                                else
                                    tempwin.snap = {x=true,y=true,oPos={tempwin.win.getPosition()},oSize={tempwin.win.getSize()}}
                                    --tempwin.win.reposition(1,2,totalW,totalH-1)
                                    os.queueEvent("window_reposition",focusWin,tostring(tempwin),1,2,totalW,totalH-1)
                                end
                            else
                                dragging = tempwin
                                dragging.dragtimestamp = os.epoch("utc")
                                dragon = true
                                DRx,DRy = e[3],e[4]
                                OGx,OGy = winX,winY
                            end
                        end
                    end
                    if e[4] >= winY and e[4] <= winY+winH and (e[3] == winX-1 or e[3] == winX+winW) and e[1] == "mouse_click" and (tempwin.resizable == nil or tempwin.resizable == true) then
                        dragging = tempwin
                        DRx = e[3]
                        OGw = winW
                        OGx = winX
                        dragX = true
                        if e[3] == winX-1 then
                            dragSide = 1
                        else
                            dragSide = 2
                        end
                    end
                    if e[4] == winY+(winH) and e[3] >= winX-1 and e[3] <= winX+(winW) and e[1] == "mouse_click" and (tempwin.resizable == nil or tempwin.resizable == true) then
                        dragY = true
                        DRy = e[4]
                        OGh = winH
                        dragging = tempwin
                    end
                end
            end
            if e[1] == "mouse_up" then
                if dragon == true then
                    local w,h = totalW,totalH
                    dragging.snap = {x=false,y=true,oPos={dragging.win.getPosition()},oSize={dragging.win.getSize()}}
                    if e[3] == w and e[4] == 1 then
                        os.queueEvent("window_reposition",focusWin,tostring(tempwin),math.ceil(w/2)+1,2,math.floor(w/2),math.floor((h)/2)-2)
                        -- whenever im not super lazy, make this window 1 pixel higher on the bottom and then don't draw the bottom line. that way it connects nicely to the window below.
                    elseif e[3] == w and e[4] == h then
                        os.queueEvent("window_reposition",focusWin,tostring(tempwin),math.ceil(w/2)+1,math.floor((h)/2)+2,math.floor(w/2),math.floor((h)/2)-1)
                    elseif e[3] == w then
                        os.queueEvent("window_reposition",focusWin,tostring(tempwin),math.ceil(w/2)+1,2,math.floor(w/2),h-1)
                    elseif e[3] == 1 and e[4] == 1 then
                        os.queueEvent("window_reposition",focusWin,tostring(tempwin),1,2,math.floor(w/2)-1,math.floor((h)/2)-2)
                    elseif e[3] == 1 and e[4] == h then
                        os.queueEvent("window_reposition",focusWin,tostring(tempwin),1,math.floor((h)/2)+2,math.floor(w/2)-1,math.floor((h)/2)-1)
                    elseif e[3] == 1 then
                        os.queueEvent("window_reposition",focusWin,tostring(tempwin),1,2,math.floor(w/2)-1,h-1)
                    else
                        dragging.snap = nil
                    end
                    os.queueEvent("term_resize")
                end
                previewrect = nil
                dragon = false
                dragging = nil
                dragX,dragY = false,false
                wButton = 0
            end
        end
        if e[1] == "key_up" and lUtils.isHolding(keys.leftCtrl) and e[2] == keys.w and #lOS.wins > 0 and lOS.focusWin and lOS.focusWin ~= lOS.wins[0] and not lOS.focusWin.noShortcuts then
            local focusWin
            for t=#lOS.wins,1,-1 do
                if lOS.wins[t] == lOS.focusWin then
                    focusWin = t
                    break
                end
            end
            os.queueEvent("window_close",focusWin,tostring(lOS.focusWin),"system closed cuz ctrl + w")
        elseif e[1] ~= "mouse_move" or e[3] ~= nil then
            refreshProc(e)
        end
    end
end




local hover = false
function lOS.isHover()
    return hover
end



local function hoverevent()
    local timerID = os.startTimer(3)
    while true do
        e = table.pack(os.pullEventRaw("mouse_move"))
        if e[1] == "mouse_move" then
            os.cancelTimer(timerID)
            timerID = os.startTimer(3)
            hX,hY = e[3],e[4]
            hover = false
        elseif e[1] == "timer" and e[2] == timerID then
            os.queueEvent("mouse_hover",1,hX,hY)
            log("Hovering at "..hX..","..hY)
            hover = true
        end
    end
end
lOS.notifWins = {}
function lOS.notification(title,txt,programpath,duration)
    lOS.notifications[#lOS.notifications+1] = {title,txt,programpath,duration}

    local w,h = lOS.wAll.getSize()
    local y = h-5-lOS.tbSize
    local continue = false
    while not continue do
        continue = true
        for k,v in pairs(lOS.notifWins) do
            if coroutine.status(v[1]) ~= "dead" then
                local c1 = false
                for k1,v1 in pairs(lOS.processes) do
                    if v1 == v then
                        c1 = true
                    end
                end
                if c1 == false then
                    lOS.notifWins[k] = nil
                else
                    local tx,ty = v.win.getPosition()
                    if ty-6 <= y then
                        y = ty-6
                    end
                end
            else
                lOS.notifWins[k] = nil
            end
        end
    end
    lOS.execute({"LevelOS/Notification.lua",title,txt,programpath,duration},"widget",w-31,y,32,5,false)
end
--parallel.waitForAny(manage,notifications,hoverevent)
manage()