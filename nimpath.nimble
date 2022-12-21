# Package

version       = "0.1.0"
author        = "Wesley Kerfoot"
description   = "Interface to libxml2's XPath parser"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["nimpath"]


# Dependencies

requires "nim >= 1.6.10, futhark >= 0.6.1"
