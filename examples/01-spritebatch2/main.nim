import
  strutils

import
  bgfx
  , bgfx_platform
  , sdl2 as sdl

import
  graphics/graphics
  , graphics/twoD/spritebatch
  , graphics/twoD/texture

const WIDTH = 960
const HEIGHT = 540

let targetFramePeriod: uint32 = 20 # 20 milliseconds corresponds to 50 fps
var frameTime: uint32 = 0

proc limitFrameRate*() =
  let now = getTicks()
  if frameTime > now:
    delay(frameTime - now) # Delay to maintain steady frame rate
  frameTime += targetFramePeriod

proc getTime(): float64 =
    return float64(sdl.getPerformanceCounter()*1000) / float64 sdl.getPerformanceFrequency()

type
  App* = ref object of RootObj
    batch: SpriteBatch

proc render(a: App, tex: Texture) =
  a.batch.begin()
  a.batch.draw(tex, 100.0, 100.0, float tex.width, float tex.height, 0xffffffff'u32)
  a.batch.`end`()



var a = App()
var g = newGraphics()

g.init("bgfx demo", WIDTH, HEIGHT, SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE)

var
  event = sdl.defaultEvent
  runGame = true
  batch = SpriteBatch()
  tex : Texture

a.batch = newSpriteBatch(1000, 0)
tex = texture.load("test.png")

while runGame:
  while sdl.pollEvent(event):
    case event.kind
    of sdl.QuitEvent:
      runGame = false
      break
    else:
      discard

  a.render(tex)

  g.frame()
  
  limitFrameRate()

tex.unload()
batch.dispose()
g.dispose()