local assets = {
  [ "slider.lua" ] = {
    id = 1,
    content = "local s = shapescape.getSlide()\
if not s.var then s.var = {} end\
\
local set = \"LevelOS/data/settings.lconf\"\
\
if lOS.settings.rTime == nil then\
    lOS.settings.rTime = false\
end\
\
local r = string.rep\
\
local rtime = lOS.settings.rTime\
\
local w,h = term.getSize()\
\
if rtime then\
    term.setBackgroundColor(colors.green)\
    term.setCursorPos(1,1)\
    term.write(r(\" \",w-1))\
    term.setBackgroundColor(colors.white)\
    term.write(\" \")\
else\
    term.setCursorPos(1,1)\
    term.setBackgroundColor(colors.white)\
    term.write(\" \")\
    term.setBackgroundColor(colors.red)\
    term.write(r(\" \",w-1))\
end\
\
while true do\
    local w,h = term.getSize()\
    if lOS.settings.rTime ~= rtime then\
        rtime = lOS.settings.rTime\
        local b1,b2,fg\
        b1 = \"d\"\
        b2 = \"e\"\
        fg = \"0\"\
        local a,b,c\
        if rtime then\
            a,b,c = 1,w,1\
        else\
            a,b,c = w,1,-1\
        end\
        for x=a,b,c do\
            local d,e = x-1,w-x\
            term.setCursorPos(1,1)\
            term.blit(r(\" \",d)..\" \"..r(\" \",e),r(\"f\",w),r(b1,d)..fg..r(b2,e))\
            os.sleep(0.05)\
        end\
    end\
    e = {os.pullEvent()}\
end",
    name = "slider.lua",
  },
  [ "switch_time.lua" ] = {
    id = 2,
    content = "lOS.settings.rTime = not lOS.settings.rTime",
    name = "switch_time.lua",
  },
  [ "rendercalender.lua" ] = {
    id = 7,
    content = "local w,h = term.getSize()\
while h < 21 do\
    os.pullEvent()\
    w,h = term.getSize()\
end\
local epoch = os.epoch(\"local\")/1000\
local date = os.date(\"*t\",epoch)\
local targetmonth = date.month\
local targetyear = date.year\
local d = {}\
d.sec = 1\
d.min = d.sec*60\
d.hour = d.min*60\
d.day = d.hour*24\
local function dayadd()\
	epoch = epoch+d.day\
	date = os.date(\"*t\",epoch)\
end\
local function daysub()\
	epoch = epoch-d.day\
	date = os.date(\"*t\",epoch)\
end\
while date.year < targetyear or date.month < targetmonth do\
	dayadd()\
end\
term.setBackgroundColor(colors.gray)\
term.setTextColor(colors.white)\
term.clear()\
term.setCursorPos(1,1)\
term.write(os.date(\"%B %Y\"))\
term.setCursorPos(1,3)\
days = {\"Mo\",\"Tu\",\"We\",\"Th\",\"Fr\",\"Sa\",\"Su\"}\
for t=1,7 do\
	term.write(\" \"..days[t]..\" \")\
end\
local x = term.getCursorPos()\
term.setCursorPos(x-3,1)\
--LevelOS.setWin(x-1,24)\
term.write(\"\\30 \\31\")\
while date.day > 1 do\
	daysub()\
end\
while date.wday ~= 2 do\
	daysub()\
end\
local current = os.date(\"*t\")\
for w=1,6 do\
	--term.setCursorPos(1,5+(w-1)*3)\
	for t=1,7 do\
		local x,y = 1+(t-1)*4,5+(w-1)*3\
		local cur = false\
		if current.day == date.day and current.month == date.month and current.year == date.year then\
			term.setTextColor(colors.black)\
			term.setBackgroundColor(colors.lightGray)\
			lUtils.border(x,y-1,x+3,y+1)\
			cur = true\
		else\
			term.setBackgroundColor(colors.gray)\
		end\
		if targetmonth == date.month then\
			term.setTextColor(colors.white)\
		elseif cur then\
			term.setTextColor(colors.gray)\
		else\
			term.setTextColor(colors.lightGray)\
		end\
		term.setCursorPos(x+1,y)\
		term.write(os.date(\"%d\",epoch))\
		dayadd()\
	end\
end\
while true do os.pullEvent() end",
    name = "rendercalender.lua",
  },
  [ "offset.lua" ] = {
    id = 3,
    content = "if lOS.settings.timeOffset then\
    local o = lOS.settings.timeOffset\
    if o >= 0 then\
        self.txt = \"+\"..o\
    else\
        self.txt = tostring(o)\
    end\
end",
    name = "offset.lua",
  },
  [ "offset_up.lua" ] = {
    id = 5,
    content = "lOS.settings.timeOffset = lOS.settings.timeOffset + 0.5",
    name = "offset_up.lua",
  },
  [ "time.lua" ] = {
    id = 0,
    content = "if not lOS.settings.timeOffset then\
    lOS.settings.timeOffset = 0\
end\
local t = os.date(\"*t\",os.epoch(\"utc\")/1000+lOS.settings.timeOffset*3600)\
term.setBackgroundColor(colors.gray)\
term.setTextColor(colors.white)\
term.setCursorPos(self.x1,self.y1)\
local function tz(n)\
    return string.rep(\"0\",2-string.len(n))..n\
end\
if lOS.settings.rTime then\
    bigfont.bigPrint(tz(t.hour)..\":\"..tz(t.min)..\":\"..tz(t.sec))\
else\
    local nTime = (os.time()+lOS.settings.timeOffset)%24\
    local nHour = math.floor(nTime)\
    local nMinute = math.floor((nTime - nHour) * 60)\
    bigfont.bigPrint(tz(nHour)..\":\"..tz(nMinute))\
end\
term.setTextColor(colors.lightGray)\
local days = {\"Sunday\",\"Monday\",\"Tuesday\",\"Wednesday\",\"Thursday\",\"Friday\",\"Saturday\"}\
local months = {\"Jan\",\"Feb\",\"Mar\",\"Apr\",\"May\",\"Jun\",\"Jul\",\"Aug\",\"Sep\",\"Oct\",\"Nov\",\"Dec\"}\
term.setCursorPos(self.x1,({term.getCursorPos()})[2])\
print(days[t.wday]..\", \"..months[t.month]..\" \"..t.day..\", \"..t.year)",
    name = "time.lua",
  },
  [ "init.lua" ] = {
    id = 4,
    content = "local w,h = 27,13\
local tw,th = lOS.wAll.getSize()\
if th >= 40 then\
    w,h = 32,36\
end\
LevelOS.setWin(w,h,\"widget\")\
LevelOS.self.window.win.reposition(tw-w,th-(h-1+lOS.tbSize))",
    name = "init.lua",
  },
  [ "offset_down.lua" ] = {
    id = 6,
    content = "lOS.settings.timeOffset = lOS.settings.timeOffset - 0.5",
    name = "offset_down.lua",
  },
}

local nAssets = {}
for key,value in pairs(assets) do nAssets[key] = value nAssets[assets[key].id] = assets[key] end
assets = nAssets
nAssets = nil

local slides = {
  {
    y = 21,
    x = 61,
    h = 19,
    w = 51,
    objs = {
      {
        x2 = 51,
        y2 = 19,
        y1 = 1,
        x1 = 1,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 4,
          },
        },
        ox2 = 0,
        color = 128,
        border = {
          color = 256,
          type = 1,
        },
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        oy2 = 0,
      },
      {
        x2 = 26,
        y2 = 4,
        border = {
          color = 128,
          type = 1,
        },
        x1 = 3,
        txt = "",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          render = {
            [ 2 ] = 0,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        color = 128,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        y1 = 2,
      },
      {
        x2 = 50,
        y2 = 8,
        y1 = 7,
        x1 = 2,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        color = 128,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        border = {
          color = 256,
          type = 1,
        },
      },
      {
        x2 = 50,
        y2 = 8,
        y1 = 8,
        x1 = 2,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        color = 128,
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
        type = "rect",
        color = 128,
        y2 = 7,
        y1 = 7,
        x1 = 2,
        x2 = 2,
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
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
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
        x2 = 50,
        y2 = 7,
        y1 = 7,
        x1 = 50,
        ox1 = 1,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        color = 128,
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
        color = 128,
        y2 = 8,
        y1 = 8,
        x1 = 11,
        txt = "Use real time",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        input = false,
        x2 = 23,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 1,
        y2 = 12,
        y1 = 10,
        x1 = 3,
        txt = "+0",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = 3,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 32768,
        input = false,
        x2 = 9,
        border = {
          color = 256,
          type = 1,
        },
      },
      {
        x2 = 9,
        y2 = 10,
        y1 = 10,
        x1 = 3,
        txt = "   ",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = 5,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        input = false,
        color = 256,
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
        color = 256,
        y2 = 12,
        y1 = 12,
        x1 = 3,
        txt = "   ",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = 6,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        input = false,
        x2 = 9,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 128,
        y2 = 11,
        y1 = 11,
        x1 = 11,
        txt = "Offset (hours)",
        type = "text",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        input = false,
        x2 = 26,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        type = "window",
        color = 32768,
        y2 = 8,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 3,
        y1 = 8,
        x2 = 9,
        snap = {
          Top = "Snap top",
          Right = "Snap left",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        event = {
          mouse_up = {
            [ 2 ] = 2,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = 1,
          },
        },
      },
      {
        color = 128,
        y2 = 15,
        border = {
          color = 256,
          type = 1,
        },
        x1 = 2,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        x2 = 50,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        y1 = 14,
      },
      {
        type = "rect",
        x2 = 2,
        y2 = 14,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 2,
        color = 128,
        y1 = 14,
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
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
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
        color = 128,
        y2 = 14,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 50,
        ox1 = 1,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        x2 = 50,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap right",
          Bottom = "Snap top",
        },
        y1 = 14,
      },
      {
        color = 128,
        y2 = 15,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 2,
        type = "rect",
        event = {
          mouse_up = {
            [ 2 ] = -1,
          },
          mouse_click = {
            [ 2 ] = -1,
          },
          Initialize = {
            [ 2 ] = -1,
          },
          selected = {
            [ 2 ] = -1,
          },
          update = {
            [ 2 ] = -1,
          },
          Coroutine = {
            [ 2 ] = -1,
          },
        },
        ox2 = 1,
        x2 = 50,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap top",
        },
        y1 = 15,
      },
      {
        x2 = 49,
        y2 = 18,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 3,
        type = "window",
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
            [ 2 ] = 7,
          },
        },
        ox2 = 2,
        color = 32768,
        y1 = 15,
        snap = {
          Top = "Snap top",
          Right = "Snap right",
          Left = "Snap left",
          Bottom = "Snap bottom",
        },
        oy2 = 1,
      },
    },
    c = 1,
  },
  {
    y = 21,
    x = 61,
    h = 19,
    w = 51,
    objs = {},
    c = 2,
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

	
	lUtils.shapescape.run(slides,...)