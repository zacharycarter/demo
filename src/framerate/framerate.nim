import
  sdl2 as sdl

let targetFramePeriod: uint32 = 20 # 20 milliseconds corresponds to 50 fps
var frameTime: uint32 = 0

proc limitFrameRate*() =
  let now = sdl.getTicks()
  if frameTime > now:
    sdl.delay(frameTime - now) # Delay to maintain steady frame rate
  frameTime += targetFramePeriod