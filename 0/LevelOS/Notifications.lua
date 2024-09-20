local assets = {}

local nAssets = {}
for key,value in pairs(assets) do nAssets[key] = value nAssets[assets[key].id] = assets[key] end
assets = nAssets
nAssets = nil

local slides = {
  {
    y = 21,
    x = 70,
    w = 32,
    h = 19,
    objs = {
      {
        type = "rect",
        color = 32768,
        y2 = 19,
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
        x1 = 1,
        x2 = 32,
        border = {
          color = 0,
          type = 1,
        },
        y1 = 1,
      },
      {
        type = "rect",
        color = 128,
        y2 = 6,
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
        x1 = 2,
        y1 = 2,
        border = {
          color = 0,
          type = 1,
        },
        x2 = 31,
      },
      {
        x2 = 19,
        y2 = 3,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 8,
        txt = "Notification",
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
            [ 2 ] = -1,
          },
        },
        txtcolor = 1,
        input = false,
        color = 0,
        y1 = 3,
      },
      {
        type = "rect",
        color = 16384,
        y2 = 5,
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
        x1 = 4,
        y1 = 3,
        border = {
          color = 0,
          type = 1,
        },
        x2 = 6,
      },
      {
        x2 = 30,
        y2 = 5,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 8,
        txt = "This is a notification to tell you things yes.",
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
            [ 2 ] = -1,
          },
        },
        txtcolor = 256,
        input = false,
        color = 0,
        y1 = 4,
      },
      {
        x2 = 30,
        y2 = 3,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 30,
        txt = "×",
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
            [ 2 ] = -1,
          },
        },
        txtcolor = 256,
        input = false,
        color = 0,
        y1 = 3,
      },
    },
    c = 1,
  },
  {
    y = 21,
    x = 70,
    c = 2,
    objs = {
      {
        type = "rect",
        color = 128,
        y2 = 6,
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
        x1 = 2,
        x2 = 31,
        y1 = 2,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        type = "rect",
        color = 16384,
        y2 = 5,
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
        x1 = 3,
        x2 = 5,
        y1 = 3,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 0,
        y2 = 3,
        y1 = 3,
        x1 = 7,
        txt = "Notification",
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
        txtcolor = 1,
        input = false,
        x2 = 18,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 0,
        y2 = 5,
        y1 = 4,
        x1 = 7,
        txt = "This is a notification to tell you things yes.",
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
        txtcolor = 256,
        input = false,
        x2 = 30,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 0,
        y2 = 3,
        y1 = 3,
        x1 = 30,
        txt = "×",
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
        txtcolor = 256,
        input = false,
        x2 = 30,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        type = "rect",
        color = 128,
        y2 = 12,
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
        x1 = 2,
        border = {
          color = 0,
          type = 1,
        },
        x2 = 31,
        y1 = 8,
      },
      {
        color = 0,
        y2 = 9,
        y1 = 9,
        x1 = 3,
        txt = "Notification",
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
        txtcolor = 1,
        input = false,
        x2 = 14,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        x2 = 30,
        y2 = 11,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 3,
        txt = "This notification has no icon available.",
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
        txtcolor = 256,
        input = false,
        color = 0,
        y1 = 10,
      },
      {
        x2 = 30,
        y2 = 9,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 30,
        txt = "×",
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
        txtcolor = 256,
        input = false,
        color = 0,
        y1 = 9,
      },
      {
        type = "rect",
        color = 128,
        y2 = 19,
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
        x1 = 2,
        border = {
          color = 0,
          type = 1,
        },
        y1 = 14,
        x2 = 31,
      },
      {
        type = "rect",
        color = 16384,
        y2 = 17,
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
        x1 = 3,
        x2 = 5,
        border = {
          color = 0,
          type = 1,
        },
        y1 = 15,
      },
      {
        color = 0,
        y2 = 15,
        y1 = 15,
        x1 = 7,
        txt = "Notification",
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
        txtcolor = 1,
        input = false,
        x2 = 18,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        color = 0,
        y2 = 18,
        y1 = 16,
        x1 = 7,
        txt = "This notification does not have enough space so it expands downwards.",
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
        txtcolor = 256,
        input = false,
        x2 = 30,
        border = {
          color = 0,
          type = 1,
        },
      },
      {
        x2 = 30,
        y2 = 15,
        border = {
          color = 0,
          type = 1,
        },
        x1 = 30,
        txt = "×",
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
        txtcolor = 256,
        input = false,
        color = 0,
        y1 = 15,
      },
    },
    w = 32,
    h = 19,
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