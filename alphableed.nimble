# package
version     = "0.3.3"
author      = "NiChrosia"
description = "A pure-nim alpha bleeding implementation."
license     = "MIT"

installExt  = @["nim"]
srcDir      = "src"
binDir      = "build"
namedBin    = {
    "alphableed/bleed":  "bleedalpha",
    "alphableed/remove": "rmalpha",
}.toTable()

# dependencies
requires [
    "nim >= 1.6.10",
    "stbimage >= 2.5",
]
