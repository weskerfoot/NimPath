## API to allow for parsing HTML/XML and querying it using XPath expressions

**Requires you to have libxml2 installed**

Example
```nim
var parsed = parseHTML("<html><body><h1>foobar</h1></body></html>", "")

var nodes : seq[HTMLNode] = toSeq(xpathQuery(parsed, "//*"))

assert map(nodes, (n) => n.node_name.get) == @["html", "body", "h1"]

for node in xpathQuery(parsed, "//*"):
    if node.node_name.isSome and node.node_name.get == "h1":
        assert node.textContent.get == "foobar"
```

See the tests for more detailed examples.

To install, simply add `nimpath >= 0.1.9` to your .nimble file, and make sure clang is installed. If you installed libxml2 using something other than your package manager, it may require setting the linker flags in config.nims manually and/or using `LD_LIBRARY_PATH`.
