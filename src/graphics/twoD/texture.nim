import
  bgfx
  , stb_image as stbi

type
  Texture* = ref TTexture
  TTexture* = object
    handle*: bgfx.TextureHandle
    filename*: string
    data: seq[uint8]
    width*, height*: int
    channels: int

proc load*(filename: string) : Texture =
  echo "Loading texture with filename : " & filename

  result = Texture()
  result.filename = filename

  result.data = stbi.load(filename, result.width, result.height, result.channels, stbi.Default)

  if result.data.isNil:
    echo "Error loading Texture!"
    return

  if result.channels == 4:
    result.handle = bgfx.CreateTexture2d(uint16_t result.width, uint16_t result.height, false, 1, bgfx.TextureFormat.TextureFormat_RGBA8, 0, bgfx.Copy(addr result.data[0], uint32_t result.width * result.height * 4))
  else:
    result.handle = bgfx.CreateTexture2d(uint16_t result.width, uint16_t result.height, false, 1, bgfx.TextureFormat.TextureFormat_RGB8, 0, bgfx.Copy(addr result.data[0], uint32_t result.width * result.height * 4))

proc unload*(texture: Texture) =
  echo "Unloading texture with filename : " & texture.filename
  
  if bgfx.isValid(texture.handle):
    bgfx.DestroyTexture(texture.handle)
    texture.handle = cast[TextureHandle](bgfx.invalidHandle)