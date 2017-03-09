import
  bgfx

import 
  fs_default
  , ../../math/fpu_math as fpumath
  , texture
  , vs_default


type
  SpriteBatch* = ref TSpriteBatch
  TSpriteBatch* = object
    vertices: seq[PosUVColorVertex]
    maxSprites: int
    lastTexture: Texture
    drawing: bool
    programHandle: ProgramHandle
    ibh: IndexBufferHandle
    vDecl: ptr VertexDecl
    texHandle: UniformHandle
    view: uint8_t

  PosUVColorVertex {.packed, pure.} = object
    x*, y*, z*: float32
    u*, v*: float32
    abgr*: uint32

proc flush(spriteBatch: SpriteBatch) =
  if spriteBatch.lastTexture.isNil:
    return
  
  bgfx.SetViewClear(spriteBatch.view, BGFX_CLEAR_COLOR or BGFX_CLEAR_DEPTH, 0x303030ff, 1.0, 0)

  bgfx.Touch(0)

  var vb : bgfx.TransientVertexBuffer
  bgfx.AllocTransientVertexBuffer(addr vb, 4, spriteBatch.vDecl);
  copyMem(vb.data, addr spriteBatch.vertices[0], sizeof(PosUVColorVertex) * spriteBatch.vertices.len)

  bgfx.SetTexture(0, spriteBatch.texHandle, spriteBatch.lastTexture.handle)
  bgfx.SetVertexBuffer(addr vb)
  bgfx.SetIndexBuffer(spriteBatch.ibh)

  var mtx: fpumath.Mat4
  mtxIdentity(mtx)

  bgfx.SetTransform(addr mtx[0])
  
  bgfx.SetState(0'u64 or BGFX_STATE_RGB_WRITE or BGFX_STATE_ALPHA_WRITE or BGFX_STATE_BLEND_FUNC(BGFX_STATE_BLEND_SRC_ALPHA
    , BGFX_STATE_BLEND_INV_SRC_ALPHA));
  
  bgfx.Submit(spriteBatch.view, spriteBatch.programHandle)

  spriteBatch.vertices.setLen(0)
  echo "HERE"

proc switchTexture(spriteBatch: SpriteBatch, texture: Texture) =
  flush(spriteBatch)
  spriteBatch.lastTexture = texture
#[
proc draw*(spriteBatch: SpriteBatch, textureRegion: TextureRegion, x, y: float32, color: uint32 = 0xffffffff'u32) =
  if not spriteBatch.drawing:
    logError "Spritebatch not in drawing mode. Call begin before calling draw."
    return
  
  let texture = textureRegion.texture

  if texture != spriteBatch.lastTexture:
    switchTexture(spriteBatch, texture)

  spriteBatch.vertices.add([
    PosUVColorVertex(x: x, y: y, u:textureRegion.u, v:textureRegion.v, z: 0.0'f32, abgr: color ),
    PosUVColorVertex(x: x + float textureRegion.regionWidth, y: y, u:textureRegion.u2, v:textureRegion.v, z: 0.0'f32, abgr: color ),
    PosUVColorVertex(x: x + float textureRegion.regionWidth, y: y + float textureRegion.regionHeight, u:textureRegion.u2, v:textureRegion.v2, z: 0.0'f32, abgr: color ),
    PosUVColorVertex(x: x, y: y + float textureRegion.regionHeight, u:textureRegion.u, v:textureRegion.v2, z: 0.0'f32, abgr: color ),
  ])
]#
proc draw*(spriteBatch: SpriteBatch, texture: Texture, x, y, width, height: float32, color: uint32 = 0xffffffff'u32, scale: Vec3 = [1.0'f32, 1.0'f32, 1.0'f32]) =
  if not spriteBatch.drawing:
    echo "Spritebatch not in drawing mode. Call begin before calling draw."
    return

  if texture != spriteBatch.lastTexture:
    switchTexture(spriteBatch, texture)

  var x1 = x
  var x2 = x + width
  var y1 = y
  var y2 = y + width

  if scale[0] != 1.0'f32 or scale[1] != 1.0'f32:
    x1 *= scale[0]
    x2 *= scale[0]
    y1 *= scale[0]
    y2 *= scale[0]


  spriteBatch.vertices.add([
    PosUVColorVertex(x: x1, y: y1, u:0.0, v:1.0, z: 0.0'f32, abgr: color ),
    PosUVColorVertex(x: x2, y: y1, u:1.0, v:1.0, z: 0.0'f32, abgr: color ),
    PosUVColorVertex(x: x2, y: y2, u:1.0, v:0.0, z: 0.0'f32, abgr: color ),
    PosUVColorVertex(x: x1, y: y2, u:0.0, v:0.0, z: 0.0'f32, abgr: color )
  ])

proc newSpriteBatch*(maxSprites: int, view: uint8_t) : SpriteBatch =
  result = SpriteBatch()
  result.drawing = false
  result.maxSprites = maxSprites
  result.vertices = @[]
  result.view = view

  result.vDecl = create(bgfx.VertexDecl)

  var indexdata = [
    0'u16, 1'u16, 2'u16,
    3'u16, 0'u16, 2'u16
  ]

  result.ibh = bgfx.CreateIndexBuffer(bgfx.Copy(addr indexdata[0], uint32_t indexdata.len * sizeof(uint_16t)))

  bgfx.Begin(result.vDecl)
  bgfx.Add(result.vDecl, bgfx.Attrib.Attrib_Position, 3, bgfx.AttribType.AttribType_Float)
  bgfx.Add(result.vDecl, bgfx.Attrib.Attrib_TexCoord0, 2, bgfx.AttribType.AttribType_Float)
  bgfx.Add(result.vDecl, bgfx.Attrib.Attrib_Color0, 4, bgfx.AttribType.AttribType_Uint8, true)
  bgfx.End(result.vDecl)

  result.texHandle = bgfx.CreateUniform("s_texColor", bgfx.UniformType.UniformType_Int1)
  
  let vsh = bgfx.CreateShader(bgfx.MakeRef(addr vs_default.vs[0], uint32_t sizeof(vs_default.vs)))
  let fsh = bgfx.CreateShader(bgfx.MakeRef(addr fs_default.fs[0], uint32_t sizeof(fs_default.fs)))
  result.programHandle = bgfx.CreateProgram(vsh, fsh, true)
  
  var proj: fpumath.Mat4
  fpumath.mtxOrtho(proj, 0.0, 960.0, 0.0, 540.0, 0.1'f32, 100.0'f32)
  bgfx.SetViewTransform(0, nil, unsafeAddr(proj[0]))

  bgfx.SetViewRect(0, 0, 0, cast[uint16](960), cast[uint16](540))

proc begin*(spriteBatch: SpriteBatch) =
  if spriteBatch.drawing:
    echo "Spritebatch is already in drawing mode. Call end before calling begin."
    return

  spriteBatch.drawing = true

proc `end`*(spriteBatch: SpriteBatch) =
  if not spriteBatch.drawing:
    echo "Spritebatch is not currently in drawing mode. Call begin before calling end."
    return
  
  if spriteBatch.vertices.len > 0:
    flush(spriteBatch)

  spriteBatch.lastTexture = nil
  spriteBatch.drawing = false

proc dispose*(spriteBatch: SpriteBatch) =
  if bgfx.isValid(spriteBatch.texHandle):
    bgfx.DestroyUniform(spriteBatch.texHandle)
    spriteBatch.texHandle = cast[UniformHandle](bgfx.invalidHandle)

  if bgfx.isValid(spriteBatch.ibh):
    bgfx.DestroyIndexBuffer(spriteBatch.ibh)
    spriteBatch.ibh = cast[IndexBufferHandle](bgfx.invalidHandle)

  if bgfx.isValid(spriteBatch.programHandle):
    bgfx.DestroyProgram(spriteBatch.programHandle)
    spriteBatch.programHandle = cast[ProgramHandle](bgfx.invalidHandle)