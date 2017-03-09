# Package

version       = "0.1.0"
author        = "Zachary Carter"
description   = "A 2D | 3D game development framework for the Nim programming language."
license       = "MIT"

srcDir        = "src"
skipDirs      = @["examples"]

# Dependencies

requires "nim >= 0.16.1"
requires "sdl2 >= 1.1"
requires "stb_image >= 1.1" # Would like to eventually not depend on this. Can't get sdl2_image and bgfx playing nicely.
requires "https://github.com/Halsys/nim-bgfx.git"

