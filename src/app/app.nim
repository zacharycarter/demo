type
  IApp* = tuple[
    init:      proc()
    , update:  proc(deltaTime: float)
    , render:  proc(deltaTime: float)
    , dispose: proc()
  ]

  AbstractApp* {.pure, inheritable.} = ref object of RootObj

proc init*(app: AbstractApp) =
  discard

proc update*(app: AbstractApp, deltaTime: float) =
  discard

proc render*(app: AbstractApp, deltaTime: float) =
  discard

proc dispose*(app: AbstractApp) =
  discard
