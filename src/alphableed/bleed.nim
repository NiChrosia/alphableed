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
    # but have opaque pixels as one of their 8 neigbors
    # var next: seq[(int, int)]
    var next = initHashSet[(int, int)]()
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

        for (xo, yo) in OFFSETS:
            let nx {.inject.} = x + xo
            let ny {.inject.} = y + yo

            let index = nx + ny * width

            if (nx >= 0) and (nx < width) and (ny >= 0) and (ny < height):
                if (not opaque[index]) or (pixels[index].alpha == 0):
                    body

    proc checkPixel(x, y: int) =
        if opaque[x + y * width] or (pixels[x + y * width].alpha > 0):
            if not opaque[x + y * width]:
                totalOpaques += 1

            opaque[x + y * width] = true
            return

        var hasOpaqueNearby = false

        forOpaqueNeighbors(x, y):
            hasOpaqueNearby = true

        if hasOpaqueNearby:
            next.incl((x, y))

    for y in 0 ..< height:
        for x in 0 ..< width:
            checkPixel(x, y)

    while totalOpaques < width * height:
        var afterQueue: Table[(int, int), Color]

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

            # we need to do it after to avoid
            # influencing the other pixels
            let color = Color(red: uint8(red), green: uint8(green), blue: uint8(blue), alpha: 0'u8)

            afterQueue[(x, y)] = color

        for (x, y) in afterQueue.keys:
            let color = afterQueue[(x, y)]
            pixels[x + y * width] = color

            # fake being opaque so that the
            # next round treats it as such
            opaque[x + y * width] = true
            totalOpaques += 1

        let previous = next
        var checks = initHashSet[(int, int)]()

        next = initHashSet[(int, int)]()

        for (x, y) in previous:
            forClearNeighbors(x, y):
                checks.incl((nx, ny))

        for (x, y) in checks:
            checkPixel(x, y)

    return cast[seq[uint32]](pixels)

when isMainModule:
    if paramCount() < 2:
        quit(HELP, QuitSuccess)

    var input = validateFile(paramStr(1))
    var output = paramStr(2)

    var (width, height, pixels) = readPng(input)

    pixels = bleed(width, height, pixels)

    writePng(output, width, height, pixels)
