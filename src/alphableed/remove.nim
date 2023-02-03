import os, strformat, common

type Color = object
    red, green, blue, alpha: uint8

const HELP = fmt"""
rmalpha [input] [output]

Makes all transparent pixels opaque by setting the alpha to max.

v{pkgVersion}; written by NiChrosia
"""

proc removeAlpha*(width, height: int, data: openArray[uint32]): seq[uint32] =
    result.setLen(width * height)

    for index in 0 ..< (width * height):
        # set alpha bits to max
        var color = cast[Color](data[index])
        color.alpha = uint8.high

        result[index] = cast[uint32](color)

when isMainModule:
    if paramCount() < 2:
        quit(HELP, QuitSuccess)

    var input = validateFile(paramStr(1))
    var output = paramStr(2)

    var (width, height, pixels) = readPng(input)

    pixels = removeAlpha(width, height, pixels)

    writePng(output, width, height, pixels)
