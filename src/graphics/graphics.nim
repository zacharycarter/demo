import
  strutils

import
  bgfx
  , bgfx_platform
  , sdl2 as sdl

import 
  window

type
  Graphics* = ref TGraphics
  TGraphics* = object
    rootWindow: Window


when defined(macosx):
  type
    SysWMinfoCocoaObj = object
      window: pointer ## The Cocoa window

    SysWMinfoKindObj = object
      cocoa: SysWMinfoCocoaObj

when defined(linux):
  type
    SysWMinfoX11Obj* = object
      display*: pointer  ##  The X11 display
      window*: pointer  ##  The X11 window

    SysWMinfoKindObj* = object
      x11*: SysWMinfoX11Obj

proc getTime(): float64 =
    return float64(sdl.getPerformanceCounter()*1000) / float64 sdl.getPerformanceFrequency()

proc linkSDL2BGFX(window: sdl.WindowPtr) =
    var pd: ptr PlatformData = create(PlatformData) 
    var info: sdl.WMinfo
    assert sdl.getWMInfo(window, info)
    echo  "SDL2 version: $1.$2.$3 - Subsystem: $4".format(info.version.major.int, info.version.minor.int, info.version.patch.int, 
    info.subsystem)
    
    case(info.subsystem):
        of SysWM_Windows:
          when defined(windows):
            pd.nwh = cast[pointer](info.info.win.window)
          pd.ndt = nil
        of SysWM_X11:
          when defined(linux):
            let info = cast[ptr SysWMinfoKindObj](addr info.padding[0])
            pd.nwh = info.x11.window
            pd.ndt = info.x11.display
        of SysWM_Cocoa:
          when defined(macosx):
            let info = cast[ptr SysWMinfoKindObj](addr info.padding[0])
            pd.nwh = info.cocoa.window
          pd.ndt = nil
        else:
          echo "SDL2 failed to get handle: $1".format(sdl.getError())
          raise newException(OSError, "No structure for subsystem type")

    pd.backBuffer = nil
    pd.backBufferDS = nil
    pd.context = nil
    SetPlatformData(pd)

proc newGraphics*(): Graphics =
  result = Graphics()

proc init*(graphics: Graphics, title: string, width, height: int, flags: uint32) =
  if not sdl.init(INIT_TIMER or INIT_VIDEO or INIT_JOYSTICK or INIT_HAPTIC or INIT_GAMECONTROLLER or INIT_EVENTS):
    echo "Error initializing SDL2."
    quit(QUIT_FAILURE)
  
  graphics.rootWindow = newWindow()

  graphics.rootWindow.init(title, width, height, flags)

  if graphics.rootWindow.isNil:
    echo "Error creating SDL2 window."
    quit(QUIT_FAILURE)

  linkSDL2BGFX(graphics.rootWindow.handle)

  if not bgfx.Init(bgfx.RendererType.RendererType_Count, 0'u16, 0, nil, nil):
    echo "Error initializng BGFX."
    quit(QUIT_FAILURE)

  bgfx.SetDebug(BGFX_DEBUG_TEXT)

  bgfx.Reset(uint32 width, uint32 height)

  bgfx.SetViewRect(0, 0, 0, uint16 width, uint16 height)

proc frame*(graphics: Graphics) =
  var now = getTime()
  var last {.global.} = getTime()
  let frameTime: float32 = now - last
  let time = getTime()
  last = now
  var toMs = 1000.0'f32

  bgfx.DebugTextClear()
  bgfx.DebugTextPrintf(1, 1, 0x0f, "Frame: %7.3f[ms] FPS: %7.3f", float32(frameTime), (1.0 / frameTime) * toMs)

  bgfx.Touch(0)
  
  bgfx.Frame()

proc dispose*(graphics: Graphics) =
  sdl.destroyWindow(graphics.rootWindow.handle)
  sdl.quit()
  bgfx.Shutdown()