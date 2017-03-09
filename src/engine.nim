import
  sdl2 as sdl

import
  app/app
  , framerate/framerate
  , graphics/graphics

type
  Engine* = ref TEngine
  TEngine* = object
    app: IApp
    graphics: Graphics

proc newEngine*(app: IApp): Engine =
  result = Engine()
  result.app = app

proc init*(engine: Engine, title: string, width, height: int, windowFlags: uint32) =
  engine.graphics = newGraphics()
  engine.graphics.init("bgfx demo", width, height, windowFlags)

proc run*(engine: Engine) =
  var
    event = sdl.defaultEvent
    runGame = true

  while runGame:
    while sdl.pollEvent(event):
      case event.kind
      of sdl.QuitEvent:
        runGame = false
        break
      else:
        discard

    engine.app.render(0.0)

    engine.graphics.frame()

    limitFrameRate()

proc dispose*(engine: Engine) =
  engine.graphics.dispose()