# Package

version     = "0.1.0"
author      = "NiChrosia"
description = "A pure-nim alpha bleeding implementation."
license     = "MIT"

srcDir      = "src"
binDir      = "build"
bin         = @["bleed", "remove-alpha"]

requires [
    "nim >= 1.6.10"
]
