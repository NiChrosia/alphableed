import strformat, common

const HELP = fmt"""
bleedalpha [input] [output] (maxLayers)

Bleeds the alpha from the opaque pixels out into the image.

Optionally takes an argument (maxLayers) determining
how many layers to bleed out from the original image.

v{pkgVersion}; written by NiChrosia
"""

proc bleed*(width, height: int, data: seq[uint32], maxLayers: int = int.high): seq[uint32] =
    assert data.len == width * height, "Image data has incorrect dimensions!"

    var pixels = cast[seq[Color]](data)

    var isOpaque, isLoose = newSeq[bool](pixels.len)
    var next, pendingNext: seq[(int, int)]

    template `[]`[T](image: seq[T], x, y: int): T =
        image[x + y * width]

    template `[]=`[T](image: seq[T], x, y: int, value: T) =
        image[x + y * width] = value

    for y in 0 ..< height:
        for x in 0 ..< width:
            # this pixel is opaque
            if pixels[x, y].alpha > 0:
                isOpaque[x, y] = true
                continue
            
            # it is transparent
            for oy in max(y - 1, 0) .. min(y + 1, height - 1):
                for ox in max(x - 1, 0) .. min(x + 1, width - 1):
                    # it has an opaque neighbor
                    if pixels[ox, oy].alpha > 0:
                        next.add((x, y))

                        continue

            # it has no opaque neighbors
            isLoose[x, y] = true

    var layer = 0

    while layer < maxLayers and next.len > 0:
        pendingNext.setLen(0)
        
        for (x, y) in next:
            var ar, ag, ab: uint
            var opaqueNeighbors: uint = 0

            for oy in max(y - 1, 0) .. min(y + 1, height - 1):
                for ox in max(x - 1, 0) .. min(x + 1, width - 1):
                    if isLoose[ox, oy]:
                        isLoose[ox, oy] = false

                        pendingNext.add((ox, oy))
                    elif isOpaque[ox, oy]:
                        ar += pixels[ox, oy].red
                        ag += pixels[ox, oy].green
                        ab += pixels[ox, oy].blue

                        opaqueNeighbors += 1

            if opaqueNeighbors > 0:
                pixels[x, y].red   = uint8(ar div opaqueNeighbors)
                pixels[x, y].green = uint8(ag div opaqueNeighbors)
                pixels[x, y].blue  = uint8(ab div opaqueNeighbors)
            else:
                # if it doesn't have colors
                # nearby yet, it will
                pendingNext.add((x, y))

        for (x, y) in next:
            # opaqueness is set afterwards to
            # avoid interfering with the color
            # calculations of the previous layer
            isOpaque[x, y] = true

        next.swap(pendingNext)
        layer += 1

    return cast[seq[uint32]](pixels)

when isMainModule:
    import os, strutils

    if paramCount() < 2:
        quit(HELP, QuitSuccess)

    var input = validateFile(paramStr(1))
    var output = paramStr(2)
    var maxLayers = if paramCount() == 3: parseInt(paramStr(3)) else: int.high

    var (width, height, pixels) = readPng(input)

    pixels = bleed(width, height, pixels, maxLayers)

    writePng(output, width, height, pixels)
