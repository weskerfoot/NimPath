## API to allow for parsing HTML/XML and querying it using XPath expressions

See tests for examples.

To install, simply add `https://github.com/weskerfoot/NimPath >= 0.1.3` to your .nimble file, and make sure clang is installed, and add `switch("passL", "/usr/lib/libxml2.so")` to config.nims in your project (or pass the linker flag manually).
