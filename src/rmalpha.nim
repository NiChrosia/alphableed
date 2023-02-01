import stb_image/read as stbi
import stb_image/write as stbiw
import os, strformat

const HELP = """
rmalpha [input] [output]

Makes all transparent pixels opaque by setting the alpha to max.

v0.1.0; written by NiChrosia
"""

if paramCount() < 2:
    echo HELP
    quit(QuitSuccess)

var input = paramStr(1)
if not fileExists(input):
    echo fmt"file '{input}' does not exist."
    quit(QuitFailure)

var output = paramStr(2)

var
    width, height, channels: int
    data: seq[uint8]

data = stbi.load(input, width, height, channels, stbi.RGBA)

type
    Color = object
        red, green, blue, alpha: uint8

var
    pixels: seq[Color]

pixels.setLen(data.len div 4)
copyMem(addr pixels[0], addr data[0], data.len)

for y in 0 ..< height:
    for x in 0 ..< width:
        pixels[x + y * width].alpha = uint8.high

var writtenData: seq[uint8]
writtenData.setLen(pixels.len * 4)

copyMem(addr writtenData[0], addr pixels[0], writtenData.len)

stbiw.writePNG(output, width, height, stbiw.RGBA, writtenData)
