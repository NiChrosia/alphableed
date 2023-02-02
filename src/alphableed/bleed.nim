import os, strformat, common, tables, sets

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
    # but have opaque pixels as one of their 8 neighbors
    var isNext = newSeq[bool](pixels.len)
    var next = newSeq[(int, int)]()

    var opaque: seq[bool]
    opaque.setLen(pixels.len)

    var totalOpaques = 0

    var loose = newSeq[bool](pixels.len)

    var isChecked = newSeq[bool](pixels.len)
    var checks = newSeq[(int, int)]()

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

    template forOpaqueNeighbors(x, y: int, body: untyped) =
        ## executes [body] for all opaque neighbors
        ##
        ## additionally, the variables nx and ny
        ## are provided for the current neighbor

        for (xo, yo) in OFFSETS:
            let nx {.inject.} = x + xo
            let ny {.inject.} = y + yo

            let index = nx + ny * width

            if (nx >= 0) and (nx < width) and (ny >= 0) and (ny < height):
                if opaque[index] or (pixels[index].alpha > 0):
                    body

    template forClearNeighbors(x, y: int, body: untyped) =
        ## same as forOpaqueNeighbors but for transparent neighbors

        for nx {.inject.} in max(x - 1, 0) .. min(x + 1, width - 1):
            for ny {.inject.} in max(y - 1, 0) .. min(y + 1, height - 1):
                if loose[nx + ny * width]:
                    body

    proc checkPixel(x, y: int) =
        if opaque[x + y * width] or (pixels[x + y * width].alpha > 0):
            if not opaque[x + y * width]:
                totalOpaques += 1

            opaque[x + y * width] = true
            return

        forOpaqueNeighbors(x, y):
            if not isNext[x + y * width]:
                next.add((x, y))
                isNext[x + y * width] = true
                return

        loose[x + y * width] = true

    for y in 0 ..< height:
        for x in 0 ..< width:
            checkPixel(x, y)

    proc bleedLayer() =
        checks = @[]

        var opaqueQueue: seq[int]

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

            # we need to set opaque after to avoid
            # influencing the other pixels

            # but since the color adding checks
            # opaque first, we can set the color during
            # the iteration
            let color = Color(red: uint8(red), green: uint8(green), blue: uint8(blue), alpha: 0'u8)
            pixels[x + y * width] = color

            opaqueQueue.add(x + y * width)
            isNext[x + y * width] = false

            forClearNeighbors(x, y):
                if not isChecked[nx + ny * width]:
                    checks.add((nx, ny))
                    isChecked[nx + ny * width] = true

        for index in opaqueQueue:
            # fake being opaque so that the
            # next round treats it as such
            opaque[index] = true
            totalOpaques += 1

            loose[index] = false

        next = @[]

        for (x, y) in checks:
            isChecked[x + y * width] = false
            checkPixel(x, y)

    while totalOpaques < width * height:
        bleedLayer()

    return cast[seq[uint32]](pixels)

when isMainModule:
    if paramCount() < 2:
        quit(HELP, QuitSuccess)

    var input = validateFile(paramStr(1))
    var output = paramStr(2)

    var (width, height, pixels) = readPng(input)

    pixels = bleed(width, height, pixels)

    writePng(output, width, height, pixels)
