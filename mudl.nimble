# Package

version       = "0.1.0"
author        = "l1pz"
description   = "A music downloader (with an api) written in Nim"
license       = "Unlicense"
srcDir        = "src"
bin           = @["mudl"]
binDir        = "bin"



# Dependencies

requires "nim >= 1.2.0"
requires "jester >= 0.4.3"
requires "cligen >= 1.0.0"
