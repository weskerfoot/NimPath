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

Example using `queryWithContext` to query against subnodes.

```nim

var parsed = parseHTML("<html><body><h3>foobar</h3><h3>sdasdasd</h3><div><span>this is a span</span><span>this is another span</span></div><h1 id="some_id" class="header1">foo bar baz</h1></body></html>")

var nodes : seq[HTMLNode] = toSeq(xpathQuery(parsed, "//*"))
for node in xpathQuery(parsed, "//div"):
    for subnode in queryWithContext(node, ".//*"):
        assert $subnode.node.name == "span"
```

See the tests for more detailed examples.

I have also written up a quick guide [here](https://wesk.tech/posts/nimpath-html-parsing/) with a more detailed explanation of how the library works.

To install, add `nimpath >= 0.1.9` to your .nimble file, and make sure clang is installed. If you installed libxml2 using something other than your package manager, it may require setting the linker flags in config.nims manually and/or using `LD_LIBRARY_PATH`.

You must also add this code to `config.nims` to get it to build.

```
import strutils
switch("passL", staticExec("pkg-config --libs libxml-2.0").strip)
```
