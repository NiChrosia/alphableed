# Package

version     = "0.2.0"
author      = "NiChrosia"
description = "A pure-nim alpha bleeding implementation."
license     = "MIT"

srcDir      = "src"
binDir      = "build"
bin         = @["bleedalpha", "rmalpha"]

requires [
    "nim >= 1.6.10",
    "stbimage >= 2.5",
]
