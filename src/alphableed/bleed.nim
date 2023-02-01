import os, strformat, common

const HELP = fmt"""
bleedalpha [input] [output]

Bleeds the alpha from the opaque pixels out into the image.

v{pkgVersion}; written by NiChrosia
"""

proc bleed*(width, height: int, data: openArray[uint32]): seq[uint32] =
    ## data must be a sequence of size (width * height)
    ## containing 32-bit elements, with 8 bits reserved
    ## for each of the RGBA channels
    ##
    ## afterwards, a sequence containing the bled data
    ## is returned
    var pixels = newSeq[Color](data.len)
    copyMem(addr pixels[0], unsafeAddr data[0], data.len * sizeof(uint32))

    # we progressively set the colors around
    # opaque pixels to their average color,
    # until there are no transparent pixels left

    # next contains the pixels that are transparent,
    # but have opaque pixels as one of their 8 neigbors
    # var next: seq[(int, int)]
    var next: seq[(int, int)]
    var opaque: seq[bool]
    opaque.setLen(pixels.len)

    var totalOpaques = 0

    const OFFSETS: array[8, (int, int)] = [
        (0,   1),
        (1,   1),
        (1,   0),
        (1,  -1),
        (0,  -1),
        (-1, -1),
        (-1,  0),
        (-1,  1),
    ]

    proc addNext() =
        for y in 0 ..< height:
            for x in 0 ..< width:
                if opaque[x + y * width] or (pixels[x + y * width].alpha > 0):
                    if not opaque[x + y * width]:
                        totalOpaques += 1

                    opaque[x + y * width] = true
                    continue

                var hasOpaqueNearby = false

                for (xo, yo) in OFFSETS:
                    let nx = x + xo
                    let ny = y + yo

                    let index = nx + ny * width

                    if (nx >= 0) and (nx < width) and (ny >= 0) and (ny < height):
                        if opaque[index] or (pixels[index].alpha > 0):
                            hasOpaqueNearby = true

                if hasOpaqueNearby:
                    next.add((x, y))

    addNext()

    while totalOpaques < width * height:
        var opaqueQueue: seq[(int, int)]

        for (x, y) in next:
            var opaquesNearby = 0'u
            # sum of nearby colors
            var red, green, blue = 0'u

            for (xo, yo) in OFFSETS:
                let nx = x + xo
                let ny = y + yo

                let index = nx + ny * width

                if (nx >= 0) and (nx < width) and (ny >= 0) and (ny < height):
                    if opaque[index]:
                       let color = pixels[index]

                       opaquesNearby += 1
                       red += color.red
                       green += color.green
                       blue += color.blue

            red = red div opaquesNearby
            green = green div opaquesNearby
            blue = blue div opaquesNearby

            let color = Color(red: uint8(red), green: uint8(green), blue: uint8(blue), alpha: 0'u8)
            pixels[x + y * width] = color

            # we need to do it after to avoid
            # influencing the other pixels
            opaqueQueue.add((x, y))

        for (x, y) in opaqueQueue:
            # fake being opaque so that the
            # next round treats it as such
            opaque[x + y * width] = true
            totalOpaques += 1

        next = @[]
        addNext()

    return cast[seq[uint32]](pixels)

when isMainModule:
    if paramCount() < 2:
        quit(HELP, QuitSuccess)

    var input = validateFile(paramStr(1))
    var output = paramStr(2)

    var (width, height, pixels) = readPng(input)

    pixels = bleed(width, height, pixels)

    writePng(output, width, height, pixels)
