# Package

version     = "0.3.0"
author      = "NiChrosia"
description = "A pure-nim alpha bleeding implementation."
license     = "MIT"

srcDir      = "alphableed"
binDir      = "build"
namedBin    = {
    "bleed":  "bleedalpha",
    "remove": "rmalpha",
}.toTable()

requires [
    "nim >= 1.6.10",
    "stbimage >= 2.5",
]
