local assets = {
  [ "background.lua" ] = {
    id = 8,
    name = "background.lua",
    content = "-- render bg\
\
os.sleep(0.5)\
ogP = {}\
local s = shapescape.getSlide()\
for a=2,4 do\
    ogP[a] = s.objs[a].oy1\
end\
\
while true do\
    -- render bg if app changes\
    local e = {os.pullEvent()}\
    if e[1] == \"mouse_scroll\" then\
        for a=2,4 do\
            if s.objs[a].oy1+e[2] >= ogP[a] then\
                s.objs[a].oy1 = s.objs[a].oy1+e[2]\
                if a ~= 2 then\
                    s.objs[a].oy2 = s.objs[a].oy2+e[2]\
                end\
            end\
        end\
    end\
end\
            ",
  },
  [ "updatething.lua" ] = {
    id = 10,
    name = "updatething.lua",
    content = "local s = shapescape.getSlide()\
if s.updateFunc then\
\9s.updateFunc()\
\9s.updateFunc = nil\
end",
  },
  [ "mainscreen.lua" ] = {
    id = 2,
    name = "mainscreen.lua",
    content = "function doYourThing()\
local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
local hpost = http.post\
local function download(name,pth,saveto,run)\
\9local f = hpost(\"https://old.leveloper.cc/sGet.php\",\"path=\"..textutils.urlEncode(pth)..\"&\"..rType..\"=\"..textutils.urlEncode(name),{Cookie=lOS.userID}).readAll()\
\9if f and f ~= \"409\" and f ~= \"403\" and f ~= \"401\" then\
\9\9if run then\
\9\9\9return f\
\9\9else\
\9\9\9lUtils.fwrite(saveto,f)\
\9\9\9return true\
\9\9end\
\9else\
\9\9return false\
\9end\
end\
local function get(name)\
\
\9--write(\"Connecting to LevelStore... \")\
\
\9rType = \"code\"\
\9local response, err = http.post(\"https://old.leveloper.cc/sGet.php\",\"path=\"..textutils.urlEncode(\"\")..\"&code=\"..textutils.urlEncode(name),{Cookie=lOS.userID})\
\
\9if not response then\
\9\9rType = \"name\"\
\9\9response, err = http.post(\"https://old.leveloper.cc/sGet.php\",\"path=\"..textutils.urlEncode(\"\")..\"&name=\"..textutils.urlEncode(name),{Cookie=lOS.userID})\
\9end\
\
\9if response then\
\9\9local tree = {}\
\9\9local folders = {}\
\9\9local function searchFolder(folder)\
\9\9\9--print(\"Searching folder root/\"..folder)\
\9\9\9local f = hpost(\"https://old.leveloper.cc/sGet.php\",\"path=\"..textutils.urlEncode(folder)..\"&\"..rType..\"=\"..textutils.urlEncode(name),{Cookie=lOS.userID}).readAll()\
\9\9\9--print(f)\
\9\9\9local f2 = f\
\9\9\9while true do\
\9\9\9\9local file = nil\
\9\9\9\9file,f = lUtils.getField(f,\"file\")\
\9\9\9\9if not file then\
\9\9\9\9\9break\
\9\9\9\9else\
\9\9\9\9\9local name = lUtils.getField(file,\"name\")\
\9\9\9\9\9tree[#tree+1] = fs.combine(folder,name)\
\9\9\9\9\9--print(\"Found \"..fs.combine(folder,name))\
\9\9\9\9end\
\9\9\9end\
\9\9\9f = f2\
\9\9\9while true do\
\9\9\9\9local file = nil\
\9\9\9\9file,f = lUtils.getField(f,\"folder\")\
\9\9\9\9if not file then\
\9\9\9\9\9break\
\9\9\9\9else\
\9\9\9\9\9local name = lUtils.getField(file,\"name\")\
\9\9\9\9\9--if not fs.exists(fs.combine(folder,name)) then\
\9\9\9\9\9\9--fs.makeDir(fs.combine(folder,name))\
\9\9\9\9\9--end\
\9\9\9\9\9folders[#folders+1] = fs.combine(folder,name)\
\9\9\9\9\9searchFolder(fs.combine(folder,name))\
\9\9\9\9end\
\9\9\9end\
\9\9\9return true\
\9\9end\
\9\9searchFolder(\"\")\
\9\9--print(\"Success.\")\
\
\9\9return tree,folders\
\9else\
\9\9printError(\"Failed.\")\
\9\9print(err)\
\9end\
end\
\
local circ = lUtils.asset.load(\"LevelOS/assets/circProgress.limg\")\
\
bigfont.writeOn(term.current(),1,\"Loading...\")\
local pth = \"Program_Files\"\
local appdata = \"AppData/lStore\"\
if not fs.exists(appdata) then\
\9fs.makeDir(appdata)\
end\
local apps = {} -- retrieve from servers\
_G.debugApps = apps\
local response,err = http.get(\"https://old.leveloper.cc/sList.php\",{Cookie=lOS.userID})\
if not response then\
\9term.setBackgroundColor(colors.black)\
\9term.clear()\
\9bigfont.writeOn(term.current(),1,err)\
\9return\
end\
local res = response.readAll()\
--local gf = lUtils.getField\
local cols = {}\
for k,v in pairs(colors) do\
\9if type(v) == \"number\" and v ~= colors.gray and v ~= colors.white and v ~= colors.black then\
\9\9table.insert(cols,v)\
\9end\
end\
local selected = {}\
while true do\
\9local p\
\9p,res = lUtils.getField(res,\"project\")\
\9if p ~= nil then\
\9\9local function gf(field)\
\9\9\9return (lUtils.getField(p,field))\
\9\9end\
\9\9local app = {code=gf(\"code\"),name=string.gsub(gf(\"title\"),\"_\",\" \"),creator=gf(\"creator\"),timestamp=gf(\"version\"),listing=gf(\"listing\")}\
\9\9if gf(\"icon\") then\
\9\9\9local icon = gf(\"icon\")\
\9\9\9if icon and textutils.unserialize(icon) then\
\9\9\9\9app.icon = textutils.unserialize(icon)[1]\
\9\9\9end\
\9\9end\
\9\9if gf(\"iconBig\") then\
\9\9\9local ico = gf(\"iconBig\")\
\9\9\9if ico and textutils.unserialize(ico) then\
\9\9\9\9app.ico = textutils.unserialize(ico)[1]\
\9\9\9end\
\9\9end\
\9\9if gf(\"background\") then\
\9\9\9app.background = gf(\"background\")\
\9\9end\
\9\9if gf(\"description\") then\
\9\9\9app.description = gf(\"description\")\
\9\9else\
\9\9\9app.description = \"<text>No description.</text>\"\
\9\9end\
\9\9app.creatorName = gf(\"creator_name\")\
\9\9if gf(\"rating\") and gf(\"ratings\") then\
\9\9\9app.rating = tonumber(gf(\"rating\"))\
\9\9\9app.ratings = tonumber(gf(\"ratings\"))\
\9\9else\
\9\9\9app.rating = 0\
\9\9\9app.ratings = 0\
\9\9end\
\9\9if gf(\"fname\") then\
\9\9\9app.fname = gf(\"fname\")\
\9\9else\
\9\9\9app.fname = string.gsub(app.name,\"%W\",\"_\")\
\9\9end\
\9\9app.verified = gf(\"verified\")\
\9\9if app.verified == \"true\" then\
\9\9\9app.verified = true\
\9\9else\
\9\9\9app.verified = false\
\9\9end\
\9\9if app.creator == \"2\" then\
\9\9\9app.verified = true\
\9\9end\
\9\9app.bg = cols[math.random(1,#cols)]\
\9\9table.insert(apps,app)\
\9else\
\9\9break\
\9end\
end\
if not fs.exists(pth) then\
\9fs.makeDir(pth)\
end\
local tCol = {bg=colors.black,txt=colors.white,txt2=colors.white,app=colors.gray,topbar=colors.black,sel=colors.blue,heart=colors.red}\
local aW,aH = 14,11\
local function path(app)\
\9return fs.combine(pth,app.fname)\
end\
sl.api = {get=get,download=download,path=path,circ=circ,tCol=tCol}\
local function textbox(txt,x1,y1,x2,y2)\
\9local x,y = x1,y1\
\9local w,h = x2-(x-1),y2-(y-1)\
\9local bg,fg = term.getBackgroundColor(),term.getTextColor()\
\9local win = window.create(term.current(),x,y,w,h,false)\
\9win.setBackgroundColor(bg)\
\9win.setTextColor(fg)\
\9win.clear()\
\9win.setCursorPos(1,1)\
\9local oterm = term.current()\
\9term.redirect(win)\
\9write(txt)\
\9term.redirect(oterm)\
\9for y=y1,y2 do\
\9\9term.setCursorPos(x1,y)\
\9\9term.blit(win.getLine(y-(y1-1)))\
\9end\
end\
local function bigWrite(txt)\
\9local x,y = term.getCursorPos()\
\9bigfont.writeOn(term.current(),1,txt,x,y)\
end\
local function rApp(app,x,y)\
\9app.x1,app.y1 = x,y\
\9app.x2,app.y2 = x+(aW-1),y+(aH-1)\
\9if app.ico then\
\9\9lUtils.renderImg(app.ico,x,y)\
\9elseif app.icon then\
\9\9term.setBackgroundColor(app.bg)\
\9\9--local w,h = term.getSize()\
\9\9for q=0,4 do\
\9\9\9term.setCursorPos(x,y+q)\
\9\9\9term.write(string.rep(\" \",aW))\
\9\9end\
\9\9lUtils.renderImg(app.icon,x+math.floor(aW/2 - 3/2),y+1)\
\9else\
\9\9term.setBackgroundColor(app.bg)\
\9\9--local w,h = term.getSize()\
\9\9for q=0,4 do\
\9\9\9term.setCursorPos(x,y+q)\
\9\9\9term.write(string.rep(\" \",aW))\
\9\9end\
\9\9term.setTextColor(colors.white)\
\9\9term.setCursorPos(x+math.ceil(aW/2)-3,y+1)\
\9\9bigWrite(string.upper(string.sub(app.name,1,2)))\
\9end\
\9if app.listing == \"unlisted\" then\
\9\9term.setTextColor(colors.lightGray)\
\9elseif app.listing == \"premium\" then\
\9\9term.setTextColor(colors.orange)\
\9else\
\9\9term.setTextColor(tCol.txt)\
\9end\
\9if selected == app then\
\9\9term.setBackgroundColor(colors.lightGray)\
\9else\
\9\9term.setBackgroundColor(tCol.app)\
\9end\
\9for q=5,aH-1 do\
\9\9term.setCursorPos(x,y+q)\
\9\9term.write(string.rep(\" \",aW))\
\9end\
\9--textbox(app.name,x+1,y+6,x+aW-2,y+7)\
\9local txt = lUtils.wordwrap(app.name, aW-2)\
\9term.setCursorPos(x+1, y+6)\
\9term.write(txt[1])\
\9term.setCursorPos(x+1, y+7)\
\9if txt[2] then\
\9\9term.write(txt[2])\
\9\9term.setCursorPos(x+1, y+8)\
\9end\
\9local creatorName = app.creatorName\
\9\
\9if creatorName == \"Noodle\" then\
\9\9creatorName = \"Leveloper\"\
\9\9term.setTextColor(colors.cyan)\
\9else\
\9\9term.setTextColor(colors.lightGray)\
\9end\
\9local creatorName = creatorName:sub(1, aW-2)\
\9term.write(creatorName)\
\9\
\9term.setCursorPos(x+1,y+aH-2)\
\9for q=1,5 do\
\9\9if math.floor(app.rating+0.5) >= q then\
\9\9\9term.setTextColor(tCol.heart)\
\9\9else\
\9\9\9term.setTextColor(colors.lightGray)\
\9\9end\
\9\9term.write(\"\\3\")\
\9end\
\9term.setTextColor(colors.lightGray)\
\9term.write(\" \"..app.ratings)\
\9term.setCursorPos(x+aW-3,y+aH-2)\
\9if fs.exists(path(app)) then\
\9\9term.setTextColor(colors.red)\
\9\9term.write(\"×\")\
\9\9term.setCursorPos(x+1,y+aH-1)\
\9\9term.setTextColor(colors.lightGray)\
\9\9term.write(\"Installed\")\
\9else\
\9\9term.setTextColor(colors.blue)\
\9\9term.write(\"\\25\")\
\9end\
end\
local scroll = 0\
\
local function matchSearch(app)\
\9if not s.var.search or s.var.search == \"\" then\
\9\9return true\
\9elseif app.name:lower():find(s.var.search:lower(), nil, true) then\
\9\9return true\
\9else\
\9\9return false\
\9end\
end\
\
local function render()\
\9term.setBackgroundColor(colors.black)\
\9term.clear()\
\9local w,h = term.getSize()\
\9local cX = 3\
\9local cY = 2\
\9for a=1,#apps do\
\9\9if (s.var.menu.id == \"home\" or (s.var.menu.id == \"verified\" and apps[a].verified) or (s.var.menu.id == \"installed\" and fs.exists(path(apps[a])))) and matchSearch(apps[a]) then\
\9\9\9--rApp(apps[a],cX,cY)\
\9\9\9if cX + (aW) >= w then\
\9\9\9\9cX = 3\
\9\9\9\9cY = cY+aH+1\
\9\9\9end\
\9\9\9rApp(apps[a],cX,cY-scroll)\
\9\9\9cX = cX+aW+2\
\9\9end\
\9end\
end\
\
function s.var.resetRender()\
\9scroll = 0\
\9os.queueEvent(\"store_render\")\
end\
\
render()\
while true do\
\9local e = {os.pullEvent()}\
\9if e[1] == \"store_render\" then\
\9\9render()\
\9elseif (e[1] == \"mouse_click\" or e[1] == \"mouse_up\") and s.var.sb and e[3] >= s.var.sidebar.x1 then\
\9\9-- nothing\
\9elseif e[1] == \"term_resize\" then\
\9\9render()\
\9elseif e[1] == \"mouse_click\" then\
\9\9local x,y = e[3],e[4]\
\9\9for k,a in ipairs(apps) do\
\9\9\9if x >= a.x1 and y >= a.y1 and x <= a.x2 and y <= a.y2 then\
\9\9\9\9selected = a\
\9\9\9\9render()\
\9\9\9end\
\9\9end\
\9elseif e[1] == \"mouse_up\" then\
\9\9local x,y = e[3],e[4]\
\9\9if selected.x2 and selected.y2 then\
\9\9\9local app = selected\
\9\9\9if x == selected.x2-2 and y == selected.y2-1 then\
\9\9\9\9local o = {lUtils.popup(\"LevelStore\",\"Do you want to install \"..selected.name..\"?\",25,9,{\"Install\",\"Cancel\"})}\
\9\9\9\9--local app = selected\
\9\9\9\9selected = {}\
\9\9\9\9render()\
\9\9\9\9if o[1] and o[3] == \"Install\" then\
\9\9\9\9\9lUtils.renderImg(circ[1],x-1,y-1)\
\9\9\9\9\9local tree,folders = get(app.code)\
\9\9\9\9\9--if not tree then return end\
\9\9\9\9\9--term.write(\"Downloading... \")\
\9\9\9\9\9--term.write(\"0%\")\
\9\9\9\9\9local sPath = path(app)\
\9\9\9\9\9if #tree > 0 or #folders > 0 then\
\9\9\9\9\9\9fs.makeDir(sPath)\
\9\9\9\9\9\9for f=1,#folders do\
\9\9\9\9\9\9\9fs.makeDir(fs.combine(sPath,folders[f]))\
\9\9\9\9\9\9end\
\9\9\9\9\9\9for f=1,#tree do\
\9\9\9\9\9\9\9download(app.code,tree[f],fs.combine(sPath,tree[f]))\
\9\9\9\9\9\9\9term.setBackgroundColor(tCol.app)\
\9\9\9\9\9\9\9term.setTextColor(tCol.txt)\
\9\9\9\9\9\9\9lUtils.renderImg(circ[math.floor(8*(f/#tree)+1.5)],x-1,y-1)\
\9\9\9\9\9\9\9--term.setCursorPos(x,y)\
\9\9\9\9\9\9\9--term.write(math.floor(99*(f/#tree)))\
\9\9\9\9\9\9end\
\9\9\9\9\9\9local b = {lUtils.popup(\"LevelStore\",\"Do you want to create a shortcut to \"..app.name..\"?\",25,9,{\"Yes\",\"No\"})}\
\9\9\9\9\9\9if b[1] and b[3] == \"Yes\" then\
\9\9\9\9\9\9\9lOS.genIco(sPath)\
\9\9\9\9\9\9end\
\9\9\9\9\9end\
\9\9\9\9\9lUtils.renderImg(circ[9],x-1,y-1)\
\9\9\9\9\9render()\
\9\9\9\9end\
\9\9\9elseif x >= app.x1 and y >= app.y1 and x <= app.x2 and y <= app.y2 then\
\9\9\9\9local slides = shapescape.getSlides()\
\9\9\9\9slides.app = app\
\9\9\9\9shapescape.setSlide(2)\
\9\9\9\9--lUtils.popup(\"LevelStore\",\"Click: \"..x..\",\"..y..\" vs \"..(selected.x2-2)..\",\"..(selected.y2-2),27,9,{\"OK\"})\
\9\9\9end\
\9\9end\
\9\9selected = {}\
\9\9render()\
\9elseif e[1] == \"mouse_scroll\" then\
\9\9if scroll+e[2] >= 0 then\
\9\9\9scroll = scroll+e[2]\
\9\9\9render()\
\9\9end\
\9end\
end\
end\
local ok,err = pcall(doYourThing)\
if not ok then\
\9printError(err)\
end\
--os.sleep(10)",
  },
  [ "Top_menu.lua" ] = {
    id = 0,
    name = "Top_menu.lua",
    content = "local s = shapescape.getSlide()\
if not s.var then\
    s.var = {}\
end\
if not s.var.theme then\
    s.var.theme = {txt=colors.white,txt2=colors.lightGray,bg=colors.gray,app=colors.gray,bb=colors.blue}\
end\
local th = s.var.theme\
local acc = {{\"\\159\\131\\139 \",\"----\",\"bbb-\"},{\" \\144\\133\\149\",\"-b0b\",\"b0b-\"},{\"\\130\\143\\135 \",\"000-\",\"----\"}}\
local src = {{\" \\159\\140\\144\",\"--00\",\"-0--\"},{\" \\154 \\154\",\"---0\",\"-0--\"},{\"\\136\\129\\131 \",\"000-\",\"----\"}}\
local function g(str)\
    return (str:gsub(\"-\",lUtils.toBlit(th.bg)))\
end\
local function blit(p)\
    term.blit(p[1],g(p[2]),g(p[3]))\
end\
s.var.menus = {{name=\"Home\", id=\"home\"},{name=\"Verified\", id=\"verified\"},{name=\"Installed\", id=\"installed\"}}\
s.var.menu = s.var.menus[1]\
local bline = {x1=2,x2=3}\
local function render()\
    term.setBackgroundColor(th.bg)\
    term.clear()\
    term.setCursorPos(1,2)\
    for t=1,#s.var.menus do\
        local m = s.var.menus[t]\
        if s.var.menu == m then\
            term.setTextColor(th.txt)\
        else\
            term.setTextColor(th.txt2)\
        end\
        term.write(\" \")\
        m.x1 = ({term.getCursorPos()})[1]\
        term.write(m.name)\
        m.x2 = ({term.getCursorPos()})[1]-1\
        term.write(\" \")\
    end\
    local m = s.var.menu\
    local function b()\
        term.setCursorPos(1,3)\
        term.setBackgroundColor(th.bg)\
        term.clearLine()\
        term.setCursorPos(bline.x1,3)\
        term.setTextColor(th.bb)\
        term.write(string.rep(\"\\131\",bline.x2-(bline.x1-1)))\
        local w,h = term.getSize()\
        for a=1,#acc do\
            --w,h = term.getSize()\
            term.setCursorPos(w-4,a)\
            blit(acc[a])\
        end\
        if not src.x then src.x = 10 end\
        for a=1,#src do\
            term.setCursorPos(w-src.x,a)\
            blit(src[a])\
        end\
        if src.x > 11 then\
            if th.bg == colors.black then\
                term.setBackgroundColor(colors.gray)\
            else\
                term.setBackgroundColor(colors.black)\
            end\
            term.setTextColor(th.bg)\
            lUtils.border((w-src.x)+4,1,w-7,3)\
            term.setCursorPos((w-src.x)+5,2)\
            term.write(string.rep(\" \",src.x-12))\
            if s.var.search then\
                term.setCursorPos((w-src.x)+5,2)\
                term.setTextColor(th.txt2)\
                term.write(string.sub(s.var.search,1,src.x-12))\
            end\
        end\
        term.setBackgroundColor(th.bg)\
    end\
    local v = 5\
    while bline.x2 < m.x2 do\
        bline.x2 = bline.x2+math.ceil((m.x2-bline.x2)/v)\
        b()\
        os.sleep(0.05)\
    end\
    while bline.x1 < m.x1 do\
        bline.x1 = bline.x1+math.ceil((m.x1-bline.x1)/v)\
        b()\
        os.sleep(0.05)\
    end\
    while bline.x1 > m.x1 do\
        bline.x1 = bline.x1-math.ceil((bline.x1-m.x1)/v)\
        b()\
        os.sleep(0.05)\
    end\
    while bline.x2 > m.x2 do\
        bline.x2 = bline.x2-math.ceil((bline.x2-m.x2)/v)\
        b()\
        os.sleep(0.05)\
    end\
    b()\
end\
render()\
local ow,oh = term.getSize()\
while true do\
    local e = {os.pullEvent()}\
    local w,h = term.getSize()\
    if e[1] == \"mouse_up\" and e[2] == 1 and e[4] == 2 then\
        for t=1,#s.var.menus do\
            local m = s.var.menus[t]\
            if e[3] >= m.x1 and e[3] <= m.x2 then\
            \9s.var.menu = {}\
            \9--s.var.resetRender()\
                s.var.menu = m\
                render()\
                --s.var.resetRender()\
            end\
        end\
        if e[3] >= w-4 and e[3] <= w-1 then\
            if s.var.sidebar and not s.var.sb then\
                table.insert(s.objs,s.var.sidebar)\
                s.var.sb = true\
            elseif s.var.sidebar and s.var.sb then\
                for o=1,#s.objs do\
                    if s.objs[o] == s.var.sidebar then\
                        table.remove(s.objs,o)\
                        s.var.sb = false\
                        break\
                    end\
                end\
            end\
        elseif e[3] >= w-src.x and e[3] <= w-7 then\
            if not src.search then\
                if w > 80 then\
                    max = 24\
                else\
                    max = 12\
                end\
                for t=1,max,2 do\
                    src.x = src.x+2\
                    render()\
                    os.sleep(0.05)\
                end\
                src.search = true\
                term.setBackgroundColor(colors.black)\
                term.setTextColor(colors.white)\
                src.box = lUtils.input((w-src.x)+5,2,w-8,2,{overflowX=\"scroll\",overflowY=\"none\"})\
            end\
            --[[local txtbox = window.create(term.current(),(w-src.x)+5,2,src.x-12,1)\
            if th.bg == colors.black then\
                txtbox.setBackgroundColor(colors.gray)\
            else\
                txtbox.setBackgroundColor(colors.black)\
            end\
            txtbox.setTextColor(colors.white)\
            txtbox.clear()\
            txtbox.setCursorPos(1,1)\
            local txtcor = coroutine.create(function() s.var.search = lUtils.read() term.setCursorBlink(false) end)\
            local oterm = term.current()\
            while coroutine.status(txtcor) ~= \"dead\" do\
                e = {os.pullEvent()}\
                render()\
                txtbox.redraw()\
                term.redirect(txtbox)\
                coroutine.resume(txtcor,unpack(e))\
                term.redirect(oterm)\
                term.setTextColor(colors.red)\
                term.setCursorBlink(true)\
            end]]\
            \
            local box = src.box\
            box.state = true\
            if #box.txt > 0 then\
            \9box.select = {1, #box.txt}\
            \9box.cursor.a = #box.txt+1\
            end\
            box.update(\"term_resize\")\
            box.render()\
            while box.state do\
            \9local e = {os.pullEvent()}\
            \9if e[1] == \"key\" and e[2] == keys.enter then\
            \9\9box.state = false\
            \9else\
            \9\9box.update(unpack(e))\
            \9\9box.render()\
            \9\9if s.var.search ~= box.txt then\
            \9\9\9s.var.search = box.txt\
            \9\9\9s.var.resetRender()\
            \9\9end\
            \9end\
            end\
            term.setCursorBlink(false)\
            render()\
            s.var.resetRender()\
            --[[else\
                while src.x > 10 do\
                    src.x = src.x-1\
                    render()\
                    os.sleep(0.05)\
                end\
                src.search = false\
            end]]\
        end\
    elseif e[1] == \"term_resize\" or w ~= ow or h ~= oh then\
        render()\
    end\
    ow,oh = w,h\
end",
  },
  [ "appPage_topbar.lua" ] = {
    id = 5,
    name = "appPage_topbar.lua",
    content = "local sl = shapescape.getSlides()\
local get = sl.api.get\
local download = sl.api.download\
local path = sl.api.path\
local s = shapescape.getSlide()\
local circSymbol = lUtils.asset.load(\"LevelOS/assets/Circle_Symbols.limg\")\
if not s.var then s.var = {} end\
while true do\
    term.setBackgroundColor(colors.lightGray)\
    term.clear()\
    --[[term.setCursorPos(4,3)\
    term.setTextColor(colors.gray)\
    term.write(sl.app.code)]]\
    if fs.exists(sl.api.path(sl.app)) then\
        lUtils.renderImg(circSymbol[2],2,2)\
        term.setBackgroundColor(colors.lightGray)\
        term.setTextColor(colors.white)\
        term.setCursorPos(8,3)\
        term.write(\"Installed\")\
    end\
    local e = {os.pullEvent()}\
    if s.var.download then\
        lUtils.renderImg(circSymbol[1],2,2)\
        term.setCursorPos(8,3)\
        term.write(\"0%\")\
        term.setCursorPos(12,3)\
        term.setTextColor(colors.white)\
        term.setBackgroundColor(colors.lightGray)\
        local w,h = term.getSize()\
        for t=12,w-14 do\
            term.write(\"\\140\")\
        end\
        term.write(\" ×\")\
        --os.sleep(5)\
        local app = sl.app\
        local tree,folders = get(app.code)\
        --if not tree then return end\
        --term.write(\"Downloading... \")\
        --term.write(\"0%\")\
        local sPath = path(app)\
        if #tree > 0 or #folders > 0 then\
            fs.makeDir(sPath)\
            for f=1,#folders do\
                fs.makeDir(fs.combine(sPath,folders[f]))\
            end\
            for f=1,#tree do\
                download(app.code,tree[f],fs.combine(sPath,tree[f]))\
                term.setBackgroundColor(colors.lightGray)\
                term.setCursorPos(8,3)\
                term.write(math.floor((f/#tree)*100+0.5)..\"%\")\
                term.setCursorPos(12,3)\
                for t=12,w-14 do\
                    if (t-11)/(w-14-11) <= f/#tree then\
                        term.setTextColor(colors.blue)\
                    else\
                        term.setTextColor(colors.white)\
                    end\
                    term.write(\"\\140\")\
                end\
            end\
\9\9\9s.updateFunc = function()\
\9\9\9\9local b = {lUtils.popup(\"LevelStore\",\"Do you want to create a shortcut to \"..app.name..\"?\",25,9,{\"Yes\",\"No\"})}\
\9\9\9\9if b[1] and b[3] == \"Yes\" then\
\9\9\9\9\9lOS.genIco(sPath)\
\9\9\9\9end\
\9\9\9end\
\9\9\9os.pullEvent()\
        end\
        s.var.download = false\
    end\
end",
  },
  [ "toMain.lua" ] = {
    id = 3,
    name = "toMain.lua",
    content = "local s = shapescape.getSlide()\
if not s.var.download then\
    os.queueEvent(\"term_resize\")\
    shapescape.setSlide(1)\
end",
  },
  [ "sidebar.lua" ] = {
    id = 1,
    name = "sidebar.lua",
    content = "term.setBackgroundColor(colors.gray)\
term.clear()\
local s = shapescape.getSlide()\
for t=1,#s.objs do\
    if s.objs[t] == self then\
        s.var.sidebar = self\
        s.var.sb = false\
        table.remove(s.objs,t)\
        coroutine.yield()\
    end\
end\
lUtils.shapescape.run({shapescape.getSlides()[3]})",
  },
  [ "getbuttonclick.lua" ] = {
    id = 7,
    name = "getbuttonclick.lua",
    content = "local s = shapescape.getSlide()\
local sl = shapescape.getSlides()\
if self.txt == \"  Get  \" then\
    s.var.download = true\
elseif self.txt == \"  Run  \" then\
    local get,path = sl.api.get,sl.api.path\
    local app = sl.app\
    if fs.isDir(path(app)) == false then\
        lOS.execute(path(app))\
    else\
        local file\
        local files = fs.list(path(app))\
        for f=1,#files do\
            local fP = fs.combine(path(app),files[f])\
            if not fs.isDir(fP) then\
                if files[f] == \"main.lua\" then\
                    file = fP\
                elseif not file and lUtils.getFileType(files[f]) == \".lua\" then\
                    file = fP\
                end\
            end\
        end\
        if not file then\
            lUtils.popup(\"LevelStore\",\"No lua file found in this project. Please contact the developer.\",27,9,{\"Cancel\"})\
        else\
            lOS.execute(file)\
        end\
    end\
end",
  },
  [ "username.lua" ] = {
    id = 9,
    name = "username.lua",
    content = "self.txt = lOS.username or \"Guest\"",
  },
  [ "Get_Button.lua" ] = {
    id = 6,
    name = "Get_Button.lua",
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
while true do\
    if s.var and s.var.download then\
        self.txt = \"  Get  \"\
        self.txtcolor = colors.lightGray\
    elseif fs.exists(sl.api.path(sl.app)) then\
        self.txt = \"  Run  \"\
        self.txtcolor = colors.white\
    else\
        self.txt = \"  Get  \"\
        self.txtcolor = colors.white\
    end\
    local e = {os.pullEvent()}\
end",
  },
  [ "appPage.lua" ] = {
    id = 4,
    name = "appPage.lua",
    content = "local function find(a,b)\
    return string.find(a,b,nil,true)\
end\
local function tag(txt)\
    if not find(txt,\"<\") then return nil end\
    local txt2 = string.sub(txt,({find(txt,\"<\")})[2]+1,#txt)\
    return txt2:match(\"(.-)[^%w_]\")\
end\
local function renderdesc(txt)\
    local d = txt\
    while true do\
        local t = tag(d)\
        if not t then\
            return\
        else\
            local content\
            content,d = lUtils.getField(d,t)\
            if t == \"text\" then\
                print(content)\
            end\
        end\
    end\
end\
\
local function wordwrap(str)\
    local x,y = term.getCursorPos()\
    local tW,tH = term.getSize()\
    local words = 0\
    for w in str:gmatch(\"%S+\") do\
        local x1,y1 = term.getCursorPos()\
        if x1+(#w*3) >= tW then\
            if words == 0 then\
                return false,0\
            else\
                bigfont.bigPrint(\" \")\
            end\
        end\
        bigfont.bigWrite(w..\" \")\
        words = words+1\
    end\
    bigfont.bigPrint(\" \")\
    return true,words\
end\
\
while true do\
    term.setBackgroundColor(colors.gray)\
    term.setTextColor(colors.white)\
    term.clear()\
    local w,h = term.getSize()\
    local oterm = term.current()\
    local win = window.create(term.current(),2,2,w-2,h)\
    term.redirect(win)\
    term.setBackgroundColor(colors.gray)\
    term.setTextColor(colors.white)\
    term.clear()\
    term.setCursorPos(1,1)\
    local slides = shapescape.getSlides()\
    local app = slides.app\
    if app.icon then\
        lUtils.renderImg(app.icon,1,1)\
        term.setCursorPos(6,1)\
    end\
    if not wordwrap(app.name) then\
        local x,y = term.getCursorPos()\
        term.setCursorPos(x,2)\
        print(app.name)\
        print(\"\")\
    end\
    print(\"\")\
    renderdesc(app.description)\
    local e = {os.pullEvent()}\
end",
  },
}

local nAssets = {}
for key,value in pairs(assets) do nAssets[key] = value nAssets[assets[key].id] = assets[key] end
assets = nAssets
nAssets = nil

local slides = {
  {
    h = 19,
    x = 65,
    y = 22,
    objs = {
      {
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
        x1 = 1,
        y1 = 1,
        x2 = 51,
        y2 = 3,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 0,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        type = "window",
        ox2 = 0,
        color = 128,
      },
      {
        oy2 = 0,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        type = "window",
        x1 = 1,
        y1 = 4,
        x2 = 51,
        y2 = 19,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 2,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        color = 32768,
        border = {
          color = 256,
          type = 1,
        },
      },
      {
        oy2 = 0,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap bottom",
        },
        type = "window",
        x1 = 22,
        y1 = 4,
        x2 = 51,
        y2 = 19,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox1 = 29,
        ox2 = 0,
        color = 128,
        border = {
          color = 1,
          type = 1,
        },
      },
    },
    c = 1,
    w = 51,
  },
  {
    h = 19,
    x = 65,
    y = 22,
    objs = {
      {
        oy2 = 0,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        border = {
          color = 128,
          type = 1,
        },
        x1 = 1,
        y1 = 4,
        x2 = 51,
        y2 = 19,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 8,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 10,
          },
        },
        ox2 = 0,
        color = 32768,
        type = "window",
      },
      {
        oy2 = -15,
        snap = {
          Top = "Snap center",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        type = "window",
        x1 = 9,
        y1 = 12,
        x2 = 43,
        y2 = 34,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 4,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 8,
        color = 128,
        oy1 = -2,
        border = {
          color = 1,
          type = 1,
        },
      },
      {
        oy2 = -1,
        snap = {
          Top = "Snap center",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap center",
        },
        type = "window",
        x1 = 9,
        y1 = 7,
        x2 = 43,
        y2 = 11,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 5,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 8,
        color = 128,
        oy1 = 3,
        border = {
          color = 256,
          type = 1,
        },
      },
      {
        oy2 = 0,
        border = {
          color = 256,
          type = 1,
        },
        txtcolor = 1,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 6,
          },
          mouse_up = {
            [ 2 ] = 7,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        color = 512,
        snap = {
          Top = "Snap center",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap center",
        },
        x1 = 33,
        y1 = 8,
        x2 = 41,
        y2 = 10,
        ox1 = 18,
        txt = "  Get",
        ox2 = 10,
        type = "text",
        input = false,
        oy1 = 2,
      },
      {
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
        x1 = 1,
        y1 = 1,
        x2 = 51,
        y2 = 3,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        color = 128,
        input = false,
        type = "rect",
      },
      {
        type = "text",
        txtcolor = 1,
        y1 = 1,
        x2 = 5,
        y2 = 3,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = 3,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txt = " \
  \27",
        x1 = 1,
        color = 0,
        input = false,
        border = {
          color = 0,
          type = 1,
        },
      },
    },
    c = 2,
    w = 51,
  },
  {
    h = 19,
    x = 65,
    y = 22,
    objs = {
      {
        oy2 = 0,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        type = "rect",
        x1 = 1,
        y1 = 1,
        x2 = 51,
        y2 = 19,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        color = 128,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        type = "text",
        border = {
          color = 0,
          type = 1,
        },
        x1 = 3,
        y1 = 2,
        x2 = 15,
        y2 = 2,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txt = "Logged in as",
        txtcolor = 1,
        color = 128,
        input = false,
      },
      {
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        txtcolor = 2048,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 16,
        y1 = 2,
        x2 = 25,
        y2 = 2,
        event = {
          selected = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 9,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txt = "loading...",
        type = "text",
        color = 0,
        input = false,
      },
      {
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        x1 = 3,
        type = "text",
        txtcolor = 1,
        y1 = 8,
        x2 = 20,
        y2 = 10,
        event = {
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
        },
        txt = "  App Settings",
        border = {
          color = 128,
          type = 1,
        },
        color = 32768,
        input = false,
      },
      {
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 128,
          type = 1,
        },
        type = "text",
        x1 = 3,
        y1 = 4,
        x2 = 22,
        y2 = 6,
        event = {
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
        },
        txt = "  Manage Account",
        txtcolor = 1,
        color = 32768,
        input = false,
      },
      {
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 128,
          type = 1,
        },
        type = "text",
        x1 = 3,
        y1 = 12,
        x2 = 19,
        y2 = 14,
        event = {
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
        },
        txt = "  Manage Apps",
        txtcolor = 1,
        color = 32768,
        input = false,
      },
    },
    c = 3,
    w = 51,
  },
  {
    h = 19,
    x = 61,
    y = 22,
    objs = {},
    c = 4,
    w = 51,
  },
}

for s=1,#slides do
	local slide = slides[s]
	for o=1,#slide.objs do
		local obj = slide.objs[o]
		for key,value in pairs(obj.event) do
			if assets[ value[2] ] then
				lUtils.shapescape.addScript(obj,value[2],key,assets,LevelOS,slides)
			else
				obj.event[key] = {function() end,-1}
			end
		end
	end
end

	local tArgs = {...}
if tArgs[1] and tArgs[1] == "load" then
	return {assets=assets,slides=slides}
end


return lUtils.shapescape.run(slides,...)