import stb_image/read as stbi
import stb_image/write as stbiw
import os, strformat

type Color* = object
    # adds up to 32 bits, and thus is 
    # memory-equivalent to a uint32
    red*, green*, blue*, alpha*: uint8

proc validateFile*(file: string): string =
    if not fileExists(file):
        echo fmt"file '{file}' does not exist!"
        quit(QuitFailure)
    else:
        return file

proc readPng*(file: string): tuple[width: int, height: int, pixels: seq[uint32]] =
    var channels: int
    var data = stbi.load(file, result.width, result.height, channels, stbi.RGBA)

    result.pixels.setLen(result.width * result.height)
    copyMem(addr result.pixels[0], addr data[0], data.len)

proc writePng*(file: string, width, height: int, pixels: seq[uint32]) =
    var data = newSeq[byte](pixels.len * 4)
    copyMem(addr data[0], unsafeAddr pixels[0], data.len)

    stbiw.writePNG(file, width, height, stbi.RGBA, data)
