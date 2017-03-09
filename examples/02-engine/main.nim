import
  strutils

import
  bgfx
  , bgfx_platform
  , sdl2 as sdl

import
  app/app
  , engine
  , graphics/graphics
  , graphics/twoD/spritebatch
  , graphics/twoD/texture

type
  Game* = ref object of AbstractApp
    batch: SpriteBatch

const WIDTH = 960
const HEIGHT = 540

let targetFramePeriod: uint32 = 20 # 20 milliseconds corresponds to 50 fps
var frameTime: uint32 = 0

proc limitFrameRate*() =
  let now = getTicks()
  if frameTime > now:
    delay(frameTime - now) # Delay to maintain steady frame rate
  frameTime += targetFramePeriod

proc init(game: Game) =
  discard

proc update(game: Game, deltaTime: float) =
  discard

proc render(game: Game, deltaTime: float) =
  echo "HERE"
  var tex = texture.load("test.png")
  game.batch.begin()
  game.batch.draw(tex, 100.0, 100.0, float tex.width, float tex.height, 0xffffffff'u32)
  game.batch.`end`()

proc dispose(game: Game) =
  discard

proc toApp*(game: Game) : IApp =
  return (
    init:      proc() = game.init()
    , update:  proc(deltaTime: float) = game.update(deltaTime)
    , render:  proc(deltaTime: float) = game.render(deltaTime)
    , dispose: proc() = game.dispose()
  )

var g = Game()
var e = newEngine(toApp(g))

e.init("bgfx demo", WIDTH, HEIGHT, SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE)

e.run()

e.dispose()