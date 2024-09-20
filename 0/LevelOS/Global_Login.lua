local assets = {
  [ "init.lua" ] = {
    id = 9,
    content = "local gW,gH = 44,33\
local tW,tH = lOS.wAll.getSize()\
if tW-4 <= gW or tH-2 <= gH then\
    LevelOS.self.window.winMode = \"fullscreen\"\
else\
    local x,y = math.ceil(tW/2)-math.floor(gW/2),math.ceil(tH/2)-math.floor(gH/2)\
    LevelOS.self.window.win.reposition(x,y,gW,gH)\
    LevelOS.setTitle(\"Leveloper Account\")\
    LevelOS.self.window.resizable = false\
end",
    name = "init.lua",
  },
  [ "rememberme.lua" ] = {
    id = 10,
    content = "local sl = shapescape.getSlides()\
if sl.rememberme then\
    self.txt = \" \"\
    sl.rememberme = false\
else\
    self.txt = \" × \"\
    sl.rememberme = true\
end",
    name = "rememberme.lua",
  },
  [ "box.lua" ] = {
    id = 1,
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
--[[if s == sl[1] and not sl.usernameBox then\
    sl.usernameBox = self\
elseif s == sl[3] then\
    self = sl.usernameBox\
end]]\
s.box = self\
if not self.init then\
    self.state = true\
    self.init = true\
end\
if self.errorTxt and self.txt ~= self.errorTxt then\
    s.error = nil\
    self.errorTxt = nil\
end\
if s.error and #s.error > 0 then\
    self.border.color = colors.red\
    if not self.errorTxt then\
        self.errorTxt = self.txt\
    end\
elseif self.state then\
    self.border.color = colors.blue\
else\
    self.border.color = colors.lightGray\
end\
if self.txt == \"\" then\
    term.setCursorPos(self.x1+1,self.y1+1)\
    term.setBackgroundColor(self.color)\
    term.setTextColor(colors.lightGray)\
    if s == sl[1] or s == sl[3] then\
        term.write(\"Username\")\
    elseif s == sl[2] or s == sl[4] then\
        term.write(\"Password\")\
    end\
    term.setCursorPos(self.x1+1,self.y1+1)\
    term.setTextColor(self.txtcolor)\
end\
if s == sl[1] or s == sl[3] then\
    --sl.username = self.txt\
    if sl.username == self.txt then\
        self.opt.replaceChar = nil\
    end\
    sl.username = self.txt\
elseif s == sl[2] or s == sl[4] then\
    --sl.password = self.txt\
    if sl.password == self.txt then\
        self.opt.replaceChar = \"\\7\"\
    end\
    sl.password = self.txt\
end",
    name = "box.lua",
  },
  [ "makebig.lua" ] = {
    id = 0,
    content = "term.setBackgroundColor(self.color)\
term.setTextColor(self.txtcolor)\
term.setCursorPos(self.x1,self.y1)\
bigfont.bigWrite(self.txt)",
    name = "makebig.lua",
  },
  [ "Create_one.lua" ] = {
    id = 8,
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
while true do\
    local e = {os.pullEvent()}\
    if (e[1] == \"mouse_click\" or e[1] == \"mouse_up\") and e[3] >= self.x1 and e[4] >= self.y1 and e[3] <= self.x2 and e[4] <= self.y2 then\
        if e[1] == \"mouse_click\" then\
            self.txtcolor = colors.lightBlue\
        elseif e[1] == \"mouse_up\" and self.txtcolor == colors.lightBlue then\
            self.txtcolor = colors.blue\
            if s == sl[1] then\
                shapescape.setSlide(3)\
            elseif s == sl[3] then\
                shapescape.setSlide(1)\
            end\
        end\
    end\
    if e[1] == \"mouse_up\" then\
        self.txtcolor = colors.blue\
    end\
end",
    name = "Create_one.lua",
  },
  [ "userback.lua" ] = {
    id = 4,
    content = "local sl = shapescape.getSlides()\
self.txt = \"\\27 \"..sl.username\
while true do\
    local e = {os.pullEvent()}\
    self.txt = \"\\27 \"..sl.username\
    if (e[1] == \"mouse_click\" or e[1] == \"mouse_up\") and e[3] >= self.x1 and e[4] >= self.y1 and e[3] <= self.x2 and e[4] <= self.y2 then\
        if e[1] == \"mouse_click\" then\
            self.txtcolor = colors.gray\
        elseif e[1] == \"mouse_up\" and self.txtcolor == colors.gray then\
            self.txtcolor = colors.black\
            if shapescape.getSlide() == sl[2] then\
                shapescape.setSlide(1)\
            else\
                shapescape.setSlide(3)\
            end\
        end\
    end\
    if e[1] == \"mouse_up\" then\
        self.txtcolor = colors.black\
    end\
end",
    name = "userback.lua",
  },
  [ "Next.lua" ] = {
    id = 2,
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
if fs.exists(\"LevelOS/data/account.txt\") and not sl.putusername then\
	sl.putusername = true\
	os.sleep(0.05)\
	s.box.txt = lUtils.fread(\"LevelOS/data/account.txt\")\
	sl.username = s.box.txt\
	shapescape.setSlide(2)\
end\
while true do\
    local e = {os.pullEvent()}\
    if sl.username and sl.username ~= \"\" then\
        if self.color == colors.lightGray then\
            self.color = colors.blue\
        end\
        if ((e[1] == \"mouse_click\" or e[1] == \"mouse_up\") and e[3] >= self.x1 and e[4] >= self.y1 and e[3] <= self.x2 and e[4] <= self.y2) or ((e[1] == \"key\" or e[1] == \"key_up\") and e[2] == keys.enter) then\
            if e[1] == \"mouse_click\" or e[1] == \"key\" then\
                self.color = colors.lightBlue\
            elseif e[1] == \"mouse_up\" or e[1] == \"key_up\" then\
            	s.box.state = false\
                if shapescape.getSlide() == sl[1] then\
                    local ok,err = lUtils.login(sl.username,\"\")\
                    if err and err:find(\"password\") then\
                        shapescape.setSlide(2)\
                    else\
                        s.error = err or \"Unknown error!\"\
                    end\
                elseif shapescape.getSlide() == sl[3] then\
                    local res,err = http.post(\"https://old.leveloper.cc/register.php\",\"username=\" .. textutils.urlEncode(sl.username)..\"&password=\"..textutils.urlEncode(\"a\"))\
                    if not res then\
                        s.error = err or \"Unknown error!\"\
                    else\
                        local msg = res.readAll()\
                        if msg:find(\"Password\") then\
                            shapescape.setSlide(4)\
                        else\
                            s.error = msg\
                        end\
                    end\
                end\
            end\
        end\
        if (e[1] == \"key_up\" and e[2] == keys.enter) or e[1] == \"mouse_up\" then\
            self.color = colors.blue\
        end\
    else\
        self.color = colors.lightGray\
    end\
end",
    name = "Next.lua",
  },
  [ "showError.lua" ] = {
    id = 6,
    content = "local s = shapescape.getSlide()\
if not s.error then\
    self.txtcolor = colors.white\
else\
    self.txtcolor = colors.red\
    self.txt = s.error\
end",
    name = "showError.lua",
  },
  [ "Sign_in.lua" ] = {
    id = 3,
    content = "local sl = shapescape.getSlides()\
local s = shapescape.getSlide()\
while true do\
    local e = {os.pullEvent()}\
    if sl.password and sl.password ~= \"\" then\
        if self.color == colors.lightGray then\
            self.color = colors.blue\
        end\
        if ((e[1] == \"mouse_click\" or e[1] == \"mouse_up\") and e[3] >= self.x1 and e[4] >= self.y1 and e[3] <= self.x2 and e[4] <= self.y2) or ((e[1] == \"key\" or e[1] == \"key_up\") and e[2] == keys.enter) then\
    		s.box.state = false\
            if e[1] == \"mouse_click\" or e[1] == \"key\" then\
                self.color = colors.lightBlue\
            elseif e[1] == \"mouse_up\" or e[1] == \"key_up\" then\
                if shapescape.getSlide() == sl[2] then\
                    local userID,msg = lUtils.login(sl.username,sl.password,false,sl.rememberme)\
                    if userID then\
                        lOS.userID = userID\
                        lOS.username = sl.username\
                        shapescape.exit()\
                    else\
                        s.error = msg or \"Unknown error\"\
                    end\
                else\
                    local res,err = http.post(\"https://old.leveloper.cc/register.php\",\"username=\"..textutils.urlEncode(sl.username)..\"&password=\"..textutils.urlEncode(sl.password))\
                    if not res then\
                        s.error = err or \"Unknown error\"\
                    else\
                        local msg = res.readAll()\
                        if msg == \"200\" then\
                            local userID,msg = lUtils.login(sl.username,sl.password,false,sl.rememberme)\
                            lOS.userID = userID\
                            lOS.username = sl.username\
                            shapescape.exit()\
                        else\
                            s.error = msg\
                        end\
                    end\
                end\
            end\
        end\
        if (e[1] == \"key_up\" and e[2] == keys.enter) or e[1] == \"mouse_up\" then\
            self.color = colors.blue\
        end\
    else\
        self.color = colors.lightGray\
    end\
end",
    name = "Sign_in.lua",
  },
}

local nAssets = {}
for key,value in pairs(assets) do nAssets[key] = value nAssets[assets[key].id] = assets[key] end
assets = nAssets
nAssets = nil

local slides = {
  {
    y = 21,
    x = 65,
    h = 19,
    w = 51,
    objs = {
      {
        color = 1,
        y2 = 2,
        y1 = 2,
        x1 = 5,
        txt = "Leveloper",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 9,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 128,
        input = false,
        x2 = 13,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        x2 = 13,
        y2 = 4,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "Sign in",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = 0,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        color = 1,
        y1 = 4,
      },
      {
        lines = {
          "",
        },
        x2 = 48,
        changed = false,
        y1 = 7,
        x1 = 4,
        scrollX = 0,
        ox2 = 3,
        history = {},
        border = {
          color = 16384,
          type = 1,
        },
        txt = "",
        opt = {
          overflowX = "scroll",
          overflowY = "none",
          cursorColor = 32768,
          indentChar = " ",
          tabSize = 4,
          minWidth = 45,
          overflow = "scroll",
          minHeight = 3,
        },
        blit = {},
        rhistory = {},
        cursor = {
          y = 1,
          x = 1,
          a = 1,
        },
        y2 = 9,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = 1,
          },
          update = {
            [ 2 ] = 1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        state = false,
        dLines = {
          "",
        },
        type = "input",
        scr = 0,
        ref = {
          1,
          1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        color = 1,
      },
      {
        type = "rect",
        x2 = 4,
        y2 = 9,
        y1 = 7,
        x1 = 1,
        border = {
          color = 0,
          type = 1,
        },
        color = 1,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
      },
      {
        color = 1,
        y2 = 9,
        y1 = 7,
        x1 = 48,
        ox1 = 3,
        type = "rect",
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
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
        },
        ox2 = 0,
        x2 = 51,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 1,
        y2 = 7,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 4,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        ox2 = 3,
        x2 = 48,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        y1 = 7,
      },
      {
        x2 = 15,
        y2 = 11,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "No account?",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        color = 0,
        y1 = 11,
      },
      {
        x2 = 26,
        y2 = 11,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 17,
        txt = "Create one",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 8,
          },
        },
        txtcolor = 2048,
        input = false,
        color = 0,
        y1 = 11,
      },
      {
        color = 256,
        y2 = 16,
        x1 = 38,
        ox1 = 13,
        txt = "  Next",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          [ " update" ] = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 2,
          },
          update = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        ox2 = 4,
        txtcolor = 1,
        border = {
          color = 1,
          type = 1,
        },
        input = false,
        x2 = 47,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        y1 = 14,
      },
      {
        color = 0,
        y2 = 15,
        y1 = 13,
        x1 = 5,
        txt = "Loading...",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 6,
          },
        },
        txtcolor = 16384,
        input = false,
        x2 = 36,
        border = {
          color = 0,
          type = 1,
        },
      },
    },
    c = 1,
  },
  {
    y = 21,
    x = 65,
    h = 19,
    w = 51,
    objs = {
      {
        x2 = 13,
        y2 = 2,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "Leveloper",
        type = "text",
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
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
        },
        txtcolor = 128,
        input = false,
        color = 1,
        y1 = 2,
      },
      {
        x2 = 18,
        y2 = 6,
        y1 = 6,
        x1 = 5,
        txt = "Password",
        type = "text",
        event = {
          render = {
            [ 2 ] = 0,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
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
        },
        txtcolor = 32768,
        input = false,
        color = 1,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 0,
        y2 = 4,
        y1 = 4,
        x1 = 5,
        txt = " ",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 4,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        x2 = 42,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        lines = {
          "",
        },
        x2 = 48,
        changed = false,
        cursor = {
          y = 1,
          x = 1,
          a = 1,
        },
        x1 = 4,
        scrollX = 0,
        ox2 = 3,
        history = {},
        border = {
          color = 16384,
          type = 1,
        },
        txt = "",
        opt = {
          overflowX = "scroll",
          overflowY = "none",
          cursorColor = 32768,
          indentChar = " ",
          tabSize = 4,
          minWidth = 45,
          overflow = "scroll",
          minHeight = 3,
        },
        blit = {},
        rhistory = {},
        y1 = 9,
        y2 = 11,
        event = {
          render = {
            [ 2 ] = 1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        state = false,
        dLines = {
          "",
        },
        type = "input",
        scr = 0,
        ref = {
          1,
          1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        color = 1,
      },
      {
        type = "rect",
        color = 1,
        y2 = 11,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 1,
        x2 = 4,
        y1 = 9,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
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
        },
      },
      {
        x2 = 51,
        y2 = 11,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 48,
        ox1 = 3,
        type = "rect",
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        color = 1,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        y1 = 9,
      },
      {
        x2 = 48,
        y2 = 9,
        y1 = 9,
        x1 = 4,
        type = "rect",
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
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
        },
        ox2 = 3,
        color = 1,
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
      },
      {
        x2 = 47,
        y2 = 16,
        x1 = 37,
        ox1 = 14,
        txt = " Sign in",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 3,
          },
          [ " update" ] = {
            [ 2 ] = -1,
          },
        },
        ox2 = 4,
        txtcolor = 1,
        y1 = 14,
        input = false,
        color = 256,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        border = {
          color = 1,
          type = 1,
        },
      },
      {
        x2 = 35,
        y2 = 14,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "No connection",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 6,
          },
        },
        ox2 = 16,
        txtcolor = 16384,
        input = false,
        color = 0,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        y1 = 13,
      },
      {
        x2 = 19,
        y2 = 15,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 9,
        txt = "Remember me",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        color = 0,
        y1 = 15,
      },
      {
        x2 = 7,
        y2 = 15,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = " ",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = 10,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        input = false,
        color = 256,
        y1 = 15,
      },
    },
    c = 2,
  },
  {
    y = 21,
    x = 61,
    h = 19,
    w = 51,
    objs = {
      {
        x2 = 13,
        y2 = 2,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "Leveloper",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 128,
        input = false,
        color = 1,
        y1 = 2,
      },
      {
        x2 = 12,
        y2 = 4,
        y1 = 4,
        x1 = 5,
        txt = "Register",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = 0,
          },
        },
        txtcolor = 32768,
        input = false,
        color = 1,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        lines = {
          "",
        },
        x2 = 48,
        changed = false,
        cursor = {
          y = 1,
          x = 1,
          a = 1,
        },
        x1 = 4,
        scrollX = 0,
        ox2 = 3,
        history = {},
        border = {
          color = 16384,
          type = 1,
        },
        txt = "",
        opt = {
          overflowX = "scroll",
          overflowY = "none",
          cursorColor = 32768,
          indentChar = " ",
          tabSize = 4,
          minWidth = 45,
          overflow = "scroll",
          minHeight = 3,
        },
        blit = {},
        rhistory = {},
        y1 = 7,
        y2 = 9,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 1,
          },
          render = {
            [ 2 ] = 1,
          },
        },
        txtcolor = 32768,
        state = false,
        dLines = {
          "",
        },
        type = "input",
        scr = 0,
        ref = {
          1,
          1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        color = 1,
      },
      {
        type = "rect",
        x2 = 4,
        y2 = 9,
        y1 = 7,
        x1 = 1,
        color = 1,
        border = {
          color = 0,
          type = 1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
      },
      {
        x2 = 51,
        y2 = 9,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 48,
        ox1 = 3,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        color = 1,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        y1 = 7,
      },
      {
        x2 = 48,
        y2 = 7,
        y1 = 7,
        x1 = 4,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        ox2 = 3,
        color = 1,
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
      },
      {
        color = 0,
        y2 = 15,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "Loading...",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 6,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 16384,
        input = false,
        x2 = 36,
        y1 = 13,
      },
      {
        x2 = 47,
        y2 = 16,
        x1 = 38,
        ox1 = 13,
        txt = "  Next",
        type = "text",
        event = {
          render = {
            [ 2 ] = -1,
          },
          [ " update" ] = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 2,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
        },
        ox2 = 4,
        txtcolor = 1,
        y1 = 14,
        input = false,
        color = 256,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        border = {
          color = 1,
          type = 1,
        },
      },
      {
        x2 = 20,
        y2 = 11,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "Have an account?",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        color = 0,
        y1 = 11,
      },
      {
        x2 = 28,
        y2 = 11,
        y1 = 11,
        x1 = 22,
        txt = "Sign in",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 8,
          },
          update = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 2048,
        input = false,
        color = 0,
        border = {
          color = 0,
          type = 1,
        },
      },
    },
    c = 3,
  },
  {
    y = 21,
    x = 61,
    h = 19,
    w = 51,
    objs = {
      {
        x2 = 13,
        y2 = 2,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "Leveloper",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 128,
        input = false,
        color = 1,
        y1 = 2,
      },
      {
        color = 0,
        y2 = 4,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = " ",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 4,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        x2 = 42,
        y1 = 4,
      },
      {
        x2 = 20,
        y2 = 6,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 5,
        txt = "New password",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = 0,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        color = 1,
        y1 = 6,
      },
      {
        lines = {
          "",
        },
        x2 = 48,
        changed = false,
        y1 = 9,
        x1 = 4,
        scrollX = 0,
        ox2 = 3,
        history = {},
        border = {
          color = 16384,
          type = 1,
        },
        txt = "",
        opt = {
          overflowX = "scroll",
          overflowY = "none",
          cursorColor = 32768,
          indentChar = " ",
          tabSize = 4,
          minWidth = 45,
          overflow = "scroll",
          minHeight = 3,
        },
        blit = {},
        rhistory = {},
        cursor = {
          y = 1,
          x = 1,
          a = 1,
        },
        y2 = 11,
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = 1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 1,
          },
        },
        txtcolor = 32768,
        state = false,
        dLines = {
          "",
        },
        type = "input",
        scr = 0,
        ref = {
          1,
          1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        color = 1,
      },
      {
        type = "rect",
        x2 = 4,
        y2 = 11,
        y1 = 9,
        x1 = 1,
        color = 1,
        border = {
          color = 0,
          type = 1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
      },
      {
        color = 1,
        y2 = 11,
        y1 = 9,
        x1 = 48,
        ox1 = 3,
        type = "rect",
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        ox2 = 0,
        x2 = 51,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 1,
        y2 = 9,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 4,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 3,
        x2 = 48,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        y1 = 9,
      },
      {
        color = 0,
        y2 = 14,
        y1 = 13,
        x1 = 5,
        txt = "No connection",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 6,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        ox2 = 16,
        txtcolor = 16384,
        input = false,
        x2 = 35,
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
      },
      {
        color = 256,
        y2 = 16,
        x1 = 36,
        ox1 = 15,
        txt = " Register",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          [ " update" ] = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 3,
          },
          update = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
        },
        ox2 = 4,
        txtcolor = 1,
        border = {
          color = 1,
          type = 1,
        },
        input = false,
        x2 = 47,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        y1 = 14,
      },
      {
        x2 = 7,
        y2 = 15,
        y1 = 15,
        x1 = 5,
        txt = " ",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = 10,
          },
          focus = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        input = false,
        color = 256,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        x2 = 19,
        y2 = 15,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 9,
        txt = "Remember me",
        type = "text",
        event = {
          render = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          focus = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          mouse_up = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        color = 0,
        y1 = 15,
      },
    },
    c = 4,
  },
  {
    y = 13,
    x = 38,
    h = 19,
    w = 51,
    objs = {},
    c = 5,
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